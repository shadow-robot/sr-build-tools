#
# Indigo with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM shadowrobot/dexterous-hand:indigo

RUN \
  sudo apt-get update && \
  sudo apt-get -y install libgl1-mesa-glx libgl1-mesa-dri && \
  sudo rm -rf /var/lib/apt/lists/* && \
  sudo usermod -a -G video user
