

segment readable writeable

; entry
; 0 (4b) offset to linked list of location to patch, 
; +16 symbol entry (round up to multible of 8, curr 16) (32b total)
UNK_ENTRY_SIZE equ 32
; linked list body - +4 offset in segment arr, +4 offset to patch
; ptr, count in entries, capacity in entries, entry size
UNKNOWN_NAME_SYM_REF_ARRAY dq 0
dd 0, 0, UNK_ENTRY_SIZE


; entry
; 0 data size, +4 offset in segment arr?, +8 offset of definition in file data, +12 line num in file
; +16 symbol entry (roud up), (header size 32b)
; +32 start of data in _token buff_ format
NAME_SYM_REF_ARRAY dq 0
dd 0, 0, 1

; TODO: complete
; entry - 0 (entry array, work size 1b) token buf , +20 file array id start,
; +24 file array id end, +28 mod (4b) (32b total)
SEG_ENTRY_SIZE equ 32
SEG_ENTRY_ARRAY dq 0
dd 0, 0, SEG_ENTRY_SIZE

NAME_SYM_HASH_TABLE dq 0
dd 0, 0

;entry array (for ease mem mang.) + 
PATCH_LIST dq 0
dd 0, 0, 0
dd 0, 0

TOKEN_HEADER_SIZE equ 16
; token buf
; (header)
; 0(4) offset in render buf, +4(4) file entry offset, +8(4) line num, +12(2) entry size in byte
; (2 bytes reseved)
; (body) 
; +16(1) token type, +17 [(8) ptr to token | (TOKEN_KIND_SIZE) token body] ... (n times)

CURR_SEG_OFFSET dd 0

ERR_SEG_INV_DEF db "ERR: invalid definition of segment", 0
ERR_INV_EXP db "ERR: invalid expresion", 0

segment readable executable

;rdi - ptr to ht entry, rsi - ptr to temp token block storage
push_name_to_unk:
    push rbp
    mov rbp, rsp
    sub rsp, 68
    mov [rbp-32], rdi
    mov [rbp-40], rsi
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
    xor edx, edx
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
    mov ecx, 20
    lea rsi, [rbp-24]
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
    ;TODO: init header
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
    mov r8, [rbp-48]
    mov [r8], eax 
    ;TODO: init list entry
_end_push_name_to_unk:
    add rsp, 68
    pop rbp
    ret

;rdi - ptr to symbol entry, esi - segment id, edx - offset to patch
push_link_to_unk:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    sub rdi, 16
    mov [rbp-8], rdi
    mov [rbp-12], esi
    mov [rbp-16], edx
    mov rdi, PATCH_LIST
    call list_check_get_free
    test eax, eax
    jnz _add_link_to_chain_unk 
    mov rdi, PATCH_LIST
    mov esi, [rdi+12]
    shl esi, 1
    call list_realloc
    mov rdi, PATCH_LIST
    call list_check_get_free
_add_link_to_chain_unk:
    mov esi, eax
    mov ecx, [rbp-12]
    mov eax, [rbp-16]
    mov [rbx+4], ecx
    mov [rbx+8], eax
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
    add rsp, 16
    pop rbp
    ret

;TODO: complete
;rdi - ptr to unk symbol
patch_unk_ref:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    mov [rbp-8], rdi
    mov rbx, rdi
    sub rbx, 16
_loop_patch_ur:
    mov rdi, PATCH_LIST
    mov esi, [rbx]
    call list_free_node
    test eax, eax
    jz _end_patch_unk_ref
    mov rbx, [rbp-8]
    mov [rbx], eax
    jmp _loop_patch_ur
_end_patch_unk_ref:
    add rsp, 16
    pop rbp
    ret

;-16 token 0, -32 token 1, -40 passed rdi, -48 ptr to token in entry_array,
;-52 passed esi, -56(4) seg mask val /, -64 start offset of curr render entry
; rdi - ptr to file entry, esi- offset of file entry
start_parser:
    push rbp
    mov rbp, rsp
    sub rsp, 256
    mov [rbp-40], rdi
_new_entry_start_ps:
    mov rdi, [rbp-40]
    lea rsi, [rbp-16]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-4]
    ;cmp eax, TOKEN_TYPE_INS
    ;je _begin_ins_sp
    cmp eax, TOKEN_TYPE_NAME
    je _begin_name_sp
    cmp eax, TOKEN_TYPE_KEYWORD
    je _begin_kw_sp 
    cmp eax, TOKEN_TYPE_EOF
    jz _end_start_parser
    jmp _new_entry_start_ps;TODO: remove

_begin_name_sp:
    mov ecx, [rbp-8]
    mov rdi, NAME_SYM_HASH_TABLE
    mov rsi, [rbp-16]
    movzx edx, byte [rbp-3]
    call hash_table_find_entry
    mov rbx, [rax]
    test rbx, rbx
    jnz _check_next_sym
    lea rsi, [rbp-16]
    mov rdi, rax
    call push_name_to_unk
    jmp _print_buff_info
_check_next_sym:
    mov [rbp-48], rbx
    mov rdi, [rbp-40]
    lea rsi, [rbp-32]
    call next_token
    test rax, rax
    jz _end_start_parser
    movzx eax, byte [rbp-20]
    cmp eax, TOKEN_TYPE_EOF
    je _add_to_chain
    cmp eax, TOKEN_TYPE_AUX
    jne _new_entry_start_ps
    mov eax, [rbp-24]
    cmp eax, AUX_COLON
    jne _add_to_chain
    mov rdi, [rbp-48]
    call patch_unk_ref
    jmp _new_entry_start_ps
_add_to_chain:
    mov rdi, [rbp-48]
    mov esi, 0
    mov edx, 0
    call push_link_to_unk
    jmp _new_entry_start_ps
_print_buff_info:
    movzx rdi, byte [rbp-4]
    mov rsi, 10
    call print_u_digit
    call print_new_line
    mov rdi, [rbp-16]
    movzx rsi, byte [rbp-3]
    call print_len_str
    call print_new_line
    mov r15, UNKNOWN_NAME_SYM_REF_ARRAY 
    mov edi, [r15+12]
    mov esi, 10
    call print_u_digit
    call print_new_line
    mov edi, [r15+8]
    mov esi, 10
    call print_u_digit
    call print_new_line
    call print_new_line

_begin_kw_sp:
    ;TODO: add more
    mov eax, [rbp-8]
    cmp eax, KW_SEGMT
    je __kw_segm_sp
    jmp _err_invalid_expr
__kw_segm_sp:
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
    mov eax, [rbp-56]
    test eax, eax
    jz _err_seg_inv_def
    mov ebx, eax
    mov ecx, SEG_ENTRY_SIZE
    mul ecx
    mov dword [CURR_SEG_OFFSET], eax
    mov rdx, qword [SEG_ENTRY_ARRAY]
    add rdx, rax
    mov [rdx+28], ebx
    jmp _new_entry_start_ps
_next_test_sp:
    jmp _new_entry_start_ps

_begin_ins_sp:
_err_invalid_expr:
    mov rdi, [rbp-40]
    call print_file_line
    mov rdi, ERR_INV_EXP
    call print_zero_str
    call print_new_line
    exit_m -6
_err_seg_inv_def:
    mov rdi, [rbp-40]
    call print_file_line
    mov rdi, ERR_SEG_INV_DEF
    call print_zero_str
    call print_new_line
    exit_m -6
_end_start_parser:
    add rsp, 256
    pop rbp
    ret

; rdi - ptr to segment entry
segment_entry_init:
    push rbp
    mov rbp, rsp
    mov dword [rdi+16], 1
    mov rsi, 50
    shl rsi, 10
    call init_entry_array
    pop rbp
    ret


init_parser_data:
    push rbp
    mov rbp, rsp
    mov rdi, NAME_SYM_HASH_TABLE
    mov rsi, 2048
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
    mov rsi, 7
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    mov ecx, 7
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
    mov dword [rdi+16], 16
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
