format ELF64 executable

BUILD_TYPE_EXE equ 1
BUILD_TYPE_OBJ equ 2
BUILD_TYPE_BIN equ 3

segment readable writeable

ENTRY_SYM_ARR_PTR dq 0
ENTRY_SYM_OFFSET dd 0
DEF_BASE_ADDR dd 0x400000
CURR_FILE_ENTRY_OFFSET dd 0
IS_ENTRY_DEFINED db 0
BUILD_TYPE db 0

include 'err_msg.asm'
include 'sys_call.asm'
include 'symbols.asm'
include 'entry_array.asm'
include 'hash_table.asm'
include 'list.asm'
include 'helper.asm'
include 'files.asm'
include 'lex.asm'
include 'parser.asm'
include 'render.asm'
include 'build.asm'

segment readable writeable
TEST_R db "./r.bin", 0
TEST_RW db "./rw.bin", 0
TEST_RX db "./rx.bin", 0

entry_array_data_m BUILD_ARR, 1
entry_array_data_m TEMP_COMMON_ARR, 1
hash_table_data_m DEF_SYM_HASH_TABLE, 1

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
    xor rdx, rdx
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
    mov rdi, ERR_INVALID_HASH
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
    mov rdi, ERR_DBL_DEF_SYM
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
    mov esi, 2048
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
    xor rdx, rdx
    call load_file_by_path
    test rax, rax
    jz _end_start
    mov dword [LAST_LINE_NUM], 1
    mov [rbp-8], rax
    mov rdi, rax
    mov esi, ebx
    call start_parser
    call parser_check_print_unk_name
    call start_render

    mov rdi, TEST_RW
    call open_file_w_trunc
    mov r8, [SEG_ENTRY_ARRAY]
    add r8, 384 
    mov rdi, rax
    mov rsi, [r8+20]
    mov edx, [r8+28]
    call write

    mov rdi, TEST_R
    call open_file_w_trunc
    mov r8, [SEG_ENTRY_ARRAY]
    add r8, 256
    mov rdi, rax
    mov rsi, [r8+20]
    mov edx, [r8+28]
    call write

    mov rdi, TEST_RX
    call open_file_w_trunc
    mov r8, [SEG_ENTRY_ARRAY]
    add r8, 320
    mov rdi, rax
    mov rsi, [r8+20]
    mov edx, [r8+28]
    call write
    mov rdi, BUILD_ARR
    mov rsi, 65536
    call init_entry_array
    mov dword [TEMP_COMMON_ARR+8], 0
_end_start:
    add rsp, 40
    exit_m 0

segment readable executable
_end_of_end:
    exit_m -1
