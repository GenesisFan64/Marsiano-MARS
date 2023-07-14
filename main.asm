; ===========================================================================
; +-----------------------------------------------------------------+
; PROJECT MARSIANO
; +-----------------------------------------------------------------+

		!org 0				; Start at 0
		cpu 		68000		; Current CPU is 68k, gets changed later.
		padding		off		; Dont pad dc.b
		listing 	purecode	; Want listing file, but only the final code in expanded macros
		supmode 	on 		; Supervisor mode 68k
		dottedstructs	off		; If needed
		page 		0

; ====================================================================
; ----------------------------------------------------------------
; USER SETTINGS
; ----------------------------------------------------------------

; RAM Sizes
;
; MAKE SURE IT DOESN'T REACH FC00 FOR CROSS-PORTING
; TO SEGA-CD (And maybe SCD+32X)

MAX_SysCode	equ $2000
MAX_UserCode	equ $2000
MAX_UserData	equ $4000
MAX_MdVideo	equ $2000
MAX_MdSystem	equ $0800
MAX_MdOther	equ $2000	; 32X's DREQ data to send
MAX_MdGlobal	equ $1000	; USER Global variables
MAX_ScrnBuff	equ $2000	; RAM section for current screen ONLY

; ====================================================================
; ----------------------------------------------------------------
; Includes
; ----------------------------------------------------------------

		include	"macros.asm"			; Assembler macros
		include	"system/shared.asm"		; Shared Genesis/32X variables
		include	"system/md/map.asm"		; Genesis hardware map
		include	"system/md/const.asm"		; Genesis variables
		include	"system/md/ram.asm"		; Genesis RAM sections
		include	"system/mars/map.asm"		; 32X hardware map
		include "game/global.asm"		; Global user variables on the Genesis

; ====================================================================
; ----------------------------------------------------------------
; Main
; ----------------------------------------------------------------

; ---------------------------------------------
; 32X MAIN
; ---------------------------------------------

	if MARS
		include	"system/head_mars.asm"			; 32X header
		lea	($880000+Md_SysCode),a0			; Transfer SYSTEM code
		lea	(RAM_SystemCode),a1
		move.w	#((Md_SysCode_e-Md_SysCode))-1,d0
.copyme:
		move.b	(a0)+,(a1)+
		dbf	d0,.copyme
		lea	($880000+Md_JumpCode),a0		; Transfer JUMP code
		lea	(RAM_ScreenJump),a1
		move.w	#((Md_JumpCode_e-Md_JumpCode))-1,d0
.copyme_2:
		move.b	(a0)+,(a1)+
		dbf	d0,.copyme_2

		jsr	(Sound_init).l
		jsr	(Video_init).l
		jsr	(System_Init).l
		move.w	#0,(RAM_Glbl_Scrn).w			; *** TEMPORAL ***
		jmp	(Md_ReadModes).l

; ---------------------------------------------
; MD MAIN
; ---------------------------------------------
	else
		include	"system/head_md.asm"		; Genesis header
		jsr	(Sound_init).l
		jsr	(Video_init).l
		jsr	(System_Init).l
		move.w	#0,(RAM_Glbl_Scrn).w			; *** TEMPORAL ***
		bra.w	Md_ReadModes

; ---------------------------------------------
	endif

; ====================================================================
; --------------------------------------------------------
; Code sections
; --------------------------------------------------------

		align $1000
; ---------------------------------------------
; TOP-RAM Genesis system routines
; ---------------------------------------------

	if MARS
Md_SysCode:
		phase RAM_SystemCode
	endif
; ---------------------------------------------
		include	"sound/gema.asm"
		include	"system/md/video.asm"
		include	"system/md/system.asm"
; ---------------------------------------------
	if MARS
.end:
	if (.end-RAM_SystemCode) > MAX_SysCode
		error "RAN OUT OF TOP-CODE"
	else
		report "RAM TOP-CODE SUBS",(.end-RAM_SystemCode)
	endif
		dephase
Md_SysCode_e:
		align 2
	endif

; ---------------------------------------------
; JUMP code for switching screen modes
;
; $100 BYTES ONLY!
; ---------------------------------------------

	if MARS
Md_JumpCode:
		phase RAM_ScreenJump
	endif
; ---------------------------------------------

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

; ---------------------------------------------
	if MARS
.end:
	if (.end-RAM_ScreenJump) > $100 ; $FFFF00-$FFFFFF
		error "RAN OUT OF JUMP-CODE"
	else
		report "RAM JUMP-CODE SUBS",(.end-Md_ReadModes)
	endif
		dephase
Md_JumpCode_e:
		align 2
	endif

; ====================================================================
; --------------------------------------------------------
; Screen modes
; --------------------------------------------------------

RamCode_Scrn1:
	if MARS
		phase RAM_UserCode
	endif
		include "game/screen_1.asm"
.here:
	if MARS
		dephase
	endif

RamCode_Scrn2:
	if MARS
		phase RAM_UserCode
	endif
		include "game/screen_2.asm"
.here:
	if MARS
		dephase
	endif

RamCode_Debug:
	if MARS
		phase RAM_UserCode
	endif
		include "game/debug.asm"
.here:
	if MARS
		dephase
	endif

; ====================================================================
; --------------------------------------------------------
; Stuff stored on the 880000+ ROM area
; --------------------------------------------------------

		align 4
		phase $880000+*
		include "system/md/sub_dreq.asm"	; DREQ transfer only works on 880000
Z80_CODE:	include "sound/gema_zdrv.asm"		; Called once
Z80_CODE_END:
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
		include "game/data/md_bank0.asm"	; <-- 68K ONLY bank data
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
; 		include "game/data/md_bank1.asm"
; 		dephase
; 		org $200000-4
; 		dc.b "BNK1"

; ---------------------------------------------
; BANK 2
; ---------------------------------------------

; 		phase $900000
; 		include "game/data/md_bank2.asm"
; 		dephase
; 		org $300000-4
; 		dc.b "BNK2"

; ---------------------------------------------
; BANK 3
; ---------------------------------------------

; 		phase $900000
; 		include "game/data/md_bank3.asm"
; 		dephase
; 		org $400000-4
; 		dc.b "BNK3"

; ====================================================================
; ----------------------------------------------------------------
; MD DMA data: Requires RV bit set to 1, BANK-free
; ----------------------------------------------------------------

		align 4
		include "game/data/md_dma.asm"

; ====================================================================
; ----------------------------------------------------------------
; SH2 SDRAM CODE
; ----------------------------------------------------------------

	if MARS
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
		include "game/data/mars_rom.asm"
		dephase
	endif

; ====================================================================
; ---------------------------------------------
; End
; ---------------------------------------------

ROM_END:
		align $8000
