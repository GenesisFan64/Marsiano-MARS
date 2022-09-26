; ====================================================================
; ----------------------------------------------------------------
; Default gamemode
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

; TEST_MAINSPD	equ $04

; ====================================================================
; ------------------------------------------------------
; Structs
; ------------------------------------------------------

; 		struct 0
; strc_xpos	ds.w 1
; strc_ypos	ds.w 1
; 		finish

; ====================================================================
; ------------------------------------------------------
; This screen's RAM
; ------------------------------------------------------

		struct RAM_ModeBuff
; RAM_MapX	ds.l 1
; RAM_MapY	ds.l 1
; RAM_ThisSpeed	ds.l 1
; RAM_EmiFrame	ds.w 1
; RAM_EmiAnim	ds.w 1
; RAM_EmiTimer	ds.w 1
		finish

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

MD_3DMODE:
; 		bra	MD_DebugMenu

		move.w	#$2700,sr
		bclr	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update
		bsr	Mode_Init
		bsr	Video_PrintInit

; 	3D TEST
		move.l	#Art_Test3D,d0			; Genesis VDP graphics
		move.w	#$20,d1
		move.w	#Art_Test3D_e-Art_Test3D,d2
		bsr	Video_LoadArt
		lea	(Map_Test3D),a0			; 16-color palette
		move.l	#locate(1,0,0),d0		; Genesis VDP graphics
		move.l	#mapsize(320,224),d1
		moveq	#1,d2
		bsr	Video_LoadMap
		lea	(Pal_Test3D),a0			; 16-color palette
		moveq	#0,d0
		move.w	#16,d1
		bsr	Video_FadePal
		lea	(RAM_MdDreq+Dreq_Objects),a0
		move.l	#MarsObj_test|TH,mdl_data(a0)
		move.w	#-$1000,mdl_z_pos(a0)
		lea	(MDLDATA_PAL_TEST),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#1,d2
		bsr	Video_FadePal_Mars
		clr.w	(RAM_PaletteFd).w		; <-- quick patch
		clr.w	(RAM_MdMarsPalFd).w
		and.w	#$7FFF,(RAM_MdMarsPalFd).w

; 	; Testing track
; 		moveq	#0,d0
; 		bsr	Sound_TrkStop
; 		move.w	#200+32,d1
; 		bsr	Sound_GlbBeats
; 		lea	(GemaTrkData_MOVEME),a0
; ; 		lea	(GemaTrkData_Nadie_MD),a0
; 		moveq	#0,d0
; 		move.w	#7,d1
; 		moveq	#0,d2
; 		move.w	#0,d3
; 		bsr	Sound_TrkPlay

	; Set Fade-in settings
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#2,(RAM_FadeMarsIncr).w
		move.w	#1,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w
		move.b	#%000,(RAM_VdpRegs+$B).l
		move.b	#$10,(RAM_VdpRegs+7).l
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update

		bsr 	System_WaitFrame	; Send first DREQ
		moveq	#3,d0			; and set this psd-graphics mode
		bsr	Video_Mars_GfxMode

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	MdMap_Update
		bsr	System_WaitFrame
		bsr	Video_RunFade
		bne.s	.loop

		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyZ,d7
		beq.s	.not_mode

		bsr	.fade_out
		bra	MD_2DMODE_FROM

.not_mode:

		lea	str_Stats(pc),a0
		move.l	#locate(0,2,2),d0
		bsr	Video_Print
		lea	(RAM_MdDreq+Dreq_Objects),a0
		add.w	#8*2,mdl_x_rot(a0)
; 		add.w	#8*2,mdl_y_rot(a0)
; 		add.w	#8*5,mdl_z_rot(a0)
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyUp,d7
		beq.s	.z_up2
		sub.w	#$10,mdl_z_pos(a0)
.z_up2:
		btst	#bitJoyDown,d7
		beq.s	.z_dw2
		add.w	#$10,mdl_z_pos(a0)
.z_dw2:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq	.loop
		bra	MD_DebugMenu

; ====================================================================
; ----------------------------------------------
; common subs
; ----------------------------------------------

.fade_in:
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#1,(RAM_FadeMarsIncr).w
		move.w	#4,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		bra.s	.loop2

.fade_out:
		move.w	#2,(RAM_FadeMdReq).w
		move.w	#2,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#1,(RAM_FadeMarsIncr).w
		move.w	#4,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
.loop2:
		bsr	System_WaitFrame
		bsr	Video_RunFade
		bne.s	.loop2
		rts

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; VBlank
; ------------------------------------------------------

; ------------------------------------------------------
; HBlank
; ------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; DATA
;
; Small stuff goes here
; ------------------------------------------------------

; Pal_Emily:
; 		dc.w 0
; 		binclude "data/md/sprites/emi_pal.bin",2
; 		align 2
; Map_Nicole:
; 		include "data/md/sprites/emi_map.asm"
; 		align 2
; Dplc_Nicole:
; 		include "data/md/sprites/emi_plc.asm"
; 		align 2

