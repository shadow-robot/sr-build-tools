# How does it work

The build tools was created to run on the Docker based CI servers.
The Docker image for all build is one hosted on [Docker Hub](https://hub.docker.com/r/shadowrobot/ubuntu-ros-indigo-build-tools)

The build script is loading Ubuntu 14.04 Docker image with pre-installed ROS Indigo.
This image is dependent on Ubuntu and ROS repositories in Docker Hub which means that image is rebuild as soon as any of parent images changes.

The build tools also put special marker in the image which indicates that ROS was installed using their script and workspace was created as well.
Supported CI servers download latest version of the Docker image and run Ansible build tools inside.
Number of modules can be used based on the preferences of the developers.

