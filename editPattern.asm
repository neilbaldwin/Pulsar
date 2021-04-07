	
editPattern:
		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF

		ldx patternCursorY
		lda patternRowsIndex,x
		ldx editorCurrentPattern
		clc
		adc editPatternAddressLo,x
		sta patternVector
		lda editPatternAddressHi,x
		adc #$00
		sta patternVector+1

		lda writeScreen		;need to write screen?
		beq @a
		jsr writePatternScreen		;yes
		dec writeScreen		;if writeScreen was 1, only write main window, else		
		beq @a			;  write header and title too
		jsr writePatternHeaderFooter
		dec writeScreen		;reset screen writing flag
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		jmp editorLoop
		

@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editPatternExit		;if changed, don't do any more keys
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF

		jsr patternHintSystem
		ldy patternCursorX
		jsr patternKeysHoldA_UDLR
		ldy patternCursorX
		jsr patternKeysTapA
		jsr patternKeysTapB
		ldy patternCursorX
		jsr patternKeysHoldB_UD
		jsr patternKeysSelect_UDLR
		jsr patternKeysHoldAB_TapUDLR
		lda PAD1_firea
		bne @c
		lda #$FF
		sta patternLastNote
		lda editPatternLastValue
		and #%01111111
		sta editPatternLastValue
@c:		jsr moveAroundEditor	;global routine for moving around editors
editPatternExit:
		updateCursor patternCursorX,patternCursorY,patternCursorColumns,patternCursorRows,patternColumnCursorType
		jsr patternPlayMarkers
		;lda #%11111111
		;sta PPU1
		jsr patternIsPatternEmpty
		;lda #%00011110
		;sta PPU1
		
		jsr patternSmartTranspose
		
		;jsr patternTapSelect
		;jsr patternBlock
		;jsr patternDisplayBlock
		jmp editorLoop


patternTapSelect:
		lda keysTapSel
		beq @doBlock
		lda PAD1_firea
		ora PAD1_fireb
		bne @doBlock
		lda blockMode
		eor #$FF
		sta blockMode
		beq @blockOff
		lda patternCursorY
		sta blockStart
		sta blockEnd
		sta blockOrigin
		rts
		
@blockOff:	lda #$01
		sta writeScreen
		lda #$00
		sta blockMode
		lda #$FF
		sta blockStart
		sta blockEnd
		sta blockOrigin
@doBlock:		rts

		
patternBlock:	lda blockMode
		beq @x

		lda patternCursorY
		cmp blockOrigin
		bcs @end
		
		cmp blockStart
		beq @a
		bcc @a
		
		;lda blockStart
		;jsr patternBlockUnmark
		lda patternCursorY
		sta blockStart
		rts

@a:		sta blockStart
		;jsr patternBlockMark
		rts
		
@end:		cmp blockEnd
		bcs @b
		;lda blockEnd
		;jsr patternBlockUnmark
		lda patternCursorY
		sta blockEnd
		rts

@b:		sta blockEnd
		bne @c
		lda blockStart
		cmp blockOrigin
		bcs @c
		;jsr patternBlockUnmark
		lda blockOrigin
		sta blockStart
		
		
@c:		;lda blockEnd
		;jsr patternBlockMark
		
	
		
@x:		rts

patternDisplayBlock:
		lda blockMode
		beq @x
		lda blockEnd
		sec
		sbc blockStart
		sta tmp0
		
		lda blockStart
		tax
		lda rowOffsetPattern,x
		tax
@b:		ldy #$00
@a:		lda windowBuffer,x
		ora #$40
		sta windowBuffer,x
		inx
		iny
		cpy #10
		bcc @a
		inx
		inx
		inx
		inx
		dec tmp0
		bpl @b
		lda #$01
		sta writeScreen
@x:		rts
		
patternSmartTranspose:
		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF
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
		ldy editorCurrentPattern
		lda editPatternAddressLo,y
		sta tmp0
		lda editPatternAddressHi,y
		sta tmp1
		ldy patternCursorX
		cpy #PATTERN_COLUMN_COMMAND
		bcc @notCommand
		ldy #PATTERN_COLUMN_COMMAND_DATA
		lda (patternVector),y
		sta tmp3
		dey
@notCommand:	lda (patternVector),y
		sta tmp2
	
		lda patternCursorX
		cmp #PATTERN_COLUMN_NOTE
		beq @notCom1
		cmp #PATTERN_COLUMN_INSTRUMENT
		beq @tranIns
		jmp @tranCom

@tranIns:		tay
		lda (tmp0),y
		cmp #$FF
		beq @noIns
		ldx PAD1_dud
		beq @freeIns
		cmp tmp2
		bne @noIns
@freeIns:		clc
		adc tmp4
		bmi @noIns
		cmp #NUMBER_OF_INSTRUMENTS
		bcs @noIns
		sta (tmp0),y
@noIns:		tya
		clc
		adc #BYTES_PER_PATTERN_STEP
		cmp #(STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP)
		bcc @tranIns
		ldy patternCursorX
		lda (patternVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		rts
		
@notCom1:		tay
		lda (tmp0),y
		cmp #$FF
		beq @noNote
		ldx PAD1_dud
		beq @free
		cmp tmp2
		bne @noNote
@free:		clc
		adc tmp4
		cmp #$FF
		beq @noNote
		cmp #NUMBER_OF_NOTES + $80
		bcs @noNote
		sta (tmp0),y
@noNote:		tya
		clc
		adc #BYTES_PER_PATTERN_STEP
		cmp #(STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP)
		bcc @notCom1
		lda #$01
		sta writeScreen
		lda patternCursorX
		cmp #PATTERN_COLUMN_NOTE
		bne @x2
		lda #$00
		sta editorPlayingNote
		ldy patternCursorX
		lda (patternVector),y
		sta editBuffer
		and #$7F
		jmp patternPlayNote
@x2:		rts

@tranCom:		cmp #PATTERN_COLUMN_COMMAND
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
		adc #BYTES_PER_PATTERN_STEP
		cmp #(STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP)
		bcc @notCom1
		ldy patternCursorX
		lda (patternVector),y
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
		adc #BYTES_PER_PATTERN_STEP
		cmp #(STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP)
		bcc @comData1
		ldy patternCursorX
		lda (patternVector),y
		sta editBuffer
		lda #$01
		sta writeScreen			
		rts		

patternHintSystem:
		ldy patternCursorX
		cpy #PATTERN_COLUMN_COMMAND
		bcc @x
		lda PAD1_sel
		bne @x
		lda PAD1_firea
		bne @a
		lda hintMode
		beq @x
@c:		lda #$00
		sta hintMode
		lda #$81
		sta writeScreen
		rts

@a:		clc
		adc hintMode
		cmp #$20
		bcc @b
		lda editBuffer
		;cmp #$FF
		;beq @c
		ldy patternCursorX
		cpy #PATTERN_COLUMN_COMMAND
		beq @d
		dey
		lda (patternVector),y
		cmp #$FF
		beq @x
@d:		ldy patternCursorY
		jsr editorShowHint
		rts
		
@b:		sta hintMode
@x:		rts
		

patternPlayMarkers: ldx editorCurrentTrack
		lda plyrCurrentPattern,x
		cmp editorCurrentPattern
		bne @x
		lda plyrPatternIndex,x
		sec
		sbc #$01
		and #STEPS_PER_PATTERN-1
		tay
		lda patternCursorRows,y
		sec
		sbc #$01
		sta SPR05_Y
		sta SPR06_Y
		lda #SPR_RIGHT_ARROW
		sta SPR05_CHAR
		lda hintMode
		cmp #$1F
		bcs @x

		lda #SPR_LEFT_ARROW
		sta SPR06_CHAR
		lda #26+48
		sta SPR05_X
		clc
		adc #11*8
		sta SPR06_X

@x:		rts		
				

patternKeysHoldAB_TapUDLR:
		;lda keysHoldA
		;beq @x
		;lda keysHoldB
		;beq @x
		lda PAD1_firea
		beq @x
		lda PAD1_fireb
		beq @x
		
		lda PAD1_dud
		beq @noUD
		bpl @down
		jsr patternDeleteRow
		ldy patternCursorX
		lda (patternVector),y
		cmp #$FF
		beq @a
		sta editPatternLastValue,x
@a:		sta editBuffer
		lda #$01
		sta editBufferFlag
@a1:		lda #$81
		sta writeScreen
		rts

@down:		jsr patternInsertRow
		ldy patternCursorX
		lda (patternVector),y
		sta editBuffer
		lda #$81
		sta writeScreen
		lda #$01
		sta editBufferFlag
		rts

@noUD:		lda PAD1_dlr
		beq @x
		
@x:		rts


patternDeleteRow:	
		ldx editorCurrentPattern
		lda editPatternAddressLo,x
		sta tmp0
		lda editPatternAddressHi,x
		sta tmp1
		
		lda patternCursorY
		cmp #STEPS_PER_PATTERN-1
		beq @x
		sta tmp2
		
@a:		ldy tmp2
		iny
		lda patternRowsIndex,y
		tay
		lda (tmp0),y	;note
		pha
		iny
		lda (tmp0),y	;ins
		pha
		iny
		lda (tmp0),y	;fx
		pha
		iny
		lda (tmp0),y	;fx data
		dey
		dey
		dey
		dey
		sta (tmp0),y	;fx data
		dey
		pla
		sta (tmp0),y	;fx
		dey
		pla
		sta (tmp0),y	;ins
		dey
		pla
		sta (tmp0),y	;note
		inc tmp2
		lda tmp2
		cmp #STEPS_PER_PATTERN-1
		bne @a
		tay
		lda patternRowsIndex,y
		tay
		lda #$FF
		sta (tmp0),y
		iny
		sta (tmp0),y
		iny
		sta (tmp0),y
		iny
		lda #$00
		sta (tmp0),y
@x:		rts


		
patternInsertRow:	ldx editorCurrentPattern
		lda editPatternAddressLo,x
		sta tmp0
		lda editPatternAddressHi,x
		sta tmp1
		
		lda patternCursorY
		cmp #STEPS_PER_PATTERN-1
		beq @x
		tay
		lda patternRowsIndex,y
		sta tmp2
		
		ldy #STEPS_PER_PATTERN-1
		lda patternRowsIndex,y
		tay
@a:		dey
		lda (tmp0),y	;fx data
		pha
		dey
		lda (tmp0),y	;fx
		pha
		dey
		lda (tmp0),y	;ins
		pha
		dey
		lda (tmp0),y	;note
		iny
		iny
		iny
		iny
		sta (tmp0),y	;note
		iny
		pla
		sta (tmp0),y	;ins
		iny
		pla
		sta (tmp0),y	;fx
		iny
		pla
		sta (tmp0),y	;fx data
		dey
		dey
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

patternKeysSelect_UDLR:
		lda PAD1_sel
		beq @x
		lda PAD1_fireb
		ora PAD1_firea
		bne @x
		
		lda PAD1_dud
		ora keysRepeatUD
		beq @noUD
		clc
		adc editorCurrentPattern
		bpl @a
		lda #$00
		beq @b
@a:		cmp #NUMBER_OF_PATTERNS
		bcs @x
@b:		sta editorCurrentPattern
		lda #$02
		sta writeScreen
		jmp @x
		
@noUD:		lda PAD1_dlr
		beq @x
		bmi patternCopyData
		jsr patternPasteData

@x:		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF
		rts
		
patternKeysHoldB_UD:
		lda PAD1_sel
		beq @x
		lda keysHoldB
		beq @x
		lda PAD1_firea
		bne @x
		lda PAD1_dud
		beq @x
		
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		ldx editorCurrentChain
		lda editChainAddressLo,x
		sta chainVector
		lda editChainAddressHi,x
		sta chainVector+1
		lda editChainIndex
		clc
		adc PAD1_dud
		bmi @x
		cmp #STEPS_PER_CHAIN
		bcs @x
		asl a
		tay
		lda (chainVector),y
		cmp #$FF
		beq @x
		sta editorCurrentPattern
		tya
		lsr a
		sta editChainIndex
		lda #$02
		sta writeScreen

@x:		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF
			
		rts


patternCopyData:	lda editorMode
		sta copyBufferObjectType
		
		ldx editorCurrentPattern
		stx copyBufferObject
		lda editPatternAddressLo,x
		sta tmp0
		lda editPatternAddressHi,x
		sta tmp1
		
		ldx #$00
		ldy patternCursorY
		sty copyBufferStartIndex
		lda patternRowsIndex,y
		tay
@copyLoop:	lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_PATTERN*BYTES_PER_PATTERN_STEP)
		bcc @copyLoop
		stx copyBufferLength
@x:
		jsr editorUpdateCopyInfo
		rts

patternPasteData:	lda copyBufferObjectType
		bmi @x			;nothing to copy
		cmp editorMode
		bne @x			;wrong object type

		ldx editorCurrentPattern
		lda editPatternAddressLo,x
		sta tmp0
		lda editPatternAddressHi,x
		sta tmp1
		ldy patternCursorY
		lda patternRowsIndex,y
		tay
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpx copyBufferLength
		bcs @a
		cpy #(STEPS_PER_PATTERN*BYTES_PER_PATTERN_STEP)
		bcc @b
@a:		lda #$01
		sta writeScreen
		rts
		
@x:		lda #ERROR_PASTE
		sta errorMessageNumber
		rts


patternKeysHoldA_UDLR:
		lda PAD1_fireb
		ora PAD1_sel
		beq @noB
@x2:		rts
@noB:		lda PAD1_firea
		bne @holdA
		lda editBufferFlag
		beq @x2
		lda editBuffer
		sta (patternVector),y
@notEditing:	
		lda #$00
		sta editBufferFlag
		lda editBuffer
		jsr editPatternUpdateScreenValue
		ldy editorCurrentTrack
		lda plyrKillCounter,y
		bne @killing
		lda #$00
		sta editorPlayingNote
@killing:		jmp @x
@holdA:		ldy patternCursorX
		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda (patternVector),y
		cpy #PATTERN_COLUMN_COMMAND_DATA
		beq @notEmpty
		cmp #$FF
		bne @notEmpty
		lda editPatternLastValue,y
@notEmpty:	sta editBuffer
		jsr editPatternUpdateScreenValue
		lda PAD1_fireb
		bne @noNote	
		
@editing:		jsr patternPlayNote
@noNote:		ldy patternCursorX		
		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bpl @negative
		lda patternPositiveAdd,y
		jmp @addValue
@negative:	lda patternNegativeAdd,y
@addValue:	clc
		adc editBuffer
		cpy #PATTERN_COLUMN_NOTE
		bne @notNote
		and #$FF
		bmi @negNote
		cmp #$70
		bcc @negNote1
		lda #$80
		jmp @noLimit
@negNote1:	cmp #NUMBER_OF_NOTES
		bcc @noLimit
		lda #NUMBER_OF_NOTES
		jmp @noLimit
@negNote:		cmp #$F0
		bcc @negNote0
		lda #$00
		beq @noLimit
@negNote0:	cmp #NUMBER_OF_NOTES+$80
		bcc @noLimit
		lda #NUMBER_OF_NOTES+$80
		jmp @noLimit
		
@notNote:		cpy #PATTERN_COLUMN_COMMAND_DATA
		beq @noLimit
		and #$FF
		bpl @notNeg
		lda #$00
		beq @noLimit
@notNeg:		cmp patternMaxValues,y
		bcc @noLimit
		lda patternMaxValues,y
		sec
		sbc #$01
@noLimit:		sta editPatternLastValue,y
		sta editBuffer
		jsr editPatternUpdateScreenValue		
		lda #$00
		sta editorPlayingNote
@x:		rts

patternKeysTapB:
		lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		lda patternClearValues,y
		sta (patternVector),y
		sta editBuffer
		jsr editPatternUpdateScreenValue
@x:		rts
		
patternKeysTapA:	lda keysTapA
		beq @x
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		lda patternClearValues,y
		sta (patternVector),y
		sta editBuffer
		jsr editPatternUpdateScreenValue
		rts
		.ENDIF
	
@notDel:		lda PAD1_sel
		beq @notSel
		cpy #PATTERN_COLUMN_NOTE
		bne @x
		lda (patternVector),y
		eor #$80
		sta (patternVector),y
		jsr editPatternUpdateScreenValue
		rts	

@notSel:
		lda editPatternLastValue,y
		sta editBuffer
		sta (patternVector),y
		sta editBuffer
		jsr editPatternUpdateScreenValue
		jsr patternPlayNote2

@x:		rts

patternIsPatternEmpty:	
		ldx editorCurrentPattern
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_PATTERN_FLAGS,x
		and #%11111101
		sta SRAM_PATTERN_FLAGS,x
		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF

		ldx editorCurrentPattern
		lda editPatternAddressLo,x
		sta tmp0
		lda editPatternAddressHi,x
		sta tmp1
		
		ldy #$00
@a:		lda (tmp0),y
		cmp #$FF
		bne @notEmpty
		iny
		lda (tmp0),y
		cmp #$FF
		bne @notEmpty
		iny
		lda (tmp0),y
		cmp #$FF
		bne @notEmpty
		iny
		iny
		cpy #(STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP)
		bcc @a
		rts
@notEmpty:	.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_PATTERN_FLAGS,x
		ora #%00000010
		sta SRAM_PATTERN_FLAGS,x
		rts

patternClearValues:
		.BYTE $FF,$FF,$FF,$00
		
patternMaxValues:
		.BYTE NUMBER_OF_NOTES+$80,NUMBER_OF_INSTRUMENTS,(editorCommandsEnd-editorCommands),0

patternPositiveAdd:
		.BYTE $0C,$10,$01,$10

patternNegativeAdd:
		.BYTE -12,-16,-1,-16
		


patternPlayNote:	ldy patternCursorX
		cpy #PATTERN_COLUMN_NOTE
		beq @a
		rts
		
@a:		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_HEADER_PRELISTEN
		beq @x

@b:		lda editorPlayingNote
		bne @playing
		
		lda #$01
		sta editorPlayingNote
		
		ldy editorCurrentTrack
		lda editBuffer
		and #$7F
		sta plyrCurrentNote,y
		clc
		adc plyrCurrentChainTranspose,y
		lda #$01
		sta plyrKeyOn,y
		lda #$00
		sta plyrRetriggerSpeed,y
@playing:		ldx editorCurrentTrack
		lda #$20
		sta plyrKillCounter,x
@x:		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF
		rts
		
patternPlayNote2:	lda editorPlayingNote
		bne patternStopNote
		ldy patternCursorX
		cpy #PATTERN_COLUMN_NOTE
		bne @x		
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_HEADER_PRELISTEN
		beq @x
		ldy editorCurrentTrack
		lda editBuffer
		and #$7F
		sta plyrCurrentNote,y
		lda #$01
		sta plyrKeyOn,y
		lda #$00
		sta plyrRetriggerSpeed,y
		ldx editorCurrentTrack
		lda #$20
		sta plyrKillCounter,x
		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF

@x:		rts


patternStopNote:	ldy patternCursorX
		cpy #PATTERN_COLUMN_NOTE
		bne @x
		lda SRAM_HEADER_PRELISTEN
		beq @x
		lda #$00
		sta editorPlayingNote
		ldy editorCurrentTrack
		lda #$01
		sta plyrKillCounter,y
		lda #$00
		sta plyrKeyOn,y
		lda #$FF
		sta patternLastNote
@x:		rts
		
printPatternCommand:
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

editPatternUpdateScreenValue:
		pha
		ldx patternCursorY
		lda rowOffsetPattern,x
		ldx patternCursorX
		clc
		adc columnOffsetPattern,x
		tax
		pla
		cpy #PATTERN_COLUMN_NOTE
		bne @notNote
		jmp printEditorNote
		
@notNote:		cpy #PATTERN_COLUMN_INSTRUMENT
		bne @b
		and #$FF
		cmp #$FF
		bne @a0
		printEmptyCell
		rts
@a0:		jmp phexWindow
		
@b:		sta tmp3
		cpy #PATTERN_COLUMN_COMMAND
		bne @data
		jsr printPatternCommand
		lda tmp3
		cmp #COMMAND_W
		bne @x
		iny
		lda (patternVector),y
		jmp instrumentPrintDuty
@x:		iny
		lda (patternVector),y
		jmp phexWindow
		
@data:		dey
		lda (patternVector),y
		cmp #COMMAND_W
		bne @notDuty
		lda tmp3
		jsr instrumentPrintDuty
		rts
@notDuty:		lda tmp3
@c:		jmp phexWindow


writePatternScreen:
		ldx #$00
		ldy patternFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #$20
		bcc @a

		ldx editorCurrentPattern
		lda editPatternAddressLo,x
		sta tmp0
		lda editPatternAddressHi,x
		sta tmp1
			
		ldx #$00
		lda patternFirstRow
		tay
		lda patternRowsIndex,y
		tay
@b:		lda (tmp0),y		;note
		jsr printEditorNote
		lda #CHR_SPACE
		sta windowBuffer,x
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y		;instrument number
		cmp #$FF
		bne @b0
		printEmptyCell
		jmp @b1
@b0:		jsr phexWindow
@b1:		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y		;command number
		pha
		jsr printPatternCommand
		lda #CHR_SPACE
		sta windowBuffer,x
		iny
		pla
		cmp #COMMAND_W
		bne @notDuty
		lda (tmp0),y
		jsr instrumentPrintDuty
		jmp @skipDuty
@notDuty:		lda (tmp0),y		;commmand parameter
		jsr phexWindow
@skipDuty:		iny
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		cpx #(14 * 16)
		bcc @b
		
		lda writeScreen
		and #$7F
		sta writeScreen
		
		rts

writePatternHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titlePattern,x
		sta titleBuffer,x
		lda headerPattern,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		ldx #$0A			;print current chain number in title bar
		lda editorCurrentPattern
		jsr phexTitle
		rts
		

patternCursorColumns:
		.BYTE $53, $53+(4*8), $53+(7*8), $53+(8*8)
		
patternCursorRows:
		.REPEAT 16,i
		.BYTE $28 + (i * 8)
		.ENDREPEAT

rowOffsetPattern:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
	
columnOffsetPattern:
		.BYTE 0,4,7,8

;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
patternColumnCursorType:
		.BYTE 3,2,1,2

