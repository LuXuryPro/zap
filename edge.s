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
    mov R13, rsi
    mov R14, 0xF
    and R13, R14 ; reminder
    mov R12, rsi
    SAR R12, 4
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
    mov R14, rcx
    mov R13, 0xF
    and R14, R13 ; reminder
    mov R15, rcx
    SAR R15, 4
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

    AND rcx, 0xFF
    AND r8, 0xFF

    mov R14, rdx
    mov R13, 0xF
    and R14, R13 ; reminder
    mov R15, rdx
    SAR R15, 4

    mov r9, r14
    test r14, r14
    jnz .not_sub_one_form_chunks
    dec R15
    mov r9, 16
    .not_sub_one_form_chunks:
    xor R12, R12; i = 0
    dec rsi

    mov rax, rcx
    MOVQ xmm8, rax
    PXOR xmm3, xmm3
    PSHUFB xmm8, xmm3 ; lower limit

    mov rax, r8
    MOVQ xmm9, rax
    PXOR xmm3, xmm3
    PSHUFB xmm9, xmm3; upper limit

    mov rax, 0x7f ; max val 127
    MOVQ xmm10, rax
    PXOR xmm3, xmm3
    PSHUFB xmm10, xmm3

    mov rax, 0x80 ; min val -128
    MOVQ xmm11, rax
    PXOR xmm3, xmm3
    PSHUFB xmm11, xmm3

    mov rax, 0xFF
    MOVQ xmm12, rax
    PXOR xmm3, xmm3
    PSHUFB xmm12, xmm3 ; lower limit

    .for_i_in_rows:
        cmp R12, rsi; i < heigth
        jnb .last_row

        xor R13, R13; j = 0
        .for_j_in_columns:
            cmp R13, R15; j < width
            jnb .reminder

            MOVDQU xmm1, [rdi]; current pixel


            ; ###################################
            ; first remove all values which are less than lower limit
            ; ###################################

            MOVDQA xmm14, xmm8
            PCMPGTB xmm8, xmm1 ; see what values of xmm1 are less than lower
            MOVDQA xmm15, xmm8 ; 1 - when less than
            MOVDQA xmm0, xmm8

            PBLENDVB xmm1, xmm11

            MOVDQA xmm8, xmm14


            ; set all values gt upper limit (r8) to 127 (max val)
            ; prepare vector filled with upper

            MOVDQA xmm4, xmm1 ; save

            PCMPGTB xmm4, xmm9 ; 1 - if bigger than upper limit
            MOVDQA xmm0, xmm4
            PBLENDVB xmm1, xmm10

            ; set zeros in places where we set value to max or we set it to min
            ; to discard this values form further calculations
            POR xmm15, xmm4
            PXOR xmm15, xmm12

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
            PAND xmm5, xmm15
            PADDSB xmm7, xmm5

            MOVDQU xmm3, [rdi+rdx]; x+1 y
            PCMPGTB xmm3, xmm1
            xor rax, rax
            mov rax, 10
            MOVQ xmm5, rax
            PXOR xmm6, xmm6
            PSHUFB xmm5, xmm6

            PAND xmm5, xmm3
            PAND xmm5, xmm15
            PADDSB xmm7, xmm5

            MOVDQU xmm4, [rdi+1]; x y+1
            PCMPGTB xmm4, xmm1
            xor rax, rax
            mov rax, 10
            MOVQ xmm5, rax
            PXOR xmm6, xmm6
            PSHUFB xmm5, xmm6

            PAND xmm5, xmm4
            PAND xmm5, xmm15
            PADDSB xmm7, xmm5
            ;%endif

            ; save 16 pixels
            MOVDQU [rdi], xmm1

            add R13, 1; move to next 16 pixels
            add rdi, 16
            jmp .for_j_in_columns
            .reminder:
                ;lower = rcx
                ;upper = r8
                mov R13, r9
                xor R14, R14; i = 0
                mov rbx, r8
                .for_i_in_reminder:
                    cmp R14, R13, ; i < reminder
                    jnb .exit_inner_loop
                    MOV al, [rdi]
                    cmp cl,al
                    jl .no_zeroing
                    mov al, 0x80
                    jmp .endt
                    .no_zeroing:
                    cmp bl,al
                    jg .no_max
                    mov al,0x7F
                    .no_max:
                    .endt:
                    MOV [rdi], al
                    inc rdi
                    inc R14
                    jmp .for_i_in_reminder
        .exit_inner_loop:
        inc R12
        jmp .for_i_in_rows
        .last_row:
            xor R13, R13; j = 0
            .last_row_for_j_in_columns:
                cmp R13, R15; j < width
                jnb .last_reminder
                NEG rdx
                MOVDQU xmm1, [rdi+ rdx]; current pixel
                NEG rdx
                MOVDQU [rdi], xmm1; current pixel
                add rdi, 16
                inc R13
                jmp .last_row_for_j_in_columns
            .last_reminder:
                    mov R13, r9
                    xor R14, R14; i = 0
                    .last_reminder_for_i_in_reminder:
                        cmp R14, R13, ; i < reminder
                        jnb .exit
                        NEG rdx
                        MOV al, [rdi+ rdx]
                        NEG rdx
                        MOV [rdi], al
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

    mov R14, rcx
    mov R13, 0xF
    and R14, R13 ; reminder
    mov R15, rcx
    SAR R15, 4

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
