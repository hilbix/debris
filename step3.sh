#!/bin/bash

. ./lib.sh

mksources()
{
echo " deb     $MIRROR $RELEASE           main contrib non-free"
echo " deb     http://security.debian.org/  $RELEASE/updates   main contrib non-free"

case "$RELEASE" in
squeeze)
	echo " deb     $MIRROR $RELEASE-updates   main contrib non-free"
	;;
esac
}

debdoubler()
{
sed -n 'p;s/deb     /deb-src /p'
}

mkinterfaces()
{
cat <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
}

mkfstab()
{
cat <<EOF
proc /proc    proc     defaults             0 0
none /dev     devtmpfs mode=0755            0 0
none /sys     sysfs    noexec,nosuid,nodev  0 0
EOF
}

echo "$HOSTNAME" | copy /ins/etc/hostname
echo "$DOMAINNAME"

mksources | debdoubler | copy /ins/etc/apt/sources.list
mkinterfaces | copy /ins/etc/network/interfaces
mkfstab | copy /ins/etc/fstab

copy run.sh /ins/run.sh
callsub chroot /ins /run.sh

procedure <<EOF

ok umount /dev
ok umount /sys
ok umount /proc

mount /proc
mount /dev
mount /sys

apt-get update
apt-get install $KERN $PACKAGES
EOF

