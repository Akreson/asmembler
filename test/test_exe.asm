format ELF64 executable

include '../err_msg.asm'
include '../sys_call.asm'
include '../symbols.asm'

segment readable writeable
HT_MAIN_BLOCK_SIZE equ 17
FNV_PRIME equ 16777619
FNV_OFFSET equ 2166136261

;0 ptr to buff, +8 count, +12 capacity, +16 is realloc allowed (20b) 
macro hash_table_data_m name, is_allow_realloc
{
    name dq 0
    dd 0, 0
    db is_allow_realloc
}
hash_table_data_m DEF_SYM_HASH_TABLE, 1

segment readable
NEW_LINE db 10, 0
DIGIT_MAP db "0123456789ABCDEF", 0

MIN_INT8 equ 0x80
MAX_INT8 equ 0x7F

MIN_INT32 equ 0x80000000
MAX_INT32 equ 0x7FFFFFFF

segment readable executable

log2_val_ceil:
    xor rax, rax
    test rdi, rdi
    jz _end_log2_val_ceil
    cmp rdi, 1
    je _end_log2_val_ceil
    dec rdi
    bsr rax, rdi
    inc rax
_end_log2_val_ceil:
    ret

; rdi - val to align, rsi - pow2 align to
; return rax - aligned val
align_to_pow2:
    mov rax, rdi
    mov r8, rsi
    dec r8
    and rdi, r8
    test rdi, rdi
    jz _end_align_to_pow2
    sub rsi, rdi
    add rax, rsi
_end_align_to_pow2:
    ret

print_new_line:
    push rbp
    mov rsi, NEW_LINE
    mov rdx, 1
    write_m STD_OUT, rsi, rdx
    pop rbp
    ret

;rdi - string ptr
print_zero_str:
    push rbp
    test rdi, rdi
    jz _end_print_str
    push rdi
    call get_zero_str_len
    pop rdi
    test rax, rax
    jz _end_print_str 
    mov rsi, rdi
    mov rdx, rax
    write_m STD_OUT, rsi, rdx
_end_print_str:
    pop rbp
    ret

;rdi - string ptr
get_zero_str_len:
    push rbp
    test rdi, rdi
    jz _end_get_zero_len
    xor rax, rax
_loop_get_zero_len:
    movzx ebx, byte [rdi]
    test ebx, ebx
    jz _end_get_zero_len
    inc rax
    inc rdi
    jmp _loop_get_zero_len
_end_get_zero_len:
    pop rbp
    ret

;rdi - string ptr, rsi - len
print_len_str:
    push rbp
    test rdi, rdi
    jz _end_print_len_str
    test rsi, rsi
    jz _end_print_len_str
_loop_print_len_str:
    mov rdx, rsi
    mov rsi, rdi
    write_m STD_OUT, rsi, rdx
_end_print_len_str:
    pop rbp
    ret

;TODO: save rdx for 3rd param
;rdi - digit, rsi - base
print_u_digit:
    push rbp
    mov rbp, rsp
    sub rsp, 144
    mov rax, 2
    mov rbx, rax
    shl rbx, 3
    mov r8, 10
    mov r9, 8
    cmp rsi, rax
    je _begin_loop_print_digit
    cmp rsi, rbx
    je _begin_loop_print_digit
    cmp rsi, r8
    je _begin_loop_print_digit
    cmp rsi, r9
    je _begin_loop_print_digit
    mov rdi, ERR_PRINT_BASE
    call print_zero_str
    jmp _end_print_digit
_begin_loop_print_digit:
    mov rcx, rbp
    dec rcx
    mov rax, rdi
    xor rdi, rdi
    mov [rcx], dil 
    mov rbx, DIGIT_MAP
_loop_print_digit:
    xor rdx, rdx
    div rsi
    mov r8b, [rbx + rdx*1]
    dec rcx
    mov [rcx], r8b
    cmp rax, rdi
    je _write_print_digit
    jmp _loop_print_digit
_write_print_digit:
    mov rdi, rcx
    call print_zero_str
_end_print_digit:
    add rsp, 144
    pop rbp
    ret

;rdi - ptr to ht main block
print_ht_sym_str:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov r8, [rdi]
    mov r9, r8
    mov [rbp-8], r8
    mov ebx, [rdi+12]
    shl ebx, 3
    add r9, rbx
    mov [rbp-16], r9
_loop_start_phtss:
    mov r8, [rbp-8]
    mov r9, [rbp-16]
    cmp r8, r9
    jae _end_print_ht_sym_str
    mov rbx, [r8]
    add r8, 8
    mov [rbp-8], r8
    test rbx, rbx
    jz _loop_start_phtss
    mov [rbp-24], rbx
    mov rdi, [rbp-8]
    sub rdi, 8
    mov rsi, 16
    call print_u_digit
    call print_new_line
    mov rbx, [rbp-24]
    mov rdi, [rbx]
    movzx esi, byte [rbx+13]
    call print_len_str
    call print_new_line
    call print_new_line
    jmp _loop_start_phtss
_end_print_ht_sym_str:
    add rsp, 24
    pop rbp
    ret

segment readable executable
entry _start


;rdi - ptr to str, esi - str len
hash_str:
    push rbp
    mov rbp, rsp
    xor rax, rax
    test rdi, rdi
    jz _end_hash_str
    test esi, esi
    jz _end_hash_str
    mov r8d, FNV_PRIME
    mov eax, FNV_OFFSET
    mov rbx, rdi
    add rbx, rsi
_loop_hash_str:
    movzx ecx, byte [rdi]
    xor eax, ecx
    xor edx, edx
    mul r8d
    inc rdi
    cmp rdi, rbx
    jb _loop_hash_str
_end_hash_str:
    pop rbp
    ret

;table stores ptr to sym table entry
;rdi - ptr to hash table main block, rsi - ptr to str, edx - str len, ecx - hash of str
;return pointer to entry [entry] -> zero | ptr to entry
hash_table_find_entry:
    push rbp
    mov rbp, rsp
    xor rax, rax
    test rdi, rdi
    jz _exit_ht_find_entry
    test rsi, rsi
    jz _exit_ht_find_entry
    mov r8, [rdi]
    mov ebx, [rdi+12] 
    dec ebx
    and ecx, ebx
_start_loop_ht_find:
    lea r9, [r8+rcx*8]
    mov r10, [r9]
    test r10, r10
    jz _success_ht_find_entry 
    movzx r11d, byte [r10+13]
    cmp r11d, edx
    jne _next_loop_ht_find
    mov rax, [r10]
    mov r12d, edx
_cmp_str_ht_find:
    dec edx; len of str so last char is [len - 1]
    movzx r13d, byte [rax+rdx]
    movzx r14d, byte [rsi+rdx]
    cmp r13d, r14d
    jne _end_cmp_str_ht_find
    test rdx, rdx
    jz _success_ht_find_entry
    jmp _cmp_str_ht_find
_end_cmp_str_ht_find:
    mov edx, r12d
_next_loop_ht_find:
    inc ecx
    and ecx, ebx
    jmp _start_loop_ht_find
_success_ht_find_entry:
    mov rax, r9
_exit_ht_find_entry:
    pop rbp
    ret

;rdi - ptr to hash table main block, rsi - ptr to ht entry, rdx - ptr to sym entry,
hash_table_add_entry:
    push rbp
    mov rbp, rsp
    sub rsp, 56
    mov [rbp-8], rdi

    xor rax, rax
    test rdi, rdi
    jz _exit_ht_add_entry
    test rsi, rsi
    jz _exit_ht_add_entry
    test rdx, rdx
    jz _exit_ht_add_entry
    cmp rsi, rdi
    jb _exit_ht_add_entry
    mov rbx, [rdi]
    mov ecx, [rdi+12]
    lea r8, [rbx+rcx*8]
    cmp rsi, r8
    jge _exit_ht_add_entry

    mov [rsi], rdx
    mov ebx, [rdi+8]
    inc ebx
    mov [rdi+8], ebx
    mov eax, ecx
    mov r8d, ecx
    shr eax, 1
    shr r8d, 2
    add eax, r8d
    cmp ebx, eax
    jb _success_exit_ht_add_entry 
    mov bl, [rdi+16]
    test bl, bl
    jz _err_realloc_forbid_ht
    mov edi, ecx
    shl edi, 4; 3 + 1
    call mmap_def
    xor rdx, rdx
    not rdx
    cmp rax, rdx   
    jne _start_realloc_ht
    xor rax, rax
    jmp _exit_ht_add_entry
_start_realloc_ht:
    mov ecx, 16
    mov rsi, [rbp-8]
    mov rdx, rsi
    lea rdi, [rbp-32]
    rep movsb
    mov ecx, [rdx+12]
    mov r8, [rdx]
    lea r9, [r8+rcx*8]
    shl ecx, 1
    mov [rdx], rax
    mov [rdx+12], ecx
    mov [rbp-48], r9
_start_realloc_loop_ht:
    mov rax, [r8]
    test rax, rax
    jz _next_realloc_loop_ht
    mov [rbp-40], r8
    mov rdi, [rax]
    movzx esi, byte [rax+13]
    mov [rbp-56], rax
    call hash_str
    mov rbx, [rbp-56]
    mov rdi, [rbp-8]
    mov rsi, [rbx]
    movzx edx, byte [rbx+13]
    mov ecx, eax
    call hash_table_find_entry
    mov rbx, [rbp-56]
    mov [rax], rbx
    mov r8, [rbp-40]
    mov r9, [rbp-48]
_next_realloc_loop_ht:
    add r8, 8
    cmp r8, r9
    jb _start_realloc_loop_ht
    mov rdi, [rbp-32]
    mov esi, [rbp-20]
    call munmap
    test rax, rax
    jz _success_exit_ht_add_entry
    exit_m -10
_err_realloc_forbid_ht:
    xor rax, rax
    jmp _exit_ht_add_entry
_success_exit_ht_add_entry:
    mov rax, 1
_exit_ht_add_entry:
    add rsp, 56
    pop rbp
    ret

; rdi - ptr to hash table main block, esi - capacity,
; rdx - mem for entries (0 if must be allocated)
hash_table_init:
    push rbp
    mov rbp, rsp
    sub rsp, 12
    test rdi, rdi
    jz _false_ht_init
    mov ecx, esi
    sub ecx, 1
    and ecx, esi
    test ecx, ecx
    jnz _false_ht_init
    mov [rdi], rdx
    mov [rbp-12], esi
    test rdx, rdx
    jnz _ht_init_skip_alloc
    mov [rbp-8], rdi
    mov rdi, rsi
    shl rdi, 3
    call mmap_def
    xor rdx, rdx
    sub rdx, 1
    cmp rax, rdx
    je _false_ht_init
    mov rdi, [rbp-8]
    mov [rdi], rax
_ht_init_skip_alloc:
    mov dword [rdi+8], 0
    mov ecx, [rbp-12]
    mov [rdi+12], ecx
    mov rax, 1
    jmp _exit_ht_init
_false_ht_init:
    xor rax, rax
_exit_ht_init:
    add rsp, 12
    pop rbp
    ret

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
    sub rsp, 64
    mov esi, 2048
    call init_def_sym_table
    lea rdi, [DEF_SYM_HASH_TABLE]
    call print_ht_sym_str
    exit_m 0
