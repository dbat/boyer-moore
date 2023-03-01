# boyer-moore

Boyer-moore-horspool library in x86 asm (function name may be changed later) for fast searching arbitrary/binary string.
Also including simple search: memem and memem_nc for case insensitive

    init_bmtable proc text:dword, textlen:dword, shift_table:dword
    ; initialize shit_table array[256] of integer

    init_bmtable_nc proc text:dword, textlen:dword, shift_table_nc:dword
    ; initialize shit_table array[256] of integer for insensitive case search
    
    
    textpos proc data:dword, datasize:dword, text:dword, textlen:dword, shift_table:dword
    ; returns position (0-based) of sub-string in other binary string
    ; shift_table must already been prepared with init_bmtable

    textpos_nc proc data:dword, datasize:dword, text:dword, textlen:dword, shift_table:dword
    ; returns position (0-based) of sub-string in other binary string
    ; shift_table must already been prepared with init_bmtable_nocase


    memem proc data:dword, datasize:dword, text:dword, textlen:dword
    ; returns pointer of sub-string in other binary string, or NULL if not found

    memem_nc proc data:dword, datasize:dword, text:dword, textlen:dword
    ; returns pointer of sub-string in other binary string, or NULL if not found
    ; insensitive case search
