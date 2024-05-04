segment readable
DIGIT_MAP db "0123456789ABCDEF", 0
PRINT_BASE_ERR db "Unsupported base for print_digit", 0


segment readable executable

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
    mov rdi, rcx
    call print_zero_str
_end_print_digit:
    add rsp, 144
    pop rbp
    ret

