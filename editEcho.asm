
editEchoTable:
		.IF SRAM_MAP=32
		lda #SRAM_ECHO_BANK
		jsr setMMC1r1
		.ENDIF

		lda echoFirstRow
		clc
		adc echoCursorY
		tax
		lda echoRowsIndex,x
		clc
		adc echoCursorX
		sta echoIndex
		tay
		ldx echoCursorX
		
		lda writeScreen		;need to write screen?
		beq @a
		jsr writeEchoScreen		;yes
		dec writeScreen		;if writeScreen was 1, only write main window, else		
		beq @a			;  write header and title too
		jsr writeEchoHeaderFooter
		dec writeScreen		;reset screen writing flag
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
	
@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editEchoExit		;if changed, don't do any more keys
	
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_ECHO_BANK
		jsr setMMC1r1
		.ENDIF

		ldy echoIndex
		jsr echoKeysTapA
		jsr echoKeysTapB
		jsr echoKeysHoldA_UDLR
		jsr moveAroundEditor

editEchoExit:
		updateCursor echoCursorX,echoCursorY,echoCursorColumns,echoCursorRows,echoColumnCursorType

		jmp editorLoop

echoKeysHoldA_UDLR:
		lda PAD1_fireb;keysHoldB
		beq @noB
		rts
@noB:		lda PAD1_firea;keysHoldA			;hold A + U/D/L/R = modify value
		bne @holdA
		lda editBufferFlag
		beq @x
		lda editBuffer
		sta SRAM_ECHOES,y
@notEditing:	lda #$00
		sta editBufferFlag
		beq @x
@holdA:		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda SRAM_ECHOES,y
		sta editBuffer

@editing:		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bpl @addNeg
		ldy echoCursorX
		lda echoPositiveAdd,y
		ldy echoIndex
		jmp @addValue
@addNeg:		ldy echoCursorX
		lda echoNegativeAdd,y
		ldy echoIndex		
@addValue:	clc
		;adc SRAM_ECHOES,y
		;sta SRAM_ECHOES,y
		adc editBuffer
		sta editBuffer
		ldx echoCursorX
		sta editEchoLastValue,x
		jsr editEchoUpdateScreenValue
@x:		rts
	
echoKeysTapB:
		lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		lda #$00
		sta SRAM_ECHOES,y
		sta editBuffer
		jmp editEchoUpdateScreenValue
@x:		rts

echoKeysTapA:	ldx echoCursorX
		lda keysTapA
		beq @x
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		lda #$00
		sta SRAM_ECHOES,y
		sta editBuffer
		jmp editEchoUpdateScreenValue
		.ENDIF
		
@notDel:
		lda editEchoLastValue,x
		ldy echoIndex
		sta SRAM_ECHOES,y
		sta editBuffer
		jsr editEchoUpdateScreenValue
@x:		rts

echoNegativeAdd:
		.BYTE -16,-16,-16,-16
	
echoPositiveAdd:
		.BYTE 16,16,16,16
		

editEchoUpdateScreenValue:
		pha
		ldx echoCursorY
		lda rowOffsetEcho,x
		ldx echoCursorX
		clc
		adc columnOffsetEcho,x
		tax
		pla
		jsr phexWindow
		rts	


writeEchoScreen:
		ldx #$00
		ldy echoFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #$20
		bcc @a
		
		ldy echoFirstRow
		lda echoRowsIndex,y
		tay
		ldx #$00
@b:		lda SRAM_ECHOES,y
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda SRAM_ECHOES,y
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda SRAM_ECHOES,y
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		iny
		cpx #224
		bcc @b
		
@x:		rts

writeEchoHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleEcho,x
		sta titleBuffer,x
		lda headerEcho,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		rts


echoCursorColumns:
		.REPEAT 3,i
		.BYTE $53+(i*24)
		.ENDREPEAT
		
echoCursorRows:
		.REPEAT 16,i
		.BYTE $28+(i*8)
		.ENDREPEAT
		
rowOffsetEcho:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
		
columnOffsetEcho:
		.BYTE 0,3,6



;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
echoColumnCursorType:
		.BYTE 2,2,2
