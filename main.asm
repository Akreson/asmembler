format ELF64 executable

include 'sys_call.asm'
include 'helper.asm'
include 'symbols.asm'

segment readable executable
entry _start

_start:
    mov r15, DEF_SYM_TABLE
_start_loop:
    mov rdi, [r15+8]
    test rdi, rdi
    jnz _print_val
    mov rax, [r15+4]
    test rax, rax
    jz _exit
    jmp _next_item
_print_val:
    call print_str
    mov rdi, NEW_LINE
    call print_str
_next_item:
    add r15, 16
    jmp _start_loop
_exit:
    exit_m 0

segment readable writeable
msg db "Hellow World", 10
db "lllallalalala", 10, 0
NEW_LINE db 10, 0
