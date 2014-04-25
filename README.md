The debris is all yours.

2014-04-25 draft idea

# DEBian Remote Install Shell

This is the planning for a complete fresh restart.  Some things which I started to detect which are needed and so on.


## This is in the pre-planning phase

DebRIS is not ready for anything today.  This here is only to outline, what I want to have.  And what I perhaps will create if I ever find the time.


## Development goals

There is only one design principle of Debris.  It is:

> DebRIS just works.

In situations, in which DebRIS does not work, it tells you what failed.  It does so in detail.  It then is easy to catch and easy to fix.

This is the DebRIS principle:  "DebRIS just works."

BTW, DebRIS will just work out of the box.  No configuration.  No thinking ahead.  Just install and start to use.  Everything else would contradict the principle "DebRIS just works."

DebRIS shall become something like a very properly build tractor without any fancy stuff.  If you fuel it, it will never leave you alone.  It is able to pull itself up the Mount Everest if you like, and if you supply air it even will run on the moon or under water.  A thing, which just works.  And if it needs repair, everything you need is a hammer, which is readily available as part of the tractor.  Such a tractor will not be able to win a battle against a Ferrari.  But 100 years later the Ferrari has rusted to dust, while such a tractor still lives, because it was build from 20mm stainless steel plates.  If you ever start to get accustomed to such a tractor, you will never want to miss it.  It's ugly.  It's loud.  It's messy.  But it's a workhorse and is of use in nearly all situations you ever can think of.  Yes, perhaps there are better tools around to do some job.  But if they die, the tractor still will get the job done for you.  That is the idea behind DebRIS.


## Development nogoals

- Security
- Efficiency
- Speed
- Complete
- Good looking
- 1337
- Elegant
- Noob friendly
- Hackish
- Feature rich


DebRIS is meant to run as root.  On both sides.  So if you think you found some security problem with DebRIS, you probably stumbled the wrong universe.  Try heading back.  The client is inherently insecure, because DebRIS is meant to install things, and this means, if you gain access to DebRIS you are in full control of the client.

There are only two security related things:

- Debris is meant to administer far away servers in difficult situations and in difficult to reach locations.  So if a client is able to interfer with the infrastructure and do bad things on a host (or relay), then this is an issue.  It is an issue, because it contradicts the "DebRIS just works" principle.

- DebRIS is meant to allow to administer far away servers in case there is boot trouble or it crashes.  So DebRIS will be part of initrd and crashkernel.  To be usable in such stages where the system is helpless, it must not be endangered by security flaws in DebRIS.  That, again, is no security issue but a basic need for the "DebRIS just works" principle.


## Debris session

Look and feel of a DebRIS session:

### On the client

DebRIS is not needed on the client.  If it is used, it offers following services:

- Terminal access to the machine
- Remote upload/download/execution
- Variouis networking tunnelling support

Besides of that it should stay out of sight.  It may run in background, but you shall not notice much of it.

I don't think it will have it's own uIP-Stack, but who knows, perhaps this will come handy to not interfere with the kernel too much.


### On the host

Start a debris session is like starting some commandline program:

```bash
debris
debris> connect client
debris: connected to debris@client
debris@client> 
```

Debris immediately (always) starts to record the session.  This includes everything that is funneled over DebRIS.  So it is able to replace `script`:

```bash
debris shell
$ ..do..work..
$ exit
debris> 
```

DebRIS talks RFB (aka. VNC) out of the box.  However it does not need a graphical interface nor a mouse:

```bash
debris
debris> connect vncclient
debris: connected to debris@client
debris@client> mouse 0 0
```

This does not look much different, but the difference is, that you then connect your vncviewer to DebRIS, not to the client.  And DebRIS is able to control the remote session.  More importantly, you are able to automate graphical sessions this way.

This plays nicely with `virsh` which offers a VNC connection to VMs.


## DebRIS protocol

DebRIS is meant to just work.  So it is designed to work over 5 bit RTTY lines.  The communication protocol of DebRIS is pure ASCII with base16 (aka. Hex) encapsulation.

If you are running `debris shell`, you are not in the shell.  You are still in DebRIS forwarding everything transparently to you.  You can switch in and out of this mode using the `^` key (you can alter it if you like, but by default it is `^`, because this is not often used).

Chained DebRIS are able to communicate this way directly with each other using the normale terminal stream.  However you never talk directly to the remote systems.  You always talk to your local DebRIS, keep that in mind.  It just looks that you are talking directly to the remote shell.

But the connection between the DebRIS instances are arbitrary.  There need not be a stream, only some way to communicate bi-directional.  Using SMT transported by IPoAC could be an option.  Or some printer/scanner combination.  Anything you might think of.

If you type something, this is posted to the next DebRIS, which then posts this to the next one and so on, until it reaches the wanted destination.  Later it is planned, that this communication can take shortcuts or other routes if possible.

So DebRIS does not need to know how to communicate with one client, as long as it knows another DebRIS which is able to.  So you have 3 different types of DebRIS in such a network:

- Host, this is where you are and what you talk to
- Relay, this are DebRIS in between needed for communication and data routing
- Client, the thing you are currently managing

Each DebRIS can act as anyone.  There is only one DebRIS, not differend brands of it.  However, you can leave away things you do not need.

- The DebRIS client is always needed, because it implements all basic communication methods.
- But you can leave out the relay part, in which case this client is "terminal".  It then is not more capable of everything.  Usuall you want to leave that in, because in case you `su` into another context, you want to start a new DebRIS process there to chain, and this only works if you have realying available.
- On pure client machines and when space is an issue, you probably can leave away the host part.  But it is all-too-handy to be called from shell there, just in case you need it.  So usually you will have the complete DebRIS installed on your systems.

Note that the Host part is the biggest one.  It allows VNC relaying (has an RFB server built in) and much more.

### Shell mode

- The protocol is transparent to TTY traffic, except for one character '^'
- `^` will prompt you a 'DebRIS>' prompt.  If you type `^` again, the prompt vanishes and the `^` is sent to the other side.
- There is no "double escape" mode.  If you want to talk to the 2nd DebRIS in row, you do this through your local one.  This is unlike `ssh` use of `~`.
- After pressing `^` all uppercase keys are bound to a macro.  This is handy, as you are already holding down the Shift key.
- Anything else is an error and will not be accepted.

Standard macros:

(Those which are empty probably get some function as soon as I need it.  All can be re-defined by you, of course.)

- `A`: left (mouse)
- `B`: Binary data communication packet.  Data communication is done using base16 with 0-9 and lowercase letters a-f.  DebRIS communication packets are not meant to be meaningful to humans.
- `C`: middle klick (mouse)
- `D`: right (mouse)
- `E`: right klick (mouse)
- `F`: scrollwheel down (mouse)
- `G`:
- `H`: show help
- `I`:
- `J`:
- `K`:
- `L`:
- `M`: enter mouse mode, this is your number pad then acts as a mouse cursor while all other keys send keystrokes via RFB.  Until you press Enter.  For this you need a keypad which sends keypad keys.  If this works this depends on your terminal.
- `N`:
- `O`:
- `P`:
- `Q`: left click (mouse)
- `R`: scrollwheel up (mouse)
- `S`: down (mouse)
- `T`:
- `U`: send single keystroke through RFB
- `V`:
- `W`: up (mouse)
- `X`:
- `Y`: Temporarily leave Shell mode until you press Enter.  The string you entered will be sent to the remote (without Enter).
- `Z`: see `Y` (because I am German!)
- `SPC`: Leave escape mode

If you want to enter command mode, type `^Y^command`, if you want to enter a string starting with `^` to the remote like this you can enter `^Y^^string`.  This is meant to be very fast to type.

So to leave shell mode you can use `^Y^leave`.  You can customize the key settings, so you can put it on the key you want.


### Line mode

Line mode is just like `Y` in Shell mode with roles reversed.

- You enter commands to DebRIS.
- You can see all output of the other side.
- You still can use the Macros, as commands are lower letter.
- To send something to the other side, you can prefix it with `^`, or you can use the right command.


### Virtual Desktop

DebRIS internally only provides following components:

- An RFB repeater which tunnels over the DebRIS protocol.
- A virtual terminal which records the TTY of the other side.
- The DebRIS console

Each of this can exist multiple times.  For example, if you happen to have a computer with two screens which are independently handled by RFB, or you need two DebRIS consoles or more than one TTY on the other side, this works.

However, DebRIS has no virtual desktop.  This is not needed, as you already have it.  It is called XVnc.

This way you can create a virtual desktop with following components, or more:

- RFB repeater, where you see the screen of the other side
- RFB terminal, where you see the TTY of the other side
- RFB console, where you see DebRIS console
- RFB contols (a second Console), some buttons for easy access
- RFB keypad, a keyboard input field
- And more, like xeyes

It is easy to create such a beast.  The good thing is, if you have set it up once, you never need to change it.  It fits all your needs.  And thanks to `xvncviewer` you can view it conveniently from any X-Window.  Or another DebRIS, of course ;)

