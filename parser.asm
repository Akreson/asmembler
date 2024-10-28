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
TEST_MACRO_FILE db "./macro_test.asm", 0
LAST_LINE_NUM dd 0
CURR_SEG_OFFSET dd 0

entry_array_data_m TEMP_PARSER_ARR, 1

; entry
; 0 (4b) linked list entry offset to a chain of patch location, 
; +16 symbol entry (round up to multible of 8, curr 16) (32b total)
UNK_ENTRY_SIZE equ 32
entry_array_data_m UNKNOWN_NAME_SYM_REF_ARRAY, UNK_ENTRY_SIZE

; entry
; 0 data size, +4 offset in file array, +8 offset of definition in file data,
; +12 line num in file
; +16 name symbol token (+30 type, ), (header size 32b)
; (+32 start of data)
;(TOKEN_NAME_CONST || TOKEN_NAME_CONST_MUT)
; +32 sym token
;(TOKEN_NAME_JMP)
;(TOKEN_NAME_DATA)
; +32 segment offset, +36 offest to entry header in seg token buf
;(TOKEN_NAME_MACR)
; copy entires (4 offset, 4 len, 1 arg num)
NAME_CONST_ENTRY_SIZE    equ 46
NAME_DATA_ENTRY_SIZE     equ 40
NAME_SYM_REF_HEADER_SIZE equ 32
NAME_SYM_REF_SERV_HS     equ 16
entry_array_data_m NAME_SYM_REF_ARRAY, 1

; entry - 0 (entry array, work size 1b) token buf, +20 (entry array, work size 1b) render buf
; +40 file array id start, +44 file array id end, +48 mod (4b) (52b total)
SEG_ENTRY_SIZE equ 52
entry_array_data_m SEG_ENTRY_ARRAY, SEG_ENTRY_SIZE
hash_table_data_m NAME_SYM_HASH_TABLE, 1

; linked list entry body - +4 offset in file array, +8 **ptr of buf to offset from, +16 offset in buff,
; +20 second indirectional offset (must be 0 if not set)
;entry array (for ease mem mang.) + 
PATCH_LIST dq 0
dd 0, 0, 0
dd 0, 0

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
; (body) 
; +16(1) token type, +17 [(8) ptr to token | (TOKEN_KIND_SIZE) token body, [if TOKEN_KIND_INS +31 argc]] ... (n times)
; token type, qul size keyword token,(1) size of unit in bytes, direct/str token ... [n times]

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
;rdx - **ptr to buff, ecx - offset in buff, r8d - offset in file array,
;r9d - indirectional offset in buffer
push_name_to_unk:
    push rbp
    mov rbp, rsp
    sub rsp, 88
    mov [rbp-32], rdi
    mov [rbp-40], rsi
    mov [rbp-72], ecx
    mov [rbp-80], rdx
    mov [rbp-84], r8d
    mov [rbp-88], r9d
    mov rdi, UNKNOWN_NAME_SYM_REF_ARRAY 
    mov esi, 1
    call entry_array_check_get
    test rax, rax
    jnz _add_entry_pnt_unk
    mov rdi, UNKNOWN_NAME_SYM_REF_ARRAY 
    mov esi, [rdi+12]
    shl esi, 1
    lea rdx, [rbp-24]
    call entry_array_copy_realloc
    test rax, rax
    jnz _success_realloc_pnt_unk
    exit_m -9
_success_realloc_pnt_unk:
    mov rdi, UNKNOWN_NAME_SYM_REF_ARRAY
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
__ht_reasign_push_unk_start:
    mov rdi, NAME_SYM_HASH_TABLE
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
    add ecx, ebx
    cmp ecx, esi
    jae __dealloc_old_push_unk
    mov [rbp-60], ecx
    mov rdi, [rbp-48]
    lea r8, [rdi+rcx]
    jmp __ht_reasign_push_unk_start
__dealloc_old_push_unk:
    mov rdi, UNKNOWN_NAME_SYM_REF_ARRAY
    call entry_array_dealloc
    mov rdx, UNKNOWN_NAME_SYM_REF_ARRAY 
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
    mov rdi, NAME_SYM_HASH_TABLE
    mov rsi, [rbp-32]
    mov rdx, rax
    call hash_table_add_entry
    test rax, rax
    ;TODO: add check
    mov rdi, PATCH_LIST
    call list_check_get_free
    test eax, eax
    jnz _node_fetch_succ_pnt_unk
    mov rdi, PATCH_LIST
    mov esi, [rdi+12]
    shl esi, 1
    call list_realloc
    mov rdi, PATCH_LIST
    call list_check_get_free
_node_fetch_succ_pnt_unk:
    mov edx, eax
    mov rbx, [UNKNOWN_NAME_SYM_REF_ARRAY]
    mov rcx, [rbp-48]
    mov [rcx], edx
    add rcx, 16
    sub rcx, rbx
    mov rdi, PATCH_LIST
    mov esi, edx
    call list_get_node_ptr
    mov r10d, [rbp-88]
    mov r9d, [rbp-84]
    mov r8, [rbp-80]
    mov edx, [rbp-72]
    mov [rax+4], r9d
    mov [rax+8], r8
    mov [rax+16], edx
    mov [rax+20], r10d
    mov rax, UNKNOWN_NAME_SYM_REF_ARRAY
    mov ebx, ecx
_end_push_name_to_unk:
    add rsp, 88
    pop rbp
    ret

;rdi - ptr to symbol entry, rsi - **ptr to buff, edx - offset in buff
;ecx - offset in file array, r8d - indirectional offset
push_link_to_unk:
    push rbp
    mov rbp, rsp
    sub rsp, 28
    sub rdi, 16
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], edx
    mov [rbp-24], ecx
    mov [rbp-28], r8d
    mov rdi, PATCH_LIST
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
    mov [rbx+4], ecx
    mov [rbx+8], r8
    mov [rbx+16], eax
    mov [rbx+20], r9d
    mov rax, [rbp-8]
    mov edx, [rax]
    mov rdi, PATCH_LIST
    call list_insert_node
    test eax, eax
    jnz _finish_add_link_unk
    exit_m -7
_finish_add_link_unk:
    mov rbx, [rbp-8]
    mov [rbx], eax
_end_push_link_to_unk:
    add rsp, 28
    pop rbp
    ret

;TODO: free node 
;rdi - ptr to unk symbol, rsi - new buf to offset from, edx - new offset
patch_unk_ref:
    push rbp
    mov rbp, rsp
    sub rsp, 20
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], edx
    mov rbx, rdi
    sub rbx, 16
    mov esi, [rbx]
_loop_patch_ur:
    mov rdi, PATCH_LIST
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
    mov esi, [rax]
    test esi, esi
    jnz _loop_patch_ur
_end_patch_unk_ref:
    add rsp, 20
    pop rbp
    ret

; edi - req size
; return rax - addr to mem
get_mem_def_name_buf:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov esi, edi 
    mov rdi, NAME_SYM_REF_ARRAY
    call entry_array_check_get
    test rax, rax
    jnz _end_get_mem_def_name_buf 
    mov rdi, NAME_SYM_REF_ARRAY
    mov esi, [rdi]
    shl esi, 1
    lea rdx, [rbp-24]
    call entry_array_copy_realloc
    test rax, rax
    jnz _success_realloc_pnt_unk 
    exit_m -9
_success_realloc_pnt_def:
    mov rdi, NAME_SYM_REF_ARRAY
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
    mov rdi, NAME_SYM_HASH_TABLE
    mov rsi, [r8+16]
    mov ecx, [r8+24]
    movzx edx, byte [r8+29]
    call hash_table_find_entry
    mov rdx, [rbp-40]
    mov ecx, [rbp-44]
    mov esi, [rbp-48]
    mov ebx, [rdx]
    lea r9, [rdx+rcx+16]
    mov [rax], r9
    add ecx, ebx
    cmp ecx, esi
    jae __dealloc_old_pnt_def
    mov [rbp-44], ecx
    mov rdi, [rbp-32]
    lea r8, [rdi+rcx]
    jmp __ht_reasign_pnt_def
__dealloc_old_pnt_def:
    mov rdi, NAME_SYM_REF_ARRAY
    call entry_array_dealloc
    mov rdx, NAME_SYM_REF_ARRAY
    mov rdi, rdx
    lea rsi, [rbp-24]
    mov ecx, ENTRY_ARRAY_DATA_SIZE 
    rep movsb
    mov rdi, rdx
    mov esi, NAME_SYM_REF_HEADER_SIZE
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

;TODO: add offset to definition
;rdi - ht entry ptr, rsi - ptr to sym temp mem, ecx - file entry offset
;return rax - addr to start of allco mem, ebx - offset from start of buff 
push_name_to_defined:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], ecx
    mov edi, NAME_SYM_REF_HEADER_SIZE
    call get_mem_def_name_buf
    mov [rbp-32], rax
    mov [rbp-36], ebx
    add rax, 16
    mov rdi, rax
    mov rsi, [rbp-16]
    mov ecx, TOKEN_HEADER_SIZE
    rep movsb
    mov rbx, [rbp-8]
    mov rdi, [rbx]
    test rdi, rdi
    jz _add_entry_pnt_def
    mov rsi, NAME_SYM_REF_ARRAY
    mov rcx, [rsi]
    mov rdx, rax
    sub rdx, rcx
    ;mov [rbp-40], edx
    call patch_unk_ref
_add_entry_pnt_def:
    mov rax, [rbp-32]
    ;mov ebx, [rbp-40]
    mov edi, [rbp-24]
    mov ecx, dword [LAST_LINE_NUM]
    mov [rax+4], edi
    mov [rax+12], ecx
    mov rdi, NAME_SYM_HASH_TABLE
    mov rsi, [rbp-8]
    add rax, 16
    mov rdx, rax
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
    sub rsp, 36
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], edx
    mov [rbp-24], ecx
    mov [rbp-36], r8d
    mov rsi, [rdi]
    movzx edx, byte [rdi+13]
    mov ecx, [rdi+8]
    mov rdi, NAME_SYM_HASH_TABLE
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
    call push_link_to_unk
    mov rax, UNKNOWN_NAME_SYM_REF_ARRAY
    mov rbx, [rbp-32]
    mov rcx, [rax]
    sub rbx, rcx
    jmp _end_get_name_sym_ref_data
_def_sym_gnsrd:
    mov rax, NAME_SYM_REF_ARRAY
    mov rcx, [rax]
    sub rbx, rcx
_end_get_name_sym_ref_data:
    add rsp, 36
    pop rbp
    ret

;do not modifies rcx-rdi reg
curr_token_buf_ptr:
    mov r9, qword [SEG_ENTRY_ARRAY]
    mov r8d, dword [CURR_SEG_OFFSET]
    add r9, r8
    mov rax, [r9]
    mov ebx, [r9+8]
    add rax, rbx
    ret

;do not modifies rbx-rdi reg
curr_token_buf_start_ptr:
    mov r9, qword [SEG_ENTRY_ARRAY]
    mov r8d, dword [CURR_SEG_OFFSET]
    add r9, r8
    mov rax, [r9]
    ret

;do not modifies rbx-rdi reg
curr_seg_ptr:
    mov rax, qword [SEG_ENTRY_ARRAY]
    mov r8d, dword [CURR_SEG_OFFSET]
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
    mov rsi, SEG_ENTRY_ARRAY 
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
    neg qword [rsi]
    movzx rdi, byte [rsi+13]
    inc rdi
    mov rsi, 8
    call align_to_pow2
    mov rsi, [rbp-8]
    mov byte [rsi+13], al
    mov al, 1
    jmp _end_convert_digit_to_neg
_err_convert_dtn:
    xor rax, rax
_end_convert_digit_to_neg:
    add rsp, 8
    pop rbp
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
    mov r8, [TEMP_PARSER_ARR]
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
    mov dword [TEMP_PARSER_ARR+8], ebx
    mov rdx, r8
    mov esi, [rbp-20]; must be 1 byte size max
    call hash_table_init
    mov rax, [rbp-8]
    mov rbx, [rbp-16]
_end_init_hash_table_in_temp_p_arr:
    add rsp, 20
    pop rbp
    ret

;-16 token 0, -32 token 1, -40 passed rdi, -48 ptr to token in entry_array,
;-52 passed esi, -56(4) seg mask val /, -64 start offset of curr render entry,
;-68 temp var, -72 temp var, -76 offset to start of token buf entry header,
;-84 temp token buf ptr / temp token buf offset, -92 - -116 temp var,
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
    inc ebx
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
    inc ebx
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
    ;TODO: support neg digit
    cmp eax, TOKEN_TYPE_DIGIT
    jne _err_invalid_expr
___ins_digit_set_sp:
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-32]
    mov edx, [rbp-52]
    call push_direct
    mov edi, [rbp-76]
    call inc_ins_argc
    jmp __ins_next_arg_check
__ins_addr_tokens:
    xor rax, rax
    mov [rbp-72], rax
    mov byte [rbp-65], 3
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_REG
    jne ___ins_addr_name_test
    mov byte [rbp-68], 3
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
    add byte [rbp-65], 15
    jmp ___ins_addr_def
___ins_addr_name_test:
    cmp eax, TOKEN_TYPE_NAME
    jne _err_invalid_addr_expr
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    mov edx, [rbp-52]
    call push_name_ptr_offset
    add byte [rbp-65], 13
    mov byte [rbp-68], 2
    ;mov byte [rbp-67], 1
    mov eax, PARSER_ADDR_FLAG_NAME
    mov [rbp-72], eax
___ins_addr_def:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_AUX
    jne _err_invalid_expr
    mov ebx, [rbp-24]
    cmp ebx, AUX_RBRACKET
    jne ___ins_addr_def_next_aux
    call curr_token_buf_start_ptr
    movzx edx, byte [rbp-67]
    mov esi, 1
    cmp edx, 0
    cmove edx, esi
    mov ecx, [rbp-84]
    mov r8b, [rbp-65]
    mov [rax+rcx], dl
    add [rax+rcx+1], r8b
    mov edi, [rbp-76]
    call inc_ins_argc
    jmp __ins_next_arg_check
___ins_addr_def_next_aux:
    movzx ecx, byte [rbp-68]
    movzx edx, byte [rbp-67]
    cmp edx, ecx
    ja _err_invalid_addr_expr
    cmp ebx, AUX_ADD
    je ___ins_addr_arith_check
    cmp ebx, AUX_SUB
    je ___ins_addr_arith_check 
    cmp ebx, AUX_MUL
    je ___ins_addr_scale_check
    jne _err_invalid_addr_expr
___ins_addr_arith_check:
    movzx eax, byte [rbp-67]
    mov esi, eax
    mov edi, PARSER_ADDR_FLAG_BITS
    mul edi
    mov ecx, eax
    mov ebx, [rbp-72]
    mov r9d, ebx
    shr ebx, cl
    mov edi, PARSER_ADDR_FLAG_MASK
    and ebx, edi
    test ebx, ebx
    jnz ___ins_addr_arith_check_set_curr
    mov ebx, PARSER_ADDR_FLAG_REG
    shl ebx, cl
    or r9d, ebx
    mov [rbp-72], r9d
___ins_addr_arith_check_set_curr:
    mov edx, ebx
___ins_addr_arith_fetch_next:
    inc esi
    mov [rbp-67], sil
    mov [rbp-66], dl
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-32]
    call push_direct
    add byte [rbp-65], 15
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_REG
    je ___inc_addr_arith_reg
    cmp eax, TOKEN_TYPE_DIGIT
    je ___inc_addr_arith_digit_offset
    cmp eax, TOKEN_TYPE_NAME
    je ___inc_addr_arith_name_offset
    jmp _err_invalid_addr_expr
___inc_addr_arith_reg:
    mov eax, [rbp-24]
    movzx ecx, byte [rbp-67]
    movzx edx, byte [rbp-66]
    cmp eax, AUX_ADD
    jne _err_invalid_addr_expr
    cmp ecx, 2
    jae _err_invalid_addr_expr
    cmp edx, PARSER_ADDR_FLAG_REG_SCALE
    je _err_invalid_addr_expr
    cmp edx, PARSER_ADDR_FLAG_NAME
    je _err_invalid_addr_expr
___inc_addr_arith_reg_pass:
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
    add byte [rbp-65], 15
    inc byte [rbp-67]
    jmp ___ins_addr_def
___inc_addr_arith_digit_offset:
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    call push_direct
    add byte [rbp-65], 15
    jmp ___inc_addr_arith_offset
___inc_addr_arith_name_offset:
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-16]
    mov edx, [rbp-52]
    call push_name_ptr_offset
    add byte [rbp-65], 13
___inc_addr_arith_offset:
    mov al, [rbp-67]
    inc al
    mov [rbp-67], al
    mov [rbp-68], al
    jmp ___ins_addr_def
___ins_addr_scale_check:
    movzx edx, byte [rbp-67]
    cmp edx, 2
    ja _err_invalid_addr_expr
    cmp edx, 1
    jne ___ins_addr_scale_mul
    movzx ecx, byte [rbp-72]
    and ecx, PARSER_ADDR_FLAG_MASK
    cmp ecx, PARSER_ADDR_FLAG_REG_SCALE
    je _err_invalid_addr_expr
    cmp ecx, PARSER_ADDR_FLAG_NAME
    je _err_invalid_addr_expr
___ins_addr_scale_mul:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_NAME
    je ___ins_addr_scale_mul_name
    cmp eax, TOKEN_TYPE_DIGIT
    jne _err_invalid_addr_expr
    mov rcx, [rbp-32]
    cmp rcx, 8
    ja _err_invalid_addr_expr
    mov rdx, rcx
    dec rcx
    and rdx, rcx
    test rdx, rdx
    jnz _err_invalid_addr_expr
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-32]
    call push_direct
    add byte [rbp-65], 15
    jmp ___ins_addr_scale_set
___ins_addr_scale_mul_name:
    call curr_seg_ptr
    mov rdi, rax
    lea rsi, [rbp-32]
    mov edx, [rbp-52]
    call push_name_ptr_offset
    add byte [rbp-65], 13
___ins_addr_scale_set:
    movzx eax, byte [rbp-67]
    mov edi, PARSER_ADDR_FLAG_BITS
    mul edi
    mov ecx, eax
    mov esi, PARSER_ADDR_FLAG_REG_SCALE
    shl esi, cl
    mov edx, [rbp-72]
    or edx, esi
    mov [rbp-72], edx
    jmp ___ins_addr_def
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
    mov rdi, NAME_SYM_HASH_TABLE
    mov rsi, [rbp-16]
    movzx edx, byte [rbp-3]
    mov ecx, [rbp-8]
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jz __name_sp_check_next
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
    cmp eax, TOKEN_TYPE_AUX
    je __name_sp_set_def
    jmp _err_invalid_expr
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
    test r9b, r9b
    jz _err_segment_not_set
    mov [rbp-92], r8d
    mov r8, [rbp-84]
    mov dword [r8], NAME_DATA_ENTRY_SIZE
    mov byte [r8+30], TOKEN_NAME_DATA
    mov edi, 8
    call get_mem_def_name_buf
    mov [rbp-84], rax
    call curr_token_buf_ptr
    mov r8, [rbp-84]
    mov r9d, [rbp-92]
    mov [r8], r9d
    mov [r8+4], ebx 
    call curr_seg_ptr
    mov rdi, rax
    mov esi, [rbp-52]
    call push_token_entry_header
    ;mov r8, [rbp-84]
    ;mov [r8+8], ebx
    mov [rbp-76], ebx
___name_data_qul_read:
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
    jne _err_invalid_expr
___name_data_read_digit_overflow_check:
    movzx ebx, byte [rbp-68]
    shl ebx, 3
    movzx esi, byte [rbp-3] 
    cmp esi, ebx
    ja _err_out_of_range_value
___name_data_read_next:
    call curr_seg_ptr
    mov rdi, rax
    mov rsi, [rbp-40]
    lea rdx, [rbp-16]
    mov rcx, rdx
    call push_direct_and_read_next
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_EOF
    je ___name_data_read_finish 
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
    mov edi, [ebp-72]
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
    mov [rbp-92], r8d
    mov r8, [rbp-84]
    mov dword [r8], NAME_DATA_ENTRY_SIZE
    mov byte [r8+30], TOKEN_NAME_JMP
    mov edi, 8
    call get_mem_def_name_buf
    mov [rbp-84], rax
    call curr_token_buf_ptr
    mov r8, [rbp-84]
    mov r9d, dword [CURR_SEG_OFFSET]
    mov [r8], r9d
    mov [r8+4], ebx 
    jmp _new_entry_start_ps
__name_sp_macro:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    mov ecx, [rbp-8]
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_AUX
    jne ___name_sp_macro_skip_comma
    cmp ecx, AUX_COMMA
    je _err_invalid_expr
___name_sp_macro_skip_comma: 
    mov rdi, TEMP_PARSER_ARR
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
    cmp eax, TOKEN_TYPE_AUX
    jne ___ins_next_arg_eof
    mov ecx, [rbp-24]
    cmp ecx, AUX_COMMA
    je __name_sp_macro
    cmp ecx, AUX_NEW_LINE
    jne _err_invalid_expr
___name_sp_macro_arg_end:
    mov ebx, dword [TEMP_PARSER_ARR+8]
    mov [rbp-68], ebx
    mov rdx, [FILES_ARRAY]
    mov r8, [rbp-92]
    lea r9, [r8+NAME_SYM_REF_HEADER_SIZE]
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
    mov rdi, TEMP_PARSER_ARR
    mov esi, [r9+4]
    movzx eax, byte [r9+8]
    cmp eax, MACRO_EMPTY_ARG_FLAG
    je ___name_sp_macro_skip_arg_size
    mov ecx, TOKEN_KIND_SIZE
    mul ecx
    mov rbx, [TEMP_PARSER_ARR]
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
    mov rdi, [rbp-40]
    call get_file_entry_offset_by_ptr
    mov ecx, [rbp-52]
    mov [rbp-112], eax
    mov rbx, qword [TEMP_PARSER_ARR]
    mov edi, dword [TEMP_PARSER_ARR+8]
    mov byte [rbx+rdi], 0
    inc edi
    mov dword [TEMP_PARSER_ARR+8], edi
    mov edx, [rbp-68]
    sub edi, edx
    call alloc_virt_file
    mov [rbp-84], rax
    mov [rbp-72], ebx
    mov edi, [rbp-112]
    call get_file_entry_ptr_from_offset
    mov [rbp-40], rax
    mov rbx, qword [TEMP_PARSER_ARR]
    mov edx, [rbp-68]
    lea rsi, [rbx+rdx]
    mov rax, [rbp-84]
    mov rdi, [rax]
    mov rcx, [rax+8]
    rep movsb

    mov r8, rax
    mov rdi, TEST_MACRO_FILE
    call open_file_w_trunc
    mov rdi, rax
    mov rsi, [r8]
    mov rdx, [r8+8]
    call write

    jmp _new_entry_start_ps

_begin_kw_sp:
    ;TODO: add more
    mov eax, [rbp-8]
    cmp eax, KW_SEGMT
    je __kw_segm_sp
    cmp eax, KW_MACR
    je __kw_macr
    jmp _err_invalid_expr
__kw_segm_sp:
    ;TODO: catch wrong combination?
    xor eax, eax
    mov [rbp-56], eax
___kw_segm_loop_sp:
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_AUX
    jne ___kw_segm_next_check
    mov ebx, [rbp-24]
    cmp ebx, AUX_NEW_LINE
    je __assign_segment_collate
    jmp _err_invalid_expr
___kw_segm_next_check:
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
    jmp ___kw_segm_loop_sp
__assign_segment_collate:
    ;TODO: add file id start and end
    mov eax, [rbp-56]
    test eax, eax
    jz _err_seg_inv_def
    mov ebx, eax
    mov ecx, SEG_ENTRY_SIZE
    mul ecx
    mov dword [CURR_SEG_OFFSET], eax
    mov rdx, qword [SEG_ENTRY_ARRAY]
    add rdx, rax
    mov [rdx+48], ebx
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
    mov rdi, NAME_SYM_HASH_TABLE
    mov rsi, [rbp-16]
    movzx edx, byte [rbp-3]
    mov ecx, [rbp-8]
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jnz _err_defined_symbol
    mov rdi, rax
    lea rsi, [rbp-16]
    mov ecx, [rbp-52]
    call push_name_to_defined
    mov [rbp-84], rax
    mov [rbp-72], ebx
    mov byte [rax+30], TOKEN_NAME_MACRO
    mov edi, 32
    call init_hash_table_in_temp_p_arr
    mov [rbp-92], rax
    mov [rbp-100], rbx
__kw_macro_arg_loop:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    cmp eax, TOKEN_TYPE_NAME
    jne _err_invalid_expr
    mov rdi, [rbp-92]
    mov rsi, [rbp-16]
    movzx edx, byte [rbp-3]
    mov ecx, [rbp-8]
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jnz _err_macro_arg_rep
    mov [rbp-108], rax
    mov rdi, TEMP_PARSER_ARR
    mov esi, 15
    call entry_array_reserve_size
    mov rdx, rax
    mov rdi, rax
    lea rsi, [rbp-16]
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
    cmp eax, TOKEN_TYPE_AUX
    jne ___ins_next_arg_eof
    mov ecx, [rbp-24]
    cmp ecx, AUX_COMMA
    je __kw_macro_arg_loop
    cmp ecx, AUX_NEW_LINE
    je __kw_macro_expect_lbrace
    cmp ecx, AUX_LBRACE
    je __kw_macro_set_entries
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
__kw_macro_set_entries:
    lea rsi, [rbp-16]
    mov rdi, [rbp-40]
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
    mov dword [TEMP_PARSER_ARR+8], 0
    jmp _new_entry_start_ps

_err_macro_arg_rep:
_err_macro_to_many_arg:
_err_segment_not_set:
    mov rsi, ERR_SEGMENT_NOT_SET
    jmp _err_start_parser
_err_out_of_range_value:
    mov rsi, ERR_STATIC_DIGIT_OVERFLOW
    jmp _err_start_parser
_err_invalid_const_value:
    mov rsi, ERR_INV_CONST_DEF
    jmp _err_start_parser
_err_defined_symbol:
    mov rsi, ERR_DEF_SYM
    jmp _err_start_parser
_err_invalid_addr_expr:
    mov rsi, ERR_INV_ADDR
    jmp _err_start_parser
_err_invalid_expr:
    mov rsi, ERR_INV_EXP
    jmp _err_start_parser
_err_seg_inv_def:
    mov rsi, ERR_SEG_INV_DEF
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

; rdi - ptr to segment entry
segment_entry_init:
    push rbp
    mov rbp, rsp
    mov dword [rdi+16], 1
    mov dword [rdi+36], 1
    mov rsi, 50
    shl rsi, 10
    push rdi
    call init_entry_array
    pop rdi
    add rdi, ENTRY_ARRAY_DATA_SIZE
    mov rsi, 8
    shl rsi, 10
    call init_entry_array
    pop rbp
    ret

init_parser_data:
    push rbp
    mov rbp, rsp
    mov rdi, TEMP_PARSER_ARR
    mov rsi, 2048
    call init_entry_array
    mov rdi, NAME_SYM_HASH_TABLE
    mov rsi, 2048
    xor rdx, rdx
    call hash_table_init
    test rax, rax
    jz _fail_exit_init_parser_data 
    mov rdi, UNKNOWN_NAME_SYM_REF_ARRAY
    mov rsi, 256
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    mov rdi, NAME_SYM_REF_ARRAY
    mov rsi, 1
    shl rsi, 20
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    ;TODO: do not init seg array if non collate mod is enabled
    mov rdi, SEG_ENTRY_ARRAY
    mov rsi, 8
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    mov ecx, 8
_init_seg_loop:
    dec ecx
    test ecx, ecx
    jz _end_seg_loop
    mov rdi, qword [SEG_ENTRY_ARRAY]
    mov eax, SEG_ENTRY_SIZE
    mul ecx
    add rdi, rax
    push rcx
    call segment_entry_init
    pop rcx
    jmp _init_seg_loop
_end_seg_loop:
    mov rdi, PATCH_LIST
    mov dword [rdi+16], 24
    mov esi, 256
    call init_list
    test rax, rax
    jz _fail_exit_init_parser_data
    mov rax, 1
    jmp _end_init_parser_data
_fail_exit_init_parser_data:
    xor rax, rax
_end_init_parser_data:
    pop rbp
    ret
