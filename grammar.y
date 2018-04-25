
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    struct argument{
        int value;
        int value2;
        char *var_name;
        int ret_reg;
    }parameter;
    int yylex(void);
    void yyerror (char const *);
    void initBison(char const *);
    void gen_code(char*,struct argument);
    int countreg = 1;
%}

%union {
  int val;
  char* text;
}

/* Bison declarations */
%token<val> D_NUM H_NUM
%token<text>  T_VAR
%token STRING_LITERAL
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

%type<val> value
%type<text> T_PLUS T_MINUS operator

/* The grammar follows. */

%%
input:
  %empty
| input command {initBison("");}
;

command:
  T_ENDL
| assign T_ENDL

| T_LOOP LEFT_PAREN value T_COMMA value RIGHT_PAREN T_ENDL statement T_SEMI T_ENDL

| if_stmt 
| T_SDEC T_VAR T_ENDL

| T_SDEC D_NUM T_ENDL

| T_SHEX T_VAR T_ENDL

| T_SHEX H_NUM T_ENDL

| T_SHNL T_ENDL

| T_SHSTR STRING_LITERAL T_ENDL

;

if_stmt:
  T_IF condition T_THEN T_ENDL statement T_SEMI T_ENDL

| T_IF condition T_THEN T_ENDL statement T_SEMI T_ENDL T_ELSE T_ENDL statement T_SEMI T_ENDL

;

statement:
  statement command
| command
;

condition:
  value compare value
;

value:
  D_NUM             {$$=$1;}
| H_NUM
;

assign:
  T_VAR T_ASS expression    {   parameter.value=parameter.ret_reg;
                                parameter.var_name = $1;
                                gen_code("assign",parameter); 
                            }   
;



expression:
  value             {   parameter.value=$1;
                        parameter.var_name=NULL;
                        gen_code("value",parameter);
                    }
| T_VAR
| expression operator value         {   
                                        int r1 = parameter.ret_reg;
                                        parameter.value=$3;
                                        parameter.var_name=NULL;
                                        gen_code("value",parameter);
                                        int r2 = parameter.ret_reg;
                                        parameter.value = r1;
                                        parameter.value2 = r2;
                                        gen_code($2,parameter);

                                    }
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
  T_PLUS                    {$$=$1;}
| T_MINUS                   {$$=$1;}
| T_MUL
| T_DIV
| T_MOD
;

%%


void yyerror (char const *s)
{
	fprintf (stderr, "%s\n", s);
}

void initBison(char const *s)
{
    printf("%s\n",s);
}

void gen_code(char * format,struct argument arg)
{
    if(!strcmp(format,"value"))
    {
        printf("MOV r%d,%d\n",countreg++,arg.value);
        parameter.ret_reg = countreg-1;
    }
    else if(!strcmp(format,"assign"))
    {
        printf("STR %s,r%d\n",arg.var_name,arg.value);
        countreg = 1;
    }
    else if(!strcmp(format,"+"))
    {
        printf("ADD r%d,r%d\n",arg.value,arg.value2);
        parameter.ret_reg=arg.value;
    }
    else if(!strcmp(format,"-"))
    {
        
        printf("SUB r%d,r%d\n",arg.value,arg.value2);
        parameter.ret_reg=arg.value;
    }
}

int main()
{
    int status = yyparse();
    while(!status)
    {
        status = yyparse();
    }
}