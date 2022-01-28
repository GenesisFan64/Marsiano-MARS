; ===========================================================================
; +-----------------------------------------------------------------+
; PROJECT MARSIANO
; +-----------------------------------------------------------------+

		include	"system/macros.asm"	; Assembler macros
		include	"system/md/const.asm"	; MD variables and shared vars
		include	"system/md/map.asm"	; Genesis hardware map
		include	"system/mars/map.asm"	; MARS map
		include	"system/mars/dreq.asm"	; MARS map
		include	"system/head.asm"	; 32X header
		include "code/global.asm"	; Global user variables for the Genesis

; ====================================================================
; ----------------------------------------------------------------
; Main 68k code
; ----------------------------------------------------------------

		lea	MdRamCode(pc),a0		; Load shared code on top
		lea	($FF0000),a1
		move.w	#((MdRamCode_end-MdRamCode))-1,d0
.copyme:
		move.b	(a0)+,(a1)+
		dbf	d0,.copyme
		move.l	#RamCode_Default,d0
		jmp	(System_JumpRamCode).l

; --------------------------------------------------------
; Top-common code stored on RAM
; --------------------------------------------------------

MdRamCode:
		phase $FF0000
minfo_ram_s:
		include	"system/md/sound.asm"
		include	"system/md/video.asm"
		include	"system/md/system.asm"
RAMCODE_USER:
		dephase
MdRamCode_end:
		align 2

; ----------------------------------------------------------------
; Z80 code
; Located at the 880000 area
; ----------------------------------------------------------------

		align 4
Z80_CODE:
		include "system/md/z_driver.asm"
		cpu 68000
		padding off
		phase Z80_CODE+*
Z80_CODE_END:
		align 2
		include "sound/instr.asm"

; ====================================================================
; ----------------------------------------------------------------
; 68k code-sections for RAM
; ----------------------------------------------------------------

RamCode_Default:
		phase RAMCODE_USER
		include "code/default.asm"
		dephase

; ====================================================================
; ----------------------------------------------------------------
; 68k DATA BANKs at $900000 1MB max
; ----------------------------------------------------------------

	; First one is smaller than the others...
		phase $900000+*				; Only one currently
		include "sound/tracks.asm"
		include "data/md_bank0.asm"
		dephase
; 		org $100000-4				; Fill this bank and
; 		dc.b "BNK0"				; add a tag at the end

; 		phase $900000;+*
; 		include "data/md_bank1.asm"
; 		dephase
; 		org $200000-4
; 		dc.b "BNK1"

; 		phase $900000;+*
; 		include "data/md_bank2.asm"
; 		dephase
; 		org $300000-4
; 		dc.b "BNK2"

; 		phase $900000;+*
; 		include "data/md_bank3.asm"
; 		dephase
; 		org $400000-4
; 		dc.b "BNK3"

; ====================================================================
; ----------------------------------------------------------------
; MD DMA data, BANK-free but requres RV=1
; ----------------------------------------------------------------

		align 4
		include "data/md_dma.asm"

; ====================================================================
; ----------------------------------------------------------------
; SH2 CODE
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
