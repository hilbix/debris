*THIS HERE CAN BE EXTREMELY DANGEROUS FOR NOW!* You have been warned.

Status
======

Unusable for others.  Just a rough start.

*THIS HERE CAN BE EXTREMELY DANGEROUS FOR NOW!* You have been warned.

Currently the development test bed is as follows:

- Have a scratch VM with a Debian install

- Do everything as root (remember: scratch VM!)

- Fetch ptybuffer from http://www.scylla-charybdis.com/tool.php/ptybuffer

- Extract, build and install ptybuffer (tar xfz; cd; make; make install)

- mkdir /auto; cd /auto; git pull https://github.com/hilbix/debris

- Edit machine.inc to your needs

- Be sure the disks do not contain valuable data!

- Run ./debris.sh

*THIS HERE CAN BE EXTREMELY DANGEROUS FOR NOW!* You have been warned.

Everything below is how the planned future:

About
=====

DebRIS is my method to install a minimal Debian onto remote
root servers.

The idea is:

- Have a single easy to understand and maintain text file
  which contains the complete(!) base-configuration of a system.

- Have a fully installed local or server Linux machine which 
  has a broad set of tools.

- Have a remote system which must be installed and can be booted
  into some sort of rescue system in which you can SSH into
  (or open another socket from the local to the remote).

DebRIS offers the building blocks to have an easily documented,
easy to use, flexible and complete basic setup of any machine.

Flexibility is in the partitioning scheme, which helps you to specify
your partition layout, with MD, crypo and LVM in place.


Requirements:
-------------

The requirements will change in future.  The plan is, to have just
one single static binary which must be run on the remote side.
For now this is not possible yet, so the requirements are somewhat
higher.

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

The intersting part about DebRIS is, that it works from the commandline.
It can do chroot and everything just like a normal admin.

So you do not need any fancy things on the remote, except being able to
run it in some noninteractive batch mode.


Future thoughts:
================

Currently DebRIS only runs from bare metal to boot.  In future perhaps
this can be extended such, that it continues to setup a machine after
the initial boot.

Currently the remote system must have bash and some trainloads of other
tools.  Perhaps this can be relaxed as well.  The goal is to have some
single static binary (like BusyBox) which is the only requirement on
the remote system to be started.  Perhaps this all can be even stuffed
into a single Linux kernel/initrd combination.

Then everything else (including debootstrap) shall be provided by DebRIS.

