; ===========================================================================
; +-----------------------------------------------------------------+
; MARSIANO ENGINE
;
; A game engine that can be cross-ported to:
; Sega Genesis, Sega CD, Sega 32X, Sega CD32X and Sega Pico
; +-----------------------------------------------------------------+

; ====================================================================
; ----------------------------------------------------------------
; USER SETTINGS
; ----------------------------------------------------------------

; --------------------------------------------------------
; 68000 RAM SIZES
;
; MAX_SysCode, MAX_UserCode and MAX_RamSndData
; are used only in Sega CD, Sega 32X and
; Sega CD32X
; For the stock Genesis (OR Pico) these sections
; are free to use ONLY if you want your game
; to be playable ONLY on stock Genesis or Pico.
;
; Starting from MAX_MdGlobal it the RAM should be
; located after $FF8000
;
; ** MAKE SURE IT DOESN'T REACH $FFFC00 IF YOU WANT TO
; RUN THIS ON SEGA CD AND CD32X **
; $FFFD00 is reserved for SegaCD/SegaCD32X, the
; STACK a7 point starts from here also.
; --------------------------------------------------------

MAX_SysCode	equ $1800	; ** CD/32X/CD32X ONLY
MAX_UserCode	equ $2000	; ** CD/32X/CD32X ONLY
MAX_RamSndData	equ $4000	; ** CD/32X/CD32X ONLY
MAX_MdGlobal	equ $0800	; USER Global variables
MAX_ScrnBuff	equ $2800	; RAM section for Current screen
MAX_MdVideo	equ $2000	;
MAX_MdSystem	equ $0500	;
MAX_MdOther	equ $1000	; System-specific stuff goes here

; ====================================================================

		!org 0				; Start at 0
		cpu 		68000		; Current CPU is 68k, gets changed later.
		padding		off		; Dont pad dc.b
		listing 	purecode	; Want listing file, but only the final code in expanded macros
		supmode 	on 		; Supervisor mode 68k
		dottedstructs	off		; If needed
		page 		0

; ====================================================================
; ----------------------------------------------------------------
; Includes
; ----------------------------------------------------------------

		include	"macros.asm"			; Assembler macros
		include	"system/shared.asm"		; Shared Genesis/32X/CD32X variables
		include	"system/mcd/shared.asm"		; Shared Sega CD variables
		include	"system/md/map.asm"		; Genesis hardware map
		include	"system/mars/map.asm"		; 32X hardware map (SH2 area)
		include	"system/md/ram.asm"		; Genesis RAM sections
		include "game/global.asm"		; Global user variables on the Genesis side.

; ====================================================================
; ----------------------------------------------------------------
; Init procedures
; ----------------------------------------------------------------

; ---------------------------------------------
; SEGA 32X
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
; SEGA CD and CD32X
; ---------------------------------------------

	elseif MCD|MARSCD
		include	"system/head_mcd.asm"			; Sega CD header
mcdin_top:
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
	if MARSCD						; Include 32X boot
		include "system/mcd/marscd.asm"
	endif
		lea	file_worddata(pc),a0
		jsr	(System_McdTrnsfr_WRAM).l
		jsr	(Sound_init).l
		jsr	(Video_init).l
		jsr	(System_Init).l
		lea	file_gematrks(pc),a0			; Transfer GEMA tracks and instr
		lea	(RAM_ExSoundData),a1
		move.w	#MAX_RamSndData,d0
		jsr	(System_McdTrnsfr_RAM).l
		move.w	#0,(RAM_Glbl_Scrn).w			; *** TEMPORAL ***
		jmp	(Md_ReadModes).l
file_worddata:	dc.b "WORDDATA.BIN",0
		align 2
file_gematrks:	dc.b "GEMATRKS.BIN",0
		align 2
mcdin_end:
		phase $FFFF2000+(mcdin_end-mcdin_top)
Z80_CODE:	include "sound/gema_zdrv.asm"			; Called once
Z80_CODE_END:
		dephase

; ---------------------------------------------
; SEGA PICO
;
; This recycles the MD's routines.
; ---------------------------------------------
	elseif PICO
		include	"system/head_pico.asm"			; Pico header
		jsr	(Sound_init).l
		jsr	(Video_init).l
		jsr	(System_Init).l
		move.w	#0,(RAM_Glbl_Scrn).w			; *** TEMPORAL ***
		bra.w	Md_ReadModes

; ---------------------------------------------
; MD
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
; SYSTEM and SCREEN-JUMP codes
;
; MD and PICO: Normal ROM locations
; CD/32X/CD32X: Loaded in RAM
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
		include "system/mars/md_dreq.asm"	; Tested on HW, works.
; ---------------------------------------------
	if MCD|MARS|MARSCD
.end:
		erreport "RAM TOP-CODE SUBS",(.end-RAM_SystemCode),MAX_SysCode
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
		lsl.w	#4,d0			; * $10
		lea	.pick_boot(pc),a0	; LEA the filename
		jsr	(System_GrabRamCode).l
	elseif MARS
		lsl.w	#2,d0			; * 4
		move.l	.pick_boot(pc,d0.w),d0	; d0 - code location to transfer
		jsr	(System_GrabRamCode).l
	else
		lsl.w	#2,d0			; * 4
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
		erreport "RAM JUMP-CODE SUBS",(mdjumpcode_e-mdjumpcode_s),$180
		dephase
	endif
Md_JumpCode_e:
		align 2

; ====================================================================
; --------------------------------------------------------
; Misc. stuff FOR CARTRIDGE ONLY:
;
; Genesis, Sega 32X and Pico
; --------------------------------------------------------

	if MCD|MARSCD=0

	if MARS
		phase $880000+*
	endif
Z80_CODE:	include "sound/gema_zdrv.asm"		; Called once
Z80_CODE_END:
	endif

	if MCD|MARS|MARSCD
		dephase
	endif

; ===========================================================================
; ----------------------------------------------------------------
; GAME DATA for ALL Cartridge and Disc
; ----------------------------------------------------------------

; --------------------------------------------------------
; SEGA CD / SEGA CD32X ISO header
; --------------------------------------------------------

	if MCD|MARSCD
		align $8000	; Pad to $8000
		binclude "system/mcd/fshead.bin"
		iso_setfs 0,IsoFileList,IsoFileList_e	; TWO COPIES
		iso_setfs 1,IsoFileList,IsoFileList_e
IsoFileList:	iso_file "MARSCODE.BIN",MARS_RAMDATA,MARS_RAMDATA_E
		iso_file "WORDDATA.BIN",MCD_DBANK0,MCD_DBANK0_e
		iso_file "GEMATRKS.BIN",MCD_GEMATRKS,MCD_GEMATRKS_e
		iso_file "SCREEN00.BIN",Md_Screen00,Md_Screen00_e
		align $800
IsoFileList_e:
	endif

; ====================================================================
; --------------------------------------------------------
; Screen modes
; --------------------------------------------------------

	if MCD|MARSCD
		align $800	; Sector align
	elseif MARS
		phase $880000+*
	endif
Md_Screen00:
	if MARS
		dephase
	endif
	if MCD|MARSCD|MARS
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

	if MCD|MARS|MARSCD
		report "SCREEN 0 code",cscrn0_e-cscrn0_s,MAX_UserCode
	endif

; ====================================================================
; --------------------------------------------------------
; GEMA SOUND DRIVER DATA:
; Tracks and Instruments
;
;    MD: Normal ROM area
;   MCD: Loaded to RAM from disc (Z80 CAN read from RAM)
;   32X: At the $880000+ area
; CD32X: Same as CD
;  Pico: N/A (TODO)
;
; DAC samples are stored externally depending
; of the system.
; 32X: PWM can be on both ROM and SDRAM
; but to keep cross-compatible with CD32X use
; SDRAM only, use small samples to save space.
; --------------------------------------------------------

	if MCD|MARSCD
		align $800
	endif
MCD_GEMATRKS:
	if MARS
		phase $880000+*
	elseif MCD|MARSCD
		phase RAM_ExSoundData
	endif
gemacd_report:
		include "sound/tracks.asm"		; GEMA: Track data
		include "sound/instr.asm"		; GEMA: FM instruments
gemacd_report_e:
	if MARS
		dephase
	elseif MCD|MARSCD
		align $800
		dephase
MCD_GEMATRKS_e:
		report "MCD GEMA TRACKS/INS",gemacd_report_e-gemacd_report,MAX_RamSndData
	endif

; ====================================================================
; ----------------------------------------------------------------
; 68K DATA BANKs
;
; SEGA CD:
; BANKS are stored in WORD-RAM pieces
; limited to 256KB 2M or 128KB 1M/1M
; ** THESE CANNOT BE USED IF USING ASIC STAMPS **
;
; SEGA 32X:
; BANKS are limited to 1MB, only 4 banks can be used
; ----------------------------------------------------------------

; ---------------------------------------------
; BANK 0 DEFAULT
;
; CD/CD32X:
; $200000 (WORD-RAM)
;
; 32X:
; $900000
; ---------------------------------------------

MCD_DBANK0:
	if MARS
		phase $900000+*				; ** Currently this one only.
	elseif MCD|MARSCD
		phase sysmcd_wram
	endif
mdbank0:
		include "game/data/md_bank0.asm"	; <-- 68K ONLY bank data
mdbank0_e:
		include "sound/smpl_dac.asm"		; (MCD/CD32X ONLY) GEMA: DAC samples
; 	if MARS
; 		org $100000-4				; Fill this bank and
; 		dc.b "BNK0"				; add a tag at the end
; 		dephase
	if MCD|MARSCD
		include "game/data/md_dma.asm"		; SEGA CD / CD32X ONLY.
; 		phase CS1+*
; 		include "sound/smpl_pwm.asm"		; GEMA: PWM samples
; 		dephase
	endif

	if MARS|MCD|MARSCD
mdbank0_cd_e:
		dephase
		align $800
MCD_DBANK0_e:
	endif

	if MARS
		report "68K DEFAULT BANK (900000)",mdbank0_e-mdbank0,$100000
	elseif MCD|MARSCD
		report "68K DEFAULT BANK (WORDRAM)",mdbank0_cd_e-mdbank0,$40000
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
; 32X Cartridge DMA data: Requires RV bit set to 1, BANK-free
; ----------------------------------------------------------------

		align $8000
	if MCD|MARSCD=0
		include "game/data/md_dma.asm"
	endif

; ====================================================================
; ----------------------------------------------------------------
; 32X ONLY
;
; SH2 code and ROM data
;
; ** MARSCD: Loads to WORD-RAM
; ----------------------------------------------------------------

	if MCD|MARSCD
		align $800
	elseif MARS
		align 4
	endif
MARS_RAMDATA:
	if MARS|MARSCD
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
		rompad $200000		; Pad the ISO file
	else
		align $8000		; Pad the Cartridge
	endif
