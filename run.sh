#!/bin/bash
# 
# This Works is placed under the terms of the Copyright Less License,
# see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

cd / || exit 1

stty -echo

export LC_ALL=C LANG=C

stamp()
{
NOW="`date +%Y%m%d-%H%M%S`"
echo "$NOW $*"
}

res()
{
echo "
###RES### $$-$cmdnr $*"
}

cmdnr=0
run()
{
let cmdnr++
echo "###RUN### $$-$cmdnr $*"
}

ign()
{
echo "###IGN### $$-$cmdnr $*"
}

oops()
{
stamp "OOPS $*"
echo "$NOW OOPS $*" >&2
exit 1
}

cmd_bye()
{
echo "###BYE###"
exit 0
}

x()
{
"$@"
}

ok()
{
x "$@"
ret=$?
[ 0 = $ret ] || ign $ret
}

cmd_run()
{
run "$*"
x "$@"
echo "
###RES### $$-$cmdnr $?"
}

# Requires output of "printansi -lp. file; echo EOF" on the other side
# This probably cannot transfer binary files correctly
cmd_copy_UNUSED()
{
let cmdnr++
echo "###COPY### $$-$cmdnr $*"
while	read -r line
do
	case "$line" in
	EOF)	break;;
	.)	eval echo "\$'${line#.}'";;
	*)	oops "inproper terminated copy command: $line";;
	esac
done > "$*"
echo "###RES### $$-$cmdnr 0"
}

cmd_copy()
{
let cmdnr++
echo "###COPY### $$-$cmdnr $*"
uudecode
echo "###RES### $$-$cmdnr $?"
}

# Send a fake RESULT in case we are a sub call
echo "###RES### $$-$cmdnr 0"
while	echo "###PROMPT### $$-$cmdnr"
	read -r cmd rest
do
	case "$cmd" in
	bye|run|copy)	;;
	*)		oops unknown cmd;;
	esac
	"cmd_$cmd" $rest
done

