

segment readable writeable

; entry
; 0 ptr to linked list of location to patch, +8 id in segment arr (4b),
; +16 symbol entry (round up to multible of 8, curr 16) (32b total)
; ptr, count in entries, capacity in entries, entry size
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


segment readable executable

init_parser_data:
    push rbp
    mov rbp, rsp
_end_init_parser_data:
    pop rbp
    ret
