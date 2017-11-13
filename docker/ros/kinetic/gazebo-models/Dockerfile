FROM shadowrobot/build-tools:xenial-kinetic-mongodb-fix

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This ROS Kinetic image contains folder with loaded Gazebo models" Vendor="Shadow Robot" Version="1.0"

RUN echo "Loading gazebo models" && \
    /home/user/sr-build-tools/docker/utils/load_gazebo_models.sh && \
    mv /root/.gazebo /home/$MY_USERNAME && \
    chown -R $MY_USERNAME:$MY_USERNAME /home/$MY_USERNAME/.gazebo && \
    
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig
    
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
