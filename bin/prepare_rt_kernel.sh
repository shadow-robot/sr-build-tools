#!/bin/bash

RT_PATCH_DIR="4.13"
RT_PATCH_VERSION="4.13.13-rt5"
KERNEL_DIR="v4.x"
KERNEL_VERSION="4.13.13"

# Double check the links here as they do change over time to include new paths i.e. kernel/projects/old/rt
wget https://www.kernel.org/pub/linux/kernel/projects/rt/${RT_PATCH_DIR}/patch-${RT_PATCH_VERSION}.patch.xz  --no 
wget https://www.kernel.org/pub/linux/kernel/${KERNEL_DIR}/linux-${KERNEL_VERSION}.tar.xz
tar -xvJf linux-${KERNEL_VERSION}.tar.xz
cd linux-${KERNEL_VERSION}/
xzcat -dc ../patch-${RT_PATCH_VERSION}.patch.xz | patch -p1

# Prepare for compilation
make mrproper

# Copy the configuration from the current kernel. This will be the base for the new one.
cp /boot/config-`uname -r` .config

make olddefconfig
# Setting systemkeys to avoid; No rule to make target 'debian/certs/test-signing-certs.pem' build error
scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
scripts/config --disable SYSTEM_REVOCATION_KEYS

# edit manually the RT_PREEMPT parameters:
# General Setup -> Preemption Model  set to Fully Preemptible Kernel (RT)
sudo apt-get install libncurses-dev
make menuconfig
#or
#make xconfig

# TODO find a way to edit the params on the .config file automatically 
