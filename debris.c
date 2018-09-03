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
#include "tino/hash.h"

#define	DEBRIS	struct _debris *D

struct _debris
  {
    const char		*arg0, *arg0dir, * const *cmdline;
    int			end;		/* end!=0 we are terminating, lower 8 bits are the return code	*/
    TINO_BUF		in;
    int			_rd, _wr, _ex;	/* stdin/out/err	*/

    int			outhas;		/* output was generated	*/

    int			interactive;	/* do we interact with stdin	*/

    tino_hash_map	cmds, vars;
    int			cmdmaxwidth;

    struct _debris_cmd	*now;
  };

struct _debris_cmd
  {
    const char	*name;
    int		min, max;
    const char	*usage, *help;
    const char	*(*fn)(DEBRIS, char **args);
  };

struct _debris_var
  {
    const char	*name;
    const char	*val;
    const char	*def;		/* default value (if val==0)	*/
    int		mode;
    const char	*help;		/* if set, this variable is automatic	*/
  };

static const char *
call(DEBRIS, const char *(*fn)(DEBRIS, char **args), int min, int max, va_list list)
{
  tino_str_args	args;
  const char	*ret;
  int		i;

  tino_str_args_init(&args, "");
  for (i=0; tino_str_args_add(&args, tino_strdupN(va_arg(list, char *))); i++);
  if (i<min)
    return "too few arguments to call";
  if (max>=min && i>max)
    return "too many arguments to call";

  ret	= fn(D, args.argv);
  tino_str_args_free(&args);
  return ret;
}

static void *
debris_hash(DEBRIS, tino_hash_map *h, const char *name, size_t create)
{
  tino_hash_map_val	*v;

  xDP(("(%p, %p, %s, %d)", D, h, name, create));
  v	= (create ? tino_hash_add_ptr : tino_hash_get_ptr)(h, name, strlen(name));
  if (!v)
    return 0;
  if (!v->raw.len)
    {
      FATAL(v->raw.ptr);
      if (!create)
        return 0;
      v->raw.len	= create;
      v->raw.ptr	= tino_alloc0O(create);
    }
  xDP(("() %d %s %ld %p", create, name, v->raw.len, v->raw.ptr));
  FATAL(create && v->raw.len!=create);
  FATAL(!v->raw.ptr);
  return v->raw.ptr;
}

static struct _debris_cmd *
debris_cmd(DEBRIS, const char *name, int create)
{
  struct _debris_cmd *c;

  c	= debris_hash(D, &D->cmds, name, create ? sizeof *c : 0);
  FATAL(create && !c);
  return c;
}

static struct _debris_var *
debris_var(DEBRIS, const char *name, int create)
{
  struct _debris_var	*v;

  v	= debris_hash(D, &D->vars, name, create ? sizeof *v : 0);
  if (!create)
    return v;
  FATAL(!v);
  return v;
}

static const struct _debris_var *
debris_set(DEBRIS, int unset, const char *name, const char *val)
{
  struct _debris_var	*v;

  FATAL(!name || !*name);
  v	= debris_var(D, name, !unset);
  if (!v)
    {
      FATAL(!unset);
      return v;
    }
  v->val	= val;
  return v;
}

#define	DEBRIS_CMD(X)	const char *(X)(DEBRIS, char **args)

#define	DEBRIS_CNAME(X)	static DEBRIS_CMD(cmd_##X);
#define	DEBRIS_CALL(X,Y,Z)	static const char *call_##X(DEBRIS, ...) { va_list list; va_start(list, D); const char *s=call(D, cmd_##X, Y, Z, list); va_end(list); return s; }
#include "cmd.h"

static void
debris_add_cmd(DEBRIS, DEBRIS_CMD(*fn), const char *name, int min, int max, const char *usage, const char *help)
{
  struct _debris_cmd	*c;
  int			w;

  c		= debris_cmd(D, name, 1);
  c->fn		= fn;
  c->name	= tino_strdupO(name);
  c->min	= min;
  c->max	= max;
  c->usage	= tino_strdupN(usage);
  c->help	= tino_strdupN(help);
  w	= strlen(name)+strlen(usage);
  if (w>=D->cmdmaxwidth)
    D->cmdmaxwidth	= w+1;
}

static void
debris_add_var(DEBRIS, const char *name, int mode, const char *def, const char *help)
{
  struct _debris_var	*v;

  v		= debris_var(D, name, 1);
  v->mode	= mode;
  v->def	= def;
  v->help	= help;
}

static void
debris_init(DEBRIS, int argc, const char * const *argv)
{
  tino_buf_initO(&D->in);

  D->arg0dir	= tino_file_dirname_allocO(argv[0]);
  D->arg0	= tino_file_filename_allocO(argv[0]);
  D->cmdline	= argv+1;
  FATAL(argv[argc]);
  while (argc)
    FATAL(!argv[--argc]);
  D->interactive= -1;
  D->_rd	= tino_io_fd(0, "(stdin)");
  D->_wr	= tino_io_fd(1, "(stdout)");
  D->_ex	= tino_io_fd(2, "(stderr)");

  /* This could be optimizied by pre-compiling a perfect hashmap.
   * XXX TODO XXX future optimization: Move effort to compile time.
   */
  tino_hash_map_init(&D->cmds, 100, 1);
  tino_hash_map_init(&D->vars, 1000, 2);

#define	DEBRIS_CADD(...)	debris_add_cmd(D, __VA_ARGS__);
#define	DEBRIS_VADD(...)	debris_add_var(D, __VA_ARGS__);
#include "cmd.h"
}

static void
debris_free(DEBRIS)
{
  tino_free_constO(D->arg0);
  tino_free_constO(D->arg0dir);
  /* rest of deinit?	*/
}

static const char *
outx(DEBRIS)
{
  D->outhas	= 0;
  tino_io_flush_write(D->_wr);
  return 0;
}

static const char *
outc(DEBRIS, int c)
{
  D->outhas	= 1;
  if (c>=0)
    tino_io_put(D->_wr, c);
  return 0;
}

static const char *
outs(DEBRIS, const char *s)
{
  D->outhas	= 1;
  if (s)
    tino_put_s(D->_wr, s);
  return 0;
}

static const char *
outsep(DEBRIS, const char *s)
{
  if (s)
    outs(D, s);
  if (D->outhas)
    outc(D, ' ');
  return 0;
}

static const char *
outln(DEBRIS, const char *s)
{
  outs(D, s);
  outc(D, '\n');
  return 0;
}

static const char *
outbuf(DEBRIS, const void *s, size_t len)
{
  outc(D, '\'');
  tino_put_ansi_buf(D->_wr, s, len, NULL);
  outc(D, '\'');
  return 0;
}

static const char *
outesc(DEBRIS, const char *s)
{
  return outbuf(D, s, strlen(s));
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

static void
debris_command(DEBRIS, char **argv)
{
  struct _debris_cmd	*cmd;
  int			cnt;
  const char		*err;

  if (!argv) return;			/* ignore empty command list	*/
  for (cnt=0; argv[cnt]; cnt++);
  if (cnt<=0)	return;			/* ignore too short lines	*/

  if (D->interactive<0)
    D->interactive	= 0;		/* no more fallback to STDIN	*/

  cmd	= debris_cmd(D, argv[0], 0);
  if (!cmd)
    return debris_error(D, "unknown command: %s", argv[0]);

  if (cnt<=cmd->min)
    return debris_error(D, "too few args to comand: %s %s", cmd->name, cmd->usage);
  if (cmd->max>=cmd->min && cnt-1>cmd->max)
    return debris_error(D, "too many args to comand: %s %s", cmd->name, cmd->usage);

  D->now	= cmd;
  err		= cmd->fn(D, argv+1);
  outx(D);
  if (err)
    return debris_error(D, "%s error: %s", cmd->name, err);
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
        call_print(D, "{$prompt}", NULL);
      if ((line=tino_buf_line_readE(&buf, fd, '\n'))==0)
        break;
      while (isspace(*line))			/* skip spaces at start of interactive line	*/
        line++;
      debris_feed(D, line);			/* process line	*/
      debris_feed(D, "\n");			/* line above does not contain LF	*/
    }
  tino_buf_freeO(&buf);
}

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

#define	DEBRIS_CFN(X,Y)	static const char *cmd_##X(DEBRIS, char **args) Y
#include "cmd.h"

