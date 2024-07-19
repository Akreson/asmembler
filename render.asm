

; ins code struct (32 bytes)
; 0 (16 bytes) post opcodes bytes, +16 (8 bytes) prefix bytes, +24 len post opcode,
; +25 prefix bytes, +26 1st arg size, +27 2nd arg size, +28 3rd arg size (3 bytes reserved)
INS_CODE_STRUCT_SIZE equ 32

REX   equ 0x40
REX_R equ 0x04
REX_X equ 0x02
REX_B equ 0x01

MOD_ADDR_REG        equ 0
MOD_ADDR_REG_DISP8  equ 0x40
MOD_ADDR_REG_DISP32 equ 0x80
MOD_REG             equ 0xC0

RM_SIB equ 0x04

PREFIX_16BIT equ 0x66

segment readable executable

; rdi - ptr to buf of ptr to seg entry
; return eax - count of segments
set_collate_seg_ptr:
    push rbp
    mov rbp, rsp
    xor r9, r9
    mov r8, [SEG_ENTRY_ARRAY]
    mov ecx, SEG_ENTRY_SIZE
    mov eax, 4
    mul ecx
    lea rbx, [r8+rax]
    mov esi, [rbx+8]
    test esi, esi
    jz _set_collate_sg_check2
    inc r9d
    mov [rdi], rbx
    add rdi, 8
_set_collate_sg_check2:
    mov eax, 6
    mul ecx
    lea rbx, [r8+rax]
    mov esi, [rbx+8]
    test esi, esi
    jz _set_collate_sg_check3
    inc r9d
    mov [rdi], rbx
    add rdi, 8
_set_collate_sg_check3:
    mov eax, 5
    mul ecx
    lea rbx, [r8+rax]
    mov esi, [rbx+8]
    test esi, esi
    jz _set_collate_sg_check4
    inc r9d
    mov [rdi], rbx
    add rdi, 8
_set_collate_sg_check4:
    mov eax, 3
    mul ecx
    lea rbx, [r8+rax]
    mov esi, [rbx+8]
    test esi, esi
    jz _set_collate_sg_check5
    inc r9d
    mov [rdi], rbx
    add rdi, 8
_set_collate_sg_check5:
    mov eax, 1
    mul ecx
    lea rbx, [r8+rax]
    mov esi, [rbx+8]
    test esi, esi
    jz _end_set_collate_seg_ptr
    inc r9d
    mov [rdi], rbx
    add rdi, 8
_end_set_collate_seg_ptr:
    mov eax, r9d
    pop rbp
    ret

; TODO: complete
; rdi - ptr to token entry
render_err_first_param:
    push rbp
    mov rbp, rsp
    pop rbp
    ret

; for r_r version by default used r, r/m version
; rdi - ptr to ins param, rsi - ptr to ins code struct 
; return eax - 0 if succes 
process_gen_r_r:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rsi
    mov r10, rsi
    xor r9,r9 
    lea r8, [rdi+15]
    mov eax, [rdi+9]
    mov ebx, [r8+9]
    mov edx, eax
    mov ecx, ebx
    and eax, REG_MASK_REG_VAL
    and ebx, REG_MASK_REG_VAL
    and edx, REG_MASK_BITS
    and ecx, REG_MASK_BITS
    mov [rsi+26], edx
    mov [rsi+27], ecx
    cmp ecx, edx
    jne _err_gen_r_r_unmatch_size
    cmp eax, REG_REX_TH
    jne _gen_r_r_2rex_check
    or r9b, REX_R
_gen_r_r_2rex_check:
    cmp ebx, REG_REX_TH
    jne _gen_r_r_set_rex
    or r9b, REX_B
_gen_r_r_set_rex:
    test r9b, r9b
    jz _gen_r_r_set_arg
    or r9b, REX
_gen_r_r_set_arg:
    xor r12, r12
    lea r11, [r10+16]
    shl eax, 3
    or r12b, al
    or r12b, bl
    or r12b, MOD_REG
    mov byte [r10], r12b
    inc byte [rsi+24]
    cmp edx, REG_MASK_VAL_16B
    jne _gen_r_r_set_prefix
_gen_r_r16:
    mov byte [r11], PREFIX_16BIT
    inc byte [rsi+25]
_gen_r_r_set_prefix:
    test r9b, r9b
    jz _success_gen_r_r
    movzx eax, byte [rsi+25]
    mov byte [r11+rax], r9b
    inc eax
    mov byte [rsi+25], al
    jmp _success_gen_r_r
_err_gen_r_r_unrec_size:
_err_gen_r_r_unmatch_size:
    mov eax, 1
    jmp _end_process_gen_r_r
_success_gen_r_r:
    xor eax, eax
_end_process_gen_r_r:
    add rsp, 16
    pop rbp
    ret

; -8 passed rdi, -16 passed rsi, -24 render entry array, -32-38 (reserved), -42 (4b) opcode
; -128 ins code struct,
; rdi - segment ptr, rsi - ptr to token entry to process
process_mov:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    movzx eax, byte [rsi+31]
    cmp eax, 2
    jne _err_invalid_argc_mov
    xor rax, rax
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-24], rdi
    mov ecx, INS_CODE_STRUCT_SIZE
    lea rdi, [rbp-128]
    rep stosb
    mov eax, [rdi+28]
    mov [rsi], eax
    add rsi, TOKEN_HEADER_PLUS_INS_TOKEN
    movzx ebx, byte [rsi]
    cmp ebx, TOKEN_BUF_DIRECT
    je _mov_r
    cmp ebx, TOKEN_BUF_ADDR
    je _mov_a
    jmp _err_invalid_first_param_mov
_mov_r:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    jne _err_invalid_first_param_mov
    lea r9, [rsi+15]
    movzx ecx, byte [r9]
    cmp ecx, TOKEN_BUF_ADDR
    je __mov_r_a
    cmp ecx, TOKEN_BUF_PTR_OFFSET
    je __mov_r_i
    cmp ecx, TOKEN_BUF_DIRECT
    jne _err_invalid_second_param_mov
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    je __mov_r_r
    cmp ebx, TOKEN_TYPE_DIGIT
    je __mov_r_i
    jmp _err_invalid_second_param_mov
__mov_r_r:
    mov rdi, rsi
    lea rsi, [rbp-128]
    call process_gen_r_r
    test eax, eax
    jnz _err_parse_mov
    lea r8, [rbp-128]
    movzx ebx, byte [r8+26]
    cmp ebx, REG_MASK_VAL_8B
    jne ___mov_r_r_non_byte_opcode
    mov byte [rbp-42], 0x8A
    jmp _mov_accemble
___mov_r_r_non_byte_opcode:
    mov byte [rbp-42], 0x8B
    jmp _mov_accemble
__mov_r_a:
__mov_r_i:
_mov_a:
__mov_a_r:
__mov_a_i:
_mov_accemble:
    mov rdi, [rbp-24]
    call entry_array_curr_ptr
    mov rdi, rax
    lea r8, [rbp-128]
    lea rsi, [r8+16]
    movzx ecx, byte [r8+25]
    add rax, rcx
    rep movsb
    mov bl, [rbp-42]
    mov [rax], bl
    inc rax
    mov rdi, rax
    mov rsi, r8
    movzx ecx, byte [r8+24]
    add rax, rcx
    rep movsb
    mov rdi, [rbp-24]
    mov rsi, rax
    call entry_array_commit_size
    jmp _end_process_mov
_err_parse_mov:
_err_invalid_argc_mov:
_err_invalid_second_param_mov:
_err_invalid_first_param_mov:
    mov rdi, [rbp-16]
    call render_err_first_param
_err_exit_mov:
    exit_m -6
_end_process_mov:
    add rsp, 128
    pop rbp
    ret

; -8 passed rdi, -12 curr token buff offset, -16 reserve
; -24 curr token buf ptr; -32 ptr to render segm buff
; rdi - segment ptr
render_process_segment:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    xor rax, rax
    mov [rbp-8], rdi
    mov [rbp-12], eax
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-32], rdi
_start_loop_process_segment:
    mov rdi, [rbp-32]
    mov esi, 32
    call entry_array_ensure_free_space
    mov ecx, [rbp-12]
    mov r8, [rbp-8]
    mov ebx, [r8+8]
    cmp ecx, ebx
    jae _end_render_process_segment
    mov rdx, [r8]
    lea r9, [rdx+rcx]
    mov [rbp-24], r9
    movzx esi, word [r9+12]
    add ecx, esi
    mov [rbp-12], ecx
    lea r10, [r9+16]
    movzx ebx, byte [r10]
    cmp ebx, TOKEN_BUF_DIRECT
    jne _err_processing_start_token
    movzx eax, byte [r10+13]
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
    jae _end_start_render
    mov ecx, ebx
    inc ecx
    mov [rbp-4], ecx
    shr ebx, 3
    mov rdx, rsp
    add rdx, rbx
    mov rdi, [rdx]
    call render_process_segment
    jmp _render_seg_grab_loop    
_end_start_render:
    add rsp, 2304
    pop rbp
    ret
