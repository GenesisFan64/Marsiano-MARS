; ====================================================================
; ----------------------------------------------------------------
; Default gamemode
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

var_MoveSpd	equ	$4000

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
; This mode's RAM
; ------------------------------------------------------

		struct RAM_ModeBuff
RAM_MarsPal	ds.w 256
RAM_MarsFade	ds.w 256
RAM_Cam_Xpos	ds.l 1
RAM_Cam_Ypos	ds.l 1
RAM_Cam_Zpos	ds.l 1
RAM_Cam_Xrot	ds.l 1
RAM_Cam_Yrot	ds.l 1
RAM_Cam_Zrot	ds.l 1
RAM_CamData	ds.l 1
RAM_CamFrame	ds.l 1
RAM_CamTimer	ds.l 1
RAM_CamSpeed	ds.l 1
RAM_MdlCurrMd	ds.w 1
RAM_BgCamera	ds.w 1
RAM_BgCamCurr	ds.w 1
sizeof_mdglbl	ds.l 0
		finish

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

thisCode_Top:
		move.w	#$2700,sr
		bsr	Mode_Init
		bsr	Video_PrintInit
		move.w	#0,(RAM_MdlCurrMd).w
; 		move.l	#GemaTrk_Demo_patt,d0
; 		move.l	#GemaTrk_Demo_blk,d1
; 		move.l	#GemaTrk_Demo_ins,d2
; 		moveq	#4,d3
; 		moveq	#0,d4
; 		bsr	SoundReq_SetTrack

		bset	#bitDispEnbl,(RAM_VdpRegs+1).l		; Enable display
		bsr	Video_Update

; 		moveq	#0,d1
; 		move.l	#PWM_STEREO,d2
; 		move.l	#PWM_STEREO_e,d3
; 		move.l	d2,d4
; 		move.l	#$100,d5
; 		move.l	#0,d6
; 		moveq	#%11|%10000000,d7
; 		move.l	#CmdTaskMd_PWM_SetChnl,d0
; 		bsr	System_MdMars_MstTask

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		beq.s	.loop
		bsr	System_Input
.inside:	move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		bne.s	.inside
; 		rts

; 		bsr	System_VSync
		move.l	#$7C000003,(vdp_ctrl).l
		move.w	(RAM_BgCamCurr).l,d0
		move.w	d0,(sysmars_reg+comm0).l
		neg.w	d0
; 		lsr.w	#1,d0
		move.w	#0,(vdp_data).l
		move.w	d0,(vdp_data).l
; 		lea	str_Status(pc),a0
; 		move.l	#locate(0,0,0),d0
; 		bsr	Video_Print
		move.w	(RAM_MdlCurrMd).w,d0
		and.w	#%11111,d0
		add.w	d0,d0
		add.w	d0,d0
		jsr	.list(pc,d0.w)
		bra	.loop

; ====================================================================
; ------------------------------------------------------
; Mode sections
; ------------------------------------------------------

.list:
		bra.w	.mode0
		bra.w	.mode0
		bra.w	.mode0

; --------------------------------------------------
; Mode 0
; --------------------------------------------------

.mode0:
		tst.w	(RAM_MdlCurrMd).w
		bmi	.mode0_loop
		or.w	#$8000,(RAM_MdlCurrMd).w

		lea	MdPal_BgTest(pc),a0
		move.w	#0,d0
		move.w	#16-1,d1
		bsr	Video_LoadPal
		lea	(MdMap_BgTest),a0
		move.l	#locate(1,0,0),d0
		move.l	#mapsize(512,224),d1
		move.w	#1,d2
		bsr	Video_LoadMap
		move.l	#MdGfx_BgTest,d0
		move.w	#(MdGfx_BgTest_e-MdGfx_BgTest),d1
		move.w	#1,d2
		bsr	Video_LoadArt

; 		move.l	#CmdTaskMd_SetBitmap,d0		; 32X display OFF
; 		moveq	#0,d1
; 		bsr	System_MdMars_MstTask		; Wait until it finishes.
; 		bclr	#bitDispEnbl,(RAM_VdpRegs+1).l	; Disable MD display
; 		bsr	Video_Update
; 		move.l	#TESTMARS_BG_PAL,d1			; Load palette
; 		moveq	#0,d2
; 		move.l	#256,d3
; 		move.l	#$0000,d4
; 		move.l	#CmdTaskMd_LoadSPal,d0
; 		bsr	System_MdMars_MstTask
; 		move.l	#CmdTaskMd_SetBitmap,d0		; 32X display ON
; 		moveq	#1,d1
; 		bsr	System_MdMars_MstTask
; 		bset	#bitDispEnbl,(RAM_VdpRegs+1).l	; Enable MD display
; 		bsr	Video_Update

		move.w	#$0000,(sysmars_reg+comm0)
		move.w	#$0000,(sysmars_reg+comm2)
		move.w	#$0100,(sysmars_reg+comm4)
		move.w	#$0100,(sysmars_reg+comm6)
		move.w	#"GO",(sysmars_reg+comm14)

; Mode 0 mainloop
.mode0_loop:

		move.w	(Controller_1+on_press),d7
		move.w	d7,d6
		and.w	#JoyY,d6
		beq.s	.no_x
		sub.w	#1,(RAM_BgCamCurr).l
.no_x:
		move.w	d7,d6
		and.w	#JoyZ,d6
		beq.s	.no_y
		add.w	#1,(RAM_BgCamCurr).l
.no_y:


		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyUp,d7
		beq.s	.no_up
		sub.w	#2,(sysmars_reg+comm2).l
.no_up:
		btst	#bitJoyDown,d7
		beq.s	.no_dw
		add.w	#2,(sysmars_reg+comm2).l
.no_dw:
		btst	#bitJoyLeft,d7
		beq.s	.no_lf
		sub.w	#2,(RAM_BgCamCurr).l
.no_lf:
		btst	#bitJoyRight,d7
		beq.s	.no_rf
		add.w	#2,(RAM_BgCamCurr).l
.no_rf:

		move.w	(Controller_2+on_hold),d7
		btst	#bitJoyUp,d7
		beq.s	.no2_up
		sub.w	#2,(sysmars_reg+comm6).l
.no2_up:
		btst	#bitJoyDown,d7
		beq.s	.no2_dw
		add.w	#2,(sysmars_reg+comm6).l
.no2_dw:
		btst	#bitJoyLeft,d7
		beq.s	.no2_lf
		sub.w	#2,(sysmars_reg+comm4).l
.no2_lf:
		btst	#bitJoyRight,d7
		beq.s	.no2_rf
		add.w	#2,(sysmars_reg+comm4).l
.no2_rf:


; 		move.l	#CmdTaskMd_UpdModels,d0
; 		bsr	System_MdMars_SlvTask
		rts

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

MdMdl_SetNewCamera:
		clr.l	(RAM_Cam_Xpos).l
		clr.l	(RAM_Cam_Ypos).l
		clr.l	(RAM_Cam_Zpos).l
		clr.l	(RAM_Cam_Xrot).l
		clr.l	(RAM_Cam_Yrot).l
		clr.l	(RAM_Cam_Zrot).l
		moveq	#0,d4
		move.l	d4,(RAM_CamFrame).l
		move.l	d4,(RAM_CamTimer).l
		move.l	d1,(RAM_CamSpeed).l
		move.l	d0,(RAM_CamData).l
		rts

; d7 - Move to this mode after
;      animation ends.
MdMdl_RunAnimation:
		bsr	MdMdl_CamAnimate
		bpl.s	.stay
		move.w	d7,(RAM_MdlCurrMd).w
		rts					; exit mode
.stay:
		moveq	#0,d1
		move.l	(RAM_Cam_Xpos),d2
		move.l	(RAM_Cam_Ypos),d3
		move.l	(RAM_Cam_Zpos),d4
		move.l	(RAM_Cam_Xrot),d5
		move.l	(RAM_Cam_Yrot),d6
		move.l	(RAM_Cam_Zrot),d7
		move.l	#CmdTaskMd_CameraPos,d0		; Load map
		bsr	System_MdMars_SlvAddTask
		move.l	#CmdTaskMd_UpdModels,d0
		bsr	System_MdMars_SlvAddTask
		bsr	System_MdMars_SlvSendDrop
.nel2:
		bne.s	.busy
		move.l	(RAM_Cam_Xrot),d1
		neg.l	d1
		lsr.l	#8,d1
		move.w	d1,(RAM_BgCamCurr).l
.busy:
		rts

MdMdl_CamAnimate:
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
		move.l	(a1)+,(RAM_Cam_Xrot).l
		move.l	(a1)+,(RAM_Cam_Yrot).l
		move.l	(a1)+,(RAM_Cam_Zrot).l
		lsr.l	#7,d1
		move.w	d1,(RAM_BgCamera).l
.no_camanim:
		moveq	#0,d0
		rts

MdMdl1_Usercontrol:
		move.l	#var_MoveSpd,d5
		move.l	#-var_MoveSpd,d6
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyUp,d7
		beq.s	.no_up
; 		lea	(RAM_MdCamera),a0
		move.l	(RAM_Cam_Zpos).l,d0
		add.l	d5,d0
		move.l	d0,(RAM_Cam_Zpos).l
.no_up:
		btst	#bitJoyDown,d7
		beq.s	.no_dw
; 		lea	(RAM_MdCamera),a0
		move.l	(RAM_Cam_Zpos).l,d0
		add.l	d6,d0
		move.l	d0,(RAM_Cam_Zpos).l
.no_dw:
		btst	#bitJoyLeft,d7
		beq.s	.no_lf
; 		lea	(RAM_MdCamera),a0
		move.l	(RAM_Cam_Xpos).l,d0
		add.l	d6,d0
		move.l	d0,(RAM_Cam_Xpos).l
.no_lf:
		btst	#bitJoyRight,d7
		beq.s	.no_rg
; 		lea	(RAM_MdCamera),a0
		move.l	(RAM_Cam_Xpos).l,d0
		add.l	d5,d0
		move.l	d0,(RAM_Cam_Xpos).l
.no_rg:

		btst	#bitJoyB,d7
		beq.s	.no_a
; 		lea	(RAM_MdCamera),a0
		move.l	(RAM_Cam_Xrot).l,d0
		move.l	d6,d1
		add.l	d1,d0
		move.l	d0,(RAM_Cam_Xrot).l
		lsr.l	#7,d0
		neg.l	d0
		move.w	d0,(RAM_BgCamera).l
.no_a:
		btst	#bitJoyC,d7
		beq.s	.no_b
; 		lea	(RAM_MdCamera),a0
		move.l	(RAM_Cam_Xrot).l,d0
		move.l	d5,d1
		add.l	d1,d0
		move.l	d0,(RAM_Cam_Xrot).l
		lsr.l	#7,d0
		neg.l	d0
		move.w	d0,(RAM_BgCamera).l
.no_b:
	; Reset all
; 		btst	#bitJoyC,d7
; 		beq.s	.no_c
; 		;move.w	#1,(RAM_MdMdlsUpd).l
; 		lea	(RAM_MdCamera),a0
; 		moveq	#0,d0
; 		move.l	d0,(RAM_Cam_Xpos).l
; 		move.l	d0,(RAM_Cam_Ypos).l
; 		move.l	d0,(RAM_Cam_Zpos).l
; 		move.l	d0,(RAM_Cam_Xrot).l
; 		move.l	d0,(RAM_Cam_Yrot).l
; 		move.l	d0,(RAM_Cam_Zrot).l
; .no_c:


	; Up/Down
		move.w	(Controller_1+on_hold),d7
		move.w	d7,d4
		and.w	#JoyZ,d4
		beq.s	.no_x
		;move.w	#1,(RAM_MdMdlsUpd).l
; 		lea	(RAM_MdCamera),a0
		move.l	(RAM_Cam_Ypos).l,d0
		add.l	d5,d0
		move.l	d0,(RAM_Cam_Ypos).l
.no_x:
		move.w	d7,d4
		and.w	#JoyY,d4
		beq.s	.no_y
		;move.w	#1,(RAM_MdMdlsUpd).l
; 		lea	(RAM_MdCamera),a0
		move.l	(RAM_Cam_Ypos).l,d0
		add.l	d6,d0
		move.l	d0,(RAM_Cam_Ypos).l
.no_y:

		moveq	#0,d1
		move.l	(RAM_Cam_Xpos),d2
		move.l	(RAM_Cam_Ypos),d3
		move.l	(RAM_Cam_Zpos),d4
		move.l	(RAM_Cam_Xrot),d5
		move.l	(RAM_Cam_Yrot),d6
		move.l	(RAM_Cam_Zrot),d7
		move.l	#CmdTaskMd_CameraPos,d0		; Load map
		bsr	System_MdMars_SlvAddTask
		move.l	#CmdTaskMd_UpdModels,d0
		bsr	System_MdMars_SlvAddTask
		bsr	System_MdMars_SlvSendDrop
.nel2:
		bne.s	.busy
		move.l	(RAM_Cam_Xrot),d1
		neg.l	d1
		lsr.l	#8,d1
		move.w	d1,(RAM_BgCamCurr).l
.busy:
		rts

; 		lea	(RAM_MdCamera),a0
; 		move.l	#CmdTaskMd_CameraPos,d0		; Cmnd $0D: Set camera positions
; 		moveq	#0,d1
; 		move.l	(RAM_Cam_Xpos).l,d2
; 		move.l	(RAM_Cam_Ypos).l,d3
; 		move.l	(RAM_Cam_Zpos).l,d4
; 		move.l	(RAM_Cam_Xrot).l,d5
; 		move.l	(RAM_Cam_Yrot).l,d6
; 		move.l	(RAM_Cam_Zrot).l,d7
; 		bsr	System_MdMars_SlvAddTask

; 	; temporal camera
; 		moveq	#0,d6
; 		move.w	(Controller_1+on_hold).l,d7
; 		btst	#bitJoyUp,d7
; 		beq.s	.nou
; 		add.l	#var_MoveSpd,(RAM_Cam_Zpos).l
; 		moveq	#1,d6
; .nou:
; 		btst	#bitJoyDown,d7
; 		beq.s	.nod
; 		add.l	#-var_MoveSpd,(RAM_Cam_Zpos).l
; 		moveq	#1,d6
; .nod:
; 		btst	#bitJoyLeft,d7
; 		beq.s	.nol
; 		add.l	#-var_MoveSpd,(RAM_Cam_Xpos).l
; 		moveq	#1,d6
; .nol:
; 		btst	#bitJoyRight,d7
; 		beq.s	.nor
; 		add.l	#var_MoveSpd,(RAM_Cam_Xpos).l
; 		moveq	#1,d6
; .nor:
; 		btst	#bitJoyA,d7
; 		beq.s	.noa
; 		add.l	#-var_MoveSpd,(RAM_Cam_Xrot).l
; 		moveq	#1,d6
; .noa:
; 		btst	#bitJoyB,d7
; 		beq.s	.nob
; 		add.l	#var_MoveSpd,(RAM_Cam_Xrot).l
; 		moveq	#1,d6
; .nob:
; ; 		tst.w	d6
; ; 		beq.s	.nel
; .first_draw:

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

str_Status:
		dc.b "\\w \\w",0
		dc.l RAM_BgCamCurr
		dc.l sysmars_reg+comm0
		align 2
MdPal_BgTest:
		binclude "data/md/bg/bg_pal.bin"
		align 2

; ====================================================================

	if MOMPASS=6
.end:
		message "This 68K RAM-CODE uses: \{.end-thisCode_Top}"
	endif
