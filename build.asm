EM_X86_64 equ 6; AMD x86-64 architecture

;elf type
ET_NONE equ 0; No file type
ET_REL  equ 1; Relocatable file
ET_EXEC equ 2; Executable file
ET_DYN  equ 3; Shared object file
ET_CORE equ 4; Core file

; Legal values for sh_type (section type).
SHT_NULL          equ 0; Section header table entry unused
SHT_PROGBITS      equ 1; Program data
SHT_SYMTAB        equ 2; Symbol table
SHT_STRTAB        equ 3; String table
SHT_RELA          equ 4; Relocation entries with addends
SHT_HASH          equ 5; Symbol hash table
SHT_DYNAMIC       equ 6; Dynamic linking information
SHT_NOTE          equ 7; Notes
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

segment readable executable

build_executable:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    lea rdi, [BUILD_ARR]
    mov esi, 64
    call entry_array_reserve_size
    mov [rbp-8], rax
    mov rbx, 0x00010102464C457F
    mov qword [rax], rbx
    mov qword [rax+8], 0
    add rsp, 64
    pop rbp
    ret
