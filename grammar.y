
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    struct return_val{
        char* cmd;
        char* reg;
    }myreturn;
    struct argument{
        char* value;
        char* var_name;
        struct return_val ret;
    }parameter;
    int yylex(void);
    void yyerror (char const *);
    void initBison(char const *);
    struct return_val* gen_code(char*,struct argument);
    int countreg = 1;
%}

%union {
  int val;
  char* text;
  struct return_val* ret;
}

/* Bison declarations */
%token<text> D_NUM H_NUM
%token<text> T_VAR
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

%type<text> value T_PLUS operator T_MINUS T_MUL
%type<ret> expression

/* The grammar follows. */

%%
input:
  %empty
| input command {}
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
  T_VAR T_ASS expression    { 
                              parameter.var_name=$1;
                              parameter.ret = *($3);
                              gen_code("assign",parameter);
                            }
;



expression:
  value             { parameter.value=$1;
                      $$=gen_code("value",parameter);
                    }
| T_VAR             
| expression operator value   { parameter.ret = *($1);
                                parameter.value=$3;
                                $$=gen_code($2,parameter);
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
  T_PLUS          {$$=$1;}             
| T_MINUS         {$$=$1;}           
| T_MUL           {$$=$1;}
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

struct return_val* gen_code(char * format,struct argument arg)
{
    if(!strcmp(format,"value"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[100000];
      char regname[5];
      sprintf(command,"MOV r%d,%d\n",countreg,atoi(arg.value));
      sprintf(regname,"r%d",countreg++);
      ret->cmd = command;
      ret->reg = regname;
      return ret;
    }
    else if(!strcmp(format,"assign"))
    {
      printf("%s",parameter.ret.cmd);
      printf("STR %s,%s\n",parameter.var_name,parameter.ret.reg);
    }
    else if(!strcmp(format,"+"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[100000];
      sprintf(command,"%sADD %s,%d\n",parameter.ret.cmd,parameter.ret.reg,atoi(parameter.value));
      ret->cmd = command;
      ret->reg = parameter.ret.reg;
      return ret;
    }
    else if(!strcmp(format,"-"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[100000];
      sprintf(command,"%sSUB %s,%d\n",parameter.ret.cmd,parameter.ret.reg,atoi(parameter.value));
      ret->cmd = command;
      ret->reg = parameter.ret.reg;
      return ret;
    }
    else if(!strcmp(format,"*"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[100000];
      sprintf(command,"%sMUL %s,%d\n",parameter.ret.cmd,parameter.ret.reg,atoi(parameter.value));
      ret->cmd = command;
      ret->reg = parameter.ret.reg;
      return ret;
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