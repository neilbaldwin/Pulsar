
editVibratoTable:
		.IF SRAM_MAP=32
		lda #SRAM_VIBRATO_BANK
		jsr setMMC1r1
		.ENDIF

		lda vibratoFirstRow
		clc
		adc vibratoCursorY
		tax
		lda vibratoRowsIndex,x
		clc
		adc vibratoCursorX
		sta vibratoIndex
		tay
		ldx vibratoCursorX
		
		lda writeScreen		;need to write screen?
		beq @a
		jsr writeVibratoScreen		;yes
		dec writeScreen		;if writeScreen was 1, only write main window, else		
		beq @a			;  write header and title too
		jsr writeVibratoHeaderFooter
		dec writeScreen		;reset screen writing flag
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
	
@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editVibratoExit		;if changed, don't do any more keys
	
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_VIBRATO_BANK
		jsr setMMC1r1
		.ENDIF

		ldy vibratoIndex
		jsr vibratoKeysTapA
		jsr vibratoKeysTapB
		jsr vibratoKeysHoldA_UDLR
		jsr moveAroundEditor

editVibratoExit:
		updateCursor vibratoCursorX,vibratoCursorY,vibratoCursorColumns,vibratoCursorRows,vibratoColumnCursorType

		jmp editorLoop

vibratoKeysHoldA_UDLR:
		lda PAD1_fireb;keysHoldB
		beq @noB
		rts
@noB:		lda PAD1_firea;keysHoldA			;hold A + U/D/L/R = modify value
		bne @holdA
		lda editBufferFlag
		beq @x
		lda editBuffer
		sta SRAM_VIBRATOS,y
@notEditing:	lda #$00
		sta editBufferFlag
		beq @x
@holdA:		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda SRAM_VIBRATOS,y
		sta editBuffer
@editing:		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bpl @addNeg
		ldy vibratoCursorX
		lda vibratoPositiveAdd,y
		ldy vibratoIndex
		jmp @addValue
@addNeg:		ldy vibratoCursorX
		lda vibratoNegativeAdd,y
		ldy vibratoIndex		
@addValue:	clc
		adc editBuffer
		cpy #VIBRATO_COLUMN_ACCELERATE
		bcs @noLimit
		and #$FF
		bpl @notNeg
		lda #$00
		beq @noLimit
@notNeg:		cmp vibratoMaxValues,y
		bcc @noLimit
		lda vibratoMaxValues,y
		sec
		sbc #$01
@noLimit:		sta editBuffer
		ldx vibratoCursorX
		sta editVibratoLastValue,x
		jsr editVibratoUpdateScreenValue
@x:		rts
	
vibratoKeysTapB:
		lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		lda #$00
		sta SRAM_VIBRATOS,y
		sta editBuffer
		jmp editVibratoUpdateScreenValue
@x:		rts

vibratoKeysTapA:	lda keysTapA
		beq @x
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		lda #$00
		sta SRAM_VIBRATOS,y
		sta editBuffer
		jmp editVibratoUpdateScreenValue
		.ENDIF

@notDel:		ldx vibratoCursorX
		lda editVibratoLastValue,x
		ldy vibratoIndex
		sta SRAM_VIBRATOS,y
		sta editBuffer
		jsr editVibratoUpdateScreenValue
@x:		rts

vibratoNegativeAdd:
		.BYTE -16,-16,-16,-16
	
vibratoPositiveAdd:
		.BYTE 16,16,16,16
		
vibratoMaxValues:	.BYTE $10,$20,0,0

editVibratoUpdateScreenValue:
		pha
		ldx vibratoCursorY
		lda rowOffsetVibrato,x
		ldx vibratoCursorX
		clc
		adc columnOffsetVibrato,x
		tax
		pla
		jsr phexWindow
		rts	


writeVibratoScreen:
		ldx #$00
		ldy vibratoFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #$20
		bcc @a
		
		ldy vibratoFirstRow
		lda vibratoRowsIndex,y
		tay
		ldx #$00
@b:		lda SRAM_VIBRATOS,y
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda SRAM_VIBRATOS,y
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda SRAM_VIBRATOS,y
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda SRAM_VIBRATOS,y
		jsr phexWindow
		lda #CHR_SPACE
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

writeVibratoHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleVibrato,x
		sta titleBuffer,x
		lda headerVibrato,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		rts


vibratoCursorColumns:
		.REPEAT 4,i
		.BYTE $53+(i*24)
		.ENDREPEAT
		
vibratoCursorRows:
		.REPEAT 16,i
		.BYTE $28+(i*8)
		.ENDREPEAT
		
rowOffsetVibrato:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
		
		
columnOffsetVibrato:
		.BYTE 0,3,6,9


;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
vibratoColumnCursorType:
		.BYTE 2,2,2,2
