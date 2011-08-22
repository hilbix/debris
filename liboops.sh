#
# OOPS and assertions
#

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
shift
[ ".$ASSERTCMP" = ".$1" ] || OOPS "mismatch, wanted '$ASSERTCMP' got '$*'"
}

# As assert, but error if both are the same
unassert()
{
ASSERTCMP="$1"
shift
[ ".$ASSERTCMP" = ".$1" ] && OOPS "mismatch, wanted '$ASSERTCMP' got '$*'"
}
