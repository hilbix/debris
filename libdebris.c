#include "tino/dirty.h"
#include "tino/alloc.h"

#if 0
#include <stdio.h>
#include <stdlib.h>
#endif

#include "debris.h"
#include "debris_version.h"

static void
verr(DEBRIS *D, const char *s, va_list list)
{
  xDP(("(%s)", s));
  fprintf(stderr, "error: ");
  vfprintf(stderr, s, list);
  fprintf(stderr, "\n");
  va_end(list);
}

static void
err(DEBRIS *D, const char *s, ...)
{
  va_list	list;

  xDP(("(%s)", s));
  va_start(list, s);
  D->err(D, s, list);
  va_end(list);

  D->status = 1;
}

static void
notyet(DEBRIS *D, const char *what)
{
  err(D, "not yet implemented: %s", what);
}

#define	DEFINE	enum
#include "cmds.h"

#define	DEFINE	declare
#include "cmds.h"

#define	DEFINE	commands
#include "cmds.h"

#define	DEFINE	code
#include "cmds.h"

static void
run(DEBRIS *D, int argc, const char * const *argv)
{
  struct commands *ptr;

  FATAL(argc<=0);
  argc--;	/* decrement args here for better cmp below */
  for (ptr=commands; ptr->name; ptr++)
    if (!strcmp(argv[0], ptr->name))
      {
	if (argc<ptr->minargs || (ptr->maxargs>=ptr->minargs && argc>ptr->maxargs))
	  return err(D, "wrong number of arguments, see: help %s", ptr->name);

        D->cmd = ptr;
	D->status = 0;
	xDP(("() run %s", ptr->name));
        if (ptr->deferred)
	  err(D, "command is deferred: %s", argv[0]);
        else
	  ptr->fn(D, argc, argv+1);
	xDP(("() end %s: %d", ptr->name, D->status));
	return;
      }
  err(D, "command not found: %s (try: help)", argv[0]);
}

static void
debris_free(DEBRIS *D)
{
  /* TODO XXX TODO	*/
  000;
}

void
debris_init(DEBRIS *D)
{
  memset(D, 0, sizeof *D);
  D->version	= DEBRIS_VERSION;
  D->exit	= debris_free;
  D->err	= verr;
  D->run	= run;
  D->notyet	= notyet;
}

