;---------------------------------------------------------------
; PULSAR EDITOR
;---------------------------------------------------------------
	

initEditor:
		jsr editorCheckWRAM
		
		jsr initEditorVars
		lda #$00
		sta setupCursorX
		sta setupCursorY

		jsr initEditorKeys
		jsr clearCopyInfoBuffer
		jsr errorBufferClear
		
		lda #$FF
		sta lfsr
		
		lda #$00
		sta dmaCycleFlag
		
		lda #$00
		sta editorPlayingNote
		
		lda #$00
		sta waitForTapA
		
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
				
		lda #$01
		sta SRAM_HEADER_PRELISTEN	;*SRAM*
		
		lda #PLAY_MODE_STOPPED
		sta plyrPlayMode
		
		lda #$00
		sta hintMode
		lda #$00
		sta editBufferFlag
		sta editNavFlag
		
		lda #$00
		sta blockMode
		lda #$FF
		sta blockStart
		sta blockEnd
		sta blockOrigin
		
		lda #$00
		sta editorCurrentSong
			
		lda #EDIT_MODE_SONG		;start in Song mode
		sta editorMode
		lda #EDIT_MODE_SONG
		sta editorPreviousModes
		lda #$00
		sta editorModeIndex
		lda #$02			;force window and header/title text to be written to screen
		sta writeScreen
		lda #$01
		sta dmaUpdateWindow
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		jsr editorInitSprites
		rts

initEditorKeys:	ldx #$00
		txa
@a:		sta editorKeys,x
		inx
		cpx #<(editorKeysEnd-editorKeys)
		bne @a
		rts
	
editorCheckWRAM:	lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		lda SRAM_HEADER_0
		cmp @signature+0
		bne @clear
		lda SRAM_HEADER_1
		cmp @signature+1
		bne @clear
		lda SRAM_HEADER_2
		cmp @signature+2
		bne @clear
		lda SRAM_HEADER_3
		cmp @signature+3
		bne @clear
		jmp @c		;always write signature and version number
		
@clear:		lda #$00
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

		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		
@c:		ldx #$00
@b:		lda @signature,x
		sta SRAM_HEADER_0,x
		inx
		cpx #$06
		bcc @b

		lda #$00
		sta DO_NOT_INTERRUPT
		rts

@signature:	.BYTE $50,$4E,$45,$53
@version:		.BYTE $01,$04
	
;---------------------------------------------------------------
; COMMON ROUTINES
;---------------------------------------------------------------
editorUpdateTrackInfo:
		lda editorCurrentTrack
		clc
		adc #$0A
		;adc #$8A
		sta infoBuffer1+1
		lda #$A4
		sta infoBuffer1+2
		lda songCursorY
		clc
		adc songFirstRow
		pha
		lsr a
		lsr a
		lsr a
		lsr a
		clc
		;ora #$80
		sta infoBuffer1+3
		pla
		and #$0F
		;ora #$80
		sta infoBuffer1+4
		
		lda editorCurrentChain
		pha
		lsr a
		lsr a
		lsr a
		lsr a
		clc
		;ora #$80
		sta infoBuffer2+0
		pla
		and #$0F
		;ora #$80
		sta infoBuffer2+1
		lda #$A4
		sta infoBuffer2+2
		lda editChainIndex
		pha
		lsr a
		lsr a
		lsr a
		lsr a
		clc
		;ora #$80
		sta infoBuffer2+3
		pla
		and #$0F
		;ora #$80
		sta infoBuffer2+4
		rts


editorUpdateCopyInfo:
		lda copyBufferObjectType
		bmi @x
		asl a
		clc
		adc copyBufferObjectType
		tax
		lda copyBufferNames,x
		sta copyInfoBuffer+0
		lda copyBufferNames+1,x
		sta copyInfoBuffer+1
		lda copyBufferNames+2,x
		sta copyInfoBuffer+2
		ldx #$03
		lda #$A4
		sta copyInfoBuffer,x
		inx
		lda copyBufferObject
		jsr @phex
		lda #$A4
		sta copyInfoBuffer,x
		inx
		lda copyBufferStartIndex
		jsr @phex
		lda #$01
		sta copyInfoFlag
		rts
@x:		jmp clearCopyInfoBuffer
	
@phex:		pha
		lsr a
		lsr a
		lsr a
		lsr a
		sta copyInfoBuffer,x
		inx
		pla
		and #$0F
		sta copyInfoBuffer,x
		inx
		rts

clearCopyInfoBuffer:
		ldx #$00
@a:		lda _clearCopyInfoBuffer,x
		sta copyInfoBuffer,x
		inx
		cpx #$09
		bcc @a
		stx copyInfoFlag
		rts

_clearCopyInfoBuffer:
		.byte $25,$25,$25,$A4,$25,$25,$A4,$25,$25
			
copyBufferNames:	.byte $25,$25,$25		;---
		.byte $0C,$11,$17		;CHN
		.byte $19,$0A,$1D		;PAT
		.byte $12,$17,$1C		;INS
		.byte $0D,$1B,$16		;DRM
		.byte $25,$25,$25		;---
		.byte $1D,$0A,$0B		;TAB
		.byte $25,$25,$25		;---
		.byte $0D,$1E,$1D		;DUT
		.byte $25,$25,$25		;---
		.byte $1C,$19,$0D		;SPD
		.byte $16,$0F,$21		;MFX


errorBufferClear:
		lda #$35
		ldx #$00
@a:		sta errorMessageBuffer,x
		inx
		cpx #$10
		bcc @a
		lda #$01
		sta errorMessageFlag
		rts


checkErrorMessages:
		lda errorMessageNumber
		bmi @noNewError
		
		tax
		lda errorMessageLo,x
		sta tmp0
		lda errorMessageHi,x
		sta tmp1
		ldy #$00
@a:		lda (tmp0),y
		sta errorMessageBuffer,y
		iny
		cpy #$10
		bcc @a
		
		lda #$FF
		sta errorMessageNumber
		lda #ERROR_DISPLAY_TIME
		sta errorCounter
		sta errorMessageFlag
		
@noNewError:	lda errorCounter
		beq @x
		
		dec errorCounter
		bne @x
		
		jsr errorBufferClear
		lda #$01
		sta errorMessageFlag
@x:		rts

errorMessageLo:	.LOBYTES errorMessages+$00, errorMessages+$10, errorMessages+$20
errorMessageHi:	.HiBYTES errorMessages+$00, errorMessages+$10, errorMessages+$20

errorMessages:	.incbin "nametables/errors.bin"




clearMarkers:	lda #CHR_SPACE
		sta SPR05_CHAR
		sta SPR06_CHAR
		sta SPR07_CHAR
		sta SPR08_CHAR
		sta SPR09_CHAR
@noShowA:		rts


SPR_UP_ARROW	= SPR03_CHAR
SPR_DN_ARROW	= SPR04_CHAR

editorUpdateScrollArrows:
		lda #$FF
		sta SPR_UP_ARROW
		sta SPR_DN_ARROW
		ldx editorMode
		;lda editorModeScrolling,x
		lda editorModeFirstRow,x
		beq @x
@a:		lda songFirstRow,x
		bne @b
		lda #$05
		sta SPR_DN_ARROW
		bne @x
@b:		lda #$04
		sta SPR_UP_ARROW
		lda songFirstRow,x
		cmp editorModeFirstRow,x
		bcs @x
		lda #$05
		sta SPR_DN_ARROW		
@x:		rts
	
;---------------------------------------------------------------		
; GLOBAL KEYS
;---------------------------------------------------------------				
globalKeys:
		;jsr checkKeysSel

		lda PAD1_fireb
		beq @noHoldB
		lda keysTapSel
		;lda PAD1_dsel
		beq @noTapSel
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		ldy editorCurrentSong
		ldx editorCurrentTrack
		lda SRAM_SONG_MUTE,y	;*SRAM*
		eor SetBits,x
		sta SRAM_SONG_MUTE,y	;*SRAM*
		rts		

@noHoldB:
@noTapSel:
		;lda PAD1_sel
		;beq @noSel
		;lda PAD1_firea
		;bne @noSel
		;lda PAD1_dud
		;beq @noUD
		;bmi @selUp
		;lda PAD1_fireb
		;bne @noStart
		

	
@noUD:			
@noSel:
@noStart:
		jsr navigationKeys
		jsr editorStartButton
		rts
;---------------------------------------------------------------		
; START Button handling
;---------------------------------------------------------------				


editorStartButton:
		lda PAD1_dsta
		beq @x
		lda PAD1_fireb
		bne @solo
		lda PAD1_sel
		beq @notBegin
		lda #$00
		jmp @startSong
		
@solo:
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		ldy editorCurrentSong
		lda editorCurrentTrack
		cmp SRAM_SONG_SOLO,y		;*SRAM*		
		bne @notToggleSolo
		lda #$FF
@notToggleSolo:	sta SRAM_SONG_SOLO,y		;*SRAM*
		rts
				
@notBegin:	lda plyrPlayMode
		beq @notPlaying
		lda #$00
		sta plyrPlaying
		sta plyrPlayMode
		rts
		
@notPlaying:	lda editorMode
		cmp #EDIT_MODE_SONG
		bne @notSongMode
		
		lda #PLAY_MODE_SONG
		sta plyrPlayMode
		lda songFirstRow
		clc
		adc songCursorY
		jmp @startSong

@notSongMode:	cmp #EDIT_MODE_CHAIN
		bne @notChainMode
	
		jmp @startChain

@notChainMode:	jmp @startPattern

@x:		rts

@startSong:	ldx #$00
		stx plyrPlaying
		sta plyrSongStartIndex
@a:		sta plyrTrackIndex,x
		inx
		cpx #$05
		bcc @a
		ldx #$00
		lda #$00
@b:		sta plyrChainIndex,x
		sta plyrPatternIndex,x
		sta plyrDelayNoteCounter,x
		sta plyrRetriggerCounter,x
		inx
		cpx #$05
		bcc @b
		sta plyrPatternStepCounter
		sta plyrSpeedTableIndex
		
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
		
		ldx editorCurrentSong
		lda SRAM_SONG_SPEEDS,x
		sta plyrCurrentSpeedTable
		
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
		
		lda #$1F
		sta tmp0
		ldy plyrTrackIndex
		lda (songVectors+$00),y	;*SRAM*
		cmp #$FF
		bne :+
		lda tmp0
		and ClrBits+0
		sta tmp0
:		lda (songVectors+$02),y	;*SRAM*
		cmp #$FF
		bne :+
		lda tmp0
		and ClrBits+1
		sta tmp0
:		lda (songVectors+$04),y	;*SRAM*
		cmp #$FF
		bne :+
		lda tmp0
		and ClrBits+2
		sta tmp0
:		lda (songVectors+$06),y	;*SRAM*
		cmp #$FF
		bne :+
		lda tmp0
		and ClrBits+3
		sta tmp0
:		lda (songVectors+$08),y	;*SRAM*
		cmp #$FF
		bne :+
		lda tmp0
		and ClrBits+4
		sta tmp0
:
		lda tmp0
		sta plyrPlaying
		lda #PLAY_MODE_SONG
		sta plyrPlayMode
		rts

@startChain:	lda #PLAY_MODE_CHAIN
		sta plyrPlayMode
		lda #$00
		sta plyrPlaying
		
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		ldx editorCurrentChain
		lda editChainAddressLo,x
		sta tmp0
		lda editChainAddressHi,x
		sta tmp1
		lda editChainIndex
		asl a
		tay
		lda (tmp0),y
		sta tmp2
		cmp #$FF
		bne @notEmptyChainCell
		ldy #$00
		lda (tmp0),y
		cmp #$FF
		beq @noPlayChain
		sta tmp2

@notEmptyChainCell:		
		tya
		lsr a
		ldx editorCurrentTrack
		sta plyrChainIndex,x
		lda tmp2
		sta plyrCurrentPattern,x

		lda #$00
		sta plyrPatternIndex,x
		sta plyrDelayNoteCounter,x
		sta plyrRetriggerCounter,x
		
		sta plyrCurrentSpeedTable
		sta plyrSpeedTableIndex
		sta plyrPatternStepCounter
		
		lda editorCurrentChain
		sta plyrCurrentChain,x
		lda SetBits,x
		sta plyrPlaying
@noPlayChain:		
		rts

@startPattern:	lda #PLAY_MODE_PATTERN
		sta plyrPlayMode
		lda #$00
		sta plyrPlaying
		
		lda editorCurrentPattern
		ldx editorCurrentTrack
		sta plyrCurrentPattern,x
		
		lda #$00
		sta plyrPatternIndex,x
		sta plyrDelayNoteCounter,x
		sta plyrRetriggerCounter,x
		sta plyrCurrentSpeedTable
		sta plyrSpeedTableIndex
		sta plyrPatternStepCounter

		lda editorCurrentChain
		sta plyrCurrentChain,x
		lda SetBits,x
		sta plyrPlaying
@noPlayPattern:	rts	
		
;---------------------------------------------------------------		
; Mode context navigation
;---------------------------------------------------------------				
navigationKeys:	
		lda PAD1_firea
		ora PAD1_sel
		beq @goChange
		jmp @noModeChange

@goChange:
		lda keysTapB
		bne @modeChange
		lda #$00
		sta editNavFlag
		lda keysHoldB
		bne @doNav
		jmp @noNav
@doNav:		lda #$01
		sta editNavFlag
		lda PAD1_dlr
		beq @noLR
		bmi @goBack
		;jmp @modeChange
		
		ldx editorMode
		cpx #EDIT_MODE_SONG
		beq @switchMode
		cpx #EDIT_MODE_CHAIN
		beq @switchMode
		cpx #EDIT_MODE_PATTERN
		beq @switchMode
		jmp @noNav
		
@switchMode:	cpx #EDIT_MODE_PATTERN
		bne @switch
		lda editorCurrentTrack
		cmp #$04
		bne @switch
		ldx #EDIT_MODE_DRUMKIT-1
@switch:		inx
		txa
		jmp changeEditorMode
		
		
@goBack:		jmp getPreviousMode
		
@noLR:		lda PAD1_dud
		beq @noNav
		bmi @setupMenu
		lda editorMode
		ldx editorModeIndex
		sta editorPreviousModes,x
		inx
		cpx #$10
		bcs @nav0
		stx editorModeIndex
@nav0:		
		lda #EDIT_MODE_NAV_MENU
		sta editorMode
		lda #$02
		sta writeScreen
		rts

@setupMenu:	lda editorMode
		ldx editorModeIndex
		sta editorPreviousModes,x
		inx
		cpx #$10
		bcc @setup0
		stx editorModeIndex
@setup0:		lda #EDIT_MODE_SETUP
		sta editorMode
		lda #$02
		sta writeScreen
		rts
		
@modeChange:	lda #$00
		sta keysTapB
		ldx editorMode
		lda navKeysHi,x
		pha
		lda navKeysLo,x
		pha
@noNav:		rts

@noModeChange:		
		lda PAD1_sel
		clc
		adc PAD1_fireb
		cmp #$02
		bcs @changeTrack
		rts
		
		;
		; SELECT+B then L/R (change track from within editor)
		;
@changeTrack:	lda PAD1_dlr
		beq @noNav
		clc
		adc editorCurrentTrack
		bmi @noNav
		cmp #$05
		bcs @noNav
		sta editorCurrentTrack
		tax
		lda editTrackAddressLo,x
		sta trackVector
		lda editTrackAddressHi,x
		sta trackVector+1
		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
		ldy songTrackIndex
		lda (trackVector),y
		cmp #$FF
		bne @changeChain
		ldy #$00
		lda (trackVector),y
		cmp #$FF
		beq @noChange
@changeChain:	sta editorCurrentChain
		tax
		lda #$02
		sta writeScreen
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		lda editChainAddressLo,x
		sta chainVector
		lda editChainAddressHi,x
		sta chainVector+1
		lda editChainIndex
		asl a
		tay
		lda (chainVector),y
		cmp #$FF
		bne @changePattern
		ldy #$00
		lda (chainVector),y
		cmp #$FF
		beq @noChange
@changePattern:	sta editorCurrentPattern
		tya
		lsr a
		sta editChainIndex
		lda #$02
		sta writeScreen
@noChange:	rts
			

		
navKeysHi:	.HIBYTES _navSong-1,_navChain-1,_navPattern-1,_navInstrument-1,_navDrumkit-1
		.HIBYTES _navEnvelope-1,_navTable-1,_navVibrato-1,_navDuty-1,_navEcho-1
		.HIBYTES _navSpeed-1,_navFx-1,_navSetup-1,_navNavMenu-1
		
navKeysLo:	.LOBYTES _navSong-1,_navChain-1,_navPattern-1,_navInstrument-1,_navDrumkit-1
		.LOBYTES _navEnvelope-1,_navTable-1,_navVibrato-1,_navDuty-1,_navEcho-1
		.LoBYTES _navSpeed-1,_navFx-1,_navSetup-1,_navNavMenu-1

;---------------------------------------------------------------
; Nav Song
;---------------------------------------------------------------		
_navSong:		.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
		ldy songTrackIndex
		lda (trackVector),y
		cmp #$FF
		beq @noChange
		sta editorCurrentChain
@noChange:	lda #EDIT_MODE_CHAIN
		jmp changeEditorMode
		rts

;---------------------------------------------------------------
; Nav Chain
;---------------------------------------------------------------		
_navChain:	.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		ldy chainCursorX
		cpy #CHAIN_COLUMN_PATTERN
		beq @pattern
		dey
@pattern:		lda (chainVector),y
		cmp #$FF
		beq @noChange
		sta editorCurrentPattern
@noChange:	lda #EDIT_MODE_PATTERN
		jmp changeEditorMode
		rts
		
;---------------------------------------------------------------
; Nav Pattern
;---------------------------------------------------------------		
_navPattern:	.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF

		ldy patternCursorX
		cpy #PATTERN_COLUMN_INSTRUMENT
		bne @notInstrument
		lda editorCurrentTrack
		cmp #SONG_TRACK_E
		bne @notDrum
		lda (patternVector),y
		cmp #$FF
		beq @noChangeCurrentDrum
		and #$01			;*** TEMP to limit drum to 0 or 1 ***
		sta editorCurrentDrumkit
@noChangeCurrentDrum:	
		lda #EDIT_MODE_DRUMKIT
		jmp changeEditorMode
@notDrum:		lda (patternVector),y
		cmp #$FF
		beq @noChangeIns
		sta editorCurrentInstrument
@noChangeIns:	lda #EDIT_MODE_INSTRUMENT
		jmp changeEditorMode
@notInstrument:	cpy #PATTERN_COLUMN_COMMAND
		bne @notCommand
		lda patternVector
		sta tmp0
		lda patternVector+1
		sta tmp1
		jmp _navCommand
@notCommand:	cpy #PATTERN_COLUMN_COMMAND_DATA
		bne @notData
		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF
		lda patternVector
		sta tmp0
		lda patternVector+1
		sta tmp1
		dey
		jmp _navCommand
@notData:		rts

;---------------------------------------------------------------
; Nav Instrument
;---------------------------------------------------------------		
_navInstrument:	.IF SRAM_MAP=32
		lda #SRAM_INSTRUMENT_BANK
		jsr setMMC1r1
		.ENDIF
		cpy #INSTRUMENT_ROW_ENVELOPE
		bne @noEnv
		lda (instrumentVector),y
		sta editorCurrentEnvelope
		cmp #NUMBER_OF_ENVELOPES-$10
		bcs @env0
		sta envelopeFirstRow
		lda #$00
		sta envelopeCursorY
		jmp @envMode
@env0:		sec
		sbc #NUMBER_OF_ENVELOPES-$10
		sta envelopeCursorY
		lda #NUMBER_OF_ENVELOPES-$10
		sta envelopeFirstRow
@envMode:		lda #EDIT_MODE_ENVELOPE_TABLE
		jmp changeEditorMode
		
@noEnv:		cpy #INSTRUMENT_ROW_DUTY
		bne @notDuty
		lda (instrumentVector),y
		cmp #$04
		bcc @notDutyTable
		sbc #$04
		sta editorCurrentDuty
		lda #EDIT_MODE_DUTY_TABLE
		jmp changeEditorMode
@notDutyTable:	rts
		
@notDuty:		cpy #INSTRUMENT_ROW_TABLE
		bne @notTable
		lda (instrumentVector),y
		cmp #$FF
		beq @goTable
		sta editorCurrentTable
@goTable:		lda #EDIT_MODE_PITCH_TABLE
		jmp changeEditorMode
		
@notTable:	cpy #INSTRUMENT_ROW_VIBRATO
		bne @noVib
		lda (instrumentVector),y
		cmp #$FF
		beq @goVib
		sta editorCurrentVibrato
		.IF (NUMBER_OF_VIBRATOS < $11)
		sta vibratoCursorY
@goVib:		lda #EDIT_MODE_VIBRATO_TABLE
		jmp changeEditorMode
		.ELSE
		cmp #NUMBER_OF_VIBRATOS-$10
		bcs @vib0
		sta vibratoFirstRow
		lda #$00
		sta vibratoCursorY
		jmp @goVib
@vib0:		sec
		sbc #NUMBER_OF_VIBRATOS-$10
		sta vibratoCursorY
		lda #NUMBER_OF_VIBRATOS-$10
		sta vibratoFirstRow
@goVib:		lda #EDIT_MODE_VIBRATO_TABLE
		jmp changeEditorMode
		.ENDIF
@noVib:		cpy #INSTRUMENT_ROW_ECHO
		bne @noEcho
		lda (instrumentVector),y
		cmp #$FF
		beq @goEcho
		sta editorCurrentEcho
		sta echoCursorY
@goEcho:		lda #EDIT_MODE_ECHO_TABLE
		jmp changeEditorMode

@noEcho:		rts
		
;---------------------------------------------------------------
; Nav Drumkit
;---------------------------------------------------------------		
_navDrumkit:	rts

;---------------------------------------------------------------
; Nav Envelope
;---------------------------------------------------------------		
_navEnvelope:
		rts

;---------------------------------------------------------------
; Nav Table
;---------------------------------------------------------------		
_navTable:	.IF SRAM_MAP=32
		lda #SRAM_TABLE_BANK
		jsr setMMC1r1
		.ENDIF
		ldy tableCursorX
		lda tableVector
		sta tmp0
		lda tableVector+1
		sta tmp1
		cpy #TABLE_COLUMN_FX1
		bcc @notCommand
		cpy #TABLE_COLUMN_FX2
		bcs @fx2
		ldy #TABLE_COLUMN_FX1
		jmp _navCommand
@fx2:		ldy #TABLE_COLUMN_FX2
		jmp _navCommand
@notCommand:	rts

;---------------------------------------------------------------
; Nav Vibrato
;---------------------------------------------------------------		
_navVibrato:
		rts
;---------------------------------------------------------------
; Nav Duty
;---------------------------------------------------------------		
_navDuty:
		rts


;---------------------------------------------------------------
; Nav Echo
;---------------------------------------------------------------		
_navEcho:
		rts


;---------------------------------------------------------------
; Nav Speed
;---------------------------------------------------------------		
_navSpeed:
		rts

;---------------------------------------------------------------
; Nav FX
;---------------------------------------------------------------		
_navFx:
		rts

;---------------------------------------------------------------
; Nav Nav Menu
;---------------------------------------------------------------		
_navNavMenu:
		rts

;---------------------------------------------------------------
; Nav Setup
;---------------------------------------------------------------		
_navSetup:
		rts


;---------------------------------------------------------------
; Nav Command
;---------------------------------------------------------------		
;commands that need jump
;
; A B E F G W Y
_navCommand:	lda (tmp0),y		;command number
		cmp #COMMAND_A
		bne @notA
		iny
		lda (tmp0),y
		and #NUMBER_OF_TABLES-1
		sta editorCurrentTable
		lda #EDIT_MODE_PITCH_TABLE
		jmp changeEditorMode

@notA:		cmp #COMMAND_B
		bne @notB
		iny
		lda (tmp0),y
		and #NUMBER_OF_VIBRATOS-1
		sta editorCurrentVibrato
		sta vibratoCursorY
		lda #EDIT_MODE_VIBRATO_TABLE
		jmp changeEditorMode
				
@notB:		cmp #COMMAND_E
		bne @notE
		iny
		lda (tmp0),y
		and #NUMBER_OF_ENVELOPES-1
		cmp #NUMBER_OF_ENVELOPES-$10
		bcs @env0
		sta envelopeFirstRow
		lda #$00
		sta envelopeCursorY
		jmp @envMode
@env0:		sec
		sbc #NUMBER_OF_ENVELOPES-$10
		sta envelopeCursorY
		lda #NUMBER_OF_ENVELOPES-$10
		sta envelopeFirstRow
@envMode:		lda #EDIT_MODE_ENVELOPE_TABLE
		jmp changeEditorMode
		
				
@notE:		cmp #COMMAND_F
		bne @notF
		iny
		lda (tmp0),y
		and #NUMBER_OF_FX_TABLES-1
		sta editorCurrentFx
		lda #EDIT_MODE_FX_TABLE
		jmp changeEditorMode
		
@notF:		cmp #COMMAND_G
		bne @notG
		iny
		lda (tmp0),y
		and #NUMBER_OF_SPEED_TABLES-1
		sta editorCurrentSpeed
		lda #EDIT_MODE_SPEED_TABLE
		jmp changeEditorMode
		
@notG:		cmp #COMMAND_W
		bne @notW
		iny
		lda (tmp0),y
		and #NUMBER_OF_DUTY_TABLES-1
		sec
		sbc #$04
		bpl @jumpDuty
		rts
@jumpDuty:	sta editorCurrentDuty
		lda #EDIT_MODE_DUTY_TABLE
		jmp changeEditorMode

@notW:		cmp #COMMAND_Y
		bne @notY
		iny
		lda (tmp0),y
		and #NUMBER_OF_ECHOES-1
		sta editorCurrentEcho
		sta echoCursorY
		lda #EDIT_MODE_ECHO_TABLE
		jmp changeEditorMode

@notY:		
		rts
		
;---------------------------------------------------------------		
; Change Editor Mode
;---------------------------------------------------------------		
		
changeEditorMode:
		pha
		lda editorMode
		ldx editorModeIndex
		sta editorPreviousModes,x
		inx
		cpx #$10
		bcs @a
		stx editorModeIndex
@a:		pla
		sta editorMode
		lda #$02			;if editor mode change, make sure screen fully written
		sta writeScreen
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		rts
		
getPreviousMode:	
		ldx editorModeIndex
		beq @a
		dex
@a:		lda editorPreviousModes,x
		sta editorMode
		stx editorModeIndex
		lda #$02			;if editor mode change, make sure screen fully written
		sta writeScreen
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		rts		
;---------------------------------------------------------------		
; Handle Cursor Movement For Each Editor Mode
;---------------------------------------------------------------		
moveAroundEditor:
		;lda keysHoldB		;if A, B or SELECT held, don't move around
		lda keysHoldA
		ora PAD1_firea
		;ora PAD1_fireb
		beq @doMove
@out:		rts
		
@doMove:		ldx editorMode
		cpx #EDIT_MODE_NAV_MENU
		beq @nav
		lda PAD1_sel
		bne @out
@nav:		lda keysRepeatLR
		ora PAD1_dlr
		beq @a
		clc			;move LEFT/RIGHT
		adc songCursorX,x
		bmi @a			;limit to 0
		cmp editorModeColumns,x	;limit to number of columns in mode	
		bcs @a
		sta songCursorX,x		;update cursor X pos
	
@a:	
		lda keysRepeatUD
		ora PAD1_dud
		beq @b
		bmi @a1
	
		lda songCursorY,x		;move DOWN
		clc
		adc #$01
		cmp editorModeRows,x	;reached bottom?
		bcc @a2
		;lda editorModeScrolling,x	;yes, does this mode scroll?
		lda editorModeFirstRow,x
		beq @b			;no
		lda songFirstRow,x		;yes, have we reached bottom of scrolling window?
		cmp editorModeFirstRow,x
		beq @b			;yes, nothing to do
		inc songFirstRow,x		;no, move window down
		lda #$01			;and make sure window gets updated
		sta writeScreen
		bne @b
		;jmp @b
@a2:		sta songCursorY,x		;bottom not reached, update Y pos
		cpx #EDIT_MODE_DRUMKIT
		bne @b
		cmp #$0C
		bne @b
		inc songCursorY,x
		lda songCursorX,x
		sta drumkitCursorX_old
		lda #$05
		sta drumkitCursorX
		jmp @b
	
@a1:		lda songCursorY,x		;move UP
		bne @a3			;reached top?
		;lda editorModeScrolling,x	;yes, does this mode scroll?
		lda editorModeFirstRow,x
		beq @b			;no
		lda songFirstRow,x		;yes, are we at top?
		beq @b			;yes
		dec songFirstRow,x		;no, move window up
		lda #$01			;and make sure window gets updated
		sta writeScreen
		bne @b
		;jmp @b
@a3:		dec songCursorY,x		;not reached top, update Y pos
		cpx #EDIT_MODE_DRUMKIT
		bne @b
		lda songCursorY,x
		cmp #$0C
		bne @b
		dec songCursorY,x
		lda drumkitCursorX_old
		sta drumkitCursorX		
@b:
		rts

;---------------------------------------------------------------		
; Handle Cursor Movement For Each Editor Mode
;---------------------------------------------------------------		

CURSOR_BASE_COLOUR	= $06
CURSOR_BASE_COLOUR2 = $02
CURSOR_HOLD_COLOUR	= $2a
CURSOR_NAV_COLOUR	= $11

editorFlashCursor:
		lda #CURSOR_HOLD_COLOUR
		sta cursorFlashColour
		lda editBufferFlag
		bne @b
		lda editNavFlag
		bne @d
@c:		rts
	
@b:		ldx cursorFlashIndex
		lda cursorFlashColours,x
		sta cursorFlashColour
		inx
		cpx #cursorFlashColoursEnd-cursorFlashColours
		bcc @a
		ldx #$00
@a:		stx cursorFlashIndex
		rts
		
@d:		ldx cursorFlashIndex
		lda cursorFlashColours2,x
		sta cursorFlashColour
		inx
		cpx #cursorFlashColoursEnd2-cursorFlashColours2
		bcc @e
		ldx #$00
@e:		stx cursorFlashIndex		
		rts
		
cursorFlashColours:
		;.RES 1,$30
		.RES 5,$20+CURSOR_BASE_COLOUR
		.RES 3,$10+CURSOR_BASE_COLOUR
		.RES 1,$00+CURSOR_BASE_COLOUR
		.RES 2,$0F
		.RES 1,$00+CURSOR_BASE_COLOUR
		.RES 3,$10+CURSOR_BASE_COLOUR
		.RES 5,$20+CURSOR_BASE_COLOUR
		
cursorFlashColoursEnd:

cursorFlashColours2:
		;.RES 1,$30
		.RES 1,$20+CURSOR_BASE_COLOUR2
		.RES 1,$10+CURSOR_BASE_COLOUR2
		.RES 1,$00+CURSOR_BASE_COLOUR2
		.RES 2,$0F
		.RES 2,$00+CURSOR_BASE_COLOUR2
		.RES 4,$10+CURSOR_BASE_COLOUR2
		.RES 6,$20+CURSOR_BASE_COLOUR2
		
cursorFlashColoursEnd2:


printEditorNote:	
		
		cmp #$FF
		bne @a
		lda #CHR_EMPTY
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		rts
	
@a:
		pha
		sty tmp2
		ldy #$00
		cmp #NUMBER_OF_NOTES+1
		bcc @b
		lda writeScreen
		bmi @a0
		lda PAD1_firea
		bne @b
@a0:		ldy #$80
@b:		sty tmp3
		
		pla
		and #$7F
		tay
		lda editorNotes,y
		ora tmp3
		sta windowBuffer,x
		inx
		lda editorAccidentals,y
		ora tmp3
		sta windowBuffer,x
		inx
		lda editorCurrentTrack
		cmp #SONG_TRACK_C
		bne @notC
		
		lda editorOctaves,y
		sec
		sbc #$01
		ora tmp3
		sta windowBuffer,x
		ldy tmp2
		inx
		rts		

@notC:		lda editorOctaves,y
		ora tmp3
		sta windowBuffer,x
		ldy tmp2
		inx
		rts		

printEditorNote2:	
		cmp #$FF
		bne @a
		lda #CHR_EMPTY
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		sta windowBuffer,x
		inx
		rts
	
@a:		tay
		lda editorNotes,y
		ora #$80
		sta windowBuffer,x
		inx
		lda editorAccidentals,y
		ora #$80
		sta windowBuffer,x
		inx
		lda editorOctaves,y
		ora #$80
		sta windowBuffer,x
		rts		
				
editorNotes:
		.REPEAT 8
		.BYTE $0A,$0A,$0B,$0C,$0C,$0D,$0D,$0E,$0F,$0F,$10,$10
		.ENDREPEAT

editorAccidentals:
		.REPEAT 8
		.BYTE CHR_SPACE,CHR_SHARP,CHR_SPACE,CHR_SPACE,CHR_SHARP,CHR_SPACE
		.BYTE CHR_SHARP,CHR_SPACE,CHR_SPACE,CHR_SHARP,CHR_SPACE,CHR_SHARP
		.ENDREPEAT
		
editorOctaves:
		.BYTE 1,1,1
		.REPEAT 8,o
		.BYTE 2+o,2+o,2+o,2+o,2+o,2+o,2+o,2+o,2+o,2+o,2+o,2+o
		.ENDREPEAT
		
editorCommands:
		.BYTE $0A,$0B,$0C,$0D,$0E,$0F,$10,$11,$12,$13
		.BYTE $14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D
		.BYTE $1E,$1F,$20,$21,$22,$23
editorCommandsEnd:

processKeys:
		jsr checkKeysB
		jsr checkKeysA
		jsr checkKeysSel
		jsr checkRepeatKeyUD
		jsr checkRepeatKeyLR	
		rts

checkKeysA:	
checkHoldTapAndDoubleTap PAD1_firea,PAD1_firea_old,keysHoldA,keysHoldCounterA,keysTapA,keysDoubleTapA,keysTapCounterA
	
checkKeysB:
checkHoldTapAndDoubleTap PAD1_fireb,PAD1_fireb_old,keysHoldB,keysHoldCounterB,keysTapB,keysDoubleTapB,keysTapCounterB

checkKeysSel:
checkHoldTapAndDoubleTap PAD1_sel,PAD1_sel_old,keysHoldSel,keysHoldCounterSel,keysTapSel,keysDoubleTapSel,keysTapCounterSel

		
checkRepeatKeyUD:
@no_delay:		ldx #$00
		lda PAD1_ud
		bne @do_key
		sta keysRepeatUD
		sta keysRepeatOldUD
		lda #KEYS_REPEAT_DELAY
		sta keysRepeatRateUD
		rts
		
@do_key:		stx keysTapCounterA
		stx keysTapCounterB
		cmp keysRepeatOldUD
		beq @same_key
		sta keysRepeatOldUD
		rts
		
@same_key:		lda keysRepeatRateUD
		beq @do_repeat
		dec keysRepeatRateUD
		rts
		
@do_repeat:		sta keysRepeatUD
		inc keysRepeatCounterUD
		lda keysRepeatCounterUD
		and #KEYS_REPEAT_SPEED
		bne @a
		lda keysRepeatOldUD
		sta keysRepeatUD
@a:		rts	
		
checkRepeatKeyLR:
@no_delay:	lda PAD1_lr
		bne @do_key
		sta keysRepeatLR
		sta keysRepeatOldLR
		lda #KEYS_REPEAT_DELAY
		sta keysRepeatRateLR
		rts
		
@do_key:		stx keysTapCounterA
		stx keysTapCounterB
		cmp keysRepeatOldLR
		beq @same_key
		sta keysRepeatOldLR
		rts
		
@same_key:	lda keysRepeatRateLR
		beq @do_repeat
		dec keysRepeatRateLR
		rts
		
@do_repeat:	sta keysRepeatLR
		inc keysRepeatCounterLR
		lda keysRepeatCounterLR
		and #KEYS_REPEAT_SPEED
		bne @a
		lda keysRepeatOldLR
		sta keysRepeatLR
@a:		rts	

;
;0/1 = cursor left/right
;3/4 = scroll arrows up/down
;5/6/7/8/9 = playback arrows
;
editorInitSprites:
		lda #$FF
		sta SPR00_CHAR
		lda #$FF
		sta SPR01_CHAR

		lda #%00000000
		sta SPR00_ATTR
		sta SPR01_ATTR
		lda #%00000001	
		sta SPR03_ATTR
		sta SPR04_ATTR
	
		lda #21*8
		sta SPR03_Y
		sta SPR04_Y
		lda #25*8
		sta SPR03_X
		lda #26*8
		sta SPR04_X
		lda #$FF
		sta SPR03_CHAR
		sta SPR04_CHAR
				
		;Play markers
		lda #SPR_RIGHT_ARROW
		sta SPR05_CHAR
		sta SPR06_CHAR
		sta SPR07_CHAR
		sta SPR08_CHAR
		sta SPR09_CHAR
		
		lda #%0000001
		sta SPR05_ATTR
		sta SPR06_ATTR
		sta SPR07_ATTR
		sta SPR08_ATTR
		sta SPR09_ATTR
		
		jsr initVuMeters
		jsr initBPMDisplay
		rts


		.include "vuMeters.asm"
		.include "bpmDisplay.asm"



;---------------------------------------------------------------
; TABLES FOR SCREEN/BUFFER COORDINATES
;---------------------------------------------------------------

editorModeColumns:
		.BYTE songModeColumns
		.BYTE chainModeColumns
		.BYTE patternModeColumns
		.BYTE instrumentModeColumns
		.BYTE drumkitModeColumns
		.BYTE envelopeModeColumns
		.BYTE tableModeColumns
		.BYTE vibratoModeColumns
		.BYTE dutyModeColumns
		.BYTE echoModeColumns
		.BYTE speedModeColumns
		.BYTE fxModeColumns
		.BYTE setupModeColumns
		.BYTE navModeColumns

editorModeRows:
		.BYTE songModeRows
		.BYTE chainModeRows
		.BYTE patternModeRows
		.BYTE instrumentModeRows
		.BYTE drumkitModeRows
		.BYTE envelopeModeRows
		.BYTE tableModeRows
		.BYTE vibratoModeRows
		.BYTE dutyModeRows
		.BYTE echoModeRows
		.BYTE speedModeRows
		.BYTE fxModeRows
		.BYTE setupModeRows
		.BYTE navModeRows
	
editorModeFirstRow:
		.BYTE STEPS_PER_TRACK-$10
		.BYTE STEPS_PER_CHAIN-$10
		.BYTE STEPS_PER_PATTERN-$10
		.BYTE 0
		.BYTE 0
		.BYTE NUMBER_OF_ENVELOPES-$10
		.BYTE STEPS_PER_TABLE-$10
		.BYTE NUMBER_OF_VIBRATOS-$10
		.BYTE STEPS_PER_DUTY_TABLE-$10
		.BYTE NUMBER_OF_ECHOES-$10
		.BYTE 0
		.BYTE STEPS_PER_FX_TABLE-$10
		.BYTE 0
		.BYTE 0
	
	
;---------------------------------------------------------------
; CURSOR TYPE OFFSETS
;---------------------------------------------------------------

cursorTypeOffsetX0:
		.BYTE 0
		.BYTE $FE,$FE,$FE,$FE

cursorTypeOffsetX1:
		.BYTE 0
		.BYTE 2,10,18,26


;---------------------------------------------------------------
; NAMETABLES FOR EACH MODE
;---------------------------------------------------------------
	
headerChain:
	.incbin "nametables/header_chain.bin"
headerDrumkit:
	.incbin "nametables/header_drumkit.bin"
headerEnvelope:
	.incbin "nametables/header_envelope.bin"
headerPattern:
	.incbin "nametables/header_pattern.bin"
headerSong:
	.incbin "nametables/header_song.bin"	
headerTable:
	.incbin "nametables/header_table.bin"
headerInstrument:
	.incbin "nametables/header_instrument.bin"
headerVibrato:
	.incbin "nametables/header_vibrato.bin"
headerDuty:
	.incbin "nametables/header_duty.bin"
headerEcho:
	.incbin "nametables/header_echo.bin"
headerSpeed:
	.incbin "nametables/header_speed.bin"
headerNavMenu:
	.incbin "nametables/header_navmenu.bin"
headerSetup:
	.incbin "nametables/header_setup.bin"
headerFx:
	.incbin "nametables/header_fx.bin"

	
titleChain:
	.incbin "nametables/title_chain.bin"
titleDrumkit:
	.incbin "nametables/title_drumkit.bin"
titleEnvelope:
	.incbin "nametables/title_envelope.bin"
titlePattern:
	.incbin "nametables/title_pattern.bin"
titleSong:
	.incbin "nametables/title_song.bin"	
titleTable:
	.incbin "nametables/title_table.bin"
titleInstrument:
	.incbin "nametables/title_instrument.bin"
titleVibrato:
	.incbin "nametables/title_vibrato.bin"
titleDuty:
	.incbin "nametables/title_duty.bin"
titleEcho:
	.incbin "nametables/title_echo.bin"
titleSpeed:
	.incbin "nametables/title_speed.bin"
titleNavMenu:
	.incbin "nametables/title_navmenu.bin"
titleSetup:
	.incbin "nametables/title_setup.bin"
titleFx:
	.incbin "nametables/title_fx.bin"

windowChain:
	;.incbin "nametables/window_chain.bin"
windowDrumkit:
	.incbin "nametables/window_drumkit.bin"
windowEnvelope:
	;.incbin "nametables/window_envelope.bin"
windowPattern:
	;.incbin "nametables/window_pattern.bin"
windowSong:
	;.incbin "nametables/window_song.bin"	
windowTable:
	;.incbin "nametables/window_table.bin"
windowInstrument:
	.incbin "nametables/window_instrument.bin"
windowVibrato:
	;.incbin "nametables/window_vibrato.bin"
windowDuty:
	;.incbin "nametables/window_duty.bin"
windowEcho:
	;.incbin "nametables/window_echo.bin"
windowSpeed:
	;.incbin "nametables/window_speed.bin"
windowNavMenu:
	.incbin "nametables/window_navmenu.bin"
windowSetup:
	.incbin "nametables/window_setup.bin"


initEditorData:
		jsr clearSongs
		jsr clearChains
		jsr clearPatterns
		jsr clearInstruments
		jsr clearDrumkits
		jsr clearEnvelopeTable
		jsr clearTables
		jsr clearVibratoTable
		jsr clearDutyTables
		jsr clearEchoTable
		jsr clearSpeedTables
		jsr clearFxTables
		jsr initPalette
		lda #$01
		sta writePaletteFlag
		rts
		

initEditorVars:	
		lda #$00
		sta songCursorX
		sta songCursorY
		sta chainCursorX
		sta chainCursorY
		sta patternCursorX
		sta patternCursorY
		sta instrumentCursorX
		sta instrumentCursorY
		sta drumkitCursorX
		sta drumkitCursorY
		sta drumkitCursorX_old
		sta envelopeCursorX
		sta envelopeCursorY
		sta tableCursorX
		sta tableCursorY
		sta vibratoCursorX
		sta vibratoCursorY
		sta dutyCursorX
		sta dutyCursorY
		sta echoCursorX
		sta echoCursorY
		sta speedCursorX
		sta speedCursorY
		sta fxCursorX
		sta fxCursorY
		sta navMenuCursorX
		sta navMenuCursorY
		;sta setupCursorX
		;sta setupCursorY
		
		sta editorCurrentChain
		sta editorCurrentPattern
		sta editorCurrentInstrument
		sta editorCurrentDrumkit
		sta editorCurrentEnvelope
		sta editorCurrentTable
		sta editorCurrentVibrato
		sta editorCurrentDuty
		sta editorCurrentEcho
		sta editorCurrentSpeed
		sta editorCurrentFx
		
		sta songFirstRow
		sta chainFirstRow
		sta patternFirstRow
		sta instrumentFirstRow
		sta drumkitFirstRow
		sta envelopeFirstRow
		sta tableFirstRow
		sta vibratoFirstRow
		sta dutyFirstRow
		sta echoFirstRow
		sta speedFirstRow
		sta fxFirstRow

		ldy #$00
@clearLast:	sta editorLastValues,y
		iny
		cpy #<(editorLastValuesEnd-editorLastValues)
		bne @clearLast
	
		ldx #$00
@clearInstruments:	lda _blankInstrument,x
		sta plyrInstrumentCopyA,x
		sta plyrInstrumentCopyB,x
		sta plyrInstrumentCopyC,x
		sta plyrInstrumentCopyD,x
		inx
		cpx #STEPS_PER_INSTRUMENT
		bcc @clearInstruments

		ldx #$00
@clearDrumkit:	lda _blankDrumKit,x
		sta plyrInstrumentCopyE,x
		inx
		cpx #(STEPS_PER_DRUMKIT * BYTES_PER_DRUMKIT_STEP)
		bcc @clearDrumkit
		rts

_blankInstrument:
		.BYTE $00		;env
		.BYTE $0F		;level
		.BYTE $00		;gate	
		.BYTE $00		;duty
		.BYTE $FF		;table
		.BYTE $00		;psweep
		.BYTE $80		;psweepq
		.BYTE $00		;sweep
		.BYTE $FF		;vib
		.BYTE $00		;detune
		.BYTE $00		;hard frq
		.BYTE $FF		;echo

_blankDrumKit:
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		.BYTE $00,$0F,$00,$00,$00
		
clearSongs:	.IF SRAM_MAP=32
		lda #SRAM_SONG_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx songFirstRow
@b:		lda editTrackAddressLo,x
		sta tmp0
		lda editTrackAddressHi,x
		sta tmp1
		ldy #$00
		lda #$FF
@a:		sta (tmp0),y
		iny
		cpy #STEPS_PER_TRACK
		bcc @a
		inx
		cpx #NUMBER_OF_SONGS * 5
		bcc @b

		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF		
		ldx #$00
@c:		lda #$00
		sta SRAM_SONG_MUTE,x
		lda #$FF
		sta SRAM_SONG_SOLO,x
		lda #$00
		sta SRAM_SONG_SPEEDS,x
		inx
		cpx #NUMBER_OF_SONGS
		bcc @c
		rts
		
clearChains:		
		.IF SRAM_MAP=32
		lda #SRAM_CHAIN_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx chainFirstRow
@a:		lda editChainAddressLo,x
		sta tmp0
		lda editChainAddressHi,x
		sta tmp1
		ldy #$00
@b:		lda #$FF
		sta (tmp0),y
		iny
		lda #$00
		sta (tmp0),y
		iny
		cpy #(STEPS_PER_CHAIN * BYTES_PER_CHAIN_STEP)
		bcc @b
		inx
		cpx #NUMBER_OF_CHAINS
		bcc @a
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		stx SRAM_HEADER_FREE_CHAINS
		ldx #$00
		lda #$00
@c:		sta SRAM_CHAIN_FLAGS,x
		inx
		cpx #NUMBER_OF_CHAINS
		bcc @c
		rts
		
clearPatterns:		
		.IF SRAM_MAP=32
		lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx patternFirstRow
@a:		lda editPatternAddressLo,x
		sta tmp0
		lda editPatternAddressHi,x
		sta tmp1
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
		inx
		cpx #NUMBER_OF_PATTERNS
		bcc @a
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		stx SRAM_HEADER_FREE_PATTERNS
		lda #$00
		ldx #$00
@c:		sta SRAM_PATTERN_FLAGS,x
		inx
		cpx #NUMBER_OF_PATTERNS
		bcc @c
		rts
		
clearInstruments:		
		.IF SRAM_MAP=32
		lda #SRAM_INSTRUMENT_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx instrumentFirstRow
@a:		lda editInstrumentAddressLo,x
		sta tmp0
		lda editInstrumentAddressHi,x
		sta tmp1
		ldy #$00
		tya
@b:		sta (tmp0),y		;note
		iny
		cpy #(STEPS_PER_INSTRUMENT * BYTES_PER_INSTRUMENT_STEP)
		bcc @b
		ldy #INSTRUMENT_ROW_LEVEL	;set level to 0F
		lda #$0F
		sta (tmp0),y
		lda #$FF
		ldy #INSTRUMENT_ROW_TABLE
		sta (tmp0),y
		ldy #INSTRUMENT_ROW_VIBRATO
		sta (tmp0),y
		ldy #INSTRUMENT_ROW_ECHO
		sta (tmp0),y
		ldy #INSTRUMENT_ROW_PSWEEPQ
		lda #$80
		sta (tmp0),y
		inx
		cpx #NUMBER_OF_INSTRUMENTS
		bcc @a
		rts

clearDrumkits:
		.IF SRAM_MAP=32
		lda #SRAM_DRUMKIT_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx drumkitFirstRow
@a:		lda #$00
		sta SRAM_DRUMKIT_ROOTS,x
		lda editDrumkitAddressLo,x
		sta tmp0
		lda editDrumkitAddressHi,x
		sta tmp1
		ldy #$00
@b:		lda #$00
		sta (tmp0),y		;sample
		iny
		lda #$0F
		sta (tmp0),y		;pitch
		iny
		lda #$00
		sta (tmp0),y		;start offset
		iny
		sta (tmp0),y		;end offset
		iny
		sta (tmp0),y		;loop
		iny
		cpy #(STEPS_PER_DRUMKIT * BYTES_PER_DRUMKIT_STEP)
		bcc @b
		inx
		cpx #NUMBER_OF_DRUMKITS
		bcc @a
		rts
		
clearEnvelopeTable:
		.IF SRAM_MAP=32
		lda #SRAM_ENVELOPE_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx envelopeFirstRow
@a:		lda #$00
		sta SRAM_ENVELOPES,x
		inx
		sta SRAM_ENVELOPES,x
		inx
		lda #$0F
		sta SRAM_ENVELOPES,x
		inx
		lda #$00
		sta SRAM_ENVELOPES,x
		inx
		cpx #(NUMBER_OF_ENVELOPES * BYTES_PER_ENVELOPE)
		bcc @a
		
		rts
		
clearTables:	
		.IF SRAM_MAP=32
		lda #SRAM_TABLE_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx tableFirstRow
@a:		lda editTableAddressLo,x
		sta tmp0
		lda editTableAddressHi,x
		sta tmp1
		ldy #$00
@b:		lda #$0F
		sta (tmp0),y		;volume
		iny
		lda #$00
		sta (tmp0),y		;pitch
		iny
		lda #$FF
		sta (tmp0),y		;command
		iny
		lda #$00			;command data
		sta (tmp0),y
		iny
		lda #$FF
		sta (tmp0),y		;command
		iny
		lda #$00			;command data
		sta (tmp0),y
		iny
		cpy #(STEPS_PER_TABLE * BYTES_PER_TABLE_STEP)
		bcc @b
		inx
		cpx #NUMBER_OF_TABLES
		bcc @a
		rts
				
clearVibratoTable:
		.IF SRAM_MAP=32
		lda #SRAM_VIBRATO_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx vibratoFirstRow
@a:		lda #$00
		sta SRAM_VIBRATOS,x
		inx
		cpx #(NUMBER_OF_VIBRATOS* BYTES_PER_VIBRATO)
		bcc @a
		rts
				
clearDutyTables:
		.IF SRAM_MAP=32
		lda #SRAM_DUTY_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx dutyFirstRow
@a:		lda editDutyAddressLo,x
		sta tmp0
		lda editDutyAddressHi,x
		sta tmp1
		ldy #$00
@b:		lda #$00
		sta (tmp0),y
		iny
		sta (tmp0),y
		iny
		lda #$FF
		sta (tmp0),y
		iny
		cpy #(STEPS_PER_DUTY_TABLE * BYTES_PER_DUTY_TABLE_STEP)
		bcc @b
		inx
		cpx #NUMBER_OF_DUTY_TABLES
		bcc @a
		rts
clearEchoTable:
		.IF SRAM_MAP=32
		lda #SRAM_ECHO_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx echoFirstRow
@a:		lda #$00
		sta SRAM_ECHOES,x
		inx
		cpx #(NUMBER_OF_ECHOES* BYTES_PER_ECHO)
		bcc @a
		rts
		
clearSpeedTables:		
		.IF SRAM_MAP=32
		lda #SRAM_SPEED_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx speedFirstRow
@a:		lda editSpeedAddressLo,x
		sta tmp0
		lda editSpeedAddressHi,x
		sta tmp1
		ldy #$00
		lda #$06
		sta (tmp0),y
		iny
		lda #$FF
@b:		sta (tmp0),y
		iny
		cpy #(STEPS_PER_SPEED_TABLE * BYTES_PER_SPEED_TABLE_STEP)
		bcc @b
		inx
		cpx #NUMBER_OF_SPEED_TABLES
		bcc @a
		rts
		
clearFxTables:		
		.IF SRAM_MAP=32
		lda #SRAM_FX_BANK
		jsr setMMC1r1
		.ENDIF
		ldx #$00
		stx fxFirstRow
@a:		lda editFxAddressLo,x
		sta tmp0
		lda editFxAddressHi,x
		sta tmp1
		ldy #$00
@b:		lda #$Ff
		sta (tmp0),y
		iny
		lda #$0F
		sta (tmp0),y
		iny
		lda #$80
		sta (tmp0),y
		iny
		lda #$Ff
		sta (tmp0),y
		iny
		lda #$0F
		sta (tmp0),y
		iny
		lda #$80
		sta (tmp0),y
		iny
		lda #$FF
		sta (tmp0),y
		iny
		lda #$FF
		sta (tmp0),y
		iny
		lda #$0F
		sta (tmp0),y
		iny
		cpy #(STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP)
		bcc @b
		inx
		cpx #NUMBER_OF_FX_TABLES
		bcc @a
		rts
				
		
		
			