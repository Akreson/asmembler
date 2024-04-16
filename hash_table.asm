segment readable executable
; hash table main block: ptr, count, capacity
; capacity must be power of two

; rdi - ptr to hash table main block, rsi - capacity
hash_table_init:
    push rbp
    mov rbp, rsp
    test rdi, rdi
    jz _false_exit_hash_table_init
    mov ecx, esi
    sub ecx, 1
    and ecx, esi
    test ecx, ecx
    jnz _false_exit_hash_table_init
    push rdi
    push esi
    mov rdi, rsi
    call mmap_def
    xor rdx, rdx
    sub rdx, 1
    cmp rax, rdx
    je _false_hash_table_init
    mov rdx, [rbp-8]
    mov [rdx], rax
    mov dword [rdx+8], 0
    mov ecx, [rbp-12]
    mov [rdx+12], ecx
    mov rax, 1
    jmp _exit_hash_table_init
_false_hash_table_init:
    xor rax, rax
_exit_hash_table_init:
    pop rbp
    ret
