FROM ros:indigo

ENV DEBIAN_FRONTEND noninteractive

RUN sudo apt-get install python-pip && \
    sudo pip install rosdep rosinstall_generator wstool rosinstall && \
    sudo pip install autobahn trollius

RUN mkdir -p /workspace/blockly/src && \
    cd blockly/src && \
    wstool init && \
    wstool set -y -u robot_blockly --git https://github.com/shadow-robot/robot_blockly && \
    cd ../ && \
    catkin_make_isolated --pkg robot_blockly --install



# setup entrypoint
COPY ./entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
