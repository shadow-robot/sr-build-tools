#!/usr/bin/env bash
chroot $R apt-get update
chroot $R apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl \
            software-properties-common
chroot $R curl -fsSL https://apt.dockerproject.org/gpg | sudo apt-key add -
chroot $R apt-key fingerprint 58118E89F3A912897C070ADBF76221572C52609D
chroot $R add-apt-repository \
            "deb https://apt.dockerproject.org/repo/ ubuntu-${RELEASE} main"
chroot $R apt-get update
chroot $R apt-get -y install --allow-unauthenticated docker-engine
chroot $R groupadd dockerproject
chroot $R usermod -aG docker ${USERNAME}