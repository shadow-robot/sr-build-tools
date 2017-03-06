This folder contains files necessary for building a Docker image for ARM architectures containing ROS kinetic core. It is based on [OSRF's ROS Kinetic Core x86 Dockerfile](https://github.com/osrf/docker_images/blob/master/ros/kinetic/kinetic-ros-core/Dockerfile), but inherits from [armhf/ubuntu:xenial](https://hub.docker.com/r/armhf/ubuntu/) rather than [ubuntu:xenial](https://hub.docker.com/_/ubuntu/). Note that it must be built on an ARM platform - you almost certainly cannot build it on your desktop/laptop! It has been built and pushed to [Docker Hub](https://hub.docker.com/r/shadowrobot/ros-kinetic-core-armhf/), so you can obtain it by running:

`docker pull shadowrobot/ros-kinetic-core-armhf`

on your ARM machine.

You could pull it to an x86 machine, but it would not run there!