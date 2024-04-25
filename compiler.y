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

/* Token with return */
%token <i_var> INT_LIT
%token <f_var> FLOAT_LIT
%token <s_var> STR_LIT
%token <b_var> BOOL_LIT

/* Token with return, which need to sepcify type */
%token <var_type> VARIABLE_T
%token <s_var> IDENT

/* Nonterminal with return, which need to sepcify type */
%type <object_val> Expression
%type <object_val> Primary

%left ADD SUB
%left MUL DIV REM
%nonassoc UMINUS

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
    | VARIABLE_T IdentList ';'
;

IdentList
    : IdentList ',' IDENT
    | IDENT
;

/* Function */
FunctionDefStmt
    : VARIABLE_T IDENT '(' {  createFunction($<var_type>1, $<s_var>2); pushScope(); } FunctionParameterStmtList ')'  '{' StmtList '}' { dumpScope(); }
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

/* assigned variable */
AssignVariableStmt
    : /*IDENT VAL_ASSIGN Expression { printf("AssignVariableStmt\n"); } ';'*/
    /* | IDENT ADD_ASSIGN Expression { printf("AssignVariableStmt\n"); } ';' */
;

CoutParmListStmt
    : CoutParmListStmt SHL Expression { pushFunInParm(&$<object_val>3); }
    | SHL Expression { pushFunInParm(&$<object_val>2); }
;

/* Expression, expression count +1 */
/* 記得處理先乘除後加減，以及括號 */
Expression : Primary
           | '(' ConditionalExpr ')' { /* do nothing */ }
           | ConditionalExpr { /* do nothing */ }
           ;

ConditionalExpr : LogicalOrExpr
                | LogicalOrExpr '?' Expression ':' ConditionalExpr { printf("TERNARY\n"); }
                ;

LogicalOrExpr : LogicalAndExpr
              | LogicalOrExpr LOR LogicalAndExpr { printf("LOR\n"); }
              ;

LogicalAndExpr : InclusiveOrExpr
               | LogicalAndExpr LAN InclusiveOrExpr { printf("LAN\n"); }
               ;

InclusiveOrExpr : ExclusiveOrExpr
                | InclusiveOrExpr BOR ExclusiveOrExpr { printf("BOR\n"); }
                ;

ExclusiveOrExpr : AndExpr
                | ExclusiveOrExpr BXO AndExpr { printf("BXO\n"); }
                ;

AndExpr : EqualityExpr
        | AndExpr BAN EqualityExpr { printf("BAN\n"); }
        ;

EqualityExpr : RelationalExpr
             | EqualityExpr EQL RelationalExpr { printf("EQL\n"); }
             | EqualityExpr NEQ RelationalExpr { printf("NEQ\n"); }
             ;

RelationalExpr : ShiftExpr
               | RelationalExpr LES ShiftExpr { printf("LES\n"); }
               | RelationalExpr LEQ ShiftExpr { printf("LEQ\n"); }
               | RelationalExpr GTR ShiftExpr { printf("GTR\n"); }
               | RelationalExpr GEQ ShiftExpr { printf("GEQ\n"); }
               ;
ShiftExpr : AdditiveExpr
          | ShiftExpr SHL AdditiveExpr { printf("SHL\n"); }
          | ShiftExpr SHR AdditiveExpr { printf("SHR\n"); }
          ;
AdditiveExpr : MultiplicativeExpr
             | AdditiveExpr ADD MultiplicativeExpr { printf("ADD\n"); /*TODO: 填入相加的值像是 $ = $1 + $3;，參考：https://cse.iitkgp.ac.in/~bivasm/notes/LexAndYaccTutorial.pdf*/}
             | AdditiveExpr SUB MultiplicativeExpr { printf("SUB\n"); }
             ;

MultiplicativeExpr : UnaryExpr
                   | MultiplicativeExpr MUL UnaryExpr { printf("MUL\n"); }
                   | MultiplicativeExpr DIV UnaryExpr { printf("DIV\n"); }
                   | MultiplicativeExpr REM UnaryExpr { printf("REM\n"); }
                   ;

UnaryExpr : PostfixExpr
          | NOT UnaryExpr { printf("NOT\n"); }
          | BNT UnaryExpr { printf("BNT\n"); }
          | SUB UnaryExpr { printf("NEG\n"); }
          /* | ADD UnaryExpr { printf("POSITIVE\n"); }
          | BAN UnaryExpr { printf("ADDRESS_OF\n"); }
          | MUL UnaryExpr { printf("DEREFERENCE\n"); }
          | "sizeof" UnaryExpr { printf("SIZEOF\n"); } */
          ;

PostfixExpr : PrimaryExpr
            | PostfixExpr INC_ASSIGN { printf("INC_ASSIGN\n"); }
            | PostfixExpr DEC_ASSIGN { printf("DEC_ASSIGN\n"); }
            ;

PrimaryExpr : Primary { /* do nothing */}
            | '(' Expression ')' { /* do nothing */}
            ;


/* Term       : Factor
           | Term MUL Factor { printf("MUL\n"); }
           | Term DIV Factor { printf("DIV\n"); }
           | Term REM Factor { printf("REM\n"); }
           ;

Factor     : Primary
           | '(' Expression ')'
           | SUB Factor %prec UMINUS { printf("NEG\n"); } 
           | NOT Factor { printf("NOT\n"); }
           ; */


Primary
    : STR_LIT { $$.type = OBJECT_TYPE_STR;  /* $$ 表示這個非終端符號的值 */
                $$.value = (uint64_t) $<s_var>1; 
                printf("STR_LIT \"%s\"\n", (char *) $$.value); }
    | INT_LIT { $$.type = OBJECT_TYPE_INT; 
                $$.value = $<i_var>1; 
                printf("INT_LIT %lu\n", $$.value);
                // convert int $<i_var>1 to string
                // char *str = (char *) malloc(32);
                // sprintf(str, "%d", $<i_var>1);
                // Object* obj = createVariable(OBJECT_TYPE_STR, str, VAR_FLAG_DEFAULT);
                // $$ = *obj;
                }
    | FLOAT_LIT { $$.type = OBJECT_TYPE_FLOAT; 
                    $$.value = (uint64_t) $<f_var>1; 
                    printf("FLOAT_LIT %f\n", $<f_var>1);}
    | BOOL_LIT { $$.type = OBJECT_TYPE_BOOL;
                    $$.value = $<b_var>1; 
                    if ($<b_var>1) {
                        printf("BOOL_LIT TRUE\n");
                    } else {
                        printf("BOOL_LIT FALSE\n");
                    }
                    }
    | IDENT { /* 找出有沒有這個變數，沒有的話就建立一個 */
                Object* obj = findVariable($<s_var>1);
                if (obj == NULL) {
                    obj = createVariable(OBJECT_TYPE_UNDEFINED, $<s_var>1, VAR_FLAG_DEFAULT); 
                }
                if (!strcmp(obj->symbol->name, "endl")) {
                    obj->symbol->addr = -1;
                }
                $$ = *obj;
                printf("IDENT (name=%s, address=%ld)\n", obj->symbol->name, obj->symbol->addr);
                }
    | IDENT '[' Expression ']'
;
%%
/* C code section */