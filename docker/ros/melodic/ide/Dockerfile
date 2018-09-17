#
# ROS Melodic with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM shadowrobot/build-tools:bionic-melodic

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This image is used to make ROS Melodic based projects build faster using build tools" Vendor="Shadow Robot" Version="1.0"

RUN set -x && \

    echo "Running one-liner" && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    gosu $MY_USERNAME /tmp/oneliner "$toolset_branch" $server_type 'setup_docker_ide' && \

    apt-get install -y emacs && \
    apt-get install -y gnome-icon-theme && \
    
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
