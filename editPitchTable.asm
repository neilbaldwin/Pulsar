
editTable:
		.IF SRAM_MAP=32
		lda #SRAM_TABLE_BANK
		jsr setMMC1r1
		.ENDIF

		ldx tableCursorY
		lda tableRowsIndex,x
		ldx editorCurrentTable
		clc
		adc editTableAddressLo,x
		sta tableVector
		lda editTableAddressHi,x
		adc #$00
		sta tableVector+1

		lda writeScreen		;need to write screen?
		beq @a
		jsr writeTableScreen		;yes
		dec writeScreen		;if writeScreen was 1, only write main window, else		
		beq @a			;  write header and title too
		jsr writeTableHeaderFooter
		dec writeScreen		;reset screen writing flag
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		jmp editorLoop

@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editTableExit		;if changed, don't do any more keys
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_TABLE_BANK
		jsr setMMC1r1
		.ENDIF

		ldy tableCursorX

		jsr tableHintSystem
		ldy tableCursorX
		jsr tableKeysTapA
		jsr tableKeysTapB
		jsr tableKeysHoldA_UDLR
		jsr tableKeysHoldAB_TapUDLR
		jsr tableKeysHoldSelect_UDLR
		jsr moveAroundEditor

editTableExit:
		jsr tablePlayMarkers		
		
		updateCursor tableCursorX,tableCursorY,tableCursorColumns,tableCursorRows,tableColumnCursorType
		jsr tableSmartTranspose
		jmp editorLoop


tableSmartTranspose:
		lda PAD1_firea
		beq @x
		lda PAD1_sel
		beq @x
		
		lda PAD1_dlr
		bne @transpose
		lda PAD1_dud
		eor #$FF
		clc
		adc #$01
		bne @transpose
		
@x:		rts

@transpose:	sta tmp4
		ldy editorCurrentTable
		lda editTableAddressLo,y
		sta tmp0
		lda editTableAddressHi,y
		sta tmp1
		ldy tableCursorX
		cpy #TABLE_COLUMN_FX1
		bcc @notCommand
		cpy #TABLE_COLUMN_FX2
		ldy #TABLE_COLUMN_FX2_DATA
		bcs @fx2
		ldy #TABLE_COLUMN_FX1_DATA
@fx2:		lda (tableVector),y
		sta tmp3
		dey
@notCommand:	lda (tableVector),y
		sta tmp2
		
		lda tableCursorX
		cmp #TABLE_COLUMN_PITCH
		beq @tranPitch
		cmp #TABLE_COLUMN_VOLUME
		beq @tranVol
		jmp @tranCom

@tranVol:		tay
		lda (tmp0),y
		ldx PAD1_dud
		beq @freeVol
		cmp tmp2
		bne @noVol
@freeVol:		clc
		adc tmp4
		bmi @noVol
		cmp #$10
		bcs @noVol
		sta (tmp0),y
@noVol:		tya
		clc
		adc #BYTES_PER_TABLE_STEP
		cmp #(STEPS_PER_TABLE * BYTES_PER_TABLE_STEP)
		bcc @tranVol
		ldy tableCursorX
		lda (tableVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		rts
		
@tranPitch:	tay
		lda (tmp0),y
		ldx PAD1_dud
		beq @freePitch
		cmp tmp2
		bne @noPitch
@freePitch:	clc
		adc tmp4
		sta (tmp0),y
@noPitch:		tya
		clc
		adc #BYTES_PER_TABLE_STEP
		cmp #(STEPS_PER_TABLE * BYTES_PER_TABLE_STEP)
		bcc @tranPitch
		ldy tableCursorX
		lda (tableVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		rts

@tranCom:		cmp #TABLE_COLUMN_FX1
		beq @tranCom1
		cmp #TABLE_COLUMN_FX2
		bne @comData
@tranCom1:	tay
		lda (tmp0),y
		cmp #$FF
		beq @noCom
		ldx PAD1_dud
		beq @freeCom
		cmp tmp2
		bne @noCom
@freeCom:		clc
		adc tmp4
		bmi @noCom
		cmp #COMMAND_Z
		bcs @noCom
		sta (tmp0),y
@noCom:		tya
		clc
		adc #BYTES_PER_TABLE_STEP
		cmp #(STEPS_PER_TABLE * BYTES_PER_TABLE_STEP)
		bcc @tranCom1
		ldy tableCursorX
		lda (tableVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		rts

@comData:		tay
		dey
		tya
@comData1:	tay
		lda (tmp0),y
		cmp #$FF
		beq @noComData
		ldx PAD1_dud
		beq @freeComData
		cmp tmp2
		bne @noComData
@freeComData:	iny
		lda (tmp0),y
		clc
		adc tmp4
		sta (tmp0),y
		dey
@noComData:	tya
		clc
		adc #BYTES_PER_TABLE_STEP
		cmp #(STEPS_PER_TABLE * BYTES_PER_TABLE_STEP)
		bcc @comData1
		ldy tableCursorX
		lda (tableVector),y
		sta editBuffer
		lda #$01
		sta writeScreen			
		rts		

tableHintSystem:
		ldy tableCursorX
		cpy #TABLE_COLUMN_FX1
		;beq @yes
		;cpy #TABLE_COLUMN_FX2
		;bne @x
		bcc @x
		
@yes:		lda PAD1_sel
		bne @x
		lda PAD1_firea
		bne @a
		lda hintMode
		beq @x
@c:		lda #$00
		sta hintMode
		lda #$01
		sta writeScreen
		rts

@a:		clc
		adc hintMode
		cmp #$20
		bcc @b
		lda editBuffer
		;cmp #$FF
		;beq @c
		ldy tableCursorX
		cpy #TABLE_COLUMN_FX1
		beq @d
		cpy #TABLE_COLUMN_FX2
		beq @d
		dey
		lda (tableVector),y
		cmp #$FF
		beq @x
@d:		ldy tableCursorY
		jsr editorShowHint
		rts
		
@b:		sta hintMode
@x:		rts

tableKeysHoldAB_TapUDLR:
		lda PAD1_firea
		beq @x
		lda PAD1_fireb
		beq @x
		
		lda PAD1_dud
		beq @noUD
		bpl @down
		jsr tableDeleteRow
		ldy tableCursorX
		lda (tableVector),y
		cmp #$FF
		beq @a
		sta editTableLastValue,x
@a:		sta editBuffer
		lda #$01
		sta editBufferFlag
@a1:		lda #$01
		sta writeScreen
		rts

@down:		jsr tableInsertRow
		ldy tableCursorX
		lda (tableVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		lda #$01
		sta editBufferFlag
		rts

@noUD:		lda PAD1_dlr
		beq @x
		
@x:		rts


tableDeleteRow:	
		ldx editorCurrentTable
		lda editTableAddressLo,x
		sta tmp0
		lda editTableAddressHi,x
		sta tmp1
		
		lda tableCursorY
		cmp #STEPS_PER_TABLE-1
		beq @x
		
		tay
		iny
		lda tableRowsIndex,y
		tay
		ldx #$00
@a:		lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_TABLE * BYTES_PER_TABLE_STEP)
		bcc @a

		lda tableCursorY
		tay
		lda tableRowsIndex,y
		tay
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpy #((STEPS_PER_TABLE-1) * BYTES_PER_TABLE_STEP)
		bcc @b
	
		ldy #STEPS_PER_TABLE-1
		lda tableRowsIndex,y
		tay
		
		lda #$0F
		sta (tmp0),y	;vol
		iny
		lda #$00
		sta (tmp0),y	;pitch
		iny
		lda #$FF
		sta (tmp0),y	;fx
		iny
		lda #$00
		sta (tmp0),y	;fx data
		iny
		lda #$FF
		sta (tmp0),y	;fx
		iny
		lda #$00
		sta (tmp0),y	;fx data
		
		lda #$FF
		sta copyBufferObjectType
		jsr editorUpdateCopyInfo
@x:		rts		

tableInsertRow:	ldx editorCurrentTable
		lda editTableAddressLo,x
		sta tmp0
		lda editTableAddressHi,x
		sta tmp1
		
		lda tableCursorY
		cmp #STEPS_PER_TABLE-1
		beq @x
		tay
		lda tableRowsIndex,y
		tay
		ldx #$00
@a:		lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_TABLE * BYTES_PER_TABLE_STEP)
		bcc @a
		
		lda tableCursorY
		tay
		iny
		lda tableRowsIndex,y
		tay
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpy #(STEPS_PER_TABLE * BYTES_PER_TABLE_STEP)
		bcc @b
		
		lda #$FF
		sta copyBufferObjectType
		jsr editorUpdateCopyInfo
		
@x:		rts



tablePlayMarkers:	ldx editorCurrentTrack
		lda editorInstrumentAddressLo,x
		sta tmp0
		lda editorInstrumentAddressHi,x
		sta tmp1
		ldy #INSTRUMENT_ROW_TABLE
		lda (tmp0),y
		cmp editorCurrentTable
		bne @x
		
		lda plyrTableIndex,x
		tay
		lda tableCursorRows,y
		sec
		sbc #$01
		sta SPR05_Y
		sta SPR06_Y
		lda #SPR_RIGHT_ARROW
		sta SPR05_CHAR
		lda #SPR_LEFT_ARROW
		sta SPR06_CHAR
		lda #26+48
		sta SPR05_X
		clc
		adc #14*8
		sta SPR06_X

@x:		rts	
tableKeysHoldSelect_UDLR:
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
		adc editorCurrentTable
		bpl @a
		lda #$00
		beq @b
@a:		cmp #NUMBER_OF_TABLES
		bcs @x
@b:		sta editorCurrentTable
		lda #$02
		sta writeScreen
		rts

@noUD:		lda PAD1_dlr
		beq @x
		bmi tableCopyData
		jsr tablePasteData
@x:		rts

tableCopyData:	lda editorMode
		sta copyBufferObjectType
		
		ldx editorCurrentTable
		stx copyBufferObject
		lda editTableAddressLo,x
		sta tmp0
		lda editTableAddressHi,x
		sta tmp1
		
		ldx #$00
		ldy tableCursorY
		sty copyBufferStartIndex
		lda tableRowsIndex,y
		tay
@copyLoop:	lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_TABLE*BYTES_PER_TABLE_STEP)
		bcc @copyLoop
		stx copyBufferLength
@x:		jsr editorUpdateCopyInfo
		rts

tablePasteData:	lda copyBufferObjectType
		bmi @x			;nothing to copy
		cmp editorMode
		bne @x			;wrong object type

		ldx editorCurrentTable
		lda editTableAddressLo,x
		sta tmp0
		lda editTableAddressHi,x
		sta tmp1
		ldy tableCursorY
		lda tableRowsIndex,y
		tay
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpx copyBufferLength
		bcs @a
		cpy #(STEPS_PER_TABLE*BYTES_PER_TABLE_STEP)
		bcc @b
@a:		lda #$01
		sta writeScreen
		
		rts
		
@x:		lda #ERROR_PASTE
		sta errorMessageNumber
		rts


tableKeysHoldA_UDLR:
		lda PAD1_fireb;keysHoldB
		beq @noB
@y:		rts
@noB:		lda PAD1_sel
		bne @y
		lda PAD1_firea;keysHoldA			;hold A + U/D/L/R = modify value
		bne @holdA
		lda editBufferFlag
		beq @x
		lda editBuffer
		sta (tableVector),y
@notEditing:	lda #$00
		sta editBufferFlag
		beq @x
@holdA:		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda (tableVector),y
		cpy #TABLE_COLUMN_PITCH
		beq @notEmpty
		cpy #TABLE_COLUMN_FX1_DATA
		beq @notEmpty
		cpy #TABLE_COLUMN_FX2_DATA
		beq @notEmpty		
		cmp #$FF
		bne @notEmpty
		lda editTableLastValue,y
@notEmpty:	sta editBuffer
		jsr editTableUpdateScreenValue
		ldy tableCursorX

@editing:		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bpl @negative
		lda tablePositiveAdd,y
		jmp @addValue
@negative:	lda tableNegativeAdd,y		
@addValue:	clc
		adc editBuffer
		cpy #TABLE_COLUMN_PITCH
		beq @noLimit1
		cpy #TABLE_COLUMN_FX1_DATA
		beq @noLimit1
		cpy #TABLE_COLUMN_FX2_DATA
		beq @noLimit1
		and #$FF
		bpl @notNeg0
		lda #$00
		beq @noLimit1
@notNeg0:		cmp tableMaxValues,y
		bcc @noLimit1
		lda tableMaxValues,y
		sec
		sbc #$01
@noLimit1:	sta editBuffer
		sta editTableLastValue,y
		jsr editTableUpdateScreenValue
@x:		rts

tableKeysTapB:
		lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		ldy tableCursorX
		lda tableClearValues,y
		sta (tableVector),y
		sta editBuffer
		jmp editTableUpdateScreenValue
@x:		rts

tableKeysTapA:	lda keysTapA
		beq @x
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		ldy tableCursorX
		lda tableClearValues,y
		sta (tableVector),y
		sta editBuffer
		jmp editTableUpdateScreenValue
		.ENDIF

@notDel:
		lda editTableLastValue,y
		sta (tableVector),y
		sta editBuffer
		jsr editTableUpdateScreenValue
		ldy tableCursorX
@x:		rts
	
tableClearValues:
		.BYTE $0F,$00,$FF,$00,$FF,$00
		
tableMaxValues:
		.BYTE $10,$00,(editorCommandsEnd-editorCommands),0,(editorCommandsEnd-editorCommands),0
		
tablePositiveAdd:
		.BYTE $01,$0C,$01,$10,$01,$10

tableNegativeAdd:
		.BYTE -1, -12, -1, -16, -1, -16

printTableCommand:
		cmp #$FF
		bne @a
		lda #CHR_EMPTY
		sta windowBuffer,x
		inx
		rts
		
@a:		sty tmp2
		tay
		lda editorCommands,y
		sta windowBuffer,x
		ldy tmp2
		inx
		rts
		



editTableUpdateScreenValue:
		sta tmp3
		ldx tableCursorY
		lda rowOffsetTable,x
		ldx tableCursorX
		clc
		adc columnOffsetTable,x
		tax
		lda tableCursorX
		
		lda tmp3
		cpy #TABLE_COLUMN_FX1
		bcs @a
		jmp phexWindow
		
@a:		beq @command
		cpy #TABLE_COLUMN_FX2
		beq @command
		
		dey
		lda (tableVector),y
		cmp #COMMAND_W
		bne @notDuty
		lda tmp3
		jmp instrumentPrintDuty
@notDuty:		lda tmp3
		jmp phexWindow
		
@command:		jsr printTableCommand
		lda tmp3
		cmp #COMMAND_W
		bne @notDuty2
		iny
		lda (tableVector),y
		jmp instrumentPrintDuty
@notDuty2:	iny
		lda (tableVector),y
		jmp phexWindow

		
writeTableScreen:
		ldx #$00
		ldy tableFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #$20
		bcc @a

		ldx editorCurrentTable
		lda editTableAddressLo,x
		sta tmp0
		lda editTableAddressHi,x
		sta tmp1
			
		ldx #$00
		lda tableFirstRow
		tay
		lda tableRowsIndex,y
		tay
@b:		lda (tmp0),y		;volume
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y		;pitch
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y		;FX1
		pha
		jsr printTableCommand
		iny
		pla
		cmp #COMMAND_W
		bne @notDuty1
		lda (tmp0),y
		jsr instrumentPrintDuty
		jmp @skipDuty1
@notDuty1:	lda (tmp0),y		;FX1 data
		jsr phexWindow
@skipDuty1:	lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y		;FX2
		pha
		jsr printTableCommand
		iny
		pla
		cmp #COMMAND_W
		bne @notDuty2
		lda (tmp0),y
		jsr instrumentPrintDuty
		jmp @skipDuty2
@notDuty2:	lda (tmp0),y		;FX1 data
		jsr phexWindow
@skipDuty2:	lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		cpx #(14 * 16)
		bcc @b
		rts

writeTableHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleTable,x
		sta titleBuffer,x
		lda headerTable,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		ldx #$08			;print current chain number in title bar
		lda editorCurrentTable
		jsr phexTitle
		rts
		

tableCursorColumns:
		.BYTE $53, $53+(3*8), $53+(6*8), $53+(7*8), $53+(10*8), $53+(11*8)
		
tableCursorRows:
		.REPEAT 16,i
		.BYTE $28 + (i * 8)
		.ENDREPEAT

rowOffsetTable:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
	
columnOffsetTable:
		.BYTE 0,3,6,7,10,11


;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
tableColumnCursorType:
		.BYTE 2,2,1,2,1,2

