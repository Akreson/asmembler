segment readable writeable

ALL_ONE_8B dq 0x0101010101010101
ALL_HIGH_SET_8B dq 0x8080808080808080
SPACE_CHAR_4B dq 0x200D090B
ALL_ONE_4B dd 0x01010101
ALL_HIGH_SET_4B dd 0x80808080

; TODO: SAVE IN FILE ENTRY FOR BEING ABLE GET IT BACK LATER
LAST_LINE_NUM dd 0

ERR_LEXER_TO_LONG_NAME db "ERR: Name is to long, max. is 255 bytes", 10, 0
ERR_LEXER_NUM_TO_BIG db "ERR: Number overflow 64-bit reg", 10, 0
ERR_LEXER_NUMBER_FORMAT db "ERR: invalid digit format", 10, 0
ERR_LEXER_NUMBER_ORDER db "ERR: invalid symbol for choosen base of digit", 10, 0
ERR_LEXER_INVALID_CHAR db "ERR: Unsupported char", 10, 0

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

;does not modifies rbx -rdi reg
;rdi - char to check
is_digit:
    push rbp
    mov rbp, rsp
    xor eax, eax
    mov r8d, '0'
    mov r9d, '9'
    cmp edi, r8d
    jb _end_is_digit
    cmp edi, r9d
    ja _end_is_digit
    inc eax
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

;TODO: debug
;rdi - ptr to file entry
;return rax - offset to line, rbx - line len
get_curr_line_start_end:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov rdx, [rdi]
    mov rcx, [rdi+16]
    mov [rbp-8], rcx
    test rcx, rcx
    jz _count_len_gclse
_back_loop_gclse:
    dec rcx
    test rcx, rcx
    jz _count_len_gclse
    movzx eax, byte [rdx+rcx]
    cmp eax, 0x0A
    jne _back_loop_gclse
    inc rcx
_count_len_gclse:
    mov [rbp-16], rcx
    mov rbx, [rbp-8]
    mov r8, [rdi+8]
__loop_len_gclse:
    cmp rbx, r8
    jae __end_loop_len_gclse
    movzx eax, byte [rdx+rbx]
    cmp eax, 0x0A
    je __end_loop_len_gclse
    inc rbx
    jmp __end_loop_len_gclse
__end_loop_len_gclse:
    mov rax, [rbp-16]
    sub rbx, rax
_end_get_curr_line_start_end:
    add rsp, 16
    pop rbp
    ret

next_char:
    push rbp
    mov rbp, rsp
_end_next_char:
    pop rbp
    ret

;does not modifies rbx, rcx, rdx, rdi reg
;rdi - char to check
is_valid_sym_char:
    push rbp
    mov rbp, rsp
    mov esi, dword [SPACE_CHAR_4B]
    test edi, edi
    jz _fail_ivsc
    call is_contain_byte_4b
    test eax, eax
    jnz _fail_ivsc
    call is_aux_sym
    test rax, rax
    jz _success_ivsc
    cmp rax, AUX_NAME_VALID_FROM
    jb _fail_ivsc
_success_ivsc:
    mov rax, 1
    jmp _end_valid_sym_char
_fail_ivsc:
    xor rax, rax
_end_valid_sym_char:
    pop rbp
    ret

;TODO: add line info
;rdi - file entry ptr, rsi - ptr to space for symbol entry
; -8 passed rdi, -16 passed rsi, -24 ptr to buff, -32 size of buff
; -40 curr read ptr; -48 cahed last read char, -56 ptr to aux token
; -64 offset for start of token, -72 building digit / hash of token
next_token:
    push rbp
    mov rbp, rsp
    sub rsp, 72
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rbx, [rdi]
    mov rcx, [rdi+16]; curr pos
    mov [rbp-24], rbx
    mov rdx, [rdi+8]
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
_loop_new_line_collate_nl_nt:
    mov rax, LAST_LINE_NUM
    inc dword [rax]
    ;inc dword [LAST_LINE_NUM]
_loop_collate_nl_nt:
    inc rcx
    cmp rcx, rdx
    je _eof_nt
    movzx edi, byte [rbx+rcx]
    cmp edi, 10
    je _loop_new_line_collate_nl_nt
    call is_contain_byte_4b
    test eax, eax
    jnz _loop_collate_nl_nt
    dec rcx
    mov [rbp-40], rcx
_set_aux_token:
    inc dword [rbp-40]
    mov ecx, TOKEN_KIND_SIZE
    mov rsi, [rbp-56]
    mov rdi, [rbp-16]
    rep movsb
    mov rax, 1
    jmp _end_next_token
_scan_symbol_nt:
    mov rbx, [rbp-24]
    mov rcx, [rbp-40]
    mov [rbp-64], rcx
__loop_scan_symbol_nt:
    inc rcx
    mov r8, [rbp-32]
    cmp rcx, r8
    jae __finish_loop_scan_symbol_nt
    mov rdx, rcx
    mov rax, [rbp-64]
    sub rdx, rax
    cmp rdx, SYM_NAME_MAX_LEN
    ja _err_to_long_sym_nt
    movzx edi, byte [rbx+rcx]
    call is_valid_sym_char
    test rax, rax
    jnz __loop_scan_symbol_nt
__finish_loop_scan_symbol_nt:
    mov [rbp-40], rcx
    mov rbx, [rbp-24]
    mov rsi, rcx
    mov rcx, [rbp-64]
    sub rsi, rcx
    lea rdi, [rbx+rcx]
    push rsi
    push rdi
    call hash_str
    mov [rbp-72], eax
    mov ecx, eax
    pop rsi
    pop rdx
    mov rdi, DEF_SYM_HASH_TABLE
    call hash_table_find_entry
    mov rdi, [rbp-16]
    mov r8, [rax]
    test r8, r8
    jnz __def_symbol_found_nt
    mov byte [rdi+12], TOKEN_TYPE_NAME 
    mov rbx, [rbp-24]
    mov rdx, [rbp-40]
    mov rcx, [rbp-64]
    lea rax, [rbx+rcx]
    mov [rdi], rax
    mov esi, [rbp-72]
    mov [rdi+8], esi
    sub rdx, rcx
    mov [rdi+13], dl
    mov byte [rdi+14], 0
    mov rax, 1
    jmp _end_next_token
__def_symbol_found_nt:
    mov rsi, r8
    mov rcx, TOKEN_KIND_SIZE
    rep movsb
    jmp _end_next_token 
_scan_digit_nt:
    xor rax, rax
    mov [rbp-72], rax
    mov rbx, [rbp-24]
    mov rcx, [rbp-40]
    mov [rbp-64], rcx
    cmp edi, '0'
    je __check_base16_start_nt
    mov eax, 10
    jmp __start_loop_scan_digit_nt
__check_base16_start_nt:
    inc rcx
    movzx edi, byte [rbx+rcx]
    cmp edi, 'x'
    jne __check_base8_start_nt
    mov eax, 16
    jmp __start_loop_inc_scan_digit_nt
__check_base8_start_nt:
    call is_digit
    test eax, eax
    jz __check_base2_start_nt
    mov eax, 8
    jmp __start_loop_inc_scan_digit_nt
__check_base2_start_nt:
    cmp edi, 'b'
    jne _err_digit_format
    mov eax, 2
__start_loop_inc_scan_digit_nt:
    inc rcx
__start_loop_scan_digit_nt:
    mov [rbp-48], eax
__loop_scan_digit_nt:
    mov r8, [rbp-32]
    cmp rcx, r8
    jae __finish_scan_digit_nt
    movzx edi, byte [rbx+rcx]
    call is_digit
    test eax, eax
    jz __check_base16_digit_nt
    sub edi, '0'
    jmp __build_up_digit_nt
__check_base16_digit_nt:
    mov edx, edi
    mov eax, 32
    not eax
    and edx, eax
    mov eax, 'A'
    mov esi, 'F'
    cmp edi, eax
    jb __check_end_of_digit
    cmp edx, esi
    ja __check_end_of_digit
    mov edi, edx
    sub edi, 55
    jmp __build_up_digit_nt
__check_end_of_digit:
    call is_aux_sym
    test rax, rax
    jnz __finish_scan_digit_nt
    mov esi, dword [SPACE_CHAR_4B]
    call is_contain_byte_4b
    test rax, rax
    jnz __finish_scan_digit_nt
    jmp _err_digit_format
__build_up_digit_nt:
    mov rsi, [rbp-72]
    mov r8d, [rbp-48]
    cmp edi, r8d
    jae _err_out_of_base_digit
    xor rdx, rdx
    xor rax, rax
    sub rax, 1
    sub rax, rdi
    div r8
    cmp rsi, rax
    ja _err_digit_overflow
    mov rax, rsi
    mul r8
    add rax, rdi
    mov [rbp-72], rax
    inc rcx
    jmp __loop_scan_digit_nt
__finish_scan_digit_nt:
    mov [rbp-40], rcx
    mov rax, [rbp-72]
    lzcnt rbx, rax
    mov rdx, 64
    sub rdx, rbx
    mov rdi, [rbp-16]
    mov [rdi], rax
    mov byte [rdi+12], TOKEN_TYPE_DIGIT
    mov [rdi+13], dl
    mov rax, 1
    jmp _end_next_token
_err_digit_format:
    mov rdi, ERR_LEXER_NUMBER_FORMAT
    jmp __err_digit_end_nt
_err_out_of_base_digit:
    mov rdi, ERR_LEXER_NUMBER_ORDER
    jmp __err_digit_end_nt
_err_digit_overflow:
    mov rdi, ERR_LEXER_NUM_TO_BIG
    jmp __err_digit_end_nt
__err_digit_end_nt:
    mov [rbp-40], rcx
    call print_zero_str
    mov rcx, [rbp-40]
    mov rbx, [rbp-24]
    mov esi, dword [SPACE_CHAR_4B]
__loop_err_digit_end_nt:
    inc rcx
    movzx edi, byte [rbx+rcx]
    call is_aux_sym
    test eax, eax
    jnz __finish_loop_err_digit_end_nt
    call is_contain_byte_4b
    test eax, eax
    jnz __finish_loop_err_digit_end_nt
    jmp __loop_err_digit_end_nt
__finish_loop_err_digit_end_nt:
    mov rsi, rcx
    mov rax, [rbp-64]
    sub rsi, rax
    lea rdi, [rbx+rax]
    call print_len_str
    xor rax, rax
    jmp _end_next_token
_eof_nt:
    mov rdi, [rbp-16]
    mov qword [rdi], 0
    mov dword [rdi+8], 0
    mov byte [rdi+12], TOKEN_TYPE_EOF
    mov byte [rdi+13], 0
    mov rax, 1
    jmp _end_next_token
_unrec_char_nt:
    mov rdi, ERR_LEXER_INVALID_CHAR
    call print_zero_str
    xor rax, rax
    jmp _end_next_token
_err_to_long_sym_nt:
    movzx edi, byte [rbx+rcx]
    inc rcx
    call is_valid_sym_char
    test rax, rax
    jnz _err_to_long_sym_nt
    mov [rbp-40], rcx
    mov rdi, ERR_LEXER_TO_LONG_NAME
    call print_zero_str
    mov rdx, [rbp-40]
    mov rax, [rbp-64]
    lea rdi, [rdx+rax]
    sub rdx, rax
    call print_len_str
    xor rax, rax
_end_next_token:
    mov rcx, [rbp-40]
    mov rax, [rbp-8]
    mov [rax+16], rcx
    add rsp, 72
    pop rbp
    ret
