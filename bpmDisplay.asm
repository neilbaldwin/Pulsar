;--------------------------------------------------------------------------------						
; Calc BPM
;--------------------------------------------------------------------------------						
bpmX		= (13*8)+3
bpmY		= (26*8)
bpmSpacingX	= 8

;19, 20, 21, 22, 23
;24, 25, 26, 27, 28

initBPMDisplay:
		lda #bpmX
		sta SPR19_X
		sta SPR24_X
		clc
		adc #bpmSpacingX
		sta SPR20_X
		sta SPR25_X
		clc
		adc #bpmSpacingX
		sta SPR21_X
		sta SPR26_X
		clc
		adc #bpmSpacingX
		sta SPR22_X
		sta SPR27_X
		clc
		adc #bpmSpacingX
		sta SPR23_X
		sta SPR28_X
		
		lda #bpmY
		sta SPR19_Y
		sta SPR20_Y
		sta SPR21_Y
		sta SPR22_Y
		sta SPR23_Y
		clc
		adc #$08
		sta SPR24_Y
		sta SPR25_Y
		sta SPR26_Y
		sta SPR27_Y
		sta SPR28_Y
		
		lda #$03
		sta SPR19_ATTR
		sta SPR20_ATTR
		sta SPR21_ATTR
		sta SPR22_ATTR
		sta SPR23_ATTR
		sta SPR24_ATTR
		sta SPR25_ATTR
		sta SPR26_ATTR
		sta SPR27_ATTR
		sta SPR28_ATTR
		
		lda #$80
		sta SPR19_CHAR
		sta SPR20_CHAR
		sta SPR21_CHAR
		lda #$8A
		sta SPR22_CHAR
		lda #$80
		sta SPR23_CHAR
		lda #$90
		sta SPR24_CHAR
		sta SPR25_CHAR
		sta SPR26_CHAR
		lda #$9A
		sta SPR27_CHAR
		lda #$90
		sta SPR28_CHAR
		rts
		
editorDisplayBPM:	lda writeScreen
		beq @a
		rts
		
@a:		lda bpmCurrent
		asl a
		asl a
		;asl a
		clc
		adc #0
		tay
		lda bpmTable+1,y
		pha
		lsr a
		lsr a
		lsr a
		lsr a
		ora #$80
		sta SPR19_CHAR
		ora #$10
		sta SPR24_CHAR
		pla
		and #$0F
		ora #$80
		sta SPR20_CHAR
		ora #$10
		sta SPR25_CHAR

		lda bpmTable,y
		pha
		lsr a
		lsr a
		lsr a
		lsr a
		ora #$80
		sta SPR21_CHAR
		ora #$10
		sta SPR26_CHAR
				
		pla
		and #$0F
		ora #$80
		sta SPR23_CHAR
		ora #$10
		sta SPR28_CHAR		
		rts
				
		
bpmTable:
		.BYTE 00,00,00,00,00,00,00,00
		.BYTE 00,00,00,00,00,00,00,00
		;.BYTE 00,00,00,00,00,00,00,00
		;.BYTE 00,00,00,00,00,00,00,00
		.WORD $9015,$8013,$7212,$6556,$6010,$5548,$5151,$4808 
		.WORD $4508,$4242,$4007,$3796,$3606,$3434,$3278,$3136 
		.WORD $3005,$2885,$2774,$2671,$2576,$2487,$2404,$2326 
		.WORD $2254,$2185,$2121,$2061,$2003,$1949,$1898,$1849 
		.WORD $1803,$1759,$1717,$1677,$1639,$1603,$1568,$1534 
		.WORD $1503,$1472,$1442,$1414,$1387,$1361,$1336,$1311 
		.WORD $1288,$1265,$1243,$1222,$1202,$1182,$1163,$1145 
		.WORD $1127,$110A,$1093,$1076,$1061,$1045,$1030,$1016 
		.WORD $1002,$0988,$0975,$0962,$0949,$0937,$0925,$0913 
		.WORD $0902,$0890,$087A,$0869,$0859,$0848,$0839,$0829 
		.WORD $082A,$0810,$0801,$0793,$0784,$0775,$0767,$0759 
		.WORD $0751,$0744,$0736,$0728,$0721,$0714,$0707,$0700 
		.WORD $0693,$0687,$0680,$0674,$0668,$0662,$0656,$064A 
		.WORD $0644,$0638,$0633,$0627,$0622,$0616,$0611,$0606 
		.WORD $0601,$0596,$0591,$0586,$0582,$0577,$0572,$0568
	