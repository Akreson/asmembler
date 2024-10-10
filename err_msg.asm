segment readable

ERR_HEADER_STR db "(ERR) ", 0

ERR_MMAP_FAILED db "mmap have failed", 0
ERR_MUNMAP_FAILED db "munmap have failed", 0

ERR_INVALID_HASH db "Invalid hash for: ", 0
ERR_ADD_HT db "Error on adding entry to hash table", 0

ERR_PRINT_BASE db "Unsupported base for print_digit", 0
ERR_DBL_DEF_SYM db "Doubled default symbol: ", 0

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

; PARSER
ERR_SEG_INV_DEF db "Invalid definition of segment", 0
ERR_INV_EXP db "Invalid expresion", 0
ERR_SEGMENT_NOT_SET db "No segment have been set", 0
ERR_STATIC_DIGIT_OVERFLOW db "Digit overlfow on data definition", 0
ERR_INV_CONST_DEF db "Invalid constant definition", 0
ERR_DEF_SYM db "Symbol already have been defined", 0
ERR_INV_ADDR db "Invalid addres expresion", 0
