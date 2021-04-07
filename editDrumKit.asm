
editDrumkit:
		.IF SRAM_MAP=32
		lda #SRAM_DRUMKIT_BANK
		jsr setMMC1r1
		.ENDIF

		ldx drumkitCursorY
		lda drumkitRowsIndex,x
		ldx editorCurrentDrumkit
		clc
		adc editDrumkitAddressLo,x
		sta drumkitVector
		lda editDrumkitAddressHi,x
		adc #$00
		sta drumkitVector+1

		lda writeScreen		;need to write screen?
		beq @a
		jsr writeDrumkitScreen		;yes
		dec writeScreen		;if writeScreen was 1, only write main window, else		
		beq @a			;  write header and title too
		jsr writeDrumkitHeaderFooter
		dec writeScreen		;reset screen writing flag
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle

@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editDrumkitExit		;if changed, don't do any more keys
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_DRUMKIT_BANK
		jsr setMMC1r1
		.ENDIF

		ldy drumkitCursorX

		jsr drumkitKeysHoldA_UDLR
		jsr drumkitKeysTapA
		jsr drumkitKeysTapB
		jsr drummkitKeysHoldSelect_UDLR

		ldy drumkitCursorX		;if editing root, stop L/R movement
		cpy #DRUMKIT_COLUMN_ROOT
		bne @notRoot
		lda #$00
		sta keysRepeatLR
		sta PAD1_dlr
		
@notRoot:		jsr moveAroundEditor

editDrumkitExit:	
		updateCursor drumkitCursorX,drumkitCursorY,drumkitCursorColumns,drumkitCursorRows,drumkitColumnCursorType
		jsr drumkitPlayMarkers
		jsr writeDrumkitThisNote
		jmp editorLoop


drumkitPlayMarkers:	
		ldx editorCurrentTrack
		cpx #SONG_TRACK_E
		bne @x
		lda plyrCurrentInstrument,x
		tay
		lda plyrCurrentNote,x
		cmp SRAM_DRUMKIT_ROOTS,y
		bcc @x
		sbc SRAM_DRUMKIT_ROOTS,y
		cmp #$0C
		bcs @x
		tay
		lda drumkitCursorRows,y
		sec
		sbc #$01
		sta SPR05_Y
		lda #SPR_RIGHT_ARROW
		sta SPR05_CHAR
		lda #26+48
		sta SPR05_X

@x:		rts		
		
drummkitKeysHoldSelect_UDLR:
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
		adc editorCurrentDrumkit
		bpl @a
		lda #$00
		beq @b
@a:		cmp #NUMBER_OF_DRUMKITS
		bcs @x
@b:		sta editorCurrentDrumkit
		lda #$02
		sta writeScreen
		rts

@noUD:		lda PAD1_dlr
		beq @x
		bmi drumkitCopyData
		jsr drumkitPasteData
@x:		rts

drumkitCopyData:	lda editorMode
		sta copyBufferObjectType
		
		ldx editorCurrentDrumkit
		stx copyBufferObject
		lda editDrumkitAddressLo,x
		sta tmp0
		lda editDrumkitAddressHi,x
		sta tmp1
		
		ldx #$00
		ldy drumkitCursorY
		sty copyBufferStartIndex
		lda drumkitRowsIndex,y
		tay
@copyLoop:	lda (tmp0),y
		sta copyBuffer,x
		inx
		iny
		cpy #(STEPS_PER_DRUMKIT*BYTES_PER_DRUMKIT_STEP)
		bcc @copyLoop
		stx copyBufferLength
@x:		jsr editorUpdateCopyInfo
		rts

drumkitPasteData:	lda copyBufferObjectType
		bmi @x			;nothing to copy
		cmp editorMode
		bne @x			;wrong object type

		ldx editorCurrentDrumkit
		lda editDrumkitAddressLo,x
		sta tmp0
		lda editDrumkitAddressHi,x
		sta tmp1
		ldy drumkitCursorY
		lda drumkitRowsIndex,y
		tay
		ldx #$00
@b:		lda copyBuffer,x
		sta (tmp0),y
		inx
		iny
		cpx copyBufferLength
		bcs @a
		cpy #(STEPS_PER_DRUMKIT*BYTES_PER_DRUMKIT_STEP)
		bcc @b
@a:		lda #$01
		sta writeScreen
		rts
		
@x:		lda #ERROR_PASTE
		sta errorMessageNumber
		rts
		

		
drumkitKeysHoldA_UDLR:
		lda PAD1_fireb;keysHoldB
		beq @noB
@x2:		rts
@noB:		lda PAD1_firea;keysHoldA			;hold A + U/D/L/R = modify value
		bne @holdA
		lda editBufferFlag
		beq @x2
		lda editBuffer
		cpy #DRUMKIT_COLUMN_ROOT
		bne @notRoot2
		ldy editorCurrentDrumkit
		sta SRAM_DRUMKIT_ROOTS,y
		jmp @notEditing
@notRoot2:	sta (drumkitVector),y
@notEditing:	lda #$00
		sta editBufferFlag
		lda #$00
		sta editorPlayingNote
@killing:		jmp @x
@holdA:		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		
		cpy #DRUMKIT_COLUMN_ROOT
		bne @notEditRoot
		ldy editorCurrentDrumkit
		lda SRAM_DRUMKIT_ROOTS,y
		sta editBuffer
		jmp @editing

@notEditRoot:	lda (drumkitVector),y
		sta editBuffer
		
@editing:		jsr drumkitPlayNote
		ldy drumkitCursorX		
		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bmi @posAdd
		lda drumkitNegativeAdd,y
		jmp @addValue
@posAdd:		lda drumkitPositiveAdd,y
		
@addValue:	cpy #DRUMKIT_COLUMN_ROOT
		bne @notRoot
		ldy editorCurrentDrumkit
		clc
		;adc SRAM_DRUMKIT_ROOTS,y
		adc editBuffer
		bpl @notNegRoot
		lda #$00
		beq @notLimitRoot
@notNegRoot:	cmp #NUMBER_OF_NOTES
		bcc @notLimitRoot
		lda #NUMBER_OF_NOTES-1
@notLimitRoot:	;sta SRAM_DRUMKIT_ROOTS,y
		sta editBuffer
		ldy drumkitCursorX
		sta editDrumkitLastValue,y
		jsr editDrumkitUpdateScreenValue
		rts
		
@notRoot:		clc
		adc editBuffer
		cpy #DRUMKIT_COLUMN_START_OFFSET
		beq @noLimit
		cpy #DRUMKIT_COLUMN_END_OFFSET
		beq @noLimit
		cpy #DRUMKIT_COLUMN_LOOP
		bne @notLoop
		and #$01
		bpl @noLimit
@notLoop:		and #$FF
		bpl @notNeg
		lda #$00
		beq @noLimit
@notNeg:		cmp drumkitMaxValues,y
		bcc @noLimit
		lda drumkitMaxValues,y
		sec
		sbc #$01
@noLimit:		sta editBuffer
		sta editDrumkitLastValue,y
		jsr editDrumkitUpdateScreenValue
		lda #$00
		sta editorPlayingNote
@x:		rts
		

drumkitKeysTapB:
		lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		lda drumkitClearValues,y
		cpy #DRUMKIT_COLUMN_ROOT
		bne @notRootClear
		ldy editorCurrentDrumkit
		sta SRAM_DRUMKIT_ROOTS,y
		ldy drumkitCursorX
		bpl @clearRoot
@notRootClear:	sta (drumkitVector),y
@clearRoot:	sta editBuffer
		jmp editDrumkitUpdateScreenValue
@x:		rts

drumkitKeysTapA:	lda keysTapA
		beq @x
		.IF 0=1
		lda PAD1_fireb
		beq @notDel
		lda drumkitClearValues,y
		cpy #DRUMKIT_COLUMN_ROOT
		bne @notRootClear
		ldy editorCurrentDrumkit
		sta SRAM_DRUMKIT_ROOTS,y
		ldy drumkitCursorX
		bpl @clearRoot
@notRootClear:	sta (drumkitVector),y
@clearRoot:	sta editBuffer
		jmp editDrumkitUpdateScreenValue
		.ENDIF
		
@notDel:
		lda editDrumkitLastValue,y
		cpy #DRUMKIT_COLUMN_ROOT
		bne @tapEdit1
		ldy editorCurrentDrumkit
		sta SRAM_DRUMKIT_ROOTS,y
		ldy drumkitCursorX
		jmp @tapEdit0
@tapEdit1:	sta (drumkitVector),y
@tapEdit0:	sta editBuffer
		jsr editDrumkitUpdateScreenValue
@x:		rts


drumkitClearValues:
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00
		
drumkitMaxValues:
		.BYTE MAX_NUMBER_OF_SAMPLES,$10,$FF,$FF,1

drumkitPositiveAdd:
		.BYTE $10,1,$10,$10,1,12

drumkitNegativeAdd:
		.BYTE -16,-1,-16,-16,-1,-12

editDrumkitUpdateScreenValue:
		pha
		ldx drumkitCursorY
		lda rowOffsetDrumkit,x
		ldx drumkitCursorX
		clc
		adc columnOffsetDrumkit,x
		tax
		lda drumkitCursorX
		cmp #DRUMKIT_COLUMN_ROOT
		bne @notRoot
		pla
		jsr printEditorNote
		rts
		
@notRoot:		cmp #DRUMKIT_COLUMN_LOOP
		bne @a
		pla
		tay
		lda yesNoSwitch,y
		sta windowBuffer,x
		rts
		
@a:		pla
		jsr phexWindow
		rts


writeDrumkitScreen:
		
		ldx #$00
		ldy drumkitFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #(12 *2)
		bcc @a
		
		lda #CHR_SPACE		;only 12 rows so clear remaining numbers
@a0:		sta rowBuffer,x
		inx
		cpx #(16 * 2)
		bcc @a0
		
		
		lda #<windowDrumkit
		sta tmp0
		lda #>windowDrumkit
		sta tmp1
		ldy #$00
@c:		lda (tmp0),y
		sta windowBuffer,y
		iny
		cpy #(14*16)
		bcc @c

		ldx editorCurrentDrumkit
		lda editDrumkitAddressLo,x
		sta tmp0
		lda editDrumkitAddressHi,x
		sta tmp1
		ldx #$00
		ldy #$00
@b:		lda (tmp0),y		;note
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y		;note
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y		;note
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y		;note
		jsr phexWindow
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		iny
		lda (tmp0),y
		beq @d
		lda #CHR_Y
		bne @d0
@d:		lda #CHR_N
@d0:		sta windowBuffer,x
		inx
		lda #CHR_SPACE
		sta windowBuffer,x
		iny
		inx
		cpx #(12 * 14)
		bcc @b
		
		ldx #(13 *14)+10
		ldy editorCurrentDrumkit
		lda SRAM_DRUMKIT_ROOTS,y
		jsr printEditorNote

writeDrumkitThisNote:
		ldx #(14*14)+10
		ldy editorCurrentDrumkit
		lda drumkitCursorY
		cmp #$0C
		bcc @a
		lda #$0B
@a:		clc
		adc SRAM_DRUMKIT_ROOTS,y
		jsr printEditorNote2
		rts
		

writeDrumkitHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleDrumkit,x
		sta titleBuffer,x
		lda headerDrumkit,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		ldx #$0A			;print current chain number in title bar
		lda editorCurrentDrumkit
		jsr phexTitle
		rts
		


drumkitPlayNote:	ldy drumkitCursorX
		cpy #DRUMKIT_COLUMN_ROOT
		bne @a
		rts
		
@a:		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_HEADER_PRELISTEN
		beq @x

@b:		lda editorPlayingNote
		bne @playing
		
		.IF SRAM_MAP=32
		lda #SRAM_DRUMKIT_BANK
		jsr setMMC1r1
		.ENDIF
		ldy drumkitCursorX
		lda editBuffer
		sta (drumkitVector),y
		lda #$01
		sta editorPlayingNote

		ldy drumkitCursorY
		sty tmp2			;key number
		lda drumkitRowsIndex,y
		tay
		ldx editorCurrentDrumkit
		lda SRAM_DRUMKIT_ROOTS,x
		clc
		adc tmp2
		sta plyrCurrentNote+$04
		lda editDrumkitAddressLo,x
		sta tmp0
		lda editDrumkitAddressHi,x
		sta tmp1
		lda (tmp0),y
		sta plyrInstrumentCopyE,y
		iny
		lda (tmp0),y
		sta plyrInstrumentCopyE,y
		iny
		lda (tmp0),y
		sta plyrInstrumentCopyE,y
		iny
		lda (tmp0),y
		sta plyrInstrumentCopyE,y
		iny
		lda (tmp0),y
		sta plyrInstrumentCopyE,y
		
		ldy editorCurrentTrack
		lda #$01
		sta plyrKeyOn,y
		lda #$00
		sta plyrRetriggerSpeed,y
@playing:		ldx editorCurrentTrack
		lda #$08
		sta plyrKillCounter,x
@x:		.IF SRAM_MAP=32
		lda #SRAM_DRUMKIT_BANK
		jsr setMMC1r1
		.ENDIF
		rts
		
drumkitStopNote:	ldy patternCursorX
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

drumkitCursorColumns:
		.BYTE $53,$53+(3*8),$53+(6*8),$53+(9*8),$53+(12*8)
		.BYTE $53+(10*8)
				
drumkitCursorRows:
		.REPEAT 16,i
		.BYTE $28+(i*8)
		.ENDREPEAT

rowOffsetDrumkit:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
	
columnOffsetDrumkit:
		.BYTE 0,3,6,9,12
		.BYTE 10

;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
drumkitColumnCursorType:
		.BYTE 2,2,2,2,1
		.BYTE 3
		
