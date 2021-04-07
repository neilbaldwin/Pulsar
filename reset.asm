.export editorInstrumentAddressLo,editorInstrumentAddressHi
.export editorLoop

;---------------------------------------------------------------
; CODE
;---------------------------------------------------------------
	
RESET:	sei		

	lda #$00
	sta PPU0
	sta PPU1

	;clear RAM
	lda #$FF
	ldx #$00
@a:	sta $0000,x
	sta $0100,x
	sta $0200,x
	sta $0300,x
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x
	inx
	bne @a

	ldx #$FF			;reset stack pointer
	txs

	lda #$00
	sta DO_NOT_INTERRUPT
	
	jsr resetMMC1
		
	lda #%00001100		;Set bank layout, H&V mirror, 16kb ROM at $C000. 8KB CHR
	jsr setMMC1r0

	jsr vblankwait	;warm up
	jsr vblankwait

	jsr initGraphics
	jsr clearSprites


	lda #WRAM_BANK_00
	jsr setMMC1r1
	lda #$01
	sta $7FFF	
	lda #WRAM_BANK_01
	jsr setMMC1r1
	lda #$02
	sta $7FFF	
	lda #WRAM_BANK_02
	jsr setMMC1r1
	lda #$04
	sta $7FFF	
	lda #WRAM_BANK_03
	jsr setMMC1r1
	lda #$08
	sta $7FFF
		
	lda #WRAM_BANK_00
	jsr setMMC1r1
	lda $7FFF
	cmp #$01
	bne @lockUp	
	lda #WRAM_BANK_01
	jsr setMMC1r1
	lda $7FFF
	cmp #$02
	bne @lockUp
	lda #WRAM_BANK_02
	jsr setMMC1r1
	lda $7FFF
	cmp #$04
	bne @lockUp
	lda #WRAM_BANK_03
	jsr setMMC1r1
	lda $7FFF
	cmp #$08
	beq @noLock

@lockUp:	lda #BANK_SCREEN
	jsr setPRGBank
	jsr errorScreen
	lda #$00
	sta $2005
	sta $2006
	sta $2006
	lda #%00001000
	sta PPU0
	lda #%00011010
	sta PPU1	
	jmp *

	
@noLock:	



	lda #BANK_EDITOR0
	jsr setPRGBank

	jsr readPad1
	lda PAD1_sel
	beq @noClear

	lda #%00010000		;WRAM bank 0?
	jsr setMMC1r1
	lda #$FF
	jsr clearWRAM
	
	.IF SRAM_MAP=32
	lda #%00010100		;WRAM bank 1?
	jsr setMMC1r1
	lda #$FF
	jsr clearWRAM

	lda #%00011000		;WRAM bank 2?
	jsr setMMC1r1
	lda #$FF
	jsr clearWRAM

	lda #%00011100		;WRAM bank 3?
	jsr setMMC1r1
	lda #$FF
	jsr clearWRAM
	.ENDIF

	lda #%00010000		;WRAM bank 0?
	jsr setMMC1r1
	jsr initEditorData

@noClear:
	lda #%00010000		;WRAM bank 0?
	jsr setMMC1r1		
	jsr pulsarGraphics
	
	lda #BANK_ENGINE
	jsr setPRGBank
	jsr initPulsar
	jsr plyrInitSong
	lda #BANK_EDITOR0
	jsr setPRGBank
	jsr initEditor
	
	jsr vblankwait	;warm up
	jsr vblankwait

	lda #%10001000
	sta PPU0
	lda #%00011010
	sta PPU1	

mainLoop:	
	lda #BANK_EDITOR0
	jsr setPRGBank
	jmp editorLoop


vblankwait:
:	bit $2002
	bpl :-
	rts
	
vblankendwait:
:	bit $2002
	bmi :-
	rts
	
editorLoop:
		
	lda vblankFlag		;wait for VBLANK
	cmp vblankFlagOld
	beq editorLoop
	pha
	
	sec
	sbc vblankFlagOld
	sta vblankOverflow
	pla
		
	sta vblankFlagOld
		
	jsr editorSetupSongPointers	
	jsr editorFlashCursor
	jsr editorUpdateScrollArrows
	jsr readPad1		;read pads
	jsr clearMarkers
	jsr updateVuMeters
	jsr editorDisplayBPM
	jsr editorUpdateTrackInfo
	jsr checkErrorMessages
		
	ldx editorMode		;jump table
	lda editorBankTable,x
	jsr setPRGBank
	lda editorModeTableLo,x
	sta editorVector
	lda editorModeTableHi,x
	sta editorVector+1
	jmp (editorVector)

editorSetupSongPointers:
	ldx editorCurrentSong
	lda songTrackIndexes,x
	tax
	lda editTrackAddressLo+0,x
	sta songVectors+0
	lda editTrackAddressHi+0,x
	sta songVectors+1

	lda editTrackAddressLo+1,x
	sta songVectors+2
	lda editTrackAddressHi+1,x
	sta songVectors+3

	lda editTrackAddressLo+2,x
	sta songVectors+4
	lda editTrackAddressHi+2,x
	sta songVectors+5

	lda editTrackAddressLo+3,x
	sta songVectors+6
	lda editTrackAddressHi+3,x
	sta songVectors+7

	lda editTrackAddressLo+4,x
	sta songVectors+8
	lda editTrackAddressHi+4,x
	sta songVectors+9

	rts
	
;---------------------------------------------------------------
; TABLES
;---------------------------------------------------------------

editorModeTableLo:
	.LOBYTES editSong,editChain,editPattern,editInstrument,editDrumkit
	.LOBYTES editEnvelopeTable,editTable,editVibratoTable,editDutyTable,editEchoTable
	.LOBYTES editSpeed,editFx,editSetup,editNavMenu

editorModeTableHi:
	.HIBYTES editSong,editChain,editPattern,editInstrument,editDrumkit
	.HIBYTES editEnvelopeTable,editTable,editVibratoTable,editDutyTable,editEchoTable
	.HIBYTES editSpeed,editFx,editSetup,editNavMenu

editorBankTable:
	.BYTE BANK_EDITOR0	;song
	.BYTE BANK_EDITOR0	;chain
	.BYTE BANK_EDITOR0	;pattern
	.BYTE BANK_EDITOR0	;instrument
	.BYTE BANK_EDITOR0	;drumkit
	.BYTE BANK_EDITOR0	;envelope
	.BYTE BANK_EDITOR0	;table
	.BYTE BANK_EDITOR0	;vibrato
	.BYTE BANK_EDITOR1	;duty
	.BYTE BANK_EDITOR1	;echo
	.BYTE BANK_EDITOR1	;speed
	.BYTE BANK_EDITOR1	;Fx
	.BYTE BANK_EDITOR1	;setup
	.BYTE BANK_EDITOR1	;nav		;nav always last mode
		
editorInstrumentAddressLo:
	.BYTE <plyrInstrumentCopyA
	.BYTE <plyrInstrumentCopyB
	.BYTE <plyrInstrumentCopyC
	.BYTE <plyrInstrumentCopyD
	.BYTE <plyrInstrumentCopyE

editorInstrumentAddressHi:
	.BYTE >plyrInstrumentCopyA
	.BYTE >plyrInstrumentCopyB
	.BYTE >plyrInstrumentCopyC
	.BYTE >plyrInstrumentCopyD
	.BYTE >plyrInstrumentCopyE

yesNoSwitch:
	.BYTE CHR_N,CHR_Y

;---------------------------------------------------------------
;---------------------------------------------------------------
	
delay01:
	ldx #$00
	inx
	ldy #$80
@a:	dey
	bne @a
	dex
	bne @a
	rts
	
whiteBar:
	lda #%11111111
	;sta PPU1

	jsr pulsarRefresh	
	
	lda #%00011110
	;sta PPU1
	rts
	
NMI:	pha
	txa
	pha
	tya
	pha
	
	bit PPU_STATUS

	lda DO_NOT_INTERRUPT
	bne @exitNMI

	lda currentPrgBank
	pha
	.IF SRAM_MAP=32
	lda currentSramBank
	pha
	.ENDIF
	
	lda #BANK_SCREEN
	jsr setPRGBank

	lda writePaletteFlag
	beq @noPalette
	jsr writePalette
	jmp @skipScreen
@noPalette:
	jsr dmaSecondary
@skipScreen:
	.IF DEBUG=1
	jsr debugNumbers
	.ENDIF
	jsr spriteDMA

	jsr spriteWriteFlashColour
	
	lda #$FD			;use X scroll to move screen to left by 8 pixels
	sta $2005
	lda #$00
	sta $2005
	lda #$00
	sta $2006
	sta $2006
	
	inc vblankFlag
	
	lda #BANK_ENGINE
	jsr setPRGBank
	
	lda #$00
	sta pulsarPassCounter
	
	jsr whiteBar	;1	
	jsr delay01
	jsr whiteBar	;2	
	jsr delay01
	jsr whiteBar	;3	


	;jsr delay01
	;jsr whiteBar	;4

	;lda #%11111111
	;sta PPU1
	jsr plyrRefresh
	lda #%00011110
	sta PPU1
	
	.IF SRAM_MAP=32
	pla
	jsr setMMC1r1
	.ENDIF	
	pla
	jsr setPRGBank
	
@exitNMI:	
	pla
	tay
	pla
	tax
	pla
IRQ:	rti
	
vblankWait:
	lda $2002
	bpl vblankWait
	rts

	.IF DEBUG=1
	.include "debug.asm"
	.ENDIF


initGraphics:
	;CHR Font
	lda #<font
	sta tmp0
	lda #>font
	sta tmp1
	lda #BANK_FONT
	jsr setPRGBank
	lda #>CHR_RAM_0
	sta $2006
	lda #<CHR_RAM_0
	sta $2006
	jsr writeFont
	lda #$00
	sta $2006
	sta $2006
	
	;SPR Font
	lda #<spr
	sta tmp0
	lda #>spr
	sta tmp1
	lda #>CHR_RAM_1
	sta $2006
	lda #<CHR_RAM_1
	sta $2006
	jsr writeFont
	lda #$00
	sta $2006
	sta $2006
	rts
	
	
pulsarGraphics:
	lda #BANK_FONT
	jsr setPRGBank

	lda #<layout
	sta tmp0
	lda #>layout
	sta tmp1

	lda #>SCREEN
	sta $2006
	lda #<SCREEN
	sta $2006
	ldy #$00
	ldx #$04
@c:	lda (tmp0),y
	sta $2007
	iny
	bne @c
	inc tmp1
	dex
	bne @c
	lda #$00
	sta $2006
	sta $2006

	lda #BANK_EDITOR0
	jsr setPRGBank
	
	lda PAD1_firea
	beq @notInitPalette
	jsr initPalette
@notInitPalette:
	jsr writePalette
	rts

initPalette:
	.IF SRAM_MAP=32
	lda #SRAM_HEADER_BANK
	jsr setMMC1r1
	.ENDIF
	ldx #$00
@a:	lda palette,x
	sta SRAM_PALETTE,x
	inx
	cpx #$20
	bcc @a
	rts
	
writePalette:
	;jsr vblankWait
	lda #$3f
	ldx #$00
	sta $2006
	stx $2006
@a:	lda SRAM_PALETTE,x
	sta $2007
	inx
	cpx #$20
	bne @a
	lda #$00
	sta $2006
	sta $2006
	sta writePaletteFlag
	rts

writeFont:
	ldx #$10
	ldy #$00
@writeFont:
	lda (tmp0),y
	sta $2007
	iny
	bne @writeFont
	inc tmp1
	dex
	bne @writeFont
	rts

palette:	.incbin "set.dat"

spriteDMA:	
	lda #$00
	sta $2003
	lda #>sprBuf
	sta $4014
	rts
	
spriteWriteFlashColour:
	;Flash palette
	lda #>$3F13
	sta $2006
	lda #<$3F13
	sta $2006
	lda cursorFlashColour
	sta $2007
	;lda #$00
	;sta $2006
	;sta $2006
	rts

clearSprites:
	ldx #$00
@a:	lda #240
	sta SPR00_Y,x
	lda #$FF
	sta SPR00_CHAR,x
	lda #$00
	sta SPR00_ATTR,x
	lda #$00
	sta SPR00_X,x
	inx
	inx
	inx
	inx
	bne @a	
	rts

;---------------------------------------------------------------
; COMMON ROUTINES/TABLES THAT PLAYER AND ALL EDITORS NEED
;---------------------------------------------------------------

debugPhex:	
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	sta $2007
	pla
	and #$0F
	sta $2007
	rts

phexWindow:
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	sta windowBuffer,x
	inx
	pla
	and #$0F
	sta windowBuffer,x
	inx
	rts

phexWindow2:
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$80
	sta windowBuffer,x
	inx
	pla
	and #$0F
	ora #$80
	sta windowBuffer,x
	inx
	rts

phexWindow3:
	cmp #$FF
	bne @a
	lda #CHR_EMPTY
	sta windowBuffer,x
	inx
	sta windowBuffer,x
	inx
	rts
	
@a:	pha
	lsr a
	lsr a
	lsr a
	lsr a
	sta windowBuffer,x
	inx
	pla
	and #$0F
	sta windowBuffer,x
	inx
	rts

phexRow:	pha
	lsr a
	lsr a
	lsr a
	lsr a
	sta rowBuffer,x
	inx
	pla
	and #$0F
	sta rowBuffer,x
	inx
	rts

phexTitle:
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	sta titleBuffer,x
	inx
	pla
	and #$0F
	sta titleBuffer,x
	rts
	

;---------------------------------------------------------------
; SHOW HINT
;---------------------------------------------------------------
editorShowHint:
		cmp #$FF
		bne @ok
		rts
@ok:
		tax
		lda currentPrgBank
		pha
		lda #BANK_HINTS
		jsr setPRGBank
		lda hintAddressLo,x
		sta tmp0
		lda hintAddressHi,x
		sta tmp1

		cpy #$08
		bcs @upper
		tya
		clc
		adc #$01
		jmp @b
@upper:		tya
		sec
		sbc #$08
		bpl @b
		lda #$00
@b:		tay
		lda hintFourteens,y
		tax

		ldy #$00
@loop:		lda (tmp0),y
		sta windowBuffer,x
		inx
		iny
		cpy #(8*14)
		bcc @loop

		pla
		jsr setPRGBank
		rts
		

;---------------------------------------------------------------
; ENGINE CODE
;---------------------------------------------------------------
	.include "joypad.asm"

SetBits:	.BYTE %00000001,%00000010,%00000100,%00001000,%00010000

ClrBits:	.BYTE %11111110,%11111101,%11111011,%11110111,%11101111	


;---------------------------------------------------------------
; DEBUGGING STUB
;---------------------------------------------------------------
		
editTrackAddressLo: .LOBYTES SRAM_TRACK_A0,SRAM_TRACK_B0,SRAM_TRACK_C0,SRAM_TRACK_D0,SRAM_TRACK_E0
		.IF SRAM_MAP=32
		.LOBYTES SRAM_TRACK_A1,SRAM_TRACK_B1,SRAM_TRACK_C1,SRAM_TRACK_D1,SRAM_TRACK_E1
		.LOBYTES SRAM_TRACK_A2,SRAM_TRACK_B2,SRAM_TRACK_C2,SRAM_TRACK_D2,SRAM_TRACK_E2
		.LOBYTES SRAM_TRACK_A3,SRAM_TRACK_B3,SRAM_TRACK_C3,SRAM_TRACK_D3,SRAM_TRACK_E3
		.LOBYTES SRAM_TRACK_A4,SRAM_TRACK_B4,SRAM_TRACK_C4,SRAM_TRACK_D4,SRAM_TRACK_E4
		.LOBYTES SRAM_TRACK_A5,SRAM_TRACK_B5,SRAM_TRACK_C5,SRAM_TRACK_D5,SRAM_TRACK_E5
		.LOBYTES SRAM_TRACK_A6,SRAM_TRACK_B6,SRAM_TRACK_C6,SRAM_TRACK_D6,SRAM_TRACK_E6
		.LOBYTES SRAM_TRACK_A7,SRAM_TRACK_B7,SRAM_TRACK_C7,SRAM_TRACK_D7,SRAM_TRACK_E7
		.ENDIF
				
editTrackAddressHi:
 		.HIBYTES SRAM_TRACK_A0,SRAM_TRACK_B0,SRAM_TRACK_C0,SRAM_TRACK_D0,SRAM_TRACK_E0
		.IF SRAM_MAP=32
		.HIBYTES SRAM_TRACK_A1,SRAM_TRACK_B1,SRAM_TRACK_C1,SRAM_TRACK_D1,SRAM_TRACK_E1
		.HIBYTES SRAM_TRACK_A2,SRAM_TRACK_B2,SRAM_TRACK_C2,SRAM_TRACK_D2,SRAM_TRACK_E2
		.HIBYTES SRAM_TRACK_A3,SRAM_TRACK_B3,SRAM_TRACK_C3,SRAM_TRACK_D3,SRAM_TRACK_E3
		.HIBYTES SRAM_TRACK_A4,SRAM_TRACK_B4,SRAM_TRACK_C4,SRAM_TRACK_D4,SRAM_TRACK_E4
		.HIBYTES SRAM_TRACK_A5,SRAM_TRACK_B5,SRAM_TRACK_C5,SRAM_TRACK_D5,SRAM_TRACK_E5
		.HIBYTES SRAM_TRACK_A6,SRAM_TRACK_B6,SRAM_TRACK_C6,SRAM_TRACK_D6,SRAM_TRACK_E6
		.HIBYTES SRAM_TRACK_A7,SRAM_TRACK_B7,SRAM_TRACK_C7,SRAM_TRACK_D7,SRAM_TRACK_E7
		.ENDIF
editChainAddressLo:
		.REPEAT NUMBER_OF_CHAINS,c
		.BYTE <(SRAM_CHAINS + (c * STEPS_PER_CHAIN * BYTES_PER_CHAIN_STEP))
		.ENDREPEAT
editChainAddressHi:
		.REPEAT NUMBER_OF_CHAINS,c
		.BYTE >(SRAM_CHAINS + (c * STEPS_PER_CHAIN * BYTES_PER_CHAIN_STEP))
		.ENDREPEAT

editPatternAddressLo:
		.REPEAT NUMBER_OF_PATTERNS,p
		.BYTE <(SRAM_PATTERNS+(p * STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP))
		.ENDREPEAT

editPatternAddressHi:
		.REPEAT NUMBER_OF_PATTERNS,p
		.BYTE >(SRAM_PATTERNS+(p * STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP))
		.ENDREPEAT

editInstrumentAddressLo:
		.REPEAT NUMBER_OF_INSTRUMENTS,i
		.BYTE <(SRAM_INSTRUMENTS+(i * STEPS_PER_INSTRUMENT * BYTES_PER_INSTRUMENT_STEP))
		.ENDREPEAT

editInstrumentAddressHi:
		.REPEAT NUMBER_OF_INSTRUMENTS,i
		.BYTE >(SRAM_INSTRUMENTS+(i * STEPS_PER_INSTRUMENT * BYTES_PER_INSTRUMENT_STEP))
		.ENDREPEAT


editDrumkitAddressLo:
		.REPEAT NUMBER_OF_DRUMKITS,i
		.BYTE <(SRAM_DRUMKITS+(i * STEPS_PER_DRUMKIT * BYTES_PER_DRUMKIT_STEP))
		.ENDREPEAT
		
editDrumkitAddressHi:
		.REPEAT NUMBER_OF_DRUMKITS,i
		.BYTE >(SRAM_DRUMKITS+(i * STEPS_PER_DRUMKIT * BYTES_PER_DRUMKIT_STEP))
		.ENDREPEAT

editTableAddressLo:
		.REPEAT NUMBER_OF_TABLES,p
		.BYTE <(SRAM_TABLES+(p * STEPS_PER_TABLE * BYTES_PER_TABLE_STEP))
		.ENDREPEAT

editTableAddressHi:
		.REPEAT NUMBER_OF_TABLES,p
		.BYTE >(SRAM_TABLES+(p * STEPS_PER_TABLE * BYTES_PER_TABLE_STEP))
		.ENDREPEAT

editDutyAddressLo:
		.REPEAT NUMBER_OF_DUTY_TABLES,c
		.BYTE <(SRAM_DUTY_TABLES + (c * STEPS_PER_DUTY_TABLE * BYTES_PER_DUTY_TABLE_STEP))
		.ENDREPEAT
editDutyAddressHi:
		.REPEAT NUMBER_OF_DUTY_TABLES,c
		.BYTE >(SRAM_DUTY_TABLES + (c * STEPS_PER_DUTY_TABLE * BYTES_PER_DUTY_TABLE_STEP))
		.ENDREPEAT


editSpeedAddressLo:	.REPEAT NUMBER_OF_SPEED_TABLES,c
		.BYTE <(SRAM_SPEED_TABLES + (c * STEPS_PER_SPEED_TABLE * BYTES_PER_SPEED_TABLE_STEP))
		.ENDREPEAT
		
editSpeedAddressHi:	.REPEAT NUMBER_OF_SPEED_TABLES,c
		.BYTE >(SRAM_SPEED_TABLES + (c * STEPS_PER_SPEED_TABLE * BYTES_PER_SPEED_TABLE_STEP))
		.ENDREPEAT

editFxAddressLo:	.REPEAT NUMBER_OF_FX_TABLES,c
		.BYTE <(SRAM_FX_TABLES + (c * STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP))
		.ENDREPEAT
		
editFxAddressHi:	.REPEAT NUMBER_OF_FX_TABLES,c
		.BYTE >(SRAM_FX_TABLES + (c * STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP))
		.ENDREPEAT


		.EXPORT editTrackAddressLo,editTrackAddressHi
		.EXPORT editSpeedAddressLo,editSpeedAddressHi
		.EXPORT editChainAddressLo,editChainAddressHi
		.EXPORT editPatternAddressLo,editPatternAddressHi
		.EXPORT editInstrumentAddressLo,editInstrumentAddressHi
		.EXPORT editDrumkitAddressLo,editDrumkitAddressHi
		.EXPORT editTableAddressLo,editTableAddressHi
		.EXPORT editDutyAddressLo,editDutyAddressHi
		.EXPORT editSpeedAddressLo,editSpeedAddressLo
		.EXPORT editFxAddressLo,editFxAddressLo
		.EXPORT chainRowsIndex,patternRowsIndex,dutyRowsIndex
		.EXPORT tableRowsIndex,vibratoRowsIndex,drumkitRowsIndex
		.EXPORT phexTitle,phexRow,phexWindow
		.EXPORT editorShowHint
		.EXPORT SetBits,ClrBits, readPad1

songTrackIndexes:	.REPEAT 8,i
		.BYTE i * 5
		.ENDREPEAT
chainRowsIndex:
		.REPEAT STEPS_PER_CHAIN,i
		.BYTE i * BYTES_PER_CHAIN_STEP
		.ENDREPEAT

patternRowsIndex:
		.REPEAT STEPS_PER_PATTERN,i
		.BYTE i * BYTES_PER_PATTERN_STEP
		.ENDREPEAT

dutyRowsIndex:
		.REPEAT STEPS_PER_DUTY_TABLE,i
		.BYTE i*BYTES_PER_DUTY_TABLE_STEP
		.ENDREPEAT

tableRowsIndex:
		.REPEAT STEPS_PER_TABLE,i
		.BYTE i*BYTES_PER_TABLE_STEP
		.ENDREPEAT
tableRowsIndex2:
		.REPEAT STEPS_PER_TABLE,i
		.BYTE (i*BYTES_PER_TABLE_STEP)+2
		.ENDREPEAT

vibratoRowsIndex:
		.REPEAT NUMBER_OF_VIBRATOS,i
		.BYTE i*BYTES_PER_VIBRATO
		.ENDREPEAT

drumkitRowsIndex:
		.REPEAT STEPS_PER_DRUMKIT,i
		.BYTE i * BYTES_PER_DRUMKIT_STEP
		.ENDREPEAT

echoRowsIndex:
		.REPEAT NUMBER_OF_ECHOES,i
		.BYTE i*BYTES_PER_ECHO
		.ENDREPEAT	
fxRowsIndex:
		.REPEAT STEPS_PER_FX_TABLE,i
		.BYTE i*BYTES_PER_FX_TABLE_STEP
		.ENDREPEAT

		
;---------------------------------------------------------------
; MMC1 CODE
;---------------------------------------------------------------
clearWRAM:
	ldx #<SRAM
	stx tmp0
	ldx #>SRAM
	stx tmp1
	ldx #$20
	ldy #$00
@clearWram:
	sta (tmp0),y
	iny
	bne @clearWram
	inc tmp1
	dex
	bne @clearWram
	rts

resetMMC1:
	ldx #$80
	stx $8000
	rts

setPRGBank:
	sta currentPrgBank
	sta $E000
	lsr a
	sta $E000
	lsr a
	sta $E000
	lsr a
	sta $E000
	lsr a
	sta $E000
	rts
	
setMMC1r0:
	sta $9fff
	lsr a
	sta $9fff
	lsr a
	sta $9fff
	lsr a
	sta $9fff
	lsr a
	sta $9fff
	rts

setMMC1r1:
	sta currentSramBank
	sta $Bfff
	lsr a
	sta $Bfff
	lsr a
	sta $Bfff
	lsr a
	sta $Bfff
	lsr a
	sta $Bfff
	rts

setMMC1r2:
	sta $Dfff
	lsr a
	sta $Dfff
	lsr a
	sta $Dfff
	lsr a
	sta $Dfff
	lsr a
	sta $Dfff
	rts
		