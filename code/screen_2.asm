; ====================================================================
; ----------------------------------------------------------------
; 3D Part
; ----------------------------------------------------------------

		phase RAMCODE_USER

; ====================================================================
; ------------------------------------------------------
; Settings
; ------------------------------------------------------

MAPPZ_SIZE	equ $1000
SET_MAPSPD	equ $20

; ====================================================================
; ------------------------------------------------------
; Structs
; ------------------------------------------------------

		struct 0
field_data	ds.l 1
; field_x		ds.w 1
; field_z		ds.w 1
sizeof_mdfield	ds.l 0
		finish

; ====================================================================
; ------------------------------------------------------
; This screen's RAM
; ------------------------------------------------------

		struct RAM_ModeBuff
RAM_FieldBuff	ds.b sizeof_mdfield
RAM_HorCopy	ds.w 1
RAM_CamData	ds.l 1
RAM_CamFrame	ds.l 1
RAM_CamTimer	ds.l 1
RAM_CamSpeed	ds.l 1
RAM_Cam_Xpos	ds.l 1
RAM_Cam_Ypos	ds.l 1
RAM_Cam_Zpos	ds.l 1
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
		move.l	#locate(1,0,0),d0
		move.l	#mapsize(512,224),d1
		moveq	#1,d2
		bsr	Video_LoadMap
		lea	(Pal_Test3D),a0			; 16-color palette
		moveq	#0,d0
		move.w	#16,d1
		bsr	Video_FadePal
		lea	(PalMars_MarsCity),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#1,d2
		bsr	Video_FadePal_Mars
		clr.w	(RAM_PaletteFd).w		; <-- quick patch
		clr.w	(RAM_MdMarsPalFd).w
		and.w	#$7FFF,(RAM_MdMarsPalFd).w

	; Read MAP
		move.l	#MapCamera_0,d0			; Animation
		moveq	#1,d1
; 		bsr	MdMdl_SetNewCamera
		bsr	MdlMap_Init

	; Testing track
		moveq	#0,d0
		bsr	Sound_TrkStop
		move.w	#200+32,d1		; 160+
		bsr	Sound_GlbBeats
		lea	(GemaTrk_BodyOver),a0
		moveq	#0,d0
		move.w	#6,d1
		moveq	#0,d2
		move.w	#%0001,d3		;
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
		moveq	#3,d0			; and set this psd-graphics mode
		bsr	Video_Mars_GfxMode

		bsr	System_WaitFrame	; Send first DREQ
; 		moveq	#2-1,d7
; .pre_w:
; 		bset	#5,(sysmars_reg+comm12+1).l
; .pre_wl:
; 		btst	#5,(sysmars_reg+comm12+1).l
; 		bne.s	.pre_wl
; 		dbf	d7,.pre_w

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
		lea	(RAM_MdDreq+Dreq_ObjCam),a6
		lea	(RAM_FieldBuff),a5
		move.l	#MarsMap_00,field_data(a5)
		bsr	MdlMap_Build
		bsr	MdMdl_CamAnimate
		bpl.s	MdlMap_Loop
		clr.l	(RAM_Cam_Xpos).l
		clr.l	(RAM_Cam_Ypos).l
		clr.l	(RAM_Cam_Zpos).l
		clr.l	cam_x_rot(a6)
		clr.l	cam_y_rot(a6)
		clr.l	cam_z_rot(a6)
		move.l	#-$80,(RAM_Cam_Ypos).l

MdlMap_Loop:
; 		lea	(RAM_MdDreq+Dreq_Objects),a6
; 		add.w	#8*4,mdl_x_rot(a6)

		lea	(RAM_MdDreq+Dreq_ObjCam),a6
		lea	(RAM_FieldBuff),a5
		move.w	(Controller_1+on_hold),d7
		move.l	#SET_MAPSPD,d6
		move.l	d6,d5
		lsr.l	#2,d5
		move.w	(RAM_HorCopy).l,d4
		btst	#bitJoyUp,d7
		beq.s	.z_up2
		add.l	d6,(RAM_Cam_Zpos).l;cam_z_pos(a6)
.z_up2:
		btst	#bitJoyDown,d7
		beq.s	.z_dw2
		sub.l	d6,(RAM_Cam_Zpos).l;cam_z_pos(a6)
.z_dw2:
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyLeft,d7
		beq.s	.z_up3
		sub.l	d6,(RAM_Cam_Xpos).l;cam_X_pos(a6)
.z_up3:
		btst	#bitJoyRight,d7
		beq.s	.z_dw3
		add.l	d6,(RAM_Cam_Xpos).l;cam_X_pos(a6)
.z_dw3:
		btst	#bitJoyA,d7
		beq.s	.z_rl
		sub.l	d6,cam_x_rot(a6)
		add.w	d5,d4
.z_rl:
		btst	#bitJoyB,d7
		beq.s	.z_rr
		add.l	d6,cam_x_rot(a6)
		sub.w	d5,d4
.z_rr:
		btst	#bitJoyX,d7
		beq.s	.z2_rl
		add.l	d6,cam_y_rot(a6)
.z2_rl:
		btst	#bitJoyY,d7
		beq.s	.z2_rr
		sub.l	d6,cam_y_rot(a6)
.z2_rr:

		btst	#bitJoyZ,d7
		beq.s	.z_rld
		sub.l	d6,(RAM_Cam_Ypos).l
.z_rld:
		btst	#bitJoyC,d7
		beq.s	.z_rrd
		add.l	d6,(RAM_Cam_Ypos).l
.z_rrd:
		move.w	d4,(RAM_HorCopy).l
		btst	#5,(sysmars_reg+comm12+1).l
		bne.s	.busy
		move.w	(RAM_HorCopy).l,(RAM_HorScroll+2).l
		bset	#5,(sysmars_reg+comm12+1).l
.busy:
		bsr	MdMdl_CamAnimate

; 		move.l	cam_z_pos(a6),d7
; 		and.w	#-MAPPZ_SIZE,d7
; 		beq.s	.z_upd
; 		moveq	#1,d0
; 		tst.w	d7
; 		bmi.s	.z_up
; 		neg.w	d0
; .z_up:
; 		add.w	d0,field_z(a5)
; .z_upd:
; 		move.l	cam_x_pos(a6),d7
; ; 		add.w	#MAPPZ_SIZE/2,d7
; 		and.w	#-MAPPZ_SIZE,d7
; 		beq.s	.x_upd
; 		moveq	#1,d0
; 		tst.w	d7
; 		bpl.s	.x_up
; 		neg.w	d0
; .x_up:
; 		add.w	d0,field_x(a5)
;
;
; .x_upd:

		move.l	(RAM_Cam_Xpos).w,d0
		move.l	(RAM_Cam_Zpos).w,d1
		and.l	#MAPPZ_SIZE-1,d0
		and.l	#MAPPZ_SIZE-1,d1
		move.l	d0,cam_x_pos(a6)
		move.l	d1,cam_z_pos(a6)
		move.l	(RAM_Cam_Ypos).w,d0
		move.l	d0,cam_y_pos(a6)

; 		rts

; a6 - camera
; a5 - field buffer
MdlMap_Build:
;  rts
		lea	(RAM_MdDreq+Dreq_Objects),a4
		move.l	field_data(a5),a3
		move.l	(a3)+,a1

		move.l	(RAM_Cam_Zpos),d1
		move.l	(RAM_Cam_Xpos),d0
		lsr.l	#8,d0	; *** MANUAL SETTING
		lsr.l	#8,d1
		lsr.l	#4,d0
		lsr.l	#4,d1
		neg.w	d1
		add.w	#$0D-1,d0
		add.w	#$0D,d1
		lsl.w	#6,d1
		add.w	d0,d0
		adda	d1,a3
		adda	d0,a3

		move.l	cam_x_rot(a6),d0	; $0000/$1000
		lsr.w	#8,d0
		and.w	#%11110,d0
		move.w	.list(pc,d0.w),d0
		jmp	.list(pc,d0.w)
.list:
		dc.w .front-.list	; $000
		dc.w .front-.list	;
		dc.w .front-.list	;
		dc.w .bottom-.list	;
		dc.w .bottom-.list	; $800
		dc.w .bottom-.list	;
		dc.w .bottom-.list	;
		dc.w .bottom-.list	;
		dc.w .bottom-.list	; $1000
		dc.w .bottom-.list	;
		dc.w .bottom-.list	;
		dc.w .bottom-.list	;
		dc.w .bottom-.list	; $1800
		dc.w .front-.list	;
		dc.w .front-.list	;
		dc.w .front-.list	;


; - l x r -
; - L X R -
; - L X R -
; - - - - -
; - - - - -
.front:
		adda	#2,a3
		move.w	#-MAPPZ_SIZE*2,d2

		move.w	#-MAPPZ_SIZE,d3	; Start base X
		move.l	(RAM_Cam_Xpos),d5
		move.l	(RAM_Cam_Zpos),d4
		and.l	#MAPPZ_SIZE/2,d4
		bne.s	.midz
		adda	#$40,a3
		add.w	#MAPPZ_SIZE,d2
.midz:
		and.l	#MAPPZ_SIZE/2,d5
		beq.s	.midx
		adda	#2,a3
		add.w	#MAPPZ_SIZE,d3
.midx:

		bsr	.do_clmn
		adda	#$40,a3
		add.w	#MAPPZ_SIZE,d2
		bra	.do_clmn

; - - - - -
; - - - - -
; - L X R -
; - L X R -
; - l x r -
.bottom:
		adda	#($40)+2,a3
		move.w	#-MAPPZ_SIZE,d2

		move.w	#-MAPPZ_SIZE,d3		; Start base X
		move.l	(RAM_Cam_Xpos),d5
		move.l	(RAM_Cam_Zpos),d4
		and.l	#MAPPZ_SIZE/2,d4
		bne.s	.midz_b
		adda	#$40,a3
		add.w	#MAPPZ_SIZE,d2
.midz_b:
		and.l	#MAPPZ_SIZE/2,d5
		beq.s	.midx_b
		adda	#2,a3
		add.w	#MAPPZ_SIZE,d3
.midx_b:
		bsr	.do_clmn
		adda	#$40,a3
		add.w	#MAPPZ_SIZE,d2

; ****
.do_clmn:
		move.l	a3,a2
		move.w	d3,d1
		bsr	.mk_pz		; LEFT
		add.w	#MAPPZ_SIZE,d1
		adda	#2,a2
		bsr	.mk_pz		; MID
		add.w	#MAPPZ_SIZE,d1
		adda	#2,a2
; 		bsr.s	.mk_pz		; RIGHT
; .lpze:
; 		rts

; d1 - X pos
; d2 - Z pos
; (a2) - Piece id
.mk_pz:
		move.w	(a2),d0
		lsl.w	#2,d0
		move.l	(a1,d0.w),mdl_data(a4)
		move.w	d1,mdl_x_pos(a4)
		move.w	d2,mdl_z_pos(a4)
		adda	#sizeof_mdlobj,a4
		rts

; 		move.w	#-MAPPZ_SIZE,d1
; 		move.l	a3,a2
; ; 		adda	#2,a2
; 		bsr	.mk_pz
; 		adda	#2,a2
; 		add.w	#MAPPZ_SIZE,d1
; 		bsr	.mk_pz
; 		adda	#2,a2
; 		add.w	#MAPPZ_SIZE,d1
; 		bsr	.mk_pz
;
; 		adda	#$40,a3
; 		add.w	#MAPPZ_SIZE,d2
; 		dbf	d3,.next_m
; 		rts

; ; - - -
; ; - X X
; ; - X X
; .front_d:
; 		move.w	#0,d2
; 		adda	#$40,a3
; 		moveq	#2-1,d3
; .next_dm:
; 		move.w	#0,d1
; 		move.l	a3,a2
; 		adda	#2,a2
; 		bsr	.mk_pz
; 		adda	#2,a2
; 		add.w	#MAPPZ_SIZE,d1
; 		bsr	.mk_pz
; 		adda	#$40,a3
;
; 		add.w	#MAPPZ_SIZE,d2
; 		dbf	d3,.next_dm
; 		rts

; 		move.l	a2,a3
; 		adda	#$40+$02,a3
; 		moveq	#0,d1
; 		move.w	#-(MAPPZ_SIZE),d2
; 		bsr	.mk_pz
; 		adda	#2,a3
; 		add.w	#MAPPZ_SIZE,d1
; 		bsr	.mk_pz
; 		move.l	a2,a3
; 		adda	#$40+$02,a3
; 		moveq	#0,d1
; 		move.w	#-(MAPPZ_SIZE),d2
; 		bsr	.mk_pz
; 		adda	#2,a3
; 		add.w	#MAPPZ_SIZE,d1
; 		bsr	.mk_pz

; ------------------------------------------------------
; Camera
; ------------------------------------------------------

MdMdl_SetNewCamera:
; 		clr.l	(RAM_Cam_Xpos).l
; 		clr.l	(RAM_Cam_Ypos).l
; 		clr.l	(RAM_Cam_Zpos).l
; 		clr.l	(RAM_Cam_Xrot).l
; 		clr.l	(RAM_Cam_Yrot).l
; 		clr.l	(RAM_Cam_Zrot).l
		moveq	#0,d4
		move.l	d4,(RAM_CamFrame).l
		move.l	d4,(RAM_CamTimer).l
		move.l	d1,(RAM_CamSpeed).l
		move.l	d0,(RAM_CamData).l
		rts

MdMdl_CamAnimate:
		lea	(RAM_MdDreq+Dreq_ObjCam),a6
		move.l	(RAM_CamData).l,d0			; If 0 == No animation
		beq.s	.no_camanim
		sub.l	#1,(RAM_CamTimer).l
		bpl.s	.no_camanim
		move.l	(RAM_CamSpeed).l,(RAM_CamTimer).l	; TEMPORAL timer
		move.l	d0,a1
		move.l	(a1)+,d1
		move.l	(RAM_CamFrame).l,d0
		add.l	#1,d0
		cmp.l	d1,d0
		bne.s	.on_frames
		moveq	#-1,d0
		rts
.on_frames:
		move.l	d0,(RAM_CamFrame).l
		mulu.w	#$18,d0
		adda	d0,a1
		move.l	(a1)+,(RAM_Cam_Xpos).l
		move.l	(a1)+,(RAM_Cam_Ypos).l
		move.l	(a1)+,(RAM_Cam_Zpos).l
		move.l	(a1)+,cam_x_rot(a6)
		move.l	(a1)+,cam_y_rot(a6)
		move.l	(a1)+,cam_z_rot(a6)

	; Quick BG move
		move.l	cam_x_rot(a6),d1
		move.l	cam_z_rot(a6),d0
		add.l	d0,d0
		add.l	d0,d1
		lsr.l	#2,d1
		neg.w	d1
		move.w	d1,(RAM_HorCopy).l
.no_camanim:
		moveq	#0,d0
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

; str_Stats2:
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
; 		align 2

str_Stats2:
		dc.b "\\l",$A
		dc.b "\\l",$A
		dc.b "\\l \\w",0
		dc.l RAM_MdDreq+Dreq_ObjCam+cam_x_rot
		dc.l RAM_Cam_Ypos
		dc.l RAM_Cam_Zpos
		dc.l sysmars_reg+comm0
		align 2

		align 4
MarsMap_00:
		include "data/maps/3D/mcity/map_data.asm"
		dc.l 0
		dc.l 0
		dc.l 0
		dc.l 0
		align 2

MapCamera_0:
		binclude "data/maps/3D/mcity/anim/mcity_anim.bin"
		align 4

; ====================================================================

.here:
	if MOMPASS=6
		message "THIS RAM-CODE ends at: \{.here}"
	endif
		dephase
