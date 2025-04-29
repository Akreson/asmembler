EM_X86_64 equ 62; AMD x86-64 architecture

;elf type ET_NONE equ 0; No file type
ET_REL  equ 1; Relocatable file
ET_EXEC equ 2; Executable file
ET_DYN  equ 3; Shared object file
ET_CORE equ 4; Core file

PT_NULL    equ 0
PT_LOAD	   equ 1
PT_DYNAMIC equ 2
PT_INTERP  equ 3
PT_NOTE	   equ 4
PT_SHLIB   equ 5
PT_PHDR	   equ 6
PT_TLS     equ 7

; Special section indices
SHN_UNDEF     equ 0; Undefined section
SHN_LORESERVE equ 0xff00; Start of reserved indices
SHN_LOPROC    equ 0xff00; Start of processor-specific
SHN_HIPROC    equ 0xff1f; End of processor-specific
SHN_LOOS      equ 0xff20; Start of OS-specific
SHN_HIOS      equ 0xff3f; End of OS-specific
SHN_ABS	      equ 0xfff1; Associated symbol is absolute
SHN_COMMON    equ 0xfff2; Associated symbol is common
SHN_XINDEX    equ 0xffff; Index is in extra table
SHN_HIRESERVE equ 0xffff; End of reserved indices

; Legal values for sh_type (section type).
SHT_NULL          equ 0; Section header table entry unused
SHT_PROGBITS      equ 1; Program data
SHT_SYMTAB        equ 2; Symbol table
SHT_STRTAB        equ 3; String table
SHT_RELA          equ 4; Relocation entries with addends
SHT_HASH          equ 5; Symbol hash table
SHT_DYNAMIC       equ 6; Dynamic linking information SHT_NOTE          equ 7; Notes
SHT_NOBITS        equ 8; Program space with no data (bss)
SHT_REL           equ 9; Relocation entries, no addends
SHT_SHLIB         equ 10; Reserved
SHT_DYNSYM        equ 11; Dynamic linker symbol table
SHT_INIT_ARRAY    equ 14; Array of constructors
SHT_FINI_ARRAY    equ 15; Array of destructors
SHT_PREINIT_ARRAY equ 16; Array of pre-constructors
SHT_GROUP         equ 17; Section group
SHT_SYMTAB_SHNDX  equ 18; Extended section indices
SHT_NUM           equ 19; Number of defined types.

; Legal values for sh_flags.
SHF_WRITE            equ 0x0; Writable
SHF_ALLOC            equ 0x1; Occupies memory during execution
SHF_EXECINSTR        equ 0x2; Executable
SHF_MERGE            equ 0x10; Might be merged
SHF_STRINGS          equ 0x20; Contains nul-terminated strings
SHF_INFO_LINK        equ 0x40; `sh_info' contains SHT index
SHF_LINK_ORDER       equ 0x80; Preserve order after combining
SHF_OS_NONCONFORMING equ 0x100; Non-standard OS specific handling required
SHF_GROUP            equ 0x200; Section is member of a group.
SHF_TLS              equ 0x400; Section hold thread-local data.
SHF_COMPRESSED       equ 0x800; Section with compressed data.
SHF_MASKOS           equ 0x0ff00000; OS-specific.
SHF_MASKPROC         equ 0xf0000000; Processor-specific
SHF_GNU_RETAIN       equ 0x200000; Not to be GCed by linker.

; Legal values for ST_BIND subfield of st_info (symbol binding).
STB_LOCAL      equ 0; Local symbol
STB_GLOBAL     equ 1; Global symbol
STB_WEAK       equ 2; Weak symbol
STB_NUM        equ 3; Number of defined types
STB_LOOS       equ 10; Start of OS-specific
STB_GNU_UNIQUE equ 10; Unique symbol.
STB_HIOS       equ 12; End of OS-specific
STB_LOPROC     equ 13; Start of processor-specific
STB_HIPROC     equ 15; End of processor-specific

; Legal values for ST_TYPE subfield of st_info (symbol type).
STT_NOTYPE    equ 0; Symbol type is unspecified
STT_OBJECT    equ 1; Symbol is a data object
STT_FUNC      equ 2; Symbol is a code object
STT_SECTION   equ 3; Symbol associated with a section
STT_FILE      equ 4; Symbol's name is file name
STT_COMMON    equ 5; Symbol is a common data object
STT_TLS       equ 6; Symbol is thread-local data object
STT_NUM	      equ 7;Number of defined types
STT_LOOS      equ 10; Start of OS-specific
STT_GNU_IFUNC equ 10; Symbol is indirect code object
STT_HIOS      equ 12; End of OS-specific
STT_LOPROC    equ 13; Start of processor-specific
STT_HIPROC    equ 15; End of processor-specific

; Symbol table indices are found in the hash buckets and chain table
; of a symbol hash table section.  This special index value indicates
; the end of a chain, meaning no further symbols are found in that bucket.

STN_UNDEF                equ 0; End of a chain relocations
R_X86_64_NONE            equ 0; No rel
R_X86_64_64              equ 1; Direct 64 bi
R_X86_64_PC32            equ 2; PC relative 32 bit sign
R_X86_64_GOT32           equ 3; 32 bit GOT ent
R_X86_64_PLT32           equ 4; 32 bit PLT addre
R_X86_64_COPY            equ 5; Copy symbol at runti
R_X86_64_GLOB_DAT        equ 6; Create GOT ent
R_X86_64_JUMP_SLOT       equ 7; Create PLT ent
R_X86_64_RELATIVE        equ 8; Adjust by program ba
R_X86_64_GOTPCREL        equ 9; 32 bit signed PC rel offset to GOT
R_X86_64_32              equ 10; Direct 32 bit zero extended
R_X86_64_32S             equ 11; Direct 32 bit sign extended
R_X86_64_16              equ 12; Direct 16 bit zero extended
R_X86_64_PC16            equ 13; 16 bit sign extended pc relative
R_X86_64_8               equ 14; Direct 8 bit sign extended
R_X86_64_PC8             equ 15; 8 bit sign extended pc relative
R_X86_64_DTPMOD64        equ 16; ID of module containing symbol
R_X86_64_DTPOFF64        equ 17; Offset in module's TLS block
R_X86_64_TPOFF64         equ 18; Offset in initial TLS block
R_X86_64_TLSGD           equ 19; 32 bit signed PC relative to two GOT entries for GD symbol
R_X86_64_TLSLD           equ 20; 32 bit signed PC relative to two GOT entries for LD symbol
R_X86_64_DTPOFF32        equ 21; Offset in TLS block
R_X86_64_GOTTPOFF        equ 22; 32 bit signed PC relative to GOT entry for IE symbol
R_X86_64_TPOFF32         equ 23; Offset in initial TLS block
R_X86_64_PC64            equ 24; PC relative 64 bit
R_X86_64_GOTOFF64        equ 25; 64 bit offset to GOT
R_X86_64_GOTPC32         equ 26; 32 bit signed pc offset to GOT
R_X86_64_GOT64           equ 27; 64-bit GOT entry offset
R_X86_64_GOTPCREL64      equ 28; 64-bit PC relative to GOT entry
R_X86_64_GOTPC64         equ 29; 64-bit PC relative offset to GOT
R_X86_64_GOTPLT64        equ 30; like GOT64, says PLT entry needed
R_X86_64_PLTOFF64        equ 31; 64-bit GOT relative to PLT entry
R_X86_64_SIZE32          equ 32; Size of symbol plus 32-bit addend
R_X86_64_SIZE64          equ 33; Size of symbol plus 64-bit addend
R_X86_64_GOTPC32_TLSDESC equ 34; GOT offset for TLS descriptor
R_X86_64_TLSDESC_CALL    equ 35; Marker for call through descriptor
R_X86_64_TLSDESC         equ 36; TLS descriptor
R_X86_64_IRELATIVE       equ 37; Adjust indirectly by program base
R_X86_64_RELATIVE64      equ 38; 64-bit adjust by program base
;39 Reserved was R_X86_64_PC32_BND,
;40 Reserved was R_X86_64_PLT32_BND
R_X86_64_GOTPCRELX     equ 41;Load from 32 bit signed pc offset to GOT entry without REX prefix, relaxable
R_X86_64_REX_GOTPCRELX equ 42;Load from 32 bit signed pc offset to GOT entry with REX prefix, relaxable
R_X86_64_NUM           equ 43

ELF_HEADER_SIZE equ 64
E_type      equ 16; Object file type
E_machine   equ 18; Architecture
E_version   equ 20; Object file version
E_entry     equ 24; Entry point virtual address
E_phoff     equ 32; Program header table file offset
E_shoff     equ 40; Section header table file offset
E_flags     equ 48; Processor-specific flags
E_ehsize    equ 52; ELF header size in bytes
E_phentsize equ 54; Program header table entry size
E_phnum     equ 56; Program header table entry count
E_shentsize equ 58; Section header table entry size
E_shnum     equ 60; Section header table entry count
E_shstrndx  equ 62; Section header string table index

PROG_HEADER_SIZE equ 56
P_type   equ 0;  Segment type
P_flags  equ 4;  Segment flags
P_offset equ 8;  Segment file offset
P_vaddr  equ 16; Segment virtual address
P_paddr  equ 24; Segment physical address
P_filesz equ 32; Segment size in file
P_memsz  equ 40; Segment size in memory
P_align  equ 48; Segment alignment

SECTION_HEADER_SIZE equ 64
SH_name      equ 0;  Section name (string tbl index)
SH_type      equ 4;  Section type 
SH_flags     equ 8;  Section flags
SH_addr      equ 16; Section virtual addr at execution
SH_offset    equ 24; Section file offset
SH_size      equ 32; Section size in bytes
SH_link      equ 40; Link to another section
SH_info      equ 44; Additional section information
SH_addralign equ 48; Section alignment
SH_entsize   equ 56; Entry size if section holds table

SYM64_TABLE_ENTRY_SIZE equ 24
ST_name  equ 0; Symbol name (string tbl index)
ST_info  equ 4; Symbol type and binding
ST_other equ 5; Symbol visibility
ST_shndx equ 6; Section index
ST_value equ 8; Symbol value
ST_size  equ 16; Symbol size

RELA64_ENTRY_SIZE equ 24
RA64_offset equ 0
RA64_info   equ 8
RA64_addend equ 16

SYMTAB_BUILD_ENTRY_SIZE equ 32; SYM64_TABLE_ENTRY_SIZE + ptr 
segment readable executable

render_patch_delayed_ref:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    lea rsi, [DELAYED_PATCH_ARR]
    mov ecx, [rsi+8]
    mov eax, ADDR_ARR_PATCH_ENTRY_SIZE
    mul ecx
    mov rdx, [rsi]
    mov rdi, rdx
    add rdi, rax
    mov [rbp-8], rdx
    mov [rbp-16], rdi
    mov rbx, qword [SEG_ENTRY_ARRAY]
    ;mov [rbp-24], rbx
_loop_patch_rpdr:
    cmp rdx, rdi
    je _end_render_patch_delayed_ref
    mov rsi, [rdx]
    mov eax, [rsi+16]; sym seg offset
    lea rcx, [rbx+rax]
    mov r8d, [rcx+52]
    mov [rbp-28], r8d
    mov eax, [rsi+20]; sym token buff offset
    mov rdi, [rcx]; ptr to token buf
    mov r11d, [rdi+rax]; ref sym offset in render buff
    add [rbp-28], r11d
    mov rsi, [rdx+8]
    mov eax, [rdx+20]
    lea rcx, [rbx+rax]
    mov rdi, [rcx+20]; ptr to render buf
    mov r8d, [rdx+16]
    mov r9d, [rsi]; ins / data start offset in render buf
    ;TODO: check if it exec, obj or bin mod
    mov al, [rdx+24]
    cmp al, ADDR_PATCH_TYPE_DEF_RIP
    je __rip_patch_rpdr
    cmp al, ADDR_PATCH_TYPE_ABS
    jne _err_invalid_type_rpdr 
__abs4_patch_rpdr:
    add r9d, r8d
    mov eax, [DEF_BASE_ADDR]
    ;mov ecx, [rbp-28]
    ;add rax, rcx
    mov eax, [rbp-28]
    mov r10b, [rdx+25] 
    cmp r10b, 4
    jne __abs8_patch_rpdr
    add [rdi+r9], eax
    jmp _next_patch_rpdr
__abs8_patch_rpdr:
    add [rdi+r9], rax
    jmp _next_patch_rpdr
__rip_patch_rpdr:
    ;NOTE: rip ref is used only in instruction
    movzx eax, byte [rsi+7]
    add eax, r9d
    add eax, [rcx+52]
    mov ecx, [rbp-28]
    sub ecx, eax
    add r9d, r8d
    add [rdi+r9], ecx
_next_patch_rpdr:
    add rdx, ADDR_ARR_PATCH_ENTRY_SIZE
    mov rdi, [rbp-16]
    jmp _loop_patch_rpdr
_err_invalid_type_rpdr:
_end_render_patch_delayed_ref:
    add rsp, 64
    pop rbp
    ret

; -8 8, -16 8, -24 8, -28 4, -32 4, -40 8, -48 8
; return eax - count of .rela sec.
render_set_rela_entry:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    xor rbx, rbx
    mov [rbp-32], rbx
    lea rsi, [RELOC_PATCH_ARR]
    mov ecx, [rsi+8]
    mov eax, ADDR_ARR_PATCH_ENTRY_SIZE
    mul ecx
    mov rdx, [rsi]
    mov r8, rdx
    add r8, rax
    mov [rbp-8], rdx
    mov [rbp-16], r8
    mov rbx, qword [SEG_ENTRY_ARRAY]
    mov [rbp-24], rbx
_loop_set_rsre:
    cmp rdx, r8
    je _end_loop_set_rsre
    mov eax, [rdx+20]
    mov ecx, [rbp-28]
    cmp eax, ecx
    je __skip_set_rela_arr
    mov ebx, KW_SEC_RELA
    mov ecx, SEG_ENTRY_SIZE
    and ebx, SEC_INDEX_MASK
    imul ebx, ecx
    mov [rbp-28], eax
    add eax, ebx
    mov rcx, [SEG_ENTRY_ARRAY]
    lea rdi, [rcx+rax+20]
    mov [rbp-40], rdi
    inc dword [rbp-32]
__skip_set_rela_arr:
    mov [rbp-8], rdx
    mov rdi, [rbp-40]
    mov esi, RELA64_ENTRY_SIZE
    call entry_array_reserve_size
    mov [rbp-48], rax
    mov rsi, rax
    mov rbx, [rbp-24]
    mov rdx, [rbp-8]
    mov r15, [rdx]
    mov eax, [r15+16]; sym seg offset
    lea rcx, [rbx+rax]
    mov eax, [r15+20]; sym token buff offset
    mov rdi, [rcx]; ptr to token buf
    ;mov r11d, [rdi+rax]; ref sym offset in render buff
    mov r14, [rdx+8]
    mov eax, [rdx+20]
    lea rcx, [rbx+rax]
    mov rdi, [rcx+20]; ptr to render buf
    mov r8d, [rdx+16]
    mov r9d, [r14]; ins / data start offset in render buf
    movzx r11d, word [r15+24]
    shl r11, 32
    xor ebx, ebx
    mov al, [rdx+24]
    and al, ADDR_PATCH_TYPE_MAIN_MASK
    cmp al, ADDR_PATCH_TYPE_DEF_RIP
    je _rip_patch_rsre
    cmp al, ADDR_PATCH_TYPE_ABS
    jne _err_invalid_type_rsre
__abs8_patch_rsre:
    mov r10b, [rdx+25] 
    cmp r10b, 8
    jne _err_abs8_patch_rsre
    add r9d, r8d
    movsxd r10, dword [rdi+r9]
    mov [rdi+r9], ebx
    or r11, R_X86_64_64 
    mov [rsi+RA64_offset], r9
    mov [rsi+RA64_info], r11 
    mov [rsi+RA64_addend], r10
    jmp _next_patch_rsre
_rip_patch_rsre:
    movzx eax, byte [r14+7]
    add r9d, r8d
    sub r8d, eax
    movsxd r10, dword [rdi+r9]
    movsxd r8, r8d
    add r10, r8
    mov [rdi+r9], ebx
    or r11, R_X86_64_PC32 
    mov [rsi+RA64_offset], r9
    mov [rsi+RA64_info], r11 
    mov [rsi+RA64_addend], r10
_next_patch_rsre:
    add rdx, ADDR_ARR_PATCH_ENTRY_SIZE
    mov r8, [rbp-16]
    jmp _loop_set_rsre
_end_loop_set_rsre:
_err_abs8_patch_rsre:
_err_invalid_type_rsre:
_end_render_set_rela_entry:
    mov eax, [rbp-32]
    add rsp, 64
    pop rbp
    ret

; -8 8, -12 4, -16 4, -24 8, -32 8, -40 8, -44 4, -56 8, -60 4
; rdi - ptr to arr of ptr to seg, esi - count of elements
build_exe_set_main_info:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-24], rdi
    mov [rbp-16], esi
    mov dword [rbp-12], ELF_HEADER_SIZE
    mov eax, [DEF_BASE_ADDR]
    mov [rbp-44], eax
    lea rdi, [BUILD_ARR]
    mov esi, ELF_HEADER_SIZE
    call entry_array_reserve_size
    mov [rbp-8], rax
    mov rdx, rax
    mov rdi, rax
    xor eax, eax
    mov [rbp-60], eax
    mov ecx, ELF_HEADER_SIZE
    rep stosb
    mov rbx, 0x00010102464C457F
    mov [rdx], rbx
    xor r9, r9
    mov qword [rdx+8], r9
    mov word [rdx+E_type], ET_EXEC
    mov word [rdx+E_machine], EM_X86_64
    mov dword [rdx+E_version], 1
    mov qword [rdx+E_phoff], ELF_HEADER_SIZE
    mov word [rdx+E_ehsize], ELF_HEADER_SIZE
    mov word [rdx+E_phentsize], PROG_HEADER_SIZE
    mov word [rdx+E_shentsize], r9w
    mov eax, [rbp-16]
    mov rcx, [rbp-8]
    mov word [rcx+E_phnum], ax
    mov edx, eax
    shl eax, 3
    add rax, [rbp-24]
    mov [rbp-32], rax
    mov eax, PROG_HEADER_SIZE 
    mul edx
    mov esi, eax
    add [rbp-12], eax
    lea rdi, [BUILD_ARR]
    call entry_array_reserve_size
    mov [rbp-56], rax
    mov r10, [rbp-24]
    mov r14, [rbp-32]
_start_loop_build_exe_seg:
    cmp r10, r14
    je _end_build_exe_set_main_info 
    mov rdi, [r10]
    mov esi, [rdi+28]
    xor r9, r9
    mov [rbp-40], rdi
    mov [rax+P_paddr], r9d
    mov qword [rax+P_align], 4096
    mov dword [rax+P_type], PT_LOAD
    mov bx, [rdi+48]
    mov [rax+P_flags], bx
    mov [rax+P_filesz], esi
    mov ecx, [rbp-12]
    add [rbp-12], esi
    mov [rax+P_offset], rcx
    add ecx, [rbp-60]
    add ecx, [rbp-44]
    mov [rdi+52], ecx
    mov [rax+P_vaddr], rcx
    mov [rbp-8], ecx
    mov edi, ecx
    add edi, esi
    mov esi, 4096
    call align_to_pow2
    mov ebx, eax
    mov ecx, [rbp-8]
    shr ecx, 12
    shr ebx, 12
    sub ebx, ecx
    shl ebx, 12
    mov rdi, [rbp-40]
    mov rax, [rbp-56]
    mov [rdi+56], ebx
    mov [rax+P_memsz], ebx
    add [rbp-60], ebx
    add rax, PROG_HEADER_SIZE
    mov [rbp-56], rax
    add r10, 8
    mov [rbp-24], r10
    jmp _start_loop_build_exe_seg
_end_build_exe_set_main_info:
    add rsp, 64
    pop rbp
    ret

; rdi - ptr to entry sym, 
build_executable:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-64], rdi
    mov rdi, TEMP_COMMON_ARR
    mov esi, 64
    call entry_array_ensure_free_space
    mov [rbp-8], rax
    mov rdi, rax
    call render_set_collate_seg_ptr
    mov [rbp-12], eax
    mov rdi, [rbp-8]
    mov esi, eax
    call build_exe_set_main_info
    call render_patch_delayed_ref
    mov r10, [rbp-8]
    mov r14d, [rbp-12]
    shl r14d, 3
    add r14, r10
    mov [rbp-24], r14
_start_loop_copy_seg_be:
    cmp r10, r14
    je _end_loop_copy_seg_be 
    mov rdi, [r10]
    mov esi, [rdi+28]
    lea rdi, [BUILD_ARR]
    call entry_array_reserve_size
    mov rdi, rax
    mov r10, [rbp-8]
    mov rdx, [r10]
    mov rsi, [rdx+20]
    mov ecx, [rdx+28]
    rep movsb
    mov r14, [rbp-24]
    add r10, 8
    mov [rbp-8], r10
    jmp _start_loop_copy_seg_be
_end_loop_copy_seg_be:
    mov rdi, [rbp-64]
    mov eax, [rdi+32]
    mov ebx, [rdi+36]
    add rax, [SEG_ENTRY_ARRAY]
    add rbx, [rax]
    mov r11d, [rbp-44]
    add r11d, [rax+52]
    add r11d, [rbx]
    mov rsi, [BUILD_ARR]
    mov [rsi+E_entry], r11
_end_build_executable:
    add rsp, 64
    pop rbp
    ret

; -8 8, -16 8, -40 8, -48 8, -63 1
; rdi - ptr to temp arr for sections headers, rsi - shstrtab ptr to entry array
; return eax - count of written sec
set_user_def_sec_obj_file:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-16], rdi
    mov [rbp-40], rsi
    mov esi, SECTION_HEADER_SIZE
    call entry_array_reserve_size
    mov rdi, [rbp-40]
    mov esi, 1
    call entry_array_reserve_size
    mov byte [rbp-63], 1
    lea rdi, [BUILD_ARR]
    mov esi, ELF_HEADER_SIZE
    call entry_array_reserve_size
    mov [rbp-8], rax
    mov rdx, rax
    mov rdi, rax
    xor eax, eax
    mov ecx, ELF_HEADER_SIZE
    rep stosb
    mov rbx, 0x00010102464C457F
    mov [rdx], rbx
    xor r9, r9
    mov qword [rdx+8], r9
    mov word [rdx+E_type], ET_REL
    mov word [rdx+E_machine], EM_X86_64
    mov dword [rdx+E_version], 1
    mov word [rdx+E_ehsize], ELF_HEADER_SIZE
    mov word [rdx+E_shentsize], SECTION_HEADER_SIZE
    mov rdx, [SEG_ENTRY_ARRAY]
    mov r8d, KW_SEC_RELA
    mov ecx, SEG_ENTRY_SIZE
    and r8d, SEC_INDEX_MASK
    imul r8d, ecx
    add r8, rdx
    mov [rbp-24], rdx
    mov [rbp-32], r8
_start_loop_dsof:
    cmp rdx, r8
    je _end_loop_dsof
    mov rax, [rdx+40]
    test rax, rax
    jz _next_loop_dsof
    mov ecx, [rdx+28]
    test ecx, ecx
    jz _next_loop_dsof
    mov [rbp-24], rdx
    mov rdi, [rbp-16]
    mov esi, SECTION_HEADER_SIZE
    call entry_array_reserve_size
    mov [rbp-48], rax
    mov rdx, [rbp-24]
    mov cl, [rbp-63]
    inc byte [rbp-63]
    mov [rdx+49], cl
    mov rbx, [rdx+40]
    mov rdi, [rbp-40]
    movzx esi, byte [rbx+13]
    inc esi
    call entry_array_reserve_size
    mov r9, [rbp-48]
    mov rdx, [rbp-24]
    mov r10, [rdx+40]
    mov rdi, rax 
    mov rsi, [r10]
    movzx ecx, byte [r10+13]
    rep movsb
    mov byte [rdi], 0
    mov r11d, [r10+8]
    shr r11d, SEC_ATTR_SEC_FLAG_SHIFT
    and r11d, 0x7
    mov [r9+SH_name], ebx
    mov [r9+SH_flags], r11
    lea rdi, [BUILD_ARR]
    mov esi, [rdx+28]
    call entry_array_reserve_size
    mov rdx, [rbp-24]
    mov r9, [rbp-48]
    mov rdi, rax
    mov rsi, [rdx+20]
    mov ecx, [rdx+28]
    mov dword [r9+SH_type], SHT_PROGBITS
    mov [r9+SH_offset], rbx
    mov [r9+SH_size], rcx
    rep movsb
    mov r8, [rbp-32]
_next_loop_dsof:
    add rdx, SEG_ENTRY_SIZE
    jmp _start_loop_dsof
_end_loop_dsof:
_end_set_user_def_sec_obj_file:
    movzx eax, byte [rbp-63]
    add rsp, 64
    pop rbp
    ret

; rdi - ptr to symtab entry array, rsi - ptr to symtab build entry array, edx - offset addend
merge_sym_to_symtab_obj:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-20], edx
    mov rdx, [rsi] 
    mov r8d, [rsi+8]
    mov r9d, r8d
    mov eax, SYMTAB_BUILD_ENTRY_SIZE
    imul r8d, eax
    add r8, rdx
    mov [rbp-32], rdx
    mov [rbp-40], r8
    mov esi, SYM64_TABLE_ENTRY_SIZE 
    imul esi, r9d
    call entry_array_reserve_size
    mov [rbp-48], rax
    mov rdi, rax
    mov rdx, [rbp-32]
    mov r8, [rbp-40]
    mov eax, [rbp-20]
_start_loop_mstso:
    cmp rdx, r8
    je _end_merge_sym_to_symrab_obj
    mov rbx, [rdx+SYM64_TABLE_ENTRY_SIZE]
    add [rbx+40], ax
    mov rsi, rdx
    mov ecx, SYM64_TABLE_ENTRY_SIZE
    rep movsb
    add rdx, SYMTAB_BUILD_ENTRY_SIZE
    jmp _start_loop_mstso
_end_merge_sym_to_symrab_obj:
    add rsp, 64
    pop rbp
    ret

; -20 STB_LOCAL entry_arr, -40 STB_GLOBAL entry_arr, -60 SHN_UNDEF entry_arr
; -72 curr name_sym_arr ptr, -80 end name_sym_arr_ptr, -88 curr symtab entry ptr 
; -96 ptr to .strtab render arr, -100 curr addend for sym num patch,
; -104 first non local sym, -128 passed rdi
; rdi - symtab ptr entry array
; return eax - first non local sym in symtab 
set_symtab_for_obj_file:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov [rbp-128], rdi
    mov edx, SYMTAB_BUILD_ENTRY_SIZE
    xor eax, eax
    lea rdi, [rbp-60]
    mov ecx, 60
    rep stosb
    mov [rbp-44], edx
    mov [rbp-24], edx
    mov [rbp-4], edx
    lea rdi, [rbp-60]
    mov rsi, 128 
    call init_entry_array
    lea rdi, [rbp-40]
    mov rsi, 128 
    call init_entry_array
    lea rdi, [rbp-20]
    mov rsi, 128 
    call init_entry_array
    mov rbx, qword [SEG_ENTRY_ARRAY]
    mov eax, KW_SEC_STRTAB
    and eax, SEC_INDEX_MASK 
    mov ecx, SEG_ENTRY_SIZE
    mul ecx
    lea rdi, [rbx+rax+20]
    mov [rbp-96], rdi
    mov esi, 1
    call entry_array_reserve_size
    lea rdx, [NAME_SYM_REF_ARRAY] 
    mov rsi, [rdx]
    mov r9d, [rdx+8]
    add r9, rsi
    mov [rbp-72], rsi
    mov [rbp-80], r9
_start_loop_set_symtabl_of:
    cmp rsi, r9
    je _end_loop_set_symtabl_of
    mov [rbp-72], rsi
    mov al, [rsi+31] 
    and al, SYM_REF_MASK_REF
    cmp al, SYM_REF_MOD_PUBLIC
    jne _loop_set_st_of_ch_p
    lea rdi, [rbp-40]
    mov byte [rbp-61], STB_GLOBAL
    jmp __set_info_common_ssfof
_loop_set_st_of_ch_p:
    mov cl, [rsi+42]
    test cl, cl
    jz _next_loop_set_symtabl_of
    cmp al, SYM_REF_MOD_EXTRN 
    je __set_undf_sym_ssfof
    lea rdi, [rbp-20]
    mov byte [rbp-61], STB_LOCAL
__set_info_common_ssfof:
    mov [rbp-104], rdi
    mov esi, 1
    call entry_array_reserve_size
    mov [rbp-88], rax
    mov r15, rax
    mov rdi, rax
    xor eax, eax
    mov ecx, SYMTAB_BUILD_ENTRY_SIZE
    rep stosb
    mov rsi, [rbp-72]
    mov bl, [rbp-61] 
    shl bl, 4 
    mov r8d, STT_OBJECT
    mov r10d, STT_FUNC 
    mov r11b, [rsi+30] 
    cmp r11b, TOKEN_NAME_JMP 
    cmove r8d, r10d
    or bl, r8b
    mov [r15+ST_info], bl
    mov [r15+SYM64_TABLE_ENTRY_SIZE], rsi
    mov r14, [rbp-104]
    mov ecx, [r14+8]
    jmp __set_symtab_of_common_val
__set_undf_sym_ssfof:
    lea rdi, [rbp-60]
    mov esi, 1
    call entry_array_reserve_size
    mov [rbp-88], rax
    mov r15, rax
    mov rdi, rax
    xor eax, eax
    mov ecx, SYMTAB_BUILD_ENTRY_SIZE
    rep stosb
    mov rsi, [rbp-72]
    mov bl, STB_GLOBAL
    shl bl, 4 
    mov [r15+ST_info], bl
    mov [r15+SYM64_TABLE_ENTRY_SIZE], rsi
    mov ecx, [rbp-52]
    jmp __set_symtab_of_common_idx
__set_symtab_of_common_val:
    mov r8, qword [SEG_ENTRY_ARRAY]
    mov edi, [rsi+32]
    mov r11d, [rsi+36]
    mov r14, [r8+rdi]
    add r14, r11
    mov ebx, [r14]
    movzx r12d, byte [r8+rdi+49]
    mov [r15+ST_shndx], r12w 
    mov [r15+ST_value], rbx 
__set_symtab_of_common_idx:
    dec ecx
    mov [rsi+40], cx; truncate to 16 bits!
    mov byte [rsi+43], 1
    movzx eax, word [rsi+40]
    mov rdi, [rbp-96]
    movzx esi, byte [rsi+29]
    inc esi
    call entry_array_reserve_size
    mov r8, [rbp-88]
    mov rdx, [rbp-72]
    mov [r8+ST_name], ebx
    mov rdi, rax
    mov rsi, [rdx+16]
    movzx ecx, byte [rdx+29]
    rep movsb
    mov byte [rdi], 0
    mov rsi, rdx
    mov r9, [rbp-80]
_next_loop_set_symtabl_of:
    mov r10d, [rsi]
    add rsi, r10
    jmp _start_loop_set_symtabl_of
_end_loop_set_symtabl_of:
    mov rdi, [rbp-128]
    mov esi, SYM64_TABLE_ENTRY_SIZE
    call entry_array_reserve_size
    mov rdi, [rbp-128] 
    lea rsi, [rbp-20]
    mov edx, 1
    mov eax, [rbp-12]
    inc eax
    mov [rbp-100], eax
    mov [rbp-104], eax
    call merge_sym_to_symtab_obj
    mov rdi, [rbp-128] 
    lea rsi, [rbp-40]
    mov edx, [rbp-100]
    mov eax, [rbp-32]
    add [rbp-100], eax
    call merge_sym_to_symtab_obj
    mov rdi, [rbp-128] 
    lea rsi, [rbp-60]
    mov edx, [rbp-100]
    call merge_sym_to_symtab_obj
_end_set_symtab_for_obj_file:
    lea rdi, [rbp-60]
    call entry_array_dealloc
    lea rdi, [rbp-40]
    call entry_array_dealloc
    lea rdi, [rbp-20]
    call entry_array_dealloc
    mov eax, [rbp-104]
    add rsp, 128
    pop rbp
    ret

; rdi - ptr to temp arr for sections headers, rsi - shstrtab ptr to entry array
; edx - symtab idx
set_rela_sec_for_obj_file:
    push rbp
    mov rbp, rsp
    sub rsp, 128
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-84], edx
    mov ebx, KW_SEC_RELA
    mov ecx, SEG_ENTRY_SIZE
    and ebx, SEC_INDEX_MASK
    imul ebx, ecx
    mov [rbp-60], ebx
    mov rsi, [SEG_ENTRY_ARRAY]
    lea rdx, [rsi+rbx]
    mov [rbp-24], rdx
    mov [rbp-56], rdx
    mov eax, KW_SEC_SYMTAB 
    and eax, SEC_INDEX_MASK
    imul eax, ecx
    lea r8, [rsi+rax]
    mov [rbp-32], r8
_start_loop_srsfof:
    cmp rdx, r8
    je _end_loop_srsfof
    mov eax, [rdx+28]
    test eax, eax
    jz _next_loop_srsfof
    mov [rbp-24], rdx
    mov rdi, [rbp-8]
    mov esi, SECTION_HEADER_SIZE
    call entry_array_reserve_size
    mov [rbp-48], rax
    mov rdx, [rbp-24]
    mov r14, [rbp-56]
    mov rbx, [r14+40]
    movzx esi, byte [rbx+13]
    mov r10d, [rbp-60]
    sub rdx, r10
    mov [rbp-80], rdx
    mov rax, [rdx+40]
    mov [rbp-72], rax 
    add sil, [rax+13] 
    inc esi
    mov rdi, [rbp-16]
    call entry_array_reserve_size
    mov [rbp-64], ebx
    mov rdi, rax
    mov r10, [rbp-56]
    mov rdx, [r10+40]
    mov rsi, [rdx]
    movzx ecx, byte [rdx+13]
    rep movsb
    mov r11, [rbp-72]
    mov rsi, [r11]
    movzx ecx, byte [r11+13]
    rep movsb
    mov byte [rdi], 0
    mov r9, [rbp-48]
    mov dword [r9+SH_flags], SHF_INFO_LINK 
    mov [r9+SH_name], ebx
    mov rdx, [rbp-24]
    lea rdi, [BUILD_ARR]
    mov esi, [rdx+28]
    call entry_array_reserve_size
    mov r15, [rbp-24]
    mov r9, [rbp-48]
    mov rdi, rax
    mov rsi, [r15+20]
    mov ecx, [r15+28]
    mov [r9+SH_size], ecx
    rep movsb
    mov [r9+SH_offset], ebx
    mov dword [r9+SH_type], SHT_RELA
    mov r10d, [rbp-84]
    mov [r9+SH_link], r10d
    mov rax, [rbp-80]
    movzx edx, byte [rax+49]
    mov [r9+SH_info], edx
    mov qword [r9+SH_entsize], RELA64_ENTRY_SIZE
    mov rdx, r15
    mov r8, [rbp-32]
_next_loop_srsfof:
    add rdx, SEG_ENTRY_SIZE
    jmp _start_loop_srsfof
_end_loop_srsfof:
_end_set_rela_sec_for_obj_file:
    add rsp, 128
    pop rbp
    ret

; rdi - ptr to temp arr for sections headers, rsi - shstrtab ptr to entry array,
; rdx - ptr to sec data
; return rax - ptr to sec struct
write_sec_obj_file:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov [rbp-8], rdi
    mov [rbp-16], rsi
    mov [rbp-24], rdx
    mov esi, SECTION_HEADER_SIZE
    call entry_array_reserve_size
    mov [rbp-32], rax
    mov rdx, [rbp-24]
    mov rbx, [rdx+40]
    mov [rbp-40], rbx
    mov rdi, [rbp-16]
    movzx esi, byte [rbx+13]
    inc esi
    call entry_array_reserve_size
    mov r9, [rbp-32]
    mov [r9+SH_name], ebx
    mov rdi, rax
    mov rbx, [rbp-40]
    mov rsi, [rbx]
    movzx ecx, byte [rbx+13]
    rep movsb
    mov byte [rdi], 0
    mov rdx, [rbp-24]
    lea rdi, [BUILD_ARR]
    mov esi, [rdx+28]
    call entry_array_reserve_size
    mov rdx, [rbp-24]
    mov r9, [rbp-32]
    mov rdi, rax
    mov rsi, [rdx+20]
    mov ecx, [rdx+28]
    mov [r9+SH_offset], ebx
    mov [r9+SH_size], ecx
    rep movsb
    mov rax, r9
_end_write_sec_obj_file:
    add rsp, 64
    pop rbp
    ret

build_object_file:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    mov dword [rbp-64], 0
    lea rdi, [TEMP_COMMON_ARR]
    mov [rbp-32], rdi
    mov eax, SECTION_HEADER_SIZE
    mov esi, 48 
    imul esi, eax
    call entry_array_ensure_free_space
    call render_patch_delayed_ref
    mov rbx, qword [SEG_ENTRY_ARRAY]
    mov eax, KW_SEC_SHSTRTAB
    and eax, SEC_INDEX_MASK 
    mov edx, SEG_ENTRY_SIZE
    mul edx
    lea rsi, [rbx+rax+20]
    mov [rbp-8], rsi
    mov rdi, [rbp-32]
    call set_user_def_sec_obj_file
    add [rbp-64], eax
    mov rbx, qword [SEG_ENTRY_ARRAY]
    mov eax, KW_SEC_SYMTAB
    and eax, SEC_INDEX_MASK 
    mov ecx, SEG_ENTRY_SIZE
    mul ecx
    lea rdi, [rbx+rax]
    mov [rbp-16], rdi
    add rdi, 20
    call set_symtab_for_obj_file
    mov [rbp-24], rax
    call render_set_rela_entry
    add eax, [rbp-64]
    mov [rbp-64], eax
    mov edx, eax
    mov rdi, [rbp-32]
    mov rsi, [rbp-8]
    call set_rela_sec_for_obj_file
    mov rdx, [rbp-16]
    mov rdi, [rbp-32]
    mov rsi, [rbp-8]
    call write_sec_obj_file
    mov dword [rax+SH_type], SHT_SYMTAB
    mov ecx, [rbp-64]
    inc ecx
    mov r8d, [rbp-24]
    mov [rax+SH_link], ecx
    mov [rax+SH_info], r8d
    mov qword [rax+SH_entsize], SYM64_TABLE_ENTRY_SIZE
    mov [rbp-64], ecx
    mov rbx, qword [SEG_ENTRY_ARRAY]
    mov eax, KW_SEC_STRTAB
    and eax, SEC_INDEX_MASK 
    mov ecx, SEG_ENTRY_SIZE
    mul ecx
    lea rdx, [rbx+rax]
    mov rdi, [rbp-32]
    mov rsi, [rbp-8]
    call write_sec_obj_file
    inc dword [rbp-64]
    mov dword [rax+SH_type], SHT_STRTAB
    mov rdx, [rbp-8]
    sub rdx, 20
    mov rdi, [rbp-32]
    mov rsi, [rbp-8]
    call write_sec_obj_file
    mov dword [rax+SH_type], SHT_STRTAB
    mov rdi, [BUILD_ARR]
    mov ecx, [rbp-64]
    mov [rdi+E_shstrndx], cx
    inc ecx
    mov [rdi+E_shnum], cx
    mov rax, [rbp-32]
    lea rdi, [BUILD_ARR]
    mov esi, [rax+8]
    call entry_array_reserve_size
    mov rdi, rax
    mov rdx, [BUILD_ARR]
    mov [rdx+E_shoff], rbx
    mov rax, [rbp-32]
    mov rsi, [rax]
    mov ecx, [rax+8]
    rep movsb
_end_build_object_file:
    add rsp, 64
    pop rbp
    ret

build_output_bin:
    push rbp
    call render_patch_delayed_ref
    mov rax, [SEG_ENTRY_ARRAY]
    mov rbx, [rax+20]
    mov esi, [rax+28]
    lea rdi, [BUILD_ARR]
    mov rdx, [rdi]
    push rbx
    push rdx
    push rsi
    call entry_array_reserve_size
    pop rcx
    pop rdi
    pop rsi
    rep movsb
    pop rbp
    ret
