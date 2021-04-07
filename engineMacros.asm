
;-------------------------------------------------------------------------------
; Echo
;-------------------------------------------------------------------------------
		.MACRO echoEffect _track
		.local _voice
		.IF (_track=0)
		_voice = 0
		.ELSEIF (_track=1)
		_voice = 1
		.ELSE
		_voice = 2
		.ENDIF
		
		lda #SRAM_ECHO_BANK
		jsr setMMC1r1
		;lda plyrEchoSpeed+_track
		;cmp #$FF
		;bne @doEcho
		lda plyrInstrumentCopy + (_track * STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_ECHO
		cmp #$FF
		bne @doEcho
		rts
		
@doEcho:		and #NUMBER_OF_ECHOES-1
		tay
		lda echoRowsIndex,y
		tay
		lda SRAM_ECHOES,y
		sta plyrEchoSpeed+_track
		lda SRAM_ECHOES+1,y
		sta plyrEchoInitAttn+_track
		lda SRAM_ECHOES+2,y
		sta plyrEchoAttn+_track	
			
		ldy plyrEchoIndex+_track
		lda envelopePhase+_track
		;cmp #ENVELOPE_RELEASE_PHASE
		cmp #ENVELOPE_OFF_PHASE
		;bcs @writeToBuffer
		bne @writeToBuffer
		.IF (_voice=0)
		lda plyrEchoBuffer03_A,y
		cmp #$FF
		bne @readFromBuffer
		.ELSEIF (_voice=1)
		lda plyrEchoBuffer03_B,y
		cmp #$FF
		bne @readFromBuffer
		.ELSE
		lda plyrEchoBuffer02_D,y
		cmp #$FF
		bne @readFromBuffer
		.ENDIF
		.IF (_voice=0)
		lda V_APU+$00
		and #%11110000
		sta V_APU+$00
		.ELSEIF (_voice=1)
		lda V_APU+$04
		and #%11110000
		sta V_APU+$04
		.ELSE
		lda V_APU+$0C
		and #%11110000
		;and #%00000000
		sta V_APU+$0C
		.ENDIF
		jmp @writeToBuffer
		
@readFromBuffer:	
		.IF (_voice=0)
		sta V_APU+$03
		lda plyrEchoBuffer02_A,y
		sta V_APU+$02
		lda plyrEchoBuffer00_A,y
		sta V_APU+$00
		and #%11110000
		sta tmp0
		lda plyrEchoBuffer00_A,y
		and #%00001111
		sec
		sbc plyrEchoAttn+_track
		bpl @a
		lda #$00
@a:		ora tmp0
		sta plyrEchoBuffer00_A,y
		jmp @exit
		
@writeToBuffer:
		lda plyrInstrumentCopy+(0*STEPS_PER_INSTRUMENT)+INSTRUMENT_ROW_HARDFREQ
		asl a
		asl a
		asl a
		asl a
		ora V_APU+$03		;hi freq
		sta plyrEchoBuffer03_A,y
		lda V_APU+$02		;lo freq
		sta plyrEchoBuffer02_A,y
		lda V_APU+$00		;duty & amp
		and #%11110000
		sta tmp0
		lda V_APU+$00
		and #%00001111
		sty tmp1
		tay
		lda VOLUME_TABLE_LO,y
		sta engineTmp0
		lda VOLUME_TABLE_HI,y
		sta engineTmp1
		ldy plyrEchoInitAttn+_track
		lda (engineTmp0),y
@b:		ora tmp0
		ldy tmp1
		sta plyrEchoBuffer00_A,y
		
		.ELSEIF (_voice=1)
		
		sta V_APU+$07
		lda plyrEchoBuffer02_B,y
		sta V_APU+$06
		lda plyrEchoBuffer00_B,y
		sta V_APU+$04
		and #%11110000
		sta tmp0
		lda plyrEchoBuffer00_B,y
		and #%00001111
		sec
		sbc plyrEchoAttn+_track
		bpl @a
		lda #$00
@a:		ora tmp0
		sta plyrEchoBuffer00_B,y
		jmp @exit
@writeToBuffer:	
		lda plyrInstrumentCopy+(1*STEPS_PER_INSTRUMENT)+INSTRUMENT_ROW_HARDFREQ
		asl a
		asl a
		asl a
		asl a
		ora V_APU+$07		;hi freq
		sta plyrEchoBuffer03_B,y
		lda V_APU+$06		;lo freq
		sta plyrEchoBuffer02_B,y
		lda V_APU+$04		;duty & amp
		and #%11110000
		sta tmp0
		lda V_APU+$04
		and #%00001111
		sty tmp1
		tay
		lda VOLUME_TABLE_LO,y
		sta engineTmp0
		lda VOLUME_TABLE_HI,y
		sta engineTmp1
		ldy plyrEchoInitAttn+_track
		lda (engineTmp0),y
@b:		ora tmp0
		ldy tmp1
		sta plyrEchoBuffer00_B,y
		
		.ELSE
		
		sta V_APU+$0F
		lda plyrEchoBuffer02_D,y
		sta V_APU+$0E
		lda plyrEchoBuffer00_D,y
		sta V_APU+$0C
		and #%11110000
		sta tmp0
		lda plyrEchoBuffer00_D,y
		and #%00001111
		sec
		sbc plyrEchoAttn+_track
		bpl @a
		lda #$00
@a:		ora tmp0
		sta plyrEchoBuffer00_D,y
		jmp @exit
@writeToBuffer:	lda V_APU+$0E		;lo freq
		sta plyrEchoBuffer02_D,y
		lda V_APU+$0C		;duty & amp
		and #%11110000
		sta tmp0
		lda V_APU+$0C
		and #%00001111
		sty tmp1
		tay
		lda VOLUME_TABLE_LO,y
		sta engineTmp0
		lda VOLUME_TABLE_HI,y
		sta engineTmp1
		ldy plyrEchoInitAttn+_track
		lda (engineTmp0),y
@b:		ora tmp0
		ldy tmp1
		sta plyrEchoBuffer00_D,y
		.ENDIF		
						
@exit:		inc plyrEchoIndex+_track
		lda plyrEchoIndex+_track
		cmp #SIZE_OF_ECHO_BUFFER		;ECHO_MAX_DELAY
		bcc @exit0
		lda #$00
		sta plyrEchoIndex+_track
@exit0:		rts
		.ENDMACRO


		.MACRO plyrUpdateEchoIndex _track
		.local _voice
		.IF (_track=0)
		_voice = 0
		.ELSEIF (_track=1)
		_voice = 1
		.ELSE
		_voice = 2
		.ENDIF
		lda plyrEchoCounter+_track
		beq @a
		dec plyrEchoCounter+_track
		rts
@a:		lda #$00
		sta plyrEchoIndex+_track
		lda plyrEchoSpeed+_track
		sta plyrEchoCounter+_track
@x:		rts
		.ENDMACRO
		

;-------------------------------------------------------------------------------
; Pitch Slide
;-------------------------------------------------------------------------------
	.MACRO doPitchSlide _track
	
	lda plyrSlideSpeed+_track
	beq @slideX
	bpl @slidePos
	
	lda noteNumber+_track
	clc
	adc noteAddNote+_track
	cmp plyrSlideDestination+_track
	bcs @slideX
	bcc @slideOff

@slidePos:	lda noteNumber+_track
	clc
	adc noteAddNote+_track
	cmp plyrSlideDestination+_track
	bcc @slideX
	
@slideOff:	lda plyrSlideDestination+_track
	sta noteNumber+_track
	lda #$00
	sta plyrSlideSpeed+_track
	sta noteAddFrac+_track
	sta noteAddNote+_track
@slideX:	rts
	
	.ENDMACRO

;-------------------------------------------------------------------------------
; Pitch Sweep
;-------------------------------------------------------------------------------
	.MACRO doPitchSweep _track
	lda #$00
	sta plyrPitchSweepDelta+_track
	
	lda plyrSlideSpeed+_track
	beq @noSlide
	lda plyrPitchSweepLo+_track
	clc
	adc plyrInstrumentCopy + (_track*STEPS_PER_INSTRUMENT)+INSTRUMENT_ROW_PSWEEPQ
	sta plyrPitchSweepLo+_track
	bcc @xSweep
	lda plyrSlideSpeed+_track
	sta plyrPitchSweepDelta+_track
	rts
	
@noSlide:	lda plyrPitchSweepLo+_track
	clc
	adc plyrInstrumentCopy + (_track*STEPS_PER_INSTRUMENT)+INSTRUMENT_ROW_PSWEEPQ
	sta plyrPitchSweepLo+_track
	bcc @xSweep
	lda plyrInstrumentCopy + (_track*STEPS_PER_INSTRUMENT)+INSTRUMENT_ROW_PSWEEP
	sta plyrPitchSweepDelta+_track
@xSweep:	rts
	.ENDMACRO
	
;-------------------------------------------------------------------------------
; Vibrato
;-------------------------------------------------------------------------------
	.MACRO doVibrato _track
	.IF SRAM_MAP=32
	lda #SRAM_VIBRATO_BANK
	jsr setMMC1r1
	.ENDIF
	;lda #$80
	;sta plyrVibSpeedLo
	ldx plyrInstrumentCopy+(_track*STEPS_PER_INSTRUMENT)+INSTRUMENT_ROW_VIBRATO
	cpx #$FF
	bne @doVib
	lda #$00
	sta plyrVibDelta+_track
	sta plyrVibLastDelta+_track
@noVibYet:
	rts

@doVib:	lda vibratoRowsIndex,x
	tax
	lda plyrNoteCounter+_track
	cmp SRAM_VIBRATOS+VIBRATO_COLUMN_DELAY,x	;*SRAM*
	bcc @noVibYet
	
	lda plyrSlideSpeed+_track
	bne @noVibYet	
	
	lda #$00			;zero delta so can be called every frame
	sta plyrVibDelta+_track

	lda SRAM_VIBRATOS+VIBRATO_COLUMN_ACCELERATE,x	;*SRAM*
	beq @noAcc

	lda plyrVibDepthMod+_track
	cmp SRAM_VIBRATOS+VIBRATO_COLUMN_DEPTH,x	;*SRAM*
	beq @accVib

	lda plyrVibDepthModCounter+_track
	clc
	adc SRAM_VIBRATOS+VIBRATO_COLUMN_ACCELERATE,x	;*SRAM*
	sta plyrVibDepthModCounter+_track
	bcc @accVib
	inc plyrVibDepthMod+_track
	jmp @accVib

@noAcc:	lda SRAM_VIBRATOS+VIBRATO_COLUMN_DEPTH,x	;*SRAM*
	sta plyrVibDepthMod+_track
	
@accVib:	lda plyrVibDepthMod+_track
	beq @yVib
	lda SRAM_VIBRATOS+VIBRATO_COLUMN_SPEED,x	;*SRAM*
	beq @yVib
	lda plyrVibSpeedCounter+_track
	clc
	;adc plyrVibSpeedLo+_track
	adc plyrInstrumentCopy+(_track*STEPS_PER_INSTRUMENT)+INSTRUMENT_ROW_PSWEEPQ
	sta plyrVibSpeedCounter+_track
	bcc @xVib
	
	lda plyrVibPos+_track
	clc
	adc SRAM_VIBRATOS+VIBRATO_COLUMN_SPEED,x	;*SRAM*
	;adc plyrVibDepthMod+_track
	and #$3F
	sta plyrVibPos+_track
	tay
	;lda sineTable,y
	lda triTable,y
	jsr @scaleVib
	sta engineTmp2
	sec
	sbc plyrVibLastDelta+_track
	sta plyrVibDelta+_track
	lda engineTmp2
	sta plyrVibLastDelta+_track
@xVib:	rts
@yVib:	lda #$00
	;sta noteAddFrac
	;sta noteAddNote
	sta plyrVibPos+_track
	sta plyrVibLastDelta+_track
	rts

@scaleVib:	
	cpy #$1f
	bcs @negative
	sta engineTmp2
	lda #$0F
	sec
	;sbc SRAM_VIBRATOS+VIBRATO_COLUMN_DEPTH,x
	sbc plyrVibDepthMod+_track
	beq @x1
	tay
	lda divideLo,y
	sta engineTmp0
	lda divideHi,y
	sta engineTmp1
	lda engineTmp2
	tay
	lda (engineTmp0),y
	rts
@x1:	lda engineTmp2
	rts
	
@negative:
	sta engineTmp2
	lda #$10
	sec
	;sbc SRAM_VIBRATOS+VIBRATO_COLUMN_DEPTH,x
	sbc plyrVibDepthMod+_track
	beq @y1
	tay
	lda divideLo,y
	sta engineTmp0
	lda divideHi,y
	sta engineTmp1
	lda engineTmp2
	tay
	lda (engineTmp0),y
	eor #$FF
	clc
	adc #$01
	rts
@y1:	lda engineTmp2
	eor #$FF
	clc
	adc #$01
	rts
	
	.ENDMACRO

;-------------------------------------------------------------------------------
; Add To Pitch
;-------------------------------------------------------------------------------
	.MACRO addToPitch _voice
	bmi @subtract
	clc
	adc noteAddFrac+_voice
	sta engineTmp2
	and #$0F
	sta noteAddFrac+_voice
	lda engineTmp2
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc noteAddNote+_voice
	sta noteAddNote+_voice
	
	clc
	adc noteNumber+_voice
	sec
	sbc #$5F
	beq @a
	bmi @a
	sec
	sbc noteNumber+_voice
	sta noteAddNote+_voice
	lda #$00
	sta noteAddFrac+_voice	
@a:	rts
	
@subtract:
	clc
	adc noteAddFrac+_voice
	sta engineTmp2
	and #$0F
	sta noteAddFrac+_voice
	lda engineTmp2
	eor #$FF
	clc
	adc #$10
	lsr a
	lsr a
	lsr a
	lsr a
	sta engineTmp0
	sec
	lda noteAddNote+_voice
	sbc engineTmp0
	sta noteAddNote+_voice
	clc
	adc noteNumber+_voice
	bpl @b
	clc
	adc #$5F
	sec
	sbc noteNumber+_voice
	sta noteAddNote+_voice
@b:	rts
	.ENDMACRO
;-------------------------------------------------------------------------------
; Scale Amplitude 
;-------------------------------------------------------------------------------
	.MACRO scaleVolume _track
	tay
	lda VOLUME_TABLE_LO,y
	sta engineTmp0
	lda VOLUME_TABLE_HI,y
	sta engineTmp1
	ldy plyrInstrumentCopy + (_track * STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_LEVEL
	lda (engineTmp0),y
	tay
	lda VOLUME_TABLE_LO,y
	sta engineTmp0
	lda VOLUME_TABLE_HI,y
	sta engineTmp1
	ldy plyrTableVolume+_track
	lda (engineTmp0),y
	.ENDMACRO
;-------------------------------------------------------------------------------
; Get Note
;-------------------------------------------------------------------------------
	.MACRO getNote _track
	clc
	adc noteAddNote+_track
	cmp #NUMBER_OF_NOTES
	bcc @notOver
	bmi @x
	sec
	lda #NUMBER_OF_NOTES
@notOver:
	tay
	lda octaveShiftTable,y
	pha
	lda note2Table,y
	clc
	adc noteAddFrac+_track
	tay
	lda Tone2PeriodLo,y
	sta getNoteTemp0
	lda Tone2PeriodHi,y
	sta getNoteTemp1
	pla
	beq @getNoteB
	tay
@getNoteA:	
	lsr getNoteTemp1
	ror getNoteTemp0
	dey
	bne @getNoteA
@getNoteB:
	lda getNoteTemp0
	ldy getNoteTemp1
@x:	rts
	.ENDMACRO

;-------------------------------------------------------------------------------
; Run (Pitch) Table
;-------------------------------------------------------------------------------
	.MACRO runTable _track
	lda plyrPlaying
	beq @notPlaying
	.IF (_track<4)
	ldx plyrInstrumentCopy + (_track * STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_TABLE
	.ELSE
	ldx plyrTableTrackE
	.ENDIF
	cpx #$FF
	bne @runTable
	.IF (_track<4)
	lda #$0F
	sta plyrTableVolume+_track
	lda #$00
	sta plyrTablePitch+_track
	.ENDIF
@notPlaying:
	rts
	
@runTable:
	.IF SRAM_MAP=32
	lda #SRAM_TABLE_BANK
	jsr setMMC1r1
	.ENDIF
	lda editTableAddressLo,x
	sta plyrTableVector
	lda editTableAddressHi,x
	sta plyrTableVector+1
	lda plyrTableDoStep+_track
	bne @doStep

@noStep:	;lda plyrTableCounter+_track
	;clc
	;adc plyrTableSpeed+_track
	;sta plyrTableCounter+_track
	lda plyrTableSpeed+_track
	and #%11111110
	clc
	adc plyrTableCounter+_track
	sta plyrTableCounter+_track
	bcc @xxx

	.IF (_track=4)
	lda #$81
	sta plyrKeyOn+$04
	.ENDIF
		
	lda plyrTableJump+_track
	bpl @doJump
	
	lda plyrTableIndex+_track
	clc
	adc #$01
	and #STEPS_PER_TABLE-1
@doJump:	sta plyrTableIndex+_track
	lda #$FF
	sta plyrTableJump+_track
	sta plyrTableDoStep+_track
@xxx:	rts
		
@doStep:	ldy plyrTableIndex+_track
	lda tableRowsIndex2,y
	tay	
	lda (plyrTableVector),y	;*SRAM* fx1
	sta plyrFxTemp1
	iny
	lda (plyrTableVector),y	;*SRAM* fx1 data
	sta plyrFxDataTemp1
	iny
	lda (plyrTableVector),y	;*SRAM* fx2
	sta plyrFxTemp2
	cmp #COMMAND_H
	bne @notJump
	iny
	lda (plyrTableVector),y
	jsr randomRangeNumber
	cmp plyrTableIndex+_track
	beq @noJumping
	sta plyrTableIndex+_track
	lda #$01
	sta plyrTableDoStep+_track
	lda #$FF
	sta plyrTableJump+_track
	jmp @doStep
@noJumping:
	lda #$FF
	sta plyrTableJump+_track
@notJump:	
	iny
	lda (plyrTableVector),y	;*SRAM* fx2 data
	sta plyrFxDataTemp2	

	lda #$FF
	sta plyrTableJump+_track
	lda #$01
	sta plyrFxType
	
	ldy plyrFxTemp1
	bmi @noFX1
	lda plyrFxDataTemp1
	ldx #_track
	jsr plyrDoCommand	
@noFX1:
	ldy plyrFxTemp2
	bmi @noFX2
	lda plyrFxDataTemp2
	ldx #_track
	jsr plyrDoCommand
@noFX2:
	
	.IF (_track=4)
	ldx plyrCurrentInstrument+_track
	lda plyrCurrentNote+_track
	cmp SRAM_DRUMKIT_ROOTS,x		;*SRAM*
	bcc @xxx
	sbc SRAM_DRUMKIT_ROOTS,x		;*SRAM*
	cmp #$0C
	bcs @xxx
	tax
	lda drumkitRowsIndex,x
	tax
	.ENDIF
	ldy plyrTableIndex+_track
	lda tableRowsIndex,y
	tay
	lda (plyrTableVector),y	;*SRAM* volume scale or DPCM pitch
	.IF (_track<4)
	sta plyrTableVolume+_track
	.ELSE
	inx
	sta plyrInstrumentCopyE,x
	.ENDIF
	iny
	lda (plyrTableVector),y	;*SRAM* pitch offset or DPCM sample number
	.IF (_track<4)
	sta plyrTablePitch+_track
	.ELSE
	dex
	sta plyrInstrumentCopyE,x
	.ENDIF

	lda #$00
	sta plyrTableDoStep+_track
	jmp @noStep
	
	
	
	rts
	
	.ENDMACRO

;-------------------------------------------------------------------------------
; Run Duty Table
;-------------------------------------------------------------------------------
	.MACRO runDutyTable _track
	
	.IF (_track=0) || (_track=1)
	lda plyrInstrumentCopy + (_track * STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_DUTY
	cmp #$04
	bcs @runDuty
	tax
	lda DUTY_TABLE,x
	sta plyrCurrentDuty + _track
	rts
	
@runDuty:	sbc #$04
	tax
	lda plyrDutyTableDelay+_track
	beq @moreDuty
	dec plyrDutyTableDelay+_track
	rts

@moreDuty:
	lda editDutyAddressLo,x
	sta plyrDutyVector
	lda editDutyAddressHi,x
	sta plyrDutyVector+1
	
	.IF SRAM_MAP=32
	lda #SRAM_DUTY_BANK
	jsr setMMC1r1
	.ENDIF

	lda plyrDutyIndex+_track	
	tay
	lda dutyRowsIndex,y
	tay
	lda (plyrDutyVector),y		;*SRAM*
	sta plyrCurrentDuty+_track
	iny
	lda (plyrDutyVector),y		;*SRAM*
	sta plyrDutyTableDelay+_track
	iny
	lda (plyrDutyVector),y		;*SRAM*
	cmp #$FF
	bne @dutyJump
	lda plyrDutyIndex+_track
	clc
	adc #$01
	and #STEPS_PER_DUTY_TABLE-1	
@dutyJump:
	sta plyrDutyIndex+_track
	.ENDIF
	rts
	.ENDMACRO

;-------------------------------------------------------------------------------
; Refresh Voice
;-------------------------------------------------------------------------------

	.MACRO refreshVoice _track

	.IF (_track=4)
	jsr @doTable
	.ENDIF
	
	lda #$01
	sta plyrFxType

	.IF (_track=0) || (_track=1)
	jsr @doDuty
	.ENDIF
	
	.IF (_track < 4)
	jsr @doTable
	jsr @doADSR
	jsr @doChord
	.ENDIF
	
	.IF (_track<3)
	jsr @doPitchSlide
	jsr @doPitchSweep
	jsr @doVibrato
	.ENDIF
	
	.IF (_track<3)
	lda plyrVibDelta+_track
	clc 
	adc plyrPitchSweepDelta+_track
	jsr @addToPitch
	.ENDIF
	
	.IF (_track<4)
	lda plyrTablePitch+_track
	cmp #$60
	bcc @posPitch
	cmp #NUMBER_OF_NOTES+$60
	bcs @posPitch
	sec
	sbc #$60
	jmp @absPitch
	
@posPitch:
	clc
	adc noteNumber+_track
	clc
	adc plyrPatternChordNote+_track
@absPitch:
	
	.IF (_track<3)
	jsr @getNote
	sta pitchLo+_track
	sty pitchHi+_track
	.ELSEIF (_track=3)
	clc
	adc plyrPatternChordNote+_track
	cmp #$10
	bcc @notToneNoise
	and #$0F
	ora #$80
@notToneNoise:
	sta pitchLo+_track
	.ENDIF
	
	.IF (_track < 3)
	lda pitchLo+_track
	sta V_APU+(_track * 4)+2
	lda pitchHi+_track
	sta V_APU+(_track * 4)+3
	.ELSEIF (_track=3)
	lda pitchLo+_track
	sta V_APU+$0E
	.ENDIF
	
	.IF (_track < 3)
	lda V_APU+(_track*4)+2
	clc
	adc plyrInstrumentCopy + (_track*STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_DETUNE
	sta V_APU+(_track*4)+2
	lda V_APU+(_track*4)+3
	adc plyrDetuneHi+_track
	and #$07
	sta V_APU+(_track*4)+3
	
	lda plyrInstrumentCopy + (_track*STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_SWEEP
	eor #$FF
	clc
	adc #$01
	bmi @negDetuneSweep
	clc
	adc plyrInstrumentCopy + (_track*STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_DETUNE
	sta plyrInstrumentCopy + (_track*STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_DETUNE
	lda plyrDetuneHi+_track
	adc #$00
	sta plyrDetuneHi+_track
	jmp @skipDetuneSweep
@negDetuneSweep:
	clc
	adc plyrInstrumentCopy + (_track*STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_DETUNE
	sta plyrInstrumentCopy + (_track*STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_DETUNE
	lda plyrDetuneHi+_track
	adc #$FF
	sta plyrDetuneHi+_track
@skipDetuneSweep:	
	.ENDIF
	
	
	.IF (_track=0) || (_track=1)
	lda envelopeAmp+_track
	scaleVolume _track
	eor plyrCurrentDuty+_track
	ora #$30
	sta V_APU+(_track * 4)+0
	.ENDIF
	
	.IF _track = 2
	lda plyrTableVolume+_track
	beq @zeroC
	lda envelopeAmp+_track
	beq @zeroC
	lda #$81
@zeroC:	sta V_APU+$08
	.ENDIF
	
	.IF _track = 3
	lda envelopeAmp+_track
	scaleVolume _track
	ora #$30
	sta V_APU+(3 * 4)+0
	.ENDIF

	.ENDIF

	.IF SRAM_MAP=32
	lda #SRAM_HEADER_BANK
	jsr setMMC1r1
	.ENDIF
	ldy editorCurrentSong
	lda #$00
	sta plyrDpcmMuted
	lda SRAM_SONG_MUTE,y
	and SetBits+_track
	beq @noMute
	.IF (_track<2)||(_track=3)
	lda V_APU+(_track*4)+0
	and #%11110000
	sta V_APU+(_track*4)+0
	.ENDIF
	.IF (_track=2)
	lda #$00
	sta V_APU+$08
	.ENDIF	
	.IF (_track=4)
	;handle DPCM
	inc plyrDpcmMuted
	.ENDIF
@noMute:	
	lda SRAM_SONG_SOLO,y
	bmi @noSolo
	cmp #_track
	beq @noSolo
	.IF (_track<2)||(_track=3)
	lda V_APU+(_track*4)+0
	and #%11110000
	sta V_APU+(_track*4)+0
	.ENDIF
	.IF (_track=2)
	lda #$00
	sta V_APU+$08
	.ENDIF	
	.IF (_track=4)
	inc plyrDpcmMuted
	.ENDIF
@noSolo:	

	rts

	.IF (_track<4)
;-------------------------------------------------------------------------------
; Pitch Sweep Call
;-------------------------------------------------------------------------------
@doPitchSweep:
	.IF (_track<3)
	doPitchSweep _track
	.ELSE
	.ENDIF
	rts

;-------------------------------------------------------------------------------
; Pitch Slide Call
;-------------------------------------------------------------------------------
@doPitchSlide:
	.IF (_track<3)
	doPitchSlide _track
	.ENDIF
	rts
	
;-------------------------------------------------------------------------------
; Vibrato Call
;-------------------------------------------------------------------------------
@doVibrato:	
	.IF (_track<3)
	doVibrato _track
	.ENDIF
	rts
	
;-------------------------------------------------------------------------------
; ADSR Call
;-------------------------------------------------------------------------------
@doADSR:
	.IF (_track<4)
	doADSR _track
	.ENDIF
	rts
	
;-------------------------------------------------------------------------------
; Get Note Call
;-------------------------------------------------------------------------------
@getNote:	.IF (_track < 3)
	getNote _track
	.ENDIF
	rts

;-------------------------------------------------------------------------------
; Duty Call
;-------------------------------------------------------------------------------
@doDuty:	.IF (_track=0) | (_track=1)
	runDutyTable _track
	.ENDIF
	rts

;-------------------------------------------------------------------------------
; Add To Pitch Call
;-------------------------------------------------------------------------------
@addToPitch:
	.IF (_track<3)
	addToPitch _track
	.ENDIF
	rts
	
;-------------------------------------------------------------------------------
; Chord Call
;-------------------------------------------------------------------------------
@doChord:
	lda plyrChordNotes+_track
	ldy plyrPatternChordIndex+_track
	bne @notRoot
	sty plyrPatternChordNote+_track
	beq @updateChord
@notRoot:	cpy #$01
	bne @notChord1
	lsr a
	lsr a
	lsr a
	lsr a
	bpl @writeChord
@notChord1:
	and #$0F
@writeChord:
	sta plyrPatternChordNote+_track
@updateChord:
	lda plyrPatternChordCounter+_track
	clc
	adc plyrInstrumentCopy+(_track*STEPS_PER_INSTRUMENT)+INSTRUMENT_ROW_PSWEEPQ
	sta plyrPatternChordCounter+_track
	lda plyrPatternChordIndex+_track
	adc #$00
	cmp #$03
	bcc @notChordLoop
	lda #$00
@notChordLoop:
	sta plyrPatternChordIndex+_track
	rts

	.ENDIF
	
;-------------------------------------------------------------------------------
; Table Call
;-------------------------------------------------------------------------------
@doTable:
	runTable _track
	rts
	
	
	.ENDMACRO
	
