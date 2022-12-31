; ===========================================================================
; +-----------------------------------------------------------------+
; PROJECT MARSIANO
; +-----------------------------------------------------------------+

		include	"system/macros.asm"		; Assembler macros
		include	"system/shared.asm"		; Shared Genesis/32X variables
		include	"system/md/map.asm"		; Genesis hardware map
		include	"system/md/const.asm"		; Genesis variables
		include	"system/mars/map.asm"		; 32X hardware map
		include "code/global.asm"		; Global user variables on the Genesis
		include	"system/head.asm"		; 32X header

; ====================================================================
; ----------------------------------------------------------------
; Main
; ----------------------------------------------------------------

		lea	(Md_TopCode+$880000),a0			; Transfer common 68K code
		lea	($FF0000),a1				; at the top of RAM
		move.w	#((Md_TopCode_e-Md_TopCode))-1,d0
.copyme:
		move.b	(a0)+,(a1)+
		dbf	d0,.copyme
		jsr	(Sound_init).l
		jsr	(Video_init).l
		jsr	(System_Init).l
		move.w	#0,(RAM_Glbl_Scrn).w			; *** TEMPORAL ***
		jmp	(Md_ReadModes).l

; ====================================================================
; --------------------------------------------------------
; TOP 68K code
; --------------------------------------------------------

Md_TopCode:
		phase $FF0000
minfo_ram_s:
		include	"system/md/sound.asm"
		include	"system/md/video.asm"
		include	"system/md/system.asm"
Md_ReadModes:
		moveq	#0,d0
		move.w	(RAM_Glbl_Scrn).w,d0
		and.w	#%0111,d0		; <-- current limit
		lsl.w	#2,d0
		move.l	.pick_boot(pc,d0.w),d0
		jsr	(System_GrabRamCode).l
		bra.s	Md_ReadModes
.pick_boot:
		dc.l RamCode_Scrn1
		dc.l RamCode_Scrn2
		dc.l RamCode_Debug
		dc.l RamCode_Debug
		dc.l RamCode_Debug
		dc.l RamCode_Debug
		dc.l RamCode_Debug
		dc.l RamCode_Debug

	if MOMPASS=6
.here:		message "MD TOP RAM-CODE uses: \{.here-minfo_ram_s}"
	endif
RAMCODE_USER:
		dephase
Md_TopCode_e:
		align 2

; ====================================================================
; --------------------------------------------------------
; Screen modes
; --------------------------------------------------------

RamCode_Scrn1:
		phase RAMCODE_USER
		include "code/screen_1.asm"
.here:
	if MOMPASS=6
		message "THIS RAM-CODE ends at: \{.here}"
	endif
		dephase
RamCode_Scrn2:
		phase RAMCODE_USER
		include "code/screen_2.asm"
.here:
	if MOMPASS=6
		message "THIS RAM-CODE ends at: \{.here}"
	endif
		dephase
RamCode_Debug:
		phase RAMCODE_USER
		include "code/debug.asm"
.here:
	if MOMPASS=6
		message "THIS RAM-CODE ends at: \{.here}"
	endif
		dephase

; ====================================================================
; --------------------------------------------------------
; Stuff stored on the 880000+ ROM area
; --------------------------------------------------------

		align 4
		phase $880000+*
Z80_CODE:	include "system/md/z_driver.asm"	; Called once
Z80_CODE_END:
		include "system/md/sub_dreq.asm"	; DREQ transfer only works on 880000
		include "sound/tracks.asm"		; GEMA: Track data
		include "sound/instr.asm"		; GEMA: FM instruments
		include "sound/smpl_dac.asm"		; GEMA: DAC samples
		dephase
		align 2

; ====================================================================
; ----------------------------------------------------------------
; 68K DATA BANKs at $900000 1MB max
; ----------------------------------------------------------------

; ---------------------------------------------
; BANK 0
; ---------------------------------------------

		phase $900000+*			; ** Currently this one only.
MDBNK0_START:
		include "data/md_bank0.asm"	; <-- 68K ONLY bank data
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
; MD DMA data: Requires RV bit set to 1, BANK-free
; ----------------------------------------------------------------

		align 4
		include "data/md_dma.asm"

; ====================================================================
; ----------------------------------------------------------------
; SH2 SDRAM CODE
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
; SH2's ROM view
; This section will be gone if RV bit is set to 1
; --------------------------------------------------------

		phase CS1+*
		align 4
		include "sound/smpl_pwm.asm"		; GEMA: PWM samples
		include "data/mars_rom.asm"
		dephase

; ====================================================================
; ---------------------------------------------
; End
; ---------------------------------------------

ROM_END:
		align $8000
