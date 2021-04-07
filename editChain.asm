;---------------------------------------------------------------
; EDIT CHAIN
;---------------------------------------------------------------
editChain:
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF

		ldx chainCursorY
		stx editChainIndex
		lda chainRowsIndex,x
		ldx editorCurrentChain
		clc
		adc editChainAddressLo,x
		sta chainVector
		lda editChainAddressHi,x
		adc #$00
		sta chainVector+1

		lda writeScreen
		beq @a
		jsr writeChainScreen
		dec writeScreen
		beq @a
		jsr writeChainHeaderFooter
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		lda #$00
		sta writeScreen
		jmp editorLoop

@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editChainExit		;if changed, don't do any more keys
@b:		jsr processKeys

		
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		ldy chainCursorX
		jsr chainKeysHoldA_UDLR
		ldy chainCursorX
		jsr chainKeysHoldAB_TapUDLR		
		ldy chainCursorX
		jsr chainKeysTapB		
		jsr chainKeysTapA
		ldy chainCursorX
		jsr chainKeysDoubleTapA
		ldy chainCursorX
		jsr chainKeysHoldB_UD
		ldy chainCursorX
		jsr chainKeysSelect_UDLR
		jsr moveAroundEditor	;global routine for moving around editors
editChainExit:
		updateCursor chainCursorX,chainCursorY,chainCursorColumns,chainCursorRows,chainColumnCursorType
		jsr chainPlayMarkers
		;lda #%11111111
		;sta PPU1
		jsr chainIsChainEmpty
		;lda #%00011110
		;sta PPU1
		jmp editorLoop

chainIsChainEmpty:	
		ldx editorCurrentChain
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_CHAIN_FLAGS,x
		and #%11111101
		sta SRAM_CHAIN_FLAGS,x
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		ldy #$00
@a:		lda (chainVector),y
		cmp #$FF
		bne @notEmpty
		iny
		iny
		cpy #(STEPS_PER_CHAIN * BYTES_PER_CHAIN_STEP)
		bcc @a
		rts
@notEmpty:	.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_CHAIN_FLAGS,x
		ora #%00000010
		sta SRAM_CHAIN_FLAGS,x
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		rts

chainPlayMarkers:	ldx editorCurrentTrack
		lda plyrCurrentChain,x
		cmp editorCurrentChain
		bne @x
		
		lda plyrChainIndex,x
		tay
		lda chainCursorRows,y
		sec
		sbc #$01
		sta SPR05_Y
		lda #SPR_RIGHT_ARROW
		sta SPR05_CHAR
		lda #26+48
		sta SPR05_X

@x:		rts		
		

chainKeysHoldAB_TapUDLR:
		lda keysHoldA
		beq @x
		lda keysHoldB
		beq @x
		lda PAD1_dud
		beq @noUD
		bpl @down
		jsr chainDeleteRow
		ldy chainCursorX
		lda (chainVector),y
		cmp #$FF
		beq @a
		sta editChainLastValue,x
@a:		sta editBuffer
		lda #$01
		sta editBufferFlag
@a1:		lda #$01
		sta writeScreen
		rts

@down:		jsr chainInsertRow
		ldy chainCursorX
		lda (chainVector),y
		sta editBuffer
		lda #$01
		sta writeScreen
		lda #$01
		sta editBufferFlag
		rts

@noUD:
@x:		rts



chainDeleteRow:	
		ldx editorCurrentChain
		lda editChainAddressLo,x
		sta tmp0
		lda editChainAddressHi,x
		sta tmp1
		
		lda chainCursorY
		cmp #STEPS_PER_CHAIN-1
		beq @x
		sta tmp2
		
@a:		ldy tmp2
		iny
		lda chainRowsIndex,y
		tay
		lda (tmp0),y
		pha
		iny
		lda (tmp0),y
		dey
		dey
		sta (tmp0),y
		dey
		pla
		sta (tmp0),y
		inc tmp2
		lda tmp2
		cmp #STEPS_PER_CHAIN-1
		bne @a
		tay
		lda chainRowsIndex,y
		tay
		lda #$FF
		sta (tmp0),y
		iny
		lda #$00
		sta (tmp0),y
@x:		rts


		
chainInsertRow:	ldx editorCurrentChain
		lda editChainAddressLo,x
		sta tmp0
		lda editChainAddressHi,x
		sta tmp1
		
		lda chainCursorY
		cmp #STEPS_PER_CHAIN-1
		beq @x
		tay
		lda chainRowsIndex,y
		sta tmp2
		
		ldy #STEPS_PER_CHAIN-1
		lda chainRowsIndex,y
		tay
@a:		dey
		lda (tmp0),y
		pha
		dey
		lda (tmp0),y
		iny
		iny
		sta (tmp0),y
		iny
		pla
		sta (tmp0),y
		dey
		dey
		dey
		bmi @x
		cpy tmp2
		beq @x
		bcs @a

@x:		rts

chainKeysSelect_UDLR:
		lda PAD1_sel
		beq @x
		lda PAD1_fireb
		bne @x
		
		lda PAD1_dud
		ora keysRepeatUD
		beq @noUD
		clc
		adc editorCurrentChain
		bpl @a
		lda #$00
		beq @b
@a:		cmp #NUMBER_OF_CHAINS
		bcs @x
@b:		sta editorCurrentChain
		lda #$02
		sta writeScreen
		rts
		
@noUD:		lda PAD1_dlr
		beq @x
		bmi chainCopyData
		jsr chainPasteData

@x:		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		rts
		
		
chainKeysHoldB_UD:
		lda PAD1_sel
		beq @x

		lda keysHoldB
		beq @x
		
		lda PAD1_firea
		bne @x
		
		lda PAD1_dud
		beq @x
				
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
		
		lda editorCurrentTrack
		asl a
		tax
		lda songVectors,x
		sta trackVector
		lda songVectors+1,x
		sta trackVector+1
		
		lda songTrackIndex
		clc
		adc PAD1_dud
		bmi @x
		cmp #STEPS_PER_TRACK
		bcs @x
		tay
		lda (trackVector),y
		cmp #$FF
		beq @x
		sty songTrackIndex
		sta editorCurrentChain
		lda #$02
		sta writeScreen
		
@x:		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF		
		rts

chainCopyData:	lda editorMode
		sta copyBufferObjectType
		
		ldx editorCurrentChain
		stx copyBufferObject
		lda editChainAddressLo,x
		sta tmp0
		lda editChainAddressHi,x
		sta tmp1
		
		ldx #$00
		ldy chainCursorY
		sty copyBufferStartIndex
		lda chainRowsIndex,y
		tay
@copyLoop:	lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_CHAIN*BYTES_PER_CHAIN_STEP)
		bcc @copyLoop
		stx copyBufferLength
@x:		
		jsr editorUpdateCopyInfo
		rts

chainPasteData:	lda copyBufferObjectType
		bmi @x			;nothing to copy
		cmp editorMode
		bne @x			;wrong object type

		ldx editorCurrentChain
		lda editChainAddressLo,x
		sta tmp0
		lda editChainAddressHi,x
		sta tmp1
		ldy chainCursorY
		lda chainRowsIndex,y
		tay
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpx copyBufferLength
		bcs @a
		cpy #(STEPS_PER_CHAIN*BYTES_PER_CHAIN_STEP)
		bcc @b
@a:		lda #$01
		sta writeScreen
		rts
		
@x:		lda #ERROR_PASTE
		sta errorMessageNumber
		rts

chainKeysHoldA_UDLR:
		lda PAD1_fireb;keysHoldB
		beq @noB
		rts
@noB:		lda PAD1_firea;keysHoldA			;hold A + U/D/L/R = modify value
		bne @holdA
		lda editBufferFlag
		beq @x
		lda editBuffer
		sta (chainVector),y
@notEditing:	lda #$00
		sta editBufferFlag
		beq @x
@holdA:		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda (chainVector),y
		cmp #$FF
		bne @notEmpty
		lda editChainLastValue,y
@notEmpty:	sta editBuffer
		jsr editChainUpdateScreenValue
		ldy chainCursorX
	
@editing:		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bpl @subBig
		lda chainAddBig,y
		jmp @addValue
@subBig:		lda chainSubBig,y
@addValue:	clc
		adc editBuffer
		cpy #CHAIN_COLUMN_TRANSPOSE
		beq @notTop
		and #$FF
		bpl @notNeg
		lda #$00
		beq @notTop
@notNeg:		cmp #NUMBER_OF_PATTERNS
		bcc @notTop
		lda #NUMBER_OF_PATTERNS-1
@notTop:		sta editBuffer
		sta editChainLastValue,y
		jsr editChainUpdateScreenValue
@x:		rts
		
chainKeysTapB:
		lda keysTapB
		beq @x
		lda PAD1_sel
		beq @x
		lda chainClearValue,y
		sta (chainVector),y
		sta editBuffer
		jsr editChainUpdateScreenValue
@x:		rts
				
chainKeysTapA:	lda keysTapA
		beq @a
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		lda chainClearValue,y
		sta (chainVector),y
		sta editBuffer
		jsr editChainUpdateScreenValue
		rts
		.ENDIF
	
@notDel:		lda PAD1_sel
		beq @notClone
		ldy chainCursorX
		cpy #CHAIN_COLUMN_PATTERN
		bne @a
		lda (chainVector),y
		cmp #$FF
		beq @a
		jsr chainClonePattern
		bcs @x			;carry set if pattern not cloned
		ldy chainCursorX
		sta editChainLastValue,y
		
@notClone:
		lda editChainLastValue,y
		sta (chainVector),y
		sta editBuffer
		jsr editChainUpdateScreenValue
		ldy chainCursorX
		cpy #CHAIN_COLUMN_PATTERN
		bne @a
		lda (chainVector),y
		tax
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_PATTERN_FLAGS,x
		ora #%00000001
		sta SRAM_PATTERN_FLAGS,x
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
@a:		rts
@x:		lda #ERROR_NO_FREE_PATTERNS
		sta errorMessageNumber
		rts

chainKeysDoubleTapA:
		cpy #CHAIN_COLUMN_TRANSPOSE
		beq @x
		lda keysDoubleTapA
		beq @x
		ldx chainCursorX
		lda editChainLastValue,x
		jsr chainFindNextUnusedPattern
		bmi @x
		sta editChainLastValue,y
		sta (chainVector),y
		jsr editChainUpdateScreenValue
		ldy chainCursorX
		cpy #CHAIN_COLUMN_PATTERN
		bne @x
		lda (chainVector),y
		tax
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_PATTERN_FLAGS,x
		ora #%00000001
		sta SRAM_PATTERN_FLAGS,x
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
@x:		rts

chainClonePattern:	lda #$00
		sta tmp0
@a:		jsr chainFindNextUnusedPattern
		bmi @noUnused
		sta tmp0
		jsr chainIsPatternEmpty
		bcc @unused
		inc tmp0
		lda tmp0
		cmp #NUMBER_OF_PATTERNS
		bcc @a
@noUnused:	sec
		rts
		
@unused:		ldy chainCursorX
		lda (chainVector),y
		tax
		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF
		lda editPatternAddressLo,x
		sta tmp1
		lda editPatternAddressHi,x
		sta tmp2
		ldy #$00
@b:		lda (tmp1),y
		sta (patternVector),y
		iny
		cpy #(STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP)
		bcc @b
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		clc
		lda tmp0
		rts

;IN : A=chain to check
;OUT 
chainIsPatternEmpty:
		tax
		lda editPatternAddressLo,x
		sta patternVector
		lda editPatternAddressHi,x
		sta patternVector+1
		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF
		ldy #$00
@a:		lda (patternVector),y	;check note
		bpl @notEmpty
		iny
		lda (patternVector),y	;check instrument
		bpl @notEmpty
		iny
		lda (patternVector),y	;check command
		bpl @notEmpty
		iny
		iny
		cpy #(STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP)
		bcc @a
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		clc
		rts
@notEmpty:	.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		sec
		rts
		
;	
;In : A=pattern number to start search from
;OUT : A = free pattern, if $FF then no free pattern
;
chainFindNextUnusedPattern:
		pha
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		pla
		tax
@a:		lda SRAM_PATTERN_FLAGS,x
		beq @x
		inx
		cpx #NUMBER_OF_PATTERNS
		bcc @a
		ldx #$FF
@x:		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		txa
		rts

chainClearValue:
		.BYTE $FF,$00

chainAddBig:	.BYTE 16,12
chainSubBig:	.BYTE -16,-12


editChainUpdateScreenValue:
		pha
		ldx chainCursorY
		lda rowOffsetChain,x
		ldx chainCursorX
		clc
		adc columnOffsetChain,x
		tax
		pla
		cpy #CHAIN_COLUMN_TRANSPOSE
		beq @normal
		cmp #$FF
		beq @empty
@normal:		jmp phexWindow
@empty:		printEmptyCell
		rts

writeChainScreen:
		ldx #$00
		ldy chainFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #$20
		bcc @a

		ldx editorCurrentChain
		lda editChainAddressLo,x
		sta tmp0
		lda editChainAddressHi,x
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
		iny
		lda (tmp0),y
		jsr phexWindow
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

writeChainHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleChain,x
		sta titleBuffer,x
		lda headerChain,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		ldx #$08			;print current chain number in title bar
		lda editorCurrentChain
		jsr phexTitle
		rts
		

chainCursorColumns:
		.REPEAT 2,i
		.BYTE $53+(i * 24)
		.ENDREPEAT

chainCursorRows:
		.REPEAT 16,i
		.BYTE $28 + (i*8)
		.ENDREPEAT

rowOffsetChain:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
			
columnOffsetChain:
		.BYTE 0,3


		
;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
chainColumnCursorType:
		.BYTE 2,2
		
