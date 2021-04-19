FROM shadowrobot/build-tools:xenial-kinetic

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/F#SRC-1901_mujoco_ansible_role/ansible/deploy.sh"
ENV PROJECTS_WS=/home/user/projects
ENV rosinstall_repo=sr-build-tools
ENV rosinstall_repo_branch=F#SRC-1901_mujoco_ansible_role

RUN set +x && \
    echo "Running one-liner" && \
    apt-get update && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    gosu $MY_USERNAME /tmp/oneliner -w $PROJECTS_WS/base -r $rosinstall_repo -b $rosinstall_repo_branch -i data/empty.rosinstall -v "$ros_release_name" -s false -t mujoco && \
    \
    chmod 755 /tmp/oneliner && \
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig /home/$MY_USERNAME/.cache && \
    echo "Removing ws" && \
    rm -rf $PROJECTS_WS/ && \
    echo "Changing ros source" && \ 
    sed -i '/source \/home\/user\/projects\/base\/devel\/setup.bash/d' /home/user/.bashrc && \
    echo 'source /opt/ros/kinetic/setup.bash' >> /home/user/.bashrc


ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/terminator"]
