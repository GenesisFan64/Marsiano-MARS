; ===========================================================================
; +-----------------------------------------------------------------+
; PROJECT MARSIANO
; +-----------------------------------------------------------------+

		include	"system/macros.asm"	; Assembler macros
		include	"system/shared.asm"	; Shared Genesis/32X variables
		include	"system/md/map.asm"	; Genesis hardware map
		include	"system/md/const.asm"	; Genesis variables
		include	"system/mars/map.asm"	; 32X hardware map
		include "code/global.asm"	; Global user variables on the Genesis
		include	"system/head.asm"	; 32X header

; ====================================================================
; ----------------------------------------------------------------
; Main
; ----------------------------------------------------------------

		lea	(Md_TopCode+$880000),a0		; Transfer RAM-shared code
		lea	($FF0000),a1
		move.w	#((Md_TopCode_e-Md_TopCode))-1,d0
.copyme:
		move.b	(a0)+,(a1)+
		dbf	d0,.copyme
		jsr	(Sound_init).l
		jsr	(Video_init).l
		jsr	(System_Init).l
		move.l	#RamCode_Boot,d0
		jmp	(System_JumpRamCode).l

; ====================================================================
; --------------------------------------------------------
; All shared routines at the top of RAM
; --------------------------------------------------------

Md_TopCode:
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
Md_TopCode_e:
		align 2

; ====================================================================
; --------------------------------------------------------
; RAM code sections for 68K
; --------------------------------------------------------

RamCode_Boot:
		phase RAMCODE_USER
		include "code/main.asm"
		include "code/debug.asm"
		dephase
.here:
	if MOMPASS=6
		message "THIS RAM-BANK uses: \{.here-RamCode_Boot} of \{MDRAM_START&$FFFF-RAMCODE_USER&$FFFF}"
	endif
;
; ; ====================================================================
; ; --------------------------------------------------------
; ; Section stored at the $880000 area
; ; --------------------------------------------------------
;
; 		phase $FF0000
; Md_TopCode:
; 		include	"system/md/sound.asm"
; 		include	"system/md/video.asm"
; 		include	"system/md/system.asm"
; 		include "code/main.asm"
; 		include "code/debug.asm"
; Md_TopCode_e:
; 		dephase
; 		align 2
;
; 	if MOMPASS=6
; .end:
; 		message "Fixed 68K code ends at: \{Md_TopCode_end}"
; 	endif

; ====================================================================
; --------------------------------------------------------
; Stuff that needs to be stored on the $880000+ area
; --------------------------------------------------------

		align 4
		phase $880000+*
		include "system/md/sub_dreq.asm"
Z80_CODE:	include "system/md/z_driver.asm"
Z80_CODE_END:
		dephase
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

		phase $900000+*			; Only one currently
MDBNK0_START:
		include "sound/tracks.asm"
		include "sound/instr.asm"
		include "sound/smpl_dac.asm"
		include "data/md_bank0.asm"
MDBNK0_END:
		dephase
; 		org $100000-4			; Fill this bank and
; 		dc.b "BNK0"			; add a tag at the end

	if MOMPASS=6
.end:
		message "68k BANK 0: \{MDBNK0_START}-\{MDBNK0_END}"
	endif

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
; 32X data for SH2's ROM view
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
