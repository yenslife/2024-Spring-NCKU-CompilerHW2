#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "main.h"

#define debug printf("%s:%d: ############### debug\n", __FILE__, __LINE__)

#define toupper(_char) (_char - (char)32)

const char* objectTypeName[] = {
    [OBJECT_TYPE_UNDEFINED] = "undefined",
    [OBJECT_TYPE_VOID] = "void",
    [OBJECT_TYPE_INT] = "int",
    [OBJECT_TYPE_FLOAT] = "float",
    [OBJECT_TYPE_BOOL] = "bool",
    [OBJECT_TYPE_STR] = "string",
    [OBJECT_TYPE_FUNCTION] = "function",
};

char* yyInputFileName;
bool compileError;

int indent = 0;
int scopeLevel = -1;
int funcLineNo = 0;
int variableAddress = 0;
ObjectType variableIdentType;

/* use list head to implement symbol table */
struct list_head *scopeList[1024]; /* scope list */


void pushScope() {
    printf("> Create symbol table (scope level %d)\n", ++scopeLevel);
    struct list_head *head = scopeList[scopeLevel] = malloc(sizeof(struct list_head));
    INIT_LIST_HEAD(head);
    variableAddress = 0;
}

void dumpScope() {
    printf("\n> Dump symbol table (scope level: %d)\n", scopeLevel);
    printf("Index     Name                Type      Addr      Lineno    Func_sig  \n");
    struct list_head *pos;
    Object *obj;
    list_for_each(pos, scopeList[scopeLevel]) {
        obj = list_entry(pos, Object, list);
        printf("%-10d%-20s%-10s%-10ld%-10d%-10s\n"
            , obj->symbol->index, obj->symbol->name, objectTypeName[obj->type], obj->symbol->addr, obj->symbol->lineno, obj->symbol->func_sig);
    }
    scopeLevel--;
}

Object* createVariable(ObjectType variableType, char* variableName, int variableFlag) {
    Object *variable = malloc(sizeof(Object));
    variable->type = variableType;
    variable->symbol = malloc(sizeof(SymbolData));
    variable->symbol->name = variableName;
    variable->symbol->addr = variableAddress++;
    if (!strcmp(variableName, "endl")) {
        variable->symbol->addr = -1;
        variableAddress--;
    }
    if (variableType == OBJECT_TYPE_FUNCTION) {
        variable->symbol->addr = -1;
        variableAddress--;
        printf("func ");
    }
    variable->symbol->lineno = yylineno;
    return variable;
}

void pushFunParm(ObjectType variableType, char* variableName, int variableFlag) {
    printf("> Insert `%s` (addr: %d) to scope level %d\n", variableName, variableAddress, scopeLevel);
    Object* variable = createVariable(variableType, variableName, variableFlag);
    int index = 0;
    // 計算 symbol table 中的 index
    struct list_head *pos;
    list_for_each(pos, scopeList[scopeLevel])
        index++;
    variable->symbol->index = index;
    variable->symbol->func_sig = "-";
    variable->symbol->func_var = 0;
    // put into symbol table
    list_add_tail(&variable->list, scopeList[scopeLevel]);
}

void createFunction(ObjectType variableType, char* funcName) {
    printf("func: %s\n", funcName);
    printf("> Insert `%s` (addr: %d) to scope level %d\n", funcName, -1, scopeLevel);
    Object* variable = createVariable(variableType, funcName, VAR_FLAG_DEFAULT);
    funcLineNo = variable->symbol->lineno;
    variable->type = OBJECT_TYPE_FUNCTION;
    variable->symbol->func_sig = "([Ljava/lang/String;)I";
    variable->symbol->func_var = 1;
    variable->symbol->addr = -1;
    variableAddress = 0;
    // put into symbol table
    list_add_tail(&variable->list, scopeList[scopeLevel]);
}

void debugPrintInst(char instc, Object* a, Object* b, Object* out) {
}

bool objectExpression(char op, Object* dest, Object* val, Object* out) {
    return false;
}

bool objectExpBinary(char op, Object* a, Object* b, Object* out) {
    return false;
}

bool objectExpBoolean(char op, Object* a, Object* b, Object* out) {
    return false;
}

bool objectExpAssign(char op, Object* dest, Object* val, Object* out) {
    return false;
}

bool objectValueAssign(Object* dest, Object* val, Object* out) {
    return false;
}

bool objectNotBinaryExpression(Object* dest, Object* out) {
    return false;
}

bool objectNegExpression(Object* dest, Object* out) {
    return false;
}
bool objectNotExpression(Object* dest, Object* out) {
    return false;
}

bool objectIncAssign(Object* a, Object* out) {
    return false;
}

bool objectDecAssign(Object* a, Object* out) {
    return false;
}

bool objectCast(ObjectType variableType, Object* dest, Object* out) {
    return false;
}

Object* findVariable(char* variableName) {
    /* 在 symbol table 中找到 variableName */
    struct list_head *pos;
    Object *variable;
    for (int i = scopeLevel; i >= 0; i--) {
        list_for_each(pos, scopeList[i]) {
            variable = list_entry(pos, Object, list);
            if (!strcmp(variable->symbol->name, variableName)) {
                printf("test found %s\n", variable->symbol->name);
                return variable;
            }
        }
    }
    return NULL;
}

void pushFunInParm(Object* variable) {
    // printf("this is pushFunInParm name:%d\n", variable->value);
    // printf("this is pushFunInParm\n");
    if (variable->symbol){
        // printf("IDENT (name=%s, address=%ld)\n", variable->symbol->name, variable->symbol->addr);
    } else if (variable->type == OBJECT_TYPE_INT) {
        // printf("INT_LIT %ld\n", variable->value);
        printf("int ");
    } else if (variable->type == OBJECT_TYPE_FLOAT) {
        printf("float ");
    } else if (variable->type == OBJECT_TYPE_BOOL) {
        printf("bool ");
    } else if (variable->type == OBJECT_TYPE_STR) {
        // printf("STR_LIT \"%s\"\n", (char *)variable->value);
    } else {
        // printf("UNDEFINED\n");
    }
    // 將 Parm 數量 +1
    indent++;
}

void stdoutPrint() {
    printf("cout");
    for (int i = 0; i < indent; i++) {
        printf(" string"); /* TODO: 印出的值不一定是 string
                                    要從 table 裡面找 */
    }
    printf("\n");
}

int main(int argc, char* argv[]) {
    if (argc == 2) {
        yyin = fopen(yyInputFileName = argv[1], "r");
    } else {
        yyin = stdin;
    }
    if (!yyin) {
        printf("file `%s` doesn't exists or cannot be opened\n", yyInputFileName);
        exit(1);
    }

    // Start parsing
    yyparse();
    printf("Total lines: %d\n", yylineno);
    fclose(yyin);

    yylex_destroy();
    return 0;
}