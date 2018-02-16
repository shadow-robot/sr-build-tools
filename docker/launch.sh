#!/usr/bin/env bash

set -e # fail on errors

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -i|--image)
    DOCKER_IMAGE_NAME="$2"
    shift
    ;;
    -u|--user)
    DOCKER_HUB_USER="$2"
    shift
    ;;
    -p|--password)
    DOCKER_HUB_PASSWORD="$2"
    shift
    ;;
    -r|--reinstall)
    REINSTALL_DOCKER_CONTAINER="$2"
    shift
    ;;
    -n|--name)
    DOCKER_CONTAINER_NAME="$2"
    shift
    ;;
    *)
    # ignore unknown option
    ;;
esac
shift
done

if [ -z "${REINSTALL_DOCKER_CONTAINER}" ];
then
    REINSTALL_DOCKER_CONTAINER="False"
fi

# If re-installation flag is Off that the following procedure will occur
#Check if Docker was installed
#Check if Docker container with provided name exists.
#If yes then check if Docker container is not running and start it

#If Docker container is running just exit
#Check if Docker image was pulled
#Check if login is required to get image and login (ask for password if it is not provided)
#Pull Docker image
#Start docker container with provided name and exit

#If re-installation flag is On that the following procedure will occur
#Check if Docker was installed
#Check if Docker container with provided name exists.
#If yes then stop container and delete container
#Check if login is required to get image and login (ask for password if it is not provided)
#Pull latest version of the Docker image
#Start docker container with provided name and exit


#Executed using the following format bash <(curl -Ls $remote_shell_script) -i <image_name> -u <docker_hub_user> -p <docker_hub_password> -r <Reinstall docker container fully (True, False), default False> -n <Docker container name>
#Flags -i <image_name>, -n <Docker container name> are required


echo "================================================================="
echo "|                                                               |"
echo "|             Shadow default docker deployment                  |"
echo "|                                                               |"
echo "================================================================="
echo ""
echo "possible options: "
echo "  * -i or --image name of the Docker hub image to pull"
echo "  * -u or --user Docker hub user name"
echo "  * -p or --password Docker hub password"
echo "  * -r or --reinstall flag to know if the docker container should be fully reinstalled (false by default)"
echo "  * -n or --name name of the docker container"
echo ""
echo "example: ./launch.sh -i   -u mydockerhublogin -p mysupersecretpassword"
echo ""
echo "image name        = ${DOCKER_IMAGE_NAME}"
echo "container name    = ${DOCKER_CONTAINER_NAME}"
echo "docker hub user   = ${DOCKER_HUB_USER}"
echo "reinstall flag    = ${REINSTALL_DOCKER_CONTAINER}"


echo ""
echo " -----------------------------------"
echo " |   Checking docker installation  |"
echo " -----------------------------------"
echo ""


export SR_BUILD_TOOLS_HOME=/tmp/sr-build-tools/

if [ -x "$(command -v docker)" ]; then
    echo "Docker installed"
else
    echo "Install docker"
    # command
fi

if [ ! "$(docker ps -q -f name=${DOCKER_CONTAINER_NAME})" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=${DOCKER_CONTAINER_NAME})" ]; then
        # cleanup
        echo "Container already exist"
        #docker rm <name>
    fi
    # run your container
    docker pull ${DOCKER_IMAGE_NAME}
    docker run -d --name ${DOCKER_CONTAINER_NAME} ${DOCKER_IMAGE_NAME}
fi


echo ""
echo " ------------------------------------------------"
echo " |            Operation completed               |"
echo " ------------------------------------------------"
echo ""
