DEF_TOKEN_BUF_SIZE equ 40960
DEF_REN_BUF_SIZE   equ 8192

TOKEN_BUF_NONE       equ 0
TOKEN_BUF_PTR_OFFSET equ 1
TOKEN_BUF_DIRECT     equ 2
TOKEN_BUF_ADDR       equ 3

PARSER_ADDR_FLAG_BITS      equ 4
PARSER_ADDR_FLAG_MASK      equ 0xF
PARSER_ADDR_FLAG_REG       equ 0x1
PARSER_ADDR_FLAG_SCALE     equ 0x2
PARSER_ADDR_FLAG_REG_SCALE equ 0x3
PARSER_ADDR_FLAG_NAME      equ 0x4
PARSER_ADDR_FLAG_DIGIT     equ 0x8
MACRO_EMPTY_ARG_FLAG equ 0xFF
MACRO_COPY_ENTRY_SIZE equ 10

segment readable writeable
LAST_LINE_NUM dd 0
CURR_SEG_OFFSET dd 0

; entry
; 0 (4b) linked list entry offset to a chain of patch location,
;4:16 if token is _extrn_ or was defined as _global_ before def 
; +4 offset in file array, +8 offset of definition in file data,
; +12 line num in file
;4:16 else empty
; +16 symbol entry (round up to multible of 8, curr 16) (32b total)
UNK_ENTRY_SIZE equ 32
entry_array_data_m UNKNOWN_NAME_SYM_REF_ARRAY, UNK_ENTRY_SIZE

; linked list entry body - +4 offset in file array, +8 **ptr of buf to offset from,
; +16 offset in buff, +20 second indirectional offset (must be 0 if not set),
; +24 line num, +28 in file offset
PATCH_LIST_ENTRY_SIZE equ 32
list_main_block_m PATCH_LIST, PATCH_LIST_ENTRY_SIZE 

; entry
; 0 data size, +4 offset in file array, +8 offset of definition in file data,
; +12 line num in file
; +16 name symbol token (+30 type, +31 mod), (header size 32b)
; (+32 start of data)
;(TOKEN_NAME_CONST || TOKEN_NAME_CONST_MUT)
; +32 sym token
;(TOKEN_NAME_JMP)
;(TOKEN_NAME_DATA)
; +32 segment offset, +36 offset to entry header in seg token buf,
; +40 meta info ([if obj file - idx in symtab]), +42 is used for reloc, +43 1b reserved
;(TOKEN_NAME_MACR)
; +32 start offset of body in file buff, +36 start line of body in file,
; +40 copy entires (4 offset, 4 len, 1 arg num) _n_ times
NAME_CONST_ENTRY_SIZE    equ 46
NAME_DATA_ENTRY_SIZE     equ 44
NAME_DATA_BODY_SIZE      equ 12
NAME_SYM_REF_HEADER_SIZE equ 32
NAME_SYM_REF_SERV_HS     equ 16
entry_array_data_m NAME_SYM_REF_ARRAY, 1

; entry - 0 (entry array, work size 1b) token buf, +20 (entry array, work size 1b) render buf
; +40 [if sec. - ptr to sec. token], +48 mod (2b), +49 sec idx in sec.arr., 1b reserved, +52 offset from base
; +56 aligned to 2^12 rendered size
SEG_ENTRY_SIZE equ 64
entry_array_data_m SEG_ENTRY_ARRAY, SEG_ENTRY_SIZE
hash_table_data_m NAME_SYM_HASH_TABLE, 1

TOKEN_OFFSET_TO_INS_ARGC    equ 35
TOKEN_HEADER_PLUS_TYPE      equ 21
TOKEN_HEADER_PLUS_INS_TOKEN equ 36 ;20+1+14+1
TOKEN_HEADER_SIZE           equ 20
; TODO: finish format description
; token buf
; (header)(20b)
; 0(4) offset in render buf, +4(2) file entry id, +6 skip flag (is token group represent renderable info.),
; +7 (count of rendered bytes for TOKEN_TYPE_INS), +8(4) line num, +12(4) entry size in bytes
; token buf, +16 offset to line in file buff
; +20 (body) 
; +16(1) token type, +17 [(8) ptr to token | (TOKEN_KIND_SIZE) token body, [if TOKEN_KIND_INS +31 argc]] ... (n times)
; token type, qul size keyword token,(1) size of unit in bytes, 
; [direct digit | str token | ptr offset | direct dub kw, direct digit ... [n times]
;TODO: add buff off. and lin num for each new data line

segment readable executable

;rdi - ptr to token entry array, esi - size of push mem, rdx - ptr to push mem
;return rax - ptr to start of alloc mem, ebx - offset in buffer
token_buf_push_size:
    push rbp
    mov rbp, rsp
    sub rsp, 20
    mov [rbp-8], rdx
    mov [rbp-12], esi
    call entry_array_reserve_size
    mov rdi, rax
    mov rsi, [rbp-8]
    mov ecx, [rbp-12]
    rep movsb
_end_token_buf_push_size:
    add rsp, 20
    pop rbp
    ret

;-8 passed rdi, -24 token group entry header
;rdi - ptr to token entry array, esi - offset of curr file entry
push_token_entry_header:
    push rbp
    mov rbp, rsp
    sub rsp, 28
    mov [rbp-28], rdi
    mov rbx, rdi
    xor eax, eax
    lea rdi, [rbp-20]
    mov ecx, TOKEN_HEADER_SIZE 
    rep stosb
    mov r8, [FILES_ARRAY]
    lea rax, [r8+rsi]
    mov r9, rax
    sub rax, r8
    xor rdx, rdx
    mov rcx, FILE_ARRAY_ENTRY_SIZE
    div rcx
    mov [rbp-16], ax
    mov edx, [r9+16]
    mov ebx, [r9+44]
    mov [rbp-12], ebx
    mov [rbp-4], edx
    mov rdi, [rbp-28]
    lea rdx, [rbp-20] 
    mov esi, TOKEN_HEADER_SIZE
    call token_buf_push_size
_end_push_render_entry_header:
    add rsp, 28
    pop rbp
    ret

;rdi - ptr to ht entry, rsi - ptr to temp token block storage,
;rdx - **ptr to buff (if 0 rest are ignored), ecx - offset in buff, r8d - offset in file array,
;r9d - indirectional offset in buffer, r10 - cur file entry
push_name_to_unk:
    push rbp
    mov rbp, rsp
    sub rsp, 96
    mov [rbp-32], rdi
    mov [rbp-40], rsi
    mov [rbp-72], ecx
    mov [rbp-80], rdx
    mov [rbp-84], r8d
    mov [rbp-88], r9d
    mov [rbp-96], r10
    lea rdi, [UNKNOWN_NAME_SYM_REF_ARRAY] 
    mov esi, 1
    call entry_array_check_get
    test rax, rax
    jnz _add_entry_pnt_unk
    lea rdi, [UNKNOWN_NAME_SYM_REF_ARRAY] 
    mov esi, [rdi+12]
    shl esi, 1
    lea rdx, [rbp-24]
    call entry_array_copy_realloc
    test rax, rax
    jnz _success_realloc_pnt_unk
    exit_m -9
_success_realloc_pnt_unk:
    lea rdi, [UNKNOWN_NAME_SYM_REF_ARRAY]
    mov r8, [rdi]
    mov r9, [rbp-24]
    mov [rbp-48], r8
    mov [rbp-56], r9
    mov eax, [rdi+8]
    mov ebx, [rdi+16]
    mul ebx
    mov dword [rbp-60], 0
    mov [rbp-64], eax
    mov [rbp-68], ebx
    xor ecx, ecx
    mov esi, eax
__ht_reasign_push_unk_start:
    mov eax, [r8]
    test eax, eax; TODO: delete entry for not checking later?
    jz __ht_reasign_unk_next
    lea rdi, [NAME_SYM_HASH_TABLE]
    mov rsi, [r8+16]
    mov ecx, [r8+24]
    movzx edx, byte [r8+29]
    call hash_table_find_entry
    mov rdx, [rbp-56]
    mov ecx, [rbp-60]
    mov esi, [rbp-64]
    mov ebx, [rbp-68]
    lea r9, [rdx+rcx+16]
    mov [rax], r9
__ht_reasign_unk_next:
    add ecx, ebx
    cmp ecx, esi
    jae __dealloc_old_push_unk
    mov [rbp-60], ecx
    mov rdi, [rbp-48]
    lea r8, [rdi+rcx]
    jmp __ht_reasign_push_unk_start
__dealloc_old_push_unk:
    lea rdi, [UNKNOWN_NAME_SYM_REF_ARRAY]
    call entry_array_dealloc
    lea rdx, [UNKNOWN_NAME_SYM_REF_ARRAY]
    mov rdi, rdx
    lea rsi, [rbp-24]
    mov ecx, ENTRY_ARRAY_DATA_SIZE 
    rep movsb
    mov rdi, rdx
    mov esi, 1
    call entry_array_check_get
    test rax, rax
    jnz _add_entry_pnt_unk 
    exit_m -8
_add_entry_pnt_unk:
    mov [rbp-48], rax 
    add rax, 16
    mov rdi, rax
    mov rsi, [rbp-40]
    mov ecx, 16
    rep movsb
    lea rdi, [NAME_SYM_HASH_TABLE]
    mov rsi, [rbp-32]
    mov rdx, rax
    call hash_table_add_entry
    mov rax, [rbp-80]
    test rax, rax
    jz _end_push_name_to_unk
    lea rdi, [PATCH_LIST]
    call list_get_free
_node_fetch_succ_pnt_unk:
    mov edx, eax
    mov rbx, [UNKNOWN_NAME_SYM_REF_ARRAY]
    mov rcx, [rbp-48]
    mov [rcx], edx
    add rcx, 16
    sub rcx, rbx
    lea rdi, [PATCH_LIST]
    mov esi, edx
    call list_get_node_ptr
    mov rdi, [rbp-96]
    mov r10d, [rbp-88]
    mov r9d, [rbp-84]
    mov r8, [rbp-80]
    mov edx, [rbp-72]
    mov ebx, [rdi+44]
    mov esi, [rdi+16]
    mov [rax+4], r9d
    mov [rax+8], r8
    mov [rax+16], edx
    mov [rax+20], r10d
    mov [rax+24], ebx
    mov [rax+28], esi
    lea rax, [UNKNOWN_NAME_SYM_REF_ARRAY]
    mov ebx, ecx
_end_push_name_to_unk:
    add rsp, 96
    pop rbp
    ret

;rdi - ptr to symbol entry, rsi - **ptr to buff, edx - offset in buff
;ecx - offset in file array, r8d - indirectional offset, r9 - cur file entry
push_link_to_unk:
    push rbp
    mov rbp, rsp
    sub rsp, 36
    sub rdi, 16
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], edx
    mov [rbp-24], ecx
    mov [rbp-28], r8d
    mov [rbp-36], r9
    lea rdi, [PATCH_LIST]
    call list_get_free
    test eax, eax
    jnz _add_link_to_chain_unk
    exit_m -8
_add_link_to_chain_unk:
    mov esi, eax
    mov r9d, [rbp-28]
    mov ecx, [rbp-24]
    mov eax, [rbp-20]
    mov r8, [rbp-16]
    mov rdx, [rbp-36]
    mov edi, [rdx+44]
    mov r10d, [rdx+16]
    mov [rbx+4], ecx
    mov [rbx+8], r8
    mov [rbx+16], eax
    mov [rbx+20], r9d
    mov [rbx+24], edi
    mov [rbx+28], r10d
    mov rax, [rbp-8]
    mov edx, [rax]
    test edx, edx
    jz _insert_first_link_unk
    lea rdi, [PATCH_LIST]
    call list_insert_node
    test eax, eax
    jnz _finish_add_link_unk
    exit_m -7
_insert_first_link_unk:
    mov eax, esi
_finish_add_link_unk:
    mov rbx, [rbp-8]
    mov [rbx], eax
_end_push_link_to_unk:
    add rsp, 36
    pop rbp
    ret

;rdi - ptr to unk symbol, rsi - new buf to offset from, edx - new offset
patch_unk_ref:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], edx
    mov rbx, rdi
    sub rbx, NAME_SYM_REF_SERV_HS 
    mov esi, [rbx]
    mov [rbp-24], esi
_loop_patch_ur:
    test esi, esi
    jz _end_patch_unk_ref
    lea rdi, [PATCH_LIST]
    call list_get_node_ptr
    test rax, rax
    jnz _valid_list_entry_patch_ur
    exit_m -7
_valid_list_entry_patch_ur:
    mov r11, [rax+8]
    mov edx, [rax+16]
    mov ecx, [rax+20]
    mov r8, [r11]
    add r8, rdx
    test ecx, ecx
    jz _no_indrct_patch_ur
    mov r9, [r8]
    add r9, rcx
    mov r8, r9
_no_indrct_patch_ur:
    mov r10, [rbp-16]
    mov edx, [rbp-20]
    mov [r8], r10
    mov [r8+8], edx
    mov esi, [rbp-24]
    mov ecx, [rax]
    mov [rbp-24], ecx
    lea rdi, [PATCH_LIST]
    call list_free_node
    mov esi, [rbp-24]
    jnz _loop_patch_ur
_end_patch_unk_ref:
    mov rdi, [rbp-8]
    xor eax, eax
    mov [rdi-NAME_SYM_REF_SERV_HS], eax
    add rsp, 24
    pop rbp
    ret

; -24 temp entry_array, -32 ptr to old arr, -40 ptr to new arr, -44 curr offset,
; -48 - max offset, -52 req size
; edi - req size
; return rax - addr to mem
get_mem_def_name_buf:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-52], edi
    mov esi, edi 
    lea rdi, [NAME_SYM_REF_ARRAY]
    call entry_array_check_get
    test rax, rax
    jnz _end_get_mem_def_name_buf 
    lea rdi, [NAME_SYM_REF_ARRAY]
    mov esi, [rdi+12]
    shl esi, 1
    lea rdx, [rbp-24]
    call entry_array_copy_realloc
    test rax, rax
    jnz _success_realloc_pnt_def 
    exit_m -9
_success_realloc_pnt_def:
    lea rdi, [NAME_SYM_REF_ARRAY]
    mov r8, [rdi]
    mov r9, [rbp-24]
    mov [rbp-32], r8
    mov [rbp-40], r9
    mov eax, [rdi+8]
    mov ebx, [rdi+16]
    mul ebx
    mov dword [rbp-44], 0
    mov [rbp-48], eax
__ht_reasign_pnt_def:
    lea rdi, [NAME_SYM_HASH_TABLE]
    mov rsi, [r8+16]
    mov ecx, [r8+24]
    movzx edx, byte [r8+29]
    mov r8b, [r8+30]
    call hash_table_find_entry
    mov rdx, [rbp-40]
    mov ecx, [rbp-44]
    mov esi, [rbp-48]
    mov ebx, [rdx+rcx]
    lea r9, [rdx+rcx+NAME_SYM_REF_SERV_HS]
    mov [rax], r9
    add ecx, ebx
    cmp ecx, esi
    jae __dealloc_old_pnt_def
    mov [rbp-44], ecx
    mov rdi, [rbp-32]
    lea r8, [rdi+rcx]
    jmp __ht_reasign_pnt_def
__dealloc_old_pnt_def:
    lea rdi, [NAME_SYM_REF_ARRAY]
    call entry_array_dealloc
    lea rdx, [NAME_SYM_REF_ARRAY]
    mov rdi, rdx
    lea rsi, [rbp-24]
    mov ecx, ENTRY_ARRAY_DATA_SIZE 
    rep movsb
    mov rdi, rdx
    mov esi, [rbp-52]
    call entry_array_check_get
    test rax, rax
    jnz _end_get_mem_def_name_buf 
    exit_m -8
_end_get_mem_def_name_buf:
    mov rcx, [NAME_SYM_REF_ARRAY]
    mov rbx, rax
    sub rbx, rcx
    add rsp, 64
    pop rbp
    ret

;rdi - ht entry ptr, rsi - ptr to sym temp mem, edx - file entry offset
;return rax - addr to start of allco mem, ebx - offset from start of buff 
push_name_to_defined:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], edx
    mov edi, NAME_SYM_REF_HEADER_SIZE
    call get_mem_def_name_buf
    mov [rbp-32], rax
    mov [rbp-36], ebx
    add rax, 16
    mov rdi, rax
    mov rsi, [rbp-16]
    mov ecx, NAME_SYM_REF_SERV_HS
    rep movsb
    mov rbx, [rbp-8]
    mov rdi, [rbx]
    test rdi, rdi
    jz _add_entry_pnt_def
    lea rsi, [NAME_SYM_REF_ARRAY]
    mov cl, [rdi+15]
    mov [rax+15], cl
    and cl, SYM_REF_MASK_EXT
    cmp cl, SYM_REF_EXT_ENTRY
    jne _patch_pnt_def
    mov ebx, [rbp-36]
    mov [ENTRY_SYM_OFFSET], ebx
    mov [ENTRY_SYM_ARR_PTR], rsi
_patch_pnt_def:
    mov rcx, [rsi]
    mov rdx, rax
    sub rdx, rcx
    call patch_unk_ref
_add_entry_pnt_def:
    mov rax, [rbp-32]
    mov edi, [rbp-24]
    mov ecx, dword [LAST_LINE_NUM]
    mov [rax+4], edi
    mov [rax+12], ecx
    call get_file_entry_ptr_from_offset
    mov rbx, rax
    mov rdx, [rbp-32]
    mov ecx, [rbx+16]
    mov [rdx+8], ecx
    lea rdi, [NAME_SYM_HASH_TABLE]
    mov rsi, [rbp-8]
    add rdx, 16
    call hash_table_add_entry
    mov rax, [rbp-32]
    mov ebx, [rbp-36]
_end_push_name_to_defined:
    add rsp, 64
    pop rbp
    ret

;rdi - ptr to temp token mem, rsi - **ptr to buff, edx - offset in buff,
;ecx - offset in file array, r8d - indirectional offset
;return rax - **ptr to buff, ebx offset in buff
get_name_sym_ref_data:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], edx
    mov [rbp-24], ecx
    mov [rbp-36], r8d
    call get_cur_file_entry_ptr
    mov [rbp-44], rax
    mov rdi, [rbp-8]
    mov rsi, [rdi]
    movzx edx, byte [rdi+13]
    mov ecx, [rdi+8]
    lea rdi, [NAME_SYM_HASH_TABLE]
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jnz _check_exist_gnsrd
    mov rdi, rax
    mov rsi, [rbp-8]
    mov rdx, [rbp-16]
    mov ecx, [rbp-20]
    mov r8d, [rbp-24]
    mov r9d, [rbp-36]
    mov r10, [rbp-44]
    call push_name_to_unk
    jmp _end_get_name_sym_ref_data
_check_exist_gnsrd:
    movzx ecx, byte [rbx+14]
    test ecx, ecx
    jnz _def_sym_gnsrd
    mov [rbp-32], rbx
    mov rdi, rbx
    mov rsi, [rbp-16]
    mov edx, [rbp-20]
    mov ecx, [rbp-24]
    mov r8d, [rbp-36]
    mov r9, [rbp-44]
    call push_link_to_unk
    lea rax, [UNKNOWN_NAME_SYM_REF_ARRAY]
    mov rbx, [rbp-32]
    mov rcx, [rax]
    sub rbx, rcx
    jmp _end_get_name_sym_ref_data
_def_sym_gnsrd:
    lea rax, [NAME_SYM_REF_ARRAY]
    mov rcx, [rax]
    sub rbx, rcx
_end_get_name_sym_ref_data:
    add rsp, 64
    pop rbp
    ret

;do not modifies rcx-rdi reg
curr_token_buf_ptr:
    mov r9, [SEG_ENTRY_ARRAY]
    mov r8d, [CURR_SEG_OFFSET]
    add r9, r8
    mov rax, [r9]
    mov ebx, [r9+8]
    add rax, rbx
    ret

;do not modifies rbx-rdi reg
curr_token_buf_start_ptr:
    mov r9, [SEG_ENTRY_ARRAY]
    mov r8d, [CURR_SEG_OFFSET]
    add r9, r8
    mov rax, [r9]
    ret

;do not modifies rbx-rdi reg
curr_seg_ptr:
    mov rax, [SEG_ENTRY_ARRAY]
    mov r8d, [CURR_SEG_OFFSET]
    add rax, r8
    ret

;edi - offset of tbuf entry header
set_tbuf_body_size:
    call curr_token_buf_ptr
    sub ebx, edi
    sub rax, rbx
    mov [rax+12], ebx
    ret

; edi - offset of header of token group
inc_ins_argc:
    call curr_token_buf_start_ptr
    inc byte [rax+rdi+TOKEN_OFFSET_TO_INS_ARGC]; header + buf type + direct
    ret

; edi - offset of header of token group
get_ins_argc:
    call curr_token_buf_start_ptr
    movzx eax, byte [rax+rdi+TOKEN_OFFSET_TO_INS_ARGC]
    ret

;rdi - ptr to element buff with elements size of size 1, rsi - push from addr 
push_direct:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov [rbp-8], rsi
    mov esi, 15
    call entry_array_reserve_size
    mov byte [rax], TOKEN_BUF_DIRECT
    inc rax
    mov rdi, rax
    mov rsi, [rbp-8]
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
_end_push_direct:
    add rsp, 8
    pop rbp
    ret
   
;rdi - ptr to elemnt buf with elements of size 1, rsi - ptr to file entry, rdx - push from addr, rcx - read to addr
push_direct_and_read_next:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov [rbp-8], rsi
    mov [rbp-16], rdx
    mov [rbp-24], rcx
    mov esi, 15
    call entry_array_reserve_size
    mov byte [rax], TOKEN_BUF_DIRECT
    inc rax
    mov rdi, rax
    mov rsi, [rbp-16]
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    mov rdi, [rbp-8]
    mov rsi, [rbp-24]
    call next_token
    ;TODO: add check
_end_push_direct_and_read_next:
    add rsp, 24
    pop rbp
    ret

;rdi - ptr to elemnt buf with elements of size 1, rsi - ptr to temp token mem, edx - offset in file array
push_name_ptr_offset:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov [rbp-8], rsi
    mov [rbp-16], edx
    mov esi, 13; TOKEN_BUF_TYPE + buff ptr + offset
    call entry_array_reserve_size
    mov byte [rax], TOKEN_BUF_PTR_OFFSET
    inc rax
    inc ebx
    mov [rbp-24], rax
    mov rdi, [rbp-8]
    lea rsi, [SEG_ENTRY_ARRAY]
    mov edx, dword [CURR_SEG_OFFSET] 
    mov ecx, [rbp-16]
    mov r8d, ebx
    call get_name_sym_ref_data
    mov rdx, [rbp-24]
    mov [rdx], rax
    mov [rdx+8], ebx
_end_push_name_ptr_offset:
    add rsp, 24
    pop rbp
    ret

; edi - offset to name entry, esi - type
set_name_token_type:
    mov rax, [NAME_SYM_REF_ARRAY]
    add rax, rdi
    mov [rax+30], sil 
    ret

; rdi - ptr to file entry, rsi - ptr to token temp mem
convert_digit_to_neg:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov [rbp-8], rsi
    call next_token
    test rax, rax
    jz _err_convert_dtn
    test ebx, ebx
    jnz _err_convert_dtn
    mov rsi, [rbp-8]
    movzx ecx, byte [rsi+12]
    cmp ecx, TOKEN_TYPE_DIGIT
    jne _err_convert_dtn
    mov rbx, [rsi]
    neg qword [rsi]
    mov rdi, rbx
    dec rbx
    and rbx, rdi
    test rbx, rbx
    jz _skip_new_len_cdtn
    movzx edx, byte [rsi+13]
    lzcnt edx, edx
    mov ecx, 32
    sub ecx, edx
    mov eax, 1
    shl eax, cl
    mov [rsi+13], al
_skip_new_len_cdtn:
    mov eax, 1
    jmp _end_convert_digit_to_neg
_err_convert_dtn:
    xor eax, eax
_end_convert_digit_to_neg:
    add rsp, 8
    pop rbp
    ret

; edi - curr seg offset
set_last_name_data_h_info:
    push rdi
    mov edi, NAME_DATA_BODY_SIZE
    call get_mem_def_name_buf
    push rax
    call curr_token_buf_ptr
    pop rdx
    pop rcx
    mov [rdx], ecx 
    mov [rdx+4], ebx 
    ret

; rdi - ptr to file entry, rsi - ptr to space for token
get_next_token_skip_new_line:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rdi
    mov [rbp-16], rsi
_loop_gntsnl:
    call next_token
    mov rsi, [rbp-16]
    mov rdi, [rbp-8]
    mov al, [rsi+12]
    cmp al, TOKEN_TYPE_AUX
    jne _end_get_next_token_skip_new_line
    mov ecx, [rsi+8] 
    cmp ecx, AUX_NEW_LINE 
    je _loop_gntsnl
_end_get_next_token_skip_new_line:
    add rsp, 16
    pop rbp
    ret

; NOTE: hash table main block gonna start from offset 0
; edi - count of entries; must be 1 byte size max
; return rax - ptr to ht main block, rbx - start
init_hash_table_in_temp_p_arr:
    push rbp
    mov rbp, rsp
    sub rsp, 20
    mov [rbp-20], edi
    mov r8, [TEMP_COMMON_ARR]
    mov rdi, r8
    mov ecx, HT_MAIN_BLOCK_SIZE
    xor eax, eax
    rep stosb
    mov byte [r8+17], 1
    mov [rbp-8], r8
    lea rdi, [r8+HT_MAIN_BLOCK_SIZE]
    mov esi, 8
    call align_to_pow2
    mov [rbp-16], rax
    mov r8, rax
    mov rdi, rax
    mov ecx, [rbp-20]
    shl ecx, 3
    xor rax, rax
    rep stosb
    mov rbx, rdi
    mov rdi, [rbp-8]
    sub rbx, rdi
    mov dword [TEMP_COMMON_ARR+8], ebx
    mov rdx, r8
    mov esi, [rbp-20]; must be 1 byte size max
    call hash_table_init
    mov rax, [rbp-8]
    mov rbx, [rbp-16]
_end_init_hash_table_in_temp_p_arr:
    add rsp, 20
    pop rbp
    ret

; rbx - ptr to name entry
name_entry_print_info:
    push rbp
    mov rbp, rsp
    mov edi, [rbx+4]
    mov r8d, [rbx+8]
    mov ecx, [rbx+12]
    xor r9, r9
    xor rdx, rdx
    xor rsi, rsi
    call err_print
    call print_new_line
    pop rbp
    ret

;-16 token 0, -32 token 1, -40 passed rdi, -48 ptr to token in entry_array,
;-52 passed esi, -56(4) seg mask val /, -64 start offset of curr render entry,
;-68 temp var, -72 temp var, -76 offset to start of token buf entry header,
;-84 temp token buf ptr / temp token buf offset, -92 - -124 temp var,
; rdi - ptr to file entry, esi - offset of curr file entry
start_parser:
    push rbp
    mov rbp, rsp
    sub rsp, 256
    mov [rbp-40], rdi
    mov [rbp-52], esi
    mov [CURR_FILE_ENTRY_OFFSET], esi
_new_entry_start_ps:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
__new_entry_start_read_ps:
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_INS
    je _begin_ins_sp
    cmp eax, TOKEN_TYPE_NAME
    je _begin_name_sp
    cmp eax, TOKEN_TYPE_KEYWORD
    je _begin_kw_sp 
    cmp eax, TOKEN_TYPE_EOF
    jz _end_start_parser
    jmp _new_entry_start_ps;TODO: remove?

_begin_ins_sp:
    call curr_seg_ptr
    mov rdi, rax
    mov esi, [rbp-52]
    call push_token_entry_header
    mov [rbp-76], ebx
    mov edx, [rbp-8]
    and edx, PREF_INS_TYPE_MASK
    jz __ins_skip_prefix
__ins_pref_check_sp:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_INS
    jne _err_invalid_expr
    mov ecx, [rbp-24]
    and ecx, INS_CAN_HAS_PREFIX_MASK
    test ecx, ecx
    jz _err_invalid_expr
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-32]
    call push_direct
    call curr_seg_ptr
    mov rdi, rax
    mov esi, 1
    call entry_array_reserve_size
    mov byte [rax], 0
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
    lea rsi, [rbp-32]
    lea rdi, [rbp-16]
    mov ecx, 16
    rep movsb
    jmp __ins_prefix_end
__ins_skip_prefix:
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
    call curr_seg_ptr
    mov rdi, rax
    mov esi, 1
    call entry_array_reserve_size
    mov byte [rax], 0
__ins_prefix_end:
    mov ebx, [rbp-8]
    and ebx, INS_ZERO_ARG_MASK
    jnz __ins_set_token_group
__get_ins_arg:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_REG
    jne __ins_kw_check_sp
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-32]
    call push_direct
    mov edi, [rbp-76]
    call inc_ins_argc
    jmp __ins_next_arg_check
__ins_kw_check_sp:
    cmp eax, TOKEN_TYPE_KEYWORD
    jne __ins_aux_check_sp
    mov ebx, [rbp-24]
    and ebx, ADDR_QUL_TYPE_MASK 
    cmp ebx, ADDR_QUL_TYPE_MASK
    jne _err_invalid_expr
    call curr_seg_ptr
    mov rdi, rax
    mov esi, 18; TOKEN_BUF_TYPE + count + size + _TYPE + token body
    call entry_array_reserve_size
    mov byte [rax], TOKEN_BUF_ADDR 
    mov byte [rax+1], 0
    mov byte [rax+2], 15
    ;inc ebx
    add rax, 3
    mov [rbp-84], ebx
    mov byte [rax], TOKEN_BUF_DIRECT
    inc rax
    mov rdi, rax
    lea rsi, [rbp-32]
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_AUX
    jne _err_invalid_expr
    mov ecx, [rbp-8]
    cmp ecx, AUX_LBRACKET
    jne _err_invalid_expr
    jmp __ins_addr_tokens
__ins_aux_check_sp:
    cmp eax, TOKEN_TYPE_AUX
    jne __ins_name_check_sp
    mov ecx, [rbp-24]
    cmp ecx, AUX_LBRACKET
    jne ___ins_aux_check_sub_sp
    call curr_seg_ptr
    mov rdi, rax
    mov esi, 3
    call entry_array_reserve_size
    mov byte [rax], TOKEN_BUF_ADDR
    mov byte [rax+1], 0
    ;inc ebx
    mov [rbp-84], ebx
    jmp __ins_addr_tokens
___ins_aux_check_sub_sp:
    cmp ecx, AUX_SUB
    jne _err_invalid_expr
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call convert_digit_to_neg
    test rax, rax
    jz _err_invalid_expr
    jmp ___ins_digit_set_sp
__ins_name_check_sp:
    cmp eax, TOKEN_TYPE_NAME
    jne __ins_digit_check_sp
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-32]
    mov edx, [rbp-52]
    call push_name_ptr_offset
    mov edi, [rbp-76]
    call inc_ins_argc
    jmp __ins_next_arg_check
__ins_digit_check_sp:
    cmp eax, TOKEN_TYPE_DIGIT
    jne __ins_str_check_sp
___ins_digit_set_sp:
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-32]
    mov edx, [rbp-52]
    call push_direct
    mov edi, [rbp-76]
    call inc_ins_argc
    jmp __ins_next_arg_check
__ins_str_check_sp:
    cmp eax, TOKEN_TYPE_STR
    jne _err_invalid_expr
    mov ecx, [rbp-24]
    cmp ecx, 8
    jg _err_str_reg_val
    mov rsi, [rbp-32]
    xor rax, rax
    mov [rbp-32], rax
    lea rdi, [rbp-32]
    rep movsb
    mov byte [rbp-20], TOKEN_TYPE_DIGIT
    mov rax, [rbp-32]
    lzcnt rbx, rax
    mov rdx, 64
    sub rdx, rbx
    mov [rbp-19], dl
    jmp ___ins_digit_set_sp
__ins_addr_tokens:
    xor edx, edx
    mov byte [rbp-66], dl
    mov byte [rbp-67], dl
    mov eax, 237
    mov ebx, TOKEN_KIND_SIZE
    div ebx
    mov [rbp-72], rax
    mov byte [rbp-66], al
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_REG
    jne ___ins_addr_name_test
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
    dec byte [rbp-66]
    inc byte [rbp-67]
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    mov al, [rbp-4]
    cmp al, TOKEN_TYPE_AUX
    jne _err_invalid_addr_expr
    mov ebx, [rbp-8]
    cmp ebx, AUX_RBRACKET
    je __ins_addr_end
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
    mov ebx, [rbp-8]
    cmp ebx, AUX_SUB
    je ___ins_addr_rs
    cmp ebx, AUX_ADD
    jne _err_invalid_addr_expr
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    mov al, [rbp-4]
    cmp al, TOKEN_TYPE_NAME
    je ___ins_addr_offset_n
    cmp al, TOKEN_TYPE_DIGIT
    je ___ins_addr_offset_d 
    cmp al, TOKEN_TYPE_REG
    jne _err_invalid_addr_expr
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
    dec byte [rbp-66]
    inc byte [rbp-67]
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    mov al, [rbp-4]
    cmp al, TOKEN_TYPE_AUX
    jne _err_invalid_addr_expr
    mov ebx, [rbp-8]
    cmp ebx, AUX_RBRACKET
    je __ins_addr_end
    cmp ebx, AUX_MUL
    je ___ins_addr_rr_s_check
    cmp ebx, AUX_ADD
    je ___ins_addr_rr_o
    cmp ebx, AUX_SUB
    je ___ins_addr_rr_o
    jne _err_invalid_addr_expr
___ins_addr_rr_s_check:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    mov al, [rbp-4]
    cmp al, TOKEN_TYPE_DIGIT
    jne ___ins_addr_check_rr_sn
    mov rcx, [rbp-16]
    cmp rcx, 8
    ja _err_invalid_addr_expr
    mov edx, ecx
    dec ecx
    and edx, ecx
    test edx, edx
    jnz _err_invalid_addr_expr
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
    dec byte [rbp-66]
    jmp ___ins_addr_rr_s_end
___ins_addr_check_rr_sn:
    cmp al, TOKEN_TYPE_NAME
    jne _err_invalid_addr_expr
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    mov edx, [rbp-52]
    call push_name_ptr_offset
    dec byte [rbp-66]
___ins_addr_rr_s_end:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    mov ebx, [rbp-8]
    cmp ebx, AUX_RBRACKET
    je __ins_addr_end
    cmp ebx, AUX_ADD
    je ___ins_addr_rr_o
    cmp ebx, AUX_SUB
    je ___ins_addr_rr_o
    jmp _err_invalid_addr_expr 
___ins_addr_rr_o:
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
___ins_addr_rs:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    mov al, [rbp-4]
    cmp al, TOKEN_TYPE_NAME
    je ___ins_addr_offset_n
    cmp al, TOKEN_TYPE_DIGIT
    je ___ins_addr_offset_d 
    jne _err_invalid_addr_expr
___ins_addr_name_test:
    cmp eax, TOKEN_TYPE_NAME
    jne _err_invalid_addr_expr
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    mov edx, [rbp-52]
    call push_name_ptr_offset
    dec byte [rbp-66]
    inc byte [rbp-67]
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    mov al, [rbp-4]
    cmp al, TOKEN_TYPE_AUX
    jne _err_invalid_addr_expr
    mov ebx, [rbp-8]
    cmp ebx, AUX_RBRACKET
    je __ins_addr_end
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
    mov ebx, [rbp-8]
    cmp ebx, AUX_SUB
    je ___ins_addr_name_o_check
    cmp ebx, AUX_ADD
    jne _err_invalid_addr_expr
___ins_addr_name_o_check:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    mov al, byte [rbp-4]
    cmp al, TOKEN_TYPE_DIGIT
    je ___ins_addr_offset_d
    cmp al, TOKEN_TYPE_NAME
    jne _err_invalid_addr_expr
___ins_addr_offset_n:
    dec byte [rbp-66]
    inc byte [rbp-67]
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    mov edx, [rbp-52]
    call push_name_ptr_offset
    xor rax, rax
    mov [rbp-16], rax
    mov [rbp-8], eax
    mov byte [rbp-4], TOKEN_TYPE_DIGIT
    mov byte [rbp-3], 0
    jmp ___ins_addr_loop_mul_d
___ins_addr_offset_d:
    dec byte [rbp-66]
    inc byte [rbp-67]
___ins_addr_loop_mul_d:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    mov al, byte [rbp-20]
    cmp al, TOKEN_TYPE_AUX
    jne _err_invalid_addr_expr
    mov ebx, [rbp-24]
    cmp ebx, AUX_RBRACKET
    je ___ins_addr_end_mul_d
    mov cl, [rbp-66]
    test cl, cl
    jz _err_invalid_addr_expr
    mov [rbp-72], ebx
    cmp ebx, AUX_ADD
    je ___ins_addr_mul_d_exp_d 
    cmp ebx, AUX_SUB
    jne  _err_invalid_addr_expr 
___ins_addr_mul_d_exp_d:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    mov al, byte [rbp-20]
    cmp al, TOKEN_TYPE_DIGIT
    jne _err_invalid_addr_expr
    mov rbx, [rbp-32]
    mov ecx, [rbp-72]
    cmp ecx, AUX_SUB
    jne ___ins_addr_mul_d_add
    neg rbx
___ins_addr_mul_d_add:
    add [rbp-16], rbx
    dec byte [rbp-66]
    jmp ___ins_addr_loop_mul_d
___ins_addr_end_mul_d:
    ;TODO: check overflow?
    mov eax, [rbp-16]; bound to 32bits value
    test eax, eax
    jz __ins_addr_end
    mov [rbp-16], eax
    lzcnt ebx, eax
    mov edx, 32
    sub edx, ebx
    mov [rbp-3], dl
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
__ins_addr_end:
    call curr_token_buf_ptr
    mov ecx, [rbp-84]
    sub ebx, ecx
    sub rax, rbx
    mov r8b, [rbp-67]
    mov [rax+1], r8b
    mov [rax+2], bl
    mov edi, [rbp-76]
    call inc_ins_argc
    jmp __ins_next_arg_check
__ins_set_token_group:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_AUX
    jne ___ins_next_arg_eof
    mov ecx, [rbp-24]
    cmp ecx, AUX_NEW_LINE
    jne _err_invalid_expr
    jmp ___ins_next_arg_set_body_size 
__ins_next_arg_check:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_AUX
    jne ___ins_next_arg_eof
    mov ecx, [rbp-24]
    cmp ecx, AUX_NEW_LINE
    jne ___ins_next_arg_comma
___ins_next_arg_set_body_size:
    mov edi, [rbp-76]
    call set_tbuf_body_size
    jmp _new_entry_start_ps
___ins_next_arg_comma:
    cmp ecx, AUX_COMMA
    je __get_ins_arg
    jmp _err_invalid_expr
___ins_next_arg_eof:
    cmp eax, TOKEN_TYPE_EOF
    jne _err_invalid_expr
    mov edi, [rbp-76]
    call set_tbuf_body_size
    jmp _end_start_parser

_begin_name_sp:
    lea rdi, [NAME_SYM_HASH_TABLE]
    mov rsi, [rbp-16]
    movzx edx, byte [rbp-3]
    mov ecx, [rbp-8]
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jz __name_sp_check_next
    mov dl, SYM_REF_MASK_REF
    and dl, [rbx+15]
    cmp dl, SYM_REF_MOD_EXTRN
    je _err_def_ext_before
    movzx ecx, byte [rbx+14]
    test ecx, ecx
    jz __name_sp_check_next 
    cmp ecx, TOKEN_NAME_MACRO
    jne _err_defined_symbol
    sub rbx, NAME_SYM_REF_SERV_HS
    mov [rbp-92], rbx
    jmp __name_sp_macro
__name_sp_check_next:
    mov [rbp-92], rax
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    mov rax, [rbp-92]
    movzx ebx, byte [rbp-20]
    cmp ebx, TOKEN_TYPE_KEYWORD
    je __name_sp_set_def
    cmp ebx, TOKEN_TYPE_AUX
    jne _err_invalid_expr
__name_sp_set_def:
    mov rdi, rax
    lea rsi, [rbp-16]
    mov edx, [rbp-52]
    call push_name_to_defined
    mov [rbp-84], rax
    mov [rbp-72], ebx
    mov ecx, [rbp-24]
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_KEYWORD
    je __name_sp_kw
    cmp eax, TOKEN_TYPE_AUX
    je __name_sp_aux
__name_sp_kw:
    mov ebx, ecx
    mov edx, DATA_QUL_TYPE_MASK
    and ebx, edx
    cmp ebx, edx
    je ___name_data_def
    cmp ecx, KW_EQU
    je ___name_const_def
    jmp _err_invalid_expr
___name_data_def:
    mov r9d, dword [CURR_SEG_OFFSET]
    test r9d, r9d
    jz _err_segment_not_set
    mov [rbp-92], r9d
    mov r8, [rbp-84]
    mov dword [r8], NAME_DATA_ENTRY_SIZE
    mov byte [r8+30], TOKEN_NAME_DATA
    mov edi, r9d
    call set_last_name_data_h_info
___name_data_def_kw_new_rip:
    call curr_seg_ptr
    mov rdi, rax
    mov esi, [rbp-52]
    call push_token_entry_header
    ;mov r8, [rbp-84]
    ;mov [r8+8], ebx
    mov [rbp-76], ebx
___name_data_qul_read:
    mov dword [rbp-96], 0
    call curr_seg_ptr
    mov rdi, rax
    mov esi, 16
    call entry_array_reserve_size
    mov byte [rax], TOKEN_BUF_DIRECT
    inc rax
    mov rdi, rax
    lea rsi, [rbp-32]
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    add rax, 14
    mov [rbp-92], rax
    mov edx, [rbp-24]
    mov eax, 1 ; KW_DB by default
    mov ecx, 2
    mov esi, 4
    mov ebx, 8
    cmp edx, KW_DW
    cmove eax, ecx
    cmp edx, KW_DD
    cmove eax, esi
    cmp edx, KW_DQ
    cmove eax, ebx
    mov byte [rbp-68], al
    mov rdx, [rbp-92]
    mov [rdx], al
___name_data_read_val:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_STR
    jne ___name_data_read_digit_sub_check
    movzx ebx, byte [rbp-68]
    cmp ebx, 1
    ja _err_out_of_range_value
    inc dword [rbp-96]
    jmp ___name_data_read_next
___name_data_read_digit_sub_check:
    cmp eax, TOKEN_TYPE_AUX
    jne ___name_data_read_digit_check 
    mov ecx, [rbp-8]
    cmp ecx, AUX_SUB
    jne _err_invalid_expr
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call convert_digit_to_neg
    test rax, rax
    jz _err_invalid_expr 
    jmp ___name_data_read_digit_overflow_check 
___name_data_read_digit_check:
    cmp eax, TOKEN_TYPE_DIGIT
    je ___name_data_read_digit_overflow_check
    cmp eax, TOKEN_TYPE_NAME
    jne _err_invalid_expr
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    mov edx, [rbp-52]
    call push_name_ptr_offset
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    jmp ___name_data_check_next_sym
___name_data_read_digit_overflow_check:
    movzx ebx, byte [rbp-68]
    shl ebx, 3
    movzx esi, byte [rbp-3] 
    cmp esi, ebx
    ja _err_out_of_range_value
    inc dword [rbp-96]
___name_data_read_next:
    call curr_seg_ptr
    mov rdi, rax
    mov rsi, [rbp-40]
    lea rdx, [rbp-16]
    mov rcx, rdx
    call push_direct_and_read_next
___name_data_check_next_sym:
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_EOF
    je ___name_data_read_finish 
    cmp eax, TOKEN_TYPE_KEYWORD
    jne __name_data_check_next_sym_aux
    mov ebx, [rbp-8]
    cmp ebx, KW_DUP
    jne _err_invalid_expr
    mov ecx, [rbp-96]
    test ecx, ecx
    jz _err_invalid_expr
    xor ecx, ecx
    mov [rbp-96], ecx
    call curr_seg_ptr
    mov rdi, rax
    mov rsi, [rbp-40]
    lea rdx, [rbp-16]
    mov rcx, rdx
    call push_direct_and_read_next
    mov al, [rbp-4]
    cmp al, TOKEN_TYPE_DIGIT
    je ___name_data_read_next
__name_data_check_next_sym_aux:
    cmp eax, TOKEN_TYPE_AUX
    jne _err_invalid_expr
    mov ebx, [rbp-8]
    cmp ebx, AUX_COMMA
    je ___name_data_read_val
    cmp ebx, AUX_NEW_LINE
    jne _err_invalid_expr
    call curr_token_buf_start_ptr
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test eax, eax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_KEYWORD
    jne ___name_data_read_finish
    mov ecx, [rbp-8]
    mov ebx, ecx
    mov edx, DATA_QUL_TYPE_MASK
    and ebx, edx
    cmp ebx, edx
    jne ___name_data_read_finish
    lea rdi, [rbp-32]
    lea rsi, [rbp-16]
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    jmp ___name_data_qul_read
___name_data_read_finish:
    mov edi, [rbp-76]
    call set_tbuf_body_size
    jmp __new_entry_start_read_ps
___name_const_def:
    mov r8, [rbp-84]
    mov dword [r8], NAME_CONST_ENTRY_SIZE
    mov byte [r8+30], TOKEN_NAME_CONST
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_DIGIT
    je ___name_const_set_token
    cmp eax, TOKEN_TYPE_STR
    je ___name_const_set_token
    cmp eax, TOKEN_TYPE_AUX
    jne _err_invalid_const_value
    mov ebx, [rbp-8]
    cmp ebx, AUX_NEW_LINE
    je ___name_const_set_empty
    cmp ebx, AUX_SUB
    jne _err_invalid_const_value
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call convert_digit_to_neg
    test rax, rax
    jz _err_invalid_expr
___name_const_set_token:
    mov edi, TOKEN_KIND_SIZE
    call get_mem_def_name_buf
    mov rdi, rax
    lea rsi, [rbp-16]
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    mov edi, [rbp-72]
    mov esi, TOKEN_NAME_CONST
    call set_name_token_type
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_EOF
    je _end_start_parser
    cmp eax, TOKEN_TYPE_AUX
    jne _err_invalid_const_value
    mov ebx, [rbp-8]
    cmp ebx, AUX_NEW_LINE
    je _new_entry_start_ps
    jmp _err_invalid_const_value
___name_const_set_empty:
    mov edi, TOKEN_KIND_SIZE
    call get_mem_def_name_buf
    mov byte [rax+13], TOKEN_TYPE_NONE
    mov edi, [rbp-72]
    mov esi, TOKEN_NAME_CONST
    call set_name_token_type
    jmp _new_entry_start_ps
__name_sp_aux:
    cmp ecx, AUX_COLON
    jne _err_invalid_expr
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    mov ecx, [rbp-24]
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_EOF
    je _end_start_parser
    cmp eax, TOKEN_TYPE_AUX
    jne _err_invalid_expr
    cmp ecx, AUX_NEW_LINE
    jne _err_invalid_expr
    mov r8, [rbp-84]
    mov dword [r8], NAME_DATA_ENTRY_SIZE
    mov byte [r8+30], TOKEN_NAME_JMP
    mov edi, dword [CURR_SEG_OFFSET]
    call set_last_name_data_h_info
    jmp _new_entry_start_ps
__name_sp_macro:
    mov dword [rbp-108], 0 
    mov rdi, [rbp-40]
    mov rax, [rdi+16]
    mov ecx, [rdi+44]
    mov [rbp-120], eax
    mov [rbp-124], ecx
    lea rsi, [rbp-16]
    call next_token
    mov ecx, [rbp-8]
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_DIGIT
    je ___name_sp_macro_digit_convert
    cmp eax, TOKEN_TYPE_AUX
    jne ___name_sp_macro_skip_comma
    cmp ecx, AUX_COMMA
    je _err_invalid_expr
    cmp ecx, AUX_NEW_LINE 
    je ___name_sp_macro_arg_end
    cmp ecx, AUX_SUB
    jne _err_invalid_expr
    mov dword [rbp-108], 1 
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_DIGIT
    jne _err_invalid_expr
___name_sp_macro_digit_convert:
    mov rdi, [rbp-40]
    mov rdx, [rdi]
    mov ebx, [rdi+16]
    mov ecx, [rbp-8]
    add ecx, [rbp-108]
    mov byte [rbp-3], cl
    sub ebx, ecx 
    add rdx, rbx
    mov [rbp-16], rdx
___name_sp_macro_skip_comma: 
    mov rdi, TEMP_COMMON_ARR
    mov esi, TOKEN_KIND_SIZE
    call entry_array_reserve_size
    mov rdx, rax
    mov rdi, rax
    lea rsi, [rbp-16]
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_EOF
    je ___name_sp_macro_arg_end 
    cmp eax, TOKEN_TYPE_AUX
    jne _err_invalid_expr
    mov ecx, [rbp-24]
    cmp ecx, AUX_COMMA
    je __name_sp_macro
    cmp ecx, AUX_NEW_LINE
    jne _err_invalid_expr
___name_sp_macro_arg_end:
    mov ebx, dword [TEMP_COMMON_ARR+8]
    mov [rbp-68], ebx
    mov rdx, [FILES_ARRAY]
    mov r8, [rbp-92]
    lea r9, [r8+NAME_SYM_REF_HEADER_SIZE+8]
    mov [rbp-84], r9
    mov eax, [r8]
    mov ecx, [r8+4]
    lea r10, [r8+rax]
    lea r11, [rdx+rcx]
    mov [rbp-100], r10
    mov [rbp-108], r11
___name_sp_macro_set_buf:
    cmp r9, r10
    jae ___name_sp_macro_end
    lea rdi, [TEMP_COMMON_ARR]
    mov esi, [r9+4]
    movzx eax, byte [r9+8]
    cmp eax, MACRO_EMPTY_ARG_FLAG
    je ___name_sp_macro_skip_arg_size
    mov ecx, TOKEN_KIND_SIZE
    mul ecx
    mov rbx, [TEMP_COMMON_ARR]
    add rbx, rax
    mov [rbp-116], rbx
    movzx ecx, byte [rbx+13]
    add esi, ecx
___name_sp_macro_skip_arg_size:
    call entry_array_reserve_size
    mov rdi, rax
    mov r9, [rbp-84]
    mov ebx, [r9]
    mov ecx, [r9+4]
    mov r11, [rbp-108]
    mov rsi, [r11]
    add rsi, rbx
    rep movsb 
    movzx eax, byte [r9+8]
    cmp eax, MACRO_EMPTY_ARG_FLAG
    je ___name_sp_macro_end
    mov rbx, [rbp-116]
    mov rsi, [rbx]
    movzx ecx, byte [rbx+13]
    rep movsb
    add r9, MACRO_COPY_ENTRY_SIZE 
    mov [rbp-84], r9
    mov r10, [rbp-100]
    jmp ___name_sp_macro_set_buf
___name_sp_macro_end:
    mov rbx, qword [TEMP_COMMON_ARR]
    mov edi, dword [TEMP_COMMON_ARR+8]
    mov byte [rbx+rdi], 0
    inc edi
    mov dword [TEMP_COMMON_ARR+8], edi
    mov edx, [rbp-68]
    sub edi, edx
    call alloc_virt_file
    mov [rbp-72], ebx
    mov r8, [rbp-92]
    mov r9d, [rbp-52]
    mov r10d, [r8+32]
    mov r11d, [r8+36]
    mov r12d, [rbp-120]
    mov r13d, [rbp-124]
    mov r14d, [r8+4]
    mov [rax+24], r9d
    mov [rax+28], r12d
    mov [rax+32], r13d
    mov [rax+48], r14d
    mov [rax+52], r10d
    mov [rax+56], r11d
    mov rbx, qword [TEMP_COMMON_ARR]
    mov edx, [rbp-68]
    lea rsi, [rbx+rdx]
    mov rdi, [rax]
    mov rcx, [rax+8]
    rep movsb
    mov dword [TEMP_COMMON_ARR+8], 0
    mov rdi, rax
    mov rsi, [rbp-72]
    call start_parser
    mov edi, [rbp-52]
    mov [CURR_FILE_ENTRY_OFFSET], edi
    call get_file_entry_ptr_from_offset
    mov [rbp-40], rax
    jmp _new_entry_start_ps

_begin_kw_sp:
    ;TODO: add more
    mov eax, [rbp-8]
    cmp eax, KW_SEGMT
    je __kw_segm_sp
    cmp eax, KW_SECT
    je __kw_sect_sp
    cmp eax, KW_MACR
    je __kw_macr
    cmp eax, KW_INCL
    je __kw_include
    cmp eax, KW_EXTRN
    je __kw_name_mod
    cmp eax, KW_PUBLIC
    je __kw_name_mod
    cmp eax, KW_ENTRY
    je __kw_entry
    mov ebx, eax
    mov edx, DATA_QUL_TYPE_MASK
    and ebx, edx
    cmp ebx, edx
    jne _err_invalid_expr
    lea rsi, [rbp-16]
    lea rdi, [rbp-32]
    mov ecx, TOKEN_KIND_SIZE
    rep movsb
    jmp ___name_data_def_kw_new_rip
__kw_segm_sp:
    mov bl, [BUILD_TYPE]
    cmp bl, BUILD_TYPE_ELF_EXE
    jne _err_seg_in_non_exe
    ;TODO: catch wrong combination?
    jmp ___kw_sec_segm_qul_start
__kw_sect_sp:
    mov bl, [BUILD_TYPE]
    cmp bl, BUILD_TYPE_ELF_OBJ
    jne _err_sec_in_non_obj
___kw_sec_segm_qul_start:
    xor eax, eax
    mov [rbp-56], eax
___kw_sec_segm_loop_sp:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_AUX
    jne ___kw_sec_segm_next_check
    mov ebx, [rbp-24]
    cmp ebx, AUX_NEW_LINE
    je ___kw_sec_seg_loop_end
    jmp _err_invalid_expr
___kw_sec_segm_next_check:
    cmp eax, TOKEN_TYPE_KEYWORD
    jne _err_invalid_expr
    mov ebx, [rbp-24]
    mov ecx, ebx
    and ebx, SEC_SEG_TYPE_MOD_MASK
    cmp ebx, SEC_SEG_TYPE_MOD_MASK
    jne _err_invalid_expr
    and ecx, SEC_SEG_VAL_MOD_MASK
    mov edx, [rbp-56]
    mov eax, edx
    and eax, ecx
    test eax, eax
    jnz _err_seg_inv_def
    or edx, ecx
    mov [rbp-56], edx
    jmp ___kw_sec_segm_loop_sp
___kw_sec_seg_loop_end:
    mov eax, [rbp-56]
    test eax, eax
    jz _err_seg_inv_def
    mov ebx, eax
    mov ecx, SEG_ENTRY_SIZE
    mul ecx
    mov dword [CURR_SEG_OFFSET], eax
    mov rdi, qword [SEG_ENTRY_ARRAY]
    add rdi, rax
    mov dl, [BUILD_TYPE]
    cmp dl, BUILD_TYPE_ELF_EXE
    jne __assign_sec_collate_sp
__assign_segment_collate_sp:
    ;TODO: add file id start and end
    mov [rdi+48], bx
    jmp _new_entry_start_ps
__assign_sec_collate_sp:
    mov rax, [rdi+40]
    test rax, rax
    jz _err_invalid_sec_modifier
    jmp _new_entry_start_ps
__kw_include:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_STR
    jne _err_invalid_expr
    mov rdi, [rbp-16]
    mov esi, [rbp-8]
    mov edx, [rbp-52]
    call load_file_by_path
    mov rdi, rax
    mov rsi, rbx
    call start_parser
    mov edi, [rbp-52]
    mov [CURR_FILE_ENTRY_OFFSET], edi
    call get_file_entry_ptr_from_offset
    mov [rbp-40], rax
    jmp _new_entry_start_ps
__kw_macr:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_NAME
    jne _err_invalid_expr
    lea rdi, [NAME_SYM_HASH_TABLE]
    mov rsi, [rbp-16]
    movzx edx, byte [rbp-3]
    mov ecx, [rbp-8]
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jnz _err_defined_symbol
    mov rdi, rax
    lea rsi, [rbp-16]
    mov edx, [rbp-52]
    call push_name_to_defined
    mov [rbp-84], rax
    mov [rbp-72], ebx
    mov byte [rax+30], TOKEN_NAME_MACRO
    mov edi, 8
    call get_mem_def_name_buf
    mov edi, 32
    call init_hash_table_in_temp_p_arr
    mov [rbp-92], rax
    mov [rbp-100], rbx
__kw_macro_arg_loop:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_NAME
    jne __kw_macro_arg_loop_ck_n
    mov rdi, [rbp-92]
    mov rsi, [rbp-32]
    movzx edx, byte [rbp-19]
    mov ecx, [rbp-24]
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jnz _err_macro_arg_rep
    mov [rbp-108], rax
    lea rdi, [TEMP_COMMON_ARR]
    mov esi, 15
    call entry_array_reserve_size
    mov rdx, rax
    mov rdi, rax
    lea rsi, [rbp-32]
    mov ecx, 14 
    rep movsb
    mov rdi, [rbp-92]
    mov al, [rdi+8]
    mov [rdx+14], al
    mov rsi, [rbp-108]
    call hash_table_add_entry 
    test rax, rax
    jz _err_macro_to_many_arg
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
__kw_macro_arg_loop_ck_n:
    cmp eax, TOKEN_TYPE_AUX
    jne ___ins_next_arg_eof
    mov ecx, [rbp-24]
    cmp ecx, AUX_COMMA
    je __kw_macro_arg_loop
    cmp ecx, AUX_NEW_LINE
    je __kw_macro_expect_lbrace
    cmp ecx, AUX_LBRACE
    je __kw_macro_save_start_body
__kw_macro_expect_lbrace:
    lea rsi, [rbp-32]
    mov rdi, [rbp-40]
    call get_next_token_skip_new_line
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_AUX
    jne _err_invalid_expr
    mov ecx, [rbp-24]
    cmp ecx, AUX_LBRACE
    jne _err_invalid_expr
    mov rdi, [rbp-40]
    mov rsi, [rdi+16]
    mov dword [rbp-68], esi
__kw_macro_save_start_body:
    mov rax, [rbp-84]
    mov rdi, [rbp-40]
    mov ebx, [rdi+44]
    mov rcx, [rdi+16]
    mov [rax+32], ecx
    mov [rax+36], ebx
__kw_macro_set_entries:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    mov ecx, [rbp-8]
    cmp eax, TOKEN_TYPE_AUX 
    jne ___kw_macro_entr_check_n
    cmp ecx, AUX_RBRACE
    je __kw_macro_end
    jmp __kw_macro_set_entries
___kw_macro_entr_check_n:
    cmp eax, TOKEN_TYPE_KEYWORD; TODO: add check
    jne ___kw_macro_check_int_name
    mov ebx, ecx
    mov edx, DATA_QUL_TYPE_MASK
    and ebx, edx
    cmp ebx, edx
    jne _err_invalid_command_in_macr_def
    jne __kw_macro_set_entries 
___kw_macro_check_int_name:
    cmp eax, TOKEN_TYPE_NAME
    jne __kw_macro_set_entries 
    mov rdi, [rbp-92]
    mov rsi, [rbp-16]
    movzx edx, byte [rbp-3]
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jz __kw_macro_set_entries
    mov [rbp-108], rbx
    mov edi, 10
    call get_mem_def_name_buf
    mov r8d, [rbp-68]
    mov r9d, r8d
    mov rdi, [rbp-40]
    mov rbx, [rdi+16]
    mov r10, rbx
    movzx edx, byte [rbp-3]
    sub ebx, edx ; TODO: will file really be more then 4GiB?
    sub ebx, r9d
    mov [rax], r8d
    mov [rax+4], ebx
    mov [rbp-68], r10d
    mov rsi, [rbp-108]
    mov cl, [rsi+14]
    mov [rax+8], cl
    jmp __kw_macro_set_entries
__kw_macro_end:
    mov rdi, [rbp-40]
    mov rbx, [rdi]
    mov r9, [rdi+16]
    dec r9
    mov rcx, rbx
    mov r8d, [rbp-68]
    add rbx, r8
    add rcx, r9
    cmp rbx, rcx
    je __kw_macro_set_entry_size
    mov edi, 10
    call get_mem_def_name_buf
    mov r8d, [rbp-68]
    mov r9d, r8d
    mov rdi, [rbp-40]
    mov rbx, [rdi+16]
    mov r10, rbx
    dec rbx
    sub ebx, r9d
    mov [rax], r8d
    mov [rax+4], ebx
    mov [rbp-68], r10d
    mov byte [rax+8], MACRO_EMPTY_ARG_FLAG
__kw_macro_set_entry_size:
    mov rdx, [rbp-84]
    mov ebx, [rbp-72] 
    mov eax, dword [NAME_SYM_REF_ARRAY+8]
    sub eax, ebx
    mov [rdx], eax
    mov dword [TEMP_COMMON_ARR+8], 0
    jmp _new_entry_start_ps
__kw_name_mod:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_NAME
    jne _err_invalid_expr
    lea rdi, [NAME_SYM_HASH_TABLE]
    mov rsi, [rbp-32]
    movzx edx, byte [rbp-19]
    mov ecx, [rbp-24]
    call hash_table_find_entry
    mov rbx, [rax]
    mov ecx, [rbp-8]
    cmp ecx, KW_PUBLIC
    je __kw_public
__kw_extrn:
    test rbx, rbx
    jnz ___kw_extrn_check_name
    mov [rbp-72], rax
    mov rdi, rax
    lea rsi, [rbp-32]
    mov edx, [rbp-52]
    call push_name_to_defined
    mov dword [rax], NAME_DATA_ENTRY_SIZE 
    mov byte [rax+30], TOKEN_TYPE_EXT_REF 
    mov byte [rax+31], SYM_REF_MOD_EXTRN 
    mov edi, dword [CURR_SEG_OFFSET]
    call set_last_name_data_h_info
    jmp _new_entry_start_ps
___kw_extrn_check_name:
    sub rbx, NAME_SYM_REF_SERV_HS
    mov cl, [rbx+30]
    test cl, cl
    jz ___kw_extrn_check_is_def
    call name_entry_print_info
    jmp _err_def_ext
___kw_extrn_check_is_def:
    mov dl, SYM_REF_MASK_REF
    and dl, [rbx+31]
    test dl, dl
    jz ___kw_extrn_set
    call name_entry_print_info
    jmp _err_def_mod_def
___kw_extrn_set:
    or byte [rbx+31], SYM_REF_MOD_EXTRN
    jmp __kw_name_mod_unk_set_data
__kw_public:
    test rbx, rbx
    jnz ___kw_public_check_is_def
    mov [rbp-72], rax
    mov rdi, rax
    lea rsi, [rbp-32]
    xor rdx, rdx
    call push_name_to_unk
    mov rax, [rbp-72]
    mov rbx, [rax]
    sub rbx, NAME_SYM_REF_SERV_HS
    mov byte [rbx+31], SYM_REF_MOD_PUBLIC 
    jmp __kw_name_mod_unk_set_data
___kw_public_check_is_def:
    sub rbx, NAME_SYM_REF_SERV_HS
    mov dl, SYM_REF_MASK_REF
    or dl, [rbx+31]
    test dl, dl
    jz ___kw_public_check_name
    call name_entry_print_info
    jmp _err_def_mod_def
___kw_public_check_name:
    or byte [rbx+31], SYM_REF_MOD_PUBLIC
    mov cl, [rbx+30]
    test cl, cl
    jz __kw_name_mod_unk_set_data
    cmp cl, TOKEN_NAME_DATA
    je __kw_mod_check_last_char
    cmp cl, TOKEN_NAME_JMP
    je __kw_mod_check_last_char
    call name_entry_print_info
    jmp _err_def_pub
__kw_name_mod_unk_set_data:
    mov rdi, [rbp-40]
    mov esi, [rdi+16]
    mov edx, [rbp-52]
    mov ecx, dword [LAST_LINE_NUM]
    mov [rbx+4], edx
    mov [rbx+8], esi
    mov [rbx+12], ecx
    jmp _new_entry_start_ps
__kw_mod_check_last_char:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_EOF
    je __new_entry_start_read_ps 
    cmp eax, TOKEN_TYPE_AUX
    mov ebx, [rbp-8]
    cmp ebx, AUX_NEW_LINE
    jne _err_invalid_expr
    jmp _new_entry_start_ps
__kw_entry:
    mov bl, [BUILD_TYPE]
    cmp bl, BUILD_TYPE_ELF_OBJ
    je _err_entry_in_obj
    mov dl, [IS_ENTRY_DEFINED]
    test dl, dl
    jnz __kw_entry_err
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_NAME
    jne _err_invalid_expr
    lea rdi, [NAME_SYM_HASH_TABLE]
    mov rsi, [rbp-32]
    movzx edx, byte [rbp-19]
    mov ecx, [rbp-24]
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jnz ___kw_entry_define_sym
    mov [rbp-72], rax
    mov rdi, rax
    lea rsi, [rbp-32]
    xor rdx, rdx
    call push_name_to_unk
    mov rax, [rbp-72]
    mov rbx, [rax]
___kw_entry_define_sym:
    mov byte [IS_ENTRY_DEFINED], 1
    or byte [rbx+15], SYM_REF_EXT_ENTRY
    lea rax, [NAME_SYM_REF_ARRAY]
    lea rdx, [UNKNOWN_NAME_SYM_REF_ARRAY]
    mov cl, [rbx+14]
    cmp cl, 0
    cmovz rax, rdx
    sub rbx, NAME_SYM_REF_SERV_HS 
    mov r8, [rax]
    mov rsi, rbx
    sub rsi, r8
    mov [ENTRY_SYM_OFFSET], esi
    mov [ENTRY_SYM_ARR_PTR], rax
    test cl, cl
    jz __kw_name_mod_unk_set_data
    jmp _new_entry_start_ps 
__kw_entry_err:
    mov ebx, [ENTRY_SYM_OFFSET]
    mov rdx, [ENTRY_SYM_ARR_PTR]
    add rbx, [rdx]
    call name_entry_print_info
    jmp _err_dubl_entry

_err_macro_arg_rep:
    lea rsi, [ERR_MACRO_ARG_REP]
    jmp _err_start_parser
_err_macro_to_many_arg:
    lea rsi, [ERR_MACRO_TM_ARG]
    jmp _err_start_parser
_err_invalid_command_in_macr_def:
    lea rsi, [ERR_MACRO_FORBID_CMD]
    jmp _err_start_parser
_err_segment_not_set:
    lea rsi, [ERR_SEGMENT_NOT_SET]
    jmp _err_start_parser
_err_out_of_range_value:
    lea rsi, [ERR_STATIC_DIGIT_OVERFLOW]
    jmp _err_start_parser
_err_invalid_const_value:
    lea rsi, [ERR_INV_CONST_DEF]
    jmp _err_start_parser
_err_defined_symbol:
    lea rsi, [ERR_DEF_SYM]
    jmp _err_start_parser
_err_invalid_addr_expr:
    lea rsi, [ERR_INV_ADDR]
    jmp _err_start_parser
_err_invalid_expr:
    lea rsi, [ERR_INV_EXP]
    jmp _err_start_parser
_err_def_ext:
    lea rsi, [ERR_SYM_EXT_ALR_DEF]
    jmp _err_start_parser
_err_def_pub:
    lea rsi, [ERR_SYM_PUB_TYPE]
    jmp _err_start_parser
_err_def_mod_def:
    lea rsi, [ERR_SYM_HAS_MOD]
    jmp _err_start_parser
_err_def_ext_before:
    lea rsi, [ERR_SYM_EXT_DEF]
    jmp _err_start_parser
_err_dubl_entry:
    lea rsi, [ERR_DUBL_ENTRY]
    jmp _err_start_parser
_err_str_reg_val:
    lea rsi, [ERR_INV_EXP]
    jmp _err_start_parser
_err_seg_in_non_exe:
    lea rsi, [ERR_SEG_IN_N_EXE]
    jmp _err_start_parser
_err_sec_in_non_obj:
    lea rsi, [ERR_SEC_IN_N_OBJ]
    jmp _err_start_parser
_err_invalid_sec_modifier:
    lea rsi, [ERR_SEC_INV_MOD]
    jmp _err_start_parser
_err_entry_in_obj:
    lea rsi, [ERR_ENTRY_IN_OBJ]
    jmp _err_start_parser
_err_seg_inv_def:
    lea rsi, [ERR_SEG_INV_DEF]
_err_start_parser:
    mov edi, [rbp-52]
    xor rdx, rdx
    xor ecx, ecx
    mov r9, -4
    call err_print
_end_start_parser:
    add rsp, 256
    pop rbp
    ret

; rdi - ptr to file entry, esi - offset of curr file entry
parser_check_format:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-40], rdi
    mov [rbp-52], esi
_check_parser_first:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_KEYWORD
    jne _first_check_fail
    mov ecx, [rbp-8]
    cmp ecx, KW_FORMAT
    jne _end_parser_check_format
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_KEYWORD
    jne _err_parsre_check_format
    mov ecx, [rbp-8]
    cmp ecx, KW_F_ELF64
    jne __check_next_pcf
    mov byte [BUILD_TYPE], BUILD_TYPE_ELF_OBJ
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    mov ecx, [rbp-8]
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_KEYWORD
    jne ___check_nl_pcf
    cmp ecx, KW_EXTB
    jne _err_parsre_check_format
    mov byte [BUILD_TYPE], BUILD_TYPE_ELF_EXE
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    mov ecx, [rbp-8]
    movzx eax, byte [rbp-4]
___check_nl_pcf:
    cmp eax, TOKEN_TYPE_AUX
    jne _err_parsre_check_format
    cmp ecx, AUX_NEW_LINE
    jne _err_parsre_check_format
    jmp _end_parser_check_format 
_first_check_fail:
    xor rbx, rbx
    mov rax, [rbp-40]
    mov [rax+16], rbx
    jmp _set_bin_seg_pcf
__check_next_pcf:
    cmp ecx, KW_F_BIN
    jne _err_parsre_check_format
_set_bin_seg_pcf:
    mov dword [CURR_SEG_OFFSET], 0
    jmp _end_parser_check_format 
_err_parsre_check_format:
    mov rsi, ERR_INV_EXP
    mov edi, [rbp-52]
    xor rdx, rdx
    xor ecx, ecx
    mov r9, -4
    call err_print
_end_parser_check_format:
    add rsp, 64
    pop rbp
    ret

parser_check_print_unk_name:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    lea rdi, [UNKNOWN_NAME_SYM_REF_ARRAY] 
    mov ecx, [rdi+8]
    mov eax, UNK_ENTRY_SIZE
    mul ecx
    mov rdx, [rdi]
    add rax, rdx
    mov r8, rax
    mov [rbp-8], rdx
    mov [rbp-16], rax
    mov byte [rbp-29], 0
_loop_cpun:
    cmp rdx, r8
    je _end_loop_cpun
    mov esi, [rdx]
    test esi, esi
    jz _next_loop_cpun
    mov al, [rdx+31]
    and al, SYM_REF_MASK_REF
    cmp al, SYM_REF_MOD_EXTRN
    je _next_loop_cpun
    mov [rbp-8], rdx
    mov r9, [rdx+16]
__start_inner_loop_cpun:
    lea rdi, [PATCH_LIST]
    call list_get_node_ptr
    mov ebx, [rax]
    mov [rbp-28], ebx
    mov edi, [rax+4]
    lea rsi, [ERR_UNDEF_SYM]
    mov ecx, [rax+24]
    mov r8d, [rax+28]
    xor r9, r9
    call err_print
    call print_new_line
    mov byte [rbp-29], 1
    mov esi, [rbp-28]
    test esi, esi
    jnz __start_inner_loop_cpun
__end_inner_loop_cpun:
    mov r8, [rbp-16]
    mov rdx, [rbp-8] 
_next_loop_cpun:
    add rdx, PATCH_LIST_ENTRY_SIZE
    jmp _loop_cpun
_end_loop_cpun:
;    mov rdi, NAME_SYM_HASH_TABLE
;    call print_ht_sym_str
    mov al, [rbp-29]
    test al, al
    jz _return_cpun
    exit_m -1
_return_cpun:
    add rsp, 64
    pop rbp
    ret

; rdi - ptr to segment entry, esi - token buf size, edx - render buf size
segment_entry_init:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rdi
    mov [rbp-12], edx
    mov dword [rdi+16], 1
    mov dword [rdi+36], 1
    test esi, esi
    jz _init_next_seg_entry_init
    call init_entry_array
    mov rdi, [rbp-8]
_init_next_seg_entry_init:
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov esi, [rbp-12]
    test esi, esi
    jz _end_segment_entry_init
    call init_entry_array
_end_segment_entry_init:
    add rsp, 16
    pop rbp
    ret

init_parser_data:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    lea rdi, [TEMP_COMMON_ARR]
    mov rsi, 2048
    call init_entry_array
    lea rdi, [NAME_SYM_HASH_TABLE]
    mov rsi, 4096
    xor rdx, rdx
    call hash_table_init
    test rax, rax
    jz _fail_exit_init_parser_data 
    lea rdi, [UNKNOWN_NAME_SYM_REF_ARRAY]
    mov rsi, 1024
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    lea rdi, [NAME_SYM_REF_ARRAY]
    mov esi, 20480
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    lea rdi, [PATCH_LIST]
    mov esi, 1024
    call init_list
    test rax, rax
    jz _fail_exit_init_parser_data
    mov bl, [BUILD_TYPE]
    cmp bl, BUILD_TYPE_ELF_EXE
    jne _init_parser_check_o
    lea rdi, [SEG_ENTRY_ARRAY]
    mov esi, 8
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    mov ecx, 8
_init_seg_loop:
    dec ecx
    test ecx, ecx
    jz _init_parser_success
    mov rdi, [SEG_ENTRY_ARRAY]
    mov eax, SEG_ENTRY_SIZE
    mul ecx
    add rdi, rax
    push rcx
    mov esi, DEF_TOKEN_BUF_SIZE
    mov edx, DEF_REN_BUF_SIZE
    call segment_entry_init
    pop rcx
    jmp _init_seg_loop
_init_parser_check_o:
    ; TODO: do similar init for exe type?
    cmp bl, BUILD_TYPE_ELF_OBJ
    jne _init_parser_check_b
    lea rdi, [SEG_ENTRY_ARRAY]
    mov esi, 48
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    lea rdx, [SEG_ENTRY_ARRAY]
    mov rdi, [rdx]
    mov ecx, SEG_ENTRY_SIZE
    mov esi, [rdx+12]
    imul ecx, esi
    xor eax, eax
    rep stosb
    lea rbx, [DUMMY_NODE_AUX+SEC_NAME_OFFSET_FROM_DUMMY]
    mov [rbp-8], rbx
_init_sections_loop:
    mov al, [rbx+13]
    test al, al
    jz _init_parser_success
    mov ecx, [rbx+8]
    cmp ecx, KW_SEC_RELA
    jne __init_sec_skip_rela
    mov rdi, [SEG_ENTRY_ARRAY]
    and ecx, SEC_INDEX_MASK
    mov eax, SEG_ENTRY_SIZE
    mul ecx
    add rdi, rax
    mov [rdi+40], rbx
    jmp __next_init_sec_loop
__init_sec_skip_rela:
    mov [rbp-12], ecx
    mov r10d, ecx
    mov r8d, ecx
    and ecx, SEC_INDEX_MASK
    and r8d, IS_SEC_USER_DEF_MASK
    shr r10d, SEC_ATTR_RIGHTS_SHIFT
    and r10d, 0x7
    mov esi, DEF_TOKEN_BUF_SIZE
    mov eax, 0
    test r8d, r8d 
    cmovz esi, eax
    mov edx, DEF_REN_BUF_SIZE
    mov rdi, [SEG_ENTRY_ARRAY]
    mov eax, SEG_ENTRY_SIZE
    mul ecx
    add rdi, rax
    mov [rdi+48], r10w
    mov [rdi+40], rbx
    call segment_entry_init
    mov ecx, [rbp-12]
    mov ebx, KW_SEC_RELA
    cmp ecx, ebx
    jb __next_init_sec_loop
    and ecx, SEC_INDEX_MASK
    and ebx, SEC_INDEX_MASK
    add ecx, ebx
    mov rdi, [SEG_ENTRY_ARRAY]
    mov eax, SEG_ENTRY_SIZE
    mul ecx
    add rdi, rax
    mov esi, 0
    mov edx, DEF_REN_BUF_SIZE
    call segment_entry_init
__next_init_sec_loop:
    mov rbx, [rbp-8]
    add rbx, TOKEN_KIND_SIZE
    mov [rbp-8], rbx
    jmp _init_sections_loop
_init_parser_check_b:
    lea rdi, [SEG_ENTRY_ARRAY]
    mov esi, 1
    call init_entry_array
    mov rdi, qword [SEG_ENTRY_ARRAY]
    mov esi, DEF_TOKEN_BUF_SIZE
    mov edx, DEF_REN_BUF_SIZE
    call segment_entry_init
_init_parser_success:
    mov rax, 1
    jmp _end_init_parser_data
_fail_exit_init_parser_data:
    xor rax, rax
_end_init_parser_data:
    add rsp, 32
    pop rbp
    ret

