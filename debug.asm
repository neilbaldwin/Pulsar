.export debugNumbers

debugNumbers:
	setdmapos 20,2
	lda plyrPatternVector+1
	jsr debugPhex
	lda #CHR_SPACE
	;sta $2007
	lda plyrPatternVector
	jsr debugPhex
	
	lda #CHR_SPACE
	sta $2007
	lda plyrCurrentPattern
	jsr debugPhex
	rts
	

	rts
