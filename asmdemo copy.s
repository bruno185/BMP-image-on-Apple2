;
; Demo for Graphics Primitives            
;
GP_call     MAC                                         ; call to graphic primitives (macro)
                jsr GrafMLI                             ; graphic primitives only entry point
                dfb ]1                                  ; command ID (1 byte)
                da  ]2                                  ; address of parameter(s) (2 bytes), 0 if no paramter
                EOM
;
                org $1800
                put equates


MyBuffer        equ $8000                               ; starting address of storage for MyPort grafport
TestFont        equ $800                                ; loading address of "TEST.FONT" file
Bell            equ $FBDD                               ; play a sound
KeyBoard        equ $C000                               ; ascii code of last key pressed (+ 128 if strobe not cleared) 
Strobe          equ $C010                               ; Keyboard Strobe
;
; test stuff
;
* <bp>
                GP_call InitGraf;0
                ; InitGraf : sets the current port to the standard port and clears the screen.
                ; Parameters : None.

                ; 3 lines useless ?
                ;lda #0
                ;sta MyBits                              ; set upper-left corner of the viewport to 0,0
                ;sta MyBits+2
;
; set up a graf port
;
; Set up My port for drawing into
; buffer at $4000
                                                        ; offscreen graf port
                GP_call InitPort;MyPort
                ; InitPort : sets the specified GrafPort'a attributes to those 
                ; of the standard port.
                ; Parameters :
                        ; a_GrafPort :
                                ; portmap: mapinfo (see below)
                                ; penpattern: pattern
                                ; color-masks: maskrecord
                                ; penloc: point
                                ; penvidth: byte
                                ; penheight: byte
                                ; penmode: pmode
                                ; reserved: 0..31
                                ; textback: bits
                                ; textfont: pointer

                                ; The attributes of the standard port have the following values:
                                ; portmap:
                                        ; viewloc               (0,0)
                                        ; mapbits               $2000 (points to hi-res screen page 1)
                                        ; mapwidth              $80 (special value specifying a screen)
                                        ; maprect               (full screen)
                                        ;                       (for single-hi-rea  [(0,0), (279,191)])
                                        ;                       (for double-hi-res [(0,0), (559,191)]) 
                                
                                ; penpattern                    (white pattern)
                                        ; %llllllll,            (Row 1)
                                        ; %11111111,            (Row 2)            
                                        ; %llllllll,            (Row 3)            
                                        ; %llllllll,            (Row 4)              
                                        ; %llllllll,            (Row 5)              
                                        ; %llllllll,            (Row 6)              
                                        ; %llllllll,            (Row 7)              
                                        ; %llllllll,            (Row 8)             
; 
;                               ; color-masks                   $FF,0 (AND mask, OR mask)
;                               ; penloc                        (0,0) (upper-left corner of screen)
                                ; penvldth                      1
                                ; penheight                     1
                                ; penmode                       pencopy
                                ; text back                     0 (black background)
                                ; textfont                      0 (no font present)
*<bp>
                GP_call SetPort;MyPort
                ; SetPort : Sets the current GrafPort to the specified GrafPort. Subsequent calls to
                ; the primitives will use and update the attributes of the new GrafPort
                ; until SetPort is called again.
                ; Parameters : a_GrafPort (see above)

                GP_call SetPortBits;MyBits
                ; set up an offscreen 200x100 pixels area for MyPort grafport.
                ; SetPortBits : sets the current port's map information
                ; structure to the specified Maplnfo structure.
                ; Parameter : a_mapinfo: maplnfo :
                        ; viewloc: point (view location = upper-left corner of the viewport)
                        ; mapblts: pointer (to the bitmap that contains the graphic image)
                                ; In this area of memory, horizontal coordinates start at zero and
                                ; increase from left to right, and vertical coordinates start at zero and
                                ; increase from top to bottom. The first byte of the bitmap represents
                                ; the leftmost pixels of the topmost row of the image with the low-order
                                ; bit specifying the leftmost pixel. Only the least significant seven
                                ; bits are used for pixels; the eighth bit is the color flag. 
                                ; Some devices (like the AppleColor RGB adaptor card) make use of
                                ; this bit in double-hi-res.
                        ; mapwidth: byte : number of bytes used for each row of the bitmap (map width - (bits per row - 1) / 7 + 1).
                        ; reserved: byte
                        ; maprect: rect (clip rectangle = The clip rectangle specifies (in data coordinates) the area in the
                        ; bitmap to which drawing is clipped. It also specifies the size of the viewport.


; Now set up TestPort for drawing onto screen
                GP_call InitPort;TestPort
                GP_call SetPort;TestPort                ;  set grafport to screen
;
                lda #0
                sta LoopCounter                         ; init loop counter
                jsr DrawSomething ; Test the drawing code
                ; draw on screen directly : 4 ractangles (2 framed, 2 painted), lines, a polygon (A shape),
                ; a text, a bitmap (hand).

                GP_call MoveTo;Point4
                ; MoveTo : moves the current pen location to the specified point.
                ; Parameters: a_point: point (input) new pen location
                GP_call DrawText;ContText
                ; DrawText : Draws the text scored at the specified address at the current pen
                ; locacion. 
                jsr WaitForKeyPress                     ; wait a key from user
                inc LoopCounter                         ; now LoopCounter = 1
;
; Now tell user that we are drawing in to buffer so they will wait
;
MainLoop equ *
                GP_call MoveTo;Point4
                GP_call DrawText;BufText

                GP_call SetPort;MyPort                  ; now we draw offscreen !
;
; Now clear the buffer by drawing a large rect. in a pattern of black
;
                jsr ClearIt                             ; fill port with black
                jsr DrawSomething ; Draw into it        ; draw rects or lines or polys etc.,
                                                        ; draws lines or polygons depending on LoopCounter value
                
                GP_call SetPort;TestPort                ; set port to screen
                ; lda LoopCounter ; Move viewloc in MyBits      ; useless ?
                GP_call PaintBits;MyDestBits
                ; copy data from MyPort (offsreen) to current port (TestPort = screen)
                ; MyDestBits and and MyBits (= map_info of MyPort grafport) 
                ; point both to the same data buffer,
                ; so MyDestBits holds data previosly drawn by DrawSomething function (above)
                ; PaintBits : draws the specified bitmap onto the bitmap specified by the current grafport.
                ; Parameters :
                        ; view location (x,y) = 50,30 
                        ; bitmap address = same as MyPort map_info.
                        ; width of bitmap (in low byte; high byte is ignored) = 40
                        ; clip rectangle = 0,0,200,100 

; Now tell user to press return to continue
;
                GP_call MoveTo;Point4
                GP_call DrawText;ContText
                jsr WaitForKeyPress                     ; wait a key from user
;
                inc LoopCounter ; test to see if done
                lda LoopCounter
;
; Now see if we have gone through all 5 parts if not go to next part
; If we have tell user to press return to quit then set the soft switches
;
                cmp #6
                bcc MainLoop
                GP_call MoveTo;Point4
                GP_call DrawText;QuitText
                jsr WaitForKeyPress                     ; wait a key from user
                GP_call SetSwitches;Switch
                ; SetSwicches : sets the soft switches in the Apple II.
                ; Parameters :
                        ; Bits :
                        ; 4-7 not used
                        ; 3 
                                ; 0: TEXT Off (SC050) graphics on
                                ; 1: TEXT On (SC051) cext on
                        ; 2 
                                ; 0: MIXED Off (SC052) mixed mode off
                                ; 1: MIXED On (SC053) mixed mode on
                        ; 1 
                                ; 0: PAGE2 Off ($C054) page 1
                                ; 1: PAGE2 On (SC055) page 2
                        ; 0 
                                ; 0: HIRES Off (SC056) hi-res off
                                ; 1: HIRES On (SC057) hi-res on

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
; Wait for keypress
;
WaitForKeyPress equ *                                   ; wait a key from user
                jsr Bell                                ; play a sound
Wait            equ *
                bit Strobe                              ; test keybord input
                bpl Wait                                ; loop while no key pressed
                lda KeyBoard                            ; get kes value
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
