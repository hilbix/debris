#!/bin/bash

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
set -x
wget -c "$1" || exit
bnam="`basename "$1" .tar.gz`"
md5sum "$bnam.tar.gz" |
{
read -r md5 rest || exit
if [ ".$2" != ".$md5" ]
then
	echo "ERROR: $bnam MD5 mismatch: wanted $2 got $md5" >&2
	exit 1
fi
shift 2 || exit
rm -rf "$bnam" "$@"
tar xfz "$bnam.tar.gz" || exit
make -C "$bnam" || exit
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
if	! check "$@"
then
	echo "cannot create $a from `basename "$1"`" >&2
	exit 1
fi
}

tt http://www.scylla-charybdis.com/download/ptybuffer-0.6.4-20071020-171424.tar.gz 8bbc9f57c9ca5a02a139bc0407ac2ea9 ptybuffer ptybufferconnect

