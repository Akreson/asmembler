segment readable executable

;0 ptr to buff, +8 count, +12 capacity, +16 entry size (20b) 
macro entry_array_data_m size
{
    dq 0
    dd 0, 0, size
}

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
    mov rax, r8
    add ebx, esi
    mov [rdi+8], ebx
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
