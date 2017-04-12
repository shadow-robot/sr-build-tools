FROM shadowrobot/build-tools:xenial-kinetic

LABEL Description="This ROS Kinetic image contains build tools and the required mongoncxx and pyassimp libraries." Vendor="Shadow Robot" Version="1.0"

ENV PROJECTS_WS=/home/user/mongo_ws
RUN echo "Updating sources" && \
    apt-get update && \
    echo "Creating mongo_ws workspace" && \
    mkdir -p $PROJECTS_WS/src && \
    cd $PROJECTS_WS/src && \
    
    echo "Downloading warehouse source" && \
    wstool init && \
    wstool set -yu warehouse_ros_mongo --git https://github.com/ros-planning/warehouse_ros_mongo.git -v jade-devel && \
    wstool set -yu warehouse_ros --git https://github.com/ros-planning/warehouse_ros.git -v jade-devel && \
    
    echo "Installing mongocxx driver for the warehouse" && \
    git clone -b 26compat https://github.com/mongodb/mongo-cxx-driver.git && \
    apt-get -qq install -y scons mongodb && \
    cd mongo-cxx-driver && \
    scons --use-system-boost --prefix=/usr/local/ --full --disable-warnings-as-errors && \
    
    echo "Changing folders owner" && \
    chown -R user:user $PROJECTS_WS && \
    
    echo "Building the workspace" && \
    cd $PROJECTS_WS && \
    gosu $MY_USERNAME bash -c "source /opt/ros/kinetic/setup.bash && catkin_make" && \
    echo "source /home/user/mongo_ws/devel/setup.bash" >> /home/user/.bashrc  && \
    
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