editDutyTable:
		.IF SRAM_MAP=32
		lda #SRAM_DUTY_BANK
		jsr setMMC1r1
		.ENDIF

		ldx dutyCursorY
		lda dutyRowsIndex,x
		ldx editorCurrentDuty
		clc
		adc editDutyAddressLo,x
		sta dutyVector
		lda editDutyAddressHi,x
		adc #$00
		sta dutyVector+1
		ldy dutyCursorX

		lda writeScreen		;need to write screen?
		beq @a
		jsr writeDutyScreen		;yes
		dec writeScreen		;if writeScreen was 1, only write main window, else		
		beq @a			;  write header and title too
		jsr writeDutyHeaderFooter
		dec writeScreen		;reset screen writing flag
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
	
@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editDutyExit		;if changed, don't do any more keys
	
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_DUTY_BANK
		jsr setMMC1r1
		.ENDIF

		ldy dutyCursorX
		jsr dutyKeysTapA
		jsr dutyKeysTapB
		jsr dutyKeysHoldA_UDLR
		jsr dutyKeysHoldSelect_UDLR
		jsr dutyKeysHoldAB_TapUDLR
		jsr moveAroundEditor

editDutyExit:
		updateCursor dutyCursorX,dutyCursorY,dutyCursorColumns,dutyCursorRows,dutyColumnCursorType
		jsr dutyPlayMarkers
		jmp editorLoop


dutyPlayMarkers:	ldx editorCurrentTrack
		cpx #$02
		bcs @x
		lda plyrCurrentInstrument,x
		tax
		lda editInstrumentAddressLo,x
		sta tmp0
		lda editInstrumentAddressHi,x
		sta tmp1
		ldy #INSTRUMENT_ROW_DUTY
		lda (tmp0),y
		sec
		sbc #$04
		bmi @x
		cmp editorCurrentDuty
		bne @x
		ldx editorCurrentTrack
		lda plyrDutyIndex,x
		tay
		lda dutyCursorRows,y
		sec
		sbc #$01
		sta SPR05_Y
		lda #SPR_RIGHT_ARROW
		sta SPR05_CHAR
		lda #26+48
		sta SPR05_X
@x:		rts

dutyKeysHoldAB_TapUDLR:
		lda PAD1_firea
		beq @x
		lda PAD1_fireb
		beq @x
		
		lda PAD1_dud
		beq @noUD
		bpl @down
		jsr dutyDeleteRow
		ldy dutyCursorX
		lda (dutyVector),y
		cmp #$FF
		beq @a
		sta editDutyLastValue,x
@a:		sta editBuffer
		lda #$01
		sta editBufferFlag
@a1:		lda #$01
		sta writeScreen
		rts

@down:		jsr dutyInsertRow
		ldy dutyCursorX
		lda (dutyVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		lda #$01
		sta editBufferFlag
		rts

@noUD:		lda PAD1_dlr
		beq @x
		
@x:		rts


dutyDeleteRow:	
		ldx editorCurrentDuty
		lda editDutyAddressLo,x
		sta tmp0
		lda editDutyAddressHi,x
		sta tmp1
		
		lda dutyCursorY
		cmp #STEPS_PER_DUTY_TABLE-1
		beq @x
		sta tmp2
		
@a:		ldy tmp2
		iny
		lda dutyRowsIndex,y
		tay
		lda (tmp0),y	;duty
		pha
		iny
		lda (tmp0),y	;delay
		pha
		iny
		lda (tmp0),y	;jump
		dey
		dey
		dey
		sta (tmp0),y	;jump
		dey
		pla
		sta (tmp0),y	;delay
		dey
		pla
		sta (tmp0),y	;duty
		inc tmp2
		lda tmp2
		cmp #STEPS_PER_DUTY_TABLE-1
		bne @a
		tay
		lda dutyRowsIndex,y
		tay
		lda #$00
		sta (tmp0),y
		iny
		sta (tmp0),y
		iny
		lda #$FF
		sta (tmp0),y
@x:		rts


		
dutyInsertRow:	ldx editorCurrentDuty
		lda editDutyAddressLo,x
		sta tmp0
		lda editDutyAddressHi,x
		sta tmp1
		
		lda dutyCursorY
		cmp #STEPS_PER_DUTY_TABLE-1
		beq @x
		tay
		lda dutyRowsIndex,y
		sta tmp2
		
		ldy #STEPS_PER_DUTY_TABLE-1
		lda dutyRowsIndex,y
		tay
@a:		dey
		lda (tmp0),y	;jmp
		pha
		dey
		lda (tmp0),y	;del
		pha
		dey
		lda (tmp0),y	;duty
		iny
		iny
		iny
		sta (tmp0),y	;duty
		iny
		pla
		sta (tmp0),y	;del
		iny
		pla
		sta (tmp0),y	;jmp
		dey
		dey
		dey
		dey
		dey
		bmi @x
		cpy tmp2
		beq @x
		bcs @a

@x:		rts

dutyKeysHoldSelect_UDLR:
		;rts		;*new controls*
		lda PAD1_sel
		beq @x
		lda PAD1_firea
		ora PAD1_fireb
		bne @x
		lda PAD1_dud
		ora keysRepeatUD
		beq @noUD
		clc
		adc editorCurrentDuty
		bpl @a
		lda #$00
		beq @b
@a:		cmp #NUMBER_OF_DUTY_TABLES
		bcs @x
@b:		sta editorCurrentDuty
		lda #$02
		sta writeScreen
		rts

@noUD:		lda PAD1_dlr
		beq @x
		bmi dutyCopyData
		jsr dutyPasteData
@x:		rts

dutyCopyData:	lda editorMode
		sta copyBufferObjectType
		
		ldx editorCurrentDuty
		stx copyBufferObject
		lda editDutyAddressLo,x
		sta tmp0
		lda editDutyAddressHi,x
		sta tmp1
		
		ldx #$00
		ldy dutyCursorY
		sty copyBufferStartIndex
		lda dutyRowsIndex,y
		tay
@copyLoop:	lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_DUTY_TABLE*BYTES_PER_DUTY_TABLE_STEP)
		bcc @copyLoop
		stx copyBufferLength
@x:		jsr editorUpdateCopyInfo
		rts

dutyPasteData:	lda copyBufferObjectType
		bmi @x			;nothing to copy
		cmp editorMode
		bne @x			;wrong object type

		ldx editorCurrentDuty
		lda editDutyAddressLo,x
		sta tmp0
		lda editDutyAddressHi,x
		sta tmp1
		ldy dutyCursorY
		lda dutyRowsIndex,y
		tay
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpx copyBufferLength
		bcs @a
		cpy #(STEPS_PER_DUTY_TABLE*BYTES_PER_DUTY_TABLE_STEP)
		bcc @b
@a:		lda #$01
		sta writeScreen
		
		rts
		
@x:		lda #ERROR_PASTE
		sta errorMessageNumber
		rts

dutyKeysHoldA_UDLR:
		lda PAD1_fireb;keysHoldB
		beq @noB
		rts
@noB:		lda PAD1_firea;keysHoldA			;hold A + U/D/L/R = modify value
		bne @doA
		lda editBufferFlag
		beq @x
		lda editBuffer
		sta (dutyVector),y
@notEditing:	lda #$00
		sta editBufferFlag
		rts
@doA:		ldy dutyCursorX
		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda (dutyVector),y
		sta editBuffer
		
@editing:		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		ldy dutyCursorX
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bpl @addNeg
		lda dutyPositiveAdd,y
		jmp @addValue
@addNeg:		lda dutyNegativeAdd,y
		
@addValue:	cpy #DUTY_COLUMN_DUTY
		bne @notDuty1
		asl a
		asl a
		asl a
		asl a
		asl a
		asl a
		clc
		adc editBuffer
		jmp @notTop
@notDuty1:	clc
		adc editBuffer
		bpl @notNeg
		lda #$00
		beq @notTop
@notNeg:		cmp dutyMaxValues,y
		bcc @notTop
		lda dutyMaxValues,y
@notTop:		
		sta editBuffer
		sta editDutyLastValue,y
		jsr editDutyUpdateScreenValue

@x:		rts
	
dutyKeysTapB:
		lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		lda dutyClearValues,y
		sta (dutyVector),y
		sta editBuffer
		jsr editDutyUpdateScreenValue
		ldy dutyCursorX
@x:		rts

dutyKeysTapA:
		ldy dutyCursorX
		lda keysTapA
		beq @x
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		lda dutyClearValues,y
		sta (dutyVector),y
		sta editBuffer
		jsr editDutyUpdateScreenValue
		ldy dutyCursorX
		rts
		.ENDIF
		
@notDel:
		lda editDutyLastValue,y
		sta (dutyVector),y
		sta editBuffer
		jsr editDutyUpdateScreenValue
		ldy dutyCursorX
@x:		rts

dutyNegativeAdd:
		.BYTE -1,-16,-11
	
dutyPositiveAdd:
		.BYTE 1,16,1

dutyMaxValues:
		.BYTE $00,$3F,$0F
		
dutyClearValues:	.BYTE $00,$00,$FF

editDutyUpdateScreenValue:
		pha
		ldx dutyCursorY
		lda rowOffsetDuty,x
		ldx dutyCursorX
		clc
		adc columnOffsetDuty,x
		tax

		ldy dutyCursorX
		cpy #DUTY_COLUMN_JUMP
		beq @jump
		cpy #DUTY_COLUMN_DUTY
		bne @delayEdited
		pla
		jsr dutyPrintDuty
		rts

@delayEdited:	pla
		jsr phexWindow
		rts
		
@jump:		pla
		cmp #$FF
		bne @a
		printEmptyCell
		rts
@a:		jsr phexWindow
		rts	


writeDutyScreen:
		ldx #$00
		ldy dutyFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #$20
		bcc @a
		
		ldx editorCurrentDuty
		lda editDutyAddressLo,x
		sta tmp0
		lda editDutyAddressHi,x
		sta tmp1
	
		ldx #$00
		ldy #$00
@b:		lda (tmp0),y
		jsr dutyPrintDuty
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y
		cmp #$FF
		bne @b0
		printEmptyCell
		jmp @b1
@b0:		jsr phexWindow
@b1:		lda #CHR_SPACE
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
		sta windowBuffer,x
		inx
		iny
		cpx #(14 * 16)
		bcc @b
		rts

dutyPrintDuty:	and #%11000000
		lsr a
		lsr a
		lsr a
		lsr a
		lsr a
		clc
		adc #CHR_DUTY_00
		sta windowBuffer,x
		inx
		adc #$01
		sta windowBuffer,x
		inx
		rts

writeDutyHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleDuty,x
		sta titleBuffer,x
		lda headerDuty,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		ldx #$0D			;print current chain number in title bar
		lda editorCurrentDuty
		jsr phexTitle
		rts

dutyCursorColumns:
		.REPEAT 4,i
		.BYTE $53+(i*24)
		.ENDREPEAT
		
dutyCursorRows:
		.REPEAT 16,i
		.BYTE $28+(i*8)
		.ENDREPEAT
		
rowOffsetDuty:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
		
		
columnOffsetDuty:
		.BYTE 0,3,6

;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
dutyColumnCursorType:
		.BYTE 2,2,2,2
