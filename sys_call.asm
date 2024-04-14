SYS_READ equ 0
SYS_WRITE equ 1
SYS_OPEN equ 2
SYS_CLOSE equ 3
SYS_MMAP equ 9
SYS_LSEEK equ 13
SYS_EXIT equ 60

O_CREAT equ 64
O_DIRECTORY equ 65536
O_RDONLY equ 0
O_WRONLY equ 1
O_RDWR equ 2

PROT_EXEC equ 4
PROT_READ equ 1
PROT_WRITE equ 2

STD_IN equ 0
STD_OUT equ 1
STD_ERR equ 2

macro write_m fd_out, buf_ptr, len
{
    mov rax, SYS_WRITE
	mov rdi, fd_out
	mov rsi, buf_ptr
	mov rdx, len
	syscall  
}

