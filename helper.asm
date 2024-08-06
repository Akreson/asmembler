segment readable
DIGIT_MAP db "0123456789ABCDEF", 0
PRINT_BASE_ERR db "Unsupported base for print_digit", 0

MIN_INT8 equ 0x80
MAX_INT8 equ 0x7F

MIN_INT32 equ 0x80000000
MAX_INT32 equ 0x7FFFFFFF

segment readable executable

log2_val_ceil:
    xor rax, rax
    test rdi, rdi
    jz _end_log2_val_ceil
    cmp rdi, 1
    je _end_log2_val_ceil
    dec rdi
    bsr rax, rdi
    inc rax
_end_log2_val_ceil:
    ret

; rdi - val to align, rsi - pow2 align to
align_to_pow2:
    mov rax, rdi
    mov r8, rsi
    dec r8
    and rdi, r8
    test rdi, rdi
    jz _end_align_to_pow2
    sub rsi, rdi
    add rax, rsi
_end_align_to_pow2:
    ret

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

;rdi - ptr to ht main block
print_ht_sym_str:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov r8, [rdi]
    mov r9, r8
    mov [rbp-8], r8
    mov ebx, [rdi+12]
    shl ebx, 3
    add r9, rbx
    mov [rbp-16], r9
_loop_start_phtss:
    mov r8, [rbp-8]
    mov r9, [rbp-16]
    cmp r8, r9
    jae _end_print_ht_sym_str
    mov rbx, [r8]
    add r8, 8
    mov [rbp-8], r8
    test rbx, rbx
    jz _loop_start_phtss
    mov [rbp-24], rbx
    mov rdi, [rbp-8]
    sub rdi, 8
    mov rsi, 16
    call print_u_digit
    call print_new_line
    mov rbx, [rbp-24]
    mov rdi, [rbx]
    movzx esi, byte [rbx+13]
    call print_len_str
    call print_new_line
    call print_new_line
    jmp _loop_start_phtss
_end_print_ht_sym_str:
    add rsp, 24
    pop rbp
    ret

;rdi - curr file entry ptr
print_file_line:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov [rbp-8], rdi
    mov rbx, rdi
    mov rdi, [rbx+24]
    mov esi, [rbx+40]
    call print_len_str
    mov rdi, _STR_SPACE
    mov esi, 1
    call print_len_str
    mov rdi, STR_LBRACKET
    mov esi, 1
    call print_len_str
    mov edi, dword [LAST_LINE_NUM]
    mov esi, 10
    call print_u_digit
    mov rdi, STR_RBRACKET
    mov esi, 1
    call print_len_str
    mov rdi, STR_COLON
    mov esi, 1
    call print_len_str
    call print_new_line
    mov rdi, _STR_TAB
    mov esi, 1
    call print_len_str
    mov rdi, [rbp-8]
    call get_curr_line_start_end
    mov r8, [rbp-8]
    mov rdi, [r8]
    add rdi, rax
    mov rsi, rbx
    call print_len_str
    call print_new_line
_ent_print_file_line:
    add rsp, 8
    pop rbp
    ret
