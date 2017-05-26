#!/usr/bin/env bash

set -e # fail on errors
# set -x # echo commands run

export PYCHARM_HOME=${1:-/etc/pycharm}

wget https://download-cf.jetbrains.com/python/pycharm-community-2017.1.3.tar.gz -O /tmp/pycharm.tar.gz
sudo mkdir ${PYCHARM_HOME}
tar -xzvf /tmp/pycharm.tar.gz -C ${PYCHARM_HOME} --strip=1
wget -P /tmp/ https://bootstrap.pypa.io/get-pip.py
sudo python /tmp/get-pip.py
