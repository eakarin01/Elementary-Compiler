
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    struct return_val{
        char data[10000];
        char cmd[10000];
        char reg[10];
    }myreturn;
    struct argument{
        int len;
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
    int isRegister(char []);
    void genasmfile(char[],char[]);
    struct return_val* gen_code(char*,struct argument);
    char asmreg[][5] = {"RAX","RBX","RDX"};
    int usereg[3] = {0,0,0};
    int msgcount = 0;
    int varflag[26];
    FILE *fp;
    char textcode[10000] = "";
    char datacode[10000] = "";
    char filename[20];
%}

%union {
  int val;
  char* text;
  struct return_val* ret;
}

/* Bison declarations */
%token<text> D_NUM H_NUM
%token<text> T_VAR
%token<text> STRING_LITERAL
%right T_ASS
%left T_EQUL T_NOTEQ
%left T_MORE T_LESS T_MOREEQ T_LESSEQ
%left T_PLUS T_MINUS
%left T_MUL T_DIV T_MOD
%right T_IF T_THEN T_ELSE
%right T_SDEC T_SHEX T_SHNL T_SHSTR
%token T_LOOP T_COMMA T_SEMI
%token LEFT_PAREN RIGHT_PAREN
%precedence NEG
%token T_ENDL

%type<text> value T_PLUS T_MINUS T_MUL T_DIV T_MOD
%type<ret> expression command assign

/* The grammar follows. */

%%
start:
  input { genasmfile(textcode,datacode);}
;
input:
  %empty
| input command     {  //printf("---------------------\n%s",$2->cmd);
                        strcat(textcode,$2->cmd);
                        strcat(datacode,$2->data);
                    }
;

command:
  T_ENDL
| assign T_ENDL                       { $$=$1;}

| T_LOOP LEFT_PAREN value T_COMMA value RIGHT_PAREN T_ENDL statement T_SEMI T_ENDL

| if_stmt 
| T_SDEC T_VAR T_ENDL

| T_SDEC D_NUM T_ENDL

| T_SHEX T_VAR T_ENDL

| T_SHEX H_NUM T_ENDL

| T_SHNL T_ENDL                       { 
                                        $$=gen_code("SHN",parameter);
                                      }

| T_SHSTR STRING_LITERAL T_ENDL       { parameter.value=$2;
                                        parameter.len=strlen($2)-2;
                                        $$=gen_code("SHS",parameter);
                                      }

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
| H_NUM             {$$=$1;}
;

assign:
  T_VAR T_ASS expression    { 
                              parameter.var_name=$1;
                              parameter.ret = *($3);
                              $$=gen_code("assign",parameter);
                            }
;



expression:
  value             { parameter.value=$1;
                      $$=gen_code("value",parameter);
                      //printf("[%d]",atoi($1));
                    }
| T_VAR             { parameter.value=$1;
                      $$=gen_code("value",parameter);
                    }
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
| expression T_MOD expression     { parameter.ret = *($1);
                                    parameter.ret2 = *($3);
                                    $$=gen_code("%%",parameter);
                                  }
| LEFT_PAREN expression RIGHT_PAREN   {$$=$2;}                                                                                                                                         
| T_MINUS expression %prec NEG    { parameter.ret2 = *($2);
                                    $$=gen_code("NEG",parameter);
                                  }
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

int isRegister(char name[])
{
  for(int i=0;i<3;i++)
  {
    if(!strcmp(asmreg[i],name))
    {
      return 1;
    }
  }
  return 0;
}

struct return_val* gen_code(char * format,struct argument arg)
{
    if(!strcmp(format,"value"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      char regname[10];
      /*int regid = selectReg();
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
      strcpy(ret->reg,regname);*/
      strcpy(regname,arg.value);
      if (arg.value[0]=='$')
        sprintf(regname,"[%s]",arg.value);
      strcpy(ret->cmd,"");
      strcpy(ret->reg,regname);
      return ret;
    }
    else if(!strcmp(format,"assign"))
    {
      // get return command
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      char data[10000];
      sprintf(command,"%s",arg.ret.cmd);
      // assign command
      if(!isRegister(arg.ret.reg))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret.reg);
        strcpy(arg.ret.reg,asmreg[regid]);
      }
      sprintf(command,"%s\t\tMOV [%s],%s\n",command,arg.var_name,arg.ret.reg);
      clearReg(arg.ret.reg);
      // add section data
      strcpy(data,"");
      int idxvar = arg.var_name[2]-'A';
      // check if already has
      if (!varflag[idxvar])
      {
        // gen section data code
        sprintf(data,"\t\t%s dq 0\n",arg.var_name);
        varflag[idxvar]=1;
      }
      strcpy(ret->data,data);
      strcpy(ret->cmd,command);
      //printf("%s",command);
      //printf("[%s]",ret->data);
      return ret;
    }
    else if(!strcmp(format,"+"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      // get return command
      sprintf(command,"%s%s",arg.ret.cmd,arg.ret2.cmd);
      // ADD command
      if(!isRegister(arg.ret.reg))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret.reg);
        strcpy(arg.ret.reg,asmreg[regid]);
      }
      if(!isRegister(arg.ret2.reg) && arg.ret2.reg[0]=='[')
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
      }
      sprintf(command,"%s\t\tADD %s,%s\n",command,arg.ret.reg,arg.ret2.reg);
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
      if(!isRegister(arg.ret.reg))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret.reg);
        strcpy(arg.ret.reg,asmreg[regid]);
      }
      if(!isRegister(arg.ret2.reg) && arg.ret2.reg[0]=='[')
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
      }
      sprintf(command,"%s\t\tSUB %s,%s\n",command,arg.ret.reg,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret.reg);
      clearReg(arg.ret2.reg);
      return ret;
    }
    else if(!strcmp(format,"NEG"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      // get return command
      sprintf(command,"%s",arg.ret2.cmd);
      // NEG command
      // check if not register
      if (!isRegister(arg.ret2.reg))
      {
        // assign register
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
      }
      sprintf(command,"%s\t\tNEG %s\n",command,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret2.reg);
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
      // if right is in RAX
      if (!strcmp(arg.ret2.reg,"RAX"))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
        sprintf(command,"%s\t\tMOV RAX,%s\n",command,arg.ret.reg);
        usereg[0]=1;
        clearReg(arg.ret.reg);
      }
      // if left is not in RAX
      else if (strcmp(arg.ret.reg,"RAX"))
      {
        // check if RAX has been use
        if (usereg[0])
        {
          sprintf(command,"%s\t\tPUSH RAX\n",command);
          checkpush=1;
        }
        sprintf(command,"%s\t\tMOV RAX,%s\n",command,arg.ret.reg);
        clearReg(arg.ret.reg);
        usereg[0]=1;
      }
      // create register for return value 2
      char regname[10];
      strcpy(regname,arg.ret2.reg);
      // if right is not register
      if(!isRegister(arg.ret2.reg))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(regname,asmreg[regid]);
      }
      //sprintf(command,"%sPUSH RDX\nIMUL %s\nPOP RDX\n",command,regname);
      sprintf(command,"%s\t\tIMUL %s\n",command,regname);
      clearReg(regname);
      strcpy(ret->reg,"RAX");
      if (checkpush)
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,RAX\n",command,asmreg[regid]);
        sprintf(command,"%s\t\tPOP RAX\n",command);
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
      // if right is in RAX
      if (!strcmp(arg.ret2.reg,"RAX"))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
        sprintf(command,"%s\t\tMOV RAX,%s\n",command,arg.ret.reg);
        clearReg(arg.ret.reg);
        usereg[0]=1;
      }
      // if left is not in RAX
      else if (strcmp(arg.ret.reg,"RAX"))
      {
        // check if RAX has been use
        if (usereg[0])
        {
          sprintf(command,"%s\t\tPUSH RAX\n",command);
          checkpush=1;
        }
        sprintf(command,"%s\t\tMOV RAX,%s\n",command,arg.ret.reg);
        clearReg(arg.ret.reg);
        usereg[0]=1;
      }
      // create register for return value 2
      char regname[10];
      strcpy(regname,arg.ret2.reg);
      // if right is not register
      if(!isRegister(arg.ret2.reg))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(regname,asmreg[regid]);
      }
      sprintf(command,"%s\t\tIDIV %s\n",command,regname);
      clearReg(regname);
      strcpy(ret->reg,"RAX");
      if (checkpush)
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,RAX\n",command,asmreg[regid]);
        sprintf(command,"%s\t\tPOP RAX\n",command);
        strcpy(ret->reg,asmreg[regid]);
      }
      strcpy(ret->cmd,command);
      return ret;
    }
    else if(!strcmp(format,"%%"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      int checkpush=0;
      // get return command
      sprintf(command,"%s%s",arg.ret.cmd,arg.ret2.cmd);
      // MOD command
      // if right is in RAX
      if (!strcmp(arg.ret2.reg,"RAX"))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
        sprintf(command,"%s\t\tMOV RAX,%s\n",command,arg.ret.reg);
        usereg[0]=1;
        clearReg(arg.ret.reg);
        strcpy(arg.ret.reg,"RAX");
      }
      // if left is not in RAX
      else if (strcmp(arg.ret.reg,"RAX"))
      {
        // check if RAX has been use
        if (usereg[0])
        {
          sprintf(command,"%s\t\tPUSH RAX\n",command);
          checkpush=1;
        }
        sprintf(command,"%s\t\tMOV RAX,%s\n",command,arg.ret.reg);
        usereg[0]=1;
        clearReg(arg.ret.reg);  
        strcpy(arg.ret.reg,"RAX");
      }
      // create register for return value 2
      // if right is not register
      if(!isRegister(arg.ret2.reg))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
      }
      sprintf(command,"%s\t\tIDIV %s\n",command,arg.ret2.reg);
      clearReg(arg.ret.reg);
      clearReg(arg.ret2.reg);
      if (checkpush)
      {
        sprintf(command,"%s\t\tPOP RAX\n",command);
        usereg[0]=1;
      }
      int newregid = selectReg();
      sprintf(command,"%s\t\tMOV %s,RDX\n",command,asmreg[newregid]);
      strcpy(ret->reg,asmreg[newregid]);
      strcpy(ret->cmd,command);
      return ret;
    }
    else if(!strcmp(format,"SHS"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      char data[10000];
      sprintf(command,"\t\tMOV RAX,1\n\t\tMOV RDI,1\n\t\tMOV RSI,msg%d\n\t\tMOV RDX,%d\n\t\tSYSCALL\n",msgcount,arg.len);
      sprintf(data,"\t\tmsg%d dq %s, 0\n",msgcount++,parameter.value);
      strcpy(ret->cmd,command);
      strcpy(ret->data,data);
      //printf("%s",command);
      //printf("[%s]",data);
      return ret;
    }
    else if(!strcmp(format,"SHN"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      sprintf(command,"\t\tMOV RAX,1\n\t\tMOV RDI,1\n\t\tMOV RSI,CRLF\n\t\tMOV RDX,%d\n\t\tSYSCALL\n",1);
      strcpy(ret->cmd,command);
      strcpy(ret->data,"");
      //printf("%s",command);
      //printf("[%s]",data);
      return ret;
    }

}


void genasmfile(char text[],char data[])
{
  char file[10000];
  sprintf(file,"section .data\n%s",data);
  // gen newline character
  sprintf(file,"%s\t\tCRLF db 10, 0\n\n",file);
  sprintf(file,"%ssection .text\n\t\tglobal _start\n_start:\n%s\n",file,text);
  // add exit program to my program
  sprintf(file,"%s\t\tMOV RAX,60\n\t\tMOV RDI,0\n\t\tSYSCALL",file);
  FILE* fp;
  fp = fopen(filename,"w");
  fprintf(fp,"%s",file);
  fclose(fp);
}


int main(int args,char* argv[])
{
  if (!argv[1]) 
  {
    printf("Error: missing output filename\n");
    return 0;
  }
  strcpy(filename,argv[1]);
  // init var flag
  for(int i=0;i<26;i++)
    varflag[i]=0;
  //fp = fopen("test.asm","w");  
  int status = yyparse();
  //fclose(fp);
}