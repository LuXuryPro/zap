    section .text
    global canny

;source = rdi
;dest = rsi
;num = rdx;R15
;den = rcx
;r8 - numer poprzedniego wiersza obrazu zrodlowego
;r9 - numer obecnego wiersza obrazu zrodlowego
;r10 - dest img data
;r11 - src img data
canny:
    push RBP
    push rbx
    push R12
    push R13
    push R14
    push R15
    mov R10, [rsi+16] ;dest img data
    mov R11, [rdi+16] ;src img data
    mov R15, RDX
    mov R8, -1
    xor rbx, rbx
for_i_in_rows:
    mov rax, rcx
    mul rbx
    div R15
    mov R9, rax
    cmp R9, R8
    jg row_change

    mov R14, R10
    mov edx, dword [rsi+8]
    sub R14, RDX
    xor R13, R13
copy_row_next:
    mov eax, dword [R14]
    mov dword [R10], eax
    add R10, 4
    add R14, 4
    add R13, 4
    cmp R13D, [rsi+8]
    jb copy_row_next
    jmp exit

row_change:
    mov R8, R9
    mov R14, R10;dest
    mov R13, R11;src
    xor R12,R12
for_j_in_columns:
    mov rax, rcx
    mul R12
    div R15
    lea rax, [rax+rax*2]
    add rax, R13
    mov eax, dword [RAX]
    mov dword [R14], eax
    add R14, 3
    inc R12
    cmp R12D, dword [rsi]
    jb for_j_in_columns

    mov edx, dword [rdi+8]
    add R11, RDX
    mov edx, dword [rsi+8]
    add R10, RDX
exit:
    inc ebx
    cmp ebx, [rsi+4]
    jb for_i_in_rows

    pop R15
    pop R14
    pop R13
    pop R12
    pop rbx
    pop rbp
    ret
