[![DebRIS dev Build Status](https://api.cirrus-ci.com/github/hilbix/debris.svg?branch=dev)](https://cirrus-ci.com/github/hilbix/debris/dev)

> Note that this is in the beginning.  What you see here are the goals.  Not all goals are fulfilled.

# DebRIS

"Debian Remote Install Service" is a shell tool to run commands transparently on a remote, as if the commands were running locally.

Requirements:

a) DebRIS is running on the remote.

b) You need some communication channel to the remote which allows to talk to this DebRIS.

c) Then you can issue commands to the remote DebRIS using a local DebRIS.

Improvements over `ssh remote: command` are:

- Arguments can be passed naturally and transparently.  You do not need to double-escape things.

- The remote commands are not terminated on a connection break, as the remote DebRIS keeps them alive.  You can then re-establish the connection and continue from where you were.

- DebRIS can cross the `sudo` and `chroot` barrier.  There is no difference if a command runs locally, remotely, in a chroot or in a privileged shell.

- You can use Unix pipes transparently like you are used to.  On-demand, any time, right in the middle of your remote session.

Notes:

- DebRIS itself is communication agnostic.  You should use `ssh` for communication.  However you can talk over any socket or device, as long as there is another command which utilizes the device.

- DebRIS can be a major security threat, if left running when not in use.  It is meant to ease the setup phase of a computer or VM.  It is also meant for automation systems to remotely run system maintainance commands.  It is not meant as a replacement for a secure administration session, because it is just too easy to hijack DebRIS in case somebody gets access to anything which takes part in the communication between the first and the last DebRIS (until the communication gets end2end protected, which is not even planned).


## Usage

	git clone https://github.com/hilbix/debris.git
	cd debris
	make static
	strip -s debris
	scp debris $REMOTE:

(Following is not entirely stable, this is planning:)

Start DebRIS daemon on the remote:

	ssh $REMOTE: "./debris 'receive ./.sock' daemonize"

Define the connection to the remote DebRIS and to transparently pass commandline to the remote:

	export DEBRIS="'open ssh $REMOTE ./debris \"send ./.sock\"' pass"

Now you can talk to the remote transparently, as if it were local commands:

	./debris ls

This runs the `ls` on the remote.

However this does not yet protect against connection breaks to the remote yet.
If the connection to the remote is unstable
(and to prevent, a connection is opened each time you issue a local command)
you need to tunnel the DebRIS over another DebRIS.

This involves following steps:

- Run the remote Daemon (as above)
- In a second terminal, run a DebRIS which talks to the remote DebRIS.
- In the first terminal, use a DebRIS, which talks to the DebRIS running in the second terminal.

This way, the connection of the local DebRIS never breaks, as it talks to the DebRIS in the second terminal.
This DebRIS in the second terminal then can handle all the connection reestablishments to the remote DebRIS.

I am working on this.  And in future this can be fully automated, of course.

To use DebRIS interactively you must re-enable the interactive mode:

	export DEBRIS="(open ssh $REMOTE './debris \"send ./.sock\"') (remote tty) (interactive escape \!) pass"
	./debris

This way you can "escape out" of remote commands using `!` as the first character.


## Caveats

DebRIS is command based.  Each argument to DebRIS is a full command with all of the commands's arguments quoted together.  The environment is a space separated command list, here `()` can be used for quoting as well (nonrecursively) to eases readbility.

First the environment variable DEBRIS is parsed, then the commandline arguements are parsed, then (`NL` separated) lines read from STDIN (note that NUL always is a line separator).

Do not forget to quote the command and it's arguments.  You can do the usual backslash-escape.  Hence:

	DEBRIS="help help" ./debris help help

outputs the command list 4 times!  Why?  Because the commands were not quoted.  The correct way would be:

	DEBRIS="(help help)" ./debris 'help help'

This outputs the help for the help two times.  Quoting and escapes follow the usual shell way, but you also have to think about the shell itself, wich adds another layer of quoting.  You already know this from `ssh`, right?  If you want to invoke a `command with spaces` on the remote, you cannot do `ssh remote: 'command with spaces' arg1 arg2` as this runs `'command' with spaces arg1 arg2` instead of `'command with spaces' arg1 arg2`.  So you must enter `ssh remote: "'command with spaces' arg1 arg2"`.  This gets difficult, if you want to do `ssh remote: "command '$VAR'" when `VAR` might contain single quotes, too.  The usual workaround is `ssh remote: "$(printf ' %q' command args..)"` which assumes you are using `bash` on both sides.  Sigh.

However, DebRIS' `pass` command handles commandline parameters transparently, as it consumes the rest of the commandline and passes this to the remote DebRIS as given.  So you have no worries, except that Shell Globbing still is done on the local side, of course, as this cannot be circumvented.  (Well, not easily enough yet.)


## BUGs and incompatibilities in future

- Quoting and `print`/`println` are incompatible.  This must change.
  - `print` does ANSI-Sequence `$'quoted'`, which is understood by `bash` directly.  The `$` of `$'quoted'` must vanish.
  - Input does not understand `\xHH` which is needed quote quote arbitrary characters like `NL`.
  - `print` always outputs `'quoted'` which uses `\xHH` and some idioms from `bash`'s `$'quoted'`
  - Input must understand the idioms which `print` outputs.
  - Input shall understand the output of `bash`'s `printf '%q\n'` mostly.  The problem is that `printf` outputs `$` which must be removed such that DebRIS can understand it.


## FAQ

Why?

- Because I need it

Suid?

- Doable but insecure, as it is not specially supported today.

Contact?  Bugs?

- GitHub: Issue or pull request

License?

- See below.
- It is free as in free beer, free speech and free baby.
- But never dare to cover parts of this code with a Copyright, else you will violate German law.


## License

Please note that the sub-module `tino/` partly has some different license.

For everything in this directory following license applies:

This Works is placed under the terms of the Copyright Less License,
see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

