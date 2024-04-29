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
%type <object_val> LogicalOrExpr
%type <object_val> LogicalAndExpr
%type <object_val> InclusiveOrExpr
%type <object_val> ExclusiveOrExpr
%type <object_val> AndExpr
%type <object_val> EqualityExpr
%type <object_val> RelationalExpr
%type <object_val> ShiftExpr
%type <object_val> AdditiveExpr
%type <object_val> UnaryExpr
%type <object_val> MultiplicativeExpr
%type <object_val> PostfixExpr
%type <object_val> PrimaryExpr


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
    | COUT {init_cout_list();} CoutParmListStmt ';' { stdoutPrint(); }
    | RETURN Expression ';' { printf("RETURN\n"); }
    | DefineVariableStmt
;

CoutParmListStmt
    : CoutParmListStmt SHL Expression { pushFunInParm(&$<object_val>3); }
    | SHL Expression { pushFunInParm(&$<object_val>2); }
;

/* Expression, expression count +1 */
/* 記得處理先乘除後加減，以及括號 */
Expression : '(' ConditionalExpr ')' { $$ = $<object_val>2; }
           | ConditionalExpr { $$ = $<object_val>1;}
           ;

ConditionalExpr : LogicalOrExpr
                | LogicalOrExpr '?' Expression ':' ConditionalExpr { printf("TERNARY\n"); }
                ;

LogicalOrExpr : LogicalAndExpr
              | LogicalOrExpr LOR LogicalAndExpr { printf("LOR\n"); $<object_val>1.value = $<object_val>1.value || $<object_val>3.value; $$ = $<object_val>1;}
              ;

LogicalAndExpr : InclusiveOrExpr
               | LogicalAndExpr LAN InclusiveOrExpr { printf("LAN\n"); $<object_val>1.value = $<object_val>1.value && $<object_val>3.value; $$ = $<object_val>1;}
               ;

InclusiveOrExpr : ExclusiveOrExpr
                | InclusiveOrExpr BOR ExclusiveOrExpr { printf("BOR\n"); $<object_val>1.value = $<object_val>1.value | $<object_val>3.value; $$ = $<object_val>1;}
                ;

ExclusiveOrExpr : AndExpr
                | ExclusiveOrExpr BXO AndExpr { printf("BXO\n"); $<object_val>1.value = $<object_val>1.value ^ $<object_val>3.value; $$ = $<object_val>1;}
                ;

AndExpr : EqualityExpr
        | AndExpr BAN EqualityExpr { printf("BAN\n"); $<object_val>1.value = $<object_val>1.value & $<object_val>3.value; $$ = $<object_val>1;}
        ;

EqualityExpr : RelationalExpr
             | EqualityExpr EQL RelationalExpr { printf("EQL\n"); $<object_val>1.value = $<object_val>1.value == $<object_val>3.value; $$ = $<object_val>1;}
             | EqualityExpr NEQ RelationalExpr { printf("NEQ\n"); $<object_val>1.value = $<object_val>1.value != $<object_val>3.value; $$ = $<object_val>1;}
             ;

RelationalExpr : ShiftExpr
               | RelationalExpr LES ShiftExpr { printf("LES\n"); $<object_val>1.value = $<object_val>1.value < $<object_val>3.value; $$ = $<object_val>1;}
               | RelationalExpr LEQ ShiftExpr { printf("LEQ\n"); $<object_val>1.value = $<object_val>1.value <= $<object_val>3.value; $$ = $<object_val>1;}
               | RelationalExpr GTR ShiftExpr { printf("GTR\n"); $<object_val>1.value = $<object_val>1.value > $<object_val>3.value; $$ = $<object_val>1;}
               | RelationalExpr GEQ ShiftExpr { printf("GEQ\n"); $<object_val>1.value = $<object_val>1.value >= $<object_val>3.value; $$ = $<object_val>1;}
               ;

ShiftExpr : AdditiveExpr
          | ShiftExpr SHL AdditiveExpr { printf("SHL\n"); $<object_val>1.value = $<object_val>1.value << $<object_val>3.value; $$ = $<object_val>1;}
          | ShiftExpr SHR AdditiveExpr { printf("SHR\n"); $<object_val>1.value = $<object_val>1.value >> $<object_val>3.value; $$ = $<object_val>1;}
          ;

AdditiveExpr : UnaryExpr
             | AdditiveExpr ADD UnaryExpr { printf("ADD\n"); $<object_val>1.value = $<object_val>1.value + $<object_val>3.value; $$ = $<object_val>1;}
             | AdditiveExpr SUB UnaryExpr { printf("SUB\n"); $<object_val>1.value = $<object_val>1.value - $<object_val>3.value; $$ = $<object_val>1;}
             ;

UnaryExpr : MultiplicativeExpr
          | NOT UnaryExpr { printf("NOT\n"); $<object_val>2.value = !$<object_val>2.value; $$ = $<object_val>2;}
          | BNT UnaryExpr { printf("BNT\n"); $<object_val>2.value = ~$<object_val>2.value; $$ = $<object_val>2;}
          | SUB UnaryExpr { printf("NEG\n"); $<object_val>2.value = -$<object_val>2.value; $$ = $<object_val>2;}
          ;
    
MultiplicativeExpr : PostfixExpr
                   | MultiplicativeExpr MUL UnaryExpr { printf("MUL\n"); $<object_val>1.value = $<object_val>1.value * $<object_val>3.value; $$ = $<object_val>1;}
                   | MultiplicativeExpr DIV UnaryExpr { printf("DIV\n"); $<object_val>1.value = $<object_val>1.value / $<object_val>3.value; $$ = $<object_val>1;}
                   | MultiplicativeExpr REM UnaryExpr { printf("REM\n"); $<object_val>1.value = $<object_val>1.value % $<object_val>3.value; $$ = $<object_val>1;}
                   ;

PostfixExpr : PrimaryExpr
            | PostfixExpr INC_ASSIGN { printf("INC_ASSIGN\n"); $<object_val>1.value = $<object_val>1.value + 1; $$ = $<object_val>1;}
            | PostfixExpr DEC_ASSIGN { printf("DEC_ASSIGN\n"); $<object_val>1.value = $<object_val>1.value - 1; $$ = $<object_val>1;}
            ;

PrimaryExpr : '(' Expression ')' { $$ = $<object_val>2;}
            | Primary { $$ = $<object_val>1;} 
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
    : STR_LIT { 
                // $$.type = OBJECT_TYPE_STR;  /* $$ 表示這個非終端符號的值 */
                // $$.value = (uint64_t) $<s_var>1; 
                /* create variable */
                Object* obj = createVariable(OBJECT_TYPE_STR, $<s_var>1, VAR_FLAG_DEFAULT);
                // printf("value=%s\n", (char *) $$.value);
                /* copy obj to $$ */
                obj->value = (uint64_t) $<s_var>1;
                obj->type = OBJECT_TYPE_STR;
                free(obj->symbol);
                obj->symbol = NULL;
                $$ = *obj;
                $<object_val>1 = *obj;
                printf("STR_LIT \"%s\"\n", (char *) $$.value); }
    | INT_LIT { 
                // $$.type = OBJECT_TYPE_INT; 
                // $$.value = $<i_var>1; 
                Object* obj = createVariable(OBJECT_TYPE_INT, "NULL", VAR_FLAG_DEFAULT);
                obj->value = $<i_var>1;
                obj->type = OBJECT_TYPE_INT;
                // free(obj->symbol->name);
                // free(obj->symbol->func_sig);
                free(obj->symbol);
                obj->symbol = NULL;
                $$ = *obj;
                // $<object_val>1 = *obj;
                // printf("value=%lu\n", $<i_var>1);
                // printf("INT_LIT type:%d, value:%ld\n", obj->type, obj->value);
                printf("INT_LIT %lu\n", $$.value);
                // convert int $<i_var>1 to string
                // char *str = (char *) malloc(32);
                // sprintf(str, "%d", $<i_var>1);
                // Object* obj = createVariable(OBJECT_TYPE_STR, str, VAR_FLAG_DEFAULT);
                // $$ = *obj;
                }
    | FLOAT_LIT { 
                    // $$.type = OBJECT_TYPE_FLOAT; 
                    // $$.value = (uint64_t) $<f_var>1; 
                    Object* obj = createVariable(OBJECT_TYPE_FLOAT, "NULL", VAR_FLAG_DEFAULT);
                    obj->value = (uint64_t) $<f_var>1;
                    obj->type = OBJECT_TYPE_FLOAT;
                    free(obj->symbol);
                    obj->symbol = NULL;
                    $$ = *obj;
                    // printf("value=%f\n",(float) $$.value);
                    printf("FLOAT_LIT %f\n", $<f_var>1);}
    | BOOL_LIT { 
                    // $$.type = OBJECT_TYPE_BOOL;
                    // $$.value = $<b_var>1; 
                    Object* obj = createVariable(OBJECT_TYPE_BOOL, "NULL", VAR_FLAG_DEFAULT);
                    // printf("value=%d\n", $<b_var>1);
                    obj->value = $<b_var>1;
                    obj->type = OBJECT_TYPE_BOOL;
                    obj->symbol = NULL;
                    free(obj->symbol);
                    obj->symbol = NULL;
                    $$ = *obj;
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
                $$.type = obj->type;
                $$.value = obj->value;
                // printf("IDENT type=%d, value=%ld\n", obj->type, obj->value);
                printf("IDENT (name=%s, address=%ld)\n", obj->symbol->name, obj->symbol->addr);
                }
    /* | IDENT '[' Expression ']' */
;
%%
/* C code section */