#!/usr/bin/env bash

########################################################################
#
# Copyright (C) 2015 Martin Wimpress <code@ubuntu-mate.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
########################################################################

set -ex

DEST="man"

if [ -f build-settings.sh ]; then
    source build-settings.sh
else
    echo "ERROR! Could not source build-settings.sh."
    exit 1
fi

if [ $(id -u) -eq 0 ]; then
    echo "ERROR! Must be a regular user."
    exit 1
fi

function publish_image() {
    echo "Sending to: ${DEST}"
    ssh matey@${DEST}.ubuntu-mate.net mkdir -p /home/matey/ISO-Mirror/${RELEASE}/armhf/
    rsync -rvl -e 'ssh -c aes128-gcm@openssh.com' --progress "${BASEDIR}/${IMAGE}.xz" matey@${DEST}.ubuntu-mate.net:ISO-Mirror/${RELEASE}/armhf/
    rsync -rvl -e 'ssh -c aes128-gcm@openssh.com' --progress "${BASEDIR}/${IMAGE}.xz.sha256" matey@${DEST}.ubuntu-mate.net:ISO-Mirror/${RELEASE}/armhf/
    rsync -rvl -e 'ssh -c aes128-gcm@openssh.com' --progress "${BASEDIR}/${IMAGE}.xz.sha256.sign" matey@${DEST}.ubuntu-mate.net:ISO-Mirror/${RELEASE}/armhf/
}

function publish_tarball() {
    if [ ${MAKE_TARBALL} -eq 1 ]; then
        echo "Sending to: ${DEST}"
        rsync -rvl -e 'ssh -c aes128-gcm@openssh.com' --progress "${BASEDIR}/${TARBALL}" matey@${DEST}.ubuntu-mate.net:ISO-Mirror/${RELEASE}/armhf/
        rsync -rvl -e 'ssh -c aes128-gcm@openssh.com' --progress "${BASEDIR}/${TARBALL}.sha256" matey@${DEST}.ubuntu-mate.net:ISO-Mirror/${RELEASE}/armhf/
        rsync -rvl -e 'ssh -c aes128-gcm@openssh.com' --progress "${BASEDIR}/${TARBALL}.sha256.sign" matey@${DEST}.ubuntu-mate.net:ISO-Mirror/${RELEASE}/armhf/
    fi
}

publish_image
publish_tarball
echo "Published to ${DEST}. Now mirror from there!"