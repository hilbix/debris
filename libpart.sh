#
# Subroutines to calculate the partition layout
#
# Copyright (C) 2011 Valentin Hilbig <webmaster@scylla-charybdis.com>
# License see lib.sh

# 1-4 primary 5-9 would be extended when supported
PARTITIONS="${PARTITIONS:-1 2 3 4}"
DISKS="${DISKS:-1 2}"
SECTORALIGN="${SECTORALIGN:-64}"
PARTTYPE="${PARTTYPE:-msdos}"

# This calculates the partition layout
#
# Needs following variables:
#
# PARTTYPE	msdos
#		(no other types supported for now)
#
# PART#SIZE	in MB
# PART#FLAG	special flags for partition layout
#
# Sets following variables:
#
# PART#SECT	number of sectors of the given partition
# MAXPART	maximum partition

# Partitions for this disks, in MB
# TYPE=msdos FLAG=boot lba raid LVM
# special flags:
# crypt
# swap

# PART#SIZE in MB
# PART#FLAG special are "crypt" and "swap"


########################################################################

DISKsubs="SIZE"

getdisk()
{
setvar disk $1
getvar diskDEV DISK$1
getvars disk "GETDISK$1" $DISKsubs
}

#----------------------------------------------------------------------

PARTsubs="SIZE FLAG SECT START END"

# Args: partition#
getpart()
{
setvar part $1
getvars part PART$1 $PARTsubs
}

# Define some setting for a partition
# Args: sub value
# Can only be used after getpart
setpart()
{
[ 2 = $# ] || OOPS "wrong number of arguments: setpart $*"
setvar part$1 "$2"
setvar PART$part$1 "$2"
}

#----------------------------------------------------------------------

# Initially the devices list is empty
# It will be constructed out of the partitioning and disk data
DEVS=""
DEVnr=0
DEVsubs="ITER NAME CMD DISK PART FLAG DEV"
WNAME=4
WCMD=6
WDISK=3
WFLAG=7

# Create a device.  Internally they are numbered
# ID
getdevbyname()
{
[ 1 = $# ] || OOPS "wrong number of arguments: getdevbyname $*"
getvar dev DEV_$1_NR
if [ -z "$dev" ]
then
	# Add a device
	let DEVnr++
	dev=$DEVnr
	setvar DEV_$1_NR $DEVnr

	# Add dev to the list
	DEVS="$DEVS $DEVnr"

	# clean all device settings to avoid sideeffects
	setvars DEV$DEVnr "" $DEVsubs

	# setup name of device
	setvar  DEV${DEVnr}NAME $1
fi
getdev $dev
}

# get a device by number
getdev()
{
# remember the old values for easy processing
setvar  ldev $dev
getvars ldev dev $DEVsubs
setvar  dev  $1
getvars dev  DEV$1 $DEVsubs
}

# Args: sub value
# Can only be used after getdev
setdev()
{
[ 2 = $# ] || OOPS "wrong number of arguments: setdev $*"
setvar dev$1 "$2"
setvar DEV$dev$1 "$2"
}

# Append something to an arg
# Args: sub value
# Can only be used after getdev
adddev()
{
[ 2 = $# ] || OOPS "wrong number of arguments: setdev $*"
getvar old dev$1
[ -z "$old" ] || old="$old "
setvar dev$1 "$old$2"
setvar DEV$dev$1 "$old$2"
}

########################################################################

# Roll back any previous run.  Bring everything to a clean start.
partstep0()
{
piped cat /proc/mounts |
grep ' /ins/' |
while read -r fs rest
do
	call ok umount "$fs"
done
piped mdadm --detail --scan |
while read -r array dev uid
do
	call ok umount "$dev"
	call mdadm --stop "$dev"
done
}

########################################################################

# Read the devices and find the usable size
partstep1()
{
for d in $DISKS
do
	getdisk $d
	pullvar DISK${disk}SIZE blockdev --getsize $diskDEV
done

MINSIZE=$GETDISK1SIZE
for d in $DISKS
do
	getdisk $d
	logsect $diskSIZE 'disk %2d size' $disk
	[ "$MINSIZE" -lt "$diskSIZE" ] || MINSIZE=$diskSIZE
done

logsect $MINSIZE 'usable sector count'
}

########################################################################

# Calculate the number of sectors of the partitions with fixed size
# Sets PART#SECT
# sets total (number of free sectors)
partstep2()
{
total=MINSIZE
restpart=
for p in $PARTITIONS
do
	getpart $p
	let PART${p}DEV=$p

	case "$partSIZE" in
	*% | \*)	continue;;
	esac

	let sects=partSIZE*2048
	setpart SECT $sects
	let total-=sects

	logsect $sects 'partition %2d size' $p
done
}

########################################################################

# Calculate the % partitions (rounded up)
# updates total
partstep3()
{
sum=0
for p in $PARTITIONS
do
	getpart $p
	case "$partSIZE" in
	*%)	;;
	*)	continue;;
	esac

	let sects="((total*${partSIZE%\%}+99)/100+SECTORALIGN-1)/SECTORALIGN"
	let sects*=SECTORALIGN
	let PART${p}SECT=sects
	let sum+=sects

	logsect $sects 'partition %2d size' $p
done
let total-=sum

logsect $total 'free sector count'
}

########################################################################

# Set the * partition to the rest
# This is the only one which is unaligned!
partstep4()
{
sum=0
for p in $PARTITIONS
do
	getpart $p
	case "$partSIZE" in
	\*)	;;
	*)	continue;;
	esac

	let PART${p}SECT=total
	let sum+=total
done
[ 0 -lt $sum ] || let sum=-sum
let total-=sum
}

########################################################################

# Warn if something is left
partstep5()
{
if [ 0 -gt "$total" ]
then
	log "warning: disk is too small: $total sectors"

elif [ $SECTORALIGN -le "$total" ]
then
	log "warning: disk has $total unused sectors"
fi
}

########################################################################

# Calculate the START and END sector numbers of each partition
partstep6()
{
off=$SECTORALIGN
start=0
for p in $PARTITIONS
do
	getpart $p

	setpart START $[off+start]
	setpart END   $[start+partSECT-1]
	let start+=partSECT
	off=0
done
}

########################################################################

# Now initialize the devices and which commands to run
partstep7()
{
# initialize the bootsectors
for d in $DISKS
do
	getdisk $d
	getdevbyname d$d
	setdev DISK $d
	setdev DEV  $diskDEV
	setdev CMD  mkboot
done

# create the partition devices
partno=0
for p in $PARTITIONS
do
	getpart $p
	let partno++
	for d in $DISKS
	do
		getdisk $d
		getdevbyname d${d}p$part
		setdev DISK $d
		setdev PART $p
		setdev FLAG primary
		setdev DEV  $partno
		setdev CMD  mkpart
	done
done
}

########################################################################

CMDdebug()
{
for d in $DEVS
do
	getdev $d
	debugdev
done
}

debugdev()
{
gather "%2d" $dev
for x in $DEVsubs
do
	getvar y dev$x
	getvar w W$x
	gadd " %s=%-${w:-1}s " "$x" "$y"
done
gather
}

########################################################################

CMDparted()
{
getdisk $devDISK
call parted -saopt $diskDEV "$@"
}

CMDmkboot()
{
CMDparted mklabel $PARTTYPE
}

CMDmkpart()
{
getpart $devPART
CMDparted mkpart $devFLAG ${partSTART}s ${partEND}s
call ok mdadm --zero-superblock $diskDEV$devDEV
call dd if=/dev/zero of=$diskDEV$devDEV bs=32768 count=2
partflag $partFLAG
}

partflag()
{
while	[ 0 != "$#" ]
do
	flag="$1"
	shift || OOPS "internal error"

	case "$flag" in
	crypt)	#
		return
		;;

	*)	CMDparted set $devDEV "$flag" on;;
	esac

	case "$flag" in
	raid)	getdevbyname md$devDEV
		adddev DISK $ldevDISK
		setdev PART $ldevDEV
		setdev FLAG "$*"
		adddev DEV  $diskDEV$ldevDEV
		setdev CMD  mkmd
		return
		;;
	esac
done
}

# We cannot handle boot and other MDs differently yet
# So all have --metadata=0 to shut up mdadm
CMDmkmd()
{
call mdadm --create $devNAME --level=1 --metadata=0 --raid-devices=`wordcount $devDEV` $devDEV
# process remaining FLAGs
}

########################################################################

# Now iterate over the devices until all have been set up
partstep8()
{
ps8iter=0
while	let ps8iter++
	partstep8a $ps8iter
do
	log "ITERATION $ps8iter done"
done
}

partstep8a()
{
have=false
for d in $DEVS
do
	getdev $d
	[ -z "$devITER" ] || continue
	have=:
	
	debugdev
	CMD$devCMD || OOPS "cannot execute CMD$devCMD"

	getdev $d
	setdev ITER $1
done
$have
}

#----------------------------------------------------------------------

raiddisks()
{
raidcnt=0
raiddsk=
for rdisk in $DISKS
do
	getdisk $rdisk
	raiddsk="$raiddsk $diskDEV$1"
	let raidcnt++
done
echo "--raid-devices=$raidcnt $raiddsk"
}

partstepX()
{
	for flag in $partFLAG
	do
		case "$flag" in
		raid)	;;
		esac
	done

	case " $partFLAG " in
	*\ raid\ *)	call mdadm --create /dev/md$p --level=1 `raiddisks $p`;;
	esac
}

########################################################################

partsteps()
{
for pstep in 0 1 2 3 4 5 6 7 8
do
	partstep$pstep
done
CMDdebug
logcalls
}

########################################################################

