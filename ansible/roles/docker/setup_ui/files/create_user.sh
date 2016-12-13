#!/usr/bin/env bash

set -e # fail on errors
# set -x # echo commands run

export USERNAME=$1
export USER_PASSWORD=$2
export ROS_RELEASE=${3:-indigo}

echo "Adding user"
useradd -m $USERNAME
echo "$USERNAME:$USER_PASSWORD" | chpasswd
usermod --shell /bin/bash $USERNAME
usermod -aG sudo $USERNAME
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME
chmod 0440 /etc/sudoers.d/$USERNAME

echo "Setup .bashrc for ROS"
echo "source /opt/ros/${ROS_RELEASE}/setup.bash" >> /home/$USERNAME/.bashrc
#Fix for qt and X server errors
echo "export QT_X11_NO_MITSHM=1" >> /home/$USERNAME/.bashrc
# cd to home on login
echo "cd" >> /home/$USERNAME/.bashrc
