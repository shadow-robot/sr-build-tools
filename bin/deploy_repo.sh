#!/usr/bin/env bash

# This scripts deploy any repository using Ansible.
# Repository should have particular structure

set -e # fail on errors
#set -x # echo commands run

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
    -l|--githublogin)
    GITHUB_LOGIN="$2"
    shift
    ;;
    -p|--githubpassword)
    GITHUB_PASSWORD="$2"
    shift
    ;;
    -b|--branch)
    GITHUB_BRANCH="$2"
    shift
    ;;
    --)
    shift
    break
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

if [ -z "${GITHUB_BRANCH}" ]; then
    GITHUB_BRANCH_URL_PART="trunk"
else
    GITHUB_BRANCH_URL_PART="branches/${GITHUB_BRANCH}"
fi

echo "================================================================="
echo "|                                                               |"
echo "|               Shadow Robot deployment script                  |"
echo "|                                                               |"
echo "================================================================="
echo ""
echo "possible options: "
echo "  * -o or --owner name of the GitHub repository owner (shadow-robot by default)"
echo "  * -r or --repo name of the owners repository (sr-interface by default)"
echo "  * -l or --githublogin github login for private repositories."
echo "  * -p or --githubpassword github password for private repositories."
echo "  * -b or --branch name of the repository branch name used for deployment"
echo "  * -- mark after which would be listed parameter repository deploy script "
echo ""
echo "example: ./deploy_repo.sh -o shadow-robot -r sr-interface -- -t deploy -h development "
echo ""
echo "owner    = ${REPOSITORY_OWNER}"
echo "repo     = ${REPOSITORY_NAME}"

if [ -z "${GITHUB_PASSWORD}" ] && [ -n "${GITHUB_LOGIN}" ]; then
    echo "git user = ${GITHUB_LOGIN}"
    echo -n "${GITHUB_LOGIN}'s GitHub password:"
    read -s GITHUB_PASSWORD
    echo
fi

REPOSITORY_URL="https://github.com//${REPOSITORY_OWNER}/${REPOSITORY_NAME}.git/${GITHUB_BRANCH_URL_PART}/deployment"

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
sudo apt-get install subversion -y

echo ""
echo " -------------------"
echo " |   Cloning repo  |"
echo " -------------------"
echo ""

pushd /tmp

rm -rf ./deployment

if [ -n "${GITHUB_LOGIN}" ]; then
    svn export --no-auth-cache -q ${REPOSITORY_URL} --username ${GITHUB_LOGIN} --password ${GITHUB_PASSWORD}
else
    svn export --no-auth-cache -q ${REPOSITORY_URL}
fi

if [ -z "${GITHUB_LOGIN}" ]; then
    /tmp/deployment/ansible/deploy.sh "$@"
else
    /tmp/deployment/ansible/deploy.sh -l ${GITHUB_LOGIN} -p ${GITHUB_PASSWORD} "$@"
fi

rm -rf ./deployment

popd

echo ""
echo " ------------------------------------------------"
echo " |            Operation completed               |"
echo " ------------------------------------------------"
echo ""
