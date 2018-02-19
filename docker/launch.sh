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
    -d|--desktopicon)
    DESKTOP_ICON="$2"
    shift
    ;;
    -l|--launchhand)
    LAUNCH_HAND="$2"
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
    REINSTALL_DOCKER_CONTAINER=false
fi

if [ -z "${DESKTOP_ICON}" ];
then
    DESKTOP_ICON=true
fi

if [ -z "${LAUNCH_HAND}" ];
then
    LAUNCH_HAND=false
fi

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
echo "example: ./launch.sh -i shadowrobot/dexterous-hand:indigo -n hand_e_indigo_real_hw -u mydockerhublogin -p mysupersecretpassword"
echo ""
echo "image name        = ${DOCKER_IMAGE_NAME}"
echo "container name    = ${DOCKER_CONTAINER_NAME}"
echo "reinstall flag    = ${REINSTALL_DOCKER_CONTAINER}"

if [ -z ${DOCKER_IMAGE_NAME} ] || [ -z ${DOCKER_CONTAINER_NAME} ]; then
    echo "Docker image name and name of container are required"
    exit 1
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

# From ANSI escape codes we have the following colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo " -----------------------------------"
echo " |   Checking docker installation  |"
echo " -----------------------------------"
echo ""

if [ -x "$(command -v docker)" ]; then
    echo "Docker installed"
else
    echo "Install docker"
    sudo apt-get update
    sudo apt-get install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"

    sudo apt-get update
    sudo apt-get install docker-ce

    sudo groupadd docker
    sudo usermod -aG docker $USER
fi

echo "Docker log in "
for i in 'seq 1 3';
do
    if [ -n ${DOCKER_HUB_USER} ]; then
        if [ -n ${DOCKER_HUB_PASSWORD} ]; then
            docker login --username ${DOCKER_HUB_USER} --password ${DOCKER_HUB_PASSWORD}
        else
            docker login --username ${DOCKER_HUB_USER} --password-stdin
        fi
    else
        docker login
    fi
    if [ $? == 0 ]; then
        break
    fi
    if [ ${i} == 3 and $? !=0 ]; then
        echo -e "${RED}Docker login failed. You will not be able to pull private docker images.${NC}"
        exit 1
    fi
done

if [ ${REINSTALL_DOCKER_CONTAINER} = false ] ; then
   echo "Not reinstalling docker image"
   if [ ! "$(docker ps -q -f name=${DOCKER_CONTAINER_NAME})" ]; then
        if [ "$(docker ps -aq -f status=exited -f name=${DOCKER_CONTAINER_NAME})" ]; then
            echo "Container with specified name already exist. Starting container"
            docker start ${DOCKER_CONTAINER_NAME}
        else
            if [[ "$(docker images -q ${DOCKER_IMAGE_NAME} 2> /dev/null)" == "" ]]; then
                # Image doesn't exist, pull it
                docker pull ${DOCKER_IMAGE_NAME}
            fi
            echo "Running container"
            docker run -it --privileged --name ${DOCKER_CONTAINER_NAME} --network=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME}
        fi
   else
        echo "Container already running"
   fi
else
    echo "Reinstalling docker container"
    if [ ! "$(docker ps -q -f name=${DOCKER_CONTAINER_NAME})" ]; then
        echo "Container running. Stopping it"
        docker stop ${DOCKER_CONTAINER_NAME}
    fi
    if [ "$(docker ps -aq -f status=exited -f name=${DOCKER_CONTAINER_NAME})" ]; then
        echo "Container with specified name already exist. Removing container"
        docker rm ${DOCKER_CONTAINER_NAME}
    fi
    echo "Pulling latest version of docker image"
    docker pull ${DOCKER_IMAGE_NAME}

    echo "Running container"
    docker run -it --privileged --name ${DOCKER_CONTAINER_NAME} --network=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME}
fi

if [ ${DESKTOP_ICON} = true ] ; then
    echo ""
    echo " -------------------------------"
    echo " |   Making desktop shortcut   |"
    echo " -------------------------------"
    echo ""

    echo "Creating launcher folder"
    APP_FOLDER=/home/$USER/launcher_app
    if [ ! -d "${APP_FOLDER}" ]; then
      mkdir ${APP_FOLDER}
    fi

    echo "Downloading the script"
    # TODO: change this for master before merging
    curl "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/F%23SRC-1277_one_liner_docker_deployment/docker/launch.sh" >> ${APP_FOLDER}/launch.sh

    echo "Creating executable file"
    printf "#! /bin/bash
    terminator -x bash -c 'cd ${APP_FOLDER}; ./launch.sh -i ${DOCKER_IMAGE_NAME} -n ${DOCKER_CONTAINER_NAME} ; exec bash'
    " > ${APP_FOLDER}/launcher_exec.sh

    echo "Copying icon"
    cp hand_h.png ${APP_FOLDER}

    echo "Creating desktop file"
    printf "[Desktop Entry]
    Version=1.0
    Name=Hand_Launcher
    Comment=This is application launches the hand
    Exec=/home/${USER}/launcher_app/launcher_exec.sh
    Icon=/home/${USER}/launcher_app/hand_h.png
    Terminal=false
    Type=Application
    Categories=Utility;Application;" > /home/$USER/Desktop/launcher.desktop

    echo "Allowing files to be executable"
    chmod +x ${APP_FOLDER}/launcher_exec.sh
    chmod +x /home/$USER/Desktop/launcher.desktop
fi


echo "Login out from docker"
docker logout

echo -e "${YELLOW}Please logout and login again.${NC}"

echo ""
echo -e "${GREEN} ------------------------------------------------${NC}"
echo -e "${GREEN} |            Operation completed               |${NC}"
echo -e "${GREEN} ------------------------------------------------${NC}"
echo ""
