*
*<sym>
MyBuffer        equ $8000                               ; starting address of storage for MyPort grafport
*<sym>
TestFont        equ $800  


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

*
* Clear screen using Graphics Primitives library
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