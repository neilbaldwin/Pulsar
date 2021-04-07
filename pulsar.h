		.include "nes_audio.h"

ENABLE_ECHO 		= 1
SIZE_OF_ECHO_BUFFER		= $80
NEW_CONTROLS		= 1
DEBUG			= 0
PAL_VERSION		= 0
;---------------------------------------------------------------
; SRAM BANKS
;---------------------------------------------------------------

SRAM_MAP			= 32

SRAM_BANK_0		= %00010000
SRAM_BANK_1		= %00010100
SRAM_BANK_2		= %00011000
SRAM_BANK_3		= %00011100

WRAM_BANK_00 = SRAM_BANK_0
WRAM_BANK_01 = SRAM_BANK_1
WRAM_BANK_02 = SRAM_BANK_2
WRAM_BANK_03 = SRAM_BANK_3

		.IF SRAM_MAP=32

SRAM_HEADER_BANK		= SRAM_BANK_0

SRAM_SONG_BANK		= SRAM_BANK_0
SRAM_CHAIN_BANK		= SRAM_BANK_1
SRAM_INSTRUMENT_BANK	= SRAM_BANK_1
SRAM_DRUMKIT_BANK		= SRAM_BANK_2
SRAM_ENVELOPE_BANK		= SRAM_BANK_1
SRAM_VIBRATO_BANK		= SRAM_BANK_1
SRAM_DUTY_BANK		= SRAM_BANK_1
SRAM_ECHO_BANK		= SRAM_BANK_1
SRAM_SPEED_BANK		= SRAM_BANK_0

SRAM_TABLE_BANK		= SRAM_BANK_2
SRAM_FX_BANK		= SRAM_BANK_2


SRAM_PATTERN_BANK		= SRAM_BANK_3

		.ELSE
		
SRAM_HEADER_BANK		= SRAM_BANK_0
SRAM_SONG_BANK		= SRAM_BANK_0
SRAM_CHAIN_BANK		= SRAM_BANK_0
SRAM_PATTERN_BANK		= SRAM_BANK_0
SRAM_INSTRUMENT_BANK	= SRAM_BANK_0
SRAM_DRUMKIT_BANK		= SRAM_BANK_0
SRAM_ENVELOPE_BANK		= SRAM_BANK_0
SRAM_TABLE_BANK		= SRAM_BANK_0
SRAM_VIBRATO_BANK		= SRAM_BANK_0
SRAM_DUTY_BANK		= SRAM_BANK_0
SRAM_ECHO_BANK		= SRAM_BANK_0
SRAM_SPEED_BANK		= SRAM_BANK_0
SRAM_FX_BANK		= SRAM_BANK_0

		.ENDIF
		
;---------------------------------------------------------------
; ROM LAYOUT
;---------------------------------------------------------------

BANK_EDITOR0 		= $00
BANK_EDITOR1		= $01
BANK_FONT		= $02
BANK_SCREEN		= $03
BANK_HINTS		= $04
BANK_ENGINE		= $05

;---------------------------------------------------------------
; SPECIAL CHARS
;---------------------------------------------------------------

CHR_SPACE			= $FF
CHR_EMPTY			= $25
CHR_SHARP			= $26
CHR_Y			= $22
CHR_N			= $17
CHR_DUTY_00		= $27
CHR_DUTY_40		= $29
CHR_DUTY_80		= $2B
CHR_DUTY_C0		= $2D
CHR_DUTY_00_SMALL		= $30
CHR_DUTY_40_SMALL		= $31
CHR_DUTY_80_SMALL		= $32
CHR_DUTY_C0_SMALL		= $33


;---------------------------------------------------------------
; SPRITE CONSTANTS
;---------------------------------------------------------------

SPR_RIGHT_ARROW		= $06
SPR_LEFT_ARROW		= $07

;---------------------------------------------------------------
; EDITOR CONSTANTS
;---------------------------------------------------------------
EDITOR_MODES		= 13

EDIT_MODE_SONG		= 0
EDIT_MODE_CHAIN		= 1
EDIT_MODE_PATTERN		= 2
EDIT_MODE_INSTRUMENT	= 3
EDIT_MODE_DRUMKIT		= 4
EDIT_MODE_ENVELOPE_TABLE	= 5
EDIT_MODE_PITCH_TABLE	= 6
EDIT_MODE_VIBRATO_TABLE	= 7
EDIT_MODE_DUTY_TABLE	= 8
EDIT_MODE_ECHO_TABLE	= 9
EDIT_MODE_SPEED_TABLE	= 10
EDIT_MODE_FX_TABLE		= 11
EDIT_MODE_SETUP		= 12
EDIT_MODE_NAV_MENU		= 13

CHAIN_COLUMN_PATTERN	= 0
CHAIN_COLUMN_TRANSPOSE	= 1

PATTERN_COLUMN_NOTE		= 0
PATTERN_COLUMN_INSTRUMENT	= 1
PATTERN_COLUMN_COMMAND	= 2
PATTERN_COLUMN_COMMAND_DATA	= 3

INSTRUMENT_ROW_ENVELOPE	= 0
INSTRUMENT_ROW_LEVEL	= 1
INSTRUMENT_ROW_GATE		= 2
INSTRUMENT_ROW_DUTY		= 3
INSTRUMENT_ROW_TABLE	= 4
INSTRUMENT_ROW_PSWEEP	= 5
INSTRUMENT_ROW_PSWEEPQ	= 6
INSTRUMENT_ROW_SWEEP	= 7
INSTRUMENT_ROW_VIBRATO	= 8
INSTRUMENT_ROW_DETUNE	= 9
INSTRUMENT_ROW_HARDFREQ	= 10
INSTRUMENT_ROW_ECHO		= 11

		
DRUMKIT_COLUMN_SAMPLE	= 0
DRUMKIT_COLUMN_PITCH	= 1
DRUMKIT_COLUMN_START_OFFSET	= 2
DRUMKIT_COLUMN_END_OFFSET	= 3
DRUMKIT_COLUMN_LOOP		= 4
DRUMKIT_COLUMN_ROOT		= 5
	
ENVELOPE_COLUMN_ATTACK	= 0
ENVELOPE_COLUMN_DECAY	= 1
ENVELOPE_COLUMN_SUSTAIN	= 2
ENVELOPE_COLUMN_RELEASE	= 3

TABLE_COLUMN_VOLUME		= 0
TABLE_COLUMN_PITCH		= 1
TABLE_COLUMN_FX1		= 2
TABLE_COLUMN_FX1_DATA	= 3
TABLE_COLUMN_FX2		= 4
TABLE_COLUMN_FX2_DATA	= 5

VIBRATO_COLUMN_SPEED	= 0
VIBRATO_COLUMN_DEPTH	= 1
VIBRATO_COLUMN_ACCELERATE	= 2
VIBRATO_COLUMN_DELAY	= 3

DUTY_COLUMN_DUTY		= 0
DUTY_COLUMN_DELAY		= 1
DUTY_COLUMN_JUMP		= 2

ECHO_COLUMN_SPEED		= 0
ECHO_COLUMN_LEVEL		= 1
ECHO_COLUMN_ATTENUATION	= 2

FX_COLUMN_PITCH_A		= 0
FX_COLUMN_VOLUME_A		= 1
FX_COLUMN_DUTY_A		= 2
FX_COLUMN_PITCH_B		= 3
FX_COLUMN_VOLUME_B		= 4
FX_COLUMN_DUTY_B		= 5
FX_COLUMN_PITCH_C		= 6
FX_COLUMN_PITCH_D		= 7
FX_COLUMN_VOLUME_D		= 8

SETUP_ROW_SONG		= 0
SETUP_ROW_SONG_SPEED	= 1
SETUP_ROW_PRELISTEN		= 2
SETUP_ROW_CLEAR_SONG	= 3
SETUP_ROW_CLEAN_SONGS	= 4
SETUP_ROW_INIT_ALL		= 5
SETUP_ROW_PALETTE		= 6
SETUP_ROW_NEXT 		= SETUP_ROW_PALETTE+4

COMMAND_A		= 0
COMMAND_B		= 1
COMMAND_C		= 2
COMMAND_D		= 3
COMMAND_E		= 4
COMMAND_F		= 5
COMMAND_G		= 6
COMMAND_H		= 7
COMMAND_I		= 8
COMMAND_J		= 9
COMMAND_K		= 10
COMMAND_L		= 11
COMMAND_M		= 12
COMMAND_N		= 13
COMMAND_O		= 14
COMMAND_P		= 15
COMMAND_Q		= 16
COMMAND_R		= 17
COMMAND_S		= 18
COMMAND_T		= 19
COMMAND_U		= 20
COMMAND_V		= 21
COMMAND_W		= 22
COMMAND_X		= 23
COMMAND_Y		= 24
COMMAND_Z		= 25

KEYS_DOUBLE_TAP_SPEED	= $09
KEYS_REPEAT_DELAY	= $08
KEYS_REPEAT_SPEED	= $00

songModeColumns	= 5
chainModeColumns	= 2
patternModeColumns	= 4
instrumentModeColumns	= 1
drumkitModeColumns	= 5
tableModeColumns	= 6
envelopeModeColumns	= 4
vibratoModeColumns	= 4
dutyModeColumns	= 3
echoModeColumns	= 3
speedModeColumns	= 1
fxModeColumns	= 9
navModeColumns	= 1
setupModeColumns	= 1

songModeRows	= 16
chainModeRows	= 16
patternModeRows	= 16
instrumentModeRows	= 12
drumkitModeRows	= 14
tableModeRows	= 16
envelopeModeRows	= 16
vibratoModeRows	= 16
dutyModeRows	= 16
echoModeRows	= 16
speedModeRows	= 16
fxModeRows	= 16
navModeRows	= 13
setupModeRows	= 10

SONG_TRACK_A	= 0
SONG_TRACK_B	= 1
SONG_TRACK_C	= 2
SONG_TRACK_D	= 3
SONG_TRACK_E	= 4

PLAY_MODE_STOPPED	= $00
PLAY_MODE_SONG	= $01
PLAY_MODE_CHAIN	= $02
PLAY_MODE_PATTERN	= $03

ERROR_DISPLAY_TIME 	= $80
ERROR_NO_FREE_CHAINS = $00
ERROR_NO_FREE_PATTERNS = $01
ERROR_PASTE	= $02

		
		.IF SRAM_MAP=32
;---------------------------------------------------------------
; SRAM OBJECTS FOR 32KB
;---------------------------------------------------------------
NUMBER_OF_SONGS		= 8

NUMBER_OF_NOTES		= 7*12
MAX_NUMBER_OF_SAMPLES	= $40

SIZE_OF_HEADER		= $10

TRACKS_PER_SONG		= $05
STEPS_PER_TRACK		= $7F

NUMBER_OF_CHAINS		= $7F
STEPS_PER_CHAIN		= $10
BYTES_PER_CHAIN_STEP	= $02

NUMBER_OF_PATTERNS		= $7F
STEPS_PER_PATTERN		= $10
BYTES_PER_PATTERN_STEP	= $04

NUMBER_OF_INSTRUMENTS	= $20
STEPS_PER_INSTRUMENT	= $0C
BYTES_PER_INSTRUMENT_STEP	= $01

NUMBER_OF_DRUMKITS		= $08
STEPS_PER_DRUMKIT		= $0C
BYTES_PER_DRUMKIT_STEP	= $05

NUMBER_OF_ENVELOPES		= $20
BYTES_PER_ENVELOPE		= $04

NUMBER_OF_TABLES		= $38
STEPS_PER_TABLE		= $10
BYTES_PER_TABLE_STEP	= $06

NUMBER_OF_VIBRATOS		= $20
BYTES_PER_VIBRATO		= $04

NUMBER_OF_DUTY_TABLES	= $20
STEPS_PER_DUTY_TABLE	= $10
BYTES_PER_DUTY_TABLE_STEP	= $03

NUMBER_OF_ECHOES		= $20
BYTES_PER_ECHO		= $03

NUMBER_OF_SPEED_TABLES	= $20
STEPS_PER_SPEED_TABLE	= $10
BYTES_PER_SPEED_TABLE_STEP	= $01

NUMBER_OF_FX_TABLES		= $10
STEPS_PER_FX_TABLE		= $10
BYTES_PER_FX_TABLE_STEP	= $09

		.ELSE
;---------------------------------------------------------------
; SRAM OBJECTS FOR 8KB
;---------------------------------------------------------------
NUMBER_OF_SONGS		= 1

NUMBER_OF_NOTES		= 7*12
MAX_NUMBER_OF_SAMPLES	= $40

SIZE_OF_HEADER		= $10

TRACKS_PER_SONG		= $05
STEPS_PER_TRACK		= $40

NUMBER_OF_CHAINS		= $20
STEPS_PER_CHAIN		= $10
BYTES_PER_CHAIN_STEP	= $02

NUMBER_OF_PATTERNS		= $20
STEPS_PER_PATTERN		= $10
BYTES_PER_PATTERN_STEP	= $04

NUMBER_OF_INSTRUMENTS	= $20
STEPS_PER_INSTRUMENT	= $0C
BYTES_PER_INSTRUMENT_STEP	= $01

NUMBER_OF_DRUMKITS		= $02
STEPS_PER_DRUMKIT		= $0C
BYTES_PER_DRUMKIT_STEP	= $05

NUMBER_OF_ENVELOPES		= $20
BYTES_PER_ENVELOPE		= $04

NUMBER_OF_TABLES		= $10
STEPS_PER_TABLE		= $10
BYTES_PER_TABLE_STEP	= $06

NUMBER_OF_VIBRATOS		= $10
BYTES_PER_VIBRATO		= $04

NUMBER_OF_DUTY_TABLES	= $10
STEPS_PER_DUTY_TABLE	= $10
BYTES_PER_DUTY_TABLE_STEP	= $03

NUMBER_OF_ECHOES		= $10
BYTES_PER_ECHO		= $03

NUMBER_OF_SPEED_TABLES	= $10
STEPS_PER_SPEED_TABLE	= $10
BYTES_PER_SPEED_TABLE_STEP	= $01

NUMBER_OF_FX_TABLES		= $08
STEPS_PER_FX_TABLE		= $10
BYTES_PER_FX_TABLE_STEP	= $09

		.ENDIF
		
;---------------------------------------------------------------
; SONG HEADER
;---------------------------------------------------------------
SRAM_HEADER_0	= SRAM_HEADER+0		;P
SRAM_HEADER_1	= SRAM_HEADER+1		;N
SRAM_HEADER_2	= SRAM_HEADER+2		;E
SRAM_HEADER_3	= SRAM_HEADER+3		;S
SRAM_HEADER_4	= SRAM_HEADER+4
SRAM_HEADER_5	= SRAM_HEADER+5
SRAM_HEADER_6	= SRAM_HEADER+6
SRAM_HEADER_7	= SRAM_HEADER+7
SRAM_HEADER_PRELISTEN = SRAM_HEADER_7+1
SRAM_HEADER_FREE_CHAINS = SRAM_HEADER_PRELISTEN+1
SRAM_HEADER_FREE_PATTERNS = SRAM_HEADER_FREE_CHAINS+1

UI_COLOUR_BG0	= SRAM_PALETTE+$01
UI_COLOUR_BG1	= SRAM_PALETTE+$05
UI_COLOUR_01	= SRAM_PALETTE+$02
UI_COLOUR_02	= SRAM_PALETTE+$03
UI_COLOUR_03	= SRAM_PALETTE+$07

;---------------------------------------------------------------
; GLOBAL DECLARATIONS
;---------------------------------------------------------------

;--- ZP ---
.globalzp DO_NOT_INTERRUPT
.globalzp currentPrgBank,currentSramBank
.globalzp vblankFlag
.globalzp vblankFlagOld
.globalzp vblankOverflow
.globalzp dmaCycleFlag
.globalzp tmp0,tmp1,tmp2,tmp3,tmp4,tmp5
.globalzp engineTmp0
.globalzp engineTmp1
.globalzp engineTmp2
.globalzp engineTmp3
.globalzp PAD1_jt
.globalzp PAD1_lr
.globalzp PAD1_ud
.globalzp PAD1_str
.globalzp PAD1_sel
.globalzp PAD1_firea
.globalzp PAD1_fireb
.globalzp PAD1_oldlr
.globalzp PAD1_dlr
.globalzp PAD1_dud
.globalzp PAD1_dsta
.globalzp PAD1_dsel
.globalzp PAD1_dfirea
.globalzp PAD1_dfireb
.globalzp screenVector
.globalzp editorVector
.globalzp trackVector
.globalzp chainVector
.globalzp patternVector
.globalzp instrumentVector
.globalzp drumkitVector
.globalzp tableVector
.globalzp vibratoVector
.globalzp dutyVector
.globalzp echoVector
.globalzp speedVector
.globalzp fxVector
.globalzp songVectors
.globalzp plyrTrackVector
.globalzp plyrEnvelopeVector
.globalzp plyrChainVector
.globalzp plyrPatternVector
.globalzp plyrInstrumentVector
.globalzp plyrDutyVector
.globalzp plyrTableVector
.globalzp plyrSpeedVector
.globalzp plyrFxVector
.globalzp copyBufferVector
.globalzp lfsr
.globalzp rleSource,rleDestination
.globalzp plyrInstrumentCopy,plyrInstrumentCopyA,plyrInstrumentCopyB,plyrInstrumentCopyC,plyrInstrumentCopyD
.globalzp plyrFxTemp1,plyrFxTemp2,plyrFxDataTemp1,plyrFxDataTemp2

;--- SRAM ---
.global SRAM
.global SRAM_HEADER
.global SRAM_PALETTE
.global SRAM_TRACK_A0,SRAM_TRACK_B0,SRAM_TRACK_C0,SRAM_TRACK_D0,SRAM_TRACK_E0
.IF SRAM_MAP=32
.global SRAM_TRACK_A1,SRAM_TRACK_B1,SRAM_TRACK_C1,SRAM_TRACK_D1,SRAM_TRACK_E1
.global SRAM_TRACK_A2,SRAM_TRACK_B2,SRAM_TRACK_C2,SRAM_TRACK_D2,SRAM_TRACK_E2
.global SRAM_TRACK_A3,SRAM_TRACK_B3,SRAM_TRACK_C3,SRAM_TRACK_D3,SRAM_TRACK_E3
.global SRAM_TRACK_A4,SRAM_TRACK_B4,SRAM_TRACK_C4,SRAM_TRACK_D4,SRAM_TRACK_E4
.global SRAM_TRACK_A5,SRAM_TRACK_B5,SRAM_TRACK_C5,SRAM_TRACK_D5,SRAM_TRACK_E5
.global SRAM_TRACK_A6,SRAM_TRACK_B6,SRAM_TRACK_C6,SRAM_TRACK_D6,SRAM_TRACK_E6
.global SRAM_TRACK_A7,SRAM_TRACK_B7,SRAM_TRACK_C7,SRAM_TRACK_D7,SRAM_TRACK_E7
.ENDIF

.global SRAM_CHAIN_FLAGS,SRAM_CHAINS
.global SRAM_PATTERN_FLAGS,SRAM_PATTERNS
.global SRAM_INSTRUMENTS,SRAM_DRUMKITS,SRAM_DRUMKIT_ROOTS
.global SRAM_ENVELOPES,SRAM_TABLES,SRAM_VIBRATOS,SRAM_DUTY_TABLES,SRAM_ECHOES,SRAM_SPEED_TABLES
.global SRAM_SONG_SPEEDS,SRAM_SONG_MUTE,SRAM_SONG_SOLO
.global copyBufferLength,copyBufferStartIndex,copyBuffer
.global SRAM_FX_TABLES
.IF SRAM_MAP=32
.IF ENABLE_ECHO=1
.global plyrEchoBuffer00_A,plyrEchoBuffer02_A,plyrEchoBuffer03_A
.global plyrEchoBuffer00_B,plyrEchoBuffer02_B,plyrEchoBuffer03_B
.global plyrEchoBuffer00_D,plyrEchoBuffer02_D
.ENDIF
.ENDIF


;--- RAM ---
.global infoBuffer1,infoBuffer2,copyInfoBuffer,copyInfoFlag
.global sprBuf
.global debug0,debug1,debug2,debug3
.global editorMode,editorModeIndex,editorPreviousModes
.global hintMode, cursorFlashColour,cursorFlashIndex
.global editorCurrentTrack,editorCurrentChain,editorCurrentPattern,editorCurrentInstrument
.global editorCurrentDrumkit,editorCurrentEnvelope,editorCurrentTable,editorCurrentVibrato
.global editorCurrentDuty,editorCurrentEcho,editorCurrentSpeed
.global editorCurrentSong
.global editPatternTie
.global songTrackIndex,editChainIndex,envelopeIndex,vibratoIndex,echoIndex
.global editorLastValues,editorLastValuesEnd
.global editSongLastValue,editChainLastValue,editPatternLastValue,editDrumkitLastValue
.global editEnvelopeLastValue,editTableLastValue,editVibratoLastValue,editDutyLastValue
.global editEchoLastValue,editSpeedLastValue
.global editBuffer, editBufferFlag, editNavFlag
.global editorKeys,editorKeysEnd
.global keysHoldCounterB,keysTapCounterB,keysTapB,keysDoubleTapB,keysHoldB
.global keysHoldCounterA,keysTapCounterA,keysTapA,keysDoubleTapA,keysHoldA
.global keysHoldCounterSel,keysTapCounterSel,keysTapSel,keysDoubleTapSel,keysHoldSel
.global keysRepeatUD,keysRepeatOldUD,keysRepeatRateUD,keysRepeatCounterUD
.global keysRepeatLR,keysRepeatOldLR,keysRepeatRateLR,keysRepeatCounterLR
.global PAD1_firea_old,PAD1_fireb_old,PAD1_sel_old
.global windowBuffer,titleBuffer,headerBuffer,rowBuffer,writeScreen,errorMessageBuffer
.global dmaUpdateWindow,dmaUpdateHeader,dmaUpdateTitle
.global songCursorX,chainCursorX,patternCursorX,instrumentCursorX,drumkitCursorX
.global envelopeCursorX,tableCursorX,vibratoCursorX,dutyCursorX,echoCursorX
.global speedCursorX,navMenuCursorX,setupCursorX
.global songCursorY,chainCursorY,patternCursorY,instrumentCursorY,drumkitCursorY
.global envelopeCursorY,tableCursorY,vibratoCursorY,dutyCursorY,echoCursorY
.global speedCursorY,navMenuCursorY,setupCursorY
.global songFirstRow,chainFirstRow,patternFirstRow,instrumentFirstRow,drumkitFirstRow
.global envelopeFirstRow,tableFirstRow,vibratoFirstRow,dutyFirstRow,echoFirstRow
.global speedFirstRow,navFirstRow,setupFirstRow
.global drumkitCursorX_old
.global blockMode,blockOrigin,blockStart,blockEnd
.global plyrPlaying,plyrSongStartIndex,plyrTrackIndex,plyrPatternIndex,plyrPatternStepCounter
.global plyrPatternJump,plyrChainIndex,plyrCurrentChain,plyrCurrentChainTranspose
.global plyrCurrentInstrument,plyrCurrentNote,plyrNoteCounter
.global plyrCurrentPattern,plyrCurrentPatternFX,plyrCurrentPatternFXData
;.global plyrInstrumentCopy,plyrInstrumentCopyA,plyrInstrumentCopyB,plyrInstrumentCopyC,plyrInstrumentCopyD
.global plyrInstrumentCopyE
.global envelopeCounter,envelopePhase,envelopeAmp
.global noteNumber
.global noteAddFrac,noteAddNote
.global pitchLo,pitchHi,pitchHiOld,pitchLoOld
.global plyrPitchSweepDelta,plyrPitchSweepLo
.global plyrCurrentDuty,plyrDutyIndex,plyrDutyTableDelay
.global plyrTableVolume,plyrTablePitch,plyrTableIndex,plyrTableSpeed
.global plyrTableCounter,plyrTableJump,plyrTableDoStep
.global plyrTableTrackE
;.global plyrFxTemp1,plyrFxTemp2,plyrFxDataTemp1,plyrFxDataTemp2
.global plyrFxType
.global patternLastNote,plyrCurrentSpeedTable,plyrSpeedTableIndex
.global plyrChordNotes,plyrPatternChordIndex,plyrPatternChordCounter,plyrPatternChordNote
.global getNoteTemp0,getNoteTemp1
.global plyrKillCounter,plyrDelayNoteCounter,plyrDelayNote
.global plyrVibPos,plyrVibSpeedCounter,plyrVibDelta,plyrVibLastDelta
.global plyrVibSpeedLo,plyrVibDepthMod,plyrVibDepthModCounter
.global plyrSlideSpeed,plyrSlideDestination,plyrPreviousNote
.global plyrDetuneHi
.global V_APU
.global dpcmStart,dpcmLength,dpcmPitch,dpcmDC,plyrDpcmOn, plyrDpcmMuted
.global plyrKeyOn
.global vuIndex,vuCounter
.global plyrRetriggerSpeed,plyrRetriggerCounter
.global pulsarPassCounter,pulsarIntensity
.global copyBufferObjectType,copyBufferObject,copyBufferStartIndex,copyBufferEndIndex
.global soloLightCounter,soloLightChar
.global plyrPlayMode
.global errorMessageFlag, errorMessageNumber, errorCounter
.global fxCursorX,fxCursorY,fxFirstRow,editFxLastValue,editorCurrentFx
.global plyrFxTable,plyrFxTableCounter,plyrFxTableIndex,plyrFxTableSpeed,plyrFxTableVoice
.global echoRowsIndex
.global bpmBeatCounter,bpmFrameCounter,bpmCurrent

	.IF SRAM_MAP=32
	.IF ENABLE_ECHO=1
.global plyrEchoIndex,plyrEchoSpeed,plyrEchoInitAttn,plyrEchoAttn,plyrEchoCounter
	.ENDIF
	.ENDIF

.global old_V_APUA,old_V_APUB

;---FIXED BANK---
.global RESET,NMI,IRQ
.global editTrackAddressLo,editTrackAddressHi
.global editSpeedAddressLo,editSpeedAddressHi
.global editChainAddressLo,editChainAddressHi
.global editPatternAddressLo,editPatternAddressHi
.global editInstrumentAddressLo,editInstrumentAddressHi
.global editDrumkitAddressLo,editDrumkitAddressHi
.global editTableAddressLo,editTableAddressHi
.global editDutyAddressLo,editDutyAddressHi
.global editSpeedAddressLo,editSpeedAddressLo
.global editFxAddressLo,editFxAddressHi
.global chainRowsIndex,patternRowsIndex,dutyRowsIndex
.global tableRowsIndex,tableRowsIndex2,vibratoRowsIndex,drumkitRowsIndex,fxRowsIndex
.global phexTitle,phexRow,phexWindow,phexWindow2,phexWindow3
.global writePalette,writePaletteFlag
.global editorShowHint
.global SetBits,ClrBits,readPad1
.global dmcAddressTable
.global setMMC1r1
.global initPalette


;--- MISC ---
.global font,spr,layout
.global dmaSecondary
.global waitForTapA
.global editorPlayingNote
	
;--- EDITOR ---
.global editSong
.global editChain
.global editPattern
.global editInstrument
.global editDrumkit
.global editEnvelopeTable
.global editTable
.global editVibratoTable
.global editDutyTable
.global editEchoTable
.global editSpeed
.global editFx
.global editNavMenu
.global editSetup
.global editorInstrumentAddressLo,editorInstrumentAddressHi
.global editorLoop
.global editorLoadSave

.global errorScreen,palette

;--- PLAYER ---
.global plyrInitSong, plyrRefresh

;--- ENGINE ---
.global pulsarRefresh, initPulsar

;--- HINTS ---
.global hintFourteens, hintAddressLo, hintAddressHi

;--- FONT/CHR ---
.global font,spr,layout



;--- SPRITES ---
.global SPR00_Y,SPR00_CHAR,SPR00_ATTR,SPR00_X
.global SPR01_Y,SPR01_CHAR,SPR01_ATTR,SPR01_X
.global SPR02_Y,SPR02_CHAR,SPR02_ATTR,SPR02_X
.global SPR03_Y,SPR03_CHAR,SPR03_ATTR,SPR03_X
.global SPR04_Y,SPR04_CHAR,SPR04_ATTR,SPR04_X
.global SPR05_Y,SPR05_CHAR,SPR05_ATTR,SPR05_X
.global SPR06_Y,SPR06_CHAR,SPR06_ATTR,SPR06_X
.global SPR07_Y,SPR07_CHAR,SPR07_ATTR,SPR07_X
.global SPR08_Y,SPR08_CHAR,SPR08_ATTR,SPR08_X
.global SPR09_Y,SPR09_CHAR,SPR09_ATTR,SPR09_X
.global SPR0A_Y,SPR0A_CHAR,SPR0A_ATTR,SPR0A_X
.global SPR0B_Y,SPR0B_CHAR,SPR0B_ATTR,SPR0B_X
.global SPR0C_Y,SPR0C_CHAR,SPR0C_ATTR,SPR0C_X
.global SPR0D_Y,SPR0D_CHAR,SPR0D_ATTR,SPR0D_X
.global SPR0E_Y,SPR0E_CHAR,SPR0E_ATTR,SPR0E_X
.global SPR0F_Y,SPR0F_CHAR,SPR0F_ATTR,SPR0F_X
.global SPR10_Y,SPR10_CHAR,SPR10_ATTR,SPR10_X
.global SPR11_Y,SPR11_CHAR,SPR11_ATTR,SPR11_X
.global SPR12_Y,SPR12_CHAR,SPR12_ATTR,SPR12_X
.global SPR13_Y,SPR13_CHAR,SPR13_ATTR,SPR13_X
.global SPR14_Y,SPR14_CHAR,SPR14_ATTR,SPR14_X
.global SPR15_Y,SPR15_CHAR,SPR15_ATTR,SPR15_X
.global SPR16_Y,SPR16_CHAR,SPR16_ATTR,SPR16_X
.global SPR17_Y,SPR17_CHAR,SPR17_ATTR,SPR17_X
.global SPR18_Y,SPR18_CHAR,SPR18_ATTR,SPR18_X
.global SPR19_Y,SPR19_CHAR,SPR19_ATTR,SPR19_X
.global SPR1A_Y,SPR1A_CHAR,SPR1A_ATTR,SPR1A_X
.global SPR1B_Y,SPR1B_CHAR,SPR1B_ATTR,SPR1B_X
.global SPR1C_Y,SPR1C_CHAR,SPR1C_ATTR,SPR1C_X
.global SPR1D_Y,SPR1D_CHAR,SPR1D_ATTR,SPR1D_X
.global SPR1E_Y,SPR1E_CHAR,SPR1E_ATTR,SPR1E_X
.global SPR1F_Y,SPR1F_CHAR,SPR1F_ATTR,SPR1F_X
.global SPR20_Y,SPR20_CHAR,SPR20_ATTR,SPR20_X
.global SPR21_Y,SPR21_CHAR,SPR21_ATTR,SPR21_X
.global SPR22_Y,SPR22_CHAR,SPR22_ATTR,SPR22_X
.global SPR23_Y,SPR23_CHAR,SPR23_ATTR,SPR23_X
.global SPR24_Y,SPR24_CHAR,SPR24_ATTR,SPR24_X
.global SPR25_Y,SPR25_CHAR,SPR25_ATTR,SPR25_X
.global SPR26_Y,SPR26_CHAR,SPR26_ATTR,SPR26_X
.global SPR27_Y,SPR27_CHAR,SPR27_ATTR,SPR27_X
.global SPR28_Y,SPR28_CHAR,SPR28_ATTR,SPR28_X
.global SPR29_Y,SPR29_CHAR,SPR29_ATTR,SPR29_X
.global SPR2A_Y,SPR2A_CHAR,SPR2A_ATTR,SPR2A_X
.global SPR2B_Y,SPR2B_CHAR,SPR2B_ATTR,SPR2B_X
.global SPR2C_Y,SPR2C_CHAR,SPR2C_ATTR,SPR2C_X
.global SPR2D_Y,SPR2D_CHAR,SPR2D_ATTR,SPR2D_X
.global SPR2E_Y,SPR2E_CHAR,SPR2E_ATTR,SPR2E_X
.global SPR2F_Y,SPR2F_CHAR,SPR2F_ATTR,SPR2F_X
.global SPR30_Y,SPR30_CHAR,SPR30_ATTR,SPR30_X
.global SPR31_Y,SPR31_CHAR,SPR31_ATTR,SPR31_X
.global SPR32_Y,SPR32_CHAR,SPR32_ATTR,SPR32_X
.global SPR33_Y,SPR33_CHAR,SPR33_ATTR,SPR33_X
.global SPR34_Y,SPR34_CHAR,SPR34_ATTR,SPR34_X
.global SPR35_Y,SPR35_CHAR,SPR35_ATTR,SPR35_X
.global SPR36_Y,SPR36_CHAR,SPR36_ATTR,SPR36_X
.global SPR37_Y,SPR37_CHAR,SPR37_ATTR,SPR37_X
.global SPR38_Y,SPR38_CHAR,SPR38_ATTR,SPR38_X
.global SPR39_Y,SPR39_CHAR,SPR39_ATTR,SPR39_X
.global SPR3A_Y,SPR3A_CHAR,SPR3A_ATTR,SPR3A_X
.global SPR3B_Y,SPR3B_CHAR,SPR3B_ATTR,SPR3B_X
.global SPR3C_Y,SPR3C_CHAR,SPR3C_ATTR,SPR3C_X
.global SPR3D_Y,SPR3D_CHAR,SPR3D_ATTR,SPR3D_X
.global SPR3E_Y,SPR3E_CHAR,SPR3E_ATTR,SPR3E_X
.global SPR3F_Y,SPR3F_CHAR,SPR3F_ATTR,SPR3F_X
