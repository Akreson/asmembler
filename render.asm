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
    mov 1
    mov ecx
    lea rbx, [rdx+rax]
    mov [rdi+32], rbx
    mov eax, 5
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
    call set_collate_set_ptr
    mov [rbp-8], eax
    
_end_start_render:
    add rsp, 2304
    pop rbp
    ret
