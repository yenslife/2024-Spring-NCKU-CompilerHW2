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

void pushScope() {
    printf("> Create symbol table (scope level %d)\n", ++scopeLevel);
    scopeList[scopeLevel] = (struct list_head*)malloc(sizeof(struct list_head));
    INIT_LIST_HEAD(scopeList[scopeLevel]);
}

void dumpScope() {
}

Object* createVariable(ObjectType variableType, char* variableName, int variableFlag) {
    return NULL;
}

void pushFunParm(ObjectType variableType, char* variableName, int variableFlag) {
}

void createFunction(ObjectType variableType, char* funcName) {
    // create function object
    Object* function = (Object*)malloc(sizeof(Object));
    function->type = OBJECT_TYPE_FUNCTION;
    function->symbol = (SymbolData*)malloc(sizeof(SymbolData));
    function->symbol->name = strdup(funcName);
    function->symbol->addr = -1; // 如果是 function 就不用 addr
    printf("func: %s\n", funcName);
    printf("> Insert `%s` (addr: %ld) to scope level %d\n", funcName, function->symbol->addr, scopeLevel);

    // add to scope list
    list_add_tail(&function->list, scopeList[scopeLevel]);
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
}

void stdoutPrint() {
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