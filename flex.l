D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*
err         .

%option noyywrap

%{
    #include <stdio.h>
    #include <string.h>
    #include "grammar.tab.h"
%}

%%
[ \t]           ; // ignore all whitespace
\n				{ return T_ENDL;}
[0-9]+          { yylval.text = strdup(yytext);return D_NUM;}
[0-9A-F]+[hH]   { return H_NUM;}

[$]v[A-Z]       { yylval.text = strdup(yytext);return T_VAR;}

[+]             { yylval.text = strdup(yytext);return T_PLUS;}
[-]             { yylval.text = strdup(yytext);return T_MINUS;}
[*]             { yylval.text = strdup(yytext);return T_MUL;}
[/]             { return T_DIV;}
[%]             { return T_MOD;}
[(]             { return LEFT_PAREN;}
[)]             { return RIGHT_PAREN;}

[=]             { return T_ASS;}
SHD             { return T_SDEC;}
SHH             { return T_SHEX;}
SHN             { return T_SHNL;}
SHS             { return T_SHSTR;}

if              { return T_IF;}
then            { return T_THEN;}
else            { return T_ELSE;}
";"             { return T_SEMI;}
"=="            { return T_EQUL;}
">"             { return T_MORE;}             
"<"             { return T_LESS;}
">="            { return T_MOREEQ;}
"<="            { return T_LESSEQ;}
"!="            { return T_NOTEQ;}
LOOP            { return T_LOOP;}
","             { return T_COMMA;}
\"(\\.|[^\\"])*\" { return STRING_LITERAL;}
\'(\\.|[^\\"])*\' { return STRING_LITERAL;}
%%
