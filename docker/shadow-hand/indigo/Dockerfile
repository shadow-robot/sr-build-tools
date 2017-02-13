FROM shadowrobot/build-tools:trusty-indigo-ide

ENV GOSU_VERSION 1.10
ENV MY_USERNAME user
ENV toolset_branch="master"
ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/bin/setup_dev_machine"

COPY additional_bashrc_cmds /tmp/additional_bashrc_cmds

RUN apt-get update && \
    apt-get install -y curl && \
    
    echo "Running one-liner" && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    gosu $MY_USERNAME /tmp/oneliner -b "$toolset_branch" -w ~{ros_user}/projects/shadow_robot/base  && \
    cat /tmp/additional_bashrc_cmds >> /home/user/.bashrc && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
