#
# OOPS and assertions
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

OOPS()
{
log "OOPS $*"
exit 1
}

# Args: Val Val [explain]
# make sure the arguments are the same
assert()
{
ASSERTCMP="$1"
ASSERTVAL="$2"
shift 2 || OOPS "too few arguments to assert: $*"
[ ".$ASSERTCMP" = ".$ASSERTVAL" ] || OOPS "assert mismatch: wanted '$ASSERTCMP' got '$ASSERTVAL' $*"
}

# As assert, but error if both are the same
unassert()
{
ASSERTCMP="$1"
ASSERTVAL="$2"
shift 2 || OOPS "too few arguments to unassert: $*"
[ ".$ASSERTCMP" = ".$ASSERTVAL" ] && OOPS "unassert match: got '$ASSERTCMP' $*"
}
