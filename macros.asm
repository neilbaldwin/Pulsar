	.MACRO setdmapos _x,_y
	.LOCAL _scnadd
_scnadd 	= SCREEN+(_y*$20)+_x
	lda #>_scnadd
	sta $2006
	lda #<_scnadd
	sta $2006
	.ENDMACRO
	

;------------------------------------------------------------------------------
; Reset stub goes at end of every PRG bank
;------------------------------------------------------------------------------
		.MACRO resetStub
		.word 0,0,0, NMI, RESET, IRQ
		;lda #$80
		;sta $8000
		;jmp RESET
		;dw NMI,$FFF2,IRQ
		.ENDMACRO	
;------------------------------------------------------------------------------
; Print an "empty" cell i.e. "--"
;------------------------------------------------------------------------------
		.MACRO printEmptyCell
		lda #CHR_EMPTY
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		.ENDMACRO
;------------------------------------------------------------------------------
; Update Sprite Cursor based on current editor X/Y position
;------------------------------------------------------------------------------	
		.MACRO updateCursor _cursorX,_cursorY,_cursorColumns,_cursorRows,_cursorType
		lda _cursorX
		tax
		lda _cursorColumns,x
		sta tmp0
		sta SPR00_X			;update sprite position
		ldy #$01
		lda _cursorType,x
		bne @b
		lda #$FF
		sta SPR00_CHAR
		sta SPR01_CHAR
		bne @a
@b:		tax
		sty SPR00_CHAR
		iny
		iny
		sty SPR01_CHAR

		lda tmp0
		clc
		adc cursorTypeOffsetX0,x
		sta SPR00_X
	
		lda tmp0
		clc
		adc cursorTypeOffsetX1,x
		sta SPR01_X

		lda _cursorY
		tax
		lda _cursorRows,x
		sec
		sbc #$01
		sta SPR00_Y
		sta SPR01_Y
@a:
		.ENDMACRO


;------------------------------------------------------------------------------
; Process hold and double tap for any button
;------------------------------------------------------------------------------	

		.MACRO checkHoldTapAndDoubleTap _button,_buttonOld,_hold,_holdCounter,_tap,_doubleTap,_tapCounter
		lda #$00			;clear button status
		sta _doubleTap
		sta _tap
		;sta _hold
		lda _button		;is it pressed?
		bne @a			
		lda #$00			;no, clear hold counter
		sta _holdCounter
		lda _hold
		beq @d
		dec _hold
		bne @d
;		lda _holdCounter
;		beq @d
;		dec _holdCounter
@d:		lda _buttonOld		;pressed last frame too?
		beq @a
		lda _hold
		bne @c0
		lda _tapCounter		;no, has been released. In time for double?
		beq @c
		inc _doubleTap		;yes, set double tap flag	
		lda #$00			;clear up some flags
		sta _tapCounter
		sta _buttonOld
		beq @b			;exit
@c:		inc _tap			;not double tap set single tap flag
		lda #KEYS_DOUBLE_TAP_SPEED	;and double tap catch counter
		sta _tapCounter
@c0:		lda #$00			;clear/set old button
@a:		sta _buttonOld		;jump here if button pressed
		clc
		adc _holdCounter		;increment hold counter
		cmp #KEYS_REPEAT_DELAY
		bcs @holdMax		;reached limit at which key is determined held?
		sta _holdCounter		;no, update hold count
		bcc @skipMax
@holdMax:		;inc _hold			;yes, set hold flag
		lda #$02
		sta _hold
@skipMax:		;lda _hold
		;beq @e
		;lda #$00
		;sta _tapCounter
@e:		lda _tapCounter		;update tap (release) counter
		beq @b
		dec _tapCounter
		bne @b
		;inc _tap
@b:		rts


		.ENDMACRO

;------------------------------------------------------------------------------
; Process hold and double tapp for any button
;------------------------------------------------------------------------------	
	.MACRO checkKeyHoldAndDoubleTap button, debounced, doubleTap, tapCounter, hold, holdCounter
	lda #$00			;clear hold and tap flags every refresh
	sta doubleTap
	sta hold
	lda button			;B held down?
	bne @a
	sta holdCounter		;no, clear hold counter (A=0)
	beq @doTap			;nothing to do	
@a:	lda holdCounter		;has hold counter reached threshold?
	cmp #KEYS_HOLD_TIME
	bcs @b			;yes
	inc holdCounter		;no, increment hold counter
	bne @doTap				;nothing else to do yet
@b:	inc hold			;hold threshold reached, set hold flag
	
@doTap:	lda debounced		;button B tapped?
	beq @d			;no
	lda tapCounter		;yes, still counting from last tap? 
	beq @e			;no
	inc doubleTap		;yes, so this is double tap, set flag
@e:	lda #KEYS_DOUBLE_TAP_SPEED	;set
	sta tapCounter
@d:	lda tapCounter
	beq @f
	dec tapCounter
@f	rts
	.ENDMACRO
