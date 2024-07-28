;TODO: move remove mod/rm byte to sep. func.

; ins code struct (32 bytes)
; 0 (16 bytes) post opcodes bytes (1st byte is ModR/M), +16 (8 bytes) prefix bytes, +24 post opcode bytes count,
; +25 prefix bytes count, +26 1st arg size, +27 2nd arg size, +28 3rd arg size (3 bytes reserved)
INS_CODE_STRUCT_SIZE equ 32

MOD_RM_RM_MASK equ 0x07

REX   equ 0x40
REX_W equ 0x08
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

; rdi - ptr to TOKEN_BUF_PTR_OFFSET entry body
is_name_rip_ref:
    mov r8, [rdi]
    mov r9d, [rdi+8]
    mov r10, [r8]
    lea r11, [r10+r9]
    lea rax, [r10+r9+16]
    movzx edi, byte [r11+14]
    cmp edi, TOKEN_NAME_DATA
    je _end_is_name_rip_ref
    cmp edi, TOKEN_NAME_JMP
    je _end_is_name_rip_ref
    xor rax, rax
_end_is_name_rip_ref:
    ret

; rdi - ptr to TOKEN_BUF_PTR_OFFSET entry body
is_name_const:
    mov r8, [rdi]
    mov r9d, [rdi+8]
    mov r10, [r8]
    lea r11, [r10+r9]
    lea rax, [r10+r9+16]
    movzx edi, byte [r11+14]
    cmp edi, TOKEN_NAME_CONST
    je _end_is_name_const
    cmp edi, TOKEN_NAME_CONST_MUT
    je _end_is_name_const
    xor rax, rax
_end_is_name_const:
    ret

; rdi - ptr to TOKEN_BUF_PTR_OFFSET entrh body
; return rax - ptr to symbol, ebx - type
get_name_ref_type:
    mov r8, [rdi]
    mov r9d, [rdi+8]
    mov r10, [r8]
    lea r11, [r10+r9]
    lea rax, [r10+r9+16]
    movzx ebx, byte [r11+14]
    ret

; TODO: complete
; rdi - ptr to token entry
render_err_first_param:
    push rbp
    mov rbp, rsp
    pop rbp
    ret

; rdi - dest, rsi - source, ecx - size
shift_and_clear_postfix_buf:

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
    mov r12d, eax
    mov r13d, ebx
    and r12b, REG_REX_MASK
    and r13b, REG_REX_MASK
    shr r12b, 1
    shr r13b, 1
    or r12b, r13b
    mov r9b, r12b
    mov edx, eax
    mov ecx, ebx
    and eax, REG_MASK_REG_VAL
    and ebx, REG_MASK_REG_VAL
    and edx, REG_MASK_BITS
    and ecx, REG_MASK_BITS
    mov [rsi+26], dl
    mov [rsi+27], cl
    cmp ecx, REG_MASK_VAL_64B
    jne _gen_r_r_check_arg_th
    or r9b, REX_W
_gen_r_r_check_arg_th:
    cmp eax, REG_REX_TH
    jb _gen_r_r_2rex_check
    or r9b, REX_R
    and eax, REG_MASK_REG_IDX
_gen_r_r_2rex_check:
    cmp ebx, REG_REX_TH
    jb _gen_r_r_set_arg
    or r9b, REX_B
    and ebx, REG_MASK_REG_IDX
_gen_r_r_set_arg:
    xor r12, r12
    lea r11, [r10+16]
    shl eax, 3
    or r12b, al
    or r12b, bl
    or r12b, MOD_REG
    mov [r10], r12b
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
    mov [r11+rax], r9b
    inc eax
    mov [rsi+25], al
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

; rdi - ptr to imm token, rsi - ptr to ins code struct,
; edx - imm arg order in ins (0 based), ecx - dest bits size (for overflow check) 
render_process_imm:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-16], rsi
    mov [rbp-28], ecx
    lea rax, [rsi+rdx+26]
    mov [rbp-24], rax
    mov cl, [rdi]
    inc rdi
    mov [rbp-8], rdi
    cmp cl, TOKEN_BUF_PTR_OFFSET
    jne _rproc_imm
    call get_name_ref_type
    cmp ebx, TOKEN_NAME_DATA
    jne _rproc_imm_const
    mov rsi, [rbp-16]
    mov r9, [rbp-24]
    mov edx, [rbp-28]
    cmp edx, REG_MASK_VAL_32B
    jb _err_rproc_imm_overflow
    mov r10, rax
    xor ecx, ecx
    mov byte [r9], REG_MASK_VAL_32B
    movzx eax, byte [rsi+24]
    mov [rsi+rax], ecx
    add eax, 4
    mov [rsi+24], al
    ;TODO: add to patch list
    jmp _success_rproc_imm
_rproc_imm_const:
    lea rdi, [rbp-64]
    mov [rbp-8], rdi
    mov rsi, rax
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
_rproc_imm:
    mov r8, [rbp-8]
    mov rsi, [rbp-16]
    mov r9, [rbp-24]
    mov edx, [rbp-28]
    movzx eax, byte [rsi+24]
    movzx ebx, byte [r8+13]
    cmp ebx, 8
    ja __rproc_imm64
    mov byte [r9], REG_MASK_VAL_8B
    mov cl, [r8]
    mov [rsi+rax], cl
    inc al
    mov [rsi+24], al
    jmp _success_rproc_imm
__rproc_imm64:
    cmp edx, REG_MASK_VAL_64B
    jne __rproc_imm32
    cmp ebx, 33
    jb ___rproc_imm64_32
    mov byte [r9], REG_MASK_VAL_64B
    mov rcx, [r8]
    mov [rsi+rax], rcx
    add al, 8
    mov [rsi+24], al
    jmp _success_rproc_imm
___rproc_imm64_32:
    mov byte [r9], REG_MASK_VAL_32B
    mov ecx, [r8]
    mov [rsi+rax], ecx
    add al, 4
    mov [rsi+24], al
    jmp _success_rproc_imm
__rproc_imm32:
    cmp edx, REG_MASK_VAL_32B
    jne __rproc_imm16
    cmp ebx, 32
    ja _err_rproc_imm_overflow
    jmp ___rproc_imm64_32
__rproc_imm16:
    cmp edx, REG_MASK_VAL_16B
    jne _err_rproc_imm_overflow
    cmp ebx, 16
    ja _err_rproc_imm_overflow
    mov byte [r9], REG_MASK_VAL_16B
    mov cx, [r8]
    mov [rsi+rax], cx
    add al, 2
    mov [rsi+24], al
    jmp _success_rproc_imm
_err_rproc_imm_overflow:
    mov eax, 1
    jmp _end_render_process_imm
_success_rproc_imm:
    xor eax, eax
_end_render_process_imm:
    add rsp, 64
    pop rbp
    ret

; for r_i version by default used r/m, imm version
; rdi - ptr to ins param, rsi - ptr to inc code struct
; return eax - 0 if succes, 1 if imm less then reg
process_gen_rm_i:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-16], rsi
    mov r10, rsi
    xor r9, r9
    lea r8, [rdi+15]
    mov eax, [rdi+9]
    mov r12d, eax
    and r12b, REG_REX_MASK
    shr r12b, 1
    mov r9b, r12b
    mov edx, eax
    and eax, REG_MASK_REG_VAL
    and edx, REG_MASK_BITS
    mov [rsi+26], dl
    cmp edx, REG_MASK_VAL_64B
    jne _gen_rm_i_check_arg_th
    or r9b, REX_W
_gen_rm_i_check_arg_th:
    cmp eax, REG_REX_TH
    jb _gen_rm_i_set_arg
    or r9b, REX_B
    and eax, REG_MASK_REG_IDX
_gen_rm_i_set_arg:
    xor r12, r12
    lea r11, [r10+16]
    or r12b, MOD_REG
    or r12b, al
    mov [r10], r12b
    inc byte [rsi+24]
    cmp edx, REG_MASK_VAL_16B
    jne _gen_rm_i_set_prefix
    mov byte [r11], PREFIX_16BIT
    inc byte [rsi+25]
_gen_rm_i_set_prefix:
    test r9b, r9b
    jz _gen_rm_i_set_postfix
    movzx eax, byte [rsi+25]
    mov [r11+rax], r9b
    inc eax
    mov byte [rsi+25], al
_gen_rm_i_set_postfix:
    mov rdi, r8
    mov ecx, edx
    mov edx, 1
    call render_process_imm
_end_process_gen_rm_i:
    add rsp, 16
    pop rbp
    ret

; -8 passed rdi, -16 passed rsi, -20 passed edx, -24 1st reg token val, -28 1st reg masked val
; -32 2nd reg token val, -40 ptr to aux token, -48 ptr to 2nd param, -56 ptr to and of addr token group
; (3 reserved) -60 temp sib byte/r8d passed, -128 temp token storage
; rdi - ptr to addr token group, rsi - ptr to ins code struct, edx - rex preffix
; ecx - addr arg order in ins (0 based), r8d - source/dest of addr arg order in ins
render_process_addr:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], edx
    mov [rbp-60], r8d
    lea r11, [rsi+rcx+26]
    movzx ecx, byte [rdi+2]
    lea rax, [rdi+rcx]
    mov [rbp-56], rax
    lea r8, [rdi+3]
    movzx eax, byte [r8]
    cmp eax, TOKEN_BUF_DIRECT
    jne _rproc_addr_start_pre_check
    movzx ebx, byte [rdi+16]
    cmp ebx, TOKEN_TYPE_KEYWORD
    jne _rproc_addr_start_pre_check
    mov eax, [rdi+12]
    mov r12b, REG_MASK_VAL_8B 
    mov r13b, REG_MASK_VAL_16B
    mov r14b, REG_MASK_VAL_32B
    mov r15b, REG_MASK_VAL_64B
    cmp eax, KW_BYTE
    cmove ecx, r12d 
    cmp eax, KW_WORD
    cmove ecx, r13d 
    cmp eax, KW_DWORD
    cmove ecx, r14d 
    cmp eax, KW_QWORD
    cmove ecx, r15d 
    mov [r11], cl
    add r8, 15
    jmp _rproc_addr_start_check
_rproc_addr_start_pre_check:
    mov ecx, [rbp-60]
    lea r12, [rsi+rcx+26]
    mov dl, [r12]
    mov [r11], dl
_rproc_addr_start_check:
    movzx ebx, byte [r8] 
    movzx eax, byte [rdi+1]
    cmp eax, 1
    je _rproc_addr_1p
    cmp eax, 2
    jae _rproc_addr_2p
    jmp _err_rproc_count
_rproc_addr_1p:
    cmp ebx, TOKEN_BUF_DIRECT
    jne __rproc_addr_1p_ref_check
    mov r9b, [rsi]
    mov eax, [r8+9]
    mov ecx, eax
    mov edx, eax
    and ecx, REG_MASK_REG_VAL
    and edx, REG_MASK_BITS
    cmp edx, REG_MASK_VAL_64B
    jne _err_rproc_addr_invalid_reg_size
    cmp eax, REG_RBP
    je _rproc_addr_1p_rbp
    cmp eax, REG_RSP
    je _rproc_addr_1p_rsp
    cmp ecx, REG_REX_TH
    jb __rproc_addr_1p_reg
    mov r11b, REX_B
    or r11b, REX
    or [rbp-20], r11b
    and ecx, REG_MASK_REG_IDX
 __rproc_addr_1p_reg:
    or r9b, MOD_ADDR_REG
    or r9b, cl
    mov [rsi], r9b
    jmp _success_render_process_addr
_rproc_addr_1p_rbp:
    or r9b, MOD_ADDR_REG_DISP8
    or r9b, cl
    mov [rsi], r9b
    mov byte [rsi+1], 0
    inc byte [rsi+24]
    jmp _success_render_process_addr
_rproc_addr_1p_rsp:
    or r9b, MOD_ADDR_REG
    or r9b, cl
    mov [rsi], r9b
    xor r10, r10
    or r10b, cl
    shl r10b, 3
    or r10b, cl
    mov [rsi+1], r10b
    inc byte [rsi+24]
    jmp _success_render_process_addr
__rproc_addr_1p_ref_check:
    cmp ebx, TOKEN_BUF_PTR_OFFSET
    jne _err_rproc_1param_invalid
    lea rdi, [r8+1]
    call is_name_rip_ref
    test eax, eax
    jz _err_rproc_invalid_ref_name
    ;TODO: add to patch list of offset
    mov rsi, [rbp-16]
    mov r9b, [rsi]
    or r9b, MOD_ADDR_REG
    or r9b, 0x5
    mov [rsi], r9b
    mov dword [rsi+1], 0
    add byte [rsi+24], 4
    jmp _success_render_process_addr
_rproc_addr_2p:
    cmp ebx, TOKEN_BUF_DIRECT
    jne __rproc_addr_2p_ref_check
    mov eax, [r8+9]
    mov ecx, eax
    mov edx, eax
    and ecx, REG_MASK_REG_VAL
    and edx, REG_MASK_BITS
    cmp edx, REG_MASK_VAL_64B
    jne _err_rproc_addr_invalid_reg_size
    cmp ecx, REG_REX_TH
    jb __rproc_addr_2p_check_arith1
    mov r11b, REX_B
    or r11b, REX
    or [rbp-20], r11b
    and ecx, REG_MASK_REG_IDX
__rproc_addr_2p_check_arith1:
    mov [rbp-24], eax
    mov [rbp-28], ecx
    lea r9, [r8+30]
    add r8, 15
    mov [rbp-40], r8
    mov [rbp-48], r9
    mov dl, [r9]
    cmp dl, TOKEN_BUF_DIRECT
    jne __rproc_addr_2p_ptr_offset_check
    mov bl, [r9+13]
    cmp bl, TOKEN_TYPE_DIGIT
    jne __rproc_addr_2p_2nd_reg
    lea r15, [r9+1]
    mov ecx, [r8+9]
    jmp __rproc_addr_2p_ptr_digit_neg_chech 
__rproc_addr_2p_ptr_offset_check:
    cmp dl, TOKEN_BUF_PTR_OFFSET
    jne __rproc_addr_2p_2nd_reg
    lea rdi, [r9+1]
    call is_name_const
    test rax, rax
    jz _err_rproc_second_param_non_const
    mov r8, [rbp-40]
    mov r9, [rbp-48]
    lea rdi, [rbp-128]
    mov r15, rdi
    mov rsi, rax
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    mov ecx, [r8+9]
__rproc_addr_2p_ptr_digit_neg_chech:
    cmp ecx, AUX_SUB
    jne __rproc_addr_2p_r_d
    mov r12, [r15]
    neg qword [r15]   
__rproc_addr_2p_r_d:
    movzx ecx, byte [r15+13]
    mov ebx, MOD_ADDR_REG_DISP8
    mov esi, MOD_ADDR_REG_DISP32
    cmp ecx, 8
    cmovg ebx, esi
    mov rsi, [rbp-16]
    mov ecx, [rbp-28]
    mov r9b, [rsi]
    or r9b, bl
    or r9b, cl
    mov [rsi], r9b
    mov eax, [rbp-24]
    cmp eax, REG_RSP
    jne __rproc_addr_2p_r_d_set_disp
_rproc_addr_2p_r_d_rsp:
    xor r10, r10
    or r10b, cl
    shl r10b, 3
    or r10b, cl
    mov [rsi+1], r10b
    inc byte [rsi+24]
__rproc_addr_2p_r_d_set_disp:
    movzx edx, byte [rsi+24]
    cmp ebx, MOD_ADDR_REG_DISP8
    jne ___rproc_addr_2p_r_d_disp32 
    mov al, [r15]
    mov [rsi+rdx], al
    inc byte [rsi+24]
    jmp _success_render_process_addr
___rproc_addr_2p_r_d_disp32:
    mov eax, [r15]
    mov [rsi+rdx], eax
    add byte [rsi+24], 4
    jmp _success_render_process_addr
__rproc_addr_2p_2nd_reg:
    mov ebx, [r8+9]
    cmp ebx, AUX_ADD
    jne _err_rproc_addr_2p_sub_reg
    mov eax, [r9+9]
    mov [rbp-32], eax
    cmp eax, REG_RSP
    je _err_rproc_addr_invalid_2nd
    xor r15, r15
    mov ecx, eax
    mov edx, eax
    and ecx, REG_MASK_REG_VAL
    and edx, REG_MASK_BITS
    cmp edx, REG_MASK_VAL_64B
    jne _err_rproc_addr_invalid_reg_size
    cmp ecx, REG_REX_TH
    jb __rproc_addr_2p_sib_init
    mov r11b, REX_X
    or r11b, REX
    or [rbp-20], r11b
    and ecx, REG_MASK_REG_IDX
__rproc_addr_2p_sib_init:
    shl ecx, 3
    mov ebx, [rbp-28]
    or r15b, bl
    or r15b, cl
    mov [rbp-60], r15b
    lea r8, [r9+15]
    mov rcx, [rbp-56]
    cmp r8, rcx
    je __rproc_addr_2p_r_r_set
    mov cl, [r8]
    cmp cl, TOKEN_BUF_PTR_OFFSET
    jne ___rproc_addr_2p_sib_check
    lea r9, [r8+13]
    mov [rbp-40], r8
    mov [rbp-48], r9
    lea rdi, [r8+1]
    call is_name_const
    test rax, rax
    jz _err_rproc_second_param_non_const
    lea rdi, [rbp-128]
    mov r15, rdi
    mov rsi, rax
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    jmp ___rproc_addr_2p_sib_scale 
___rproc_addr_2p_sib_check:
    cmp cl, TOKEN_BUF_DIRECT
    jne _err_rproc_addr_invalid_2nd
    mov al, [r8+13]
    cmp al, TOKEN_TYPE_DIGIT
    jne __rproc_adder_2p_3rd_check
    lea r9, [r8+15]
    mov [rbp-48], r9
    lea r15, [r8+1]
___rproc_addr_2p_sib_scale:
    movzx eax, byte [r15+13]
    cmp eax, 4
    ja _err_rproc_addr_invalid_scale
    movzx edx, byte [r15]
    mov ecx, 0x01010101
    mov ebx, 0x08040201
    imul ecx, edx
    and ecx, ebx
    test ecx, ecx
    jz _err_rproc_addr_invalid_scale
    mov edi, edx
    call log2_val_ceil
    shl al, 6
    or [rbp-60], al
__rproc_adder_2p_3rd_check:
    mov rdx, [rbp-56]
    mov r9, [rbp-48]
    cmp rdx, r9
    je __rproc_addr_2p_r_r_set
    mov r8, r9
    lea r9, [r8+15]
    mov eax, [r8+9]
    cmp eax, AUX_ADD
    je __rproc_addr_3p_disp
    cmp eax, AUX_SUB
    je __rproc_addr_3p_disp
__rproc_addr_2p_r_r_set:
    mov rsi, [rbp-16]
    mov edx, [rbp-24]
    mov cl, [rbp-60]
    mov bl, [rsi]
    mov [rsi+1], cl
    inc byte [rsi+24]
    mov al, MOD_ADDR_REG
    cmp edx, REG_RBP
    jne ___rproc_addr_2p_r_r_skip_rbp
    mov al, MOD_ADDR_REG_DISP8
    mov byte [rsi+2], 0
    inc byte [rsi+24]
___rproc_addr_2p_r_r_skip_rbp:
    or bl, al
    or bl, 0x4
    mov [rsi], bl
    jmp _success_render_process_addr
__rproc_addr_3p_disp:
    mov [rbp-40], r8
    mov [rbp-48], r9
    mov dl, [r9]
    inc r9
    cmp dl, TOKEN_BUF_PTR_OFFSET
    jne __rproc_addr_3p_disp_digit
    mov rdi, r9
    call is_name_const
    test rax, rax
    jz _err_rproc_second_param_non_const
    mov r8, [rbp-40]
    lea rdi, [rbp-128]
    mov r9, rdi
    mov rsi, rax
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
__rproc_addr_3p_disp_digit:
    mov ebx, [r8+9]
    cmp ebx, AUX_SUB
    jne ___rproc_addr_3p_skip_neg
    neg qword [r9]
___rproc_addr_3p_skip_neg:
    mov rsi, [rbp-16]
    mov bl, [rbp-60]
    mov [rsi+1], bl
    inc byte [rsi+24]
    mov al, [r9+13]
    cmp al, 8
    mov dl, 0x4
    ja ___rprc_addr_3p_disp32
    or dl, MOD_ADDR_REG_DISP8
    or byte [rsi], dl
    mov cl, [r9]
    mov [rsi+2], cl
    inc byte [rsi+24]
    jmp _success_render_process_addr
___rprc_addr_3p_disp32:
    or dl, MOD_ADDR_REG_DISP32
    or byte [rsi], dl
    mov ecx, [r9]
    mov [rsi+2], ecx
    add byte [rsi+24], 4
    jmp _success_render_process_addr
__rproc_addr_2p_ref_check:
    ;TODO: Add to patch list
    cmp ebx, TOKEN_BUF_PTR_OFFSET
    jne _err_rproc_1param_invalid
    mov [rbp-40], r8
    lea rdi, [r8+1]
    call is_name_rip_ref
    test rax, rax
    jz _err_rproc_invalid_ref_name
    mov r8, [rbp-40]
    lea r9, [r8+13]
    lea r8, [r9+15]
    mov [rbp-40], r8
    mov [rbp-48], r9
    lea r15, [r8+1]
    movzx eax, byte [r8]
    cmp eax, TOKEN_BUF_PTR_OFFSET
    jne __rproc_addr_2p_ref_neg_check
    mov rdi, r15
    call is_name_const
    test rax, rax
    jz _err_rproc_invalid_ref_name
    lea rdi, [rbp-128]
    mov r15, rdi
    mov rsi, rax
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    mov r8, [rbp-40]
    mov r9, [rbp-48]
__rproc_addr_2p_ref_neg_check:
    mov ebx, [r9+9]
    cmp ebx, AUX_SUB
    jne __rproc_addr_2p_ref_set
    neg qword [r15]
__rproc_addr_2p_ref_set:
    mov rsi, [rbp-16]
    mov r10b, [rsi]
    or r10b, MOD_ADDR_REG
    or r10b, 0x5
    mov [rsi], r10b
    mov edx, [r15]
    mov [rsi+1], edx
    add byte [rsi+24], 4
    jmp _success_render_process_addr
_err_rproc_addr_invalid_scale:
_err_rproc_addr_invalid_const:
_err_rproc_addr_invalid_2nd:
_err_rproc_addr_2p_sub_reg:
_err_rproc_addr_invalid_reg_size:
_err_rproc_1param_invalid:
_err_rproc_invalid_ref_name:
_err_rproc_second_param_non_const:
_err_rproc_count:
    exit_m -1
_success_render_process_addr:
    xor rax, rax
    mov ebx, [rbp-20]
_end_render_process_addr:
    add rsp, 128
    pop rbp
    ret

; rdi - ptr to ins param, rsi - ptr to inc code struct
process_gen_r_a:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    xor r9, r9
    mov eax, [rdi+9]
    mov r12d, eax
    and r12b, REG_REX_MASK
    shr r12b, 1
    mov r9b, r12b
    mov edx, eax
    and eax, REG_MASK_REG_VAL
    and edx, REG_MASK_BITS
    mov [rsi+26], dl
    cmp edx, REG_MASK_VAL_64B
    jne _gen_r_a_arg_th
    or r9b, REX_W
_gen_r_a_arg_th:
    cmp eax, REG_REX_TH
    jb _gen_r_a_init_rm
    or r9b, REX_R
    and eax, REG_MASK_REG_IDX
_gen_r_a_init_rm:
    xor r12, r12
    shl eax, 3
    or r12b, al
    mov byte [rsi], r12b
    inc byte [rsi+24]
    cmp edx, REG_MASK_VAL_16B
    jne _gen_r_a_addr_check
    mov byte [rsi+16], PREFIX_16BIT
    inc byte [rsi+25]
_gen_r_a_addr_check:
    add rdi, 15
    mov edx, r9d
    mov ecx, 1
    xor r8, r8
    call render_process_addr
    test rax, rax
    jnz _err_process_gen_r_a
    mov r9d, ebx
    test r9b, r9b
    jz _success_gen_r_a
    mov rsi, [rbp-16]
    lea r11, [rsi+16]
    movzx eax, byte [rsi+25]
    mov [r11+rax], r9b
    inc al
    mov [rsi+25], al
    jmp _success_gen_r_a
_err_process_gen_r_a:
_success_gen_r_a:
    xor rax, rax
_end_process_gen_r_a:
    add rsp, 16
    pop rbp
    ret

; rdi - ptr to ins param, rsi - ptr to inc code struct
process_gen_a_r:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    movzx edx, byte [rdi+2]
    lea r10, [rdi+rdx]
    xor r9, r9
    mov eax, [r10+9]
    mov r12d, eax
    and r12d, REG_REX_MASK
    shr r12b, 1
    mov r9b, r12b
    mov edx, eax
    and eax, REG_MASK_REG_VAL
    and edx, REG_MASK_BITS
    mov [rsi+27], dl
    cmp edx, REG_MASK_VAL_64B
    jne _gen_a_r_arg_th
    or r9b, REX_W
_gen_a_r_arg_th:
    cmp eax, REG_REX_TH
    jb _gen_a_r_init_rm
    or r9b, REX_R
    and eax, REG_MASK_REG_IDX
_gen_a_r_init_rm:
    xor r12, r12
    shl eax, 3
    or r12b, al
    mov byte [rsi], r12b
    inc byte [rsi+24]
    cmp edx, REG_MASK_VAL_16B
    jne _gen_a_r_addr_check
    mov byte [rsi+16], PREFIX_16BIT
    inc byte [rsi+25]
_gen_a_r_addr_check:
    mov edx, r9d
    xor ecx, ecx
    mov r8d, 1
    call render_process_addr
    test rax, rax
    jnz _err_process_gen_a_r
    mov r9d, ebx
    test r9b, r9b
    jz _success_gen_r_a
    mov rsi, [rbp-16]
    lea r11, [rsi+16]
    movzx eax, byte [rsi+25]
    mov [r11+rax], r9b
    inc eax
    mov [rsi+25], al
    jmp _success_gen_r_a
_err_process_gen_a_r:
_success_gen_a_r:
    xor rax, rax
_end_process_gen_a_r:
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
    movzx eax, byte [rsi+26]
    movzx ebx, byte [rsi+27]
    cmp eax, ebx
    jne _err_arg_size_mov
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
    mov rdi, rsi
    lea rsi, [rbp-128]
    call process_gen_r_a
    test eax, eax
    jnz _err_parse_mov
    lea rsi, [rbp-128]
    movzx eax, byte [rsi+26]
    movzx ebx, byte [rsi+27]
    cmp eax, ebx
    jne _err_arg_size_mov
    cmp eax, REG_MASK_VAL_8B
    jne ___mov_r_a_non_byte_opcode
    mov byte [rbp-42], 0x8A
    jmp _mov_accemble
___mov_r_a_non_byte_opcode:
    mov byte [rbp-42], 0x8B
    jmp _mov_accemble
__mov_r_i:
    mov rdi, rsi
    lea rsi, [rbp-128]
    call process_gen_rm_i
    test eax, eax
    jnz _err_parse_mov
    lea r8, [rbp-128]
    movzx ebx, byte [r8+26]
    cmp ebx, REG_MASK_VAL_8B
    jne ___mov_r_i_non_byte_opcode
    mov byte [rbp-42], 0xB0
    jmp ___mov_r_i_reg_opc_remove_modrm 
___mov_r_i_non_byte_opcode:
    mov byte [rbp-42], 0xB8
    cmp ebx, REG_MASK_VAL_64B
    jne ___mov_r_i_reg_opc_remove_modrm
    movzx eax, byte [r8+27]
    cmp eax, REG_MASK_VAL_32B
    ja ___mov_r_i_reg_opc_remove_modrm
    mov byte [rbp-42], 0xC7
    cmp eax, REG_MASK_VAL_32B
    je _mov_accemble
    mov r10d, 3
    mov r11d, 2
    cmp eax, REG_MASK_VAL_8B
    cmove ecx, r10d
    cmp eax, REG_MASK_VAL_16B
    cmove ecx, r11d
    movzx edx, byte [r8+24]
    lea r9, [r8+rdx]
    jmp ___mov_r_i_reg_opc_ext_mod 
___mov_r_i_reg_opc_remove_modrm:
    mov bl, [rbp-42] 
    mov al, [r8]
    and al, MOD_RM_RM_MASK
    or bl, al
    mov [rbp-42], bl
    ;TODO: handle sign digit in right way
    movzx ecx, byte [r8+24]
    dec ecx
    mov [r8+24], cl
    mov r9, r8
    mov rdi, r8
    inc r9
    mov rsi, r9
    rep movsb
    movzx eax, byte [r8+27]
    movzx ebx, byte [r8+26]
    cmp eax, REG_MASK_VAL_8B
    jne _mov_accemble
    cmp ebx, REG_MASK_VAL_8B
    je _mov_accemble
    mov r10d, 1
    mov r11d, 3
    mov r12d, 7
    cmp ebx, REG_MASK_VAL_16B
    cmove ecx, r10d
    cmp ebx, REG_MASK_VAL_32B
    cmove ecx, r11d
    cmp ebx, REG_MASK_VAL_64B
    cmove ecx, r12d
___mov_r_i_reg_opc_ext_mod:
    xor eax, eax
    mov r13d, ecx
    mov rdi, r9
    rep stosb
    add [r8+24], r13b
    jmp _mov_accemble
_mov_a:
    movzx eax, byte [rsi+2]
    lea r9, [rsi+rax]
    movzx ecx, byte [r9]
    cmp ecx, TOKEN_BUF_PTR_OFFSET
    je __mov_r_i
    cmp ecx, TOKEN_BUF_DIRECT
    jne _err_invalid_second_param_mov
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    je __mov_a_r
    cmp ebx, TOKEN_TYPE_DIGIT
    je __mov_a_i
    jmp _err_invalid_second_param_mov
__mov_a_r:
    mov rdi, rsi
    lea rsi, [rbp-128]
    call process_gen_a_r
    test eax, eax
    jnz _err_parse_mov
    lea rsi, [rbp-128]
    movzx eax, byte [rsi+26]
    movzx ebx, byte [rsi+27]
    cmp eax, ebx
    jne _err_arg_size_mov
    cmp eax, REG_MASK_VAL_8B
    jne ___mov_a_r_non_byte_opcode
    mov byte [rbp-42], 0x88
    jmp _mov_accemble
___mov_a_r_non_byte_opcode:
    mov byte [rbp-42], 0x89
    jmp _mov_accemble
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
_err_arg_size_mov:
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
    jmp _end_render_process_segment
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
    shl ebx, 3
    mov rdx, rsp
    add rdx, rbx
    mov rdi, [rdx]
    call render_process_segment
    jmp _render_seg_grab_loop    
_end_start_render:
    add rsp, 2304
    pop rbp
    ret
