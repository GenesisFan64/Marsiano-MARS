; ====================================================================
; ----------------------------------------------------------------
; 3D Part
; ----------------------------------------------------------------

		phase RAMCODE_USER

; ====================================================================
; ------------------------------------------------------
; Settings
; ------------------------------------------------------

; TEST_MAINSPD	equ $04

; ====================================================================
; ------------------------------------------------------
; Structs
; ------------------------------------------------------

		struct 0
field_data	ds.l 1
field_x		ds.w 1
field_z		ds.w 1
sizeof_mdfield	ds.l 0
		finish

; ====================================================================
; ------------------------------------------------------
; This screen's RAM
; ------------------------------------------------------

		struct RAM_ModeBuff
RAM_FieldBuff	ds.b sizeof_mdfield
		finish

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

MD_3DMODE:
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
		lea	(MDLDATA_PAL_TEST),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#1,d2
		bsr	Video_FadePal_Mars
		clr.w	(RAM_PaletteFd).w		; <-- quick patch
		clr.w	(RAM_MdMarsPalFd).w
		and.w	#$7FFF,(RAM_MdMarsPalFd).w

	; Read MAP
		bsr	MdlMap_Init

; 	; Testing track
		moveq	#0,d0
		bsr	Sound_TrkStop
		move.w	#200+32,d1
		bsr	Sound_GlbBeats
		lea	(GemaTrkData_MOVEME),a0
; 		lea	(GemaTrkData_Nadie_MD),a0
		moveq	#0,d0
		move.w	#7,d1
		moveq	#0,d2
		move.w	#0,d3
		bsr	Sound_TrkPlay

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
		btst	#bitJoyMode,d7
		beq.s	.not_mode
		bsr	.fade_out
		move.w	#0,(RAM_Glbl_Scrn).w
		rts
.not_mode:

		lea	str_Stats2(pc),a0
		move.l	#locate(0,2,2),d0
		bsr	Video_Print
		bsr	MdlMap_Loop


		bra	.loop
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyStart,d7
; 		beq	.loop
; 		bra	MD_DebugMenu

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

MdlMap_Init:
		lea	(RAM_FieldBuff),a5
		move.l	#MarsMap_00,field_data(a5)
		clr.l	cam_x_pos(a6)
; 		clr.l	cam_y_pos(a6)
		clr.l	cam_z_pos(a6)
		clr.l	cam_x_rot(a6)
		clr.l	cam_y_rot(a6)
		clr.l	cam_z_rot(a6)
		move.w	#$0E,field_x(a5)
		move.w	#$10,field_z(a5)
		bsr	MdlMap_Build
		lea	(RAM_MdDreq+Dreq_ObjCam),a6
		move.l	#-$80,cam_y_pos(a6)

MdlMap_Loop:
		lea	(RAM_MdDreq+Dreq_ObjCam),a6
		lea	(RAM_FieldBuff),a5
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyUp,d7
		beq.s	.z_up2
		add.l	#$10,cam_z_pos(a6)
.z_up2:
		btst	#bitJoyDown,d7
		beq.s	.z_dw2
		sub.l	#$10,cam_z_pos(a6)
.z_dw2:
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyLeft,d7
		beq.s	.z_up3
		sub.l	#$10,cam_x_pos(a6)
.z_up3:
		btst	#bitJoyRight,d7
		beq.s	.z_dw3
		add.l	#$10,cam_x_pos(a6)
.z_dw3:
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyA,d7
		beq.s	.z_rl
		sub.l	#$10,cam_x_rot(a6)
.z_rl:
		btst	#bitJoyB,d7
		beq.s	.z_rr
		add.l	#$10,cam_x_rot(a6)
.z_rr:
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyX,d7
		beq.s	.z2_rl
		add.l	#$10,cam_y_rot(a6)
.z2_rl:
		btst	#bitJoyY,d7
		beq.s	.z2_rr
		sub.l	#$10,cam_y_rot(a6)
.z2_rr:

		move.l	cam_z_pos(a6),d7
		and.w	#-$400,d7
		beq.s	.z_upd
		moveq	#1,d0
		tst.w	d7
		bmi.s	.z_up
		neg.w	d0
.z_up:
		add.w	d0,field_z(a5)
		bsr.s	MdlMap_Build

.z_upd:
		move.l	cam_x_pos(a6),d7
		and.w	#-$400,d7
		beq.s	.x_upd
		moveq	#1,d0
		tst.w	d7
		bpl.s	.x_up
		neg.w	d0
.x_up:
		add.w	d0,field_x(a5)
		bsr.s	MdlMap_Build
.x_upd:
		and.l	#$3FF,cam_x_pos(a6)
		and.l	#$3FF,cam_z_pos(a6)
		rts

; a6 - camera
; a5 - field buffer
MdlMap_Build:
		lea	(RAM_MdDreq+Dreq_Objects),a4
		move.l	field_data(a5),a3
		move.l	(a3)+,a1
		move.w	field_z(a5),d1
		lsl.w	#6,d1
		move.w	field_x(a5),d0
		add.w	d0,d0
		adda	d1,a3
		adda	d0,a3

; 		moveq	#-$400,d1
; 		move.w	#-$800,d2
; 		bsr	.column
		move.w	#0,d1
		move.w	#-$800,d2
		bsr.s	.column
		adda	#2,a3
		move.w	#$400,d1
		move.w	#-$800,d2
; 		bra.s	.column

.column:
		move.l	a3,a2
		move.w	(a2),d0
		lsl.w	#2,d0
		move.l	(a1,d0.w),mdl_data(a4)
		move.w	d1,mdl_x_pos(a4)
		move.w	d2,mdl_z_pos(a4)
		adda	#sizeof_mdlobj,a4
		add.w	#$400,d2
		adda	#$40,a2

		move.w	(a2),d0
		lsl.w	#2,d0
		move.l	(a1,d0.w),mdl_data(a4)
		move.w	d1,mdl_x_pos(a4)
		move.w	d2,mdl_z_pos(a4)
		adda	#sizeof_mdlobj,a4
		add.w	#$400,d2
		adda	#$40,a2

		move.w	(a2),d0
		lsl.w	#2,d0
		move.l	(a1,d0.w),mdl_data(a4)
		move.w	d1,mdl_x_pos(a4)
		move.w	d2,mdl_z_pos(a4)
		adda	#sizeof_mdlobj,a4
		rts

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

str_Stats2:
		dc.b "\\l \\l \\l",$A,$A
		dc.b "\\w \\w \\w",0
		dc.l RAM_MdDreq+Dreq_ObjCam+cam_x_pos
		dc.l RAM_MdDreq+Dreq_ObjCam+cam_z_pos
		dc.l RAM_MdDreq+Dreq_ObjCam+cam_x_rot

		dc.l RAM_FieldBuff+field_x
		dc.l RAM_FieldBuff+field_z
		dc.l sysmars_reg+comm0
; 		dc.l RAM_Framecount

; 		dc.b "\\w \\w \\w \\w",$A
; 		dc.b "\\w \\w \\w \\w",$A,$A
; 		dc.b "\\l",0
; 		dc.l sysmars_reg+comm0
; 		dc.l sysmars_reg+comm2
; 		dc.l sysmars_reg+comm4
; 		dc.l sysmars_reg+comm6
; 		dc.l sysmars_reg+comm8
; 		dc.l sysmars_reg+comm10
; 		dc.l sysmars_reg+comm12
; 		dc.l sysmars_reg+comm14
; 		dc.l RAM_Framecount
		align 2

MarsMap_00:
		include "data/maps/mars/mcity/map_data.asm"
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		align 2

; ====================================================================

.here:
	if MOMPASS=6
		message "THIS RAM-CODE ends at: \{.here}"
	endif
		dephase
