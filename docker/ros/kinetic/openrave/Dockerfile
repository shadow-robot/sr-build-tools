#
# Dockfile that adds openrave to the ROS Kinetic with build tools image
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM shadowrobot/build-tools:xenial-kinetic-mongodb-fix

LABEL Description="This image contains ROS kinetic, Shadow Robot's build tools, Mongo, and Openrave." \
      Author="Ethan Fowler <ethan@shadowrobot.com>" \
      Maintainer="The Shadow Robot Company Software Team <software@shadowrobot.com>"

RUN echo "Updating package list..." && \
    apt-get update && \
    
    echo "Installing OpenRAVE dependencies" && \
    apt-get update && \
    apt-get install -y ipython minizip python-h5py python-scipy python-sympy qt4-dev-tools \
    libassimp-dev libavcodec-dev libavformat-dev libavformat-dev libboost-all-dev \
    libboost-date-time-dev libbullet-dev libgsm1-dev liblapack-dev liblog4cxx-dev \
    libmpfr-dev libode-dev libogg-dev libpcrecpp0v5 libpcre3-dev libqhull-dev libqt4-dev \
    libsoqt-dev-common libsoqt4-dev libswscale-dev libswscale-dev libvorbis-dev libx264-dev \
    libxml2-dev libxvidcore-dev libtinyxml2-dev && \

    echo "Creating openRAVE workspace" && \
    cd /home/user && \
    openrave_ws='/home/user/openrave_ws' && \
    mkdir ${openrave_ws} && \

    echo "Installing collada-dom" && \
    cd ${openrave_ws}  && \
    git clone https://github.com/rdiankov/collada-dom.git && \
    mkdir collada-dom/build && cd collada-dom/build && \
    cmake .. && make -j8 && make install && \

    echo "Installing openrave" && \
    cd ${openrave_ws}  && \
    git clone --branch production https://github.com/rdiankov/openrave.git && \
    mkdir openrave/build && cd openrave/build && \
    cmake .. -DOPENRAVE_PLUGIN_BULLETRAVE=OFF -DOPENRAVE_PLUGIN_FCLRAVE=OFF \
    -DOPT_FCL_COLLISION=OFF && \
    make -j8 && make install && \

    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(openrave-config' \
    '--python-dir)/openravepy/_openravepy_'  >> /home/user/.bashrc && \
    echo 'export PYTHONPATH=$PYTHONPATH:$(openrave-config --python-dir)' >> /home/user/.bashrc && \

    echo "Fixing ownership of openrave directories..." && \
    chown -R user:user ${openrave_ws} && \
    echo "Removing caches" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
