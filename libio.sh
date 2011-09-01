#
# Subroutines to talk to the remote
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

# Args: the line to split
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

# Args: [tSECONDS]
# Get a line from remote
getline()
{
read -r$1 line <&3 && setlast $line
}

# Args: Line to send (all arguments blank separated)
# Send a line to remote
send()
{
logf "SEND %s" "$*"
build/ptybufferconnect -eqnp "$*" .sock
}

# Args: TAG_to_wait_for [getline_option]
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

# Send a command on remote
# The commands are remembered in CALL$calls
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

# Args see sendcmd
# Invoke a command 
# This is send it to remote and wait for it to be executed
invoke()
{
sendcmd "run $*"
waitfor "###RUN###" t30
}

# Args: $calls "$lasttag"
# Wait for the result.
# Remember the output in CALLOUT$callnr
# Note that this can be called later, such that
# the caller needs to remember $calls/$lasttag
result()
{
[ 2 = "$#" ] || OOPS "wrong number of arguments: result $*"

waitfor "###RES###"
assert "$2" "$lasttag" "(chain of command out of sync)"
assert 0 "$lastcode" "(command return value)"
setvar CALLOUT$1 "$output"
}

# Args see sendcmd
# Send some command to remote and wait for result
call()
{
invoke "$@"
result $calls "$lasttag"
}

# Args see sendcmd
# Fork off another run.sh, like in "chroot /ins /run.sh"
# This pushes the arguments to "result" onto CALLS/CALLT
CALLSTACK=0
callsub()
{
invoke "$@"

let callstack++
setvar CALLS$callstack "$calls"
setvar CALLT$callstack "$lasttag"
lastcallsubtag="$lasttag"

waitfor "###RES###"
assert 0 "$lastcode" "(command return value)"
# Check that the ID changed, such that we are sure another ./run.sh runs.
unassert "$lastcallsubtag" "$lasttag" "callsub did not work, command returned"
}

# No args
# Make sure that the command forked by callsub returned
callend()
{
getvar callC "CALLS$callstack"
getvar callT "CALLT$callstack"
result $callC "$callT"
let callstack--
}

# Args: VAR (rest see sendcmd)
# Fetch the output of a remote command into a variable
pullvar()
{
VAR="$1"
shift || OOPS "too few arguments to pullvar: $*"
call "$@"
setvar GET$VAR "$output"
log "GET$VAR set to '$output'"
}

# Args see sendcmd
# Pipe output of remote command to something
# (pipe ls | consumer)
piped()
{
call "$@"
log "piped >>>>>>>>>>$output<<<<<<<<<<"
echo "${output:1}"
}

# Args: src(local) dest(remote) [ignored for now]
# Copy a local file onto the remote
# This needs run.sh already running
copy()
{
sendcmd copy "copy $*"
waitfor "###COPY###" t30

# Stdin is not yet supported by ptybufferconnect
uuencode "$1" "$2" | socat - unix:.sock

result $calls "$lasttag"
}

# procedure << EOF
# cmds
# EOF
# invoke a bunch of remote commands which all must return 0
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

