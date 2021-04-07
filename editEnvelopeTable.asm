
editEnvelopeTable:
		.IF SRAM_MAP=32
		lda #SRAM_ENVELOPE_BANK
		jsr setMMC1r1
		.ENDIF

		lda envelopeFirstRow
		clc
		adc envelopeCursorY
		tax
		lda envelopeRowsIndex,x
		clc
		adc envelopeCursorX
		sta envelopeIndex

		lda writeScreen		;need to write screen?
		beq @a
		jsr writeEnvelopeScreen	;yes
		dec writeScreen		;if writeScreen was 1, only write main window, else		
		beq @a			;  write header and title too
		jsr writeEnvelopeHeaderFooter
		dec writeScreen		;reset screen writing flag
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
	
@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editEnvelopeExit		;if changed, don't do any more keys
	
@b:		jsr processKeys
		
		.IF SRAM_MAP=32
		lda #SRAM_ENVELOPE_BANK
		jsr setMMC1r1
		.ENDIF

		ldy envelopeIndex
		ldx envelopeCursorX
		
		jsr envelopeKeysTapA
		jsr envelopeKeysTapB
		jsr envelopeKeysHoldA_UDLR
		jsr moveAroundEditor


editEnvelopeExit:
		updateCursor envelopeCursorX,envelopeCursorY,envelopeCursorColumns,envelopeCursorRows,envelopeColumnCursorType

		jmp editorLoop


envelopeKeysHoldA_UDLR:
		lda PAD1_fireb;keysHoldB
		beq @noB
		rts
@noB:		lda PAD1_firea;keysHoldA			;hold A + U/D/L/R = modify value
		bne @holdA
		lda editBufferFlag
		beq @x
		lda editBuffer
		sta SRAM_ENVELOPES,y
@notEditing:	lda #$00
		sta editBufferFlag
		beq @x
@holdA:		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda SRAM_ENVELOPES,y
		sta editBuffer
@editing:		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bpl @addNeg
		ldy envelopeCursorX
		lda envelopePositiveAdd,y
		ldy envelopeIndex
		jmp @addValue
@addNeg:		ldy envelopeCursorX
		lda envelopeNegativeAdd,y
		ldy envelopeIndex
				
@addValue:	clc
		adc editBuffer
		cpx #ENVELOPE_COLUMN_SUSTAIN
		bne @notTop
		and #$FF
		bpl @notNeg
		lda #$00
		beq @notTop
@notNeg:		cmp #$10
		bcc @notTop
		lda #$0F
@notTop:		sta editBuffer
		sta editEnvelopeLastValue,x
		jsr editEnvelopeUpdateScreenValue
@x:		rts

envelopeKeysTapB:	
		lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		lda envelopeClearValues,x
		sta SRAM_ENVELOPES,y
		sta editBuffer
		jmp editEnvelopeUpdateScreenValue
@x:		rts
	
envelopeKeysTapA:
		lda keysTapA
		beq @x
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		lda envelopeClearValues,x
		sta SRAM_ENVELOPES,y
		sta editBuffer
		jmp editEnvelopeUpdateScreenValue
		.ENDIF

@notDel:
		ldx envelopeCursorX
		lda editEnvelopeLastValue,x
		ldy envelopeIndex
		sta SRAM_ENVELOPES,y
		sta editBuffer
		jsr editEnvelopeUpdateScreenValue
@x:		rts


envelopeNegativeAdd:
		.BYTE -16,-16,-1,-16
	
envelopePositiveAdd:
		.BYTE 16,16,1,16
		
envelopeClearValues:
		.BYTE $00,$00,$0F,$00
		
editEnvelopeUpdateScreenValue:
		pha
		ldx envelopeCursorY
		lda rowOffsetEnvelope,x
		ldx envelopeCursorX
		clc
		adc columnOffsetEnvelope,x
		tax
		pla
		jsr phexWindow
		rts	


writeEnvelopeScreen:
		ldx #$00
		ldy envelopeFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #$20
		bcc @a
		
		ldy envelopeFirstRow
		lda envelopeRowsIndex,y
		tay
		ldx #$00
@b:		lda SRAM_ENVELOPES,y
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda SRAM_ENVELOPES,y
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda SRAM_ENVELOPES,y
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda SRAM_ENVELOPES,y
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

writeEnvelopeHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleEnvelope,x
		sta titleBuffer,x
		lda headerEnvelope,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		rts


envelopeCursorColumns:
		.REPEAT 4,i
		.BYTE $53+(i*24)
		.ENDREPEAT
		
envelopeCursorRows:
		.REPEAT 16,i
		.BYTE $28+(i*8)
		.ENDREPEAT
		
rowOffsetEnvelope:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
		
		
columnOffsetEnvelope:
		.BYTE 0,3,6,9

envelopeRowsIndex:
		.REPEAT NUMBER_OF_ENVELOPES,i
		.BYTE i*BYTES_PER_ENVELOPE
		.ENDREPEAT

;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
envelopeColumnCursorType:
		.BYTE 2,2,2,2
