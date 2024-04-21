FNV_PRIME equ 16777619
FNV_OFFSET equ 2166136261

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

;rdi - ptr to hash table main block, rsi - ptr to ht entry, rdx - ptr to sym table entry,
hash_table_add_entry:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    push rdx

    xor rax, rax
    test rdi, rdi
    jz _exit_ht_add_entry
    test rsi, rsi
    jz _exit_ht_add_entry
    test rdx, rdx
    jz _exit_ht_add_entry
    cmp rsi, rdi
    jb _exit_ht_add_entry
    mov rbx, rdi
    mov ecx, [rdi+12]
    add rbx, rcx
    cmp rsi, rdi
    jge _exit_ht_add_entry

    mov [rsi], rdx
    mov rbx, [rdi]
    mov ebx, [rdi+8]
    mov eax, ecx
    mov r8d, ecx
    shl eax, 1
    shl r8d, 2
    add eax, r8d
    cmp ecx, eax
    jb _exit_ht_add_entry
    ;realloc all entries
_exit_ht_add_entry:
    add rsp, 24
    pop rbp
    ret

; rdi - ptr to hash table main block, esi - capacity
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
    mov [rbp-8], rdi
    mov [rbp-12], esi
    mov rdi, rsi
    call mmap_def
    xor rdx, rdx
    sub rdx, 1
    cmp rax, rdx
    je _false_ht_init
    mov rdx, [rbp-8]
    mov [rdx], rax
    mov dword [rdx+8], 0
    mov ecx, [rbp-12]
    mov [rdx+12], ecx
    mov rax, 1
    jmp _exit_ht_init
_false_ht_init:
    xor rax, rax
_exit_ht_init:
    add rsp, 12
    pop rbp
    ret
