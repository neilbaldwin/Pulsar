	.include "macros.asm"

.import debugNumbers
.export dmaSecondary
	
HEADER_ROW	= 4
HEADER_COLUMN	= 8
WINDOW_ROW	= (HEADER_ROW+1)
WINDOW_COLUMN	= 8
TITLE_ROW		= 2;21;WINDOW_ROW+17
TITLE_COLUMN	= 6

;
;0 = no screen DMA
;1 = do both halves of window
;2 = do both halves of window & title
;3 = do both halves of window, header & title
;
; %00 window 0
; %01 window 1
; %10 title/header
; %11 
dmaPrimary:
	lda dmaCycleFlag
	clc
	adc #$01
	cmp #$03
	bcc @a
	lda #$00
@a:	sta dmaCycleFlag
	tay
	lda dmaJumpHi,y
	pha
	lda dmaJumpLo,y
	pha
	rts
	
dmaJumpHi:	.HIBYTES dmaWindow0-1,dmaWindow1-1,dmaWindow2-1
dmaJumpLo:	.LOBYTES dmaWindow0-1,dmaWindow1-1,dmaWindow2-1

dmaSpare:
	;jsr debugNumbers
	rts

	
dmaSecondary:
	lda dmaUpdateTitle
	beq @a
	lda #$00
	sta dmaUpdateTitle
	jmp dmaTitle
@a:	lda dmaUpdateHeader
	beq @b
	lda #$00
	sta dmaUpdateHeader
	jmp dmaHeader
@b:	jsr dmaPrimary
	

	lda copyInfoFlag
	bne dmaCopyInfo

	lda errorMessageFlag
	beq @noErrors
	jmp dmaErrors
@noErrors:
	setdmapos 8,23
	.REPEAT 5,i
	lda infoBuffer1+i
	sta $2007
	.ENDREPEAT

	setdmapos 8,24
	.REPEAT 5,i
	lda infoBuffer2+i
	sta $2007
	.ENDREPEAT
	rts
		
dmaCopyInfo:
	setdmapos 20,24
	.REPEAT 9,i
	lda copyInfoBuffer+i
	sta $2007
	.ENDREPEAT
	lda #$00
	sta copyInfoFlag
	rts
	
dmaErrors:
	setdmapos 09,22
	.REPEAT 16,i
	lda errorMessageBuffer+i
	sta $2007
	.ENDREPEAT
	lda #$00
	sta errorMessageFlag
	rts
	
	
dmaHeader:
	lda #>(SCREEN+(HEADER_ROW * 32) + HEADER_COLUMN)
	sta $2006
	lda #<(SCREEN+(HEADER_ROW  * 32) + HEADER_COLUMN)
	sta $2006
	.REPEAT 17,i
	lda headerBuffer+i
	sta $2007
	.ENDREPEAT
	rts	

dmaTitle:
	lda #>(SCREEN+(TITLE_ROW * 32) + TITLE_COLUMN)
	sta $2006
	lda #<(SCREEN+(TITLE_ROW * 32) + TITLE_COLUMN)
	sta $2006
	.REPEAT 17,i
	lda titleBuffer+i
	sta $2007
	.ENDREPEAT
	rts	

	.MACRO dmaWindowLine lineNum
	lda #>(SCREEN+((lineNum+WINDOW_ROW) * 32) + WINDOW_COLUMN)
	sta $2006
	lda #<(SCREEN+((lineNum+WINDOW_ROW) * 32) + WINDOW_COLUMN)
	sta $2006
	lda rowBuffer+(lineNum * 2)
	sta $2007
	lda rowBuffer+(lineNum * 2)+1
	sta $2007
	lda #CHR_SPACE
	sta $2007
	.REPEAT 14,i
	lda windowBuffer+(lineNum*14)+i
	sta $2007
	.ENDREPEAT
	.ENDMACRO

dmaWindow0:
	dmaWindowLine 0
	dmaWindowLine 1
	dmaWindowLine 2
	dmaWindowLine 3
	dmaWindowLine 4
	dmaWindowLine 5
	

	rts
;--------------------------------

dmaWindow1:
	dmaWindowLine 6
	dmaWindowLine 7
	dmaWindowLine 8
	dmaWindowLine 9
	dmaWindowLine 10	
	rts

dmaWindow2:

	dmaWindowLine 11
	dmaWindowLine 12
	dmaWindowLine 13
	dmaWindowLine 14
	dmaWindowLine 15

	rts
	
	
errorScreen:
	lda #<errorNameTable
	sta tmp0
	lda #>errorNameTable
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
	

	ldx #$00
	lda #$3f
	ldx #$00
	sta $2006
	stx $2006
@d:	lda palette,x
	sta $2007
	inx
	cpx #$20
	bne @d
		

	rts
	
errorNameTable:
	.incbin "nametables/booterror.nam"
	