**THIS HERE CAN BE EXTREMELY DANGEROUS FOR NOW!** You have been warned.

Status
======

INCOMPLETE, so it does not work yet.

**THIS HERE CAN BE EXTREMELY DANGEROUS FOR NOW!** You have been warned.

Currently a suitable development testbed is:
--------------------------------------------

- Download and install VirtualBox from virtualbox.org

- Download *-rescue.iso from http://cdimage.debian.org/cdimage/release/current-live/i386/iso-hybrid/

- Create a scratch VM with 1 GB RAM and two networks: NAT and Host Only

- Add two VM drives of the same size, this will become /dev/sda and /dev/sdb

- Boot the VM into the downloaded live system by booting from the ISO image (this is: add the ISO to the virtual CD-ROM drive)

- Boot the "Live" VM, then do:

	sudo su -
	# vi /etc/apt/sources.list
	# export http_proxy=http://192.168.1.1:8080

	apt-get udpate
	# apt-get upgrade # this probably will use up all your RAM
	apt-get install git

	git clone https://github.com/hilbix/debris.git
	cd debris
	
	cp EXAMPLE.debris TEST.debris
	vi TEST.debris
	
	./debris.sh TEST

- Eject the CD, reboot into the new system

**RUNNING THIS NOT IN A SCRATCH VM CAN BE EXTREMELY DANGEROUS FOR NOW!** You have been warned.

**Everything below is planned future:**

About
=====

**THIS HERE CAN BE EXTREMELY DANGEROUS FOR NOW!** You have been warned.

DebRIS is my method to install a minimal Debian onto remote root servers from scratch.

The idea behind DebRIS:

- Have a single easy to understand and maintain text file which contains the complete(!) base-configuration of a system.

- Have a fully installed local or server Linux machine which has a broad set of tools.

- Have a remote system which must be installed and can be booted into some sort of rescue system in which you can SSH into (or open another socket from the local to the remote).

DebRIS offers the building blocks to have an easily documented, easy to use, flexible and complete basic setup of any machine.

Flexibility is in the partitioning scheme, which helps you to specify your partition layout, with MD, crypo and LVM in place.

The easy part is that you can edit the text file and sit back and relax while the machine is installed, without need of any manual intervention.  Ever.


Requirements:
-------------

The requirements will change in future.  The plan is, to have just one single static binary which must be run on the remote side.  For now this is not possible yet, so the requirements are somewhat higher.

The remote must offer the minimal basic setup tools:

- bash, mkdir, mount, umount, chmod, rm, uudecode

- blockdev, dd, mdadm, parted, mke2fs

- probably some other tools I forgot to mention

On the local system there must be a full development system available.


Install process:
----------------

The install then is easy enough:

- Edit the config of the machine

- Boot the remote into the rescue system

- Run DebRIS on the local machine to install the remote system

You can easily iterate this until you are happy.
 
DebRIS will do following:

- SSH to the remote system

- Upload run.sh using uudecode

- Run run.sh and issue all commands to this script

- Now the machine is set up and can boot into the fresh system

The intersting part about DebRIS is, that it works from the commandline.  It can do chroot and everything just like a normal admin.

So you do not need any fancy things on the remote, except being able to run it in some noninteractive batch mode.


Future thoughts:
================

- Currently DebRIS only runs from bare metal to boot.  In future perhaps this can be extended such, that it continues to setup a machine after the initial boot.

- Currently the remote system must have bash and some trainloads of other tools.  Perhaps this can be relaxed as well.  The goal is to have some single static binary (like BusyBox) which is the only requirement on the remote system to be started.  Perhaps this all can be even stuffed into a single Linux kernel/initrd combination or can be `cat`ted to the remote via the tty link.

In that case plain everything (including debootstrap) shall be provided by DebRIS and not be a requirement on the remote.

