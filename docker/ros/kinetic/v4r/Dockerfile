FROM shadowrobot/dexterous-hand:kinetic

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="Image for using sr_recognizer package" Version="1.0"

RUN echo "Installing ceres with dependencies" && \
    apt-get update && apt-get -y install \
    cmake \
    libgoogle-glog-dev \
    libatlas-base-dev \
    libeigen3-dev \
    libsuitesparse-dev && \
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

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig \
    /ceres-solver-1.8.0 /ceres-solver-1.8.0.tar.gz /ceres-bin


ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
