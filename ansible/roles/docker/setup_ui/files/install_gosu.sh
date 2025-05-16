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

if [ -z ${GOSU_VERSION} ]; then
  export GOSU_VERSION='1.10'
fi

dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"
wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"
export GNUPGHOME="$(mktemp -d)"
for server in $(shuf -e ha.pool.sks-keyservers.net \
                        hkp://p80.pool.sks-keyservers.net:80 \
                        keyserver.ubuntu.com \
                        hkp://keyserver.ubuntu.com:80 \
                        pgp.mit.edu) ; do \
    gpg --keyserver "$server" --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && break || : ; \
done
gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu
rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc
chmod +x /usr/local/bin/gosu
gosu nobody true
