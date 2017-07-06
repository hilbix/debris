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

