FROM ubuntu:xenial

MAINTAINER "Shadow Robot's Software Team <software@shadowrobot.com>"

LABEL Description="Ubuntu Xenial Raspberry Pi Flavour Maker" Version="1.0"

ENV LC_ALL en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LANG en_GB.UTF-8

RUN locale-gen en_GB.UTF-8 && \
    apt-get update && \
    apt-get install -y git dosfstools parted binfmt-support debootstrap f2fs-tools \
    qemu-user-static rsync ubuntu-keyring whois sudo && \
    git clone https://github.com/shadow-robot/sr-build-tools.git && \
    cp -r sr-build-tools/arm/ubuntu-pi-flavour-maker /. && \
    rm -rf sr-build-tools && \
    apt-get purge -y git && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /ubuntu-pi-flavour-maker

CMD bash
