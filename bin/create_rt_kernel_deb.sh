#!/bin/bash
# 1) Replace with kernel version
KERNEL_VERSION="x.x.x"

# https://www.debian.org/releases/stable/i386/ch08s06.html.en
sudo apt-get install kernel-package fakeroot libssl-dev dpkg-dev libelf-dev

cd linux-${KERNEL_VERSION}/
make clean

# set concurrency to all cores but one
export CONCURRENCY_LEVEL=$(expr $(grep -c ^processor /proc/cpuinfo) - 1)

# 2)a) on systems prior to 22.04 run below
#sudo fakeroot make-kpkg --initrd --revision=1.0.custom kernel_image

#2)b) on systems 22.04 and up run
#sudo fakeroot make bindeb-pkg
