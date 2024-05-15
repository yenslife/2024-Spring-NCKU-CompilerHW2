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
    struct IdentListNode* ident_list;
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
%type <object_val> ConditionalExpr
%type <object_val> LogicalOrExpr
%type <object_val> LogicalAndExpr
%type <object_val> InclusiveOrExpr
%type <object_val> ExclusiveOrExpr
%type <object_val> AndExpr
%type <object_val> EqualityExpr
%type <object_val> RelationalExpr
%type <object_val> ShiftExpr
%type <object_val> AdditiveExpr
%type <object_val> MultiplicativeExpr
%type <object_val> UnaryExpr
%type <object_val> PostfixExpr
%type <object_val> PrimaryExpr
%type <ident_list> IdentList

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
    : VARIABLE_T IDENT VAL_ASSIGN Expression ';' { pushVariable($<var_type>1, $<s_var>2, VAR_FLAG_DEFAULT); }
    | VARIABLE_T IdentList ';' { pushVariableList($1, $2, VAR_FLAG_DEFAULT); }
;

IdentList
    : IDENT { $$ = createIdentList($1); }
    | IdentList ',' IDENT { $$ = appendIdentList($1, $3); }

/* Function */
FunctionDefStmt
    : 
     /* VARIABLE_T IDENT '(' FunctionParameterStmtList ')' { createFunction($<var_type>1, $<s_var>2); } '{' '}' { dumpScope(); } */
    | VARIABLE_T IDENT '(' { createFunction($<var_type>1, $<s_var>2); } FunctionParameterStmtList ')' '{' StmtList '}' { dumpScope(); }
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
    | DefineVariableStmt
    | AssignVariableStmt
;

AssignVariableStmt
    : IDENT {processIdentifier($<s_var>1);} VAL_ASSIGN Expression ';' { if (!objectExpAssign('=', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }
    | IDENT {processIdentifier($<s_var>1);} ADD_ASSIGN Expression ';' { if (!objectExpAssign('+', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }
    | IDENT {processIdentifier($<s_var>1);} SUB_ASSIGN Expression ';' { if (!objectExpAssign('-', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }
    | IDENT {processIdentifier($<s_var>1);} MUL_ASSIGN Expression ';' { if (!objectExpAssign('*', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }
    | IDENT {processIdentifier($<s_var>1);} DIV_ASSIGN Expression ';' { if (!objectExpAssign('/', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }
    | IDENT {processIdentifier($<s_var>1);} REM_ASSIGN Expression ';' { if (!objectExpAssign('%', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }
    | IDENT {processIdentifier($<s_var>1);} BAN_ASSIGN Expression ';' { if (!objectExpAssign('&', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }
    | IDENT {processIdentifier($<s_var>1);} BOR_ASSIGN Expression ';' { if (!objectExpAssign('|', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }
    | IDENT {processIdentifier($<s_var>1);} BXO_ASSIGN Expression ';' { if (!objectExpAssign('^', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }
    | IDENT {processIdentifier($<s_var>1);} SHR_ASSIGN Expression ';' { if (!objectExpAssign('>', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }
    | IDENT {processIdentifier($<s_var>1);} SHL_ASSIGN Expression ';' { if (!objectExpAssign('<', &$<object_val>1, &$<object_val>3, &$<object_val>1)) YYABORT; }

;

CoutParmListStmt
    : CoutParmListStmt SHL Expression { pushFunInParm(&$<object_val>3); }
    | SHL Expression { pushFunInParm(&$<object_val>2); }
;

Expression : '(' Expression ')' { $$ = $2; }
           | ConditionalExpr { $$ = $1;}
           ;

ConditionalExpr : LogicalOrExpr { $$ = $1;}
                | LogicalOrExpr '?' Expression ':' ConditionalExpr { $$ = $3; }
                ;

LogicalOrExpr : LogicalAndExpr
              | LogicalOrExpr LOR LogicalAndExpr { if (!objectExpBoolean('|', &$<object_val>1, &$<object_val>3, &$$)) YYABORT; }
              ;

LogicalAndExpr : InclusiveOrExpr
               | LogicalAndExpr LAN InclusiveOrExpr { if (!objectExpBoolean('&', &$<object_val>1, &$<object_val>3, &$$)) YYABORT; }
               ;

InclusiveOrExpr : ExclusiveOrExpr
                | InclusiveOrExpr BOR ExclusiveOrExpr { if (!objectExpBinary('|', &$<object_val>1, &$<object_val>3, &$$)) YYABORT; }
                ;

ExclusiveOrExpr : AndExpr
                | ExclusiveOrExpr BXO AndExpr { !objectExpBinary('^', &$<object_val>1, &$<object_val>3, &$$); }
                ;

AndExpr : EqualityExpr
        | AndExpr BAN EqualityExpr { if (!objectExpBinary('&', &$<object_val>1, &$<object_val>3, &$$)) YYABORT; }
        ;

EqualityExpr : RelationalExpr { $$ = $1;}
             | EqualityExpr EQL RelationalExpr { if (!objectExpBoolean('=', &$<object_val>1, &$<object_val>3, &$$)) YYABORT; }
             | EqualityExpr NEQ RelationalExpr { if (!objectExpBoolean('!', &$<object_val>1, &$<object_val>3, &$$)) YYABORT; }
             ;

RelationalExpr : AdditiveExpr { $$ = $1;}
               | RelationalExpr LES AdditiveExpr { if (!objectExpBoolean('<', &$<object_val>1, &$<object_val>3, &$$)) YYABORT; }
               | RelationalExpr LEQ AdditiveExpr { printf("LEQ\n"); $$ = $1;}
               | RelationalExpr GTR AdditiveExpr { if (!objectExpBoolean('>', &$<object_val>1, &$<object_val>3, &$$)) YYABORT; }
               | RelationalExpr GEQ AdditiveExpr { printf("GEQ\n"); $$ = $1;}
               ;

ShiftExpr : AdditiveExpr { $$ = $1;}
          | ShiftExpr SHL AdditiveExpr { printf("SHL\n"); $$ = $1;}
          | ShiftExpr SHR AdditiveExpr { printf("SHR\n"); $$ = $1;}
          ; 

AdditiveExpr : MultiplicativeExpr { $$ = $1;}
             | AdditiveExpr ADD MultiplicativeExpr { if (!objectExpression('+', &$<object_val>1, &$<object_val>3, &$$)) YYABORT;}
             | AdditiveExpr SUB MultiplicativeExpr { if (!objectExpression('-', &$<object_val>1, &$<object_val>3, &$$)) YYABORT;}
             ;

MultiplicativeExpr : UnaryExpr { $$ = $1;}
                   | MultiplicativeExpr MUL UnaryExpr { if (!objectExpression('*', &$<object_val>1, &$<object_val>3, &$$)) YYABORT;}
                   | MultiplicativeExpr DIV UnaryExpr { if (!objectExpression('/', &$<object_val>1, &$<object_val>3, &$$)) YYABORT;}
                   | MultiplicativeExpr REM UnaryExpr { if (!objectExpression('%', &$<object_val>1, &$<object_val>3, &$$)) YYABORT;}
                   ;

UnaryExpr : PostfixExpr
          | NOT UnaryExpr { if (!objectNotExpression(&$<object_val>2, &$$)) YYABORT;}
          | BNT UnaryExpr { if (!objectNotBinaryExpression(&$<object_val>2, &$$)) YYABORT;}
          | SUB UnaryExpr { if (!objectNegExpression(&$<object_val>2, &$$)) YYABORT;}
          ;
    


PostfixExpr : PrimaryExpr { $$ = $1; }
            | '(' Expression ')' { $$ = $2; }
            | PostfixExpr INC_ASSIGN { printf("INC_ASSIGN\n"); $$ = $1; }
            | PostfixExpr DEC_ASSIGN { printf("DEC_ASSIGN\n"); $$ = $1; }
            ;

PrimaryExpr
    : STR_LIT { 
        Object* obj = malloc(sizeof(Object));
        obj->value = (uint64_t) $<s_var>1;
        obj->type = OBJECT_TYPE_STR;
        obj->symbol = NULL;
        $$ = *obj;
        printf("STR_LIT \"%s\"\n", (char *) $$.value); 
    }
    | INT_LIT { 
        Object* obj = malloc(sizeof(Object));
        obj->value = $<i_var>1;
        obj->type = OBJECT_TYPE_INT;
        obj->symbol = NULL;
        $$ = *obj;
        printf("INT_LIT %d\n", (int) $$.value); 
    }
    | FLOAT_LIT { 
        Object* obj = malloc(sizeof(Object));
        obj->value = $<f_var>1; // 會有問題，因為 value 是 uint64_t
        obj->type = OBJECT_TYPE_FLOAT;
        obj->symbol = NULL;
        $$ = *obj;
        printf("FLOAT_LIT %f\n", $<f_var>1); 
    }
    | BOOL_LIT {
        Object* obj = malloc(sizeof(Object));
        obj->value = $<b_var>1;
        obj->type = OBJECT_TYPE_BOOL;
        obj->symbol = NULL;
        $$ = *obj;
        printf("BOOL_LIT %s\n", (bool) $$.value ? "TRUE" : "FALSE");
    }
    | IDENT { $$ = processIdentifier($<s_var>1);}
;
%%
/* C code section */