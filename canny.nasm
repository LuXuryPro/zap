    section .text
    global canny

extern	printf
fmt:    db "i=%d j=%d", 10, 0

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
    for_i_in_rows:
        cmp R12, rdx ; i < heigth
        jnb exit

        xor R13, R13; j = 0
        for_j_in_columns:
            cmp R13, rcx; j < width
            jnb exit_inner_loop

            ; calculate current pixel address
            mov rax, rcx ; rax <= width
            push rdx
            imul R12 ; rax <= i * width
            pop rdx
            add rax, R13 ; i * width + j
            xor R15, R15
            add R15, rdi
            add R15, rax
            MOVDQU xmm1, [R15]; current pixel
            MOVDQU xmm2, [R15+rcx+ 1]; current pixel

            PSUBSB xmm1, xmm2
            PABSB xmm1, xmm1

            MOVDQU xmm3, [R15+rcx]; x+1 y
            MOVDQU xmm4, [R15+1]; x y+1
            PSUBSB xmm3, xmm4
            PABSB xmm3, xmm3

            PADDSB xmm3, xmm1

            ; save 16 pixels
            MOVDQU [rsi + rax], xmm3

            add R13, 16 ; move to next 16 pixels
            jmp for_j_in_columns
        exit_inner_loop:
        inc R12
        jmp for_i_in_rows
exit:
    pop R15
    pop R14
    pop R13
    pop R12
    pop rbx
    pop rbp
    ret

