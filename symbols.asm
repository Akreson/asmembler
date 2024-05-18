TOKEN_TYPE_KEYWORD equ 1
TOKEN_TYPE_INS     equ 2
TOKEN_TYPE_REG     equ 3
TOKEN_TYPE_AUX     equ 4
TOKEN_TYPE_NAME    equ 5
TOKEN_TYPE_DIGIT   equ 6
TOKEN_TYPE_STR     equ 7
TOKEN_TYPE_EOF     equ 8

REG_AL   equ 0x00
REG_CL   equ 0x01
REG_DL   equ 0x02
REG_BL   equ 0x03
REG_AH   equ 0x04
REG_CH   equ 0x05
REG_DH   equ 0x06
REG_BH   equ 0x07
REG_R8B  equ 0x08
REG_R9B  equ 0x09
REG_R10B equ 0x0A
REG_R11B equ 0x0B
REG_R12B equ 0x0C
REG_R13B equ 0x0D
REG_R14B equ 0x0E
REG_R15B equ 0x0F

REG_AX   equ 0x10
REG_CX   equ 0x11
REG_DX   equ 0x12
REG_BX   equ 0x13
REG_SP   equ 0x14
REG_BP   equ 0x15
REG_SI   equ 0x16
REG_DI   equ 0x17
REG_R8W  equ 0x18
REG_R9W  equ 0x19
REG_R10W equ 0x1A
REG_R11W equ 0x1B
REG_R12W equ 0x1C
REG_R13W equ 0x1D
REG_R14W equ 0x1E
REG_R15W equ 0x1F

REG_EAX  equ 0x20
REG_ECX  equ 0x21
REG_EDX  equ 0x22
REG_EBX  equ 0x23
REG_ESP  equ 0x24
REG_EBP  equ 0x25
REG_ESI  equ 0x26
REG_EDI  equ 0x27
REG_R8D  equ 0x28
REG_R9D  equ 0x29
REG_R10D equ 0x2A
REG_R11D equ 0x2B
REG_R12D equ 0x2C
REG_R13D equ 0x2D
REG_R14D equ 0x2E
REG_R15D equ 0x2F

REG_RAX equ 0x40
REG_RCX equ 0x41
REG_RDX equ 0x42
REG_RBX equ 0x43
REG_RSP equ 0x44
REG_RBP equ 0x45
REG_RSI equ 0x46
REG_RDI equ 0x47
REG_R8  equ 0x48
REG_R9  equ 0x49
REG_R10 equ 0x4A
REG_R11 equ 0x4B
REG_R12 equ 0x4C
REG_R13 equ 0x4D
REG_R14 equ 0x4E
REG_R15 equ 0x4F

NAME_JUMP  equ 0x01
NAME_CONST equ 0x02
NAME_VAR   equ 0x03


;STR_REPS
INS_REP   equ 0x010000
INS_MOV   equ 0x010001
INS_MOVS  equ 0x010002
INS_MOVSB equ 0x010003
INS_MOVSW equ 0x010004
INS_MOVSD equ 0x010005
INS_MOVZX equ 0x010006
INS_MOVSX equ 0x010007
INS_LEA   equ 0x010008
INS_RET   equ 0x010009
INS_POP   equ 0x01000A
INS_PUSH  equ 0x01000B
INS_INC   equ 0x01000C
INS_DEC   equ 0x01000D
INS_AND   equ 0x01000E
INS_OR    equ 0x01000F
INS_XOR   equ 0x010010
INS_ADD   equ 0x010011
INS_SHL   equ 0x010012
INS_SAL   equ 0x010013
INS_SHR   equ 0x010014
INS_SAR   equ 0x010015
INS_SUB   equ 0x010016
INS_DIV   equ 0x010017
INS_IDVI  equ 0x010018
INS_MUL   equ 0x010019
INS_IMUL  equ 0x01001A
INS_TEST  equ 0x01001B
INS_BSR   equ 0x01001C
INS_BSF   equ 0x01001D
INS_TZCNT equ 0x01001E
INS_LZCNT equ 0x01001F
INS_CMP   equ 0x010020
INS_CALL  equ 0x010021
INS_JMP   equ 0x010022
INS_JE    equ 0x010023
INS_JNE   equ 0x010024
INS_JG    equ 0x010025
INS_JGE   equ 0x010026
INS_JL    equ 0x010027
INS_JLE   equ 0x010028
INS_JZ    equ 0x010029
INS_JNZ   equ 0x01002A
INS_JO    equ 0x01002B
INS_JNO   equ 0x01002C
INS_JS    equ 0x01002D
INS_JNS   equ 0x01002E
INS_JA    equ 0x01002F
INS_JAE   equ 0x010030
INS_JB    equ 0x010031
INS_JBE   equ 0x010032
 
AUX_COLON     equ 0x020000
AUX_LPAREN    equ 0x020001
AUX_RPAREN    equ 0x020002
AUX_LBRACE    equ 0x020003
AUX_RBRACE    equ 0x020004
AUX_LBRACKET  equ 0x020005
AUX_RBRACKET  equ 0x020006
AUX_COMMA     equ 0x020007
AUX_DOT       equ 0x020008
AUX_SEMICOLON equ 0x020009
AUX_MOD       equ 0x02000A
AUX_ADD       equ 0x02000B
AUX_SUB       equ 0x02000C
AUX_MUL       equ 0x02000D
AUX_DQM       equ 0x02000E
AUX_QM        equ 0x02000F
AUX_NEW_LINE  equ 0x020010
AUX_ATSIGN    equ 0x020011

TOKEN_KIND_SIZE equ 14
SIZE_HASH_DEF_SYM_TABLE equ 2048

segment readable

;STR_ "", 0
STR_AL   db "al"
STR_CL   db "cl"
STR_DL   db "dl"
STR_BL   db "bl"
STR_AH   db "ah"
STR_CH   db "ch"
STR_DH   db "dh"
STR_BH   db "bh"
STR_R8B  db "r8b"
STR_R9B  db "r9b"
STR_R10B db "r10b"
STR_R11B db "r11b"
STR_R12B db "r12b"
STR_R13B db "r13b"
STR_R14B db "r14b"
STR_R15B db "r15b"
 
STR_AX   db "ax"
STR_CX   db "cx"
STR_DX   db "dx"
STR_BX   db "bx"
STR_SP   db "sp"
STR_BP   db "bp"
STR_SI   db "si"
STR_DI   db "di"
STR_R8W  db "r8w"
STR_R9W  db "r9w"
STR_R10W db "r10w"
STR_R11W db "r11w"
STR_R12W db "r12w"
STR_R13W db "r13w"
STR_R14W db "r14w"
STR_R15W db "r15w"

STR_EAX  db "eax"
STR_ECX  db "ecx"
STR_EDX  db "edx"
STR_EBX  db "ebx"
STR_ESP  db "esp"
STR_EBP  db "ebp"
STR_ESI  db "esi"
STR_EDI  db "edi"
STR_R8D  db "r8d"
STR_R9D  db "r9d"
STR_R10D db "r10d"
STR_R11D db "r11d"
STR_R12D db "r12d"
STR_R13D db "r13d"
STR_R14D db "r14d"
STR_R15D db "r15d"

STR_RAX db "rax"
STR_RCX db "rcx"
STR_RDX db "rdx"
STR_RBX db "rbx"
STR_RSP db "rsp"
STR_RBP db "rbp"
STR_RSI db "rsi"
STR_RDI db "rdi"
STR_R8  db "r8"
STR_R9  db "r9"
STR_R10 db "r10"
STR_R11 db "r11"
STR_R12 db "r12"
STR_R13 db "r13"
STR_R14 db "r14"
STR_R15 db "r15"


;STR_REPS
STR_REP   db "rep"
STR_MOV   db "mov"
STR_MOVS  db "movs"
STR_MOVSB db "movsb"
STR_MOVSW db "movsw"
STR_MOVSD db "movsd"
STR_MOVZX db "movzx"
STR_MOVSX db "movcx"
STR_LEA   db "lea"
STR_RET   db "ret"
STR_POP   db "pop"
STR_PUSH  db "push"
STR_INC   db "inc"
STR_DEC   db "dec"
STR_AND   db "and"
STR_OR    db "or"
STR_XOR   db "xor"
STR_ADD   db "add"
STR_SHL   db "shl" ; / same opcode
STR_SAL   db "sal" ; \
STR_SHR   db "shr" ; / not the same
STR_SAR   db "sar" ; \
STR_SUB   db "sub"
STR_DIV   db "div"
STR_IDVI  db "idiv"
STR_MUL   db "mul"
STR_IMUL  db "imul"
STR_TEST  db "test"
STR_BSR   db "bsr"
STR_BSF   db "bsf"
STR_TZCNT db "tzcnt"
STR_LZCNT db "lzcnt"
STR_CMP   db "cmp"
STR_CALL  db "call"
STR_JMP   db "jmp"
STR_JE    db "je"
STR_JNE   db "jne"
STR_JG    db "jg"
STR_JA    db "ja"
STR_JGE   db "jge"
STR_JAE   db "jae"
STR_JL    db "jl"
STR_JB    db "jb"
STR_JLE   db "jle"
STR_JBE   db "jbe"
STR_JZ    db "jz"
STR_JNZ   db "jnz"
STR_JO    db "jo"
STR_JNO   db "jno"
STR_JS    db "js"
STR_JNS   db "jns"

;START OF AUX STR
STR_COMMA     db ","
STR_COLON     db ":"
STR_LBRACKET  db "["
STR_RBRACKET  db "]"
STR_AUX_ADD   db "+"
STR_AUX_SUB   db "-"
STR_AUX_MUL   db "*"
STR_NEW_LINE  db 0x0A
STR_DQM       db 0x22
STR_QM        db 0x27
STR_LPAREN    db "("
STR_RPAREN    db ")"
STR_LBRACE    db "{"
STR_RBRACE    db "}"
STR_SEMICOLON db ";"
STR_MOD       db "%"
STR_DOT       db "."
STR_ATSIGN    db "@"
db 0 dup 6; this block of data must be multible of 8
AUX_MEM_BLOCK_SIZE equ 24
AUX_NAME_VALID_FROM equ 17

SYM_NAME_MAX_LEN equ 255
; reserve for token_type_name field _type_ as _size_?
macro def_symbol_m value, type, str_ptr, str_len
{   
    ; 0, +8, +12, +13, (+14)
    dq str_ptr; / general prt to struct / digit container
    dd value
    db type
    db str_len
    ;db name type (only for _name_ type token in memory)
}

DEF_SYM_TABLE dq 0
dd 0
db 0xFF, 0; dumy define
def_symbol_m REG_AL, TOKEN_TYPE_REG, STR_AL, 2
def_symbol_m REG_CL, TOKEN_TYPE_REG, STR_CL, 2
def_symbol_m REG_DL, TOKEN_TYPE_REG, STR_DL, 2
def_symbol_m REG_BL, TOKEN_TYPE_REG, STR_BL, 2
def_symbol_m REG_AH, TOKEN_TYPE_REG, STR_AH, 2
def_symbol_m REG_CH, TOKEN_TYPE_REG, STR_CH, 2
def_symbol_m REG_DH, TOKEN_TYPE_REG, STR_DH, 2
def_symbol_m REG_BH, TOKEN_TYPE_REG, STR_BH, 2
def_symbol_m REG_R8B, TOKEN_TYPE_REG, STR_R8B, 3
def_symbol_m REG_R9B, TOKEN_TYPE_REG, STR_R9B, 3
def_symbol_m REG_R10B, TOKEN_TYPE_REG, STR_R10B, 4
def_symbol_m REG_R11B, TOKEN_TYPE_REG, STR_R11B, 4
def_symbol_m REG_R12B, TOKEN_TYPE_REG, STR_R12B, 4
def_symbol_m REG_R13B, TOKEN_TYPE_REG, STR_R13B, 4
def_symbol_m REG_R14B, TOKEN_TYPE_REG, STR_R14B, 4
def_symbol_m REG_R15B, TOKEN_TYPE_REG, STR_R15B, 4

def_symbol_m REG_AX, TOKEN_TYPE_REG, STR_AX, 2
def_symbol_m REG_CX, TOKEN_TYPE_REG, STR_CX, 2
def_symbol_m REG_DX, TOKEN_TYPE_REG, STR_DX, 2
def_symbol_m REG_BX, TOKEN_TYPE_REG, STR_BX, 2
def_symbol_m REG_SP, TOKEN_TYPE_REG, STR_SP, 2
def_symbol_m REG_BP, TOKEN_TYPE_REG, STR_BP, 2
def_symbol_m REG_SI, TOKEN_TYPE_REG, STR_SI, 2
def_symbol_m REG_DI, TOKEN_TYPE_REG, STR_DI, 2
def_symbol_m REG_R8W, TOKEN_TYPE_REG, STR_R8W, 3
def_symbol_m REG_R9W, TOKEN_TYPE_REG, STR_R9W, 3
def_symbol_m REG_R10W, TOKEN_TYPE_REG, STR_R10W, 4
def_symbol_m REG_R11W, TOKEN_TYPE_REG, STR_R11W, 4
def_symbol_m REG_R12W, TOKEN_TYPE_REG, STR_R12W, 4
def_symbol_m REG_R13W, TOKEN_TYPE_REG, STR_R13W, 4
def_symbol_m REG_R14W, TOKEN_TYPE_REG, STR_R14W, 4
def_symbol_m REG_R15W, TOKEN_TYPE_REG, STR_R15W, 4

def_symbol_m REG_EAX, TOKEN_TYPE_REG, STR_EAX, 3
def_symbol_m REG_ECX, TOKEN_TYPE_REG, STR_ECX, 3
def_symbol_m REG_EDX, TOKEN_TYPE_REG, STR_EDX, 3
def_symbol_m REG_EBX, TOKEN_TYPE_REG, STR_EBX, 3
def_symbol_m REG_ESP, TOKEN_TYPE_REG, STR_ESP, 3
def_symbol_m REG_EBP, TOKEN_TYPE_REG, STR_EBP, 3
def_symbol_m REG_ESI, TOKEN_TYPE_REG, STR_ESI, 3
def_symbol_m REG_EDI, TOKEN_TYPE_REG, STR_EDI, 3
def_symbol_m REG_R8D, TOKEN_TYPE_REG, STR_R8D, 3
def_symbol_m REG_R9D, TOKEN_TYPE_REG, STR_R9D, 3
def_symbol_m REG_R10D, TOKEN_TYPE_REG, STR_R10D, 4
def_symbol_m REG_R11D, TOKEN_TYPE_REG, STR_R11D, 4
def_symbol_m REG_R12D, TOKEN_TYPE_REG, STR_R12D, 4
def_symbol_m REG_R13D, TOKEN_TYPE_REG, STR_R13D, 4
def_symbol_m REG_R14D, TOKEN_TYPE_REG, STR_R14D, 4
def_symbol_m REG_R15D, TOKEN_TYPE_REG, STR_R15D, 4

def_symbol_m REG_RAX, TOKEN_TYPE_REG, STR_RAX, 3
def_symbol_m REG_RCX, TOKEN_TYPE_REG, STR_RCX, 3
def_symbol_m REG_RDX, TOKEN_TYPE_REG, STR_RDX, 3
def_symbol_m REG_RBX, TOKEN_TYPE_REG, STR_RBX, 3
def_symbol_m REG_RSP, TOKEN_TYPE_REG, STR_RSP, 3
def_symbol_m REG_RBP, TOKEN_TYPE_REG, STR_RBP, 3
def_symbol_m REG_RSI, TOKEN_TYPE_REG, STR_RSI, 3
def_symbol_m REG_RDI, TOKEN_TYPE_REG, STR_RDI, 3
def_symbol_m REG_R8, TOKEN_TYPE_REG, STR_R8, 2
def_symbol_m REG_R9, TOKEN_TYPE_REG, STR_R9, 2
def_symbol_m REG_R10, TOKEN_TYPE_REG, STR_R10, 3
def_symbol_m REG_R11, TOKEN_TYPE_REG, STR_R11, 3
def_symbol_m REG_R12, TOKEN_TYPE_REG, STR_R12, 3
def_symbol_m REG_R13, TOKEN_TYPE_REG, STR_R13, 3
def_symbol_m REG_R14, TOKEN_TYPE_REG, STR_R14, 3
def_symbol_m REG_R15, TOKEN_TYPE_REG, STR_R15, 3

def_symbol_m INS_REP, TOKEN_TYPE_INS, STR_REP, 3
def_symbol_m INS_MOV, TOKEN_TYPE_INS, STR_MOV, 3
def_symbol_m INS_MOVS, TOKEN_TYPE_INS, STR_MOVS, 4
def_symbol_m INS_MOVSB, TOKEN_TYPE_INS, STR_MOVSB, 5
def_symbol_m INS_MOVSW, TOKEN_TYPE_INS, STR_MOVSW, 5
def_symbol_m INS_MOVSD, TOKEN_TYPE_INS, STR_MOVSD, 5
def_symbol_m INS_MOVZX, TOKEN_TYPE_INS, STR_MOVZX, 5
def_symbol_m INS_MOVSX, TOKEN_TYPE_INS, STR_MOVSX, 5
def_symbol_m INS_LEA, TOKEN_TYPE_INS, STR_LEA, 3
def_symbol_m INS_RET, TOKEN_TYPE_INS, STR_RET, 3
def_symbol_m INS_POP, TOKEN_TYPE_INS, STR_POP, 3
def_symbol_m INS_PUSH, TOKEN_TYPE_INS, STR_PUSH, 4
def_symbol_m INS_INC, TOKEN_TYPE_INS, STR_INC, 3
def_symbol_m INS_DEC, TOKEN_TYPE_INS, STR_DEC, 3
def_symbol_m INS_AND, TOKEN_TYPE_INS, STR_AND, 3
def_symbol_m INS_OR, TOKEN_TYPE_INS, STR_OR, 2
def_symbol_m INS_XOR, TOKEN_TYPE_INS, STR_XOR, 3
def_symbol_m INS_ADD, TOKEN_TYPE_INS, STR_ADD, 3
def_symbol_m INS_SHL, TOKEN_TYPE_INS, STR_SHL, 3
def_symbol_m INS_SAL, TOKEN_TYPE_INS, STR_SAL, 3
def_symbol_m INS_SHR, TOKEN_TYPE_INS, STR_SHR, 3
def_symbol_m INS_SAR, TOKEN_TYPE_INS, STR_SAR, 3
def_symbol_m INS_SUB, TOKEN_TYPE_INS, STR_SUB, 3
def_symbol_m INS_DIV, TOKEN_TYPE_INS, STR_DIV, 3
def_symbol_m INS_IDVI, TOKEN_TYPE_INS, STR_IDVI, 4
def_symbol_m INS_MUL, TOKEN_TYPE_INS, STR_MUL, 3
def_symbol_m INS_IMUL, TOKEN_TYPE_INS, STR_IMUL, 4
def_symbol_m INS_TEST, TOKEN_TYPE_INS, STR_TEST, 4
def_symbol_m INS_BSR, TOKEN_TYPE_INS, STR_BSR, 3
def_symbol_m INS_BSF, TOKEN_TYPE_INS, STR_BSF, 3
def_symbol_m INS_TZCNT, TOKEN_TYPE_INS, STR_TZCNT, 5
def_symbol_m INS_LZCNT, TOKEN_TYPE_INS, STR_LZCNT, 5
def_symbol_m INS_CMP, TOKEN_TYPE_INS, STR_CMP, 3
def_symbol_m INS_CALL, TOKEN_TYPE_INS, STR_CALL, 4
def_symbol_m INS_JMP, TOKEN_TYPE_INS, STR_JMP, 3
def_symbol_m INS_JE, TOKEN_TYPE_INS, STR_JE, 2
def_symbol_m INS_JNE, TOKEN_TYPE_INS, STR_JNE, 3
def_symbol_m INS_JG, TOKEN_TYPE_INS, STR_JG, 2
def_symbol_m INS_JGE, TOKEN_TYPE_INS, STR_JGE, 3
def_symbol_m INS_JL, TOKEN_TYPE_INS, STR_JL, 2
def_symbol_m INS_JLE, TOKEN_TYPE_INS, STR_JLE, 3
def_symbol_m INS_JZ, TOKEN_TYPE_INS, STR_JZ, 2
def_symbol_m INS_JNZ, TOKEN_TYPE_INS, STR_JNZ, 3
def_symbol_m INS_JO, TOKEN_TYPE_INS, STR_JO, 2
def_symbol_m INS_JNO, TOKEN_TYPE_INS, STR_JNO, 3
def_symbol_m INS_JS, TOKEN_TYPE_INS, STR_JS, 2
def_symbol_m INS_JNS, TOKEN_TYPE_INS, STR_JNS, 3
def_symbol_m INS_JA, TOKEN_TYPE_INS, STR_JA, 2
def_symbol_m INS_JAE, TOKEN_TYPE_INS, STR_JAE, 3
def_symbol_m INS_JB, TOKEN_TYPE_INS, STR_JB, 2
def_symbol_m INS_JBE, TOKEN_TYPE_INS, STR_JBE, 3

DUMMY_NODE_AUX dq 0
dd 0
db 0xFF, 0

def_symbol_m AUX_COMMA, TOKEN_TYPE_AUX, STR_COMMA, 1
def_symbol_m AUX_COLON, TOKEN_TYPE_AUX, STR_COLON, 1
def_symbol_m AUX_LBRACKET, TOKEN_TYPE_AUX, STR_LBRACKET, 1
def_symbol_m AUX_RBRACKET, TOKEN_TYPE_AUX, STR_RBRACKET, 1
def_symbol_m AUX_ADD, TOKEN_TYPE_AUX, STR_AUX_ADD, 1
def_symbol_m AUX_SUB, TOKEN_TYPE_AUX, STR_AUX_SUB, 1
def_symbol_m AUX_MUL, TOKEN_TYPE_AUX, STR_AUX_MUL, 1
def_symbol_m AUX_NEW_LINE, TOKEN_TYPE_AUX, STR_NEW_LINE, 1
def_symbol_m AUX_DQM, TOKEN_TYPE_AUX, STR_DQM, 1
def_symbol_m AUX_QM, TOKEN_TYPE_AUX, STR_QM, 1
def_symbol_m AUX_LPAREN, TOKEN_TYPE_AUX, STR_LPAREN, 1
def_symbol_m AUX_RPAREN, TOKEN_TYPE_AUX, STR_RPAREN, 1
def_symbol_m AUX_LBRACE, TOKEN_TYPE_AUX, STR_LBRACE, 1
def_symbol_m AUX_RBRACE, TOKEN_TYPE_AUX, STR_RBRACE, 1
def_symbol_m AUX_SEMICOLON, TOKEN_TYPE_AUX, STR_SEMICOLON, 1
def_symbol_m AUX_MOD, TOKEN_TYPE_AUX, STR_MOD, 1
def_symbol_m AUX_DOT, TOKEN_TYPE_AUX, STR_DOT, 1
def_symbol_m AUX_ATSIGN, TOKEN_TYPE_AUX, STR_ATSIGN, 1

def_symbol_m 0, 0, 0, 0
