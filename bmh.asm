.686
.mmx
.model flat, stdcall
option casemap :none

;LOCALS @@

.data
align 16
.radix 16

upcase_table \
    db 000, 001, 002, 003, 004, 005, 006, 007, 008, 009, 00a, 00b, 00c, 00d, 00e, 00f
    db 010, 011, 012, 013, 014, 015, 016, 017, 018, 019, 01a, 01b, 01c, 01d, 01e, 01f
    db 020, 021, 022, 023, 024, 025, 026, 027, 028, 029, 02a, 02b, 02c, 02d, 02e, 02f
    db 030, 031, 032, 033, 034, 035, 036, 037, 038, 039, 03a, 03b, 03c, 03d, 03e, 03f
    db 040, 041, 042, 043, 044, 045, 046, 047, 048, 049, 04a, 04b, 04c, 04d, 04e, 04f
    db 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 05a, 05b, 05c, 05d, 05e, 05f

; db 060, 061, 062, 063, 064, 065, 066, 067, 068, 069, 06a, 06b, 06c, 06d, 06e, 06f
; db 070, 071, 072, 073, 074, 075, 076, 077, 078, 079, 07a, 07b, 07c, 07d, 07e, 07f

    db 060, 041, 042, 043, 044, 045, 046, 047, 048, 049, 04a, 04b, 04c, 04d, 04e, 04f
    db 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 05a, 07b, 07c, 07d, 07e, 07f

    db 080, 081, 082, 083, 084, 085, 086, 087, 088, 089, 08a, 08b, 08c, 08d, 08e, 08f
    db 090, 091, 092, 093, 094, 095, 096, 097, 098, 099, 09a, 09b, 09c, 09d, 09e, 09f
    db 0a0, 0a1, 0a2, 0a3, 0a4, 0a5, 0a6, 0a7, 0a8, 0a9, 0aa, 0ab, 0ac, 0ad, 0ae, 0af
    db 0b0, 0b1, 0b2, 0b3, 0b4, 0b5, 0b6, 0b7, 0b8, 0b9, 0ba, 0bb, 0bc, 0bd, 0be, 0bf
    db 0c0, 0c1, 0c2, 0c3, 0c4, 0c5, 0c6, 0c7, 0c8, 0c9, 0ca, 0cb, 0cc, 0cd, 0ce, 0cf
    db 0d0, 0d1, 0d2, 0d3, 0d4, 0d5, 0d6, 0d7, 0d8, 0d9, 0da, 0db, 0dc, 0dd, 0de, 0df
    db 0e0, 0e1, 0e2, 0e3, 0e4, 0e5, 0e6, 0e7, 0e8, 0e9, 0ea, 0eb, 0ec, 0ed, 0ee, 0ef
    db 0f0, 0f1, 0f2, 0f3, 0f4, 0f5, 0f6, 0f7, 0f8, 0f9, 0fa, 0fb, 0fc, 0fd, 0fe, 0ff

.radix 0ah

.code
align 4

public init_bmtable
; initialize shit_table array[256] of integer
init_bmtable proc text:dword, textlen:dword, shift_table:dword
    push edi

    mov edi, shift_table
    mov ecx, text         ;
    mov eax, textlen      ;
    mov edx, ecx          ; text
    mov ecx, 100h
    rep stosd

    lea ecx, [eax -1]     ; len -1
    lea eax, [edi -400h]  ; shift_table rewind
    mov edi, edx          ; text
    mov edx, eax          ; shift_table
    xor eax, eax

@@loop:
    mov al, [edi]         ; curtail
    lea edi, [edi +1]
    mov [edx + eax*4], ecx
    dec ecx
    jg @@loop

    pop edi
    ret
init_bmtable endp

public init_bmtable_nc
; initialize shit_table array[256] of integer for insensitive case search
init_bmtable_nc proc text:dword, textlen:dword, shift_table_nc:dword
    push esi
    push edi

    mov edi, shift_table_nc
    mov ecx, text         ;
    mov eax, textlen      ;
    mov edx, ecx          ; text
    mov ecx, 100h
    rep stosd

    lea ecx, [eax -1]     ; len -1
    lea edi, [edi -400h]  ; shift_table rewind
    mov esi, edx          ; text
    mov edx, offset upcase_table
    xor eax, eax

@@loop:
    mov al, [esi]         ; curtail
    inc esi
    mov al, [edx + eax]
    mov [edi + eax*4], ecx
    dec ecx
    jnz @@loop

    pop edi
    pop esi
    ret
init_bmtable_nc endp


public textpos
; returns position (0-based) of sub-string in other binary string
; shift_table must already been prepared with init_bmtable
textpos proc data:dword, datasize:dword, text:dword, 
  textlen:dword, shift_table:dword
    push esi
    push edi
    push ebx

    mov edx, datasize
    mov esi, data
    mov eax, textlen

    lea edx, [esi + edx -1]
    lea esi, [esi + eax -1]

    mov ebx, shift_table
    mov dword ptr [esp - 4], edx ; tail
    ;// mov edx, esi ; store pos

    jmp @@bmStart

@@shifted:
    mov al, [edx]
    mov esi, edx ; restore pos
    mov eax, [ebx + eax*4]
    mov edx, [esp - 4] ; tail
    add esi, eax ; lea esi, [esi + eax]

@@bmStart:
    cmp esi, edx
    ja @@NOTFOUND

@@get_cycle:
    mov edi, text
    mov ecx, textlen
    mov edx, esi ; store pos
    lea edi, [edi + ecx -1]
    xor eax, eax

@@fetch:
    ;movzx eax, byte ptr [esi]
    mov al, [esi]
    dec esi
    cmp al, [edi]
    jnz @@shifted
    dec edi
    dec ecx
    jnz @@fetch
    ;jmp @@FOUND

@@FOUND:
    lea eax, [esi +1]
    mov edx, data
    jmp @@DONE

@@NOTFOUND:
    lea eax, [edx-1]
    ;jmp @@DONE

@@DONE:
    sub eax, edx
    pop ebx
    pop edi
    pop esi
    ret

textpos endp

public textpos_nc
; returns position (0-based) of sub-string in other binary string
; shift_table must already been prepared with init_bmtable_nocase
textpos_nc proc data:dword, datasize:dword,
  text:dword, textlen:dword, shift_table:dword
    push esi
    push edi
    push ebx

    mov eax, textlen
    mov esi, data
    mov edx, datasize
    mov edi, text

    sub eax, 1            ; textlen -1
    lea edx, [edx+esi-1]  ; data tail

    add esi, eax          ; cmp data offset
    add edi, eax          ; text tail

    push edx              ; 4 data tail
    push edi              ; 0 text tail

    jmp @@bmStart

@@shifted:
    mov al, [edx]

    mov ebx, shift_table
    mov al, upcase_table[eax]   ; get upcased char
    mov esi, edx                ; restore pos
    mov eax, [ebx + eax*4]
    mov edx, [esp + 4]          ; DATA tail
    add esi, eax                ; lea esi, [edx + eax]

@@bmStart:
    cmp esi, edx
    ja @@NOTFOUND

@@get_cycle:
    mov edi, [esp]      ; text tail
    mov ecx, textlen    ; text len
    mov edx, esi        ; store pos
    xor eax, eax

@@fetch_nc:
    mov al, [esi]
    sub esi, 1
    mov bl, upcase_table[eax]
    mov al, [edi]
    sub edi, 1
    cmp bl, upcase_table[eax]
    jnz @@shifted
    dec ecx
    jnz @@fetch_nc
    ;jmp @@FOUND

@@FOUND:
    lea eax, [esi +1]
    mov edx, data
    jmp @@DONE

@@NOTFOUND:
    lea eax, [edx -1]
    ;jmp @@DONE

@@DONE:
    add esp, 8
    sub eax, edx
    pop ebx
    pop edi
    pop esi
    ret

textpos_nc endp


public memem
; returns pointer of sub-string in other binary string, or NULL if not found
memem proc data:dword, datasize:dword, text:dword, textlen:dword
    mov eax, datasize
    mov ecx, textlen
    mov edx, text
    sub eax, ecx
    jnl @@Start
    xor eax, eax
    jmp short @@Stop

@@Start:
    push esi
    mov esi, data
    push edi
    push ebx
    lea ebx, [eax + esi +1] ; txt-tail
    mov eax, esi

@@shift1:
    mov esi, eax

@@begin:
    cmp eax, ebx
    ja @@notfound
    lea eax, [esi +1]   ; forward-1 pos
    mov ecx, textlen
    mov edi, text

@@fetch:
    mov dl, [esi]
    add esi, 1
    cmp dl, [edi]
    jnz @@shift1
    add edi, 1
    sub ecx, 1
    jnz @@fetch
    sub eax, 1  ; rewind-1 pos
    jmp @@Done

@@notfound:
    xor eax, eax
@@Done:
    pop edi
    pop esi
    pop ebx

@@Stop:
   ret
memem endp


public memem_nc
; returns pointer of sub-string in other binary string, or NULL if not found
; insensitive case search
memem_nc proc data:dword, datasize:dword, text:dword, textlen:dword
    mov eax, datasize
    mov ecx, textlen
    mov edx, text
    sub eax, ecx            ; datasize - textlen
    jnl @@Start
    xor eax, eax
    jmp short @@Stop

@@Start:
    push esi
    mov esi, data
    push edi
    push ebx
    lea ebx, [eax + esi +1] ; last comparable pos
    mov eax, esi            ; data
    xor edx, edx            ;
    push ebx                ; savelast comparable pos

@@shift1:
    mov esi, eax

@@begin:
    cmp eax, [esp]
    ja @@notfound
    lea eax, [esi +1]       ; forward-1 pos
    mov ecx, textlen
    mov edi, text

@@fetch:
    mov dl, [esi]
    add esi, 1
    mov bl, upcase_table[edx]
    mov dl, [edi]
    add edi, 1
    cmp bl, upcase_table[edx]
    jnz @@shift1
    sub ecx, 1
    jnz @@fetch
    sub eax, 1  ; rewind-1 pos
    jmp @@Done

@@notfound:
    xor eax, eax
@@Done:
    pop ebx
    pop edi
    pop esi
    pop ebx

@@Stop:
   ret

memem_nc endp



END

