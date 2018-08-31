/* DebRIS: Debian Remote Install Service
 *
 * This Works is placed under the terms of the Copyright Less License,
 * see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.
 *
 * This is very easy to understand:
 *
 * ./debris command..
 *
 * - Commands are lines.
 * - First, the environment variable DebRIS is parsed.
 * - Then commandline is parsed (each arg is a command).
 * - If still no command was present, commands are read from stdin until EOF.
 *
 * For all commands see "help"
 */

#include "tino/dirty.h"
#include "tino/file.h"
#include "tino/filetool.h"
#include "tino/fatal.h"
#include "tino/buf_line.h"
#include "tino/strargs.h"
#include "tino/put.h"

#define	DEBRIS	struct _debris *D

struct _debris
  {
    const char	*arg0, *arg0dir, * const *cmdline;
    int		end;		/* end!=0 we are terminating, lower 8 bits are the return code	*/
    TINO_BUF	in;
    int		rd, wr, ex;	/* stdin/out/err	*/

    int		interactive;	/* do we interact with stdin	*/
    const char	*prompt;
  };

static void
debris_init(DEBRIS, int argc, const char * const *argv)
{
  tino_buf_initO(&D->in);

  D->arg0dir	= tino_file_dirname_allocO(argv[0]);
  D->arg0	= tino_file_filename_allocO(argv[0]);
  D->cmdline	= argv+1;
  D->prompt	= "DEBRIS: ";
  FATAL(argv[argc]);
  while (argc)
    FATAL(!argv[--argc]);
  D->interactive= -1;
  D->rd		= tino_io_fd(0, "(stdin)");
  D->wr		= tino_io_fd(1, "(stdout)");
  D->ex		= tino_io_fd(2, "(stderr)");
}

static void
debris_free(DEBRIS)
{
  tino_free_constO(D->arg0);
  tino_free_constO(D->arg0dir);
  /* rest of deinit?	*/
}

static int
debris_exit(DEBRIS)
{
  int	code;

  code	= D->end & 0xff;
  debris_free(D);
  return code;
}

static void
debris_error(DEBRIS, const char *format, ...)
{
  va_list	list;

  fflush(stdout);
  fflush(stderr);
  fprintf(stderr, "\nDebRIS ERROR: ");
  va_start(list, format);
  vfprintf(stderr, format, list);
  va_end(list);
  fprintf(stderr, "\n");
  fflush(stderr);
}

#define	DEBRIS_FN(X,Y)	static const char *debriscmd_##X(DEBRIS, char **args);
#include "cmd.h"

struct _cmd
  {
    const char	*cmd;
    int		min, max;
    const char	*usage, *help;
    const char	*(*fn)(DEBRIS, char **args);
  } _cmds[] = {
#define	DEBRIS_CMD(X)	{ #X
#define	DEBRIS_MIN(X)	, X
#define	DEBRIS_MAX(X)	, X
#define	DEBRIS_USAGE(X)	, X
#define	DEBRIS_HELP(X)	, X
#define	DEBRIS_FN(X,Y)	, debriscmd_##X },
#include "cmd.h"
    { 0 }
  };

static void
debris_command(DEBRIS, char **argv)
{
  struct _cmd	*cmd;
  int		cnt;
  const char	*err;

  if (!argv) return;			/* ignore empty command list	*/
  for (cnt=0; argv[cnt]; cnt++);
  if (cnt<=0)	return;			/* ignore too short lines	*/

  if (D->interactive<0)
    D->interactive	= 0;		/* no more fallback to STDIN	*/

  /* we could improve this with perfect hashing, of course	*/
  for (cmd=_cmds;; cmd++)
    if (!cmd->cmd)
      return debris_error(D, "unknown command: %s", argv[0]);
    else if (!strcmp(cmd->cmd, argv[0]))
      break;

  if (cnt<=cmd->min)
    return debris_error(D, "too few args to comand: %s %s", cmd->cmd, cmd->usage);
  if (cmd->max>=cmd->min && cnt-1>cmd->max)
    return debris_error(D, "too many args to comand: %s %s", cmd->cmd, cmd->usage);

  err	= cmd->fn(D, argv+1);
  tino_io_flush_write(D->wr);
  if (err)
    return debris_error(D, "%s error: %s", cmd->cmd, err);
}

/* Parse input into arguments	*/
static void
debris_parse(DEBRIS, const char *cmd)
{
  tino_str_args args;

  if (!cmd || !*cmd)
    return;				/* ignore empty/missing lines	*/

  tino_str_args_init(&args, cmd);
  tino_str_args_argvOi(&args);		/* Probably we need some more sophisticated parser in future	*/

  debris_command(D, args.argv);		/* Run the command	*/

  tino_str_args_free(&args);		/* cleanup	*/
}

/* Feed some line to the command parser	*/
static void
debris_feed(DEBRIS, const char *data)
{
  int pos;

  if (D->end)
    return;		/* we are terminating?	*/

  if (data)
    tino_buf_add_sO(&D->in, data);

  while (!D->end && (pos=tino_buf_line_scan(&D->in, '\n', 0))!=0)
    {
      char	*cmd;

      if (pos<0)
        pos	= -pos-1;
      else if (data)	/* data==NULL: fallthrough to command	*/
        return;		/* more data ahead, perhaps	*/
      cmd	= tino_buf_get_s_nonconstO(&D->in);
      cmd[pos]	= 0;
      tino_buf_advanceO(&D->in, pos+1);
      debris_parse(D, cmd);
    }
}

static void
debris_feed_arglist(DEBRIS, char **args)
{
  if (!args) return;				/* ignore non-data	*/

  while (*args)
     {
       debris_feed(D, *args++);			/* Feed arg as line	*/
       debris_feed(D, NULL);
     }
}

static void
debris_feed_env(DEBRIS, const char *data)
{
  tino_str_args		split;

  if (!data) return;				/* ignore non-data	*/

  tino_str_args_init(&split, data);
  split.quote	= "\'\'\"\"()";			/* allow {quoting}	*/
  tino_str_args_argvOi(&split);			/* Probably we want some more sophisticated parser in future	*/
  debris_feed_arglist(D, split.argv);		/* feed the args	*/
  tino_str_args_free(&split);
}

/* Well, breaking things up is a bit redundant here.
 * We could fill D->in and then debris_feed(D, "");
 *
 * However in future we might want to use GNU_readline,
 * hence do it line by line here.
 */
static void
debris_interactive(DEBRIS, int fd)
{
  TINO_BUF	buf;
  const char	*line;
  int		tty;

  tty	= isatty(fd);		/* XXX TODO XXX use GNU readline if on TTY	*/
  tino_buf_initO(&buf);
  while (!D->end)
    {
      if (tty && !tino_buf_get_lenO(&D->in))
        tino_file_write_sE(fd, D->prompt);
      if ((line=tino_buf_line_readE(&buf, fd, '\n'))==0)
        break;
      while (isspace(*line))			/* skip spaces at start of interactive line	*/
        line++;
      debris_feed(D, line);			/* process line	*/
      debris_feed(D, "\n");			/* line above does not contain LF	*/
    }
  tino_buf_freeO(&buf);
}

#define	DEBRIS_FN(X,Y)	static const char *debriscmd_##X(DEBRIS, char **args) Y
#include "cmd.h"

int
main(int argc, const char * const *argv)	/* Yay, that's easy, right?	*/
{
  struct _debris	debris	= { 0 };
  DEBRIS		= &debris;

  debris_init(D, argc, argv);

  debris_feed_env(D, getenv("DEBRIS"));		/* Split env DEBRIS into commands	*/

  /* we cannot use debris_freed_args here, as D->cmdline might get consumed by commands */
  while (*D->cmdline)
    {
      debris_feed(D, *D->cmdline++);		/* Add commands from commandline	*/
      debris_feed(D, NULL);
    }

  if (D->interactive)
    debris_interactive(D, 0);			/* Read commands from stdin	*/
  debris_feed(D, NULL);

  return debris_exit(D);			/* done	*/
}

