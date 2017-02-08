#
# ROS Indigo with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM shadowrobot/build-tools:trusty-indigo-ide

LABEL Description="This image is used to make ROS Indigo based projects build faster using build tools. It includes IDE environments. Nvidia compatible" Vendor="Shadow Robot" Version="1.0"

# nvidia-docker hooks
LABEL com.nvidia.volumes.needed="nvidia_driver"

ENV PATH /usr/local/nvidia/bin:${PATH}

ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}

