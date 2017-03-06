#!/usr/bin/env bash

########################################################################
#
# Copyright (C) 2015 - 2017 Martin Wimpress <code@ubuntu-mate.org>
# Copyright (C) 2015 Rohith Madhavan <rohithmadhavan@gmail.com>
# Copyright (C) 2015 Ryan Finnie <ryan@finnie.org>
#
# See the included LICENSE file.
# 
########################################################################

set -ex

if [ -f build-settings.sh ]; then
    source build-settings.sh
else
    echo "ERROR! Could not source build-settings.sh."
    exit 1
fi

if [ $(id -u) -ne 0 ]; then
    echo "ERROR! Must be root."
    exit 1
fi

# Check specified post build scripts exist
if [ -z "POST_BUILD_SCRIPT" ]; then
    echo "No post-build scripts specified."
else
    for var in "${POST_BUILD_SCRIPT[@]}"
    do
        if [ -f "post-build-scripts/${var}" ]; then
            echo "Specified post-build script ${var} exists."
        else
            echo "Specified post-build script ${var} does not exist!"
            exit 1
        fi
    done
fi

# Mount host system
function mount_system() {
    # In case this is a re-run move the cofi preload out of the way
    if [ -e $R/etc/ld.so.preload ]; then
        mv -v $R/etc/ld.so.preload $R/etc/ld.so.preload.disabled
    fi
    mount -t proc none $R/proc
    mount -t sysfs none $R/sys
    mount -o bind /dev $R/dev
    mount -o bind /dev/pts $R/dev/pts
    echo "nameserver 8.8.8.8" > $R/etc/resolv.conf
}

# Unmount host system
function umount_system() {
    umount -l $R/sys
    umount -l $R/proc
    umount -l $R/dev/pts
    umount -l $R/dev
    echo "" > $R/etc/resolv.conf
}

function sync_to() {
    local TARGET="${1}"
    if [ ! -d "${TARGET}" ]; then
        mkdir -p "${TARGET}"
    fi
    rsync -aHAXx --progress --delete ${R}/ ${TARGET}/
}

# Base debootstrap
function bootstrap() {
    # Required tools
    apt-get -y install binfmt-support debootstrap f2fs-tools \
    qemu-user-static rsync ubuntu-keyring whois

    # Use the same base system for all flavours.
    if [ ! -f "${R}/tmp/.bootstrap" ]; then
        if [ "${ARCH}" == "armv7l" ]; then
            debootstrap --verbose $RELEASE $R http://ports.ubuntu.com/
        else
            qemu-debootstrap --verbose --arch=armhf $RELEASE $R http://ports.ubuntu.com/
        fi
        touch "$R/tmp/.bootstrap"
    fi
}

function generate_locale() {
    for LOCALE in $(chroot $R locale | cut -d'=' -f2 | grep -v : | sed 's/"//g' | uniq); do
        if [ -n "${LOCALE}" ]; then
            chroot $R locale-gen $LOCALE
        fi
    done
}

# Set up initial sources.list
function apt_sources() {
    cat <<EOM >$R/etc/apt/sources.list
deb http://ports.ubuntu.com/ ${RELEASE} main restricted universe multiverse
deb-src http://ports.ubuntu.com/ ${RELEASE} main restricted universe multiverse

deb http://ports.ubuntu.com/ ${RELEASE}-updates main restricted universe multiverse
deb-src http://ports.ubuntu.com/ ${RELEASE}-updates main restricted universe multiverse

deb http://ports.ubuntu.com/ ${RELEASE}-security main restricted universe multiverse
deb-src http://ports.ubuntu.com/ ${RELEASE}-security main restricted universe multiverse

deb http://ports.ubuntu.com/ ${RELEASE}-backports main restricted universe multiverse
deb-src http://ports.ubuntu.com/ ${RELEASE}-backports main restricted universe multiverse
EOM
}

function apt_upgrade() {
    chroot $R apt-get update
    chroot $R apt-get -y -u dist-upgrade
}

function apt_clean() {
    chroot $R apt-get -y autoremove
    chroot $R apt-get clean
}

# Install Ubuntu minimal
function ubuntu_minimal() {
    if [ ! -f "${R}/tmp/.minimal" ]; then
        chroot $R apt-get -y install ubuntu-minimal parted software-properties-common
        if [ "${FS}" == "f2fs" ]; then
            chroot $R apt-get -y install f2fs-tools
        fi
        touch "${R}/tmp/.minimal"
    fi
}

# Install Ubuntu standard
function ubuntu_standard() {
    if [ "${FLAVOUR}" != "ubuntu-minimal" ] && [ ! -f "${R}/tmp/.standard" ]; then
        chroot $R apt-get -y install ubuntu-standard
        touch "${R}/tmp/.standard"
    fi
}

# Install meta packages
function install_meta() {
    local META="${1}"
    local RECOMMENDS="${2}"
    if [ "${RECOMMENDS}" == "--no-install-recommends" ]; then
        echo 'APT::Install-Recommends "false";' > $R/etc/apt/apt.conf.d/99noinstallrecommends
    else
        local RECOMMENDS=""
    fi

    cat <<EOM >$R/usr/local/bin/${1}.sh
#!/bin/bash
service dbus start
apt-get -f install
dpkg --configure -a
apt-get -y install ${RECOMMENDS} ${META}^
service dbus stop
EOM
    chmod +x $R/usr/local/bin/${1}.sh
    chroot $R /usr/local/bin/${1}.sh

    rm $R/usr/local/bin/${1}.sh

    if [ "${RECOMMENDS}" == "--no-install-recommends" ]; then
        rm $R/etc/apt/apt.conf.d/99noinstallrecommends
    fi
}

function create_groups() {
    chroot $R groupadd -f --system gpio
    chroot $R groupadd -f --system i2c
    chroot $R groupadd -f --system input
    chroot $R groupadd -f --system spi

    # Create adduser hook
    cp files/adduser.local $R/usr/local/sbin/adduser.local
    chmod +x $R/usr/local/sbin/adduser.local
}

# Create default user
function create_user() {
    local DATE=$(date +%m%H%M%S)
    local PASSWD=$(mkpasswd -m sha-512 ${USERNAME} ${DATE})

    if [ ${OEM_CONFIG} -eq 1 ]; then
        chroot $R addgroup --gid 29999 oem
        chroot $R adduser --gecos "OEM Configuration (temporary user)" --add_extra_groups --disabled-password --gid 29999 --uid 29999 ${USERNAME}
    else
        chroot $R adduser --gecos "${FLAVOUR_NAME}" --add_extra_groups --disabled-password ${USERNAME}
    fi
    chroot $R usermod -a -G sudo -p ${PASSWD} ${USERNAME}
}

# Prepare oem-config for first boot.
function prepare_oem_config() {
    if [ ${OEM_CONFIG} -eq 1 ]; then
        if [ "${FLAVOUR}" == "kubuntu" ]; then
            chroot $R apt-get -y install --no-install-recommends oem-config-kde ubiquity-frontend-kde ubiquity-ubuntu-artwork
        else
            chroot $R apt-get -y install --no-install-recommends oem-config-gtk ubiquity-frontend-gtk ubiquity-ubuntu-artwork
        fi

        if [ "${FLAVOUR}" == "ubuntu" ]; then
            chroot $R apt-get -y install --no-install-recommends oem-config-slideshow-ubuntu
        elif [ "${FLAVOUR}" == "ubuntu-mate" ]; then
            chroot $R apt-get -y install --no-install-recommends oem-config-slideshow-ubuntu-mate
            # Force the slideshow to use Ubuntu MATE artwork.
            sed -i 's/oem-config-slideshow-ubuntu/oem-config-slideshow-ubuntu-mate/' $R/usr/lib/ubiquity/plugins/ubi-usersetup.py
            sed -i 's/oem-config-slideshow-ubuntu/oem-config-slideshow-ubuntu-mate/' $R/usr/sbin/oem-config-remove-gtk
        fi
        cp -a $R/usr/lib/oem-config/oem-config.service $R/lib/systemd/system
        cp -a $R/usr/lib/oem-config/oem-config.target $R/lib/systemd/system
        chroot $R /bin/systemctl enable oem-config.service
        chroot $R /bin/systemctl enable oem-config.target
        chroot $R /bin/systemctl set-default oem-config.target
    fi
}

function configure_ssh() {
    chroot $R apt-get -y install openssh-server sshguard
    cp files/sshdgenkeys.service $R/lib/systemd/system/
    mkdir -p $R/etc/systemd/system/ssh.service.wants
    chroot $R /bin/systemctl enable sshdgenkeys.service
    chroot $R /bin/systemctl disable ssh.service
    chroot $R /bin/systemctl disable sshguard.service
}

function configure_network() {
    # Set up hosts
    echo ${FLAVOUR} >$R/etc/hostname
    cat <<EOM >$R/etc/hosts
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.1.1       ${FLAVOUR}
EOM

    # Set up interfaces
    if [ "${FLAVOUR}" != "ubuntu-minimal" ] && [ "${FLAVOUR}" != "ubuntu-standard" ]; then
        cat <<EOM >$R/etc/network/interfaces
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# The loopback network interface
auto lo
iface lo inet loopback
EOM
    else
        cat <<EOM >$R/etc/network/interfaces
# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d

# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOM
    fi
}

function disable_services() {
    # Disable brltty because it spams syslog with SECCOMP errors
    if [ -e $R/sbin/brltty ]; then
        chroot $R /bin/systemctl disable brltty.service
    fi

    # Disable ntp because systemd-timesyncd will take care of this.
    if [ -e $R/etc/init.d/ntp ]; then
        chroot $R /bin/systemctl disable ntp
        chmod -x $R/usr/sbin/ntpd
        cp files/prefer-timesyncd.service $R/lib/systemd/system/
        chroot $R /bin/systemctl enable prefer-timesyncd.service
    fi

    # Disable irqbalance because it is of little, if any, benefit on ARM.
    if [ -e $R/etc/init.d/irqbalance ]; then
        chroot $R /bin/systemctl disable irqbalance
    fi

    # Disable TLP because it is redundant on ARM devices.
    if [ -e $R/etc/default/tlp ]; then
        sed -i s'/TLP_ENABLE=1/TLP_ENABLE=0/' $R/etc/default/tlp
        chroot $R /bin/systemctl disable tlp.service
        chroot $R /bin/systemctl disable tlp-sleep.service
    fi

    # Disable apport because these images are not official
    if [ -e $R/etc/default/apport ]; then
        sed -i s'/enabled=1/enabled=0/' $R/etc/default/apport
        chroot $R /bin/systemctl disable apport.service
        chroot $R /bin/systemctl disable apport-forward.socket
    fi

    # Disable whoopsie because these images are not official
    if [ -e $R/usr/bin/whoopsie ]; then
        chroot $R /bin/systemctl disable whoopsie.service
    fi

    # Disable mate-optimus
    if [ -e $R/usr/share/mate/autostart/mate-optimus.desktop ]; then
        rm -f $R/usr/share/mate/autostart/mate-optimus.desktop || true
    fi
}

function configure_hardware() {
    local FS="${1}"
    if [ "${FS}" != "ext4" ] && [ "${FS}" != 'f2fs' ]; then
        echo "ERROR! Unsupport filesystem requested. Exitting."
        exit 1
    fi

    # Install the RPi PPA
    chroot $R apt-add-repository -y ppa:ubuntu-pi-flavour-makers/ppa
    chroot $R apt-get update

    # Firmware Kernel installation
    chroot $R apt-get -y install libraspberrypi-bin libraspberrypi-dev \
    libraspberrypi-doc libraspberrypi0 raspberrypi-bootloader rpi-update \
    bluez-firmware linux-firmware pi-bluetooth

    # Raspberry Pi 3 WiFi firmware. Supplements what is provided in linux-firmware
    cp -v firmware/* $R/lib/firmware/brcm/
    chown root:root $R/lib/firmware/brcm/*

    # pi-top poweroff and brightness utilities
    cp -v files/pi-top-* $R/usr/bin/
    chown root:root $R/usr/bin/pi-top-*
    chmod +x $R/usr/bin/pi-top-*

    if [ "${FLAVOUR}" != "ubuntu-minimal" ] && [ "${FLAVOUR}" != "ubuntu-standard" ]; then
        # Install fbturbo drivers on non composited desktop OS
        # fbturbo causes VC4 to fail
        if [ "${FLAVOUR}" == "lubuntu" ] || [ "${FLAVOUR}" == "ubuntu-mate" ] || [ "${FLAVOUR}" == "xubuntu" ]; then
            chroot $R apt-get -y install xserver-xorg-video-fbturbo
        fi

        # omxplayer
        # - Requires: libpcre3 libfreetype6 fonts-freefont-ttf dbus libssl1.0.0 libsmbclient libssh-4
        cp deb/omxplayer_0.3.7-git20160923-dfea8c9_armhf.deb $R/tmp/omxplayer.deb
        chroot $R apt-get -y install /tmp/omxplayer.deb

        # Make Ubiquity "compatible" with the Raspberry Pi Foundation kernel.
        if [ ${OEM_CONFIG} -eq 1 ]; then
            cp plugininstall-${RELEASE}.py $R/usr/share/ubiquity/plugininstall.py
        fi
    fi

    # Install Raspberry Pi system tweaks
    chroot $R apt-get -y install fbset raspberrypi-sys-mods

    # Enable hardware random number generator
    chroot $R apt-get -y install rng-tools

    # copies-and-fills
    # Create /spindel_install so cofi doesn't segfault when chrooted via qemu-user-static
    touch $R/spindle_install
    cp deb/raspi-copies-and-fills_0.5-1_armhf.deb $R/tmp/cofi.deb
    chroot $R apt-get -y install /tmp/cofi.deb

    # Add /root partition resize
    if [ "${FS}" == "ext4" ]; then
        CMDLINE_INIT="init=/usr/lib/raspi-config/init_resize.sh"
        # Add the first boot filesystem resize, init_resize.sh is
        # shipped in raspi-config.
        cp files/resize2fs_once	$R/etc/init.d/
        chroot $R /bin/systemctl enable resize2fs_once        
    else
        CMDLINE_INIT=""
    fi
    chroot $R apt-get -y install raspi-config

    # Add /boot/config.txt
    cp files/config.txt $R/boot/

    # Add /boot/cmdline.txt
    echo "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=${FS} elevator=deadline fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles ${CMDLINE_INIT}" > $R/boot/cmdline.txt
    # Enable VC4 on composited desktops
    if [ "${FLAVOUR}" == "kubuntu" ] || [ "${FLAVOUR}" == "ubuntu" ] || [ "${FLAVOUR}" == "ubuntu-gnome" ]; then
        echo "dtoverlay=vc4-kms-v3d" >> $R/boot/config.txt
    fi

    # Set up fstab
    cat <<EOM >$R/etc/fstab
proc            /proc           proc    defaults          0       0
/dev/mmcblk0p2  /               ${FS}   defaults,noatime  0       1
/dev/mmcblk0p1  /boot/          vfat    defaults          0       2
EOM
}

function install_software() {

    if [ "${FLAVOUR}" != "ubuntu-minimal" ]; then
        # FIXME - Replace with meta packages(s)

        # Python
        chroot $R apt-get -y install \
        python-minimal python3-minimal \
        python-dev python3-dev \
        python-pip python3-pip \
        python-setuptools python3-setuptools

        # Python extras a Raspberry Pi hacker expects to be available ;-)
        chroot $R apt-get -y install \
        raspi-gpio \
        python-rpi.gpio python3-rpi.gpio \
        python-gpiozero python3-gpiozero \
        pigpio python-pigpio python3-pigpio \
        python-serial python3-serial \
        python-spidev python3-spidev \
        python-smbus python3-smbus \
        python-astropi python3-astropi \
        python-drumhat python3-drumhat \
        python-envirophat python3-envirophat \
        python-pianohat python3-pianohat \
        python-pantilthat python3-pantilthat \
        python-scrollphat python3-scrollphat \
        python-st7036 python3-st7036 \
        python-sn3218 python3-sn3218 \
        python-piglow python3-piglow \
        python-microdotphat python3-microdotphat \
        python-mote python3-mote \
        python-motephat python3-motephat \
        python-explorerhat python3-explorerhat \
        python-rainbowhat python3-rainbowhat \
        python-sense-hat python3-sense-hat \
        python-sense-emu python3-sense-emu sense-emu-tools \
        python-picamera python3-picamera \
        python-rtimulib python3-rtimulib \
        python-pygame

        chroot $R pip2 install codebug_tether
        chroot $R pip3 install codebug_tether
    fi

    if [ "${FLAVOUR}" == "ubuntu-mate" ]; then
        # Install the Minecraft PPA
        chroot $R apt-add-repository -y ppa:flexiondotorg/minecraft
        chroot $R apt-add-repository -y ppa:ubuntu-mate-dev/welcome
        chroot $R apt-get update

        # Python IDLE
        chroot $R apt-get -y install idle idle3

        # YouTube DL
        chroot $R apt-get -y install ffmpeg rtmpdump
        chroot $R apt-get -y --no-install-recommends install ffmpeg youtube-dl
        chroot $R apt-get -y install youtube-dlg

        # Scratch (nuscratch)
        # - Requires: scratch and used to require wiringpi
        cp deb/scratch_1.4.20131203-2_all.deb $R/tmp/wiringpi.deb
        cp deb/wiringpi_2.32_armhf.deb $R/tmp/scratch.deb
        chroot $R apt-get -y install /tmp/wiringpi.deb
        chroot $R apt-get -y install /tmp/scratch.deb
        chroot $R apt-get -y install nuscratch

        # Minecraft
        chroot $R apt-get -y install minecraft-pi python-picraft python3-picraft --allow-downgrades

        # Sonic Pi
        cp files/jackd.conf $R/tmp/
        chroot $R debconf-set-selections -v /tmp/jackd.conf
        chroot $R apt-get -y install sonic-pi
    fi
}

function clean_up() {
    rm -f $R/etc/apt/*.save || true
    rm -f $R/etc/apt/sources.list.d/*.save || true
    rm -f $R/etc/resolvconf/resolv.conf.d/original
    rm -f $R/run/*/*pid || true
    rm -f $R/run/*pid || true
    rm -f $R/run/cups/cups.sock || true
    rm -f $R/run/uuidd/request || true
    rm -f $R/etc/*-
    rm -rf $R/tmp/*
    rm -f $R/var/crash/*
    rm -f $R/var/lib/urandom/random-seed

    # Build cruft
    rm -f $R/var/cache/debconf/*-old || true
    rm -f $R/var/lib/dpkg/*-old || true
    rm -f $R/var/cache/bootstrap.log || true
    truncate -s 0 $R/var/log/lastlog || true
    truncate -s 0 $R/var/log/faillog || true

    # SSH host keys
    rm -f $R/etc/ssh/ssh_host_*key
    rm -f $R/etc/ssh/ssh_host_*.pub

    # Clean up old Raspberry Pi firmware and modules
    rm -f $R/boot/.firmware_revision || true
    rm -rf $R/boot.bak || true
    rm -rf $R/lib/modules.bak || true

    # Potentially sensitive.
    rm -f $R/root/.bash_history
    rm -f $R/root/.ssh/known_hosts

    # Remove bogus home directory
    if [ -d $R/home/${SUDO_USER} ]; then
        rm -rf $R/home/${SUDO_USER} || true
    fi

    # Machine-specific, so remove in case this system is going to be
    # cloned.  These will be regenerated on the first boot.
    rm -f $R/etc/udev/rules.d/70-persistent-cd.rules
    rm -f $R/etc/udev/rules.d/70-persistent-net.rules
    rm -f $R/etc/NetworkManager/system-connections/*
    [ -L $R/var/lib/dbus/machine-id ] || rm -f $R/var/lib/dbus/machine-id
    echo '' > $R/etc/machine-id

    # Enable cofi
    if [ -e $R/etc/ld.so.preload.disabled ]; then
        mv -v $R/etc/ld.so.preload.disabled $R/etc/ld.so.preload
    fi

    rm -rf $R/tmp/.bootstrap || true
    rm -rf $R/tmp/.minimal || true
    rm -rf $R/tmp/.standard || true
    rm -rf $R/spindle_install || true
}

function make_raspi2_image() {
    # Build the image file
    local FS="${1}"
    local SIZE_IMG="${2}"
    local SIZE_BOOT="64MiB"

    if [ "${FS}" != "ext4" ] && [ "${FS}" != 'f2fs' ]; then
        echo "ERROR! Unsupport filesystem requested. Exitting."
        exit 1
    fi

    # Remove old images.
    rm -f "${BASEDIR}/${IMAGE}" || true

    # Create an empty file file.
    dd if=/dev/zero of="${BASEDIR}/${IMAGE}" bs=1MB count=1
    dd if=/dev/zero of="${BASEDIR}/${IMAGE}" bs=1MB count=0 seek=$(( ${SIZE_IMG} * 1000 ))

    # Initialising: msdos
    parted -s ${BASEDIR}/${IMAGE} mktable msdos
    echo "Creating /boot partition"
    parted -a optimal -s ${BASEDIR}/${IMAGE} mkpart primary fat32 1 "${SIZE_BOOT}"
    echo "Creating /root partition"
    parted -a optimal -s ${BASEDIR}/${IMAGE} mkpart primary ext4 "${SIZE_BOOT}" 100%

    PARTED_OUT=$(parted -s ${BASEDIR}/${IMAGE} unit b print)
    BOOT_OFFSET=$(echo "${PARTED_OUT}" | grep -e '^ 1'| xargs echo -n \
    | cut -d" " -f 2 | tr -d B)
    BOOT_LENGTH=$(echo "${PARTED_OUT}" | grep -e '^ 1'| xargs echo -n \
    | cut -d" " -f 4 | tr -d B)

    ROOT_OFFSET=$(echo "${PARTED_OUT}" | grep -e '^ 2'| xargs echo -n \
    | cut -d" " -f 2 | tr -d B)
    ROOT_LENGTH=$(echo "${PARTED_OUT}" | grep -e '^ 2'| xargs echo -n \
    | cut -d" " -f 4 | tr -d B)

    BOOT_LOOP=$(losetup --show -f -o ${BOOT_OFFSET} --sizelimit ${BOOT_LENGTH} ${BASEDIR}/${IMAGE})
    ROOT_LOOP=$(losetup --show -f -o ${ROOT_OFFSET} --sizelimit ${ROOT_LENGTH} ${BASEDIR}/${IMAGE})
    echo "/boot: offset ${BOOT_OFFSET}, length ${BOOT_LENGTH}"
    echo "/:     offset ${ROOT_OFFSET}, length ${ROOT_LENGTH}"

    mkfs.vfat -n PI_BOOT -S 512 -s 16 -v "${BOOT_LOOP}"
    if [ "${FS}" == "ext4" ]; then
        mkfs.ext4 -L PI_ROOT -m 0 -O ^huge_file "${ROOT_LOOP}"
    else
        mkfs.f2fs -l PI_ROOT -o 1 "${ROOT_LOOP}"
    fi

    MOUNTDIR="${BUILDDIR}/mount"
    mkdir -p "${MOUNTDIR}"
    mount -v "${ROOT_LOOP}" "${MOUNTDIR}" -t "${FS}"
    mkdir -p "${MOUNTDIR}/boot"
    mount -v "${BOOT_LOOP}" "${MOUNTDIR}/boot" -t vfat
    rsync -aHAXx "$R/" "${MOUNTDIR}/"
    sync
    umount -l "${MOUNTDIR}/boot"
    umount -l "${MOUNTDIR}"
    losetup -d "${ROOT_LOOP}"
    losetup -d "${BOOT_LOOP}"
}

function make_hash() {
    local FILE="${1}"
    local HASH="sha256"
    local KEY="FFEE1E5C"
    if [ ! -f ${FILE}.${HASH}.sign ]; then
        if [ -f ${FILE} ]; then
            ${HASH}sum ${FILE} > ${FILE}.${HASH}
            sed -i -r "s/ .*\/(.+)/  \1/g" ${FILE}.${HASH}
            gpg --default-key ${KEY} --armor --output ${FILE}.${HASH}.sign --detach-sig ${FILE}.${HASH}
        else
            echo "WARNING! Didn't find ${FILE} to hash."
        fi
    else
        echo "Existing signature found, skipping..."
    fi
}

function make_tarball() {
    if [ ${MAKE_TARBALL} -eq 1 ]; then
        rm -f "${BASEDIR}/${TARBALL}" || true
        tar -cSf "${BASEDIR}/${TARBALL}" $R
        make_hash "${BASEDIR}/${TARBALL}"
    fi
}

function compress_image() {
    if [ ! -e "${BASEDIR}/${IMAGE}.xz" ]; then
        echo "Compressing to: ${BASEDIR}/${IMAGE}.xz"
        xz ${BASEDIR}/${IMAGE}
    fi
    make_hash "${BASEDIR}/${IMAGE}.xz"
}

function stage_01_base() {
    R="${BASE_R}"
    bootstrap
    mount_system
    generate_locale
    apt_sources
    apt_upgrade
    ubuntu_minimal
    ubuntu_standard
    apt_clean
    umount_system
    sync_to "${DESKTOP_R}"
}

function stage_02_desktop() {
    R="${DESKTOP_R}"
    mount_system

    if [ "${FLAVOUR}" == "ubuntu-minimal" ] || [ "${FLAVOUR}" == "ubuntu-standard" ]; then
        echo "Skipping desktop install for ${FLAVOUR}"
    elif [ "${FLAVOUR}" == "lubuntu" ]; then
        install_meta ${FLAVOUR}-core --no-install-recommends
        install_meta ${FLAVOUR}-desktop --no-install-recommends
    elif [ "${FLAVOUR}" == "ubuntu-mate" ]; then
        # Install meta packages the "old" way for Xenial
        if [ "${RELEASE}" == "xenial" ]; then
            install_meta ${FLAVOUR}-core --no-install-recommends
            install_meta ${FLAVOUR}-desktop --no-install-recommends
        else
            install_meta ${FLAVOUR}-core
            install_meta ${FLAVOUR}-desktop
        fi
    elif [ "${FLAVOUR}" == "xubuntu" ]; then
        install_meta ${FLAVOUR}-core
        install_meta ${FLAVOUR}-desktop
    else
        install_meta ${FLAVOUR}-desktop
    fi

    create_groups
    create_user
    prepare_oem_config
    configure_ssh
    configure_network
    disable_services
    apt_upgrade
    apt_clean
    umount_system
    clean_up
    sync_to ${DEVICE_R}
    make_tarball
}

function stage_03_raspi2() {
    R=${DEVICE_R}
    mount_system
    configure_hardware ${FS_TYPE}
    install_software
    apt_upgrade
    apt_clean
    clean_up
    umount_system
    make_raspi2_image ${FS_TYPE} ${FS_SIZE}
}

function stage_04_corrections() {
    R=${DEVICE_R}
    mount_system

    if [ "${RELEASE}" == "xenial" ]; then
      # Add the MATE Desktop PPA for Xenial
      if [ "${FLAVOUR}" == "ubuntu-mate" ]; then
        chroot $R apt-add-repository -y ppa:ubuntu-mate-dev/xenial-mate
        chroot $R apt-get update
        chroot $R apt-get -y dist-upgrade
      fi

      # Upgrade Xorg using HWE.
      chroot $R apt-get install -y --install-recommends \
      xserver-xorg-core-hwe-16.04 \
      xserver-xorg-input-all-hwe-16.04 \
      xserver-xorg-input-evdev-hwe-16.04 \
      xserver-xorg-input-synaptics-hwe-16.04 \
      xserver-xorg-input-wacom-hwe-16.04 \
      xserver-xorg-video-all-hwe-16.04 \
      xserver-xorg-video-fbdev-hwe-16.04 \
      xserver-xorg-video-vesa-hwe-16.04
    fi

    # Run post build scripts if specified
    if [ -z "POST_BUILD_SCRIPT" ]; then
        echo "No post-build scripts specified."
    else
        for var in "${POST_BUILD_SCRIPT[@]}"
        do
        echo "Running post-build script: ${var}"
            source "post-build-scripts/${var}"
        done
    fi

    apt_clean
    clean_up
    umount_system
    make_raspi2_image ${FS_TYPE} ${FS_SIZE}
}

stage_01_base
stage_02_desktop
stage_03_raspi2
stage_04_corrections
#compress_image