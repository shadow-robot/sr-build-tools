FROM ros:indigo

# using bash instead of sh to be able to source
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

ENV DEBIAN_FRONTEND noninteractive

RUN sudo apt-get update && \
    sudo apt-get install -y python-pip && \
    sudo pip install -U rosdep rosinstall_generator wstool rosinstall && \
    sudo pip install -U autobahn trollius txaio

RUN mkdir -p /workspace/blockly/src && \
    cd /workspace/blockly/src && \
    wstool init && \
    wstool set -y -u robot_blockly --git https://github.com/shadow-robot/robot_blockly && \
    wstool set -y -u sr_blockly_blocks --git https://github.com/shadow-robot/sr_blockly && \
    source /opt/ros/indigo/setup.bash && \
    cd .. && \
    catkin_make

# setup entrypoint
COPY ./entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
