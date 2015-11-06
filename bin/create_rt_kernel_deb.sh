#!/bin/bash

KERNEL_VERSION="4.1.10"

# https://www.debian.org/releases/stable/i386/ch08s06.html.en
sudo apt-get install kernel-package fakeroot

cd linux-${KERNEL_VERSION}/
make-kpkg clean
# set concurrency to all cores but one
export CONCURRENCY_LEVEL=$(expr $(grep -c ^processor /proc/cpuinfo) - 1)
sudo fakeroot make-kpkg --initrd --revision=1.0.custom kernel_image
