#!/bin/bash

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

KERNEL_VERSION="4.13.13"

# https://www.debian.org/releases/stable/i386/ch08s06.html.en
sudo apt-get install kernel-package fakeroot libssl-dev

cd linux-${KERNEL_VERSION}/
make-kpkg clean
# set concurrency to all cores but one
export CONCURRENCY_LEVEL=$(expr $(grep -c ^processor /proc/cpuinfo) - 1)
sudo fakeroot make-kpkg --initrd --revision=1.0.custom kernel_image
