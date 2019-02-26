FROM shadowrobot/build-tools:xenial-kinetic

LABEL Description="This ROS Kinetic image contains Ros Kinetic and Eigen v. 3.3.7"
ENV eigen_folder=eigen_3.3.7

RUN set +x && \
    apt-get update && \
    echo "Installing Eigen library v. 3.3.7" && \
    wget "http://bitbucket.org/eigen/eigen/get/3.3.7.tar.bz2" -O $eigen_folder.tar.bz2 && \
    mkdir $eigen_folder && \
    tar -xjf $eigen_folder.tar.bz2 -C $eigen_folder --strip-components=1 && \
    cd eigen_3.3.7 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    cmake . -DCMAKE_INSTALL_PREFIX=/usr && \
    make install

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["usr/bin/terminator"]
