segment readable
DIGIT_MAP db "0123456789ABCDEF", 0
PRINT_BASE_ERR db "Unsupported base for print_digit", 0


segment readable executable
;rdi - string ptr
print_zero_str:
    push rbp
    test rdi, rdi
    jz _end_print_str
    movzx ebx, byte [rdi]
    test ebx, ebx
    je _end_print_str
    mov rdx, rdi
_count_loop_print_str:
    inc rdx
    movzx ecx, byte [rdx] 
    test ecx, ecx
    jnz _count_loop_print_str
    sub rdx, rdi
    mov rsi, rdi
    write_m STD_OUT, rsi, rdx
_end_print_str:
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
    shl rbx, 4
    mov r8, 10
    cmp rsi, rax
    je _begin_loop_print_digit
    cmp rsi, rbx
    je _begin_loop_print_digit
    cmp rsi, r8
    je _begin_loop_print_digit
    mov rdi, PRINT_BASE_ERR
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
    ;mov [rcx], dil
    mov rdi, rcx
    call print_zero_str
_end_print_digit:
    add rsp, 144
    pop rbp
    ret

