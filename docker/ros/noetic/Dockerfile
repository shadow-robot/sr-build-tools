#
# ROS Noetic with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM ros:noetic-robot

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This image is used to make ROS Noetic based projects build faster using build tools" Vendor="Shadow Robot" Version="1.0"

ENV DEBIAN_FRONTEND noninteractive

ENV PULSE_SERVER /run/pulse/native
ENV GOSU_VERSION 1.10
ENV MY_USERNAME user
ARG toolset_branch
ENV toolset_branch ${toolset_branch:-"master"}
ENV server_type="docker_hub"
ENV used_modules="check_cache,create_workspace"
ENV ros_release_name=noetic
ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/sr-run-ci-build.sh"
ENV quality_of_life_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/sr_quality_of_life.sh"

ENV remote_additional_bashrc_cmds="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/docker/utils/additional_bashrc_cmds_noetic"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY terminator_config /tmp/terminator_config

########################################################################################################################
# Temporary fix for expired ROS GPG key issue as of 01/06/2025 (https://github.com/osrf/docker_images/issues/807)
# Can be removed once upstream ros base images have been fixed.
########################################################################################################################
RUN rm /etc/apt/sources.list.d/ros1-latest.list && \
    rm /usr/share/keyrings/ros1-latest-archive-keyring.gpg

RUN apt-get update && \
    apt-get install -y ca-certificates curl

ENV ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')

RUN curl -L -s -o /tmp/ros-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb" && \
    apt-get update \
    apt-get install /tmp/ros-apt-source.deb \
    rm -f /tmp/ros-apt-source.deb

RUN apt-get update && \
    apt-get install -y ros-noetic-roscpp-tutorials
########################################################################################################################

RUN set -x && \
    \
    echo "Installing wget" && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates wget sudo curl && \
    apt-get install -y bash-completion && \
    apt-get install -y gdb && \
    \
    echo "Running one-liner" && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    /tmp/oneliner "$toolset_branch" $server_type 'setup_docker_user' && \
    gosu $MY_USERNAME /tmp/oneliner "$toolset_branch" $server_type $used_modules && \
    \
    echo "Updating bash commands" && \
    wget -O /tmp/additional_bashrc_cmds "$( echo "$remote_additional_bashrc_cmds" | sed 's/#/%23/g' )" && \
    cat /tmp/additional_bashrc_cmds >> /home/user/.bashrc && \
    \
    echo "Installing and configuring additional quality-of-life tools" && \
    wget -O /tmp/quality_of_life_setup "$( echo "$quality_of_life_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/quality_of_life_setup && \
    gosu $MY_USERNAME /tmp/quality_of_life_setup --user ${MY_USERNAME} && \
    \
    echo "Setting default terminator config" && \
    mkdir -p /home/$MY_USERNAME/.config/terminator/ && \
    mv /tmp/terminator_config /home/$MY_USERNAME/.config/terminator/config && \
    chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.config &&\
    \
    echo "Creating XDG_RUNTIME_DIR to avoid rqt black windows" && \
    mkdir -p /run/$MY_USERNAME/1000 && \
    chmod 0700 /run/$MY_USERNAME/1000 && \
    chown 1000:1000 /run/$MY_USERNAME/1000 && \
    export XDG_RUNTIME_DIR=/run/$MY_USERNAME/1000 && \
    \
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/workspace/build_isolated /home/$MY_USERNAME/workspace/devel_isolated /home/$MY_USERNAME/workspace/src/roslint /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig /home/$MY_USERNAME/.cache

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
