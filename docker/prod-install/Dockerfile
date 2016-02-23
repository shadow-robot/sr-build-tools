#
# ROS Indigo Shadow's production machine
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM ubuntu:14.04

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This is sample production machine image" Vendor="Shadow Robot" Version="1.0"

RUN locale-gen en_US.UTF-8
RUN apt-get install curl -y

# Installing production machine the first time
RUN curl -L bit.ly/prod-install | bash -s indigo-devel

# Installing production machine the second time
RUN curl -L bit.ly/prod-install | bash -s indigo-devel

