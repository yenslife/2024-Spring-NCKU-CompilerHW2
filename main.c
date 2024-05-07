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

void init_cout_list() {
    // printf("cout init\n");
    struct list_head *head = scopeList[++scopeLevel] = malloc(sizeof(struct list_head));
    INIT_LIST_HEAD(head);
}

Object* createVariable(ObjectType variableType, char* variableName, int variableFlag) {
    Object *variable = malloc(sizeof(Object));
    variable->type = variableType;
    // printf("variableType: %d\n", variableType);
    variable->symbol = malloc(sizeof(SymbolData));
    variable->symbol->name = variableName;
    variable->symbol->addr = variableAddress++;
    INIT_LIST_HEAD(&variable->list);
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
    // printf("before add, check scopeLevel:%d(pushFunParm)\n", scopeLevel);
    list_add_tail(&variable->list, scopeList[scopeLevel]);
    // /*印出目前所有的 type*/
    // printf("印出目前所有的 type(pushFunParm) 在 scopeLevel:%d\n", scopeLevel);
    // list_for_each(pos, scopeList[scopeLevel]) {
    //     variable = list_entry(pos, Object, list);
    //     printf("type %d\n", variable->type);
    // }
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
    // printf("before add, check scopeLevel:%d(createFunction)\n", scopeLevel);
    list_add_tail(&variable->list, scopeList[scopeLevel]);
}

void debugPrintInst(char instc, Object* a, Object* b, Object* out) {
}

bool objectExpression(char op, Object* dest, Object* val, Object* out) {
    // 用法: if (objectExpression('+', &$<obj_val>1, &$<obj_val>3, &$$))
    // 會回傳 true/false 代表是否成功
    // 函式的功能是將 dest 和 val 進行運算，結果存到 out
    // 例如: dest = 1, val = 2, op = '+', 則 out = 3
    if (op == '+') {
        out->value = dest->value + val->value;
        printf("ADD\n");
        return true;
    } else if (op == '-') {
        out->value = dest->value - val->value;
        printf("SUB\n");
        return true;
    } else if (op == '*') {
        out->value = dest->value * val->value;
        printf("MUL\n");
        return true;
    } else if (op == '/') {
        out->value = dest->value / val->value;
        printf("DIV\n");
        return true;
    } else if (op == '%') {
        out->value = dest->value % val->value;
        printf("REM\n");
        return true;
    }
    return false;
}

bool objectExpBinary(char op, Object* a, Object* b, Object* out) {
    if (op == '^') {
        out->value = a->value ^ b->value;
        printf("XOR\n");
        return true;
    } else if (op == '|') {
        out->value = a->value | b->value;
        printf("OR\n");
        return true;
    } else if (op == '&') {
        out->value = a->value & b->value;
        printf("AND\n");
        return true;
    } else if (op == '>') {
        out->value = a->value >> b->value;
        printf("SHR\n");
        return true;
    } else if (op == '<') {
        out->value = a->value << b->value;
        printf("SHL\n");
        return true;
    }
    return false;
}

bool objectExpBoolean(char op, Object* a, Object* b, Object* out) {
    if (op == '>') {
        out->value = a->value > b->value;
        printf("GTR\n");
        return true;
    } else if (op == '<') {
        out->value = a->value < b->value;
        printf("LES\n");
        return true;
    } else if (op == '|') {
        out->value = a->value || b->value;
        printf("LOR\n");
        return true;
    } else if (op == '&') {
        out->value = a->value && b->value;
        printf("LAN\n");
        return true;
    } else if (op == '=') {
        out->value = a->value == b->value;
        printf("EQL\n");
        return true;
    } else if (op == '!') {
        out->value = a->value != b->value;
        printf("NEQ\n");
        return true;
    }
    return false;
}

bool objectExpAssign(char op, Object* dest, Object* val, Object* out) {
    return false;
}

bool objectValueAssign(Object* dest, Object* val, Object* out) {
    return false;
}

bool objectNotBinaryExpression(Object* dest, Object* out) {
    // object not binary expression
    // 意思是將 dest 的值取反，存到 out
    if (!dest || !out) {
        return false;
    }
    out->value = !dest->value;
    printf("NOT\n");
    return true;
}

bool objectNegExpression(Object* dest, Object* out) {
    if (!dest || !out) {
        return false;
    }
    out->value = -dest->value;
    printf("NEG\n");
    return true;
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
    // struct list_head *pos;
    // Object *variable;
    // for (int i = scopeLevel; i >= 0; i--) {
    //     list_for_each(pos, scopeList[i]) {
    //         variable = list_entry(pos, Object, list);
    //         if (!strcmp(variable->symbol->name, variableName)) {
    //             printf("test found %s\n", variable->symbol->name);
    //             return variable;
    //         }
    //     }
    // }
    return NULL;
}

void pushFunInParm(Object* variable) {
    // printf("this is pushFunInParm value:%s\n", (char *)variable->value);
    // printf("this is pushFunInParm\n");
    // printf("xtype %d\n", variable->type);
    if (variable->symbol){
        // printf("IDENT (name=%s, address=%ld)\n", variable->symbol->name, variable->symbol->addr);
        if (!strcmp(variable->symbol->name, "endl")) {
            // printf("endl\n");
            Object *new_obj = malloc(sizeof(Object));
            new_obj->type = OBJECT_TYPE_STR;
            new_obj->value = (uint64_t)strdup("endl");
            INIT_LIST_HEAD(&new_obj->list);
            list_add_tail(&new_obj->list, scopeList[scopeLevel]);
            return;
        }
    } else if (variable->type == OBJECT_TYPE_INT) {
        // printf("INT_LIT %ld\n", variable->value);
        // printf("!!!int value:%ld\n", variable->value);
    } else if (variable->type == OBJECT_TYPE_FLOAT) {
        // printf("!!!float value:%ld\n", variable->value);
    } else if (variable->type == OBJECT_TYPE_BOOL) {
        // printf("!!!bool value:%ld\n", variable->value); 
    } else if (variable->type == OBJECT_TYPE_STR) {
        // printf("str\n");
        // printf("STR_LIT \"%s\"\n", (char *)variable->value);
    } else {
        printf("wtf\n");
    }
    // if (variable->list)
    //     printf("NULL\n");

    // printf("before add, check scopeLevel:%d(pushFunInParm)\n", scopeLevel);
    // printf("variable type %d\n", variable->type);
    
    Object *new_obj = createVariable(variable->type, "NULL", VAR_FLAG_DEFAULT);
    new_obj->value = variable->value;
    // new_obj->type = variable->type;
    // new_obj->value = variable->value;
    INIT_LIST_HEAD(&new_obj->list);
    // free(variable);

    list_add_tail(&new_obj->list, scopeList[scopeLevel]);
    // list_add(&variable->list, scopeList[scopeLevel]);

    // 將 Parm 數量 +1
    indent++;
}

void stdoutPrint() {
    // printf("開始 stdoutPrint\n");
    printf("cout");
    // for (int i = 0; i < indent; i++) {
    //     printf(" string"); /* TODO: 印出的值不一定是 string
    //                                 要從 table 裡面找 */
    // }
    // printf("\n");
    struct list_head *pos;
    Object *variable;
    list_for_each(pos, scopeList[scopeLevel]) {
        variable = list_entry(pos, Object, list);
        // printf("value:%ld\n", variable->value);
        // printf("type:%d\n", variable->type);
        if (variable->type == OBJECT_TYPE_INT) {
            printf(" int");
        } else if (variable->type == OBJECT_TYPE_FLOAT) {
            printf(" float");
        } else if (variable->type == OBJECT_TYPE_BOOL) {
            printf(" bool");
        } else if (variable->type == OBJECT_TYPE_STR) {
            printf(" string");
        } else {
            printf(" undefined");
        }
    }
    // printf("結束 stdoutPrint\n");
    
    /* remove all Parm on cout level */
    struct list_head *q;
    list_for_each_safe(pos, q, scopeList[scopeLevel]) {
        variable = list_entry(pos, Object, list);
        list_del(pos);
        free(variable);
    }
    
    printf("\n");
    indent = 0;
    scopeLevel--;
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