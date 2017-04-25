FROM shadowrobot/dexterous-hand:kinetic

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="Image for using sr_recognizer package" Version="1.0"

RUN echo "Installing ceres with dependencies" && \
    apt-get update && apt-get -y install \
    cmake libgoogle-glog-dev libatlas-base-dev \
    libeigen3-dev libsuitesparse-dev && \
    wget http://ceres-solver.org/ceres-solver-1.8.0.tar.gz && \
    tar zxf ceres-solver-1.8.0.tar.gz && \
    mkdir ceres-bin && cd ceres-bin && \
    cmake ../ceres-solver-1.8.0 -DBUILD_SHARED_LIBS=ON && \
    make -j3 && make test && make install && \

    echo "Installing v4r library" && \
    cd /home/$MY_USERNAME && \
    git clone 'https://github.com/ThoMut/v4r.git' && \
    cd v4r && \
    ./setup.sh xenial kinetic && \
    mkdir build && cd build && \
    cmake .. && \
    cmake --build . --target ObjectRecognizer && \
    cmake --build . --target RTMT && \
    make install && \

    echo "Installing OpenNI with dependencies" && \
    apt-get -y install \
    freeglut3-dev pkg-config build-essential \
    libxmu-dev libxi-dev libusb-1.0-0-dev doxygen \
    graphviz mono-complete ros-kinetic-openni-launch \
    libopenni-sensor-primesense0 openjdk-8-jdk && \
    cd / && \
    git clone https://github.com/OpenNI/OpenNI.git && \
    cd OpenNI && git checkout unstable && \
    cd Platform/Linux/CreateRedist && \
    ./RedistMaker && \
    cd /OpenNI/Platform/Linux/Redist/OpenNI-Bin-Dev-Linux-x64-v1.5.8.5/ && \
    ./install.sh && \
    cd / && \
    git clone https://github.com/ph4m/SensorKinect.git && \
    cd SensorKinect && git checkout unstable && \
    cd /SensorKinect/Platform/Linux/CreateRedist && \
    ./RedistMaker && \
    cd /SensorKinect/Platform/Linux/Redist/Sensor-Bin-Linux-x64-v5.1.2.1/ && \
    ./install.sh && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig \
    /ceres-solver-1.8.0 /ceres-solver-1.8.0.tar.gz /ceres-bin /OpenNI /SensorKinect


ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
