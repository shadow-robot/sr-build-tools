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
    -e|--ethercatinterface)
    ETHERCAT_INTERFACE="$2"
    shift
    ;;
    -b|--configbranch)
    CONFIG_BRANCH="$2"
    shift
    ;;
    -g|--nvidiagraphics)
    NVIDIA="$2"
    shift
    ;;
    -s|--startcontainer)
    START_CONTAINER="$2"
    shift
    ;;
    -sn|--shortcutname)
    DESKTOP_SHORTCUT_NAME="$2"
    shift
    ;;
    *)
    # ignore unknown option
    ;;
esac
shift
done

# Default values
if [ -z "${REINSTALL_DOCKER_CONTAINER}" ];
then
    REINSTALL_DOCKER_CONTAINER=false
fi

if [ -z "${DESKTOP_ICON}" ];
then
    DESKTOP_ICON=true
fi

if [ -z "${NVIDIA}" ];
then
    NVIDIA=false
fi

if [ -z "${START_CONTAINER}" ];
then
    START_CONTAINER=false
fi

if [ -z "${DESKTOP_SHORTCUT_NAME}" ];
then
    DESKTOP_SHORTCUT_NAME=Shadow_Hand_Launcher
fi


echo "================================================================="
echo "|                                                               |"
echo "|             Shadow default docker deployment                  |"
echo "|                                                               |"
echo "================================================================="
echo ""
echo "possible options: "
echo "  * -i or --image               Name of the Docker hub image to pull"
echo "  * -u or --user                Docker hub user name"
echo "  * -p or --password            Docker hub password"
echo "  * -r or --reinstall           Flag to know if the docker container should be fully reinstalled (false by default)"
echo "  * -n or --name                Name of the docker container"
echo "  * -e or --ethercatinterface   Ethercat interface of the hand"
echo "  * -g or --nvidiagraphics      Enable nvidia-docker"
echo "  * -d or --desktopicon         Generates a desktop icon to launch the hand"
echo "  * -b or --configbranch        Specify the branch for the specific hand (Only for dexterous hand)"
echo "  * -sn or --shortcutname       Specify the name for the desktop icon (default: Shadow_Hand_Launcher)"
echo ""
echo "example hand E: ./launch.sh -i shadowrobot/dexterous-hand:kinetic -n hand_e_kinetic_real_hw -e enp0s25 -b shadowrobot_demo_hand -r true -g false"
echo "example agile-grasper: ./launch.sh -i shadowrobot/agile-grasper:kinetic-release -n agile_grasper -e enp0s25 -r true -g false -u mydockerhublogin -p mysupersecretpassword"

echo ""
echo "image name        = ${DOCKER_IMAGE_NAME}"
echo "container name    = ${DOCKER_CONTAINER_NAME}"
echo "reinstall flag    = ${REINSTALL_DOCKER_CONTAINER}"

# From ANSI escape codes we have the following colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z ${DOCKER_IMAGE_NAME} ] || [ -z ${DOCKER_CONTAINER_NAME} ]; then
    echo -e "${RED}Docker image name and name of container are required ${NC}"
    exit 1
fi

if [ ${NVIDIA} = false ]; then
    DOCKER="docker"
else
    DOCKER="nvidia-docker"
fi

HAND_E_NAME="dexterous-hand"
HAND_H_NAME="agile-grasper"

# Check if they have specified the ethercat interface
if [ -z ${ETHERCAT_INTERFACE} ] ; then
    echo -e "${RED}Ethercat interface ID needs to be specified ${NC}"
    exit 1
fi

if echo "${DOCKER_IMAGE_NAME}" | grep -q "${HAND_E_NAME}"; then
    echo "Hand E/G image requested"
    HAND_H=false
    HAND_ICON=hand_E.png
elif echo "${DOCKER_IMAGE_NAME}" | grep -q "${HAND_H_NAME}"; then
    echo "Hand H image requested"
    HAND_H=true
    HAND_ICON=hand_H.png
else
    echo -e "${RED}Unknown image requested ${NC}"
    HAND_H=""
    exit 1
fi

echo ""
echo " -----------------------------------"
echo " |   Checking docker installation  |"
echo " -----------------------------------"
echo ""

if [ -x "$(command -v docker)" ]; then
    echo "Docker installed"
else
    echo "Installing docker"
    if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"xenial"* ]]; then
        echo "Ubuntu version: Xenial"
        sudo apt-get update
        sudo apt-get install  -y \
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
        sudo apt-get install -y docker-ce
        
        if ! grep -q docker /etc/group ; then
            sudo groupadd docker
        fi

        sudo usermod -aG docker $USER
    elif [[ $(cat /etc/*release | grep VERSION_CODENAMEe) = *"trusty"* ]]; then
        echo "Ubuntu version: Trusty"
        sudo apt-get update
        sudo apt-get -y install docker.io
        ln -sf /usr/bin/docker.io /usr/local/bin/docker
        sed -i '$acomplete -F _docker docker' /etc/bash_completion.d/docker.io
        update-rc.d docker.io defaults
    else
        echo -e "${RED}Unsupported ubuntu version! ${NC}"
        exit 1
    fi
fi

if [ ${NVIDIA} = true ]; then
    sudo apt-get install -y nvidia-docker
fi

# Log in to docker only for hand h images
function docker_login
{
    if [ ${HAND_H} = true ]; then
        echo "Logging in to docker "
        for i in 'seq 1 3';
        do
            if [ -z ${DOCKER_HUB_USER} ]; then
                echo "Docker username not specified"
                docker login
            else
                echo "Docker username specified"
                if [ -z ${DOCKER_HUB_PASSWORD} ]; then
                    docker login --username ${DOCKER_HUB_USER}
                else
                    docker login --username ${DOCKER_HUB_USER} --password ${DOCKER_HUB_PASSWORD}
                fi
            fi
            if [ $? == 0 ]; then
                break
            fi
            if [ ${i} == 3 and $? !=0 ]; then
                echo -e "${RED}Docker login failed. You will not be able to pull private docker images.${NC}"
                exit 1
            fi
        done
    fi
}

# If running for the first time create desktop shortcut
APP_FOLDER=/home/$USER/.launcher_app
BUILD_TOOLS_BRANCH=master
if [ ${DESKTOP_ICON} = true ] ; then
    echo ""
    echo " -------------------------------"
    echo " |   Making desktop shortcut   |"
    echo " -------------------------------"
    echo ""

    echo "Creating launcher folder"
    if [ ! -d "${APP_FOLDER}" ]; then
      mkdir ${APP_FOLDER}
    fi

    cd ${APP_FOLDER}

    if [ ! -d "${DESKTOP_SHORTCUT_NAME}" ]; then
      mkdir ${DESKTOP_SHORTCUT_NAME}
    fi

    cd ..

    # Create a initial script for dexterous hand
    if [ ${HAND_H} = false ]; then
        if [ -z "${CONFIG_BRANCH}" ]; then
            echo -e "${RED}Specify a config branch for your dexterous hand ${NC}"
            exit 1
        else
            printf "#! /bin/bash
            source /home/user/projects/shadow_robot/base/devel/setup.bash
            roscd sr_ethercat_hand_config
            git fetch
            git checkout ${CONFIG_BRANCH}

            # Changing ethernet interface
            sed -i 's|eth_port\" value=.*|eth_port\" value=\"${ETHERCAT_INTERFACE}\" />|' \$(rospack find sr_ethercat_hand_config)/launch/sr_rhand.launch

            roslaunch sr_ethercat_hand_config sr_rhand.launch
            " > ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_dexterous_hand.sh
            chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_dexterous_hand.sh
        fi
    fi

    if [ -e ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/launch.sh ]; then
        rm ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/launch.sh
    fi
    echo "Downloading the script"
    curl "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/launch.sh" >> ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/launch.sh
    
    echo "Checking if terminator installed"
    if [ -x "$(command -v terminator)" ]; then
        echo "terminator installed"
    else
        echo "No terminator. Installing..."
        sudo apt update
        sudo apt install -y terminator
    fi
    
    echo "Creating executable file"
    printf "#! /bin/bash
    terminator -x bash -c \"cd ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}; ./launch.sh -i ${DOCKER_IMAGE_NAME} -n ${DOCKER_CONTAINER_NAME} -e ${ETHERCAT_INTERFACE} -r false -d false -s true\"" > ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/launcher_exec.sh

    echo "Downloading icon"
    wget --no-check-certificate https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/${HAND_ICON} -O ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/${HAND_ICON}

    echo "Creating desktop file"
    printf "[Desktop Entry]
    Version=1.0
    Name=${DESKTOP_SHORTCUT_NAME}
    Comment=This is application launches the hand
    Exec=/home/${USER}/.launcher_app/${DESKTOP_SHORTCUT_NAME}/launcher_exec.sh
    Icon=/home/${USER}/.launcher_app/${DESKTOP_SHORTCUT_NAME}/${HAND_ICON}
    Terminal=false
    Type=Application
    Categories=Utility;Application;" > /home/$USER/Desktop/${DESKTOP_SHORTCUT_NAME}.desktop

    echo "Allowing files to be executable"
    chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/launcher_exec.sh
    chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/launch.sh
    chmod +x /home/$USER/Desktop/${DESKTOP_SHORTCUT_NAME}.desktop
fi

if [ ${REINSTALL_DOCKER_CONTAINER} = false ] ; then
   echo "Not reinstalling docker image"
   if [ ! "$(docker ps -q -f name=^/${DOCKER_CONTAINER_NAME}$)" ]; then
        if [ "$(docker ps -aq -f name=^/${DOCKER_CONTAINER_NAME}$)" ]; then
            echo "Container with specified name already exists."
        else
            if [[ "$(docker images -q ${DOCKER_IMAGE_NAME} 2> /dev/null)" == "" ]]; then
                # Image doesn't exist, pull it
                docker_login
                docker pull ${DOCKER_IMAGE_NAME}
                if [ ${NVIDIA} = true ]; then
                    if [[ "$(docker images -q "${DOCKER_IMAGE_NAME}-nvidia" 2> /dev/null)" == "" ]]; then
                        bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/docker/utils/docker_nvidialize.sh) ${DOCKER_IMAGE_NAME}
                    fi
                    DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME}-nvidia"
                fi
            fi
            echo "Creating the container"
            if [ ${HAND_H} = true ]; then
                ${DOCKER} create -it --privileged --name ${DOCKER_CONTAINER_NAME} -e verbose=true -e interface=${ETHERCAT_INTERFACE} --network=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME} terminator -x bash -c "/usr/local/bin/setup.sh && bash || bash"
            else
                ${DOCKER} create -it --privileged --name ${DOCKER_CONTAINER_NAME} --network=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME} terminator -x bash -c "/usr/local/bin/setup_dexterous_hand.sh && bash || bash"
                docker cp ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_dexterous_hand.sh ${DOCKER_CONTAINER_NAME}:/usr/local/bin/setup_dexterous_hand.sh
            fi
        fi
   else
        echo -e "${RED}Container already running ${NC}"
        exit 1
   fi
else
    echo "Reinstalling docker container"
    if [ "$(docker ps -aq -f name=^/${DOCKER_CONTAINER_NAME}$)" ]; then
        echo "Container with specified name already exist. Removing container"
        docker rm -f ${DOCKER_CONTAINER_NAME}
    fi
    echo "Pulling latest version of docker image"
    docker_login
    docker pull ${DOCKER_IMAGE_NAME}
    if [ ${NVIDIA} = true ]; then
        if [[ "$(docker images -q "${DOCKER_IMAGE_NAME}-nvidia" 2> /dev/null)" == "" ]]; then
            bash <(curl -Ls https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/docker/utils/docker_nvidialize.sh) ${DOCKER_IMAGE_NAME}
        fi
        DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME}-nvidia"
    fi

    echo "Running the container"
    if [ ${HAND_H} = true ]; then
        ${DOCKER} create -it --privileged --name ${DOCKER_CONTAINER_NAME} -e verbose=true -e interface=${ETHERCAT_INTERFACE} --network=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME} terminator -x bash -c "/usr/local/bin/setup.sh && bash || bash"
    else
        ${DOCKER} create -it --privileged --name ${DOCKER_CONTAINER_NAME} --network=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME} terminator -x bash -c "/usr/local/bin/setup_dexterous_hand.sh && bash || bash"
        docker cp ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_dexterous_hand.sh ${DOCKER_CONTAINER_NAME}:/usr/local/bin/setup_dexterous_hand.sh
    fi
fi

echo ""
echo -e "${GREEN} ------------------------------------------------${NC}"
echo -e "${GREEN} |            Operation completed               |${NC}"
echo -e "${GREEN} ------------------------------------------------${NC}"
echo ""

if [ ${START_CONTAINER} = true ]; then
    echo -e "${YELLOW}Please wait for docker container to start on a new terminal as this might take a while. ${NC}"
    echo -e "${YELLOW}This terminal will be closing soon...
    docker start ${DOCKER_CONTAINER_NAME}
    sleep 30
fi
