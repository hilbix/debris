#!/bin/bash

. ./lib.sh

copy run.sh /ins/run.sh

callsub chroot /ins /run.sh

procedure <<EOF

mount -t proc proc /proc
mount -t devtmpfs -o mode=0755 none /dev
mount -t sysfs -o noexec,nosuid,nodev none /sys

EOF
