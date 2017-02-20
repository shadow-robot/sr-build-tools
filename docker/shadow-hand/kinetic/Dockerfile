FROM shadowrobot/build-tools:xenial-kinetic-ide

ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/ansible/deploy.sh"

ENV PROJECTS_WS=/home/user/projects/shadow_robot
RUN echo "Running one-liner" && \
    apt-get update && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    gosu $MY_USERNAME /tmp/oneliner -w $PROJECTS_WS/shadow_robot/base -b "kinetic-devel" -v "kinetic"  && \
    
    echo "Installing mongodb" && \
    cd $PROJECTS_WS/base_deps/src && \
    
    # installing mongocxx driver for the warehouse && \
    git clone -b 26compat https://github.com/mongodb/mongo-cxx-driver.git && \
    apt-get -qq install -y scons mongodb && \
    cd mongo-cxx-driver && \
    scons --use-system-boost --prefix=/usr/local/ --full --disable-warnings-as-errors && \

    # Download warehouse source && \
    cd $PROJECTS_WS/base_deps/src && \
    wstool set -yu warehouse_ros_mongo --git https://github.com/ros-planning/warehouse_ros_mongo.git -v jade-devel && \
    wstool set -yu warehouse_ros --git https://github.com/ros-planning/warehouse_ros.git -v jade-devel && \
    
    #Changing folders owner && \
    chown -R user:user mongo-cxx-driver warehouse_ros* && \

    # build the workspace && \
    cd $PROJECTS_WS/base_deps && \
    gosu $MY_USERNAME source $PROJECTS_WS/base_deps/devel/setup.bash && \
    gosu $MY_USERNAME catkin_make && \

    echo "Fixing pyassimp issue" && \
    cd /tmp/  && \
    git clone https://github.com/assimp/assimp.git && \
    cd assimp && \
    cmake CMakeLists.txt -G 'Unix Makefiles' && \
    make && \
    make install && \
    cd port/PyAssimp/ && \
    python setup.py install && \
    
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
