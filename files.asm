FILE_ENTRY_SIZE equ 64

segment readable writeable

;file array
;entry format - 0 ptr to file data, +8 alloc data size, +16 read pos, +24 ptr to str name,
;+32 inode, +40 name len, +44 curr line num, +48 offset to parent entry,
;+52 offset in parent buff, +56 line in parent buff (16 bytes reserved) 
FILE_ARRAY_ENTRY_SIZE equ 64
;array - 0 ptr to buf, +8 count, +12 capacity
FILES_ARRAY dq 0
dd 0, 0, 64

segment readable executable

;rdi - ptr to entry
get_file_offset_by_ptr:
    push rbp
    mov rbp, rsp
    test rdi, rdi
    jz _fail_get_fobp
    mov r8, qword [FILES_ARRAY]
    cmp rdi, r8
    jb _fail_get_fobp
    mov r9, r8
    mov r10d, dword [FILES_ARRAY+8]
    shl r10d, 6
    sub eax, FILE_ARRAY_ENTRY_SIZE
    add r9, rax
    cmp rdi, r9
    ja _fail_get_fobp
    sub rdi, r8
    shr rdi, 6
    mov eax, edi
    jmp _end_get_file_offset_by_ptr
_fail_get_fobp:
    xor eax, eax
    dec eax
_end_get_file_offset_by_ptr:
    pop rbp
    ret

;rdi - inode
check_if_inode_exist:
    push rbp
    mov rbp, rsp
    mov r8, FILES_ARRAY
    mov r9, [r8]
    mov ecx, [r8+8]
    xor rax, rax
    test ecx, ecx
    jz _exit_check_if_inode_exist
_loop_ciie:
    mov r10, [r9+32]
    cmp r10, rdi
    jne _next_loop_ciie
    mov rax, r9
    jmp _exit_check_if_inode_exist
_next_loop_ciie:
    add r9, FILE_ENTRY_SIZE
    dec ecx
    test ecx, ecx
    jnz _loop_ciie
_exit_check_if_inode_exist:
    pop rbp
    ret

;rdi - ptr to path str, esi - str len
;-144 stat struct, -152 (4) (4 padding) str len, -160(8) str ptr, -168(8) file entry ptr,
;-176(8) temp fd, -184(8) temp mem, -188(4) offset of file entry, 4KiB temp path
load_file_by_path:
    push rbp
    mov rbp, rsp
    sub rsp, 4288
    mov eax, 4096
    cmp esi, eax
    jng _len_pach_check_lfbp 
    xor rax, rax
    jmp _exit_load_file_by_path
_len_pach_check_lfbp:
    xor rbx, rbx
    mov [rbp-176], rbx
    mov [rbp-152], esi
    mov [rbp-160], rdi
    mov ecx, esi
    mov rsi, rdi
    mov rdi, rsp
    rep movsb
    mov byte [rdi], 0
    mov rdi, rsp
    lea rsi, [rbp-144]
    call stat
    test eax, eax
    jz _stat_success_lfbp
    mov rdi, rsp
    call print_zero_str
    mov rdi, ERR_FILE_MISS
    call print_zero_str
    call print_new_line
    jmp _error_exit_lfbp
_stat_success_lfbp:
    mov rax, [rbp-96]; file size
    test rax, rax
    jz _end_lfbp
    mov eax, [rbp-120]
    and eax, S_IFMT
    mov ebx, S_IFREG
    cmp eax, ebx
    je _check_is_file_exit_lfbp
    mov rdi, rsp
    call print_zero_str
    mov rdi, ERR_NOT_A_FILE
    call print_zero_str
    call print_new_line
    jmp _error_exit_lfbp
_check_is_file_exit_lfbp:
    mov rdi, [rbp-136]
    call check_if_inode_exist
    test rax, rax
    ;TODO: better report?
    jz _get_file_entry_lfbp
    mov rdi, [rbp-160]
    mov esi, [rbp-152]
    call print_len_str
    mov rdi, ERR_ALREADY_INCLUDED
    call print_zero_str
    jmp _error_exit_lfbp 
_get_file_entry_lfbp:
    mov rdi, FILES_ARRAY
    mov esi, 1
    call entry_array_reserve_size
    mov [rbp-168], rax
    mov [rbp-188], ebx
    mov rdi, rsp
    call open_file_read
    xor rbx, rbx
    cmp rax, rbx
    jg _alloc_file_mem_lfbp
    mov rdi, rsp
    call print_zero_str
    sub rbx, EACCES
    cmp rax, rbx
    jne _err1_lfbp
    mov rdi, ERR_ACCES_DENIED
    jmp _error_exit_lfbp
_err1_lfbp:
    mov rdi, ERR_ERROR_ACCESS
    call print_zero_str
    jmp _error_exit_lfbp
_alloc_file_mem_lfbp:
    mov [rbp-176], rax;fd
    mov rdi, [rbp-96] ;size
    call mmap_def
    mov rdi, [rbp-176]
    mov rsi, rax
    xor rax, rax
    cmp rsi, rax
    jl _error_exit_lfbp
_read_up_file_lfbp:
    mov [rbp-184], rsi; mem
    mov rdx, [rbp-96]
    call read
    xor rbx, rbx
    cmp rax, rbx;TODO: check properly
    jg _save_read_file_lfbp
    mov rdi, rsp
    call print_zero_str
    mov rdi, ERR_READ_ERR
    call print_zero_str
    call print_new_line
    jmp _error_exit_lfbp
_save_read_file_lfbp:
    mov rax, [rbp-168];entry ptr
    mov rdi, [rbp-184];mem
    mov rbx, [rbp-160];str ptr
    mov rcx, [rbp-96]; file size
    mov rdx, [rbp-136];inode
    mov esi, [rbp-152];name len
    mov [rax], rdi
    mov [rax+24], rbx
    mov [rax+8], rcx
    mov [rax+32], rdx
    mov [rax+40], esi
    xor r8, r8
    mov [rax+16], r8
    mov dword [rax+44], 1
    mov ebx, [rbp-188]
    jmp _exit_load_file_by_path
_error_exit_lfbp:
    exit_m -1
_exit_load_file_by_path:
    mov rdi, [rbp-176]
    test rdi, rdi
    jz _end_lfbp
    mov rax, [rbp-168]
_end_lfbp:
    add rsp, 4288
    pop rbp
    ret

init_file_array:
    push rbp
    mov rbp, rsp
    mov rdi, FILES_ARRAY
    mov rsi, 64
    call init_entry_array
    test rax, rax
    jz _exit_init_file_array
    mov rdi, FILES_ARRAY
    mov dword [rdi+8], 1
_exit_init_file_array:
    pop rbp
    ret
