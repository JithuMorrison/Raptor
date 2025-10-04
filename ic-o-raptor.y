%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE *yyin;
extern int line_num;

void yyerror(const char *s);

// Three Address Code Generator
FILE *ic_file;
int temp_count = 0;
int label_count = 0;

char* new_temp() {
    char *temp = (char*)malloc(20);
    sprintf(temp, "t%d", temp_count++);
    return temp;
}

char* new_label() {
    char *label = (char*)malloc(20);
    sprintf(label, "L%d", label_count++);
    return label;
}

void emit(const char *op, const char *arg1, const char *arg2, const char *result) {
    if (arg2 && result) {
        fprintf(ic_file, "%s = %s %s %s\n", result, arg1, op, arg2);
    } else if (arg1 && result) {
        fprintf(ic_file, "%s = %s %s\n", result, op, arg1);
    } else if (arg1) {
        fprintf(ic_file, "%s %s\n", op, arg1);
    } else {
        fprintf(ic_file, "%s\n", op);
    }
}

void emit_label(const char *label) {
    fprintf(ic_file, "%s:\n", label);
}

void emit_assign(const char *lhs, const char *rhs) {
    fprintf(ic_file, "%s = %s\n", lhs, rhs);
}

void emit_goto(const char *label) {
    fprintf(ic_file, "goto %s\n", label);
}

void emit_if(const char *cond, const char *label) {
    fprintf(ic_file, "if %s goto %s\n", cond, label);
}

void emit_iffalse(const char *cond, const char *label) {
    fprintf(ic_file, "ifFalse %s goto %s\n", cond, label);
}

void emit_call(const char *func, int num_params) {
    fprintf(ic_file, "call %s, %d\n", func, num_params);
}

void emit_param(const char *param) {
    fprintf(ic_file, "param %s\n", param);
}

void emit_return(const char *val) {
    if (val) {
        fprintf(ic_file, "return %s\n", val);
    } else {
        fprintf(ic_file, "return\n");
    }
}

%}

%union {
    char *str;
    struct {
        char *addr;
        char *code;
    } expr;
    int num;
}

%token <str> IDENTIFIER INT_LITERAL FLOAT_LITERAL STRING_LITERAL CHAR_LITERAL
%token INT_TYPE FLOAT_TYPE CHAR_TYPE STRING_TYPE BOOL_TYPE LIST_TYPE
%token DICT OBJ CLASS FN IF ELSE FOR WHILE IN WHERE TRUE FALSE SELF RET
%token COLON_EQ EQ NEQ LEQ GEQ AND OR DOTDOT ARROW UNDERSCORE
%token ASSIGN PLUS MINUS STAR SLASH MOD LT GT NOT QUESTION COLON
%token SEMI COMMA DOT LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK

%type <expr> Expr TernaryExpr OrExpr AndExpr RelExpr AddExpr MulExpr UnaryExpr Primary
%type <expr> Literal ListLiteral DictLiteral MemberAccess RangeExpr
%type <str> Type RangeOp
%type <num> ArgList NonEmptyArgList

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
    { 
        ic_file = fopen("ic.txt", "w");
        if (!ic_file) {
            fprintf(stderr, "Error: Cannot create ic.txt\n");
            exit(1);
        }
        fprintf(ic_file, "# Three Address Code\n");
        fprintf(ic_file, "# Generated Intermediate Code\n\n");
    }
    StmtList 
    { 
        printf("Parsing completed successfully!\n");
        printf("Three Address Code generated in ic.txt\n");
        fclose(ic_file);
    }
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
    | ExprStmt
    | ReturnStmt
    ;

ExprStmt:
    IDENTIFIER LPAREN ArgList RPAREN
    {
        fprintf(ic_file, "call %s, %d\n", $1, $3);
    }
    | IDENTIFIER DOT IDENTIFIER LPAREN ArgList RPAREN
    {
        fprintf(ic_file, "call %s.%s, %d\n", $1, $3, $5);
    }
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
    {
        fprintf(ic_file, "declare %s\n", $2);
    }
    | Type IDENTIFIER ASSIGN Expr
    {
        fprintf(ic_file, "declare %s\n", $2);
        emit_assign($2, $4.addr);
    }
    | IDENTIFIER COLON_EQ Expr
    {
        fprintf(ic_file, "declare %s\n", $1);
        emit_assign($1, $3.addr);
    }
    | Type IDENTIFIER LPAREN ArgList RPAREN
    {
        fprintf(ic_file, "%s = new %s(%d)\n", $2, $1, $4);
        free($1);
    }
    ;

Type:
    INT_TYPE    { $$ = strdup("int"); }
    | FLOAT_TYPE  { $$ = strdup("float"); }
    | CHAR_TYPE   { $$ = strdup("char"); }
    | STRING_TYPE { $$ = strdup("string"); }
    | BOOL_TYPE   { $$ = strdup("bool"); }
    | LIST_TYPE   { $$ = strdup("list"); }
    | DICT        { $$ = strdup("dict"); }
    | IDENTIFIER  { $$ = $1; }
    ;

Assignment:
    IDENTIFIER ASSIGN Expr
    {
        emit_assign($1, $3.addr);
    }
    | IDENTIFIER DOT IDENTIFIER ASSIGN Expr
    {
        char *temp = (char*)malloc(100);
        sprintf(temp, "%s.%s", $1, $3);
        emit_assign(temp, $5.addr);
        free(temp);
    }
    ;

ReturnStmt:
    RET Expr
    {
        emit_return($2.addr);
    }
    | RET
    {
        emit_return(NULL);
    }
    ;

ObjDecl:
    OBJ IDENTIFIER ASSIGN LBRACE 
    {
        fprintf(ic_file, "\n# Object %s\n", $2);
        fprintf(ic_file, "begin_object %s\n", $2);
    }
    ObjBody RBRACE
    {
        fprintf(ic_file, "end_object %s\n\n", $2);
    }
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
    {
        fprintf(ic_file, "  member %s\n", $2);
    }
    | Type IDENTIFIER ASSIGN Expr
    {
        fprintf(ic_file, "  member %s\n", $2);
        fprintf(ic_file, "  %s = %s\n", $2, $4.addr);
    }
    | IDENTIFIER COLON_EQ Expr
    {
        fprintf(ic_file, "  member %s\n", $1);
        fprintf(ic_file, "  %s = %s\n", $1, $3.addr);
    }
    | FN IDENTIFIER LPAREN ParamList RPAREN SEMI
    {
        fprintf(ic_file, "  method %s\n", $2);
    }
    | FN IDENTIFIER LPAREN ParamList RPAREN Block
    {
        fprintf(ic_file, "  method %s\n", $2);
    }
    ;

ClassDecl:
    CLASS IDENTIFIER LPAREN ParamList RPAREN 
    {
        fprintf(ic_file, "\n# Class %s\n", $2);
        fprintf(ic_file, "begin_class %s\n", $2);
    }
    Block
    {
        fprintf(ic_file, "end_class %s\n\n", $2);
    }
    | CLASS IDENTIFIER 
    {
        fprintf(ic_file, "\n# Class %s\n", $2);
        fprintf(ic_file, "begin_class %s\n", $2);
    }
    Block
    {
        fprintf(ic_file, "end_class %s\n\n", $2);
    }
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
    {
        fprintf(ic_file, "  param %s\n", $1);
    }
    | IDENTIFIER COLON Type
    {
        fprintf(ic_file, "  param %s : %s\n", $1, $3);
        free($3);
    }
    | IDENTIFIER ASSIGN Expr
    {
        fprintf(ic_file, "  param %s = %s\n", $1, $3.addr);
    }
    | IDENTIFIER ASSIGN Expr COLON Type
    {
        fprintf(ic_file, "  param %s = %s : %s\n", $1, $3.addr, $5);
        free($5);
    }
    ;

FuncDef:
    FN IDENTIFIER 
    {
        fprintf(ic_file, "\n# Function %s\n", $2);
        fprintf(ic_file, "begin_func %s\n", $2);
    }
    LPAREN ParamList RPAREN Block
    {
        fprintf(ic_file, "end_func %s\n\n", $2);
    }
    ;

ArgList:
    /* epsilon */          { $$ = 0; }
    | NonEmptyArgList      { $$ = $1; }
    ;

NonEmptyArgList:
    Expr
    {
        emit_param($1.addr);
        $$ = 1;
    }
    | NonEmptyArgList COMMA Expr
    {
        emit_param($3.addr);
        $$ = $1 + 1;
    }
    ;

IfStmt:
    IF Expr Block
    {
        char *end_label = new_label();
        emit_iffalse($2.addr, end_label);
        emit_label(end_label);
    }
    | IF Expr Block ELSE Block
    {
        char *else_label = new_label();
        char *end_label = new_label();
        emit_iffalse($2.addr, else_label);
        emit_goto(end_label);
        emit_label(else_label);
        emit_label(end_label);
    }
    | IF Expr Block ELSE IfStmt
    {
        char *else_label = new_label();
        char *end_label = new_label();
        emit_iffalse($2.addr, else_label);
        emit_goto(end_label);
        emit_label(else_label);
        emit_label(end_label);
    }
    | IF Expr IN Expr Block
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = %s in %s\n", temp, $2.addr, $4.addr);
        char *end_label = new_label();
        emit_iffalse(temp, end_label);
        emit_label(end_label);
    }
    | IF Expr IN Expr Block ELSE Block
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = %s in %s\n", temp, $2.addr, $4.addr);
        char *else_label = new_label();
        char *end_label = new_label();
        emit_iffalse(temp, else_label);
        emit_goto(end_label);
        emit_label(else_label);
        emit_label(end_label);
    }
    | IF Expr IN Expr Block ELSE IfStmt
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = %s in %s\n", temp, $2.addr, $4.addr);
        char *else_label = new_label();
        char *end_label = new_label();
        emit_iffalse(temp, else_label);
        emit_goto(end_label);
        emit_label(else_label);
        emit_label(end_label);
    }
    ;

WhileStmt:
    WHILE Expr 
    {
        char *start_label = new_label();
        char *end_label = new_label();
        emit_label(start_label);
        emit_iffalse($2.addr, end_label);
        $<str>$ = start_label;
        $<str>1 = end_label;
    }
    Block
    {
        emit_goto($<str>3);
        emit_label($<str>1);
    }
    ;

ForStmt:
    FOR IDENTIFIER IN Expr Block
    {
        fprintf(ic_file, "\n# For loop: %s in collection\n", $2);
        char *iter = new_temp();
        char *start_label = new_label();
        char *end_label = new_label();
        fprintf(ic_file, "%s = iterator(%s)\n", iter, $4.addr);
        emit_label(start_label);
        fprintf(ic_file, "%s = next(%s)\n", $2, iter);
        char *cond = new_temp();
        fprintf(ic_file, "%s = has_next(%s)\n", cond, iter);
        emit_iffalse(cond, end_label);
        emit_goto(start_label);
        emit_label(end_label);
    }
    | FOR IDENTIFIER IN Expr WHERE Expr Block
    {
        fprintf(ic_file, "\n# For loop with where clause\n");
        char *iter = new_temp();
        char *start_label = new_label();
        char *check_label = new_label();
        char *end_label = new_label();
        fprintf(ic_file, "%s = iterator(%s)\n", iter, $4.addr);
        emit_label(start_label);
        fprintf(ic_file, "%s = next(%s)\n", $2, iter);
        char *cond = new_temp();
        fprintf(ic_file, "%s = has_next(%s)\n", cond, iter);
        emit_iffalse(cond, end_label);
        emit_label(check_label);
        emit_iffalse($6.addr, start_label);
        emit_goto(start_label);
        emit_label(end_label);
    }
    ;

Expr:
    TernaryExpr
    {
        $$.addr = $1.addr;
    }
    ;

TernaryExpr:
    OrExpr
    {
        $$.addr = $1.addr;
    }
    | OrExpr QUESTION Expr COLON Expr
    {
        char *temp = new_temp();
        char *true_label = new_label();
        char *false_label = new_label();
        char *end_label = new_label();
        
        emit_if($1.addr, true_label);
        emit_goto(false_label);
        emit_label(true_label);
        emit_assign(temp, $3.addr);
        emit_goto(end_label);
        emit_label(false_label);
        emit_assign(temp, $5.addr);
        emit_label(end_label);
        
        $$.addr = temp;
    }
    ;

OrExpr:
    AndExpr
    {
        $$.addr = $1.addr;
    }
    | OrExpr OR AndExpr
    {
        char *temp = new_temp();
        emit("||", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    ;

AndExpr:
    RelExpr
    {
        $$.addr = $1.addr;
    }
    | AndExpr AND RelExpr
    {
        char *temp = new_temp();
        emit("&&", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    ;

RelExpr:
    AddExpr
    {
        $$.addr = $1.addr;
    }
    | RelExpr EQ AddExpr
    {
        char *temp = new_temp();
        emit("==", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    | RelExpr NEQ AddExpr
    {
        char *temp = new_temp();
        emit("!=", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    | RelExpr LT AddExpr
    {
        char *temp = new_temp();
        emit("<", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    | RelExpr GT AddExpr
    {
        char *temp = new_temp();
        emit(">", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    | RelExpr LEQ AddExpr
    {
        char *temp = new_temp();
        emit("<=", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    | RelExpr GEQ AddExpr
    {
        char *temp = new_temp();
        emit(">=", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    ;

AddExpr:
    MulExpr
    {
        $$.addr = $1.addr;
    }
    | AddExpr PLUS MulExpr
    {
        char *temp = new_temp();
        emit("+", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    | AddExpr MINUS MulExpr
    {
        char *temp = new_temp();
        emit("-", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    ;

MulExpr:
    UnaryExpr
    {
        $$.addr = $1.addr;
    }
    | MulExpr STAR UnaryExpr
    {
        char *temp = new_temp();
        emit("*", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    | MulExpr SLASH UnaryExpr
    {
        char *temp = new_temp();
        emit("/", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    | MulExpr MOD UnaryExpr
    {
        char *temp = new_temp();
        emit("%", $1.addr, $3.addr, temp);
        $$.addr = temp;
    }
    ;

UnaryExpr:
    Primary
    {
        $$.addr = $1.addr;
    }
    | NOT UnaryExpr
    {
        char *temp = new_temp();
        emit("!", $2.addr, NULL, temp);
        $$.addr = temp;
    }
    | MINUS UnaryExpr %prec UMINUS
    {
        char *temp = new_temp();
        emit("-", $2.addr, NULL, temp);
        $$.addr = temp;
    }
    | PLUS UnaryExpr %prec UPLUS
    {
        $$.addr = $2.addr;
    }
    ;

Primary:
    IDENTIFIER
    {
        $$.addr = strdup($1);
    }
    | Literal
    {
        $$.addr = $1.addr;
    }
    | ListLiteral
    {
        $$.addr = $1.addr;
    }
    | DictLiteral
    {
        $$.addr = $1.addr;
    }
    | LPAREN Expr RPAREN
    {
        $$.addr = $2.addr;
    }
    | IDENTIFIER LPAREN ArgList RPAREN
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = return_value\n", temp);
        $$.addr = temp;
    }
    | IDENTIFIER DOT IDENTIFIER LPAREN ArgList RPAREN
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = return_value\n", temp);
        $$.addr = temp;
    }
    | MemberAccess
    {
        $$.addr = $1.addr;
    }
    | RangeExpr
    {
        $$.addr = $1.addr;
    }
    | SELF
    {
        $$.addr = strdup("self");
    }
    ;

MemberAccess:
    IDENTIFIER DOT IDENTIFIER
    {
        char *temp = (char*)malloc(100);
        sprintf(temp, "%s.%s", $1, $3);
        $$.addr = temp;
    }
    ;

RangeExpr:
    INT_LITERAL DOTDOT INT_LITERAL
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = range(%s, %s, 1)\n", temp, $1, $3);
        $$.addr = temp;
    }
    | INT_LITERAL DOTDOT INT_LITERAL UNDERSCORE RangeOp INT_LITERAL
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = range(%s, %s, %s%s)\n", temp, $1, $3, $5, $6);
        $$.addr = temp;
    }
    ;

RangeOp:
    PLUS    { $$ = strdup("+"); }
    | MINUS { $$ = strdup("-"); }
    | STAR  { $$ = strdup("*"); }
    | SLASH { $$ = strdup("/"); }
    ;

ListLiteral:
    LBRACK RBRACK
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = []\n", temp);
        $$.addr = temp;
    }
    | LBRACK ExprList RBRACK
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = list_literal\n", temp);
        $$.addr = temp;
    }
    ;

ExprList:
    Expr
    {
        fprintf(ic_file, "list_elem %s\n", $1.addr);
    }
    | ExprList COMMA Expr
    {
        fprintf(ic_file, "list_elem %s\n", $3.addr);
    }
    ;

DictLiteral:
    LBRACE KeyValList RBRACE
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = dict_literal\n", temp);
        $$.addr = temp;
    }
    | LBRACE RBRACE
    {
        char *temp = new_temp();
        fprintf(ic_file, "%s = {}\n", temp);
        $$.addr = temp;
    }
    ;

KeyValList:
    KeyVal
    | KeyValList COMMA KeyVal
    ;

KeyVal:
    Expr COLON Expr
    {
        fprintf(ic_file, "dict_entry %s : %s\n", $1.addr, $3.addr);
    }
    ;

Literal:
    INT_LITERAL
    {
        $$.addr = strdup($1);
    }
    | FLOAT_LITERAL
    {
        $$.addr = strdup($1);
    }
    | STRING_LITERAL
    {
        $$.addr = strdup($1);
    }
    | CHAR_LITERAL
    {
        $$.addr = strdup($1);
    }
    | TRUE
    {
        $$.addr = strdup("true");
    }
    | FALSE
    {
        $$.addr = strdup("false");
    }
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
