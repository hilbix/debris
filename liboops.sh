#
# OOPS and assertions
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

OOPS()
{
logf "OOPS %s" "$*"
exit 1
}

WRONG()
{
OOPS "wrong number of arguments: $*"
}

INTERN()
{
OOPS "internal error in $*"
}

# Args: Val Val [explain]
# make sure the arguments are the same
assert()
{
ASSERTCMP="$1"
ASSERTVAL="$2"
shift 2 || WRONG assert "$*"
[ ".$ASSERTCMP" = ".$ASSERTVAL" ] || OOPS "assert mismatch: wanted '$ASSERTCMP' got '$ASSERTVAL' $*"
}

# As assert, but error if both are the same
unassert()
{
ASSERTCMP="$1"
ASSERTVAL="$2"
shift 2 || WRONG unassert "$*"
[ ".$ASSERTCMP" = ".$ASSERTVAL" ] && OOPS "unassert match: got '$ASSERTCMP' $*"
}
