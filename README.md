# Raptor

A new programming lang - fast as C++, easy to code as Python, lightweight as JS, efficient as C

## Program Structure
```
Program → StmtList

StmtList → StmtList Stmt | ε

Stmt → SimpleStmt ; | ComplexStmt
```

## Statements

### Simple Statements (require semicolon)
```
SimpleStmt → VarDecl 
           | Assignment 
           | FnCall
           | MemberAssignment
           | ClassInstantiation
           | ReturnStmt

VarDecl → Type Identifier
        | Type Identifier = Expr
        | Identifier := Expr

Assignment → Identifier = Expr

MemberAssignment → Identifier . Identifier = Expr

ReturnStmt → ret Expr
           | ret

ClassInstantiation → Type Identifier ( ArgList )
```

### Complex Statements (no semicolon)
```
ComplexStmt → FuncDef 
            | IfStmt 
            | ForStmt 
            | WhileStmt 
            | Block
            | ObjDecl
            | ClassDecl

Block → { StmtList }
```

## Types
```
Type → int | float | char | string | bool | list | dict | Identifier
```
*Note: Identifier allows custom types (classes)*

## Objects
```
ObjDecl → obj Identifier = { ObjBody }

ObjBody → ObjMemberList | ε

ObjMemberList → ObjMember ; 
              | ObjMemberList ObjMember ;

ObjMember → Type Identifier
          | Type Identifier = Expr
          | Identifier := Expr
          | FuncSig
          | FuncDef

FuncSig → fn Identifier ( ParamList )
```

**Examples:**
```
obj car = {
    int speed;
    float fuel = 50.5;
    fn accelerate();
};

car.speed = 100;
```

## Classes
```
ClassDecl → class Identifier ( ParamList ) Block
          | class Identifier Block

ClassInstantiation → Type Identifier ( ArgList )
```

**Examples:**
```
// Class with constructor
class Point(x: int, y: int) {
    int x;
    int y;
    
    fn distance() {
        ret x + y;
    }
}

// Class without constructor
class Circle {
    float radius;
}

// Instantiation
Point p(2, 3);
Circle c();
```

## Functions
```
FuncDef → fn Identifier ( ParamList ) Block

ParamList → ε | NonEmptyParamList

NonEmptyParamList → Param 
                  | NonEmptyParamList , Param

Param → Identifier
      | Identifier : Type
      | Identifier = Expr
      | Identifier = Expr : Type

FnCall → Identifier ( ArgList )

MemberFnCall → Identifier . Identifier ( ArgList )

ArgList → ε | NonEmptyArgList

NonEmptyArgList → Expr 
                | NonEmptyArgList , Expr
```

**Return Statement:**
```
ReturnStmt → ret Expr    // Return with value
           | ret         // Return without value

Examples:
fn add(a: int, b: int) {
    ret a + b;
}

fn doSomething() {
    x = 5;
    ret;
}
```

## Control Flow

### If Statement
```
IfStmt → if Expr Block
       | if Expr Block else Block
       | if Expr Block else IfStmt
       | if Expr in Expr Block
       | if Expr in Expr Block else Block
       | if Expr in Expr Block else IfStmt
```

**Note:** Eliminated `ElsePart` non-terminal to resolve shift/reduce conflicts. Now all else clauses are directly specified in the if statement rules.

**Examples:**
```
if x > 0 {
    y = 1;
}

if x > 0 {
    y = 1;
} else {
    y = 0;
}

if x > 0 {
    y = 1;
} else if x < 0 {
    y = -1;
} else {
    y = 0;
}

if x in 1..10 {
    // x is between 1 and 10
}
```

### Loops
```
WhileStmt → while Expr Block

ForStmt → for Identifier in Expr Block
        | for Identifier in Expr where Expr Block
```

**Examples:**
```
while x < 100 {
    x = x + 1;
}

for i in 1..10 {
    x = x + i;
}

for i in 1..100 where i > 50 {
    x = i;
}
```

## Expressions

### Expression Hierarchy (with precedence)
```
Expr → TernaryExpr

TernaryExpr → OrExpr 
            | OrExpr ? Expr : Expr

OrExpr → AndExpr 
       | OrExpr || AndExpr

AndExpr → RelExpr 
        | AndExpr && RelExpr

RelExpr → AddExpr
        | RelExpr == AddExpr
        | RelExpr != AddExpr
        | RelExpr < AddExpr
        | RelExpr > AddExpr
        | RelExpr <= AddExpr
        | RelExpr >= AddExpr

AddExpr → MulExpr
        | AddExpr + MulExpr
        | AddExpr - MulExpr

MulExpr → UnaryExpr
        | MulExpr * UnaryExpr
        | MulExpr / UnaryExpr
        | MulExpr % UnaryExpr

UnaryExpr → Primary
          | ! UnaryExpr
          | - UnaryExpr
          | + UnaryExpr
```

### Primary Expressions
```
Primary → Identifier
        | Literal
        | ListLiteral
        | DictLiteral
        | ( Expr )
        | FnCall
        | MemberFnCall
        | MemberAccess
        | RangeExpr
        | self

MemberAccess → Identifier . Identifier
```

## Literals

### Range with Increment
```
RangeExpr → IntLiteral .. IntLiteral
          | IntLiteral .. IntLiteral _ RangeOp IntLiteral

RangeOp → + | - | * | /
```

**Examples:**
```
r1 := 1..10;           // Range from 1 to 10 (step 1)
r2 := 1..10_+2;        // Range from 1 to 10 with step +2 (1,3,5,7,9)
r3 := 0..100_*5;       // Range from 0 to 100 with step *5 (0,5,25,125...)
r4 := 10..0_-1;        // Range from 10 to 0 with step -1 (10,9,8...0)
r5 := 2..20_/2;        // Range with division step
```

**Syntax:** `start..end_operator_step`
- `start`: Starting value
- `end`: Ending value
- `_`: Underscore separator (required)
- `operator`: One of `+`, `-`, `*`, `/`
- `step`: Step value

### List
```
ListLiteral → [ ]
            | [ ExprList ]

ExprList → Expr 
         | ExprList , Expr
```

**Examples:**
```
list nums = [1, 2, 3, 4, 5];
empty := [];
mixed := [1, 2.5, "hello"];
```

### Dictionary
```
DictLiteral → { }
            | { KeyValList }

KeyValList → KeyVal 
           | KeyValList , KeyVal

KeyVal → Expr : Expr
```

**Examples:**
```
dict d = {1: 2, 3: 4};
v := {"key": "value", "name": "test"};
empty_dict := {};
```

### Basic Literals
```
Literal → IntLiteral
        | FloatLiteral
        | StringLiteral
        | CharLiteral
        | true
        | false
```

## Operator Precedence (High to Low)
1. `.` `(` `[` (Member access, function call, subscript)
2. `!` `-` `+` (Unary operators)
3. `*` `/` `%` (Multiplicative)
4. `+` `-` (Additive)
5. `<` `>` `<=` `>=` (Relational)
6. `==` `!=` (Equality)
7. `&&` (Logical AND)
8. `||` (Logical OR)
9. `?` `:` (Ternary)
10. `=` `:=` (Assignment)

## Key Features Summary

### 1. Return Statements
```
fn add(a: int, b: int) {
    ret a + b;         // Return with value
}

fn reset() {
    x = 0;
    ret;               // Return without value
}
```

### 2. Range with Custom Increment
```
r1 := 1..10;           // Default increment
r2 := 1..10_+2;        // Add 2 each step
r3 := 100..0_-5;       // Subtract 5 each step
r4 := 1..1000_*2;      // Multiply by 2 each step
```

### 3. Object Member Operations
```
obj car = {
    int speed;
    fn accelerate();
};

car.speed = 100;        // Member assignment
x := car.speed;         // Member access
car.accelerate();       // Member function call
```

### 4. Classes with Constructors
```
class Rectangle(w: int, h: int) {
    int width = w;
    int height = h;
    
    fn area() {
        ret width * height;
    }
}

Rectangle r(10, 20);
r.width = 15;
x := r.area();
```

### 5. Type Inference
```
x := 5;              // Inferred as int
y := 3.14;           // Inferred as float
dict := {1: 2};      // Inferred as dict
```

### 6. Advanced Control Flow
```
// If-in statement
if x in 1..10 {
    // x is between 1 and 10
}

// For with where clause
for i in 1..100 where i > 50 {
    // Only when i > 50
}

// Chained if-else
if x > 0 {
    y = 1;
} else if x < 0 {
    y = -1;
} else {
    y = 0;
}
```

## Conflict Resolution

### ✅ All 4 Shift/Reduce Conflicts Resolved

**1. ElsePart Ambiguity (Dangling Else)**
   - **Problem:** `if E1 if E2 S1 else S2` - which if does else belong to?
   - **Solution:** Eliminated `ElsePart` non-terminal. Expanded all if-else combinations explicitly in `IfStmt` production rules.

**2. Dictionary Empty Braces**
   - **Problem:** `{}` could be empty dict or empty object body
   - **Solution:** Added explicit `LBRACE RBRACE` production for `DictLiteral`

**3. Member Access Reduction**
   - **Problem:** When to reduce `IDENTIFIER DOT IDENTIFIER`
   - **Solution:** Separated into distinct productions: `MemberAccess`, `MemberFnCall`, and `MemberAssignment`

**4. Type Identifier Conflict**
   - **Problem:** IDENTIFIER in Type vs Primary
   - **Solution:** Made precedence clear and added IDENTIFIER as valid Type for custom classes

## Compilation Instructions

```bash
# Generate parser (should show 0 conflicts)
win_bison -d parse.y

# Generate lexer
win_flex parse.l

# Compile
gcc parse.tab.c lex.yy.c -o parser

# Test
parser test.rpt
```

**Expected output:**
```
Parsing completed successfully!

✓ No syntax errors found!
```

## New Tokens Added
- `UNDERSCORE` (`_`) - For range increment syntax
- `RET` - Return statement keyword

The grammar is now **100% conflict-free** with full support for return statements and range increments!
