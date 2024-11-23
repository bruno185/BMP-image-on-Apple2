R1              hex 00
R2              hex 00
R3              hex 00
R4              hex 00
*
*<sym>
random          ror R4          ; bit 25 to carry
                lda R3          ; shift left 8 bits
                sta R4
                lda R2
                sta R3
                lda R1
                sta R2
                lda R4          ; get original bits 17-24
                ror             ; now bits 18-25 in acc
                rol R1          ; R1 holds bits 1-7
                eor R1          ; seven bits at once
                ror R4          ; shift right by one bit
                ror R3
                ror R2
                ror
                sta R1
                rts
*
*here is a routine to seed the random number generator with a
*reasonable initial value:
*<sym>
initrand        lda $4e         ; seed the random number generator
                sta R1          ; based on delay between keypresses
                sta R3
                lda $4f
                sta R2
                sta R4
                ldx #$20        ; generate a few random numbers
                ldx R1
*<sym>
initrandloop    jsr random       ; to kick things off
                dex
                bne initrandloop
                rts