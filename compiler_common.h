#ifndef COMPILER_COMMON_H
#define COMPILER_COMMON_H

#include <stdbool.h>
#include <stdint.h>

#include "list.h"

typedef enum _objectType {
    OBJECT_TYPE_UNDEFINED,
    OBJECT_TYPE_AUTO,
    OBJECT_TYPE_VOID,
    OBJECT_TYPE_CHAR,
    OBJECT_TYPE_INT,
    OBJECT_TYPE_LONG,
    OBJECT_TYPE_FLOAT,
    OBJECT_TYPE_DOUBLE,
    OBJECT_TYPE_BOOL,
    OBJECT_TYPE_STR,
    OBJECT_TYPE_FUNCTION,
} ObjectType;

typedef struct _symbolData {
    char* name;
    int32_t index; /* 在 symbol table 的 index */
    int64_t addr; /* 如果是變數，是在記憶體的位置，從 0 開始數，如果是不確定的，應該是 -1 */
    int32_t lineno; /* 在哪一行，應該是從 yylineno 拿 */
    char* func_sig; /* 函數簽名，目前只知道 "-"" 和 "([Ljava/lang/String;)I" */
    uint8_t func_var; /* 不確定是做什麼的，應該是函數的變數 */
} SymbolData;

typedef struct _object {
    ObjectType type;
    uint64_t value;
    SymbolData* symbol;
    struct list_head list;
} Object;

extern int yylineno;
extern int funcLineNo;

#endif /* COMPILER_COMMON_H */