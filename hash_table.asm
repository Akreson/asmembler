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

segment readable executable
; hash table main block: ptr, count, capacity
; capacity must be power of two

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
