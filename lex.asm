
;rdi - char to check
is_alpha:
    push rbp
    mov rbp, rsp
    xor rax, rax
    mov cl, 'a'
    mov bl, 'z'
    cmp edi, ecx
    jb _check_next_alpha_range_ia
    cmp edi, ebx
    ja _end_is_alpha 
    jmp _success_ia
_check_next_alpha_range_ia:
    mov cl, 'A'
    mov bl, 'Z'
    cmp edi, ecx
    jb _end_is_alpha
    cmp edi, ebx
    ja _end_is_alpha
_success_ia:
    inc rax
_end_is_alpha:
    pop rbp
    ret

is_digit:
    push rbp
    mov rbp, rsp
    ; TODO: implement
_end_is_digit:
    pop rbp
    ret

_end_is_digit:
    pop rbp
    ret

next_char:
    push rbp
    mov rbp, rsp

_end_next_char:
    pop rbp
    ret

;rdi - file entry
next_token:
    push rbp
    mov rbp, rsp
    sub rsp, 40
    mov rax, [rdi]
    mov ebx, [rdi+36]
    mov [rbp-8], rdi
    mov [rbp-16], rax
    mov [rbp-24], ebx
    mov [rbp-36], rsi
    movzx edi, byte [rax+rbx]
    mov [rbp-40], edi
    call is_alpha
    test rax, rax
    jnz _scan_symbol_nt
    mov eax, [rbp-40]
    mov bl, '_'
    test eax, ebx
    je _scan_symbol_nt

_scan_symbol_nt:
_end_next_token:
    add rsp, 40
    pop rbp
    ret
