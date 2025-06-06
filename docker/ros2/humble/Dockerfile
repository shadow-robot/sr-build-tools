#
# ROS2 humble with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM ros:humble-ros-base

LABEL Description="This image is used to make ROS2 humble based projects build faster using build tools" Vendor="Shadow Robot" Version="1.0"

ENV DEBIAN_FRONTEND noninteractive

ENV GOSU_VERSION 1.10
ENV MY_USERNAME user

ARG toolset_branch
ENV toolset_branch ${toolset_branch:-"master"}
ENV server_type="docker_hub"
ENV used_modules="check_cache,create_workspace"
ENV ros_release_name=humble
ENV ubuntu_version_name=jammy
ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/sr-run-ci-build.sh"

ENV remote_additional_bashrc_cmds="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/docker/utils/additional_bashrc_cmds_humble"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY terminator_config /tmp/terminator_config

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
