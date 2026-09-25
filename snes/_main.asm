;AddmusicK 1.0.11 to standard N-SPC batch converter
norom
arch 65816
dpbase $0000
optimize dp always

;zeropage
org $000000
base $000000

skip 1 ;offset by one (compared to SPC-side defines)
DPTimerUnit: ;units to divide timer from
skip 2
DPTimerMin:
skip 2
DPTimerSec:
skip 2
DPTimerMil:
skip 2
DPTimerFrc:
skip 2

DPTimer:
skip 2
DPScoreMils:
skip 2
DPScoreTens:
skip 2
DPScoreHund: ;ignore last 0 here
skip 2
DPJoyIn: ;read from joycon
skip 2
DPJoyOut: ;wait for latest result to be processed
skip 2
DPPlayMode:
skip 2
DPCursorPos:
skip 2
DPLatestPos:
skip 2
DPNowLevel:
skip 2
DPNowField:
skip 2
DPNowScene:
skip 2
DPNowTint:
skip 2
DPNowMusic:
skip 2
DPNowSFX:
skip 2
DPNowSample:
skip 2
DPNowGridS: ;grid size
skip 2
DPNowExt: ;extended
skip 2
DPNowQuest:
skip 2

DPGridBegin:
skip 2
DPGridEnd:
skip 2
DPGridPos:
skip 2
DPGridVal:
skip 2
DPGridCount:
skip 2
DPGridComp:
skip 2
DPGridMat:
skip 2
DPGridTop: ;highest match
skip 2

DPVolMusic:
skip 2
DPVolSFX:
skip 2

DPRenderMode:
skip 2
DPRenderRow:
skip 2
DPRenderColumn:
skip 2
DPRenderPos:
skip 2
DPRenderBytes:
skip 2
DPRenderBytedown:
skip 2
DPRenderColor:
skip 2
DPRenderDelay:
skip 2

DPRenderBegin:
skip 2
DPRenderEnd:
skip 2

DPRandomVal1:
skip 2
DPRandomVal2:
skip 2


DPStat0s:
skip 2
DPStat1s:
skip 2
DPStat2s:
skip 2
DPStat3s:
skip 2
DPStat4s:
skip 2
DPStat5s:
skip 2
DPStat6s:
skip 2
DPStat7s:
skip 2

DPStat8s:
skip 2
DPStat9s:
skip 2
DPCStatMoves:
skip 2
DPCStatMat3:
skip 2
DPCStatMat4:
skip 2
DPCStatMat5:
skip 2
DPCStatMat6:
skip 2



DPStack:
skip 16


;screen pages
org $000100
base $000100
SPLayer1ASCII: ;8x8 100-4FF
skip 1024

SPLayer1FG: ;16x16 500-5FF layer 1 foreground (cursor, etc.)
skip 256

SPLayer2FG: ;16x16 600-6FF layer 2 foreground (puzzle tiles, overlay this on top of layer 2 BG)
skip 256

SPLayer2BG: ;16x16 700-7FF layer 2 background (mirrored in automatically)
skip 256

SPLayerX: ;16x16 800-8FF layer X ghost shadow (not actually rendered)
skip 256

OPStoreRecords: ;store high scores for each round informally (no SRAM due to jam rules :v:)
skip 256


org $000f00
base $000f00
VRAMBuffer: ;VRAM buffer (0F00-1EFF) [E000-E7FF or E800-EFFF]
skip 2048


;SNES-side program
org $007FC0
base $00FFC0 ;SFC_ROMNAME
	db "DEKREMIT                "


org $007FD5
base $00FFD5 ;SFC_ROMMETA
	db $00 ;LoRom
	db $01 ;ROM + RAM
	db $09 ;ROM size
	db $00 ;$01 ;SRAM size
	db $01 ;country code
	db $FA ;developer ID
	db $00 ;ROM version
	dw $0000
	dw $0000

org $007FE0
base $00FFE0
	db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00
	db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$80,$00,$00

;BANK 0
org $000000
base $808000 ;BANK 0
incsrc "b00.asm"

org $008000 ;BANK 1
base $818000
incsrc "b01.asm"

org $010000 ;BANK 2
base $828000
incsrc "b02.asm"

org $018000 ;BANK 3
base $838000
incsrc "b03.asm"

org $020000 ;BANK 4
base $848000
incsrc "b04.asm"

org $028000 ;BANK 5
base $858000
incsrc "b05.asm"

org $030000 ;BANK 6
base $868000
incsrc "b06.asm"

org $038000 ;BANK 7
base $878000
incsrc "b07.asm"

org $040000 ;BANK 8
base $888000
incsrc "b08.asm"

org $048000 ;BANK 9
base $898000
incsrc "b09.asm"

org $050000 ;BANK A
base $8A8000
incsrc "b0A.asm"

org $058000 ;BANK B
base $8B8000
incsrc "b0B.asm"

org $060000 ;BANK C
base $8C8000
incsrc "b0C.asm"

org $068000 ;BANK D
base $8D8000
incsrc "b0D.asm"

org $070000 ;BANK E
base $8E8000
incsrc "b0E.asm"

org $078000 ;BANK F
base $8F8000
incsrc "b0F.asm"


fill align 32768