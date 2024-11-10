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
*<sym>
ptr             equ $06

*
*
**************************** MAIN PROGRAM ****************************
*
                org $E00
        

                jsr DoHeader
                bcc okheader              ; exit on error if carry set
                rts
*<sym>
okheader
                GP_call InitGraf;0
                GP_call InitPort;MyPort
                GP_call SetPort;MyPort
*<sym>
startimage
                jsr Doimg 
                ;jsr DoPaint
                lda #0
                sta quitflag
                jsr WaitForKeyPress
                jsr DoKey
                lda quitflag
                beq startimage
                jsr DoTextScreen
                rts
*
*********************************************************************
*
*<sym>
DoHeader
                jsr TestSignature       ; test BMP signature
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
                beq samelength
*<sym>
higher          jmp dataerr
                sec
                rts
*<sym>
samelength                              ; file length = max : OK
*<sym>
lower                                   ; file length < max : OK
                ldx #$12                ; get image width in BMP header
                lda bmp,x 
                sta hdef
                inx
                lda bmp,x 
                sta hdef+1
                ldx #$16                ; get image height in BMP header
                lda bmp,x 
                sta vdef
                inx
                lda bmp,x 
                sta vdef+1 

                lda hdef+1              ; width must be <= maxwidth

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
                lda vdef+1              ; height must be <= maxheight
                cmp #>maxheight
                bne :1
                lda vdef
                cmp #<maxheight
:1              bcc goodh
                bne badw
                beq goodh
*<sym>
goodh
                ldx #$A                 ; get image offset in BMP header
                                        ; image data start @ bmp+imgoffset
                lda bmp,x 
                sta imgoffset
                inx
                lda bmp,x 
                sta imgoffset+1  

                lda #<bmp               ; set pointer to beginning of image data
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
maxlen          equ $2000               ; 8 k for image (between $6000 and $7FFF)
*<syme>
maxwidth        equ 280                 ; = 560 / 2 (each pixel is doubled in width)
*<syme>
maxheight       equ 192                 ; screen height in pixels
*<sym>
hdef            ds 2                    ; image width
*<sym>
vdef            ds 2                    ; image height
*<sym>
imgoffset       ds 2                    ; offset to image data (over BMP header)
*<sym>
imgdata
                ds 2                    ; address of image data


*<sym>
TestSignature
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
* Doimg
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

* vars :
*<sym>
lineCnt         ds 1    ; current # of lines
*<sym>
inputBitPos     ds 1    ; current position in input byte (0 to 7)
*<sym>
inputBitCnt     ds 2    ; current # of input byte (0 to hdef - 1)
*<sym>
outputBitPos    ds 1    ; current position in ouput byte (0 to 6)
*<sym>
inbyte          ds 1    ; save input byte
*<sym>
inputByteCnt    ds 1    ; counts # of input byte in a line
*<sym>
tableZero
                db %11111110 
                db %11111101
                db %11111011
                db %11110111
                db %11101111
                db %11011111
                db %10111111 
*<sym>
tableOne        ds 7
*<sym>
bitmapwidth     ds 1
*<sym>
flipflop        db 1                    ; used to double pixels horizontally 
*<sym>
quitflag        ds 1


************ line grafport ************
*<m2>
*<sym>
imageLine       dw 0,0                  ; view location on current port
*<sym>
imfbits         dw outbuff              ; bitmap pointer
*<sym>
imgw            dw 0                    ; width of bitmap 
*<sym>
clipr           dw 0,0,0,0              ; clip rectangle

*<m1>
*<sym>
outbuff         ds 80
*<sym>
carryf          db 1
*<sym>
inverse         db 1

*<sym>
Doimg
***** init *****

                jsr clearbuffer         ; clear line buffer

                lda #0                  ; init input line counter
                sta lineCnt
                sta inputBitCnt         ; init input bit counter
                sta inputBitCnt+1  
                sta inputByteCnt        ; init # of byte in a row           

                sta outputBitPos        ; init output bit counter

                lda imgdata             ; init pointer to image data (input)
                sta lineloop+1
                lda imgdata+1
                sta lineloop+2

                lda #<outbuff           ; init pointer to ouput (buffer)
                sta getoutbyte+1
                lda #>outbuff
                sta getoutbyte+2

                ldx #0                  ; init tableOne (= eor table Zero)
*<sym> 
tabloop         lda tableZero,x
                eor #$FF
                sta tableOne,x
                inx
                cpx #7
                bne tabloop 
*<sym>
getwidth
                lda hdef
                ldx hdef+1
                jsr computeBytes
                stx bitmapwidth
*<sym>
setline
                lda vdef
                sta imageLine+2         ; set vertical position of lower image line   

                lda bitmapwidth
                asl
                sta imgw                ; set image width in byte

                lda hdef                ; set clip rectangle in pixels
                asl
                sta clipr+4
                lda hdef+1
                rol
                sta clipr+5

***** process data *****
* outer loop (on all bytes of an image line)
*<sym>   
lineloop                                ; get a new input byte                   
                lda $ffff               ; self modified
                pha
                lda inverse
                beq normalvideo
                pla 
                eor #$ff
                jmp inversevideo
*<sym>
normalvideo    
                pla 
*<sym>
inversevideo
                sta inbyte              ; save it
                inc inputByteCnt        ; update counter

* inner loop on pixels (= input bits)
*<sym>
pixelloop
                lda inbyte              ; reload input byte         
                asl                     ; get a bit
                sta inbyte              ; save shifted input byte

                inc inputBitCnt
                bne getoutbyte
                inc inputBitCnt+1
*<sym>        
getoutbyte      
                lda $ffff               ; get ouput byte
                ldx outputBitPos
                bcs pokeOne             ; bit coming from input byte = 1 ?
*<sym>
pokeZero                                ; no : set this bit to 0 in output bit
                and tableZero,x         ; A : ouput byte, and it with table value
                ldy #0
                sty carryf              ; save carry value in carryf var
                jmp pokeresult
*<sym>
pokeOne                                 ; yes : set this bit to 1 in output bit
                ldy #1
                sty carryf              ; save carry value in carryf var
                ora tableOne,x
*<sym>                                
pokeresult                              ; save output byte 
                ldx getoutbyte+1        ; get output address
                stx ptr
                ldx getoutbyte+2
                stx ptr+1
                ldy #0
                sta (ptr),y             ; poke output byte in its original place
*<sym> 
updateoutput    inc outputBitPos       ; get bit pos (output)
                lda outputBitPos
                cmp #7                  ; = 7 ?
                bne :1
                lda #0
                sta outputBitPos        ; yes : reset pos
                jsr nextoutput          ; inc pointer
:1
                clc 
                ldy carryf
                beq :2
                sec
:2              lda flipflop            ; each pixel horizontally must be draw twice (and only twice)
                eor #1                  ; test flipflop 
                sta flipflop            ; invvert it
                beq getoutbyte          ; if 0 : draw same pixel once again

                lda inputBitCnt         ; all pixels done for this line ?
                cmp hdef                ;         
                bne nextpixel           ; no : loop to process next pixel
                lda inputBitCnt+1
                cmp hdef+1
                bne nextpixel

*<sym>  
nextline                                ; yes : paint current line and prepare next one
                jsr drawImgLine         ; a line has been calcultated, paint it !!!

                lda #<outbuff           ; reset pointer to beginning of output buffer
                sta getoutbyte+1
                lda #>outbuff
                sta getoutbyte+2 

                jsr clearbuffer         ; zero ouput buffer 
*<sym> 
loopadjust                              ; in an image line, # of bytes must be divisible by 4
                                        ; if not, padded with zeros to make it divisible by 4
                                        ; so we need to jump over these useless bytes.
                lda inputByteCnt        ; get # of byte done in previous image line
                and #3                  ; if this number is divisible by 4 
                beq div4ok              ; go on
                jsr nextinput           ; else inc pointer to input data
                inc inputByteCnt        ; inc counter       
                jmp loopadjust          ; and loop until inputByteCnt is divisible by 4 
                bne div4ok
*<sym> 
div4ok
                lda #0
                sta inputByteCnt
                jsr nextinput           ; inc pointer to input byte

                lda #0
                sta inputBitPos         ; reset bit pos for input
                sta inputBitCnt         ; reset input bit counter
                sta inputBitCnt+1
                sta outputBitPos        ; reset output byte position  

                lda #1
                sta flipflop      
      
                inc lineCnt             ; inc line counter
                lda lineCnt
                cmp vdef                ; all lines done ?
                beq endloop             ; yes : end
                jmp lineloop            ; no : loop for another image line
*<sym>  
endloop
                rts                     ; END !!!
*<sym>         
nextpixel                               ; no : other pixels to go on current line 
                inc inputBitPos         ; get bit pos (input)
                lda inputBitPos
                cmp #8                  ; = 8 ?
                beq nextbyte            
                jmp pixelloop
*<sym>  
nextbyte
                lda #0                  ; yes : adjust vars
                sta inputBitPos         ; reset input bit position pos to 0
                jsr nextinput           ; inc pointer to image data
                jmp lineloop            ; loop to get next input byte
*<sym>                                 
nextinput
                inc lineloop+1
                bne nextinputO
                inc lineloop+2
*<sym>
nextinputO      rts 


*<sym>
nextoutput
                inc getoutbyte+1
                bne nextoutputO
                inc getoutbyte+2
*<sym>
nextoutputO     rts


*<sym>
drawImgLine
                GP_call PaintBits;imageLine
                dec imageLine+2
                rts
*<syme>
bmp             equ $6000               ; image is supposed to be loaded at $6000 

*<bp>
*<sym>
DoKey                                   ; test keys
                cmp #"i"                ; if i ou I : negate image
                beq doInverse
                cmp #"I" 
                beq doInverse 
*<sym>
nextkey         cmp #$9B                ; escape : exit
                beq exitDK
                ;jsr clerscr

                cmp #"c"                ; c for clear
                beq doclear
                cmp #"C"
                beq doclear
                rts                     ; none of these keys : do nothing
*<sym>
doclear
                jsr clerscr             ; call clear screen proc.
                rts
*<sym>
exitDK          lda #1                  ; escape : set quit flag
                sta quitflag
                rts
   
*<sym>
doInverse
                lda inverse
                eor #$01
                sta inverse 
                jmp startimage

*
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
*<sym>
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
* Clear DHGR screen   
screenbase      equ $2000               ; address of screen memory    
*<sym> 
clerscr
                lda #<screenbase
                sta ptr
                lda #>screenbase+1
                sta ptr+1
                ldy #0
                lda #0
                STA $C000
*<sym> 
clrloop         
                sta (ptr),y 
                sta RAMWRTON            ; write char in aux
                sta (ptr),y
                sta RAMWRTOFF
                iny
                bne clrloop
                inc ptr+1
                ldx ptr+1
                cpx #$40
                bne clrloop
                sta $C001
                jsr WaitForKeyPress
                jmp startimage
                rts

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
clearbuffer
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
                cpy #80
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

*<sym>
computeBytes
* given the # of bits in A,X (lo,hp) compute the # of bytes to hold these bits.             
                sta mybyte              ; number of bits (16 bits integer)
                stx mybyte+1
                ldx #1                  ; x = number of needed bytes
*<sym>
loopbyte
                lda mybyte
                sec
                sbc #7
                sta mybyte
                lda mybyte+1
                sbc #0
                sta mybyte+1

                ora mybyte
                beq :1                  ; = 0 : exit, nb_byte is correct
                lda mybyte+1
                bmi :1                  ; < 0 : exit, nb_byte is correct
                                        ; > 0 : loop
                inx
                jmp loopbyte

:1              rts
*<sym>
mybyte         
                ds 2

