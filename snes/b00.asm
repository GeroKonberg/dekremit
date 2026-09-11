;BANK 0 INIT CODE
GKFInitCode:
	clc
	xce
	sei
	rep #$39
	ldx #$1fff
	txs
	stz $2102
	stz $2103
-	stz $00,x  ;clear all RAM
	stz $2104
	dex
	bne -
;	lda $700000 ;check if sram has been freed
;	beq ++
;	ldx #$07ff
;-	lda #$0000
;	sta.l $700000,x ;clear SRAM if uncleared
;	dex
;	bne -
++	lda #$0001
	sta $4200
	stz $4016
	stz $420C
	lda #$008F
	sta $2100
	stz $420D
	lda #$00FF
	sta $4201
	stz $2101
	stz $2102
	stz $2103
	stz $2105
	stz $2107
	stz $2108
	stz $2109
	stz $210A
	stz $210B
	stz $210C
	stz $210D
	sta $210E
	stz $210F
	sta $2110
	stz $2111
	sta $2112
	stz $2113
	stz $2113
	sta $2114
	sta $2114
	lda #$0080
	sta $2115
	stz $211A
	stz $211B
	stz $211C
	stz $211D
	stz $211E
	stz $211F
	stz $2120
	stz $2123
	stz $2124
	stz $2125
	stz $2126
	stz $2127
	stz $2128
	stz $2129
	stz $212A
	stz $212B
	lda #$001f
	sta $212C
	sta $212D
	stz $212E
	stz $212F
	lda #$0030
	sta $2130
	stz $2131
	lda #$00E0
	sta $2132
	stz $2133
	lda #$0001
	sta $2105
	stz $2106
	lda #$7470 ;set BG1/2 tilemap VRAM offset
	sta $2107
	lda #$7c78 ;set BG3/4 tilemap VRAM offset
	sta $2109
	ldy #$0000
	lda #$6000
	sta $2116
-	stz $2118
	iny
	tya
	cmp #$2000
	bne -

GKFInitPalette:
	lda.l InitPalPos
	sta $c0
	lda.l InitPalPos+2
	sta $c2
	stz $2121
	stz $2122
	ldy #$0003
--	jsl GKFRoutineTint
	cmp #$017F
	beq +
	iny
	bra --
+

GKFInitTiles:
	lda #$0000
	sta $2116
	ldy #$0000
--	lda InitBG1,y
	sta $2118
	iny
	iny
	tya
	cmp #$4000
	beq +
	bra --
+	jsl KonzertInstDriver ;install sound driver
	lda #$0001 ;load sample pack 1
	jsl KonzertInstSamples
	lda #$0001 ;laad music 1
	jsl KonzertLoadMIDI
	lda #$0001 ;load gfx 1
	jsl GKFLoadScenes
	lda #$0001 ;load tint 1
	jsl GKFLoadTint
	lda #$0001 ;load field 1
	jsl GKFLoadFields
	lda #$1000 ;set tempo divider
	sta DPTimerUnit
	lda #$0006 ;set timer (00:03)
	jsl RoutineSetTimer
--	jsl GKFTickTimer ;wait
	bpl --
	jml DekremitSTART ;main routine after the title screen


RoutineSetTimer:
	pha
	xba
	and #$00ff
	sta DPTimerMin
	pla
	and #$00ff
	sta DPTimerSec
	stz DPTimerMil
	stz DPTimerFrc
	rtl


GKFTickTimer: ;tick DPTimer in decimal (N flag = time ran out)
	inc DPRandomVal1
	lda DPNowExt
	cmp #$0002 ;if puzzle, check if all tiles have been cleared out
	bne +++
	phx
	ldx DPGridEnd
--	lda SPLayer2FG,x
	and #$00ff
	bne ++
	dex
	bpl --
	stz DPNowExt
	sed
--	lda DPScoreTens
	clc
	adc DPTimerSec
	cmp #$0100
	bmi +
	and #$00ff
	pha
	lda DPScoreMils
	clc
	adc #$0001
	sta DPScoreMils
	pla
+	sta DPScoreTens
	
	lda DPTimerMin
	beq +
	dec DPTimerMin
	lda #$0060
	sta DPTimerSec
	bra --
+++	bra +++
+	cld
	jsl RoutineUpdateScore
	stz DPTimerMin ;reset time
	stz DPTimerSec
	stz DPTimerMil
	jsl RoutineUpdateTimer
++	plx
	phx
	ldx DPCursorPos
	lda SPLayer2FG,x ;check if cursor grid is aligned to air
	and #$00ff
	bne ++
	stx DPLatestPos
	txa
--	cmp DPGridEnd
	bpl +
	tax
	lda SPLayer2FG,x ;check if cursor grid is aligned to air
	and #$00ff
	bne +
	txa
	clc
	adc #$0010
	bra --
+	stx DPCursorPos
	ldx DPLatestPos
	stz SPLayer1FG,x
	ldx DPCursorPos
	lda #$003e
	sta SPLayer1FG,x
	jsl RoutineUpdateLayer1
++	plx
+++	lda DPTimerMin
	bmi +++
	lda DPTimerFrc
	sec
	sbc #$0001
	sta DPTimerFrc
	bpl +++
	lda DPTimerUnit
	sta DPTimerFrc
	sed
	lda DPTimerMil
	sec
	sbc #$0001
	sta DPTimerMil
	bpl +++
	lda #$0009
	sta DPTimerMil
	lda DPTimerSec
	sec
	sbc #$0001
	sta DPTimerSec
	bpl +++
	lda #$0059
	sta DPTimerSec
	lda DPTimerMin
	sec
	sbc #$0001
	sta DPTimerMin
+++	cld
	rtl

RoutineUpdateTimer:
	lda DPTimerMil ;mili second (left)
	and #$00f0
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$0030
	sta $013d
	lda DPTimerMil ;mili second (right)
	and #$000f
	ora #$0030
	sta $013e
	lda DPTimerSec ;second (left)
	and #$00f0
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$0030
	sta $013a
	lda DPTimerSec ;second (right)
	and #$000f
	ora #$3a30
	sta $013b
	lda DPTimerMin ;minute (left)
	and #$00f0
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$0030
	sta $0137
	lda DPTimerMin ;minute (right)
	and #$000f
	ora #$3a30
	sta $0138
	lda #$0100  ;render buffer, change this whenever the layer doesn't actualize
	jsl RoutineUpdateLayerASCII 
	rtl


RoutineUpdateScore:
	lda DPScoreMils ;millions (left)
	and #$00f0
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$0030
	sta $0178
	lda DPScoreMils ;one hundred thousands (right)
	and #$000f
	ora #$0030
	sta $0179
	lda DPScoreTens ;tens thousands (left)
	and #$00f0
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$0030
	sta $017a
	lda DPScoreTens ;thousands (right)
	and #$000f
	ora #$0030
	sta $017b
	lda DPScoreHund ;hundreds (left)
	and #$00f0
	lsr a
	lsr a
	lsr a
	lsr a
	ora #$0030
	sta $017c
	lda DPScoreHund ;tens (right)
	and #$000f
	ora #$3030
	sta $017d
	lda #$0100  ;render buffer, change this whenever the layer doesn't actualize
	jsl RoutineUpdateLayerASCII 
	rtl


RoutineGetRNG: ;get xorshift random number generator
	LDA $2137
    LDA $213C
    ORA #$0001            ;   guarantee non-zero
	adc DPRandomVal1
    STA DPRandomVal1
    LDA $213D
	adc DPRandomVal1+1
    STA DPRandomVal1+1
 ;   REP #$20
    LDA DPRandomVal1

    ; prng.state ^= prng.state << 7
    AND #$01FF
    CMP #$0100
    XBA
    ROR
    EOR DPRandomVal1
    STA DPRandomVal1

    ; prng.state ^= prng.state >> 9
    XBA
    AND #$00FF
    LSR
    EOR DPRandomVal1
    STA DPRandomVal1

    ; prng.state ^= prng.state << 8
    AND #$00FF
    XBA
    EOR DPRandomVal1
    STA DPRandomVal1
;   SEP #$20
	rtl

RoutineBytesASCII: ;turn one (decimal!) byte into an ASCII word
	pha
	and #$000f
	ora #$0030
	xba
	sta DPStack
	pla
	and #$00f0
	lsr
	lsr
	lsr
	lsr
	ora #$0030
	ora DPStack
	rtl

;JOYPAD READER
;01 = X
;02 = A
;03 = ->
;04 = <-
;05 = v
;06 = ^
;07 = START
;08 = SELECT
;09 = Y
;0A = B


RoutineReadJoypad:
;	lda DPJoyOut  ;check if the latest input has been acknowledged & zeroed out
;	bne +++
	lda #$0040
	sta DPRenderBytedown ;AND by amounts
	stz DPRenderBytes ;use a value for joy commands
-	lda $4212
	and #$00C1 ;wait until H/V blank and controller reading have been finished
	bne -
	lda $4218
	sta DPJoyIn ;store latest input
-	inc DPRenderBytes
	lda DPJoyIn
	and DPRenderBytedown ;check if any button has been pressed
	bne +
	asl DPRenderBytedown
	beq +++ ;+
	bra -
+++	stz DPJoyOut
	bra +++
+	lda DPRenderBytes
	asl
	tay
	lda PresetJoyConv,y
+++	cmp DPJoyOut ;check if the same button is already being hold
	bne +
	lda #$007f
	rtl
+	sta DPJoyOut ;store resulting input changes (if any)
++	stz DPRenderBytes
	stz DPRenderBytedown
	lda DPJoyOut
	rtl

PresetJoyConv:
	dw $0000,$0002,$0006,$000E,$000C,$0010,$000A,$0012,$0014,$0004,$0008

InitPalPos:
	dd InitPalette
InitPalette:
incbin "visuals/InitPalette.pal"
InitBG1:
incbin "visuals/InitCharSet.bin"
InitBG2:
incbin "visuals/InitTiles.bin"
InitBG3:
incbin "visuals/InitLogo1.bin"
InitBG4:
incbin "visuals/InitLogo2.bin"



















;GAMEPLAY LOOP
;JOYPAD READER
;X = 02
;Y = 04
;A = 06
;B = 08
;^ = 0A
;<- = 0C
;-> = 0E
;v = 10
;START = 12
;SELECT = 14

DekremitSTART:
	lda #$0002 ;laad music 2
	jsl KonzertLoadMIDI
	lda #$0002 ;load gfx 2
	jsl GKFLoadScenes
	lda #$0002 ;load tint 2
	jsl GKFLoadTint
	lda #$0002 ;load field 2
	jsl GKFLoadFields
DekremitStartButton:
---	jsl GKFTickTimer
	jsl RoutineReadJoypad ;wait for start button
	cmp #$0012
	bne ---
	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	jmp DekremitRules

DekremitMode:
;	lda #$0002 ;load tint 2
;	jsl GKFLoadTint
	lda #$0004 ;load field 4
	jsl GKFLoadFields
---	jsl GKFTickTimer
	jsl RoutineReadJoypad ;read X/Y/A/B buttons
	cmp #$000a
	bpl ---
	tax
	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	jmp (DekremitSelMode,x)



DekremitSelMode:
	dw DekremitMode
	dw DekremitGame1
	dw DekremitGame2
	dw DekremitGame3
	dw DekremitOptions



DekremitGame1:
	lda #$0005 ;load field 5
	jsl GKFLoadFields
---	jsl GKFTickTimer
	jsl RoutineReadJoypad ;read X/Y/A/B buttons
	cmp #$000a
	bpl ---
	tax
	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	jmp (DekremitSelGame1,x)



DekremitSelGame1:
	dw DekremitGame1
	dw DekremitLevelSet
	dw DekremitLevelSet
	dw DekremitLevelSet
	dw DekremitMode



DekremitGame2:
	lda #$0006 ;load field 6
	jsl GKFLoadFields
---	jsl GKFTickTimer
	jsl RoutineReadJoypad ;read X/Y/A/B buttons
	cmp #$000a
	bpl ---
	tax
	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	jmp (DekremitSelGame2,x)


DekremitSelGame2:
	dw DekremitGame2
	dw DekremitLevelSet
	dw DekremitLevelSet
	dw DekremitLevelSet
	dw DekremitMode



DekremitGame3:
	lda #$0007 ;load field 7
	jsl GKFLoadFields
---	jsl GKFTickTimer
	jsl RoutineReadJoypad ;read X/Y/A/B buttons
	cmp #$000a
	bpl ---
	tax
	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	jmp (DekremitSelGame3,x)


DekremitSelGame3:
	dw DekremitGame3
	dw DekremitLevelSet
	dw DekremitLevelSet
	dw DekremitLevelSet
	dw DekremitMode



DekremitOptions:
	lda #$0008 ;load field 8
	jsl GKFLoadFields
---	jsl GKFTickTimer
	jsl RoutineReadJoypad ;read X/Y/A/B buttons
	cmp #$000a
	bpl ---
	tax
	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	jmp (DekremitSelOpts,x)


DekremitSelOpts:
	dw DekremitOptions
	dw DekremitRules
	dw DekremitSounds
	dw DekremitCredits
	dw DekremitMode



DekremitRules:
	lda #$000A ;load tint A
	jsl GKFLoadTint
	lda #$0009 ;load field 9
	jsl GKFLoadFields
---	jsl GKFTickTimer
	jsl RoutineReadJoypad ;wait for start button
	cmp #$0012
	bne ---
	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	
	
DekremitRules2:
	lda #$0010 ;load field 10
	jsl GKFLoadFields
---	jsl GKFTickTimer
	jsl RoutineReadJoypad ;wait for start button
	cmp #$0012
	bne ---
	bra +++


DekremitSounds:
	lda #$000A ;load tint A
	jsl GKFLoadTint
	lda #$000A ;load field A
	jsl GKFLoadFields
---	jsl GKFTickTimer
	jsl RoutineReadJoypad ;read X/Y/A/B buttons
;	beq ---
	cmp #$0012
	beq +++
	cmp #$000a
	bpl ---
	tax
	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	jsr (DekremitSoundOpts,x) ;call sound options
	bra ---
+++	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	jmp DekremitMode

DekremitSoundOpts:
	dw DekremitSounds
	dw DekremitMusInc
	dw DekremitMusDec
	dw DekremitSFXInc
	dw DekremitSFXDec

DekremitMusInc:
	lda DPVolMusic
	cmp #$0078
	bpl +
	clc
	adc #$0008
	sta DPVolMusic
	and #$007f
	sta $2141
+	rts

DekremitMusDec:
	lda DPVolMusic
	cmp #$0008
	bmi +
	sec
	sbc #$0008
	sta DPVolMusic
	and #$007f
	sta $2141
+	rts

DekremitSFXInc:
	lda DPVolSFX
	cmp #$0078
	bpl +
	clc
	adc #$0008
	sta DPVolSFX
	and #$007f
	ora #$0080
	sta $2141
+	rts

DekremitSFXDec:
	lda DPVolSFX
	cmp #$0008
	bmi +
	sec
	sbc #$0008
	sta DPVolSFX
	and #$007f
	ora #$0080
	sta $2141
+	rts


DekremitCredits:
	lda #$000A ;load tint A
	jsl GKFLoadTint
	lda #$000B ;load field B
	jsl GKFLoadFields
---	jsl GKFTickTimer
	jsl RoutineReadJoypad ;wait for start button
	cmp #$0012
	bne ---
	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	jmp DekremitMode



DekremitLevelSet: ;set up level with rules
	lda #$0008 ;laad SFX 4
	jsl KonzertPlaySFX
	stz DPScoreHund ;reset score
	stz DPScoreTens
	stz DPScoreMils
	stz DPNowQuest
	lda DPNowField ;5-7 arcade-puzzle-quest
	sec
	sbc #$0005
	sta DPNowField
	asl
	clc
	adc DPNowField
	lsr DPJoyOut
	clc
	adc DPJoyOut
	sta DPNowLevel ;mark level
	dec a
	asl a
	asl a
	asl a
	asl a
	asl a
	tax
	phx
	phx
	phx
	phx
	phx
	phx
	phx

	lda.l LevelHeaders+6,x
	jsl KonzertLoadMIDI

	plx
	lda.l LevelHeaders,x
	jsl GKFLoadFields

	plx
	lda.l LevelHeaders+2,x
	jsl GKFLoadScenes

	plx
	lda.l LevelHeaders+4,x
	jsl GKFLoadTint

	plx
	lda.l LevelHeaders+8,x
	sta DPNowGridS
	sta DPGridCount

	asl
	tax
	lda.l PresetGridStart,x
	sta DPGridBegin
	lda.l PresetGridEnd,x
	sta DPGridEnd
	sta DPGridPos
	tax
--	lda.w SPLayer2FG,x
	and #$ff00
	ora #$0030
	sta.w SPLayer2FG,x
	dex
	dec DPGridCount
	bne --
	inx
	txa
	cmp DPGridBegin
	beq ++
	clc
	adc DPNowGridS
	sec
	sbc #$0011
	tax
	lda DPNowGridS
	sta DPGridCount
	bra --
++	jsl RoutineUpdateLayer2

	plx
	lda.l LevelHeaders+10,x
	sta DPNowExt

	plx
	lda.l LevelHeaders+12,x
	jsl RoutineSetTimer

	plx
	lda.l LevelHeaders+14,x
	sta $0123
	lda.l LevelHeaders+16,x
	sta $0125
	lda.l LevelHeaders+18,x
	sta $0127
	lda.l LevelHeaders+20,x
	sta $0129
	lda.l LevelHeaders+22,x
	sta $012B
	lda.l LevelHeaders+24,x
	sta $012D
	jsl RoutineUpdateLayer1

	jsr RoutineRefillZeroes


	lda DPNowLevel ;load high scores from RAM (if available)
	asl
	asl
	asl
	tax
	lda.w OPStoreRecords,x
;	lda.l $700002,x
	ora #$3030
	cmp #$3a00 ;skip upon invalid values
	bpl ++
	sta $0168
	lda.w OPStoreRecords+2,x
;	lda.l $700004,x
	ora #$3030
	sta $016A
	lda.w OPStoreRecords+4,x
;	lda.l $700006,x
	ora #$3030
	sta $016C


++	ldx #$0020 ;clear statistics
-	stz DPStat0s,x
	dex
	dex
	bpl -
	lda #$0088 ;prepare cursor position
	sta DPCursorPos
	sta DPLatestPos
	lda #$0003 ;set tempo divider
	sta DPTimerUnit
	lda DPNowExt ;if 1, set 2 to prevent any new tiles in puzzle mode
	cmp #$0001
	bne +
	inc DPNowExt
+

DekremitLevelRuntime:
	jsl GKFTickTimer ;tick timer
	bpl +
	jmp DekremitLevelDone
+	jsl RoutineUpdateTimer
	jsl RoutineReadJoypad ;check for X/Y/A/B & ^<>v arrow keys
	beq +++
	cmp #$0016
	bpl +++
	tax
	jsr (DekremitLevelVCMDs,x) ;run controller commands
+++	;jsl RoutineUpdateLayer1 ;keep rendering each 256 frames
	jmp DekremitLevelRuntime


DekremitLevelVCMDs:
	dw DekremitLevelRuntime
	dw CursorInteract
	dw CursorInteract
	dw CursorInteract
	dw CursorInteract
	dw CursorMoveUp
	dw CursorMoveLeft
	dw CursorMoveRight
	dw CursorMoveDown
	dw DekremitPauseGame
	dw DekremitPauseGame


CursorInteract:
	sed
	lda DPCStatMoves
	clc
	adc #$0001
	sta DPCStatMoves
	cld
	lda #$0003 ;laad SFX 2
	jsl KonzertPlaySFX
	lda DPCursorPos
	tax
	lda.w SPLayer2FG,x
	and #$00ff
	cmp #$003a ;do not affect beyond numbers
	bpl +++
	lda.w SPLayer2FG,x
	dec a
	sta.w SPLayer2FG,x
	and #$00ff
	cmp #$0080
	bmi +
--	stz DPTimerMil
	stz DPTimerSec
	stz DPTimerMin
	pha
	lda #$0003
	sta DPNowExt ;mark failure byte (hitting an invalid null tile)
	pla
+	cmp #$0030
	bne +++
	lda #$0007
	jsl KonzertPlaySFX ;play SFX 
	lda DPNowExt
	cmp #$0005 ;if expert, end the game at 0s
	beq --
++	sed
	lda DPStat0s
	clc
	adc #$0001
	sta DPStat0s
	lda DPTimerSec
	sec
	sbc #$0003 ;decrement each penalty by 3s (until no further minute left)
	bcs ++
	dec DPTimerMin
	bpl +
	stz DPTimerMil
	stz DPTimerSec
	stz DPTimerMin
	lda #$0000
	bra ++
+	and #$00ff
	sec
	sbc #$0040  ;9999->0059
++	sta DPTimerSec
	cld
	jsr RoutineRefillZeroes ;refill zeroes if 0s (30) is reached
-
+++	jsr RoutineCompareMatches ;compare for three or more matches (row to left, column to up)
	lda DPGridMat
	bne -
	jsl GKFTickTimer ;tick timer
	jsl GKFTickTimer ;tick timer
	jsl GKFTickTimer ;tick timer
	bpl +
	jmp DekremitLevelDone
+	lda DPNowExt
	cmp #$0004 ;if meteor, fill a random (valid) number title with air every 10 moves
	bne +++
	lda DPCStatMoves
	and #$0007 ;check every 10th move
	bne +++
--	jsl RoutineGetRNG
	and #$00ff
	tax
	lda.w SPLayer2FG,x
	and #$00ff
	beq --
	cmp #$0030 ;check if tile is a valid number or not
	bmi --
	cmp #$003a
	bpl --
	lda.w SPLayer2FG,x
	and #$ff00
	sta.w SPLayer2FG,x
	jsl RoutineUpdateLayer2
	lda #$0010 ;laad SFX 1
	jsl KonzertPlaySFX
+++

	rts


CursorMoveUp:
	lda DPCursorPos
	sec
	sbc #$0010
	jmp CursorMoveRoutine

CursorMoveLeft:
	lda DPCursorPos
	dec a
	jmp CursorMoveRoutine

CursorMoveRight:
	lda DPCursorPos
	inc a
	jmp CursorMoveRoutine

CursorMoveDown:
	lda DPCursorPos
	clc
	adc #$0010
	jmp CursorMoveRoutine

CursorMoveRoutine:
	tax
	lda.w SPLayer2FG,x ;check if an actual tile is located there
	and #$00ff
	beq +++
	lda #$003e
	sta.w SPLayer1FG,x ;set cursor to new position
	phx
	lda DPCursorPos
	tax
	lda.w SPLayer1FG,x ;remove cursor in prior position
	and #$ff00
	sta.w SPLayer1FG,x
	plx
	txa
	sta DPCursorPos ;update cursor position for next time
+++	lda #$0002 ;laad SFX 2
	jsl KonzertPlaySFX
	jsl GKFTickTimer ;tick timer
	jsl GKFTickTimer ;tick timer
	jsl RoutineUpdateLayer1
	rts


DekremitPauseGame:
	lda #$0040
	sta $2142 ;send pause signal
	lda #$0008 ;laad SFX 8
	jsl KonzertPlaySFX
	lda #$0001
	sta $2100
---	jsl RoutineReadJoypad
	cmp #$0012
	bne ---
	lda #$00C0
	sta $2142 ;un-pause signal
	lda #$0008 ;laad SFX 8
	jsl KonzertPlaySFX
	lda #$000f
	sta $2100
	rts




DekremitLevelDone:
	lda #$0004 ;load jingle 4
	jsl KonzertLoadMIDI
	lda #$0007 ;load tint 7
	jsl GKFLoadTint
	lda #$000C ;load field C
	jsl GKFLoadFields


	lda DPNowExt
	cmp #$0008 ;check for highest score
	bne +
	lda #$000A ;load jingle A
	jsl KonzertLoadMIDI
	lda #$0005 ;load tint 5
	jsl GKFLoadTint
	lda #$000E ;load field E (MAX)
	jsl GKFLoadFields
+	

	lda DPNowExt
	cmp #$0003 ;check for any failure condition (incomplete puzzle, null tile, etc.)
	bne +
	lda #$0005 ;load jingle 5
	jsl KonzertLoadMIDI
	lda #$0008 ;load tint 2
	jsl GKFLoadTint
	lda #$000F ;load field F (FAIL)
	jsl GKFLoadFields
	bra ++
+	

	;compare current score with high score
	ldx #$ffff
-	inx
	sep #$20 
	lda $0178,x
	cmp $0168,x
	beq -
	bmi ++
	rep #$20 
	lda $0178
	sta $0168
	lda $017a
	sta $016a
	lda $017c
	sta $016c
	lda $017e
	sta $016e
	lda #$000A ;load jingle A
	jsl KonzertLoadMIDI
	lda #$0005 ;load tint 5
	jsl GKFLoadTint
	lda #$0011 ;load field 11 (REC)
	jsl GKFLoadFields
++	rep #$20 
	jsl RoutineUpdateLayer1



	;update high score to RAM table to access later w/ post-sram compatability
	lda DPNowLevel
	asl
	asl
	asl
	tax
	lda $0168
	sta.w OPStoreRecords,x
;	sta.l $700002,x
	lda $016A
	sta.w OPStoreRecords+2,x
;	sta.l $700004,x
	lda $016C
	sta.w OPStoreRecords+4,x
;	sta.l $700006,x

	;get personal statistics
	ldx #$001e
--	ldy #$0000
	lda.l PresetScorePos,x
	sta $c0
	stz $c2
	lda DPStat0s+1,x ;get higher bit
	jsl RoutineBytesASCII
	xba
	cmp #$3100 ;omit 4th digit if unused
	bpl +
	and #$00ff
+	xba
	sta [$c0],y
	iny
	iny
	lda DPStat0s,x ;get lower bit
	jsl RoutineBytesASCII
	sta [$c0],y
	dex
	dex
	bpl --
	jsl RoutineUpdateLayer1



	lda #$1000 ;set tempo divider
	sta DPTimerUnit
	lda #$0004 ;set timer (00:04)
	jsl RoutineSetTimer
--	jsl GKFTickTimer ;wait
	bpl --
	lda #$0080 ;mute jingle
	sta $2142
	lda #$0007 ;load tint 7
	jsl GKFLoadTint
	lda #$000D ;load field D
	jsl GKFLoadFields




---	jsl RoutineReadJoypad ;wait for start button
	cmp #$0012
	bne ---
	lda #$0001 ;laad SFX 1
	jsl KonzertPlaySFX
	lda #$0002 ;laad music 2
	jsl KonzertLoadMIDI
	lda #$0001 ;load field 1
	jsl GKFLoadFields
	lda #$0002 ;load field 2
	jsl GKFLoadFields
	lda #$0002 ;load gfx 2
	jsl GKFLoadScenes
	lda #$000A ;load tint A
	jsl GKFLoadTint
	jsl RoutineUpdateLayer1
	jsl RoutineUpdateLayer2
	jmp DekremitMode

-	nop
	bra -
---	nop
	bra ---


PresetScorePos: ;score positions to write to
	dw $01E3,$01E9,$01EF,$01F5,$01FB ;0-4
	dw $0263,$0269,$026F,$0275,$027B ;5-9
	dw $02E6 ;cursor moves
	dw $02BA,$02DA,$02FA,$031A ;match sizes (3-6)

LevelHeaders: ;per-level settings (Field/GFX/Tint/Music/GridSize/ExtFlags/Timers(MIN:SEC)/LevelName)
	dw $0003,$0003,$0003,$0006,$0008,$0000,$0100
	db " ARCADE 1m        "
	dw $0003,$0003,$0003,$0006,$0008,$0000,$0200
	db " ARCADE 2m        "
	dw $0003,$0003,$0003,$0006,$0008,$0000,$0300
	db " ARCADE 3m        "


	dw $0003,$0003,$0004,$0007,$0008,$0001,$0500
	db " PUZZLE x8        "
	dw $0003,$0003,$0004,$0007,$0009,$0001,$0500
	db " PUZZLE x9        "
	dw $0003,$0003,$0004,$0007,$000A,$0001,$0500
	db " PUZZLE 10        "

	dw $0003,$0003,$0006,$0008,$0008,$0005,$0300
	db " EXPERT 3m        "
	dw $0003,$0003,$0009,$0009,$0008,$0004,$0300
	db " METEOR 3m        "
	dw $0003,$0003,$0005,$0003,$0008,$0006,$0030
	db " WISHES 30s       "



PresetGridStart: ;where to start a grid from
	dw $00,$88,$77,$77,$66,$66,$55,$55,$44,$44,$33,$33,$22,$22

PresetGridEnd: ;where to end a grid from
	dw $00,$88,$88,$99,$99,$AA,$AA,$BB,$BB,$CC,$CC,$DD,$DD,$EE

PresetNewTiles: ;chance for each tile to show up:
	dw $31,$32,$33,$34,$35,$36,$37,$38,$39
	dw $31,$32,$33,$34,$35,$36,$37,$38
	dw $31,$32,$33,$34,$35,$36,$37,$38
	dw $31,$32,$33,$34,$35,$36,$37
	dw $31,$32,$33,$34,$35,$36,$37
	dw $31,$32,$33,$34,$35,$36,$37
	dw $31,$32,$33,$34,$35,$36,$37
	dw $31,$32,$33,$34,$35,$36
	dw $31,$32,$33,$34,$35,$36
	dw $31,$32,$33,$34,$35,$36
	dw $31,$32,$33,$34,$35,$36
	dw $31,$32,$33,$34,$35,$36
	dw $31,$32,$33,$34,$35,$36
	dw $31,$32,$33,$34,$35,$36
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34,$35
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33,$34
	dw $31,$32,$33
	dw $31,$32,$33
	dw $31,$32,$33
	dw $31,$32,$33
	dw $31,$32,$33
	dw $31,$32,$33
	dw $31,$32,$33
	dw $31,$32,$33
	dw $31
	dw $00,$00,$00

RoutineClearZeroes:
	stz DPGridMat
	lda DPNowGridS
	sta DPGridCount
	lda DPGridEnd
	sta DPGridPos
	tax
---	lda.w SPLayerX,x
	and #$00ff
	cmp #$0030 ;check for zeroes
	bne ++
	stz.w SPLayerX,x
	inc DPGridMat
	lda.w SPLayer2FG,x
	and #$ff00
	ora #$0030
	sta.w SPLayer2FG,x
++	dex
	dec DPGridCount
	bne ---
	inx
	txa
	cmp DPGridBegin
	beq ++
	clc
	adc DPNowGridS
	sec
	sbc #$0011
	tax
	lda DPNowGridS
	sta DPGridCount
	bra ---
++	jsl RoutineUpdateLayer2
	lda DPGridMat
	rts


RoutineRefillZeroes:
	lda DPNowExt
	cmp #$0006 ;if wishes, check for any stars at the botton
	bne +++
	lda DPGridEnd
	tax
	sec
	sbc #$000c
	sta DPGridComp
--	lda.w SPLayer2FG,x
	and #$00ff
	cmp #$003a ;check for wishing stars
	bne ++
	lda.w SPLayer2FG,x
	and #$ff00
	ora #$0030 ;zero out
	sta.w SPLayer2FG,x
	sed
	lda DPTimerSec
	clc
	adc #$0005
	cmp #$0060
	bmi +
	pha
	lda DPTimerMin
	clc
	adc #$0001
	sta DPTimerMin
	pla
	sec
	sbc #$0060
+	sta DPTimerSec
	cld
	lda #$0001 ;laad SFX C
	jsl KonzertPlaySFX
	bra +++
++	dex
	cpx DPGridComp
	bne --
+++	

	stz DPGridMat
	lda DPNowGridS
	sta DPGridCount
	lda DPGridEnd
	sta DPGridPos
	tax
CheckForZeroes:
---	lda.w SPLayer2FG,x
	stx DPGridPos
	and #$00ff
	cmp #$0030 ;check for zeroes
	bne +++
	inc DPGridMat
--	txa
	sec
	sbc #$0010
	tax
	lda.w SPLayer2FG,x ;check for valid numbers (31-39) above
	and #$00ff
	beq ++ ;if no more tiles exist above, call a random value at the topmost
	cmp #$0031 ;if 1-9, make it fall down
	bmi --
	sta DPGridVal
	lda.w SPLayer2FG,x
	and #$ff00
	ora #$0030
	sta.w SPLayer2FG,x ;zero out prev position
	ldx DPGridPos
	lda.w SPLayer2FG,x
	and #$ff00
	ora DPGridVal
	sta.w SPLayer2FG,x ;move down prev value
	bra +++
++	ldx DPGridPos
	lda.w SPLayer2FG,x ;update lowest-most zero with a random number upon ceiling
	and #$ff00
	phx
	pha
	jsl RoutineGetRNG
	and #$00ff
	;lda $2140 ;get randomized number pointer
	asl
	tax
	lda DPNowExt ;don't refill on extensions 1->2
	cmp #$0002
	bne +
	ldx #$0200
+	pla
	ora.l PresetNewTiles,x
	plx
	sta.w SPLayer2FG,x
	lda DPNowExt ;on wishes, replace 7-9 with falling stars to add time once landed
	cmp #$0006
	bne +++
	lda.w SPLayer2FG,x
	and #$00ff
	cmp #$0037
	bmi +++
	lda.w SPLayer2FG,x
	and #$ff00
	ora #$003A
	sta.w SPLayer2FG,x
+++	ldx DPGridPos
	dex
	dec DPGridCount
	beq +
	jmp CheckForZeroes
+	inx
	txa
	cmp DPGridBegin
	beq ++
	clc
	adc DPNowGridS
	sec
	sbc #$0011
	tax
	lda DPNowGridS
	sta DPGridCount
	jmp CheckForZeroes
++	jsl RoutineUpdateLayer2
	lda DPGridMat
	rts



RoutineCompareMatches: ;check for identical rows/matches (right to left;down to up)
	stz DPGridTop ;highest score
	lda DPNowGridS
	sta DPGridCount
	lda DPGridEnd
	sta DPGridPos
	tax

RoutineCompareLoop:
---	lda.w SPLayer2FG,x
	stx DPGridPos
	stz DPGridMat ;reset amount of matches
	and #$00ff
	cmp #$0030 ;skip zeroes on comparison
	beq +++
	cmp #$003a ;only compare valid numbers
	bpl +++
	sta DPGridVal ;store value to compare from
--	inc DPGridMat
	dex ;check left
	lda.w SPLayer2FG,x
	and #$00ff
	beq +++
	cmp #$0030 ;skip zeroes on comparison
	beq +++
	cmp #$003a ;only compare valid numbers
	bpl +++
	cmp DPGridVal ;compare if before matches with latest value
	bne +++
	bra --
+++	lda DPGridMat
	cmp #$0003 ;check if at least three horizontals match up
	bmi +++
	jsr RoutineScoreMatches
--	inx ;go back right
	lda.w SPLayerX,x
	and #$ff00
	ora #$0030
	sta.w SPLayerX,x
	dec DPGridMat
	bne --

+++	ldx DPGridPos
	lda.w SPLayer2FG,x
	stz DPGridMat ;reset amount of matches
	and #$00ff
	cmp #$0030 ;skip zeroes on comparison
	beq +++
	sta DPGridVal ;store value to compare from
--	inc DPGridMat
	txa
	sec
	sbc #$0010
	tax ;check up
	lda.w SPLayer2FG,x
	and #$00ff
	beq +++
	cmp #$0030 ;skip zeroes on comparison
	beq +++
	cmp #$003a ;only compare valid numbers
	bpl +++
	cmp DPGridVal ;compare if before matches with latest value
	bne +++
	bra --
+++	lda DPGridMat
	cmp #$0003 ;check if at least three verticals match up
	bmi +++
	jsr RoutineScoreMatches
--	txa
	clc
	adc #$0010
	tax ;go back down
	lda.w SPLayerX,x
	and #$ff00
	ora #$0030
	sta.w SPLayerX,x
	dec DPGridMat
	bne --

+++	


	ldx DPGridPos
	dex
	dec DPGridCount
	beq +
	jmp RoutineCompareLoop
+
	inx
	txa
	cmp DPGridBegin
	beq +++
	clc
	adc DPNowGridS
	sec
	sbc #$0011
	tax
	lda DPNowGridS
	sta DPGridCount
	jmp RoutineCompareLoop
+++	lda DPGridTop  ;play sfx based off highest value (3-5 -> 4-6)
	beq +
	inc a
	inc a
-	dec a
	cmp #$0007
	bpl -
	jsl KonzertPlaySFX
+	jsr RoutineClearZeroes
	jsr RoutineRefillZeroes
	jsl RoutineUpdateScore
	rts


RoutineScoreMatches: ;score after each match (value * amount of matches)
	lda DPGridMat
	pha
	pha
	cmp DPGridTop ;set highest per match
	bmi +
	sta DPGridTop
+	phx
	inc a
-	dec a
	cmp #$0007
	bpl -
	asl
	tax
	sed
	lda DPCStatMat3-6,x
	clc
	adc #$0001
	sta DPCStatMat3-6,x
	lda DPGridVal
	and #$000f
	asl
	tax
	lda DPStat0s,x
	clc
	adc DPGridMat
	sta DPStat0s,x
	cld
	plx
	pla
	dec DPGridMat
	lsr DPGridMat
	lda DPGridVal
	and #$000f
	sta DPGridVal
	sed
	clc
	adc DPGridVal
	sta DPGridVal
	clc
	adc DPGridVal
	sta DPGridVal
	clc
	adc DPGridVal
	sta DPGridVal
	clc
	adc DPGridVal
	sta DPGridVal
	clc
	adc DPGridVal
	sta DPGridVal
	clc
	adc DPGridVal
	sta DPGridVal
	clc
	adc DPGridVal
	sta DPGridVal
	clc
	adc DPGridVal
	sta DPGridVal
---	lda DPScoreHund
	clc
	adc DPGridVal
	cmp #$009a
	bmi ++
	pha
	xba
	and #$00ff
	clc
	adc DPScoreTens
	cmp #$009a
	bmi +
	pha 
	xba
	and #$00ff
	clc
	adc DPScoreMils
	cmp #$0100
	bmi +++
	stz DPTimerMin
	stz DPTimerSec
	stz DPTimerMil
	cld
	lda #$0008
	sta DPNowExt
	pla
	pla
	pla
	rts
+++	sta DPScoreMils
	pla
+	and #$00ff
	sta DPScoreTens
	pla
++	and #$00ff
	sta DPScoreHund
;	asl DPGridVal
	dec DPGridMat
;	bne ---
	cld
	pla
	sta DPGridMat
	rts




;	db "BANK00"