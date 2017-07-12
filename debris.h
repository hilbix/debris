/* DebRIS runtime include
 *
 * This Works is placed under the terms of the Copyright Less License,
 * see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.
 */

#ifndef	INC_libdebris_h
#define	INC_libdebris_h

#include <stdarg.h>

#define	DEBRIS_NOTYET

typedef struct debris DEBRIS;
struct debris
  {
    /* Public members	*/
    int			status;
    const char		*version;	/* static string */

    /* extension area	*/
    void		*user_ptr;	/* for your use	*/

    /* Methods, can be overrridden	*/
    void		(*exit)(DEBRIS *);	/* free this */
    void		(*err)(DEBRIS *, const char *s, va_list list);	/* all errors go here	*/
    void		(*run)(DEBRIS *, int argc, const char * const *argv);	/* run command	*/
#ifdef	DEBRIS_NOTYET
    void		(*notyet)(DEBRIS *, const char *s);
#endif

    /* Following is internal to DebRIS and may change	*/
    struct commands	*cmd;
  };

struct commands
  {
    const char	*help, *desc, *name;
    void	(*fn)(DEBRIS *, int, const char * const *);
    int		cmd_nr, minargs, maxargs, deferred;
  };

/* Initialize structure.  This NULLs everything.
 *
 * How to use:
 *
 * DEBRIS *D;
 *
 * D = malloc(sizeof(*D));
 * debris_init(D);
 * assert(!D->status);
 * //D->user = some_own_structure;
 * //D->err  = some_own_error_processing_function;
 * ..
 * cmd[0] = "ls";
 * D->run(D, 1, cmd);
 * ..
 * D->exit(D);
 * status = D->status;
 * free(D);
 */
void debris_init(DEBRIS *);

#endif

