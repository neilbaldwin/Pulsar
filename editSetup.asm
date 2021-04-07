editSetup:
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF

		lda writeScreen
		beq @a
		jsr writeSetupScreen
		dec writeScreen
		beq @a
		jsr writeSetupHeaderFooter
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		lda #$00
		sta writeScreen

@a:		jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editSetupExit		;if changed, don't do any more keys
@b:		jsr processKeys

		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF

		lda #$00
		sta keysRepeatUD
		sta PAD1_ud
		jsr setupKeysHoldA
		jsr setupKeysTapA

		lda waitForTapA
		bne @noMove
		jsr moveAroundEditor	;global routine for moving around editors
		jsr setupHandlePaletteRow
@noMove:		
		
editSetupExit:
		;updateCursor setupCursorX,setupCursorY,setupCursorColumns,setupCursorRows,setupColumnCursorType
		lda setupCursorY
		tax
		lda setupCursorColumns,x
		sta tmp0
		sta SPR00_X			;update sprite position
		ldy #$01
		lda setupColumnCursorType,x
		bne @b
		lda #$FF
		sta SPR00_CHAR
		sta SPR01_CHAR
		bne @a
@b:		tax
		sty SPR00_CHAR
		iny
		iny
		sty SPR01_CHAR

		lda tmp0
		clc
		adc cursorTypeOffsetX0,x
		sta SPR00_X
	
		lda tmp0
		clc
		adc cursorTypeOffsetX1,x
		sta SPR01_X

		lda setupCursorY
		tax
		lda setupCursorRows,x
		sec
		sbc #$01
		sta SPR00_Y
		sta SPR01_Y
@a:
		jmp editorLoop

setupKeysHoldA:	lda keysHoldA
		beq @x
		lda setupCursorY
		cmp #SETUP_ROW_SONG
		bne @a
		lda PAD1_dud
		ora PAD1_dlr
		clc
		adc editorCurrentSong
		bmi @x
		cmp #NUMBER_OF_SONGS
		bcs @x
		sta editorCurrentSong
		ldx #(1*14)+12
		jsr phexWindow
		ldx editorCurrentSong
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_SONG_SPEEDS,x
		ldx #(2*14)+12
		jmp phexWindow
					

@a:
@x:		rts

		
setupHandlePaletteRow:
		lda setupCursorY
		cmp #SETUP_ROW_PALETTE
		bcc @notPalette
		cmp #SETUP_ROW_NEXT
		bcs @notPalette
	
		lda PAD1_firea
		bne @modValues
	
		lda PAD1_dud
		beq @noUD
		bpl @downRow
		lda #SETUP_ROW_PALETTE-1
		sta setupCursorY
		rts
		
@downRow:		lda #SETUP_ROW_PALETTE
		sta setupCursorY
		
@noUD:		lda PAD1_dlr
		beq @noLR
		clc
		adc setupCursorY
		cmp #SETUP_ROW_PALETTE
		bcc @notPalette
		cmp #SETUP_ROW_PALETTE+4
		bcs @notPalette
		sta setupCursorY
@noLR:		rts

@modValues:	lda setupCursorY
		sec
		sbc #SETUP_ROW_PALETTE
		tax
		lda uiPaletteTable,x
		tax
		
		lda PAD1_dlr
		beq @notSmallMod
		lda SRAM_PALETTE,x
		and #$30
		sta tmp0
		lda PAD1_dlr
		clc
		adc SRAM_PALETTE,x
		and #$0F
		ora tmp0
		sta SRAM_PALETTE,x
@c:		cpx #(UI_COLOUR_BG0-SRAM_PALETTE)
		bne @notBG
		sta UI_COLOUR_BG1
@notBG:		lda #$01
		sta writePaletteFlag
		jsr updateSetupScreen
		lda #$01
		sta writeScreen
		rts

@notSmallMod:	lda PAD1_dud
		beq @notPalette
		eor #$FF
		clc
		adc #$01
		asl a
		asl a
		asl a
		asl a
		clc
		adc SRAM_PALETTE,x
		and #$3F
		sta SRAM_PALETTE,x
		bpl @c
				
@notPalette:	rts

uiPaletteTable:	.BYTE UI_COLOUR_BG0-SRAM_PALETTE
		.BYTE UI_COLOUR_02-SRAM_PALETTE
		.BYTE UI_COLOUR_03-SRAM_PALETTE
		.BYTE UI_COLOUR_01-SRAM_PALETTE


setupKeysTapA:
		
@a:		lda setupCursorY
		cmp #SETUP_ROW_INIT_ALL
		bne @b
		jmp setupInitAll
@b:		cmp #SETUP_ROW_CLEAN_SONGS
		bne @c
		jmp setupCleanSong
@c:		cmp #SETUP_ROW_PRELISTEN
		bne @d
		jmp setupPrelistenToggle
@d:		cmp #SETUP_ROW_SONG
		bne @e
		jmp setupChangeSong
@e:		cmp #SETUP_ROW_SONG_SPEED
		bne @f
		jmp setupChangeSongSpeed
@f:		cmp #SETUP_ROW_CLEAR_SONG
		bne @g
		jmp setupClearSong
@g:
@x:		rts

setupChangeSong:
		lda PAD1_firea
		beq @x
		lda PAD1_dlr
		beq @x
		clc
		adc editorCurrentSong
		bmi @x
		cmp #NUMBER_OF_SONGS
		bcs @x
		sta editorCurrentSong
@x:		rts

setupChangeSongSpeed:
		lda PAD1_firea
		beq @x
		lda PAD1_dlr
		beq @x
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		ldx editorCurrentSong
		lda PAD1_dlr
		clc
		adc SRAM_SONG_SPEEDS,x
		bmi @x
		cmp #NUMBER_OF_SPEED_TABLES
		bcs @x
		sta SRAM_SONG_SPEEDS,x
		jmp updateSetupScreen
@x:		rts
		
setupClearSong:
		rts
		
setupInitAll:
		lda keysTapA
		bne @go
		rts
		
@go:		lda waitForTapA
		beq @noWait
		lda #$00
		sta waitForTapA
		sta keysTapA
		lda #$01
		sta writeScreen
		rts
@noWait:
		lda #$00
		sta plyrPlaying
		lda #$01
		sta DO_NOT_INTERRUPT
		jsr initEditorData
		jsr initEditorVars
		jsr clearCopyInfoBuffer
		jsr errorBufferClear

		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda #$00
		sta hintMode
		
		ldx #$00
@a:		lda #$00
		sta SRAM_SONG_MUTE,x
		lda #$FF
		sta SRAM_SONG_SOLO,x
		inx
		cpx #NUMBER_OF_SONGS
		bcc @a
		
		lda #PLAY_MODE_STOPPED
		sta plyrPlayMode
		lda #EDIT_MODE_SONG
		sta editorPreviousModes
		lda #$01
		sta SRAM_HEADER_PRELISTEN
		sta editorModeIndex

@temp:		jsr setupShowSongStatsWindow
		lda #$01
		sta waitForTapA
		lda #$00
		sta DO_NOT_INTERRUPT
		rts
	
setupCleanSong:	
		lda keysTapA
		bne @go
		rts
@go:		lda waitForTapA
		beq @noWait
		lda #$00
		sta keysTapA
		sta waitForTapA
		lda #$01
		sta writeScreen
		rts
@noWait:	
		lda #$00
		sta plyrPlaying
		lda #$01
		sta DO_NOT_INTERRUPT
		jsr setupMarkUsedChains
		jsr setupClearUnusedChains
		jsr setupMarkUsedPatterns
		jsr setupClearUnusedPatterns
		jsr setupShowSongStatsWindow
		lda #$01
		sta waitForTapA
		lda #$00
		sta DO_NOT_INTERRUPT
		rts

setupPrelistenToggle:
		lda keysTapA
		bne @go
		rts
@go:
		lda SRAM_HEADER_PRELISTEN
		and #$01
		eor #$01
		sta SRAM_HEADER_PRELISTEN
		tax
		lda setupYesNoSwitch,x
		sta windowBuffer+(9*14)+12			
		rts

setupMarkUsedPatterns:
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		txa
@a:		sta SRAM_PATTERN_FLAGS,x
		inx
		cpx #NUMBER_OF_PATTERNS
		bcc @a
		
		ldx #$00
@a0:		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		lda editChainAddressLo,x
		sta tmp0
		lda editChainAddressHi,x
		sta tmp1
		ldy #$00
@b:		lda (tmp0),y
		cmp #$FF
		beq @b0
		sty tmp2
		tay
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda #$01
		sta SRAM_PATTERN_FLAGS,y
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		ldy tmp2
@b0:		iny
		iny
		cpy #(STEPS_PER_CHAIN*BYTES_PER_CHAIN_STEP)
		bcc @b
		inx
		cpx #NUMBER_OF_CHAINS
		bcc @a0
		
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda #NUMBER_OF_PATTERNS
		sta SRAM_HEADER_FREE_PATTERNS
		ldx #$00
@c:		sec
		sbc SRAM_PATTERN_FLAGS,x
		inx
		cpx #NUMBER_OF_PATTERNS
		bcc @c
		sta SRAM_HEADER_FREE_PATTERNS
		rts
	
setupClearUnusedPatterns:
		ldx #$00
@a:		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_PATTERN_FLAGS,x
		bne @used
		lda editPatternAddressLo,x
		sta tmp0
		lda editPatternAddressHi,x
		sta tmp1
		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF
		ldy #$00
@b:		lda #$FF
		sta (tmp0),y		;note
		iny
		lda #$FF
		sta (tmp0),y		;instrument
		iny
		lda #$FF
		sta (tmp0),y		;command
		iny
		lda #$00			;command data
		sta (tmp0),y
		iny
		cpy #(STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP)
		bcc @b
@used:		inx
		cpx #NUMBER_OF_PATTERNS
		bcc @a
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		rts
				
setupMarkUsedChains:
		;Find unused chains
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00			;temp mark all chains unused
		txa
@a:		sta SRAM_CHAIN_FLAGS,x
		inx
		cpx #NUMBER_OF_CHAINS
		bcc @a
		
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF

		ldx #$00
@a0:		stx tmp2
		lda editTrackAddressLo,x
		sta tmp0
		lda editTrackAddressHi,x
		sta tmp1
		
		ldy #$00
@b:		lda (tmp0),y
		cmp #$FF
		beq @noChain
		tax
		lda #$01
		sta SRAM_CHAIN_FLAGS,x
@noChain:		iny
		cpy #STEPS_PER_TRACK
		bcc @b
		ldx tmp2
		inx
		cpx #(5 * NUMBER_OF_SONGS)
		bcc @a0

		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda #NUMBER_OF_CHAINS
		sta SRAM_HEADER_FREE_CHAINS
		ldx #$00
		lda SRAM_HEADER_FREE_CHAINS
@c:		sec
		sbc SRAM_CHAIN_FLAGS,x
		inx
		cpx #NUMBER_OF_CHAINS
		bcc @c
		sta SRAM_HEADER_FREE_CHAINS
		rts
		
setupClearUnusedChains:		
		ldx #$00
@a:		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_CHAIN_FLAGS,x
		bne @used
		lda editChainAddressLo,x
		sta tmp0
		lda editChainAddressHi,x
		sta tmp1
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		ldy #$00
@b:		lda #$FF
		sta (tmp0),y
		iny
		lda #$00
		sta (tmp0),y
		iny
		cpy #(STEPS_PER_CHAIN * BYTES_PER_CHAIN_STEP)
		bcc @b
@used:		inx
		cpx #NUMBER_OF_CHAINS
		bcc @a
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		rts		


setupShowSongStatsWindow:
		ldx #$00
@a:		lda songStatWindow,x
		sta windowBuffer+(4*14),x
		inx
		cpx #(songStatWindowEnd-songStatWindow)
		bcc @a
		
		lda SRAM_HEADER_FREE_CHAINS
		ldx #(6*14)+10
		jsr phexWindow
		lda SRAM_HEADER_FREE_PATTERNS
		ldx #(8*14)+10
		jsr phexWindow
		rts
		
songStatWindow:
		.incbin "nametables/songStat.bin"
songStatWindowEnd:
		

writeSetupScreen:
		ldx #$00
		lda #CHR_SPACE
@a:		sta rowBuffer,x
		inx
		cpx #$20
		bcc @a

		ldy #$00
@b:		lda windowSetup,y
		sta windowBuffer,y
		iny
		cpy #(14 * 16)
		bcc @b
		
updateSetupScreen:
		lda SRAM_HEADER_PRELISTEN
		and #$01
		tax
		lda setupYesNoSwitch,x
		sta windowBuffer+(9*14)+12
		
		ldx #(15*14)+6
		lda UI_COLOUR_BG0
		jsr phexWindow2
		lda UI_COLOUR_02
		jsr phexWindow2
		lda UI_COLOUR_03
		jsr phexWindow2
		lda UI_COLOUR_01
		jsr phexWindow2
		
		lda editorCurrentSong
		ldx #(1*14)+12
		jsr phexWindow			

		ldx editorCurrentSong
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda SRAM_SONG_SPEEDS,x
		ldx #(2*14)+12
		jsr phexWindow
		
		rts

writeSetupHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleSetup,x
		sta titleBuffer,x
		lda headerSetup,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		rts
		

setupCursorColumns:
		.BYTE $53+(12*8)
		.BYTE $53+(12*8)

		.BYTE $53+(12*8)

		.BYTE $53+(12*8)
		.BYTE $53+(12*8)
		.BYTE $53+(12*8)

		.BYTE $53+(06*8)+0
		.BYTE $53+(08*8)+0
		.BYTE $53+(10*8)+0
		.BYTE $53+(12*8)+0
		

setupCursorRows:
		.BYTE 8 + $28 + (0*8)
		.BYTE 8 + $28 + (1*8)
		
		.BYTE 8 + $28 + (8*8)
		
		.BYTE 8 + $28 + (10*8)
		.BYTE 8 + $28 + (11*8)
		.BYTE 8 + $28 + (12*8)
		

		.BYTE 8 + $28 + (14*8)
		.BYTE 8 + $28 + (14*8)
		.BYTE 8 + $28 + (14*8)
		.BYTE 8 + $28 + (14*8)

rowOffsetSetup:
		.BYTE 0,0,0,0

		.BYTE 0,0,0,0

		
			
columnOffSetsetup:
		.BYTE 0,0,0,0
		.BYTE 0,0,0,0


;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
setupColumnCursorType:
		.BYTE 2,2
		.BYTE 1
		.BYTE 2,2,2
		.BYTE 2,2,2,2
		
setupYesNoSwitch:
		.BYTE CHR_N,CHR_Y
		
