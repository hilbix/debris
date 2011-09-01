#!/bin/bash
#
# DebRIS: DEBian Remote Install Service
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

########################################################################
# SETUP START #
########################################################################

DISK1=/dev/sda
DISK2=/dev/sdb

PARTTYPE=msdos

PART1SIZE=200
PART1FLAG="boot raid"
PART1TYPE=ext2
PART1NAME=boot
PART1PATH=/boot

PART2SIZE=128
PART2FLAG="crypt"
PART2NAME=swap

PART3SIZE=100%
PART3FLAG="raid LVM"
PART3NAME=main

PART4SIZE=10
PART4FLAG=LVM
PART4NAME=data

LVM1SIZE1=200
LVM1FLAG1=""
LVM1TYPE1=ext4
LVM1PATH1=/

LVM1SIZE2=2000
LVM1FLAG2=""
LVM1TYPE2=ext4
LVM1PATH2=/usr

LVM1SIZE3=1000
LVM1FLAG3=""
LVM1TYPE3=ext4
LVM1PATH3=/var

LVM1SIZE4=100
LVM1FLAG4=""
LVM1TYPE4=ext4
LVM1PATH4=/home

########################################################################
# SETUP END #
########################################################################

# dmsetup -v status

. ./step1.sh
. ./step2.sh
. ./step3.sh

