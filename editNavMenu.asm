editNavMenu:
		lda PAD1_sel
		beq @noSel
	
@noSel:
		lda #$00
		sta navMenuCursorX
		lda writeScreen
		beq @a
		jsr writeNavMenuScreen
		dec writeScreen
		beq @a
		jsr writeNavMenuHeaderFooter
		lda #$01
		sta dmaUpdateHeader
		sta dmaUpdateTitle
		lda #$00
		sta writeScreen

@a:		;jsr globalKeys		;global keys
		lda writeScreen		;if mode has changed, this flag will be !=0
		beq @b
		jmp editNavMenuExit		;if changed, don't do any more keys
@b:		jsr processKeys
		
		;lda keysHoldSel
		lda keysHoldB
		bne @noJump

@aa:
		ldx editorModeIndex
		lda editorPreviousModes-1,x
		cmp navMenuCursorY
		bne @ab
		dec editorModeIndex
@ab:
		lda navMenuCursorY
		sta editorMode
		lda #$00
		;sta PAD1_sel
		sta keysHoldB
		;sta keysHoldSel
		lda #$02
		sta writeScreen
		lda #$00
		sta editBufferFlag
		jmp editNavMenuExit
		
@noJump:		lda #$01
		sta editBufferFlag
		jsr moveAroundEditor	;global routine for moving around editors
		
editNavMenuExit:
		updateCursor navMenuCursorX,navMenuCursorY,navMenuCursorColumns,navMenuCursorRows,navMenuColumnCursorType
		jmp editorLoop


writeNavMenuScreen:
		ldx #$00
		lda #CHR_SPACE
@a:		sta rowBuffer,x
		inx
		cpx #$20
		bcc @a

		ldy #$00
@b:		lda windowNavMenu,y
		sta windowBuffer,y
		iny
		cpy #(14 * 16)
		bcc @b
		rts

writeNavMenuHeaderFooter:
		ldx #$00			;write header and title bars to buffer
@c:		lda titleNavMenu,x
		sta titleBuffer,x
		lda headerNavMenu,x
		sta headerBuffer,x
		inx
		cpx #$11
		bne @c
		rts
		

navMenuCursorColumns:
		.REPEAT 1,i
		.BYTE $53+(11*8)
		.ENDREPEAT

navMenuCursorRows:
		.REPEAT navModeRows,i
		.BYTE $30 + (i*8)
		.ENDREPEAT

rowOffsetNavMenu:
		.REPEAT navModeRows,i
		.BYTE 14 + (i*14)
		.ENDREPEAT
			
columnOffsetNavMenu:
		.BYTE 0


		
;
;0 = no cursor, 1=8x8, 2=8x16, 3=8x24
;
navMenuColumnCursorType:
		.BYTE 2
		
