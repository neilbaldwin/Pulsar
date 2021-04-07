;---------------------------------------------------------------
	.MACRO setdmapos _x,_y
_scnadd 	= SCREEN+(_y*$20)+_x
	lda #>_scnadd
	sta $2006
	lda #<_scnadd
	sta $2006
	.ENDMACRO
;---------------------------------------------------------------
; CODE
;---------------------------------------------------------------
	
RESET:	sei		
	ldx #$FF
  	txs        ; set the stack pointer
  	stx $8000  ; reset the mapper
	lda #%00010000		;WRAM bank 0?
	sta $Bfff
	lsr a
	sta $Bfff
	lsr a
	sta $Bfff
	lsr a
	sta $Bfff
	lsr a
	sta $Bfff

RESET2:	lda #$00
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

	;ldx #$FF			;reset stack pointer
	;txs
	;stx screenNumberOld
	
	
	;jsr resetMMC1
		
	lda #%00001100		;Set bank layout, H&V mirror, 16kb ROM at $C000. 8KB CHR
	jsr setMMC1r0

	lda #$00
	jsr setPRGBank
	lda #%00010000		;WRAM bank 0?
	jsr setMMC1r1
	

	jsr readPad1
	lda PAD1_sel
	beq @noClear
	.IF 1=1
	lda #%00010000		;WRAM bank 0?
	jsr setMMC1r1
	lda #$FF
	jsr clearWRAM
	
	lda #%00010100		;WRAM bank 1?
	jsr setMMC1r1
	lda #$01
	jsr clearWRAM

	lda #%00011000		;WRAM bank 2?
	jsr setMMC1r1
	lda #$02
	jsr clearWRAM

	lda #%00011100		;WRAM bank 3?
	jsr setMMC1r1
	lda #$03
	jsr clearWRAM

	lda #%00010000		;WRAM bank 0?
	jsr setMMC1r1
	.ENDIF

	jsr initPulsarData
@noClear:

		
	jsr initGraphics
	jsr clearSprites
	
	;lda #$01
	;jsr setPRGBank
	;jsr initPulsar
	;lda #$00
	;jsr setPRGBank
	
	lda #%10001000
	sta PPU0
	lda #%00011010
	sta PPU1	

mainLoop:	
	lda #$00
	jsr setPRGBank
	jsr initEditor
	jmp editorLoop
	jmp mainLoop

delay01:
	ldx #$04
	ldy #$00
@a:	dey
	bne @a
	dex
	bne @a
	rts
	
whiteBar:
	lda #%11111111
	sta PPU1

	jsr pulsarRefresh	
	
	lda #%00011110
	sta PPU1
	rts
	
NMI:	pha
	txa
	pha
	tya
	pha
	
	bit PPU_STATUS

	
	lda currentBank
	pha
	
	lda #$03
	jsr setPRGBank
	jsr debugNumbers
	jsr dmaPrimary
	jsr dmaSecondary


	lda #$FD			;use X scroll to move screen to left by 8 pixels
	sta $2005
	lda #$00
	sta $2005
	lda #$00
	sta $2006
	sta $2006
	jsr spriteDMA
	
	inc vblankFlag
	
	.IF 0=1
	lda #BANK_ENGINE
	jsr setPRGBank
	jsr whiteBar	
	jsr delay01
	jsr whiteBar	
	jsr delay01
	
	jsr whiteBar	
	jsr delay01
	jsr whiteBar
	jsr delay01
	jsr processController	;***TEMP***for audio 
	.ENDIF
	
		
		
	pla
	jsr setPRGBank

	;jsr readPad1
	
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

	.include "debug.asm"

debugPhex:pha
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

	lda #BANK_FIXED
	jsr setPRGBank
	
	lda #$3f
	ldx #$00
	sta $2006
	stx $2006
@a:	lda palette,x
	sta $2007
	inx
	cpx #$20
	bne @a
	rts


attributeTable:
	.BYTE $55,$55,$55,$55,$55,$55,$55,$55
	.BYTE $00,$00,$11,$00,$00,$00,$00,$00
	.BYTE $00,$00,$11,$00,$00,$00,$00,$00
	.BYTE $00,$00,$11,$00,$00,$00,$00,$00
	.BYTE $00,$00,$11,$00,$00,$00,$00,$00
	.BYTE $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
	;%0101-0101
	;.BYTE $FA,$FA,$FA,$FA,$FA,$FA,$BA,$EA
	.BYTE $FA,$FA,$FA,$FA,$FA,$FA,$BA,$EA
	.BYTE $5F,$5F,$4F,$0F,$4F,$0F,$4B,$0E

writeFont:	ldx #$10
	ldy #$00
@writeFont:	lda (tmp0),y
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
	;Flash palette
	lda #>$3F13
	sta $2006
	lda #<$3F13
	sta $2006
	lda cursorFlashColour
	sta $2007
	lda #$00
	sta $2006
	sta $2006
	rts
	

	

clearSprites:
	ldx #$00
@a:	lda #240
	sta SPR_Y,x
	lda #$C0
	sta SPR_CHAR,x
	lda #$00
	sta SPR_ATTR,x
	lda #$00
	sta SPR_X,x
	inx
	inx
	inx
	inx
	bne @a	
	rts

	
;---------------------------------------------------------------
; ENGINE CODE
;---------------------------------------------------------------
	.include "joypad.asm"

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
	sta currentBank
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
		