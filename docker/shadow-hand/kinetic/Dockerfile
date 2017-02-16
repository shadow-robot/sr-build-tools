FROM shadowrobot/build-tools:xenial-kinetic-ide

ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/master/ansible/deploy.sh"

COPY additional_bashrc_cmds /tmp/additional_bashrc_cmds

RUN echo "Running one-liner" && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    gosu $MY_USERNAME /tmp/oneliner -w /home/user/projects/shadow_robot/base -b "kinetic-devel" -v "kinetic"  && \
    cat /tmp/additional_bashrc_cmds >> /home/user/.bashrc && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
