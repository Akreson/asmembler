FILE_ENTRY_SIZE equ 64

segment readable writeable

ERR_NOT_A_FILE db ": is not a regular file", 0
FILE_MISS db ": unable to get info about file", 0
ACCES_DENIED db ": access denied", 0
ERROR_ACCESS db ": error on access file", 0
READ_ERR db ": error during file reading", 0

ALREADY_INCLUDED db ": already included", 0

;file array
;entry format - 0 ptr to file data, +8 ptr to str name, +16 file size, +24 inode, +32 name len (32 bytes reserved)
;array - 0 ptr to buf, +8 count, +12 capacity
FILES_ARRAY dq 0
dd 0, 0


segment readable executable

get_free_file_entry:
    push rbp
    mov rbp, rsp
    sub rsp, 24
    mov rdi, FILES_ARRAY
    mov rdx, [rdi]
    mov ecx, [rdi+8]
    mov ebx, [rdi+12]
    cmp ecx, ebx
    jne _fetch_entry_ptr_gffe
    mov [rbp-16], rdi
    mov edi, ebx
    shl edi, 1
    mov [rbp-4], edi
    shl edi, 6
    call mmap_def
    xor r8, r8
    cmp rax, r8
    jl _exit_get_free_file_entry
    mov [rbp-24], rax
    mov rbx, [rbp-16]
    mov rsi, [rbx]
    mov ecx, [rbx+8]
    shl ecx, 6
    mov rdi, rax
    rep movsb
    mov rdi, [rbx]
    mov esi, [rbx+12]
    shl esi, 6
    call munmap
    test rax, rax
    jnz _exit_get_free_file_entry
    mov rdi, [rbp-16]
    mov rdx, [rbp-24]
    mov esi, [rbp-4]
    mov [rdi], rdx
    mov [rdi+12], esi
    mov ecx, [rdi+8]
_fetch_entry_ptr_gffe:
    mov ebx, ecx
    shl ebx, 6
    lea rax, [rdx+rbx]
    inc ecx
    mov [rdi+8], ecx
_exit_get_free_file_entry:
    add rsp, 24
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
    mov r10, [r9+24]
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
;144 stat struct, +152 8 (4 padding) str len, +160 8 str ptr, +168 8 file entry ptr,
;+176 8 temp fd, +184 8 temp mem, 4KiB temp path

load_file_by_path:
    push rbp
    mov rbp, rsp
    sub rsp, 4280
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
    mov rdi, FILE_MISS
    call print_zero_str
    call print_new_line
    jmp _exit_load_file_by_path
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
    jmp _exit_load_file_by_path
_check_is_file_exit_lfbp:
    mov rdi, [rbp-136]
    call check_if_inode_exist
    test rax, rax
    ;TODO: better report?
    jz _get_file_entry_lfbp
    mov rdi, [rbp-160]
    mov esi, [rbp-152]
    call print_len_str
    mov rdi, ALREADY_INCLUDED
    call print_zero_str
    jmp _error_exit_lfbp 
_get_file_entry_lfbp:
    call get_free_file_entry
    mov [rbp-168], rax
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
    mov rdi, ACCES_DENIED
    jmp _error_exit_lfbp
_err1_lfbp:
    mov rdi, ERROR_ACCESS
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
    jl _exit_load_file_by_path
_read_up_file_lfbp:
    mov [rbp-184], rsi; mem
    mov rdx, [rbp-96]
    call read
    xor rbx, rbx
    cmp rax, rbx
    jg _save_read_file_lfbp
    mov rdi, rsp
    call print_zero_str
    mov rdi, READ_ERR
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
    mov [rax+8], rbx
    mov [rax+16], rcx
    mov [rax+24], rdx
    mov [rax+32], esi
    jmp _exit_load_file_by_path
_error_exit_lfbp:
    call print_new_line
    xor rax, rax
_exit_load_file_by_path:
    mov rdi, [rbp-176]
    test rdi, rdi
    jz _end_lfbp
    close_m
    mov rax, [rbp-168]
_end_lfbp:
    add rsp, 4280
    pop rbp
    ret

init_file_array:
    push rbp
    mov rbp, rsp
    mov rdi, 64
    shl rdi, 6
    call mmap_def
    xor rdx, rdx
    sub rdx, 1
    cmp rdx, rax
    jne _final_init_file_array
    xor rax, rax
    jmp _exit_init_file_array
_final_init_file_array:
    mov rdi, FILES_ARRAY
    mov [rdi], rax
    mov dword [rdi+8], 0
    mov dword [rdi+12], 64
    mov rax, 1
_exit_init_file_array:
    pop rbp
    ret
