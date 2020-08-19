FROM shadowrobot/build-tools:xenial-kinetic

LABEL Description="This ROS Kinetic image contains Ros Kinetic and Eigen v. 3.3.7"
ENV eigen_folder=eigen_3.3.7
ENV aurora_branch="master"
ENV aurora_script="https://raw.githubusercontent.com/shadow-robot/aurora/$aurora_branch/bin/run-ansible.sh"

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
    wget -O /tmp/aurora "$( echo "$aurora_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/aurora && \
    gosu $MY_USERNAME /tmp/aurora install_software --branch $aurora_branch software=[libglvnd] && \
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["usr/bin/terminator"]
