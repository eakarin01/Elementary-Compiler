
%{
    #include <stdio.h>
    #include <stdlib.h>
    int yylex(void);
    void yyerror (char const *);
    void printCmd(char const *);
%}

/* Bison declarations */
%token D_NUM H_NUM T_VAR STRING_LITERAL
%right T_ASS
%left T_EQUL T_MORE T_LESS T_MOREEQ T_LESSEQ T_NOTEQ
%left T_PLUS T_MINUS
%left T_MUL T_DIV
%left T_MOD
%token T_LOOP T_COMMA T_SEMI
%right T_IF T_THEN T_ELSE
%right T_SDEC T_SHEX T_SHNL T_SHSTR
%token LEFT_PAREN RIGHT_PAREN
%precedence NEG
%token T_ENDL


/* The grammar follows. */

%%
input:
  %empty
| input command
;

command:
  T_ENDL
| assign T_ENDL
    {
        printCmd("Assignment");
    }
| T_LOOP LEFT_PAREN value T_COMMA value RIGHT_PAREN T_ENDL statement T_SEMI T_ENDL
    {
        printCmd("Loop");
    }
| T_IF condition T_THEN T_ENDL statement T_SEMI T_ENDL
    {
        printCmd("IF");
    }
| T_IF condition T_THEN T_ENDL statement T_SEMI T_ENDL T_ELSE T_ENDL statement T_SEMI T_ENDL
    {
        printCmd("IF-ELSE");
    }
| T_SDEC T_VAR T_ENDL
    {
        printCmd("Show DEC");
    }
| T_SDEC D_NUM T_ENDL
    {
        printCmd("Show DEC");
    }
| T_SHEX T_VAR T_ENDL
    {
        printCmd("SHOW HEX");
    }
| T_SHEX H_NUM T_ENDL
    {
        printCmd("SHOW HEX");
    }
| T_SHNL T_ENDL
    {
        printCmd("SHOW NEWLINE");
    }
| T_SHSTR STRING_LITERAL T_ENDL
    {
        printCmd("SHOW String");
    }
;


statement:
  statement command
| command
;

condition:
  value compare value
;

value:
  D_NUM
| H_NUM
| T_VAR
;

assign:
  T_VAR T_ASS expression
;



expression:
  value
| expression operator value
| expression operator parenthesis
| T_MINUS expression %prec NEG
| parenthesis
;

parenthesis:
LEFT_PAREN expression RIGHT_PAREN
;



compare:
  T_EQUL
| T_MORE
| T_LESS
| T_MOREEQ
| T_LESSEQ
| T_NOTEQ
;

operator:
  T_PLUS
| T_MINUS
| T_MUL
| T_DIV
| T_MOD
;

%%


void yyerror (char const *s)
{
	fprintf (stderr, "%s\n", s);
}

void printCmd(char const *s)
{
    printf("%s\n",s);
}

int main()
{
    int status = yyparse();
    while(!status)
    {
        status = yyparse();
    }
}