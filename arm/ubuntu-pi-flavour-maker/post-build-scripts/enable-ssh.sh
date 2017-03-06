#!/usr/bin/env bash
chroot $R systemctl enable ssh.socket
chroot $R systemctl enable ssh.service