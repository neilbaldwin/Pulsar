
;---------------------------------------------------------------
; EDIT SONG
;---------------------------------------------------------------
editSong:
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF


		lda songCursorX		;get index into actual data to modify values
		sta editorCurrentTrack

		;tax
		;lda editTrackAddressLo,x
		;sta trackVector
		;lda editTrackAddressHi,x
		;sta trackVector+1
		asl a
		tax
		lda songVectors,x
		sta trackVector
		lda songVectors+1,x
		sta trackVector+1
		
		lda songFirstRow
		clc
		adc songCursorY
		sta songTrackIndex
		tay
				
		lda writeScreen		;need to write screen?
		beq @a
		bpl @thisTime
		and #$7F
		sta writeScreen
		bpl @a
@thisTime:	jsr writeSongScreen		;yes
		dec writeScreen		;if writeScreen was 1, only write main window, else		
		beq @a			;  write header and title too
		jsr writeSongHeaderFooter
		dec writeScreen		;reset screen writing flag
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		jmp editorLoop
	
@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editSongExit		;if changed, don't do any more keys
	
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF

		ldy songTrackIndex
		ldx songCursorX
		
		jsr songKeysHoldA_UDLR
		jsr songKeysTapA
		jsr songKeysTapB
		jsr songKeysDoubleTapA
		jsr songKeysHoldAB_TapUDLR
		jsr songKeysHoldB_UD
		jsr moveAroundEditor		;global routine for moving around editors

editSongExit:
		updateCursor songCursorX,songCursorY,songCursorColumns,songCursorRows,songColumnCursorType
		
		jsr songPlayMarkers		
		jmp editorLoop

songKeysHoldB_UD:	lda keysHoldB
		beq @x
		lda PAD1_firea
		bne @x
		lda PAD1_sel
		bne @x
		lda PAD1_dud
		beq @x
				
		lda editorCurrentSong
		clc
		adc PAD1_dud
		bmi @x
		cmp #NUMBER_OF_SONGS
		bcs @x
		sta editorCurrentSong
		lda #$02
		sta writeScreen
		
		
@noUD:
@x:		rts


songKeysHoldAB_TapUDLR:
		lda keysHoldA
		beq @x
		lda keysHoldB
		beq @x
		lda PAD1_dud
		beq @noUD
		bpl @down
		jsr songDeleteRow
		lda songFirstRow
		clc
		adc songCursorY
		tay
		lda (trackVector),y
		cmp #$FF
		beq @a
		;sta editSongLastValue,x
		sta editSongLastValue
@a:		sta editBuffer
		lda #$81		;write next time
		sta writeScreen
		lda #$01
		sta editBufferFlag
		rts

@down:		jsr songInsertRow
		lda songFirstRow
		clc
		adc songCursorY
		tay
		lda (trackVector),y
		sta editBuffer
		lda #$81		;write next time
		sta writeScreen
		lda #$01
		sta editBufferFlag
		rts

@noUD:		lda PAD1_dlr
		beq @x
@x:		rts

songDeleteRow:	
		lda songFirstRow
		clc
		adc songCursorY
		tay
		cpy #STEPS_PER_TRACK-1
		beq @x
@a:		iny
		lda (songVectors+$00),y
		pha
		lda (songVectors+$02),y
		pha
		lda (songVectors+$04),y
		pha
		lda (songVectors+$06),y
		pha
		lda (songVectors+$08),y
		dey
		sta (songVectors+$08),y
		pla
		sta (songVectors+$06),y
		pla
		sta (songVectors+$04),y
		pla
		sta (songVectors+$02),y
		pla
		sta (songVectors+$00),y
		iny
		cpy #STEPS_PER_TRACK-1
		bcc @a
		lda #$FF
		sta (songVectors+$00),y
		sta (songVectors+$02),y
		sta (songVectors+$04),y
		sta (songVectors+$06),y
		sta (songVectors+$08),y
@x:		
		rts
		
		
songInsertRow:
		lda songFirstRow
		clc
		adc songCursorY
		cmp #STEPS_PER_TRACK-1
		beq @x
		sta tmp0
		ldy #STEPS_PER_TRACK-1
@a:		dey
		lda (songVectors+$00),y
		pha
		lda (songVectors+$02),y
		pha
		lda (songVectors+$04),y
		pha
		lda (songVectors+$06),y
		pha
		lda (songVectors+$08),y
		iny
		sta (songVectors+$08),y
		pla
		sta (songVectors+$06),y
		pla
		sta (songVectors+$04),y
		pla
		sta (songVectors+$02),y
		pla
		sta (songVectors+$00),y
		dey
		cpy tmp0
		beq @x
		bcs @a
@x:		rts

songPlayMarkers:	
		lda writeScreen
		beq @go
		;rts
		
@go:		ldx #$00
@a:		lda plyrPlaying
		and SetBits,x
		bne @show
@noShow:		inx
		cpx #$05
		bcc @a
		rts

@show:		lda songFirstRow
		clc
		adc #$10
		sta tmp0
		lda plyrTrackIndex,x
		cmp songFirstRow
		bcc @noShow
		cpy tmp0
		bcs @noShow
		
		sec
		sbc songFirstRow
		tay
		lda songCursorRows,y
		sec
		sbc #$01
		pha
		txa
		asl a
		asl a
		tay
		lda #SPR_RIGHT_ARROW
		sta SPR05_CHAR,y
		pla
		sta SPR05_Y,y
		lda twentyFour,x
		clc
		adc #$4B
		sta SPR05_X,y
		jmp @noShow
				
twentyFour:	.BYTE 0*24,1*24,2*24,3*24,4*24

songKeysHoldA_UDLR:
		ldx songCursorX
		lda PAD1_fireb;keysHoldB
		ora PAD1_sel
		beq @noB
		rts
@noB:		lda keysHoldA			;hold A + U/D/L/R = modify value
		bne @holdA
		lda editBufferFlag
		beq @x
		lda editBuffer
		sta (trackVector),y
@notEditing:	lda #$00
		sta editBufferFlag
		beq @x
@holdA:		lda editBufferFlag
		bne @editing
		inc editBufferFlag
		lda (trackVector),y
		cmp #$FF
		bne @notEmpty
		;lda editSongLastValue,x
		lda editSongLastValue
@notEmpty:	sta editBuffer
		jsr editSongUpdateScreenValue
		ldx songCursorX

@editing:		lda keysRepeatLR
		ora PAD1_dlr
		bne @addValue
		lda keysRepeatUD
		ora PAD1_dud
		beq @x
		bpl @subBig
		lda songAddBig,x
		jmp @addValue
@subBig:		lda songSubBig,x

@addValue:	clc
		adc editBuffer
		bpl @notNeg
		lda #$00
		beq @notTop
@notNeg:		cmp #NUMBER_OF_CHAINS
		bcc @notTop
		lda #NUMBER_OF_CHAINS-1
@notTop:		sta editBuffer
		jsr editSongUpdateScreenValue
@x:		rts
			
songKeysDoubleTapA:	lda keysDoubleTapA
		beq @x
		lda PAD1_fireb
		ora PAD1_sel
		bne @x
		ldx songCursorX
		;lda editSongLastValue,x
		lda editSongLastValue
		jsr songFindNextUnusedChain
		bmi @x
		ldx songCursorX
		;sta editSongLastValue,x
		sta editSongLastValue
		sta (trackVector),y
		jsr editSongUpdateScreenValue
		lda (trackVector),y
		tax
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_CHAIN_FLAGS,x
		ora #$01
		sta SRAM_CHAIN_FLAGS,x
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
@x:		rts

songKeysTapB:	lda PAD1_sel
		beq @x
		lda keysTapB
		beq @x
		lda #$FF
		sta (trackVector),y
		sta editBuffer
		jsr editSongUpdateScreenValue
@x:		rts
	
songKeysTapA:	ldx songCursorX
		lda keysTapA
		beq @a

		.IF 0=1
@b:		lda PAD1_fireb
		beq @notDel
		lda #$FF
		sta (trackVector),y
		sta editBuffer
		jsr editSongUpdateScreenValue
		rts
		.ENDIF

@notDel:		lda PAD1_sel
		beq @notClone
		ldy songTrackIndex
		lda (trackVector),y
		cmp #$FF
		beq @a
		jsr songCloneChain
		bcs @x			;carry set if pattern not cloned
		ldx songCursorX
		ldy songTrackIndex
		;sta editSongLastValue,x
		sta editSongLastValue
		
@notClone:	.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
		;lda editSongLastValue,x
		lda editSongLastValue
		sta (trackVector),y
		sta editBuffer
		jsr editSongUpdateScreenValue
		lda (trackVector),y
		tax
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_CHAIN_FLAGS,x
		ora #$01
		sta SRAM_CHAIN_FLAGS,x
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
@a:		rts

@x:		lda #ERROR_NO_FREE_CHAINS
		sta errorMessageNumber
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
		rts


songCloneChain:	lda #$00
		sta tmp0
@a:		jsr songFindNextUnusedChain
		bmi @noUnused
		sta tmp0
		jsr songIsChainEmpty
		bcc @unused
		inc tmp0
		lda tmp0
		cmp #NUMBER_OF_CHAINS
		bcc @a
@noUnused:	sec
		rts
@unused:		ldy songTrackIndex
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
		lda (trackVector),y
		tax
		lda editChainAddressLo,x
		sta tmp1
		lda editChainAddressHi,x
		sta tmp2
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		ldy #$00
@b:		lda (tmp1),y
		sta (chainVector),y
		iny
		cpy #(STEPS_PER_CHAIN * BYTES_PER_CHAIN_STEP)
		bcc @b
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
		clc
		lda tmp0
		rts

;IN : A=chain to check
;OUT 
songIsChainEmpty:	tax
		lda editChainAddressLo,x
		sta chainVector
		lda editChainAddressHi,x
		sta chainVector+1
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		ldy #$00
@a:		lda (chainVector),y
		bpl @notEmpty
		iny
		iny
		cpy #(STEPS_PER_CHAIN * BYTES_PER_CHAIN_STEP)
		bcc @a
		clc
		rts
@notEmpty:	sec
		rts
		
;	
;In : A=pattern number to start search from
;OUT : A = free pattern, if $FF then no free pattern
;
songFindNextUnusedChain:
		pha
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		pla
		tax
		ldx #$00
@a:		lda SRAM_CHAIN_FLAGS,x
		beq @x
		inx
		cpx #NUMBER_OF_CHAINS
		bcc @a
		ldx #$FF
@x:		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF		
		txa
		rts


songAddSmall:
		.BYTE 1,1,1,1,1

songSubSmall:	.BYTE -1-1-1-1-1

songAddBig:	.BYTE 16,16,16,16,16

songSubBig:	.BYTE -16,-16,-16,-16,-16

editSongUpdateScreenValue:
		pha
		ldx songCursorY
		lda rowOffsetSong,x
		ldx songCursorX
		clc
		adc columnOffsetSong,x
		tax
		pla
		cmp #$FF
		bne @normal
		printEmptyCell
		rts
@normal:		stx tmp0
		ldx songCursorX
		;sta editSongLastValue,x
		sta editSongLastValue
		ldx tmp0
		jsr phexWindow
@c:		rts	


writeSongScreen:
		ldx #$00
		ldy songFirstRow		;first write row numbers to buffer
@a:		tya
		jsr phexRow
		iny
		cpx #$20
		bcc @a
		
		lda songFirstRow
		tay
		ldx #$00
@b:		lda (songVectors+$00),y
		cmp #NUMBER_OF_CHAINS
		bcc @b1
		printEmptyCell
		jmp @b2
@b1:		jsr phexWindow
@b2:	
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		lda (songVectors+$02),y
		cmp #NUMBER_OF_CHAINS
		bcc @b3
		printEmptyCell
		jmp @b4
@b3:		jsr phexWindow
@b4:	
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		lda (songVectors+$04),y
		cmp #NUMBER_OF_CHAINS
		bcc @b5
		printEmptyCell
		jmp @b6
@b5:		jsr phexWindow
@b6:	
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		lda (songVectors+$06),y
		cmp #NUMBER_OF_CHAINS
		bcc @b7
		printEmptyCell
		jmp @b8
@b7:		jsr phexWindow
@b8:	
		lda #CHR_SPACE
		sta windowBuffer,x
		inx
		lda (songVectors+$08),y
		cmp #NUMBER_OF_CHAINS
		bcc @b9
		printEmptyCell
		jmp @b10
@b9:		jsr phexWindow
@b10:		iny
		cpx #224
		bcs @x
		jmp @b
@x:		rts

writeSongHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleSong,x
		sta titleBuffer,x
		lda headerSong,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		ldx #$07			;print current chain number in title bar
		lda editorCurrentSong
		jsr phexTitle
		rts


songCursorColumns:
		.REPEAT 5,i
		.BYTE $53+(i*24)
		.ENDREPEAT
		
songCursorRows:
		.REPEAT 16,i
		.BYTE $28+(i*8)
		.ENDREPEAT
		
rowOffsetSong:
		.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
		
		
columnOffsetSong:
		.BYTE 0,3,6,9,12

;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
songColumnCursorType:
		.BYTE 2,2,2,2,2
