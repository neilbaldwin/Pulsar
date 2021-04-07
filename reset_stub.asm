	;.word 0,0,0, NMI, RESET, IRQ
		
	lda #$80
	sta $8000
	jmp RESET
	.word NMI,$FFF2,IRQ
