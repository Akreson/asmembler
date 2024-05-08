

segment readable writeable

; entry
; 0 ptr to linked list of location to patch, +8 id in segment arr (4b),
; +16 symbol entry (round up to multible of 8, curr 16) (32b total)
; ptr, count in entries, capacity in entries, entry size

NAME_SYM_HASH_TABLE dq 0,
dd 0, 0

UNKNOWN_NAME_SYM_REF_ARRAY dq 0,
dd 0, 0, 32


; entry
; 0 data size, +4 id in segment arr, +4 offset in file, +4 line num in file
; +16 symbol entry (roud up), (header size 32b)
; +16 start of data in _token buff_ format
NAME_SYM_REF_ARRAY dq 0,
dd 0, 0, 1

; entry - 0 ptr to tokens byff, +8 file array id, +12 mod (4b) (16b total)
SEG_ENTRY_ARRAY dq 0,
dd 0, 0

; token buff
; (header)
; 0(4) offset in render buff, +4(4) line num, +8(2) offset on line, +10(2) entry size in byte
; (body) 
; +12(1) token type, +13 [(8) ptr ot token | (TOKEN_KIND_SIZE) token body] ... (n times)


segment readable executable

init_parser_data:
    push rbp
    mov rbp, rsp
_end_init_parser_data:
    pop rbp
    ret
