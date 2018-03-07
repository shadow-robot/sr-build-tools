FROM shadowrobot/build-tools:xenial-kinetic-ide

LABEL Description="This ROS Kinetic image contains Shadow's dexterous hand software with build tools. It includes IDE environments." Vendor="Shadow Robot" Version="1.0"

ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/ansible/deploy.sh"

ENV PROJECTS_WS=/home/user/projects/shadow_robot
RUN echo "Running one-liner" && \
    apt-get update && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    gosu $MY_USERNAME /tmp/oneliner -w $PROJECTS_WS/base -r sr-build-tools -b $toolset_branch -i data/shadow_robot-kinetic.rosinstall -v "kinetic" -t mongodb,pyassimp && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig

    echo "Installing Eepromtool" && \
    cd /home/user/ && \
    wget https://github.com/shadow-robot/sr-build-tools/raw/master/bin/eepromtool && \
    chmod +x /home/user/eepromtool

    echo "Installing Gedit" && \
    apt-get install gedit

    echo "Installing Multiplot" && \
    apt-get install ros-kinetic-rqt-multiplot

    echo "Installing Multiplot Configs" && \
    cd /home/user/ && \
    git clone https://github.com/shadow-robot/sr_multiplot_config.git --depth 1 && \
    chown -R $MY_USERNAME:$MY_USERNAME /home/user/sr_multiplot_config

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
