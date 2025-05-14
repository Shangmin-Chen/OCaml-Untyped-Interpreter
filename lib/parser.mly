%{
open Utils
%}

%token <int> NUM
%token <string> VAR
%token TRUE FALSE
%token IF THEN ELSE
%token LET IN FUN
%token LPAREN RPAREN
%token ADD SUB MUL DIV MOD
%token LT LTE GT GTE EQ NEQ AND OR
%token ARROW
%token EOF

%right OR
%right AND
%left LT LTE GT GTE EQ NEQ
%left ADD SUB
%left MUL DIV MOD
%nonassoc FUN

%start <Utils.expr> prog

%%

prog:
  | e = expr EOF { e }

expr:
  | IF e1 = expr THEN e2 = expr ELSE e3 = expr { If (e1, e2, e3) }
  | LET v = VAR EQ e1 = expr IN e2 = expr { Let (v, e1, e2) }
  | FUN v = VAR ARROW e = expr { Fun (v, e) }
  | e = expr2 { e }

%inline bop:
  | ADD { Add }
  | SUB { Sub }
  | MUL { Mul }
  | DIV { Div }
  | MOD { Mod }
  | LT { Lt }
  | LTE { Lte }
  | GT { Gt }
  | GTE { Gte }
  | EQ { Eq }
  | NEQ { Neq }
  | AND { And }
  | OR { Or }

expr2:
  | e1 = expr2 op = bop e2 = expr2 { Bop (op, e1, e2) }
  | e = expr_app { e }

expr_app:
  | e1 = expr_app e2 = expr3 { App (e1, e2) }
  | e = expr3 { e }
  
expr3:
  | LPAREN RPAREN { Unit }
  | TRUE { True }
  | FALSE { False }
  | n = NUM { Num n }
  | v = VAR { Var v }
  | LPAREN e = expr RPAREN { e }