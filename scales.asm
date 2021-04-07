;Ionian (major)	: R,W,W,H,W,W,W
;Dorian		: R,W,H,W,W,W,H
;Phrygian	: R,H,W,W,W,H,W
;Lydian		: R,W,W,W,H,W,W
;Mixolydian	: R,W,W,H,W,W,H
;Aeolian (minor)	: R,W,H,W,W,H,W
;Melodic Minor	: R,W,H,W,W,W,W
;Harmonic Minor	: R,W,H,W,W,H,W+
;Locrian		: R,H,W,W,H,W,W
;Whole Tone	: R,W,W,W,W,W,W
;Gypsy		: R,W,H,W+,H,H,W+
;Pentatonic	: R,W,W+,W,W (5)
;Octatonic	: R,H,W,H,W,H,W
;Blues		: R,W,H,H,H,H,H,W,H,H (10)


scaleTablesLo:
		.LOBYTES ionianScale,dorianScale,phrygianScale,lydianScale
		.LOBYTES mixolydianScale,aeolianScale,melodicMinorScale,harmonicMinorScale
		.LOBYTES locrianScale,wholeTone,pentatonicScale,octatonicScale,gypsyScale
scaleTablesHi:
		.HIBYTES ionianScale,dorianScale,phrygianScale,lydianScale
		.HIBYTES mixolydianScale,aeolianScale,melodicMinorScale,harmonicMinorScale
		.HIBYTES locrianScale,wholeTone,pentatonicScale,octatonicScale,gypsyScale

ionianScale:		.BYTE 0,2,4,5,7,9,11
dorianScale:		.BYTE 0,2,3,5,7,9,11
phrygianScale:		.BYTE 0,1,3,5,7,8,10
lydianScale:		.BYTE 0,2,4,6,7,9,11
mixolydianScale:		.BYTE 0,2,4,5,7,9,10
aeolianScale:		.BYTE 0,2,3,5,7,8,10
melodicMinorScale:		.BYTE 0,2,3,5,7,9,11
harmonicMinorScale:		.BYTE 0,2,3,5,7,8,11
locrianScale:		.BYTE 0,1,3,5,6,8,10
wholeTone:		.BYTE 0,2,4,6,8,10,12
pentatonicScale:		.BYTE 0,2,5,7,9,12,14
octatonicScale:		.BYTE 0,1,3,4,6,7,9
gypsyScale:		.BYTE 0,2,3,6,7,8,11
			
	