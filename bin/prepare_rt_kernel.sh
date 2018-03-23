#!/bin/bash

RT_PATCH_DIR="4.4"
RT_PATCH_VERSION="4.4.70-rt83"
KERNEL_DIR="v4.x"
KERNEL_VERSION="4.4.73"

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

# edit manually the RT_PREEMPT parameters:
# Processor type and features -> Preemption Model  set to Fully Preemptible Kernel (RT)
sudo apt-get install libncurses-dev
make menuconfig
#or
#make xconfig

# TODO find a way to edit the params on the .config file automatically 
