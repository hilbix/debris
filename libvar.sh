#
# Easy variable handling
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

# Args: Variable otherVariable
getvar()
{
[ 2 = $# ] || OOPS "wrong number of arguments: getvar $*"
eval $1=\"\$$2\"
}

# Copy variables: TO$suffix1=FROM$suffix1 TO$suffix2=FROM$suffix2 ...
# Args: TO FROM SUFFIX...
getvars()
{
getvarto="$1"
getvarfrom="$2"
shift 2 || OOPS "wrong number of arguments: getvars $*"
for xset
do
	getvar $getvarto$xset $getvarfrom$xset
done
}

# Args: VAR VAL...
setvar()
{
[ 2 = $# ] || OOPS "wrong number of arguments: setvar $*"
eval $1=\"\$2\"
}

logvar()
{
setvar "$@"
logf "set %20s = %s" "$@"
}

# Initialize variables: VAR$suffix1=VAL VAR$suffix2=VAL ...
# Args: VAR VAL SUFFIX...
setvars()
{
setvarto="$1"
setvarval="$2"
shift 2 || OOPS "wrong number of arguments: setvars $*"
for xset
do
	setvar $setvarto$xset "$setvarval"
done
}

# Usage: `wordcount $var` (without quotes) to expand into words
wordcount()
{
echo $#
}

