;---------------------------------------------------------------
; LOADING and SAVING stuff
;---------------------------------------------------------------
;.zp
;rleSource:		.RES 2
;rleDestination:		.RES 2

;.ram
;rleMode:			.RES 1
;rleTokenLength:		.RES 1
;rleToken:			.RES 8
;rleTokenBuffer:		.RES 8
;chunkCount:		.RES 2
;sourceCounter:		.RES 2

;rleSaveBuffer		= $0750 ;.RES $80

editorLoadSave:
		jsr editorClearSaveBuffer
		jsr editorCompressPatterns
		rts
	
editorCompressPatterns:
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		
		
		ldx #$00
@a:		lda rlePatternToken,x
		;sta SRAM_SAVE_BUFFER+1,x
		sta rleSaveBuffer+1,x
		sta rleToken,x
		inx
		cpx #(rlePatternTokenEnd-rlePatternToken)
		bcc @a
		;stx SRAM_SAVE_BUFFER
		stx rleSaveBuffer
		stx rleTokenLength
		
		lda #<SRAM_PATTERNS
		sta rleSource
		lda #>SRAM_PATTERNS
		sta rleSource+1
		
		;lda #<(SRAM_SAVE_BUFFER+$10)
		lda #<(rleSaveBuffer+$10)
		sta rleDestination
		;lda #>(SRAM_SAVE_BUFFER+$10)
		lda #>(rleSaveBuffer+$10)
		sta rleDestination+1
				
		lda #$00
		sta sourceCounter
		lda #$08
		sta sourceCounter+1
		
		lda #$00
		sta rleMode			;set initial mode to stream
		
		lda rleDestination			;save pointer
		sta tmp0
		lda rleDestination+1
		sta tmp1
	
		lda rleDestination			;move output point 2 bytes forward
		clc
		adc #$02
		sta rleDestination
		lda rleDestination+1
		adc #$00
		sta rleDestination+1

@readLoop2:	lda #$00
		sta chunkCount
		sta chunkCount+1

@readLoop:	lda rleMode
		bne @doingToken
		
		jsr rleReadBytes			;stream mode, read bytes
		bcc @notDone
		jmp @done
@notDone:		jsr rleMatchToken
		bcs @foundMatch0
		jsr rleWriteBytes			;no match, output bytes to stream
		lda chunkCount			;update size of current chunk
		clc
		adc rleTokenLength
		sta chunkCount
		lda chunkCount+1
		adc #$00
		sta chunkCount+1
		jmp @readLoop			;get more stuff

@foundMatch0:	lda chunkCount			;stream but found token match so end stream
		ora chunkCount+1
		beq @switchToToken			;if chunk size > 0 write chunk length to output
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		ldy #$00
		lda chunkCount
		sta (tmp0),y
		lda chunkCount+1
		iny
		ora #$80				;set bit 7 of length to signifiy stream
		sta (tmp0),y
		lda #$01
		sta rleMode			;change to token mode
		jsr rleUpdateOutputAddress
		lda #$01
		sta chunkCount
		lda #$00
		sta chunkCount+1
		jmp @readLoop			;get more data (jump to 0 chunk size)
		
@switchToToken:	lda #$01
		sta rleMode
		inc chunkCount
		bne @skip0
		inc chunkCount+1
@skip0:
		
@doingToken:	jsr rleReadBytes
		bcs @done
		jsr rleMatchToken
		bcc @noMatch
		inc chunkCount
		bne @skip1
		inc chunkCount+1
@skip1:		jmp @readLoop
		
@noMatch:		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		lda #$00
		sta $07FF
		ldy #$00
		lda chunkCount
		sta (tmp0),y
		lda chunkCount+1
		iny
		sta (tmp0),y
		lda #$00
		sta rleMode			;change to stream mode		
		jsr rleUpdateOutputAddress
		lda #$04
		sta chunkCount
		lda #$00
		sta chunkCount+1
		jmp @notDone
		
@done:		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		ldy #$00
		lda chunkCount
		sta (tmp0),y
		iny
		lda chunkCount+1
		sta (tmp0),y
		rts

rleUpdateOutputAddress:
		lda rleDestination
		sta tmp0
		lda rleDestination+1
		sta tmp1
		lda rleDestination
		clc
		adc #$02
		sta rleDestination
		lda rleDestination+1
		adc #$00
		sta rleDestination+1
		rts
		
		
rleWriteBytes:	lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		ldy #$00				;needs error check in case of run out of SRAM!
@writeLoop:	lda rleTokenBuffer,y
		sta (rleDestination),y
		iny
		cpy rleTokenLength
		bcc @writeLoop
		lda rleDestination
		clc
		adc rleTokenLength
		sta rleDestination
		lda rleDestination+1
		adc #$00
		sta rleDestination+1
		rts
		
rleReadBytes:	lda #SRAM_PATTERN_BANK
		jsr setMMC1r1
		ldy #$00
		lda sourceCounter
		ora sourceCounter+1
		bne @readMore
		sec				;set carry to say end of source
		rts
		
@readMore:	lda (rleSource),y
		sta rleTokenBuffer,y
		iny
		cpy rleTokenLength
		bcc @readMore
		lda rleSource			;adjust source data
		clc
		adc rleTokenLength
		sta rleSource
		lda rleSource+1
		adc #$00
		sta rleSource+1
		
		lda sourceCounter			;adjust source count
		sec
		sbc rleTokenLength
		sta sourceCounter
		lda sourceCounter+1
		sbc #$00
		sta sourceCounter+1
		clc				;clear carry to say read succesful
		rts

;		
;Return : Carry clear if no match, or carry set if match
;		
rleMatchToken:	ldy #$00
@matchLoop:	;lda (rleSource),y
		lda rleToken,y
		cmp rleTokenBuffer,y
		bne @noMatch
		iny
		cpy rleTokenLength
		bcc @matchLoop
		rts				;carry set
		
@noMatch:		clc
		rts
		


rlePatternToken:	.BYTE $FF,$FF,$FF,$00
rlePatternTokenEnd:
		
editorClearSaveBuffer:
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		ldx #$00
		lda #$34
@b:		sta rleSaveBuffer,x
		inx
		bpl @b
		rts
		
		.IF 0=1
		lda #<SRAM_SAVE_BUFFER
		sta tmp0
		lda #>SRAM_SAVE_BUFFER
		sta tmp1
		ldx #$0F
		ldy #$00
		lda #$34
@a:		sta (tmp0),y
		iny
		bne @a
		inc tmp1
		dex
		bpl @a
		rts
		.ENDIF
