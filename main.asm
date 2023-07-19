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
; MAX_UserData	equ $4000
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
; 		include	"system/mcd/const.asm"		; Sega CD variables
		include	"system/md/ram.asm"		; Genesis RAM sections
		include	"system/mcd/const.asm"		; Genesis variables
		include	"system/mars/map.asm"		; 32X hardware map
		include "game/global.asm"		; Global user variables on the Genesis

; ====================================================================
; ----------------------------------------------------------------
; Init
; ----------------------------------------------------------------

; ---------------------------------------------
; 32X INIT
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
; SEGA CD INIT
; ---------------------------------------------
	elseif MCD|MARSCD
		include	"system/head_mcd.asm"			; Sega CD header
mcdin_top:
		move.b	(sysmcd_reg+mcd_memory+1).l,d0		; Set WORDRAM to SUB, DMNA=1
		bset	#1,d0
		move.b	d0,(sysmcd_reg+mcd_memory+1).l
		if MARSCD
		include "system/mcd/marscd.asm"
		endif
		lea	Md_SysCode(pc),a0			; Transfer SYSTEM code
		lea	(RAM_SystemCode),a1
		move.w	#((Md_SysCode_e-Md_SysCode))-1,d0
.copyme:
		move.b	(a0)+,(a1)+
		dbf	d0,.copyme
		lea	Md_JumpCode(pc),a0			; Transfer JUMP code
		lea	(RAM_ScreenJump),a1
		move.w	#((Md_JumpCode_e-Md_JumpCode))-1,d0
.copyme_2:
		move.b	(a0)+,(a1)+
		dbf	d0,.copyme_2

		lea	(sysmcd_reg+mcd_dcomm_m),a0
		move.l	#"WORD",(a0)+
		move.l	#"DATA",(a0)+
		move.l	#".BIN",(a0)+
		move.w	#0,(a0)+
		moveq	#$02,d0
		jsr	(System_McdSubTask).l
		jsr	(Sound_init).l
		jsr	(Video_init).l
		jsr	(System_Init).l
		move.w	#0,(RAM_Glbl_Scrn).w			; *** TEMPORAL ***
		jmp	(Md_ReadModes).l
mcdin_end:
		phase $FFFF2000+(mcdin_end-mcdin_top)
Z80_CODE:	include "sound/gema_zdrv.asm"			; Called once
Z80_CODE_END:
Gema_MasterList:	; TEMPORAL
		dephase

; ---------------------------------------------
; MD INIT
; ---------------------------------------------
	else
		include	"system/head_md.asm"			; Genesis header
		jsr	(Sound_init).l
		jsr	(Video_init).l
		jsr	(System_Init).l
		move.w	#0,(RAM_Glbl_Scrn).w			; *** TEMPORAL ***
		bra.w	Md_ReadModes

; ---------------------------------------------
	endif

; ====================================================================
; --------------------------------------------------------
; SYSTEM and MODE code
; --------------------------------------------------------

; ---------------------------------------------
; TOP-RAM Genesis system routines
; ---------------------------------------------

Md_SysCode:
	if MCD|MARS|MARSCD
		phase RAM_SystemCode
	endif

; ---------------------------------------------
		include	"sound/gema.asm"
		include	"system/md/video.asm"
		include	"system/md/system.asm"
	if MARSCD
		include "system/md/sub_dreq.asm"	; Will fail on hardware anyway.
	endif
; ---------------------------------------------
	if MCD|MARS|MARSCD
.end:
		report "RAM TOP-CODE SUBS",(.end-RAM_SystemCode),MAX_SysCode
		dephase
	endif
Md_SysCode_e:
		align 2

; ---------------------------------------------
; JUMP code for switching screen modes
; ---------------------------------------------

Md_JumpCode:
	if MCD|MARS|MARSCD	; $FF0000
		phase RAM_ScreenJump
mdjumpcode_s:
	endif
; ---------------------------------------------

Md_ReadModes:
		moveq	#0,d0
		move.w	(RAM_Glbl_Scrn).w,d0
		and.w	#%1111,d0		; <-- current limit
	if MCD|MARSCD
		lsl.w	#4,d0			; * 8
		lea	.pick_boot(pc),a0
		jsr	(System_GrabRamCode).l
	elseif MARS
		lsl.w	#2,d0			; *4
		move.l	.pick_boot(pc,d0.w),d0
		jsr	(System_GrabRamCode).l
	else
		lsl.w	#2,d0			; *4
		move.l	.pick_boot(pc,d0.w),d0
		move.l	d0,a0
		jsr	(a0)
	endif
		bra.s	Md_ReadModes

.pick_boot:
	; size $10
	if MCD|MARSCD
		dc.b "SCREEN00.BIN"
		dc.l 0
		dc.b "SCREEN00.BIN"
		dc.l 0
		dc.b "SCREEN00.BIN"
		dc.l 0
		dc.b "SCREEN00.BIN"
		dc.l 0
	; size 4
	else
		dc.l RamCode_Scrn0
		dc.l RamCode_Scrn0
		dc.l RamCode_Scrn0
		dc.l RamCode_Scrn0
	endif

; ---------------------------------------------
	if MCD|MARS|MARSCD
mdjumpcode_e:
		report "RAM JUMP-CODE SUBS",(mdjumpcode_e-mdjumpcode_s),$180
		dephase
	endif
Md_JumpCode_e:
		align 2

; ===========================================================================
; ----------------------------------------------------------------
; SEGA CD ONLY
;
; ISO file
; ----------------------------------------------------------------

	if MCD|MARSCD

; --------------------------------------------------------

		align $8000
		binclude "system/mcd/fshead.bin"
IsoFsSector:	iso_setfs 0,IsoFileList,IsoFileList_e	; Two copies of this
; 		iso_setfs 1,IsoFileList,IsoFileList_e
IsoFileList:
		iso_file "SCREEN00.BIN",SAT_Main,SAT_Main_e
		iso_file "WORDDATA.BIN",GFXDMA_WRAM,GFXDMA_WRAM_e
		iso_file "MARSCODE.BIN",CD32_Start,CD32_End
		align $800
IsoFileList_e:

; ----------------------------------------------------------------
; Files
; ----------------------------------------------------------------

; --------------------------------------------------------
; Screen modes
; --------------------------------------------------------

		align $800
SAT_Main:
		phase RAM_UserCode
		include "game/screen_0.asm"
		dephase
		align $800
SAT_Main_e:

; --------------------------------------------------------
; Screen modes
; --------------------------------------------------------

		align $800
GFXDMA_WRAM:
		phase sysmcd_wram
		include "game/data/md_dma.asm"
		include "game/data/md_bank0.asm"	; <-- 68K ONLY bank data
		dephase
		align $800
GFXDMA_WRAM_e:

; --------------------------------------------------------
; Screen modes
; --------------------------------------------------------

; 	if MARS
		align $800
CD32_Start:
		include "system/mars/code.asm"
		cpu 68000
		padding off
		dephase
		align $800
CD32_End:
		align 4

	endif

; ====================================================================
; --------------------------------------------------------
; Genesis and Sega 32X ROM section
;
; 32X: $880000+ area
; --------------------------------------------------------

	if MCD|MARSCD=0

; --------------------------------------------------------
; Screen modes
; --------------------------------------------------------

RamCode_Scrn0:
	if MARS
		dc.w cscrn0_e-cscrn0_s
		phase RAM_UserCode
	endif
cscrn0_s:
		include "game/screen_0.asm"
cscrn0_e:
	if MARS
		dephase
	endif

; --------------------------------------------------------

		align 4
	if MARS
		phase $880000+*
	endif
		include "system/md/sub_dreq.asm"	; DREQ transfer only works on 880000
Z80_CODE:	include "sound/gema_zdrv.asm"		; Called once
Z80_CODE_END:
		include "sound/tracks.asm"		; GEMA: Track data
		include "sound/instr.asm"		; GEMA: FM instruments
		include "sound/smpl_dac.asm"		; GEMA: DAC samples
	if MARS
		dephase
	endif
		align 2

; ====================================================================
; ----------------------------------------------------------------
; 68K DATA BANKs at $900000 1MB max
; ----------------------------------------------------------------

; ---------------------------------------------
; BANK 0
; ---------------------------------------------

		phase $900000+*				; ** Currently this one only.
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
; 32X ONLY:
;
; SH2 code and ROM data
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

	endif


; ====================================================================
; ---------------------------------------------
; End
; ---------------------------------------------

ROM_END:
		align $8000
