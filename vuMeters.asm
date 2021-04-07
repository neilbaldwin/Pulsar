vuX = (13*8) +3
vuY = 23*8
vuXSpacing = 8
vuDecay = $C0
statusLightsX = (13*8)+3
statusLightsY = 25*8

;A/B C/D E/F 10/11 12/13
initVuMeters:	;rts
		lda #vuX
		sta SPR0A_X
		sta SPR0B_X
		clc
		adc #vuXSpacing
		sta SPR0C_X
		sta SPR0D_X
		clc
		adc #vuXSpacing
		sta SPR0E_X
		sta SPR0F_X
		clc
		adc #vuXSpacing
		sta SPR10_X
		sta SPR11_X
		clc
		adc #vuXSpacing
		sta SPR12_X
		sta SPR13_X
		
		lda #vuY
		sta SPR0A_Y
		clc
		adc #$08
		sta SPR0B_Y
		lda #vuY
		sta SPR0C_Y
		clc
		adc #$08
		sta SPR0D_Y
		lda #vuY
		sta SPR0E_Y
		clc
		adc #$08
		sta SPR0F_Y
		lda #vuY
		sta SPR10_Y
		clc
		adc #$08
		sta SPR11_Y
		lda #vuY
		sta SPR12_Y
		clc
		adc #$08
		sta SPR13_Y
				
		lda #$03
		sta SPR0A_ATTR
		sta SPR0B_ATTR
		sta SPR0C_ATTR
		sta SPR0D_ATTR
		sta SPR0E_ATTR
		sta SPR0F_ATTR
		sta SPR10_ATTR
		sta SPR11_ATTR
		sta SPR12_ATTR
		sta SPR13_ATTR
		
		lda #$00
		sta vuIndex
		sta vuIndex+1
		sta vuIndex+2
		sta vuIndex+3
		sta vuIndex+4
		
		ldy #statusLightsY
		lda #statusLightsX
		sty SPR14_Y
		sta SPR14_X
		clc
		adc #$08
		sty SPR15_Y
		sta SPR15_X
		clc
		adc #$08
		sty SPR16_Y
		sta SPR16_X
		clc
		adc #$08
		sty SPR17_Y
		sta SPR17_X
		clc
		adc #$08
		sty SPR18_Y
		sta SPR18_X
		
		lda #$0A
		sta SPR14_CHAR
		sta SPR15_CHAR
		sta SPR16_CHAR
		sta SPR17_CHAR
		sta SPR18_CHAR
		
		lda #$02
		sta SPR14_ATTR
		sta SPR15_ATTR
		sta SPR16_ATTR
		sta SPR17_ATTR
		sta SPR18_ATTR
		
		rts

vuCharsTop:	.BYTE $68,$67,$66,$65,$64,$63,$62,$61,$60
vuCharsBot:	.BYTE $78,$77,$76,$75,$74,$73,$72,$71,$70

CHR_GREEN_LIGHT	= $08
CHR_GREY_LIGHT	= $09
CHR_RED_LIGHT	= $0A
CHR_RED_OFF_LIGHT	= $0B

updateStatusLights:

		lda soloLightCounter
		clc
		adc #$10
		sta soloLightCounter
		bcc @noFlash
		inc soloLightChar
@noFlash:
		lda #CHR_GREY_LIGHT
		sta SPR14_CHAR
		sta SPR15_CHAR
		sta SPR16_CHAR
		sta SPR17_CHAR
		sta SPR18_CHAR
		
		ldy editorCurrentSong
		lda SRAM_SONG_SOLO,y
		bmi @noSolo
		asl a
		asl a
		tax
		lda soloLightChar
		and #$01
		clc
		adc #CHR_RED_LIGHT
		sta SPR14_CHAR,x
		jmp @x
		
@noSolo:		ldx #CHR_GREEN_LIGHT
		lda SRAM_SONG_MUTE,y
		lsr a
		bcs @a
		stx SPR14_CHAR
@a:		lsr a
		bcs @b
		stx SPR15_CHAR
@b:		lsr a
		bcs @c
		stx SPR16_CHAR
@c:		lsr a
		bcs @d
		stx SPR17_CHAR
@d:		lsr a
		bcs @e
		stx SPR18_CHAR
@e:				

@x:		rts
		

updateVuMeters:	;rts
		.IF SRAM_MAP=32
		lda #SRAM_HEADER_BANK
		jsr setMMC1r1
		.ENDIF
		lda writeScreen
		beq @ok
		rts
	

@ok:		jsr updateStatusLights
	
		ldx #$00
@c:
		lda vuIndex,x
		tay
		lda vuCharsBot,y
		pha
		lda vuCharsTop,y
		pha
		txa
		asl a
		asl a
		asl a
		tay
		pla
		sta SPR0A_CHAR,y
		pla
		sta SPR0B_CHAR,y
		
		lda vuIndex,x
		beq @a
		
		lda vuCounter,x
		clc
		adc #vuDecay
		sta vuCounter,x
		bcc @a
		
		dec vuIndex,x
		
@a:		txa
		asl a
		asl a
		tay
		cpx #$02
		beq @a0
		cpx #$04
		beq @a0
		lda V_APU,y
		and #$0F
		lsr a
		bpl @a1
@a0:		lda plyrNoteCounter,x
		bne @b
		;lda plyrDpcmMuted
		;bne @b
		lda #$08
@a1:		sta vuIndex,x
@b:		
		ldy editorCurrentSong
		lda SRAM_SONG_MUTE,y
		and SetBits,x
		beq @noMute
		lda #$00
		sta vuIndex,x
@noMute:		lda SRAM_SONG_SOLO,y
		bmi @noSolo
		txa
		cmp SRAM_SONG_SOLO,y
		beq @noSolo
		lda #$00
		sta vuIndex,x
@noSolo:

		inx
		cpx #$05
		bcc @c
		rts
		