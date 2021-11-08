; ====================================================================
; ----------------------------------------------------------------
; Default gamemode
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

var_MoveSpd	equ	$4000
MAX_TSTTRKS	equ	3
MAX_TSTENTRY	equ	1

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
; RAM_MarsPal	ds.w 256
; RAM_MarsFade	ds.w 256
; RAM_Cam_Xpos	ds.l 1
; RAM_Cam_Ypos	ds.l 1
; RAM_Cam_Zpos	ds.l 1
; RAM_Cam_Xrot	ds.l 1
; RAM_Cam_Yrot	ds.l 1
; RAM_Cam_Zrot	ds.l 1
; RAM_CamData	ds.l 1
; RAM_CamFrame	ds.l 1
; RAM_CamTimer	ds.l 1
; RAM_CamSpeed	ds.l 1
RAM_MdlCurrMd	ds.w 1
RAM_BgCamera	ds.w 1
RAM_BgCamCurr	ds.w 1
; RAM_Layout_X	ds.w 1
; RAM_Layout_Y	ds.w 1
RAM_CurrTrack	ds.w 2
RAM_CurrSelc	ds.w 1
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
		add.l	#1,(RAM_Framecount).l
.inside:	move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		bne.s	.inside

		move.l	#$7C000003,(vdp_ctrl).l
		move.w	(RAM_BgCamCurr).l,d0
		neg.w	d0
		asr.w	#2,d0
		move.w	d0,(vdp_data).l
		asr.w	#1,d0
		move.w	d0,(vdp_data).l
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

		lea	str_Title(pc),a0
		move.l	#locate(0,2,2),d0
		bsr	Video_Print

; 		move.l	#PCM_START,d0
; 		move.l	#PCM_END-PCM_START,d1
; 		moveq	#0,d2
; 		move.w	#$100,d3
; 		moveq	#1,d4
; 		bsr	SoundReq_SetSample
		move.w	#$8080,(sysmars_reg+comm14)
		bsr	.print_cursor

; Mode 0 mainloop
.mode0_loop:
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyA,d7
; 		beq.s	.noc_up
; 		move.w	#1,d0
; 		move.w	d0,(sysmars_reg+comm0)
; .noc_up:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyA,d7
		beq.s	.noc_d
		move.l	#PCM_START,d0
		move.l	#PCM_END-PCM_START,d1
		moveq	#0,d2
		move.w	#$100,d3
		moveq	#1,d4
		bsr	SoundReq_SetSample
.noc_d:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyC,d7
		beq.s	.noc_c

		move.w	(RAM_CurrSelc).w,d0
		lea	(RAM_CurrTrack).w,a0
		add.w	d0,d0
		move.w	(a0,d0.w),d0
		lsl.w	#4,d0
		lea	.playlist(pc),a0
		lea	(a0,d0.w),a0
		move.l	(a0)+,d0
		move.l	(a0)+,d1
		move.l	(a0)+,d2
		move.l	(a0)+,d3
		move.w	(RAM_CurrSelc).w,d4
		bsr	SoundReq_SetTrack
.noc_c:

		move.w	(Controller_1+on_press),d7
		btst	#bitJoyUp,d7
		beq.s	.nou
		tst.w	(RAM_CurrSelc).w
		beq.s	.nou
		sub.w	#1,(RAM_CurrSelc).w
		bsr	.print_cursor
.nou:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyDown,d7
		beq.s	.nod
		cmp.w	#MAX_TSTENTRY,(RAM_CurrSelc).w
		bge.s	.nod
		add.w	#1,(RAM_CurrSelc).w
		bsr	.print_cursor
.nod:
		move.w	(RAM_CurrSelc),d0
		add.w	d0,d0
		lea	(RAM_CurrTrack),a1
		adda	d0,a1
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyLeft,d7
		beq.s	.nol
		tst.w	(a1)
		beq.s	.nol
		sub.w	#1,(a1)
		bsr	.print_cursor
.nol:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyRight,d7
		beq.s	.nor
		cmp.w	#MAX_TSTTRKS,(a1)
		bge.s	.nor
		add.w	#1,(a1)
		bsr	.print_cursor
.nor:
		lea	str_COMM(pc),a0
		move.l	#locate(0,2,7),d0
		bsr	Video_Print
		rts

; test playlist
.playlist:
	dc.l GemaTrk_patt_TEST,GemaTrk_blk_TEST,GemaTrk_ins_TEST
	dc.l 4
	dc.l GemaTrk_patt_TEST2,GemaTrk_blk_TEST2,GemaTrk_ins_TEST2
	dc.l 3
	dc.l GemaTrk_patt_chrono,GemaTrk_blk_chrono,GemaTrk_ins_chrono
	dc.l 3
	dc.l GemaTrk_mecano_patt,GemaTrk_mecano_blk,GemaTrk_mecano_ins
	dc.l 1
; 	dc.l GemaTrk_mars_patt,GemaTrk_mars_blk,GemaTrk_mars_ins
; 	dc.l 3
; 	dc.l GemaTrk_jackrab_patt,GemaTrk_jackrab_blk,GemaTrk_jackrab_ins
; 	dc.l 5
; 	dc.l GemaTrk_gigalo_patt,GemaTrk_gigalo_blk,GemaTrk_gigalo_ins
; 	dc.l 3
; 	dc.l GemaTrk_brinstr_patt,GemaTrk_brinstr_blk,GemaTrk_brinstr_ins
; 	dc.l 3
	align 2

.print_cursor:
		lea	str_Status(pc),a0
		move.l	#locate(0,13,4),d0
		bsr	Video_Print
		lea	str_Cursor(pc),a0
		moveq	#0,d0
		move.w	(RAM_CurrSelc).w,d0
		add.l	#locate(0,2,3),d0
		bsr	Video_Print
		rts

; 		move.w	(Controller_1+on_hold),d7
; 		move.w	d7,(sysmars_reg+comm12)
; 		move.w	(Controller_1+on_press),d7
; 		move.w	d7,(sysmars_reg+comm10)

; 		moveq	#0,d0
; 		move.w	(Controller_1+on_hold),d7
; 		move.w	d7,d6
; 		and.w	#JoyY,d6
; 		beq.s	.no_x
; 		move.w	#-1,d0
; .no_x:
; 		move.w	d7,d6
; 		and.w	#JoyZ,d6
; 		beq.s	.no_y
; 		move.w	#1,d0
; .no_y:
; 		move.w	(sysmars_reg+comm0).l,d4
; 		add	d0,d4
; 		move.w	d4,(sysmars_reg+comm0).l

; 		moveq	#0,d0
; 		moveq	#0,d1
; 		move.w	(Controller_2+on_hold),d7
; 		btst	#bitJoyUp,d7
; 		beq.s	.no_up
; 		move.l	#-1,d1
; .no_up:
; 		btst	#bitJoyDown,d7
; 		beq.s	.no_dw
; 		move.l	#1,d1
; .no_dw:
; 		btst	#bitJoyLeft,d7
; 		beq.s	.no_lf
; 		move.l	#-1,d0
; .no_lf:
; 		btst	#bitJoyRight,d7
; 		beq.s	.no_rf
; 		move.l	#1,d0
; .no_rf:
; 		move.w	(sysmars_reg+comm4).l,d4
; 		add	d0,d4
; 		move.w	d4,(sysmars_reg+comm4).l
; 		move.w	(sysmars_reg+comm6).l,d4
; 		add	d1,d4
; 		move.w	d4,(sysmars_reg+comm6).l
;
; 		moveq	#0,d0
; 		moveq	#0,d1
;
; 		move.w	(Controller_1+on_press),d7
; 		move.w	d7,d6
; 		and.w	#JoyY,d6
; 		beq.s	.no_x
; 		move.w	#-1,d0
; .no_x:
; 		move.w	d7,d6
; 		and.w	#JoyZ,d6
; 		beq.s	.no_y
; 		move.w	#1,d0
; .no_y:
;
; 		move.w	(Controller_1+on_hold),d7
; 		btst	#bitJoyUp,d7
; 		beq.s	.no2_up
; 		move.l	#-4,d1
; .no2_up:
; 		btst	#bitJoyDown,d7
; 		beq.s	.no2_dw
; 		move.l	#4,d1
; .no2_dw:
; 		btst	#bitJoyLeft,d7
; 		beq.s	.no2_lf
; 		move.l	#-4,d0
; .no2_lf:
; 		btst	#bitJoyRight,d7
; 		beq.s	.no2_rf
; 		move.l	#4,d0
; .no2_rf:
; 		move.w	(sysmars_reg+comm0).l,d4
; 		add	d0,d4
; 		move.w	d4,(sysmars_reg+comm0).l
; 		move.w	(sysmars_reg+comm2).l,d4
; 		add	d1,d4
; 		move.w	d4,(sysmars_reg+comm2).l

; 		move.w	(Controller_2+on_hold),d7
; 		btst	#bitJoyUp,d7
; 		beq.s	.no2_up
; 		sub.w	#1,(sysmars_reg+comm6).l
; .no2_up:
; 		btst	#bitJoyDown,d7
; 		beq.s	.no2_dw
; 		add.w	#1,(sysmars_reg+comm6).l
; .no2_dw:
; 		btst	#bitJoyLeft,d7
; 		beq.s	.no2_lf
; 		sub.w	#1,(sysmars_reg+comm4).l
; .no2_lf:
; 		btst	#bitJoyRight,d7
; 		beq.s	.no2_rf
; 		add.w	#1,(sysmars_reg+comm4).l
; .no2_rf:


; 		move.l	#CmdTaskMd_UpdModels,d0
; 		bsr	System_MdMars_SlvTask
; .busy_mstr:

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

; MdMdl_SetNewCamera:
; 		clr.l	(RAM_Cam_Xpos).l
; 		clr.l	(RAM_Cam_Ypos).l
; 		clr.l	(RAM_Cam_Zpos).l
; 		clr.l	(RAM_Cam_Xrot).l
; 		clr.l	(RAM_Cam_Yrot).l
; 		clr.l	(RAM_Cam_Zrot).l
; 		moveq	#0,d4
; 		move.l	d4,(RAM_CamFrame).l
; 		move.l	d4,(RAM_CamTimer).l
; 		move.l	d1,(RAM_CamSpeed).l
; 		move.l	d0,(RAM_CamData).l
; 		rts

; d7 - Move to this mode after
;      animation ends.
; MdMdl_RunAnimation:
; 		bsr	MdMdl_CamAnimate
; 		bpl.s	.stay
; 		move.w	d7,(RAM_MdlCurrMd).w
; 		rts					; exit mode
; .stay:
; 		moveq	#0,d1
; 		move.l	(RAM_Cam_Xpos),d2
; 		move.l	(RAM_Cam_Ypos),d3
; 		move.l	(RAM_Cam_Zpos),d4
; 		move.l	(RAM_Cam_Xrot),d5
; 		move.l	(RAM_Cam_Yrot),d6
; 		move.l	(RAM_Cam_Zrot),d7
; ; 		move.l	#CmdTaskMd_CameraPos,d0		; Load map
; ; 		bsr	System_MdMars_SlvAddTask
; ; 		move.l	#CmdTaskMd_UpdModels,d0
; ; 		bsr	System_MdMars_SlvAddTask
; 		bsr	System_MdMars_SlvSendDrop
; .nel2:
; 		bne.s	.busy
; 		move.l	(RAM_Cam_Xrot),d1
; 		neg.l	d1
; 		lsr.l	#8,d1
; 		move.w	d1,(RAM_BgCamCurr).l
; .busy:
; 		rts

; MdMdl_CamAnimate:
; 		move.l	(RAM_CamData).l,d0			; If 0 == No animation
; 		beq.s	.no_camanim
; 		sub.l	#1,(RAM_CamTimer).l
; 		bpl.s	.no_camanim
; 		move.l	(RAM_CamSpeed).l,(RAM_CamTimer).l	; TEMPORAL timer
; 		move.l	d0,a1
; 		move.l	(a1)+,d1
; 		move.l	(RAM_CamFrame).l,d0
; 		add.l	#1,d0
; 		cmp.l	d1,d0
; 		bne.s	.on_frames
; 		moveq	#-1,d0
; 		rts
; .on_frames:
; 		move.l	d0,(RAM_CamFrame).l
; 		mulu.w	#$18,d0
; 		adda	d0,a1
; 		move.l	(a1)+,(RAM_Cam_Xpos).l
; 		move.l	(a1)+,(RAM_Cam_Ypos).l
; 		move.l	(a1)+,(RAM_Cam_Zpos).l
; 		move.l	(a1)+,(RAM_Cam_Xrot).l
; 		move.l	(a1)+,(RAM_Cam_Yrot).l
; 		move.l	(a1)+,(RAM_Cam_Zrot).l
; 		lsr.l	#7,d1
; 		move.w	d1,(RAM_BgCamera).l
; .no_camanim:
; 		moveq	#0,d0
; 		rts
;
; MdMdl1_Usercontrol:
; 		move.l	#var_MoveSpd,d5
; 		move.l	#-var_MoveSpd,d6
; 		move.w	(Controller_1+on_hold),d7
; 		btst	#bitJoyUp,d7
; 		beq.s	.no_up
; ; 		lea	(RAM_MdCamera),a0
; 		move.l	(RAM_Cam_Zpos).l,d0
; 		add.l	d5,d0
; 		move.l	d0,(RAM_Cam_Zpos).l
; .no_up:
; 		btst	#bitJoyDown,d7
; 		beq.s	.no_dw
; ; 		lea	(RAM_MdCamera),a0
; 		move.l	(RAM_Cam_Zpos).l,d0
; 		add.l	d6,d0
; 		move.l	d0,(RAM_Cam_Zpos).l
; .no_dw:
; 		btst	#bitJoyLeft,d7
; 		beq.s	.no_lf
; ; 		lea	(RAM_MdCamera),a0
; 		move.l	(RAM_Cam_Xpos).l,d0
; 		add.l	d6,d0
; 		move.l	d0,(RAM_Cam_Xpos).l
; .no_lf:
; 		btst	#bitJoyRight,d7
; 		beq.s	.no_rg
; ; 		lea	(RAM_MdCamera),a0
; 		move.l	(RAM_Cam_Xpos).l,d0
; 		add.l	d5,d0
; 		move.l	d0,(RAM_Cam_Xpos).l
; .no_rg:
;
; 		btst	#bitJoyB,d7
; 		beq.s	.no_a
; ; 		lea	(RAM_MdCamera),a0
; 		move.l	(RAM_Cam_Xrot).l,d0
; 		move.l	d6,d1
; 		add.l	d1,d0
; 		move.l	d0,(RAM_Cam_Xrot).l
; 		lsr.l	#7,d0
; 		neg.l	d0
; 		move.w	d0,(RAM_BgCamera).l
; .no_a:
; 		btst	#bitJoyC,d7
; 		beq.s	.no_b
; ; 		lea	(RAM_MdCamera),a0
; 		move.l	(RAM_Cam_Xrot).l,d0
; 		move.l	d5,d1
; 		add.l	d1,d0
; 		move.l	d0,(RAM_Cam_Xrot).l
; 		lsr.l	#7,d0
; 		neg.l	d0
; 		move.w	d0,(RAM_BgCamera).l
; .no_b:
; 	; Reset all
; ; 		btst	#bitJoyC,d7
; ; 		beq.s	.no_c
; ; 		;move.w	#1,(RAM_MdMdlsUpd).l
; ; 		lea	(RAM_MdCamera),a0
; ; 		moveq	#0,d0
; ; 		move.l	d0,(RAM_Cam_Xpos).l
; ; 		move.l	d0,(RAM_Cam_Ypos).l
; ; 		move.l	d0,(RAM_Cam_Zpos).l
; ; 		move.l	d0,(RAM_Cam_Xrot).l
; ; 		move.l	d0,(RAM_Cam_Yrot).l
; ; 		move.l	d0,(RAM_Cam_Zrot).l
; ; .no_c:
;
;
; 	; Up/Down
; 		move.w	(Controller_1+on_hold),d7
; 		move.w	d7,d4
; 		and.w	#JoyZ,d4
; 		beq.s	.no_x
; 		;move.w	#1,(RAM_MdMdlsUpd).l
; ; 		lea	(RAM_MdCamera),a0
; 		move.l	(RAM_Cam_Ypos).l,d0
; 		add.l	d5,d0
; 		move.l	d0,(RAM_Cam_Ypos).l
; .no_x:
; 		move.w	d7,d4
; 		and.w	#JoyY,d4
; 		beq.s	.no_y
; 		;move.w	#1,(RAM_MdMdlsUpd).l
; ; 		lea	(RAM_MdCamera),a0
; 		move.l	(RAM_Cam_Ypos).l,d0
; 		add.l	d6,d0
; 		move.l	d0,(RAM_Cam_Ypos).l
; .no_y:
;
; 		moveq	#0,d1
; 		move.l	(RAM_Cam_Xpos),d2
; 		move.l	(RAM_Cam_Ypos),d3
; 		move.l	(RAM_Cam_Zpos),d4
; 		move.l	(RAM_Cam_Xrot),d5
; 		move.l	(RAM_Cam_Yrot),d6
; 		move.l	(RAM_Cam_Zrot),d7
; 		move.l	#CmdTaskMd_CameraPos,d0		; Load map
; 		bsr	System_MdMars_SlvAddTask
; 		move.l	#CmdTaskMd_UpdModels,d0
; 		bsr	System_MdMars_SlvAddTask
; 		bsr	System_MdMars_SlvSendDrop
; .nel2:
; 		bne.s	.busy
; 		move.l	(RAM_Cam_Xrot),d1
; 		neg.l	d1
; 		lsr.l	#8,d1
; 		move.w	d1,(RAM_BgCamCurr).l
; .busy:
; 		rts

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

MD_FifoMars:
		lea	(RAM_FrameCount),a6
		move.w	#$100,d6

		lea	(sysmars_reg),a5
		move.w	sr,d7			; Backup current SR
		move.w	#$2700,sr		; Disable interrupts
		move.w	#$00E,d5
.retry:
		move.l	#$C0000000,(vdp_ctrl).l	; DEBUG ENTER
		move.w	d5,(vdp_data).l
		move.b	#%000,($A15107).l	; 68S bit
		move.w	d6,($A15110).l		; DREQ len
		move.b	#%100,($A15107).l	; 68S bit
		lea	($A15112).l,a4
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		move.w	standby(a5),d0		; Request SLAVE CMD interrupt
		bset	#1,d0
		move.w	d0,standby(a5)
.wait_cmd:	move.w	standby(a5),d0		; interrupt is ready?
		btst    #1,d0
		bne.s   .wait_cmd
; .wait_dma:	move.b	comm15(a5),d0		; Another flag to check
; 		btst	#6,d0
; 		beq.s	.wait_dma
; 		move.b	#1,d0
; 		move.b	d0,comm15(a5)

; 	; blast
; 	rept $200/128
; 		bsr.s	.blast
; 	endm
; 		move.l	#$C0000000,(vdp_ctrl).l	; DEBUG EXIT
; 		move.w	#$000,(vdp_data).l
; 		move.w	d7,sr			; Restore SR
; 		rts
; .blast:
; 	rept 128
; 		move.w	(a6)+,(a4)
; 	endm
; 		rts

; 	safer
.l0:		move.w	(a6)+,(a4)		; Data Transfer
		move.w	(a6)+,(a4)		;
		move.w	(a6)+,(a4)		;
		move.w	(a6)+,(a4)		;
.l1:		btst	#7,dreqctl+1(a5)	; FIFO Full ?
		bne.s	.l1
		subq	#4,d6
		bcc.s	.l0
		move.w	#$E00,d5
		btst	#2,dreqctl(a5)		; DMA All OK ?
		bne.s	.retry
		move.l	#$C0000000,(vdp_ctrl).l	; DEBUG EXIT
		move.w	#$000,(vdp_data).l
		move.w	d7,sr			; Restore SR
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

str_Cursor:	dc.b " ",$A
		dc.b ">",$A
		dc.b " ",0

str_Status:
		dc.b "\\w",$A
		dc.b "\\w",0
		dc.l RAM_CurrTrack
		dc.l RAM_CurrTrack+2
		align 2
str_Title:
		dc.b "Marsiano/GEMA sound driver",$A
		dc.b $A
		dc.b "  Track 0:      B-stop C-play",$A
		dc.b "  Track 1:",0
		align 2
str_COMM:
		dc.b "\\w \\w \\w \\w",$A
		dc.b "\\w \\w \\w \\w",0
		dc.l sysmars_reg+comm0
		dc.l sysmars_reg+comm2
		dc.l sysmars_reg+comm4
		dc.l sysmars_reg+comm6
		dc.l sysmars_reg+comm8
		dc.l sysmars_reg+comm10
		dc.l sysmars_reg+comm12
		dc.l sysmars_reg+comm14
		align 2

; ====================================================================

	if MOMPASS=6
.end:
		message "This 68K RAM-CODE uses: \{.end-thisCode_Top}"
	endif
