

segment readable writeable

; entry
; 0 (4b) offset to linked list of location to patch, 
; +16 symbol entry (round up to multible of 8, curr 16) (32b total)
UNK_ENTRY_SIZE equ 32
; linked list body - +4 id in segment arr, +4 offset to patch
; ptr, count in entries, capacity in entries, entry size
UNKNOWN_NAME_SYM_REF_ARRAY dq 0
dd 0, 0, UNK_ENTRY_SIZE


; entry
; 0 data size, +4 id in segment arr, +4 offset in file, +4 line num in file
; +16 symbol entry (roud up), (header size 32b)
; +32 start of data in _token buff_ format
NAME_SYM_REF_ARRAY dq 0
dd 0, 0, 1

; TODO: complite
; entry - 0 ptr to tokens byff, +8 file array id, +12 mod (4b) (16b total)
SEG_ENTRY_ARRAY dq 0
dd 0, 0, 16

NAME_SYM_HASH_TABLE dq 0
dd 0, 0


;entry array (for ease mem mang.) + 
PATCH_LIST dq 0
dd 0, 0, 0
dd 0, 0

; token buff
; (header)
; 0(4) offset in render buff, +4(4) line num, +8(2) offset on line, +10(2) entry size in byte
; (body) 
; +12(1) token type, +13 [(8) ptr to token | (TOKEN_KIND_SIZE) token body] ... (n times)

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

;-16 token 0, -32 token 1, -40 passed rdi, -48 ptr to token 
; rdi - ptr to file entry
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
_next_test_sp:
    jmp _new_entry_start_ps

_begin_ins_sp:

_end_start_parser:
    add rsp, 256
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
    mov rsi, 1; TODO: change to 256
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    mov rdi, NAME_SYM_REF_ARRAY
    mov rsi, 1
    shl rsi, 20
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    mov rdi, SEG_ENTRY_ARRAY
    mov rsi, 64
    call init_entry_array
    test rax, rax
    jz _fail_exit_init_parser_data
    mov rdi, PATCH_LIST
    mov dword [rdi+16], 16
    mov esi, 5;TODO: change to 256
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
