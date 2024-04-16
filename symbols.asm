TOKEN_TYPE_KEYWORD equ 1
TOKEN_TYPE_INS     equ 2
TOKEN_TYPE_REG     equ 3
TOKEN_TYPE_AUX     equ 4
TOKEN_TYPE_NAME    equ 5

REG_AL   equ 0x00
REG_CL   equ 0x01
REG_DL   equ 0x02
REG_BL   equ 0x03
REG_AH   equ 0x04
REG_CH   equ 0x05
REG_DH   equ 0x06
REG_BH   equ 0x07
REG_8B   equ 0x08
REG_9B   equ 0x09
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
REG_8W   equ 0x18
REG_9W   equ 0x19
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
INS_MUL   equ 0x01001A
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
INS_JI    equ 0x010027
INS_JIE   equ 0x010028
INS_JZ    equ 0x010029
INS_JNZ   equ 0x01002A
INS_JO    equ 0x01002B
INS_JNO   equ 0x01002C
INS_JS    equ 0x01002D
INS_JNS   equ 0x01002E
 
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

segment readable

;STR_ "", 0
STR_AL   db "al", 0
STR_CL   db "cl", 0
STR_DL   db "dl", 0
STR_BL   db "bl", 0
STR_AH   db "ah", 0
STR_CH   db "ch", 0
STR_DH   db "dh", 0
STR_BH   db "bh", 0
STR_R8B  db "r8b", 0
STR_R9B  db "r9b", 0
STR_R10B db "r10b", 0
STR_R11B db "r11b", 0
STR_R12B db "r12b", 0
STR_R13B db "r13b", 0
STR_R14B db "r14b", 0
STR_R15B db "r15b", 0
 
STR_AX   db "ax", 0
STR_CX   db "cx", 0
STR_DX   db "dx", 0
STR_BX   db "bx", 0
STR_SP   db "sp", 0
STR_BP   db "bp", 0
STR_SI   db "si", 0
STR_DI   db "di", 0
STR_8W   db "r8w", 0
STR_9W   db "r9w", 0
STR_R10W db "r10w", 0
STR_R11W db "r11w", 0
STR_R12W db "r12w", 0
STR_R13W db "r13w", 0
STR_R14W db "r14w", 0
STR_R15W db "r15w", 0

STR_EAX  db "eax", 0
STR_ECX  db "ecx", 0
STR_EDX  db "edx", 0
STR_EBX  db "ebx", 0
STR_ESP  db "esp", 0
STR_EBP  db "ebp", 0
STR_ESI  db "esi", 0
STR_EDI  db "edi", 0
STR_R8D  db "r8d", 0
STR_R9D  db "r9d", 0
STR_R10D db "r10d", 0
STR_R11D db "r11d", 0
STR_R12D db "r12d", 0
STR_R13D db "r13d", 0
STR_R14D db "r14d", 0
STR_R15D db "r15d", 0

STR_RAX db "rax", 0
STR_RCX db "rcx", 0
STR_RDX db "rdx", 0
STR_RBX db "rbx", 0
STR_RSP db "rsp", 0
STR_RBP db "rbp", 0
STR_RSI db "rsi", 0
STR_RDI db "rdi", 0
STR_R8  db "r8", 0
STR_R9  db "r9", 0
STR_R10 db "r10", 0
STR_R11 db "r11", 0
STR_R12 db "r12", 0
STR_R13 db "r13", 0
STR_R14 db "r14", 0
STR_R15 db "r15", 0


;STR_REPS
STR_REP   db "rep", 0
STR_MOV   db "mov", 0
STR_MOVS  db "movs", 0
STR_MOVSB db "movsb", 0
STR_MOVSW db "movsw", 0
STR_MOVSD db "movsd", 0
STR_MOVZX db "movzx", 0
STR_MOVSX db "movcx", 0
STR_LEA   db "lea", 0
STR_RET   db "ret", 0
STR_POP   db "pop", 0
STR_PUSH  db "push", 0
STR_INC   db "inc", 0
STR_DEC   db "dec", 0
STR_AND   db "and", 0
STR_OR    db "or", 0
STR_XOR   db "xor", 0
STR_ADD   db "add", 0
STR_SHL   db "shl", 0 ; / same opcode
STR_SAL   db "sal", 0 ; \
STR_SHR   db "shr", 0 ; / not the same
STR_SAR   db "sar", 0 ; \
STR_SUB   db "sub", 0
STR_DIV   db "div", 0
STR_IDVI  db "idiv", 0
STR_MUL   db "mul", 0
STR_IMUL  db "imul", 0
STR_TEST  db "test", 0
STR_BSR   db "bsr", 0
STR_BSF   db "bsf", 0
STR_TZCNT db "tzcnt", 0
STR_LZCNT db "lzcnt", 0
STR_CMP   db "cmp", 0
STR_CALL  db "call", 0
STR_JMP   db "jmp", 0
STR_JE    db "je", 0
STR_JNE   db "jne", 0
STR_JG    db "jg", 0
STR_JGE   db "jge", 0
STR_JI    db "ji", 0
STR_JIE   db "jie", 0
STR_JZ    db "jz", 0
STR_JNZ   db "jne", 0
STR_JO    db "jo", 0
STR_JNO   db "jno", 0
STR_JS    db "js", 0
STR_JNS   db "jns", 0

STR_COLON db ":", 0
STR_LPAREN db "(", 0
STR_RPAREN db ")", 0
STR_LBRACE db "{", 0
STR_RBRACE db "}", 0
STR_LBRACKET db "[", 0
STR_RBRACKET db "]", 0
STR_COMMA db ",", 0
STR_DOT db ".", 0
STR_SEMICOLON db ";", 0
STR_MOD db "%", 0
STR_AUX_ADD db "+", 0
STR_AUX_SUB db "-", 0
STR_AUX_MUL db "*", 0

; reserve for token_type_name field _type_ as _size_?
macro def_symbol_m value, type, str_ptr
{
    dd value, type
    dq str_ptr
}

DEF_SYM_TABLE dd 0, 0
dq 0
def_symbol_m REG_AL, TOKEN_TYPE_REG, STR_AL
