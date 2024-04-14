print_str:
    push rbp
    xor rax, rax
    cmp rdi, rax
    je _end_print_str
    xor rdx, rdx
    mov dl, [rdi]
    cmp rdx, rax
    je _end_print_str
    mov rdx, rdi
_count_loop_print_str:
    inc rdx
    mov cl, [rdx] 
    test cl, cl
    jnz _count_loop_print_str
    sub rdx, rdi
    mov rsi, rdi
    write_m STD_OUT, rsi, rdx
_end_print_str:
    pop rbp
    ret


