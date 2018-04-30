
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
    int selectReg();
    void clearReg(char[]);
    struct return_val* gen_code(char*,struct argument);
    char asmreg[][5] = {"RAX","RBX","RDX"};
    int usereg[3] = {0,0,0};
    int countreg = 0;
    FILE *fp;
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

%type<text> value T_PLUS T_MINUS T_MUL T_DIV T_MOD
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
                      //printf("[%d]",atoi($1));
                    }
| T_VAR             
| expression T_PLUS expression    { 
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
| expression T_MUL expression     { parameter.ret = *($1);
                                    parameter.ret2 = *($3);
                                    //printf("[%s]",$3->cmd);
                                    $$=gen_code($2,parameter);
                                  }    
| expression T_DIV expression     { parameter.ret = *($1);
                                    parameter.ret2 = *($3);
                                    $$=gen_code($2,parameter);
                                  } 
| expression T_MOD expression      
| LEFT_PAREN expression RIGHT_PAREN   {$$=$2;}                                                                                                                                         
| T_MINUS expression %prec NEG
;


compare:
  T_EQUL
| T_MORE
| T_LESS
| T_MOREEQ
| T_LESSEQ
| T_NOTEQ
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

int selectReg()
{
  for(int i=0;i<3;i++)
  {
    if (usereg[i]==0)
    {
      usereg[i]=1;
      return i;
    }
  }
  return -1;
}

void clearReg(char regname[])
{
  for(int i=0;i<3;i++)
  {
    if(!strcmp(regname,asmreg[i]))
    {
      usereg[i]=0;
    }
  }
}

struct return_val* gen_code(char * format,struct argument arg)
{
    if(!strcmp(format,"value"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      char regname[10];
      int regid = selectReg();
      // no one empty register
      if (regid==-1)
      {
        strcpy(command,"");
        sprintf(regname,"%s",arg.value);
      }
      else
      {
        sprintf(command,"MOV %s,%d\n",asmreg[regid],atoi(arg.value));
        sprintf(regname,"%s",asmreg[regid]);
      }
      strcpy(ret->cmd,command);
      strcpy(ret->reg,regname);
      return ret;
    }
    else if(!strcmp(format,"assign"))
    {
      // get return command
      printf("%s",arg.ret.cmd);
      printf("MOV %s,%s\n",arg.ret.reg,arg.var_name);
      clearReg(arg.ret.reg);
    }
    else if(!strcmp(format,"+"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      // get return command
      sprintf(command,"%s%s",arg.ret.cmd,arg.ret2.cmd);
      // ADD command
      sprintf(command,"%sADD %s,%s\n",command,arg.ret.reg,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret.reg);
      clearReg(arg.ret2.reg);
      return ret;
    }
    else if(!strcmp(format,"-"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      // get return command
      sprintf(command,"%s%s",arg.ret.cmd,arg.ret2.cmd);
      // SUB command
      sprintf(command,"%sSUB %s,%s\n",command,arg.ret.reg,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret.reg);
      clearReg(arg.ret2.reg);
      return ret;
    }
    else if(!strcmp(format,"*"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      int checkpush=0;
      // get return command
      sprintf(command,"%s%s",arg.ret.cmd,arg.ret2.cmd);
      // MUL command
      // check RAX is empty
      if (strcmp(arg.ret.reg,"RAX"))
      {
        sprintf(command,"%sPUSH RAX\n",command);
        sprintf(command,"%sMOV RAX,%s\n",command,arg.ret.reg);
        clearReg(arg.ret.reg);
        checkpush=1;
      }
      sprintf(command,"%sPUSH RDX\nIMUL %s\nPOP RDX\n",command,arg.ret2.reg);
      clearReg(arg.ret2.reg);
      strcpy(ret->reg,"RAX");
      if (checkpush)
      {
        int regid = selectReg();
        sprintf(command,"%sMOV %s,RAX\n",command,asmreg[regid]);
        sprintf(command,"%sPOP RAX\n",command);
        strcpy(ret->reg,asmreg[regid]);
      }
      strcpy(ret->cmd,command);
      return ret;
    }
    else if(!strcmp(format,"/"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      int checkpush=0;
      // get return command
      sprintf(command,"%s%s",arg.ret.cmd,arg.ret2.cmd);
      // DIV command
      // check RAX is empty
      if (strcmp(arg.ret.reg,"RAX"))
      {
        sprintf(command,"%sPUSH RAX\n",command);
        sprintf(command,"%sMOV RAX,%s\n",command,arg.ret.reg);
        clearReg(arg.ret.reg);
        checkpush=1;
      }
      sprintf(command,"%sPUSH RDX\nIDIV %s\nPOP RDX\n",command,arg.ret2.reg);
      clearReg(arg.ret2.reg);
      strcpy(ret->reg,"RAX");
      if (checkpush)
      {
        int regid = selectReg();
        sprintf(command,"%sMOV %s,RAX\n",command,asmreg[regid]);
        sprintf(command,"%sPOP RAX\n",command);
        strcpy(ret->reg,asmreg[regid]);
      }
      strcpy(ret->cmd,command);
      return ret;
    }

}

int main()
{
  //fp = fopen("test.asm","w");  
  int status = yyparse();
  //fclose(fp);
}