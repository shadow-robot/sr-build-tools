#
# ROS Indigo with build tools Dockerfile
#
# https://github.com/shadow-robot/sr-build-tools/
#

FROM ros:indigo

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="This image is used to make ROS Indigo based projects build faster using build tools" Vendor="Shadow Robot" Version="1.0"

ENV DEBIAN_FRONTEND noninteractive

ENV USERNAME user
ENV PULSE_SERVER /run/pulse/native

ENV GOSU_VERSION 1.10

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN set -x && \

    echo "Setting up bash as default shell" && \
    rm /bin/sh && \
    ln -s /bin/bash /bin/sh && \

    echo "Setting locale" && \
    locale-gen en_US.UTF-8 && \

    echo "Installing curl" && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates wget && \

    echo "Install gosudo" && \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" && \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
    rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    apt-get purge -y --auto-remove ca-certificates wget && \

    echo "Intall some basic GUI and sound libs" && \
    apt-get install -y \
        xz-utils file locales dbus-x11 pulseaudio dmz-cursor-theme \
        fonts-dejavu fonts-liberation hicolor-icon-theme \
        libcanberra-gtk3-0 libcanberra-gtk-module libcanberra-gtk3-module \
        libasound2 libgtk2.0-0 libdbus-glib-1-2 libxt6 libexif12 \
        libgl1-mesa-glx libgl1-mesa-dri && \
    update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX && \

    echo "Installing UI tools" && \
    apt-get install -y \
        terminator \
        vim \
        mc && \

    echo "Adding user" && \
    useradd -m $USERNAME && \
    echo "$USERNAME:$USERNAME" | chpasswd && \
    usermod --shell /bin/bash $USERNAME && \
    usermod -aG sudo $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \

    echo "Setup .bashrc for ROS" && \
    echo "source /opt/ros/indigo/setup.bash" >> /home/$USERNAME/.bashrc && \
    #Fix for qt and X server errors
    echo "export QT_X11_NO_MITSHM=1" >> /home/$USERNAME/.bashrc && \
    # cd to home on login
    echo "cd" >> /home/$USERNAME/.bashrc && \

    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#USER user

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["terminator"]