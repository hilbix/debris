#
# Subroutines to create the connection
#
# FD3 input FD (shell reads data from remote)
# FD4 output FD (shell writes data to remote)
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

conn_ssh()
{
build/ptybuffer -cfo DEBUG.log .sock ssh -acxqe none "$@" ./run.sh
}

conn_local()
{
build/ptybuffer -cfo DEBUG.log .sock ./run.sh
}

# Fork off new script, killing the old one, just in case
while	conn_$CONNECTIONTYPE $CONNECTIONARGS
	[ 42 = $? ]
do
	timeout 2 build/ptybufferconnect -qnp bye .sock
	timeout 2 build/ptybufferconnect -qnp "$EOF" .sock
	timeout 2 build/ptybufferconnect -qnp "$INTR" .sock
done

exec 3< <(build/ptybufferconnect -n .sock) || OOPS "cannot connect to input socket"
exec 4> >(socat - unix:.sock) || OOPS "cannot connect to output socket"

