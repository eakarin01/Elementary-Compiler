
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
        struct return_val ret3;
    }parameter;
    int yylex(void);
    void yyerror (char const *);
    void initBison(char const *);
    int selectReg();
    void clearReg(char[]);
    int isRegister(char []);
    void genasmfile(char[],char[]);
    struct return_val* gen_code(char*,struct argument);
    struct return_val* gen_cond(char*,struct argument);
    char asmreg[][5] = {"rax","rbx","rdx"};
    int usereg[3] = {0,0,0};
    int loopcount = 0;
    int msgcount = 0;
    int ifcount = 0;
    int varflag[26];
    int sd_flag = 0;
    int sh_flag = 0;
    int err_flag = 0;
    FILE *fp;
    char filename[20];
    int yylineno;
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

%type<text> value T_PLUS T_MINUS T_MUL T_DIV T_MOD T_ENDL
%type<ret> expression command assign statement input condition

%start start;

/* The grammar follows. */

%%
start:
  input   {
            if(!err_flag)
              genasmfile($1->cmd,$1->data);
          }
;
input:
  %empty    {$$=gen_code("empty",parameter);}
| input command     {  //printf("---------------------------------\n%s",$2->cmd);
                      parameter.ret = *($1);
                      parameter.ret2 = *($2);
                      $$=gen_code("concat",parameter);
                    }
;

command:
  T_ENDL            { 
                     $$=gen_code("empty",parameter);
                     }
| assign T_ENDL                       { $$=$1;}

| T_LOOP LEFT_PAREN value RIGHT_PAREN T_ENDL statement T_SEMI T_ENDL
                    {
                      parameter.value=$3;
                      parameter.ret = *($6);
                      $$=gen_code("LOOPN",parameter);
                    }
| T_LOOP LEFT_PAREN condition RIGHT_PAREN T_ENDL statement T_SEMI T_ENDL
                    {
                      parameter.ret = *($3);
                      parameter.ret2 = *($6);
                      $$=gen_code("LOOPW",parameter);
                    }

| T_IF condition T_THEN T_ENDL statement T_SEMI T_ENDL
                    {
                      parameter.ret = *($2);
                      parameter.ret2 = *($5);
                      $$=gen_code("IF",parameter);
                    }

| T_IF condition T_THEN T_ENDL statement T_SEMI T_ENDL T_ELSE T_ENDL statement T_SEMI T_ENDL
                    {
                      parameter.ret = *($2);
                      parameter.ret2 = *($5);
                      parameter.ret3 = *($10);
                      $$=gen_code("IFELSE",parameter);
                    }


| T_SDEC expression T_ENDL
              {
                parameter.ret = *($2);
                $$=gen_code("SHD",parameter);
                sd_flag = 1;
              }

| T_SHEX expression T_ENDL
              {
                parameter.ret = *($2);
                $$=gen_code("SHH",parameter);
                sh_flag = 1;
              }

| T_SHNL T_ENDL                       { 
                                        $$=gen_code("SHN",parameter);
                                      }

| T_SHSTR STRING_LITERAL T_ENDL       { parameter.value=$2;
                                        parameter.len=strlen($2)-2;
                                        $$=gen_code("SHS",parameter);   
                                      }

| error T_ENDL      {yyerrok ;} // when error occur skip token util T_ENDL

;



statement:
  %empty      {$$=gen_code("empty",parameter);}
| statement command              
          {
              parameter.ret = *($1);
              parameter.ret2 = *($2);
              $$=gen_code("concat",parameter);
          }
;

condition:
  expression T_EQUL expression
                                    {
                                      parameter.ret = *($1);
                                      parameter.ret2 = *($3);
                                      $$=gen_cond("je",parameter);
                                    }
| expression T_MORE expression
                                    {
                                      parameter.ret = *($1);
                                      parameter.ret2 = *($3);
                                      $$=gen_cond("jg",parameter);
                                    }
| expression T_LESS expression
                                    {
                                      parameter.ret = *($1);
                                      parameter.ret2 = *($3);
                                      $$=gen_cond("jl",parameter);
                                    }
| expression T_MOREEQ expression
                                    {
                                      parameter.ret = *($1);
                                      parameter.ret2 = *($3);
                                      $$=gen_cond("jge",parameter);
                                    }
| expression T_LESSEQ expression
                                    {
                                      parameter.ret = *($1);
                                      parameter.ret2 = *($3);
                                      $$=gen_cond("jle",parameter);
                                    }
| expression T_NOTEQ expression
                                    {
                                      parameter.ret = *($1);
                                      parameter.ret2 = *($3);
                                      $$=gen_cond("jne",parameter);
                                    }
;


value:
  D_NUM             {strcat($1,"\0");$$=$1;}
| H_NUM             {strcat($1,"\0");$$=$1;}
| T_VAR             {strcat($1,"\0");$$=$1;}
;

assign:
  T_VAR T_ASS expression    { strcat($1,"\0");
                              parameter.var_name=$1;
                              parameter.ret = *($3);
                              $$=gen_code("assign",parameter);
                            }
;



expression:
  value             { strcat($1,"\0");
                      parameter.value=$1;
                      // check if value is variable
                      if ($1[0]=='$')
                      {
                        int idxvar = $1[2]-'A';
                        // check if variable not declaration
                        if (!varflag[idxvar])
                        {
                          char strerr[100];
                          sprintf(strerr,"ERROR: No variable declaration (%s) in line %d",$1,yylineno);
                          yyerror(strerr);
                          err_flag=1;
                          YYERROR;
                        }
                      }
                      $$=gen_code("value",parameter);
                    }
| expression T_PLUS expression    { 
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
                                    $$=gen_code($2,parameter);
                                  }    
| expression T_DIV expression     { parameter.ret = *($1);
                                    parameter.ret2 = *($3);
                                    int number;
                                    // check if isn't varable
                                    if ($3->reg[0]!='[' && !isRegister($3->reg))
                                    {
                                      // check if hexa
                                      if ($3->reg[strlen($3->reg)-1]=='h' || $3->reg[strlen($3->reg)-1]=='H')
                                      {
                                        // convert to number
                                        number=(int)strtol($3->reg, NULL, 16);
                                      }
                                      else
                                      {
                                        // convert to number
                                        number = atoi($3->reg);
                                      }
                                    }
                                    // check in divide by zero
                                    if (number==0)
                                    {
                                      char strerr[100];
                                      sprintf(strerr,"ERROR: Divide by 0 in line %d",yylineno);
                                      yyerror(strerr);
                                      err_flag=1;
                                      YYERROR;
                                    }
                                    $$=gen_code($2,parameter);
                                  } 
| expression T_MOD expression     { parameter.ret = *($1);
                                    parameter.ret2 = *($3);
                                    int number;
                                    // check if isn't varable
                                    if ($3->reg[0]!='[' && !isRegister($3->reg))
                                    {
                                      // check if hexa
                                      if ($3->reg[strlen($3->reg)-1]=='h' || $3->reg[strlen($3->reg)-1]=='H')
                                      {
                                        // convert to number
                                        number=(int)strtol($3->reg, NULL, 16);
                                      }
                                      else
                                      {
                                        // convert to number
                                        number = atoi($3->reg);
                                      }
                                    }
                                    // check in divide by zero
                                    if (number==0)
                                    {
                                      char strerr[100];
                                      sprintf(strerr,"ERROR: Modulus by 0 in line %d",yylineno);
                                      yyerror(strerr);
                                      err_flag=1;
                                      YYERROR;
                                    }
                                    $$=gen_code("%%",parameter);
                                  }
| LEFT_PAREN expression RIGHT_PAREN   {$$=$2;}                                                                                                                                         
| T_MINUS expression %prec NEG    { parameter.ret2 = *($2);
                                    $$=gen_code("NEG",parameter);
                                  }
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
        sprintf(command,"mov %s,%d\n",asmreg[regid],atoi(arg.value));
        sprintf(regname,"%s",asmreg[regid]);
      }
      strcpy(ret->cmd,command);
      strcpy(ret->reg,regname);*/
      strcpy(regname,arg.value);
      if (arg.value[0]=='$')
        sprintf(regname,"[%s]",arg.value);
      strcpy(ret->cmd,"");
      strcpy(ret->reg,regname);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
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
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret.reg);
        strcpy(arg.ret.reg,asmreg[regid]);
      }
      sprintf(command,"%s\t\tmov [%s],%s\n",command,arg.var_name,arg.ret.reg);
      clearReg(arg.ret.reg);
      // add section data
      strcpy(data,"");
      int idxvar = arg.var_name[2]-'A';
      // check if never declaration
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

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
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
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret.reg);
        strcpy(arg.ret.reg,asmreg[regid]);
      }
      if(!isRegister(arg.ret2.reg) && arg.ret2.reg[0]=='[')
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
      }
      sprintf(command,"%s\t\tADD %s,%s\n",command,arg.ret.reg,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret.reg);
      clearReg(arg.ret2.reg);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
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
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret.reg);
        strcpy(arg.ret.reg,asmreg[regid]);
      }
      if(!isRegister(arg.ret2.reg) && arg.ret2.reg[0]=='[')
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
      }
      sprintf(command,"%s\t\tSUB %s,%s\n",command,arg.ret.reg,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret.reg);
      clearReg(arg.ret2.reg);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
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
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
      }
      sprintf(command,"%s\t\tNEG %s\n",command,arg.ret2.reg);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,arg.ret2.reg);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
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
      // if right is in rax
      if (!strcmp(arg.ret2.reg,asmreg[0]))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
        sprintf(command,"%s\t\tmov rax,%s\n",command,arg.ret.reg);
        usereg[0]=1;
        clearReg(arg.ret.reg);
      }
      // if left is not in rax
      else if (strcmp(arg.ret.reg,asmreg[0]))
      {
        // check if rax has been use
        if (usereg[0])
        {
          sprintf(command,"%s\t\tPUSH rax\n",command);
          checkpush=1;
        }
        sprintf(command,"%s\t\tmov rax,%s\n",command,arg.ret.reg);
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
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(regname,asmreg[regid]);
      }
      //sprintf(command,"%sPUSH rdx\nIMUL %s\nPOP rdx\n",command,regname);
      sprintf(command,"%s\t\tIMUL %s\n",command,regname);
      clearReg(regname);
      strcpy(ret->reg,asmreg[0]);
      if (checkpush)
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tmov %s,rax\n",command,asmreg[regid]);
        sprintf(command,"%s\t\tPOP rax\n",command);
        strcpy(ret->reg,asmreg[regid]);
      }
      strcpy(ret->cmd,command);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
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
      // if right is in rax
      if (!strcmp(arg.ret2.reg,asmreg[0]))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
        sprintf(command,"%s\t\tmov rax,%s\n",command,arg.ret.reg);
        clearReg(arg.ret.reg);
        usereg[0]=1;
      }
      // if left is not in rax
      else if (strcmp(arg.ret.reg,asmreg[0]))
      {
        // check if rax has been use
        if (usereg[0])
        {
          sprintf(command,"%s\t\tPUSH rax\n",command);
          checkpush=1;
        }
        sprintf(command,"%s\t\tmov rax,%s\n",command,arg.ret.reg);
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
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(regname,asmreg[regid]);
      }
      sprintf(command,"%s\t\txor rdx,rdx\n\t\tIDIV %s\n",command,regname);
      clearReg(regname);
      strcpy(ret->reg,asmreg[0]);
      if (checkpush)
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tmov %s,rax\n",command,asmreg[regid]);
        sprintf(command,"%s\t\tPOP rax\n",command);
        strcpy(ret->reg,asmreg[regid]);
      }
      strcpy(ret->cmd,command);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
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
      // if right is in rax
      if (!strcmp(arg.ret2.reg,asmreg[0]))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
        sprintf(command,"%s\t\tmov rax,%s\n",command,arg.ret.reg);
        usereg[0]=1;
        clearReg(arg.ret.reg);
        strcpy(arg.ret.reg,asmreg[0]);
      }
      // if left is not in rax
      else if (strcmp(arg.ret.reg,asmreg[0]))
      {
        // check if rax has been use
        if (usereg[0])
        {
          sprintf(command,"%s\t\tPUSH rax\n",command);
          checkpush=1;
        }
        sprintf(command,"%s\t\tmov rax,%s\n",command,arg.ret.reg);
        usereg[0]=1;
        clearReg(arg.ret.reg);  
        strcpy(arg.ret.reg,asmreg[0]);
      }
      // create register for return value 2
      // if right is not register
      if(!isRegister(arg.ret2.reg))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
      }
      sprintf(command,"%s\t\txor rdx,rdx\n\t\tIDIV %s\n",command,arg.ret2.reg);
      clearReg(arg.ret.reg);
      clearReg(arg.ret2.reg);
      if (checkpush)
      {
        sprintf(command,"%s\t\tPOP rax\n",command);
        usereg[0]=1;
      }
      int newregid = selectReg();
      sprintf(command,"%s\t\tmov %s,rdx\n",command,asmreg[newregid]);
      strcpy(ret->reg,asmreg[newregid]);
      strcpy(ret->cmd,command);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"SHS"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      char data[10000];
      sprintf(command,"\t\tmov rax,1\n\t\tmov rdi,1\n\t\tmov rsi,msg%d\n\t\tmov rdx,%d\n\t\tsyscall\n",msgcount,arg.len);
      sprintf(data,"\t\tmsg%d db %s, 0\n",msgcount++,parameter.value);
      strcpy(ret->cmd,command);
      strcpy(ret->data,data);
      //printf("[%s]",ret->cmd);
      //printf("(%s)dsfsdfds",ret->data);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"SHN"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      sprintf(command,"\t\tmov rax,1\n\t\tmov rdi,1\n\t\tmov rsi,CRLF\n\t\tmov rdx,%d\n\t\tsyscall\n",1);
      strcpy(ret->cmd,command);
      strcpy(ret->data,"");
      //printf("%s",command);
      //printf("[%s]",data);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"SHD"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      // get return cmd
      sprintf(command,"%s",arg.ret.cmd);
      // check if reg is not RAX
      if(strcmp(arg.ret.reg,asmreg[0]))
      {
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[0],arg.ret.reg);
        clearReg(arg.ret.reg);
        strcpy(arg.ret.reg,asmreg[0]);
      }
      sprintf(command,"%s\t\tcall print_decnum\n",command);
      clearReg(arg.ret.reg);
      strcpy(ret->cmd,command);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"empty"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      strcpy(ret->cmd,"");
      strcpy(ret->data,"");

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"SHH"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      // get return cmd
      sprintf(command,"%s",arg.ret.cmd);
      // check if reg is not RAX
      if(strcmp(arg.ret.reg,asmreg[0]))
      {
        sprintf(command,"%s\t\tmov %s,%s\n",command,asmreg[0],arg.ret.reg);
        clearReg(arg.ret.reg);
        strcpy(arg.ret.reg,asmreg[0]);
      }
      sprintf(command,"%s\t\tcall print_hexnum\n",command);
      clearReg(arg.ret.reg);
      strcpy(ret->cmd,command);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"empty"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      strcpy(ret->cmd,"");
      strcpy(ret->data,"");

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"concat"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      char data[10000];
      // init form left
      strcpy(command,arg.ret.cmd);
      strcpy(data,arg.ret.data);
      // concat wirh right
      strcat(command,arg.ret2.cmd);
      strcat(data,arg.ret2.data);
      strcpy(ret->cmd,command);
      strcpy(ret->data,data);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"LOOPN"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      // check if value is address variable
      if (arg.value[0]=='$')
      {
        // take [] to variable
        char regname[100];
        sprintf(regname,"[%s]",arg.value);
        strcpy(arg.value,regname);
      }
      sprintf(command,"\t\tPUSH rcx\n\t\tMOV rcx,%s\nL%d:\n\t\tcmp rcx,0\n\t\tjle E%d\n\t\tPUSH rcx\n",arg.value,loopcount,loopcount);
      sprintf(command,"%s%s\t\tPOP rcx\n\t\tdec rcx\n\t\tjmp L%d\nE%d:\n\t\tPOP rcx\n",command,arg.ret.cmd,loopcount,loopcount);
      loopcount++;
      strcpy(ret->cmd,command);
      strcpy(ret->data,arg.ret.data);
      
      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"LOOPW"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      sprintf(command,"LC%d:\n%s\t\t%s LS%d\n\t\tjmp LX%d\n",loopcount,arg.ret.cmd,arg.ret.reg,loopcount,loopcount);
      sprintf(command,"%sLS%d:\n%s\t\tjmp LC%d\nLX%d:\n",command,loopcount,arg.ret2.cmd,loopcount,loopcount);
      loopcount++;
      strcpy(ret->cmd,command);
      strcpy(ret->data,arg.ret2.data);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"IF"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      // get condition command
      strcpy(command,arg.ret.cmd);
      sprintf(command,"%s\t\t%s C%d\n\t\tjmp EC%d\nC%d:\n",command,arg.ret.reg,ifcount,ifcount,ifcount);
      // get statement command
      sprintf(command,"%s%sEC%d:\n",command,arg.ret2.cmd,ifcount);
      ifcount++;
      strcpy(ret->cmd,command);
      strcpy(ret->data,arg.ret2.data);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
    else if(!strcmp(format,"IFELSE"))
    {
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      // get condition command
      strcpy(command,arg.ret.cmd);
      sprintf(command,"%s\t\t%s C%d\n\t\tjmp EC%d\nC%d:\n",command,arg.ret.reg,ifcount,ifcount,ifcount);
      // get statement command
      sprintf(command,"%s%s\t\tjmp EX%d\nEC%d:\n%sEX%d:\n",command,arg.ret2.cmd,ifcount,ifcount,arg.ret3.cmd,ifcount);
      ifcount++;
      strcpy(ret->cmd,command);
      strcpy(ret->data,arg.ret2.data);
      strcat(ret->data,arg.ret3.data);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
    }
}

struct return_val* gen_cond(char * format,struct argument arg)
{
      struct return_val* ret = (struct return_val*)malloc(sizeof(struct return_val));
      char command[10000];
      char reg[10];
      strcpy(command,arg.ret.cmd);
      strcat(command,arg.ret2.cmd);
      // check left is not register
      if (!isRegister(arg.ret.reg))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret.reg);
        clearReg(arg.ret.reg);
        strcpy(arg.ret.reg,asmreg[regid]);
      }
      // check right is not register
      if (!isRegister(arg.ret2.reg))
      {
        int regid = selectReg();
        sprintf(command,"%s\t\tMOV %s,%s\n",command,asmreg[regid],arg.ret2.reg);
        clearReg(arg.ret2.reg);
        strcpy(arg.ret2.reg,asmreg[regid]);
      }
      // both are register !!
      sprintf(command,"%s\t\tcmp %s,%s\n",command,arg.ret.reg,arg.ret2.reg);
      clearReg(arg.ret.reg);
      clearReg(arg.ret2.reg);
      sprintf(reg,"%s",format);
      strcpy(ret->cmd,command);
      strcpy(ret->reg,reg);

      strcat(ret->cmd,"\0");
      strcat(ret->reg,"\0");
      strcat(ret->data,"\0");
      return ret;
}



void genasmfile(char text[],char data[])
{
  char file[10000];
  // gen data section
  sprintf(file,"section .data\n%s",data);
  // gen newline character
  sprintf(file,"%s\t\tCRLF db 10, 0\n",file);
  // gen bss section
  sprintf(file,"%ssection .bss\n\t\tnumber resb 20\n",file);
  sprintf(file,"%ssection .text\n\t\tglobal _start\n_start:\n%s\n",file,text);
  // add exit program to my program
  sprintf(file,"%s\t\tmov rax,60\n\t\tmov rdi,0\n\t\tsyscall\n\n",file);
  if(sd_flag)
  {
    // gen print dec num function
    sprintf(file,"%sprint_decnum:\n",file);
    sprintf(file,"%s\t\tmov r8,20\n",file);
    sprintf(file,"%s\t\tmov rbx,10\n",file);
    sprintf(file,"%sdivloop:\n",file);
    sprintf(file,"%s\t\tdec r8\n",file);
    sprintf(file,"%s\t\tlea r9,[number+r8]\n",file);
    sprintf(file,"%s\t\txor rdx,rdx\n",file);
    sprintf(file,"%s\t\tidiv rbx\n",file);
    sprintf(file,"%s\t\tadd rdx,48\n",file);
    sprintf(file,"%s\t\tmov byte[r9],dl\n",file);
    sprintf(file,"%s\t\tcmp rax,0\n",file);
    sprintf(file,"%s\t\tjne divloop\n",file);
    sprintf(file,"%s\t\tmov r10,20\n",file);
    sprintf(file,"%s\t\tmov r10,r8\n",file);
    sprintf(file,"%s\t\tmov rax,1\n",file);
    sprintf(file,"%s\t\tmov rdi,1\n",file);
    sprintf(file,"%s\t\tmov rsi,r9\n",file);
    sprintf(file,"%s\t\tmov rdx,r10\n",file);
    sprintf(file,"%s\t\tsyscall\n",file);
    sprintf(file,"%s\t\tret\n",file);
  }
  if(sh_flag)
  {
    // gen print hex num function
    sprintf(file,"%sprint_hexnum:\n",file);
    sprintf(file,"%s\t\tmov r8,20\n",file);
    sprintf(file,"%s\t\tmov rbx,16\n",file);
    sprintf(file,"%sdivloop2:\n",file);
    sprintf(file,"%s\t\tdec r8\n",file);
    sprintf(file,"%s\t\tlea r9,[number+r8]\n",file);
    sprintf(file,"%s\t\txor rdx,rdx\n",file);
    sprintf(file,"%s\t\tidiv rbx\n",file);
    sprintf(file,"%s\t\tcmp rdx,10\n",file);
    sprintf(file,"%s\t\tjge genAF\n",file);
    sprintf(file,"%s\t\tjmp gen09\n",file);
    sprintf(file,"%sgenAF:\n",file);
    sprintf(file,"%s\t\tadd rdx,55\n",file);
    sprintf(file,"%s\t\tsub rdx,48\n",file);
    sprintf(file,"%sgen09:\n",file);
    sprintf(file,"%s\t\tadd rdx,48\n",file);
    sprintf(file,"%s\t\tmov byte[r9],dl\n",file);
    sprintf(file,"%s\t\tcmp rax,0\n",file);
    sprintf(file,"%s\t\tjne divloop2\n",file);
    sprintf(file,"%s\t\tdec r8\n",file);
    sprintf(file,"%s\t\tlea r9,[number+r8]\n",file);
    sprintf(file,"%s\t\tmov byte[r9],120\n",file);
    sprintf(file,"%s\t\tdec r8\n",file);
    sprintf(file,"%s\t\tlea r9,[number+r8]\n",file);
    sprintf(file,"%s\t\tmov byte[r9],48\n",file);
    sprintf(file,"%s\t\tmov r10,20\n",file);
    sprintf(file,"%s\t\tmov r10,r8\n",file);
    sprintf(file,"%s\t\tmov rax,1\n",file);
    sprintf(file,"%s\t\tmov rdi,1\n",file);
    sprintf(file,"%s\t\tmov rsi,r9\n",file);
    sprintf(file,"%s\t\tmov rdx,r10\n",file);
    sprintf(file,"%s\t\tsyscall\n",file);
    sprintf(file,"%s\t\tret\n",file);
  }
  strcat(file,"\0");
  FILE* fp;
  fp = fopen(filename,"w");
  fprintf(fp,"%s",file);
  fclose(fp);
}


int main(int args,char* argv[])
{
  if (!argv[1]) 
  {
    fprintf(stderr,"Error: missing output filename\n");
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