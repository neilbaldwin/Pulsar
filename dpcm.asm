;--------------------------------------------------------------------------------						
; DO NOT CHANGE: Macros to set start address and length value of each sample
;--------------------------------------------------------------------------------						

		.MACRO DEF_DPCM address
	 	;.BYTE <(address >> 6)
		.BYTE <(address / 64)
		.ENDMACRO
		
		.MACRO END_DPCM address
		;.BYTE <(address >> 6)
		.BYTE <(address / 64)
		.ENDMACRO

;--------------------------------------------------------------------------------
; Sample Address table
;
; Format: DEF_DPCM <sample label>,LOOPING or NOT_LOOPING
;         Need "END_DPCM dmcEnd" at end of table
;--------------------------------------------------------------------------------
.EXPORT dmcAddressTable
dmcAddressTable:
		DEF_DPCM dmcTR808_Kick		;0	Bank 0
		DEF_DPCM dmcTR808_Snare		;1
		DEF_DPCM dmcTR808_Clap		;2
		DEF_DPCM dmcTR808_CowBell	;3
		DEF_DPCM dmcTR808_RimShot	;4
		DEF_DPCM dmcTR909_Kick		;5		
		DEF_DPCM dmcTR909_Snare1	;6		
		DEF_DPCM dmcTR909_Snare2	;7
				
		DEF_DPCM dmcTR707_Kick		;0	Bank 1
		DEF_DPCM dmcTR707_Snare1	;1
		DEF_DPCM dmcTR707_Snare2	;2		
		DEF_DPCM dmcTR707_RimShot	;3
		DEF_DPCM dmcTR707_HiTom		;4
		DEF_DPCM dmcTR707_HandClap	;5
		DEF_DPCM dmcTR707_SnrClp	;6	;1
		END_DPCM dmcEnd


;--------------------------------------------------------------------------------
; Sample Data
;
; Format: <sample label> incbin <sample file name>
;         Need "dmcEnd:" at end of table
;--------------------------------------------------------------------------------		
		.ALIGN 64
dmcTR808_Kick:	.incbin "DPCM/TR808-Kick1.dmc"
dmcTR808_Snare:	.incbin "DPCM/TR808-Snare2.dmc"
dmcTR808_Clap:	.incbin "DPCM/TR808-clap.dmc"
dmcTR808_CowBell:	.incbin "DPCM/TR808-cowbell.dmc"
dmcTR808_RimShot:	.incbin "DPCM/TR808-rimshot.dmc"
dmcTR909_Kick:	.incbin "DPCM/TR909-Kick1.dmc"
dmcTR909_Snare1:	.incbin "DPCM/TR909-snare1.dmc"
dmcTR909_Snare2:	.incbin "DPCM/TR909-snare2.dmc"
dmcTR707_Kick:	.incbin "DPCM/TR707-Kick1.dmc"
dmcTR707_Snare1:	.incbin "DPCM/TR707-Snare1.dmc"
dmcTR707_Snare2:	.incbin "DPCM/TR707-Snare2.dmc"
dmcTR707_RimShot:	.incbin "DPCM/TR707-RimShot.dmc"
dmcTR707_HiTom:	.incbin "DPCM/TR707-HiTom.dmc"
dmcTR707_HandClap:	.incbin "DPCM/TR707-HandClap.dmc"
dmcTR707_SnrClp:	.incbin "DPCM/TR707-SnrClp1.dmc"
dmcEnd:
		

