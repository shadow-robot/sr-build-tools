#!/bin/bash

#
# Boot strap a shadow hand environment.
# It is safe to run this script multiple times.
#

set -e # Stop on errors
#set -x # echo commands

# Get access to the build tools. This should have been mounted as a shared
# folder by Vagrantfile
PATH="$PATH:/opt/shadow/sr-build-tools/bin"
echo PATH:$PATH

hand_user="hand"
hand_password="hand"
hand_user_email="software@shadowrobot.com"
hand_home="/home/$hand_user"
build_tools_dir="/opt/shadow/sr-build-tools"
export ros_release='hydro'
apt_opt="-q --yes"

# Options
usage() {
    echo Usage: $0 "[-jHOST]"
    echo
    echo ' -r ROS version to install. Default: hydro'
    echo
    exit 0
}
while getopts "hj:" opt; do
    case $opt in
        '?'|h|:|\?)
            usage
        ;;
        r)
            ros_release=$OPTARG
        ;;
    esac
done
shift $((OPTIND-1))

# Are we root?
if [ "$(id -u)" != "0" ]; then
    echo "Not root!"
    exit 10
fi

#
# Setup apt sources etc for installing ros
# http://wiki.ros.org/hydro/Installation/Ubuntu

# Set the "seen" flag for debconf questions that --yes fails for.
# cluster is still non-interactive, see above.
# Except you can't set the "seen" flag for something that isn't installed
#cat <<EOF | debconf-set-selections
##gdm     shared/default-x-display-manager seen true
#hddtemp hddtemp/daemon seen true
#EOF

echo Activating restricted, universe, multiverse
release=$(lsb_release -sc)
bak_file=""
sed -i".bak-$(date +'%Y%m%d-%H%M%S')" "s/^#\(deb.*$release\(-updates\)\? \(restricted\|universe\|multiverse\)\)/\1/" /etc/apt/sources.list
# Add ros repo
echo "deb http://packages.ros.org/ros/ubuntu $release main" > /etc/apt/sources.list.d/ros-latest.list

echo Adding the ros key
wget http://packages.ros.org/ros.key -O - | sudo apt-key add -

echo Updating apt
apt-get update $apt_opt
apt-get dist-upgrade $apt_opt

echo Installing packages
# git  - to setup user, grab shadow code
# python-yaml - handy for the build tools
apt-get install $apt_opt git qgit python-yaml ntp acpid
apt-get install $apt_opt python-wstool
apt-get install $apt_opt screen tmux terminator

echo Converting vagrant base image to desktop system
apt-get install $apt_opt ubuntu-desktop


#
# Bootstrap ROS
#
echo Installing ROS $version 
apt-get install $apt_opt ros-$ros_release-desktop-full 

source /opt/ros/$ros_release/setup.bash
if [ ! -f "/etc/ros/rosdep/sources.list.d/20-default.list" ]; then
    rosdep init
fi


#
# Setup hand user
#

if [ -d "$hand_home" ]; then
    echo Using existing $hand_home. Assuming user is $hand_user.
else
    adduser --home "$hand_home" --disabled-login --gecos='Shadow Hand,,,' $hand_user
    echo "$hand_user:$hand_password" | chpasswd
    echo Added user $hand_user
fi

# Give no password sudo access.
sudoers-add "$hand_user  ALL=(ALL) NOPASSWD:  ALL"
echo Gave $hand_user sudo

# Do everything that needs doing as hand.
sudo su - $hand_user -c "bash /vagrant/bootstrap-hand-user.sh"

echo DONE
