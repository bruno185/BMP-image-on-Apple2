;
; Demo for Graphics Primitives            
;
GP_call     MAC                                         ; call to graphic primitives (macro)
*<sym>
                jsr GrafMLI                             ; graphic primitives only entry point
                dfb ]1                                  ; command ID (1 byte)
                da  ]2                                  ; address of parameter(s) (2 bytes), 0 if no paramter
                EOM
;
                ;org $1800
                org $E00
                put equates
                put equ

MyBuffer        equ $8000                               ; starting address of storage for MyPort grafport
TestFont        equ $800                                ; loading address of "TEST.FONT" file

*<bp>

                GP_call InitGraf;0
                GP_call InitPort;MyPort
                GP_call SetPort;MyPort

                ;jsr DrawSomething ; Test the drawing code
*<bp>
                jsr DoPaint

*<bp>
                jsr WaitForKeyPress
                jsr DoTextScreen
                rts

*********************************************************************

                jsr $BF00 ; ProDOS Quit
                dfb $65
                dw QuitParams
                rts
QuitParams      dfb 4
                dw 0,0,0,0                              ; standard parameters for Quit call
;
LoopCounter     dfb 0
Test0Table      dfb 1,1,0,0,0,0,0                       ; table used by DrawSomething function
Test1Table      dfb 1,0,1,0,0,0,0                       ; 1 : draw graphic, 0 : do not.
Test2Table      dfb 1,0,0,1,0,0,0
Test3Table      dfb 1,0,0,0,1,0,0
Test4Table      dfb 1,0,0,0,0,1,0

;
; DoPaint
;
*<sym>
DoPaint
                GP_call PaintBits;LineDHGR
                rts

LineDHGR        dw 0,10                                ; view location on current port
                dw LineBits                             ; bitmap pointer
                dw 80                                    ; width of bitmap 
                dw 0,0,560,0                             ; clip rectangle
*<m1>
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
*<bp> 
                rts

TestBits2       dw 50,50                                ; view location on current port
                dw DataBits                             ; bitmap pointer
                dw 3                                    ; width of bitmap 
                dw 0,0,17,9                             ; clip rectangle
*<m1>
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

; Wait for keypress
;
WaitForKeyPress 
                lda kbd
                bpl WaitForKeyPress
                sta kbdstrb
                rts
;
; ClearIt
;
ClearIt         equ *                                           ; fill port with black
                GP_call SetPenMode;ModeCopy             ; pen + destination = pen
                GP_call SetPattern;Black                ; black (0,0,...)
                GP_call PaintRect;WowRect               ; paint very large rectangle in black
                GP_call SetPattern;White                ; restore pattern to white (1,1,...)
                rts
WowRect         dw 0,0,10000,10000                      ; very large rectangle
;
; Draw filled and unfilled rectangles
;
DrawSomething equ *
test.0          equ *
                ldx LoopCounter                         ; LoopCounter is used as offset in Test0Table
                lda Test0Table,x                        ; if LoopCounter = 0, all TestTables then x = 1
                                                        ; and all drawings are made.
                                                        ; if LoopCounter = 1, only drawing 1 is made,
                                                        ; if LoopCounter = 2, only drawing 2 is made,
                                                        ; and so on...

                beq test_1                              ; if 0, jump to next drawing
;
                GP_call PaintRect;R1                    ; draw 2 ractangles
                ; PaintRect : Paints (fills) the interior of the specified rectangle with the current pattern.
                ; Parameters: a_rect: rect (Input) the rectangle to be painted
                GP_call PaintRect;R2
                GP_call FrameRect;R3                    ; frame 2 ractangles
                ; FrameRect : draws the boundary of the specified rectangle with the current pattern
                ; and current pen size. The pen's top-left corner traces the rectangle
                ; boundary so that the right and bottom edges of the frame extend outside
                ; of the rectangle boundary when the pen aize ia greater than 1.
                ; Parameters: a rect: rect (input) the rectangle to be framed
                GP_call FrameRect;R4
;
; draw a bunch of lines
;
test_1          equ *
                ldx LoopCounter                         ; LoopCounter is used as offset in Test1Table
                lda Test1Table,x                        ; get a flag in table
                beq test_2                              ; if 0, jump to next drawing
test_1_loop     equ *
                GP_call MoveTo;Point1                   ; move pen to upper left corner
                GP_call LineTo;Point2                   ; draw a line to bottom right corner
;
                lda Point2+2                            ; get y value of Point2
                clc
                adc #8
                sta Point2+2                            ; add 8
                cmp #192                                ; bottom of screen ?
                bcc test_1_loop                         ; no : loop to draw a new line
                lda #0                                  ; reset Point2.y to 0
                sta Point2+2
;
; draw some polygons and frame them
;
test_2          equ *
                ldx LoopCounter                         ; LoopCounter is used as offset in Test2Table
                lda Test2Table,x                        ; get a flag in table
                beq test_3                              ; if 0, jump to next drawing
;
                GP_call SetPenMode;ModeCopy
                ; SetPenMode : sets pen mode to  the value of the low byte of parameter. 
                ; The high byte is ignored.
                ; Parameters : penmode (pencopy, penOR, penXOR, penBIC, notpencopy, notpenOR, notpenXOR, notpenBIC)
                ; Pen modes :
                        ; Mode 0 (pencopy): Copy pen to destination.
                        ; Mode 1 (penOR): Overlay (OR) pen and destination.
                        ; Mode 2 (penXOR): Exclusive or (XOR) pen with destination.
                        ; Mode 3 (penBIC): Bit Clear (BIC) pen with destination ((NOT pen) AND destination).
                        ; Mode 4 (notpencopy): Copy inverse pen to destination.
                        ; Mode 5 (nocpenOR): Overlay (OR) inverse pen wich destination.
                        ; Mode 6 (notpenXOR): Exclusive or (XOR) inverse pen with destination.
                        ; Mode 7 (notpenBIC): Bit Clear (BIC) inverse pen with destination (pen AND destination)

                GP_call SetPattern;Color1
                ; SetPattern : sets the current pattern to the specified pattern. Subsequent drawing
                ; and painting commands will use this pattern until you call SetPattern
                ; again or change the pattern by calling the SetPort command.
                ; Parameters : a_pattern: pattern (input) the desired pattern

                GP_call PaintPoly;TestPoly
                ; Paint a A shape made of 2 poly. poly 1 makes outside of the A, poly 2 makes inside (hole).
                ; PaintPoly : paints (fills) the interior of the specified polygon(s)  with the current pattern.
                ; Parameters: a_polygon: polygon__list (input) polygons(s) to paint.
                ; Due to a restriction in the polygon-drawing algorithm, a polygon list
                ; cannot have more than eight peaks. (The mathematical term is strict 
                ; local maxima).
                ; A polygon is a list of vercices, each of which is a point. Polygons in
                ; the graphics primicives are defined as a list that contains one or more
                ; polygons. For each polygon in the list, there is a paramecer named
                ; LastPoly that determines whecher that polygon is the last one in the
                ; list. 
                GP_call SetPenMode;ModeNotOr
                ; SetPenMode : sets pen mode to  the value of the low byte of parameter. 

                GP_call FramePoly;TestPoly
                ; FramePoly : draws the boundary of the specified polygons(a) with the current pattern
                ; and currenc pen alze. The pen's top-left corner traces each polygon's
                ; boundary so that some edges of the frame extend outside the polygon
                ; boundary when the pen size is greater than 1.
                ; Parameters: a_polygon: polygon__list (input) polygons(s) to frame.
;
; draw some text
;
test_3          equ *
                ldx LoopCounter                         ; LoopCounter is used as offset in Test3Table
                lda Test3Table,x                        ; get a flag in table
                beq test_4                              ; if 0, jump to next drawing
;
                GP_call SetFont;TestFont
                ; SetFont : sets the current font to the font at address given in parameter.
                ; The font was presumably loaded using BLOAD or some other utility.
                ; The Applesoft interface has no way of loading or creating a font.
                ; Parameter : address of font loaded in memory.

                GP_call MoveTo;Point3
                GP_call DrawText;TestText
                ; DrawText : Draws the text scored at the specified address at the current pen
                ; locacion. Text is drawn in either black or white, wich the
                ; background in the inverse color. (See SetTextBG).
                ; Parameters:
                        ; textptr: pointer (input) address of text
                        ; textlen: byte (input) number of characters to use
;
; draw some bitmaps
;
test_4          equ *
                ldx LoopCounter                         ; loop countner is used as offset in Test4Table
                lda Test4Table,X                        ; get a flag in table
                beq test_5                              ; if 0 : rts
;
                GP_call SetPenMode;ModeCopy
                GP_call PaintBits;TestBits
                ; PaintBits : The PaintBits command draws the specified bitmap onto the bitmap
                ; specified by the current grafport.
                ; Parameters :
                        ; view location (x,y) on current grafport
                        ; bitmap address
                        ; width of bitmap (in low byte; high byte is ignored)
                        ; clip rectangle :
                                ; X-coordinate of upper-left corner
                                ; Y-coordinate of upper—left corner
                                ; X-coordinate of lower-right corner
                                ; Y-coordinate of lower-right corner
        ;
test_5          equ *
                rts
;
; Data for rects., polygons, bitmap, and text
;
TestPort        ds portlength                           ; space for TestPort (= standard grafport = screen grafport)
;
testrect1       dw 30,30,95,150                         ; a ractangle
testrect2       dw 200,50,520,140                       ; a ractangle
;
Point1          dw 0,0                                  ; upper left corner
Point2          dw 559,0                                ; bottom right corner
;
R1              dw 10,10,30,30                          ; a rect (x,y)
R2              dw 28,28,70,70                          ; a rect (x,y)
R3              dw 40,40,90,90                          ; a rect (x,y)
R4              dw 100,30,180,60                        ; a rect (x,y)
;
ModeNotOr       dfb 5
ModeCopy        dfb 0
;
Color1          dfb $66,$66,$66,$66,$66,$66,$66,$66,0   ; green pattern
Color2          dfb $11,$11,$11,$11,$11,$11,$11,$11,0   ; blue pattern
Color3          dfb $CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,0   ; orange pattern
weave           dfb $38,$74,$EE,$47,$83,$C5,$EE,$5C,0   ; nice pattern ! (yellow weave)

Black           dfb 0,0,0,0,0,0,0,0,0                   ; black pattern
White           ds 8,$FF                                ; white pattern
                dfb 0
;
                                                        ; A shape
TestPoly        dfb 8,$80                               ; 8 vertices, $80 : there is anather poly in this list
                dw 64,168,192,168,224,120,288,120,320,168,448,168,320,40,192,40
                ; dw 3                                  ; replaced by more readable :
                db 3                                    ; second poly of the list, 3 vertices 
                                                        ; makes a hole in first poly.
                db 0                                    ; $80 : last poly 
                dw 224,96,288,96,256,56
;
TestBits        dw 50,50                                ; view location on current port
                dw Handbits                             ; bitmap pointer
                dw 3                                    ; width of bitmap 
                dw 0,0,17,9                             ; clip rectangle
Handbits        dfb $00,$00,$00,$20,$00,$00,$30,$00,$00,$38,$00,$00     ; bitmap data
                dfb $5E,$7F,$07,$7E,$00,$00,$3E,$1F,$00,$7E,$00,$00
                dfb $3C,$0F,$00,$00,$00,$00
;
Point3          dw 4,50
;
;
TestText        dw message
                dfb msglength
message         asc 'This is a test of the emergency graphics system'
msglength       equ *-message
;
;
; MyPort          ds 50,0    
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
;
ContText        dw message1
                dfb msglgth
message1        asc ' Please press RETURN to continue. '
msglgth         equ *-message1
Point4          dw 30,190
Switch          dfb 8
;
QuitText        dw message2
                dfb msglgth1
message2        asc '      Please press RETURN to Quit..........                 '
msglgth1        equ *-message2
;
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
