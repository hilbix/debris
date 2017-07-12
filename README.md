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

There are following commands (in the usage above, enter them in the first terminal, as the second goes to the remote).

If `context` is missing, it is the current one (`.`) if not noted differently:

- `help` lists all possible commands in the current context
- `ls [context]` lists all known contexts on the given level
- `cd [context..]` switch in or out of contexts.  Just `cd` is an alias to `pop 0`, except there is no error if the stack is empty, in that case the current context `.` is used.  See "context names" about context naming.
  - `cd` can be left away if the line starts with `.`
  - `push [context..]` push the current context to a stack and change into the given context using `cd` if an argument is present.
  - `pop [#]` pop the topmost `#` entries (default: 1) and change into the last one popped.  If `#` is 0 this means, rechange to the context of the top of stack.

- `wait [context]` waits for changes (for example finished processes) of the context
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

- `get [what]` output the given information about the context.
  - you can get information about context result code (`.name`) or signals (`@signal`) or environment (`$name`) etc.
- `set value expression` set some information.  Only string `value`s are settable this way, everything else must be changed through commands.
  - You can set environment variables using `$name` as `value`
  - `set` can be left away if the line starts with `$`
- `unset value` removes a value.
  - `set value` usually sets an empty value.
- `inherit [context..]` inherit the settings from some other context.
  - You can merge several contexts, while the last one wins.
  - `inherit a b` is the same as `inherit a` followed by `inherit b`
  - Some settings automatically propagate (are linked), some are not (copied).  See `info` for details.
- `read [expression]` read from context `stdout`, if input is given this waits until the given input arrives
  - Input is stored in `$0` (complete line) and `$1` to `$N` for the fields
- `write expression` send the given `expression` to `stdin`
- `send expression` as before, but send LF afterwards
- `cr expression` as before, but send CR afterwards
- `crlf expression` as before, but send CR LF afterwards
- `talk [expression]` enters the context interactively.  If input is given, output starts from the last position, where this input is found in output history.
- `alias name` set an alias (human readable name) for the current context.
  - A context may have many aliases.
  - In a context, the aliases must be uniqe.
  - You can set the alias for the current context in a parent using `alias ..name` etc.
- `timeout #[smhd] [signal..]` where `#` is an integer.
 - Timeout affects all interactive waiting operations, not internal conections.
 - `0` means no timeout, which is the default.
 - Default is milliseconds. Hence `timeout 1000` is 1s.
 - If `smhd` is present, it tells that the number is `s`econds, `m`inutes `h`ours or `d`ays.
 - if `signal` is present, the given signal is sent after the given timeout.
 - There can be more than one signal, they are sent in sequence

- `on @signal command` defines a `command` which is run in the current context when signal `signal` is received.
  - `on` can be left away if the line starts with `@`
  - You can attach to a signal as often as you want


### Commands to create new context:

- `new name [command]` create a new context `name`.
  - If a `command` is present, push the new context to the stack and run the given command inside.
  - If `command` is some "create new context" command, this command runs in the given context `name` and does not create a new one.
  - To create a new empty context `xxx` just enter `new xxx`
  - To create a context which inherits from the parent, enter `new xxx inherit`
  - To create a new context `xxx` and change to it, use `new xxx cd`

- `debris command args..` create connection to other debris.  `command` must talk to stdin/stdout for the connection.  This also automatically sets an alias for the current context.

- `open name` opens the given name in the filesystem.  `mode` defaults to `ro`
  - `creat mode` set the file mode, this also sets `mode creat` (which is missing from `mode` as it needs a value), this defaults to `rw`
  - `mode MODE` set the comma separated open flags: ro,rw,wo,append,async,keep,direct,dsync,excl,follow,ctty,sync,tmp,trunc (see `man creat` on what the flags do.  Some flags are inverted).
  - This automatically attaches file to stdin for reading and, if `rw` stdout for writing

- `pty [master]` create a pty, possibly with a sub-context `master`.
  - "slave" becomes FD0, FD1 and FD2
  - "master" becomes FD4 if no `master` is given
	  - else "master" becomes FD0 and FD1 in the `master` sub-context.

- `pipe` creates a `pipe(2)`

- `run command args..` run the given local command (in background)
  - `in [#] context`, `out [#] context`, `err [#] context` take stdin/stdout/stderr from the given context where `#` is the filedescriptor, defaulting to `0`/`1`/`2` respectively.  Use `0` as `context` for `/dev/null` (see context names).
  - `fd # [#] context` take FD `#` (a number) from the given context.  The second `#` is the filedescriptor of the `context`, which defaults to the first `#`.

- `socket type` create a socket.  `type` is `unix`,`tcp`,`udp`,`pair` or `domain,type,proto`, see `man socket`, you can guess most possibilities
  - `bind address` bind to given address
  - `connect address` connect to given address
  - `listen` make the socket listen


## Example

Exec some command with some other context attached to it which are not yet fully specified:

    new myin
    new myout
    new runner cd
    in myin
    out myout
    run runnercommand args..
    # runnercommand is not started, as some contexts are not set up
    cd ..myin
    open whateverfile
    cd ..myout
    mode append
    file outputfile.txt
    # note that runnercommand starts here as now all references are satisfied

## Details

### Context Names

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
  - `.name` denotes the context `name` in the current context.  So the `.` is optional in this case.
  - `..name` denotes context `name` in the parent.  You can use `...name` and so on.

You cannot form paths on context.  So you cannot specify something like `...ctx1/ctx2`.  If you need that, use an `alias` like here:

    cd ...ctx1 ctx2
    alias ...somenewalias
    cd

### Signal Names

Signal names are names like for Contexts, but always start with a `@`.

Signals are global to `debris`, so a remote signal can activate locally.


### Environment Variables

You can access the environment using `$` as usual.  This works mostly everywhere.

Environments are context sensitive.  Usually all environment variables are inherited, but setting a variable in a sub-context does not modify the parent context.

- `$.name` is the same as `$name`

- `$..name` accesses the variable in the parental context.
  - You can use this to pass something up like in `[set] $..var $var`

- There are special environment variables `$#` where `#` is a number.
  - `$0` captures the last read input line (including the LF at the end).
  - `$1` to `$#` are space separated fields, where fields start at the first non-whitespace character and end on the first whitespace character.
  - `$#` contains the number of fields
  - Only the last line is captured.  As soon as somthing following an LF is seen, `$0` is reset.

- `$?` captures the result code of the last command in the current context.  This is the same as `get cmdstatus`.

- `${name}` can be used to remove ambiguity, like in shell.
  - `$` can be left away, as `{` is recognized as special construct.
  - The braces must be balanced.
  - To remove ambiguity, you can use a single whitespace, as in `{ name }`.
  - If you give `{ ` (that is `{` followed by SPC) you must use ` }` (that is SPC followed by ` }`), as you can no more use the form without SPC, this includes nested braces.
- Use `$$` to enter `$` which does not count as a `$`.
- Use `{{` to enter a literal `{` which does not count as a brace.
- Use `}}` to enter a literal `}` which does not count as a brace.

- `$[expression]` can be used to evaluate an expression.
  - Expression must not contain unbalanced brackets if used in this simple form.
  - You can, again, add a single SPC or use more than one `[` and `]` to remove ambiguity.
  - Expression might contain environment variable in case it is expanded, see Expressions below.
  - Note that you cannot use `$[[expression]]`, this must have the SPC as in `$[[ expression ]]`!

- `$(expression)` is nearly the same as ``$[` expression `]``, except that `expression` is environment expanded.
  - To remove ambiguity, you can, again, add SPC with more `(` and `)` respectively.


### Expressions

Expressions are evaluated based on how they start:

- `\` the rest of the expression up to the end of the line is taken literally.  This includes trailing whitespace!
- `'` the expression is taken literally.  Optionally `'` followed by whitespace is removed
- `"` the expression is environment and backslash expanded.  Optionally `"` followed by whitespace is removed
- `` `  `` (that is `` ` `` followed by a SPC) the rest of the expression is passed literally to `sh -c` and the output is captured.
  - Care must be taken if something is passed to a shell.
  - If `expression` is the full line, a single trailing LF is removed for convenience.
  - If `expression` is embedded, it must end on ``  ` `` (this is `` ` `` followed by SPC).  For a full line this is optional, and may be followed by whitespace only (which are ignored).
  - The end sequence must not be present anywhere else in the `expression`.
  - To disambiguate, you can use ``` ``  ``` (this is ``` `` ``` followed by a SPC) which then complements the end sequence ```  `` ``` (this is SPC followed by ``` `` ```).  Use as many `` ` `` characters as you need, start and end must have the same number (compare Markdown).
  - If you need environment expansion to happen prior `expression`, use `$(expression)` instead.
- `! ` (that is `!` followed by a SPC) is similar to `` `  ``, however only the result code is captured.
  - The same for the end sequence holds.
  - You can use more than one `!` as in `` ` `` usage.
  - Note that this special form is much less resource hungry than `` ` command >/dev/null; echo $? ` ``.

- Else the given string is taken literal (including trailing whitespace) and environment expanded.
  - Please note `$(expression)`.


### Patterns

T.B.D.


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


## FAQ

T.B.D.


## License

This Works is placed under the terms of the Copyright Less License,
see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.

Read: This is free as in free speech, free beer and free baby.
Copyrighting babies is slavery!

