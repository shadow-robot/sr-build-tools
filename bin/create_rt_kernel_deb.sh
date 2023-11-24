#!/bin/bash

KERNEL_VERSION="6.5.2"

# https://www.debian.org/releases/stable/i386/ch08s06.html.en
sudo apt-get install linux-source fakeroot libssl-dev

cd linux-${KERNEL_VERSION}/
make clean

# set concurrency to all cores but one
export CONCURRENCY_LEVEL=$(expr $(grep -c ^processor /proc/cpuinfo) - 1)
sudo fakeroot make bindeb-pkg  
