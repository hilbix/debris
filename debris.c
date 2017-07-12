/* This Works is placed under the terms of the Copyright Less License,
 * see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.
 */

#include "debris_interactive.h"

int
main(int argc, const char * const *argv)
{
  DEBRIS D;

  return debris(&D, argc-1, argv+1);
}

/* We could link this with
 *
 * OBJS=libdebris.o debris_interactive.o
 *
 * However Makefile.tino does not support
 * dependency calculation of object files (yet).
 * Hence this trick to get around.
 */

#include "debris_interactive.c"
#include "libdebris.c"

