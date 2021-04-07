;---------------------------------------------------------------
; EDIT FX
;---------------------------------------------------------------
editFx:
		;jmp editorLoop
		.IF SRAM_MAP=32
		lda #SRAM_FX_BANK
		jsr setMMC1r1
		.ENDIF

		ldx fxCursorY
		lda fxRowsIndex,x
		ldx editorCurrentFx
		clc
		adc editFxAddressLo,x
		sta fxVector
		lda editFxAddressHi,x
		adc #$00
		sta fxVector+1
		
		lda writeScreen
		beq @a
		jsr writeFxScreen
		dec writeScreen
		beq @a
		jsr writeFxHeaderFooter
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		lda #$00
		sta writeScreen
		jmp editorLoop

@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editFxExit		;if changed, don't do any more keys
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_FX_BANK
		jsr setMMC1r1
		.ENDIF

		ldy fxCursorX

		jsr fxKeysHoldA_UDLR
		ldy fxCursorX
		jsr fxKeysTapA
		jsr fxKeysTapB
		jsr fxKeysHoldAB_TapUDLR
		jsr fxKeysHoldSelect_UDLR
		jsr moveAroundEditor	;global routine for moving around editors
		
editFxExit:
		updateCursor fxCursorX,fxCursorY,fxCursorColumns,fxCursorRows,fxColumnCursorType
		jsr fxPlayMarkers
		jsr fxSmartTranspose
		jmp editorLoop


fxSmartTranspose:
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
		ldy editorCurrentFx
		lda editFxAddressLo,y
		sta tmp0
		lda editFxAddressHi,y
		sta tmp1
		ldy fxCursorX
		lda (fxVector),y
		sta tmp2
		lda #NUMBER_OF_NOTES
		sta tmp3
		
		lda fxCursorX
		cmp #FX_COLUMN_PITCH_A
		beq @tranPitch
		cmp #FX_COLUMN_PITCH_B
		beq @tranPitch
		cmp #FX_COLUMN_PITCH_C
		beq @tranPitch
		cmp #FX_COLUMN_PITCH_D
		beq @tranPitch
		cmp #FX_COLUMN_VOLUME_A
		beq @tranVol
		cmp #FX_COLUMN_VOLUME_B
		beq @tranVol
		cmp #FX_COLUMN_VOLUME_D
		beq @tranVol
		jmp @tranDuty

@tranVol:		tay
		dey
		lda (tmp0),y
		iny
		cmp #$FF
		beq @noVol
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
		adc #BYTES_PER_FX_TABLE_STEP
		cmp #(STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP)
		bcc @tranVol
		ldy fxCursorX
		lda (fxVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		rts
	
@tranPitch:	cmp #FX_COLUMN_PITCH_D
		bne @tranPitch1
		ldy #$10
		sty tmp3
@tranPitch1:	tay
		lda (tmp0),y
		cmp #$FF
		beq @noPitch
		ldx PAD1_dud
		beq @freePitch
		cmp tmp2
		bne @noPitch
@freePitch:	clc
		adc tmp4
		bmi @noPitch
		cmp tmp3
		bcs @noPitch
		sta (tmp0),y
@noPitch:		tya
		clc
		adc #BYTES_PER_FX_TABLE_STEP
		cmp #(STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP)
		bcc @tranPitch1
		ldy fxCursorX
		lda (fxVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		rts

@tranDuty:	tay
		lda tmp4
		asl a
		asl a
		asl a
		asl a
		asl a
		asl a
		sta tmp4
		tya
@tranDuty1:	tay
		dey
		dey
		lda (tmp0),y
		iny
		iny
		cmp #$FF
		beq @noDuty
		lda (tmp0),y
		ldx PAD1_dud
		beq @freeDuty
		cmp tmp2
		bne @noDuty
@freeDuty:	clc
		adc tmp4
		sta (tmp0),y
@noDuty:		tya
		clc
		adc #BYTES_PER_FX_TABLE_STEP
		cmp #(STEPS_PER_FX_TABLE* BYTES_PER_FX_TABLE_STEP)
		bcc @tranDuty1
		ldy fxCursorX
		lda (fxVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		rts

		
fxPlayMarkers:	lda plyrFxTable
		bmi @x
		cmp editorCurrentFx
		bne @x
		
		ldy plyrFxTableIndex
		cpy #$10
		bcs @x
		lda fxCursorRows,y
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

fxKeysHoldAB_TapUDLR:
		lda PAD1_firea
		beq @x
		lda PAD1_fireb
		beq @x
		
		lda PAD1_dud
		beq @noUD
		bpl @down
		jsr fxDeleteRow
		ldy fxCursorX
		lda (fxVector),y
		cmp #$FF
		beq @a
		sta editFxLastValue,y
@a:		sta editBuffer
		lda #$01
		sta editBufferFlag
@a1:		lda #$01
		sta writeScreen
		rts

@down:		jsr fxInsertRow
		ldy fxCursorX
		lda (fxVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		lda #$01
		sta editBufferFlag
		rts

@noUD:		lda PAD1_dlr
		beq @x
		
@x:		rts

fxDeleteRow:	
		ldx editorCurrentFx
		lda editFxAddressLo,x
		sta tmp0
		lda editFxAddressHi,x
		sta tmp1
		
		lda fxCursorY
		cmp #STEPS_PER_FX_TABLE-1
		beq @x
		
		tay
		iny
		lda fxRowsIndex,y
		tay
		ldx #$00
@a:		lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP)
		bcc @a

		lda fxCursorY
		tay
		lda fxRowsIndex,y
		tay
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpy #((STEPS_PER_FX_TABLE-1) * BYTES_PER_FX_TABLE_STEP)
		bcc @b
	
		ldy #STEPS_PER_FX_TABLE-1
		lda fxRowsIndex,y
		tay
		lda #$FF
		sta (tmp0),y	;note a
		iny
		lda #$0F
		sta (tmp0),y	;vol a
		iny
		lda #$80
		sta (tmp0),y	;duty a
		iny
		lda #$FF
		sta (tmp0),y	;note b
		iny
		lda #$0F
		sta (tmp0),y	;vol b
		iny
		lda #$80
		sta (tmp0),y	;duty b
		iny
		lda #$FF
		sta (tmp0),y	;note c
		iny
		lda #$FF
		sta (tmp0),y	;note d
		iny
		lda #$0F
		sta (tmp0),y	;vol d
		
		lda #$FF
		sta copyBufferObjectType
		jsr editorUpdateCopyInfo
@x:		rts		

fxInsertRow:	ldx editorCurrentFx
		lda editFxAddressLo,x
		sta tmp0
		lda editFxAddressHi,x
		sta tmp1
		
		lda fxCursorY
		cmp #STEPS_PER_FX_TABLE-1
		beq @x
		tay
		lda fxRowsIndex,y
		tay
		ldx #$00
@a:		lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP)
		bcc @a
		
		lda fxCursorY
		tay
		iny
		lda fxRowsIndex,y
		tay
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpy #(STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP)
		bcc @b
		
		lda #$FF
		sta copyBufferObjectType
		jsr editorUpdateCopyInfo
		
@x:		rts


fxKeysHoldSelect_UDLR:
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
		adc editorCurrentFx
		bpl @a
		lda #$00
		beq @b
@a:		cmp #NUMBER_OF_FX_TABLES
		bcs @x
@b:		sta editorCurrentFx
		lda #$02
		sta writeScreen
		rts

@noUD:		lda PAD1_dlr
		beq @x
		bmi fxCopyData
		jsr fxPasteData
@x:		rts

fxCopyData:	lda editorMode
		sta copyBufferObjectType
		
		ldx editorCurrentFx
		stx copyBufferObject
		lda editFxAddressLo,x
		sta tmp0
		lda editFxAddressHi,x
		sta tmp1
		
		ldx #$00
		ldy fxCursorY
		sty copyBufferStartIndex
@copyLoop:	lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_FX_TABLE*BYTES_PER_FX_TABLE_STEP)
		bcc @copyLoop
		stx copyBufferLength
@x:		jsr editorUpdateCopyInfo
		rts

fxPasteData:	lda copyBufferObjectType
		bmi @x			;nothing to copy
		cmp editorMode
		bne @x			;wrong object type

		ldx editorCurrentFx
		lda editFxAddressLo,x
		sta tmp0
		lda editFxAddressHi,x
		sta tmp1
		ldy fxCursorY
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpx copyBufferLength
		bcs @a
		cpy #(STEPS_PER_FX_TABLE*BYTES_PER_FX_TABLE_STEP)
		bcc @b
@a:		lda #$01
		sta writeScreen
		
		rts
		
@x:		lda #ERROR_PASTE
		sta errorMessageNumber
		rts


fxKeysHoldA_UDLR:
		lda PAD1_fireb;keysHoldB
		beq @noB
		rts
@noB:		lda PAD1_sel
		bne @x
		lda PAD1_firea;keysHoldA			;hold A + U/D/L/R = modify value
		bne @holdA
		lda editBufferFlag
		beq @x
		lda editBuffer
		sta (fxVector),y
@notEditing:	lda #$00
		sta editBufferFlag
		beq @x
@holdA:		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda (fxVector),y
		sta editBuffer
		
@editing:		ldy fxCursorX		
		lda keysRepeatLR
		ora PAD1_dlr
		beq @noLR
		cpy #FX_COLUMN_DUTY_A
		beq @dutyAdd
		cpy #FX_COLUMN_DUTY_B
		beq @dutyAdd
	 	bne @addValue
@noLR:		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bne @dutySkip
@dutyAdd:		eor #$FF
		clc
		adc #$01
@dutySkip:	bmi @posAdd
		lda fxNegativeAdd,y
		jmp @addValue
@posAdd:		lda fxPositiveAdd,y
		
@addValue:	clc
		adc editBuffer
		cpy #FX_COLUMN_DUTY_A
		beq @noLimit
		cpy #FX_COLUMN_DUTY_B
		beq @noLimit
		and #$FF
		bpl @notNeg
		lda #$00
		beq @noLimit
@notNeg:		cmp fxMaxValues,y
		bcc @noLimit
		lda fxMaxValues,y
@noLimit:		sta editBuffer
		sta editFxLastValue,y
		jsr editFxUpdateScreenValue
@x:		rts
		

fxKeysTapB:
		lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		lda fxClearValue,y
		sta (fxVector),y
		sta editBuffer
		jmp editFxUpdateScreenValue
@x:		rts
		
fxKeysTapA:	ldy fxCursorX
		lda keysTapA
		beq @a
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		lda fxClearValue,y
		sta (fxVector),y
		sta editBuffer
		jmp editFxUpdateScreenValue
		.ENDIF
		
@notDel:	
		lda editFxLastValue,y
		sta (fxVector),y
		sta editBuffer
		jsr editFxUpdateScreenValue
@a:		rts


fxClearValue:
		.BYTE $FF,$0F,$00,$FF,$0F,$00,$FF,$FF,$0F

fxPositiveAdd:	.BYTE 12		;pitch a
		.BYTE 1		;volume a
		.BYTE $40		;duty a
		.BYTE 12		;pitch b
		.BYTE 1		;volume b
		.BYTE $40		;duty b
		.BYTE 12		;pitch c
		.BYTE $10		;pitch d
		.BYTE 1		;volume a
		
fxNegativeAdd:	.BYTE -12		;pitch a
		.BYTE -1		;volume a
		.BYTE -$40	;duty a
		.BYTE -12		;pitch b
		.BYTE -1		;volume b
		.BYTE -$40	;duty b
		.BYTE -12		;pitch c
		.BYTE -$10	;pitch d
		.BYTE -1		;volume a

fxMaxValues:	.BYTE NUMBER_OF_NOTES-1
		.BYTE $0F
		.BYTE 0
		.BYTE NUMBER_OF_NOTES-1
		.BYTE $0F
		.BYTE 0
		.BYTE NUMBER_OF_NOTES-1
		.BYTE $1F
		.BYTE $0F
		

editFxUpdateScreenValue:
		pha
		ldx fxCursorY
		lda rowOffsetFx,x
		ldx fxCursorX
		clc
		adc columnOffsetFx,x
		tax
		pla
		ldy fxCursorX
		cpy #FX_COLUMN_DUTY_A
		beq @printDuty
		cpy #FX_COLUMN_DUTY_B
		beq @printDuty
		cpy #FX_COLUMN_VOLUME_A
		beq @printVolume
		cpy #FX_COLUMN_VOLUME_B
		beq @printVolume
		cpy #FX_COLUMN_VOLUME_D
		beq @printVolume

@printNote:	jmp phexWindow3		;note number

@printVolume:	and #$0F
		sta windowBuffer,x
		rts

@printDuty:	jmp fxPrintDuty

writeFxScreen:
		ldx #$00
		ldy fxFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #$20
		bcc @a

		ldx editorCurrentFx
		lda editFxAddressLo,x
		sta tmp0
		lda editFxAddressHi,x
		sta tmp1
	
		ldx #$00
		ldy #$00
@b:		lda (tmp0),y
		jsr phexWindow3		;note number
		iny
		lda (tmp0),y		;volume
		and #$0F
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y		;duty
		jsr fxPrintDuty

		iny
		lda (tmp0),y
		jsr phexWindow3		;note number
		iny
		lda (tmp0),y		;volume
		and #$0F
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y		;duty
		jsr fxPrintDuty
		iny

		lda (tmp0),y
		jsr phexWindow3		;note number
		iny
		
		lda (tmp0),y
		jsr phexWindow3		;note number
		iny
		lda (tmp0),y		;volume
		and #$0F
		sta windowBuffer,x
		inx
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		cpx #(14 * 16)
		bcc @b
		rts

fxPrintDuty:	and #%11000000
		lsr a
		lsr a
		lsr a
		lsr a
		lsr a
		lsr a
		clc
		adc #CHR_DUTY_00_SMALL
		sta windowBuffer,x
		inx
		rts
		
writeFxHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleFx,x
		sta titleBuffer,x
		lda headerFx,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		ldx #$06			;print current fx number in title bar
		lda editorCurrentFx
		jsr phexTitle
		rts
		

fxCursorColumns:
		.BYTE $53
		.BYTE $53+(2*8)
		.BYTE $53+(3*8)
		.BYTE $53+(4*8)
		.BYTE $53+(6*8)
		.BYTE $53+(7*8)
		.BYTE $53+(8*8)
		.BYTE $53+(10*8)
		.BYTE $53+(12*8)
	
		
fxCursorRows:
		.REPEAT 16,i
		.BYTE $28 + (i*8)
		.ENDREPEAT

rowOffsetFx:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
			
columnOffsetFx:
		.BYTE 0,2,3
		.BYTE 4,6,7
		.BYTE 8
		.BYTE 10,12
		
;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
fxColumnCursorType:
		.BYTE 2,1,1,2,1,1,2,2,1
		

