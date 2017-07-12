#define	D_enum(X)	X(ENUM, IGN, IGN, 0, enum {, };)
#define	D_declare(X)	X(FNE, IGN, IGN, 0,,)
#define	D_commands(X)	X(CMD, BEGIN, LF, 0, struct commands commands[]={, { 0 } };)
#define	D_code(X)	X(FN, IGN, IGN, 1,,)

#define	IGN(X)
#define	NAME(X)		debris_fn_##X
#define	STR(X)		#X

#define	ENUM(X,A,B,C)	DEBRIS_FN_##X,
#define	FN(X,A,B,C)	void NAME(X)(DEBRIS *D, int args, const char * const *argv)
#define	FNE(X,A,B,C)	FN(X,A,B,C);

#define	BEGIN(X)	{ X,
#define	LF(X)		X "\n"
#define	CMD(X,Y,Z,A)	, #X, NAME(X), Y, Z, A },

#define	SEL1(A,B,C,D,E,F)	A
#define	SEL2(A,B,C,D,E,F)	B
#define	SEL3(A,B,C,D,E,F)	C
#define	SEL4(A,B,C,D,E,F)	D
#define	SEL5(A,B,C,D,E,F)	E
#define	SEL6(A,B,C,D,E,F)	F

#define	D0(X)		D_##X
#define	D1(X)		D0(X)
#define	DD		D1(DEFINE)

#define	DD1	 	DD(SEL1)
#define	DD2	 	DD(SEL2)
#define	DD3	 	DD(SEL3)
#define	DD4	 	DD(SEL4)
#define	DD5	 	DD(SEL5)
#define	DD6	 	DD(SEL6)

#define	IMMEDIATE(X,Y,Z)	DD1(X,Y,Z,0)
#define	COMMAND(X,Y,Z)		DD1(X,Y,Z,1)
#define	SHORT(X)	DD2(X)
#define	HELP(X)		DD3(X)
#define	CODE		DD4

DD5

#include "cmd.h"

DD6
#undef	DEFINE

