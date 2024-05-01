segment readable

ALL_ONE_8B dq 0x0101010101010101
ALL_HIGH_SET_8B dq 0x8080808080808080
SPACE_CHAR_4B dq 0x200D090B
ALL_ONE_4B dd 0x01010101
ALL_HIGH_SET_4B dd 0x80808080

segment readable executable

;does not modifies rbx - rdi reg
;rdi - byte to check, rsi - bytes to cmp with
is_contain_byte_8b:
    push rbp
    mov rbp, rsp
    mov r8, [ALL_ONE_8B]
    mov r9, [ALL_HIGH_SET_8B]
    mov rax, r8
    mul rdi
    xor rax, rsi
    mov r10, rax
    sub r10, r8
    not rax
    and rax, r9
    and rax, r10
    pop rbp
    ret

; edi - byte to check, esi - bytes to cmp with
is_contain_byte_4b:
    push rbp
    mov rbp, rsp
    mov r8d, [ALL_ONE_4B]
    mov r9d, [ALL_HIGH_SET_4B]
    mov eax, r8d
    mul edi
    xor eax, esi
    mov r10d, eax
    sub r10d, r8d
    not eax
    and eax, r9d
    and eax, r10d
    pop rbp
    ret

;rdi - char to check
is_alpha:
    push rbp
    mov rbp, rsp
    xor rax, rax
    mov ecx, 'a'
    mov ebx, 'z'
    cmp edi, ecx
    jb _check_next_alpha_range_ia
    cmp edi, ebx
    ja _end_is_alpha 
    jmp _success_ia
_check_next_alpha_range_ia:
    mov ecx, 'A'
    mov ebx, 'Z'
    cmp edi, ecx
    jb _end_is_alpha
    cmp edi, ebx
    ja _end_is_alpha
_success_ia:
    inc rax
_end_is_alpha:
    pop rbp
    ret

;rdi - char to check
is_digit:
    push rbp
    mov rbp, rsp
    xor rax, rax
    mov ecx, '0'
    mov ebx, '9'
    cmp edi, ecx
    jb _end_is_digit
    cmp edi, ebx
    ja _end_is_digit
    inc rax
_end_is_digit:
    pop rbp
    ret

;does not modifies rbx, rcx, rdx, rdi reg
;rdi - byte to check
is_aux_sym:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    xor rax, rax
    mov r8, STR_COMMA
    mov r9, r8
    add r9, AUX_MEM_BLOCK_SIZE
    mov [rbp-16], r9
_loop_ias:
    mov rsi, qword [r8]
    mov [rbp-8], r8
    call is_contain_byte_8b
    mov r8, [rbp-8]
    test rax, rax
    jnz _set_result_ias
    mov r9, [rbp-16]
    add r8, 8
    cmp r8, r9
    je _end_is_aux_sym
    jmp _loop_ias
_set_result_ias:
    mov r11, STR_COMMA
    sub r8, r11
    lzcnt rax, rax
    mov r10, 64
    sub r10, rax
    shr r10, 3
    add r10, r8
    mov rax, r10
_end_is_aux_sym:
    add rsp, 24
    pop rbp
    ret

next_char:
    push rbp
    mov rbp, rsp
_end_next_char:
    pop rbp
    ret

;TODO: add line info
;rdi - file entry ptr, rsi - ptr to space for symbol entry
next_token:
    push rbp
    mov rbp, rsp
    sub rsp, 56
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rbx, [rdi]
    mov rcx, [rdi+36]; curr pos
    mov [rbp-24], rbx
    mov rdx, [rdi+16]
    mov [rbp-32], rdx
    mov esi, dword [SPACE_CHAR_4B]
_loop_skip_wt_nt:
    movzx edi, byte [rbx+rcx]
    call is_contain_byte_4b
    test eax, eax
    jz _char_check_nt
    inc rcx
    cmp rcx, rdx
    je _eof_nt
    jmp _loop_skip_wt_nt
_char_check_nt:
    mov [rbp-40], rcx
    mov [rbp-48], edi
    call is_alpha
    test rax, rax
    jnz _scan_symbol_nt
    mov edi, [rbp-48]
    mov ebx, '_'
    cmp edi, ebx
    je _scan_symbol_nt
    call is_digit
    test eax, eax
    jnz _scan_digit_nt
    mov edi, [rbp-48]
    call is_aux_sym
    test rax, rax
    jz _unrec_char_nt
    mov rbx, DUMMY_NODE_AUX
    mov rcx, TOKEN_KIND_SIZE
    mul rcx
    add rbx, rax
    mov [rbp-56], rbx
    mov edx, dword [rbx+8]
    cmp edx, AUX_NEW_LINE
    jne _set_aux_token
    mov rbx, [rbp-24]
    mov rdx, [rbp-32]
    mov rcx, [rbp-40]
    mov esi, dword [SPACE_CHAR_4B]
_loop_collate_nl_nt:
    inc rcx
    cmp rcx, rdx
    je _eof_nt
    movzx edi, byte [rbx+rcx]
    cmp edi, 10
    je _loop_collate_nl_nt
    call is_contain_byte_4b
    test eax, eax
    jnz _loop_collate_nl_nt
    dec rcx
    mov [rbp-40], rcx
_set_aux_token:
    inc qword [rbp-40]
    mov ecx, TOKEN_KIND_SIZE
    mov rsi, [rbp-56]
    mov rdi, [rbp-16]
    rep movsb
    jmp _end_next_token
_scan_symbol_nt:
_scan_digit_nt:
    inc qword [rbp-40]
    mov rdi, [rbp-16]
    mov qword [rdi], STR_COMMA
    mov dword [rdi+8], 1
    mov byte [rdi+12], TOKEN_TYPE_NAME
    mov byte [rdi+13], 8
    jmp _end_next_token
_eof_nt:
    mov rdi, [rbp-16]
    mov qword [rdi], 0
    mov dword [rdi+8], 0
    mov byte [rdi+12], TOKEN_TYPE_EOF
    mov byte [rdi+13], 0
_unrec_char_nt:
_end_next_token:
    mov rdi,[rbp-40] 
    mov rsi, 10
    call print_u_digit
    call print_new_line
    mov rcx, [rbp-40]
    mov rax, [rbp-8]
    mov [rax+36], rcx
    add rsp, 56
    pop rbp
    ret
