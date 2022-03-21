; ===========================================================================
; +-----------------------------------------------------------------+
; PROJECT MARSIANO
; +-----------------------------------------------------------------+

		include	"system/macros.asm"	; Assembler macros
		include	"system/md/map.asm"	; Genesis hardware map
		include	"system/md/const.asm"	; Genesis variables (and some shared with SH2)
		include	"system/mars/map.asm"	; 32X hardware map
		include	"system/mars/dreq.asm"	; DREQ map for both sides
		include "code/global.asm"	; Global user variables on the Genesis
		include	"system/head.asm"	; 32X header

; ====================================================================
; ----------------------------------------------------------------
; Main 68k code
; ----------------------------------------------------------------

		jmp	(thisCode_Top).l

; ====================================================================
; --------------------------------------------------------
; Section stored at the $880000 area
; --------------------------------------------------------

MdRamCode:
		phase $880000+*
		include	"system/md/sound.asm"
		include	"system/md/video.asm"
		include	"system/md/system.asm"
		include "code/default.asm"
		dephase
MdRamCode_end:
		align 2

; ====================================================================
; ----------------------------------------------------------------
; 68K DATA BANKs at $900000 1MB max
; ----------------------------------------------------------------

; ---------------------------------------------
; BANK 0
;
; First one is smaller than the others...
; ---------------------------------------------

		phase $900000+*				; Only one currently
		include "sound/tracks.asm"
		include "sound/instr.asm"
		include "sound/smpl_dac.asm"
		include "data/md_bank0.asm"
		dephase
; 		org $100000-4				; Fill this bank and
; 		dc.b "BNK0"				; add a tag at the end

; ---------------------------------------------
; BANK 1
; ---------------------------------------------

; 		phase $900000
; 		include "data/md_bank1.asm"
; 		dephase
; 		org $200000-4
; 		dc.b "BNK1"

; ---------------------------------------------
; BANK 2
; ---------------------------------------------

; 		phase $900000
; 		include "data/md_bank2.asm"
; 		dephase
; 		org $300000-4
; 		dc.b "BNK2"

; ---------------------------------------------
; BANK 3
; ---------------------------------------------

; 		phase $900000
; 		include "data/md_bank3.asm"
; 		dephase
; 		org $400000-4
; 		dc.b "BNK3"

; ====================================================================
; ----------------------------------------------------------------
; MD DMA data: BANK-free but requres RV=1
; ----------------------------------------------------------------

		align 4
		include "data/md_dma.asm"

; ====================================================================
; ----------------------------------------------------------------
; SH2 RAM CODE
; ----------------------------------------------------------------

		align 4
MARS_RAMDATA:
		include "system/mars/code.asm"
		cpu 68000
		padding off
		dephase
MARS_RAMDATA_E:
		align 4

; ====================================================================
; --------------------------------------------------------
; MARS exclusive data for SH2's ROM view
; This section will be gone if RV=1
; --------------------------------------------------------

		phase CS1+*
		align 4
		include "data/mars_rom.asm"
		include "sound/smpl_pwm.asm"
		dephase

; ====================================================================
; ---------------------------------------------
; End
; ---------------------------------------------

ROM_END:
		align $8000
