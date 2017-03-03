FROM armhf/ubuntu:xenial

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="ARM version of OSRF's ROS kinetic core image." Version="1.0"

# setup environment
ENV LANG en_GB.UTF-8
ENV ROS_DISTRO kinetic
RUN locale-gen en_GB.UTF-8 && \
    apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116 && \
    echo "deb http://packages.ros.org/ros/ubuntu xenial main" > /etc/apt/sources.list.d/ros-latest.list && \
    apt-get update && apt-get install --no-install-recommends -y \
    python-rosdep \
    python-rosinstall \
    python-vcstools && \
    rm -rf /var/lib/apt/lists/* && \
    rosdep init && \
    rosdep update && \
    apt-get update && apt-get install -y \
    ros-kinetic-ros-core=1.3.0-0* && \
    rm -rf /var/lib/apt/lists/*

# setup entrypoint
COPY ./ros_entrypoint.sh /

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
