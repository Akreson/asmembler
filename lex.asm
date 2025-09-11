segment readable writeable

CHAR_TABLE db 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0x42, 4, 0, 4, 0, 0; 0 - 15
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; 16 - 31
db 4, 0, 0x4A, 0, 0, 0x82, 0, 0x52, 0x5A, 0x62, 0x3A, 0x2A, 0xA, 0x32, 0x8A, 0; 32 - 47
db 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0x12, 0x7A, 0, 0, 0, 0; 48 - 63
db 0x92, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1; 64 - 79
db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0x1A, 0, 0x22, 0, 1; 80 - 95
db 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1; 96 - 111
db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0x6A, 0, 0x72, 0, 0; 112 - 127
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; 128 - 143
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; 144 - 159
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; 160 - 175
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; 176 - 191
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; 192 - 207
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; 208 - 223
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; 224 - 239
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0; 240 - 255

CHAR_TYPE_INVALID equ 0
CHAR_TYPE_NAME    equ 1
CHAR_TYPE_AUX     equ 2
CHAR_TYPE_DIGIT   equ 3
CHAR_TYPE_SPACE   equ 4

segment readable executable

; rdi - ptr to file entry, esi - line skip to
; return rax - ptr, rbx - offset
skip_buf_to_line:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rdi
    mov [rbp-12], esi
    mov rax, [rdi]
    mov rdx, [rdi+8]
    add rdx, rax
_skip_bf_nl_loop:
    cmp rax, rdx
    jae _end_skip_buf_to_line
    mov cl, [rax]
    cmp cl, _CONST_NEW_LINE
    jne _skip_nl_loop_check
    dec esi
    test esi, esi
    jz _end_skip_buf_to_line
_skip_nl_loop_check:
    inc rax
    jmp _skip_bf_nl_loop
_end_skip_buf_to_line:
    mov rdx, [rdi]
    mov rbx, rax
    sub rbx, rdx
    add rsp, 16
    pop rbp
    ret

;rdi - ptr to file entry, rsi - offset to start with
;return rax - offset to line, rbx - line len
get_curr_line_start_end:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov rdx, [rdi]
    mov [rbp-8], rsi
    mov rcx, rsi
    test rcx, rcx
    jz _count_len_gclse
_back_loop_gclse:
    dec rcx
    test rcx, rcx
    jz _count_len_gclse
    mov al, [rdx+rcx]
    cmp al, 0x0A
    jne _back_loop_gclse
    inc rcx
_count_len_gclse:
    mov rbx, rsi
    mov [rbp-16], rcx
    mov r8, [rdi+8]
__loop_len_gclse:
    cmp rbx, r8
    jae __end_loop_len_gclse
    mov al, [rdx+rbx]
    cmp al, 0x0A
    je __end_loop_len_gclse
    inc rbx
    jmp __loop_len_gclse
__end_loop_len_gclse:
    mov rax, [rbp-16]
    sub rbx, rax
_end_get_curr_line_start_end:
    add rsp, 16
    pop rbp
    ret

; rdi - file entry ptr, rsi - ptr to space for symbol entry
; -8 passed rdi, -16 passed rsi, -24 ptr to buff, -32 size of buff
; -40 curr read offset, -48 cached last read char, -56 ptr to aux token
; -64 offset for start of token, -72 building digit / hash of token / str quote sym
next_token:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov rbx, [rdi]
    mov rcx, [rdi+16]; curr pos
    mov [rbp-24], rbx
    mov rdx, [rdi+8]
    mov [rbp-32], rdx
    lea rsi, [CHAR_TABLE]
    mov [rbp-80], rcx
    mov dword [rbp-84], 0
_loop_skip_wt_nt:
    movzx edi, byte [rbx+rcx]
    cmp edi, 0
    je _eof_nt
    cmp edi, _CONST_SEMICOLON
    jne __loop_skip_check_space 
__comment_skip_loop:
    inc rcx
    cmp rcx, rdx
    je _eof_nt
    movzx edi, byte [rbx+rcx]
    cmp edi, _CONST_NEW_LINE
    jne __comment_skip_loop
    mov [rbp-40], rcx
    jmp _char_check_begin_nt
__loop_skip_check_space:
    mov al, [rsi+rdi]
    and al, 0x7
    cmp al, CHAR_TYPE_SPACE
    jne _char_check_nt
    inc rcx
    cmp rcx, rdx
    je _eof_nt
    jmp _loop_skip_wt_nt
_char_check_nt:
    mov r9, rcx
    mov r8, [rbp-80]
    sub rcx, r8
    mov [rbp-84], ecx
    mov rcx, r9
    mov [rbp-40], rcx
    mov [rbp-48], edi
_char_check_begin_nt:
    lea rdx, [CHAR_TABLE]
    movzx ebx, byte [rdx+rdi]
    mov eax, ebx
    and ebx, 0x7
    cmp ebx, CHAR_TYPE_NAME
    je _scan_symbol_nt
    cmp ebx, CHAR_TYPE_DIGIT
    je _scan_digit_nt
    cmp dil, _CONST_DQM 
    je _set_str_token
    cmp dil, _CONST_QM
    je _set_str_token
_aux_check_nt:
    cmp ebx, CHAR_TYPE_AUX
    jne _unrec_char_nt
    shr eax, 3
    imul eax, eax, TOKEN_KIND_SIZE
    lea rcx, [DUMMY_NODE_AUX]
    add rcx, rax
    mov [rbp-56], rcx
    mov edx, dword [rcx+8]
    cmp edx, AUX_NEW_LINE
    jne _set_aux_token
    mov rbx, [rbp-24]
    mov rdx, [rbp-32]
    mov rcx, [rbp-40]
    lea rsi, [CHAR_TABLE]
_loop_new_line_collate_nl_nt:
    mov rdi, [rbp-8]
    inc dword [rdi+44]
_loop_collate_nl_nt:
    inc rcx
    cmp rcx, rdx
    je _eof_nt
    movzx edi, byte [rbx+rcx]
    cmp edi, _CONST_NEW_LINE
    je _loop_new_line_collate_nl_nt
    cmp edi, _CONST_SEMICOLON
    je __comment_skip_loop
    mov al, [rsi+rdi]
    and al, 0x7
    cmp al, CHAR_TYPE_SPACE
    je _loop_collate_nl_nt
    dec rcx
    mov [rbp-40], rcx
_set_aux_token:
    mov r9, rcx
    mov r8, [rbp-80]
    sub rcx, r8
    mov [rbp-84], ecx
    mov rcx, r9; TODO: ?
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

    mov r8, [rbp-32]
    mov r9, [rbp-64]
    lea rdx, [CHAR_TABLE]
__loop_scan_symbol_nt:
    inc rcx
    cmp rcx, r8
    jae __finish_loop_scan_symbol_nt
    mov rsi, rcx
    sub rsi, r9 
    cmp rsi, SYM_NAME_MAX_LEN
    ja _err_to_long_sym_nt
    movzx edi, byte [rbx+rcx]
    movzx eax, byte [rdx+rdi]
    mov esi, eax
    and eax, 0x7
    cmp eax, CHAR_TYPE_INVALID
    je _unrec_char_nt 
    cmp eax, CHAR_TYPE_SPACE
    je __finish_loop_scan_symbol_nt
    cmp eax, CHAR_TYPE_AUX
    jne __loop_scan_symbol_nt
    shr esi, 3
    cmp esi, AUX_NAME_VALID_FROM
    jae __loop_scan_symbol_nt
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
    lea rdi, [DEF_SYM_HASH_TABLE]
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
    lea r9, [CHAR_TABLE]
    mov eax, 10
    cmp edi, '0'
    je __check_base16_start_nt
    jmp __start_loop_scan_digit_nt
__check_base16_start_nt:
    inc rcx
    movzx edi, byte [rbx+rcx]
    movzx esi, byte [r9+rdi]
    and esi, 0x7
    cmp edi, _CONST_SPACE
    je __start_loop_scan_digit_nt
    cmp edi, _CONST_TAB
    je __start_loop_scan_digit_nt
    cmp edi, 'x'
    jne __check_base8_start_nt
    mov eax, 16
    jmp __start_loop_inc_scan_digit_nt
__check_base8_start_nt:
    cmp esi, CHAR_TYPE_DIGIT
    jne __check_base2_start_nt
    mov eax, 8
    jmp __start_loop_inc_scan_digit_nt
__check_base2_start_nt:
    cmp edi, 'b'
    jne __check_aux_digit_next
    mov eax, 2
    jmp __start_loop_inc_scan_digit_nt
__check_aux_digit_next:
    cmp esi, CHAR_TYPE_AUX
    jne _err_digit_format
    mov eax, 10
    xor edi, edi
    jmp __finish_scan_digit_nt
__start_loop_inc_scan_digit_nt:
    inc rcx
__start_loop_scan_digit_nt:
    mov [rbp-48], eax
__loop_scan_digit_nt:
    mov r8, [rbp-32]
    cmp rcx, r8
    jae __finish_scan_digit_nt
    movzx edi, byte [rbx+rcx]
    movzx esi, byte [r9+rdi]
    and esi, 0x7
    cmp esi, CHAR_TYPE_DIGIT
    jne __check_base16_digit_nt
    sub edi, '0'
    jmp __build_up_digit_nt
__check_base16_digit_nt:
    mov edx, edi
    and edx, 0xDF 
    cmp dl, 'A'
    jb __check_end_of_digit
    cmp dl, 'F'
    ja __check_end_of_digit
    mov edi, edx
    sub edi, 55
    jmp __build_up_digit_nt
__check_end_of_digit:
    cmp esi, CHAR_TYPE_AUX
    je __finish_scan_digit_nt 
    cmp esi, CHAR_TYPE_SPACE 
    je __finish_scan_digit_nt
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
    mov rsi, [rbp-64]
    sub rcx, rsi
    mov [rdi+8], ecx
    mov rax, 1
    jmp _end_next_token

_set_str_token:
    mov [rbp-72], edi
    mov r8, [rbp-32]
    mov rsi, [rbp-40]
    mov rbx, [rbp-24]
    mov rcx, rsi
    inc rsi
__str_set_loop_start:
    inc rcx
    cmp rcx, r8
    jae _err_string_parsing
    movzx eax, byte [rbx+rcx]
    cmp eax, edi
    jne __str_set_loop_start
__finish_scan_str:
    mov r10, rcx
    sub rcx, rsi
    mov rdi, [rbp-16]
    lea r9, [rbx+rsi]
    mov [rdi], r9
    mov [rdi+8], ecx
    mov byte [rdi+12], TOKEN_TYPE_STR
    inc r10
    mov [rbp-40], r10
    jmp _end_next_token
_eof_nt:
    mov rdi, [rbp-16]
    mov qword [rdi], 0
    mov dword [rdi+8], 0
    mov byte [rdi+12], TOKEN_TYPE_EOF
    mov byte [rdi+13], 0
    mov rax, 1
    jmp _end_next_token
_err_digit_format:
    lea rbx, [ERR_LEXER_NUMBER_FORMAT]
    jmp __err_digit_end_nt
_err_out_of_base_digit:
    lea rbx, [ERR_LEXER_NUMBER_ORDER]
    jmp __err_digit_end_nt
_err_digit_overflow:
    lea rbx, [ERR_LEXER_NUM_TO_BIG]
    jmp __err_digit_end_nt
__err_digit_end_nt:
    mov [rbp-128], rbx
    mov rbx, [rbp-24]
    lea rdx, [CHAR_TABLE]
__loop_err_digit_end_nt:
    inc rcx
    movzx edi, byte [rbx+rcx]
    movzx eax, byte [rdx+rdi]
    and eax, 0x7
    cmp eax, CHAR_TYPE_AUX
    je __finish_loop_err_digit_end_nt
    cmp eax, CHAR_TYPE_SPACE
    je __finish_loop_err_digit_end_nt
    jmp __loop_err_digit_end_nt
__finish_loop_err_digit_end_nt:
    mov rax, [rbp-64]
    sub rcx, rax
    lea rdi, [rbx+rax]
    mov [rbp-120], rcx
    mov [rbp-112], rdi
    jmp _err_end_next_token
_err_string_parsing:
    lea rsi, [ERR_LEXER_STR_PARSE]
    jmp _err_next_token
_unrec_char_nt:
    lea rsi, [ERR_LEXER_INVALID_CHAR]
    jmp _err_next_token
_err_to_long_sym_nt:
    lea rsi, [ERR_LEXER_TO_LONG_NAME]
_err_next_token:
    mov edi, [CURR_FILE_ENTRY_OFFSET]
    xor rdx, rdx
    xor ecx, ecx
    mov r9, -3
    call err_print
_err_end_next_token:
    mov edi, [CURR_FILE_ENTRY_OFFSET]
    mov rax, [FILES_ARRAY]
    lea rdi, [rax+rdi]
    xor esi, esi
    xor rdx, rdx
    call print_file_line
    lea rdi, [ERR_HEADER_STR]
    call print_zero_str
    lea rdi, [STR_DQM]
    mov esi, 1
    call print_len_str
    mov rdi, [rbp-112]
    mov rsi, [rbp-120]
    call print_len_str
    lea rdi, [STR_DQM]
    mov esi, 1
    call print_len_str
    lea rdi, [_STR_TAB]
    mov esi, 1
    call print_len_str
    mov rdi, [rbp-128]
    call print_zero_str
    exit_m -3
_end_next_token:
    mov rcx, [rbp-40]
    mov rax, [rbp-8]
    mov ebx, [rbp-84]
    mov [rax+16], rcx
    add rsp, 128 
    pop rbp
    ret
