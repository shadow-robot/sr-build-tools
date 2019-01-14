#!/usr/bin/env bash

#set -x # debug
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
    -o|--optoforce)
    OPTOFORCE_BRANCH=$(echo "$2" | sed 's/#/%23/g')
    shift
    ;;
    -l|--launchhand)
    LAUNCH_HAND="$2"
    shift
    ;;
    -bt|--buildtoolsbranch)
    BUILD_TOOLS_BRANCH=$(echo "$2" | sed 's/#/%23/g')
    shift
    ;;
    -ck|--customerkey)
    CUSTOMER_KEY="$2"
    shift
    ;;
    -cg|--cyberglove)
    SR_CYBERGLOVE_CONFIG_BRANCH=$(echo "$2" | sed 's/#/%23/g')
    shift
    ;;
    -de|--demo_icons)
    DEMO_ICONS="$2"
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

if [ -z "${OPTOFORCE_BRANCH}" ];
then
    OPTOFORCE_BRANCH=false
fi

if [ -z "${LAUNCH_HAND}" ];
then
    LAUNCH_HAND=true
fi

if [[ ${OPTOFORCE_BRANCH} = false ]];
then
    OPTOFORCE=false
    OPTOFORCE_PATH=""
else
    OPTOFORCE=true
    OPTOFORCE_PATH="-v=/dev/optoforce:/dev/optoforce"
fi

if [ -z "${BUILD_TOOLS_BRANCH}" ];
then
    BUILD_TOOLS_BRANCH="master"
fi

if [[ ${CUSTOMER_KEY} = true ]];
then
    echo "Please enter your key for uploading logs to AWS:"
    read CUSTOMER_KEY
else
    CUSTOMER_KEY=false
fi

if [ -z "${SR_CYBERGLOVE_CONFIG_BRANCH}" ];
then
    SR_CYBERGLOVE_CONFIG_BRANCH=false
fi

if [ -z "${DEMO_ICONS}" ];
then
    DEMO_ICONS=false
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
echo "  * -g or --nvidiagraphics      Enable nvidia-docker (default: false)"
echo "  * -d or --desktopicon         Generates a desktop icon to launch the hand"
echo "  * -b or --configbranch        Specify the branch for the specific hand (Only for dexterous hand)"
echo "  * -sn or --shortcutname       Specify the name for the desktop icon (default: Shadow_Hand_Launcher)"
echo "  * -o or --optoforce           Specify if optoforce sensors are going to be used with a branch name (default: false)"
echo "  * -l or --launchhand          Specify if hand driver should start when double clicking desktop icon (default: true)"
echo "  * -bt or --buildtoolsbranch   Specify the Git branch for sr-build-tools (default: master)"
echo "  * -ck or --customerkey        Flag to prompt for customer key for uploading files to AWS"
echo "  * -cg or --cyberglove         Specify the branch of sr_cyberglove_config for cyberglove configuration (default: false)"
echo "  * -de or --demo_icons         Generates desktop icons to run demos (default: false)"
echo ""
echo "example hand E: ./launch.sh -i shadowrobot/dexterous-hand:kinetic -n hand_e_kinetic_real_hw -e enp0s25 -b shadowrobot_demo_hand -r true -g false"
echo "example hand H: ./launch.sh -i shadowrobot/flexible-hand:kinetic-release -n modular_grasper -e enp0s25 -r true -g false"

echo ""
echo "image name        = ${DOCKER_IMAGE_NAME}"
echo "container name    = ${DOCKER_CONTAINER_NAME}"
echo "reinstall flag    = ${REINSTALL_DOCKER_CONTAINER}"
echo "build tools branch = ${BUILD_TOOLS_BRANCH}"

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
HAND_H_NAME="flexible-hand"

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

if [ -x "$(command -v curl)" ]; then
    echo "curl installed"
else
    sudo apt-get update
    sudo apt-get install  -y curl
fi

if [ -x "$(command -v docker)" ]; then
    echo "Docker installed"
else
    echo "Installing docker"
    if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"xenial"* ]] || \
       [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* ]]; then
        if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* ]]; then
          echo "Ubuntu version: Bionic (18.04)"
          if [ -x "$(command -v xterm)" ]; then
            echo "xterm installed"
          else
            sudo apt-get update
            sudo apt-get install -y xterm
          fi
        else
          echo "Ubuntu version: Xenial (16.04)"
        fi
        sudo apt-get update
        sudo apt-get install  -y \
        apt-transport-https \
        ca-certificates \
        software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository \
             "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
             $(lsb_release -cs) \
             stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce
        if [ ! $(getent group docker) ]; then
            sudo groupadd docker
        fi

        sudo usermod -aG docker $USER
        echo ""
        echo " ---------------------------------------------------------------------------------------------------------"
        echo " |   Docker installed. Please reboot and re-run the one-liner again to resume the installation    |"
        echo " ---------------------------------------------------------------------------------------------------------"
        echo ""
        exit 0
    elif [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"trusty"* ]]; then
        echo "Ubuntu version: Trusty (12.04)"
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

function optoforce_setup
{
    cd ${APP_FOLDER}
    if [ ! -d "optoforce" ]; then
        echo ""
        echo " ---------------------------"
        echo " |   Setting up optoforce   |"
        echo " ---------------------------"
        echo ""

        echo "Cloning optoforce package..."
        git clone https://github.com/shadow-robot/optoforce.git
    fi

    if [ ! -f "/etc/udev/rules.d/optoforce.rules" ]; then
        cd ${APP_FOLDER}/optoforce/optoforce
        sed -i "s|/PATH/TO|${APP_FOLDER}|g" optoforce.rules
        sudo cp optoforce.rules /etc/udev/rules.d/
        cd ${APP_FOLDER}/optoforce/optoforce/src/optoforce
        chmod +x get_serial.py
        sudo udevadm control --reload-rules
        sudo udevadm trigger
    fi
}

function create_hand_e_icons
{
    echo "Creating Hand E/G demo icons desktop files"

    if [ ! ${SR_CYBERGLOVE_CONFIG_BRANCH} = false ]; then
        wget --no-check-certificate https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/cyberglove.png -O ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/cyberglove.png
        printf "docker exec -it ${DOCKER_CONTAINER_NAME} /ros_entrypoint.sh bash -c 'source /home/user/projects/shadow_robot/base_deps/devel/setup.bash;source /home/user/projects/shadow_robot/base/devel/setup.bash;roslaunch sr_cyberglove_config cyberglove.launch'" > ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/cyberglove_demo.sh
        chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/cyberglove_demo.sh
        printf "[Desktop Entry]
                Version=1.0
                Name=Cyberglove Demo
                Comment=This runs the cyber glove demo
                Exec=xterm -title 'cyberglove_demo' -e '${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/cyberglove_demo.sh'
                Icon=${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/cyberglove.png
                Terminal=false
                Type=Application
                Categories=Utility;Application;" > /home/$USER/Desktop/Cyberglove_demo.desktop
                chmod +x /home/$USER/Desktop/Cyberglove_demo.desktop
                if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* ]]; then
                    gio set /home/$USER/Desktop/Cyberglove_demo.desktop "metadata::trusted" yes
                fi
                
    fi

    wget --no-check-certificate https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/close_hand_icon.png -O ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/close_hand_icon.png
    printf "docker exec -it ${DOCKER_CONTAINER_NAME} /ros_entrypoint.sh bash -c 'source /home/user/projects/shadow_robot/base_deps/devel/setup.bash;source /home/user/projects/shadow_robot/base/devel/setup.bash;rosrun sr_ethercat_hand_config demo_rs.py'" > ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/close_hand.sh
    chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/close_hand.sh
    printf "[Desktop Entry]
            Version=1.0
            Name=Close Hand
            Comment=This runs closes the hand for transportation
            Exec=xterm -title 'close_hand' -e '${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/close_hand.sh'
            Icon=${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/close_hand_icon.png
            Terminal=false
            Type=Application
            Categories=Utility;Application;" > /home/$USER/Desktop/Close_hand.desktop
            chmod +x /home/$USER/Desktop/Close_hand.desktop
            if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* ]]; then
                gio set /home/$USER/Desktop/Close_hand.desktop "metadata::trusted" yes
            fi
        
    wget --no-check-certificate https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/demo_hand_icon.png -O ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/demo_hand_icon.png
    printf "docker exec -it ${DOCKER_CONTAINER_NAME} /ros_entrypoint.sh bash -c 'source /home/user/projects/shadow_robot/base_deps/devel/setup.bash;source /home/user/projects/shadow_robot/base/devel/setup.bash;rosrun sr_ethercat_hand_config demo_r.py'" > ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/demo_hand.sh
    chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/demo_hand.sh
    printf "[Desktop Entry]
            Version=1.0
            Name=Demo Hand
            Comment=This runs the basic demo for the hand
            Exec=xterm -hold -title 'demo_hand' -e '${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/demo_hand.sh'
            Icon=${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/demo_hand_icon.png
            Terminal=false
            Type=Application
            Categories=Utility;Application;" > /home/$USER/Desktop/Demo_hand.desktop
            chmod +x /home/$USER/Desktop/Demo_hand.desktop
            if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* ]]; then
                gio set /home/$USER/Desktop/Demo_hand.desktop "metadata::trusted" yes
            fi

    wget --no-check-certificate https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/open_hand_icon.png -O ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/open_hand_icon.png
    printf "docker exec -it ${DOCKER_CONTAINER_NAME} /ros_entrypoint.sh bash -c 'source /home/user/projects/shadow_robot/base_deps/devel/setup.bash;source /home/user/projects/shadow_robot/base/devel/setup.bash;rosrun sr_ethercat_hand_config demo_ro.py'" > ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/open_hand.sh
    chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/open_hand.sh
    printf "[Desktop Entry]
            Version=1.0
            Name=Open Hand
            Comment=This open the hand
            Exec=xterm -title 'open_hand' -e '${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/open_hand.sh'
            Icon=${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/open_hand_icon.png
            Terminal=false
            Type=Application
            Categories=Utility;Application;" > /home/$USER/Desktop/Open_hand.desktop
            chmod +x /home/$USER/Desktop/Open_hand.desktop
            if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* ]]; then
                gio set /home/$USER/Desktop/Open_hand.desktop "metadata::trusted" yes
            fi
}

function create_hand_h_icons
{
    echo "Creating Hand H demo icons desktop files"
    wget --no-check-certificate https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/demo_icon.png -O ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/demo_icon.png
    printf "[Desktop Entry]
            Encoding=UTF-8
            Name=Grasp looping demo
            Comment=This runs the Grasp looping demo
            Type=Link
            Icon=${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/demo_icon.png
            URL=http://127.0.0.1:8080/demos" > /home/$USER/Desktop/Grasp_loop_demo.desktop
            chmod +x /home/$USER/Desktop/Grasp_loop_demo.desktop
            if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* ]]; then
                gio set /home/$USER/Desktop/Grasp_loop_demo.desktop "metadata::trusted" yes
            fi
}


# If running for the first time create desktop shortcut
APP_FOLDER=/home/$USER/.shadow_launcher_app
SAVE_LOGS_APP_FOLDER=/home/$USER/.shadow_save_log_app

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

    echo "Creating save logs folder"
    if [ ! -d "${SAVE_LOGS_APP_FOLDER}" ]; then
      mkdir ${SAVE_LOGS_APP_FOLDER}
    fi

    cd ${SAVE_LOGS_APP_FOLDER}

    if [ ! -d "save_latest_ros_logs" ]; then
      mkdir "save_latest_ros_logs"
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
            if [ ! ${SR_CYBERGLOVE_CONFIG_BRANCH} = false ]; then
                if [ -d "/home/user/projects/shadow_robot/base/src/sr_config/sr_cyberglove_config" ]; then
                    rm -r /home/user/projects/shadow_robot/base/src/sr_config/sr_cyberglove_config
                fi
                cd /home/user/projects/shadow_robot/base/src
                if [ -d "sr_cyberglove_config" ]; then
                   cd sr_cyberglove_config
                   git pull;
                else
                    git clone https://github.com/shadow-robot/sr_cyberglove_config.git;
                    cd sr_cyberglove_config
                fi                
                git fetch
                git checkout ${SR_CYBERGLOVE_CONFIG_BRANCH}
            fi
            
            # Changing ethernet interface
            sed -i 's|eth_port\" value=.*|eth_port\" value=\"${ETHERCAT_INTERFACE}\" />|' \$(rospack find sr_ethercat_hand_config)/launch/sr_rhand.launch

            " > ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_dexterous_hand.sh

            if [ ${LAUNCH_HAND} = true ]; then
                printf "roslaunch sr_ethercat_hand_config sr_rhand.launch 2> >(tee -a ~/.ros/log/stderr.log >&2)" >> ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_dexterous_hand.sh
            fi
            chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_dexterous_hand.sh
        fi

        if [[ ${DEMO_ICONS} = true ]]; then
            echo "Downloading demo icon"
            wget --no-check-certificate https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/demo_icon.png -O ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/demo_icon.png
            create_hand_e_icons
        fi
    else
        # If LAUNCH_HAND = true for hand h, it uses the default script
        if [ ${LAUNCH_HAND} = false ]; then
            printf "#! /bin/bash
            source /home/user/projects/shadow_robot/base/devel/setup.bash
            sed -i 's|ethercat_port: .*|ethercat_port: ${ETHERCAT_INTERFACE}|' \$(rospack find fh_config)/hardware/hand_H_hardware.yaml
            if [ ! ${OPTOFORCE_BRANCH} = false ]; then
                cd /home/user/projects/shadow_robot/base/src
                if [ ! -d "fh_optoforce_config" ]; then
                    echo 'Cloning optoforce config repo...'
                    git clone https://github.com/shadow-robot/fh_optoforce_config.git
                    cd fh_optoforce_config
                    git checkout ${OPTOFORCE_BRANCH}
                fi
            fi
            " > ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_modular_grasper.sh
            chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_modular_grasper.sh
        fi
        if [ ${DEMO_ICONS} = true ]; then
            create_hand_h_icons
        fi
    fi

    if [ -e ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/launch.sh ]; then
        rm ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/launch.sh
    fi

    if [ -e ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/save_latest_ros_logs.sh ]; then
        rm ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/save_latest_ros_logs.sh
    fi

    echo "Downloading the launch script"
    curl "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/launch.sh" >> ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/launch.sh

    echo "Downloading the save_ros_logs script"
    curl "https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/utils/save_latest_ros_logs.sh" >> ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/save_latest_ros_logs.sh

    echo "Creating launch executable file"
    printf "#! /bin/bash
    exec -a shadow_launcher_app_xterm xterm -e \"cd ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}; ./launch.sh -i ${DOCKER_IMAGE_NAME} -n ${DOCKER_CONTAINER_NAME} -e ${ETHERCAT_INTERFACE} -r false -d false -s true\"" > ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/shadow_launcher_exec.sh

    echo "Creating save_ros_logs executable file"
    printf "#! /bin/bash
    exec -a shadow_save_log_app_xterm xterm -e \"cd ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs; ./save_latest_ros_logs.sh\"" > ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/shadow_save_log_exec.sh
    
    echo "Downloading launch icon"
    wget --no-check-certificate https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/${HAND_ICON} -O ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/${HAND_ICON}

    echo "Downloading save_ros_logs icon"
    wget --no-check-certificate https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/log_icon.png -O ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/log_icon.png

    mkdir -p /home/$USER/Desktop
    
    echo "Creating launch desktop file"
    printf "[Desktop Entry]
    Version=1.0
    Name=${DESKTOP_SHORTCUT_NAME}
    Comment=This is application launches the hand
    Exec=/home/${USER}/.shadow_launcher_app/${DESKTOP_SHORTCUT_NAME}/shadow_launcher_exec.sh
    Icon=/home/${USER}/.shadow_launcher_app/${DESKTOP_SHORTCUT_NAME}/${HAND_ICON}
    Terminal=false
    Type=Application
    Categories=Utility;Application;" > /home/$USER/Desktop/${DESKTOP_SHORTCUT_NAME}.desktop


    if [ ${CUSTOMER_KEY} = false ]; then
        echo "Creating save_ros_logs desktop file"
        printf "[Desktop Entry]
        Version=1.0
        Name=ROS_Logs_Saver
        Comment=This application saves latest ros logs file from running docker container
        Exec=/home/${USER}/.shadow_save_log_app/save_latest_ros_logs/shadow_save_log_exec.sh
        Icon=/home/${USER}/.shadow_save_log_app/save_latest_ros_logs/log_icon.png
        Terminal=false
        Type=Application
        Categories=Utility;Application;" > /home/$USER/Desktop/ROS_Logs_Saver.desktop
        chmod +x /home/$USER/Desktop/ROS_Logs_Saver.desktop
        if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* ]]; then
            gio set /home/$USER/Desktop/ROS_Logs_Saver.desktop "metadata::trusted" yes
        fi
    else
        echo "Creating save_and_upload_ros_logs desktop file"
        printf "[Desktop Entry]
        Version=1.0
        Name=ROS_Logs_Saver_And_Uploader
        Comment=This application saves and uploads to AWS latest ros logs file from running docker container
        Exec=/home/${USER}/.shadow_save_log_app/save_latest_ros_logs/shadow_save_log_exec.sh
        Icon=/home/${USER}/.shadow_save_log_app/save_latest_ros_logs/log_icon.png
        Terminal=false
        Type=Application
        Categories=Utility;Application;" > /home/$USER/Desktop/ROS_Logs_Saver_And_Uploader.desktop
        chmod +x /home/$USER/Desktop/ROS_Logs_Saver_And_Uploader.desktop
        if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* ]]; then
            gio set /home/$USER/Desktop/ROS_Logs_Saver_And_Uploader.desktop "metadata::trusted" yes
        fi
    fi
    echo "Allowing files to be executable"
    chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/shadow_launcher_exec.sh
    chmod +x ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/launch.sh
    chmod +x /home/$USER/Desktop/${DESKTOP_SHORTCUT_NAME}.desktop
    chmod +x ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/shadow_save_log_exec.sh
    chmod +x ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/save_latest_ros_logs.sh
    if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* ]]; then
        gio set /home/$USER/Desktop/${DESKTOP_SHORTCUT_NAME}.desktop "metadata::trusted" yes
    fi
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

            if [ ! ${OPTOFORCE_BRANCH} = false ]; then
                optoforce_setup
            fi

            echo "Creating the container"
            if [ ${HAND_H} = true ]; then
                if [ ${LAUNCH_HAND} = false ]; then
                    ${DOCKER} create -it --privileged --name ${DOCKER_CONTAINER_NAME} ${OPTOFORCE_PATH} -e verbose=true -e interface=${ETHERCAT_INTERFACE} --ulimit core=-1 --security-opt seccomp=unconfined --network=host --pid=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME} terminator -x bash -c "pkill -f \"^\"shadow_launcher_app_xterm && /usr/local/bin/setup_modular_grasper.sh && bash || bash"
                    docker cp ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_modular_grasper.sh ${DOCKER_CONTAINER_NAME}:/usr/local/bin/setup_modular_grasper.sh
                else
                    ${DOCKER} create -it --privileged --name ${DOCKER_CONTAINER_NAME} ${OPTOFORCE_PATH} -e verbose=true -e optoforce_launch=${OPTOFORCE} -e optofrc_branch=${OPTOFORCE_BRANCH} -e interface=${ETHERCAT_INTERFACE} --ulimit core=-1 --security-opt seccomp=unconfined --network=host --pid=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME} bash -c "pkill -f \"^\"shadow_launcher_app_xterm && xterm -e /usr/local/bin/setup.sh || bash"
                fi
            else
                ${DOCKER} create -it --privileged --name ${DOCKER_CONTAINER_NAME} ${OPTOFORCE_PATH} --ulimit core=-1 --security-opt seccomp=unconfined --network=host --pid=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME} terminator -x bash -c "pkill -f \"^\"shadow_launcher_app_xterm && /usr/local/bin/setup_dexterous_hand.sh && bash || bash"
                docker cp ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_dexterous_hand.sh ${DOCKER_CONTAINER_NAME}:/usr/local/bin/setup_dexterous_hand.sh
            fi
        fi
   else
        echo -e "${RED}Container already running! This window will be closed shortly... ${NC}"
        sleep 5
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

    if [ ! ${OPTOFORCE_BRANCH} = false ]; then
        if [ -d "${APP_FOLDER}/optoforce" ]; then
            rm -rf ${APP_FOLDER}/optoforce
            sudo rm /etc/udev/rules.d/optoforce.rules
        fi
        optoforce_setup
    fi

    echo "Creating the container"
    if [ ${HAND_H} = true ]; then
        if [ ${LAUNCH_HAND} = false ]; then
            ${DOCKER} create -it --privileged --name ${DOCKER_CONTAINER_NAME} ${OPTOFORCE_PATH} -e verbose=true -e interface=${ETHERCAT_INTERFACE} --ulimit core=-1 --security-opt seccomp=unconfined --network=host --pid=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME} terminator -x bash -c "pkill -f \"^\"shadow_launcher_app_xterm && /usr/local/bin/setup_modular_grasper.sh && bash || bash"
            docker cp ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_modular_grasper.sh ${DOCKER_CONTAINER_NAME}:/usr/local/bin/setup_modular_grasper.sh
        else
            ${DOCKER} create -it --privileged --name ${DOCKER_CONTAINER_NAME} ${OPTOFORCE_PATH} -e verbose=true -e optoforce_launch=${OPTOFORCE} -e optofrc_branch=${OPTOFORCE_BRANCH} -e interface=${ETHERCAT_INTERFACE} --ulimit core=-1 --security-opt seccomp=unconfined --network=host --pid=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME} bash -c "pkill -f \"^\"shadow_launcher_app_xterm && xterm -e /usr/local/bin/setup.sh || bash"
        fi
    else
        ${DOCKER} create -it --privileged --name ${DOCKER_CONTAINER_NAME} ${OPTOFORCE_PATH} --ulimit core=-1 --security-opt seccomp=unconfined --network=host --pid=host -e DISPLAY -e QT_X11_NO_MITSHM=1 -e LOCAL_USER_ID=$(id -u) -v /tmp/.X11-unix:/tmp/.X11-unix:rw ${DOCKER_IMAGE_NAME} terminator -x bash -c "pkill -f \"^\"shadow_launcher_app_xterm && /usr/local/bin/setup_dexterous_hand.sh && bash || bash"
        docker cp ${APP_FOLDER}/${DESKTOP_SHORTCUT_NAME}/setup_dexterous_hand.sh ${DOCKER_CONTAINER_NAME}:/usr/local/bin/setup_dexterous_hand.sh
    fi
fi

if [ ${CUSTOMER_KEY} = false ]; then
    echo "Skipping shadow_upload script because no customer key set"
else
    echo "Downloading the shadow_upload script"
    curl https://raw.githubusercontent.com/shadow-robot/sr-build-tools/${BUILD_TOOLS_BRANCH}/docker/utils/shadow_upload.sh > ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/shadow_upload.sh
    chmod +x ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/shadow_upload.sh
    docker cp ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/shadow_upload.sh ${DOCKER_CONTAINER_NAME}:/usr/local/bin/shadow_upload.sh
    rm ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/shadow_upload.sh
    echo "Creating customer key file"
    echo ${CUSTOMER_KEY} > ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/customer.key
    docker cp ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/customer.key ${DOCKER_CONTAINER_NAME}:/usr/local/bin/customer.key
    rm ${SAVE_LOGS_APP_FOLDER}/save_latest_ros_logs/customer.key   
fi

if [[ $(cat /etc/*release | grep VERSION_CODENAME) = *"bionic"* && $(ps -ef | grep "nautilus-desktop" | grep -v "grep" | wc -l) ]]; then
    if [[ ${DESKTOP_ICON} = true ||  ${DEMO_ICONS} = true ]]; then
        echo "Refreshing desktop..."
        killall nautilus-desktop &> /dev/null
        nautilus-desktop &> /dev/null &
    fi
fi

echo ""
echo -e "${GREEN} ------------------------------------------------${NC}"
echo -e "${GREEN} |            Operation completed               |${NC}"
echo -e "${GREEN} ------------------------------------------------${NC}"
echo ""

if [ ${START_CONTAINER} = true ]; then
    echo -e "${YELLOW}Please wait for docker container to start in a new terminal as this might take a while... ${NC}"
    docker start ${DOCKER_CONTAINER_NAME} &> /dev/null
    sleep infinity
fi
