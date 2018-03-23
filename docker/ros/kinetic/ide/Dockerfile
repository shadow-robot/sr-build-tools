#
# ROS Kinetic with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM shadowrobot/build-tools:xenial-kinetic

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This image is used to make ROS Kinetic based projects build faster using build tools" Vendor="Shadow Robot" Version="1.0"

# TODO: Remove two lines from below it is for Debug purposes only !!!
ENV toolset_branch="B_vscode_fix"
ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/sr-run-ci-build.sh"	
# Finish of DEBUG !!!

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
