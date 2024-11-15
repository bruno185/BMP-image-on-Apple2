* * * * * * * * * * * * * * * * * * * * * * * * * * * 
*                                                   *
*   Diplay a BMP image using Graphics Primitives    *      
*                                                   *  
* * * * * * * * * * * * * * * * * * * * * * * * * * *  
*
* BMP is loaded by this program, and tests are performed :
        * BMP image must have 1 bit per pixel
        * Dimension must not exceed 280 x 192
        * Every bit (= pixel) in BMP file is doubled horizontally 
* to respect image aspect ratio (more or less),
* the image is drawn line by line, using PaintBits function of Graphics Primitives package
*
*
* Memory :
* STARTUP (Basic) : $801 
* Font : $800 : destroy STARTUP !
* Program : $E00 - $1FFF
* Screen : $2000 - $3FFF
* GP Library : $4000 - $5FFF
* BMP Image : $6000 - $7FFF
* grafport storage : $8000

*<sym>
GP_call     MAC                                         ; call to graphic primitives (macro)
                jsr GrafMLI                             ; graphic primitives only entry point
                dfb ]1                                  ; command ID (1 byte)
                da  ]2                                  ; address of parameter(s) (2 bytes), 0 if no paramter
                EOM

                put equates
                put equ
                              ; loading address of "TEST.FONT" file
*<sym>
ptr             equ $06
*
**************************** MAIN PROGRAM ****************************
*
                org $E00

                lda #4                  ; get 4 pages for 1024 file buffer 
                jsr GETBUFR             ; needed by MLI OPEN
                bcc GetbufOK            ; carry clear means no error in the following code
                jmp dataerr             ; carry set means error

*<sym>
GetbufOK
                sta fbuff+1             ; set file buffer for OPEN param 
                jsr doprefix            ; set prefix 
                bcc doprefixOK
                jmp dataerr
*<sym>
doprefixOK

                jsr openBMP             ; open and load BMP file in memory
                bcc BMPok
                jmp dataerr             ; exit with error
*<sym>
BMPok
                jsr DoHeader            ; check header of BMP data and set vars
                bcc headerOK            ; exit on error if carry set
                jmp dataerr             ; exit with error
*<sym>
headerOK
                GP_call InitGraf;0      ; go DHGR mode using Graphics Primitives library
                GP_call InitPort;MyPort
                GP_call SetPort;MyPort
*<sym>
startimage
                jsr Doimg               ; display image 
                lda #0                  ; init quif flag
                sta quitflag
                jsr WaitForKeyPress     ; 
                jsr DoKey               ; process key 
                lda quitflag            ; test quit flag (=1 if escape key)
                beq startimage          ; if 0 then loop 
                jsr DoTextScreen        ; else set text screen
                rts                     ; END OF PROGRAM (without error)
*
*********************************************************************
*
*<sym>
DoHeader
* check image specs.
                jsr TestSignature       ; test BMP signature
                bcc oksign              ; exit on error if carry set
                rts
*<sym>
oksign  
* get file length
                ldx #2                  ; offset to file length in BMP header
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
higher
                sec                     ; size is too big
                rts
*<sym>
samelength                              ; file length = max : OK
*<sym>
lower                                   ; file length < max : OK
                ldx #$12                ; get image width in BMP header
                lda bmp,x 
                sta hdef                ; set hdef var accordingly
                inx
                lda bmp,x 
                sta hdef+1
                ldx #$16                ; get image height in BMP header
                lda bmp,x 
                sta vdef                ; set hdef var accordingly
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
badw            
                sec                     ; width is too large 
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
                lda vdef                ; vdef = vdef -1 : tranform img def (1 to n) 
                bne :1                  ; to screen coordinate (0 to def-1)
                dec vdef+1
:1              dec vdef

                ldx #$1C                ; offset to image depth (# of bits per pixel)
                lda bmp,x               ; get value
                cmp #1                  ; must be 1 
                beq gooddepth
                sec                     ; <> 1 bit per pixel 
                rts
*<sym>
gooddepth            
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
*
*
*<sym>
TestSignature
                lda bmp                 ; test signature
                cmp #'B'
                bne errSign
                lda bmp+1
                cmp #'M'
                beq signatureOK
*<sym>
errSign         sec
                rts
*<sym>
signatureOK     clc
                rts

* * * * Exit with an error * * * * 
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
                rts
* * * * * * * * * * * * * * * * *
*
*<sym>                             
MyPort          ds portlength                           ; space for a grafport stucture    

*<sym>
errmsg          asc "Error !"
                dfb 0
*
* Doimg
* lopp on each line
* loop on a line (lopp length = hdef bytes / 8) => calculte loop length 
* needs : pointer to inputbyte
* init pointer to imgdata

* for i = 1 to loop length
* for each byte :
* loop 8 time (or less if end of line occurs before 8)
* get next bit by shifting left in C
* poke bit in output byte : need bitcounter
* if C = 0 : x = bitcounter; lda output byte ; and tableZero ; sta output byte
* if C = 1 : x = bitcounter; lda tableZero,x ; eor $ff ; and output byte ; sta output byte
* inc bitcounter ; cmp #7 ; bne loop else { next output byte, bitcounter = 0}
* Draw line using PaintBits function in graphic primitives package
* next line
* check for last line
*
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
quitflag        ds 1                    ; to ckeck if user press escape key

******** line grafport ********
*<m1>
*<sym>
imageLine       dw 0,0                  ; view location on current port
*<sym>
imfbits         dw outbuff              ; bitmap pointer
*<sym>
imgw            dw 0                    ; width of bitmap 
*<sym>
clipr           dw 0,0,0,0              ; clip rectangle
*<sym>
outbuff         ds 80                   ; max 80 bytes for a dhgr line.
*<sym>
carryf          db 1
*<sym>
inverse         db 1

*<sym>
Doimg
***** init *****

                jsr clearbuffer         ; clear line buffer

                lda #$ff                ; init input line counter to -1
                sta lineCnt
                lda #0
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
                jsr drawImgLine2       ; a line has been calcultated, paint it !!!

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
*<sym> 
div4ok
                lda #0
                sta inputByteCnt        ; init byte counter for a line
                jsr nextinput           ; inc pointer to input byte
                lda #0
                sta inputBitPos         ; reset bit pos for input
                sta inputBitCnt         ; reset input bit counter
                sta inputBitCnt+1
                sta outputBitPos        ; reset output byte position  

                lda #1
                sta flipflop            ; reset toggle to double pixel width    
      
                inc lineCnt             ; inc line counter
                lda lineCnt
                cmp vdef                ; all lines done ?
                beq endimage             ; yes : the image is finished !   
                jmp lineloop            ; no : loop for another image line
*<sym>  
endimage
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
drawImgLine                             ; draw line using Graphics Primitives
                GP_call PaintBits;imageLine     ; dram a line of the image
                dec imageLine+2
                rts
*<bp>
*<sym>
drawImgLine2                            ; draw line using direct access to memory   
                lda imageLine+3         ; upper byte must be 0 
                beq okYinf256           ; ok
                rts                     ; else vertical position > 192 : exit
*<sym>
okYinf256       ldx imageLine+2         ; get Y pos of line
                cpx #192
                bcc okYinf192           ; chek < 192
                rts                     ; exit il not
*<sym>
okYinf192       
                lda lo,x                ; set pointer prt to memory address
                sta ptr                 ; of this image line
                lda hi,x 
                sta ptr+1
                ldx #0
                ldy #0
                sta $C000
*<sym>
pokeloop
                lda outbuff,x
                sta RAMWRTON
                sta (ptr),y 
                sta RAMWRTOFF
                inx
                cpx clipr+4
                beq outloop 
                lda outbuff,x 
                sta (ptr),y 
                iny 
                inx 
                cpx imgw
                bne pokeloop


outloop
                sta $C001
                dec imageLine+2
                rts

*<syme>
bmp             equ $6000               ; image is supposed to be loaded at $6000 

*<sym>
DoKey                                   ; test keys
                cmp #"i"                ; if i ou I : negate image
                beq doInverse
                cmp #"I" 
                beq doInverse 
*<sym>
nextkey         cmp #$9B                ; escape : exit
                beq exitDK

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


*<sym>
WaitForKeyPress 
                lda kbd
                bpl WaitForKeyPress
                sta kbdstrb
                rts



* ------------------ utils ------------------

*<sym>
testLength
                lda filelength+2        ;       Byte 3 must 0 (else file size would be > $FFFF)            
                beq :1
                sec 
                rts
:1              
                lda filelength+1        ; compare file length           
                cmp #>maxlen            ; to maxlen
                bne :2
                lda filelength
                cmp #<maxlen
:2
                bcc lowerlen            ; lower : OK
                bne higherlen           ; higher : KO
                beq lowerlen            ; = : OK
*<sym>
lowerlen        clc        
                rts
*<sym>
higherlen
                sec
                rts

* open BMP file

*<sym>
openBMP       
                jsr MLI                 ; OPEN file 
                dfb open
                da  OPEN_parms 
                bcc GetEOF              ; no error, go on
                rts
*<sym>
GetEOF 
                lda ref                 ; get reference to file (got it in open mli call above)
                sta refread             ; set it for reading 
                sta refd1               ; set if for geteof

                jsr MLI                 ; Call GetEOF to get length of file
                dfb geteof
                da GET_EOF_param
                bcc geteofOK            ; if call was ok then go on
                rts
*<sym>
geteofOK
                jsr testLength          ; compare maxlen (max size for an image in memory ans size of BMP file
                bcc LoadBMP             ; ok if file size < max size
                rts

*<sym>
LoadBMP                                 ; read BMP file 
                lda ref                 ; set reference to file (got it in open mli call above)
                sta refread
                jsr MLI
                dfb read
                da READ_param
                rts

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
                sta $C000
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
*
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
*               
*<sym>
ProDOSQuit
                jsr $BF00 ; ProDOS Quit
                dfb $65
                dw QuitParams
                rts
*<sym>
QuitParams      dfb 4
                dw 0,0,0,0                              ; standard parameters for Quit call
*
*<sym>
computeBytes
* given the # of bits in A,X (lo,hi), computes the # of bytes
* to hold these bits on Apple II screen (7 pixels per byte)           
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
:1              
        rts
*<sym>
mybyte         
                ds 2
*
*
*********** PREFIX *************
* Set prefix using current préfix :
* Call GETPREFIX, put it in "path" string
* If no prefix (i.e. length of "path" string = 0),
* then get préfix from last used disk, unsing ONLINE call
* If any error, exit with carry set
* else exit with carry clear
*
*<sym>
doprefix
                jsr MLI                 ; getprefix MLI call ; put prefix in "path"
                dfb getprefix
                da GET_PREFIX_param
                bcc gpOk             
                rts
*<sym>
gpOk
                lda path                ; first char = length
                beq noprefix            ; if length = 0 => no prefix
                jmp prefixSetOK         ; else prefix already set, exit 
*<sym>
noprefix
                lda devnum              ; last used slot/drive 
                sta unit                ; param du mli online
                jsr MLI
                dfb online              ; on_line : get prefix in path
                da ONLINE_param
                bcc onlineOK
                rts
*<sym>
onlineOK   
                lda path
                and #$0f               ; length in low nibble
                sta path
                tax
*<sym>
:1              lda path,x              ; shift prefix by one byte
                sta path+1,x            ; 
                dex
                bne :1                  ; all string
                inc path
                inc path                ; length = length + 2
                ldx path                ; 
                lda #$af                ; = '/'
                sta path,x              ; insert '/'' at the end
                sta path+1              ; and '/'' at the beginning 

                jsr MLI                 ; set_prefix (in the form : /prefix/)
                dfb setprefix
                da SET_PREFIX_param
                bcc prefixSetOK
                rts
*<sym>
prefixSetOK   
                rts
*
*
* * * * MLI Call READ parameters * * * * 
*<sym>
READ_param                              ; READ file
                hex 04                  ; number of params.
*<sym>
refread         hex 00                  ; ref #
*<sym>
rdbuffa         da bmp
*<sym>
rreq            hex 0020                ; bytes requested
*<sym>
readlen         hex 0000                ; bytes read
*
* * * * MLI Call OPEN parameters * * * * 
*<sym>
OPEN_parms                                ; OPEN file for reading             
                hex 03                  ; number of params.
                da fname                ; path name
*<sym>
fbuff           hex 0000
*<sym>
ref             hex 00
*<sym>
fname           str 'IMG'
*
* * * * MLI Call GET_PREFIX parameters * * * * 
*<sym>
GET_PREFIX_param                        ; GET_PREFIX
                hex 01                  ; number of params.
                da path

*
* * * * MLI Call SET_PREFIX parameters * * * *
*<sym>
SET_PREFIX_param                        ; SET_PREFIX
                hex 01                  ; number of params.
                da path
*
*
* * * * MLI Call ONLINE parameters * * * *
*<sym>
ONLINE_param                            ; ONLINE  
                hex 02                  ; number of params.
*<sym>
unit            hex 00
                da path
*
*<sym>
path            ds 256                  ; storage for path
*
* * * * MLI Call GET_FILE_INFO parameters * * * *
*<sym>
GET_FILE_INFO_param                     ; GET_FILE_INFO
                hex 0A
                da path
*<sym>
access          hex 00
*<sym>
ftype           hex 00
*<sym>
auxtype         hex 0000
*<sym>
stotype         hex 00
*<sym>
blocks          hex 0000
*<sym>
date            hex 0000
*<sym>
time            hex 0000
cdate           hex 0000
ctime           hex 0000
*
* * * * MLI Call GET_EOF parameters * * * *
*<sym>
GET_EOF_param                           ; GET_EOF
                hex 02
*<sym>
refd1           hex 00
*<sym>
filelength      ds 3

                put hilo