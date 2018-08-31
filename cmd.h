#ifndef	DEBRIS_CMD
#define	DEBRIS_CMD(X)
#endif
#ifndef	DEBRIS_MIN
#define	DEBRIS_MIN(X)
#endif
#ifndef	DEBRIS_MAX
#define	DEBRIS_MAX(X)
#endif
#ifndef	DEBRIS_USAGE
#define	DEBRIS_USAGE(X)
#endif
#ifndef	DEBRIS_HELP
#define	DEBRIS_HELP(X)
#endif
#ifndef	DEBRIS_FN
#define	DEBRIS_FN(X,Y)
#endif

#define	C(NAME,MIN,MAX,USAGE,HELP,FN)	DEBRIS_CMD(NAME)DEBRIS_MIN(MIN)DEBRIS_MAX(MAX)DEBRIS_USAGE(USAGE)DEBRIS_HELP(HELP)DEBRIS_FN(NAME,FN)

C(exit, 0,1, "[n]", "exit DebRIS with given return code, default: 0",
{
  int	c;

  c = args[0] ? atoi(args[0]) : 0;
  D->end	= 0x100 | c;
  return 0;
})

C(help, 0, 1, "[command]", "list available commands or explain command",
{
  struct _cmd *cmd = _cmds;

  if (!args[0])
    {
      for (cmd=_cmds; cmd->cmd; cmd++)
        printf("%s %s\n", cmd->cmd, cmd->usage);
      return 0;
    }
  for (cmd=_cmds; cmd->cmd; cmd++)
    if (!strcmp(cmd->cmd, args[0]))
      {
        printf("%s %s:\n\t%s\n", cmd->cmd, cmd->usage, cmd->help);
        return 0;
      }
  return "no help available for the given command";
})

C(echo, 0, -1, "[args..]", "echo the given args to stdout, space separated",
{
  debriscmd_echoc(D, args);
  tino_io_put(D->wr, '\n');
  return 0;
})

C(println, 0, -1, "[args..]", "like echo, but quotes arguments",
{
  debriscmd_print(D, args);
  tino_io_put(D->wr, '\n');
  return 0;
})

C(echoc, 0, -1, "[args..]", "like echo, without NL",
{
  while (*args)
    {
      tino_put_s(D->wr, *args++);
      if (*args)
        tino_io_put(D->wr, ' ');
    }
  return 0;
})

C(print, 0, -1, "[args..]", "like println without NL",
{
  while (*args)
    {
      tino_put_ansi_if(D->wr, *args++);
      if (*args)
        tino_io_put(D->wr, ' ');
    }
  return 0;
})

#undef	DEBRIS_CMD
#undef	DEBRIS_MIN
#undef	DEBRIS_MAX
#undef	DEBRIS_USAGE
#undef	DEBRIS_HELP
#undef	DEBRIS_FN
#undef	C

