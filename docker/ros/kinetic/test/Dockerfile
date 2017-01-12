FROM ubuntu:xenial

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="Ubuntu Desktop Test Image" Version="1.0"

ENV DEBIAN_FRONTEND noninteractive

RUN echo "Setting up bash as default shell" && \
    rm /bin/sh && \
    ln -s /bin/bash /bin/sh && \

    echo "Installing needed libraries for Ansible" && \
    apt-get update && \
    apt-get install -y python2.7 python sudo && \

    echo "Creation sudo user for testing" && \
    useradd -m testuser && \
    echo "testuser:testpassword" | chpasswd && \
    adduser testuser sudo && \
    
    echo "Setting up SSH access" && \
    apt-get install -y openssh-server && \
    
    echo "Required to not get a 'Missing privilege separation directory' error" && \
    mkdir /var/run/sshd && \
    
    echo "Install Ubuntu desktop files" && \
    apt-get install --no-install-recommends -y ubuntu-desktop && \
    
    echo "Removing cache" && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*