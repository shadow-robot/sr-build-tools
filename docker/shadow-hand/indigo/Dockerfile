FROM shadowrobot/build-tools:trusty-indigo-ide

RUN apt-get update && \
    apt-get install -y curl && \
    echo "Running one-liner" && \
    curl -L bit.ly/dev-machine | bash -s -- -w /projects/shadow_robot/base && \
    cat additional_bashrc_cmds >> /home/user/.bashrc
    
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]