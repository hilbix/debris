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

mkdir -p /ins/root/.ssh
copy ~/.ssh/authorized_keys /ins/root/.ssh/authorized_keys

echo "$HOSTNAME" | copy /ins/etc/hostname
echo "$HOSTNAME.$DOMAINNAME" | copy /ins/etc/mailname

mksources | debdoubler | copy /ins/etc/apt/sources.list
mkinterfaces | copy /ins/etc/network/interfaces
mkfstab | copy /ins/etc/fstab

copy run.sh /ins/run.sh
callsub chroot /ins /run.sh

procedure <<EOF

passwd -d root
ok killall cron exim4 mdadm

mount -a

$proxyline
apt-get update
apt-get -yq install firmware-linux-nonfree ssh mdadm lvm2 dhcp3-client
apt-get -yq install $PACKAGES
apt-get -yq install $KERN
EOF


grubhack()
{
case "$line" in

*\ Linux\ command\ line\ *)
	send "$KOPT";;

*Enter\ the\ items\ you\ want\ to\ select,\ *)
	devs=""
	for d in $DISKS
	do
		getdisk $d
		devs="$devs $diskDEV"
	done
	send "${devs# }"
	;;
esac
}

callback grubhack apt-get -yq install grub-pc

# Missing links
# See http://juerd.nl/site.plp/debianraid
#	Set FSCKFIX=yes in /etc/default/rcS
# dpkg-reconfigure locales
# dpkg-reconfigure tzdata
#
# pool.ntp.org

