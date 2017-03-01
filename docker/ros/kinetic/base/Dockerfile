#
# ROS Kinetic with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM ros:kinetic-perception

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This image is used to make ROS Kinetic based projects build faster using build tools" Vendor="Shadow Robot" Version="1.0"

ENV DEBIAN_FRONTEND noninteractive

ENV PULSE_SERVER /run/pulse/native
ENV GOSU_VERSION 1.10
ENV MY_USERNAME user

ENV toolset_branch="master"
ENV server_type="docker_hub"
ENV used_modules="check_cache,create_workspace"
ENV ros_release_name=kinetic
ENV remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/sr-run-ci-build.sh"

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -x && \

    echo "Installing wget" && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates wget sudo && \

    echo "Running one-liner" && \
    wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )" && \
    chmod 755 /tmp/oneliner && \
    /tmp/oneliner "$toolset_branch" $server_type 'setup_docker_user' && \
    gosu $MY_USERNAME /tmp/oneliner "$toolset_branch" $server_type $used_modules && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/usr/bin/terminator"]
