> This is planning

# DebRIS

Debian Remote Install Service

## Usage

```
git clone https://github.com/hilbix/debris.git
cd debris
make static
scp debris remote:
./debris debris ssh remote ./debris
```

This runs a connection between your local `debris` and the remote one (the debris service is started on the fly).

Start `debris` in a second termina: `./debris`

Now you are in the local context, you can enter commands like:

- `help` lists all possible commands in the current context
- `ls [context]` lists all known contexts on the given level
- `cd [context]` switch into
- `wait [context]` wait for changes
- `kill [context]`/`close [context]` terminate context
- `rm context` remove context
- `exit [context]` terminate and remove context

Commands in a context:

- `cat [info]` output the given information about the context
- `read [input]` read from context `stdout`, if input is given this waits until the given input arrives
- `write input` send the given input to `stdin`
` `writeln input` as before, but send LF afterward
- `talk [input]` enters the context interactively.  If input is given, output starts from the last position, where this input is found in output history.

To create contexts:

- `new` create new context.  `new` can be left away, which means `end` is automatically applied, too.
- `end` end the definition of the context.  Note that this is the point where context creation is executed and may fail.

Within `new` to `end` you specify the context:

- `rename name` set name of context

- `debris command args..` create connection to other debris

- `open name` opens the given name in the filesystem
  - `creat mode` set the file mode, this also sets `mode creat` (which is missing from `mode` as it needs a value)
  - `mode MODE` set the comma separated open flags: append,async,keep,direct,dsync,excl,follow,ctty,sync,tmp,trunc (see `man creat` on what the flags do.  Some flags are inverted).

- `pty` create a pty

- `pipe` create a `pipe()`

- `exec command args..` run the given local command
  - `in context`, `out context`, `err context` take stdin/stdout/stderr from the given context.  If the file within context is not fully qualified, it is guessed.  Use `0` as context for `/dev/null`.
  - `# context` take FD `#` (a number) from the given context

- `socket type` create a socket.  `type` is `unix`,`tcp`,`udp`,`pair` or `domain,type,proto`, see `man socket`, you can guess most possibilities
  - `bind address` bind to given address
  - `connect address` connect to given address
  - `listen` make the socket listen



## About

Despite it's name DebRIS is not

- a service.
- an installer.
- providing remote access.
- only for Debian.

But it is a tool, which bundles this all.  And more.

The idea behind DebRIS is to provide an easy way to control commands, regardless if they run locally, on remote, as a service or via su/sudo or behind chroot or anything, thereby overcoming network interruptions, server outages and so on.

DebRIS itself does not provide anything, except the needed core resource management.  Everything else is provided by external scripts.

With DebRIS you can

- start and control a command
- run the command via pipe, socket or pty
- and do everything, you can do on a shell level with commands, like attaching gdb or strace to it, planned or on-demand

One single DebRIS is enough to control everything.  The connections between DebRIS normally is automatic, but can be interrupted and reestablished any time, where (normally) nothing is left behind.

DebRIS orgainizes in a flat fashion:

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

