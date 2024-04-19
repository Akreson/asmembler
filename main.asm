format ELF64 executable

include 'sys_call.asm'
include 'helper.asm'
include 'hash_table.asm'
include 'symbols.asm'

segment readable executable
entry _start

init_def_sym_table:
    push rbp
    mov rbp, rsp
    sub rsp, 28
    mov qword [rbp-8], DEF_SYM_TABLE
    mov rdi, DEF_SYM_HASH_TABLE
    mov [rbp-16], rdi
    mov rsi, SIZE_HASH_DEF_SYM_TABLE
    call hash_table_init
    test rax, rax
    jnz _start_loop_init_def_sym
    xor rax, rax
    jmp _exit_init_def_sym_table
_start_loop_init_def_sym:
    mov r8, [rbp-8]
    mov rdi, [r8]
    test rdi, rdi
    jnz _calc_hash_init_def_sym_init
    movzx edx, byte [r8+12]
    test edx, edx
    jz _exit_init_def_sym_table 
    jmp _end_loop_init_def_sym
_calc_hash_init_def_sym_init:
    mov [rbp-24], rdi
    movzx esi, byte [r8+13]
    mov [rbp-28], esi
    call hash_str
    test eax, eax
    jnz _add_loop_init_def_sym
    mov rdi, INVALID_HASH
    call print_zero_str
    mov rdi, [rbp-24]
    mov esi, [rbp-28]
    call print_len_str
    mov rdi, NEW_LINE
    call print_zero_str
    jmp _end_loop_init_def_sym
_add_loop_init_def_sym:
    mov rdi, [rbp-16]
    mov rsi, [rbp-24]
    mov edx, [rbp-28]
    mov ecx, eax
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jz _add_init_def_sym 
    mov rdi, DBL_DEF_SYM
    push rbx
    call print_zero_str
    pop rbx
    mov rdi, [rbx]
    movzx esi, byte [rbx+13]
    call print_len_str
    mov rdi, NEW_LINE
    call print_zero_str
    xor rax, rax
    jmp _exit_init_def_sym_table
_add_init_def_sym:
    ; add symbol to ht
_end_loop_init_def_sym:
    add qword [rbp-8], TOKEN_KIND_SIZE
    jmp _start_loop_init_def_sym
_exit_init_def_sym_table:
    add rsp, 28
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
    ;call print_str

_next_round:
    mov rdi, rax
    mov rsi, SIZE_HASH_DEF_SYM_TABLE
    call munmap
    xor rdx, rdx
    cmp rax, rdx
    je _end_start
    mov rdi, MUNMAP_FAILED
    ;call print_str
_end_start:
    exit_m 0

segment readable writeable
; hash table: 0 ptr, +8 count, +12 capacity
; ptr point to array of pointers
DEF_SYM_HASH_TABLE dq 0
dd 0, 0

NEW_LINE db 10, 0
INVALID_HASH db "Invalid hash for: ", 0
MMAP_FAILED db "mmap have failed", 0
MUNMAP_FAILED db "munmap have failed", 0
DBL_DEF_SYM db "Dubled default symbol: ", 0
