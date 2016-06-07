#!/usr/bin/env bash

# This scripts deploy any repository using Ansible.
# Repository should have particular structure

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
    -e|--external)
    EXTERNAL_ARGUMENTS="$2"
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

if [ -z "${GITHUB_BRANCH}" ]; then
    GITHUB_BRANCH_URL_PART="trunk"
else
    GITHUB_BRANCH_URL_PART="branches/${GITHUB_BRANCH}"
fi


if [ -z "${GITHUB_PASSWORD}" ] && [ -n "${GITHUB_LOGIN}" ]; then
    echo "git user = ${GITHUB_LOGIN}"
    echo -n "${GITHUB_LOGIN}'s GitHub password:"
    read -s GITHUB_PASSWORD
    echo
fi

REPOSITORY_URL="https://github.com//${REPOSITORY_OWNER}/${REPOSITORY_NAME}.git/${GITHUB_BRANCH_URL_PART}/deployment"

if [ -n "${GITHUB_LOGIN}" ]; then
    if [ -z "${EXTERNAL_ARGUMENTS}" ]; then
        EXTERNAL_ARGUMENTS=" -l ${GITHUB_LOGIN} -p ${GITHUB_PASSWORD}"
    else
        EXTERNAL_ARGUMENTS="${EXTERNAL_ARGUMENTS} -l ${GITHUB_LOGIN} -p ${GITHUB_PASSWORD}"
    fi
fi

sudo apt-get update
sudo apt-get install subversion -y

pushd /tmp

rm -rf ./deployment

if [ -n "${GITHUB_LOGIN}" ]; then
    svn export --no-auth-cache -q ${REPOSITORY_URL} --username ${GITHUB_LOGIN} --password ${GITHUB_PASSWORD}
else
    svn export --no-auth-cache -q ${REPOSITORY_URL}
 fi
/tmp/deployment/ansible/deploy.sh ${EXTERNAL_ARGUMENTS}
rm -rf ./deployment

popd

