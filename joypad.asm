;--------------------------------------------------------------------------------				
; JOYPAD READING
;--------------------------------------------------------------------------------				

		;
		;Scan joypad, returning dynamic & debounced values
		;
readPad1:		;rts
@a:		jsr @read_bits	;debounce joypad
		ldx PAD1_jt	;by waiting until the joypad returns
		jsr @read_bits	;two consecutive equal values
		cpx PAD1_jt
		bne @a

		txa		;extract bits into bytes
		ldx #$07
@b:		asl a
		ldy #$00
		bcc @c
		iny
@c:		sty <PAD1_jt,x
		dex
		bpl @b

		ldx PAD1_lr	;set PAD1_ud
		bne @d
		ldx PAD1_lr+1
		beq @d
		ldx #$ff
@d:		stx PAD1_ud

		ldx PAD1_jt	;set PAD1_lr
		bne @e
		ldx PAD1_jt+1
		beq @e
		ldx #$ff
@e:		stx PAD1_lr

		ldx #$05	;set debounced values
@f:		lda PAD1_lr,x
		beq @g
		cmp PAD1_oldlr,x
		beq @h
@g:		sta PAD1_oldlr,x
		.byte $2c
@h:		lda #$00
		sta PAD1_dlr,x
		dex
		bpl @f
		rts

@read_bits:	lda #$01
		sta PAD1_jt	;init for 8 reads
		sta $4016		;init I/O port for joystick read
		lsr a
		sta $4016
@i:		lda $4016		;serially read 8 2-bit values from I/O port
		and #$03		;%00=%0,%01=%1,%10=%1,%11=%1
		cmp #$01
		rol PAD1_jt
		bcc @i
		rts
