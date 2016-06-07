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

if [ -z "${GITHUB_PASSWORD}" ] && [ -n "${GITHUB_LOGIN}" ]; then
    echo "git user = ${GITHUB_LOGIN}"
    echo -n "${GITHUB_LOGIN}'s GitHub password:"
    read -s GITHUB_PASSWORD
    echo
fi

if [ -n "${GITHUB_LOGIN}" ]; then
    REPOSITORY_URL="https://${GITHUB_LOGIN}:${GITHUB_PASSWORD}@github.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}.git"
    if [ -z "${EXTERNAL_ARGUMENTS}" ]; then
        EXTERNAL_ARGUMENTS=" -l ${GITHUB_LOGIN} -p ${GITHUB_PASSWORD}"
    else
        EXTERNAL_ARGUMENTS="${EXTERNAL_ARGUMENTS} -l ${GITHUB_LOGIN} -p ${GITHUB_PASSWORD}"
    fi
else
    REPOSITORY_URL="https://github.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}.git"
fi

sudo apt-get update
sudo apt-get install git -y

pushd /tmp
git clone ${REPOSITORY_URL}
popd

/tmp/${REPOSITORY_NAME}/deployment/ansible/deploy.sh ${EXTERNAL_ARGUMENTS}

rm -rf /tmp/${REPOSITORY_NAME}
