FROM shadowrobot/build-tools:trusty-indigo-ide

COPY additional_bashrc_cmds /tmp/additional_bashrc_cmds

RUN apt-get update && \
    apt-get install -y curl && \
    echo "Running one-liner" && \
    curl -L bit.ly/dev-machine | bash -s -- -w /home/user/projects/shadow_robot/base && \
    cat /tmp/additional_bashrc_cmds >> /home/user/.bashrc && \
    
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

CMD ["/usr/bin/terminator"]
