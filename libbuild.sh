#!/bin/bash
#
# Autobuild some tools which are required for now
# This is secure in the sense that I check the MD5 of the download
# (and these are my own tools, anyway).
#
# For convenience this can be called directly
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

BYE()
{
echo "libbuild.sh error $?:$PWD: $*" >&2
exit 1
}

check()
{
shift 2 || exit
for checkfile
do
	[ -x "build/$checkfile" ] || return
done
return 0
}

ttsub()
{
bnam="`basename "$1" .tar.gz`"

wget -c "$1" || exit

md5sum "$bnam.tar.gz" |
{
read -r md5 rest || BYE "cannot calc md5 for $bnam.tar.gz"
[ ".$2" = ".$md5" ] || BYE "$bnam MD5 mismatch: wanted $2 got $md5"

rm -rf "$bnam" "$@"
tar xfz "$bnam.tar.gz" || exit

make -C "$bnam" || exit

shift 2 || exit
for a
do
	ln -s "$bnam/$a" . || exit
done
}
exit 0
}

tt()
{
check "$@" ||
(
mkdir -p build
cd build && ttsub "$@"
) || exit 1
check "$@" || BYE "cannot create $a from `basename "$1"`"
}

checkfor()
{
for checkfile
do
	[ -n "`which "$checkfile"`" ] || BYE "missing tool: $checkfile"
done
}

# Build some of my tools
tt http://www.scylla-charybdis.com/download/ptybuffer-0.6.4-20071020-171424.tar.gz 8bbc9f57c9ca5a02a139bc0407ac2ea9 ptybuffer ptybufferconnect

# Check for some other
checkfor timeout socat parted blockdev debootstrap uudecode

