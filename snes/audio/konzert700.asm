;konzert700
;a simplified MIDI player and
;series of conversion tools for the 
;SPC-700 sound chip
;by Gero Konberg & Jahn Keller
;2025,2026

;Voice commands:
;$E0 xx		Program change / Wait by x times 64s (used in place of double-length note deltas)
;$E1 xx		Pan (absolute)
;$E2 xx		[TODO] Panbrello strength (by 64/2 ticks per rotation)
;$E3 xx		Vibrato strength
;$E4 xx		Vibrato delay
;$E5 xx		Global volume
;$E6 xx		Reverb multiplier (volume>feedback)
;$E7 xx		Song tempo (does not affect SFX)
;$E8 xx		[unused]
;$E9 xx		[TODO] Legato + Portamento strength
;$EA xx		Bend (percentage)
;$EB xx		[TODO] Tremolo strength
;$EC xx		[TODO] Tremolo delay
;$ED xx		Volume
;$EE xx 	Begin track (forever loop)
;$EF xx		End track


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

	;ee last termination [$EF end]

norom
arch spc700-raw
dpbase $0000
optimize dp always

;direct page

base $0000 ;zero page h1
HardActTrk: ;active tracks
skip 8
HardActKey: ;send in note key for key on events; high bit this immediatly afterwards
skip 8
HardActVel: ;active note velocity
skip 8
HardActFlags: ;voice flags
skip 8
HardModCC: ;E2 modulation value
skip 8
HardModDly: ;E3 modulation delay
skip 8
HardModPer: ;modulation percentage
skip 8
HardModFlg: ;modulation flag
skip 8

base $0080 ;zero page h2
TrkDelta: ;16-bit virtual track delta word
skip 32
TrkAddr: ;16-bit track pointer words
skip 32
MusicAddr: ;latest track to read from
skip 2
SFXAddr: ;latest sfx to read from (doubles as a flag bypass for #0)
skip 2
LoadAddr: ;used as a stack for commands
skip 2
DPStacks: ;scratch ram
skip 12
APUCopy1: ;I/O mirror from $2140
skip 1
APUCopy2: ;I/O mirror from $2141
skip 1
APUCopy3: ;I/O mirror from $2142
skip 1
APUCopy4: ;I/O mirror from $2143
skip 1
SMPOut1: ;I/O mirror to $2140
skip 1
SMPOut2: ;I/O mirror to $2141
skip 1
SMPOut3: ;I/O mirror to $2142
skip 1
SMPOut4: ;I/O mirror to $2143
skip 1
SMPBit: ;fractional of SMPOut2
skip 1

SFXWait:
skip 2

base $00E0 ;talk RAM
TPMusicBegin:
dw Konz700MusicData
TPMusicEnd:
dw LatestTrackEnd
GlobalVol:
skip 1
SongVol:
skip 1
SFXVol:
skip 1
RNGValueB:
skip 1

base $0200 ;memory page
VTkE0inst: ;
skip 1
VTkE1pan: ;
skip 31
VTkE2: ;
skip 1
VTkE3modin: ;
skip 31
VTkE4modly: ;
skip 1
VTkE5: ;
skip 31
VTkE6echo: ;
skip 1
VTkF1key: ;
skip 31
VTkE8: ;
skip 1
VTkE9: ;
skip 31
VTkEAbend: ;
skip 1
VTkEBtrem: ;
skip 31
VTkEC: ;
skip 1
VTkEDvol: ;
skip 31
VTkEE: ;
skip 1
VTkF0vel: ;
skip 31

base $0100 ;misc 2 page
StartPos:
skip 32
TrkBuffer:
skip 16
SizeBuffer:
skip 16
BuffAddr:
skip 32


base $0300 ;driver page
	skip -517
base $0300 ;driver page
	bra Konz700Init
	bra Konz700Renit
;	db "konzert700 V0.44C"
Konz700Init:
	clrp
;	mov SongVol,#$7f;init song volumes
;	mov SFXVol,#$9f;init SFX volume
	mov a,Konz700LoadRef+5 ;init echo buffer (hardcoded at the moment, TODO)
	mov y,a
	mov a,Konz700LoadRef+4
	movw TPMusicEnd,ya
Konz700Renit:
	clrp
	mov y,#$11
-	mov a,PresetDSPs+y
	mov $f2,a
	mov $f3,#$00
	dec y
	cmp y,#$00
	bpl -
	mov $f2,#$6c
	mov $f3,#$e0
	mov $f2,#$6d
	mov $f3,#$7f
	mov $f2,#$5d
	mov a,Konz700LoadRef+3
	inc a
	mov $f3,a
	inc y
	mov a,y
	mov x,a 
	dec x
	mov sp,x
-	mov $ffe0+x,a ;reset memory locations
	mov $0100+x,a
	mov $0200+x,a
	cmp x,#$00
	beq ++
	dec x
	bra -
++	mov a,Konz700Init-1
	inc a
	inc a
	mov Konz700Init-3,a ;bypass talk init after a fresh run
-	call Konz700ReadPorts
	bra -

Konz700ReadPorts:
	mov a,$f4
	beq +
	cmp a,APUCopy1
	beq +
	mov APUCopy1,a
	call Konz700LoadData
+	mov a,$f5
	beq +
	cmp a,APUCopy2
	beq +
	mov APUCopy2,a
	call Konz700LoadScaler
+	mov a,$f6
	beq +
	cmp a,APUCopy3
	beq +
	cmp a,#$40 ;pause here, wait for c0 to unpause
	bne +++
	mov a,$f7
	mov APUCopy4,a
	mov $f2,#$5c
	mov $f3,#$ff ;key-off all previous notes
	call Konz700LoadSFX


---	mov a,$fe ;wait for timer 1 SFX tick
	beq ---
	call Konz700UpdateSFX
	mov a,$f6
	cmp a,#$c0
	bne ---
	bra +
+++	cmp a,#$80 ;dont mirror fade out
	beq +
	and a,#$3f
	beq +
	mov a,$f6
	mov APUCopy3,a
	jmp Konz700LoadMusic
+	

	mov a,$f7
	beq +
	cmp a,APUCopy4
	beq +
	mov APUCopy4,a
	call Konz700LoadSFX
+	inc SMPOut1
+	


	mov $f7,SMPOut4
	mov $f6,SMPOut3
	mov $f5,SMPOut2
+++	mov $f4,SMPOut1
	ret

Konz700LoadMusic: ;01-3f/41-7f/81-bf/c1-ff change music
				;00 do nothing/40 pause on/80 fade out/C0 pause off
	mov $f2,#$6c
	mov $f3,#$e0
	mov a,Konz700LoadRef+3
	eor a,#$ff
	inc a
	mov DPStacks+2,a
	mov a,Konz700LoadRef+3
	dec a
	mov y,a
	mov a,#$00
	subw ya,TPMusicEnd
	mov a,y
	lsr a
	lsr a
	lsr a
	beq ++
	mov $f2,#$7d
	mov $f3,a
	asl a
	asl a
	asl a
	eor a,#$ff
	setc
	sbc a,DPStacks+2
	mov $f2,#$6d
	inc a
	mov $f3,a
++	mov a,#$00
	mov x,#$ff
-	mov $ffd0+x,a ;reset memory locations (safe for special events)
	mov $0200+x,a
	cmp x,#$00
	beq ++
	dec x
	bra -

++	mov GlobalVol,#$7f ;reset global volume on each load
Konz700RedoMusic:
	mov a,APUCopy3
	and a,#$3f
	dec a
	asl a
	mov x,a
	mov a,Konz700MusicArray+1+x
	mov y,a
	mov a,Konz700MusicArray+x
	movw MusicAddr,ya
	mov y,#$00
	mov a,(MusicAddr)+y ;amount of channels to load
	beq +++
	asl a
	inc a
	mov DPStacks+1,a
	mov DPStacks+2,#$01
--	mov x,DPStacks+2
	mov y,DPStacks+2
	mov a,(MusicAddr)+y
	push a
	inc y
	mov a,(MusicAddr)+y
	mov y,a
	pop a
	addw ya,MusicAddr
	mov TrkAddr-1+x,a
	mov a,y
	mov TrkAddr+x,a
	inc DPStacks+2
	inc DPStacks+2
	cmp DPStacks+2,DPStacks+1
	bne --
+++
	call RoutineCalcMixer
	mov $f2,#$6c
	mov $f3,#$00
	mov x,#$00


Konz700ReadMusic:
---	mov DPStacks,x
	mov y,#$00
	mov a,TrkAddr+1+x ;check for valid pointers (0000 = terminated)
	beq +++
	mov a,TrkDelta+1+x ;check highest delta bit
	bne ++
	mov a,TrkDelta+x ;check lowest delta bit
	bne ++
	mov a,(TrkAddr+x)
	bmi +
	call Konz700DoDelta
	bra ---
+	call RoutineIncWord
	and a,#$7f
	cmp a,#$60
	bpl +
	call Konz700DoNotes
	bra ---
+	cmp a,#$70
	bpl +
	call Konz700DoEffects
	bra ---
+	call Konz700DoForte
	bra ---
++	mov a,TrkDelta+x
	cmp a,#$40
	bne ++
	mov a,#$00
	mov TrkDelta+x,a
	mov DPStacks,x
	mov x,#$07
--	mov a,HardActTrk+x
	cmp a,DPStacks
	bne +
	mov a,#$00
	mov HardActTrk+x,a ;note off
	mov a,x
	xcn a
	or a,#$05
	mov $f2,a
	mov $f3,#$00 ;release envelope
+	dec x
	bpl --
	mov x,DPStacks
	bra ---
++	cmp a,#$00
	beq +
	dec TrkDelta+x
	bra +++
+	
++	mov a,TrkDelta+1+x
	beq +++
	mov a,#$3f
	mov TrkDelta+x,a
	dec TrkDelta+1+x
+++	
	inc x
	inc x ;update channel
	cmp x,#$20
	bne +
	call Konz700UpdateEvents
+	jmp Konz700ReadMusic
	
	db Konz700DoDelta
Konz700DoDelta:
	call RoutineIncWord
	mov TrkDelta+x,a
	ret

Konz700DoNotes:
	mov VTkF1key+x,a
	push x
	mov a,x
	mov y,a
	mov DPStacks+1,a
	mov x,#$07 ;
---	mov a,HardActTrk+x ;check for free channels of it's kind
	beq +
	bpl ++ ;positive = occupied already
	and a,#$7f
	cmp a,DPStacks+1
	beq +
++	dec x
	bne ---
	mov x,#$07
---	mov a,HardActTrk+x ;find the nearest available channel until none left
	beq +
	bmi +
	dec x
	bmi +++
	bra ---
+	mov a,y
	mov HardActTrk+x,a
	mov a,VTkF1key+y
	mov HardActKey+x,a
	mov a,VTkF0vel+y
	mov HardActVel+x,a
	mov a,VTkE4modly+y
	mov HardModDly+x,a
	mov a,VTkE6echo+y
	beq ++
	mov $f2,#$0f
	mov $f3,a
	eor a,#$7f
	mov $f2,#$0d
	mov $f3,a
++	mov $f2,#$4d
	mov HardActFlags+x,a
	beq +++
	mov a,$f3
	or a,PresetBitmask+x
	bra ++
+++	mov a,$f3
	or a,PresetBitmask+x
	eor a,PresetBitmask+x
++	mov $f3,a
	pop x
	ret

Konz700DoEffects:
	and a,#$0f
	asl a
	mov y,a
	mov a,Konz700VCMDs+1+y
	push a
	mov a,Konz700VCMDs+y
	push a
	mov a,(TrkAddr+x)
	call RoutineIncWord
	ret ;jump to VCMD

Konz700VCMDs:
	dw KonzVCMDe0
	dw KonzVCMDe1
	dw KonzVCMDe2
	dw KonzVCMDe3
	dw KonzVCMDe4
	dw KonzVCMDe5
	dw KonzVCMDe6
	dw KonzVCMDe7
	dw KonzVCMDe8
	dw KonzVCMDe9
	dw KonzVCMDea
	dw KonzVCMDeb
	dw KonzVCMDec
	dw KonzVCMDed
	dw KonzVCMDee
	dw KonzVCMDef

KonzVCMDe0: ;00 drum kit, 01-7f melodic, 80-FF long delta
	cmp a,#$00
	bmi ++
	mov VTkE0inst+x,a
	call RoutineCalcInst
	ret
++	and a,#$7f
	mov TrkDelta+1+x,a
	ret

KonzVCMDe1:
	mov VTkE1pan+x,a
	call RoutineCalcVol
	ret

KonzVCMDe2:
	mov VTkE2+x,a
	ret

KonzVCMDe3:
	mov VTkE3modin+x,a
	ret

KonzVCMDe4:
	mov VTkE4modly+x,a
	ret

KonzVCMDe5:
	mov GlobalVol,a
	call RoutineCalcMixer
	ret

KonzVCMDe6:
	mov VTkE6echo+x,a
	ret

KonzVCMDe7:
	mov y,#$af
	mul ya
	mov a,y
	mov $fa,a ;music tempo
	mov $fb,#$10 ;sfx tempo (const)
	mov $f1,#$03
	ret

KonzVCMDe8:
	mov VTkE8+x,a
	ret

KonzVCMDe9:
	mov VTkE9+x,a
	ret

KonzVCMDea:
	mov VTkEAbend+x,a
	call RoutineCalcPitch
	ret

KonzVCMDeb:
	mov VTkEBtrem+x,a
	ret

KonzVCMDec:
	mov VTkEC+x,a
	ret

KonzVCMDed:
	mov VTkEDvol+x,a
	call RoutineCalcVol
	ret

KonzVCMDee: ;update track address for loops
	mov DPStacks+2,a
	mov a,VTkEE+x ;only execute this once per track at a non-zero value
	bne ++
	mov a,DPStacks+2
	cmp a,#$08
	bmi ++
	mov VTkEE+x,a
	mov a,TrkAddr+1+x
	mov y,a
	mov a,TrkAddr+x
	subw ya,MusicAddr	
	mov Konz700MusicData+1+x,a
	mov a,y
	mov Konz700MusicData+2+x,a
++	ret

KonzVCMDef:
	mov a,#$00
	mov TrkAddr+x,a
	mov TrkAddr+1+x,a
	ret



Konz700DoForte:
	and a,#$0f
	mov VTkF0vel+x,a
	ret


Konz700UpdateEvents:
---	call Konz700ReadPorts
	mov a,SFXAddr+1 ;check for any sound effects
	beq ++
-	mov a,$fe ;wait for timer 1 SFX tick
	beq -
	call Konz700UpdateSFX
++	mov a,$fd ;wait for timer 0 tick
	bne +
	bra ---
+	mov x,#$00 ;tick delta counter down
---	
+++	inc x
	inc x
	cmp x,#$20
	bne ---
	mov DPStacks+1,#$00 ;note on table
	mov x,#$07
---	mov a,HardActKey+x ;check for new note events
	beq ++
	bmi ++
	or a,#$80 
	mov HardActKey+x,a
	mov a,PresetBitmask+x
	mov $f2,#$5c ;key off now to decade prior envelopes
	mov $f3,a
	or a,DPStacks+1
	mov DPStacks+1,a
	mov a,HardActTrk+x
	mov DPStacks,a
	call RoutineCalcPitch
	call RoutineCalcVol
	call RoutineCalcInst
	mov $f2,#$5c
	mov $f3,#$00
++	mov a,HardActTrk+x
	mov DPStacks,a
	mov y,a
	mov a,TrkDelta+y
	cmp a,#$40
	bne +
	mov a,HardActTrk+x
	or a,#$80
	mov HardActTrk+x,a ;note off
	mov a,x
	xcn a
	or a,#$05
	mov $f2,a
	mov $f3,#$00 ;release envelope

+	mov a,VTkE3modin+y
	mov HardModCC+x,a
	mov a,HardModCC+x ;check for modulation
	beq ++
	bmi ++
+	call RoutineCalcPitch
+++
++	dec x 
	bpl ---
	mov $f2,#$4c ;key on new entries
	mov $f3,DPStacks+1
	
	mov x,#$20 ;reset if all tracks have been terminated
--	mov a,TrkAddr+x
	bne ++
	dec x
	dec x
	bpl --
	pop a
	pop a ;reset stack buffer
	jmp Konz700RedoMusic
++	mov a,$f6 ;check for fade out
	cmp a,#$80
	bne +++
	mov a,GlobalVol
	beq ++
	dec GlobalVol
	call RoutineCalcMixer
	bra +++
++	mov SMPOut3,#$80 ;send acknowledgment on silence
+++	mov x,#$00
	ret


Konz700TerminSFX:
---	mov a,#$00
	mov $f2,a
	mov $f3,a
	inc $f2
	mov $f3,a
	mov HardActTrk,a
	mov SFXAddr,a
	mov SFXAddr+1,a
-	ret

Konz700UpdateSFX:
	mov a,SFXAddr+1 ;check for any sound effects
	beq -
	mov a,SFXWait
	beq ++
	dec SFXWait
	ret
++	mov a,SFXWait+1
	beq ++
	dec SFXWait+1
	mov SFXWait,#$7f
	ret
++	mov y,#$00
	mov a,(SFXAddr)+y
	bne +++
	inc y
	mov a,(SFXAddr)+y ;get instrument
	cmp a,#$ff ;check for termination
	beq ---
	and a,#$1f
	mov $f2,#$04
	mov $f3,a
	eor a,#$20
	mov HardActTrk,a
	and a,#$1f
	push y
	asl a
	asl a
	asl a 
	mov y,a
	mov $f2,#$07
	mov a,InstrumentData+2+y
	mov $f3,a
	dec $f2
	mov a,InstrumentData+1+y
	mov $f3,a
	dec $f2
	mov a,InstrumentData+y
	mov $f3,a
	pop y
	inc y
	mov a,(SFXAddr)+y ;get volume
	push y
	mov y,SFXVol
	mul ya
	mov a,y
	mov $f2,#$00
	mov $f3,a
	inc $f2
	mov $f3,a
	pop y
---	inc y
	mov a,y
	clrc
	adc a,SFXAddr
	bcc +
	inc SFXAddr+1
+	mov SFXAddr,a
	jmp Konz700UpdateSFX
+++	bmi +		;get 8-bit(16-bit) delay + raw DSP pitch
	mov SFXWait+1,#$00
	mov SFXWait,a
--	inc y
	mov $f2,#$03
	mov a,(SFXAddr)+y ;get P(H) [00-3F abs HL; 40-7F abs H; 80-BF rel+/-HL; C0-FF rel+/-H ]
	bmi ++
	cmp a,#$40
	bpl +++
	and a,#$3f
	mov $f3,a
	dec $f2
	inc y
	mov a,(SFXAddr)+y ;get P(L)
	mov $f3,a
	mov $f2,#$5c
	mov $f3,#$00 ;reset key-off
-	mov $f2,#$4c
	mov $f3,#$01 ;enable SFX key on
	inc $f2
	and $f3,#$fe ;toggle off echo for channel 0
	bra ---
+	and a,#$7f
	mov SFXWait+1,a ;high 16-bit reg
	inc y
	mov a,(SFXAddr)+y ;low 16-bit reg
	mov SFXWait,a
	bra --
++	and a,#$7f
	cmp a,#$40
	bpl ++
	clrc
	adc a,$f3 ;add up to P(H)
	and a,#$3f
	mov $f3,a
	dec $f2
	inc y
	mov a,(SFXAddr)+y
	clrc
	adc a,$f3 ;add up to P(L)
	mov $f3,a
	bcc +
	inc $f2
	inc $f3
	and $f3,#$3f
+	bra -
+++	and a,#$3f ;only write absolute P(H) during $40-$7F
	mov $f3,a
	bra -
++	and a,#$3f  ;only write relative P(H) during $C0-FF
	clrc
	adc a,$f3
	and a,#$3f
	mov $f3,a
	bra -
	


Konz700LoadSFX:
	push x
	dec a
	asl a
	mov x,a
	mov a,Konz700SFXArray+1+x
	mov y,a
	mov a,Konz700SFXArray+x
	movw SFXAddr,ya
	mov a,#$00
	mov SFXWait,a
	mov SFXWait+1,a ;overwrite previous SFX
	mov HardModCC,a
	mov HardActKey,a
	mov HardActFlags,a
	pop x
	ret


Konz700LoadScaler: ;00-7F song volume; 80-FF SFX volume
	mov a,APUCopy2
	bmi +
	asl a
	mov SongVol,a
	ret
+	and a,#$7f
	asl a
	mov SFXVol,a
	ret


Konz700LoadRef:
	dw Konz700MusicData
	dw InstrumentData
	dw !RangeEcho

Konz700LoadData: ;load data (00-0F{-7F} music, 80-FF sample data, etc. from 7E2000): finish after $f0f0 on SNES-side
	
	mov $f1,#$82 ;enable IPL & disable music timer until load is complete
;	mov $f2,#$6c
;	mov $f3,#$e0
	jmp $ffc9

;	push x
;	mov $f2,#$6c
;	mov $f3,#$e0
;	mov APUCopy1,#$01
;	mov y,#$00
;	cmp a,#$00
;	bpl +
;	inc y
;	inc y
;+	mov a,Konz700LoadRef+1+y
;	push a
;	mov a,Konz700LoadRef+y
;	pop y
;	movw LoadAddr,ya
;	mov a,#$f0
;	mov y,a
;	movw MusicAddr,ya
;---	movw ya,$f4
;	cmpw ya,MusicAddr
;	beq +++
;	movw ya,$f6
;	cmpw ya,MusicAddr
;	beq +++
;	mov y,#$00
;--	mov a,$f4+y ;byte
;	mov (LoadAddr)+y,a
;	inc y
;	cmp y,#$04
;	bne --
;	mov a,y
;	clrc
;	adc a,LoadAddr
;	bcc +
;	inc LoadAddr+1
;+	inc SMPOut1
;	mov $f6,SMPOut1 ;send new acknowledgment key upon transfer & wait to $f6
;-	mov a,$f6 ;wait for latest acknowledgment on $f6
;	cmp a,APUCopy1
;	bne -
;	inc APUCopy1
;	bra ---
;+++	movw ya,$f4 ;store song ends for echo buffer comparisons
;	movw TPMusicEnd,ya
;	mov $f1,#$33 ;reset cpuio input
;	pop x
;	ret



RoutineCalcPitch: ;new note, bends, cc vibrato (check for channels on pure DPStack ($D0))
	push y
	push x
	mov x,#$07
RoutineCalcBackP:
	call RoutineCalcShared
	bpl +
	jmp SkipCalcPitch
+	mov y,#$03
	mov a,(LoadAddr)+y ;Tuning
	mov DPStacks+3,a
	push a
	inc y
	mov a,(LoadAddr)+y ;Sub-tuning
;	clrc
;	adc a,NoteDetune+x
	mov DPStacks+4,a
	mov DPStacks+2,#$01 ;reset octave field
	inc y
	mov a,(LoadAddr)+y ;key transpose (b0 = centre)
	setc
	sbc a,#$b0
	mov DPStacks+5,a
	mov a,HardActKey+x ;get key
	and a,#$7f
	clrc
	adc a,DPStacks+5
-	cmp a,#$0c
	bmi +
	asl DPStacks+2
	setc
	sbc a,#$0c ;subtract all octaves until the first key
	bra -
+	mov y,a
	mov a,PresetTuning+y 
	mov DPStacks+5,a
	mov a,DPStacks+2
	pop y ;get tuning * octave root
	mul ya
	mov y,DPStacks+5
	mul ya
	mov DPStacks+6,a
	mov a,y
	mov DPStacks+7,a

	mov a,DPStacks+2
	mov y,#$01
	mul ya
	mov y,DPStacks+5
	push a
	mov a,DPStacks+4 ;add sub-multiplier
	mul ya
	pop a
	mul ya
	clrc
	adc a,DPStacks+6
	bcc +
	inc DPStacks+7
+	mov DPStacks+6,a
	mov a,y
	clrc
	adc a,DPStacks+7
	mov DPStacks+7,a
	mov a,DPStacks+7
	mov y,#$03 ;round up fine tune
;	inc y
	mul ya
	clrc
	adc a,DPStacks+6
	bcc +
	inc DPStacks+7
+	adc a,DPStacks+7
	bcc +
	inc DPStacks+7
+	mov DPStacks+6,a
	mov DPStacks+2,a
	mov a,DPStacks+7
	mov DPStacks+5,a
	

	mov y,DPStacks
	mov a,VTkEAbend+y ;read bend
	cmp a,#$80 ;skip bend-tuning at zero
	beq +++
	cmp a,#$00
	bmi ++
	mov DPStacks+3,a ;calculate down to one octave
	mov a,#$84
	setc
	sbc a,DPStacks+3
;	asl a
	mov y,a
	mov a,DPStacks+5
	mul ya
	mov DPStacks+3,a
	mov a,DPStacks+6
	setc
	sbc a,DPStacks+3
	bcs +
	inc y
+	mov DPStacks+6,a
	mov DPStacks+3,y
	mov a,DPStacks+7
	setc
	sbc a,DPStacks+3
	mov DPStacks+7,a
	bra +++
++	and a,#$7f
	mov y,a
	mov a,DPStacks+5 ;load high pitch
	asl a
	mul ya
	clrc
	adc a,DPStacks+6
	bcc +
	inc y
+	mov DPStacks+6,a
	mov a,y
	clrc
	adc a,DPStacks+7
	mov DPStacks+7,a
	clrc
	adc a,DPStacks+6
	bcc +
	inc DPStacks+7
+	mov DPStacks+6,a


+++	mov a,HardModDly+x
	beq +
	dec HardModDly+x
+	mov a,#$00
	mov HardModCC+x,a
	mov y,DPStacks
	mov a,VTkE3modin+y ;read modulation
	beq +
	mov HardModCC+x,a

+	
+++	mov a,HardModCC+x ;continue modulation
	beq +++
	mov a,HardModDly+x
	bne +++
	mov a,HardModFlg+x
	beq ++
	mov a,HardModCC+x ;invert sub.target
	and a,#$7f
	mov DPStacks+3,a
	mov a,#$80
	setc
	sbc a,DPStacks+3
	mov DPStacks+3,a
	mov a,HardModPer+x
	and a,#$7f
	setc
	sbc a,#$01
	cmp a,#$7a ;$7d
	bne +
	dec HardModFlg+x
+	mov HardModPer+x,a
	bra +++
++	mov a,HardModPer+x
	and a,#$7f
	clrc
	adc a,#$01
	cmp a,#$06 ;$03
	bne +
	inc HardModFlg+x
+	mov HardModPer+x,a

+++	mov a,HardModCC+x ;calculate vibrato
	beq +++ ;beq
	mov a,HardModDly+x
	bne +++
	mov a,HardModPer+x
	and a,#$7f
	cmp a,#$40 ;<=40 add, >=40 sub
	bpl +

	mov y,a
	mov a,HardModCC+x
	and a,#$7f
	lsr a
	lsr a
	lsr a
	mul ya
	lsr a
	mov y,a
	mov a,DPStacks+7
;	lsr a
	lsr a
	mul ya
	clrc
	adc a,DPStacks+6
	bcc ++
	inc DPStacks+7
	bra ++

+	mov DPStacks+3,a
	mov a,#$80
	setc
	sbc a,DPStacks+3
	mov y,a
	mov a,HardModCC+x
	and a,#$7f
	lsr a
	lsr a
	lsr a
	mul ya
	lsr a
	mov y,a
	mov a,DPStacks+7
;	lsr a
	lsr a
	mul ya
	mov DPStacks+3,a
	mov a,DPStacks+6
	setc
	sbc a,DPStacks+3
	bcs ++
	dec DPStacks+7
++	mov DPStacks+6,a


+++	;mov a,HardModCC+x ;zero out if the highest bit hasn't been set
	;bpl +
	;mov a,#$00
	;mov HardModDly+x,a

+	mov a,x
	xcn a
	inc a
	inc a
	mov $f2,a
	mov $f3,DPStacks+6
	inc $f2
	mov $f3,DPStacks+7
;	mov InstTranspose+x,a
	dec x
	jmp RoutineCalcBackP
SkipCalcPitch:
+++	pop x
	pop y
	ret


RoutineCalcInst: ;new note, instrument changes
	push y
	push x
	mov x,#$07
RoutineCalcBackI:
	call RoutineCalcShared
	bmi +++
	mov y,#$00
	mov a,(LoadAddr)+y ;ADSR1
	mov DPStacks+2,a
	inc y
	mov a,(LoadAddr)+y ;ADSR2
	mov DPStacks+3,a
	inc y
	mov a,(LoadAddr)+y ;GAIN
	mov DPStacks+4,a
	mov a,x
	xcn a
	or a,#$07
	mov $f2,a
	mov $f3,DPStacks+4
	dec $f2
	mov $f3,DPStacks+3
	dec $f2
	mov $f3,DPStacks+2
	mov y,DPStacks
	call RoutineLoadInst
	dec $f2
	mov $f3,a
	dec x
	jmp RoutineCalcBackI
+++	pop x
	pop y
	ret



RoutineCalcVol: ;new note, volume changes, pan changes, cc tremolo
	push y
	push x
	mov x,#$07
RoutineCalcBackV:
	call RoutineCalcShared
	bmi +++
	mov y,#$06
	mov a,(LoadAddr)+y ;Volume bit 1
	mov DPStacks+3,a
	inc y
	mov a,(LoadAddr)+y ;Volume bit 2
	clrc
	adc a,DPStacks+3
	mov DPStacks+3,a
	mov y,DPStacks
	mov a,VTkEDvol+y ;Volume track
	mov y,DPStacks+3
	mul ya
	mov a,HardActVel+x  ;Per-note velocity
	xcn a
	mul ya
	mov a,SongVol
	mul ya
	mov DPStacks+3,y
	mov DPStacks+4,y ;store monaural volume (3=L;4=R)
	mov y,DPStacks
	mov a,VTkE1pan+y
	cmp a,#$40 ;skip on centered
	beq ++
	bpl + ;pan left/right
	asl a
	asl a
	mov y,DPStacks+4
	mul ya
	mov DPStacks+4,y
	bra ++
+	and a,#$3f
	asl a
	asl a
	eor a,#$ff
	mov y,DPStacks+3
	mul ya
	mov DPStacks+3,y
++	mov a,x
	xcn a
	mov $f2,a
	mov $f3,DPStacks+3
	inc $f2
	mov $f3,DPStacks+4
	dec x
	jmp RoutineCalcBackV
+++	pop x
	pop y
	ret


RoutineCalcShared:
--	mov a,HardActTrk+x
	cmp a,DPStacks
	beq +
	dec x 
	bpl --
	bra ++
+	mov y,a
	mov a,Konz700LoadRef+3
	mov LoadAddr+1,a ;update instrument table
	call RoutineLoadInst
	asl a
	asl a
	asl a
	mov LoadAddr,a
	mov a,x
++	cmp x,#$00
	ret


RoutineCalcMixer:
	mov a,GlobalVol
	mov $f2,#$0c
	mov $f3,a
	mov $f2,#$1c
	mov $f3,a
	dec a
	mov $f2,#$2c
	mov $f3,a
	mov $f2,#$3c
	mov $f3,a
	ret

RoutineLoadInst:
	mov a,VTkE0inst+y
	and a,#$1f
	bne +++
	push y
	mov a,VTkF1key+y ;load drum key (C3, C#3 and onwards..)
	setc
	sbc a,#$18
	pop y
+++	ret

RoutineIncWord:
	push a
	mov a,TrkAddr+x
	inc a
	bne +
	inc TrkAddr+1+x
+	mov TrkAddr+x,a
	mov y,#$00
	pop a
	ret


PresetDSPs:
	db $0c,$1c,$2c,$3c,$4c,$0d,$2d,$3d,$4d,$7d,$0f,$1f,$2f,$3f,$4f,$5f,$6f,$7f
PresetBitmask:
	db $01,$02,$04,$08,$10,$20,$40,$80
PresetTuning:
	db $42,$46,$4A,$4F,$53,$58,$5E,$63,$69,$70,$76,$7E ;12 8-bit lowest possible octave


Konz700SFXArray:
	dw KonzSFX01
	dw KonzSFX02
	dw KonzSFX03
	dw KonzSFX04
	dw KonzSFX05
	dw KonzSFX06
	dw KonzSFX07
	dw KonzSFX08
	dw KonzSFX09
	dw KonzSFX0A
	dw KonzSFX0B
	dw KonzSFX0C
	dw KonzSFX0D
	dw KonzSFX0E
	dw KonzSFX0F
	
	dw KonzSFX10
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty

	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty

	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty
	dw KonzSFXEmpty


KonzSFX01:
	db $00,$07,$5F
	db $20
	db $08,$5C
	db $00,$FF

KonzSFX02:
	db $00,$08,$3F
	db $18
	db $08,$5C
	db $00,$FF

KonzSFX03:
	db $00,$09,$5F
	db $10
	db $08,$5C
	db $00,$FF

KonzSFX04:
	db $00,$0A,$5F
	db $60
	db $08,$5C
	db $00,$FF

KonzSFX05:
	db $00,$0B,$5F
	db $60
	db $08,$5C
	db $00,$FF

KonzSFX06:
	db $00,$0C,$5F
	db $60
	db $08,$5C
	db $00,$FF

KonzSFX07:
	db $00,$0D,$5F
	db $60
	db $08,$5C
	db $00,$FF

KonzSFX08:
	db $00,$18,$7F
	db $24
	db $03,$84
	db $12
	db $04,$2E
	db $18
	db $04,$B2
	db $00,$18,$3F
	db $24
	db $07,$0A
	db $12
	db $08,$5E
	db $0C
	db $09,$64
	db $00,$18,$1F
	db $0C
	db $09,$64
	db $00,$FF


KonzSFX09:
	db $00,$0A,$5F
	db $60
	db $09,$00
	db $00,$FF

KonzSFX0A:
	db $00,$0A,$5F
	db $60
	db $0A,$00
	db $00,$FF

KonzSFX0B:
	db $00,$0A,$5F
	db $60
	db $0B,$00
	db $00,$FF

KonzSFX0C:
	db $00,$0A,$5F
	db $60
	db $0C,$00
	db $00,$FF

KonzSFX0D:
	db $00,$0A,$5F
	db $60
	db $0D,$00
	db $00,$FF

KonzSFX0E:
	db $00,$0A,$5F
	db $60
	db $0E,$00
	db $00,$FF

KonzSFX0F:
	db $00,$0A,$5F
	db $60
	db $0F,$00
	db $00,$FF

KonzSFX10:
	db $00,$0A,$7F
	db $80,$E0
	db $03,$14
	db $00,$FF
	
KonzSFXEmpty:
	db $00,$FF



Konz700MusicArray:
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw Konz700MusicData
	dw $4f47

base !RangeMusic
Konz700MusicData:
LatestTrackEnd:

base !RangeSamples
InstrumentData:


norom
arch 65816
dpbase $0000
optimize dp always