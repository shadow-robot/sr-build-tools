#!/usr/bin/env bash

set -e # fail on errors

echo "================================================================="
echo "|                                                               |"
echo "|             Shadow default docker deployment                  |"
echo "|                                                               |"
echo "================================================================="

#Executed using the following format bash <(curl -Ls $remote_shell_script) -i <image_name> -u <docker_hub_user> -p <docker_hub_password> -r <Reinstall docker container fully (True, False), default False> -n <Docker container name>
#Flags -i <image_name>, -n <Docker container name> are required
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

if [ ! "$(docker ps -q -f name=<name>)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=<name>)" ]; then
        # cleanup
        docker rm <name>
    fi
    # run your container
    docker run -d --name <name> my-docker-image
fi

echo ""
echo " -------------------------------"
echo " |   Making desktop shortcut   |"
echo " -------------------------------"
echo ""

mkdir /home/$USER/launcher_app

cp launcher.desktop /home/$USER/Desktop

cp launcher_exec.sh /home/$USER/launcher_app
cp hand_h.png /home/$USER/launcher_app

cd /home/$USER/Desktop
chmod +x launcher.desktop

cd /home/$USER/launcher_app
chmod +x launcher.sh