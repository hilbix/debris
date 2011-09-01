#
# Constants
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

INTR="`echo -ne \\\\03`"	# ^C
 EOF="`echo -ne \\\\04`"	# ^D
  CR="`echo -ne \\\\r`"		# ^M

  LF="
"				# ^J
  LF="${LF#$CR}"		# just to be sure
