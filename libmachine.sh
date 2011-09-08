#
# Subroutines to read in the machine definition file ($MACHINE.debris)
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

[ -b "$MACHINE" ] || MACHINE="${1:-TEST}"
[ -f "./$MACHINE.debris" ] || OOPS "missing file $MACHINE.debris, example TEST.debris"

HOST()
{
logvar HOSTNAME   "${1%%.*}"
logvar DOMAINNAME "${1#*.}"
}

# CONNECTION type
# types (currently): local
CONN()
{
CONNECTIONTYPE="$1"
shift || WRONG CONN "$*"
CONNECTIONARGS="$*"
}

ARCH()
{
logvar ARCH    "${1:-i386}"
logvar RELEASE "${2:-squeeze}"
logvar BASE    "${3:-minbase}"
logvar MIRROR  "${4:-http://cdn.debian.net/debian/}"
}

KERN()
{
logvar KERN "$@"
}

PACK()
{
logvar PACKAGES "$*"
}

PROXY=
proxyline=
PROXY()
{
logvar PROXY "$@"
proxyline="export http_proxy=$1"
}

DISKS=""
DISKNUMBER=0
DISK()
{
let DISKNUMBER++
DISKS="$DISKS $DISKNUMBER"
logvar DISK$DISKNUMBER $*
}

PARTITIONS=""
PARTNUMBER=0
PART()
{
let PARTNUMBER++
PARTITIONS="$PARTITIONS $PARTNUMBER"
logvar PART${PARTNUMBER}NAME "$1"
setvar PART_$1 $PARTNUMBER
logvar PART${PARTNUMBER}SIZE "$2"
shift 2 || WRONG PART "$*"
logvar PART${PARTNUMBER}FLAG "$*"
}

FILESYSTEMS=""
FSNUMBER=0
# FS container [type] /path|name [size]
FS()
{
let FSNUMBER++
FILESYSTEMS="$FILESYSTEMS $FSNUMBER"

logvar FS${FSNUMBER}BASE $1

case "$2" in
/*)	logvar FS${FSNUMBER}TYPE ext4;;
*)	shift; logvar FS${FSNUMBER}TYPE $1;;
esac

logvar FS${FSNUMBER}PATH $2
logvar FS${FSNUMBER}SIZE "$3"
}

. "./$MACHINE.debris"

