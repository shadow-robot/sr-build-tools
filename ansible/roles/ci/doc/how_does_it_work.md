# How does it work

The build tools were created to run on the [Docker](https://www.docker.com/) based CI servers.
The Docker image for all builds are hosted on [Docker Hub](https://hub.docker.com/r/shadowrobot/ubuntu-ros-indigo-build-tools)

The build script is loading Ubuntu 14.04 Docker image with pre-installed ROS Indigo.
This image is dependent on Ubuntu and ROS repositories in the Docker Hub, which means that the image is rebuild as soon as any of parent images change.

The build tools also put a special marker in the image, which indicates that ROS was installed using their script and the workspace was created as well.
The supported CI servers download the latest version of the Docker image and run Ansible build tools inside.
The developers can choose which modules to use.
