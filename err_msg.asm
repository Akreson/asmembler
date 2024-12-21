segment readable

ERR_HEADER_STR db "(ERR) ", 0

ERR_MMAP_FAILED db "mmap have failed", 0
ERR_MUNMAP_FAILED db "munmap have failed", 0

ERR_INVALID_HASH db "Invalid hash for: ", 0
ERR_ADD_HT db "Error on adding entry to hash table", 0

ERR_PRINT_BASE db "Unsupported base for print_digit", 0
ERR_DBL_DEF_SYM db "Doubled default symbol: ", 0

ERR_PROCESSED_STR db "Processed line ", 0
ERR_PROCESSED_FROM_STR db "Processed from - ", 0
ERR_CALLED_FROM_STR db "Called from - ", 0

; FILE
ERR_NOT_A_FILE db ": is not a regular file", 0
ERR_FILE_MISS db ": unable to get info about file", 0
ERR_ACCES_DENIED db ": access denied", 0
ERR_ERROR_ACCESS db ": error on access file", 0
ERR_READ_ERR db ": error during file reading", 0
ERR_ALREADY_INCLUDED db ": already included", 0

; LEXER
ERR_LEXER_TO_LONG_NAME db "Name is to long, max. is 255 bytes", 10, 0
ERR_LEXER_NUM_TO_BIG db "Number overflow 64-bit reg", 10, 0
ERR_LEXER_NUMBER_FORMAT db "Invalid digit format", 10, 0
ERR_LEXER_NUMBER_ORDER db "Invalid symbol for choosen base of digit", 10, 0
ERR_LEXER_INVALID_CHAR db "Unsupported char", 10, 0
ERR_LEXER_STR_PARSE db "Unable to parse string", 0

; PARSER
ERR_SEG_INV_DEF db "Invalid definition of segment", 0
ERR_INV_EXP db "Invalid expresion", 0
ERR_SEGMENT_NOT_SET db "No segment have been set", 0
ERR_STATIC_DIGIT_OVERFLOW db "Digit overlfow on data definition", 0
ERR_INV_CONST_DEF db "Invalid constant definition", 0
ERR_DEF_SYM db "Symbol already have been defined", 0
ERR_INV_ADDR db "Invalid address expresion", 0
ERR_MACRO_ARG_REP db "Double declaration of a macro arg", 0
ERR_MACRO_TM_ARG db "To many args for macro", 0
ERR_MACRO_FORBID_CMD db "Forbided command in macro body", 0
ERR_DATA_SYM_REF db "Unsupported sym type in data def", 0
ERR_UNDEF_SYM db "Undefined symbol", 0
ERR_SYM_HAS_MOD db "Symbol already has ref. mod. type", 0
ERR_SYM_EXT_DEF db "Symbol already has benn defined as external", 0
ERR_SYM_EXT_ALR_DEF db "Symbol already has been defined and can't be external", 0
ERR_SYM_PUB_TYPE db "Symbol can't be referenced as global in executable", 0
ERR_DUBL_ENTRY db "Entry symbol already have been defined", 0
ERR_SEG_IN_N_EXE db "Segment can't be declared in non executable file type", 0

; RENDER
ERR_INS_UNSUPPORT db "Instruction is unsupported"
ERR_EXP_UNSUPPORT db "Unsupported expression", 0
ERR_INS_FORMAT db "Invalid instruction format", 0
ERR_IMM_OVERFLOW db "imm value to big for selected dest", 0
ERR_IMM_NAME_REF db "Unsupported name ref for imm value", 0
ERR_DATA_NAME_REF db "Saving name ref. in data def. allowed only in 8 bytes chunk", 0
ERR_INV_ADDR_SCALE db "Invalid scale index in address ref", 0
ERR_INV_2ND_ADDR_PARAM db "Invalid 2nd parameter in address ref", 0
ERR_INV_2ND_ADDR_SUB db "2nd address parameter can't be subtracted", 0
ERR_ADDR_REG_SIZE db "Unsopported reg size in address parameters", 0
ERR_INV_1ST_ADDR_PARAM db "Invalid 1st parameter in address ref", 0
ERR_INV_NAME_REF_ADDR db "Invalid name ref address field", 0
ERR_INV_ADDR_LAST_NAME db "Invalid last name ref in address field", 0
ERR_ADDR_SIZE_QUAL db "Size qualifier must be spesicied for address ref", 0
ERR_INV_ADDR_ARGC db "Invalid amount of parameters for address field", 0

ERR_INS_INV_1ST_PARAM db "Invalid 1st parameter of instruction", 0
ERR_INS_INV_2ND_PARAM db "Invalid 2nd parameter of instruction", 0
ERR_INS_INV_ARGC db "Invalid amount of parameters for this instruction", 0
ERR_INS_INV_ARGS_SIZE db "Arguments size must be the same", 0
ERR_INS_INV_ARG_SIZE db "Invalid argument size", 0
ERR_INS_INV_RIP_REF db "Invalid rip ref. is used", 0
ERR_INS_INV_REG_SIZE db "Invalid reg size", 0
ERR_INS_INV_PARAM db "Invalid parameter is used", 0
ERR_INS_REG_IMM_OVERFLOW db "imm parameter to big", 0
