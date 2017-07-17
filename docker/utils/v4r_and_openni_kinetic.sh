#!/bin/bash

set -e

echo "Installing ceres with dependencies"
apt-get update
apt-get -y install \
    cmake libgoogle-glog-dev \
    libatlas-base-dev libeigen3-dev libsuitesparse-dev
wget -P /tmp http://ceres-solver.org/ceres-solver-1.8.0.tar.gz
cd /tmp && tar zxf ceres-solver-1.8.0.tar.gz
mkdir ceres-bin && cd ceres-bin
cmake ../ceres-solver-1.8.0 -DBUILD_SHARED_LIBS=ON
make -j3 && make test && make install

echo "Installing v4r library"
cd /home/$MY_USERNAME
git clone 'https://github.com/ThoMut/v4r.git'
cd v4r
./setup.sh xenial kinetic
mkdir build && cd build
cmake ..
cmake --build . --target ObjectRecognizer
cmake --build . --target RTMT
# make install (In the current version of v4r this step is failing. 
#               Please uncomment after proper fixes in v4r are implemented,
#               alongside with removing V4R_PATH variable from v4r dedicated Dockerfiles)

echo "Installing OpenNI with dependencies"
apt-get -y install \
    freeglut3-dev pkg-config build-essential \
    libxmu-dev libxi-dev libusb-1.0-0-dev doxygen \
    graphviz mono-complete ros-kinetic-openni-launch \
    libopenni-sensor-primesense0 openjdk-8-jdk
git clone --depth 1 -b unstable https://github.com/OpenNI/OpenNI.git /tmp/OpenNI
cd /tmp/OpenNI/Platform/Linux/CreateRedist
./RedistMaker
cd /tmp/OpenNI/Platform/Linux/Redist/OpenNI-Bin-Dev-Linux-x64-v1.5.8.5/
./install.sh
git clone --depth 1 -b unstable https://github.com/ph4m/SensorKinect.git /tmp/SensorKinect
cd /tmp/SensorKinect/Platform/Linux/CreateRedist
./RedistMaker
cd /tmp/SensorKinect/Platform/Linux/Redist/Sensor-Bin-Linux-x64-v5.1.2.1/
./install.sh
