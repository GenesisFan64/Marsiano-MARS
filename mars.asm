; ===========================================================================
; +-----------------------------------------------------------------+
; PROJECT MARSIANO
; +-----------------------------------------------------------------+

		include	"system/macros.asm"	; Assembler macros
		include	"system/md/const.asm"	; MD and MARS Variables
		include	"system/md/map.asm"	; Genesis hardware map
		include	"system/mars/map.asm"	; MARS map
		
; ====================================================================
; ----------------------------------------------------------------
; Header
; ----------------------------------------------------------------

		include	"system/head.asm"	; 32X Header and boot sequence

; ====================================================================
; --------------------------------------------------------
; All purpose 68k stored on RAM
; --------------------------------------------------------

MdRamCode:
		phase $FF0000
minfo_ram_s:
		include	"system/md/sound.asm"
		include	"system/md/video.asm"
		include	"system/md/system.asm"
	if MOMPASS=6
.here:
		message "MD TOP RAM-CODE uses: \{.here-minfo_ram_s}"
	endif
RAMCODE_USER:
		dephase

MdRamCode_end:
		align 2

; ====================================================================
; ----------------------------------------------------------------
; Z80 code (read once)
; ----------------------------------------------------------------

		align $80
Z80_CODE:
		include "system/md/z80.asm"
		cpu 68000
		padding off
		phase Z80_CODE+*
Z80_CODE_END:
		align 2

; ====================================================================
; ----------------------------------------------------------------
; 68k code-banks for RAM
;
; 880000 area: 512KB max
; ----------------------------------------------------------------

Default_Boot:
		phase RAMCODE_USER
		include "code/default.asm"
		dephase

; ====================================================================
; ----------------------------------------------------------------
; 68k DATA BANKs (at $900000) 1MB max
; ----------------------------------------------------------------

	; First one is smaller than the rest...
		phase $900000+*				; Only one currently
		include "data/md_bank0.asm"
		dephase
; 		org $100000-4				; Fill this bank and
; 		dc.b "BNK0"				; add a tag at the end

; 		phase $900000+*
; 		include "data/md_bank1.asm"
; 		dephase
; 		org $200000-4
; 		dc.b "BNK1"

; 		phase $900000+*
; 		include "data/md_bank2.asm"
; 		dephase
; 		org $300000-4
; 		dc.b "BNK2"

; 		phase $900000+*
; 		include "data/md_bank3.asm"
; 		dephase
; 		org $400000-4
; 		dc.b "BNK3"

; ====================================================================
; ----------------------------------------------------------------
; DMA transfer data, RV=1 only.
; ----------------------------------------------------------------

		align 4
		include "data/md_dma.asm"

; ====================================================================
; ----------------------------------------------------------------
; SH2 SECTION
; ----------------------------------------------------------------

		align 4
MARS_RAMDATA:
		include "system/mars/code.asm"
		cpu 68000
		padding off
		dephase
MARS_RAMDATA_E:
		align 4

; --------------------------------------------------------
; MARS data for SH2's ROM view
; This section will be gone if RV=1
; --------------------------------------------------------

		phase CS1+*
		align 4
		include "data/mars_rom.asm"
		dephase

; ====================================================================
; ---------------------------------------------
; End
; ---------------------------------------------
		
ROM_END:
		align $8000
