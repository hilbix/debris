#!/bin/bash

. ./lib.sh

# THIS IS WRONG FOR NOW
procedure <<EOF

ok umount /dev/md/md1
ok umount /dev/md/md3

mke2fs -L boot /dev/md/md1
mke2fs -L root -t ext4 /dev/md/md3

mkdir -p /ins
mount /dev/md/md3 ins
mkdir -p /ins/boot
mount /dev/md/md1 /ins/boot

$proxyline
debootstrap --arch=$ARCH --variant=$BASE $RELEASE /ins $MIRROR

EOF

