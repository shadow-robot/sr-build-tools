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

docker_image=$1

mkdir -p /tmp/docker_nvidia_tmp
#cp /home/shadowop/sr-build-tools/docker/utils/10_nvidia.json /tmp/docker_nvidia_tmp/10_nvidia.json
cd /tmp/docker_nvidia_tmp
echo "{
    \"file_format_version\" : \"1.0.0\",
    \"ICD\" : {
        \"library_path\" : \"libEGL_nvidia.so.0\"
    }
}" >> 10_nvidia.json

touch Dockerfile

echo "FROM $docker_image

LABEL Description=\"This is updated to use OpenGL with nvidia-docker2\" Vendor=\"Shadow Robot\" Version=\"1.0\"

# Docker GPU access
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES all

# OpenGL using libglvnd
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        make \
        automake \
        autoconf \
        libtool \
        pkg-config \
        python \
        libxext-dev \
        libx11-dev \
        x11proto-gl-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/libglvnd

RUN git clone --branch=v1.0.0 https://github.com/NVIDIA/libglvnd.git . && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/x86_64-linux-gnu && \
    make -j\"$(nproc)\" install-strip && \
    find /usr/local/lib/x86_64-linux-gnu -type f -name 'lib*.la' -delete

RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
        gcc-multilib \
        libxext-dev:i386 \
        libx11-dev:i386 && \
    rm -rf /var/lib/apt/lists/*

# 32-bit libraries
RUN make distclean && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --libdir=/usr/local/lib/i386-linux-gnu --host=i386-linux-gnu \"CFLAGS=-m32\" \"CXXFLAGS=-m32\" \"LDFLAGS=-m32\" && \
    make -j\"$(nproc)\" install-strip && \
    find /usr/local/lib/i386-linux-gnu -type f -name 'lib*.la' -delete

COPY 10_nvidia.json /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json

RUN echo '/usr/local/lib/x86_64-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    echo '/usr/local/lib/i386-linux-gnu' >> /etc/ld.so.conf.d/glvnd.conf && \
    ldconfig

ENV LD_LIBRARY_PATH /usr/local/lib/x86_64-linux-gnu:/usr/local/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}


# nvidia-docker hooks
LABEL com.nvidia.volumes.needed=\"nvidia_driver\"

ENV PATH /usr/local/nvidia/bin:${PATH}

ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}" >> Dockerfile

docker build --tag "$docker_image-nvidia2" .

cd
rm -rf /tmp/docker_nvidia_tmp
