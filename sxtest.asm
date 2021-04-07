
.segment "SRAM"
SRAM_TEST:	.RES 1
	
.segment "CODE_00"
.segment "CODE_01"
.segment "CODE_02"
.segment "CODE_03"
.segment "CODE_04"
.segment "CODE_05"
.segment "CODE_06"

.segment "CODE_FIXED"

reset:		lda #$78
		sta SRAM_TEST
		jmp reset

	
data:	.repeat 16,i
	.byte 16+i
	.endrepeat
	
nmi:	rti
irq:	rti

.segment "HEADER"
	.byte "NES",$1a 	; iNES identifier
	.byte $08		; Number of PRG-ROM blocks
	.byte $00		; Number of CHR-ROM blocks
	.byte %00010010, %00001000
	.byte $00,$00,$90,$07,$00,$00,$00,$00	; Filler

.segment "VECTORS"
	.word 0,0,0, nmi, reset, irq