.feature force_range

	.include "pulsar.h"
	.include "common.h"

.segment "HEADER"
	.byte "NES",$1a 	; iNES identifier
	.byte $08		; Number of PRG-ROM blocks
	.byte $00		; Number of CHR-ROM blocks

	.IF SRAM_MAP=32
	.BYTE %00010010, %00001000
	.BYTE $00
	
	;.BYTE $01,$92
	.BYTE $00,$92
	
	.BYTE $07,$00,$00,$00,$00
	.ELSE
	.BYTE %00010010, %00000000
	.BYTE $00
	.BYTE $00,$02
	.BYTE $00,$00,$00,$00,$00	
	.ENDIF

.segment "CODE_00"
	.include "macros.asm"
	
	.include "editor.asm"
	.include "editSong.asm"
	.include "editChain.asm"
	.include "editPattern.asm"
	.include "editInstrument.asm"
	.include "editDrumKit.asm"
	.include "editEnvelopeTable.asm"
	.include "editPitchTable.asm"
	.include "editVibratoTable.asm"
	
.segment "RESET_00"
	.include "reset_stub.asm"