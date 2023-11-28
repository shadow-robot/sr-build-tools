#!/bin/bash

RT_PATCH_DIR="6.5"
RT_PATCH_VERSION="6.5.2-rt8"
KERNEL_DIR="v6.x"
KERNEL_VERSION="6.5.2"

wget https://www.kernel.org/pub/linux/kernel/projects/rt/${RT_PATCH_DIR}/patch-${RT_PATCH_VERSION}.patch.xz
wget https://www.kernel.org/pub/linux/kernel/${KERNEL_DIR}/linux-${KERNEL_VERSION}.tar.xz
tar -xvJf linux-${KERNEL_VERSION}.tar.xz
cd linux-${KERNEL_VERSION}/
xzcat -dc ../patch-${RT_PATCH_VERSION}.patch.xz | patch -p1

# Prepare for compilation
make mrproper

# Copy the configuration from the current kernel. This will be the base for the new one.
cp /boot/config-`uname -r` .config

make olddefconfig

scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS

scripts/config --set-val CONFIG_HZ 1000
scripts/config --enable HZ_1000
scripts/config --disable HZ_250


# edit manually the RT_PREEMPT parameters:
# General Setup -> Preemption Model  set to Fully Preemptible Kernel (RT)
sudo apt-get install libncurses-dev flex
make menuconfig
#or
#make xconfig

# TODO find a way to edit the params on the .config file automatically 
