;---------------------------------------------------------------
; PULSAR Music Player
;---------------------------------------------------------------
.export plyrInitSong, plyrRefresh

		.include "plyrMacros.asm"
			
plyrInitSong:
		lda #$00
		ldx #$00
@a:		sta plyrTrackIndex,x
		sta plyrChainIndex,x
		sta plyrPatternIndex,x
		sta plyrPatternStepCounter
		sta plyrCurrentInstrument,x
		inx
		cpx #$05
		bcc @a
		sta plyrPlaying
		sta plyrSongStartIndex
		rts
	
plyrStartSong:	
		lda vblankFlag
		sta lfsr
		lda #$00
		sta plyrCurrentSpeedTable
		sta plyrSpeedTableIndex
		
		lda #%00011111
		sta plyrPlaying
		rts
		
plyrStopSong:	lda #$00
		sta plyrPlaying
		rts
		
plyrRefresh:	
@a:		jsr plyrUpdateTrackA
		jsr plyrPlayNoteA
		jsr plyrUpdateTrackB
		jsr plyrPlayNoteB
		jsr plyrUpdateTrackC
		jsr plyrPlayNoteC
		jsr plyrUpdateTrackD
		jsr plyrPlayNoteD
		jsr plyrUpdateTrackE
		jsr plyrPlayNoteE
		
		jsr plyrUpdateSpeedTable
		
		.IF SRAM_MAP=32
		.IF ENABLE_ECHO=1
		jsr pulsarUpdateEchoA
		jsr pulsarUpdateEchoB
		jsr pulsarUpdateEchoD
		.ENDIF
		.ENDIF

		inc bpmFrameCounter
		
@x:		rts
		

plyrCalculateBPM:
		inc bpmBeatCounter
		lda bpmBeatCounter
		cmp #$04
		bcc @x
		lda bpmFrameCounter
		sta bpmCurrent
		lda #$00
		sta bpmBeatCounter
		sta bpmFrameCounter
@x:		rts

plyrUpdateSpeedTable:
		lda plyrPatternStepCounter
		beq @nextStep
		dec plyrPatternStepCounter
		rts
		
@nextStep:	jsr plyrCalculateBPM
		ldy plyrCurrentSpeedTable
		lda editSpeedAddressLo,y
		sta plyrSpeedVector
		lda editSpeedAddressHi,y
		sta plyrSpeedVector+1

		.IF SRAM_MAP=32
		lda #SRAM_SPEED_BANK
		jsr setMMC1r1
		.ENDIF

		ldy plyrSpeedTableIndex
		iny
		lda (plyrSpeedVector),y		;*SRAM*
		cmp #$FF
		bne @notEnd
		ldy #$00
		lda (plyrSpeedVector),y
@notEnd:		sta plyrPatternStepCounter
		tya
		and #STEPS_PER_SPEED_TABLE-1
		sta plyrSpeedTableIndex
		rts
		
plyrUpdateTrackA:	
		updateTrack SONG_TRACK_A

plyrUpdateTrackB:
		updateTrack SONG_TRACK_B

plyrUpdateTrackC:
		updateTrack SONG_TRACK_C
plyrUpdateTrackD:
		updateTrack SONG_TRACK_D

plyrUpdateTrackE:
		updateTrack SONG_TRACK_E
	
plyrPlayNoteA:	
		playNote SONG_TRACK_A
plyrPlayNoteB:	
		playNote SONG_TRACK_B
plyrPlayNoteC:	
		playNote SONG_TRACK_C
plyrPlayNoteD:	
		playNote SONG_TRACK_D
plyrPlayNoteE:	
		playNote SONG_TRACK_E

	
