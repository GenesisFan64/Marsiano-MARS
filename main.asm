; ===========================================================================
; +-----------------------------------------------------------------+
; MARSIANO ENGINE
;
; A game engine for
; Sega Genesis, Sega CD, Sega 32X, Sega CD32X and Sega Pico
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

; RAM Sizes for Sega CD and Sega 32X
;
; MAKE SURE IT DOESN'T REACH FC00 FOR CROSS-PORTING
; TO SEGA-CD (And maybe SCD+32X)

MAX_SysCode	equ $1800	; ** CD/32X/CD32X
MAX_UserCode	equ $3000	; ** CD/32X/CD32X
MAX_MdVideo	equ $2000	;
MAX_MdSystem	equ $0500	;
MAX_MdOther	equ $2000	; System specific stuff goes here
MAX_MdGlobal	equ $0800	; USER Global variables
MAX_ScrnBuff	equ $2800	; RAM section for Current screen

; ====================================================================
; ----------------------------------------------------------------
; Includes
; ----------------------------------------------------------------

		include	"macros.asm"			; Assembler macros
		include	"system/shared.asm"		; Shared Genesis/32X/32XCD variables
		include	"system/mcd/shared.asm"		; Shared Sega CD variables
		include	"system/md/map.asm"		; Genesis hardware map
		include	"system/mars/map.asm"		; 32X hardware map (SH2 area)
		include	"system/md/ram.asm"		; Genesis RAM sections
		include "game/global.asm"		; Global user variables on the Genesis side.

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
		jsr	(Sound_init).l				; RAM jumps
		jsr	(Video_init).l
		jsr	(System_Init).l
		move.w	#0,(RAM_Glbl_Scrn).w			; *** TEMPORAL ***
		jmp	(Md_ReadModes).l

; ---------------------------------------------
; SEGA CD and CD32X INIT
; ---------------------------------------------

	elseif MCD|MARSCD
		include	"system/head_mcd.asm"			; Sega CD header
mcdin_top:
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
		lea	(sysmcd_reg+mcd_dcomm_m),a0		; Load default assets
		move.l	#"WORD",(a0)+
		move.l	#"DATA",(a0)+
		move.l	#".BIN",(a0)+
		move.w	#0,(a0)+
		moveq	#$02,d0
		jsr	(System_McdSubTask).l			; WRAM load
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
; SEGA PICO INIT
;
; Recycles the MD's routines.
; ---------------------------------------------
	elseif PICO
		include	"system/head_pico.asm"			; Pico header
		jsr	(Sound_init).l
		jsr	(Video_init).l
		jsr	(System_Init).l
		move.w	#0,(RAM_Glbl_Scrn).w			; *** TEMPORAL ***
		bra.w	Md_ReadModes

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
; SYSTEM and JUMP codes
;
; MD and PICO: Normal ROM locations
; CD/32X/32XCD: Loaded in RAM
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
; Read screen modes
;
; MD/PICO:
; Direct ROM jump
;
; SEGA 32X:
; 880000+ jump
;
; SEGACD/CD32X:
; Read file from disc, transfer to RAM or
; WordRAM and jump there.
; ---------------------------------------------

Md_ReadModes:
		moveq	#0,d0
		move.w	(RAM_Glbl_Scrn).w,d0
		and.w	#%1111,d0		; <-- current limit
	if MCD|MARSCD
		lsl.w	#4,d0			; * 8
		lea	.pick_boot(pc),a0	; LEA filename
		jsr	(System_GrabRamCode).l
	elseif MARS
		lsl.w	#2,d0			; *4
		move.l	.pick_boot(pc,d0.w),d0	; d0 - code location to transfer
		jsr	(System_GrabRamCode).l
	else
		lsl.w	#2,d0			; *4
		move.l	.pick_boot(pc,d0.w),d0
		move.l	d0,a0
		jsr	(a0)
	endif
		bra.s	Md_ReadModes		; Loop on RTS

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
		dc.l Md_Screen00
		dc.l Md_Screen00
		dc.l Md_Screen00
		dc.l Md_Screen00
	endif

; ---------------------------------------------
	if MCD|MARS|MARSCD
mdjumpcode_e:
		report "RAM JUMP-CODE SUBS",(mdjumpcode_e-mdjumpcode_s),$180
		dephase
	endif
Md_JumpCode_e:
		align 2

; ====================================================================
; --------------------------------------------------------
; DREQ routine
; --------------------------------------------------------

	if MARS
		phase $880000+*
		include "system/md/sub_dreq.asm"	; DREQ transfer only works on 880000
	endif

; ===========================================================================
; ----------------------------------------------------------------
; DATA, shared for ALL Cartridge and Disc
; ----------------------------------------------------------------

; --------------------------------------------------------
; SEGA CD / SEGA 32XCD ISO header
; --------------------------------------------------------

	if MCD|MARSCD
		align $8000	; Pad to $8000
		binclude "system/mcd/fshead.bin"
		iso_setfs 0,IsoFileList,IsoFileList_e	; TWO COPIES
		iso_setfs 1,IsoFileList,IsoFileList_e
IsoFileList:	iso_file "MARSCODE.BIN",MARS_RAMDATA,MARS_RAMDATA_E
		iso_file "WORDDATA.BIN",GFXDMA_WRAM,GFXDMA_WRAM_e
		iso_file "SCREEN00.BIN",Md_Screen00,Md_Screen00_e
		align $800
IsoFileList_e:
	endif

; ====================================================================
; --------------------------------------------------------
; Screen modes
; --------------------------------------------------------

	if MCD|MARSCD
		align $800	; Sector
	endif
Md_Screen00:
	if MCD|MARS|MARSCD
		phase RAM_UserCode
	endif
cscrn0_s:
		include "game/screen_0.asm"
cscrn0_e:
	if MARS
		dephase
	elseif MCD|MARSCD
		dephase
		align $800
	endif
Md_Screen00_e:

; ====================================================================
; --------------------------------------------------------
; SOUND Section (and DREQ...)
; --------------------------------------------------------

	if MCD|MARSCD=0
		align 4
	if MARS
		phase $880000+*
	endif
Z80_CODE:	include "sound/gema_zdrv.asm"		; Called once
Z80_CODE_END:
		include "sound/tracks.asm"		; GEMA: Track data
		include "sound/instr.asm"		; GEMA: FM instruments
		include "sound/smpl_dac.asm"		; GEMA: DAC samples
	if MARS
		dephase
	endif
		align 2
	endif

; ====================================================================
; ----------------------------------------------------------------
; 68K DATA BANKs
;
; SEGA CD:
; BANKS are limited to 256KB 2M or 128KB 1M/1M
; ** CANNOT BE USED IF USING STAMPS **
;
; SEGA 32X:
; BANKS are limited to 1MB, only 4 banks can be used
; ----------------------------------------------------------------

; ---------------------------------------------
;
; ---------------------------------------------

	if MCD|MARSCD
		align $800
	endif
GFXDMA_WRAM:
	if MARS
		phase $900000+*				; ** Currently this one only.
	elseif MCD|MARSCD
		phase sysmcd_wram
	endif

MDBNK0_START:
		include "game/data/md_bank0.asm"	; <-- 68K ONLY bank data
MDBNK0_END:
	if MARS
		dephase
	endif
; 		org $100000-4			; Fill this bank and
; 		dc.b "BNK0"			; add a tag at the end

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

; 	if MARS|MCD|MARSCD=0
; 		dephase
; 		align $8000
; 	endif
		include "game/data/md_dma.asm"
		align $800
	if MCD|MARSCD
		dephase
	endif
GFXDMA_WRAM_e:

	if MARS
		report "68K DEFAULT BANK (900000)",MDBNK0_END-MDBNK0_START,$100000
	endif
	if MCD|MARSCD
		report "68K DEFAULT BANK (WORDRAM)",MDBNK0_END-MDBNK0_START,$40000
	endif

; ====================================================================
; ----------------------------------------------------------------
; 32X ONLY:
;
; SH2 code and ROM data
; ----------------------------------------------------------------

	if MCD|MARSCD
		align $800
	elseif MARS
		align 4
	endif
MARS_RAMDATA:
	if MARS|MARSCD	; <-- meh.
		include "system/mars/code.asm"
		cpu 68000
		padding off
		dephase
	endif
	if MCD|MARSCD
		align $800
	endif
MARS_RAMDATA_E:
		align 4

; ====================================================================
; --------------------------------------------------------
; SH2's ROM-only stuff
; This section will be gone if RV bit is set to 1
; --------------------------------------------------------

	if MARS
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
	if MCD|MARSCD
		rompad $100000		; Pad the ISO file
	else
		align $8000		; Pad the Cartridge
	endif
