format ELF64 executable

include 'sys_call.asm'
include 'helper.asm'

segment readable executable
entry _start

_start: 
    mov rdi, msg
    xor rsi, rsi
    call print_str
    mov rdi, 22990
    mov rsi, 10
    call print_u_digit
    mov rdi, 22910
    mov rsi, 3
    call print_u_digit
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall

segment readable writeable
msg db "Hellow World", 10
db "lllallalalala", 10, 0
