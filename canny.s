    section .text
    global canny
    global thresholding

;source = rdi
;dest = rsi
;heigth = rdx
;width = rcx
canny:
    push RBP
    push rbx
    push R12
    push R13
    push R14
    push R15
    xor R12, R12; i = 0
    .for_i_in_rows:
        cmp R12, rdx ; i < heigth
        jnb .exit

        xor R13, R13; j = 0
        .for_j_in_columns:
            cmp R13, rcx; j < width
            jnb .exit_inner_loop

            MOVDQU xmm1, [rdi]; current pixel
            MOVDQU xmm2, [rdi+rcx+ 1]; x+1 y+1

            PSUBSB xmm1, xmm2
            PABSB xmm1, xmm1

            MOVDQU xmm3, [rdi+rcx]; x+1 y
            MOVDQU xmm4, [rdi+1]; x y+1
            PSUBSB xmm3, xmm4
            PABSB xmm3, xmm3

            PADDSB xmm3, xmm1

            ; save 16 pixels
            MOVDQU [rsi], xmm3

            add R13, 16 ; move to next 16 pixels
            add rdi, 16
            add rsi, 16
            jmp .for_j_in_columns
        .exit_inner_loop:
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

thresholding:
    push RBP
    push rbx
    push R12
    push R13
    push R14
    push R15
    xor R12, R12; i = 0
    .for_i_in_rows:
        cmp R12, rdx ; i < heigth
        jnb .exit

        xor R13, R13; j = 0
        .for_j_in_columns:
            cmp R13, rcx; j < width
            jnb .exit_inner_loop

            MOVDQU xmm1, [rdi]; current pixel


            ; ###################################
            ; first remove all values which are less than 20
            ; ###################################
            ;
            ; prepare vector filled with BYTE 20
            xor rax, rax
            mov rax, 10
            MOVQ xmm2, rax
            mov rax, 0
            PXOR xmm3, xmm3
            PSHUFB xmm2, xmm3

            MOVDQU xmm4, xmm1 ; save

            PCMPGTB xmm4, xmm2 ; see what values of xmm1 are less than 20
            ; values less than 20 are marked by 0 in xmm2

            PAND xmm1, xmm4 ; zero out values less than 20 in xmm1


            ; set all values gt 150 to 255 (max val)
            ; prepare vector filled with 150
            xor rax, rax
            mov rax, 80
            MOVQ xmm2, rax
            mov rax, 0
            PXOR xmm3, xmm3
            PSHUFB xmm2, xmm3

            MOVDQU xmm4, xmm1 ; save

            PCMPGTB xmm4, xmm2

            POR xmm1, xmm4

            ; save 16 pixels
            MOVDQU [rdi], xmm1

            add R13, 16 ; move to next 16 pixels
            add rdi, 16
            jmp .for_j_in_columns
        .exit_inner_loop:
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
