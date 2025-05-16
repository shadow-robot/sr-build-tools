#!/usr/bin/env bash

# Copyright 2022 Shadow Robot Company Ltd.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
usermod -aG systemd-journal $USERNAME
usermod -aG video $USERNAME
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME
chmod 0440 /etc/sudoers.d/$USERNAME

echo "Setup .bashrc for ROS"
echo "source /opt/ros/${ROS_RELEASE}/setup.bash" >> /home/$USERNAME/.bashrc
#Fix for qt and X server errors
echo "export QT_X11_NO_MITSHM=1" >> /home/$USERNAME/.bashrc
# cd to home on login
echo "cd" >> /home/$USERNAME/.bashrc
