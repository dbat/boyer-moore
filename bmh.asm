.686
.mmx
.model flat, stdcall
option casemap :none
;option prologue:none, epilogue:none

;LOCALS @@

.data
align 16
.radix 16
upcase_table \
    oword 00f0e0d0c0b0a09080706050403020100
    oword 01f1e1d1c1b1a19181716151413121110
    oword 02f2e2d2c2b2a29282726252423222120
    oword 03f3e3d3c3b3a39383736353433323130
    oword 04f4e4d4c4b4a49484746454443424140
    oword 05f5e5d5c5b5a59585756555453525150
    ;dq 06766656463626160, 06f6e6d6c6b6a6968
    ;dq 07776757473727170, 07f7e7d7c7b7a7978
    oword 04f4e4d4c4b4a49484746454443424160
    oword 07f7e7d7c7b5a59585756555453525150
    oword 08f8e8d8c8b8a89888786858483828180
    oword 09f9e9d9c9b9a99989796959493929190
    oword 0afaeadacabaaa9a8a7a6a5a4a3a2a1a0
    oword 0bfbebdbcbbbab9b8b7b6b5b4b3b2b1b0
    oword 0cfcecdcccbcac9c8c7c6c5c4c3c2c1c0
    oword 0dfdedddcdbdad9d8d7d6d5d4d3d2d1d0
    oword 0efeeedecebeae9e8e7e6e5e4e3e2e1e0
    oword 0fffefdfcfbfaf9f8f7f6f5f4f3f2f1f0

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
; returns pointer of sub-string in other binary string, or NULL if not found
; shift_table must already been prepared with init_bmtable
textpos proc data:dword, datasize:dword, text:dword, textlen:dword, shift_table:dword
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
    xor eax, eax
    cmp esi, edx
    jg @@NOTFOUND

@@get_cycle:
    mov edi, text
    mov ecx, textlen
    mov edx, esi ; store pos
    lea edi, [edi + ecx -1]

@@fetch:
    mov al, [esi]
    dec esi
    cmp al, [edi]
    jnz @@shifted
    dec edi
    dec ecx
    jnz @@fetch

@@FOUND: lea eax, [esi + 1]
@@NOTFOUND:
@@DONE:
    pop ebx
    pop edi
    pop esi
    ret
textpos endp

public textpos_nc
; returns pointer of sub-string in other binary string, or NULL if not found
; shift_table must already been prepared with init_bmtable_nocase
textpos_nc proc data:dword, datasize:dword, text:dword, textlen:dword, shift_table:dword
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
    mov al, byte ptr upcase_table[eax]   ; get upcased char
    mov esi, edx                ; restore pos
    mov eax, [ebx + eax*4]
    mov edx, [esp + 4]          ; DATA tail
    add esi, eax                ; lea esi, [edx + eax]

@@bmStart:
    xor eax, eax
    cmp esi, edx
    jg @@NOTFOUND

@@get_cycle:
    mov edi, [esp]      ; text tail
    mov ecx, textlen    ; text len
    mov edx, esi        ; store pos

@@fetch_nc:
    mov al, [esi]
    dec esi
    mov bl, byte ptr upcase_table[eax]
    mov al, [edi]
    dec edi
    cmp bl, byte ptr upcase_table[eax]
    jnz @@shifted
    dec ecx
    jnz @@fetch_nc

@@FOUND: lea eax, [esi + 1]
@@NOTFOUND:
@@DONE:
    add esp, 8
    pop ebx
    pop edi
    pop esi
    ret
textpos_nc endp


public memem
; returns pointer of sub-string in other binary string, or NULL if not found
memem proc data:dword, datasize:dword, text:dword, textlen:dword
    mov edx, datasize
    mov ecx, textlen
    xor eax, eax
    sub edx, ecx
    jl @@Stop

@@Start:
    push esi
    mov esi, data
    push edi
    push ebx
    mov eax, esi
    lea ebx, [edx + esi +1] ; txt-tail

@@shift1:
    mov esi, eax
    xor eax, eax

@@begin:
    cmp esi, ebx
    jg @@notfound
    lea eax, [esi +1]   ; forward-1 pos
    mov ecx, textlen
    mov edi, text

@@fetch:
    mov dl, [esi]
    inc esi
    cmp dl, [edi]
    jnz @@shift1
    inc edi
    dec ecx
    jnz @@fetch
    dec eax  ; rewind-1 pos
    ;jmp @@Done

@@notfound:
    ;xor eax, eax
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
    mov edx, datasize
    mov ecx, textlen
    xor eax, eax            ;
    sub edx, ecx            ; datasize - textlen
    jl @@Stop

@@Start:
    push esi
    mov esi, data
    push edi
    push ebx
    lea ebx, [edx + esi +1] ; last comparable pos
    mov edx, eax            ; zero
    mov eax, esi            ; data
    push ebx                ; savelast comparable pos

@@shift1:
    mov esi, eax
    xor eax, eax

@@begin:
    cmp esi, [esp]
    jg @@notfound
    lea eax, [esi +1]       ; forward-1 pos
    mov ecx, textlen
    mov edi, text

@@fetch:
    mov dl, [esi]
    inc esi
    mov bl, byte ptr upcase_table[edx]
    mov dl, [edi]
    inc edi
    cmp bl, byte ptr upcase_table[edx]
    jnz @@shift1
    dec ecx
    jnz @@fetch
    dec eax; rewind-1 pos
    ;jmp @@Done

@@notfound:
    ;xor eax, eax
@@Done:
    pop ebx
    pop edi
    pop esi
    pop ebx

@@Stop:
   ret
memem_nc endp



END

