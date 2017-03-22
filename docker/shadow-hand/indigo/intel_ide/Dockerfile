#
# Indigo with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM shadowrobot/build-tools:trusty-indigo-ide-intel

ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/setup_dev_machine"

RUN echo "Fixing file system" && \
    mkdir -p /etc/apt/sources.list.d && \
    rm -f /etc/apt/sources.list.d/ros-latest.list && \

    echo "Running one-liner" && \
    apt-get update && \
    sudo apt-get -y install libgl1-mesa-glx libgl1-mesa-dri && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    gosu $MY_USERNAME /tmp/oneliner -b "$toolset_branch" -w /home/user/projects/shadow_robot/base  && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

    usermod -a -G video user

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
