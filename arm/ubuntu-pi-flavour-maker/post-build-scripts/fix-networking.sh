#!/usr/bin/env bash
chroot $R sed -i 's/$env{ID_NET_NAME_MAC}/eth0/' /lib/udev/rules.d/73-usb-net-by-mac.rules
chroot $R cp /lib/udev/rules.d/73-usb-net-by-mac.rules /etc/udev/rules.d/
chroot $R apt-get install -y --no-install-recommends avahi-daemon