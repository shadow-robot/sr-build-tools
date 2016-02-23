#
# ROS Indigo Shadow's development machine
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM ubuntu:14.04

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This is sample developer's machine image" Vendor="Shadow Robot" Version="1.0"

RUN locale-gen en_US.UTF-8
RUN apt-get install curl -y

# Installing developer's machine the first time
RUN curl -L bit.ly/dev-machine | bash -s -- -w ~{{ros_user}}/projects/shadow_robot/base

# Installing developer's machine the second time
RUN curl -L bit.ly/dev-machine | bash -s -- -w ~{{ros_user}}/projects/shadow_robot/base
