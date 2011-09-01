#
# Subroutines to read in the machine definition file ($MACHINE.debris)
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

[ -b "$MACHINE" ] || MACHINE="${1:-TEST}"
[ -f "./$MACHINE.debris" ] || OOPS "missing file $MACHINE.debris, example TEST.debris"

HOST()
{
HOSTNAME="${1%%.*}"
DOMAINNAME="${1#*.}"
}

# CONNECTION type
# types (currently): local
CONN()
{
CONNECTIONTYPE="$1"
shift || OOPS "too few arguments to CONN: $*"
CONNECTIONARGS="$*"
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
doshift 2
logvar PART${PARTNUMBER}FLAG "$*"
}

FILESYSTEMS=""
FSNUMBER=0
# FS container [type] /path|name [size]
FS()
{
let FSNUMBER++
FILESYSTEMS="$FILESYSTEMS $FSNUMBER"

setvar FS${FSNUMBER}BASE $1

case "$2" in
/*)	setvar FS${FSNUMBER}TYPE ext4;;
*)	shift; setvar FS${FSNUMBER}TYPE $1;;
esac

setvar FS${FSNUMBER}PATH $2
setvar FS${FSNUMBER}SIZE "$2"
}

. "./$MACHINE.debris"

