FROM shadowrobot/build-tools:trusty-indigo-ide

ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/setup_dev_machine"
ENV remote_additional_bashrc_cmds="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/docker/utils/additional_bashrc_cmds_indigo"

RUN echo "Fixing file system" && \
    mkdir -p /etc/apt/sources.list.d && \
    rm -f /etc/apt/sources.list.d/ros-latest.list && \

    echo "Running one-liner" && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    gosu $MY_USERNAME /tmp/oneliner -b "$toolset_branch" -w /home/user/projects/shadow_robot/base  && \
    
    echo "Updating bash commands" && \
    wget -O /tmp/additional_bashrc_cmds "$( echo "$remote_additional_bashrc_cmds" | sed 's/#/%23/g' )" && \
    cat /tmp/additional_bashrc_cmds >> /home/user/.bashrc && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
