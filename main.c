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

// stack
struct list_head *scopeList[1024];

// cout list
Object coutList[1024];
int coutIndex = 0;

void pushScope() {
    printf("> Create symbol table (scope level %d)\n", ++scopeLevel);
    scopeList[scopeLevel] = (struct list_head*)malloc(sizeof(struct list_head));
    INIT_LIST_HEAD(scopeList[scopeLevel]);
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
    // create variable object
    Object* variable = (Object*)malloc(sizeof(Object));
    variable->type = variableType;
    variable->symbol = (SymbolData*)malloc(sizeof(SymbolData));
    variable->symbol->name = strdup(variableName);
    variable->symbol->addr = variableAddress++;
    variable->symbol->func_sig = "-";
    variable->symbol->lineno = yylineno;
    return variable;
}

void pushFunParm(ObjectType variableType, char* variableName, int variableFlag) {
    // create variable object
    Object* variable = createVariable(variableType, variableName, variableFlag);
    printf("> Insert `%s` (addr: %ld) to scope level %d\n", variableName, variable->symbol->addr, scopeLevel);

    // add to scope list
    list_add_tail(&variable->list, scopeList[scopeLevel]);
}

void createFunction(ObjectType variableType, char* funcName) {
    // create function object
    Object* function = (Object*)malloc(sizeof(Object));
    function->type = OBJECT_TYPE_FUNCTION;
    function->symbol = (SymbolData*)malloc(sizeof(SymbolData));
    function->symbol->name = strdup(funcName);
    function->symbol->addr = -1; // 如果是 function 就不用 addr
    function->symbol->func_sig = "([Ljava/lang/String;)I"; // 暫時先用 ([Ljava/lang/String;)I，之後再來改
    function->symbol->lineno = yylineno; // 暫時先用 lineno 來記錄 function 的行數
    printf("func: %s\n", funcName);
    printf("> Insert `%s` (addr: %ld) to scope level %d\n", funcName, function->symbol->addr, scopeLevel);

    // add to scope list
    list_add_tail(&function->list, scopeList[scopeLevel]);

    // push scope
    pushScope();
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
    Object* variable = NULL;
    return variable;
}

void pushFunInParm(Object* variable) {
    // 目前只有 cout 用到
    coutList[coutIndex++] = *variable;
}

void stdoutPrint() {
    printf("cout");
    for (int i = 0; i < coutIndex; i++) {
        printf(" %s", objectTypeName[coutList[i].type]);
    }
    printf("\n");
    coutIndex = 0;
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