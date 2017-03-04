#include <stdio.h>
#include <stdlib.h>

#include "tino/alloc.h"

#include "debris_version.h"


typedef struct debris DEBRIS;
struct debris
  {
    int status;
  };

struct commands
  {
    const char	*help, *desc, *name;
    void	(*fn)(DEBRIS *, int, const char * const *);
    int		minargs, maxargs, deferred;
  };

#define	DEFINE	enum
#include "debris.h"

#define	DEFINE	declare
#include "debris.h"

#define	DEFINE	commands
#include "debris.h"

#define	DEFINE	code
#include "debris.h"

static void
err(DEBRIS *D, const char *s, ...)
{
  va_list	list;

  xDP(("(%s)", s));
  va_start(list, s);
  fprintf(stderr, "error: ");
  vfprintf(stderr, s, list);
  fprintf(stderr, "\n");
  va_end(list);

  D->status = 1;
  return;
}

void
run(DEBRIS *D, int n, const char * const *argv)
{
  struct commands *ptr;

  n--;
  for (ptr=commands; ptr->name; ptr++)
    if (n>=ptr->minargs && n<=ptr->maxargs && !strcmp(argv[0], ptr->name))
      {
	xDP(("() %s", ptr->name));
        if (ptr->deferred)
	  err(D, "command is deferred: %s", argv[0]);
        else
	  ptr->fn(D, n, argv+1);
	xDP(("() here"));
	return;
      }
  err(D, "command not found: %s (try: help)", argv[0]);
}

void
interactive(DEBRIS *D)
{
  exit(1);
}

int
main(int argc, const char * const *argv)
{
  DEBRIS *D;

  D = tino_alloc0O(sizeof *D);

  if (argc>1)
    run(D, argc-1, argv+1);
  else
    interactive(D);

  return D->status;
}

