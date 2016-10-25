#
# ROS Indigo with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM ros:indigo

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This image is used to make ROS Indigo based projects build faster using build tools" Vendor="Shadow Robot" Version="1.0"

ENV DEBIAN_FRONTEND noninteractive

ENV toolset_branch="master"
ENV server_type="docker_hub"
ENV used_modules="check_cache,create_workspace"
ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/sr-run-ci-build.sh"

RUN echo "Setting up bash as default shell" && \
    rm /bin/sh && \
    ln -s /bin/bash /bin/sh && \
    echo "Setting locale" && \
    locale-gen en_US.UTF-8 && \
    echo "Installing curl" && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install curl -y && \
    echo "Running one-liner" && \
    (curl -s "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" | bash /dev/stdin "$toolset_branch" $server_type $used_modules) && \
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
