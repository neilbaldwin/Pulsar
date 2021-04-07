		.MACRO updateTrack _track
		.LOCAL _sram_track
		.IF _track=SONG_TRACK_A
		_sram_track = SRAM_TRACK_A
		.ELSEIF _track=SONG_TRACK_B
		_sram_track = SRAM_TRACK_B
		.ELSEIF _track=SONG_TRACK_C
		_sram_track = SRAM_TRACK_C
		.ELSEIF _track=SONG_TRACK_D
		_sram_track = SRAM_TRACK_D
		.ELSE
		_sram_track = SRAM_TRACK_E
		.ENDIF
		

		
		lda #$00
		sta plyrFxType

		lda plyrRetriggerCounter+_track
		clc
		adc plyrRetriggerSpeed+_track
		sta plyrRetriggerCounter+_track
		bcc @noTrigger
		lda #$01
		sta plyrKeyOn+_track
@noTrigger:

		lda plyrKillCounter+_track
		bmi @noKill
		dec plyrKillCounter+_track
		bpl @noKill
		.IF (_track<4)
		lda plyrInstrumentCopy + (_track * STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_ENVELOPE
		asl a
		asl a
		clc
		adc #ENVELOPE_SUSTAIN_PHASE
		tay
		lda envelopeAmp+_track
		lsr a
		sta envelopeAmp+_track
		
		lda envelopePhase+_track
		cmp #$01
		bcc @noKill
		
		lda #ENVELOPE_RELEASE_PHASE
		sta envelopePhase+_track
		.ELSE
		lda #$00
		sta plyrDpcmOn
		lda APU_15
		and #$0F
		sta APU_15
		.ENDIF
@noKill:		
;		lda plyrDelayNoteCounter+_track
;		bne @noteCountOver
;		lda plyrNoteCounter+_track
;		clc
;		adc #$01
;		beq @noteCountOver			;keep at $FF max
;		sta plyrNoteCounter+_track
;@noteCountOver:

		lda plyrPlaying
		and SetBits+_track
		bne @play
		.IF (_track<4)
		;lda #$00
		;sta envelopeAmp+_track
		;sta envelopePhase+_track
		.ELSE
		lda #$00
		sta plyrDpcmOn
		;lda APU_15
		;and #$0F
		;sta APU_15
		.ENDIF
		rts
			
@play:		lda plyrPatternStepCounter+_track	;time for new note?
		beq @getPatternStep
		dec plyrPatternStepCounter+_track	;no, decrease counter and exit


		jmp @exit
		
@getPatternStep:	
		ldy plyrPatternIndex+_track		;yes, 1st step of pattern?
		bne @gotPatternAddress		;no

		ldy plyrChainIndex+_track		;yes, need pattern address
		bne @gotChainAddress		;first step of chain? 
		
		ldy plyrTrackIndex+_track		;yes need chain address
@getChain:	
		lda _sram_track,y		;get current chain from track
		cmp #$FF			;reached end (loop)?
		bne @notTrackEnd		;no
@getChain0:	cpy plyrSongStartIndex		;yes, if this is starting index
		bne @notEmptyTrack		;  then track must be "empty"
		lda plyrPlaying		;so stop track playing
		and ClrBits+_track
		sta plyrPlaying
		rts			;and exit
		
@notEmptyTrack:	ldy plyrSongStartIndex		;not empty so reset track index to start
		sty plyrTrackIndex+_track
		lda _sram_track,y		;then get chain number
@notTrackEnd:	sta plyrCurrentChain+_track
		tax
		lda editChainAddressLo,x	;and setup pointer for chain
		sta plyrChainVector+(_track*2)
		lda editChainAddressHi,x
		sta plyrChainVector+(_track*2)+1
		ldy plyrChainIndex+_track	;get current chain index
		
@gotChainAddress:	lda chainRowsIndex,y	;get index*2 (2 bytes per chain step)
		tay
		lda (plyrChainVector+(_track*2)),y	;read pattern number from chain
		cmp #$FF			;if $FF then terminate chain
		bne @notChainEnd
		ldy plyrTrackIndex+_track
		jmp @getChain0
		
@notChainEnd:	sta plyrCurrentPattern+_track	;save current pattern number
		tax
		lda editPatternAddressLo,x	;get pattern address
		sta plyrPatternVector+(_track*2)
		lda editPatternAddressHi,x
		sta plyrPatternVector+(_track*2)+1
		iny
		lda (plyrChainVector+(_track*2)),y	;get transpose for this chain step
		sta plyrCurrentChainTranspose+_track
		ldy plyrPatternIndex+_track
		
@gotPatternAddress:	lda patternRowsIndex,y	;index*4 (4 bytes per pattern step)
		tay
		lda (plyrPatternVector+(_track*2)),y	;read note
		sta tmp0

		iny
		lda (plyrPatternVector+(_track*2)),y	;read instrument
		pha			;save for later compare
		iny
		lda (plyrPatternVector+(_track*2)),y	;read FX command
		sta plyrCurrentPatternFX+_track
		iny
		lda (plyrPatternVector+(_track*2)),y	;read FX command data
		sta plyrCurrentPatternFXData+_track
		pla			;retrieve instrument
		cmp #$FF
		beq @noInstrument		;don't change if none requested
		sta plyrCurrentInstrument+_track
		
@noInstrument:	lda tmp0			;plyrCurrentNote+_track
		bmi @noInsCopy
		
		.IF (_track < SONG_TRACK_E)
		lda plyrCurrentInstrument+_track
		tax			;otherwise copy instrument to RAM
		lda editInstrumentAddressLo,x
		sta plyrInstrumentVector+(_track*2)
		lda editInstrumentAddressHi,x
		sta plyrInstrumentVector+(_track*2)+1
		
		ldy #$00
@insCopy:		lda (plyrInstrumentVector+(_track*2)),y
		sta plyrInstrumentCopy+(_track * STEPS_PER_INSTRUMENT),y
		iny
		cpy #STEPS_PER_INSTRUMENT
		bcc @insCopy

		.ELSE
		
		lda plyrCurrentInstrument+_track
		tax
		lda editDrumkitAddressLo,x
		sta plyrInstrumentVector+(4*2)
		lda editDrumkitAddressHi,x
		sta plyrInstrumentVector+(4*2)+1
		ldy #$00
@drumkitCopy:	lda (plyrInstrumentVector+(4*2)),y
		sta plyrInstrumentCopy+(_track*STEPS_PER_INSTRUMENT),y
		iny
		cpy #STEPS_PER_DRUMKIT * BYTES_PER_DRUMKIT_STEP
		bcc @drumkitCopy
		.ENDIF

@noInsCopy:
		ldy plyrCurrentPatternFX+_track
		cpy #COMMAND_U
		bne @noProb
		jsr randomNumber
		cmp plyrCurrentPatternFXData+_track
		bcs @noProb
		lda #$FF
		sta tmp0
		
@noProb:		lda tmp0
		cmp #$FF
		beq @emptyNote
		sta plyrCurrentNote+_track
		
		lda #$00
		sta plyrDelayNoteCounter+_track
		lda #$01
		sta plyrKeyOn+_track
		
		lda #$00
		sta plyrRetriggerSpeed+_track
		sta plyrRetriggerCounter+_track
		
		.IF (_track<3)
		lda #$00
		sta plyrSlideSpeed+_track
		sta plyrChordNotes+_track
		sta plyrTableIndex+_track
		.ENDIF
		.IF (_track=4)
		lda #$FF
		sta plyrTableTrackE
		.ENDIF

@emptyNote:		ldy plyrCurrentPatternFX+_track
		cpy #$FF
		beq @noFX
		ldx #_track
		lda plyrCurrentPatternFXData+_track
		jsr plyrDoCommand
@noFX:
		ldy plyrCurrentSpeedTable+_track
		lda editSpeedAddressLo,y
		sta plyrSpeedVector
		lda editSpeedAddressHi,y
		sta plyrSpeedVector+1
		ldy plyrSpeedTableIndex+_track
		lda (plyrSpeedVector),y
		cmp #$FF
		bne @notIllegalSpeed
		ldy #$00
		lda (plyrSpeedVector),y		
@notIllegalSpeed:	sta plyrPatternStepCounter+_track
		iny
		lda (plyrSpeedVector),y
		cmp #$FF
		bne @notSpeedLoop
		ldy #$00
		beq @writeSpeedIndex
@notSpeedLoop:	tya
		and #STEPS_PER_SPEED_TABLE-1
		tay
@writeSpeedIndex:	sty plyrSpeedTableIndex+_track

		lda plyrTableSpeed+_track
		bne @noSync
		lda plyrTableJump+_track
		bpl @syncJump
		lda plyrTableIndex+_track
		clc
		adc #$01
		and #$0F
@syncJump:		sta plyrTableIndex+_track
		lda #$01
		sta plyrTableDoStep+_track

		lda #$FF
		sta plyrTableJump+_track

@noSync:		lda plyrPatternJump+_track
		sta tmp0
		lda #$FF
		sta plyrPatternJump+_track
		lda tmp0
		cmp #$FF
		beq @noPatternJump
		cmp #STEPS_PER_PATTERN
		bcs @illegalJump
		cmp plyrPatternIndex+_track
		beq @illegalJump
		bcs @endPattern
@illegalJump:	lda #$00
		beq @endPattern

@noPatternJump:	lda plyrPatternIndex+_track	;update pattern index (mod $10)
		clc
		adc #$01
@endPattern:	and #STEPS_PER_PATTERN-1
		sta plyrPatternIndex+_track
		bne @exit
		
		lda plyrChainIndex+_track		;if pattern index = 0, update chain index
		clc
		adc #$01
		and #STEPS_PER_CHAIN-1
		sta plyrChainIndex+_track
		beq @updateTrack		;if chain ended (=0) or terminated with $FF
		tay			;need to update track index
		lda chainRowsIndex,y
		tay
		lda (plyrChainVector+(_track*2)),y
		cmp #$FF
		bne @exit
		ldy #$00
		sty plyrChainIndex+_track
		
@updateTrack:	lda plyrTrackIndex+_track
		clc
		adc #$01
		and #STEPS_PER_TRACK-1	;update track index
		sta plyrTrackIndex+_track
		tay
		lda _sram_track,y		;if chain at new position is $FF then loop
		cmp #$FF			;otherwise exit
		bne @exit
		ldy plyrSongStartIndex
		sty plyrTrackIndex+_track

@exit:		.IF (_track=0)
		lda plyrCurrentPatternFX
		cmp #COMMAND_H
		bne @notH
		jmp @getPatternStep
@notH:		
		.ENDIF
		rts
		
		.ENDMACRO
		
;------------------------------------------------------------------------------
; Play Notes
;------------------------------------------------------------------------------

		.MACRO playNote _track
		lda plyrDelayNoteCounter+_track
		bne @noteCountOver
		lda plyrNoteCounter+_track
		clc
		adc #$01
		beq @noteCountOver			;keep at $FF max
		sta plyrNoteCounter+_track
@noteCountOver:	

		lda plyrKeyOn+_track
		bne @keyOn
@exit:		rts
		
@keyOn:
		
		lda plyrDelayNoteCounter+_track
		beq @delayDone
		dec plyrDelayNoteCounter+_track
		beq @delay0
		jmp @noNote
@delay0:		lda plyrDelayNote+_track
		sta plyrCurrentNote+_track		
		
@delayDone:	lda #$00
		sta plyrKeyOn+_track

		lda plyrCurrentNote+_track
		cmp #$FF
		beq @exit

		.IF (_track<1)
		lda #$FF
		sta pitchHiOld+_track
		sta pitchLoOld+_track
		.ENDIF

		.IF (_track<3)
		lda noteNumber+_track
		sta plyrPreviousNote+_track
		
		lda plyrSlideSpeed+_track
		beq @noSlide
		
		lda plyrCurrentNote+_track
		and #$7F
		clc
		adc plyrCurrentChainTranspose+_track
		sta plyrSlideDestination+_track

		cmp plyrPreviousNote+_track
		bne @notSameNote
		lda #$00
		sta plyrSlideSpeed+_track
		beq @noSlide
		
@notSameNote:	bcs @posSlide
		lda plyrSlideSpeed+_track
		eor #$FF
		clc
		adc #$01
		sta plyrSlideSpeed+_track
@posSlide:

		jmp @skipNewNote
@noSlide:		.IF (_track < 2)
		lda #$00
		sta noteAddNote+_track
		sta noteAddFrac+_track
		.ENDIF
		.ENDIF

		.IF (_track < SONG_TRACK_E)
		lda plyrCurrentNote+_track
		and #$7F	
		clc
		adc plyrCurrentChainTranspose+_track
		sta noteNumber+_track
@skipNewNote:				
		.IF (_track<SONG_TRACK_E)
		lda plyrCurrentNote+_track
		and #$80
		bne @noNote

		lda #$FF
		sta plyrTableJump+_track
		
		lda plyrCurrentPatternFX+_track
		cmp #COMMAND_C
		beq @noClearChord		
		lda #$00
		sta plyrChordNotes+_track
		sta plyrTableCounter+_track
		sta plyrTableIndex+_track
		lda #$01
		sta plyrTableDoStep+_track
		
@noClearChord:	

		.IF (_track<3)
		lda #$00
		sta plyrVibPos+_track
		sta plyrVibSpeedCounter+_track
		sta plyrVibDelta+_track
		sta plyrVibLastDelta+_track
		sta noteAddFrac+_track
		sta noteAddNote+_track
		sta plyrPitchSweepLo+_track
		sta plyrPitchSweepDelta+_track
		sta plyrVibDepthMod+_track		
		.ENDIF		
		
		.IF (_track = SONG_TRACK_A) || (_track=SONG_TRACK_B)
		lda #$00
		sta plyrDutyIndex+_track
		sta plyrDutyTableDelay+_track
		.ENDIF
		
		.ENDIF

		lda #initPhase
		sta envelopePhase+_track
		lda #$00
		sta plyrNoteCounter+_track
				
		.ELSE
				
		lda APU_15
		and #$0F
		sta APU_15
		
		lda #$40
		sta dpcmDC

		lda plyrCurrentInstrument+_track
		tay
		lda plyrCurrentNote+_track
		and #$7F
		sta engineTmp0
		
		cmp SRAM_DRUMKIT_ROOTS,y
		bcc @noNote
		sbc SRAM_DRUMKIT_ROOTS,y
		cmp #STEPS_PER_DRUMKIT
		bcs @noNote
		
		tay
		lda drumkitRowsIndex,y
		tay
		lda plyrInstrumentCopyE+$00,y	;sample number?
		sta engineTmp0
		lda plyrInstrumentCopyE+$04,y	;loop
		asl a
		asl a
		asl a
		asl a
		asl a
		asl a
		ora plyrInstrumentCopyE+$01,y		
		sta dpcmPitch
		
		lda engineTmp0
		tax
		lda dmcAddressTable,x
		clc
		adc plyrInstrumentCopyE+$02,y	;start offset
		sta dpcmStart
		
		eor #$3f
		clc
		adc dmcAddressTable+1,x
		asl a
		asl a
		ora #$03
		sec
		sbc plyrInstrumentCopyE+$03,y	;end offset		
		sta dpcmLength

		lda #$00
		sta plyrNoteCounter+_track

		lda #$00
		sta plyrTableCounter+$04
				
		lda #$10
		sta plyrDpcmOn
		
		.ENDIF

		lda #$FF
		;sta plyrCurrentNote+_track
@noNote:
		rts
		.ENDMACRO

		