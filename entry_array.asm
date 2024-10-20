segment readable executable

ENTRY_ARRAY_DATA_SIZE equ 20

;0 ptr to buff, +8 count, +12 capacity, +16 entry size (20b) 
macro entry_array_data_m name, size
{
    name dq 0
    dd 0, 0, size
}

; rdi - ptr to token entry array, esi - size
; return rax - ptr to start of alloc mem, ebx - offset in buffer
entry_array_reserve_size:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-28], rdi
    mov [rbp-32], esi
    call entry_array_check_get
    test rax, rax
    jnz _finish_token_brs
    mov rdi, [rbp-28]
    mov esi, [rdi+12]
    shl esi, 1
    lea rdx, [rbp-20]
    call entry_array_copy_realloc
    test rax, rax
    jnz _success_realloc_token_brs
    exit_m -9
_success_realloc_token_brs:
    mov rdi, [rbp-28]
    call entry_array_dealloc
    mov rdx, [rbp-28]
    mov rdi, rdx
    lea rsi, [rbp-20]
    mov ecx, 20
    rep movsb
    mov rdi, rdx
    mov esi, [rbp-32]
    call entry_array_check_get
    test rax, rax
    jnz _finish_token_brs
    exit_m -9
_finish_token_brs:
    mov rbx, rax
    mov rdi, [rbp-28]
    mov r8, [rdi]
    sub rbx, r8
_end_token_buf_reserve_size:
    add rsp, 32
    pop rbp
    ret

; signed division!
; rdi - ptr to entry array main block, rsi - curr ptr in entry array
entry_array_commit_size:
    push rbp
    mov rbp, rsp
    mov r8, [rdi]
    mov ecx, [rdi+8]
    mov ebx, [rdi+12]
    mov r9d, [rdi+16]
    mov r10, r8
    add r10, rbx
    cmp rsi, r8
    jb _err_ea_commit
    cmp rsi, r10
    jae _err_ea_commit
    mov rax, rsi
    sub rax, r8
    xor edx, edx
    idiv r9d
    test edx, edx
    jnz _err_ea_commit
    mov [rdi+8], eax
    jmp _end_entry_array_commit_size
_err_ea_commit:
    exit_m -10
_end_entry_array_commit_size:
    pop rbp
    ret

; rdi - ptr to entry array main block, esi - count of entry to check
entry_array_ensure_free_space:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov ebx, [rdi+8]
    mov edx, [rdi+12]
    sub edx, ebx
    cmp edx, esi
    jae _success_eaec
    mov [rbp-28], rdi
    mov [rbp-32], esi
    shl edx, 1
    lea rdx, [rbp-20]
    call entry_array_copy_realloc
    test eax, eax
    jnz _update_eaefs
    exit_m -9
_update_eaefs:
    mov rdi, [rbp-28]
    call entry_array_dealloc
    mov rdi, [rbp-28]
    mov r8, rdi
    lea rsi, [rbp-20]
    mov ecx, 20
    mov rdi, r8
_success_eaec:
    call entry_array_curr_ptr   
_end_entry_array_ensure_free_space:
    add rsp, 32
    pop rbp
    ret

; rdi - ptr to entry array main block
; return rax - curr ptr, ebx - curr offset 
entry_array_curr_ptr:
    mov rax, [rdi]
    mov ebx, [rdi+8]
    add rax, rbx
    ret

; rdi - ptr to entry array main block, esi - count of entry to check
entry_array_check_get:
    push rbp
    mov rbp, rsp
    mov ebx, [rdi+8]
    mov edx, [rdi+12]
    sub edx, ebx
    cmp edx, esi
    jb _check_fail_eacg
    mov eax, [rdi+16]
    mul ebx
    mov rcx, [rdi]
    lea r8, [rcx+rax]
    mov r9d, eax
    mov rax, r8
    add ebx, esi
    mov [rdi+8], ebx
    mov ebx, r9d
    jmp _end_entry_array_check_get
_check_fail_eacg:
    xor rax, rax
_end_entry_array_check_get:
    pop rbp
    ret

; rdi - ptr to entry array main block, rsi - ptr to val, edx - size of val in bytes
entry_array_check_push:
    push rbp
    mov rbp, rsp
    mov eax, [rdi+8]
    mov ebx, [rdi+12]
    sub ebx, eax
    cmp edx, ebx
    jb _check_fail_eacp
    mov ecx, edx
    mov rax, [rdi]
    lea rdi, [rcx+rax]
    mov rax, rdi
    rep movsb
    jmp _end_entry_array_check_get
_check_fail_eacp:
    xor rax, rax
_end_entry_array_check_push:
    pop rbp
    ret

; rdi - ptr to entry array main block, esi - new capacity, rdx - ptr to new main block
entry_array_copy_realloc:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rdi
    mov [rbp-16], esi
    mov [rbp-32], rdx
    mov eax, [rdi+16]
    mul esi
    mov edi, eax
    call mmap_def
    xor rdx, rdx
    not rdx
    cmp rax, rdx
    jne _start_ea_realloc
    xor rax, rax
    jmp _end_entry_array_realloc
_start_ea_realloc:
    mov [rbp-24], rax
    mov rdi, rax
    mov rdx, [rbp-8]
    mov rsi, [rdx]
    mov r8d, [rdx+12]
    mov eax, [rbp-16]
    cmp r8d, eax
    ja _copy_mem_ea_realloc
    mov eax, r8d
_copy_mem_ea_realloc:
    mov ebx, [rdx+16]
    mul ebx
    mov ecx, eax
    rep movsb
    mov r8, [rbp-8]
    mov rdx, [rbp-32]
    mov rax, [rbp-24]
    mov ebx, [rbp-16]
    mov ecx, [r8+8]
    mov esi, [r8+16]
    mov [rdx], rax
    mov [rdx+8], ecx
    mov [rdx+12], ebx
    mov [rdx+16], esi
    mov rax, 1
_end_entry_array_realloc:
    add rsp, 32
    pop rbp
    ret

; rdi - ptr to entry array main block
entry_array_dealloc:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov [rbp-8], rdi
    mov eax, [rdi+12]
    mov ecx, [rdi+16]
    mul ecx
    mov esi, eax
    mov rdi, [rdi]
    call munmap
    test rax, rax
    jz _succes_dealloc_ea
    exit_m -10
_succes_dealloc_ea:
    mov rax, 1
_end_entry_array_dealloc:
    add rsp, 8
    pop rbp
    ret

; rdi - ptr to struct, esi - init capasity
init_entry_array:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    xor rax, rax
    test rdi, rdi
    jz _end_init_entry_array 
    mov [rbp-8], rdi
    mov [rbp-16], esi
    mov [rdi+12], esi
    mov [rdi+8], eax
    mov ebx, [rdi+16]
    xor edx, edx
    mov eax, esi
    mul ebx
    mov edi, eax
    call mmap_def
    xor rdx, rdx
    not rdx
    cmp rax, rdx
    je _false_init_ea
    mov rdi, [rbp-8]
    mov [rdi], rax
    jmp _end_init_entry_array
_false_init_ea:
    xor rax, rax
_end_init_entry_array:
    add rsp, 32
    pop rbp
    ret
