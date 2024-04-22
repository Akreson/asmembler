SYS_READ equ 0
SYS_WRITE equ 1
SYS_OPEN equ 2
SYS_CLOSE equ 3
SYS_STAT equ 4
SYS_MMAP equ 9
SYS_MUNMAP equ 11
SYS_LSEEK equ 13
SYS_EXIT equ 60

O_CREAT equ 64
O_DIRECTORY equ 65536
O_RDONLY equ 0
O_WRONLY equ 1
O_RDWR equ 2

PROT_READ equ 1
PROT_WRITE equ 2
PROT_EXEC equ 4
MAP_SHARED equ 1
MAP_PRIVATE equ 2
MAP_ANONYMOUS equ 32
MAP_EXECUTABLE equ 4096

STD_IN equ 0
STD_OUT equ 1
STD_ERR equ 2

EACCES equ 13

STRUCT_STAT_SIZE equ 144
S_IFREG equ 0x400000
; st_ino offset 8, size 8
; st_mode offset 24, size 4
; st_size offset 48, size 8

macro write_m fd_out, buf_ptr, len
{
    mov rax, SYS_WRITE
	mov rdi, fd_out
	mov rsi, buf_ptr
	mov rdx, len
	syscall  
}

macro exit_m code
{
    mov rax, SYS_EXIT
    mov rdi, code
    syscall
}

segment readable executable

; rdi - zero end str
open_file_read:
    push rbp
    mov rax, SYS_OPEN
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    pop rbp
    ret
;rdi - ptr to path (zero ending str), rsi - ptr to memory for _struct stat_
stat:
    push rbp
    mov rbp, rsp
    mov rax, SYS_STAT
    syscall
    pop rbp
    ret


;rdi - size to alloc
mmap_def:
    push rbp
    mov rbp, rsp
    push rdi
    mov rax, SYS_MMAP
    mov rdi, 0
    pop rsi
    mov rdx, 0x3 ; READ + WRITE
    mov r10, 0x22 ; ANON + PRIVATE
    xor r8, r8
    xor r9, r9
    syscall
    pop rbp
    ret

;rdi - ptr to start of maped mem, rsi - size
munmap:
    push rbp
    mov rbp, rsp
    test rdi, rdi
    jz _exit_munmap
    mov rax, SYS_MUNMAP
    syscall
_exit_munmap:
    pop rbp
    ret
