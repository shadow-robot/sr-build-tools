#!/usr/bin/env bash

# Copyright 2022 Shadow Robot Company Ltd.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

set -e # fail on errors
# set -x # echo commands run

export PYCHARM_HOME=${1:-/etc/pycharm}

wget https://download-cf.jetbrains.com/python/pycharm-community-2018.3.5.tar.gz -O /tmp/pycharm.tar.gz
sudo mkdir ${PYCHARM_HOME}
tar -xzvf /tmp/pycharm.tar.gz -C ${PYCHARM_HOME} --strip=1
wget -P /tmp/ https://bootstrap.pypa.io/2.7/get-pip.py
sudo python /tmp/get-pip.py
