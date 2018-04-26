
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    struct return_val{
        char cmd[10000];
        char reg[10];
    }myreturn;
    struct argument{
        char* value;
        char* var_name;
        struct return_val ret;
        struct return_val ret2;
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

%type<text> value T_PLUS operator T_MINUS T_MUL T_DIV T_MOD
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
                      //printf("{%p:%s}",&($$->cmd),$$->cmd);
                    }
| T_VAR             
| expression T_PLUS expression   { 
                                    /*printf("[%p:%s]",&($1->cmd),$1->cmd);
                                    printf("[%p:%s]",&($3->cmd),$3->cmd);*/
                                    parameter.ret = *($1);
                                parameter.ret2 = *($3);
                                $$=gen_code($2,parameter);
                              }
| expression T_MINUS expression   { parameter.ret = *($1);
                                parameter.ret2 = *($3);
                                $$=gen_code($2,parameter);
                              } 
| expression T_MUL expression   { parameter.ret = *($1);
                                parameter.ret2 = *($3);
                                $$=gen_code($2,parameter);
                              }    
| expression T_DIV expression   { parameter.ret = *($1);
                                parameter.ret2 = *($3);
                                $$=gen_code($2,parameter);
                              } 
| expression T_MOD expression                                                                                                                                               
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
| T_DIV           {$$=$1;}
| T_MOD           {$$=$1;}
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
      char command[10000];
      char regname[10];
      sprintf(command,"MOV r%d,%d\n",countreg,atoi(arg.value));
      sprintf(regname,"r%d",countreg++);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,regname);
      return ret;
    }
    else if(!strcmp(format,"assign"))
    {
      printf("%s",arg.ret.cmd);
      printf("STR %s,%s\n",arg.var_name,arg.ret.reg);
    }
    else if(!strcmp(format,"+"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      sprintf(command,"%s%sADD %s,%s\n",arg.ret.cmd,arg.ret2.cmd,arg.ret.reg,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret.reg);
      return ret;
    }
    else if(!strcmp(format,"-"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      sprintf(command,"%s%sSUB %s,%s\n",arg.ret.cmd,arg.ret2.cmd,arg.ret.reg,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret.reg);
      return ret;
    }
    else if(!strcmp(format,"*"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      sprintf(command,"%s%sMUL %s,%s\n",arg.ret.cmd,arg.ret2.cmd,arg.ret.reg,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret.reg);
      return ret;
    }
    else if(!strcmp(format,"/"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      sprintf(command,"%s%sDIV %s,%s\n",arg.ret.cmd,arg.ret2.cmd,arg.ret.reg,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret.reg);
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