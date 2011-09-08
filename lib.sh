#
# Include all of the library
#
# Following is true for all files included.
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

if [ already_included != "$HAVE_DEBRIS_LIB" ]
then

. ./libconst.sh
. ./liblog.sh
. ./liboops.sh

[ 0 = "`id -u`" ] || OOPS "must run as root"

. ./libvar.sh
. ./libio.sh
. ./libpart.sh

# Build missing tools
# This step shall vanish in future
. ./libbuild.sh

# Read in the machine definition file ($MACHINE.debris)
# $MACHINE defaults to "$1" which defaults to "TEST".
. ./libmachine.sh

# Connect to the machine
. ./libconnect.sh

fi
HAVE_DEBRIS_LIB=already_included
