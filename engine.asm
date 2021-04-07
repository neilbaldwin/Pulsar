	.include "engineMacros.asm"
	.include "adsr.asm"


.export pulsarRefresh, initPulsar

initPhase		= 5	;set "envelopePhase" to this value to start it
attackPhase	= 4
decayPhase	= 3
sustainPhase	= 2
releasePhase	= 1
offPhase		= 0	;envelope stops at this stage
	
VOICE_A	= 0
VOICE_B	= 1
VOICE_C	= 2
VOICE_D	= 3
VOICE_E	= 4

initPulsar:
	jsr pulsarInitAPU
	

	
	rts
	
	
pulsarRefresh:
	jsr pulsarRefreshVoiceA
	jsr pulsarRefreshVoiceB
	jsr pulsarRefreshVoiceC
	jsr pulsarRefreshVoiceD
	jsr pulsarRefreshVoiceE
	
	.IF SRAM_MAP=32
	.IF ENABLE_ECHO=1
	jsr pulsarEchoEffectA
	jsr pulsarEchoEffectB
	jsr pulsarEchoEffectD
	.ENDIF
	.ENDIF
	
	jsr pulsarRunFxTable

	jsr pulsarWriteApuA
	jsr pulsarWriteApuB
	jsr pulsarWriteApuC
	jsr pulsarWriteApuD
	jsr pulsarWriteApuE
	
	
@x:	inc pulsarPassCounter
	
	rts


pulsarRunFxTable:
	.IF SRAM_MAP=32
	lda #SRAM_HEADER_BANK
	jsr setMMC1r1
	.ENDIF
	ldy editorCurrentSong
	lda SRAM_SONG_MUTE,y
	sta engineTmp0
	lda SRAM_SONG_SOLO,y
	sta engineTmp1
	.IF SRAM_MAP=32
	lda #SRAM_FX_BANK
	jsr setMMC1r1
	.ENDIF
	ldx plyrFxTable
	cpx #$FF
	bne @go
@x1:	rts

@go:	
	ldy plyrFxTableIndex
	cpy #$10
	bcc @a
	lda #$FF
	sta plyrFxTable
	sta plyrFxTableVoice
	bmi @x1
	
@a:	lda fxRowsIndex,y
	tay
	lda editFxAddressLo,x
	sta plyrFxVector
	lda editFxAddressHi,x
	sta plyrFxVector+1
	
	lda engineTmp0		;*SRAM*
	and #$01
	bne @noNoteA
	lda engineTmp1		;*SRAM*
	bmi @soloA
	cmp #$00
	bne @noNoteA
@soloA:	lda (plyrFxVector),y	;*SRAM* note A
	bmi @noNoteA
	jsr pulsarFxTableGetNote
	sta V_APU+$02
	stx V_APU+$03
	iny
	lda (plyrFxVector),y	;*SRAM* volume A
	iny
	ora (plyrFxVector),y	;*SRAM* duty A
	ora #$30
	sta V_APU+$00
	jmp @doB
@noNoteA:	iny
	iny
@doB:	iny
	lda engineTmp0	;*SRAM*
	and #$02
	bne @noNoteB
	lda engineTmp1	;*SRAM*
	bmi @soloB
	cmp #$01
	bne @noNoteB
@soloB:	lda (plyrFxVector),y	;*SRAM* note B
	bmi @noNoteB
	jsr pulsarFxTableGetNote
	sta V_APU+$06
	stx V_APU+$07
	iny
	lda (plyrFxVector),y	;*SRAM* volume B
	iny
	ora (plyrFxVector),y	;*SRAM* duty B
	ora #$30
	sta V_APU+$04
	jmp @doC
@noNoteB:	iny
	iny
@doC:	iny
	lda engineTmp0	;*SRAM*
	and #$04
	bne @noNoteC
	lda engineTmp1	;*SRAM*
	bmi @soloC
	cmp #$02
	bne @noNoteC
@soloC:	lda (plyrFxVector),y	;*SRAM* note c
	bmi @noNoteC
	jsr pulsarFxTableGetNote
	sta V_APU+$0A
	stx V_APU+$0B
	lda #$81
	sta V_APU+$08
@noNoteC:	iny
	lda engineTmp0	;*SRAM*
	and #$08
	bne @noNoteD
	lda engineTmp1	;*SRAM*
	bmi @soloD
	cmp #$03
	bne @noNoteD
@soloD:	lda (plyrFxVector),y	;*SRAM* note D
	bmi @noNoteD
	cmp #$10
	bcc @notToneNoise
	and #$0F
	ora #$80
@notToneNoise:
	sta V_APU+$0E
	iny
	lda (plyrFxVector),y	;*SRAM* amp D
	ora #$30
	sta V_APU+$0C
@noNoteD:
		
	lda plyrFxTableCounter
	clc
	adc plyrFxTableSpeed
	sta plyrFxTableCounter
	bcc @x
	inc plyrFxTableIndex
	
@x:	rts

pulsarFxTableGetNote:
	tax
	lda fxNoteTableLo,x
	pha
	lda fxNoteTableHi,x
	tax
	pla
	rts
	

fxNoteTableLo:
	.byte $f1,$7f,$13,$ad,$4d,$f3,$9d,$4c,$00,$b8,$74,$34
  	.byte $f8,$bf,$89,$56,$26,$f9,$ce,$a6,$80,$5c,$3a,$1a
  	.byte $fb,$df,$c4,$ab,$93,$7c,$67,$52,$3f,$2d,$1c,$0c
  	.byte $fd,$ef,$e1,$d5,$c9,$bd,$b3,$a9,$9f,$96,$8e,$86
  	.byte $7e,$77,$70,$6a,$64,$5e,$59,$54,$4f,$4b,$46,$42
  	.byte $3f,$3b,$38,$34,$31,$2f,$2c,$29,$27,$25,$23,$21
  	.byte $1f,$1d,$1b,$1a,$18,$17,$15,$14
  	.byte $13,$12,$11,$10,$0f,$0e,$0d

fxNoteTableHi:
  	.byte $07,$07,$07,$06,$06,$05,$05,$05,$05,$04,$04,$04
  	.byte $03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02
  	.byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  	.byte $00,$00,$00,$00,$00,$00,$00,$00
  	.byte $00,$00,$00,$00,$00,$00,$00
	

pulsarRefreshVoiceA:
	lda pulsarIntensity+$00
	ldx pulsarPassCounter
	and pulsarPassCounterMasks,x
	bne @yesRefresh
	rts
@yesRefresh:
	refreshVoice VOICE_A
	rts

pulsarRefreshVoiceB:
	lda pulsarIntensity+$01
	ldx pulsarPassCounter
	and pulsarPassCounterMasks,x
	bne @yesRefresh
	rts
@yesRefresh:
	refreshVoice VOICE_B
	rts

pulsarRefreshVoiceC:
	lda pulsarIntensity+$02
	ldx pulsarPassCounter
	and pulsarPassCounterMasks,x
	bne @yesRefresh
	rts
@yesRefresh:
	refreshVoice VOICE_C
	rts

pulsarRefreshVoiceD:
	lda pulsarIntensity+$03
	ldx pulsarPassCounter
	and pulsarPassCounterMasks,x
	bne @yesRefresh
	rts
@yesRefresh:
	refreshVoice VOICE_D
	rts

pulsarRefreshVoiceE:
	lda pulsarIntensity+$04
	ldx pulsarPassCounter
	and pulsarPassCounterMasks,x
	bne @yesRefresh
	rts
@yesRefresh:
	refreshVoice VOICE_E
	rts
	
	.IF SRAM_MAP=32
	.IF ENABLE_ECHO=1
pulsarEchoEffectA:
	echoEffect VOICE_A
pulsarEchoEffectB:
	echoEffect VOICE_B
pulsarEchoEffectD:
	echoEffect VOICE_D
	
pulsarUpdateEchoA:
	plyrUpdateEchoIndex VOICE_A
pulsarUpdateEchoB:
	plyrUpdateEchoIndex VOICE_B
pulsarUpdateEchoD:
	plyrUpdateEchoIndex VOICE_D
	.ENDIF
	.ENDIF

pulsarPassCounterMasks:
	.BYTE %00000001,%00000010,%00000100,%00001000

pulsarWriteApuA:
	jmp @jump
@echoNormal:
	lda V_APU+3
	lsr a
	lsr a
	lsr a
	lsr a
	ldx pulsarPassCounter
	and pulsarPassCounterMasks,x
	bne @hard
	jmp @normal

@hard:	lda V_APU+3
	and #$07
	sta APU_03
	sta pitchHiOld
	lda V_APU+2
	sta APU_02
	sta pitchLoOld
	rts

@jump:	lda V_APU+0
	sta APU_00
	lda V_APU+1
	sta APU_01
	lda plyrInstrumentCopy+(0*STEPS_PER_INSTRUMENT)+INSTRUMENT_ROW_HARDFREQ
	beq @notHard
	ldx pulsarPassCounter
	and pulsarPassCounterMasks,x
	bne @hard
@notHard:	
	lda plyrInstrumentCopy + (0 * STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_TABLE
	bpl @normal
	lda plyrCurrentNote
	bmi @normal
	lda plyrNoteCounter
	beq @normal
	lda plyrFxTable
	bpl @normal
	.IF SRAM_MAP=32
	.IF ENABLE_ECHO=1
	lda plyrEchoSpeed
	beq @noEcho
	lda envelopePhase
	cmp #ENVELOPE_SUSTAIN_PHASE
	bcs @noEcho
	jmp @echoNormal
	.ENDIF
	.ENDIF
@noEcho:	lda V_APU+3
	and #$07
	sec
	sbc pitchHiOld
	beq @noHi
	bmi @down
	cmp #$02
	bcs @normal
	lda V_APU+3
	and #$07
	sta pitchHiOld
	lda #$40
	sta APU_17
	lda #$FF
	sta APU_02
	lda #$87
	sta APU_01
	lda #$C0
	sta APU_17
	lda #$0F
	sta APU_01
	jmp @noHi
	
@down:	cmp #$FD
	bcc @normal
	lda V_APU+3
	and #$07
	sta pitchHiOld
	lda #$40
	sta APU_17
	lda #$00
	sta APU_02
	lda #$8F
	sta APU_01
	lda #$C0
	sta APU_17
	lda #$0F
	sta APU_01
	jmp @noHi


@normal:	lda V_APU+3
	and #$07
	cmp pitchHiOld
	beq @noHi
	sta pitchHiOld
	sta APU_03
@noHi:	lda V_APU+2
	cmp pitchLoOld
	beq @noLo
	sta pitchLoOld
	sta APU_02
@noLo:	rts



	.IF 1=1
pulsarWriteApuB:
	jmp @jump
@echoNormal:
	lda V_APU+7
	lsr a
	lsr a
	lsr a
	lsr a
	ldx pulsarPassCounter
	and pulsarPassCounterMasks,x
	bne @hard
	jmp @normal
	
@hard:	lda V_APU+7
	and #$07
	sta APU_07
	sta pitchHiOld+1
	lda V_APU+6
	sta APU_06
	sta pitchLoOld+1
	rts

@jump:	lda V_APU+4
	sta APU_04
	lda V_APU+5
	sta APU_05
	lda plyrInstrumentCopy + (1*STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_HARDFREQ
	beq @notHard
	ldx pulsarPassCounter
	and pulsarPassCounterMasks,x
	bne @hard
@notHard:	
	lda plyrInstrumentCopy + (1 * STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_TABLE
	bpl @normal	
	lda plyrCurrentNote+1
	bmi @normal
	lda plyrNoteCounter+1
	beq @normal
	lda plyrFxTable
	bpl @normal
	.IF SRAM_MAP=32
	.IF ENABLE_ECHO=1
	lda plyrEchoSpeed+1
	beq @noEcho
	lda envelopePhase+1
	cmp #ENVELOPE_SUSTAIN_PHASE
	bcs @noEcho
	jmp @echoNormal
	.ENDIF
	.ENDIF
@noEcho:	lda V_APU+7
	and #$07
	sec
	sbc pitchHiOld+1
	beq @noHi
	bmi @down
	cmp #$02
	bcs @normal
	lda V_APU+7
	and #$07
	sta pitchHiOld+1
	lda #$40
	sta APU_17
	lda #$FF
	sta APU_06
	lda #$87
	sta APU_05
	lda #$C0
	sta APU_17
	lda #$0F
	sta APU_05
	jmp @noHi
	
@down:	cmp #$FD
	bcc @normal
	lda V_APU+7
	and #$07
	sta pitchHiOld+1
	lda #$40
	sta APU_17
	lda #$00
	sta APU_06
	lda #$8F
	sta APU_05
	lda #$C0
	sta APU_17
	lda #$0F
	sta APU_05
	jmp @noHi
	
	
@normal:	lda V_APU+7
	and #$07
	cmp pitchHiOld+1
	beq @noHi
	sta pitchHiOld+1
	sta APU_07
@noHi:	lda V_APU+6
	cmp pitchLoOld+1
	beq @noLo
	sta pitchLoOld+1
	sta APU_06
@noLo:	rts
	.ENDIF
	
pulsarWriteApuC:
	lda V_APU+8
	sta APU_08
	lda V_APU+9
	sta APU_09
	lda plyrNoteCounter+$02
	beq @down
	lda plyrFxTable
	bpl @down
	lda V_APU+$0B
	sec
	sbc old_V_APUB
	beq @a
	bmi @down
	lda V_APU+$0B
	sta $400B
	sta old_V_APUB
@a:	lda V_APU+$0A
	sta $400a
	rts
	
@down:	lda V_APU+$0A
	sta $400a
	lda V_APU+$0B
	sta $400b
	sta old_V_APUB
	rts

pulsarWriteApuD:
	lda V_APU+$0C
	sta APU_0C
	lda V_APU+$0D
	sta APU_0D
	lda V_APU+$0E
	sta APU_0E
	lda V_APU+$0F
	sta APU_0F
	rts
	
pulsarWriteApuE:
	lda plyrDpcmMuted
	beq @a
	
	lda #$0F
	sta APU_15
	rts
@a:
	lda plyrDpcmOn
	beq @x
	
	lda dpcmPitch
	sta APU_10
	lda dpcmDC
	sta APU_11
	lda dpcmStart
	sta APU_12
	lda dpcmLength
	sta APU_13
	
	lda APU_15
	and #$0F
	ora plyrDpcmOn
	sta APU_15
	
	lda #$00
	sta plyrDpcmOn
	
@x:	
	rts
	
pulsarInitAPU:
	lda #$00
	sta APU_15
	
	ldx #$00
	lda #$00
@a:	sta APU,x
	sta V_APU,x
	inx
	cpx #$10
	bcc @a
	
	sta plyrSlideSpeed
	sta plyrSlideSpeed+1
	sta plyrSlideSpeed+2
	
	sta plyrCurrentSpeedTable
	sta plyrSpeedTableIndex

	sta plyrCurrentChainTranspose
	sta plyrCurrentChainTranspose+1
	sta plyrCurrentChainTranspose+2
	sta plyrCurrentChainTranspose+3
	sta plyrCurrentChainTranspose+4

	sta plyrCurrentDuty
	sta plyrCurrentDuty+1
	sta plyrDutyTableDelay
	sta plyrDutyTableDelay+1

	sta plyrDutyIndex
	sta plyrDutyIndex+1
	
	sta plyrTableIndex
	sta plyrTableIndex+1
	sta plyrTableIndex+2
	sta plyrTableIndex+3

	sta plyrTablePitch
	sta plyrTablePitch+1
	sta plyrTablePitch+2
	sta plyrTablePitch+3
	
	sta plyrCurrentInstrument
	sta plyrCurrentInstrument+1
	sta plyrCurrentInstrument+2
	sta plyrCurrentInstrument+3
	sta plyrCurrentInstrument+4
	
	sta plyrDelayNoteCounter
	sta plyrDelayNoteCounter+1
	sta plyrDelayNoteCounter+2
	sta plyrDelayNoteCounter+3
	sta plyrDelayNoteCounter+4
	
	sta plyrKeyOn
	sta plyrKeyOn+$01
	sta plyrKeyOn+$02
	sta plyrKeyOn+$03
	sta plyrKeyOn+$04
	
	sta plyrDpcmOn
	
	sta noteNumber
	sta noteNumber+1
	sta noteNumber+2
	sta noteNumber+3
	
	sta noteAddNote
	sta noteAddNote+1
	sta noteAddNote+2
	
	sta noteAddFrac
	sta noteAddFrac+1
	sta noteAddFrac+2
	
	sta envelopeAmp
	sta envelopeAmp+1
	sta envelopeAmp+2
	sta envelopeAmp+3
	
	sta envelopePhase
	sta envelopePhase+1
	sta envelopePhase+2
	sta envelopePhase+3
	
	sta plyrChordNotes
	sta plyrChordNotes+1
	sta plyrChordNotes+2
	sta plyrChordNotes+3
	
	sta plyrDetuneHi
	sta plyrDetuneHi+1
	sta plyrDetuneHi+2
	
	lda #$0F
	sta plyrTableVolume
	sta plyrTableVolume+1
	sta plyrTableVolume+2
	sta plyrTableVolume+3
	
	sta pulsarIntensity
	sta pulsarIntensity+1
	sta pulsarIntensity+2
	sta pulsarIntensity+3
	sta pulsarIntensity+4
	
	lda #$FF
	sta pitchHiOld
	sta pitchHiOld+1
	
	sta plyrDelayNote
	sta plyrDelayNote+1
	sta plyrDelayNote+2
	sta plyrDelayNote+3
	sta plyrDelayNote+4
	
	sta plyrNoteCounter
	sta plyrNoteCounter+1
	sta plyrNoteCounter+2
	sta plyrNoteCounter+3
	sta plyrNoteCounter+4
	
	sta plyrKillCounter
	sta plyrKillCounter+1
	sta plyrKillCounter+2
	sta plyrKillCounter+3
	sta plyrKillCounter+4
	
	sta plyrRetriggerSpeed
	sta plyrRetriggerSpeed+1
	sta plyrRetriggerSpeed+2
	sta plyrRetriggerSpeed+3
	sta plyrRetriggerSpeed+4

	sta plyrRetriggerCounter
	sta plyrRetriggerCounter+1
	sta plyrRetriggerCounter+2
	sta plyrRetriggerCounter+3
	sta plyrRetriggerCounter+4
	
	sta plyrTableJump
	sta plyrTableJump+1
	sta plyrTableJump+2
	sta plyrTableJump+3
	sta plyrTableJump+4
	
	sta plyrPatternJump
	sta plyrPatternJump+1
	sta plyrPatternJump+2
	sta plyrPatternJump+3
	sta plyrPatternJump+4
	
	sta plyrFxTable
	
	lda #$00
	sta dpcmPitch
	sta dpcmStart
	sta dpcmLength
	lda #$40
	sta dpcmDC
	
	lda #$08
	sta APU_01
	sta V_APU+$01
	sta APU_05
	sta V_APU+$05
	
	lda #%00001111
	sta APU_15
	
	ldx #$04
	ldy #$00
@clearIns:
	lda #$00
	sta plyrInstrumentCopy,y	;envelope
	iny
	lda #$0F
	sta plyrInstrumentCopy,y	;level
	iny
	lda #$00
	sta plyrInstrumentCopy,y	;gate
	iny
	sta plyrInstrumentCopy,y	;duty
	iny
	lda #$FF
	sta plyrInstrumentCopy,y	;table
	iny
	lda #$00
	sta plyrInstrumentCopy,y	;sweep
	iny
	lda #$80
	sta plyrInstrumentCopy,y	;sweep q
	iny
	lda #$FF
	sta plyrInstrumentCopy,y	;vib
	iny
	lda #$00
	sta plyrInstrumentCopy,y	;detune
	iny
	sta plyrInstrumentCopy,y	;hard frq
	iny
	lda #$FF
	sta plyrInstrumentCopy,y	;echo
	iny
	;lda #$00
	;sta plyrInstrumentCopy,y	;aux
	;iny
	dex
	bne @clearIns


	.IF SRAM_MAP=32
	.IF ENABLE_ECHO=1
	lda #$00
	sta plyrEchoSpeed
	sta plyrEchoSpeed+1
	sta plyrEchoSpeed+2
	sta plyrEchoSpeed+3
	lda #$00
	sta plyrEchoIndex
	sta plyrEchoIndex+1
	sta plyrEchoIndex+2
	sta plyrEchoIndex+3
	lda #$00
	sta plyrEchoCounter
	sta plyrEchoCounter+1
	sta plyrEchoCounter+2
	sta plyrEchoCounter+3

	lda #SRAM_ECHO_BANK
	jsr setMMC1r1

	ldx #$00
	lda #$FF
@b:	sta plyrEchoBuffer03_A,x
	sta plyrEchoBuffer02_A,x
	sta plyrEchoBuffer00_A,x
	sta plyrEchoBuffer03_B,x
	sta plyrEchoBuffer02_B,x
	sta plyrEchoBuffer00_B,x
	sta plyrEchoBuffer02_D,x
	sta plyrEchoBuffer00_D,x
	inx
	cpx #SIZE_OF_ECHO_BUFFER
	bcc @b
	.ENDIF
	.ENDIF
	
		
	rts
	
	
	
envelopePhaseIndexes:
	.BYTE 0,3,2,1,0,0
	
DUTY_TABLE:
	.BYTE $00,$40,$80,$C0


LOCK_UP:	ldx #$00
@a:	stx $2007
	inx
	jmp @a

;-------------------------------------------------------------------------------
; FX Handling Code
;-------------------------------------------------------------------------------

;
;IN : A = command data, Y = command number, X = voice
;
plyrDoCommand:	
@a:	sta engineTmp0

	cpx #$02
	bcs @b
	lda commandFlagAB,y
	bne @ok
	rts
	
@b:	cpx #$03
	bcs @c
	lda commandFlagC,y
	bne @ok
	rts
	
@c:	bne @d
	lda commandFlagD,y
	bne @ok
	rts
	
@d:	lda commandFlagE,y
	beq @x

@ok:	lda commandAddressHi,y
	pha
	lda commandAddressLo,y
	pha
	lda engineTmp0
@x:	rts
	
commandAddressHi:
	.HIBYTES commandA-1,commandB-1,commandC-1,commandD-1,commandE-1
	.HIBYTES commandF-1,commandG-1,commandH-1,commandI-1,commandJ-1
	.HIBYTES commandK-1,commandL-1,commandM-1,commandN-1,commandO-1
	.HIBYTES commandP-1,commandQ-1,commandR-1,commandS-1,commandT-1
	.HIBYTES commandU-1,commandV-1,commandW-1,commandX-1,commandY-1
	.HIBYTES commandZ-1
	
commandAddressLo:
	.LOBYTES commandA-1,commandB-1,commandC-1,commandD-1,commandE-1
	.LOBYTES commandF-1,commandG-1,commandH-1,commandI-1,commandJ-1
	.LOBYTES commandK-1,commandL-1,commandM-1,commandN-1,commandO-1
	.LOBYTES commandP-1,commandQ-1,commandR-1,commandS-1,commandT-1
	.LOBYTES commandU-1,commandV-1,commandW-1,commandX-1,commandY-1
	.LOBYTES commandZ-1

;
;Run Table
;
commandA:
	cpx #$04
	bcc @notE
	and #NUMBER_OF_TABLES-1
	sta plyrTableTrackE
	lda #$00
	sta plyrTableIndex,x
	sta plyrTableCounter,x
	rts
	
@notE:	
	and #NUMBER_OF_TABLES-1
	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_TABLE
	pla
	sta (engineTmp0),y
	lda #$00
	sta plyrTableIndex,x
	sta plyrTableCounter,x
	rts
;
;Vibrato or, for DPCM, set loop on/off
;
commandB:
	cpx #$04
	bcc @notE
	pha
	.IF SRAM_MAP=32
	lda #SRAM_DRUMKIT_BANK
	jsr setMMC1r1
	.ENDIF
	ldy plyrCurrentInstrument=$04
	lda SRAM_DRUMKIT_ROOTS,y			;*SRAM*
	sta engineTmp0
	lda plyrCurrentNote,x
	cmp engineTmp0
	bcc @noDrum
	sbc engineTmp0
	cmp #$0C
	bcs @noDrum
	tay
	lda drumkitRowsIndex,y
	tay
	iny
	iny
	iny
	iny
	pla
	and #$01
	sta plyrInstrumentCopyE,y
	rts

@noDrum:	pla
	rts
	
@notE:	cpx #$03
	bcs @x
	cmp #$FF
	beq @a
	cmp #NUMBER_OF_VIBRATOS
	bcs @x
@a:	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_VIBRATO
	pla
	sta (engineTmp0),y
@x:	rts


;
;Pattern Chord
;
commandC:
	sta plyrChordNotes,x
	lda #$00
	sta plyrPatternChordIndex,x
	sta plyrPatternChordCounter,x
	rts

;
;Delay Note Start
commandD:
	clc
	adc #$01
	sta plyrDelayNoteCounter,x
	lda plyrCurrentNote,x
	sta plyrDelayNote,x
	rts

;
; Set envelope or for DPCM, set end offset for current note
;	
commandE:	cpx #$04
	bcc @notE
	pha
	ldy plyrCurrentInstrument+$04
	.IF SRAM_MAP=32
	lda #SRAM_DRUMKIT_BANK
	jsr setMMC1r1
	.ENDIF
	lda SRAM_DRUMKIT_ROOTS,y		;*SRAM*
	sta engineTmp0
	lda plyrCurrentNote,x
	cmp engineTmp0
	bcc @noDrum
	sbc engineTmp0
	cmp #$0C
	bcs @noDrum
	tay
	lda drumkitRowsIndex,y
	tay
	iny
	iny
	iny
	pla
	sta plyrInstrumentCopyE,y
	rts
	
@noDrum:	pla
	rts

@notE:	and #NUMBER_OF_ENVELOPES-1
	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_ENVELOPE
	pla
	sta (engineTmp0),y	
	rts

;
;Start an FX Table
;	
commandF:
	stx plyrFxTableVoice
	pha
	and #NUMBER_OF_FX_TABLES-1
	sta plyrFxTable
	pla
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda fxTableSpeeds,x
	sta plyrFxTableSpeed
	lda #$00
	sta plyrFxTableCounter
	sta plyrFxTableIndex
	rts

fxTableSpeeds:
	.BYTE $08,$10,$18,$20,$28,$30,$38
	.BYTE $40,$48,$50,$58,$60,$68,$70
;
;Speed Table Select
;	
commandG:	
	and #NUMBER_OF_SPEED_TABLES-1
	sta plyrCurrentSpeedTable
	lda #$00
	sta plyrSpeedTableIndex
@x:	rts
	
;
;Pattern Hop
;
commandH:
	pha
	lda plyrFxType
	bne @tableJump
	pla
	sta plyrPatternJump,x
	rts
@tableJump:
	pla
	.IF 0=1
	cmp #$FF
	bne @b
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_TABLE
	lda #$FF
	sta (engineTmp0),y
	rts	
	
@b:	jsr randomRangeNumber
	sta plyrTableJump,x
	.ENDIF
	rts

;
;Set Pulsar Intesity for voice (all voices?)
;
commandI:
	sta tmp0
	and #$0F
	sta pulsarIntensity,x
	lda tmp0
	cmp #$10
	bcc @a
	lda pulsarIntensity,x
	sta pulsarIntensity
	sta pulsarIntensity+1
	sta pulsarIntensity+2
	sta pulsarIntensity+3
	sta pulsarIntensity+4	
@a:	rts


;
;J = table random jump
;
commandJ:	pha
	lda plyrFxType
	bne @tableJump
	pla
	sta plyrPatternJump,x
	rts
@tableJump:
	pla
	cmp #$FF
	bne @b
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_TABLE
	lda #$FF
	sta (engineTmp0),y
	rts	
	
@b:
	jsr randomRangeNumber
	sta plyrTableJump,x
	rts

randomRangeNumber:
	stx tmp2
	pha
	lsr a
	lsr a
	lsr a
	lsr a
	sta tmp0	;lower
	pla
	and #$0F
	sec
	sbc tmp0
	sta tmp1
	jsr randomNumber
	ldx tmp1
	and rndRangeTable,x
@a:	cmp tmp1
	beq @b
	bcc @b
	sbc tmp1
	jmp @a

@b:	clc
	adc tmp0	
	ldx tmp2
	rts
	
rndRangeTable:
	.BYTE $00,$01,$03,$03,$07,$07,$07,$07,$0F,$0F,$0F,$0F,$0F

commandK:
	sta plyrKillCounter,x
	rts

;
;Slide to note or for DPCM, set Loop on/off (00/01)
;
commandL:
	cpx #$04
	bcc @notE
	pha
	.IF SRAM_MAP=32
	lda #SRAM_DRUMKIT_BANK
	jsr setMMC1r1
	.ENDIF
	ldy plyrCurrentInstrument+$04
	lda SRAM_DRUMKIT_ROOTS,y		;*SRAM*
	sta engineTmp0
	lda plyrCurrentNote,x
	cmp engineTmp0
	bcc @noDrum
	sbc engineTmp0
	cmp #$0C
	bcs @noDrum
	tay
	lda drumkitRowsIndex,y
	tay
	iny
	iny
	iny
	iny
	pla
	and #$01
	sta plyrInstrumentCopyE,y
	rts
	
@noDrum:	pla
	rts

@notE:	and #$7F
	pha
	lda plyrFxType
	bne @table
	pla
	sta plyrSlideSpeed,x
	rts

@table:	lda plyrCurrentNote,x
	and #$7F
	clc
	adc plyrCurrentChainTranspose,x
	clc
	adc plyrTablePitch,x
	sta plyrSlideDestination,x
	pla
	sta plyrSlideSpeed,x
	lda plyrSlideDestination,x
	cmp noteNumber,x
	bne @notSameNote
	lda #$00
	sta plyrSlideSpeed,x
	beq @posSlide
		
@notSameNote:	
	bcs @posSlide
	lda plyrSlideSpeed,x
	eor #$FF
	clc
	adc #$01
	sta plyrSlideSpeed,x
@posSlide:
	lda #$00
	sta plyrTablePitch,x
	rts
;
;Set Gate Time
;
commandM:
	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_GATE
	pla
	sta (engineTmp0),y
	rts

;
;Set Hard Freq
;
commandN:
	and #$0F
	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_HARDFREQ
	pla
	sta (engineTmp0),y
	rts
;
;Set output level or for DPCM, set end offset
;
commandO:
	cpx #$04
	bcc @notE
	pha
	.IF SRAM_MAP=32
	lda #SRAM_DRUMKIT_BANK
	jsr setMMC1r1
	.ENDIF
	ldy plyrCurrentInstrument=$04
	lda SRAM_DRUMKIT_ROOTS,y		;*SRAM*
	sta engineTmp0
	lda plyrCurrentNote,x
	cmp engineTmp0
	bcc @noDrum
	sbc engineTmp0
	cmp #$0C
	bcs @noDrum
	tay
	lda drumkitRowsIndex,y
	tay
	iny
	iny
	iny
	pla
	sta plyrInstrumentCopyE,y
	rts
	
@noDrum:	pla
	rts
		
@notE:	and #$0F
	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_LEVEL
	pla
	sta (engineTmp0),y
	rts

;
;Set sweep or for DPCM, set pitch
;
commandP:
	cpx #$04
	bcc @notE
	pha
	.IF SRAM_MAP=32
	lda #SRAM_DRUMKIT_BANK
	jsr setMMC1r1
	.ENDIF
	ldy plyrCurrentInstrument+$04
	lda SRAM_DRUMKIT_ROOTS,y			;*SRAM*
	sta engineTmp0
	lda plyrCurrentNote,x
	cmp engineTmp0
	bcc @noDrum
	sbc engineTmp0
	cmp #$0C
	bcs @noDrum
	tay
	lda drumkitRowsIndex,y
	tay
	iny
	pla
	and #$0F
	sta plyrInstrumentCopyE,y
	rts
	
@noDrum:	pla
	rts
		
@notE:	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_PSWEEP
	pla
	sta (engineTmp0),y
	rts

;
;Set pitch sweep/slide resolution
;
commandQ:
	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_PSWEEPQ
	pla
	sta (engineTmp0),y
	rts

commandR:
	sta plyrRetriggerSpeed,x
	rts
	
;
;DPCM, set start offset
;
commandS:	cpx #$04
	bcc @notE
	pha
	.IF SRAM_MAP=32
	lda #SRAM_DRUMKIT_BANK
	jsr setMMC1r1
	.ENDIF
	ldy plyrCurrentInstrument+$04
	lda SRAM_DRUMKIT_ROOTS,y			;*SRAM*
	sta engineTmp0
	lda plyrCurrentNote,x
	cmp engineTmp0
	bcc @noDrum
	sbc engineTmp0
	cmp #$0C
	bcs @noDrum
	tay
	lda drumkitRowsIndex,y
	tay
	iny
	iny
	pla
	sta plyrInstrumentCopyE,y
	rts
	
@noDrum:	pla
	rts

@notE:	cpx #$03
	beq @x
	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_SWEEP
	pla
	sta (engineTmp0),y
@x:	rts
	
;
;Set Detune or for DPCM, set pitch
;
commandT:	
	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_DETUNE
	pla
	sta (engineTmp0),y
	rts

;
;Probability command, no further processing needed as value checked immediately in sequence playback
;	
commandU:
	rts

;
;Will be used for volume command
;
commandV:
	rts

;
;Set Duty
;
commandMaxW = $03+NUMBER_OF_DUTY_TABLES
commandW:
	cmp #commandMaxW+1
	bcs @x
	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_DUTY
	pla
	sta (engineTmp0),y
@x:	rts

commandX:
	rts
commandY:
	.IF SRAM_MAP=32
	.IF ENABLE_ECHO=1
	and #NUMBER_OF_ECHOES-1
	pha
	lda commandInstrumentAddressLo,x
	sta engineTmp0
	lda commandInstrumentAddressHi,x
	sta engineTmp1
	ldy #INSTRUMENT_ROW_ECHO
	pla
	sta (engineTmp0),y	
	bpl @a
	lda #$00
	sta plyrEchoSpeed,x
	rts
	
@a:	tay
	lda echoRowsIndex,y
	tay
	lda #SRAM_ECHO_BANK
	jsr setMMC1r1
	lda SRAM_ECHOES,y
	sta plyrEchoSpeed,x
	lda SRAM_ECHOES+1,y
	sta plyrEchoInitAttn,x
	lda SRAM_ECHOES+2,y
	sta plyrEchoAttn,x
	.ENDIF
	.ENDIF
	rts

;
;Z = set table playback speed
;
commandZ:
	sta plyrTableSpeed,x
	lda #$00
	sta plyrTableCounter,x
	rts
	

commandInstrumentAddressLo:
	.BYTE <plyrInstrumentCopyA
	.BYTE <plyrInstrumentCopyB
	.BYTE <plyrInstrumentCopyC
	.BYTE <plyrInstrumentCopyD
	.BYTE <plyrInstrumentCopyE

commandInstrumentAddressHi:
	.BYTE >plyrInstrumentCopyA
	.BYTE >plyrInstrumentCopyB
	.BYTE >plyrInstrumentCopyC
	.BYTE >plyrInstrumentCopyD
	.BYTE >plyrInstrumentCopyE


commandFlagAB:
	.BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1
commandFlagC:
	.BYTE 1,1,1,1,0,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,0,0,1,0,1
commandFlagD:
	.BYTE 1,0,1,1,1,1,1,1,1,1,1,0,1,0,1,0,0,1,0,0,1,0,0,1,1,1
commandFlagE:
	.BYTE 1,1,0,1,1,1,1,1,1,1,1,1,0,0,1,1,0,1,1,1,1,0,0,0,0,1
	
;-------------------------------------------------------------------------------
; Random number
;-------------------------------------------------------------------------------
randomNumber: 
	lda lfsr 
	lsr a 
	bcs :+ 
	eor #$A6 
:	sta lfsr 
    	rts	

	
sineTable:
.BYTE $00,$03,$06,$09,$0c,$0f,$11,$14,$16,$18,$1a,$1c,$1d,$1e,$1f,$1f
.BYTE $1f,$1f,$1f,$1e,$1d,$1c,$1a,$18,$16,$14,$11,$0f,$0c,$09,$06,$03
.BYTE $00,$03,$06,$09,$0c,$0f,$11,$14,$16,$18,$1a,$1c,$1d,$1e,$1f,$1f
.BYTE $1f,$1f,$1f,$1e,$1d,$1c,$1a,$18,$16,$14,$11,$0f,$0c,$09,$06,$03

triTable:
.BYTE $00,$02,$04,$06,$08,$0A,$0C,$0E,$10,$12,$14,$16,$18,$1A,$1C,$1E
.BYTE $1E,$1C,$1A,$18,$16,$14,$12,$10,$0E,$0C,$0A,$08,$06,$04,$02,$00
.BYTE $00,$02,$04,$06,$08,$0A,$0C,$0E,$10,$12,$14,$16,$18,$1A,$1C,$1E
.BYTE $1E,$1C,$1A,$18,$16,$14,$12,$10,$0E,$0C,$0A,$08,$06,$04,$02,$00

divideLo:
	.LOBYTES sineTable
	.LOBYTES divideBy1
	.LOBYTES divideBy2
	.LOBYTES divideBy3
	.LOBYTES divideBy4
	.LOBYTES divideBy5
	.LOBYTES divideBy6
	.LOBYTES divideBy7
	.LOBYTES divideBy8
	.LOBYTES divideBy9
	.LOBYTES divideBy10
	.LOBYTES divideBy11
	.LOBYTES divideBy12
	.LOBYTES divideBy13
	.LOBYTES divideBy14
	.LOBYTES divideBy15

divideHi:
	.HIBYTES sineTable
	.HIBYTES divideBy1
	.HIBYTES divideBy2
	.HIBYTES divideBy3
	.HIBYTES divideBy4
	.HIBYTES divideBy5
	.HIBYTES divideBy6
	.HIBYTES divideBy7
	.HIBYTES divideBy8
	.HIBYTES divideBy9
	.HIBYTES divideBy10
	.HIBYTES divideBy11
	.HIBYTES divideBy12
	.HIBYTES divideBy13
	.HIBYTES divideBy14
	.HIBYTES divideBy15

divideBy1:
.BYTE $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f
.BYTE $10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$1a,$1b,$1c,$1d,$1e,$1f

divideBy2:
.BYTE $00,$00,$01,$02,$02,$03,$04,$04,$05,$06,$06,$07,$08,$08,$09,$0a
.BYTE $0a,$0b,$0c,$0c,$0d,$0e,$0e,$0f,$10,$10,$11,$12,$12,$13,$14,$14

divideBy3:
.BYTE $00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$07
.BYTE $08,$08,$09,$09,$0a,$0a,$0b,$0b,$0c,$0c,$0d,$0d,$0e,$0e,$0f,$0f

divideBy4:
.BYTE $00,$00,$00,$01,$01,$02,$02,$02,$03,$03,$04,$04,$04,$05,$05,$06
.BYTE $06,$06,$07,$07,$08,$08,$08,$09,$09,$0a,$0a,$0a,$0b,$0b,$0c,$0c

divideBy5:
.BYTE $00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$04,$05
.BYTE $05,$05,$06,$06,$06,$07,$07,$07,$08,$08,$08,$09,$09,$09,$0a,$0a

divideBy6:
.BYTE $00,$00,$00,$00,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$04,$04
.BYTE $04,$04,$05,$05,$05,$06,$06,$06,$06,$07,$07,$07,$08,$08,$08,$08

divideBy7:
.BYTE $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03
.BYTE $04,$04,$04,$04,$05,$05,$05,$05,$06,$06,$06,$06,$07,$07,$07,$07

divideBy8:
.BYTE $00,$00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03,$03
.BYTE $03,$03,$04,$04,$04,$04,$04,$05,$05,$05,$05,$06,$06,$06,$06,$06

divideBy9:
.BYTE $00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03
.BYTE $03,$03,$03,$03,$04,$04,$04,$04,$04,$05,$05,$05,$05,$05,$06,$06

divideBy10:
.BYTE $00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02
.BYTE $02,$03,$03,$03,$03,$03,$04,$04,$04,$04,$04,$04,$05,$05,$05,$05

divideBy11:
.BYTE $00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02
.BYTE $02,$02,$03,$03,$03,$03,$03,$03,$04,$04,$04,$04,$04,$04,$05,$05

divideBy12:
.BYTE $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$02,$02,$02
.BYTE $02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$04,$04,$04,$04,$04,$04

divideBy13:
.BYTE $00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$02,$02
.BYTE $02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$04,$04,$04,$04

divideBy14:
.BYTE $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$02
.BYTE $02,$02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$04,$04

divideBy15:
.BYTE $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01
.BYTE $02,$02,$02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03


;
;One octave (lowest) of 12 semi-tones, sub-divided into 16 steps
;Used 16 steps instead of 32 so tables can be indexed with 8bit index
;
	.IF PAL_VERSION=0
Tone2PeriodLo:
  .byte $f1,$ea,$e2,$db,$d4,$cc,$c5,$be,$b7,$b0,$a9,$a2,$9b,$94,$8d,$86
  .byte $7f,$78,$71,$6a,$63,$5c,$56,$4f,$48,$41,$3b,$34,$2d,$27,$20,$19
  .byte $13,$0c,$06,$ff,$f9,$f3,$ec,$e6,$df,$d9,$d3,$cc,$c6,$c0,$ba,$b3
  .byte $ad,$a7,$a1,$9b,$95,$8f,$89,$83,$7d,$77,$71,$6b,$65,$5f,$59,$53
  .byte $4d,$47,$42,$3c,$36,$30,$2b,$25,$1f,$1a,$14,$0e,$09,$03,$fe,$f8
  .byte $f3,$ed,$e8,$e2,$dd,$d7,$d2,$cd,$c7,$c2,$bd,$b7,$b2,$ad,$a8,$a2
  .byte $9d,$98,$93,$8e,$89,$83,$7e,$79,$74,$6f,$6a,$65,$60,$5b,$56,$51
  .byte $4c,$48,$43,$3e,$39,$34,$2f,$2b,$26,$21,$1c,$18,$13,$0e,$0a,$05
  .byte $01,$fc,$f7,$f2,$ee,$e9,$e5,$e0,$dc,$d7,$d3,$ce,$ca,$c5,$c1,$bd
  .byte $b8,$b4,$b0,$ab,$a7,$a3,$9e,$9a,$96,$92,$8d,$89,$85,$81,$7d,$79
  .byte $74,$70,$6c,$68,$64,$60,$5c,$58,$54,$50,$4c,$48,$44,$40,$3c,$38
  .byte $34,$31,$2d,$29,$25,$21,$1d,$19,$16,$12,$0e,$0a,$07,$03,$ff,$fc
Tone2PeriodHi:
  .byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  .byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  .byte $07,$07,$07,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
  .byte $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
  .byte $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$05,$05
  .byte $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
  .byte $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
  .byte $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
  .byte $05,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$03,$03
	.ELSE
Tone2PeriodLo:
  .byte $60,$5a,$53,$4c,$45,$3f,$38,$31,$2b,$24,$1d,$17,$10,$0a,$03,$fd
  .byte $f6,$f0,$e9,$e3,$dd,$d6,$d0,$ca,$c4,$bd,$b7,$b1,$ab,$a5,$9e,$98
  .byte $92,$8c,$86,$80,$7a,$74,$6e,$68,$62,$5c,$57,$51,$4b,$45,$3f,$39
  .byte $34,$2e,$28,$23,$1d,$17,$12,$0c,$06,$01,$fb,$f6,$f0,$eb,$e5,$e0
  .byte $db,$d5,$d0,$ca,$c5,$c0,$ba,$b5,$b0,$ab,$a5,$a0,$9b,$96,$91,$8c
  .byte $86,$81,$7c,$77,$72,$6d,$68,$63,$5e,$59,$54,$4f,$4a,$46,$41,$3c
  .byte $37,$32,$2d,$29,$24,$1f,$1a,$16,$11,$0c,$08,$03,$fe,$fa,$f5,$f1
  .byte $ec,$e7,$e3,$de,$da,$d5,$d1,$cd,$c8,$c4,$bf,$bb,$b7,$b2,$ae,$aa
  .byte $a5,$a1,$9d,$98,$94,$90,$8c,$88,$83,$7f,$7b,$77,$73,$6f,$6b,$66
  .byte $62,$5e,$5a,$56,$52,$4e,$4a,$46,$42,$3e,$3b,$37,$33,$2f,$2b,$27
  .byte $23,$20,$1c,$18,$14,$10,$0d,$09,$05,$01,$fe,$fa,$f6,$f3,$ef,$eb
  .byte $e8,$e4,$e1,$dd,$d9,$d6,$d2,$cf,$cb,$c8,$c4,$c1,$bd,$ba,$b7,$b3
Tone2PeriodHi:
  .byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$06
  .byte $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
  .byte $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
  .byte $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$05,$05,$05,$05,$05,$05
  .byte $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
  .byte $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
  .byte $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$03,$03,$03,$03,$03,$03
  .byte $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
	.ENDIF
note2Table:
  .byte $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0
  .byte $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0
  .byte $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0
  .byte $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0
  .byte $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0
  .byte $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0
  .byte $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0
  .byte $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0
  .byte $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$A0,$B0


octaveShiftTable:
  .byte 00,00,00,00,00,00,00,00,00,00,00,00		;1
  .byte 01,01,01,01,01,01,01,01,01,01,01,01		;2
  .byte 02,02,02,02,02,02,02,02,02,02,02,02		;3
  .byte 03,03,03,03,03,03,03,03,03,03,03,03		;4
  .byte 04,04,04,04,04,04,04,04,04,04,04,04		;5
  .byte 05,05,05,05,05,05,05,05,05,05,05,05		;6
  .byte 06,06,06,06,06,06,06,06,06,06,06,06		;7
  .byte 07,07,07,07,07,07,07,07,07,07,07,07		;8
  .byte 08,08,08,08,08,08,08,08,08,08,08,08		;9

;---------------------------------------------------------------
; Volume Table
;---------------------------------------------------------------
VOLUME_TABLE_LO:
	.REPEAT 16,i
	.BYTE <(VOLUME_TABLE + i*$10)
	.ENDREPEAT
	
VOLUME_TABLE_HI:
	.REPEAT 16,i
	.BYTE >(VOLUME_TABLE + i*10)
	.ENDREPEAT

	.ALIGN 256
VOLUME_TABLE:		
	.EXPORT VOLUME_TABLE
.BYTE $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00      ; MasterVol = 0
.BYTE $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01      ; 1
.BYTE $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$02      ; 2
.BYTE $00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03      ; 3
.BYTE $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$04      ; ..
.BYTE $00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04,$04,$05
.BYTE $00,$00,$00,$01,$01,$02,$02,$02,$03,$03,$04,$04,$04,$05,$05,$06
.BYTE $00,$00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07
.BYTE $00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$08
.BYTE $00,$00,$01,$01,$02,$03,$03,$04,$04,$05,$06,$06,$07,$07,$08,$09
.BYTE $00,$00,$01,$02,$02,$03,$04,$04,$05,$06,$06,$07,$08,$08,$09,$0A
.BYTE $00,$00,$01,$02,$02,$03,$04,$05,$05,$06,$07,$08,$08,$09,$0A,$0B
.BYTE $00,$00,$01,$02,$03,$04,$04,$05,$06,$07,$08,$08,$09,$0A,$0B,$0C
.BYTE $00,$00,$01,$02,$03,$04,$05,$06,$06,$07,$08,$09,$0A,$0B,$0C,$0D
.BYTE $00,$00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E
.BYTE $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F
