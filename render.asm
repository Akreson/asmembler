; ins code struct (32 bytes)
; 0 (16 bytes) post opcodes bytes (1st byte is ModR/M), +16 (6 bytes) prefix bytes,
; +22 16 bit addr prefix, +23 16 bit op prefix +24 post opcode bytes count,
; +25 prefix buff bytes count, +26 1st arg size, +27 2nd arg size, +28 3rd arg size,
; +29 (4) opcode bytes, +33 opcode bytes count, +34 ins operands type, (1 byte reserved)
; +36 1st op reg, +40 2nd op reg, +44 3rd op reg, +48 4th op reg, +52 rex byte
INS_CODE_STRUCT_SIZE equ 64

OP1_TYPE_R equ 0x1
OP1_TYPE_A equ 0x2
OP1_TYPE_I equ 0x3
OP2_TYPE_R equ 0x4
OP2_TYPE_A equ 0x8
OP2_TYPE_I equ 0xC
OP3_TYPE_R equ 0x10
OP3_TYPE_A equ 0x20
OP3_TYPE_I equ 0x30

OP12_TYPE_R_R equ 0x5
OP12_TYPE_R_A equ 0x6
OP12_TYPE_R_I equ 0x7
OP12_TYPE_A_R equ 0xA
OP12_TYPE_A_I equ 0xB

MOD_RM_RM_MASK equ 0x07

REX   equ 0x40
REX_W equ 0x08
REX_R equ 0x04
REX_X equ 0x02
REX_B equ 0x01
EXC_REX_W equ 0xF7

MOD_ADDR_REG        equ 0
MOD_ADDR_REG_DISP8  equ 0x40
MOD_ADDR_REG_DISP32 equ 0x80
MOD_REG             equ 0xC0

RM_SIB equ 0x04

PREFIX_16BIT equ 0x66

ADDR_PATCH_TYPE_MAIN_MASK equ 0x0F
ADDR_PATCH_TYPE_NONE    equ 0
ADDR_PATCH_TYPE_DEF_RIP equ 0x01
ADDR_PATCH_TYPE_JMP_RIP equ 0x11
ADDR_PATCH_TYPE_JCC_RIP equ 0x21
ADDR_PATCH_TYPE_ABS     equ 0x02

segment readable writeable

CURR_SECTION_OFFSET dd 0

; entry body - 0 ptr to sym, +8 ptr to token entry header,
; +16 (1) type, +17 offset to disp from start of ins, (2b reserved)
; +20 offset of section to patch in
ADDR_ARR_PATCH_ENTRY_SIZE equ 24
DELAYED_PATCH_ARR dq 0
dd 0, 0, ADDR_ARR_PATCH_ENTRY_SIZE

; TODO: move this struct to segment entry?
; entry body - +4 (1) type, +5 offset to disp from start of ins
; +6 max size of disp, +7 min size of disp
; +8 ptr to symbol, +16 ptr to token entry header
SEGMENT_PATCH_ENTRY_SIZE equ 24
SEGMENT_PATCH_LIST dq 0
dd 0, 0, SEGMENT_PATCH_ENTRY_SIZE
dd 0, 0

SEGMENT_PATCH_ARR dq 0
dd 0, 0, SEGMENT_PATCH_ENTRY_SIZE

TEMP_SYM_PTR_ARR dq 0
dd 0, 0, 8

segment readable executable

clear_patch_state:
    xor ebx, ebx
    mov rax, SEGMENT_PATCH_LIST
    mov [rax+8], ebx
    mov [rax+20], ebx
    mov [rax+24], ebx
    mov rcx, TEMP_SYM_PTR_ARR
    mov [rcx+8], ebx
    ret
; NOTE: all encoding must be with max disp size

; rdi - sym ptr, rsi - ptr to token entry header, rdx - ptr to ins code struct
; ecx - type, r8d - max disp size (in bytes), r9d - min disp size (can be set to 0 if max == min)
push_to_segment_patch:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-28], ecx
    mov [rbp-32], r8d
    cmp r9d, 0
    cmove r9d, r8d
    mov [rbp-36], r9d
    mov rdi, SEGMENT_PATCH_LIST
    mov ecx, [rdi+24]
    mov [rbp-52], ecx
    call list_get_free
    test eax, eax
    jnz _add_link_to_seg_patch
    exit_m -8
_add_link_to_seg_patch:
    mov [rbp-40], eax
    mov [rbp-48], rbx
    mov rdx, [rbp-24]
    xor ecx, ecx
    add cl, byte [rdx+25]
    add cl, byte [rdx+33]
    add cl, byte [rdx+24]
    mov r8, [rbp-8]
    sub r8, 16
    mov r9, [rbp-16]
    mov r11d, [rbp-28]
    mov r12d, [rbp-32]
    mov r13d, [rbp-36]
    mov r14d, [rbp-52]
    mov [rbx], r14d
    mov [rbx+4], r11b
    mov [rbx+5], cl
    mov [rbx+6], r12b
    mov [rbx+7], r13b
    mov [rbx+8], r8
    mov [rbx+16], r9
_end_push_to_segment_patch:
    add rsp, 64
    pop rbp
    ret

; rdi - sym ptr, rsi - ptr to token entry header, rdx - ptr to ins code struct
; ecx - type 
push_to_delayed_patch:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-28], ecx
_end_push_to_delayed_patch:
    add rsp, 64
    pop rbp
    ret

; rdi - sym ptr, rsi - ptr to token entry header, rdx - ptr to ins code struct
; ecx - type, r8d - max disp size (in bytes), r9d - min disp size (can be set to 0 if max == min)
push_to_addr_patch:
    push rbp
    mov rbp, rsp
    mov eax, dword [CURR_SECTION_OFFSET]
    mov ebx, [rdi+16]
    cmp eax, ebx
    jne _delayed_push_tap
    call push_to_segment_patch
    jmp _end_push_to_addr_patch
_delayed_push_tap:
    call push_to_delayed_patch
_end_push_to_addr_patch:
    pop rbp
    ret

; -8 passed rdi, -12 pased esi, -16 offset to the next name sym entry
; -24 ptr to curr name sym, -32 ptr to end of name sym buff
; rdi - ptr to temp arr, esi - segment offset
collect_segment_rip_sym:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-8], rdi
    mov [rbp-12], esi
    mov r8, NAME_SYM_REF_ARRAY
    mov rdx, [r8]
    mov eax, [r8+8]
    lea r10, [rdx+rax]
    mov [rbp-24], rdx
    mov [rbp-32], r10
    mov esi, 1
    call entry_array_reserve_size
    xor rbx, rbx
    mov [rax], rbx
    xor ecx, ecx
    mov [rbp-16], ecx
    mov rdx, [rbp-24]
    mov r10, [rbp-32]
    mov esi, [rbp-12]
_start_loop_csrs:
    add rdx, rcx
    cmp rdx, r10
    jge _end_collect_segment_rip_sym
    mov ebx, [rdx+32]
    cmp ebx, esi
    jne _start_loop_csrs
    movzx eax, byte [rdx+30]
    cmp eax, TOKEN_NAME_JMP
    je _check_seg_offset_csrs
    cmp eax, TOKEN_NAME_DATA
    jne _start_loop_csrs
_check_seg_offset_csrs:
    mov ecx, [rdx]
    mov [rbp-24], rdx
    mov [rbp-16], ecx
    mov rdi, [rbp-8]
    mov esi, 1
    call entry_array_reserve_size
    mov rdx, [rbp-24]
    mov [rax], rdx
    mov esi, [rbp-12]
    mov ecx, [rbp-16]
    mov r10, [rbp-32]
    jmp _start_loop_csrs
_end_collect_segment_rip_sym:
    add rsp, 64
    pop rbp
    ret

; rdi - ptr to temp arr
ensure_segment_sym_order:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov rdx, [rdi]
    mov eax, [rdi+8]
    shl eax, 3
    mov rsi, rdx
    add rsi, rax
    add rdx, 8
    xor ecx, ecx
    xor eax, eax
_start_loop_esso:
    cmp rdx, rsi
    jge _end_ensure_segment_sym_order
    mov ecx, eax
    mov rbx, [rdx]
    add rdx, 8
    mov eax, [rbx+36]
    cmp eax, ecx
    jg _start_loop_esso
_sort_sym_esso:
    exit_m -6
_end_ensure_segment_sym_order:
    add rsp, 16
    pop rbp
    ret

; TODO: check if ecx neg (for make room for encode long offset back)
; rdi - ptr to token buff entry_array, rsi - ptr to render entry_array
; rdx - ptr to header start from, ecx - amount of bytes to shift
reduce_ins_offset:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], ecx
    movzx ebx, byte [rdx+15]
    mov eax, [rdx]
    add eax, ebx
    mov r8, [rsi]
    mov r9d, [rsi+8]
    lea rdi, [r8+rax]
    mov rsi, rdi
    add rsi, rcx
    mov ecx, r9d
    rep movsb
    mov rdi, [rbp-8]
    mov r8, [rdi]
    mov r9d, [rdi+8]
    add r8, r9
    mov ecx, [rbp-20]
    neg ecx ; TODO: revisit
    movzx eax, word [rdx+12]
    add rdx, rax
_start_loop_reduce_io:
    cmp rdx, r8
    jge _end_reduce_ins_offset
    mov rsi, rdx
    movzx eax, word [rdx+12]
    mov bl, [rdx+14]
    add rdx, rax
    test bl, bl
    jnz _start_loop_reduce_io
    add [rsi], ecx
    jmp _start_loop_reduce_io 
_end_reduce_ins_offset:
    mov eax, [rbp-20]
    mov rsi, [rbp-16]
    sub [rsi+8], eax
    add rsp, 32
    pop rbp
    ret

; TODO: Fix rip ref before rip ref
; (now _n_ rip ref don't look at previous rip ref between _mark_n_ and _n_ ref)
; -8 curr checked sym thr ptr, -16 start of temp sym ptr buff,
; -24 ptr to curr seg patch entry, -28 next offset in patch linked list
; -32 prev offset of in patch linked list, -40 ptr to start of linked list buff
; -48 ptr to seg token buff entry_array, -56 ptr to render entry_array
; -64 ptr to start of render buf, -72 ptr to start of token buff,
; -76 curr offset in patch linked list
; edi - curr seg offset
render_patch_segment_addr:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov rax, SEG_ENTRY_ARRAY
    mov rbx, [rax]
    lea rcx, [rbx+rdi]
    lea rdx, [rbx+rdi+20]
    mov [rbp-48], rcx
    mov [rbp-56], rdx
    mov rax, [rcx]
    mov rbx, [rdx]
    mov [rbp-72], rax
    mov [rbp-64], rbx
    mov esi, edi
    mov rdi, TEMP_SYM_PTR_ARR
    call collect_segment_rip_sym
    mov rdi, TEMP_SYM_PTR_ARR
    mov eax, [rdi+8]
    test eax, eax
    jz _end_render_patch_segment_addr
    call ensure_segment_sym_order
    mov r8, TEMP_SYM_PTR_ARR
    mov r9, [r8]
    mov eax, [r8+8]
    dec eax
    shl eax, 3
    lea rdx, [r9+rax]
    mov [rbp-8], rdx
    mov [rbp-16], r9
    mov r10, SEGMENT_PATCH_LIST
    mov r11, [r10]
    mov [rbp-40], r11
    mov ebx, [r10+24]
    lea rsi, [r11+rbx]
    mov [rbp-24], rsi
    mov [rbp-76], ebx
    mov dword [rbp-32], ebx
_start_loop_seg_rpsa:
    mov r10, [rbp-72]
    mov ecx, [rsi]
    mov [rbp-28], ecx
    mov r8, [rsi+16]
    mov r9, [rsi+8]
    mov edi, [r8]
    mov r11d, [r9+36]
    lea r12, [r10+r11]
    mov eax, [r12]
    mov rbx, [rdx]
    test rbx, rbx
    jz _skip_bound_cheks_rpsa
    mov r11d, [rbx+36]
    lea r12, [r10+r11]
    mov esi, [r12]
    cmp edi, esi
    jl _next_sym_ptr_rpsa
    cmp eax, esi
    jl _next_patch_entry_rpsa
_skip_bound_cheks_rpsa:
    mov r9d, edi
    movzx ebx, byte [r8+15]
    add edi, ebx
    sub eax, edi
    mov rdx, [rbp-64]
    lea rcx, [rdx+r9]
    mov rsi, [rbp-24]
    movzx edi, byte [rsi+5]
    mov r9d, [rcx+rdi]
    add eax, r9d
    xor edi, edi
    mov r10b, MAX_INT8
    mov r11b, MIN_INT8
    movsx r10d, r10b
    movsx r11d, r11b
    cmp eax, r10d
    jg __check_jcc_patch_rpsa
    cmp eax, r11d
    jl __check_jcc_patch_rpsa
    inc edi
__check_jcc_patch_rpsa:
    movzx edx, byte [rsi+4]
    cmp edx, ADDR_PATCH_TYPE_JCC_RIP
    jne _check_jmp_patch_rpsa
    test edi, edi
    jz __check_jcc_max_patch_rpsa
__check_jcc_patch_min_set:
    mov r9d, 4
    mov r10d, eax
    mov r11d, eax
    add r10d, r9d
    sub r11d, r9d
    cmp eax, 0
    cmovge r10d, r11d
    mov eax, r10d
    mov bl, [rcx+1] ; from 2 byte jcc opcode to 1 byte
    sub bl, 0x10
    mov [rcx], bl
    mov [rcx+1], al
    mov byte [r8+15], 2
    mov ecx, r9d
    jmp _reduce_buffers_rpsa
__check_jcc_max_patch_rpsa:
    inc edi
    cmp eax, 0
    jg __check_jcc_max_set
    mov edx, eax
    sub edx, 4
    cmp edx, r11d
    jge __check_jcc_patch_min_set
__check_jcc_max_set:
    mov r10b, [rsi+6]
    cmp r10b, 4
    jl _err_offset_to_big_rpsa 
    jmp __check_def_patch_update_rpsa
_check_jmp_patch_rpsa:
    cmp edx, ADDR_PATCH_TYPE_JMP_RIP
    jne _check_def_patch_rpsa
    test edi, edi
    jz __check_jmp_max_patch_rpsa
__check_jmp_patch_min_set:
    mov r9d, 3
    mov r10d, eax
    mov r11d, eax
    add r10d, r9d
    ;sub r11d, r9d
    cmp eax, 0
    cmovge r10d, r11d
    mov eax, r10d
    or byte [rcx], 0x2
    mov [rcx+1], al
    mov byte [r8+15], 2
    mov ecx, r9d
    jmp _reduce_buffers_rpsa
__check_jmp_max_patch_rpsa:
    inc edi
    cmp eax, 0
    jg __check_def_patch_update_rpsa
    mov edx, eax
    sub edx, 3
    cmp edx, r11d
    jge __check_jmp_patch_min_set
_check_def_patch_rpsa:
    cmp edx, ADDR_PATCH_TYPE_DEF_RIP
    jne _err_invalid_rip_patch_type_rpsa
__check_def_patch_update_rpsa:
    movzx ebx, byte [rsi+5]
    mov [rcx+rbx], eax
    jmp _remove_patch_node_rpsa
_reduce_buffers_rpsa:
    mov rdi, [rbp-48]
    mov rsi, [rbp-56]
    mov rdx, r8
    call reduce_ins_offset
_remove_patch_node_rpsa:
    mov eax, [rbp-32]
    mov esi, [rbp-76]
    cmp eax, esi
    jne __remove_patch_node_in_between_rpsa
    mov rdi, SEGMENT_PATCH_LIST
    call list_free_node
    test eax, eax
    jz _next_sym_ptr_rpsa
    mov rdx, [rbp-40]
    lea rsi, [rdx+rax]
    mov [rbp-24], rsi
    jmp _next_patch_entry_rpsa
__remove_patch_node_in_between_rpsa:
    mov rdi, SEGMENT_PATCH_LIST
    call list_free_node
    mov edi, [rbp-28]
    cmp edi, eax ; TODO: delete check later
    jne _err_invalid_rip_patch_type_rpsa
    mov rdx, [rbp-40]
    mov ecx, [rbp-32]
    lea rsi, [rdx+rcx]
    mov [rsi], eax
    mov [rbp-24], rsi
_next_patch_entry_rpsa:
    mov ebx, [rbp-28]
    test ebx, ebx
    jz _next_sym_ptr_rpsa
    mov rax, [rbp-24]
    mov rdi, [rbp-40]
    mov r8, rax
    sub r8, rdi
    mov [rbp-32], r8d
    lea rsi, [rdi+rbx]
    mov eax, [rsi]
    mov [rbp-24], rsi
    mov [rbp-28], eax
    mov [rbp-76], ebx
    mov rdx, [rbp-8]
    jmp _start_loop_seg_rpsa
_next_sym_ptr_rpsa:
    mov rdx, [rbp-8]
    mov r9, [rbp-16]
    cmp rdx, r9
    je _end_render_patch_segment_addr
    sub rdx, 8
    mov [rbp-8], rdx
    mov rax, SEGMENT_PATCH_LIST
    mov rcx, [rbp-40]
    mov ebx, [rax+24]
    test ebx, ebx
    jz _end_render_patch_segment_addr
    lea rsi, [rcx+rbx]
    mov [rbp-24], rsi
    mov [rbp-76], ebx
    mov [rbp-32], ebx
    jmp _start_loop_seg_rpsa
_err_offset_to_big_rpsa:
_err_invalid_rip_patch_type_rpsa:
    exit_m -6
_end_render_patch_segment_addr:
    add rsp, 128
    pop rbp
    ret

; rdi - ptr to buf of ptr to seg entry
; return eax - count of segments
set_collate_seg_ptr:
    push rbp
    mov rbp, rsp
    xor r9, r9
    mov r8, [SEG_ENTRY_ARRAY]
    mov ecx, SEG_ENTRY_SIZE
    mov eax, 5 ;TODO: swap 5 and 6 back
    mul ecx
    lea rbx, [r8+rax]
    mov esi, [rbx+8]
    test esi, esi
    jz _set_collate_sg_check2
    inc r9d
    mov [rdi], rbx
    add rdi, 8
_set_collate_sg_check2:
    mov eax, 4
    mul ecx
    lea rbx, [r8+rax]
    mov esi, [rbx+8]
    test esi, esi
    jz _set_collate_sg_check3
    inc r9d
    mov [rdi], rbx
    add rdi, 8
_set_collate_sg_check3:
    mov eax, 6
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
    lea rax, [r10+r9]
    movzx edi, byte [r10+r9+14]
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
    lea rax, [r10+r9]
    movzx edi, byte [r10+r9+14]
    cmp edi, TOKEN_NAME_CONST
    je _end_is_name_const
    cmp edi, TOKEN_NAME_CONST_MUT
    je _end_is_name_const
    xor rax, rax
_end_is_name_const:
    ret

; rdi - ptr to TOKEN_BUF_PTR_OFFSET entrh body
; return rax - ptr to symbol body val, ebx - type
get_name_ref_type:
    mov r8, [rdi]
    mov r9d, [rdi+8]
    mov r10, [r8]
    lea rax, [r10+r9+16]
    movzx ebx, byte [r10+r9+14]
    ret

; edi - dest size, esi - imm size
; return eax - bytes to line up
line_up_d_s_size:
    xor edx, edx
    inc edx
    and edi, REG_MASK_BITS
    and esi, REG_MASK_BITS
    shr edi, REG_MASK_VAL_SHIFT_NORM
    shr esi, REG_MASK_VAL_SHIFT_NORM
    mov ecx, edi
    mov ebx, edx
    shl edx, cl
    mov eax, edx
    mov edx, ebx
    mov ecx, esi
    shl edx, cl
    sub eax, edx
    ret

; rdi - ptr to ins. code struct
remove_modrm_byte:
    movzx ecx, byte [rdi+24]
    dec ecx
    mov [rdi+24], cl
    mov rsi, rdi
    inc rsi
    rep movsb
    ret

apply_reg_mask_to_modrm:
    mov r11b, [r9+9]
    shl r11b, 3
    mov r12b, [r8]
    or r11b, r12b
    mov [r8], r11b

; rdi - ptr to render entry array, rsi - ptr to ins code struct
default_ins_assemble:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    call entry_array_curr_ptr
    mov rdi, rax
    mov r8, [rbp-16]
    lea rsi, [r8+22]
    movzx ecx, byte [r8+22]
    shr ecx, 6
    add rax, rcx
    rep movsb
    lea rsi, [r8+23]
    movzx ecx, byte [r8+23]
    shr ecx, 6
    add rax, rcx
    rep movsb
    lea rsi, [r8+16]
    movzx ecx, byte [r8+25]
    add rax, rcx
    rep movsb
    lea rsi, [r8+52]
    movzx ecx, byte [r8+52]
    shr ecx, 6
    add rax, rcx
    rep movsb
    lea rsi, [r8+29]
    movzx ecx, byte [r8+33]
    add rax, rcx
    rep movsb
    mov rsi, r8
    movzx ecx, byte [r8+24]
    add rax, rcx
    rep movsb
    mov rdi, [rbp-8]
    mov rsi, rax
    call entry_array_commit_size
    add rsp, 16
    pop rbp
    ret

; rdi - ptr to token group header, rsi - ptr to ins. code struct
set_rendered_size:
    xor eax, eax
    add al, byte [rsi+24]
    add al, byte [rsi+25]
    add al, byte [rsi+33]
    mov [rdi+15], al
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

; rdi - ptr to ins param, rsi - pt to ins code struct
; return eax - 0 if success
process_gen_r:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rsp-8], rsi
    xor r9, r9
    mov eax, [rdi+9]
    mov [rsi+36], eax
    mov r12d, eax
    and r12b, REG_REX_MASK
    shr r12b, 1
    mov r9b, r12b
    mov edx, eax
    and eax, REG_MASK_REG_VAL
    and edx, REG_MASK_BITS
    mov [rsi+26], dl
    cmp edx, REG_MASK_VAL_64B
    jne _gen_r_arg_th
    or r9b, REX_W
_gen_r_arg_th:
    cmp eax, REG_REX_TH
    jb _gen_r_init_rm
    or r9b, REX_B
    and eax, REG_MASK_REG_IDX
_gen_r_init_rm:
    xor r12, r12
    or r12b, MOD_REG
    or r12b, al
    mov byte [rsi], r12b
    inc byte [rsi+24]
    cmp edx, REG_MASK_VAL_16B
    jne _gen_r_rex_check
    mov byte [rsi+23], PREFIX_16BIT
_gen_r_rex_check:
    test r9b, r9b
    jz _success_gen_r
    mov [rsi+52], r9b
_success_gen_r:
    xor eax, eax
_end_process_gen_r:
    add rsp, 16
    pop rbp
    ret

; for r_r version r/m, r version is used
; rdi - ptr to ins param, rsi - ptr to ins code struct 
; return eax - 0 if succes 
process_gen_r_r:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rsi
    xor r9,r9 
    lea r8, [rdi+15]
    mov eax, [rdi+9]
    mov ebx, [r8+9]
    mov [rsi+36], eax
    mov [rsi+40], ebx
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
    or r9b, REX_B
    and eax, REG_MASK_REG_IDX
_gen_r_r_2rex_check:
    cmp ebx, REG_REX_TH
    jb _gen_r_r_set_arg
    or r9b, REX_R
    and ebx, REG_MASK_REG_IDX
_gen_r_r_set_arg:
    xor r12, r12
    shl ebx, 3
    or r12b, al
    or r12b, bl
    or r12b, MOD_REG
    mov [rsi], r12b
    inc byte [rsi+24]
    cmp edx, REG_MASK_VAL_16B
    jne _gen_r_r_set_prefix
_gen_r_r16:
    mov byte [rsi+23], PREFIX_16BIT
_gen_r_r_set_prefix:
    test r9b, r9b
    jz _success_gen_r_r
    mov [rsi+52], r9b
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

; rdi - ptr to ins code struct
switch_reg_to_r_rm:
    mov al, [rdi+52]
    test al, al
    jz _switch_r_rm_skip_rex
    mov bl, al
    mov cl, al
    and al, 0x78
    and bl, REX_B
    shl bl, 2
    and cl, REX_R
    shr cl, 2
    or al, cl
    or al, bl
    mov [rdi+52], al
_switch_r_rm_skip_rex:
    mov cl, [rdi]
    mov bl, cl
    mov al, cl
    and cl, 0xC0
    and bl, 0x38
    and al, 0x07
    shr bl, 3
    shl al, 3
    or cl, bl
    or cl, al
    mov [rdi], cl
    ret

; rdi - ptr to imm token, rsi - ptr to ins code struct,
; edx - imm arg order in ins (0 based), ecx - dest bits size (for overflow check) 
; r8 - ptr to curr token entry header
render_process_imm:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-16], rsi
    mov [rbp-28], ecx
    mov [rbp-40], r8
    lea rax, [rsi+rdx+26]
    mov [rbp-24], rax
    mov cl, [rdi]
    inc rdi
    mov [rbp-8], rdi
    cmp cl, TOKEN_BUF_PTR_OFFSET
    jne _rproc_imm
    call get_name_ref_type
    cmp ebx, TOKEN_NAME_CONST
    je _rproc_imm_const
    cmp ebx, TOKEN_NAME_CONST_MUT
    je _rproc_imm_const
    cmp ebx, TOKEN_NAME_DATA
    jne _err_rproc_imm_invalid_name
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
    mov r10, [r8]
    mov [rsi+rax], r10
    cmp ebx, 8
    ja __rproc_imm16
    mov byte [r9], REG_MASK_VAL_8B
    inc al
    jmp _success_rproc_imm
__rproc_imm16:
    cmp ebx, 16
    ja __rproc_imm32
    cmp edx, REG_MASK_VAL_16B
    jb _err_rproc_imm_overflow
    mov byte [r9], REG_MASK_VAL_16B
    add al, 2
    jmp _success_rproc_imm
__rproc_imm32:
    cmp ebx, 32
    ja __rproc_imm64
    cmp edx, REG_MASK_VAL_32B
    jb _err_rproc_imm_overflow
    mov byte [r9], REG_MASK_VAL_32B
    add al, 4
    jmp _success_rproc_imm
__rproc_imm64:
    cmp edx, REG_MASK_VAL_64B
    jb _err_rproc_imm_overflow
    mov byte [r9], REG_MASK_VAL_64B
    add al, 8
    jmp _success_rproc_imm
_err_rproc_imm_invalid_name:
_err_rproc_imm_overflow:
    mov eax, 1
    jmp _end_render_process_imm
_success_rproc_imm:
    mov [rsi+24], al
    xor eax, eax
_end_render_process_imm:
    add rsp, 64
    pop rbp
    ret

; for r_i version by default used [r/m, imm] ins. version
; rdi - ptr to ins param, rsi - ptr to inc code struct
; rdx - ptr to token entry header
; return eax - 0 if succes, 1 if imm less then reg
process_gen_rm_i:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    xor r9, r9
    lea r8, [rdi+15]
    mov eax, [rdi+9]
    mov [rsi+36], eax
    mov dword [rsi+40], REG_MASK_VAL_UNSPEC
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
    or r12b, MOD_REG
    or r12b, al
    mov [rsi], r12b
    inc byte [rsi+24]
    cmp edx, REG_MASK_VAL_16B
    jne _gen_rm_i_set_prefix
    mov byte [rsi+23], PREFIX_16BIT
_gen_rm_i_set_prefix:
    test r9b, r9b
    jz _gen_rm_i_set_postfix
    mov [rsi+52], r9b
_gen_rm_i_set_postfix:
    mov rdi, r8
    mov ecx, edx
    mov edx, 1
    mov r8, [rbp-24]
    call render_process_imm
_end_process_gen_rm_i:
    add rsp, 24
    pop rbp
    ret

; NOTE: count of post opcode bytes must be at least 1 i.e it assumes that mod_r/m is already set
; -8 passed rdi, -16 passed rsi, -20 passed edx, -24 1st reg token val, -28 1st reg masked val
; -32 2nd reg token val, -40 ptr to aux token, -48 ptr to 2nd param, -56 ptr to and of addr token group
; (3 reserved) -60 temp sib byte/r8d passed, -128 temp token storage
; rdi - ptr to addr token group, rsi - ptr to ins code struct, edx - rex preffix
; ecx - addr arg order in ins (0 based), r8d - source/dest of addr arg order in ins
; r9 - ptr to curr token entry header
render_process_addr:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], edx
    mov [rbp-60], r8d
    mov [rbp-68], r9
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
    lea rsi, [rax+16]
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
    lea rsi, [rax+16]
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    jmp ___rproc_addr_2p_sib_scale 
___rproc_addr_2p_sib_check:
    cmp cl, TOKEN_BUF_DIRECT
    jne _err_rproc_addr_invalid_2nd
    mov [rbp-48], r8
    mov al, [r8+13]
    cmp al, TOKEN_TYPE_DIGIT
    jne __rproc_addr_2p_3rd_check
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
__rproc_addr_2p_3rd_check:
    mov rdx, [rbp-56]
    mov r8, [rbp-48]
    cmp rdx, r8
    je __rproc_addr_2p_r_r_set
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
    lea rsi, [rax+16]
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
    lea rsi, [rax+16]
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

; rdi - ptr to ins param, rsi - ptr to inc code struct, rdx - ptr to curr token entry header
process_gen_r_a:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    xor r9, r9
    mov eax, [rdi+9]
    mov [rsi+36], eax
    mov dword [rsi+40], REG_MASK_VAL_UNSPEC
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
    mov byte [rsi+23], PREFIX_16BIT
_gen_r_a_addr_check:
    add rdi, 15
    mov edx, r9d
    mov ecx, 1
    xor r8, r8
    mov r9, [rbp-24]
    call render_process_addr
    test rax, rax
    jnz _err_process_gen_r_a
    mov r9d, ebx
    test r9b, r9b
    jz _success_gen_r_a
    mov rsi, [rbp-16]
    mov [rsi+52], r9b
    jmp _success_gen_r_a
_err_process_gen_r_a:
_success_gen_r_a:
    xor rax, rax
_end_process_gen_r_a:
    add rsp, 24
    pop rbp
    ret

; rdi - ptr to ins param, rsi - ptr to inc code struct, rdx - ptr to curr token entry header
process_gen_a:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov dword [rsi+40], REG_MASK_VAL_UNSPEC
    lea r9, [rdi+3]
    mov bl, [rsi+26]
    test bl, bl
    jnz _gen_a_skip_size_check
    movzx eax, byte [r9]
    cmp eax, TOKEN_BUF_DIRECT
    jne _err_gen_a_size_unspec
    mov bl, [r9+13]
    cmp bl, TOKEN_TYPE_KEYWORD
    jne _err_gen_a_size_unspec
_gen_a_skip_size_check:
    inc byte [rsi+24]
    xor edx, edx
    xor ecx, ecx
    xor r8d, r8d
    mov r9, [rbp-24]
    call render_process_addr
    test rax, rax
    jnz _err_process_gen_a
    mov rsi, [rbp-16]
    mov al, [rsi+26]
    cmp al, REG_MASK_VAL_16B
    jne _gen_a_test_64
    mov byte [rsi+23], PREFIX_16BIT
_gen_a_test_64:
    cmp al, REG_MASK_VAL_64B
    jne _gen_a_test_rex
    or bl, REX
    or bl, REX_W
    jmp _gen_a_set_rex
_gen_a_test_rex:
    test ebx, ebx
    jz _success_gen_a
_gen_a_set_rex:
    mov [rsi+52], bl
    jmp _success_gen_a
_err_gen_a_size_unspec:
_err_process_gen_a:
_success_gen_a:
    xor rax, rax
_end_process_gen_a:
    add rsp, 24
    pop rbp
    ret

; rdi - ptr to ins param, rsi - ptr to inc code struct, rdx - ptr to curr token entry header
process_gen_a_r:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    movzx edx, byte [rdi+2]
    lea r10, [rdi+rdx]
    xor r9, r9
    mov eax, [r10+9]
    mov dword [rsi+36], REG_MASK_VAL_UNSPEC
    mov [rsi+40], eax
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
    mov byte [rsi+23], PREFIX_16BIT
_gen_a_r_addr_check:
    mov edx, r9d
    xor ecx, ecx
    mov r8d, 1
    mov r9, [rbp-32]
    call render_process_addr
    test rax, rax
    jnz _err_process_gen_a_r
    mov r9d, ebx
    test r9b, r9b
    jz _success_gen_r_a
    mov rsi, [rbp-16]
    mov [rsi+52], r9b
    jmp _success_gen_r_a
_err_process_gen_a_r:
_success_gen_a_r:
    xor rax, rax
_end_process_gen_a_r:
    add rsp, 24
    pop rbp
    ret

; rdi - ptr to ins param, rsi - ptr to inc cod struct, rdx - ptr to curr token entry header
process_gen_a_i:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-32], rdx
    lea r9, [rdi+3]
    movzx eax, byte [r9]
    cmp eax, TOKEN_BUF_DIRECT
    jne _err_gen_a_i_size_unspec
    mov bl, [r9+13]
    cmp bl, TOKEN_TYPE_KEYWORD
    jne _err_gen_a_i_size_unspec
    inc byte [rsi+24]
    xor ecx, ecx
    xor edx, edx
    xor r8, r8
    mov r9, [rbp-32]
    call render_process_addr
    test rax, rax
    jnz _err_process_gen_a_i
    mov rsi, [rbp-16]
    mov al, [rsi+26]
    cmp al, REG_MASK_VAL_16B
    jne _gen_a_i_test_64
    mov byte [rsi+23], PREFIX_16BIT
_gen_a_i_test_64:
    cmp al, REG_MASK_VAL_64B
    jne _gen_a_i_test_rex
    or bl, REX
    or bl, REX_W
    jmp _gen_a_i_set_rex
_gen_a_i_test_rex:
    test ebx, ebx
    jz _gen_a_i_skip_rex
_gen_a_i_set_rex:
    mov [rsi+52], r9b
_gen_a_i_skip_rex:
    mov rbx, [rbp-8]
    movzx eax, byte [rbx+2]
    lea rdi, [rbx+rax]
    mov edx, 1
    movzx ecx, byte [rsi+26]
    mov r8, [rbp-32]
    call render_process_imm
    jmp _end_process_gen_a_i
_err_gen_a_i_size_unspec:
_err_process_gen_a_i:
    mov eax, 1
    jmp _end_process_gen_a_i
_success_gen_a_i:
    xor eax, eax
_end_process_gen_a_i:
    add rsp, 32
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
    mov eax, [rdi+28]
    mov [rsi], eax
    xor rax, rax
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-24], rdi
    mov ecx, INS_CODE_STRUCT_SIZE
    lea rdi, [rbp-128]
    mov r8, rdi
    rep stosb
    mov byte [r8+33], 1
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
    movzx eax, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_mov
    cmp ebx, REG_MASK_VAL_8B
    jne ___mov_r_r_non_byte_opcode
    mov byte [r8+29], 0x88
    jmp _mov_assemble
___mov_r_r_non_byte_opcode:
    mov byte [r8+29], 0x89
    jmp _mov_assemble
__mov_r_a:
    mov rdi, rsi
    lea rsi, [rbp-128]
    mov rdx, [rbp-16]
    call process_gen_r_a
    test eax, eax
    jnz _err_parse_mov
    lea r8, [rbp-128]
    movzx eax, byte [r8+26]
    movzx ebx, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_mov
    cmp eax, REG_MASK_VAL_8B
    jne ___mov_r_a_non_byte_opcode
    mov byte [r8+29], 0x8A
    jmp _mov_assemble
___mov_r_a_non_byte_opcode:
    mov byte [r8+29], 0x8B
    jmp _mov_assemble
__mov_r_i:
    mov rdi, rsi
    lea rsi, [rbp-128]
    mov rdx, [rbp-16]
    call process_gen_rm_i
    test eax, eax
    jnz _err_parse_mov
    lea r8, [rbp-128]
    movzx ebx, byte [r8+26]
    cmp ebx, REG_MASK_VAL_8B
    jne ___mov_r_i_non_byte_opcode
    mov byte [r8+29], 0xB0
    jmp ___mov_r_i_reg_opc_remove_modrm 
___mov_r_i_non_byte_opcode:
    mov byte [r8+29], 0xB8
    cmp ebx, REG_MASK_VAL_64B
    jne ___mov_r_i_reg_opc_remove_modrm
    movzx eax, byte [r8+27]
    cmp eax, REG_MASK_VAL_32B
    ja ___mov_r_i_reg_opc_remove_modrm
    mov byte [r8+29], 0xC7
    mov ebx, REG_MASK_VAL_32B
    cmp ebx, eax
    je _mov_assemble
    mov edi, ebx
    mov esi, eax
    call line_up_d_s_size
    add [r8+24], al
    jmp _mov_assemble
___mov_r_i_reg_opc_remove_modrm:
    mov bl, [r8+29] 
    mov al, [r8]
    and al, MOD_RM_RM_MASK
    or bl, al
    mov [r8+29], bl
    movzx edi, byte [r8+26]
    movzx esi, byte [r8+27]
    call line_up_d_s_size
    add [r8+24], al
    mov rdi, r8
    call remove_modrm_byte
    jmp _mov_assemble
_mov_a:
    movzx eax, byte [rsi+2]
    lea r9, [rsi+rax]
    movzx ecx, byte [r9]
    cmp ecx, TOKEN_BUF_PTR_OFFSET
    je __mov_a_i
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
    mov rdx, [rbp-16]
    call process_gen_a_r
    test eax, eax
    jnz _err_parse_mov
    lea r8, [rbp-128]
    movzx eax, byte [r8+26]
    movzx ebx, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_mov
    cmp eax, REG_MASK_VAL_8B
    jne ___mov_a_r_non_byte_opcode
    mov byte [r8+29], 0x88
    jmp _mov_assemble
___mov_a_r_non_byte_opcode:
    mov byte [r8+29], 0x89
    jmp _mov_assemble
__mov_a_i:
    mov rdi, rsi
    lea rsi, [rbp-128]
    mov rdx, [rbp-16]
    call process_gen_a_i
    test eax, eax
    jnz _err_parse_mov
    lea r8, [rbp-128]
    movzx ebx, byte [r8+26]
    movzx eax, byte [r8+27]
    cmp ebx, REG_MASK_VAL_8B
    jne ___mov_a_i_non_byte_opcode
    mov byte [r8+29], 0xC6
    jmp _mov_assemble
___mov_a_i_non_byte_opcode:
    mov byte [r8+29], 0xC7
    cmp ebx, REG_MASK_VAL_64B
    jne ___mov_a_i_check
    cmp eax, REG_MASK_VAL_64B
    je _err_invalid_second_param_mov
    mov ebx, REG_MASK_VAL_32B
___mov_a_i_check:
    cmp ebx, eax
    je _mov_assemble
    mov edi, ebx
    mov esi, eax
    call line_up_d_s_size
    add [r8+24], al
_mov_assemble:
    mov rdi, [rbp-24]
    lea rsi, [rbp-128]
    call default_ins_assemble
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

; rdi - segment ptr, rsi - ptr to token entry to process, rdx - ins code struct
; rcx - opcode list for instemp0 pattern, r8 - ptr to stack of caller
process_ins_template1:
    push rbp
    mov rbp, rsp
    sub rsp, 40
    movzx eax, byte [rsi+31]
    cmp eax, 1
    jne _err_instemp1_invalid_argc
    mov eax, [rdi+28]
    mov [rsi], eax
    xor rax, rax
    mov [rbp-8], rsi
    mov [rbp-16], rdx
    mov [rbp-24], rcx
    mov [r8+24], rdi
    mov [r8+16], rsi
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-32], rdi
    mov ecx, INS_CODE_STRUCT_SIZE
    mov rdi, rdx
    mov r8, rdx
    rep stosb
    mov byte [r8+33], 1
    add rsi, TOKEN_HEADER_PLUS_INS_TOKEN
    movzx ebx, byte [rsi]
    cmp ebx, TOKEN_BUF_DIRECT
    je _instemp1_r
    cmp ebx, TOKEN_BUF_ADDR
    je _instemp1_a
    jmp _err_instemp1_invalid_first_param
_instemp1_r:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    jne _err_instemp1_invalid_first_param 
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_r
    test eax, eax
    jnz _err_instemp1_parse
    jmp _instemp1_assemble
_instemp1_a:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov rdx, [rbp-8]
    call process_gen_a
    test rax, rax
    jnz _err_instemp1_parse
_instemp1_assemble:
    mov r9, [rbp-24]
    mov rsi, [rbp-16]
    mov bl, [rsi+26]
    movzx eax, byte [r9]
    movzx ecx, byte [r9+1]
    cmp bl, REG_MASK_VAL_8B
    cmovg eax, ecx
    mov byte [rsi+29], al
    mov dl, [r9+2]
    shl dl, 3
    mov cl, [rsi]
    or cl, dl
    mov [rsi], cl
    mov rdi, [rbp-32]
    call default_ins_assemble
    jmp _end_instemp1_process
_err_instemp1_invalid_argc:
_err_instemp1_invalid_first_param:
_err_instemp1_parse:
_err_instemp1_exit:
    exit_m -6
_end_instemp1_process:
    add rsp, 40
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_inc:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x00FFFE
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template1
_end_process_inc:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_dec:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x01FFFE
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template1
_end_process_dec:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_neg:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x03F7F6
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template1
_end_process_neg:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_not:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x02F7F6
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template1
_end_process_not:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_mul:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x04F7F6
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template1
_end_process_mul:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_div:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x06F7F6
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template1
_end_process_div:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_idiv:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x07F7F6
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template1
_end_process_idiv:
    add rsp, 192
    pop rbp
    ret
; rdi - segment ptr, rsi - ptr to token entry to process
process_jumps:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    movzx eax, byte [rsi+31]
    cmp eax, 1
    jne _err_invalid_argc_jumps
    mov eax, [rdi+28]
    mov [rsi], eax
    xor rax, rax
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-24], rdi
    mov ecx, INS_CODE_STRUCT_SIZE
    lea rdi, [rbp-128]
    mov r8, rdi
    rep stosb
    add rsi, TOKEN_HEADER_SIZE
    mov [rbp-32], rsi
    lea r9, [rsi+16] ; type, body, argc
    mov [rbp-40], r9
    mov eax, [rsi+9]
    movzx ebx, byte [r9]
    mov edx, eax
    and edx, INS_JMP_JCC_TYPE_MASK
    test edx, edx
    jnz __jumps_check_type_ptr_offset
_jumps_check_type:
    cmp ebx, TOKEN_BUF_ADDR
    je _jumps_addr
    cmp ebx, TOKEN_BUF_DIRECT
    je _jumps_direct
__jumps_check_type_ptr_offset:
    cmp ebx, TOKEN_BUF_PTR_OFFSET
    jne _err_parse_jumps
    lea rdi, [r9+1]
    call is_name_rip_ref
    test rax, rax
    jz _err_parse_invalid_rip_ref_jumps
    mov [rbp-48], rax
    lea r15, [rbp-128]
    mov rsi, [rbp-32]
    mov eax, [rsi+9]
    mov ebx, eax
    and ebx, INS_JMP_JCC_TYPE_MASK
    test ebx, ebx
    jz _jumps_name
_jumps_jcc:
    cmp eax, INS_JCXZ
    jne __jumps_jcc_check
    mov byte [r15+29], 0xE3
    mov byte [r15+33], 1
    mov ecx, ADDR_PATCH_TYPE_DEF_RIP
    mov r8d, 1
    xor r9, r9
    jmp _jumps_name_push
__jumps_jcc_check:
    mov ecx, ADDR_PATCH_TYPE_JCC_RIP
    mov r8d, 4
    mov r9d, 1
    mov ebx, INS_JO
    sub eax, ebx
    add eax, 0x80
    shl eax, 8
    or eax, 0x0F
    mov word [r15+29], ax
    mov byte [r15+33], 2
    jmp _jumps_name_push
_jumps_name:
    cmp eax, INS_CALL
    jne __jumps_name_jmp
    mov byte [r15+29], 0xE8
    mov byte [r15+33], 1
    mov rdi, [rbp-48]
    mov rsi, [rbp-16]
    lea rdx, [rbp-128]
    mov ecx, ADDR_PATCH_TYPE_DEF_RIP
    call push_to_delayed_patch
    jmp __jumps_name_push_set_disp
__jumps_name_jmp:
    cmp eax, INS_JMP
    jne _err_parse_jumps
    mov byte [r15+29], 0xE9 
    mov byte [r15+33], 1
    mov ecx, ADDR_PATCH_TYPE_JMP_RIP
    mov r8d, 4
    mov r9d, 1
_jumps_name_push:
    mov rdi, [rbp-48]
    mov rsi, [rbp-16]
    lea rdx, [rbp-128]
    call push_to_addr_patch
__jumps_name_push_set_disp:
    lea rsi, [rbp-128]
    mov dword [rsi], 0
    mov byte [rsi+24], 4
    jmp _jumps_assemble
_jumps_addr:
    mov rdi, r9
    lea rsi, [rbp-128]
    mov rdx, [rbp-16]
    mov byte [rsi+26], REG_MASK_VAL_32B; hack for not setting REX_W and still pass size check
    call process_gen_a
    test rax, rax
    jnz _err_parse_jumps
    jmp _jump_set_jmp_call
_jumps_direct:
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    jne _err_parse_invalid_arg_jumps
__jumps_direct_r:
    mov rdi, r9
    lea rsi, [rbp-128]
    call process_gen_r
    test eax, eax
    jnz _err_parse_jumps
    lea rsi, [rbp-128]
    mov bl, [rsi+26]
    cmp bl, REG_MASK_VAL_64B 
    jne _err_parse_invalid_arg_jumps
    mov r9, [rbp-40]
    mov eax, [r9+9]
    mov dl, [rsi+16]
    and dl, EXC_REX_W
    mov [rsi+16], dl
    and eax, REG_MASK_REG_VAL
    cmp eax, REG_REX_TH
    jge _jump_set_jmp_call
    mov byte [rsi+25], 0
    jmp _jump_set_jmp_call
_jump_set_jmp_call:
    lea r8, [rbp-128]
    mov rsi, [rbp-32]
    mov byte [r8+29], 0xFF
    mov byte [r8+33], 1
    mov al, [r8]
    mov ebx, [rsi+9]
    mov r9d, 0x10
    mov r10d, 0x20
    cmp ebx, INS_JMP
    cmove r9d, r10d
    or al, r9b
    mov [r8], al
_jumps_assemble:
    mov rdi, [rbp-16]
    lea rsi, [rbp-128]
    call set_rendered_size
    mov rdi, [rbp-24]
    call default_ins_assemble
    jmp _end_process_jumps
_err_parse_invalid_rip_ref_jumps:
_err_parse_invalid_arg_jumps:
_err_invalid_argc_jumps:
_err_parse_jumps:
    exit_m -6
_end_process_jumps:
    add rsp, 128
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process, rdx - ins code struct
; rcx - opcode list for instemp0 pattern, r8 - ptr to stack of caller
process_ins_template0:
    push rbp
    mov rbp, rsp
    sub rsp, 40
    mov [rbp-8], rsi
    mov [rbp-16], rdx
    mov [rbp-24], rcx
    mov [r8+24], rdi
    mov [r8+16], rsi
    movzx eax, byte [rsi+31]
    cmp eax, 2
    jne _err_invalid_argc_instemp0
    mov eax, [rdi+28]
    mov [rsi], eax
    xor rax, rax
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-32], rdi
    mov ecx, INS_CODE_STRUCT_SIZE
    mov rdi, rdx
    mov r8, rdx
    rep stosb
    mov byte [r8+33], 1
    add rsi, TOKEN_HEADER_PLUS_INS_TOKEN
    movzx ebx, byte [rsi]
    cmp ebx, TOKEN_BUF_DIRECT
    je _instemp0_r
    cmp ebx, TOKEN_BUF_ADDR
    je _instemp0_a
    jmp _err_invalid_first_param_instemp0
_instemp0_r:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    jne _err_invalid_first_param_instemp0
    lea r9, [rsi+15]
    movzx ecx, byte [r9]
    cmp ecx, TOKEN_BUF_ADDR
    je __instemp0_r_a
    cmp ecx, TOKEN_BUF_PTR_OFFSET
    je __instemp0_r_i
    cmp ecx, TOKEN_BUF_DIRECT
    jne _err_invalid_second_param_instemp0
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    je __instemp0_r_r
    cmp ebx, TOKEN_TYPE_DIGIT
    je __instemp0_r_i
    jmp _err_invalid_second_param_instemp0 
__instemp0_r_r:
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_r_r
    test eax, eax
    jnz _err_parse_instemp0
    mov r8, [rbp-16]
    movzx ebx, byte [r8+26]
    movzx eax, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_instemp0
    mov byte [r8+34], OP12_TYPE_R_R
    jmp __instemp0_rm_r_load_opc
__instemp0_r_a:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov rdx, [rbp-8]
    call process_gen_r_a
    test eax, eax
    jnz _err_parse_instemp0
    mov r8, [rbp-16]
    movzx eax, byte [r8+26]
    movzx ebx, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_instemp0
    mov byte [r8+34], OP12_TYPE_R_A
    mov r9, [rbp-24]
    movzx ecx, byte [r9+7]
    movzx ebx, byte [r9+8]
    jmp _instemp0_rm_rm
__instemp0_r_i:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov rdx, [rbp-8]
    call process_gen_rm_i
    test eax, eax
    jnz _err_parse_instemp0
    mov r8, [rbp-16]
    mov byte [r8+34], OP12_TYPE_R_I
    jmp _instemp0_rm_i
_instemp0_a:
    movzx eax, byte [rsi+2]
    lea r9, [rsi+rax]
    movzx ecx, byte [r9]
    cmp ecx, TOKEN_BUF_PTR_OFFSET
    je __instemp0_a_i
    cmp ecx, TOKEN_BUF_DIRECT
    jne _err_invalid_second_param_instemp0
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    je __instemp0_a_r
    cmp ebx, TOKEN_TYPE_DIGIT
    je __instemp0_a_i
    jmp _err_invalid_second_param_instemp0
__instemp0_a_r:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov rdx, [rbp-8]
    call process_gen_a_r
    test eax, eax
    jnz _err_parse_instemp0
    mov r8, [rbp-16]
    movzx eax, byte [r8+26]
    movzx ebx, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_instemp0
    mov byte [r8+34], OP12_TYPE_A_R
__instemp0_rm_r_load_opc:
    mov r9, [rbp-24]
    movzx ecx, byte [r9+5]
    movzx ebx, byte [r9+6]
    jmp _instemp0_rm_rm
__instemp0_a_i:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov rdx, [rbp-8]
    call process_gen_a_i
    test eax, eax
    jnz _err_parse_instemp0
    mov r8, [rbp-16]
    mov byte [r8+34], OP12_TYPE_A_I
    jmp _instemp0_rm_i
_instemp0_rm_rm:
    mov r9, [rbp-24]
    mov dl, [r8+26]
    cmp dl, REG_MASK_VAL_8B
    cmovne ecx, ebx ; already loaded
    mov byte [r8+29], cl
    jmp _instemp0_assemble
_instemp0_rm_i:
    mov r9, [rbp-24]
    mov r10b, [r9+9]
    shl r10b, 3
    mov r11b, [r8]
    or r10b, r11b
    mov [r8], r10b
    mov cl, [r8+26]
    mov dl, [r8+27]
    cmp cl, dl
    jl _err_instemp0_r_i_overflow
    jne __instemp0_rm_i_ds
    mov r10b, cl
    mov r11b, dl
    or r10b, r11b
    cmp r10b, REG_MASK_VAL_64B
    je _err_instemp0_r_i_overflow
__instemp0_rm_i_ds_back:
    mov bl, [r8+34]
    cmp bl, OP12_TYPE_A_I
    je __instemp0_rm_i_skip_al_check     
    mov ebx, [r8+36]
    and ebx, REG_MASK_REG_VAL
    cmp ebx, REG_AL
    je __instemp0_rm_i_ss_al
__instemp0_rm_i_skip_al_check:
    movzx eax, byte [r9+2]
    movzx ebx, byte [r9+3]
    cmp cl, REG_MASK_VAL_8B
    cmovne eax, ebx
    mov [r8+29], al
    jmp _instemp0_assemble
__instemp0_rm_i_ss_al:
    movzx eax, byte [r9]
    movzx ebx, byte [r9+1]
    cmp cl, REG_MASK_VAL_8B
    cmovne eax, ebx
    mov [r8+29], al
    mov rdi, r8
    call remove_modrm_byte
    jmp _instemp0_assemble
__instemp0_rm_i_ds:
    mov r10b, [r9+11]
    test r10b, r10b
    jnz _instemp0_rm_i_ds_op_align
    cmp dl, REG_MASK_VAL_8B 
    je __instemp0_rm_i_ds_set
_instemp0_rm_i_ds_op_align:
    cmp dl, REG_MASK_VAL_32B
    ja _err_instemp0_r_i_overflow
    mov esi, REG_MASK_VAL_32B
    cmp cl, REG_MASK_VAL_32B
    cmovg ecx, esi
    mov [r8+27], cl
    mov edi, ecx
    mov esi, edx
    call line_up_d_s_size
    mov cl, [r8+26]
    add [r8+24], al
    jmp __instemp0_rm_i_ds_back
__instemp0_rm_i_ds_set:
    mov al, byte [r9+4]
    mov byte [r8+29], al    
    jmp _instemp0_assemble
_err_arg_size_instemp0:
_err_instemp0_r_i_overflow:
_err_invalid_argc_instemp0:
_err_invalid_second_param_instemp0:
_err_invalid_first_param_instemp0:
_err_parse_instemp0:
    mov eax, 1
    jmp _end_process_instemp0
_instemp0_assemble:
    mov rdi, [rbp-32]
    mov rsi, [rbp-16]
    call default_ins_assemble
_success_process_instemp0:
    xor eax, eax
_end_process_instemp0:
    add rsp, 40 
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_add:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x81800504
    mov dword [rbp-60], 0x02010083
    mov dword [rbp-56], 0x00000003 ; last opcode + reg mask
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template0
_end_process_add:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_sub:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x81802D2C
    mov dword [rbp-60], 0x2A292883
    mov dword [rbp-56], 0x0000052B
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template0
_end_process_sub:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_and:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x81802524
    mov dword [rbp-60], 0x22212083
    mov dword [rbp-56], 0x00000423
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template0
_end_process_and:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_or:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x81800D0C
    mov dword [rbp-60], 0x0A090883
    mov dword [rbp-56], 0x0000010B
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template0
_end_process_or:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_xor:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x81803534
    mov dword [rbp-60], 0x32313083
    mov dword [rbp-56], 0x00000633
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template0
_end_process_xor:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_cmp:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x81803D3C
    mov dword [rbp-60], 0x3A393883
    mov dword [rbp-56], 0x0000073B
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template0
_end_process_cmp:
    add rsp, 192
    pop rbp
    ret


; rdi - segment ptr, rsi - ptr to token entry to process
process_test:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0xF7F6A9A8
    mov dword [rbp-60], 0x00858400
    mov dword [rbp-56], 0x01000000
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template0
    lea r8, [rbp-128]
    mov al, [r8+34]
    cmp al, OP12_TYPE_R_A
    je _test_proc_invalid_op
_test_proc_invalid_op:
_end_process_test:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process, rdx - ins code struct
; rcx - opcode list for instemp0 pattern, r8 - ptr to stack of caller
process_ins_template2:
    push rbp
    mov rbp, rsp
    sub rsp, 40
    mov [rbp-8], rsi
    mov [rbp-16], rdx
    mov [rbp-24], rcx
    mov [r8+24], rdi
    mov [r8+16], rsi
    movzx eax, byte [rsi+31]
    cmp eax, 2
    jne _err_invalid_argc_instemp2
    mov eax, [rdi+28]
    mov [rsi], eax
    xor rax, rax
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-32], rdi
    mov ecx, INS_CODE_STRUCT_SIZE
    mov rdi, rdx
    mov r8, rdx
    rep stosb
    add byte [r8+33], 2
    add rsi, TOKEN_HEADER_PLUS_INS_TOKEN
    movzx ebx, byte [rsi]
    cmp ebx, TOKEN_BUF_DIRECT
    jne _err_invalid_first_param_instemp2
_instemp2_r:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    jne _err_invalid_first_param_instemp2
    lea r9, [rsi+15]
    movzx ecx, byte [r9]
    cmp ecx, TOKEN_BUF_ADDR
    je __instemp2_r_a
    cmp ecx, TOKEN_BUF_DIRECT
    jne _err_invalid_second_param_instemp2
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    je __instemp2_r_r
    jmp _err_invalid_second_param_instemp2 
__instemp2_r_r:
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_r_r
    test eax, eax
    jnz _err_parse_instemp2
    mov r8, [rbp-16]
    movzx ebx, byte [r8+26]
    movzx eax, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_instemp2
    cmp eax, REG_MASK_VAL_8B
    je _err_arg_size_instemp2
    mov rdi, r8
    call switch_reg_to_r_rm
    jmp _instemp2_load_opc
__instemp2_r_a:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov rdx, [rbp-8]
    call process_gen_r_a
    test eax, eax
    jnz _err_parse_instemp2
    mov r8, [rbp-16]
    movzx eax, byte [r8+26]
    movzx ebx, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_instemp2
    cmp eax, REG_MASK_VAL_8B
    je _err_arg_size_instemp2
_instemp2_load_opc:
    mov r9, [rbp-24]
    mov cx, word [r9]
    mov [r8+29], cx
    jmp _instemp2_assemble
_err_arg_size_instemp2:
_err_invalid_argc_instemp2:
_err_invalid_second_param_instemp2:
_err_invalid_first_param_instemp2:
_err_parse_instemp2:
    mov eax, 1
    jmp _end_process_instemp2
_instemp2_assemble:
    mov rdi, [rbp-32]
    mov rsi, [rbp-16]
    call default_ins_assemble
_success_process_instemp2:
    xor eax, eax
_end_process_instemp2:
    add rsp, 40 
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_bsr:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov word [rbp-64], 0xBD0F
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template2
_end_process_bsr:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_bsf:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov word [rbp-64], 0xBC0F
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template2
_end_process_bsf:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_cmovcc:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    xor ebx, ebx
    mov bx, 0x400F
    mov eax, [rsi+25]; header_size + type + ptr to str
    mov ecx, INS_CMOVO
    sub eax, ecx
    shl eax, 8
    add ebx, eax
    mov word [rbp-64], bx
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template2
_end_process_cmovcc:
    add rsp, 192
    pop rbp
    ret

; -8 passed rdi, -12 curr token buff offset, -16 reserve
; -24 curr token buf ptr; -32 ptr to render segm buff
; rdi - segment ptr
render_process_segment:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov [rbp-8], rdi
    mov rbx, rdi
    mov rax, qword [SEG_ENTRY_ARRAY]
    sub rbx, rax
    mov dword [CURR_SECTION_OFFSET], ebx
    xor rax, rax
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
    mov rdi, [rbp-8]
    mov rsi, r9
    cmp ebx, INS_MOV
    jne _check_ins_rps1
    call process_mov
    jmp _start_loop_process_segment 
_check_ins_rps1:
    cmp ebx, INS_INC
    jne _check_ins_rps2
    call process_inc
    jmp _start_loop_process_segment
_check_ins_rps2:
    cmp ebx, INS_DEC
    jne _check_ins_rps3
    call process_dec
    jmp _start_loop_process_segment
_check_ins_rps3:
    cmp ebx, INS_ADD
    jne _check_ins_rps4
    call process_add
    jmp _start_loop_process_segment
_check_ins_rps4:
    cmp ebx, INS_SUB
    jne _check_ins_rps5
    call process_sub
    jmp _start_loop_process_segment
_check_ins_rps5:
    cmp ebx, INS_AND
    jne _check_ins_rps6
    call process_and
    jmp _start_loop_process_segment
_check_ins_rps6:
    cmp ebx, INS_OR
    jne _check_ins_rps7
    call process_or
    jmp _start_loop_process_segment
_check_ins_rps7:
    cmp ebx, INS_XOR
    jne _check_ins_rps8
    call process_xor
    jmp _start_loop_process_segment
_check_ins_rps8:
    cmp ebx, INS_CMP
    jne _check_ins_rps9
    call process_cmp
    jmp _start_loop_process_segment
_check_ins_rps9:
    cmp ebx, INS_TEST
    jne _check_ins_rps10
    call process_test
    jmp _start_loop_process_segment
_check_ins_rps10:
    cmp ebx, INS_NEG
    jne _check_ins_rps11
    call process_neg
    jmp _start_loop_process_segment
_check_ins_rps11:
    cmp ebx, INS_NOT
    jne _check_ins_rps12
    call process_not
    jmp _start_loop_process_segment
_check_ins_rps12:
    cmp ebx, INS_MUL
    jne _check_ins_rps13
    call process_mul
    jmp _start_loop_process_segment
_check_ins_rps13:
    cmp ebx, INS_DIV
    jne _check_ins_rps14
    call process_div
    jmp _start_loop_process_segment
_check_ins_rps14:
    cmp ebx, INS_IDIV
    jne _check_ins_rps15
    call process_idiv
    jmp _start_loop_process_segment
_check_ins_rps15:
    cmp ebx, INS_BSR
    jne _check_ins_rps16
    call process_bsr
    jmp _start_loop_process_segment
_check_ins_rps16:
    cmp ebx, INS_BSF
    jne _check_ins_rps_jmp
    call process_bsf
    jmp _start_loop_process_segment
_check_ins_rps_jmp:
    mov edx, ebx
    and edx, INS_JMP_TYPE_MASK
    test edx, edx
    jz _check_ins_rps_cmovcc 
    call process_jumps
    jmp _start_loop_process_segment
_check_ins_rps_cmovcc:
    mov edx, ebx
    and edx, INS_CMOVCC_TYPE_MASK
    test edx, edx
    jz _err_processing_start_token 
    call process_cmovcc
    jmp _start_loop_process_segment
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
    mov rdi, SEGMENT_PATCH_LIST
    mov esi, 256
    call init_list
    mov rdi, DELAYED_PATCH_ARR
    mov esi, 256
    call init_entry_array
    mov rdi, TEMP_SYM_PTR_ARR
    mov esi, 256
    call init_entry_array
    ;TODO: check if collate mode is enabled    
    mov rdi, rsp
    call set_collate_seg_ptr
    mov [rbp-8], eax
_render_seg_grab_loop:
    call clear_patch_state
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
    mov eax, dword [SEGMENT_PATCH_LIST+8]
    test eax, eax
    jz _render_seg_grab_loop
    mov edi, dword [CURR_SECTION_OFFSET]
    call render_patch_segment_addr
    jmp _render_seg_grab_loop    
_end_start_render:
    add rsp, 2304
    pop rbp
    ret
