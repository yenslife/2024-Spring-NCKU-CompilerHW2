/* Definition section */
%{
    #include "compiler_common.h"
    #include "compiler_util.h"
    #include "main.h"

    int yydebug = 1;
%}

/* Variable or self-defined structure */
%union {
    ObjectType var_type;

    bool b_var;
    int i_var;
    float f_var;
    char *s_var;

    Object object_val;
}

/* Token without return */
%token COUT
%token SHR SHL BAN BOR BNT BXO ADD SUB MUL DIV REM NOT GTR LES GEQ LEQ EQL NEQ LAN LOR
%token VAL_ASSIGN ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN REM_ASSIGN BAN_ASSIGN BOR_ASSIGN BXO_ASSIGN SHR_ASSIGN SHL_ASSIGN INC_ASSIGN DEC_ASSIGN
%token IF ELSE FOR WHILE RETURN BREAK CONTINUE

/* Token with return, which need to sepcify type */
%token <var_type> VARIABLE_T
%token <s_var> IDENT

/* Nonterminal with return, which need to sepcify type */
%type <object_val> Expression

/* Token with return */
%token <i_var> INT_LIT
%token <f_var> FLOAT_LIT
%token <s_var> STR_LIT
%token <b_var> BOOL_LIT

%left ADD SUB
%left MUL DIV REM

/* Yacc will start at this nonterminal */
%start Program

%%
/* Grammar section */

Program
    : { pushScope(); } GlobalStmtList { dumpScope(); }
    | /* Empty file */
;

GlobalStmtList 
    : GlobalStmtList GlobalStmt
    | GlobalStmt
;

GlobalStmt
    : DefineVariableStmt
    | FunctionDefStmt
;

DefineVariableStmt
    : VARIABLE_T IDENT VAL_ASSIGN Expression ';'
;

/* Function */
FunctionDefStmt
    : VARIABLE_T IDENT '(' FunctionParameterStmtList ')' { createFunction($<var_type>1, $<s_var>2); } '{' '}' { dumpScope(); }
;
FunctionParameterStmtList 
    : FunctionParameterStmtList ',' FunctionParameterStmt
    | FunctionParameterStmt
    | /* Empty function parameter */
;
FunctionParameterStmt
    : VARIABLE_T IDENT { pushFunParm($<var_type>1, $<s_var>2, VAR_FLAG_DEFAULT); }
    | VARIABLE_T IDENT '[' ']' { pushFunParm($<var_type>1, $<s_var>2, VAR_FLAG_ARRAY); }
;

/* Scope */
StmtList 
    : StmtList Stmt
    | Stmt
;
Stmt
    : ';'
    | COUT CoutParmListStmt ';' { stdoutPrint(); }
    | RETURN Expression ';' { printf("RETURN\n"); }
;

CoutParmListStmt
    : CoutParmListStmt SHL Expression { pushFunInParm(&$<object_val>3); }
    | SHL Expression { pushFunInParm(&$<object_val>2); }
;

Expression
    : Expression ADD Expression { $$.type = add($<object_val>1, $<object_val>3); }
;

%%
/* C code section */