#
# ROS Kinetic with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM shadowrobot/build-tools:xenial-kinetic

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This image is running a virtual X11 server" Vendor="Shadow Robot" Version="1.0"

COPY entrypoint_x11.sh /usr/local/bin/entrypoint_x11.sh

RUN apt-get update && \
    apt-get -y install xvfb && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /home/$MY_USERNAME/.ansible /home/$MY_USERNAME/.gitconfig

ENTRYPOINT ["/usr/local/bin/entrypoint_x11.sh"]
