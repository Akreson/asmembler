TOKEN_TYPE_NONE    equ 0
TOKEN_TYPE_KEYWORD equ 1
TOKEN_TYPE_INS     equ 2
TOKEN_TYPE_REG     equ 3
TOKEN_TYPE_AUX     equ 4
TOKEN_TYPE_NAME    equ 5
TOKEN_TYPE_DIGIT   equ 6
TOKEN_TYPE_STR     equ 7
TOKEN_TYPE_EOF     equ 8
TOKEN_TYPE_EXT_REF equ 9

TOKEN_NAME_NONE      equ 0
TOKEN_NAME_CONST     equ 0x01
TOKEN_NAME_CONST_MUT equ 0x02
TOKEN_NAME_JMP       equ 0x03
TOKEN_NAME_DATA      equ 0x04
TOKEN_NAME_MACRO     equ 0x05

SYM_REF_MASK_REF   equ 0x0F
SYM_REF_MASK_EXT   equ 0xF0
SYM_REF_MOD_NONE   equ 0
SYM_REF_MOD_EXTRN  equ 0x01
SYM_REF_MOD_PUBLIC equ 0x02
SYM_REF_EXT_ENTRY  equ 0x10

REG_REX_TH        equ 0x08
REG_REX_MASK      equ 0x80
REG_MASK_REG_VAL  equ 0x0F
REG_MASK_REG_IDX  equ 0x07
REG_MASK_BITS     equ 0x70
REG_MASK_DEF_NORM equ 0xF7
REG_MASK_VAL_8B   equ 0
REG_MASK_VAL_16B  equ 0x10
REG_MASK_VAL_32B  equ 0x20
REG_MASK_VAL_64B  equ 0x30
REG_MASK_VAL_UNSPEC equ 0xF0
REG_MASK_VAL_SHIFT_NORM equ 4

REG_AL   equ 0x00
REG_CL   equ 0x01
REG_DL   equ 0x02
REG_BL   equ 0x03
REG_AH   equ 0x04
REG_CH   equ 0x05
REG_DH   equ 0x06
REG_BH   equ 0x07
REG_SPL  equ 0x84
REG_BPL  equ 0x85
REG_SIL  equ 0x86
REG_DIL  equ 0x87
REG_R8B  equ 0x88
REG_R9B  equ 0x89
REG_R10B equ 0x8A
REG_R11B equ 0x8B
REG_R12B equ 0x8C
REG_R13B equ 0x8D
REG_R14B equ 0x8E
REG_R15B equ 0x8F

REG_AX   equ 0x10
REG_CX   equ 0x11
REG_DX   equ 0x12
REG_BX   equ 0x13
REG_SP   equ 0x14
REG_BP   equ 0x15
REG_SI   equ 0x16
REG_DI   equ 0x17
REG_R8W  equ 0x98
REG_R9W  equ 0x99
REG_R10W equ 0x9A
REG_R11W equ 0x9B
REG_R12W equ 0x9C
REG_R13W equ 0x9D
REG_R14W equ 0x9E
REG_R15W equ 0x9F

REG_EAX  equ 0x20
REG_ECX  equ 0x21
REG_EDX  equ 0x22
REG_EBX  equ 0x23
REG_ESP  equ 0x24
REG_EBP  equ 0x25
REG_ESI  equ 0x26
REG_EDI  equ 0x27
REG_R8D  equ 0xA8
REG_R9D  equ 0xA9
REG_R10D equ 0xAA
REG_R11D equ 0xAB
REG_R12D equ 0xAC
REG_R13D equ 0xAD
REG_R14D equ 0xAE
REG_R15D equ 0xAF

REG_RAX equ 0xB0
REG_RCX equ 0xB1
REG_RDX equ 0xB2
REG_RBX equ 0xB3
REG_RSP equ 0xB4
REG_RBP equ 0xB5
REG_RSI equ 0xB6
REG_RDI equ 0xB7
REG_R8  equ 0xB8
REG_R9  equ 0xB9
REG_R10 equ 0xBA
REG_R11 equ 0xBB
REG_R12 equ 0xBC
REG_R13 equ 0xBD
REG_R14 equ 0xBE
REG_R15 equ 0xBF

;TODO: mov type token val to msb bits
PREF_INS_TYPE_MASK      equ 0x08000000
INS_JMP_TYPE_MASK       equ 0x04000000
INS_CMOVCC_TYPE_MASK    equ 0x02000000
INS_ZERO_ARG_MASK       equ 0x01000000
INS_JMP_JCC_TYPE_MASK   equ 0x00800000
INS_CAN_HAS_PREFIX_MASK equ 0x00400000

;STR_REPS
;INS_REP   equ 0x18000000
INS_MOV   equ 0x10000001
INS_MOVSB equ 0x11400002
INS_MOVSW equ 0x11400003
INS_MOVSD equ 0x11400004
INS_MOVSQ equ 0x11400005
INS_MOVZX equ 0x10000006
INS_MOVSX equ 0x10000007
INS_LEA   equ 0x10000008
INS_RET   equ 0x11000009
INS_POP   equ 0x1000000A
INS_PUSH  equ 0x1000000B
INS_INC   equ 0x1040000C
INS_DEC   equ 0x1040000D
INS_AND   equ 0x1040000E
INS_OR    equ 0x1040000F
INS_XOR   equ 0x10400010
INS_ADD   equ 0x10400011
INS_SHL   equ 0x10000012
INS_SAL   equ 0x10000013
INS_SHR   equ 0x10000014
INS_SAR   equ 0x10000015
INS_SUB   equ 0x10400016
INS_DIV   equ 0x10000017
INS_IDIV  equ 0x10000018
INS_MUL   equ 0x10000019
INS_IMUL  equ 0x1000001A
INS_TEST  equ 0x1000001B
INS_BSR   equ 0x1000001C
INS_BSF   equ 0x1000001D
INS_TZCNT equ 0x1000001E
INS_LZCNT equ 0x1000001F
INS_CMP   equ 0x10000020
INS_CALL  equ 0x14000021
INS_JMP   equ 0x14000022
; NOTE: order of jcc ins. must not be changed
INS_JO    equ 0x14800023
INS_JNO   equ 0x14800024
INS_JB    equ 0x14800025
INS_JAE   equ 0x14800026
INS_JE    equ 0x14800027
INS_JNE   equ 0x14800028
INS_JBE   equ 0x14800029
INS_JA    equ 0x1480002A
INS_JS    equ 0x1480002B
INS_JNS   equ 0x1480002C
INS_JP    equ 0x1480002D
INS_JNP   equ 0x1480002E
INS_JL    equ 0x1480002F
INS_JGE   equ 0x14800030
INS_JLE   equ 0x14800031
INS_JG    equ 0x14800032
INS_JCXZ  equ 0x14800033
INS_NEG   equ 0x10400034
INS_NOT   equ 0x10400035
; NOTE: order of cmovcc ins. must not be changed
INS_CMOVO   equ 0x12000036
INS_CMOVNO  equ 0x12000037
INS_CMOVB   equ 0x12000038
INS_CMOVAE  equ 0x12000039
INS_CMOVE   equ 0x1200003A
INS_CMOVNE  equ 0x1200003B
INS_CMOVBE  equ 0x1200003C
INS_CMOVA   equ 0x1200003D
INS_CMOVS   equ 0x1200003E
INS_CMOVNS  equ 0x1200003F
INS_CMOVP   equ 0x12000040
INS_CMOVNP  equ 0x12000041
INS_CMOVL   equ 0x12000042
INS_CMOVGE  equ 0x12000043
INS_CMOVLE  equ 0x12000044
INS_CMOVG   equ 0x12000045
; NOTE: order of rep* ins. must not be changed
INS_REP   equ 0x18000046
INS_REPE  equ 0x18000047
INS_REPZ  equ 0x18000048
INS_REPNE equ 0x18000049
INS_REPNZ equ 0x1800004A
INS_LOCK  equ 0x1800004B
; NOTE: order of stos* ins. must not be changed
INS_STOSB   equ 0x1140004C
INS_STOSW   equ 0x1140004D
INS_STOSD   equ 0x1140004E
INS_STOSQ   equ 0x1140004F
INS_MOVSXD  equ 0x10000050
INS_SYSCALL equ 0x11000051
INS_INT     equ 0x10000052
INS_INT3    equ 0x11000053
INS_INT1    equ 0x11000054
INS_RDTSC   equ 0x11000055
INS_POPCNT  equ 0x10000056

AUX_COLON     equ 0x20000000
AUX_LPAREN    equ 0x20000001
AUX_RPAREN    equ 0x20000002
AUX_LBRACE    equ 0x20000003
AUX_RBRACE    equ 0x20000004
AUX_LBRACKET  equ 0x20000005
AUX_RBRACKET  equ 0x20000006
AUX_COMMA     equ 0x20000007
AUX_DOT       equ 0x20000008
AUX_SEMICOLON equ 0x20000009
AUX_MOD       equ 0x2000000A
AUX_ADD       equ 0x2000000B
AUX_SUB       equ 0x2000000C
AUX_MUL       equ 0x2000000D
AUX_DQM       equ 0x2000000E
AUX_QM        equ 0x2000000F
AUX_NEW_LINE  equ 0x20000010
AUX_ATSIGN    equ 0x20000011

ADDR_QUL_TYPE_MASK equ 0x34000000
DATA_QUL_TYPE_MASK equ 0x32000000
SEC_SEG_TYPE_MOD_MASK equ 0x38000000
SEC_SEG_VAL_MOD_MASK equ 0xFF
IS_SEC_USER_DEF_MASK equ 0x00001000
SEC_INDEX_MASK equ 0x000000FF
SEC_ATTR_MASK equ 0x000F0000
SEC_ATTR_RIGHTS_MASK equ 0x00070000
SEC_ATTR_SEC_FLAG_MASK equ 0x0000E000
SEC_ATTR_RIGHTS_SHIFT equ 16
SEC_ATTR_SEC_FLAG_SHIFT equ 13

KW_DB      equ 0x32000000
KW_DW      equ 0x32000007
KW_DD      equ 0x32000008
KW_DQ      equ 0x32000003
KW_EQU     equ 0x30000009
KW_SEGMT   equ 0x30000005
KW_SECT    equ 0x30000006
KW_RDBL    equ 0x38000004
KW_WRTB    equ 0x38000002
KW_EXTB    equ 0x38000001
KW_INCL    equ 0x3000000A
KW_MACR    equ 0x3000000B
KW_ENTRY   equ 0x3000000C
KW_BYTE    equ 0x3400000D
KW_WORD    equ 0x3400000E
KW_DWORD   equ 0x3400000F
KW_QWORD   equ 0x34000010
KW_EXTRN   equ 0x30000011
KW_PUBLIC  equ 0x30000012
KW_DUP     equ 0x30000013
KW_FORMAT  equ 0x30000014
KW_F_BIN   equ 0x30000015
KW_F_ELF64 equ 0x30000016
KW_SEC_RODATA   equ 0x30045404
KW_SEC_TEXT     equ 0x3005D405
KW_SEC_DATA     equ 0x30067406
KW_SEC_DEBUG    equ 0x30000408
; NOTE: rel. sec. group must be before sections that can have rel entries
KW_SEC_RELA     equ 0x30040410
KW_SEC_SYMTAB   equ 0x30000420
KW_SEC_STRTAB   equ 0x30000421
KW_SEC_SHSTRTAB equ 0x30000422

TOKEN_KIND_SIZE equ 14
SIZE_HASH_DEF_SYM_TABLE equ 2048

segment readable

STR_AL   db "al"
STR_CL   db "cl"
STR_DL   db "dl"
STR_BL   db "bl"
STR_AH   db "ah"
STR_CH   db "ch"
STR_DH   db "dh"
STR_BH   db "bh"
STR_SPL  db "spl"
STR_BPL  db "bpl"
STR_SIL  db "sil"
STR_DIL  db "dil"
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

STR_MOV   db "mov"
STR_MOVSB db "movsb"
STR_MOVSW db "movsw"
STR_MOVSD db "movsd"
STR_MOVSQ db "movsq"
STR_STOSB db "stosb"
STR_STOSW db "stosw"
STR_STOSD db "stosd"
STR_STOSQ db "stosq"
STR_MOVZX db "movzx"
STR_MOVSX db "movsx"
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
STR_SHL   db "shl"
STR_SAL   db "sal"
STR_SHR   db "shr"
STR_SAR   db "sar"
STR_SUB   db "sub"
STR_DIV   db "div"
STR_IDIV  db "idiv"
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
STR_JA    db "ja"
STR_JNBE  db "jnbe"
STR_JAE   db "jae"
STR_JNB   db "jnb"
STR_JNC   db "jnc"
STR_JB    db "jb"
STR_JC    db "jc"
STR_JNAE  db "jnae"
STR_JBE   db "jbe"
STR_JNA   db "jna"
STR_JCXZ  db "jcxz"
STR_JECXZ db "jecxz"
STR_JRCXZ db "jrcxz"
STR_JE    db "je"
STR_JZ    db "jz"
STR_JG    db "jg"
STR_JNLE  db "jnle"
STR_JGE   db "jge"
STR_JNL   db "jnl"
STR_JL    db "jl"
STR_JNGE  db "jnge"
STR_JLE   db "jle"
STR_JNG   db "jng"
STR_JNE   db "jne"
STR_JNZ   db "jnz"
STR_JNO   db "jno"
STR_JNP   db "jnp"
STR_JPO   db "jpo"
STR_JNS   db "jns"
STR_JO    db "jo"
STR_JP    db "jp"
STR_JPE   db "jpe"
STR_JS    db "js"
STR_NEG   db "neg"
STR_NOT   db "not"
STR_MOVSXD  db "movsxd"
STR_CMOVO   db "cmovo"
STR_CMOVNO  db "cmovno"
STR_CMOVB   db "cmovb"
STR_CMOVC   db "cmovc"
STR_CMOVNAE db "cmovnae"
STR_CMOVAE  db "cmovae"
STR_CMOVNB  db "cmovnb"
STR_CMOVNC  db "cmovnc"
STR_CMOVE   db "cmove"
STR_CMOVZ   db "cmovz"
STR_CMOVNE  db "cmovne"
STR_CMOVNZ  db "cmovnz"
STR_CMOVBE  db "cmovbe"
STR_CMOVNA  db "cmovna"
STR_CMOVA   db "cmova"
STR_CMOVNBE db "cmovnbe"
STR_CMOVS   db "cmovs"
STR_CMOVNS  db "cmovns"
STR_CMOVP   db "cmovp"
STR_CMOVPE  db "cmovpe"
STR_CMOVNP  db "cmovnp"
STR_CMOVPO  db "cmovpo"
STR_CMOVL   db "cmovl"
STR_CMOVNGE db "cmovnge"
STR_CMOVGE  db "cmovge"
STR_CMOVNL  db "cmovnl"
STR_CMOVLE  db "cmovle"
STR_CMOVNG  db "cmovng"
STR_CMOVG   db "cmovg"
STR_CMOVNLE db "cmovnle"
STR_SYSCALL db "syscall"
STR_INT     db "int"
STR_INT3    db "int3"
STR_INT1    db "int1"
STR_RDTSC   db "rdtsc"
STR_POPCNT  db "popcnt"

STR_REP   db "rep"
STR_REPE  db "repe"
STR_REPZ  db "repz"
STR_REPNE db "repne"
STR_REPNZ db "repnz"
STR_LOCK  db "lock"

STR_KW_DB db "db"
STR_KW_DW db "dw"
STR_KW_DD db "dd"
STR_KW_DQ db "dq"
STR_KW_EQU db "equ"
STR_KW_SEGMT db "segment"
STR_KW_SECT db "section"
STR_KW_RDBL db "readable"
STR_KW_WRTB db "writeable"
STR_KW_EXTB db "executable"
STR_KW_INCL db "include"
STR_KW_MACR db "macro"
STR_KW_ENTRY db "entry"
STR_KW_BYTE db "byte"
STR_KW_WORD db "word"
STR_KW_DWORD db "dword"
STR_KW_QWORD db "qword"
STR_KW_EXTRN db "extrn"
STR_KW_PUBLIC db "public"
STR_KW_DUP db "dup"
STR_KW_FORMAT db "format"
STR_KW_F_BIN db "binary"
STR_KW_F_ELF64 db "ELF64"
STR_SEC_RELA db ".rela"
STR_SEC_TEXT db ".text"
STR_SEC_DATA db ".data"
STR_SEC_DEBUG db ".debug"
STR_SEC_RODATA db ".rodata"
STR_SEC_SYMTAB db ".symtab"
STR_SEC_STRTAB db ".strtab"
STR_SEC_SHSTRTAB db ".shstrtab"


_STR_SPACE db 0x20
_STR_TAB   db 0x09
_CONST_SPACE     equ 0x20
_CONST_TAB       equ 0x20
_CONST_DQM       equ 0x22
_CONST_QM        equ 0x27
_CONST_SEMICOLON equ 0x3B
_CONST_NEW_LINE  equ 0xA
_CONST_SLASH     equ 0x2F

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
    ; 0, +8, +12, +13, (+14, +15)
    dq str_ptr; / general prt to struct / digit container
    dd value ; len for TOKEN_TYPE_STR
    db type
    db str_len; last set bit for TOKEN_TYPE_DIGIT
    ; (only for _name_ type token in memory)
    ;db name type (only for _name_ type token in memory)
    ;db name mod
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
def_symbol_m REG_SPL, TOKEN_TYPE_REG, STR_SPL, 3
def_symbol_m REG_BPL, TOKEN_TYPE_REG, STR_BPL, 3
def_symbol_m REG_SIL, TOKEN_TYPE_REG, STR_SIL, 3
def_symbol_m REG_DIL, TOKEN_TYPE_REG, STR_DIL, 3
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
def_symbol_m INS_REPE, TOKEN_TYPE_INS, STR_REPE, 4
def_symbol_m INS_REPZ, TOKEN_TYPE_INS, STR_REPZ, 4
def_symbol_m INS_REPNE, TOKEN_TYPE_INS, STR_REPNE, 5
def_symbol_m INS_REPNZ, TOKEN_TYPE_INS, STR_REPNZ, 5
def_symbol_m INS_LOCK, TOKEN_TYPE_INS, STR_LOCK, 4

def_symbol_m INS_MOV, TOKEN_TYPE_INS, STR_MOV, 3
def_symbol_m INS_MOVSB, TOKEN_TYPE_INS, STR_MOVSB, 5
def_symbol_m INS_MOVSW, TOKEN_TYPE_INS, STR_MOVSW, 5
def_symbol_m INS_MOVSD, TOKEN_TYPE_INS, STR_MOVSD, 5
def_symbol_m INS_MOVSQ, TOKEN_TYPE_INS, STR_MOVSQ, 5
def_symbol_m INS_STOSB, TOKEN_TYPE_INS, STR_STOSB, 5
def_symbol_m INS_STOSW, TOKEN_TYPE_INS, STR_STOSW, 5
def_symbol_m INS_STOSD, TOKEN_TYPE_INS, STR_STOSD, 5
def_symbol_m INS_STOSQ, TOKEN_TYPE_INS, STR_STOSQ, 5
def_symbol_m INS_MOVZX, TOKEN_TYPE_INS, STR_MOVZX, 5
def_symbol_m INS_MOVSX, TOKEN_TYPE_INS, STR_MOVSX, 5
def_symbol_m INS_MOVSXD, TOKEN_TYPE_INS, STR_MOVSXD, 6 
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
def_symbol_m INS_IDIV, TOKEN_TYPE_INS, STR_IDIV, 4
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

def_symbol_m INS_JA, TOKEN_TYPE_INS, STR_JA, 2
def_symbol_m INS_JA, TOKEN_TYPE_INS, STR_JNBE, 4
def_symbol_m INS_JAE, TOKEN_TYPE_INS, STR_JAE, 3
def_symbol_m INS_JAE, TOKEN_TYPE_INS, STR_JNB, 3
def_symbol_m INS_JAE, TOKEN_TYPE_INS, STR_JNC, 3
def_symbol_m INS_JB, TOKEN_TYPE_INS, STR_JB, 2
def_symbol_m INS_JB, TOKEN_TYPE_INS, STR_JC, 2
def_symbol_m INS_JB, TOKEN_TYPE_INS, STR_JNAE, 4
def_symbol_m INS_JBE, TOKEN_TYPE_INS, STR_JBE, 3
def_symbol_m INS_JBE, TOKEN_TYPE_INS, STR_JNA, 3
def_symbol_m INS_JCXZ, TOKEN_TYPE_INS, STR_JCXZ, 4
def_symbol_m INS_JCXZ, TOKEN_TYPE_INS, STR_JECXZ, 5
def_symbol_m INS_JCXZ, TOKEN_TYPE_INS, STR_JRCXZ, 5
def_symbol_m INS_JE, TOKEN_TYPE_INS, STR_JE, 2
def_symbol_m INS_JE, TOKEN_TYPE_INS, STR_JZ, 2
def_symbol_m INS_JG, TOKEN_TYPE_INS, STR_JG, 2
def_symbol_m INS_JG, TOKEN_TYPE_INS, STR_JNLE, 4
def_symbol_m INS_JGE, TOKEN_TYPE_INS, STR_JGE, 3
def_symbol_m INS_JGE, TOKEN_TYPE_INS, STR_JNL, 3
def_symbol_m INS_JL, TOKEN_TYPE_INS, STR_JL, 2
def_symbol_m INS_JL, TOKEN_TYPE_INS, STR_JNGE, 4
def_symbol_m INS_JLE, TOKEN_TYPE_INS, STR_JLE, 3
def_symbol_m INS_JLE, TOKEN_TYPE_INS, STR_JNG, 3
def_symbol_m INS_JNE, TOKEN_TYPE_INS, STR_JNE, 3
def_symbol_m INS_JNE, TOKEN_TYPE_INS, STR_JNZ, 3
def_symbol_m INS_JNO, TOKEN_TYPE_INS, STR_JNO, 3
def_symbol_m INS_JNP, TOKEN_TYPE_INS, STR_JNP, 3
def_symbol_m INS_JNP, TOKEN_TYPE_INS, STR_JPO, 3
def_symbol_m INS_JNS, TOKEN_TYPE_INS, STR_JNS, 3
def_symbol_m INS_JO, TOKEN_TYPE_INS, STR_JO, 2
def_symbol_m INS_JP, TOKEN_TYPE_INS, STR_JP, 2
def_symbol_m INS_JP, TOKEN_TYPE_INS, STR_JPE, 3
def_symbol_m INS_JS, TOKEN_TYPE_INS, STR_JS, 2

def_symbol_m INS_NEG, TOKEN_TYPE_INS, STR_NEG, 3
def_symbol_m INS_NOT, TOKEN_TYPE_INS, STR_NOT, 3

def_symbol_m INS_CMOVO, TOKEN_TYPE_INS, STR_CMOVO, 5
def_symbol_m INS_CMOVNO, TOKEN_TYPE_INS, STR_CMOVNO, 6
def_symbol_m INS_CMOVB, TOKEN_TYPE_INS, STR_CMOVB, 5
def_symbol_m INS_CMOVB, TOKEN_TYPE_INS, STR_CMOVC, 5
def_symbol_m INS_CMOVB, TOKEN_TYPE_INS, STR_CMOVNAE, 7
def_symbol_m INS_CMOVAE, TOKEN_TYPE_INS, STR_CMOVAE, 6
def_symbol_m INS_CMOVAE, TOKEN_TYPE_INS, STR_CMOVNB, 6
def_symbol_m INS_CMOVAE, TOKEN_TYPE_INS, STR_CMOVNC, 6
def_symbol_m INS_CMOVE, TOKEN_TYPE_INS, STR_CMOVE, 5
def_symbol_m INS_CMOVE, TOKEN_TYPE_INS, STR_CMOVZ, 5
def_symbol_m INS_CMOVNE, TOKEN_TYPE_INS, STR_CMOVNE, 6
def_symbol_m INS_CMOVNE, TOKEN_TYPE_INS, STR_CMOVNZ, 6
def_symbol_m INS_CMOVBE, TOKEN_TYPE_INS, STR_CMOVBE, 6
def_symbol_m INS_CMOVBE, TOKEN_TYPE_INS, STR_CMOVNA, 6
def_symbol_m INS_CMOVA, TOKEN_TYPE_INS, STR_CMOVA, 5
def_symbol_m INS_CMOVA, TOKEN_TYPE_INS, STR_CMOVNBE, 7
def_symbol_m INS_CMOVS, TOKEN_TYPE_INS, STR_CMOVS, 5
def_symbol_m INS_CMOVNS, TOKEN_TYPE_INS, STR_CMOVNS, 6
def_symbol_m INS_CMOVP, TOKEN_TYPE_INS, STR_CMOVP, 5
def_symbol_m INS_CMOVP, TOKEN_TYPE_INS, STR_CMOVPE, 6
def_symbol_m INS_CMOVNP, TOKEN_TYPE_INS, STR_CMOVNP, 6
def_symbol_m INS_CMOVNP, TOKEN_TYPE_INS, STR_CMOVPO, 6
def_symbol_m INS_CMOVL, TOKEN_TYPE_INS, STR_CMOVL, 5
def_symbol_m INS_CMOVL, TOKEN_TYPE_INS, STR_CMOVNGE, 7
def_symbol_m INS_CMOVGE, TOKEN_TYPE_INS, STR_CMOVGE, 6
def_symbol_m INS_CMOVGE, TOKEN_TYPE_INS, STR_CMOVNL, 6
def_symbol_m INS_CMOVLE, TOKEN_TYPE_INS, STR_CMOVLE, 6
def_symbol_m INS_CMOVLE, TOKEN_TYPE_INS, STR_CMOVNG, 6
def_symbol_m INS_CMOVG, TOKEN_TYPE_INS, STR_CMOVG, 5
def_symbol_m INS_CMOVG, TOKEN_TYPE_INS, STR_CMOVNLE, 7
def_symbol_m INS_SYSCALL, TOKEN_TYPE_INS, STR_SYSCALL, 7
def_symbol_m INS_INT, TOKEN_TYPE_INS, STR_INT, 3
def_symbol_m INS_INT3, TOKEN_TYPE_INS, STR_INT3, 4
def_symbol_m INS_INT1, TOKEN_TYPE_INS, STR_INT1, 4
def_symbol_m INS_RDTSC, TOKEN_TYPE_INS, STR_RDTSC, 5
def_symbol_m INS_POPCNT, TOKEN_TYPE_INS, STR_POPCNT, 6

def_symbol_m KW_DB, TOKEN_TYPE_KEYWORD, STR_KW_DB, 2
def_symbol_m KW_DW, TOKEN_TYPE_KEYWORD, STR_KW_DW, 2
def_symbol_m KW_DD, TOKEN_TYPE_KEYWORD, STR_KW_DD, 2
def_symbol_m KW_DQ, TOKEN_TYPE_KEYWORD, STR_KW_DQ, 2
def_symbol_m KW_EQU, TOKEN_TYPE_KEYWORD, STR_KW_EQU, 3
def_symbol_m KW_SEGMT, TOKEN_TYPE_KEYWORD, STR_KW_SEGMT, 7
def_symbol_m KW_SECT, TOKEN_TYPE_KEYWORD, STR_KW_SECT, 7
def_symbol_m KW_RDBL, TOKEN_TYPE_KEYWORD, STR_KW_RDBL, 8
def_symbol_m KW_WRTB, TOKEN_TYPE_KEYWORD, STR_KW_WRTB, 9
def_symbol_m KW_EXTB, TOKEN_TYPE_KEYWORD, STR_KW_EXTB, 10
def_symbol_m KW_INCL, TOKEN_TYPE_KEYWORD, STR_KW_INCL, 7
def_symbol_m KW_MACR, TOKEN_TYPE_KEYWORD, STR_KW_MACR, 5
def_symbol_m KW_ENTRY, TOKEN_TYPE_KEYWORD, STR_KW_ENTRY, 5
def_symbol_m KW_BYTE, TOKEN_TYPE_KEYWORD, STR_KW_BYTE, 4
def_symbol_m KW_WORD, TOKEN_TYPE_KEYWORD, STR_KW_WORD, 4
def_symbol_m KW_DWORD, TOKEN_TYPE_KEYWORD, STR_KW_DWORD, 5
def_symbol_m KW_QWORD, TOKEN_TYPE_KEYWORD, STR_KW_QWORD, 5
def_symbol_m KW_EXTRN, TOKEN_TYPE_KEYWORD, STR_KW_EXTRN, 5
def_symbol_m KW_PUBLIC, TOKEN_TYPE_KEYWORD, STR_KW_PUBLIC, 6
def_symbol_m KW_DUP, TOKEN_TYPE_KEYWORD, STR_KW_DUP, 3
def_symbol_m KW_FORMAT, TOKEN_TYPE_KEYWORD, STR_KW_FORMAT, 6
def_symbol_m KW_F_BIN, TOKEN_TYPE_KEYWORD, STR_KW_F_BIN, 6
def_symbol_m KW_F_ELF64, TOKEN_TYPE_KEYWORD, STR_KW_F_ELF64, 5

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

; NOTE: don't change location, parser relays on it
SEC_NAME_OFFSET_FROM_DUMMY equ 266
def_symbol_m KW_SEC_TEXT, TOKEN_TYPE_KEYWORD, STR_SEC_TEXT, 5
def_symbol_m KW_SEC_DATA, TOKEN_TYPE_KEYWORD, STR_SEC_DATA, 5
def_symbol_m KW_SEC_RODATA, TOKEN_TYPE_KEYWORD, STR_SEC_RODATA, 7
def_symbol_m KW_SEC_DEBUG, TOKEN_TYPE_KEYWORD, STR_SEC_DEBUG, 6
; NOTE: rel. must be before sec. that can has rel. entries
def_symbol_m KW_SEC_RELA, TOKEN_TYPE_KEYWORD, STR_SEC_RELA, 5
def_symbol_m KW_SEC_SYMTAB, TOKEN_TYPE_KEYWORD, STR_SEC_SYMTAB, 7
def_symbol_m KW_SEC_STRTAB, TOKEN_TYPE_KEYWORD, STR_SEC_STRTAB, 7
def_symbol_m KW_SEC_SHSTRTAB, TOKEN_TYPE_KEYWORD, STR_SEC_SHSTRTAB, 9

def_symbol_m 0, 0, 0, 0
