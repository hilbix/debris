> This is planning

# DebRIS

Debian Remote Install Service

## Usage

    git clone https://github.com/hilbix/debris.git
    cd debris
    make static
    ./debris

This runs `debris` in your local context.  It also starts the local "debris service" on the fly if there isn't any.

On a second terminal start a remote `debris` with:

    scp debris remote:
    ./debris debris ssh remote ./debris

Basically this runs `debris` on the remote (which starts a "debris service" on the `remote`), creates a new "context" for the remote `debris` and then acts as a bridge to this context.

Note: The sequence in which you start `debris` in the terminals is irrelevant.

## Commands

There are following commands (enter them in the first terminal).  If `context` is missing, it always is the current one:

- `help` lists all possible commands in the current context
- `ls [context]` lists all known contexts on the given level
- `cd [context]` switch in or out of contexts (this is permanent).  Just `cd` re-enters the current context like `cd .`.  See "context names" about naming.
- `wait [context]` waits for changes (for example finished processes) in the context
- `exit [context]` closes the given context (service) recursively and wait for proper termination
- `kill [context]` terminates the given context without grace and does not wait for the proper end.  This may leave debris behind in case some context is not ready.
- `reset [context]` try to restart context.  This just resets the given current context.  It does not reload sub-contexts as well.
- `restart [context]` this is a recursive reset, which also hits the sub-contexts.

> Note about loops:
>
> Commands carry some sender name and unique monotone identifier.  Each `debris` records the last seen sender/identifier and only processes commands with a higher identifier.  This effectively elliminates loops.
>
> The disadvantage is, that asynchronous commands are ignored if they are received too late.  This also is an advantage.

In case debris-A has a context for debris-B, and debris-B has a context for debris-A, then running `restart B` in debris-A does not make debris-A restart (as it already has seen the command).

### Commands within a context

- `cat [info]` output the given information about the context
- `read [input]` read from context `stdout`, if input is given this waits until the given input arrives
- `write input` send the given input to `stdin`
` `send input` as before, but send LF afterward
- `talk [input]` enters the context interactively.  If input is given, output starts from the last position, where this input is found in output history.
- `alias name` set an alias (human readable name) for the context.  There can be more than one alias.

### Commands to create new context:

- `new name [command..]` create a new context `name` and run the given command inside.  If the command run inside is a "create new context" command, this command runs in the given context `name` instead of another new one.
  - To create a context `xxx` just enter `new xxx`
  - To create a new context `xxx` and change to it, use `new xxx cd` (this is magic)

- `debris command args..` create connection to other debris.  `command` must talk to stdin/stdout for the connection.  This also automatically sets an alias for the current context.

- `open name` opens the given name in the filesystem.  `mode` defaults to `ro`
  - `creat mode` set the file mode, this also sets `mode creat` (which is missing from `mode` as it needs a value), this defaults to `rw`
  - `mode MODE` set the comma separated open flags: ro,rw,wo,append,async,keep,direct,dsync,excl,follow,ctty,sync,tmp,trunc (see `man creat` on what the flags do.  Some flags are inverted).
  - This automatically attaches file to stdin for reading and, if `rw` stdout for writing

- `pty` create a pty

- `pipe` create a `pipe()`

- `exec command args..` run the given local command
  - `in [#] context`, `out [#] context`, `err [#] context` take stdin/stdout/stderr from the given context where `#` is the filedescriptor, defaulting to `0`/`1`/`2` respectively.  Use `0` as `context` for `/dev/null` (see context names).
  - `fd # [#] context` take FD `#` (a number) from the given context.  The second `#` is the filedescriptor of the `context`, which defaults to the first `#`.

- `socket type` create a socket.  `type` is `unix`,`tcp`,`udp`,`pair` or `domain,type,proto`, see `man socket`, you can guess most possibilities
  - `bind address` bind to given address
  - `connect address` connect to given address
  - `listen` make the socket listen


Examples:

Exec some command with some other context attached to it which are not yet fully specified:

    new myin
    new myout
    new runner cd
    in myin
    out myout
    exec runnercommand args..
    cd ../myin
    file whateverfile

## Context Names

- `-` is a user controlled meta-context, see `read`, `write`, `send` and `talk`.  It is the default in case you do not give `in`, `out`, `err`.
- `0` denotes to `/dev/null` (you never can access `stdin` from your terminal, use `talk` for this)
- `1` is `stdout` of the shell which ran `debris`
- `2` is `stderr` of the shell which ran `debris`
- `3` to `127` are additional file descriptors, which might be present on `debris` when `debris` was started.  For some reason it would be unwise to allow FD above 200, as these are often used by shells to move away file descriptors not currently in use.  If need arises, we perhaps can add `128`..`199` in future.
- `.` is the current context
- `..` is the parental context
- `...` is the parent of the parent (and so on)
- `.#` where `#` is a number are the internal context numbers (usually starting from 1).  You usually do not see them.
- `name` a given alias which you can use to refer to.  It must be made of letters, number and `.-_`, and must start with a letter (so you cannot use `_` there, this is reserved for future).

## About

Despite it's name DebRIS is not

- a service.
- an installer.
- providing remote access.
- only for Debian.

But it is a tool, which can be used to bundle this all.  And more.

The idea behind DebRIS is to provide an easy way to control commands, regardless if they run locally, on remote, as a service or via su/sudo or behind chroot, on a tty, or anything, thereby overcoming network interruptions, server outages and other mayhem.

DebRIS itself does not provide anything, except the needed core resource management.  Everything else is provided by external scripts.

With DebRIS you can

- start and control a command
- run the command via pipe, socket or pty
- and do everything, you can do on a shell level with commands, like attaching gdb or strace to it, planned or on-demand

One single DebRIS is enough to control everything.  The connections between DebRIS can be interrupted and reestablished any time, and (normally) nothing is left behind, it just continues from where it hung.












# Following probably is bullshit

DebRIS organizes in a flat fashion:

- On a single computer it is sorted on uptime+pid
- On networks it is sorted on the MAC+IP+uptime+hostname
- And there are easy to use aliases, for humans

DebRIS keeps record on what happened in history on their invocation level.  Hence you can base your decisions on that history.  If it is known, these decisions can be taken without remote access.

For example:

- Is a remote machine already partitioned?  If not, do the partitioning.  If unknown, the remote DebRIS can be asked for this information.  As you need to establish a connection there anyway, this is a straight forward process.
- Has some software beein installed?  If not, install this software.
- Has a cluster of machines been provided?  If not, order them.
- Do we have all neccessary domains under our control?
- And so on

Nothing is predefined in DebRIS, all those information can be gathered in a dynamic way.  Or not.  You decide what to do.

The interesting part is, that you do not think about all this in advance.  You do it on-demand fashion.  For example, your usually connection to a remote machine breaks, because some security architecture has changed.  No problem.  Just write the script to open a new connection.  And you are again operable, from where you left off.  This also allows to interrupt things any time in any state and continue as efficient as possible.

Where efficiency is defined by you, not by DebRIS.  For example, if a copy operation of a very big file breaks, you decide which tool to use and how to restart this process.  In the naive way, you just start the copy again.  But if you are clever, you design a way to do it more clever, like with rsync.  But this depends on what breaks.  Does the remote break?  If not, the network connection can be rejoined, as long as the communication path was over DebRIS, by just connecting the DebRIS on both sides again.  Somehow, as there may be many many other DebRIS in this way.

An each level, you can start commands.  See the results.  See the recorded input and output.  You can decide, what to keep, what to ignore and what to do with it.

Everything, conveniently from just your single front end DebRIS.  Or not.  Because if you reboot your local machine, just nothing happens.  Restart DebRIS.  Jejoin the mesh.  And continue your work from where you left off.

Setup once.  Reuse multiple.  That's the power of DebRIS.

Having said that, DebRIS, today, is just meant to provide what it says:  Do Debian Installs on a remote system in a controlled way, where you have nothing but a machine running DebRIs on both sides, and, somehow, an probably instable network link between.

