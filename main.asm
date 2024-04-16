format ELF64 executable

include 'sys_call.asm'
include 'helper.asm'
include 'hash_table.asm'
include 'symbols.asm'

segment readable executable
entry _start

init_def_sym_table:
    push rbp
    mov rsp, rbp
    mov rdi, DEF_SYM_HASH_TABLE
    mov esi, SIZE_HASH_DEF_SYM_TABLE
    call hash_table_init
    xor rdx, rdx
    cmp rax, rdx
    jne _start_loop_def_sym_init
    xor rax, rax
    jmp _exit_init_def_sym_table
_start_loop_def_sym_init:
    
_exit_init_def_sym_table:
    pop rbp
    ret

_start:
    call init_def_sym_table
    mov rdi, SIZE_HASH_DEF_SYM_TABLE
    call mmap_def
    xor rdx, rdx
    sub rdx, 1
    cmp rax, rdx
    jne _next_round
    mov rdi, MMAP_FAILED
    call print_str

_next_round:
    mov rdi, rax
    mov rsi, SIZE_HASH_DEF_SYM_TABLE
    call munmap
    xor rdx, rdx
    cmp rax, rdx
    je _end_start
    mov rdi, MUNMAP_FAILED
    call print_str
_end_start:
    exit_m 0

segment readable writeable
; hash table: ptr, count, capacity
; ptr point to array of pointers
DEF_SYM_HASH_TABLE dq 0
dd 0, 0

msg db "Hellow World", 10
db "lllallalalala", 10, 0
NEW_LINE db 10, 0
MMAP_FAILED db "mmap have failed", 0
MUNMAP_FAILED db "munmap have failed", 0
