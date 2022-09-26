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
#set -x # echo commands run

docker_image=$1

mkdir -p /tmp/docker_nvidia_tmp
cd /tmp/docker_nvidia_tmp
touch Dockerfile

echo "FROM $docker_image" >> Dockerfile
echo "LABEL com.nvidia.volumes.needed=\"nvidia_driver\"" >> Dockerfile
echo "ENV PATH /usr/local/nvidia/bin:\${PATH}" >> Dockerfile
echo "ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:\${LD_LIBRARY_PATH}" >> Dockerfile

docker build --tag "$docker_image-nvidia" .

cd
rm -rf /tmp/docker_nvidia_tmp
