FROM shadowrobot/build-tools:trusty-indigo-ide

LABEL Description="This ROS Indigo image contains Shadow's dexterous hand software with build tools. It includes IDE environments" Vendor="Shadow Robot" Version="1.0"

ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/setup_dev_machine"

RUN echo "Fixing file system" && \
    mkdir -p /etc/apt/sources.list.d && \
    rm -f /etc/apt/sources.list.d/ros-latest.list && \

    echo "Running one-liner" && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    gosu $MY_USERNAME /tmp/oneliner -b "$toolset_branch" -w /home/user/projects/shadow_robot/base  && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
