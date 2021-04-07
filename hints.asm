hintTextA:	.incbin "nametables/hintA.bin"
hintTextB:	.incbin "nametables/hintB.bin"
hintTextC:	.incbin "nametables/hintC.bin"
hintTextD:	.incbin "nametables/hintD.bin"
hintTextE:	.incbin "nametables/hintE.bin"
hintTextF:	.incbin "nametables/hintF.bin"
hintTextG:	.incbin "nametables/hintG.bin"
hintTextH:	.incbin "nametables/hintH.bin"
hintTextI:	.incbin "nametables/hintI.bin"
hintTextJ:	.incbin "nametables/hintJ.bin"
hintTextK:	.incbin "nametables/hintK.bin"
hintTextL:	.incbin "nametables/hintL.bin"
hintTextM:	.incbin "nametables/hintM.bin"
hintTextN:	.incbin "nametables/hintN.bin"
hintTextO:	.incbin "nametables/hintO.bin"
hintTextP:	.incbin "nametables/hintP.bin"
hintTextQ:	.incbin "nametables/hintQ.bin"
hintTextR:	.incbin "nametables/hintR.bin"
hintTextS:	.incbin "nametables/hintS.bin"
hintTextT:	.incbin "nametables/hintT.bin"
hintTextU:	.incbin "nametables/hintU.bin"
hintTextV:	.incbin "nametables/hintV.bin"
hintTextW:	.incbin "nametables/hintW.bin"
hintTextX:	.incbin "nametables/hintX.bin"
hintTextY:	.incbin "nametables/hintY.bin"
hintTextZ:	.incbin "nametables/hintZ.bin"

hintAddressLo:	.LOBYTES hintTextA,hintTextB,hintTextC,hintTextD,hintTextE,hintTextF
		.LOBYTES hintTextG,hintTextH,hintTextI,hintTextJ,hintTextK,hintTextL
		.LOBYTES hintTextM,hintTextN,hintTextO,hintTextP,hintTextQ,hintTextR
		.LOBYTES hintTextS,hintTextT,hintTextU,hintTextV,hintTextW,hintTextX
		.LOBYTES hintTextY,hintTextZ
		

hintAddressHi:	.HIBYTES hintTextA,hintTextB,hintTextC,hintTextD,hintTextE,hintTextF
		.HIBYTES hintTextG,hintTextH,hintTextI,hintTextJ,hintTextK,hintTextL
		.HIBYTES hintTextM,hintTextN,hintTextO,hintTextP,hintTextQ,hintTextR
		.HIBYTES hintTextS,hintTextT,hintTextU,hintTextV,hintTextW,hintTextX
		.HIBYTES hintTextY,hintTextZ

hintFourteens:	.REPEAT 16,i
		.BYTE i*14
		.ENDREPEAT
	

.export hintFourteens, hintAddressLo, hintAddressHi