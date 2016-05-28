    section .text
    global canny

;source = rdi
;dest = rsi
;width = rdx
canny:
    MOVDQU xmm1, [rdi]; current pixel
    MOVDQU xmm2, [rdi+rbx+1]; x+1 y+1
    PSUBSB xmm1, xmm2
    PABSB xmm1, xmm1
    MOVDQU xmm3, [rdi+rbx]; x+1 y
    MOVDQU xmm4, [rdi+1]; x y+1
    PSUBSB xmm3, xmm4
    PABSB xmm3, xmm3
    PADDSB xmm3, xmm1
    MOVDQU [rsi], xmm3
    ret

