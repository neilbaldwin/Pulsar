
;---------------------------------------------------------------
; ADSR Routine
;---------------------------------------------------------------

ENVELOPE_INIT_PHASE	= 5
ENVELOPE_ATTACK_PHASE = 4
ENVELOPE_DECAY_PHASE = 3
ENVELOPE_SUSTAIN_PHASE = 2
ENVELOPE_RELEASE_PHASE = 1
ENVELOPE_OFF_PHASE = 0

	.MACRO doADSR _track

;	.IF (_track=2)
;	lda envelopePhase+_track
;	beq @killC
;	lda #$81
;	sta envelopeAmp+_track
;	lda plyrInstrumentCopy + (_track * STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_GATE
;	beq @noKillC
;	cmp plyrNoteCounter+_track
;	bcs @noKillC
;	lda #$00
;@killC:	sta envelopeAmp+_track
;@noKillC:	rts
;	.ELSE

	lda #<SRAM_ENVELOPES
	sta plyrEnvelopeVector
	lda #>SRAM_ENVELOPES
	sta plyrEnvelopeVector+1

	.IF SRAM_MAP=32
	lda #SRAM_ENVELOPE_BANK
	jsr setMMC1r1
	.ENDIF
	
	ldy envelopePhase+_track		;get phase address (-1)
	lda @envelopePhasesHi,y		;and push onto stack for RTS trick
	pha
	lda @envelopePhasesLo,y
	pha
	lda plyrInstrumentCopy + (_track * STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_ENVELOPE
	asl a
	asl a
	clc
	adc envelopePhaseIndexes,y
	tay
	rts

@envelopePhasesLo:
	.LOBYTES @adsrOff-1,@adsrRelease-1,@adsrSustain-1,@adsrDecay-1,@adsrAttack-1,@adsrInit-1
@envelopePhasesHi:
	.HIBYTES @adsrOff-1,@adsrRelease-1,@adsrSustain-1,@adsrDecay-1,@adsrAttack-1,@adsrInit-1

	
@adsrInit:
	lda #$00			;initialise amplitude, counter		
	sta envelopeAmp+_track
	sta envelopeCounter+_track
	dec envelopePhase+_track		;then move to Attack phase
				;drop through

@adsrAttack:
	lda (plyrEnvelopeVector),y			;if Attack = 0, set max amp and move to Decay
	bne @attA
	dec envelopePhase+_track
	iny
	lda (plyrEnvelopeVector),y
	bne @attC
	iny
	lda (plyrEnvelopeVector),y
	sta envelopeAmp+_track
	rts
@attC:	lda #$0F
	sta envelopeAmp+_track
	rts
	
@attA:	clc			;otherwise, add Attack rate to counter
	adc envelopeCounter+_track
	sta envelopeCounter+_track
	lda envelopeAmp+_track		;if counter overflows, carry is set and the ADC #$00
	adc #$00			;will increment amplitude
	cmp #$10			;exceeded max (0F)?
	bcc @attB
	dec envelopePhase+_track		;yes, move to Decay		
	rts
@attB:	sta envelopeAmp+_track		;no, store new amplitude value
	rts


@adsrDecay:lda (plyrEnvelopeVector),y			;if Decay = 0, move to Sustain phase
	bne @decA
	iny
	lda (plyrEnvelopeVector),y
	sta envelopeAmp+_track
	dec envelopePhase+_track
	rts
	
@decA:	clc			;otherwise, add Decay speed to counter
	adc envelopeCounter+_track
	sta envelopeCounter+_track		;if counter overflow, carry is set
	ror a			;this time we need to subtract from amplitude
	eor #$80			;so use ROR A to push carry into bit 7
	asl a			;invert bit 7 and push back into carry
	lda envelopeAmp+_track		;so that SBC #$00 will subtract 1 if carry set after overflow
	sbc #$00
	iny
	cmp (plyrEnvelopeVector),y	;reached sustain?
	bcc @decB
	bmi @decB
	sta envelopeAmp+_track		;no, store new amplitude
	rts
@decB:	dec envelopePhase+_track		;yes, move to Sustain phase
	lda #$00			;and zero counter because it will be indeterminate at this point
	sta envelopeCounter+_track
	rts
	
@adsrSustain:			
	;lda gateTime		;if Gate Time = 0, sustain forever. In practicality, you'd
				;only use 0 gate time if you had a command to force the envelope
				;into the release phase, as in a MIDI Key Off command
	lda plyrInstrumentCopy + (_track * STEPS_PER_INSTRUMENT) + INSTRUMENT_ROW_GATE
	
	beq @susA		
	inc envelopeCounter+_track		;otherwise, increment counter until >= Gate Time
	cmp envelopeCounter+_track
	bcs @susA
	dec envelopePhase+_track	;the move to Release Phase
@susA:	rts
		
@adsrRelease:
	lda (plyrEnvelopeVector),y			;add Release speed to counter
	bne @relB
	lda #$00
	sta envelopeAmp+_track
	beq @relA
@relB:	clc
	adc envelopeCounter+_track
	sta envelopeCounter+_track
	ror a			;same trick as Decay, invert the carry and do a SBC #$00
	eor #$80
	asl a
	lda envelopeAmp+_track		
	sbc #$00
	beq @relA			;subtract 1 from amplitude until >=$00			
	sta envelopeAmp+_track
	rts
@relA:	dec envelopePhase+_track		;move to Off phase, envelope done
	rts
		
@adsrOff:
	lda #$00			;could replace with just "STY envelopAmp" becase Y=0 at this point
	sta envelopeAmp+_track
	rts
	;.ENDIF
	.ENDMACRO
