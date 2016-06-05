bits 64
global roberts_cross_assembly
global thresholding
global blur_assembly
global fill_with_zero

section .data

zero_vector: times 16 db 0x00
signed_conversion: times 16 db 0x80

section .text

;source = rdi
;size = rsi
fill_with_zero:
    push RBP
    push rbx
    push R12
    push R13
    push R14
    push R15
    mov rax, rsi
    mov R15, 16
    mov RDX, 0
    div R15
    mov R12, rax ; number of chunks
    mov R13, rdx ; reminder
    xor R14, R14; i = 0
    PXOR xmm1, xmm1
    .for_i_in_chunks:
        cmp R14, R12, ; i < numer_of_chunks
        jnb .reminder
        MOVDQA [rdi], xmm1; current chunk
        add rdi, 16
        inc R14
        jmp .for_i_in_chunks
    .reminder:
        xor R14, R14; i = 0
        xor rax,rax
        .for_i_in_reminder:
            cmp R14, R13, ; i < reminder
            jnb .exit
            MOV [rdi], al; current chunk
            inc rdi
            inc R14
            jmp .for_i_in_reminder
    .exit:
        pop R15
        pop R14
        pop R13
        pop R12
        pop rbx
        pop rbp
        ret


;source = rdi
;dest = rsi
;heigth = rdx
;width = rcx
roberts_cross_assembly:
    push RBP
    push rbx
    push R12
    push R13
    push R14
    push R15
    mov rax, rcx
    mov R15, 16
    mov R14, RDX
    mov RDX, 0
    div R15
    mov R15, rax ; number of chunks in row
    xchg R14, rdx ; reminder in row
    mov r9, r14
    test r14, r14
    jnz .not_sub_one_form_chunks
    dec R15
    mov r9, 16
    .not_sub_one_form_chunks:
    xor R12, R12; i = 0
    dec rdx ; ommit last row
    .for_i_in_rows:
        cmp R12, rdx ; i < heigth
        jnb .exit

        xor R13, R13; j = 0
        .for_j_in_columns:
            cmp R13, R15; j < width
            jnb .reminder

            MOVDQU xmm1, [rdi]; current pixel
            MOVDQU xmm2, [rdi+rcx+1]; x+1 y+1

            PSUBSB xmm1, xmm2
            PABSB xmm1, xmm1

            MOVDQU xmm3, [rdi+rcx]; x+1 y
            MOVDQU xmm4, [rdi+1]; x y+1

            PSUBSB xmm3, xmm4
            PABSB xmm3, xmm3

            PADDSB xmm3, xmm1

            ; save 16 pixels
            MOVDQU [rsi], xmm3

            add R13, 1; move to next chunk
            add rdi, 16
            add rsi, 16
            jmp .for_j_in_columns
            jmp .for_j_in_columns
            .reminder:
                mov R13, r9
                dec R13
                cmp R13, 0
                jle .exit_inner_loop
                xor R14, R14; i = 0
                xor rax, rax
                .for_i_in_reminder:
                    cmp R14, R13, ; i < reminder
                    jnb .exit_inner_loop
                    MOV al, [rdi]
                    SUB al, [rdi + rcx + 1]
                    cmp al,0
                    jg .not_neg
                    neg al
                    .not_neg:
                    MOV bl, [rdi+rcx]
                    sub bl, [rdi + 1]
                    cmp bl,0
                    jg .not_negb
                    neg bl
                    .not_negb:
                    add al,bl
                    MOV [rsi], al
                    inc rdi
                    inc rsi
                    inc R14
                    jmp .for_i_in_reminder
        .exit_inner_loop:
        MOV al, [rsi - 1]
        MOV [rsi], al
        inc rdi
        inc rsi
        inc R12
        jmp .for_i_in_rows
        .last_row:
            xor R13, R13; j = 0
            .last_row_for_j_in_columns:
                cmp R13, R15; j < width
                jnb .last_reminder
                NEG rcx
                MOVDQU xmm1, [rsi + rcx]; current pixel
                NEG rcx
                MOVDQU [rsi], xmm1; current pixel
                add rdi, 16
                add rsi, 16
                inc R13
                jmp .last_row_for_j_in_columns
            .last_reminder:
                    mov R13, r9
                    xor R14, R14; i = 0
                    .last_reminder_for_i_in_reminder:
                        cmp R14, R13, ; i < reminder
                        jnb .exit
                        NEG rcx
                        MOV al, [rsi + rcx]
                        NEG rcx
                        MOV [rsi], al
                        inc rdi
                        inc rsi
                        inc R14
                        jmp .last_reminder_for_i_in_reminder
    .exit:
        pop R15
        pop R14
        pop R13
        pop R12
        pop rbx
        pop rbp
        ret

;source = rdi
;heigth = rsi
;width = rdx
;lower = rcx
;upper = r8
thresholding:
    push RBP
    push rbx
    push R12
    push R13
    push R14
    push R15
    xor R12, R12; i = 0
    .for_i_in_rows:
        cmp R12, rsi; i < heigth
        jnb .exit

        xor R13, R13; j = 0
        .for_j_in_columns:
            cmp R13, rdx; j < width
            jnb .exit_inner_loop

            MOVDQU xmm1, [rdi]; current pixel


            ; ###################################
            ; first remove all values which are less than 20
            ; ###################################
            ;
            ; prepare vector filled with lower byte
            xor rax, rax
            mov rax, rcx
            MOVQ xmm2, rax
            mov rax, 0
            PXOR xmm3, xmm3
            PSHUFB xmm2, xmm3

            MOVDQA xmm4, xmm1 ; save

            PCMPGTB xmm4, xmm2 ; see what values of xmm1 are less than lower
            ; values less than lower are marked by 0 in xmm2
            MOVDQA xmm0, xmm4; save zero mask

            PAND xmm1, xmm4 ; zero out values less than 20 in xmm1


            ; set all values gt upper limit (r8) to 127 (max val)
            ; prepare vector filled with upper
            xor rax, rax
            mov rax, r8
            MOVQ xmm2, rax
            mov rax, 0
            PXOR xmm3, xmm3
            PSHUFB xmm2, xmm3

            MOVDQA xmm4, xmm1 ; save

            PCMPGTB xmm4, xmm2

            POR xmm1, xmm4 ; set values greather than upper to FF
            PANDN xmm4, xmm0
            MOVDQA xmm0, xmm4

            ;%if 0
            MOVDQU xmm7, xmm1 ;save

            MOVDQU xmm2, [rdi+rdx+ 1]; x+1 y+1

            PCMPGTB xmm2, xmm1
            xor rax, rax
            mov rax, 10
            MOVQ xmm5, rax
            PXOR xmm6, xmm6
            PSHUFB xmm5, xmm6

            PAND xmm5, xmm2
            PAND xmm5, xmm0
            PADDSB xmm7, xmm5

            MOVDQU xmm3, [rdi+rdx]; x+1 y
            PCMPGTB xmm3, xmm1
            xor rax, rax
            mov rax, 10
            MOVQ xmm5, rax
            PXOR xmm6, xmm6
            PSHUFB xmm5, xmm6

            PAND xmm5, xmm3
            PAND xmm5, xmm0
            PADDSB xmm7, xmm5

            MOVDQU xmm4, [rdi+1]; x y+1
            PCMPGTB xmm4, xmm1
            xor rax, rax
            mov rax, 10
            MOVQ xmm5, rax
            PXOR xmm6, xmm6
            PSHUFB xmm5, xmm6

            PAND xmm5, xmm4
            PAND xmm5, xmm0
            PADDSB xmm7, xmm5
            ;%endif

            ; save 16 pixels
            MOVDQU [rdi], xmm1

            add R13, 16 ; move to next 16 pixels
            add rdi, 16
            jmp .for_j_in_columns
        .exit_inner_loop:
        sub R13, rdx
        sub rdi, R13
        sub rsi, R13
        inc R12
        jmp .for_i_in_rows
.exit:
    pop R15
    pop R14
    pop R13
    pop R12
    pop rbx
    pop rbp
    ret


;source = rdi
;dest = rsi
;heigth = rdx
;width = rcx
blur_assembly:
    push RBP
    push rbx
    push r9
    push R12
    push R13
    push R14
    push R15

    mov rax, rcx
    mov R15, 16
    mov R14, RDX
    mov RDX, 0
    div R15
    mov R15, rax ; number of chunks in row
    xchg R14, rdx ; reminder in row
    mov r9, r14
    test r14, r14
    jnz .not_sub_one_form_chunks
    dec R15
    mov r9, 16
    .not_sub_one_form_chunks:

    mov rax, 63
    MOVQ xmm6, rax
    PXOR xmm7, xmm7
    PSHUFB xmm6, xmm7 ;00111111

    mov rax, 0x80
    MOVQ xmm5, rax
    PXOR xmm7, xmm7
    PSHUFB xmm5, xmm7 ;10000000

    xor R12, R12; i = 0
    dec rdx
    .for_i_in_rows:
        cmp R12, rdx ; i < heigth
        jnb .last_row

        xor R13, R13; j = 0
        .for_j_in_columns:
            cmp R13, R15; j < width
            jnb .reminder
            PXOR xmm7, xmm7

            MOVDQU xmm1, [rdi]; current pixel
            PXOR xmm1, xmm5
            PSRAW xmm1, 2 ; div by 4
            PAND xmm1, xmm6
            PADDB xmm7, xmm1

            MOVDQU xmm1, [rdi+rcx+ 1]; x+1 y+1
            PXOR xmm1, xmm5
            PSRAW xmm1, 2 ; div by 4
            PAND xmm1, xmm6
            PADDB xmm7, xmm1

            MOVDQU xmm1, [rdi+rcx]; x+1 y
            PXOR xmm1, xmm5
            PSRAW xmm1, 2 ; div by 4
            PAND xmm1, xmm6
            PADDB xmm7, xmm1

            MOVDQU xmm1, [rdi+1]; x y+1
            PXOR xmm1, xmm5
            PSRAW xmm1, 2 ; div by 4
            PAND xmm1, xmm6
            PADDB xmm7, xmm1

            ; save 16 pixels
            PXOR xmm7, xmm5
            MOVDQU [rsi], xmm7

            add R13, 1; move to chunk
            add rdi, 16
            add rsi, 16
            jmp .for_j_in_columns
            .reminder:
                mov R13, r9
                dec R13
                cmp R13,0
                jle .exit_inner_loop
                xor R14, R14; i = 0
                .for_i_in_reminder:
                    cmp R14, R13, ; i < reminder
                    jnb .exit_inner_loop
                    xor rax, rax
                    MOV al, [rdi]
                    xor al, 0x80
                    SHR al,2

                    MOV bl, [rdi + rcx+1]
                    xor bl, 0x80
                    shr bl, 2
                    add al, bl

                    MOV bl, [rdi + rcx]
                    xor bl, 0x80
                    shr bl, 2
                    add al, bl

                    MOV bl, [rdi + 1]
                    xor bl, 0x80
                    shr bl, 2
                    add al, bl

                    xor al, 0x80
                    MOV [rsi], al
                    inc rdi
                    inc rsi
                    inc R14
                    jmp .for_i_in_reminder
        .exit_inner_loop:
        MOV al, [rsi - 1]
        MOV [rsi], al
        inc rdi
        inc rsi
        inc R12
        jmp .for_i_in_rows
    .last_row:
        xor R13, R13; j = 0
        .last_row_for_j_in_columns:
            cmp R13, R15; j < width
            jnb .last_reminder
            NEG rcx
            MOVDQU xmm1, [rsi + rcx]; current pixel
            NEG rcx
            MOVDQU [rsi], xmm1; current pixel
            add rdi, 16
            add rsi, 16
            inc R13
            jmp .last_row_for_j_in_columns
        .last_reminder:
                mov R13, r9
                xor R14, R14; i = 0
                .last_reminder_for_i_in_reminder:
                    cmp R14, R13, ; i < reminder
                    jnb .exit
                    NEG rcx
                    MOV al, [rsi + rcx]
                    NEG rcx
                    MOV [rsi], al
                    inc rdi
                    inc rsi
                    inc R14
                    jmp .last_reminder_for_i_in_reminder

.exit:
    pop R15
    pop R14
    pop R13
    pop R12
    pop r9
    pop rbx
    pop rbp
    ret
