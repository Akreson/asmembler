format ELF64 executable

include 'sys_call.asm'
include 'helper.asm'

segment readable executable
entry _start

_start: 
    mov rdi, msg
    call print_str

    mov rax, SYS_EXIT
    mov rdi, 0
    syscall

segment readable writeable
msg db "Hellow World", 10, 0

