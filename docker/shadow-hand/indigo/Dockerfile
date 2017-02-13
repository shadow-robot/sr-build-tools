FROM shadowrobot/build-tools:trusty-indigo-ide

ENV GOSU_VERSION 1.10
ENV MY_USERNAME user
ENV remote_shell_script="curl -L bit.ly/dev-machine | bash -s -- -w /home/user/projects/shadow_robot/base"

COPY additional_bashrc_cmds /tmp/additional_bashrc_cmds

RUN apt-get update && \
    apt-get install -y curl && \
    
    echo "Running one-liner" && \
    cat /tmp/additional_bashrc_cmds >> /home/user/.bashrc && \
    gosu $MY_USERNAME $remote_shell_script && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
