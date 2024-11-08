;
* Demo for Graphics Primitives            
*
*<sym>
GP_call     MAC                                         ; call to graphic primitives (macro)
                jsr GrafMLI                             ; graphic primitives only entry point
                dfb ]1                                  ; command ID (1 byte)
                da  ]2                                  ; address of parameter(s) (2 bytes), 0 if no paramter
                EOM

                put equates
                put equ
*<sym>
MyBuffer        equ $8000                               ; starting address of storage for MyPort grafport
*<sym>
TestFont        equ $800                                ; loading address of "TEST.FONT" file
*<m2>
*<sym>
outbuff         equ $6000
*<sym>
ptr             equ $06
*
*
**************************** START ****************************
*
                org $E00
        
                jsr DoHeader
                bcc okheader              ; exit on error if carry set
                rts
*<sym>
okheader
                jsr DoImage 
       
                jsr Doimg2          

                GP_call InitGraf;0
                GP_call InitPort;MyPort
                GP_call SetPort;MyPort

                jsr DoPaint
                jsr WaitForKeyPress
                jsr DoTextScreen
                rts

*********************************************************************


*<sym>
DoHeader
                jsr TestSign            ; test BMP signature
                bcc oksign              ; exit on error if carry set
                rts
*<sym>
oksign  
* get file length
                ldx #2
                lda bmp,x 
                sta filelen
                inx 
                lda bmp,x 
                sta filelen+1
* check file length
                lda filelen+1 
                cmp #>maxlen
                bne :1
                lda filelen 
                cmp #<maxlen
:1              bcc lower
                bne higher
                beq same
*<sym>
higher          jmp dataerr
                sec
                rts
*<sym>
same                                    ; file length = max : OK
*<sym>
lower                                   ; file length < max : OK

                ldx #$12                ; get image width
                lda bmp,x 
                sta hdef
                inx
                lda bmp,x 
                sta hdef+1
                ldx #$16                ; get image height
                lda bmp,x 
                sta vdef
                inx
                lda bmp,x 
                sta vdef+1 

                lda hdef+1              ; width must be <= maxwidth (560 ?)

                cmp #>maxwidth
                bne :1
                lda hdef
                cmp #<maxwidth
:1              bcc goodw
                bne badw
                beq goodw
*<sym>
badw            jmp dataerr
                sec
                rts
*<sym>
goodw
                lda vdef+1              ; height must be <= maxheight (192 ?)
                cmp #>maxheight
                bne :1
                lda vdef
                cmp #<maxheight
:1              bcc goodh
                bne badw
                beq goodh
*<sym>
goodh
                ldx #$A                 ; get image offset 
                                        ; image data start @ bmp+imgoffset
                lda bmp,x 
                sta imgoffset
                inx
                lda bmp,x 
                sta imgoffset+1  

                lda #<bmp               ; set pointer to strat of image data
                clc
                adc imgoffset
                sta imgdata
                lda #>bmp
                adc imgoffset+1
                sta imgdata+1

                clc
                rts
*<sym>
filelen         ds 2
*<syme>
maxlen          equ $3600
*<syme>
maxwidth        equ 560
*<syme>
maxheight       equ 192
*<sym>
hdef            ds 2
*<sym>
vdef            ds 2
*<sym>
imgoffset       ds 2
*<sym>
imgdata
                ds 2


*<sym>
TestSign
                lda bmp                 ; test signature
                cmp #'B'
                bne dataerr
                lda bmp+1
                cmp #'M'
                beq bmpOK
*<sym>
dataerr         jsr DoTextScreen        ; bad signature
                ldx #0
*<sym>
printchar       lda errmsg,x
                beq errend
                jsr cout 
                inx 
                jmp printchar
*<sym>
errend          jsr crout 
                sec
                rts
*<sym>
bmpOK           clc
                rts
*<sym>
errmsg          asc "Error"
                dfb 0

















*<sym>
Doimg2

* lopp on each line
* loop on a line (lopp length = hdef bytes / 8) => calculte loop length 
* needs : pointer to inputbyte
* init pointer to imgdata

* for i = 1 to loop length
* for each byte :
* loop 8 time :                 ; no, end of line may occur before 8
* get next bit by shifting left in C
* poke bit in output byte : need bitcounter
* if C = 0 : x = bitcounter; lda output byte ; and tableZero ; sta output byte
* if C = 1 : x = bitcounter; lda tableZero,x ; eor $ff ; and output byte ; sta output byte

* inc bitcounter ; cmp #7 ; bne loop else { next output byte, bitcounter = 0}

* Draw line
* next line

                jsr clearmem
                jmp dl2
* vars :
lineCnt         ds 1    ; current # of lines
inputBitPos     ds 1    ; current position in input byte (0 to 7)
inputBitCnt     ds 2    ; current # of input byte (0 to hdef - 1)
outputBitPos    ds 1    ; current position in ouput byte (0 to 6)

tableZero
                db %11111110 
                db %11111101
                db %11111011
                db %11110111
                db %11101111
                db %11011111
                db %10111111 
tableOne        ds 7
*<sym>
dl2
                lda #0                  ; init input line counter
                sta lineCnt
                sta inputBitCnt         ; init input bit counter
                sta inputBitCnt+1             

                sta outputBitPos        ; init output bit counter

                lda imgdata             ; init pointer to image data (input)
                sta loadinput+1
                lda imgdata+1
                sta loadinput+2

                lda #<outbuff           ; init pointer to ouput (buffer)
                sta getoutbyte+1
                lda #>outbuff
                sta getoutbyte+2


                ldx #6
:1              lda tableZero,x
                sta tableOne,x
                dex 
                bmi :1
* loop 
*<bp>
*<sym>   
*XXXXXXXXXXXXXXXXXXXXXXXX : on ne doit pas revenir ici si l'octet n'est pas terminé.
* idem pour input.
           
getoutbyte      
                lda $ffff 
                pha 
*<sym>  
loadinput                      
                lda $ffff               ; self modified
                ldx outputBitPos
                asl                     ; get a bit
                bcs pokeOne
*<sym>
pokeZero
                pla 
                and tableZero,x 
                jmp pokeresult
*<sym>
pokeOne      
                pla 
                and tableOne,x
*<sym>                                
pokeresult      
                pha                     ; save byte to poke
                lda getoutbyte+1        ; get output address
                sta ptr
                lda getoutbyte+2
                sta ptr+1
                ldy #0
                pla 
                sta (ptr),y             ; poke output byte

                lda inputBitCnt+1       ; all pixel done for this line ?
                cmp hdef+1
                bne nextpixel
                lda inputBitCnt
                cmp hdef
                bne nextpixel

                jsr nextinput           ; yes : inc pointer to input byte
                jsr nextoutput          ; inc pointer to output byte
                lda #0
                sta inputBitPos         ; reset bit pos for input
                sta outputBitPos        ; reset bit pos for output

                inc lineCnt             ; next line 
                lda lineCnt
                cmp vdef                ; all lines done ?
                bne getoutbyte          ; no : loop
                rts                     ; XXXXXXXXXX here line should be drawn
*<sym>         
nextpixel       inc inputBitPos         ; get bit pos (input)
                lda inputBitPos
                cmp #8                  ; = 8 ?
                bne np2
                lda #0 
                sta inputBitPos         ; yes : reset pos
                jsr nextinput           ; inc pointer

*<sym> 
np2             inc outputBitPos       ; get bit pos (output)
                lda outputBitPos
                cmp #7                  ; = 7 ?
                bne np3
                lda #0
                sta outputBitPos        ; yes : reset pos
                jsr nextoutput          ; inc pointer
*<sym> 
np3
                jmp getoutbyte          ; loop      

*<sym>                                 
nextinput
                inc loadinput+1
                bne nextinputO
                inc loadinput+2
*<sym>
nextinputO      rts     
*<sym>
nextoutput
                inc getoutbyte+1
                bne nextoutputO
                inc getoutbyte+2
*<sym>
nextoutputO     rts



















* DoImage
* 
*<sym>
DoImage
* given de # of bits, compute the # of bytes to hold these bits.
                lda #$84                ; number of bits (16 bits integer)
                sta mybyte
                lda #$03                ; $384 = 900 => 30 x 30 pixels image 
                sta mybyte+1
                ldx #1                  ; x = number of needed bytes
loopbyte
                lda mybyte
                sec
                sbc #8
                sta mybyte
                lda mybyte+1
                sbc #0
                sta mybyte+1

                ora mybyte
                beq next01              ; = 0 : exit, nb_byte is correct

                lda mybyte+1
                bmi next01              ; < 0 : exit, nb_byte is correct

                                        ; > 0
                inx
                jmp loopbyte 


*<sym>
next01          jsr clearmem



* process data
                stx bytemax             ; save # of input bytes to process
                lda #<bmp               ; set pointer to input data
                sta getbyte+1
                lda #>bmp
                sta getbyte+2  
                lda #<outbuff           ; set pointers to output data
                sta gtarget+1
                sta starget+1                
                lda #>outbuff
                sta gtarget+2 
                sta starget+2               
                lda #0
                sta bitpos              ; bit position in output byte
                sta bitindex            ; bit position in input byte
                sta bytecnt             ; init counter of input bytes
*<sym>
getbyte         lda $FFFF               ; get input byte (modified)
*<sym>
doloop
                asl                     ; bit in carry
                sta inbyte              ; save shifted input byte
*<sym>
gtarget         lda $FFFF               ; get target byte (modified)
                pha                     ; save it
                ldx bitpos              ; get bit index
                lda tab,x               ; get mask
                bcc bitclr              ; carry = 0
* bit  = 1
                sta mask                ; save mask
                pla                     ; restore target
                ora mask                ; set bit
                jmp starget             ; poke byte
* bit  = 0
*<sym>
bitclr        
                eor #$FF                ; invert mask
                sta mask                ; save it
                pla                     ; restore target
                and mask                ; clear bit

*<sym>
starget         sta $FFFF               ; save target byte (modified)
                inc bitpos              ; inc bit pos in input byte
                lda bitpos
                cmp #7                  ; 7 bits done ?
                bne :1                
                lda #0                  ; yes : reset bitpos
                sta bitpos
                inc starget+1           ; and inc target pointer
                bne :4
                inc starget+2
:4              inc gtarget+1           ; and inc target pointer
                bne :1
                inc gtarget+2
:1              inc bitindex            ; inc pos in input byte
                lda bitindex
                cmp #8                  ; 8 bits done ?
                bne :2
                inc bytecnt             ; yes : inc # input bytes done
                lda bytecnt
                cmp bytemax             ; all bytes done ?
                beq endbyte             ; yes : exit
                lda #0                  ; 8 bits done : reset bitindex
                sta bitindex
                inc getbyte+1           ; and inc input pointer
                bne :3
                inc getbyte+2
:3              jmp getbyte             ; get next byte

:2              lda inbyte              ; reload input byte 
                jmp doloop

*<sym>
endbyte         rts

*<m1>
*<sym>
mybyte         
                ds 2
*<sym>
inbyte          ds 1
*<sym>
bitindex        ds 1
*<sym>
bitpos          ds 1
*<sym>
mask            ds 1
*<sym>
tab             hex 01020408102040
*<sym>
bytemax         ds 1
*<sym>
bytecnt         ds 1

*<sym>
bmp 
*                hex 424DB80000000000
*                hex 00003E0000002800
*                hex 00001E0000001E00
*                hex 0000010001000000
*                hex 00007A000000232E
*                hex 0000232E00000000
*                hex 000000000000FFFF
*                hex FF00000000008000
*                hex 0004800000048000
*                hex 0004800000048000
*                hex 0004800000048000
*                hex 0004800000048000
*                hex 0004800000048000
*                hex 0004800000048000
*                hex 0004800000048000
*                hex 0004800000048000
*                hex 0004800000078000
*                hex 0006800000068000
*                hex 0004800000048000
*                hex 0004800000048000
*                hex 0004800000048000
*                hex 0004800000048000
*                hex 0004800000070000
; BBB.BMP
                hex 424DB80000000000
                hex 00003E0000002800
                hex 00001E0000001E00
                hex 0000010001000000
                hex 00007A000000232E
                hex 0000232E00000000
                hex 000000000000FFFF
                hex FF00000000008000
                hex 0004000000000000
                hex 0000000000000000
                hex 0000000000000000
                hex 0000000000000000
                hex 0000000000000000
                hex 0000000000000000
                hex 0000000000000000
                hex 0000000000000000
                hex 0000000000000000
                hex 0000000000010000
                hex 0000000000000000
                hex 0000000000010000
                hex 0000000000000000
                hex 0000000000000000
                hex 0000A80000540000


*
* DoPaint
*

*<sym>
DoPaint
                GP_call PaintBits;LineDHGR
                rts

LineDHGR        dw 0,10                                ; view location on current port
                dw LineBits                             ; bitmap pointer
                dw 80                                    ; width of bitmap 
                dw 0,0,560,0                             ; clip rectangle

LineBits        
                ds 80,$FF

*<sym>
DoPaint2   
                ldy #0
outter               
                phy
                ldx #0
godraw
                phx
                GP_call PaintBits;TestBits2

                plx
                lda DataBits,x
                sec
                rol
                sta DataBits,x 
                inx 
                cpx #30
                bne godraw
                ply 
                iny
                cpy #7
                bne outter
                rts

TestBits2       dw 50,50                                ; view location on current port
                dw DataBits                             ; bitmap pointer
                dw 3                                    ; width of bitmap 
                dw 0,0,17,9                             ; clip rectangle

DataBits        dfb $00,$00,$00         ; bitmap data
                dfb $00,$00,$00
                dfb $00,$00,$00
                dfb $00,$00,$00
                dfb $00,$00,$00
                dfb $00,$00,$00
                dfb $00,$00,$00
                dfb $00,$00,$00
                dfb $00,$00,$00
                dfb $00,$00,$00

* Wait for keypress
*
WaitForKeyPress 
                lda kbd
                bpl WaitForKeyPress
                sta kbdstrb
                rts
*
* ClearIt
*
ClearIt         equ *                                           ; fill port with black
                GP_call SetPenMode;ModeCopy             ; pen + destination = pen
                GP_call SetPattern;Black                ; black (0,0,...)
                GP_call PaintRect;WowRect               ; paint very large rectangle in black
                GP_call SetPattern;White                ; restore pattern to white (1,1,...)
                rts
WowRect         dw 0,0,10000,10000                      ; very large rectangle

*
* Data for rects., polygons, bitmap, and text
*
TestPort        ds portlength                           ; space for TestPort (= standard grafport = screen grafport)
*
testrect1       dw 30,30,95,150                         ; a ractangle
testrect2       dw 200,50,520,140                       ; a ractangle
*
Point1          dw 0,0                                  ; upper left corner
Point2          dw 559,0                                ; bottom right corner
*
R1              dw 10,10,30,30                          ; a rect (x,y)
R2              dw 28,28,70,70                          ; a rect (x,y)
R3              dw 40,40,90,90                          ; a rect (x,y)
R4              dw 100,30,180,60                        ; a rect (x,y)
*
ModeNotOr       dfb 5
ModeCopy        dfb 0
*
Color1          dfb $66,$66,$66,$66,$66,$66,$66,$66,0   ; green pattern
Color2          dfb $11,$11,$11,$11,$11,$11,$11,$11,0   ; blue pattern
Color3          dfb $CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,0   ; orange pattern
weave           dfb $38,$74,$EE,$47,$83,$C5,$EE,$5C,0   ; nice pattern ! (yellow weave)

Black           dfb 0,0,0,0,0,0,0,0,0                   ; black pattern
White           ds 8,$FF                                ; white pattern
                dfb 0
*
                                                        ; A shape
TestPoly        dfb 8,$80                               ; 8 vertices, $80 : there is anather poly in this list
                dw 64,168,192,168,224,120,288,120,320,168,448,168,320,40,192,40
                ; dw 3                                  ; replaced by more readable :
                db 3                                    ; second poly of the list, 3 vertices 
                                                        ; makes a hole in first poly.
                db 0                                    ; $80 : last poly 
                dw 224,96,288,96,256,56
*
TestBits        dw 50,50                                ; view location on current port
                dw Handbits                             ; bitmap pointer
                dw 3                                    ; width of bitmap 
                dw 0,0,17,9                             ; clip rectangle
Handbits        dfb $00,$00,$00,$20,$00,$00,$30,$00,$00,$38,$00,$00     ; bitmap data
                dfb $5E,$7F,$07,$7E,$00,$00,$3E,$1F,$00,$7E,$00,$00
                dfb $3C,$0F,$00,$00,$00,$00
*
Point3          dw 4,50
*
*
TestText        dw message
                dfb msglength
message         asc 'This is a test of the emergency graphics system'
msglength       equ *-message
*
*
* MyPort          ds 50,0    
*<sym>                             
MyPort          ds portlength                           ; space for a grafport stucture                        
                                                        ; this is better than original line above.
MyBits          dw 0,0                                  ; viewloc
                dw MyBuffer
                dw 40
                dw 0,0,200,100

MyDestBits      dw 50,30
                dw MyBuffer
                dw 40
                dw 0,0,200,100
*
ContText        dw message1
                dfb msglgth
message1        asc ' Please press RETURN to continue. '
msglgth         equ *-message1
Point4          dw 30,190
Switch          dfb 8
*
QuitText        dw message2
                dfb msglgth1
message2        asc '      Please press RETURN to Quit..........                 '
msglgth1        equ *-message2
*
BufText         dw message3
                dfb msglgth2
message3        asc '      Now drawing into buffer............'
msglgth2        equ *-message3


* ------------------ utils ------------------
*<sym>
DoTextScreen

                sta $c000 ;80store off
                sta $c002 ;RAMRD main
                sta $c004 ;RAMWRT main
                sta $c00c ;80col off
                sta $c00e ;Altcharset off
                sta $c081 ;write RAM, read ROM (2nd 4k bank)
                jsr text
                jsr home
                jsr normal
                jsr pr0
                jsr in0
                rts

*<sym>
clearmem
* clear memory 
                lda #<outbuff
                sta ptr 
                lda #>outbuff
                sta ptr+1

                lda #0
                ldy #0
*<sym>
pokeZ           sta (ptr),y 
                iny
                bne pokeZ
                inc ptr+1
                ldx ptr+1
                cpx #$96                ; stop clear at $9600
                bne pokeZ
                rts


*<sym>
ProDOSQuit
                jsr $BF00 ; ProDOS Quit
                dfb $65
                dw QuitParams
                rts
*<sym>
QuitParams      dfb 4
                dw 0,0,0,0                              ; standard parameters for Quit call