		.include "pulsar.h"


;---------------------------------------------------------------
; ZP RAM
;---------------------------------------------------------------
		
.segment "ZEROPAGE"
DO_NOT_INTERRUPT:	.RES 1
currentPrgBank:	.RES 1
currentSramBank:	.RES 1
vblankFlag:	.RES 1
vblankFlagOld:	.RES 1
vblankOverflow:	.RES 1
dmaCycleFlag:	.RES 1

tmp0:		.RES 1
tmp1:		.RES 1
tmp2:		.RES 1
tmp3:		.RES 1
tmp4:		.RES 1
tmp5:		.RES 1

engineTmp0:	.RES 1
engineTmp1:	.RES 1
engineTmp2:	.RES 1
engineTmp3:	.RES 1

PAD1_jt:		.RES 2

PAD1_lr:		.RES 1
PAD1_ud:		.RES 1
PAD1_str:		.RES 1
PAD1_sel:		.RES 1
PAD1_fireb:	.RES 1
PAD1_firea:	.RES 1

PAD1_oldlr:	.RES 6

PAD1_dlr:		.RES 1
PAD1_dud:		.RES 1
PAD1_dsta:	.RES 1
PAD1_dsel:	.RES 1
PAD1_dfireb:	.RES 1
PAD1_dfirea:	.RES 1



songVectors:	.RES 5*2

screenVector:	.RES 2
editorVector:	.RES 2
trackVector:	.RES 2
chainVector:	.RES 2
patternVector:	.RES 2
instrumentVector:	.RES 2
drumkitVector:	.RES 2
tableVector:	.RES 2
vibratoVector:	.RES 2
dutyVector:	.RES 2
echoVector:	.RES 2
speedVector:	.RES 2
fxVector:		.RES 2

plyrTrackVector:	.RES 5*2
plyrChainVector:	.RES 5*2
plyrPatternVector:	.RES 5*2
plyrInstrumentVector:	.RES 5*2
plyrEnvelopeVector:	.RES 2
plyrDutyVector:	.RES 2
plyrTableVector:	.RES 2
plyrSpeedVector:	.RES 2
plyrFxVector:	.RES 2

copyBufferVector:	.RES 2

lfsr:		.RES 1

plyrFxTemp1:		.RES 1
plyrFxTemp2:		.RES 1
plyrFxDataTemp1:		.RES 1
plyrFxDataTemp2:		.RES 1
plyrFxTempIndex:		.RES 1

plyrInstrumentCopy:
plyrInstrumentCopyA:	.RES STEPS_PER_INSTRUMENT
plyrInstrumentCopyB:	.RES STEPS_PER_INSTRUMENT
plyrInstrumentCopyC:	.RES STEPS_PER_INSTRUMENT
plyrInstrumentCopyD:	.RES STEPS_PER_INSTRUMENT

;---------------------------------------------------------------
; RAM
;---------------------------------------------------------------
		
.segment "RAM"
sprBuf:		.include "spr_vars.asm"
		
debug0:		.RES 1
debug1:		.RES 1
debug2:		.RES 1
debug3:		.RES 1
editorMode:	.RES 1
editorModeIndex:	.RES 1
editorPreviousModes: .RES $10

hintMode:		.RES 1
cursorFlashIndex:	.RES 1
cursorFlashColour:	.RES 1

editorCurrentSong:	.RES 1
editorCurrentTrack:	.RES 1
editorCurrentChain:	.RES 1
editorCurrentPattern: .RES 1
editorCurrentInstrument: .RES 1
editorCurrentDrumkit: .RES 1
editorCurrentEnvelope: .RES 1
editorCurrentTable:	.RES 1
editorCurrentVibrato:	.RES 1
editorCurrentDuty:	.RES 1
editorCurrentEcho:	.RES 1
editorCurrentSpeed:	.RES 1
editorCurrentFx:	.RES 1

editPatternTie:	.RES 1

songTrackIndex:	.RES 1
editChainIndex:	.RES 1
envelopeIndex:	.RES 1
vibratoIndex:	.RES 1
echoIndex:	.RES 1

editorLastValues:
editSongLastValue:	.RES TRACKS_PER_SONG
editChainLastValue:	.RES BYTES_PER_CHAIN_STEP
editPatternLastValue: .RES BYTES_PER_PATTERN_STEP
editDrumkitLastValue: .RES (BYTES_PER_DRUMKIT_STEP+1)
editEnvelopeLastValue:	.RES BYTES_PER_ENVELOPE
editTableLastValue:	.RES BYTES_PER_TABLE_STEP
editVibratoLastValue:	.RES BYTES_PER_VIBRATO
editDutyLastValue:	.RES BYTES_PER_DUTY_TABLE_STEP+1
editEchoLastValue:	.RES BYTES_PER_ECHO
editSpeedLastValue:	.RES BYTES_PER_SPEED_TABLE_STEP
editFxLastValue:	.RES BYTES_PER_FX_TABLE_STEP
editorLastValuesEnd:

editBuffer:	.RES 1
editBufferFlag:	.RES 1
editNavFlag:	.RES 1

editorKeys:

keysHoldCounterB:	.RES 1
keysTapCounterB:	.RES 1
keysTapB:		.RES 1
keysDoubleTapB:	.RES 1
keysHoldB:		.RES 1

keysHoldCounterA:	.RES 1
keysTapCounterA:	.RES 1
keysTapA:		.RES 1
keysDoubleTapA:	.RES 1
keysHoldA:		.RES 1

keysHoldCounterSel:	.RES 1
keysTapCounterSel:	.RES 1
keysTapSel:	.RES 1
keysDoubleTapSel:	.RES 1
keysHoldSel:	.RES 1

keysRepeatUD:	.RES 1
keysRepeatOldUD:	.RES 1
keysRepeatRateUD:	.RES 1
keysRepeatCounterUD:	.RES 1

keysRepeatLR:	.RES 1
keysRepeatOldLR:	.RES 1
keysRepeatRateLR:	.RES 1
keysRepeatCounterLR:	.RES 1

PAD1_firea_old:	.RES 1
PAD1_fireb_old:	.RES 1
PAD1_sel_old:	.RES 1

editorKeysEnd:


windowBuffer:	.RES 256
titleBuffer:	.RES 17
headerBuffer:	.RES 17
rowBuffer:		.RES 32
infoBuffer1:	.RES 5
infoBuffer2:	.RES 5
copyInfoBuffer:	.RES 9
errorMessageBuffer:	.RES 16
errorMessageFlag:	.RES 1
copyInfoFlag:	.RES 1
writeScreen:	.RES 1

dmaUpdateWindow:	.RES 1
dmaUpdateHeader:	.RES 1
dmaUpdateTitle:	.RES 1

songCursorX:	.RES 1
chainCursorX:	.RES 1
patternCursorX:	.RES 1
instrumentCursorX:	.RES 1
drumkitCursorX:	.RES 1
envelopeCursorX:	.RES 1
tableCursorX:	.RES 1
vibratoCursorX:	.RES 1
dutyCursorX:	.RES 1
echoCursorX:	.RES 1
speedCursorX:	.RES 1
fxCursorX:	.RES 1
setupCursorX:	.RES 1
navMenuCursorX:	.RES 1

songCursorY:	.RES 1
chainCursorY:	.RES 1
patternCursorY:	.RES 1
instrumentCursorY:	.RES 1
drumkitCursorY:	.RES 1
envelopeCursorY:	.RES 1
tableCursorY:	.RES 1
vibratoCursorY:	.RES 1
dutyCursorY:	.RES 1
echoCursorY:	.RES 1
speedCursorY:	.RES 1
fxCursorY:	.RES 1
setupCursorY:	.RES 1
navMenuCursorY:	.RES 1

songFirstRow:	.RES 1
chainFirstRow:	.RES 1
patternFirstRow:	.RES 1
instrumentFirstRow:	.RES 1
drumkitFirstRow:	.RES 1
envelopeFirstRow:	.RES 1
tableFirstRow:	.RES 1
vibratoFirstRow:	.RES 1
dutyFirstRow:	.RES 1
echoFirstRow:	.RES 1
speedFirstRow:	.RES 1
fxFirstRow:	.RES 1
setupFirstRow:	.RES 1
navFirstRow:	.RES 1

drumkitCursorX_old:	.RES 1

blockMode:	.RES 1
blockOrigin:	.RES 1
blockStart:	.RES 1
blockEnd:		.RES 1

;---------------------------------------------------------------
; Player Variables
;---------------------------------------------------------------

plyrPlaying:		.RES 1

plyrSongStartIndex:		.RES 1

plyrTrackIndex:		.RES 5

plyrPatternIndex:		.RES 5

plyrPatternStepCounter:	.RES 5

plyrPatternJump:		.RES 5

plyrChainIndex:		.RES 5

plyrCurrentChain:		.RES 5

plyrCurrentChainTranspose:	.RES 5

plyrCurrentInstrument:	.RES 5

plyrCurrentNote:		.RES 5

plyrNoteCounter:		.RES 5

plyrCurrentPattern:		.RES 5

plyrCurrentPatternFX:	.RES 5

plyrCurrentPatternFXData:	.RES 5


plyrInstrumentCopyE:	.RES STEPS_PER_DRUMKIT * BYTES_PER_DRUMKIT_STEP

envelopeCounter:		.RES 4
envelopePhase:		.RES 4
envelopeAmp:		.RES 4
			
noteNumber:		.RES 5

noteAddFrac:		.RES 3
noteAddNote:		.RES 4

pitchLo:			.RES 5
pitchHi:			.RES 5
pitchHiOld:		.RES 2
pitchLoOld:		.RES 2

plyrPitchSweepDelta:	.RES 3
plyrPitchSweepLo:		.RES 3

plyrCurrentDuty:		.RES 2
plyrDutyIndex:		.RES 2
plyrDutyTableDelay:		.RES 2

plyrTableVolume:		.RES 4
plyrTablePitch:		.RES 4
plyrTableIndex:		.RES 5
plyrTableSpeed:		.RES 5
plyrTableCounter:		.RES 5
plyrTableJump:		.RES 5
plyrTableDoStep:		.RES 5

plyrTableTrackE:		.RES 1


plyrFxType:		.RES 1	;0 = pattern, 1 = table

patternLastNote:		.RES 1

plyrCurrentSpeedTable:	.RES 1
plyrSpeedTableIndex:	.RES 1

plyrChordNotes:		.RES 4

plyrPatternChordIndex:	.RES 4
plyrPatternChordCounter:	.RES 4
plyrPatternChordNote:	.RES 4

getNoteTemp0:		.RES 1
getNoteTemp1:		.RES 1

plyrKillCounter:		.RES 5
plyrDelayNoteCounter:	.RES 5
plyrDelayNote:		.RES 5

plyrVibPos:		.RES 3
plyrVibSpeedCounter:	.RES 3
plyrVibDelta:		.RES 3
plyrVibLastDelta:		.RES 3
plyrVibSpeedLo:		.RES 3
plyrVibDepthMod:		.RES 3
plyrVibDepthModCounter:	.RES 3

plyrSlideSpeed:		.RES 3
plyrSlideDestination:	.RES 3
plyrPreviousNote:		.RES 3

plyrDetuneHi:		.RES 3
		
V_APU:			.RES 16

dpcmStart:		.RES 1
dpcmLength:		.RES 1
dpcmPitch:		.RES 1
dpcmDC:			.RES 1
plyrDpcmOn:		.RES 1
plyrDpcmMuted:		.RES 1

plyrKeyOn:		.RES 5

vuIndex:			.RES 5
vuCounter:		.RES 5

plyrRetriggerSpeed:		.RES 5
plyrRetriggerCounter:	.RES 5

pulsarPassCounter:		.RES 1
pulsarIntensity:		.RES 5

copyBufferObjectType:	.RES 1
copyBufferObject:		.RES 1
copyBufferStartIndex:	.RES 1
copyBufferLength:		.RES 1
copyBuffer:		.RES (STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP)

soloLightCounter:		.RES 1
soloLightChar:		.RES 1

plyrPlayMode:		.RES 1
errorMessageNumber:		.RES 1
errorCounter:		.RES 1

waitForTapA:		.RES 1
editorPlayingNote:		.RES 1
writePaletteFlag:		.RES 1

plyrFxTable:		.RES 1
plyrFxTableCounter:		.RES 1
plyrFxTableIndex:		.RES 1
plyrFxTableSpeed:		.RES 1
plyrFxTableVoice:		.RES 1

bpmBeatCounter:		.RES 1
bpmFrameCounter:		.RES 1
bpmCurrent:		.RES 1

			.IF SRAM_MAP=32
			.IF ENABLE_ECHO=1
plyrEchoIndex:		.RES 4
plyrEchoSpeed:		.RES 4
plyrEchoInitAttn:		.RES 4
plyrEchoAttn:		.RES 4
plyrEchoCounter:		.RES 4
			.ENDIF
			.ENDIF

old_V_APUA:	.RES 1
old_V_APUB:	.RES 1

		.IF SRAM_MAP=32
;------------------------------------------------------------------------------
; SRAM MAP FOR 32K
;------------------------------------------------------------------------------
SRAM		= $6000

.segment "SRAM0"
SRAM_HEADER:	.RES SIZE_OF_HEADER
SRAM_PALETTE:	.RES 32
SRAM_CHAIN_FLAGS:	.RES NUMBER_OF_CHAINS	;flags for used/unused chains
SRAM_PATTERN_FLAGS:	.RES NUMBER_OF_PATTERNS	;flags for used/unused patterns

		.ALIGN 16
SRAM_TRACK_A0:	.RES STEPS_PER_TRACK
SRAM_TRACK_B0:	.RES STEPS_PER_TRACK
SRAM_TRACK_C0:	.RES STEPS_PER_TRACK
SRAM_TRACK_D0:	.RES STEPS_PER_TRACK
SRAM_TRACK_E0:	.RES STEPS_PER_TRACK

SRAM_TRACK_A1:	.RES STEPS_PER_TRACK
SRAM_TRACK_B1:	.RES STEPS_PER_TRACK
SRAM_TRACK_C1:	.RES STEPS_PER_TRACK
SRAM_TRACK_D1:	.RES STEPS_PER_TRACK
SRAM_TRACK_E1:	.RES STEPS_PER_TRACK

SRAM_TRACK_A2:	.RES STEPS_PER_TRACK
SRAM_TRACK_B2:	.RES STEPS_PER_TRACK
SRAM_TRACK_C2:	.RES STEPS_PER_TRACK
SRAM_TRACK_D2:	.RES STEPS_PER_TRACK
SRAM_TRACK_E2:	.RES STEPS_PER_TRACK

SRAM_TRACK_A3:	.RES STEPS_PER_TRACK
SRAM_TRACK_B3:	.RES STEPS_PER_TRACK
SRAM_TRACK_C3:	.RES STEPS_PER_TRACK
SRAM_TRACK_D3:	.RES STEPS_PER_TRACK
SRAM_TRACK_E3:	.RES STEPS_PER_TRACK

SRAM_TRACK_A4:	.RES STEPS_PER_TRACK
SRAM_TRACK_B4:	.RES STEPS_PER_TRACK
SRAM_TRACK_C4:	.RES STEPS_PER_TRACK
SRAM_TRACK_D4:	.RES STEPS_PER_TRACK
SRAM_TRACK_E4:	.RES STEPS_PER_TRACK

SRAM_TRACK_A5:	.RES STEPS_PER_TRACK
SRAM_TRACK_B5:	.RES STEPS_PER_TRACK
SRAM_TRACK_C5:	.RES STEPS_PER_TRACK
SRAM_TRACK_D5:	.RES STEPS_PER_TRACK
SRAM_TRACK_E5:	.RES STEPS_PER_TRACK

SRAM_TRACK_A6:	.RES STEPS_PER_TRACK
SRAM_TRACK_B6:	.RES STEPS_PER_TRACK
SRAM_TRACK_C6:	.RES STEPS_PER_TRACK
SRAM_TRACK_D6:	.RES STEPS_PER_TRACK
SRAM_TRACK_E6:	.RES STEPS_PER_TRACK

SRAM_TRACK_A7:	.RES STEPS_PER_TRACK
SRAM_TRACK_B7:	.RES STEPS_PER_TRACK
SRAM_TRACK_C7:	.RES STEPS_PER_TRACK
SRAM_TRACK_D7:	.RES STEPS_PER_TRACK
SRAM_TRACK_E7:	.RES STEPS_PER_TRACK

SRAM_SPEED_TABLES:	.RES NUMBER_OF_SPEED_TABLES * STEPS_PER_SPEED_TABLE * BYTES_PER_SPEED_TABLE_STEP
SRAM_SONG_SPEEDS:	.RES NUMBER_OF_SONGS
SRAM_SONG_MUTE:	.RES NUMBER_OF_SONGS
SRAM_SONG_SOLO:	.RES NUMBER_OF_SONGS
		
.segment "SRAM1"
SRAM_CHAINS:	.RES (NUMBER_OF_CHAINS * STEPS_PER_CHAIN * BYTES_PER_CHAIN_STEP)
SRAM_INSTRUMENTS:	.RES (NUMBER_OF_INSTRUMENTS * STEPS_PER_INSTRUMENT * BYTES_PER_INSTRUMENT_STEP)
SRAM_ENVELOPES:	.RES NUMBER_OF_ENVELOPES * BYTES_PER_ENVELOPE
SRAM_VIBRATOS:	.RES NUMBER_OF_VIBRATOS * BYTES_PER_VIBRATO
SRAM_DUTY_TABLES:	.RES NUMBER_OF_DUTY_TABLES * STEPS_PER_DUTY_TABLE * BYTES_PER_DUTY_TABLE_STEP
SRAM_ECHOES:	.RES NUMBER_OF_ECHOES * BYTES_PER_ECHO
		.IF ENABLE_ECHO=1
plyrEchoBuffer03_A:	.RES SIZE_OF_ECHO_BUFFER
plyrEchoBuffer02_A:	.RES SIZE_OF_ECHO_BUFFER
plyrEchoBuffer00_A:	.RES SIZE_OF_ECHO_BUFFER
plyrEchoBuffer03_B:	.RES SIZE_OF_ECHO_BUFFER
plyrEchoBuffer02_B:	.RES SIZE_OF_ECHO_BUFFER
plyrEchoBuffer00_B:	.RES SIZE_OF_ECHO_BUFFER
plyrEchoBuffer02_D:	.RES SIZE_OF_ECHO_BUFFER
plyrEchoBuffer00_D:	.RES SIZE_OF_ECHO_BUFFER
		.ENDIF
		
.segment "SRAM2"
SRAM_TABLES:	.RES NUMBER_OF_TABLES * STEPS_PER_TABLE * BYTES_PER_TABLE_STEP
SRAM_FX_TABLES:	.RES NUMBER_OF_FX_TABLES * STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP
SRAM_DRUMKITS:	.RES (NUMBER_OF_DRUMKITS * STEPS_PER_DRUMKIT * BYTES_PER_DRUMKIT_STEP)
SRAM_DRUMKIT_ROOTS:	.RES NUMBER_OF_DRUMKITS
		
.segment "SRAM3"
SRAM_PATTERNS:	.RES (NUMBER_OF_PATTERNS * STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP)


		.ELSE
;------------------------------------------------------------------------------
; SRAM MAP FOR 8K
;------------------------------------------------------------------------------
		
.segment "SRAM0"

SRAM:
SRAM_HEADER:	.RES SIZE_OF_HEADER
SRAM_PALETTE:	.RES 32
SRAM_CHAIN_FLAGS:	.RES NUMBER_OF_CHAINS	;flags for used/unused chains
SRAM_PATTERN_FLAGS:	.RES NUMBER_OF_PATTERNS	;flags for used/unused patterns
SRAM_TRACK_A0:	.RES STEPS_PER_TRACK
SRAM_TRACK_B0:	.RES STEPS_PER_TRACK
SRAM_TRACK_C0:	.RES STEPS_PER_TRACK
SRAM_TRACK_D0:	.RES STEPS_PER_TRACK
SRAM_TRACK_E0:	.RES STEPS_PER_TRACK
SRAM_PATTERNS:	.RES (NUMBER_OF_PATTERNS * STEPS_PER_PATTERN * BYTES_PER_PATTERN_STEP)
SRAM_CHAINS:	.RES (NUMBER_OF_CHAINS * STEPS_PER_CHAIN * BYTES_PER_CHAIN_STEP)
SRAM_INSTRUMENTS:	.RES (NUMBER_OF_INSTRUMENTS * STEPS_PER_INSTRUMENT * BYTES_PER_INSTRUMENT_STEP)
SRAM_DRUMKITS:	.RES (NUMBER_OF_DRUMKITS * STEPS_PER_DRUMKIT * BYTES_PER_DRUMKIT_STEP)
SRAM_DRUMKIT_ROOTS:	.RES NUMBER_OF_DRUMKITS
SRAM_ENVELOPES:	.RES NUMBER_OF_ENVELOPES * BYTES_PER_ENVELOPE
SRAM_TABLES:	.RES NUMBER_OF_TABLES * STEPS_PER_TABLE * BYTES_PER_TABLE_STEP
SRAM_VIBRATOS:	.RES NUMBER_OF_VIBRATOS * BYTES_PER_VIBRATO
SRAM_DUTY_TABLES:	.RES NUMBER_OF_DUTY_TABLES * STEPS_PER_DUTY_TABLE * BYTES_PER_DUTY_TABLE_STEP
SRAM_ECHOES:	.RES NUMBER_OF_ECHOES * BYTES_PER_ECHO
SRAM_SPEED_TABLES:	.RES NUMBER_OF_SPEED_TABLES * STEPS_PER_SPEED_TABLE * BYTES_PER_SPEED_TABLE_STEP
SRAM_SONG_SPEEDS:	.RES NUMBER_OF_SONGS
SRAM_SONG_MUTE:	.RES NUMBER_OF_SONGS
SRAM_SONG_SOLO:	.RES NUMBER_OF_SONGS
SRAM_FX_TABLES:	.RES NUMBER_OF_FX_TABLES * STEPS_PER_FX_TABLE * BYTES_PER_FX_TABLE_STEP
		
		
.segment "SRAM1"
.segment "SRAM2"
.segment "SRAM3"

		.ENDIF


		

		