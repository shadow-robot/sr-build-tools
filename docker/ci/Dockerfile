#
# ROS Indigo with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM ubuntu:14.04

MAINTAINER Shadow Robot''s Software Team <software@shadowrobot.com>

LABEL Description="This image is used to make ROS Indigo based projects build faster using build tools" Vendor="Shadow Robot" Version="1.0"

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install curl -y

ENV toolset_branch="F#114_add_docker_image"
ENV server_type="docker_hub"
ENV used_modules="check_cache,install,create_workspace"
ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/sr-run-ci-build.sh"

RUN curl -s "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" | bash /dev/stdin "$toolset_branch" $server_type $used_modules
