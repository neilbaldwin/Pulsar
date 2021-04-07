;---------------------------------------------------------------
; EDIT Instrument
;---------------------------------------------------------------

editInstrument:	
		.IF SRAM_MAP=32
		lda #SRAM_INSTRUMENT_BANK
		jsr setMMC1r1
		.ENDIF

		ldx editorCurrentInstrument
		lda editInstrumentAddressLo,x
		sta instrumentVector
		lda editInstrumentAddressHi,x
		sta instrumentVector+1
		ldy instrumentCursorY	;use Y (row) as index because only one column

		lda writeScreen
		beq @a
		jsr writeInstrumentScreen
		dec writeScreen
		beq @a
		jsr writeInstrumentHeaderFooter
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		lda #$00
		sta writeScreen

@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editInstrumentExit	;if changed, don't do any more keys
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_INSTRUMENT_BANK
		jsr setMMC1r1
		.ENDIF

		ldy instrumentCursorY	;use Y (row) as index because only one column
		
		jsr instrumentKeysHoldA_UDLR
		jsr instrumentKeysTapA
		jsr instrumentKeysTapB
		jsr instrumentKeysHoldSelect_UDLR
		jsr moveAroundEditor

editInstrumentExit:
		updateCursor instrumentCursorX,instrumentCursorY,instrumentCursorColumns,instrumentCursorRows,instrumentColumnCursorType
		jmp editorLoop


instrumentKeysHoldSelect_UDLR:
		;rts		;*new controls*
		lda PAD1_sel
		beq @x
		lda PAD1_fireb
		ora PAD1_firea
		bne @x
		lda PAD1_dud
		ora keysRepeatUD
		beq @noUD
		clc
		adc editorCurrentInstrument
		bpl @a
		lda #$00
		beq @b
@a:		cmp #NUMBER_OF_INSTRUMENTS
		bcs @x
@b:		sta editorCurrentInstrument
		lda #$02
		sta writeScreen
		rts
		
@noUD:		lda PAD1_dlr
		beq @x
		bmi instrumentCopyData
		jsr instrumentPasteData
@x:		rts

instrumentCopyData:	
		lda editorMode
		sta copyBufferObjectType
		
		ldx editorCurrentInstrument
		stx copyBufferObject
		lda editInstrumentAddressLo,x
		sta tmp0
		lda editInstrumentAddressHi,x
		sta tmp1
		ldy #$00
		sty copyBufferStartIndex
@copyLoop:	lda (tmp0),y
		sta copyBuffer,y
		iny
		cpy #(STEPS_PER_INSTRUMENT*BYTES_PER_INSTRUMENT_STEP)
		bcc @copyLoop
		sty copyBufferLength
@x:
		jsr editorUpdateCopyInfo
		rts

instrumentPasteData:	
		lda copyBufferObjectType
		bmi @x			;nothing to copy
		cmp editorMode
		bne @x			;wrong object type

		ldx editorCurrentInstrument
		lda editInstrumentAddressLo,x
		sta tmp0
		lda editInstrumentAddressHi,x
		sta tmp1
		ldy #$00
@b:		lda copyBuffer,y
		sta (tmp0),y
		iny
		cpy copyBufferLength
		bcc @b
@a:		lda #$01
		sta writeScreen
		
		rts
		
@x:		lda #ERROR_PASTE
		sta errorMessageNumber
		rts

instrumentKeysTapB:
		lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		lda instrumentClearValues,y
		sta (instrumentVector),y
		sta editBuffer
		jsr editInstrumentUpdateScreenValue
@x:		rts
		
instrumentKeysTapA:
		lda keysTapA
		beq @x
		
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		lda instrumentClearValues,y
		sta (instrumentVector),y
		sta editBuffer
		jsr editInstrumentUpdateScreenValue
		rts
		.ENDIF

@notDel:		lda PAD1_sel
		beq @notClone
		ldy instrumentCursorY	;use Y (row) as index because only one column
		cpy #INSTRUMENT_ROW_DUTY
		bne @notCloneDuty
		lda (instrumentVector),y
		cmp #$04			;if Duty < 4 then not Duty Table
		bcc @x
		sbc #$04			;subtract 4 to get Duty Table number
		jsr instrumentCloneDuty
		bcs @x			;carry set if pattern not cloned
		ldy instrumentCursorY
		clc
		adc #$04
		sta editBuffer
		jmp @notClone
		
@notCloneDuty:	cpy #INSTRUMENT_ROW_TABLE
		bne @x
		lda (instrumentVector),y
		cmp #$FF
		beq @x
		jsr instrumentCloneTable
		bcs @x
		ldy instrumentCursorY
		sta editBuffer
		
@notClone:	;lda keysHoldA
		;beq @x
		;lda editBuffer
		;dec editBufferFlag
		;sta (instrumentVector),y
		;jsr editInstrumentUpdateScreenValue
		
@x:		rts

instrumentKeysHoldA_UDLR:
		lda PAD1_fireb;keysHoldB
		beq @noB
		rts
@noB:		lda PAD1_firea;keysHoldA			;hold A + U/D/L/R = modify value
		bne @holdA
		lda editBufferFlag
		beq @x
		lda editBuffer
		sta (instrumentVector),y
@notEditing:	lda #$00
		sta editBufferFlag
		beq @x
@holdA:		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda (instrumentVector),y
		sta editBuffer
		
@editing:		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bpl @negative
		lda instrumentPositiveAdd,y
		jmp @addValue
@negative:	lda instrumentNegativeAdd,y		
@addValue:	clc
		adc editBuffer
		cpy #INSTRUMENT_ROW_GATE
		beq @notTop0
		cpy #INSTRUMENT_ROW_PSWEEP
		beq @notTop0
		cpy #INSTRUMENT_ROW_PSWEEPQ
		beq @notTop0
		cpy #INSTRUMENT_ROW_SWEEP
		beq @notTop0
		cpy #INSTRUMENT_ROW_DETUNE
		beq @notTop0
		and #$FF
		bpl @notNeg0
		lda #$00
		beq @notTop0
@notNeg0:		cmp instrumentMaxValues,y
		bcc @notTop0
		lda instrumentMaxValues,y
		sec
		sbc #$01
@notTop0:		sta editBuffer
		jsr editInstrumentUpdateScreenValue
@x:		rts


instrumentCloneDuty:
		rts
		
instrumentCloneTable:
		rts
		
		

instrumentClearValues:
		.BYTE $00			;envelope
		.BYTE $0F			;level
		.BYTE 0			;gate
		.BYTE $00			;duty
		.BYTE $FF			;table
		.BYTE 0			;psweep
		.BYTE 0			;psweep q
		.BYTE 0			;sweep
		.BYTE $FF			;vib
		.BYTE 0			;detune
		.BYTE 0			;hard
		.BYTE $FF			;echo
		
instrumentPositiveAdd:
		.BYTE $01			;envelope
		.BYTE $01			;level
		.BYTE $10			;gate
		.BYTE $01			;duty
		.BYTE $01			;table
		.BYTE $10			;psweep
		.BYTE $10			;psweepq
		.BYTE $10			;sweep
		.BYTE $01			;vib
		.BYTE $10			;detune
		.BYTE $01			;hard
		.BYTE $01			;echo
		
		
instrumentNegativeAdd:
		.BYTE -1			;envelope
		.BYTE -1			;level
		.BYTE -16			;gate
		.BYTE -1			;duty
		.BYTE -1			;table
		.BYTE -16			;psweep
		.BYTE -16			;psweepq
		.BYTE -16			;sweep
		.BYTE -1			;vib
		.BYTE -16			;detune
		.BYTE -1			;hard
		.BYTE -1			;echo

instrumentMaxValues:
		.BYTE NUMBER_OF_ENVELOPES
		.BYTE $10			;level
		.BYTE 0			;gate
		.BYTE NUMBER_OF_DUTY_TABLES+$04	
		.BYTE NUMBER_OF_TABLES
		.BYTE 0			;psweep
		.BYTE 0			;psweepq
		.BYTE 0			;sweep
		.BYTE NUMBER_OF_VIBRATOS
		.BYTE 0			;detune
		.BYTE $10			;hard
		.BYTE NUMBER_OF_ECHOES		;echo
				
writeInstrumentScreen:
		ldx #$00
		lda #CHR_SPACE
@a:		sta rowBuffer,x
		inx
		cpx #$20
		bcc @a

		lda #<windowInstrument
		sta tmp0
		lda #>windowInstrument
		sta tmp1
		ldy #$00
@c:		lda (tmp0),y
		sta windowBuffer,y
		iny
		cpy #(14*16)
		bcc @c

		ldx editorCurrentInstrument
		lda editInstrumentAddressLo,x
		sta tmp0
		lda editInstrumentAddressHi,x
		sta tmp1
	
		ldx #$00
		ldy #$00
@b:		lda instrumentRowTable,y
		tax
		lda (tmp0),y
		cpy #INSTRUMENT_ROW_DUTY
		bne @notDuty
		jsr instrumentPrintDuty
		jmp @d
@notDuty:		cpy #INSTRUMENT_ROW_TABLE
		beq @table
		cpy #INSTRUMENT_ROW_VIBRATO
		beq @table
		cpy #INSTRUMENT_ROW_ECHO
		beq @table
		;cpy #INSTRUMENT_ROW_AUX
		;beq @table
@normal:		jsr phexWindow
		jmp @d
@table:		cmp #$FF
		bne @normal
		printEmptyCell
@d:		iny
		cpy #instrumentModeRows
		bcc @b
		rts
		
writeInstrumentHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleInstrument,x
		sta titleBuffer,x
		lda headerInstrument,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		ldx #$0D			;print current chain number in title bar
		lda editorCurrentInstrument
		jsr phexTitle
		rts
		
editInstrumentUpdateScreenValue:
		pha
		lda instrumentRowTable,y
		tax
		pla
		cpy #INSTRUMENT_ROW_DUTY
		bne @notDuty
		jsr instrumentPrintDuty
		rts
@notDuty:		cpy #INSTRUMENT_ROW_VIBRATO
		beq @table
		cpy #INSTRUMENT_ROW_TABLE
		beq @table
		cpy #INSTRUMENT_ROW_ECHO
		beq @table
@normal:		jsr phexWindow
		rts
@table:		cmp #$FF
		bne @normal
		printEmptyCell
		rts
		

instrumentPrintDuty:
		cmp #$04
		bcs @hex
		asl a
		clc
		adc #CHR_DUTY_00
		sta windowBuffer,x
		inx
		adc #$01
		sta windowBuffer,x
		inx
		rts
@hex:		sbc #$04
		jmp phexWindow
		
instrumentRowTable:
		.REPEAT 16,i
		.BYTE 9 + 14 + (i * 14)
		.ENDREPEAT
		
instrumentCursorColumns:
		.BYTE $53 + (9 * 8)

instrumentCursorRows:
		.REPEAT 16,i
		.BYTE $30 + (i * 8)
		.ENDREPEAT

rowOffsetInstrument:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
	
columnOffsetInstrument:
		.BYTE 0
		
;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
instrumentColumnCursorType:
		.BYTE 2
		
