#!/bin/bash

KERNEL_VERSION="6.5.2"

# https://www.debian.org/releases/stable/i386/ch08s06.html.en
sudo apt-get install linux-source fakeroot libssl-dev libelf-dev debhelper libssl-dev zstd dpkg-dev dwarves

cd linux-${KERNEL_VERSION}/

scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS

# sudo make clean

# set concurrency to all cores but one
export CONCURRENCY_LEVEL=$(expr $(grep -c ^processor /proc/cpuinfo) - 1)
sudo fakeroot make -j $CONCURRENCY_LEVEL bindeb-pkg
