#
# Subroutines to talk to the remote
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

# Internal: split the last line read from remote
setlast()
{
last="${*%$CR}"
lastfirst="$1"
lasttag="$2"
lastcode="${3%$CR}"
[ -n "$last" ] || return 0
lastline="$*"
log "got $lastline"
}

# Get a line from remote
getline()
{
read -r$1 line <&3 && setlast $line
}

# Send a line to remote
send()
{
logf "SEND %s" "$*"
ptybufferconnect -eqnp "$*" .sock
}

# Wait for some reply from remote
waitfor()
{
output=
log "WAITING FOR $1 ($2)"
while	getline $2
do
	if	[ ".$lastfirst" = ".$1" ]
	then
		log "FOUND $1"
		output="${output#$LF}"
		return
	fi
	[ -n "$last" ] &&
	output="$output
$last"
done
OOPS "timeout waiting for $1: $lastline"
}

# Execute a command on remote
# This remembers all the calls in CALL$nr
CALLS=
calls=0
# Args: "command to send" [command to log]
sendcmd()
{
waitfor "###PROMPT###" t30

let calls++
CALLS="$CALLS $calls"
setvar CALL$calls "${2:-$1}"

send "$1"
}

invoke()
{
sendcmd "run $*"
waitfor "###RUN###" t30
}

result()
{
[ 2 = "$#" ] || OOPS "wrong number of arguments: result $*"

waitfor "###RES###"
assert "$2" "$lasttag"
assert 0 "$lastcode"
setvar CALLOUT$1 "$output"
}

call()
{
invoke "$@"
result $calls "$lasttag"
}

CALLSTACK=0
callsub()
{
invoke "$@"

let callstack++
setvar CALLS$callstack "$calls"
setvar CALLT$callstack "$lasttag"
lastcallsubtag="$lasttag"

waitfor "###RES###"
assert 0 "$lastcode"
# Check that the ID changed, such that we are sure another ./run.sh runs.
[ ".$lastcallsubtag" = ".$lasttag" ] && OOPS "callsub did not work, command returned"
}

callend()
{
getvar callC "CALLS$callstack"
getvar callT "CALLT$callstack"
result $callC "$callT"
let callstack--
}

pullvar()
{
VAR="$1"
shift
call "$@"
setvar GET$VAR "$output"
log "GET$VAR set to '$output'"
}

piped()
{
call "$@"
log "piped '$output'"
echo "$output"
}

copy()
{
sendcmd copy "copy $*"
waitfor "###COPY###" t30

# Well, this is not yet supported by ptybufferconnect
uuencode "$1" "$2" | socat - unix:.sock

result $calls "$lasttag"
}

procedure()
{
while read -r line
do
	case "$line" in
	\#*|''|' '*)	;;
	*)		call "$line";;
	esac
done
}

