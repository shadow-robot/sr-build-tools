FROM shadowrobot/dexterous-hand:indigo-night-build

LABEL Description="This ROS Indigo image contains Shadow's dexterous hand software with build tools. It includes IDE environments. Intel compatible" Vendor="Shadow Robot" Version="1.0"

RUN \
  apt-get update && \
  apt-get -y install libgl1-mesa-glx libgl1-mesa-dri && \
  rm -rf /var/lib/apt/lists/* && \
  usermod -a -G video user
