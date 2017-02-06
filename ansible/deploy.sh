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
    *)
    # ignore unknown option
    ;;
esac
shift
done

export DEFAULT_INSTALL_FILE_NAME="repository.rosinstall"

if [ -z "${REPOSITORY_OWNER}" ]; then
    REPOSITORY_OWNER="shadow-robot"
fi

if [ -z "${REPOSITORY_NAME}" ]; then
    REPOSITORY_NAME="sr_interface"
fi

export PROJECT_NAME=${REPOSITORY_NAME}

if [ -z "${GITHUB_BRANCH}" ]; then
    GITHUB_BRANCH_URL_PART="trunk"
else
    GITHUB_BRANCH_URL_PART="branches/${GITHUB_BRANCH}"
fi

if [ -z "${INSTALL_FILE}" ];
then
    INSTALL_FILE=${DEFAULT_INSTALL_FILE_NAME}
else
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
echo "  * -w or --workspace path you want to use for the ROS workspace. The directory will be created. (~/indigo_ws by default)"
echo "  * -v or --v ROS version name (indigo by default)"
echo "  * -b or --branch repository branch"
echo "  * -i or --installfile relative path to rosintall file in repository (default /repository.rosinstall)"
echo "  * -l or --githublogin github login for private repositories."
echo "  * -p or --githubpassword github password for private repositories."
echo ""
echo "example: ./default_deploy.sh -o shadow-robot -r sr_interface -w ~{{ros_user}}/workspace/shadow/base  -l mygithublogin -p mysupersecretpassword"
echo ""
echo "owner        = ${REPOSITORY_OWNER}"
echo "repo         = ${REPOSITORY_NAME}"
echo "ROS          = ${ROS_VERSION}"
echo "workspace    = ${WORKSPACE_PATH}"
echo "branch       = ${GITHUB_BRANCH:-'default'}"
echo "install file = ${INSTALL_FILE}"
echo "project name = ${PROJECT_NAME}"

if [ -z "${GITHUB_PASSWORD}" ] && [ -n "${GITHUB_LOGIN}" ]; then
    echo "git user = ${GITHUB_LOGIN}"
    echo -n "${GITHUB_LOGIN}'s GitHub password:"
    read -s GITHUB_PASSWORD
    echo
fi

export SR_BUILD_TOOLS_ANSIBLE_HOME=/tmp/sr-build-tools-ansible/
export SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
export ANSIBLE_INVENTORY="${SR_BUILD_TOOLS_ANSIBLE_HOME}/hosts"
export PLAYBOOKS_DIR="${SR_BUILD_TOOLS_ANSIBLE_HOME}"
export ANSIBLE_ROLES_PATH=${SR_BUILD_TOOLS_ANSIBLE_HOME}/roles
export ANSIBLE_CALLBACK_PLUGINS=${SR_BUILD_TOOLS_ANSIBLE_HOME}/callback_plugins
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_SSH_ARGS=" -o UserKnownHostsFile=/dev/null "
export ANSIBLE_LOG_PATH=~/build_tools_ansible.log

if [ -z "${GITHUB_LOGIN}" ]; then
    GITHUB_CREDENTIALS=""
else
    GITHUB_CREDENTIALS=" \"github_login\":\"${GITHUB_LOGIN}\", \"github_password\":\"${GITHUB_PASSWORD}\", "
fi

export MY_ANSIBLE_PARAMETERS="-vvv  --ask-become-pass ${PLAYBOOKS_DIR}/vagrant_site.yml "
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
rm -rf ${SR_BUILD_TOOLS_ANSIBLE_HOME} &
wait

sudo pip install paramiko markupsafe PyYAML Jinja2 httplib2 six ansible==' 2.1.0.0'
sudo pip install --upgrade setuptools

echo ""
echo " -------------------"
echo " |   Cloning repo  |"
echo " -------------------"
echo ""

if [ -z "${SR_BUILD_TOOLS_BRANCH}" ]; then
    SR_BUILD_TOOLS_GITHUB_BRANCH_URL_PART="trunk"
else
    SR_BUILD_TOOLS_GITHUB_BRANCH_URL_PART="branches/${SR_BUILD_TOOLS_BRANCH}"
fi
svn export --no-auth-cache -q "https://github.com//shadow-robot/sr-build-tools.git/${SR_BUILD_TOOLS_GITHUB_BRANCH_URL_PART}/ansible" ${SR_BUILD_TOOLS_ANSIBLE_HOME}

echo ""
echo " ------------------------------------"
echo " |   Cloning repository.rosinstall  |"
echo " ------------------------------------"
echo ""

ROSINSTALL_PATH="https://github.com//${REPOSITORY_OWNER}/${REPOSITORY_NAME}.git/${GITHUB_BRANCH_URL_PART}/${INSTALL_FILE}"
ROS_WORKSPACE_INSTALL_FILE="${SR_BUILD_TOOLS_ANSIBLE_HOME}/repository.rosinstall"

if [ -n "${GITHUB_LOGIN}" ]; then
    svn export --no-auth-cache -q ${ROSINSTALL_PATH} --username ${GITHUB_LOGIN} --password ${GITHUB_PASSWORD} ${ROS_WORKSPACE_INSTALL_FILE}
else
    svn export --no-auth-cache -q ${ROSINSTALL_PATH} ${ROS_WORKSPACE_INSTALL_FILE}
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
fi

export WORKSPACE_SETTINGS="\"ros_workspace\":\"${WORKSPACE_PATH}\", \"ros_workspace_install\":\"${ROS_WORKSPACE_INSTALL_FILE}\" "
export EXTERNAL_VARIABLES_JSON="{ ${GITHUB_CREDENTIALS} ${EXTRA_ANSIBLE_PARAMETER_ROS_USER} ${ROS_RELEASE_SETTINGS} ${WORKSPACE_SETTINGS} }"
ansible-playbook ${MY_ANSIBLE_PARAMETERS} --extra-vars "${EXTERNAL_VARIABLES_JSON}"

echo ""
echo " ------------------------------------------------"
echo " |            Operation completed               |"
echo " ------------------------------------------------"
echo ""


