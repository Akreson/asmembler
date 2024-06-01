format ELF64 executable

segment readable writeable

NEW_LINE db 10, 0

INVALID_HASH db "Invalid hash for: ", 0
MMAP_FAILED db "mmap have failed", 0
MUNMAP_FAILED db "munmap have failed", 0
DBL_DEF_SYM db "Dubled default symbol: ", 0
ERR_ADD_HT db "Error on adding entry to hash table", 0

; hash table: 0 ptr, +8 count, +12 capacity (in 8-byte ptr)
; ptr point to array of pointers
DEF_SYM_HASH_TABLE dq 0
dd 0, 0

include 'sys_call.asm'
include 'helper.asm'
include 'hash_table.asm'
include 'entry_array.asm'
include 'list.asm'
include 'files.asm'
include 'symbols.asm'
include 'lex.asm'
include 'parser.asm'

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
    mov rdi, [rbp-16]
    mov rsi, rax
    mov rdx, [rbp-8]
    call hash_table_add_entry 
    test rax, rax
    jnz _end_loop_init_def_sym
    mov rdi, ERR_ADD_HT
    call print_zero_str
    xor rax, rax
    jmp _exit_init_def_sym_table
_end_loop_init_def_sym:
    add qword [rbp-8], TOKEN_KIND_SIZE
    jmp _start_loop_init_def_sym
_exit_init_def_sym_table:
    ;mov rdi, DEF_SYM_HASH_TABLE
    ;call print_ht_sym_str
    add rsp, 28
    pop rbp
    ret

_start:
    mov rbp, rsp
    sub rsp, 40
    call init_def_sym_table
    test rax, rax
    jz _end_start
    call init_file_array
    test rax, rax
    jz _end_start
    call init_parser_data
    test rax, rax
    jz _end_start
    mov rax, [rbp]
    cmp rax, 2
    jb _end_start
    mov rdi, [rbp+16]
    call get_zero_str_len
    mov rdi, [rbp+16]
    mov rsi, rax
    mov [rbp-24], rdi
    mov [rbp-16], rsi
    call load_file_by_path
    test rax, rax
    jz _end_start
    mov dword [LAST_LINE_NUM], 1
    mov [rbp-8], rax
    mov rdi, rax
    mov esi, ebx
    call start_parser
_end_start:
    add rsp, 40
    exit_m 0

segment readable executable
_end_of_end:
    exit_m -1
