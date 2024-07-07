segment readable executable

; rdi - ptr to buf of ptr to seg entry
; return eax - count of segments
set_collate_seg_ptr:
    push rbp
    mov rbp, rsp
    mov rdx, SEG_ENTRY_ARRAY
    mov ecx, SEG_ENTRY_SIZE
    mov eax, 4
    mul ecx
    lea rbx, [rdx+rax]
    mov [rdi], rbx
    mov eax, 6
    mul ecx
    lea rbx, [rdx+rax]
    mov [rdi+8], rbx
    mov eax, 5
    mul ecx
    lea rbx, [rdx+rax]
    mov [rdi+16], rbx
    mov eax, 3
    mul ecx
    lea rbx, [rdx+rax]
    mov [rdi+24], rbx
    mov eax, 1
    mul ecx
    lea rbx, [rdx+rax]
    mov [rdi+32], rbx
    mov eax, 5
    pop rbp
    ret

; TODO: complete
; rdi - ptr to token entry
render_err_first_param:
    push rbp
    mov rbp, rsp
    pop rbp
    ret

; -8 passed rdi, - 16 passed rsi
; rdi - segment ptr, rsi - ptr to token entry to process
process_mov:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov eax, [rdi+28]
    mov [rsi], eax
    add rsi, TOKEN_HEADER_PLUS_DIRECT 
    movzx ebx, byte [rsi]
    cmp ebx, TOKEN_BUF_DIRECT
    je _mov_f_r
    cmp ebx, TOKEN_BUF_ADDR
    je _mov_f_a
    jmp _err_invalid_first_param
_mov_f_r:
    movzx eax, byte [rsi+14]
    cmp eax, TOKEN_TYPE_REG
    jne _err_invalid_first_param
    mov ebx, [rsi+9]
    mov edx, ebx
    and edx, REG_MASK_BITS
    ;TODO: complete 
_mov_f_a:
_err_invalid_first_param:
    mov rdi, [rbp-16]
    call render_err_first_param
_err_exit:
    exit_m -6
_end_process_mov:
    add rsp, 128
    pop rbp
    ret

; -8 passed rdi, -12 curr token buff offset, -16 reserve
; -24 curr token buf ptr
; rdi - segment ptr
render_process_segment:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    xor rax, rax
    mov [rbp-8], rdi
    mov [rbp-12], eax
_start_loop_process_segment:
    mov ecx, [rbp-12]
    mov r8, [rbp-8]
    mov ebx, [r8+8]
    cmp ecx, ebx
    ja _end_render_process_segment
    mov r9, [r8+rcx]
    mov [rbp-24], r9
    lea r10, [r9+16]
    movzx ebx, byte [r10]
    cmp ebx, TOKEN_BUF_DIRECT
    jne _err_processing_start_token
    movzx eax, byte [r10+14]
    cmp eax, TOKEN_TYPE_INS
    je _check_ins_rps
    cmp eax, TOKEN_TYPE_KEYWORD
    jmp _err_processing_start_token
_check_ins_rps:
    mov ebx, [r10+9]
    cmp ebx, INS_MOV
    jne _check_ins_rps1
    mov rdi, [rbp-8]
    mov rsi, r9
    call process_mov
    jmp _start_loop_process_segment 
_check_ins_rps1:
_err_processing_start_token:
    exit_m -6
_end_render_process_segment:
    add rsp, 128
    pop rbp
    ret

; -4 - curr seg index, -8 count of seg to process
start_render:
    push rbp
    mov rbp, rsp
    sub rsp, 2304
    mov dword [rbp-4], 0
    ;TODO: check if collate mode is enabled    
    mov rdi, rsp
    call set_collate_seg_ptr
    mov [rbp-8], eax
_render_seg_grab_loop:
    mov ebx, [rbp-4]
    mov eax, [rbp-8]
    cmp ebx, eax
    ja _end_start_render
    mov ecx, ebx
    inc ecx
    mov [rbp-4], ecx
    shr ebx, 3
    mov rdi, rsp
    add rdi, rdx
    call render_process_segment
    jmp _render_seg_grab_loop    
_end_start_render:
    add rsp, 2304
    pop rbp
    ret
