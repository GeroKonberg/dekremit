;BANK 01

;FIELDS, SCENES & TINTS
	db "kosiner816 V0.04 (C)2026 GKF Lounge"

GKFLoadFields:
	cmp DPNowField
	bne +
--	rtl
+	sta DPNowField
	dec a
	asl
	asl
	tax
	lda.l FieldDir,x
	sta $c0
	lda.l FieldDir+2,x
	sta $c2
	stz $c4
	stz $c6
	ldy #$0000


---	lda [$c0],y
	and #$00ff
	cmp #$00f0 ;f0-ff = global voice commands
	bmi ++
	cmp #$00ff
	beq +++
	and #$000f
	asl
	tax
	jsr (PresetFieldCommands,x) ;call voice commands
	iny
	bra ---
++	phy
	pha
	dec DPRenderBytedown
	bpl ++
	lda DPRenderBytes
	dec a
	sta DPRenderBytedown
	inc DPRenderRow
	lda DPRenderColumn
	sec
	sbc DPRenderBytes
	sta DPRenderColumn
++	lda DPRenderRow
	asl
	asl
	asl
	asl
	sta DPRenderPos
	lda DPRenderMode
	cmp #$0100 ;check $0100 for mode 0 /ASCII
	bne +
	asl DPRenderPos ;a row is 32 bytes long on 8x8
+	lda DPRenderPos
	clc
	adc DPRenderColumn
	tay
	pla
	sta (DPRenderMode),y
	ply
	inc DPRenderColumn
	iny
	bra ---
+++	
	lda DPRenderMode
	cmp #$0700 ;flip tiles on layer 2 backgrounds
	bne +++
	lda #$0007
	sta DPRenderBytedown
	inc a
	sta DPRenderBytes
--	ldx DPRenderBytedown
	lda.w SPLayer2BG,x
	and #$00ff
	ldx DPRenderBytes
	ora.w SPLayer2BG,x
	sta.w SPLayer2BG,x
	dec DPRenderBytedown
	inc DPRenderBytes
	lda DPRenderBytes
	and #$000f
	bne --
	lda DPRenderBytedown
	clc
	adc #$0018
	sta DPRenderBytedown
	inc
	sta DPRenderBytes
	cmp #$0108
	bne --
+++
	jsl RoutineUpdateLayer1
	jsl RoutineUpdateLayer2
	rtl


PresetFieldCommands: ;voice commands f0-ff
	dw FieldVCMDf0
	dw FieldVCMDf0
	dw FieldVCMDf0
	dw FieldVCMDf0
	dw FieldVCMDf4
	dw FieldVCMDf5
	dw FieldVCMDf6
	dw FieldVCMDf7
	dw FieldVCMDf8
	dw FieldVCMDf9
	dw FieldVCMDfa
	dw FieldVCMDfb
	dw FieldVCMDfc
	dw FieldVCMDfd
	dw FieldVCMDfe
	
FieldVCMDf0: ;layer 1 ASCII, FG: layer2 FG, BG
	lda.l PresetFieldModes,x
	sta DPRenderMode
	stz DPRenderBytes
	stz DPRenderRow
	stz DPRenderColumn
	stz DPRenderPos
	txa
	bne +
	lda #$0020  ;a row is 32 bytes long on 8x8
	bra ++
+	lda #$0010
++	sta DPRenderBytes
	sta DPRenderBytedown
	stz DPRenderColor
	rts

FieldVCMDf4:
	rts

FieldVCMDf5:
	rts

FieldVCMDf6:
	rts

FieldVCMDf7:
	rts

FieldVCMDf8:
	rts

FieldVCMDf9: ;jump to location (useful for reusing settings)
	iny
	lda [$c0],y
	sta $c0
	ldy #$ffff
	rts

FieldVCMDfa: ;row/column
	iny
	lda [$c0],y
	and #$00ff
	sta DPRenderRow
	iny
	lda [$c0],y
	and #$00ff
	sta DPRenderColumn
	lda DPRenderBytes
	sta DPRenderBytedown
	rts

FieldVCMDfb: ;bytes per line
	iny
	lda [$c0],y
	and #$00ff
	sta DPRenderBytes
	sta DPRenderBytedown
	rts

FieldVCMDfc: ;color palette
	rts

FieldVCMDfd: ;delay words before next operation
	iny
	lda [$c0],y
-	dec
	bne -
	iny
	rts

FieldVCMDfe: ;erase entire mode page
	phy
	ldy #$00ff
	lda DPRenderMode
	cmp #$0100 ;create a larger clear buffer for 8x8 ASCII
	bne +
	ldy #$03ff
+	lda #$0000
--	sta (DPRenderMode),y
	dey
	bpl --
	ply
	rts


PresetFieldModes: ;pages to write each mode in
	dw $0100,$0500,$0600,$0700

PresetFieldVRAM: ;halves of E000 and E800 respectively
	dw $0F00,$0F00,$1700,$1700
;	dw $7000,$7000,$7400,$7400

FieldDir:
	dd Field01
	dd Field02
	dd Field03
	dd Field04
	dd Field05
	dd Field06
	dd Field07
	dd Field08
	dd Field09
	dd Field0A
	dd Field0B
	dd Field0C
	dd Field0D
	dd Field0E
	dd Field0F
	dd Field10
	dd Field11
	dd Field12
	dd Field13
	dd Field14
	dd Field15
	dd Field16
	dd Field17
	dd Field18
	dd Field19
	dd Field1A
	dd Field1B
	dd Field1C
	dd Field1D
	dd Field1E
	dd Field1F


Field01: ;GKF Logo
	db $F0 ;layer 1 ASCII
	db $FE ;clear out pages
	db $FA,$04,$0A ;set row/column
	db "Gero  Konberg"
	db $FA,$17,$0B ;set row/column
	db "Foundation"
	db $F1 ;layer 1 FG
	db $FE ;clear out pages
	db $FA,$03,$04 ;set row/column
	db $FB,$08 ;bytes per line
	db $80,$81,$82,$83,$84,$85,$86,$87
	db $88,$89,$8A,$8B,$8C,$8D,$8E,$8F
	db $90,$91,$92,$93,$94,$95,$96,$97
	db $98,$99,$9A,$9B,$9C,$9D,$9E,$9F
	db $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7
	db $A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF
	db $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7
	db $B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF
	db $FF ;end all operations


Field02: ;DEKREMIT title
	db $F0 ;layer 1 ASCII
	db $FE
	db $FA,$17,$05
	db "- Press START button -"

	db $F1 ;layer 1 FG
	db $FE
	db $FA,$08,$09
	db $3E ;set cursor

	db $F2 ;layer 2 FG
	db $FE
	db $FA,$05,$05
	db $FB,$06
	db "115221" ;example grid
	db "252331"
	db "133124"
	db "223341"
	db "532113"
	db "123122"
	db $F3 ;layer 2 BG
	db $FE
	db $FB,$08 ;bytes per line
	db $80,$81,$82,$83,$84,$85,$86,$87 ;background
	db $88,$89,$8A,$8B,$8C,$8D,$8E,$8F
	db $90,$91,$92,$93,$94,$95,$96,$97
	db $98,$99,$9A,$9B,$9C,$9D,$9E,$9F
	db $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7
	db $A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF
	db $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7
	db $B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF
	db $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7
	db $A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF
	db $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7
	db $B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF
	db $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7
	db $A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF

FCallLogotype:

	db $F0 ;layer 1 ASCII
	db $FA,$05,$1F
	db $17 ;trademark symbol
	db $FA,$1A,$07
	db $16," 2026 GKF Lounge"

	db $F1 ;layer 1 FG
	db $FA,$01,$00
	db $40,$41,$42,$43,$44,$45,$46,$47,$60,$61,$62,$63,$64,$65,$66,$67 ;DEKREMIT logo
	db $48,$49,$4A,$4B,$4C,$4D,$4E,$4F,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F
	db $50,$51,$52,$53,$54,$55,$56,$57,$70,$71,$72,$73,$74,$75,$76,$77
	db $58,$59,$5A,$5B,$5C,$5D,$5E,$5F,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F

	db $F3 ;layer 2 BG seed
	db $FF ;end all operations


Field03: ;DEKREMIT game
	db $F0 ;layer 1 ASCII
	db $FE
;	db $FA,$01,$04
;	db "MODEUS xM"
	db $FA,$03,$02
	db "BEST  0000000"
	db $FA,$03,$12
	db "SCORE 0000000"
	db $FA,$01,$12
	db "TIME 00:00:00"

	db $F1
	db $FE
	db $FA,$08,$08
	db $3E ;set cursor to middle null [1]

	db $F2 ;layer 2 FG
	db $FE
;	db $FA,$04,$04
;	db $FB,$08 ;example grid: clear this after testing
;	db "78888888"
;	db "85666668"
;	db "86344468"
;	db "86412468"
;	db "86422468"
;	db "86444468"
;	db "86666668"
;	db "88888888"

	db $F3 ;layer 2 BG
	db $FE
	db $FB,$08 ;bytes per line
	db $80,$80,$80,$80,$80,$80,$80,$80
	db $80,$80,$80,$80,$80,$80,$80,$80
	db $80,$80,$80,$80,$80,$80,$80,$80
	db $80,$80,$80,$80,$80,$80,$80,$80
	db $80,$80,$80,$80,$80,$80,$80,$80
	db $80,$80,$80,$80,$80,$80,$80,$80
	db $80,$81,$82,$83,$84,$85,$86,$87
	db $88,$89,$8A,$8B,$8C,$8D,$8E,$8F
	db $90,$91,$92,$93,$94,$95,$96,$97
	db $98,$99,$9A,$9B,$9C,$9D,$9E,$9F
	db $A0,$A1,$A2,$A3,$A4,$A5,$A6,$A7
	db $A8,$A9,$AA,$AB,$AC,$AD,$AE,$AF
	db $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7
	db $B8,$B9,$BA,$BB,$BC,$BD,$BE,$BF
	db $FF

Field04: ;INIT menu
	db $F0
	db $FE
	db $FA,$0C,$08
	db "- SELECT  MODE -"
	db $FA,$0F,$09
	db " <X> Arcade "
	db $FA,$12,$04
	db "<Y> Puzzle   <A> Quest "
	db $FA,$15,$09
	db "<B> Settings"
	db $FA,$17,$05
	db "                     "
	db $F1

	db $FA,$08,$09
	db $60 ;remove cursor
	db $F2
	db $FE
	db $F9 ;jump to below location
	dw FCallLogotype
	db $FF

Field05: ;ARCADE menu
	db $F0
	db $FA,$0C,$08
	db "- ARCADE  MODE -"
	db $FA,$0F,$09
	db " <X> 1 mins "
	db $FA,$12,$04
	db "<Y> 2 mins   <A> 3 mins"
	db $FA,$15,$09
	db " <B> Return "
	db $FF

Field06: ;PUZZLE menu
	db $F0
	db $FA,$0C,$08
	db "- PUZZLE  MODE -"
	db $FA,$0F,$09
	db " <X> 8 x 8  "
	db $FA,$12,$04
	db "<Y> 9 x 9    <A> 10x10 "
	db $FA,$15,$09
	db " <B> Return "
	db $FF

Field07: ;QUEST menu
	db $F0
	db $FA,$0C,$08
	db " - QUEST MODE - "
	db $FA,$0F,$09
	db " <X> Expert "
	db $FA,$12,$04
	db "<Y> Meteor   <A> Wishes"
	db $FA,$15,$09
	db " <B> Return "
	db $FF


Field08: ;OPTION menu
	db $F0
	db $FA,$0C,$08
	db "- OPTION  MODE -"
	db $FA,$0F,$09
	db " <X> Rules  "
	db $FA,$12,$04
	db "<Y> Sound   <A> Credits"
	db $FA,$15,$09
	db " <B> Return "
	db $FF

Field09: ;RULES menu
	db $F2
	db $FE
	db $F1
	db $FE
	db $F0
	db $FE
	db $FA,$02,$08
	db " - RULES MODE - "

	db $FA,$05,$03
	db "Move your cursor across the"
	db $FA,$06,$05
	db "grid using arrow keys,"
	db $FA,$07,$04
	db "push A/B/X/Y to decrement"
	db $FA,$08,$06
	db "any number selected."

	db $FA,$0A,$03
	db "Sequences of three or more"
	db $FA,$0B,$06
	db "identical numbers"
	db $FA,$0C,$04
	db "in a row or column are"
	db $FA,$0D,$07
	db "to be validated,"

	db $FA,$0F,$03
	db "with higher numbers giving"
	db $FA,$10,$06
	db "out greater scores."
	db $FA,$11,$04
	db "Decrementing any 1s will"
	db $FA,$12,$03
	db "result in a score penalty."

	db $FA,$14,$01
	db "Get as many scores as possible"
	db $FA,$15,$02
	db "before running out of time,"
	db $FA,$16,$00
	db "try out your luck in 1-5 minutes"
	db $FA,$17,$03
	db "on different sized grids."

	db $FA,$1A,$05
	db "- Press START button -"
	db $FF

Field0A: ;SOUND MODE
	db $F0
	db $FA,$0C,$08
	db " - SOUND MODE - "
	db $FA,$0F,$09
	db " <X> MUS +  "
	db $FA,$12,$04
	db "<Y> MUS -    <A> SFX + "
	db $FA,$15,$09
	db " <B> SFX -  "	
	db $FA,$17,$05
	db "- Press START button -"
	db $FF

Field0B: ;CREDITS MODE
	db $F0
	db $FE
	db $FA,$0C,$08
	db "- CREDITS MODE -"
	db $FA,$0E,$03
	db "lead developer & producer"
	db $FA,$0F,$0A
	db "GERO KONBERG"
	db $FA,$11,$05
	db "arts & puzzle designer"
	db $FA,$12,$0A
	db "TILL  FELDT"
	db $FA,$14,$05
	db "music & sound effects"
	db $FA,$15,$0A
	db "JAHN KELLER"
	db $FA,$17,$05
	db "- Press START button -"
	db $F9 ;jump to below location
	dw FCallLogotype
	db $FF

Field0C: ;END OF GAME
	db $F0 ;layer 1 ASCII
	db $FA,$01,$12
	db "END"
	db $12 ;done symbol
	db $FA,$07,$04
	db "000"
	db $FA,$07,$0A
	db "000"
	db $FA,$07,$10
	db "000"
	db $FA,$07,$16
	db "000"
	db $FA,$07,$1C
	db "000"
	db $FA,$0B,$04
	db "000"
	db $FA,$0B,$0A
	db "000"
	db $FA,$0B,$10
	db "000"
	db $FA,$0B,$16
	db "000"
	db $FA,$0B,$1C
	db "000"
	db $FA,$0F,$06
	db " 000"
	db $FA,$0D,$17
	db "3`  000"
	db $FA,$0E,$17
	db "4`  000"
	db $FA,$0F,$17
	db "5`  000"
	db $FA,$10,$17
	db "6`  000"

	db $FA,$17,$1F
	db $17 ;trademark symbol

	db $F1
	db $FE
	db $FA,$07,$02
	db "?" ;cursor
	db $FA,$0A,$00
	db $40,$41,$42,$43,$44,$45,$46,$47,$60,$61,$62,$63,$64,$65,$66,$67 ;DEKREMIT logo
	db $48,$49,$4A,$4B,$4C,$4D,$4E,$4F,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F
	db $50,$51,$52,$53,$54,$55,$56,$57,$70,$71,$72,$73,$74,$75,$76,$77
	db $58,$59,$5A,$5B,$5C,$5D,$5E,$5F,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F

	db $F2
	db $FE
	db $FA,$03,$01
	db "0"
	db $FA,$03,$04
	db "1"
	db $FA,$03,$07
	db "2"
	db $FA,$03,$0A
	db "3"
	db $FA,$03,$0D
	db "4"

	db $FA,$05,$01
	db "5"
	db $FA,$05,$04
	db "6"
	db $FA,$05,$07
	db "7"
	db $FA,$05,$0A
	db "8"
	db $FA,$05,$0D
	db "9"


	db $FF

Field0D:
	db $F0
	db $FA,$13,$05
	db "- Press START button -"

	db $FF

Field0E:
	db $F0 ;layer 1 ASCII
	db $FA,$01,$12
	db "MAX`"
	db $FF

Field0F:
	db $F0 ;layer 1 ASCII
	db $FA,$01,$12
	db "FAIL"
;	db $13 ;fail symbol
	db $FF

Field10: ;MODES explanation
	db $F1
	db $FE
	db $F0
	db $FE
	db $FA,$02,$08
	db " - GAME MODES - "

	db $FA,$05,$0C
	db "[PUZZLE]"
	db $FA,$06,$03
	db "Clear out the entire grid"
	db $FA,$07,$01
	db "with the help of matches while"
	db $FA,$08,$05
	db "escaping suffocation."

	db $FA,$0A,$0C
	db "[EXPERT]"
	db $FA,$0B,$04
	db "Get as many matches as"
	db $FA,$0C,$03
	db "possible without cheating"
	db $FA,$0D,$03
	db "on any one tile upon force."

	db $FA,$0F,$0C
	db "[METEOR]"
	db $FA,$10,$01
	db "Each cursor tap slowly causes"
	db $FA,$11,$01
	db "the grid to decay, be careful"
	db $FA,$12,$02
	db "when and where to decrement."

	db $FA,$14,$0C
	db "[WISHES]"
	db $FA,$15,$02
	db "Stars falling from the sky"
	db $FA,$16,$01
	db "reward up to 5 extra seconds"
	db $FA,$17,$01
	db "once landing at ground level."

	db $FA,$1A,$05
	db "- Press START button -"
	
	db $FF

Field11:
	db $F0 ;layer 1 ASCII
	db $FA,$01,$12
	db "REC"
	db $11 ;save symbol
	db $FF

Field12:
	db $FF

Field13:
	db $FF

Field14:
	db $FF

Field15:
	db $FF

Field16:
	db $FF

Field17:
	db $FF

Field18:
	db $FF

Field19:
	db $FF

Field1A:
	db $FF

Field1B:
	db $FF

Field1C:
	db $FF

Field1D:
	db $FF

Field1E:
	db $FF

Field1F:
	db $FF



PresetTintRows: ;palette assigned to each tile
	db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;ASCII
	db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;ASCII

	db $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;TILES
	db $04,$04,$05,$05,$00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$03,$03 ;NUMBERS & CURSOR

	db $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06 ;DEKREMIT
	db $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06 ;DEKREMIT

	db $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06 ;DEKREMIT
	db $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06 ;DEKREMIT
	
	db $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07 ;SCENERY
	db $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07 ;SCENERY

	db $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07 ;SCENERY
	db $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07 ;SCENERY




GKFLoadScenes:
	cmp DPNowScene
	bne +
	rtl
+	sta DPNowScene
	dec a
	asl
	asl
	tax
	lda.l SceneDir,x
	sta $c0
	lda.l SceneDir+2,x
	sta $c2
	lda #$007e
	sta $c6
	lda #$2000
	sta $c4
;	sta $2116
	ldy #$0000
--	lda [$c0],y
	sta [$c4],y
	iny
	iny
	tya
	cmp #$2000
	beq +
	bra --
+	
	lda #$008F
	sta $2100
	jsr RoutineSendGFX
	lda #$000F
	sta $2100
	rtl

SceneDir:
	dd Scene01
	dd Scene02
	dd Scene03




GKFLoadTint:
	cmp DPNowTint
	bne +
	rtl
+	sta DPNowTint
	dec a
	asl
	asl
	tax
	lda #$008F
	sta $2100
	lda.l TintDir,x
	sta $c0
	lda.l TintDir+2,x
	sta $c2
	lda #$0070
	sta $2121
	stz $2122
	ldy #$0003
--	jsl GKFRoutineTint
	cmp #$002F
	beq +
	iny
	bra --
+	lda #$000F
	sta $2100
	rtl

GKFRoutineTint:
	lda [$c0],y
	and #$00f8
	lsr
	lsr
	lsr
	sta DPStack+1
	iny
	lda [$c0],y
	pha
	and #$0038
	asl
	asl
	ora DPStack+1
	sta DPStack+1

	pla
	and #$00C0
	lsr
	lsr
	lsr
	lsr
	lsr
	lsr
	sta DPStack+2
	iny
	lda [$c0],y
	and #$00f8
	lsr
	ora DPStack+2
	sta DPStack+2
	lda DPStack+1
	sta $2122
	lda DPStack+2
	sta $2122
	tya
	rtl

TintDir:
	dd Tint01
	dd Tint02
	dd Tint03
	dd Tint04
	dd Tint05
	dd Tint06
	dd Tint07
	dd Tint08
	dd Tint09
	dd Tint0A


RoutineUpdateLayer1: ;16x16 L1BG (500-5FF) -> 8x8 ASCII override (100-4FF)
	stz $c6
	ldx #$0002 ;layer 1 FG [16x16]
	jsr RoutineClearTilemap
	jsr RoutineUpdateLayers16

RoutineUpdateLayerASCII:
	lda #$0400
	sta DPRenderEnd
	stz $c6
	ldx #$0000 ;layer 1 ASCII [8x8]
	lda.l PresetFieldModes,x
	sta $c0
	stz $c2
	lda.l PresetFieldVRAM,x ;write to layer 1 tilemap
	sta DPRenderPos
	stz DPRenderBytes ;use to count double rows
	ldy #$0000
---	lda [$c0],y ;get layer 1 ASCII data
	and #$00ff
	beq +++
	tax
	lda DPRenderPos
	sta $c4
	lda.l PresetTintRows
	and #$00ff
	asl
	asl
	ora #$0020 
	xba
	sta DPRenderColor
	txa
	clc
	adc DPRenderColor
	sta ($c4)
	inc $c4
	inc $c4
+++	inc DPRenderPos
	inc DPRenderPos
	iny
	tya
	cmp DPRenderEnd
	bmi ---
;	lda #$000F
;	sta $2100
	stz DPRenderEnd
	jsr RoutineSendTiles
	rtl


RoutineUpdateLayer2: ;16x16 L2BG (700-7FF mirrored) -> 16x16 L2FG override (600-6FF)
;	lda #$008F
;	sta $2100
	stz $c6
	ldx #$0006
	jsr RoutineUpdateLayers16
	ldx #$0004
	jsr RoutineUpdateLayers16
	jsr RoutineSendTiles
;	lda #$000F
;	sta $2100
	rtl

RoutineUpdateLayers16: ;global routine for all 16x16 renders
	lda.l PresetFieldModes,x
	sta $c0
	stz $c2
	stz $c6
	lda.l PresetFieldVRAM,x ;write to layer 1 tilemap
	sta DPRenderPos
	stz DPRenderBytes ;use to count double rows
	ldy #$0000
---	lda [$c0],y ;get layer 1 FG data
	and #$00ff
	beq +++ ;dont draw anything on 00
	tax
	lda DPRenderPos
	sta $c4
	lda.l PresetTintRows,x ;get palette information
	and #$00ff
	asl
	asl
	ora #$0020 
	xba
	sta DPRenderColor
	lda $c0
	cmp.w #SPLayer2BG ;apply X-flipping to layer 2 backgrounds
	bne ++
	tya
	and #$000f
	cmp #$0008
	bmi ++
	lda DPRenderColor
	ora #$4000 ;x flag on latter half
	sta DPRenderColor
	txa
	beq +
	asl
	sta DPRenderBytedown
	and #$fff0
	clc
	adc DPRenderBytedown ;obtain 8x8s out of 16x16 tiles
+	clc
	adc DPRenderColor
	clc
	adc DPRenderBytes
	inc
	sta ($c4)
	inc $c4
	inc $c4
	dec
	sta ($c4)
	inc $c4
	inc $c4
	bra +++
--	bra ---
++	txa
	beq +
	asl
	sta DPRenderBytedown
	and #$fff0
	clc
	adc DPRenderBytedown ;obtain 8x8s out of 16x16 tiles
+	clc
	adc DPRenderColor
	clc
	adc DPRenderBytes
	sta ($c4)
	inc $c4
	inc $c4
	inc
	sta ($c4)
	inc $c4
	inc $c4
+++	;lda #$008F
	;sta $2100
	inc DPRenderPos
	inc DPRenderPos
	inc DPRenderPos
	inc DPRenderPos
	iny
	tya
	and #$000f
	bne --
	lda DPRenderBytes ;check if the second 8x8 has been processed
	bne +++
	lda #$0010
	sta DPRenderBytes
	tya
	sec
	sbc #$0010
	tay
	bra --
+++	stz DPRenderBytes
	tya
	cmp #$00e0 ;check if the entire layer has been drawn
	bmi --
	rts



RoutineClearTilemap: ;clear all (visible) bytes per 4 modes
	lda.l PresetFieldVRAM,x ;write to layer 1 tilemap
	sta $c4
	ldy #$0000
---	lda #$0000
	sta ($c4)
	inc $c4
	inc $c4
	iny
	tya
	cmp #$0380
	bmi ---
	rts


RoutineCheckVBlank:
	pha
-	lda $4212
	and #$0080 ;check for vblank
	beq -
	pla
	rts



RoutineSendGFX:
	jsr RoutineCheckVBlank
	lda #$2000 ;set up VRAM address
	sta $2116
	lda #$007e ;RAM addr bank
	ldx #$2000 ;RAM addr pos
	ldy #$2000 ;amounts to copy
	bra RoutineSendVRAM



RoutineSendTiles:
	lda #$7000 ;set up VRAM address
	sta $2116

	lda #$0000 ;RAM addr bank
	ldx #$0f00 ;RAM addr pos
	ldy #$1000 ;amounts to copy

RoutineSendVRAM:
	jsr RoutineCheckVBlank

	php         ; Preserve Registers
    stx $4302   ; Store Data offset into DMA source offset
	sep #$20
    sta $4304   ; Store data Bank into DMA source bank
    sty $4305   ; Store size of data block

    lda #$01
    sta $4300   ; Set DMA mode (word, normal increment)
    lda #$18    ; Set the destination register (VRAM write register)
    sta $4301
    lda #$01    ; Initiate DMA transfer (channel 1)
    sta $420B
	
	plp         ; restore registers
    rts         ; return


Scene01: ;GKF logo
	incbin "visuals/Scene01A.bin"
	incbin "visuals/Scene01B.bin"

Scene02: ;title & menus
	incbin "visuals/Scene02A.bin"
	incbin "visuals/Scene02B.bin"

Scene03: ;gameplay
	incbin "visuals/Scene03A.bin"
	incbin "visuals/Scene03B.bin"

Tint01:
	incbin "visuals/Tint01.pal"
Tint02:
	incbin "visuals/Tint02.pal"
Tint03:
	incbin "visuals/Tint03.pal"
Tint04:
	incbin "visuals/Tint04.pal"
Tint05:
	incbin "visuals/Tint05.pal"
Tint06:
	incbin "visuals/Tint06.pal"
Tint07:
	incbin "visuals/Tint07.pal"
Tint08:
	incbin "visuals/Tint08.pal"
Tint09:
	incbin "visuals/Tint09.pal"
Tint0A:
	incbin "visuals/Tint0A.pal"


;	db "BANK01"

