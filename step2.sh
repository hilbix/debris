#!/bin/bash

. ./lib.sh

procedure <<EOF

ok umount /dev/md/md1
ok umount /dev/md/md3

mke2fs -L boot /dev/md/md1
mke2fs -L root -t ext4 /dev/md/md3

mkdir -p /ins
mount /dev/md/md3 ins
mkdir -p /ins/boot
mount /dev/md/md1 /ins/boot

export http_proxy=http://192.168.57.1:8888
debootstrap --arch=i386 --variant=minbase squeeze /ins http://ftp2.de.debian.org/debian

EOF

