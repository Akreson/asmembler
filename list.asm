segment readable executable
; first entry at offset 0 is reserved as invalid offset

;0 ptr to mem, +8 count, +12 capacity, +16 entry size,
;+20 free next offset, +24 ?
macro list_main_block_m name
{
;entry array main block
name dq 0
dd 0, 0, 0
;sentinal of free and in use nodes
;TODO: remove in use node track?
dd 0, 0
}

LIST_BLOCK_SIZE equ 24
; list entry
; 0 next offset, +4 data ...

;does not modifies ebx-rsi reg
;rdi - ptr to list main block, esi - offset of node
;return rax - ptr to node
list_get_node_ptr:
    mov eax, [rdi+16]
    mov r9d, [rdi+12]
    mul r9d
    cmp esi, eax
    ja _out_of_range_list_get
    mov r8, [rdi]
    lea rax, [r8+rsi]
    jmp _end_list_get_node_ptr
_out_of_range_list_get:
    xor rax, rax
_end_list_get_node_ptr:
    ret

;rdi - ptr to list main block, esi - offset to insert entry, edx - offset to curr lead node
;return eax = 0 if err, eax = passed esi
list_insert_node:
    push rbp
    mov rbp, rsp
    test esi, esi
    jz _out_of_range_list_insert
    mov r8d, edx
    mov eax, [rdi+16]
    mov ecx, [rdi+12]
    mul ecx
    cmp esi, eax
    ja _out_of_range_list_insert  
    cmp r8d, eax
    ja _out_of_range_list_insert
    mov rbx, [rdi]
    mov [rbx+rsi], r8d
    mov eax, esi
    jmp _end_list_insert
_out_of_range_list_insert:
    xor eax, eax
_end_list_insert:
    pop rbp
    ret

; TODO: check if node to free is last alloc
;rdi - ptr to list main block, esi - offset to node to free
;return eax - next entry offset
list_free_node:
    push rbp
    mov rbp, rsp
    sub rsp, 4
    mov rbx, [rdi]
    mov eax, [rbx+rsi]
    mov [rbp-4], eax
    mov ecx, [rdi+24]
    cmp ecx, esi
    jne _list_free_insert_to_free
    mov [rdi+24], eax
_list_free_insert_to_free:
    mov edx, [rdi+20]
    call list_insert_node
    test eax, eax
    jz _err_list_free_node
    mov ecx, eax
    mov [rdi+20], ecx
    mov eax, [rbp-4]
    jmp _end_list_free_node
_err_list_free_node:
    xor eax, eax
_end_list_free_node:
    add rsp, 4
    pop rbp
    ret

;rdi - ptr to list main block
;return eax - offset, rbx - ptr to block
list_check_get_free:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov [rbp-8], rdi
    mov esi, 1
    call entry_array_check_get
    test rax, rax
    jz _check_free_list_lcgf 
    mov rbx, rax
    mov rdi, [rbp-8]
    mov rdx, [rdi]
    sub rax, rdx
    mov [rdi+24], eax
    jmp _end_dlist_check_get_entry 
_check_free_list_lcgf:
    mov rdi, [rbp-8]
    mov ebx, [rdi+20]
    test ebx, ebx
    jz _check_fail_dcgf
    mov rdx, [rdi]
    lea r8, [rdx+rbx]
    mov ecx, [r8]
    mov [rdi+20], ecx
    mov eax, ebx
    mov [rdi+24], eax
    mov rbx, r8
    jmp _end_dlist_check_get_entry
_check_fail_dcgf:
    xor rax, rax
_end_dlist_check_get_entry:
    add rsp, 8
    pop rbp
    ret


;rdi - ptr to list main block, esi - new capacity
list_realloc:
    push rbp
    mov rbp, rsp
    sub rsp, 40
    mov [rbp-40], rdi
    mov rbx, [rdi]
    mov [rbp-32], rbx
    lea rdx, [rbp-24]
    call entry_array_copy_realloc
    test rax, rax
    jnz _success_list_realloc
    exit_m -9
_success_list_realloc:
    mov rdi, [rbp-32]
    call entry_array_dealloc
    mov rdi, [rbp-40]
    lea rsi, [rbp-24]
    mov ecx, LIST_BLOCK_SIZE
    rep movsb
_end_list_realloc:
    add rsp, 40
    pop rbp
    ret

; rdi - ptr to list main block
list_get_free:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov [rbp-8], rdi
    call list_check_get_free
    test eax, eax
    jnz _end_list_get_free 
    mov rdi, [rbp-8]
    mov esi, [rdi+12]
    shl esi, 1
    call list_realloc
    mov rdi, [rbp-8] 
    call list_check_get_free
_end_list_get_free:
    add rsp, 8
    pop rbp
    ret

list_dealloc:
;TODO: implement

;rdi - ptr to list main block, rsi - started count of entries
init_list:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    mov [rbp-8], rdi
    inc rsi
    call init_entry_array
    test rax, rax
    jz _fail_init_dlist
    mov rdi, [rbp-8]
    mov dword [rdi+8], 1
    mov eax, 1
    jmp _end_init_dlist
_fail_init_dlist:
    xor rax, rax
_end_init_dlist:
    add rsp, 8
    pop rbp
    ret
