#
# Logging and output
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

now()
{
NOW="`date +%Y%m%d-%H%M%S`"
}

rm -f TMP.log
log()
{
echo "$*" >&2
echo "$*" >> TMP.log
}

logf()
{
LOGFORMAT="$1"
shift || WRONG logf "$*"
now
printf "%s $LOGFORMAT\\n" "$NOW" "$@" | tee -a TMP.log SETUP.log >&2
}

logcalls()
{
for c in $CALLS
do
	getvar call CALL$c
	logf "%3d %s" $c "$call"
	getvar out CALLOUT$c
	[ -z "$out" ] ||
	logf "  = %s" "$out"
done
}

sizestring()
{
let byte=$1

let gb=byte/1024/1024/1024
let byte-=gb*1024*1024*1024
[ 0 = $gb ] || printf " %dG" $gb

let mb=byte/1024/1024
let byte-=mb*1024*1024
[ 0 = $mb ] || printf " %dM" $mb

let kb=byte/1024
let byte-=kb*1024
[ 0 = $kb ] || printf " %dK" $kb

[ 0 = $byte -a 000 != $gb$mb$kb ] || printf "%d" $byte
printf B
}

logsect()
{
LOGSECTORS="$1"
shift || WRONG logsect "$*"
logsize="`sizestring $[LOGSECTORS*2048]`"
logf "%-20s %10d (%s)" "`printf "$@"`:" "$LOGSECTORS" "${logsize# }"
}

GATHER=
gather()
{
[ -z "$GATHER" ] || logf "%s" "$GATHER"
GATHER=""
gadd "$@"
}

gadd()
{
case "$#" in
0)	;;
1)	GATHER="$GATHER$1";;
*)	GATHER="$GATHER`printf "$@"`";;
esac
}
