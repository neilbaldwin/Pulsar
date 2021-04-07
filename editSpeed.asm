;---------------------------------------------------------------
; EDIT CHAIN
;---------------------------------------------------------------
editSpeed:
		;jmp editorLoop
		.IF SRAM_MAP=32
		lda #SRAM_SPEED_BANK
		jsr setMMC1r1
		.ENDIF

		ldx editorCurrentSpeed
		lda editSpeedAddressLo,x
		sta speedVector
		lda editSpeedAddressHi,x
		sta speedVector+1

		lda writeScreen
		beq @a
		jsr writeSpeedScreen
		dec writeScreen
		beq @a
		jsr writeSpeedHeaderFooter
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		lda #$00
		sta writeScreen

@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editSpeedExit		;if changed, don't do any more keys
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_SPEED_BANK
		jsr setMMC1r1
		.ENDIF

		ldy speedCursorY
		
		jsr speedKeysHoldA_UDLR
		jsr speedKeysTapA
		jsr speedKeysTapB
		jsr speedKeysHoldAB_TapUDLR
		jsr speedKeysHoldSelect_UDLR
		jsr moveAroundEditor	;global routine for moving around editors
		
editSpeedExit:
		updateCursor speedCursorX,speedCursorY,speedCursorColumns,speedCursorRows,speedColumnCursorType
		jmp editorLoop

speedKeysHoldAB_TapUDLR:
		lda PAD1_firea
		beq @x
		lda PAD1_fireb
		beq @x
		
		lda PAD1_dud
		beq @noUD
		bpl @down
		jsr speedDeleteRow
		ldy speedCursorY
		lda (speedVector),y
		cmp #$FF
		beq @a
		sta editSpeedLastValue
@a:		sta editBuffer
		lda #$01
		sta editBufferFlag
@a1:		lda #$01
		sta writeScreen
		rts

@down:		jsr speedInsertRow
		ldy speedCursorY
		lda (speedVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		lda #$01
		sta editBufferFlag
		rts

@noUD:		lda PAD1_dlr
		beq @x
		
@x:		rts


speedDeleteRow:	
		ldx editorCurrentSpeed
		lda editSpeedAddressLo,x
		sta tmp0
		lda editSpeedAddressHi,x
		sta tmp1
		
		lda speedCursorY
		cmp #STEPS_PER_SPEED_TABLE-1
		beq @x
		tay
		
@a:		iny
		lda (tmp0),y	;duty
		dey
		sta (tmp0),y	;jump
		iny
		cpy #STEPS_PER_SPEED_TABLE-1
		bne @a
		tay
		lda #$FF
		sta (tmp0),y
@x:		rts


		
speedInsertRow:	ldx editorCurrentDuty
		lda editSpeedAddressLo,x
		sta tmp0
		lda editSpeedAddressHi,x
		sta tmp1
		
		lda speedCursorY
		cmp #STEPS_PER_SPEED_TABLE-1
		beq @x
		ldy #STEPS_PER_SPEED_TABLE-1

		
@a:		dey
		lda (tmp0),y	;jmp
		iny
		sta (tmp0),y	;duty
		dey
		bmi @x
		cpy speedCursorY
		beq @x
		bcs @a

@x:		rts

speedKeysHoldSelect_UDLR:
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
		adc editorCurrentSpeed
		bpl @a
		lda #$00
		beq @b
@a:		cmp #NUMBER_OF_SPEED_TABLES
		bcs @x
@b:		sta editorCurrentSpeed
		lda #$02
		sta writeScreen
		rts

@noUD:		lda PAD1_dlr
		beq @x
		bmi speedCopyData
		jsr speedPasteData
@x:		rts

speedCopyData:	lda editorMode
		sta copyBufferObjectType
		
		ldx editorCurrentSpeed
		stx copyBufferObject
		lda editSpeedAddressLo,x
		sta tmp0
		lda editSpeedAddressHi,x
		sta tmp1
		
		ldx #$00
		ldy speedCursorY
		sty copyBufferStartIndex
@copyLoop:	lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_SPEED_TABLE*BYTES_PER_SPEED_TABLE_STEP)
		bcc @copyLoop
		stx copyBufferLength
@x:		jsr editorUpdateCopyInfo
		rts

speedPasteData:	lda copyBufferObjectType
		bmi @x			;nothing to copy
		cmp editorMode
		bne @x			;wrong object type

		ldx editorCurrentSpeed
		lda editSpeedAddressLo,x
		sta tmp0
		lda editSpeedAddressHi,x
		sta tmp1
		ldy speedCursorY
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpx copyBufferLength
		bcs @a
		cpy #(STEPS_PER_SPEED_TABLE*BYTES_PER_SPEED_TABLE_STEP)
		bcc @b
@a:		lda #$01
		sta writeScreen
		
		rts
		
@x:		lda #ERROR_PASTE
		sta errorMessageNumber
		rts


speedKeysHoldA_UDLR:
		lda PAD1_fireb;keysHoldB
		beq @noB
		rts
@noB:		lda PAD1_firea;keysHoldA			;hold A + U/D/L/R = modify value
		bne @holdA
		lda editBufferFlag
		beq @x
		lda editBuffer
		sta (speedVector),y
@notEditing:	lda #$00
		sta editBufferFlag
		beq @x
@holdA:		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda (speedVector),y
		cmp #$FF
		bne @notEmpty
		lda editSpeedLastValue
@notEmpty:		sta editBuffer
		jsr editSpeedUpdateScreenValue
		ldy speedCursorY
	
@editing:		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bpl @subBig
		lda speedAddBig
		jmp @addValue
@subBig:		lda speedSubBig
@addValue:		clc
		;adc (speedVector),y
		adc editBuffer
		bpl @notTop
		cmp #$FF
		bcs @x
@notTop:		;sta (speedVector),y
		sta editBuffer
		sta editSpeedLastValue
		jsr editSpeedUpdateScreenValue
@x:		rts
		
speedKeysTapB:
		lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		lda speedClearValue
		sta (speedVector),y
		sta editBuffer
		jmp editSpeedUpdateScreenValue
@x:		rts
		
speedKeysTapA:	ldy speedCursorY
		lda keysTapA
		beq @a
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		lda speedClearValue
		sta (speedVector),y
		sta editBuffer
		jmp editSpeedUpdateScreenValue
		.ENDIF

@notDel:
		lda editSpeedLastValue
		sta (speedVector),y
		sta editBuffer
		jsr editSpeedUpdateScreenValue
@a:		rts


speedClearValue:
		.BYTE $FF

speedAddBig:	.BYTE 16
speedSubBig:	.BYTE -16


editSpeedUpdateScreenValue:
		pha
		ldy speedCursorY
		lda rowOffsetSpeed,y
		tax
		pla
		cmp #$FF
		beq @empty
@normal:		jmp phexWindow
@empty:		printEmptyCell
		rts

writeSpeedScreen:
		ldx #$00
		ldy speedFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #$20
		bcc @a

		ldx editorCurrentSpeed
		lda editSpeedAddressLo,x
		sta tmp0
		lda editSpeedAddressHi,x
		sta tmp1
	
		ldx #$00
		ldy #$00
@b:		lda (tmp0),y
		cmp #$FF
		bne @b1
		printEmptyCell
		jmp @b2
@b1:		jsr phexWindow
@b2:		lda #CHR_SPACE
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

writeSpeedHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleSpeed,x
		sta titleBuffer,x
		lda headerSpeed,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		ldx #$0E			;print current speed number in title bar
		lda editorCurrentSpeed
		jsr phexTitle
		rts
		

speedCursorColumns:
		.REPEAT 1,i
		.BYTE $53+(i * 24)
		.ENDREPEAT

speedCursorRows:
		.REPEAT 16,i
		.BYTE $28 + (i*8)
		.ENDREPEAT

rowOffsetSpeed:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
			
columnOffsetSpeed:
		.BYTE 0


		
;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
speedColumnCursorType:
		.BYTE 2
		
