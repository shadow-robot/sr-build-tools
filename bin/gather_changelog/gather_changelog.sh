#!/bin/bash
# Copyright 2023 Shadow Robot Company Ltd.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

IMAGE_NAME=$1
IMAGE_TAG=$2
IMAGE_REPOSITORY=$3
IMAGE_TAG_PREVIOUS=$4  # An override variable if you don't want it to compare to previous tag.
set -e  # Fail on error
echo "FIRST THINGS FIRST"
# This function takes in an input array and an empty array, and reverses the input into the empty array.
function reverse() {
    declare -n input_arr="$1"
    declare -n reverse_arr="$2"
    for element in "${input_arr[@]}"; do
        reverse_arr=("$element" "${reverse_arr[@]}")
    done
}

# This function gets all of the tags related to the image you are gathering the changelog for. It then sorts the list
# of tags by the time they where pushed. It then goes through the list and gets the tag of the first image that is not
# a release image, night-build, or match the ros version.
function get_last_tag() {
    # Get all image details
    images=$(aws ecr-public describe-images --repository-name $IMAGE_REPOSITORY --region us-east-1 --query 'sort_by(imageDetails,& imagePushedAt)[]')
    #images=$(aws $ecr_version describe-images --repository-name $IMAGE_REPOSITORY --region $region --query 'sort_by(imageDetails,& imagePushedAt)[]')
    # Find the image details for the input tag
    image_details=$(echo $images | jq -r ".[] | select(.imageTags[0] == \"$IMAGE_TAG\")")
    # Get the timestamp of the input image
    image_time=$(echo $image_details | jq -r '.imagePushedAt')
    # Get the image details of the previous image
    prev_image_details=$(echo $images | jq -r ".[] | select(.imagePushedAt < \"$image_time\") | .imageTags[0]")
    prev_image_details=($prev_image_details)  # Convert to list
    reverse prev_image_details reversed_image_details  # Reverse list
    reversed_image_details=(${reversed_image_details[@]})

    for tag in ${reversed_image_details[@]}; do
        if [[ $tag == *"night-build"* || $tag == *"release"* || $tag != "$DISTRIBUTION_VERSION"* ]]; then
            continue
        else
            IMAGE_TAG_PREVIOUS=$tag
            break
        fi
    done
}

# This function is used to just write a script to the container that we then later use to gather all the git repos
# In a given path and write them to a file.
function write_git_commit_dict_function_to_container() {
    container_name=$1
    function_string='
    function git_commit_dict() {
    # Define an empty dictionary
    declare -A git_dict

    # Loop through all directories in the given path
    for dir in "$1"/*/; do
        cd $dir
        # Get the repo name by removing the path and trailing slash
        repo_name="$(basename "${dir%/}")"
        remote_url=$(git config --get remote.origin.url)
        repo_name=$(basename "$remote_url")
        if [[ "$remote_url" == *"shadow-robot"* ]]; then
            # Get the git commit ID and store it in the dictionary
            git_dict[$repo_name]="$(git -C "$dir" rev-parse HEAD)"
        fi
    done

    for key in "${!git_dict[@]}"; do
        echo "$key:${git_dict[$key]}" >> /home/user/git_commit_dict.txt
    done
    }

    git config --global --add safe.directory "*"
    git_commit_dict $1
    '
    docker exec -i $container_name bash -c "echo -e '$function_string' > /home/user/git_commit_dict.sh"
    docker exec -i $container_name chmod +x /home/user/git_commit_dict.sh
}

# This function is used to start a docker container, then write a script to the container to gather all repository's
# information (repo name and hash) given a path, it then takes the file it writes the information too and copies it
# to the local machine to be read.
function get_all_github_dependencies() {
    container_name=$1
    image_name=$2

    docker run -itd --name $container_name $image_name
    write_git_commit_dict_function_to_container $container_name
    docker exec -i $container_name /bin/bash -c '/home/user/git_commit_dict.sh /home/user/projects/shadow_robot/base/src'
    docker exec -i $container_name /bin/bash -c '/home/user/git_commit_dict.sh /home/user/projects/shadow_robot/base_deps/src'
    docker cp $container_name:/home/user/git_commit_dict.txt /tmp/$container_name.txt
    docker stop $container_name
}

# This function takes in a path to a file and will go through the file line by line and creates a dictionarys.
# The file must be in the format `key:value` with one entry per line.
function file_to_dict() {
    declare -g -A file_dict=()

    while read line; do
        key=$(echo $line | cut -d ":" -f1)
        data=$(echo $line | cut -d ":" -f2)
        file_dict[$key]=$data
    done < $1
}

# This function takes in two dictionarys and compares them both. We use this as a way of determining which repoitories
# have been added, removed and updated. It sets 4 global variables:
# updated_repos - This is the dict that contains a key of the repo name and the value of the previous containers hash
# updated_repos_recent - Has the same key as above but has the current containers hash
# added_repos - This has the same key as above and has the current containr hash
# removed_repos - this is a list of all the repositories that have been removed between dict 1 and dict 2.
function compare_dicts() {
    local -n array1=$1  # Current image content
    local -n array2=$2  # Previous image content

    declare -g -A updated_repos
    declare -g -A updated_repos_recent
    declare -g -A added_repos
    declare -g -a removed_repos=()

    for key in "${!array1[@]}"; do
        if [ ! -v "array2[$key]" ]; then
            added_repos[$key]="${array1[$key]}"
        elif [ "${array1[$key]}" != "${array2[$key]}" ]; then
            updated_repos[$key]="${array2[$key]}"
            updated_repos_recent[$key]="${array1[$key]}"
        fi
    done

    for key in "${!array2[@]}"; do
        if [ ! -v "array1[$key]" ]; then
            removed_repos+=($key)
        fi
    done
}

# This function takes in a repository name a PR number and Some additonal text to add to the changelog line.
# It makes a GitHub API request to gather the details about that specific pull request, it then extracts the title
# of the PR, if it was merged or not and then the url to the PR itself. It then appends it to our changelog list.
get_pr_info() {
    repo_name=$1
    pr_number=$2
    addition_text=$3
    
    api_url="https://api.github.com/repos/shadow-robot/$repo_name/pulls/$pr_number"
    pr_info=$(curl -H "Authorization: token $GITHUB_PASSWORD" -s $api_url)
    html_url=$(echo $pr_info | jq -r '.html_url')
    merge=$(echo $pr_info | jq -r '.merged')
    title=$(echo $pr_info | jq -r '.title')
    if [[ $merge == "true" ]]; then
        changelog_list+=("$3$title <a href='$html_url'>GitHub</a>")
    fi
}

# This function takes in a subject string and a body string and then creates a temp version of our json template and
# replaces the template data with the inputted data. It then sends the email using AWS CLI SES.
function send_mail() {
    SUBJECT=$1
    BODY=$2
    TEMPLATE="$SCRIPT_DIR/ses-email-template.json"
    TMPFILE="/tmp/ses-$(date +%s)"

    jq --arg SUBJECT "$SUBJECT" --arg BODY "$BODY" '.Message.Subject.Data = $SUBJECT | .Message.Body.Text.Data = $BODY | .Message.Body.Html.Data = $BODY' $TEMPLATE > $TMPFILE

    aws ses send-email --cli-input-json file://$TMPFILE
}

# This function goes through both the updated_repos and added_repos dictionarys and clones all the repositories.
# It then navigates into the repo, gathers a log of all of the PR's. Using this list of PRs we then gather information
# on the PR and store it to the list changelog_list. Then we write all the changelog list details to another string
# called changelog and pass this to a function to then send an email giving us a list of all the differences.
function clone_repo_and_get_changes() {
    declare -g -A changelog_dict
    changelog_folder="/tmp/changelog_folder"
    mkdir $changelog_folder
    changelog_list=()

    for key in "${!updated_repos[@]}"; do
        git clone "$GITHUB_TEMPLATE/$key" "$changelog_folder/${key%.*}"
        cd "$changelog_folder/${key%.*}"
        set +e  # Grep will cause this to fail.
        pr_list=$(git log --pretty=format:'%H' --oneline "${updated_repos_recent[$key]}...${updated_repos[$key]}")
        if [[ $? == 1 ]]; then
            echo "No PRs skipping."
            continue
        fi
        set -e
        pr_number_regex='#([0-9]+)'
        hash_regex='^([a-z0-9]+)\s'
        
        pr_number_list=()
        while IFS= read -r line; do
            if [[ $line =~ $pr_number_regex ]]; then
                pr_number=${BASH_REMATCH[1]}
                pr_number_list+=($pr_number)
            fi
        done <<< "$pr_list"
        
        if [ -n "$pr_number_list" ]; then
            for pr in "${pr_number_list[@]}"; do
                get_pr_info ${key%.*} $pr
            done
        fi
    done

    for key in "${!added_repos[@]}"; do
        git clone --quiet "$GITHUB_TEMPLATE/$key" "$changelog_folder/${key%.*}"
        cd "$changelog_folder/${key%.*}"
        pr_list=$(git log --pretty=format:'%H' --oneline "${added_repos[$key]}" | grep "Merge pull request #")
        pr_number_regex='#([0-9]+)'
        hash_regex='^([a-z0-9]+)\s'
        
        pr_number_list=()
        while IFS= read -r line; do
            if [[ $line =~ $pr_number_regex ]]; then
                pr_number=${BASH_REMATCH[1]}
                pr_number_list+=($pr_number)
            fi
        done <<< "$pr_list"
        
        if [ -n "$pr_number_list" ]; then
            for pr in "${pr_number_list[@]}"; do
                get_pr_info ${key%.*} $pr "New Repo: "
            done
        fi
    done

    changelog="The changelog is gathered by comparing $IMAGE_NAME:$IMAGE_TAG to $IMAGE_NAME:$IMAGE_TAG_PREVIOUS<br>"
    changelog+="To view all the tags related to $IMAGE_NAME please click <a href='$IMAGE_LOCATION'>here</a><br><br>"
    changelog+="The changelog for the image $IMAGE_NAME:$IMAGE_TAG is as follows:<br>"
    for log in "${changelog_list[@]}"; do
        changelog+="<br>  -- $log"
    done
    for repo in "${removed_repos[@]}"; do
        changelog+="<br>  -- REPO REMOVED: $repo"
    done

    cd $STARTING_DIR
    rm -rf $changelog_folder
    
    send_mail "Changelog for image $IMAGE_NAME:$IMAGE_TAG" "$changelog"
}

if [[ $IMAGE_NAME == *"public.ecr"* ]]; then
    echo "1"
    region="us-east-1"
    aws ecr-public get-login-password --region $region | docker login --username AWS --password-stdin public.ecr.aws/shadowrobot
    IMAGE_LOCATION="https://eu-west-2.console.aws.amazon.com/ecr/repositories/public/080653068785/$IMAGE_REPOSITORY"
    ecr_version="ecr-public"
else
    echo "2"
    region="eu-west-2"
    IMAGE_LOCATION="https://eu-west-2.console.aws.amazon.com/ecr/repositories/private/080653068785/$IMAGE_REPOSITORY"
    aws ecr get-login-password --region $region | docker login --username AWS --password-stdin 080653068785.dkr.ecr.eu-west-2.amazonaws.com
    ecr_version="ecr"
fi

echo "WHATS GOING ON"

STARTING_DIR=$(pwd)
SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
GITHUB_TEMPLATE="https://$GITHUB_LOGIN:$GITHUB_PASSWORD@github.com/shadow-robot"

# Make sure that we are using a release tag
if [[ ! $IMAGE_TAG =~ ^[A-Za-z]+-v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "The image tag you inputted: $IMAGE_TAG doesn't match the required input of noetic-v0.0.1"
    exit 1
fi

# Gets the distribution version
if [[ $IMAGE_TAG =~ ^([^-]+) ]]; then
    DISTRIBUTION_VERSION="${BASH_REMATCH[1]}"
fi

# If we are using the previous tag variable, then check its a valid tag and has the right distribution version.
if [ ! -z "$IMAGE_TAG_PREVIOUS" ]; then
    if [[ ! $IMAGE_TAG_PREVIOUS =~ ^[A-Za-z]+-v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        echo "The previous image tag you inputted: $IMAGE_TAG_PREVIOUS doesn't match the required input of noetic-v0.0.1"
        exit 1
    fi
    if [[ ! $IMAGE_TAG_PREVIOUS =~ ^$DISTRIBUTION_VERSION+-v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        echo "The previous image tag you inputted: $IMAGE_TAG_PREVIOUS does not have the right distribution version $DISTRIBUTION_VERSION."
        exit 1
    fi
fi

# If we haven't set the previous tag version get the last tag.
if [ -z "$IMAGE_TAG_PREVIOUS" ]; then
    get_last_tag 
fi
docker pull $IMAGE_NAME:$IMAGE_TAG
docker pull $IMAGE_NAME:$IMAGE_TAG_PREVIOUS

get_all_github_dependencies "second_container" $IMAGE_NAME:$IMAGE_TAG_PREVIOUS
get_all_github_dependencies "first_container" $IMAGE_NAME:$IMAGE_TAG


# Gather all the github repos and their hash's from current image
file_to_dict /tmp/first_container.txt
declare -g -A first_container_dict=()
for key in "${!file_dict[@]}"; do
    first_container_dict[$key]=${file_dict[$key]}
done
# Gather all the github repos and their hash's from previous image
file_to_dict /tmp/second_container.txt
declare -g -A second_container_dict=()
for key in "${!file_dict[@]}"; do
    second_container_dict[$key]=${file_dict[$key]}
done

compare_dicts first_container_dict second_container_dict
for key in "${!updated_repos[@]}"; do
    echo "The repo $key had a hash of ${updated_repos[$key]} during the last release. And has ${updated_repos_recent[$key]} now."
done
for element in "${removed_repos[@]}"; do
    echo "The repo $element has been removed."
done
for element in "${!added_repos[@]}"; do
    echo "The repo $element has been added."
done

clone_repo_and_get_changes

rm /tmp/first_container.txt /tmp/second_container.txt
docker rm "first_container" "second_container"
