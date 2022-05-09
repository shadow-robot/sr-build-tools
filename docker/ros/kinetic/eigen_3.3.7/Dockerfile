FROM shadowrobot/build-tools:xenial-kinetic

LABEL Description="This ROS Kinetic image contains Ros Kinetic and Eigen v. 3.3.7"
ENV eigen_folder=eigen-3.3.7

RUN set +x && \
    apt-get update && \
    echo "Installing Eigen library v. 3.3.7" && \
    wget "https://gitlab.com/libeigen/eigen/-/archive/3.3.7/eigen-3.3.7.tar.bz2" -O $eigen_folder.tar.bz2 && \
    mkdir $eigen_folder && \
    tar -xjf $eigen_folder.tar.bz2 -C $eigen_folder --strip-components=1 && \
    cd $eigen_folder && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    cmake . -DCMAKE_INSTALL_PREFIX=/usr && \
    make install && \
    echo "Installing libglvnd" && \
    apt-get install git ca-certificates make automake autoconf libtool pkg-config python libxext-dev libx11-dev x11proto-gl-dev -y && \
    git clone https://github.com/NVIDIA/libglvnd.git /opt/libglvnd && \
    cd /opt/libglvnd && \
    ./autogen.sh && ./configure --prefix=/usr/local --libdir=/usr/local/lib/x86_64-linux-gnu && \
    make -j $(nproc) install-strip && \
    find /usr/local/lib/x86_64-linux-gnu -type f -name 'lib*.la' -delete && \
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["usr/bin/terminator"]
