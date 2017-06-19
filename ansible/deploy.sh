#!/usr/bin/env bash

set -e # fail on errors
set -x # echo commands run

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -o|--owner)
    REPOSITORY_OWNER="$2"
    shift
    ;;
    -r|--repo)
    REPOSITORY_NAME="$2"
    shift
    ;;
    -b|--branch)
    GITHUB_BRANCH="$2"
    shift
    ;;
    -w|--workspace)
    WORKSPACE_PATH="$2"
    shift
    ;;
    -v|--rosversion)
    ROS_VERSION="$2"
    shift
    ;;
    -i|--installfile)
    INSTALL_FILE="$2"
    shift
    ;;
    -l|--githublogin)
    GITHUB_LOGIN="$2"
    shift
    ;;
    -p|--githubpassword)
    GITHUB_PASSWORD="$2"
    shift
    ;;
    -s|--usesshuri)
    USE_SSH_URI="$2"
    shift
    ;;
    -c|--configbranch)
    SR_CONFIG_BRANCH="$2"
    shift
    ;;
    -t|--tagslist)
    TAGS_LIST="$2"
    shift
    ;;
    *)
    # ignore unknown option
    ;;
esac
shift
done

if [ -z "${REPOSITORY_OWNER}" ]; then
    REPOSITORY_OWNER="shadow-robot"
fi

if [ -z "${REPOSITORY_NAME}" ]; then
    REPOSITORY_NAME="sr_interface"
fi

export PROJECT_NAME=${REPOSITORY_NAME}

if [ -n "${INSTALL_FILE}" ];
then
    PROJECT_NAME=$(basename $INSTALL_FILE)
    PROJECT_NAME=${PROJECT_NAME%.*}
fi

if [ -z "${WORKSPACE_PATH}" ];
then
    WORKSPACE_PATH="~{{ ros_user }}/workspace/${PROJECT_NAME}/base"
fi

if [ -z "${ROS_VERSION}" ];
then
    ROS_VERSION="indigo"
fi

echo "================================================================="
echo "|                                                               |"
echo "|             Shadow default installation tool                  |"
echo "|                                                               |"
echo "================================================================="
echo ""
echo "possible options: "
echo "  * -o or --owner name of the GitHub repository owner (shadow-robot by default)"
echo "  * -r or --repo name of the owners repository (sr-interface by default)"
echo "  * -w or --workspace path you want to use for the ROS workspace. The directory will be created. (~<current_user>/workspace/<project_name>/base by default)"
echo "  * -v or --rosversion ROS version name (indigo by default)"
echo "  * -b or --branch repository branch"
echo "  * -i or --installfile relative path to rosintall file. When specified then sources from this rosintall file are installed not repository itself"
echo "  * -l or --githublogin github login for private repositories."
echo "  * -p or --githubpassword github password for private repositories."
echo "  * -s or --usesshuri flag informing that ssh format github uris will be used. Set true to enable, set false or do not set to disable"
echo ""
echo "example: ./deploy.sh -o shadow-robot -r sr_interface -w ~{{ros_user}}/workspace/shadow/base  -l mygithublogin -p mysupersecretpassword"
echo ""
echo "owner        = ${REPOSITORY_OWNER}"
echo "repo         = ${REPOSITORY_NAME}"
echo "ROS          = ${ROS_VERSION}"
echo "workspace    = ${WORKSPACE_PATH}"
echo "branch       = ${GITHUB_BRANCH:-'default'}"
echo "install file = ${INSTALL_FILE}"
echo "project name = ${PROJECT_NAME}"
echo "tags list = ${TAGS_LIST}"

if [ -z "${GITHUB_PASSWORD}" ] && [ -n "${GITHUB_LOGIN}" ]; then
    echo "git user = ${GITHUB_LOGIN}"
    echo -n "${GITHUB_LOGIN}'s GitHub password:"
    read -s GITHUB_PASSWORD
    echo
fi

export SR_BUILD_TOOLS_HOME=/tmp/sr-build-tools/
export PROJECT_HOME_DIR=/tmp/my_project/
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export ANSIBLE_INVENTORY="${SR_BUILD_TOOLS_HOME}/ansible/hosts"
export PLAYBOOKS_DIR="${SR_BUILD_TOOLS_HOME}/ansible"
export ANSIBLE_ROLES_PATH="${SR_BUILD_TOOLS_HOME}/ansible/roles"
export ANSIBLE_CALLBACK_PLUGINS="${SR_BUILD_TOOLS_HOME}/ansible/callback_plugins"
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_SSH_ARGS=" -o UserKnownHostsFile=/dev/null "
export ANSIBLE_LOG_PATH=~/build_tools_ansible.log

ROSINTSTALL_FILE_CONTENT="- git: {local-name: \"${PROJECT_NAME}\", uri: "

if [ -z "${USE_SSH_URI}" ] || [ "${USE_SSH_URI}" = false ]; then
    if [ -z "${GITHUB_LOGIN}" ]; then
        REPOSITORY_URL="https://github.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}.git"
        ROSINTSTALL_FILE_CONTENT="${ROSINTSTALL_FILE_CONTENT}\"${REPOSITORY_URL}\""
        GITHUB_CREDENTIALS=""
    else
        REPOSITORY_URL="https://${GITHUB_LOGIN}:${GITHUB_PASSWORD}@github.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}.git"
        ROSINTSTALL_FILE_CONTENT="${ROSINTSTALL_FILE_CONTENT}\"https://{{github_login}}:{{github_password}}@github.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}.git\""
        GITHUB_CREDENTIALS=" \"github_login\":\"${GITHUB_LOGIN}\", \"github_password\":\"${GITHUB_PASSWORD}\", "
    fi
elif [ "${USE_SSH_URI}" = true ]; then
    echo "Using ssh github uri format"
    REPOSITORY_URL="git@github.com:${REPOSITORY_OWNER}/${REPOSITORY_NAME}.git"
    ROSINTSTALL_FILE_CONTENT="${ROSINTSTALL_FILE_CONTENT}\"${REPOSITORY_URL}\""
    GITHUB_CREDENTIALS=" \"use_ssh_uri\":\"true\", "
else
    echo "Incorrect ssh key flag value"
    exit 1
fi

if [ -z "${TAGS_LIST}" ]; then
    export MY_ANSIBLE_PARAMETERS="-vvv  --ask-become-pass ${PLAYBOOKS_DIR}/vagrant_site.yml --tags default"
else
    export MY_ANSIBLE_PARAMETERS="-vvv  --ask-become-pass ${PLAYBOOKS_DIR}/vagrant_site.yml --tags default,${TAGS_LIST}"
fi

export EXTRA_ANSIBLE_PARAMETER_ROS_USER=" \"ros_user\":\"`whoami`\", \"ros_group\":\"`whoami`\", "

echo ""
echo " ---------------------------------"
echo " |   Installing needed packages  |"
echo " ---------------------------------"
echo ""

# Wait for apt-get update lock file to be released
while (sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1) || (sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1) do
    echo "Waiting for apt-get update file lock..."
    sleep 1
done
sudo apt-get update

# Wait for apt-get install lock file to be released
while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    echo "Waiting for apt-get install file lock..."
    sleep 1
done
sudo apt-get install -y python-pip git subversion libyaml-dev libpython2.7-dev python-crypto libssl-dev libffi-dev python-dev sshpass &
rm -rf ${SR_BUILD_TOOLS_HOME} &
rm -rf ${PROJECT_HOME_DIR} &
wait

sudo pip install paramiko markupsafe PyYAML Jinja2 httplib2 six ansible==' 2.1.0.0'
sudo pip install --upgrade setuptools

echo ""
echo " -------------------"
echo " |   Cloning repo  |"
echo " -------------------"
echo ""

git clone --depth 1 -b ${SR_BUILD_TOOLS_BRANCH:-"master"}  https://github.com/shadow-robot/sr-build-tools.git ${SR_BUILD_TOOLS_HOME}

echo ""
echo " ------------------------------------"
echo " |   Creating repository.rosinstall  |"
echo " ------------------------------------"
echo ""

ROS_WORKSPACE_INSTALL_FILE="${SR_BUILD_TOOLS_HOME}/repository.rosinstall"

if [ -z "${INSTALL_FILE}" ];
then
    if [ -z "${GITHUB_BRANCH}" ]; then
        ROSINTSTALL_FILE_CONTENT="${ROSINTSTALL_FILE_CONTENT} }"
    else
        ROSINTSTALL_FILE_CONTENT="${ROSINTSTALL_FILE_CONTENT}, version: \"${GITHUB_BRANCH}\" }"
    fi
    echo ${ROSINTSTALL_FILE_CONTENT} > ${ROS_WORKSPACE_INSTALL_FILE}
else
    if [ -z "${GITHUB_BRANCH}" ]; then
        git clone --depth 1 ${REPOSITORY_URL} ${PROJECT_HOME_DIR}
    else
        git clone --depth 1 -b ${GITHUB_BRANCH} ${REPOSITORY_URL} ${PROJECT_HOME_DIR}
    fi
    cp "${PROJECT_HOME_DIR}/${INSTALL_FILE}" ${ROS_WORKSPACE_INSTALL_FILE}
fi

echo ""
echo " -------------------"
echo " | Running Ansible |"
echo " -------------------"
echo ""

sudo sh -c "echo \"[dev-machine]
localhost ansible_connection=local\" > ${ANSIBLE_INVENTORY}"

export ROS_RELEASE_SETTINGS=" \"ros_release\":\"${ROS_VERSION}\", "
if [ "${ROS_VERSION}" != "indigo" ]; then
  ROS_RELEASE_SETTINGS="${ROS_RELEASE_SETTINGS} \"ros_packages\":[], "
  echo "ros settings = ${ROS_RELEASE_SETTINGS}"
fi

export WORKSPACE_SETTINGS="\"ros_workspace\":\"${WORKSPACE_PATH}\", \"ros_workspace_install\":\"${ROS_WORKSPACE_INSTALL_FILE}\" "
export EXTERNAL_VARIABLES_JSON="{ ${GITHUB_CREDENTIALS} ${EXTRA_ANSIBLE_PARAMETER_ROS_USER} ${ROS_RELEASE_SETTINGS} ${WORKSPACE_SETTINGS} }"
ansible-playbook ${MY_ANSIBLE_PARAMETERS} --extra-vars "${EXTERNAL_VARIABLES_JSON}"

echo ""
echo " ------------------------------------------------"
echo " |            Operation completed               |"
echo " ------------------------------------------------"
echo ""


