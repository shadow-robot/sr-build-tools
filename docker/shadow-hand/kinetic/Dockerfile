FROM shadowrobot/build-tools:xenial-kinetic-ide

ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/ansible/deploy.sh"

COPY additional_bashrc_cmds /tmp/additional_bashrc_cmds

RUN echo "Running one-liner" && \
    apt-get update && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    gosu $MY_USERNAME /tmp/oneliner -w /home/user/projects/shadow_robot/base -b "kinetic-devel" -v "kinetic"  && \
    cat /tmp/additional_bashrc_cmds >> /home/user/.bashrc && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "Fixing mongodb" && \
    cd /home/user/projects/shadow_robot/base_deps/src
    # installing mongocxx driver for the warehouse
    git clone -b 26compat https://github.com/mongodb/mongo-cxx-driver.git && \
    apt-get -qq install -y scons mongodb && \
    cd mongo-cxx-driver && \
    scons --use-system-boost --prefix=/usr/local/ --full --disable-warnings-as-errors && \
    cd /home/user/projects/shadow_robot/base_deps/src
    # Download warehouse source
    wstool set -yu warehouse_ros_mongo --git https://github.com/ros-planning/warehouse_ros_mongo.git -v jade-devel && \
    wstool set -yu warehouse_ros --git https://github.com/ros-planning/warehouse_ros.git -v jade-devel
    # build the workspace
    cd ..
    catkin_make

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
