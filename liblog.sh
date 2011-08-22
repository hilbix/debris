#
# Logging and output
#

now()
{
NOW="`date +%Y%m%d-%H%M%S`"
}

log()
{
echo "$*" >&2
}

logf()
{
LOGFORMAT="$1"
shift
now
printf "%s $LOGFORMAT\\n" "$NOW" "$@" >&2
printf "%s $LOGFORMAT\\n" "$NOW" "$@" >> SETUP.log
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
shift
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
