/* Magic include, for better command abstraction layer.
 *
 * This Works is placed under the terms of the Copyright Less License,
 * see file COPYRIGHT.CLL.  USE AT OWN RISK, ABSOLUTELY NO WARRANTY.
 *
 * This is included in several DEFINE phases:
 *
 * enum     -> enum { DEBRIS_FN_cmd,.. };
 * declare  -> void cmd(DEBRIS *D, int args, **argv);..
 * commands -> struct commands [] { { cmd, "cmd", DEBRIS_FN_cmd, SHORT, HELP+lf, minargs, maxargs, immediate}.. {0}};
 * code     -> void cmd(..) CODE;
 *
 * The commands below cmd/name.h must look like:
 *
 * #if CODE
 * some unique static functions
 * #endif
 *
 * SHORT("short-help-for-args")
 * HELP("long help line 1")
 * HELP("long help line 2")
 * //more HELP()
 * CMD(name, minargs, maxargs)
 * #if CODE
 * {
 *   // code here
 *   // returns void
 * }
 * #endif
 */

#define	DD_enum(X)	X(0, ENUM)
#define	DD_declare(X)	X(0, FNE)
#define	DD_commands(X)	X(0, CMD)
#define	DD_code(X)	X(1, FN)

#define	NAME_ENUM(X)	DEBRIS_FN_##X
#define	NAME_FN(X)	debris_fn_##X

#define	DB_ENUM		enum {
#define	DS_ENUM(X)
#define	DH_ENUM(X)
#define	DD_ENUM(X,A,B,C) NAME_ENUM(X),
#define	DE_ENUM		};

#define	DB_FNE
#define	DS_FNE(X)
#define	DH_FNE(X)
#define	DD_FNE(X,A,B,C)	DD_FN(X,A,B,C);
#define	DE_FNE

#define	DB_CMD		struct commands commands[]={
#define	DS_CMD(X)	{ X,
#define	DH_CMD(X)	X "\n"
#define	DD_CMD(X,A,B,C)	, #X, NAME_FN(X), NAME_ENUM(X), A, B, C },
#define	DE_CMD		{ 0 } };

#define	DB_FN
#define	DS_FN(X)
#define	DH_FN(X)
#define	DD_FN(X,A,B,C)	void NAME_FN(X)(DEBRIS *D, int args, const char * const *argv)
#define	DE_FN

#define	DB(X)		DB_##X
#define	DS(X)		DS_##X
#define	DH(X)		DH_##X
#define	DD(X)		DD_##X
#define	DE(X)		DE_##X

#define	DDcode(A,B)	A
#define	DDtype(A,B)	DD(B)
#define	DDbegin(A,B)	DB(B)
#define	DDend(A,B)	DE(B)
#define	DDshort(A,B)	DS(B)
#define	DDhelp(A,B)	DH(B)

#define	D0(X)		DD_##X
#define	D1(X)		D0(X)
#define	D2		D1(DEFINE)

#define	D2type		D2(DDtype)
#define	D2short		D2(DDshort)
#define	D2help		D2(DDhelp)
#define	D2code		D2(DDcode)

#define	CMD(X,Y,Z)	D2type(X,Y,Z,0)
#define	DEFER(X,Y,Z)	D2type(X,Y,Z,1)
#define	SHORT(X)	D2short(X)
#define	HELP(X)		D2help(X)
#define	CODE		D2code

D2(DDbegin)

#include "cmd.h"

D2(DDend)

#undef	DEFINE

