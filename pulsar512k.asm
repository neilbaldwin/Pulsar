;---------------------------------------------------------------
;---------------------------------------------------------------
; PULSAR
;---------------------------------------------------------------
;---------------------------------------------------------------	
SX256	= 0
SX512	= 1
	.include "pulsar.h"
	.include "macros.asm"

.segment "CODE_00"
	;.include "editor.asm"

.segment "CODE_01"
	.include "engine.asm"

.segment "CODE_02"
;font:	.incbin "set.chr"
;spr:	.incbin "spr.chr"
;layout:	.incbin "nametables/blank.nam"

.segment "CODE_03"
	;.include "screen.asm"

.segment "CODE_04"

.segment "CODE_05"

.segment "CODE_06"


	.IF SX512=1
.segment "CODE_07"
.segment "CODE_08"
.segment "CODE_09"
.segment "CODE_0A"
.segment "CODE_0B"
.segment "CODE_0C"
.segment "CODE_0D"
.segment "CODE_0E"
.segment "CODE_0F"
.segment "VECTORS2"
reset_stub:
	sei
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
	nop
	nop
	nop
  	jmp RESET2
	.word 0,0,0, NMI, reset_stub, IRQ

.segment "CODE_10"
	.include "editor.asm"

.segment "CODE_11"
.segment "CODE_12"
font:	.incbin "set.chr"
spr:	.incbin "spr.chr"
layout:	.incbin "nametables/blank.nam"
.segment "CODE_13"
	.include "screen.asm"
	
.segment "CODE_14"
.segment "CODE_15"
.segment "CODE_16"
.segment "CODE_17"
.segment "CODE_18"
.segment "CODE_19"
.segment "CODE_1A"
.segment "CODE_1B"
.segment "CODE_1C"
.segment "CODE_1D"
.segment "CODE_1E"
	.ENDIF
	
.segment "CODE_FIXED"

	.include "reset.asm"


.segment "HEADER"
	.byte "NES",$1a 	; iNES identifier
	.byte $20		; Number of PRG-ROM blocks
	.byte $00		; Number of CHR-ROM blocks
	.byte %00010010, %00001000
	.byte $00,$00,$90,$07,$00,$00,$00,$00	; Filler


.segment "VECTORS"
;	.word 0,0,0, NMI, RESET, IRQ
	sei
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
	nop
	nop
	nop
  	jmp RESET2
	.word 0,0,0, NMI, reset_stub, IRQ