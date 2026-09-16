;BANK 02



;Sound driver & global settings
	db "konzert700 V0.44C (C)2026 GKF/J.Keller"
	;SCRATCH RAM during loading
	;c0-c3 MIDI read address
	;c4-c7 Sequence output
	;c8-cb Pointer output
	;cc-cd Amount of channels to read (compare during FF 2F 00)
	;ce-cf ???
	;d0	last program change (Cx program change) [$E0 inst]
	;d2	last panning (CC#0A) [$E1 pan]
	;d4 last time sig [$E2]
	;d6	last modulation (CC#01) [$E3 00-7F vib]
	;d8 last mod delay (CC#02) [$E4 00-7F]

	;dc last reverb (CC#5B) [$E6]
	;de last tempo (META#51) [$E7]

	;e4	last bend (Ex pitch wheel) [$EA]
	;e6 last chorus (CC#5D) [$EB trem]

	;ea	last volume (CC#07) [$ED vol]
	;ec last start (CC#??) [$EE start]
	;ee last termination [$EF end]


	;f0 last note key
	;f2 last note vel
	;f4 last note delta
	;fc-fe last wait delta
	;fa total wait delta
	;f6 loop wait delta (in case time signature 1/x has been invoked)
	
KonzertLoadMIDI:
	cmp DPNowMusic
	bne +
	rtl
+	sta DPNowMusic
	dec a
	asl
	asl
	tax
	lda.l SongDir,x
	sta $c0
	lda.l SongDir+2,x
	sta $c2
	lda #$2000
	sta $c4
	inc
	sta $c8
	lda #$007e
	sta $c6
	sta $ca
	ldy #$000b
	lda [$c0],y
	asl
	sta $cc
	lsr
	jsr KonzertSubWriter
	lda $7e2000
	asl
	adc $c4
	sta $c4
	ldx #$0000
	iny
	iny
	iny
KonzertLoopMIDI: ;MIDI loop
---	jsr KonzertUpdateWord
	lda [$c0],y
	cmp #$544d ;check for new track
	bne ++
	txy
	lda $c4
	sec
	sbc #$2000
	sta [$c8],y
	stz $ce
	stz $d0
	stz $d2
	dec $d2
	stz $d4
	stz $d6
	stz $d8
	stz $da
	stz $dc
	stz $de
	stz $e0
	stz $e2
	stz $e4
	stz $e6
	stz $e8
	stz $ea
	stz $ec
	stz $ee
	stz $f0
	stz $f2
	stz $f4
	stz $f6
	stz $f8
	stz $fa
	inx
	inx
	ldy #$0008
--	jsr KonzertReadDelta
	bra ---
-	nop
	bra -
++	and #$00ff ;read one value at a time
	cmp #$00ff ;meta event
	bne +
	jmp KonzertEventMeta
+	cmp #$0080 ;note events 80-ef
	bmi ++
	phx
	and #$0070
	lsr
	lsr
	lsr
	tax
	jsr (KonzertEventsTable,x)
	plx
	bra --
++
-	nop
	bra -
	rtl


KonzertEventsTable:
	dw KonzertEventOff ;8x
	dw KonzertEventOn ;9x
	dw KonzertEventPoly ;Ax
	dw KonzertEventCC ;Bx
	dw KonzertEventInst ;Cx
	dw KonzertEventPres ;Dx
	dw KonzertEventBend ;Ex
	dw KonzertEventSys ;Fx

KonzertEventOff:
	iny
	lda [$c0],y ;get note to key off and check if it's the actual latest note
	iny
	iny
	and #$00ff
	cmp $f0
	bne +++
	pha
	jsr KonzertWriteDelta
	pla
	dec $c4
	lda [$c4],y
	and #$00ff
	cmp #$0040 ;verify for actual delta instructions
	bpl ++
	ora #$0040  ;set note-off flags in latest delta
	jsr KonzertSubWriter
+++	rts
++	inc $c4
	rts

KonzertEventOn:
	jsr KonzertWriteDelta
	iny
	lda [$c0],y ;get velocity
	pha
	xba
	and #$00ff
	lsr
	lsr
	lsr
	cmp $f2  ;check for duplicates
	beq ++
	sta $f2
	ora #$00f0
	jsr KonzertSubWriter
++	pla ;get key
	and #$00ff
	sta $f0
	sec
	sbc #$000c
	ora #$0080
	jsr KonzertSubWriter
	iny
	iny
	rts

KonzertEventPoly:
-	nop
	bra -

KonzertEventCC:
	phx
	iny
	lda [$c0],y
	and #$00ff
	iny
	tax
	lda.l PresetCCLookup,x
	and #$00ff
	beq +++
	asl
	tax
	lda [$c0],y
	cmp $d0,x
	beq +++
	sta $d0,x
	jsr KonzertWriteDelta
	txa
	lsr
	ora #$00e0
	jsr KonzertSubWriter
	lda $d0,x
	jsr KonzertSubWriter
+++	iny
	plx
	rts


PresetCCLookup: ;$00 = skip byte
	db $00,$03,$04,$00, $00,$00,$00,$0D, $00,$00,$01,$0D, $00,$00,$0e,$00 ;00-0f
	db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00 ;10-1f
	db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00 ;20-2f
	db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00 ;30-3f
	db $00,$0C,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00 ;40-4f
	db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$06, $0B,$0B,$00,$00 ;50-5f
	db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00 ;60-6f
	db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00 ;70-7f

;PresetCCMemory: ;memory locations $E0-$EF -> X offset from $00/d0-ff
;	dw $d0,$d4,$e4,$d8, $da,$e0,$de,$e2, $00,$00,$d6,$dc, $e6,$00,$00,$00

KonzertEventInst:
	jsr KonzertWriteDelta
	iny
	lda [$c0],y
	and #$00ff
	cmp $d0 ;check for duplicates
	beq ++
	sta $d0
	pha
	lda #$00e0
	jsr KonzertSubWriter
	pla
	jsr KonzertSubWriter
++	iny
	rts

KonzertEventPres:
-	nop
	bra -

KonzertEventBend:
	iny
	lda [$c0],y
	asl
	xba
	and #$00ff
	cmp $e4 ;check for duplicates
	beq ++
	sta $e4
	jsr KonzertWriteDelta
	pha
	lda #$00ea
	jsr KonzertSubWriter
	pla
	jsr KonzertSubWriter
++	iny
	iny
	rts

KonzertEventSys:
-	nop
	bra -

KonzertEventMeta:
	iny
	lda [$c0],y
	and #$00ff
	cmp #$002f ;end track
	bne ++
	lda #$00ef
	jsr KonzertSubWriter
	txa
	cmp $cc  ;check if all tracks have been processed
	bne +
	jmp KonzertCompileMIDI
+	bra +++
++	cmp #$0051 ;tempo
	bne ++
	iny
	iny ;skip meta length
	lda [$c0],y ;read 1/3
	and #$00ff
	asl
	asl
	asl
	asl
	sta $fe
	iny
	lda [$c0],y ;read 2/3
	and #$00f0
	lsr
	lsr
	lsr
	lsr
	clc
	adc $fe
	cmp $de ;check for duplicate
	beq +
	jsr KonzertWriteDelta
	sta $de
	pha
	lda #$00e7
	jsr KonzertSubWriter
	pla
	jsr KonzertSubWriter
+	iny ;skip 3/3
	bra +++
++	
KonzertSkipMeta:
	iny
	jsr KonzertUpdateWord
	lda [$c0],y
	and #$00ff
	tay
+++	iny
	jsr KonzertReadDelta
	jmp KonzertLoopMIDI


KonzertReadDelta:
	stz $fc
	stz $fe
	lda [$c0],y
	and #$00ff
	beq +++ ;skip at null
;	pha
;	lda $e6 ;check last key (reset on every new track for rests)
;	bne +
;	lda #$0080 ;assuming custom note length since the track has just started
;	jsr KonzertSubWriter
;+	pla
	cmp #$0080
	bpl ++ ;use highest bit
	bra +
++	sta $fe ;store hi bit
	iny
-	lda [$c0],y
	and #$00ff
	cmp #$0080
	bmi +
	iny
	bra -
+	clc
	lsr
	bcc +
	inc $f8 ;check for overflows (two halfes equal one new tick)
+	sta $fc ;store low bit
-	lda $f8
	cmp #$0002
	bmi +
	dec $f8
	dec $f8
	inc $fc
	bra -
+	lda $fc
	clc
	adc $fd
	and #$7fff
	clc
	adc $fa
	sta $fa ;add on to the latest delta backup
	and #$00ff
	cmp #$0040 ;compare for lower value overflows
	bmi +++
	lda $fa
	clc
	adc #$00c0 ;minus 40 plus 100
	sta $fa
+++	iny
	rts

KonzertSubWriter:
	phy
	and #$00ff
	ldy #$0000
	sta [$c4],y
	lda $c4
	inc $c4
	ply
;	iny
	jsr KonzertUpdateWord
	rts

KonzertWriteDelta: ;write delta wait (00-7Fs) whenever necessary
	pha
	lda $fa
	beq +++
	cmp #$0100
	bmi ++
	lda #$00e8
	jsr KonzertSubWriter
	lda $fb
	and #$00ff
	jsr KonzertSubWriter
++	lda $fa
	and #$00ff
	jsr KonzertSubWriter
	stz $fa
	stz $fc
	stz $fe
+++ pla
	rts


KonzertUpdateWord:
	tya
	clc
	adc $c0
	sta $c0
	ldy #$0000
	rts

KonzertCompileMIDI: ;send compressed data to SPC I/O
	stz DPRenderDelay
	lda #$0001 ;tick SPC back to IPL
	sta $2140
	lda $474f
	jsr KonzertSubWriter
	lda $4f47
	jsr KonzertSubWriter
	lda $474f
	jsr KonzertSubWriter
	lda $4f47
	jsr KonzertSubWriter
	lda #!RangeMusic-1
	sta $2142
	lda #$2000 ;$7e2000 freeram buffer location
	sta $c0
	lda #$007e
	sta $c2
	jsr RoutineProgramLoader
	lda DPNowMusic
	and #$00ff
	sta $2142
	rtl


KonzertPlaySFX:
	cmp DPNowSFX
	bne +
	eor #$0080
+	and #$00ff
	sta DPNowSFX
	sta $2143
	rtl



KonzertInstDriver: ;inst sound driver to SPC
	stz DPRenderDelay
	lda.l KonzertSndDir
	sta $c0
	lda.l KonzertSndDir+2
	sta $c2
	lda #$02ff ;begin sound driver (-1)
	sta $2142
	jsr RoutineProgramLoader
	rtl


KonzertInstSamples: ;inst BRR samples to SPC
	cmp DPNowSample
	bne +
--	rtl
+	sta DPNowSample
	dec a
	asl
	asl
	tax
	stz DPRenderDelay
	lda #$0001 ;tick SPC back to IPL
	sta $2140
	lda.l SampleDir,x
	sta $c0
	lda.l SampleDir+2,x
	sta $c2
	lda #!RangeSamples-1
	sta $2142
	jsr RoutineProgramLoader
	rtl


RoutineInitVolumes:
	lda #$0041 ;init song volume
	sta DPVolMusic
	sta.l $70000c
	lda #$0051 ;init SFX volume
	sta DPVolSFX
	sta.l $70000e
	rtl


KonzertSndDir:
	dd KonzertStoreDriver



RoutineProgramLoader:
;	lda #$008F
;	sta $2100
	lda #$77cc
	sta $2140
-	lda $2140
	cmp #$bbcc
	bne -

	stz $213f
	ldy #$0000
	tyx
---	inc DPRenderDelay
	lda DPRenderDelay
	and #$00ff
	sta DPRenderDelay
	lda [$c0],y
	;lda.l KonzertStoreDriver,y
	cmp #$4f47
	beq +++
	xba
	and #$ff00
	clc
	adc DPRenderDelay
	xba
	sta $2141
	xba
	sta $2140

-	lda $2140
	and #$00ff
	cmp DPRenderDelay
	bne -
	iny
	bra ---
+++	lda #$0300
	sta $2142
	lda $2140
	inc a
	inc a
	and #$00ff
	sta DPRenderDelay
	sta $2140
-	lda $2140
	and #$00ff
	cmp DPRenderDelay
	bne -
	stz $2140
	stz $2142
;	lda #$000F
;	sta $2100
	rts


;BRR sample banks
SampleDir:
	dd SampBank00

SampBank00:
	incsrc "audio/samples/tunings.asm"
	dw Patch001+2-SampBank00+!RangeSamples
	dw Patch001+2-SampBank00+!RangeSamples+readfile2("audio/samples/001.brr",0,$FFFF)
	dw Patch002+2-SampBank00+!RangeSamples
	dw Patch002+2-SampBank00+!RangeSamples+readfile2("audio/samples/002.brr",0,$FFFF)
	dw Patch003+2-SampBank00+!RangeSamples
	dw Patch003+2-SampBank00+!RangeSamples+readfile2("audio/samples/003.brr",0,$FFFF)
	dw Patch004+2-SampBank00+!RangeSamples
	dw Patch004+2-SampBank00+!RangeSamples+readfile2("audio/samples/004.brr",0,$FFFF)
	dw Patch005+2-SampBank00+!RangeSamples
	dw Patch005+2-SampBank00+!RangeSamples+readfile2("audio/samples/005.brr",0,$FFFF)
	dw Patch006+2-SampBank00+!RangeSamples
	dw Patch006+2-SampBank00+!RangeSamples+readfile2("audio/samples/006.brr",0,$FFFF)
	dw Patch007+2-SampBank00+!RangeSamples
	dw Patch007+2-SampBank00+!RangeSamples+readfile2("audio/samples/007.brr",0,$FFFF)
	dw Patch008+2-SampBank00+!RangeSamples
	dw Patch008+2-SampBank00+!RangeSamples+readfile2("audio/samples/008.brr",0,$FFFF)
	dw Patch009+2-SampBank00+!RangeSamples
	dw Patch009+2-SampBank00+!RangeSamples+readfile2("audio/samples/009.brr",0,$FFFF)
	dw Patch010+2-SampBank00+!RangeSamples
	dw Patch010+2-SampBank00+!RangeSamples+readfile2("audio/samples/010.brr",0,$FFFF)
	dw Patch011+2-SampBank00+!RangeSamples
	dw Patch011+2-SampBank00+!RangeSamples+readfile2("audio/samples/011.brr",0,$FFFF)
	dw Patch012+2-SampBank00+!RangeSamples
	dw Patch012+2-SampBank00+!RangeSamples+readfile2("audio/samples/012.brr",0,$FFFF)
	dw Patch013+2-SampBank00+!RangeSamples
	dw Patch013+2-SampBank00+!RangeSamples+readfile2("audio/samples/013.brr",0,$FFFF)
	dw Patch014+2-SampBank00+!RangeSamples
	dw Patch014+2-SampBank00+!RangeSamples+readfile2("audio/samples/014.brr",0,$FFFF)
	dw Patch015+2-SampBank00+!RangeSamples
	dw Patch015+2-SampBank00+!RangeSamples+readfile2("audio/samples/015.brr",0,$FFFF)
	dw Patch016+2-SampBank00+!RangeSamples
	dw Patch016+2-SampBank00+!RangeSamples+readfile2("audio/samples/016.brr",0,$FFFF)
	dw Patch017+2-SampBank00+!RangeSamples
	dw Patch017+2-SampBank00+!RangeSamples+readfile2("audio/samples/017.brr",0,$FFFF)
	dw Patch018+2-SampBank00+!RangeSamples
	dw Patch018+2-SampBank00+!RangeSamples+readfile2("audio/samples/018.brr",0,$FFFF)
	dw Patch019+2-SampBank00+!RangeSamples
	dw Patch019+2-SampBank00+!RangeSamples+readfile2("audio/samples/019.brr",0,$FFFF)
	dw Patch020+2-SampBank00+!RangeSamples
	dw Patch020+2-SampBank00+!RangeSamples+readfile2("audio/samples/020.brr",0,$FFFF)
	dw Patch021+2-SampBank00+!RangeSamples
	dw Patch021+2-SampBank00+!RangeSamples+readfile2("audio/samples/021.brr",0,$FFFF)
	dw Patch022+2-SampBank00+!RangeSamples
	dw Patch022+2-SampBank00+!RangeSamples+readfile2("audio/samples/022.brr",0,$FFFF)
	dw Patch023+2-SampBank00+!RangeSamples
	dw Patch023+2-SampBank00+!RangeSamples+readfile2("audio/samples/023.brr",0,$FFFF)
	dw Patch024+2-SampBank00+!RangeSamples
	dw Patch024+2-SampBank00+!RangeSamples+readfile2("audio/samples/024.brr",0,$FFFF)
	dw Patch025+2-SampBank00+!RangeSamples
	dw Patch025+2-SampBank00+!RangeSamples+readfile2("audio/samples/025.brr",0,$FFFF)
	dw Patch026+2-SampBank00+!RangeSamples
	dw Patch026+2-SampBank00+!RangeSamples+readfile2("audio/samples/026.brr",0,$FFFF)
	dw Patch027+2-SampBank00+!RangeSamples
	dw Patch027+2-SampBank00+!RangeSamples+readfile2("audio/samples/027.brr",0,$FFFF)
	dw Patch028+2-SampBank00+!RangeSamples
	dw Patch028+2-SampBank00+!RangeSamples+readfile2("audio/samples/028.brr",0,$FFFF)
	dw Patch029+2-SampBank00+!RangeSamples
	dw Patch029+2-SampBank00+!RangeSamples+readfile2("audio/samples/029.brr",0,$FFFF)
	dw Patch030+2-SampBank00+!RangeSamples
	dw Patch030+2-SampBank00+!RangeSamples+readfile2("audio/samples/030.brr",0,$FFFF)
	dw Patch031+2-SampBank00+!RangeSamples
	dw Patch031+2-SampBank00+!RangeSamples+readfile2("audio/samples/031.brr",0,$FFFF)
	dw Patch032+2-SampBank00+!RangeSamples
	dw Patch032+2-SampBank00+!RangeSamples+readfile2("audio/samples/032.brr",0,$FFFF)

Patch001:
	incbin "audio/samples/001.brr"
Patch002:
	incbin "audio/samples/002.brr"
Patch003:
	incbin "audio/samples/003.brr"
Patch004:
	incbin "audio/samples/004.brr"
Patch005:
	incbin "audio/samples/005.brr"
Patch006:
	incbin "audio/samples/006.brr"
Patch007:
	incbin "audio/samples/007.brr"
Patch008:
	incbin "audio/samples/008.brr"
Patch009:
	incbin "audio/samples/009.brr"
Patch010:
	incbin "audio/samples/010.brr"
Patch011:
	incbin "audio/samples/011.brr"
Patch012:
	incbin "audio/samples/012.brr"
Patch013:
	incbin "audio/samples/013.brr"
Patch014:
	incbin "audio/samples/014.brr"
Patch015:
	incbin "audio/samples/015.brr"
Patch016:
	incbin "audio/samples/016.brr"
Patch017:
	incbin "audio/samples/017.brr"
Patch018:
	incbin "audio/samples/018.brr"
Patch019:
	incbin "audio/samples/019.brr"
Patch020:
	incbin "audio/samples/020.brr"
Patch021:
	incbin "audio/samples/021.brr"
Patch022:
	incbin "audio/samples/022.brr"
Patch023:
	incbin "audio/samples/023.brr"
Patch024:
	incbin "audio/samples/024.brr"
Patch025:
	incbin "audio/samples/025.brr"
Patch026:
	incbin "audio/samples/026.brr"
Patch027:
	incbin "audio/samples/027.brr"
Patch028:
	incbin "audio/samples/028.brr"
Patch029:
	incbin "audio/samples/029.brr"
Patch030:
	incbin "audio/samples/030.brr"
Patch031:
	incbin "audio/samples/031.brr"
Patch032:
	incbin "audio/samples/032.brr"

	dw $4f47





SongDir:
	dd Song01
	dd Song02
	dd Song03
	dd Song04
	dd Song05
	dd Song06
	dd Song07
	dd Song08
	dd Song09
	dd Song0A




;	db "BANK02"