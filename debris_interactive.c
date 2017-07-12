/* This Works is placed under the terms of the Copyright Less License,
 * see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.
 */

#include "debris_interactive.h"

void
debris_interactive(DEBRIS *D)
{
  D->notyet(D, "interactive");
}

int
debris(DEBRIS *D, int argc, const char * const *argv)
{
  debris_init(D);

  if (argc>0)
    D->run(D, argc, argv);
  else
    debris_interactive(D);

  D->exit(D);
  return D->status;
}

