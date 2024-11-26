; ins code struct (32 bytes)
; 0 (16 bytes) post opcodes bytes (1st byte is ModR/M), +16 (6 bytes) prefix bytes,
; +22 16 bit addr prefix, +23 16 bit op prefix, +24 post opcode bytes count,
; +25 prefix buff bytes count, +26 1st arg size, +27 2nd arg size, +28 3rd arg size,
; +29 (4) opcode bytes, +33 opcode bytes count, +34 ins operands type, (1 byte reserved)
; +36 1st op reg, +40 2nd op reg, +44 3rd op reg, +48 4th op reg, +52 rex byte,
; +53 prefix flags, 
; +54 disp offset in post opc. buff, +55 imm offset in post opc.,
; +56 is dips ref, +57 is imm ref, (5 bytes reserevd)
; +64 ptr to sym1, +72 ptr to sym2

; TODO: add lock prefix

INS_CODE_STRUCT_SIZE equ 80

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
EXCL_REG_FIELD_MASK equ 0xC7
EXCL_REX_W_MASK equ 0xF7

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

PREFIX_TYPE_REP  equ 0x01
PREFIX_TYPE_REPN equ 0x02
PREFIX_TYPE_LOCK equ 0x04

segment readable writeable

CURR_SECTION_OFFSET dd 0

; entry body - 0 ptr to sym, +8 ptr to token entry header,
; +16 type, +17 offset to disp from start of ins, +18 size of patch, (1b reserved)
; +20 offset of section to patch in
ADDR_ARR_PATCH_ENTRY_SIZE equ 24
entry_array_data_m RELOC_PATCH_ARR, ADDR_ARR_PATCH_ENTRY_SIZE
entry_array_data_m DELAYED_PATCH_ARR, ADDR_ARR_PATCH_ENTRY_SIZE

; TODO: move this struct to segment entry?
; entry body - 0 reserved, +2 sub to min ins len, +3 total ins bytes
; +4 type, +5 offset to disp from start of ins
; +6 max size of disp, +7 min size of disp
; +8 ptr to symbol, +16 ptr to token entry header
SEGMENT_PATCH_ENTRY_SIZE equ 24
entry_array_data_m LOCAL_PATCH_ARR, SEGMENT_PATCH_ENTRY_SIZE

SEGMENT_PATCH_LIST dq 0
dd 0, 0, SEGMENT_PATCH_ENTRY_SIZE
dd 0, 0

entry_array_data_m TEMP_SYM_PTR_ARR, 8

segment readable executable

clear_patch_state:
    xor ebx, ebx
    mov rax, LOCAL_PATCH_ARR
    mov [rax+8], ebx
    mov rcx, TEMP_SYM_PTR_ARR
    mov [rcx+8], ebx
    ret
; NOTE: all encoding must be done with max disp size

; rdi - sym ptr, rsi - ptr to token entry header, rdx - ptr to ins code struct
; ecx - type, r8d - max disp size (in bytes), r9d - min disp size (can be set to 0 if max == min)
; r10d - sub to min ins len (opcode+disp), r11d - offset to disp from start of ins
push_to_segment_patch:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-28], ecx
    mov [rbp-32], r8d
    mov [rbp-52], r10d
    mov [rbp-56], r11d
    cmp r9d, 0
    cmove r9d, r8d
    mov [rbp-36], r9d
    mov rdi, LOCAL_PATCH_ARR
    mov esi, 1
    call entry_array_reserve_size
    mov [rbp-40], ebx
    mov [rbp-48], rax
    mov rdx, [rbp-24]
    xor ecx, ecx
    movzx ecx, byte [rdx+22]
    shr ecx, 6
    movzx eax, byte [rdx+23]
    shr eax, 6
    add ecx, eax
    add cl, byte [rdx+25]
    movzx eax, byte [rdx+52]
    shr eax, 6
    add ecx, eax
    add cl, byte [rdx+33]
    add cl, byte [rdx+24]
    mov al, [rbp-56]
    mov r8, [rbp-8]
    sub r8, 16
    mov rbx, [rbp-48]
    mov r9, [rbp-16]
    mov r11d, [rbp-28]
    mov r12d, [rbp-32]
    mov r13d, [rbp-36]
    mov r14d, [rbp-52]
    mov [rbx+2], r14b
    mov [rbx+3], cl
    mov [rbx+4], r11b
    mov [rbx+5], al
    mov [rbx+6], r12b
    mov [rbx+7], r13b
    mov [rbx+8], r8
    mov [rbx+16], r9
_end_push_to_segment_patch:
    add rsp, 64
    pop rbp
    ret

;TODO: push all to reloc on obj file gen?
; rdi - sym ptr, rsi - ptr to token entry header, rdx - ptr to ins code struct
; ecx - type, r8d - disp size, r9d - offset to disp from start of ins
push_to_delayed_patch:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov [rbp-28], ecx
    mov [rbp-32], r8d
    mov [rbp-36], r9d
    mov al, [rdi+15]
    cmp al, SYM_REF_MOD_EXTRN
    je _rel_entry_ptdp
    mov rdi, DELAYED_PATCH_ARR
    mov esi, 1
    call entry_array_reserve_size
    jmp _set_prdp
_rel_entry_ptdp:
    mov rdi, RELOC_PATCH_ARR
    mov esi, 1
    call entry_array_reserve_size
_set_prdp:
    mov [rbp-48], rax
    mov rdi, [rbp-8]
    mov rsi, [rbp-16]
    mov rdx, [rbp-24]
    mov ecx, [rbp-28]
    mov r8d, [rbp-32]
    mov r9d, [rbp-36]
    mov r10d, dword [CURR_SECTION_OFFSET]
    mov [rax], rdi
    mov [rax+8], rsi
    mov [rax+16], cl
    mov [rax+17], r9b
    mov [rax+18], r8b
    mov [rax+20], r10d
_end_push_to_delayed_patch:
    add rsp, 64
    pop rbp
    ret

; rdi - sym ptr, rsi - ptr to token entry header, rdx - ptr to ins code struct
; ecx - type, r8d - max disp size (in bytes), r9d - min disp size (can be set to 0 if max == min)
; r10d - sub to min ins len (opcode+disp), r11d - offset to disp from start of ins
push_to_addr_patch:
    push rbp
    mov rbp, rsp
    ;TODO: fix it
    mov eax, dword [CURR_SECTION_OFFSET]
    mov ebx, [rdi+16]
    cmp eax, ebx
    jne _delayed_push_tap
    call push_to_segment_patch
    jmp _end_push_to_addr_patch
_delayed_push_tap:
    mov r9d, r11d 
    call push_to_delayed_patch
_end_push_to_addr_patch:
    pop rbp
    ret

render_patch_delayed_ref:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    lea rsi, [DELAYED_PATCH_ARR]
    mov ecx, [rsi+8]
    mov eax, ADDR_ARR_PATCH_ENTRY_SIZE
    mul ecx
    mov rdx, [rsi]
    mov rdi, rdx
    add rdi, rax
    mov [rbp-8], rdx
    mov [rbp-16], rdi
    mov rbx, qword [SEG_ENTRY_ARRAY]
    mov [rbp-24], rbx
_loop_patch_rpdr:
    cmp rdx, rdi
    je _end_render_patch_delayed_ref
    mov rsi, [rdx]
    mov eax, [rsi+16]; sym seg offset
    lea rcx, [rbx+rax]
    mov r8d, [rcx+52]
    mov [rbp-28], r8d
    mov eax, [rsi+20]; sym rend buff offset
    mov rdi, [rcx]
    lea r8, [rdi+rax]
    mov eax, [r8]
    add [rbp-28], eax
    mov rsi, [rdx+8]
    mov eax, [rdx+20]
    lea rcx, [rbx+rax]
    mov rdi, [rcx+20]
    xor r8, r8
    mov r8b, [rdx+17]
    mov r9d, [rsi]
    ;TODO: check if it exec, obj or bin mod
    mov al, [rdx+16]
    cmp al, ADDR_PATCH_TYPE_DEF_RIP
    je _rip_patch_rpdr
    cmp al, ADDR_PATCH_TYPE_ABS
    je _abs_patch_rpdr 
    jmp _err_invalid_type_rpdr
_abs_patch_rpdr:
    add r9d, r8d
    mov eax, [DEF_BASE_ADDR]
    mov ecx, [rbp-28]
    add rax, rcx
    mov r10b, [rdx+18] 
    cmp r10b, 4
    jne _abs8_patch_rpdr
    mov [rdi+r9], eax
    jmp _next_patch_rpdr
_abs8_patch_rpdr:
    mov r10, r9 
    mov [r8], rax
    jmp _next_patch_rpdr
_rip_patch_rpdr:
    xor eax, eax
    mov al, [rsi+7]
    add eax, r9d
    add eax, [rcx+52]
    mov ecx, [rbp-28]
    sub ecx, eax
    add r9d, r8d
    add [rdi+r9], ecx
_next_patch_rpdr:
    add rdx, ADDR_ARR_PATCH_ENTRY_SIZE
    mov rdi, [rbp-16]
    jmp _loop_patch_rpdr
_err_invalid_type_rpdr:
_end_render_patch_delayed_ref:
    add rsp, 64
    pop rbp
    ret

; rdi - ptr to token buff entry_array, rsi - ptr to render entry_array
; rdx - ptr to header start from, ecx - amount of bytes to shift
reduce_ins_offset:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], ecx
    movzx ebx, byte [rdx+7]
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
    neg ecx ; TODO: revisit, (delete?)
    mov eax, [rdx+12]
    add rdx, rax
_start_loop_reduce_io:
    cmp rdx, r8
    jge _end_reduce_ins_offset
    mov rsi, rdx
    mov eax, [rdx+12]
    mov bl, [rdx+7]
    add rdx, rax
    test bl, bl
    jz _start_loop_reduce_io
    add [rsi], ecx ;(sub?)
    jmp _start_loop_reduce_io 
_end_reduce_ins_offset:
    mov eax, [rbp-20]
    mov rsi, [rbp-16]
    sub [rsi+8], eax
    add rsp, 32
    pop rbp
    ret

; rdi - ptr to start of token buff,
set_local_ref_in_dec_order:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-24], rdi
    mov rax, LOCAL_PATCH_ARR
    mov rdi, TEMP_SYM_PTR_ARR
    mov esi, [rax+8]
    call entry_array_reserve_size
    mov rdi, [rbp-24]
    mov rax, LOCAL_PATCH_ARR
    mov rbx, TEMP_SYM_PTR_ARR
    mov rcx, [rax]
    mov rsi, [rbx]
    mov eax, [rax+8]
    mov r8d, eax
    mov edx, SEGMENT_PATCH_ENTRY_SIZE
    mul edx
    add rax, rcx 
    shl r8d, 3
    add r8, rsi
    mov [rbp-8], rsi
    mov [rbp-16], r8
_copy_ptr_loop_slriro:
    cmp rcx, rax
    je _sort_by_sym_ref_slriro
    mov [rsi], rcx
    add rcx, SEGMENT_PATCH_ENTRY_SIZE
    add rsi, 8
    jmp _copy_ptr_loop_slriro
_sort_by_sym_ref_slriro:
    mov rdi, [rbp-24]
    mov rax, [rbp-8]
    mov r10, rax
    sub r8, 8
_i_sort_slriro:
    cmp rax, r8
    je _end_set_local_ref_in_dec_order
    mov rbx, r10
    mov r11, r8
    mov r9, rax
    sub r9, r10
    sub r11, r9
_y_sort_slriro:
    cmp rbx, r11
    je _i_end_sort_slriro
    mov r9, [rbx]
    mov rsi, [rbx+8]
    mov rcx, [r9+8]
    mov rdx, [rsi+8]
    mov r12d, [rcx+36]
    mov r13d, [rdx+36]
    mov r14d, [rdi+r12] 
    mov r15d, [rdi+r13]
    cmp r14d, r15d
    jbe _y_end_sort_slriro
    mov [rbx+8], r9
    mov [rbx], rsi
_y_end_sort_slriro:
    add rbx, 8
    jmp _y_sort_slriro
_i_end_sort_slriro:
    add rax, 8
    jmp _i_sort_slriro
_end_set_local_ref_in_dec_order:
    add rsp, 32
    pop rbp
    ret

; -8 ptr to seg token buff entry_array, -16 ptr to render entry_array
; -24 ptr to start of token buf, -32 ptr to start of render buff,
; -40 ptr to curr entry,-44 curr entry offset, -48 , -56 ptr to start of patch_arr
; -64 ptr to end of patch_arr, -72 ptr to arr of ptr of sym,
; -80 end of arr ptr for prev / ptr to last patch entry 
; edi - curr seg offset
render_patch_local_rel:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov rax, SEG_ENTRY_ARRAY
    mov rbx, [rax]
    lea rcx, [rbx+rdi]
    lea rdx, [rbx+rdi+20]
    mov [rbp-8], rcx
    mov [rbp-16], rdx
    mov rax, [rcx]
    mov rbx, [rdx]
    mov [rbp-24], rax
    mov [rbp-32], rbx
    mov rdi, rax
    call set_local_ref_in_dec_order
    mov rax, TEMP_SYM_PTR_ARR
    mov rbx, [rax]
    mov ecx, [rax+8]
    shl ecx, 3
    mov rdx, rbx
    add rdx, rcx
    mov [rbp-72], rbx
    mov [rbp-80], rdx
_start_patch_rplr:
    mov rbx, LOCAL_PATCH_ARR
    mov rcx, [rbx]
    mov r8d, [rbx+8]
    mov eax, SEGMENT_PATCH_ENTRY_SIZE
    mul r8d
    add rax, rcx
    mov [rbp-56], rcx
    mov [rbp-64], rax
    mov r8, rax
    mov r15, [rbp-24]
    mov r13, [rbp-32]
_loop_patch_rplr:
    cmp rcx, r8
    je _patch_ins_rplr 
    mov [rbp-40], rcx
    mov rax, [rcx+16]
    mov r9d, [rax]; curr sym offset
    mov [rbp-44], r9d
    mov rdx, [rcx+8]
    mov ebx, [rdx+36]
    mov r10d, [r15+rbx]; sym ref offset
    movzx eax, byte [rcx+3]
    add eax, r9d
    sub r10d, eax 
    lea rsi, [r13+r9]
    movzx ebx, byte [rcx+5]
    movzx eax, byte [rcx+2]
    mov r14d, [rsi+rbx]
    cmp r10d, 0
    jl __loop_neg_of_patch_rplr
    add r10d, r14d
    jmp __loop_check_th
__loop_neg_of_patch_rplr:
    sub r10d, r14d
    add r10d, eax
__loop_check_th:
    mov [rsi+rbx], r10d
    mov r11b, MAX_INT8
    mov r12b, MIN_INT8
    movsx r11d, r11b
    movsx r12d, r12b
    cmp r10d, r11d
    jg __loop_patch_next
    cmp r10d, r12d
    jl __loop_patch_next
__start_patch_before_rplr:
    mov [rbp-84], eax
    mov r14, rcx
    mov rcx, [rbp-56]
__loop_patch_before_rplr:
    cmp rcx, r14
    jae __start_patch_after_rplr
    mov rdx, [rcx+8]
    mov ebx, [rdx+36]
    mov eax, [r15+rbx]; check sym ref offset
    cmp eax, r9d
    jbe __loop_patch_before_next
    mov r10, [rcx+16]
    mov r11d, [r10]
    movzx ebx, byte [rcx+5]
    add r11d, ebx
    mov r12d, [rbp-84]
    sub [r13+r11], r12d
__loop_patch_before_next:
    add rcx, SEGMENT_PATCH_ENTRY_SIZE
    jmp __loop_patch_before_rplr
__start_patch_after_rplr:
    mov r12, [rbp-72]
    mov r14, [rbp-80]
__loop_patch_after_rplr:
    cmp r12, r14
    je __end_loop_patch_after
    mov rcx, [r12]
    mov rdx, [rcx+8]
    mov ebx, [rdx+36]
    mov eax, [r15+rbx]; check sym ref offset
    cmp eax, r9d
    ja __end_loop_patch_after
    mov r10, [rcx+16]
    mov r11d, [r10]
    cmp r11d, r9d
    jbe __loop_patch_after_next_rplr
    movzx ebx, byte [rcx+5]
    add r11d, ebx
    mov r10d, [rbp-84]
    sub [r13+r11], r10d
__loop_patch_after_next_rplr:
    add r12, 8
    jmp __loop_patch_after_rplr
__end_loop_patch_after:
    mov rcx, [rbp-40]
    mov r8, [rbp-64]
__loop_patch_next:
    add rcx, SEGMENT_PATCH_ENTRY_SIZE
    jmp _loop_patch_rplr
_patch_ins_rplr:
    mov r15, [rbp-56]
    mov rax, [rbp-64]
    sub rax, SEGMENT_PATCH_ENTRY_SIZE
_patch_loop_start_rplr:
    cmp rax, r15
    jb _end_render_patch_local_rel 
    mov rdi, [rbp-32]
    mov rdx, [rax+16]
    mov r9d, [rdx]; curr sym offset
    lea rsi, [rdi+r9]
    movzx ebx, byte [rax+5]
    mov ecx, [rsi+rbx]
    mov r11b, MAX_INT8
    mov r12b, MIN_INT8
    movsx r11d, r11b
    movsx r12d, r12b
    cmp ecx, r11d
    jg _patch_loop_next_rplr
    cmp ecx, r12d
    jl _patch_loop_next_rplr
    movzx r8d, byte [rax+4]
    cmp r8d, ADDR_PATCH_TYPE_JCC_RIP
    jne _check_jmp_patch_rplr
    mov bl, [rsi+1] ; from 2 byte jcc opcode to 1 byte
    sub bl, 0x10
    mov [rsi], bl
    mov [rsi+1], cl
    mov byte [rdx+7], 2
    movzx ecx, byte [rax+2]
    jmp _reduce_buffers_rplr
_check_jmp_patch_rplr:
    or byte [rsi], 0x2
    mov byte [rdx+7], 2
    movzx ecx, byte [rax+2]
_reduce_buffers_rplr:
    mov [rbp-80], rax
    mov rdi, [rbp-8]
    mov rsi, [rbp-16]
    call reduce_ins_offset
    mov r15, [rbp-56]
    mov rax, [rbp-80]    
_patch_loop_next_rplr:
    sub rax, SEGMENT_PATCH_ENTRY_SIZE
    jmp _patch_loop_start_rplr
_end_render_patch_local_rel:
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
    mov eax, 6
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
    lea rax, [r10+r9]
    movzx edi, byte [r10+r9+14]
    cmp edi, TOKEN_NAME_DATA
    je _end_is_name_rip_ref
    cmp edi, TOKEN_NAME_JMP
    je _end_is_name_rip_ref
    movzx edi, byte [r10+r9+15]
    cmp edi, SYM_REF_MOD_EXTRN
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

; rdi - ptr to TOKEN_BUF_PTR_OFFSET entry body
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

; rdi - ptr to render entry array, rsi - ptr to ins code struct
default_ins_assemble:
    push rbp
    mov rbp, rsp
    sub rsp, 20
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    call entry_array_curr_ptr
    mov r10, rax
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
    sub rdi, r10
    mov [rbp-20], edi
    mov rdi, [rbp-8]
    mov rsi, rax
    call entry_array_commit_size
    mov eax, [rbp-20]
    add rsp, 20
    pop rbp
    ret

; rdi - ptr to ins. code struct
get_ins_pref_opc_size:
    xor eax, eax
    movzx ecx, byte [rdi+22]
    shr eax, 6
    movzx ecx, byte [rdi+23]
    shr ecx, 6
    add eax, ecx
    add al, byte [rdi+25]
    movzx ecx, byte [rdi+52]
    shr ecx, 6
    add eax, ecx
    add al, byte [rdi+33]
    ret

; rdi - ptr to token group header, rsi - ptr to ins. code struct
set_rendered_size:
    xor ecx, ecx
    movzx ecx, byte [rdi+22]
    shr ecx, 6
    movzx eax, byte [rdi+23]
    shr eax, 6
    add ecx, eax
    add cl, byte [rdi+25]
    movzx eax, byte [rdi+52]
    shr eax, 6
    add ecx, eax
    add cl, byte [rdi+33]
    add cl, byte [rdi+24]
    mov [rdi+7], cl
    ret

; rdi - ptr to ins code struct, rsi - symbol of prefix
set_def_pref_by_symbol:
    cmp rsi, INS_REP
    je __set_def_pref_bs_rep
    cmp rsi, INS_REPE
    je __set_def_pref_bs_rep
    cmp rsi, INS_REPZ
    jne _set_def_pref_bs_check_repn
__set_def_pref_bs_rep:
    mov bl, 0xF3
    mov cl, PREFIX_TYPE_REP
    jmp _end_set_def_pref_by_symbol
_set_def_pref_bs_check_repn:
    cmp rsi, INS_REPNE
    je __set_def_pref_bs_repn
    cmp rsi, INS_REPNZ
    jne _set_def_pref_bs_lock
__set_def_pref_bs_repn:
    mov bl, 0xF2
    mov cl, PREFIX_TYPE_REPN
    jmp _end_set_def_pref_by_symbol
_set_def_pref_bs_lock:
    mov bl, 0xF0
    mov cl, PREFIX_TYPE_LOCK
_end_set_def_pref_by_symbol:
    movzx eax, byte [rdi+25] 
    mov [rdi+rax+16], bl
    mov [rdi+53], cl
    inc byte [rdi+25]
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

; rdi - ptr to token entry
set_reg_for_err_print:
    mov r10, rdi
    movzx eax, word [r10+4]
    mov ecx, FILE_ARRAY_ENTRY_SIZE
    mul ecx
    mov edi, eax
    xor rdx, rdx
    mov ecx, [r10+8]
    mov r8d, [r10+16]
    mov r9, -5
    ret

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
    or ecx, edx
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
;    jmp _success_gen_r_r
;err_gen_r_r_unrec_size:
;    mov eax, 1
;    jmp _end_process_gen_r_r
_success_gen_r_r:
    xor eax, eax
_end_process_gen_r_r:
    add rsp, 16
    pop rbp
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
    je _rproc_imm_name
    cmp ebx, TOKEN_NAME_JMP
    jne _err_rproc_imm_invalid_name
_rproc_imm_name:
    mov rsi, [rbp-16]
    mov r9, [rbp-24]
    mov edx, [rbp-28]
    cmp edx, REG_MASK_VAL_32B
    jb _err_rproc_imm_overflow
    mov r10, rax
    sub r10, NAME_SYM_REF_SERV_HS
    xor ecx, ecx
    mov byte [r9], REG_MASK_VAL_32B
    movzx eax, byte [rsi+24]
    mov [rsi+rax], ecx
    mov ecx, eax
    add eax, 4
    mov byte [rsi+24], al 
    mov [rsi+55], cl
    mov byte [rsi+57], 1
    mov [rsi+72], r10
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
    mov r11d, eax
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
    mov rax, ERR_IMM_NAME_REF
    jmp _end_render_process_imm
_err_rproc_imm_overflow:
    mov rax, ERR_IMM_OVERFLOW
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
    test rax, rax
    jnz _end_process_gen_rm_i
    mov rdi, [rbp-16]
    mov al, [rdi+57]
    test al, al
    jz _end_process_gen_rm_i 
    call get_ins_pref_opc_size   
    movzx r9d, byte [rdi+55]
    add r9d, eax
    xor r8,r8
    inc r8
    mov cl, byte [rdi+27]
    shr cl, 4
    shl r8b, cl
    mov ecx, ADDR_PATCH_TYPE_ABS
    mov rdx, [rbp-16]
    mov rsi, [rbp-24]
    mov rdi, [rdi+72]
    call push_to_delayed_patch
    xor eax, eax
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
    mov r15d, eax
    and r15d, REG_MASK_REG_VAL
    and ecx, REG_MASK_REG_IDX
    and edx, REG_MASK_BITS
    cmp edx, REG_MASK_VAL_64B
    jne _err_rproc_addr_invalid_reg_size
    and eax, REG_MASK_DEF_NORM
    cmp r15d, REG_REX_TH
    jb __rproc_addr_1p_check_r
    mov r11b, REX_B
    or r11b, REX
    or [rbp-20], r11b
__rproc_addr_1p_check_r:
    cmp eax, REG_RBP
    je _rproc_addr_1p_rbp
    cmp eax, REG_RSP
    je _rproc_addr_1p_rsp
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
    test rax, rax
    jz _err_rproc_invalid_ref_name
    ;TODO: add to patch list of offset
    mov rsi, [rbp-16]
    mov r9b, [rsi]
    or r9b, MOD_ADDR_REG
    or r9b, 0x5
    mov [rsi], r9b
    mov dword [rsi+1], 0
    mov cl, byte [rsi+24]
    add byte [rsi+24], 4
    mov [rsi+54], cl
    mov byte [rsi+56], 1
    mov [rsi+64], rax
    jmp _success_render_process_addr
_rproc_addr_2p:
    cmp ebx, TOKEN_BUF_DIRECT
    jne __rproc_addr_2p_ref_check
    mov eax, [r8+9]
    mov ecx, eax
    mov edx, eax
    mov r15d, eax
    and r15d, REG_MASK_REG_VAL
    and ecx, REG_MASK_REG_IDX
    and edx, REG_MASK_BITS
    cmp edx, REG_MASK_VAL_64B
    jne _err_rproc_addr_invalid_reg_size
    cmp r15d, REG_REX_TH
    jb __rproc_addr_2p_check_arith1
    mov r11b, REX_B
    or r11b, REX
    or [rbp-20], r11b
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
    and eax, REG_MASK_DEF_NORM
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
    xor r14, r14
    mov ecx, eax
    mov edx, eax
    mov r15d, eax
    and r15d, REG_MASK_REG_VAL
    and ecx, REG_MASK_REG_IDX
    and edx, REG_MASK_BITS
    cmp edx, REG_MASK_VAL_64B
    jne _err_rproc_addr_invalid_reg_size
    cmp r15d, REG_REX_TH
    jb __rproc_addr_2p_sib_init
    mov r11b, REX_X
    or r11b, REX
    or [rbp-20], r11b
__rproc_addr_2p_sib_init:
    shl ecx, 3
    mov ebx, [rbp-28]
    or r14b, bl
    or r14b, cl
    mov [rbp-60], r14b
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
    and edx, REG_MASK_DEF_NORM
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
    mov cl, [rsi+24]
    mov [rsi+54], cl
    mov byte [rsi+56], 1
    mov [rsi+64], rax
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
    mov edx, [r15]; in addr disp can't be bigger more then 4 bytes
    mov [rsi+1], edx
    add byte [rsi+24], 4
    jmp _success_render_process_addr
_err_rproc_count:
    mov rax, ERR_INV_ADDR_ARGC
    jmp _end_render_process_addr
_err_rproc_addr_invalid_scale:
    mov rax, ERR_INV_ADDR_SCALE
    jmp _end_render_process_addr
_err_rproc_addr_invalid_2nd:
    mov rax, ERR_INV_2ND_ADDR_PARAM
    jmp _end_render_process_addr
_err_rproc_addr_2p_sub_reg:
    mov rax, ERR_INV_2ND_ADDR_SUB 
    jmp _end_render_process_addr
_err_rproc_addr_invalid_reg_size:
    mov rax, ERR_ADDR_REG_SIZE 
    jmp _end_render_process_addr
_err_rproc_1param_invalid:
    mov rax, ERR_INV_1ST_ADDR_PARAM 
    jmp _end_render_process_addr
_err_rproc_invalid_ref_name:
    mov rax, ERR_INV_NAME_REF_ADDR 
    jmp _end_render_process_addr
_err_rproc_second_param_non_const:
    mov rax, ERR_INV_ADDR_LAST_NAME 
    jmp _end_render_process_addr
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
    jnz _end_process_gen_r_a
    mov r9d, ebx
    test r9b, r9b
    jz _check_sym_ref_gen_r_a
    mov rsi, [rbp-16]
    mov [rsi+52], r9b
_check_sym_ref_gen_r_a:
    mov al, [rsi+56]
    test al, al
    jz _success_gen_r_a
    mov rdi, rsi
    call get_ins_pref_opc_size   
    movzx r9d, byte [rdi+54]
    add r9d, eax
    xor r8,r8
    mov r8b, 4
    mov ecx, ADDR_PATCH_TYPE_DEF_RIP
    mov rdx, [rbp-16]
    mov rsi, [rbp-24]
    mov rdi, [rdi+64]
    call push_to_delayed_patch
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
    jnz _end_process_gen_a
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
    jz _check_sym_ref_gen_a
_gen_a_set_rex:
    mov [rsi+52], bl
    jmp _check_sym_ref_gen_a
_err_gen_a_size_unspec:
    mov rax, ERR_ADDR_SIZE_QUAL 
    jmp _end_process_gen_a
_check_sym_ref_gen_a:
    mov al, [rsi+56]
    test al, al
    jz _success_gen_a
    mov rdi, rsi
    call get_ins_pref_opc_size   
    movzx r9d, byte [rdi+54]
    add r9d, eax
    xor r8,r8
    mov r8b, 4
    mov ecx, ADDR_PATCH_TYPE_DEF_RIP
    mov rdx, [rbp-16]
    mov rsi, [rbp-24]
    mov rdi, [rdi+64]
    call push_to_delayed_patch
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
    cmp eax, REG_REX_TH
    jb _gen_a_r_addr_check
    or r9b, REX_R
    and eax, REG_MASK_REG_IDX
_gen_a_r_addr_check:
    xor r12, r12
    shl eax, 3
    or r12b, al
    mov byte [rsi], r12b
    inc byte [rsi+24]
    mov edx, r9d
    xor ecx, ecx
    mov r8d, 1
    mov r9, [rbp-32]
    call render_process_addr
    test rax, rax
    jnz _end_process_gen_a_r
    mov r9d, ebx
    mov rsi, [rbp-16]
    mov dl, [rsi+26]
    cmp dl, REG_MASK_VAL_64B
    jne _gen_a_r_check_16
    or r9b, REX_W
_gen_a_r_check_16:
    cmp dl, REG_MASK_VAL_16B
    jne _gen_a_r_check_rex
    mov byte [rsi+23], PREFIX_16BIT
_gen_a_r_check_rex:
    test r9b, r9b
    jz _check_ref_gen_a_r
    or r9b, REX
    mov [rsi+52], r9b
_check_ref_gen_a_r:
    mov al, [rsi+56]
    test al, al
    jz _success_gen_a_r
    mov rdi, rsi
    call get_ins_pref_opc_size   
    movzx r9d, byte [rdi+54]
    add r9d, eax
    xor r8,r8
    mov r8b, 4
    mov ecx, ADDR_PATCH_TYPE_DEF_RIP
    mov rdx, [rbp-16]
    mov rsi, [rbp-24]
    mov rdi, [rdi+64]
    call push_to_delayed_patch
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
    sub rsp, 36
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
    jnz _end_process_gen_a_i
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
_gen_a_i_test_rex:
    test ebx, ebx
    jz _gen_a_i_skip_rex
_gen_a_i_set_rex:
    mov [rsi+52], bl
_gen_a_i_skip_rex:
    mov rbx, [rbp-8]
    movzx eax, byte [rbx+2]
    lea rdi, [rbx+rax]
    mov edx, 1
    movzx ecx, byte [rsi+26]
    mov r8, [rbp-32]
    call render_process_imm
    test rax, rax
    jnz _end_process_gen_a_i
_check_ref_gen_a_i:
    mov rdi, rsi
    call get_ins_pref_opc_size   
    mov r10d, eax
    mov [rbp-36], eax
    mov al, [rdi+56]
    test al, al
    jz __check_ref_sec_gen_a_i
    movzx r9d, byte [rdi+54]
    add r9d, r10d
    xor r8,r8
    mov r8b, 4
    mov ecx, ADDR_PATCH_TYPE_DEF_RIP
    mov rdx, [rbp-16]
    mov rsi, [rbp-32]
    mov rdi, [rdi+64]
    call push_to_delayed_patch
__check_ref_sec_gen_a_i:
    mov rdi, [rbp-16]
    mov r10d, [rbp-36]
    mov al, [rdi+57]
    test al, al
    jz _success_gen_a_i
    movzx r9d, byte [rdi+57]
    add r9d, r10d
    xor r8,r8
    mov r8b, 4
    mov ecx, ADDR_PATCH_TYPE_ABS
    mov rdx, [rbp-16]
    mov rsi, [rbp-32]
    mov rdi, [rdi+72]
    call push_to_delayed_patch
_success_gen_a_i:
    xor eax, eax
    jmp _end_process_gen_a_i
_err_gen_a_i_size_unspec:
    mov rax, ERR_ADDR_SIZE_QUAL 
    jmp _end_process_gen_a_i
_end_process_gen_a_i:
    add rsp, 36
    pop rbp
    ret

; -8 passed rdi, -16 passed rsi, -24 render entry array, -32-38 (reserved), -42 (4b) opcode
; -192 ins code struct,
; rdi - segment ptr, rsi - ptr to token entry to process
process_mov:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    movzx eax, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
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
    lea rdi, [rbp-192]
    mov r8, rdi
    rep stosb
    mov byte [r8+33], 1
    add rsi, TOKEN_HEADER_PLUS_INS_TOKEN
    movzx ebx, byte [rsi]
    cmp ebx, TOKEN_BUF_DIRECT
    je _mov_direct
    cmp ebx, TOKEN_BUF_ADDR
    je _mov_a
    jmp _err_invalid_first_param_mov
_mov_direct:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    je _mov_r
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
    lea rsi, [rbp-192]
    call process_gen_r_r
    test rax, rax
    jnz _err_gen_mov
    lea r8, [rbp-192]
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
    lea rsi, [rbp-192]
    mov rdx, [rbp-16]
    call process_gen_r_a
    test rax, rax
    jnz _err_gen_mov
    lea r8, [rbp-192]
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
    lea rsi, [rbp-192]
    mov rdx, [rbp-16]
    call process_gen_rm_i
    test rax, rax
    jnz _err_gen_mov
    lea r8, [rbp-192]
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
    lea rsi, [rbp-192]
    mov rdx, [rbp-16]
    call process_gen_a_r
    test rax, rax
    jnz _err_gen_mov
    lea r8, [rbp-192]
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
    lea rsi, [rbp-192]
    mov rdx, [rbp-16]
    call process_gen_a_i
    test rax, rax
    jnz _err_gen_mov
    lea r8, [rbp-192]
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
    lea rsi, [rbp-192]
    call default_ins_assemble
    mov rsi, [rbp-16]
    mov [rsi+7], al
    jmp _end_process_mov
_err_gen_mov:
    mov rsi, rax
    jmp _err_exit_mov
_err_arg_size_mov:
    mov rsi, ERR_INS_INV_ARGS_SIZE
    jmp _err_exit_mov
_err_invalid_argc_mov:
    mov rsi, ERR_INS_INV_ARGC
    jmp _err_exit_mov
_err_invalid_first_param_mov:
    mov rsi, ERR_INS_INV_1ST_PARAM
    jmp _err_exit_mov
_err_invalid_second_param_mov:
    mov rsi, ERR_INS_INV_2ND_PARAM
_err_exit_mov:
    mov rdi, [rbp-16]
    call set_reg_for_err_print
    call err_print
_end_process_mov:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_jumps:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    movzx eax, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
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
    lea rdi, [rbp-192]
    mov r8, rdi
    rep stosb
    mov al, 4
    mov [r8+24], al
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
    jne _err_gen_jumps
    lea rdi, [r9+1]
    call is_name_rip_ref
    test rax, rax
    jz _err_parse_invalid_rip_ref_jumps
    mov [rbp-48], rax
    lea r15, [rbp-192]
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
    xor r10, r10
    mov r11d, r8d
    ;TODO: max offset -127 - +128 bytes, set only for local_patch
    jmp _jumps_name_push
__jumps_jcc_check:
    mov ecx, ADDR_PATCH_TYPE_JCC_RIP
    mov r8d, 4
    mov r9d, 1
    mov r10d, r8d
    mov r11d, 2
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
    lea rdx, [rbp-192]
    mov ecx, ADDR_PATCH_TYPE_DEF_RIP
    call push_to_delayed_patch
    jmp __jumps_name_push_set_disp
__jumps_name_jmp:
    cmp eax, INS_JMP
    jne _err_gen_jumps
    mov byte [r15+29], 0xE9 
    mov byte [r15+33], 1
    mov ecx, ADDR_PATCH_TYPE_JMP_RIP
    mov r8d, 4
    mov r9d, 1
    mov r10d, 3
    mov r11d, 1
_jumps_name_push:
    mov rdi, [rbp-48]
    mov rsi, [rbp-16]
    lea rdx, [rbp-192]
    call push_to_addr_patch
__jumps_name_push_set_disp:
    lea rsi, [rbp-192]
    mov dword [rsi], 0
    jmp _jumps_assemble
_jumps_addr:
    mov rdi, r9
    lea rsi, [rbp-192]
    mov rdx, [rbp-16]
    mov byte [rsi+26], REG_MASK_VAL_32B; hack for not setting REX_W and still pass size check
    call process_gen_a
    test rax, rax
    jnz _err_gen_jumps
    jmp _jump_set_jmp_call
_jumps_direct:
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    jne _err_parse_invalid_arg_jumps
__jumps_direct_r:
    mov rdi, r9
    lea rsi, [rbp-192]
    call process_gen_r
    test rax, rax
    jnz _err_gen_jumps
    lea rsi, [rbp-192]
    mov bl, [rsi+26]
    cmp bl, REG_MASK_VAL_64B 
    jne _err_parse_invalid_reg_size_jumps
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
    lea r8, [rbp-192]
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
    lea rsi, [rbp-192]
    call set_rendered_size
    mov rdi, [rbp-24]
    call default_ins_assemble
    jmp _end_process_jumps
_err_gen_jumps:
    mov rsi, rax
    jmp _err_parse_jumps
_err_parse_invalid_reg_size_jumps:
    mov rsi, ERR_INS_INV_REG_SIZE
    jmp _err_parse_jumps
_err_parse_invalid_rip_ref_jumps:
    mov rsi, ERR_INS_INV_PARAM
    jmp _err_parse_jumps
_err_parse_invalid_arg_jumps:
    mov rsi, ERR_INS_INV_RIP_REF
    jmp _err_parse_jumps
_err_invalid_argc_jumps:
    mov rsi, ERR_INS_INV_ARGC
_err_parse_jumps:
    mov rdi, [rbp-16]
    call set_reg_for_err_print
    call err_print
_end_process_jumps:
    add rsp, 192
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
    movzx eax, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
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
    je _instemp0_direct
    cmp ebx, TOKEN_BUF_ADDR
    je _instemp0_a
    jmp _err_invalid_first_param_instemp0
_instemp0_direct:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    jne _err_invalid_first_param_instemp0
_instemp0_r:
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
    test rax, rax
    jnz _err_gen_instemp0
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
    test rax, rax
    jnz _err_gen_instemp0
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
    test rax, rax
    jnz _err_gen_instemp0
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
    test rax, rax
    jnz _err_gen_instemp0
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
    test rax, rax
    jnz _err_gen_instemp0
    mov r8, [rbp-16]
    mov byte [r8+34], OP12_TYPE_A_I
    jmp _instemp0_rm_i
_instemp0_rm_rm:
    mov r9, [rbp-24]
    mov dl, [r8+26]
    cmp dl, REG_MASK_VAL_8B
    cmovne ecx, ebx ; already loaded
    mov [r8+29], cl
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
_err_gen_instemp0:
    mov rsi, rax
    jmp _err_parse_instemp0
_err_arg_size_instemp0:
    mov rsi, ERR_INS_INV_ARGS_SIZE
    jmp _err_parse_instemp0
_err_instemp0_r_i_overflow:
    mov rsi, ERR_INS_REG_IMM_OVERFLOW
    jmp _err_parse_instemp0
_err_invalid_argc_instemp0:
    mov rsi, ERR_INS_INV_ARGC
    jmp _err_parse_instemp0
_err_invalid_second_param_instemp0:
    mov rsi, ERR_INS_INV_2ND_PARAM
    jmp _err_parse_instemp0
_err_invalid_first_param_instemp0:
    mov rsi, ERR_INS_INV_1ST_PARAM
_err_parse_instemp0:
    mov rdi, [rbp-8]
    call set_reg_for_err_print
    call err_print
_instemp0_assemble:
    mov rdi, [rbp-32]
    mov rsi, [rbp-16]
    call default_ins_assemble
    mov rsi, [rbp-8]
    mov [rsi+7], al
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
    mov dword [rbp-56], 0x00000003 ; flag, (reserved), reg mask, last opcode
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
    lea rsi, [rbp-192]
    mov al, [rsi+34]
    cmp al, OP12_TYPE_R_A
    je _test_proc_invalid_op
_test_proc_invalid_op:
_end_process_test:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process, rdx - ins code struct
; rcx - opcode list for instemp0 pattern, r8 - ptr to stack of caller
process_ins_template1:
    push rbp
    mov rbp, rsp
    sub rsp, 40
    movzx eax, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
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
    je _instemp1_direct
    cmp ebx, TOKEN_BUF_ADDR
    je _instemp1_a
    jmp _err_instemp1_invalid_first_param
_instemp1_direct:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    je _instemp1_r
    jmp _err_instemp1_invalid_first_param
_instemp1_r:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    jne _err_instemp1_invalid_first_param 
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_r
    test rax, rax
    jnz _err_gen_instemp1
    jmp _instemp1_assemble
_instemp1_a:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov rdx, [rbp-8]
    call process_gen_a
    test rax, rax
    jnz _err_gen_instemp1
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
    mov rsi, [rbp-8]
    mov [rsi+7], al
    jmp _end_instemp1_process
_err_gen_instemp1:
    mov rsi, rax
    jmp _err_instemp1_exit
_err_instemp1_invalid_argc:
    mov rsi, ERR_INS_INV_ARGC 
    jmp _err_instemp1_exit
_err_instemp1_invalid_first_param:
    mov rsi, ERR_INS_INV_1ST_PARAM 
_err_instemp1_exit:
    mov rdi, [rbp-8]
    call set_reg_for_err_print
    call err_print
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
process_imul:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov eax, [rdi+28]
    mov [rsi], eax
    xor rax, rax
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-32], rdi
    mov ecx, INS_CODE_STRUCT_SIZE
    lea r8, [rbp-192]
    mov rdi, r8
    rep stosb
    mov al, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
    mov [rbp-33], al
    add rsi, TOKEN_HEADER_PLUS_INS_TOKEN
    cmp al, 1
    je _imul_1op
    cmp al, 2
    je _imul_2op
    cmp al, 3
    je _imul_2op
    jmp _err_invalid_argc_imul
_imul_1op:
    movzx ebx, byte [rsi]
    cmp ebx, TOKEN_BUF_DIRECT
    je __imul_1op_r
    cmp ebx, TOKEN_BUF_ADDR
    je __imul_1op_a
    jmp _err_invalid_first_param_imul
__imul_1op_r:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    jne _err_instemp1_invalid_first_param 
    mov rdi, rsi
    lea rsi, [rbp-192]
    call process_gen_r
    test rax, rax
    jnz _err_gen_imul
    jmp _imul_set_1op
__imul_1op_a:
    mov rdi, rsi
    lea rsi, [rbp-192]
    mov rdx, [rbp-16]
    call process_gen_a
    test rax, rax
    jnz _err_gen_imul
_imul_set_1op:
    lea r8, [rbp-192]
    mov byte [r8+33], 1
    mov eax, 0xF6
    mov ebx, 0xF7
    mov cl, [r8+26]
    cmp cl, REG_MASK_VAL_8B
    cmovg eax, ebx
    mov [r8+29], al
    mov dl, 5
    shl dl, 3
    mov al, [r8]
    or al, dl
    mov [r8], al
    jmp _imul_assemble
_imul_2op:
    movzx ebx, byte [rsi]
    cmp ebx, TOKEN_BUF_DIRECT
    jne _err_invalid_first_param_imul
    mov al, [rsi+13]
    cmp al, TOKEN_TYPE_REG
    jne _err_invalid_first_param_imul
    lea r9, [rsi+15]
    mov [rbp-24], r9
    movzx ecx, byte [r9]
    cmp ecx, TOKEN_BUF_ADDR
    je __imul_2op_r_a
    cmp ecx, TOKEN_BUF_DIRECT
    jne _err_invalid_second_param_imul
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    jne _err_invalid_second_param_imul
__imul_2op_r_r:
    mov byte [r8+34], OP12_TYPE_R_R
    mov rdi, rsi
    mov rsi, r8
    call process_gen_r_r
    test rax, rax
    jnz _err_gen_imul
    lea rdi, [rbp-192]
    call switch_reg_to_r_rm
    jmp __imul_2op_check_op_size
__imul_2op_r_a:
    mov byte [r8+34], OP12_TYPE_R_A
    mov rdi, rsi
    mov rsi, r8
    mov rdx, [rbp-8]
    call process_gen_r_a
    test rax, rax
    jnz _err_gen_imul
__imul_2op_check_op_size:
    lea r8, [rbp-192]
    movzx ebx, byte [r8+26]
    movzx eax, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_imul
    or eax, ebx
    cmp eax, REG_MASK_VAL_8B
    je _err_invalid_second_param_imul
    mov dl, [rbp-33]
    cmp dl, 3
    je _imul_3op
_imul_set_2op:
    mov byte [r8+33], 2
    mov word [r8+29], 0xAF0F
    jmp _imul_assemble
_imul_3op:
    mov rbx, [rbp-24]
    mov al, [r8+34]
    cmp al, OP12_TYPE_R_R
    je _imul_3op_r_r
    movzx eax, byte [rbx+2]
    lea rdi, [rbx+rax]
    jmp _imul_3op_parse_digit
_imul_3op_r_r:
    lea rdi, [rbx+15]
_imul_3op_parse_digit:
    mov edx, 2
    movzx ecx, byte [r8+26]
    mov r8, [rbp-16]
    call render_process_imm
    test rax, rax
    jnz _err_gen_imul
    lea r8, [rbp-192]
    mov byte [r8+33], 1
    movzx esi, byte [r8+28]
    cmp esi, REG_MASK_VAL_64B
    je _err_imul_i_overflow
    cmp esi, REG_MASK_VAL_8B
    jne _imul_3op_non_b
    mov byte [r8+29], 0x6B
    jmp _imul_assemble
_imul_3op_non_b:
    mov byte [r8+29], 0x69
    movzx edi, byte [r8+26]
    mov ebx, REG_MASK_VAL_32B
    cmp edi, ebx
    cmovg edi, ebx
    call line_up_d_s_size
    add [r8+24], al
    jmp _imul_assemble
_err_gen_imul:
    mov rsi, rax
    jmp _err_parse_imul
_err_invalid_first_param_imul:
    mov rsi, ERR_INS_INV_1ST_PARAM
    jmp _err_parse_imul
_err_invalid_second_param_imul:
    mov rsi, ERR_INS_INV_2ND_PARAM
    jmp _err_parse_imul
_err_invalid_argc_imul:
    mov rsi, ERR_INS_INV_ARGC
    jmp _err_parse_imul
_err_imul_i_overflow:
    mov rsi, ERR_INS_REG_IMM_OVERFLOW
    jmp _err_parse_imul
_err_arg_size_imul:
    mov rsi, ERR_INS_INV_ARGS_SIZE
_err_parse_imul:
    ;TODO: add err
    mov eax, 1
    jmp _end_process_imul
_imul_assemble:
    mov rdi, [rbp-32]
    lea rsi, [rbp-192]
    call default_ins_assemble
    mov rsi, [rbp-16]
    mov [rsi+7], al
_success_process_imul:
    xor eax, eax
_end_process_imul:
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
    movzx eax, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
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
    test rax, rax
    jnz _err_gen_instemp2
    mov r8, [rbp-16]
    movzx ebx, byte [r8+26]
    movzx eax, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_instemp2
    cmp eax, REG_MASK_VAL_8B
    je _err_invalid_arg_size_instemp2
    mov rdi, r8
    call switch_reg_to_r_rm
    jmp _instemp2_load_opc
__instemp2_r_a:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov rdx, [rbp-8]
    call process_gen_r_a
    test rax, rax
    jnz _err_gen_instemp2
    mov r8, [rbp-16]
    movzx eax, byte [r8+26]
    movzx ebx, byte [r8+27]
    cmp eax, ebx
    jne _err_arg_size_instemp2
    cmp eax, REG_MASK_VAL_8B
    je _err_invalid_arg_size_instemp2
_instemp2_load_opc:
    mov r9, [rbp-24]
    mov cx, word [r9]
    mov [r8+29], cx
    mov al, [r9+2]
    test al, al
    jz _instemp2_assemble
    mov [r8+16], al
    mov byte [r8+25], 1
    jmp _instemp2_assemble
_err_gen_instemp2:
    mov rsi, rax
    jmp _err_parse_instemp2
_err_arg_size_instemp2:
    mov rsi, ERR_INS_INV_ARGS_SIZE
    jmp _err_parse_instemp2
_err_invalid_argc_instemp2:
    mov rsi, ERR_INS_INV_ARGC
    jmp _err_parse_instemp2
_err_invalid_second_param_instemp2:
    mov rsi, ERR_INS_INV_2ND_PARAM
    jmp _err_parse_instemp2
_err_invalid_first_param_instemp2:
    mov rsi, ERR_INS_INV_1ST_PARAM
    jmp _err_parse_instemp2
_err_invalid_arg_size_instemp2:
    mov rsi, ERR_INS_INV_ARG_SIZE
_err_parse_instemp2:
    mov rdi, [rbp-8]
    call set_reg_for_err_print
    call err_print
_instemp2_assemble:
    mov rdi, [rbp-32]
    mov rsi, [rbp-16]
    call default_ins_assemble
    mov rsi, [rbp-8]
    mov [rsi+7], al
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
    mov dword [rbp-64], 0x0000BD0F
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
    mov dword [rbp-64], 0x0000BC0F
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template2
_end_process_bsf:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_lzcnt:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x00F3BD0F
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template2
_end_process_lzcnt:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_tzcnt:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x00F3BC0F
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template2
_end_process_tzcnt:
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
    mov eax, [rsi+29]; header_size + type + ptr to str
    mov ecx, INS_CMOVO
    sub eax, ecx
    shl eax, 8
    add ebx, eax
    mov dword [rbp-64], ebx
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template2
_end_process_cmovcc:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process, rdx - ins code struct
; rcx - opcode list for instemp0 pattern, r8 - ptr to stack of caller
process_ins_template3:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rsi
    mov [rbp-16], rdx
    mov [rbp-24], rcx
    mov eax, [rdi+28]
    mov [rsi], eax
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-32], rdi
    mov ecx, INS_CODE_STRUCT_SIZE
    xor rax, rax
    mov rdi, rdx
    mov r8, rdx
    rep stosb
    xor r9b, r9b
    mov byte [r8+33], 1
    mov rcx, [rbp-24]
    mov al, [rcx+2]
    cmp al, 3
    jne _instemp3_check_w
    mov bl, [rcx]
    jmp _instemp3_set_op
_instemp3_check_w:
    cmp al, 2
    jne _instemp3_check_d
    mov bl, [rcx+1]
    mov byte [r8+23], PREFIX_16BIT 
    jmp _instemp3_set_op
_instemp3_check_d:
    cmp al, 1
    jne _instemp3_check_q
    mov bl, [rcx+1]
    jmp _instemp3_set_op
_instemp3_check_q:
    cmp al, 0
    jne _err_instemp3_parse
    mov bl, [rcx+1]
    or r9b, REX
    or r9b, REX_W
_instemp3_set_op:
    mov [r8+29], bl
    mov [r8+52], r9b
    mov edx, [rsi+12]
    mov rax, rsi
    add rax, TOKEN_HEADER_PLUS_INS_TOKEN 
    add rsi, rdx
    cmp rsi, rax
    je _instemp3_assemble
    mov dl, [rax]
    cmp dl, TOKEN_BUF_DIRECT
    jne _err_instemp3_parse
    mov bl, [rax+13]
    cmp bl, TOKEN_TYPE_INS
    jne _err_instemp3_parse
    mov esi, [rax+9]
    mov rdi, r8
    call set_def_pref_by_symbol
    jmp _success_instemp3
_err_instemp3_parse:
    mov rsi, ERR_INS_FORMAT
    mov rdi, [rbp-8]
    call set_reg_for_err_print
    call err_print
_instemp3_assemble:
    mov rdi, [rbp-32]
    mov rsi, [rbp-16]
    call default_ins_assemble
    mov rsi, [rbp-8]
    mov [rsi+7], al
_success_instemp3:
    xor eax, eax
_end_process_instemp3:
    add rsp, 32
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_movs:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov word [rbp-64], 0xA5A4
    mov r9, rsi
    add r9, TOKEN_HEADER_SIZE
    mov eax, [r9+9]
    mov ebx, INS_MOVSQ
    sub ebx, eax
    mov byte [rbp-62], bl
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template3
_end_process_movs:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_stos:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov word [rbp-64], 0xABAA
    mov r9, rsi
    add r9, TOKEN_HEADER_SIZE
    mov eax, [r9+9]
    mov ebx, INS_STOSQ
    sub ebx, eax
    mov byte [rbp-62], bl
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template3
_end_process_stos:
    add rsp, 192
    pop rbp
    ret

; TODO: allow use def const and check it
; rdi - segment ptr, rsi - ptr to token entry to process, rdx - ins code struct
; rcx - opcode list for instemp0 pattern, r8 - ptr to stack of caller
process_ins_template4:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov [rbp-8], rsi
    mov [rbp-16], rdx
    mov [rbp-24], rcx
    mov [r8+24], rdi
    mov [r8+16], rsi
    movzx eax, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
    cmp eax, 2
    jne _err_invalid_argc_instemp4
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
    je _instemp4_r
    cmp ebx, TOKEN_BUF_ADDR
    je _instemp4_a
    jmp _err_invalid_first_param_instemp4
_instemp4_r:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    jne _err_invalid_first_param_instemp4
    lea r9, [rsi+15]
    movzx ecx, byte [r9]
    cmp ecx, TOKEN_BUF_DIRECT
    jne _err_invalid_second_param_instemp4
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    je __instemp4_r_r
    cmp ebx, TOKEN_TYPE_DIGIT
    je __instemp4_r_i
    jmp _err_invalid_second_param_instemp4
__instemp4_r_r:
    mov eax, [r9+9]
    cmp eax, REG_CL
    jne _err_invalid_second_param_instemp4 
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_r_r
    test rax, rax
    jnz _err_gen_instemp4
    jmp _instemp4_set_rm_r
__instemp4_r_i:
    mov rax, [r9+1]
    cmp rax, 1
    je __instemp4_r_i_1
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_rm_i
    test rax, rax
    jnz _err_gen_instemp4
    jmp _instemp4_set_rm_i
__instemp4_r_i_1:
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_r
    test rax, rax
    jnz _err_gen_instemp4
    jmp _instemp4_set_rm_i_1
_instemp4_a:
    movzx eax, byte [rsi+2]
    lea r9, [rsi+rax]
    movzx ecx, byte [r9]
    cmp ecx, TOKEN_BUF_DIRECT
    jne _err_invalid_second_param_instemp4
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    je __instemp4_a_r
    cmp ebx, TOKEN_TYPE_DIGIT
    je __instemp4_a_i
    jmp _err_invalid_second_param_instemp4
__instemp4_a_r:
    mov eax, [r9+9]
    cmp eax, REG_CL
    jne _err_invalid_second_param_instemp4 
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_a_r
    test rax, rax
    jnz _err_gen_instemp4
    jmp _instemp4_set_rm_r
__instemp4_a_i:
    mov rax, [r9+1]
    cmp rax, 1
    je __instemp4_a_i_1
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_a_i
    test rax, rax
    jnz _err_gen_instemp4
    jmp _instemp4_set_rm_i
__instemp4_a_i_1:
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_a
    test rax, rax
    jnz _err_gen_instemp4
    jmp _instemp4_set_rm_i_1
_instemp4_set_rm_r:
    mov r8, [rbp-16]
    mov r9, [rbp-24]
    movzx eax, byte [r8+26]
    movzx ebx, byte [r9+2]
    movzx ecx, byte [r9+3]
    cmp eax, REG_MASK_VAL_8B
    cmovg ebx, ecx
    mov [r8+29], bl
    jmp _instemp4_assemble
_instemp4_set_rm_i_1:
    mov r8, [rbp-16]
    mov r9, [rbp-24]
    movzx eax, byte [r8+26]
    movzx ebx, byte [r9]
    movzx ecx, byte [r9+1]
    cmp eax, REG_MASK_VAL_8B
    cmovg ebx, ecx
    mov [r8+29], bl
    jmp _instemp4_assemble
_instemp4_set_rm_i:
    mov r8, [rbp-16]
    mov dl, [r8+27]
    cmp dl, REG_MASK_VAL_8B
    jne _err_imm_overflow_instemp4
    mov r9, [rbp-24]
    mov al, [r8+26]
    movzx ebx, byte [r9+4]
    movzx ecx, byte [r9+5]
    cmp al, REG_MASK_VAL_8B
    cmovg ebx, ecx
    mov [r8+29], bl
    jmp _instemp4_assemble
_err_gen_instemp4:
    mov rsi, rax
    jmp _err_instemp4_parse
_err_imm_overflow_instemp4:
    mov rsi, ERR_INS_REG_IMM_OVERFLOW
    jmp _err_instemp4_parse
_err_invalid_first_param_instemp4:
    mov rsi, ERR_INS_INV_1ST_PARAM
    jmp _err_instemp4_parse
_err_invalid_second_param_instemp4:
    mov rsi, ERR_INS_INV_2ND_PARAM
    jmp _err_instemp4_parse
_err_invalid_argc_instemp4:
    mov rsi, ERR_INS_INV_ARGC
_err_instemp4_parse:
    mov rdi, [rbp-8]
    call set_reg_for_err_print
    call err_print
_instemp4_assemble:
    mov r10b, [r9+6]
    shl r10b, 3
    mov r11b, [r8]
    and r11b, EXCL_REG_FIELD_MASK
    or r10b, r11b
    mov [r8], r10b
    mov rdi, [rbp-32]
    mov rsi, [rbp-16]
    call default_ins_assemble
    mov rsi, [rbp-8]
    mov [rsi+7], al
_success_instemp4:
    xor rax, rax
_end_process_ins_template4:
    add rsp, 32
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_shr:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0xD3D2D1D0
    mov dword [rbp-60], 0x0005C1C0;  reg mask, 2 last opcode
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template4
_end_process_shr:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_shl:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0xD3D2D1D0
    mov dword [rbp-60], 0x0004C1C0;  reg mask, 2 last opcode
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template4
_end_process_shl:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_sar:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0xD3D2D1D0
    mov dword [rbp-60], 0x0007C1C0;  reg mask, 2 last opcode
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template4
_end_process_sar:
    add rsp, 192
    pop rbp
    ret

; TODO: check source operand size specificator
; rdi - segment ptr, rsi - ptr to token entry to process, rdx - ins code struct
; rcx - opcode list for instemp0 pattern, r8 - ptr to stack of caller
process_ins_template5:
    push rbp
    mov rbp, rsp
    sub rsp, 40
    mov [rbp-8], rsi
    mov [rbp-16], rdx
    mov [rbp-24], rcx
    mov [r8+24], rdi
    mov [r8+16], rsi
    movzx eax, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
    cmp eax, 2
    jne _err_invalid_argc_instemp5
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
    jne _err_invalid_first_param_instemp5
_instemp5_r:
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    jne _err_invalid_first_param_instemp5
    lea r9, [rsi+15]
    movzx ecx, byte [r9]
    cmp ecx, TOKEN_BUF_ADDR
    je __instemp5_r_a
    cmp ecx, TOKEN_BUF_DIRECT
    jne _err_invalid_second_param_instemp5
    movzx ebx, byte [r9+13]
    cmp ebx, TOKEN_TYPE_REG
    je __instemp5_r_r
    jmp _err_invalid_second_param_instemp5
__instemp5_r_r:
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_r_r
    test rax, rax
    jnz _err_gen_instemp5
    mov rdi, [rbp-16]
    call switch_reg_to_r_rm
    jmp _instemp5_check_args_size
__instemp5_r_a:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov rdx, [rbp-8]
    call process_gen_r_a
    test rax, rax
    jnz _err_gen_instemp5
    jmp _instemp5_check_args_size
_instemp5_check_args_size:
    mov r9, [rbp-24]
    mov r8, [rbp-16]
    mov al, [r8+26]
    mov bl, [r8+27]
    cmp eax, REG_MASK_VAL_8B
    je _err_arg_size_instemp5
    mov cl, [r9+4]
    mov dl, [r9+5]
    cmp bl, cl
    je _instemp5_check_1st_src
    cmp bl, dl
    jne _err_arg_size_instemp5
_instemp5_check_2nd_src:
    mov cl, [r9+8]
    mov dl, [r9+9]
    cmp al, cl
    jb _err_arg_size_instemp5
    cmp al, dl
    jg _err_arg_size_instemp5
    mov dx, [r9+2]
    jmp _instemp5_set_op
_instemp5_check_1st_src:
    mov cl, [r9+6]
    mov dl, [r9+7]
    cmp al, cl
    jb _err_arg_size_instemp5
    cmp al, dl
    jg _err_arg_size_instemp5
    mov dx, [r9]
_instemp5_set_op:
    mov [r8+29], dx
    mov bl, [r9+10]
    mov byte [r8+33], bl
    jmp _instemp5_assemble
_err_gen_instemp5:
    mov rsi, rax
    jmp _err_parse_instemp5
_err_arg_size_instemp5:
    mov rsi, ERR_INS_INV_ARGS_SIZE
    jmp _err_parse_instemp5
_err_instemp5_r_i_overflow:
    mov rsi, ERR_INS_REG_IMM_OVERFLOW
    jmp _err_parse_instemp5
_err_invalid_argc_instemp5:
    mov rsi, ERR_INS_INV_ARGC
    jmp _err_parse_instemp5
_err_invalid_second_param_instemp5:
    mov rsi, ERR_INS_INV_2ND_PARAM
    jmp _err_parse_instemp5
_err_invalid_first_param_instemp5:
    mov rsi, ERR_INS_INV_1ST_PARAM
_err_parse_instemp5:
    mov rdi, [rbp-8]
    call set_reg_for_err_print
    call err_print
_instemp5_assemble:
    mov rdi, [rbp-32]
    mov rsi, [rbp-16]
    call default_ins_assemble
    mov rsi, [rbp-8]
    mov [rsi+7], al
_success_process_instemp5:
    xor eax, eax
_end_process_instemp5:
    add rsp, 40 
    pop rbp
    ret

process_movzx:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0xB70FB60F
    mov dword [rbp-60], 0x30101000
    mov dword [rbp-56], 0x00023020
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template5
_end_process_movzx:
    add rsp, 192
    pop rbp
    ret

process_movsx:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0xBF0FBE0F
    mov dword [rbp-60], 0x30101000
    mov dword [rbp-56], 0x00023020
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template5
_end_process_movsx:
    add rsp, 192
    pop rbp
    ret

process_movsxd:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x00630063
    mov dword [rbp-60], 0x10102010
    mov dword [rbp-56], 0x00013020
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template5
_end_process_movsxd:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process, rdx - ins code struct
; rcx - opcode list for instemp0 pattern, r8 - ptr to stack of caller
process_ins_template6:
    push rbp
    mov rbp, rsp
    sub rsp, 40
    movzx eax, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
    cmp eax, 1
    jne _err_instemp6_invalid_argc
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
    jne _instemp6_check_a
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    je _instemp6_r
    jmp _instemp6_check_i
_instemp6_check_a:
    cmp ebx, TOKEN_BUF_ADDR
    je _instemp6_a
_instemp6_check_i:
    mov r9, [rbp-24]
    mov dl, [r9+3]
    test dl, dl
    jz _err_instemp6_invalid_first_param  
    cmp ebx, TOKEN_BUF_PTR_OFFSET; gonna be false if rip comes from *TYPE_REG cmp
    je _instemp6_i
    cmp eax, TOKEN_TYPE_DIGIT
    je _instemp6_i
    jmp _err_instemp6_invalid_first_param
_instemp6_i:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov edx, 0
    mov ecx, REG_MASK_VAL_32B
    mov r8, [rbp-8]
    call render_process_imm
    test rax, rax
    jnz _err_gen_instemp6
    mov rsi, [rbp-16]
    mov r9, [rbp-24]
    mov al, [rsi+26]
    movzx ebx, byte [r9+4]
    movzx ecx, byte [r9+5]
    cmp al, REG_MASK_VAL_8B
    cmovg ebx, ecx
    mov [rsi+29], bl
    xor edx, edx
    mov ecx, PREFIX_16BIT
    cmp al, REG_MASK_VAL_16B
    cmovne ecx, edx
    mov [rsi+23], cl
    jmp _instemp6_assemble_end
_instemp6_r:
    mov rdi, rsi
    mov rsi, [rbp-16]
    call process_gen_r
    test rax, rax
    jnz _err_gen_instemp6
    mov rsi, [rbp-16]
    mov r9, [rbp-24]
    mov byte [rsi+24], 0
    mov cl, [r9+1]
    mov edx, [rsi+36]
    and edx, REG_MASK_REG_IDX
    or cl, dl
    mov [rsi+29], cl
    jmp _instemp6_assemble
_instemp6_a:
    mov rdi, rsi
    mov rsi, [rbp-16]
    mov rdx, [rbp-8]
    call process_gen_a
    test rax, rax
    jnz _err_gen_instemp6
    mov rsi, [rbp-16]
    mov r9, [rbp-24]
    mov dl, [r9+2]
    mov al, [r9]
    shl dl, 3
    mov cl, [rsi]
    or cl, dl
    mov [rsi+29], al
    mov [rsi], cl
_instemp6_assemble:
    mov bl, [rsi+26]
    cmp bl, REG_MASK_VAL_32B
    je _err_instemp6_invalid_arg_size
    movzx eax, byte [rsi+52]
    mov ecx, eax
    xor ebx, ebx
    and ecx, EXCL_REX_W_MASK
    and eax, REX_B
    cmp eax, 0
    test eax, eax
    cmovnz ebx, ecx
    mov [rsi+52], bl
_instemp6_assemble_end:
    mov rdi, [rbp-32] 
    call default_ins_assemble
    mov rsi, [rbp-8]
    mov [rsi+7], al
    jmp _end_instemp6_process
_err_gen_instemp6:
    mov rsi, rax
    jmp _err_instemp6_exit
_err_instemp6_invalid_argc:
    mov rsi, ERR_INS_INV_ARGC
    jmp _err_instemp6_exit
_err_instemp6_invalid_arg_size:
    mov rsi, ERR_INS_INV_ARG_SIZE
    jmp _err_instemp6_exit
_err_instemp6_invalid_first_param:
    mov rsi, ERR_INS_INV_1ST_PARAM
_err_instemp6_exit:
    mov rdi, [rbp-8]
    call set_reg_for_err_print
    call err_print
_end_instemp6_process:
    add rsp, 40
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_push:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x010650FF
    mov dword [rbp-60], 0x0000686A
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template6
_end_process_push:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_pop:
    push rbp
    mov rbp, rsp
    sub rsp, 192
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov dword [rbp-64], 0x0000588F
    lea rdx, [rbp-192]
    lea rcx, [rbp-64]
    lea r8, [rbp-32]
    call process_ins_template6
_end_process_pop:
    add rsp, 192
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_lea:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov eax, [rdi+28]
    mov [rsi], eax
    xor rax, rax
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-32], rdi
    mov ecx, INS_CODE_STRUCT_SIZE
    lea r8, [rbp-128]
    mov rdi, r8
    rep stosb
    mov al, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
    cmp al, 2
    jne _err_invalid_argc_lea
    add rsi, TOKEN_HEADER_PLUS_INS_TOKEN
    movzx ebx, byte [rsi]
    cmp ebx, TOKEN_BUF_DIRECT
    jne _err_invalid_first_param_lea
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_REG
    jne _err_instemp1_invalid_first_param 
    movzx ecx, byte [rsi+15]
    cmp ecx, TOKEN_BUF_ADDR
    jne _err_invalid_second_param_lea
    mov rdi, rsi
    mov rsi, r8
    mov rdx, [rbp-8]
    call process_gen_r_a
    test rax, rax
    jnz _err_gen_lea
    lea r8, [rbp-128]
    mov bl, [r8+26]
    cmp bl, REG_MASK_VAL_8B
    je _err_invalid_arg_size_lea
    mov byte [r8+33], 1
    mov byte [r8+29], 0x8D
    jmp _lea_assemble
_err_gen_lea:
    mov rsi, rax
    jmp _err_parse_lea
_err_invalid_first_param_lea:
    mov rsi, ERR_INS_INV_1ST_PARAM
    jmp _err_parse_lea
_err_invalid_second_param_lea:
    mov rsi, ERR_INS_INV_2ND_PARAM
    jmp _err_parse_lea
_err_invalid_argc_lea:
    mov rsi, ERR_INS_INV_ARGC
    jmp _err_parse_lea
_err_invalid_arg_size_lea:
    mov rsi, ERR_INS_INV_ARGS_SIZE
_err_parse_lea:
    mov rdi, [rbp-8]
    call set_reg_for_err_print
    call err_print
_lea_assemble:
    mov rdi, [rbp-32]
    lea rsi, [rbp-128]
    call default_ins_assemble
_success_process_lea:
    xor eax, eax
_end_process_lea:
    add rsp, 128
    pop rbp
    ret

; NOTE: only near call
; rdi - segment ptr, rsi - ptr to token entry to process
process_ret:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-8], rdi
    call entry_array_curr_ptr
    mov byte [rax], 0xC3
    inc rax
    mov rsi, rax
    mov rdi, [rbp-8]
    call entry_array_commit_size
_end_process_ret:
    add rsp, 8
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_syscall:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-8], rdi
    call entry_array_curr_ptr
    mov word [rax], 0x050F
    add rax, 2
    mov rsi, rax
    mov rdi, [rbp-8]
    call entry_array_commit_size
_end_process_syscall:
    add rsp, 8
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_int:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov eax, [rdi+28]
    mov [rsi], eax
    xor rax, rax
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-32], rdi
    mov ecx, INS_CODE_STRUCT_SIZE
    lea r8, [rbp-128]
    mov rdi, r8
    rep stosb
    mov al, byte [rsi+TOKEN_OFFSET_TO_INS_ARGC]
    cmp al, 1
    jne _err_invalid_argc_int
    add rsi, TOKEN_HEADER_PLUS_INS_TOKEN
    movzx ebx, byte [rsi]
    cmp ebx, TOKEN_BUF_DIRECT
    jne _err_invalid_first_param_int
    movzx eax, byte [rsi+13]
    cmp eax, TOKEN_TYPE_DIGIT
    jne _err_instemp1_invalid_first_param 
    mov rdi, rsi
    lea rsi, [rbp-128]
    mov edx, 0
    mov ecx, REG_MASK_VAL_8B
    mov r8, [rbp-16]
    call render_process_imm
    test rax, rax
    jnz _err_gen_int
    lea rsi, [rbp-128]
    mov al, [rsi+26]
    mov byte [rsi+29], 0xCD
    mov byte [rsi+33], 1
    mov rdi, [rbp-32]
    call default_ins_assemble
    xor rax, rax
    jmp _end_process_int
_err_gen_int:
    mov rsi, rax
    jmp _err_parse_int
_err_invalid_argc_int:
    mov rsi, ERR_INS_INV_ARGC
    jmp _err_parse_int
_err_invalid_first_param_int:
    mov rsi, ERR_INS_INV_1ST_PARAM
_err_parse_int:
    mov eax, 1
    ;TODO: add err print
_end_process_int:
    add rsp, 128
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_int3:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-8], rdi
    call entry_array_curr_ptr
    mov byte [rax], 0xCC
    inc rax
    mov rsi, rax
    mov rdi, [rbp-8]
    call entry_array_commit_size
_end_process_int3:
    add rsp, 8
    pop rbp
    ret

; rdi - segment ptr, rsi - ptr to token entry to process
process_int1:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-8], rdi
    call entry_array_curr_ptr
    mov byte [rax], 0xF1
    inc rax
    mov rsi, rax
    mov rdi, [rbp-8]
    call entry_array_commit_size
_end_process_int1:
    add rsp, 8
    pop rbp
    ret

; TODO: handle addr ref
; rdi - segment ptr, rsi - ptr to token entry to process
process_data_define:
    push rbp
    mov rbp, rsp
    sub rsp, 72
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov [rbp-24], rdi
    mov ebx, [rdi+8]
    mov [rsi], ebx
    mov rbx, rsi
    mov eax, [rsi+12]
    add rbx, rax
    mov [rbp-32], rbx
    add rsi, TOKEN_HEADER_PLUS_TYPE
    mov [rbp-40], rsi
_start_loop_data_define_proc:
    mov rdx, [rbp-32]
    cmp rsi, rdx
    jae _end_process_data_define
    mov ecx, [rsi+8]
    and ecx, DATA_QUL_TYPE_MASK
    test ecx, ecx
    jz _err_process_data_define
    mov al, [rsi+14]
    mov [rbp-41], al
    add rsi, 15
    mov [rbp-40], rsi
    mov rdi, [rbp-24]
_loop_process_data_define:
    mov rsi, [rbp-40]
    mov rdx, [rbp-32]
    cmp rsi, rdx
    jae _end_process_data_define
    movzx ecx, byte [rsi]
    mov r8, rsi
    add r8, 15
    inc rsi
    mov [rbp-40], r8
    mov [rbp-72], rsi
    cmp ecx, TOKEN_BUF_DIRECT
    je _process_data_check_direct
    cmp ecx, TOKEN_BUF_PTR_OFFSET 
    jne _err_process_data_define
    xor eax, eax
    mov al, 2
    sub [rbp-40], rax
    mov rdi, rsi
    call get_name_ref_type
    mov rsi, rax
    mov [rbp-72], rax
    cmp ebx, TOKEN_NAME_CONST
    je _process_data_check_direct
    cmp ebx, TOKEN_NAME_CONST_MUT
    jne _err_process_data_define
_process_data_check_direct:
    movzx edx, byte [rsi+12]
    cmp edx, TOKEN_TYPE_DIGIT
    je _process_data_define_digit
    cmp edx, TOKEN_TYPE_STR
    je _process_data_define_str
    cmp edx, TOKEN_TYPE_KEYWORD
    je _start_loop_data_define_proc
    jmp _err_process_data_define
_process_data_define_digit:
    mov rdi, [rbp-24]
    mov esi, 8
    call entry_array_ensure_free_space
    mov rsi, [rbp-72]
    mov rdx, [rsi]
    mov [rax], rdx
    movzx ebx, byte [rbp-41]
    add rax, rbx
    mov rdi, [rbp-24]
    mov rsi, rax
    call entry_array_commit_size
    jmp _loop_process_data_define
_process_data_define_str:
    mov rdi, [rbp-24]
    mov esi, [rsi+8]
    call entry_array_ensure_free_space
    mov r8, [rbp-72]
    mov rsi, [r8]
    mov ecx, [r8+8]
    mov rdi, rax
    rep movsb
    mov rsi, rdi
    mov rdi, [rbp-24]
    call entry_array_commit_size
    jmp _loop_process_data_define
_err_process_data_define:
    mov rsi, ERR_DATA_SYM_REF
    mov rdi, [rbp-16]
    call set_reg_for_err_print
    call err_print
_end_process_data_define:
    add rsp, 72
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
    mov esi, [r9+12]
    add ecx, esi
    mov [rbp-12], ecx
    lea r10, [r9+TOKEN_HEADER_SIZE]
    movzx ebx, byte [r10]
    cmp ebx, TOKEN_BUF_DIRECT
    jne _err_processing_start_token
    mov rdi, [rbp-8]
    mov rsi, r9
    mov ebx, [r10+9]
    movzx eax, byte [r10+13]
    cmp eax, TOKEN_TYPE_INS
    je _check_ins_rps
    cmp eax, TOKEN_TYPE_KEYWORD
    jmp _check_kw_rps
_check_ins_rps:
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
    jne _check_ins_rps17
    call process_bsf
    jmp _start_loop_process_segment
_check_ins_rps17:
    cmp ebx, INS_LZCNT
    jne _check_ins_rps18
    call process_lzcnt
    jmp _start_loop_process_segment
_check_ins_rps18:
    cmp ebx, INS_TZCNT
    jne _check_ins_rps19
    call process_tzcnt
    jmp _start_loop_process_segment
_check_ins_rps19:
    cmp ebx, INS_MOVSB
    jb _check_ins_rps20
    cmp ebx, INS_MOVSQ
    ja _check_ins_rps20
    call process_movs
    jmp _start_loop_process_segment
_check_ins_rps20:
    cmp ebx, INS_STOSB
    jb _check_ins_rps21
    cmp ebx, INS_STOSQ
    ja _check_ins_rps_jmp
    call process_stos
    jmp _start_loop_process_segment
_check_ins_rps21:
    cmp ebx, INS_SHR
    jne _check_ins_rps22
    call process_shr
    jmp _start_loop_process_segment
_check_ins_rps22:
    cmp ebx, INS_SHL
    jne _check_ins_rps23
    call process_shl
    jmp _start_loop_process_segment
_check_ins_rps23:
    cmp ebx, INS_SAL
    jne _check_ins_rps24
    call process_shl
    jmp _start_loop_process_segment
_check_ins_rps24:
    cmp ebx, INS_SAR
    jne _check_ins_rps25
    call process_sar
    jmp _start_loop_process_segment
_check_ins_rps25:
    cmp ebx, INS_IMUL
    jne _check_ins_rps26
    call process_imul
    jmp _start_loop_process_segment
_check_ins_rps26:
    cmp ebx, INS_MOVZX
    jne _check_ins_rps27
    call process_movzx
    jmp _start_loop_process_segment
_check_ins_rps27:
    cmp ebx, INS_MOVSX
    jne _check_ins_rps28
    call process_movsx
    jmp _start_loop_process_segment
_check_ins_rps28:
    cmp ebx, INS_MOVSXD
    jne _check_ins_rps29
    call process_movsxd
    jmp _start_loop_process_segment
_check_ins_rps29:
    cmp ebx, INS_LEA
    jne _check_ins_rps30
    call process_lea
    jmp _start_loop_process_segment
_check_ins_rps30:
    cmp ebx, INS_PUSH
    jne _check_ins_rps31
    call process_push
    jmp _start_loop_process_segment
_check_ins_rps31:
    cmp ebx, INS_POP
    jne _check_ins_rps32
    call process_pop
    jmp _start_loop_process_segment
_check_ins_rps32:
    cmp ebx, INS_RET
    jne _check_ins_rps33
    call process_ret
    jmp _start_loop_process_segment
_check_ins_rps33:
    cmp ebx, INS_SYSCALL
    jne _check_ins_rps34
    call process_syscall
    jmp _start_loop_process_segment
_check_ins_rps34:
    cmp ebx, INS_INT
    jne _check_ins_rps35
    call process_int
    jmp _start_loop_process_segment
_check_ins_rps35:
    cmp ebx, INS_INT3
    jne _check_ins_rps36
    call process_int3
    jmp _start_loop_process_segment
_check_ins_rps36:
    cmp ebx, INS_INT1
    jne _check_ins_rps_jmp
    call process_int1
    jmp _start_loop_process_segment
_check_ins_rps_jmp:
    mov ecx, ebx
    and ecx, INS_JMP_TYPE_MASK
    test ecx, ecx
    jz _check_ins_rps_cmovcc 
    call process_jumps
    jmp _start_loop_process_segment
_check_ins_rps_cmovcc:
    and ebx, INS_CMOVCC_TYPE_MASK
    test ebx, ebx
    jz _err_processing_start_token 
    call process_cmovcc
    jmp _start_loop_process_segment
_check_kw_rps:
    mov ecx, ebx
    and ecx, DATA_QUL_TYPE_MASK
    test ecx, ecx
    jz _err_processing_start_token  
    call process_data_define
    jmp _start_loop_process_segment
_err_processing_start_token:
    mov rsi, ERR_INS_UNSUPPORT
    mov rdi, [rbp-8]
    call set_reg_for_err_print
    call err_print
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
    mov rdi, DELAYED_PATCH_ARR
    mov esi, 256
    call init_entry_array
    mov rdi, RELOC_PATCH_ARR
    mov esi, 256
    call init_entry_array
    mov rdi, LOCAL_PATCH_ARR
    mov esi, 256
    call init_entry_array
    mov rdi, TEMP_SYM_PTR_ARR
    mov esi, 256
    call init_entry_array
    ;TODO: check if it exec, obj or bin mod
    mov rdi, rsp
    call set_collate_seg_ptr
    mov [rbp-8], eax
    shl eax, 3
    mov [rbp-8], rsp
    mov rbx, rsp
    add rbx, rax
    mov [rbp-16], rbx
_render_seg_grab_loop:
    call clear_patch_state
    mov rdx, [rbp-8]
    mov rcx, [rbp-16]
    cmp rdx, rcx
    je _set_seg_addr_start_render
    mov rdi, [rdx]
    call render_process_segment
    mov eax, dword [LOCAL_PATCH_ARR+8]
    test eax, eax
    jz __next_render_grap_entry
    mov edi, dword [CURR_SECTION_OFFSET]
    call render_patch_local_rel
__next_render_grap_entry:
    add dword [rbp-8], 8
    jmp _render_seg_grab_loop
_set_seg_addr_start_render:
    xor eax, eax
    mov [rbp-28], eax 
    mov [rbp-8], rsp
_loop_set_asr:
    mov rdx, [rbp-8]
    mov rcx, [rbp-16]
    cmp rdx, rcx
    je _do_patchs_start_render
    mov rax, [rdx]
    mov edi, [rax+28]
    test edi, edi
    jz __next_loop_set_asr
    mov [rbp-24], rax
    mov ecx, [rbp-28]
    mov [rax+52], ecx
    mov esi, 4096
    call align_to_pow2
    mov rbx, [rbp-24]
    mov [rbx+56], eax
    add [rbp-28], eax
__next_loop_set_asr:
    add dword [rbp-8], 8
    jmp _loop_set_asr
_do_patchs_start_render:
    ;TODO: check if it exec, obj or bin mod
    call render_patch_delayed_ref
_end_start_render:
    add rsp, 2304
    pop rbp
    ret

render_set_segments:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    add rsp, 64
    pop rbp
    ret
