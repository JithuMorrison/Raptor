%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE *yyin;
extern int line_num;

void yyerror(const char *s);
%}

%union {
    char *str;
}

%token <str> IDENTIFIER INT_LITERAL FLOAT_LITERAL STRING_LITERAL CHAR_LITERAL
%token INT_TYPE FLOAT_TYPE CHAR_TYPE STRING_TYPE BOOL_TYPE LIST_TYPE
%token DICT OBJ CLASS FN IF ELSE FOR WHILE IN WHERE TRUE FALSE SELF RET
%token COLON_EQ EQ NEQ LEQ GEQ AND OR DOTDOT ARROW UNDERSCORE
%token ASSIGN PLUS MINUS STAR SLASH MOD LT GT NOT QUESTION COLON
%token SEMI COMMA DOT LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK

%right ASSIGN COLON_EQ
%right QUESTION COLON
%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS
%left STAR SLASH MOD
%right NOT UMINUS UPLUS
%left DOT LPAREN LBRACK

%start Program

%%

Program:
    StmtList { printf("Parsing completed successfully!\n"); }
    ;

StmtList:
    StmtList Stmt
    | /* epsilon */
    ;

Stmt:
    SimpleStmt SEMI
    | ComplexStmt
    ;

SimpleStmt:
    VarDecl
    | Assignment
    | FnCall
    | MemberFnCall
    | MemberAssignment
    | ClassInstantiation
    | ReturnStmt
    ;

ComplexStmt:
    FuncDef
    | IfStmt
    | ForStmt
    | WhileStmt
    | Block
    | ObjDecl
    | ClassDecl
    ;

Block:
    LBRACE StmtList RBRACE
    ;

VarDecl:
    Type IDENTIFIER
    | Type IDENTIFIER ASSIGN Expr
    | IDENTIFIER COLON_EQ Expr
    ;

Type:
    INT_TYPE
    | FLOAT_TYPE
    | CHAR_TYPE
    | STRING_TYPE
    | BOOL_TYPE
    | LIST_TYPE
    | DICT
    | IDENTIFIER
    ;

Assignment:
    IDENTIFIER ASSIGN Expr
    ;

MemberAssignment:
    IDENTIFIER DOT IDENTIFIER ASSIGN Expr
    ;

ReturnStmt:
    RET Expr
    | RET
    ;

ObjDecl:
    OBJ IDENTIFIER ASSIGN LBRACE ObjBody RBRACE
    ;

ObjBody:
    ObjMemberList
    | /* epsilon */
    ;

ObjMemberList:
    ObjMember SEMI
    | ObjMemberList ObjMember SEMI
    ;

ObjMember:
    Type IDENTIFIER
    | Type IDENTIFIER ASSIGN Expr
    | IDENTIFIER COLON_EQ Expr
    | FuncSig
    | FuncDef
    ;

FuncSig:
    FN IDENTIFIER LPAREN ParamList RPAREN
    ;

ClassDecl:
    CLASS IDENTIFIER LPAREN ParamList RPAREN Block
    | CLASS IDENTIFIER Block
    ;

ClassInstantiation:
    Type IDENTIFIER LPAREN ArgList RPAREN
    ;

ParamList:
    /* epsilon */
    | NonEmptyParamList
    ;

NonEmptyParamList:
    Param
    | NonEmptyParamList COMMA Param
    ;

Param:
    IDENTIFIER
    | IDENTIFIER COLON Type
    | IDENTIFIER ASSIGN Expr
    | IDENTIFIER ASSIGN Expr COLON Type
    ;

FuncDef:
    FN IDENTIFIER LPAREN ParamList RPAREN Block
    ;

FnCall:
    IDENTIFIER LPAREN ArgList RPAREN
    ;

MemberFnCall:
    IDENTIFIER DOT IDENTIFIER LPAREN ArgList RPAREN
    ;

ArgList:
    /* epsilon */
    | NonEmptyArgList
    ;

NonEmptyArgList:
    Expr
    | NonEmptyArgList COMMA Expr
    ;

IfStmt:
    IF Expr Block
    | IF Expr Block ELSE Block
    | IF Expr Block ELSE IfStmt
    | IF Expr IN Expr Block
    | IF Expr IN Expr Block ELSE Block
    | IF Expr IN Expr Block ELSE IfStmt
    ;

WhileStmt:
    WHILE Expr Block
    ;

ForStmt:
    FOR IDENTIFIER IN Expr Block
    | FOR IDENTIFIER IN Expr WHERE Expr Block
    ;

Expr:
    TernaryExpr
    ;

TernaryExpr:
    OrExpr
    | OrExpr QUESTION Expr COLON Expr
    ;

OrExpr:
    AndExpr
    | OrExpr OR AndExpr
    ;

AndExpr:
    RelExpr
    | AndExpr AND RelExpr
    ;

RelExpr:
    AddExpr
    | RelExpr EQ AddExpr
    | RelExpr NEQ AddExpr
    | RelExpr LT AddExpr
    | RelExpr GT AddExpr
    | RelExpr LEQ AddExpr
    | RelExpr GEQ AddExpr
    ;

AddExpr:
    MulExpr
    | AddExpr PLUS MulExpr
    | AddExpr MINUS MulExpr
    ;

MulExpr:
    UnaryExpr
    | MulExpr STAR UnaryExpr
    | MulExpr SLASH UnaryExpr
    | MulExpr MOD UnaryExpr
    ;

UnaryExpr:
    Primary
    | NOT UnaryExpr
    | MINUS UnaryExpr %prec UMINUS
    | PLUS UnaryExpr %prec UPLUS
    ;

Primary:
    IDENTIFIER
    | Literal
    | ListLiteral
    | DictLiteral
    | LPAREN Expr RPAREN
    | FnCall
    | MemberFnCall
    | MemberAccess
    | RangeExpr
    | SELF
    ;

MemberAccess:
    IDENTIFIER DOT IDENTIFIER
    ;

RangeExpr:
    INT_LITERAL DOTDOT INT_LITERAL
    | INT_LITERAL DOTDOT INT_LITERAL UNDERSCORE RangeOp INT_LITERAL
    ;

RangeOp:
    PLUS
    | MINUS
    | STAR
    | SLASH
    ;

ListLiteral:
    LBRACK RBRACK
    | LBRACK ExprList RBRACK
    ;

ExprList:
    Expr
    | ExprList COMMA Expr
    ;

DictLiteral:
    LBRACE KeyValList RBRACE
    | LBRACE RBRACE
    ;

KeyValList:
    KeyVal
    | KeyValList COMMA KeyVal
    ;

KeyVal:
    Expr COLON Expr
    ;

Literal:
    INT_LITERAL
    | FLOAT_LITERAL
    | STRING_LITERAL
    | CHAR_LITERAL
    | TRUE
    | FALSE
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax error at line %d: %s\n", line_num, s);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            perror("Error opening file");
            return 1;
        }
        yyin = file;
    }
    
    int result = yyparse();
    
    if (result == 0) {
        printf("\n✓ No syntax errors found!\n");
    } else {
        printf("\n✗ Syntax errors detected!\n");
    }
    
    return result;
}
