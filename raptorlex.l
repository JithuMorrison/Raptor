%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parse.tab.h"

int line_num = 1;
%}

%option noyywrap

DIGIT       [0-9]
LETTER      [a-zA-Z]
ID          {LETTER}({LETTER}|{DIGIT}|_)*
INT         {DIGIT}+
FLOAT       {INT}\.{INT}
STRING      \"[^\"]*\"
CHAR        \'[^\']\' 

%%

"int"       { return INT_TYPE; }
"float"     { return FLOAT_TYPE; }
"char"      { return CHAR_TYPE; }
"string"    { return STRING_TYPE; }
"bool"      { return BOOL_TYPE; }
"list"      { return LIST_TYPE; }
"dict"      { return DICT; }
"obj"       { return OBJ; }
"class"     { return CLASS; }
"fn"        { return FN; }
"if"        { return IF; }
"else"      { return ELSE; }
"for"       { return FOR; }
"while"     { return WHILE; }
"in"        { return IN; }
"where"     { return WHERE; }
"true"      { return TRUE; }
"false"     { return FALSE; }
"self"      { return SELF; }
"ret"       { return RET; }

":="        { return COLON_EQ; }
"=="        { return EQ; }
"!="        { return NEQ; }
"<="        { return LEQ; }
">="        { return GEQ; }
"&&"        { return AND; }
"||"        { return OR; }
".."        { return DOTDOT; }
"->"        { return ARROW; }

"="         { return ASSIGN; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return STAR; }
"/"         { return SLASH; }
"%"         { return MOD; }
"<"         { return LT; }
">"         { return GT; }
"!"         { return NOT; }
"?"         { return QUESTION; }
":"         { return COLON; }
";"         { return SEMI; }
","         { return COMMA; }
"."         { return DOT; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
"["         { return LBRACK; }
"]"         { return RBRACK; }
"_"         { return UNDERSCORE; }

{INT}       { yylval.str = strdup(yytext); return INT_LITERAL; }
{FLOAT}     { yylval.str = strdup(yytext); return FLOAT_LITERAL; }
{STRING}    { yylval.str = strdup(yytext); return STRING_LITERAL; }
{CHAR}      { yylval.str = strdup(yytext); return CHAR_LITERAL; }
{ID}        { yylval.str = strdup(yytext); return IDENTIFIER; }

[ \t]+      { /* ignore whitespace */ }
\n          { line_num++; }
"//".*      { /* single-line comment */ }
"/*"([^*]|\*+[^*/])*\*+"/" { 
    /* multi-line comment - count newlines */
    for (char *p = yytext; *p; p++) {
        if (*p == '\n') line_num++;
    }
}

.           { fprintf(stderr, "Unexpected character: %s at line %d\n", yytext, line_num); }

%%
