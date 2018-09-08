#ifndef	DEBRIS_CNAME
#define	DEBRIS_CNAME(...)
#endif
#ifndef	DEBRIS_CADD
#define	DEBRIS_CADD(...)
#endif
#ifndef	DEBRIS_CFN
#define	DEBRIS_CFN(...)
#endif
#ifndef	DEBRIS_CALL
#define	DEBRIS_CALL(...)
#endif
#ifndef	DEBRIS_VADD
#define	DEBRIS_VADD(...)
#endif
#ifndef	DEBRIS_TOPIC
#define	DEBRIS_TOPIC(...)
#endif

#define	V(AUTO,NAME,DEFAULT,HELP)	\
                                        DEBRIS_VADD(#NAME, AUTO, DEFAULT, HELP)

#define	C(NAME,MIN,MAX,USAGE,HELP,FN)	\
                                        DEBRIS_CNAME(NAME)		\
                                        DEBRIS_CFN(NAME,FN)		\
                                        DEBRIS_CALL(NAME,MIN,MAX)	\
                                        DEBRIS_CADD(#NAME, CMD(NAME), MIN, MAX, USAGE, HELP)

#define H(NAME,HELP)			DEBRIS_TOPIC(#NAME, HELP)

V(1, prompt,	"[{$prefix}]{$loc}@{$name}:{#dir}$ ",	"DebRIS prompt")
V(0, prefix,	"DebRIS",				"DebRIS prompt prefix")
V(0, name,	"{=hostname}",				"DebRIS name")
V(0, loc,	"{=getpid}",				"DebRIS location")
V(1, dir,	"{=cwd}",				"DebRIS directory")
V(0, sep,	"\t",					"separator for echo")
V(1, err,	"",					"automatic error variable (error string of last command)")

C(exit, 0,1, "[n]", "exit DebRIS with given return code, default: 0",
{
  int	c;

  c = args[0] ? atoi(args[0]) : 0;
  D->end	= 0x100 | c;
  return 0;
})

H(usage, "{arg0} 'command'..\n"
  "")
C(help, 0, 2, "[command] | help [topic]", "explain command or topic",
{
  const struct _debris_cmd	*cmd;
  const struct _debris_topic	*topic;
  const char			*p;
  int				pos;

  if (!args[0])
    {
      tino_hash_iter		iter;

      for (tino_hash_iter_start(&iter, &D->map_cmd, 0); (cmd=tino_hash_iter_data_rawptr(&iter))!=0; tino_hash_iter_next(&iter))
        outp(D, "%s %s%*s%.*s\n", cmd->name, cmd->usage, (int)(D->cmdmaxwidth-strlen(cmd->name)-strlen(cmd->usage)), "", tino_str_nclen(cmd->help, '\n'), cmd->help);
      return 0;
    }
  cmd	= debris_cmd(D, args[0], 0);
  if (!cmd)
    return "unknown command";

  if (cmd!=D->currentcmd && args[1])
    return "command do not have topics, try 'help help topic'";
  outp(D, "%s %s\n", cmd->name, cmd->usage);
  for (p=cmd->help; *p; p++)
    {
      pos	= tino_str_nclen(p, '\n');
      outp(D, "\t%.*s\n", pos, p);
      p	+= pos;
      if (!*p)
        break;
    }

  if (!args[1])
    return 0;

  topic	= debris_topic(D, args[1], 0);
  if (!topic)
    return "unknown topic";
  pos	= tino_str_nclen(topic->help, '\n');
  outp(D, "%s: %.*s\n", topic->name, pos, topic->help);
  while (topic->help[pos++]=='\n')
    {
      int	len;

      len	= tino_str_nclen(topic->help+pos, '\n');
      outp(D, "\t%.*s\n", len, topic->help+pos);
      pos	+= len;
    }

  return 0;
})

C(echo, 0, -1, "[args..]", "echo the given args uninterpreted and separated (see var sep)",
{
  CMD(echoc)(D, args);
  outln(D, "");
  return 0;
})

C(echoc, 0, -1, "[args..]", "like echo, without NL at the end",
{
  while (*args)
    outsep(D, *args++);
  return 0;
})

C(print, 0, -1, "[args..]", "evaluate arguments and print them, without sparator, without NL",
{
  DP(("(%p)", args));
  while (*args)
    {
      struct debris_expr	*e;

      DP(("() %s", *args));
      outsep(D, NULL);
      e	= EXPR(eval)(D, *args++);
      outesc(D, EXPR(str)(e));
      expr_free(e);
    }
  return 0;
})

C(println, 0, -1, "[args..]", "like print, but outputs NL afterwards",
{
  CMD(print)(D, args);
  outln(D, "");
  return 0;
})

#if 0
C(cwd, 0, 0, "", "get current working directory",
ino_file_getcwdO());
tino_str_printf("%ld", (long)getpid()));
#endif

C(set, 0, -1, "var[=value]..", "set a DebRIS variable to a static value\n"
  "If =value is missing, some default value is used",
{
  int	unset	= D->currentcmd->fn==cmd_unset;

  while (*args)
    {
      char	*name = *args;
      char	*val;
      int	n;

      n	= tino_str_cpos(name, '=');
      if (n==0)
        return "variable with empty name";
      val	= 0;
      if (n>0)
        {
          val	= name+n;
          *val++= 0;
        }
      debris_set(D, unset, name, val);
    }
  return 0;
})

C(unset, 0, -1, "var[=expr]..",  "unset a DebRIS variable or make it automatic\n"
  "Predefined variables get their default/automatic value, others are unset",
{
  return cmd_set(D, args);
})

#if 0
#define	GETSET(NAME,WHAT,HINT,DEFAULT)	\
        C(NAME, 0, 1, "[" #NAME "]", "get/set DebRIS " WHAT "\n"	\
        "if empty argument given it defaults to " HINT,			\
        {								\
          const char	*s;						\
                                                                        \
          if (args[0])							\
            return outln(D, D->NAME);					\
          TINO_FREE_NULL(D->NAME);					\
          D->NAME	= args[0][0] ? args[0] : DEFAULT;		\
          return 0;							\
        })
#endif

#undef	DEBRIS_CNAME
#undef	DEBRIS_CADD
#undef	DEBRIS_CFN
#undef	DEBRIS_CALL
#undef	DEBRIS_VADD
#undef	DEBRIS_TOPIC
#undef	V
#undef	C
