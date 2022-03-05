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
MAX_TSTENTRY	equ	4

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
RAM_EmiPosX	ds.l 1
RAM_EmiPosY	ds.l 1
RAM_Ypos	ds.l 1
RAM_XposFg	ds.l 1
RAM_XposBg	ds.l 1
RAM_CurrGfx	ds.w 1
RAM_EmiChar	ds.w 1
RAM_EmiAnim	ds.w 1
RAM_EmiHide	ds.w 1
RAM_CurrMode	ds.w 1
RAM_CurrSelc	ds.w 1
RAM_CurrIndx	ds.w 1
RAM_CurrTrack	ds.w 1
RAM_CurrTicks	ds.w 1
RAM_CurrTempo	ds.w 1
RAM_WindowCurr	ds.w 1
RAM_WindowNew	ds.w 1

RAM_WaveTmr	ds.w 1
RAM_WaveTmr2	ds.w 1
; RAM_BgCamera	ds.w 1
		finish

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

thisCode_Top:
		move.w	#$2700,sr
		bsr	Sound_init
		bsr	Video_init
		bsr	System_Init

		bsr	Mode_Init
		bsr	Video_PrintInit
		move.w	#$9200,d0
		move.w	d0,(RAM_WindowCurr).w
		move.w	d0,(RAM_WindowNew).w

; 		lea	test_polygon(pc),a0
; 		lea	(RAM_MdMarsPlgn),a1
; 		move.w	#($38/4)-1,d0
; .copy_polygn:
; 		move.l	(a0)+,(a1)+
; 		dbf	d0,.copy_polygn
; 		move.l	#1,(RAM_MdMarsPlgnNum).w

		move.l	#ART_FGTEST,d0
		move.w	#1*$20,d1
		move.w	#ART_FGTEST_e-ART_FGTEST,d2
		bsr	Video_LoadArt
		lea	(MAP_FGTEST),a0
		move.l	#locate(1,0,0),d0
		move.l	#mapsize(320,224),d1
		move.w	#1,d2
		bsr	Video_LoadMap

; 		lea	str_Title(pc),a0		; GEMA tester text on WINDOW
; 		move.l	#locate(0,2,2),d0
; 		bsr	Video_Print
		lea	str_Gema(pc),a0			; GEMA tester text on WINDOW
		move.l	#locate(2,2,2),d0
		bsr	Video_Print

	; Load palettes for fade-in
		lea	PAL_TESTBOARD(pc),a0
		moveq	#0,d0
		move.w	#$10,d1
		bsr	Video_FadePal
		lea	(MDLDATA_PAL_TEST),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#1,d2
		bsr	Video_FadePal_Mars
		clr.w	(RAM_MdMarsPalFd).w

		move.w	#3,(RAM_CurrGfx).w
		moveq	#3,d0
		bsr	Video_MarsSetGfx
		move.w	#1,(RAM_FadeMdSpd).w		; Fade-in speed(s)
		move.w	#1,(RAM_FadeMdReq).w		; FadeIn request on both sides
		move.w	#4,(RAM_FadeMarsSpd).w
		move.w	#1,(RAM_FadeMarsReq).w
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l	; Enable Genesis display
		move.b	#%111,(RAM_VdpRegs+$B).l	; Horizontall linescroll
		bsr	Video_Update
		move.w	#320/2,(RAM_EmiPosX).w
		move.w	#224/2,(RAM_EmiPosY).w
		lea	MasterTrkList(pc),a0
		move.w	$C(a0),d1
		move.w	$E(a0),d3
		moveq	#0,d0
		moveq	#0,d2
		bsr	Sound_TrkPlay

; 		lea	(RAM_MdDreq+Dreq_Models),a0
; 		move.l	#MarsObj_test,mdl_data(a0)
; 		move.l	#-$C0000,mdl_z_pos(a0)

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	System_VBlank
		move.w	(RAM_WindowCurr).w,d2		; Window up/down
		move.w	(RAM_WindowNew).w,d1		; animation
		cmp.w	d2,d1
		beq.s	.same_w
		move.w	#1,d0
		sub.w	d2,d1
		bpl.s	.revers
		move.w	#-1,d0
.revers:
		add.w	d0,(RAM_WindowCurr).w
		move.w	(RAM_WindowCurr).w,(vdp_ctrl).l
.same_w:
		add.l	#1,(RAM_Framecount).l
		lea	str_InfoMouse(pc),a0
		move.l	#locate(0,1,1),d0
		bsr	Video_Print
		move.w	(RAM_CurrMode).w,d0
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
		bra.w	.mode1
		bra.w	.mode0

; --------------------------------------------------
; Mode 0
; --------------------------------------------------

.mode0:
		tst.w	(RAM_CurrMode).w
		bmi	.mode0_loop
		or.w	#$8000,(RAM_CurrMode).w

.mode0_loop:
		bsr	Video_PalFade
		bsr	Video_MarsPalFade
		move.w	(RAM_FadeMarsReq),d7
		move.w	(RAM_FadeMdReq),d6
		or.w	d6,d7
; 		bne	.loop
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq.s	.no_mode0
		move.w	#1,(RAM_CurrMode).w
		move.w	#$920D,(RAM_WindowNew).w
.no_mode0:

		move.w	(Controller_1+on_press),d7
		lsr.w	#8,d7
		btst	#bitJoyZ,d7
		beq.s	.noah
; 		move.w	#$20,(RAM_ShakeMe).w
		moveq	#0,d2
		bsr	PlayThisSfx
.noah:

		move.l	(RAM_MdDreq+Dreq_BgXpos).w,d0
		move.l	(RAM_MdDreq+Dreq_BgYpos).w,d1
		move.l	#$10000,d5
		move.l	#1,d6
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyRight,d7
		beq.s	.nor_m
		add.l	d5,d0
		sub.w	d6,d2
.nor_m:
		btst	#bitJoyLeft,d7
		beq.s	.nol_m
		sub.l	d5,d0
		add.w	d6,d2
.nol_m:
		btst	#bitJoyDown,d7
		beq.s	.nod_m
		add.l	d5,d1
		add.w	d6,d3
.nod_m:
		btst	#bitJoyUp,d7
		beq.s	.nou_m
		sub.l	d5,d1
		sub.w	d6,d3
.nou_m:
		move.l	d0,(RAM_MdDreq+Dreq_BgXpos).w
		move.l	d1,(RAM_MdDreq+Dreq_BgYpos).w

		move.l	#0,d0
		move.l	#0,d1
		moveq	#0,d2
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyB,d7
		beq.s	.nor_m2
		add.w	#1,(RAM_CurrGfx).w
		move.w	(RAM_CurrGfx).w,d0
		bsr	Video_MarsSetGfx
		moveq	#1,d2
.nor_m2:
		btst	#bitJoyA,d7
		beq.s	.nol_m2
		sub.w	#1,(RAM_CurrGfx).w
		move.w	(RAM_CurrGfx).w,d0
		bsr	Video_MarsSetGfx
		moveq	#1,d2
.nol_m2:
		tst.w	d2
		beq.s	.no_chng
		lea	(MDLDATA_PAL_TEST),a0
; 		moveq	#0,d2
		cmp.w	#3,(RAM_CurrGfx).w
		beq.s	.thispal
		lea	(TESTMARS_BG_PAL),a0

.thispal:
		moveq	#0,d0
		move.w	#256,d1
		moveq	#1,d2
		bsr	Video_LoadPal_Mars
		clr.w	(RAM_MdDreq+Dreq_Palette).w
.no_chng:
; 		bsr	.wave_backgrnd
; 		rts

.wave_backgrnd:
	; wave background
		lea	(RAM_HorScroll),a0
		moveq	#112-1,d7
		move.w	(RAM_WaveTmr),d0
		move.w	#8,d1
.next:
		bsr	System_SineWave
		lsr.l	#8,d2
		move.w	d2,2(a0)
		adda	#4,a0
		add.w	#1,d0
		bsr	System_SineWave
		lsr.l	#8,d2
		move.w	d2,2(a0)
		adda	#4,a0
		add.w	#1,d0
		dbf	d7,.next
		add.w	#1,(RAM_WaveTmr).w

		lea	(RAM_VerScroll),a0
		moveq	#(320/16)-1,d7
		move.w	(RAM_WaveTmr),d0
		move.w	#6,d1
.next2:
		bsr	System_SineWave_Cos
		lsr.l	#8,d2
		move.w	d2,2(a0)
		adda	#4,a0
		add.w	#4,d0
		dbf	d7,.next2
		add.w	#1,(RAM_WaveTmr2).w
		rts

;
; 		move.w	(Controller_1+on_hold),d7
; 		lsr.w	#8,d7
; 		btst	#bitJoyX,d7
; 		beq.s	.nox
; 		move.w	#4,(RAM_FadeMarsSpd).w
; 		move.w	#2,(RAM_FadeMarsReq).w
; .nox:
; 		btst	#bitJoyY,d7
; 		beq.s	.noy
; 		move.w	#4,(RAM_FadeMarsSpd).w
; 		move.w	#1,(RAM_FadeMarsReq).w
; .noy:
;
; 		move.w	(Controller_1+on_hold),d7
; 		btst	#bitJoyA,d7
; 		beq.s	.noa
; 		move.w	#1,(RAM_FadeMdSpd).w
; 		move.w	#2,(RAM_FadeMdReq).w
; .noa:
; 		btst	#bitJoyB,d7
; 		beq.s	.nob
; 		move.w	#1,(RAM_FadeMdSpd).w
; 		move.w	#1,(RAM_FadeMdReq).w
; .nob:
;
;
; 	; Test movement
; 		move.l	(RAM_MdMarsBg).w,d0
; 		move.l	(RAM_MdMarsBg+4).w,d1
; 		move.w	(RAM_HorScroll+2).w,d2
; 		move.w	(RAM_VerScroll+2).w,d3
; 		move.l	#$20000,d5
; 		move.l	#1,d6
; 		move.w	(Controller_1+on_hold),d7
; 		btst	#bitJoyRight,d7
; 		beq.s	.nor_m
; 		add.l	d5,d0
; 		sub.w	d6,d2
; .nor_m:
; 		btst	#bitJoyLeft,d7
; 		beq.s	.nol_m
; 		sub.l	d5,d0
; 		add.w	d6,d2
; .nol_m:
; 		btst	#bitJoyDown,d7
; 		beq.s	.nod_m
; 		add.l	d5,d1
; 		add.w	d6,d3
; .nod_m:
; 		btst	#bitJoyUp,d7
; 		beq.s	.nou_m
; 		sub.l	d5,d1
; 		sub.w	d6,d3
; .nou_m:
;
; 		move.l	d0,(RAM_MdMarsBg).w
; 		move.l	d1,(RAM_MdMarsBg+4).w
; 		move.w	d2,(RAM_HorScroll+2).w
; 		move.w	d3,(RAM_VerScroll+2).w
;
; ; 	BOOM TEST
; 		move.w	(Controller_1+on_press),d7
; 		lsr.w	#8,d7
; 		btst	#bitJoyZ,d7
; 		beq.s	.noah
; ; 		move.w	#$20,(RAM_ShakeMe).w
; 		moveq	#0,d2
; 		bsr	PlayThisSfx
; .noah:
;
; 		bsr	Emilie_Move
; 		bsr	Emilie_MkSprite

; 		lea	str_TempVal(pc),a0		; Main title
; 		move.l	#locate(0,0,0),d0
; 		bsr	Video_Print




; 		bset	#0,(RAM_BoardUpd).w

; 	; Emilie player input
; 		move.b	(RAM_EmiFlags).w,d7

; 		btst	#7,(RAM_EmiFlags).w
; 		bne	.lockcontrl
; 		btst	#7,d7
; 		beq.s	.after
; 		lea	(RAM_BoardBlocks),a6
; 		move.w	(RAM_EmiBlockX).w,d7
; 		or.w	(RAM_EmiBlockY).w,d7
; 		bmi.s	.after
; 		move.w	(RAM_EmiBlockX).w,d0
; 		cmp.w	#6,d0
; 		bge.s	.after
; 		move.w	(RAM_EmiBlockY).w,d1
; 		cmp.w	#6,d1
; 		bge.s	.after
; 		mulu.w	#6,d1
; 		add.w	d1,d0
; 		adda	d0,a6
; 		bchg	#0,(a6)
; 		bset	#0,(RAM_BoardUpd).w
; 		moveq	#1,d2
; 		bsr	PlayThisSfx
; 		bsr	Board_CheckMatch
; .after:
;
; 	; UDLR
; 		move.w	#0,d4
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyDown,d7
; 		beq.s	.noz_down
; 		add.w	#$18,(RAM_EmiMoveY).w
; 		add.w	#1,(RAM_EmiBlockY).w
; 		move.w	d4,(RAM_EmiChar).w
; 		move.l	#-$20000,(RAM_EmiJumpSpd).l
; .noz_down:
; 		move.w	#4,d4
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyUp,d7
; 		beq.s	.noz_up
; 		add.w	#-$18,(RAM_EmiMoveY).w
; 		sub.w	#1,(RAM_EmiBlockY).w
; 		move.w	d4,(RAM_EmiChar).w
; 		move.l	#-$20000,(RAM_EmiJumpSpd).l
; .noz_up:
; 		move.w	#8,d4
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyRight,d7
; 		beq.s	.noz_r
; 		add.w	#$20,(RAM_EmiMoveX).w
; 		add.w	#1,(RAM_EmiBlockX).w
; 		move.w	d4,(RAM_EmiChar).w
; 		move.l	#-$20000,(RAM_EmiJumpSpd).l
; .noz_r:
; 		move.w	#$C,d4
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyLeft,d7
; 		beq.s	.noz_l
; 		add.w	#-$20,(RAM_EmiMoveX).w
; 		sub.w	#1,(RAM_EmiBlockX).w
; 		move.w	d4,(RAM_EmiChar).w
; 		move.l	#-$20000,(RAM_EmiJumpSpd).l
; .noz_l:
; 		rts
;
; .lockcontrl:
; 		add.w	#6,(RAM_EmiJumpTan).w
; 		rts

; --------------------------------------------------
; Mode 1
; --------------------------------------------------

.mode1:
		tst.w	(RAM_CurrMode).w
		bmi	.mode1_loop
		or.w	#$8000,(RAM_CurrMode).w
		bsr	.print_cursor
; 		move.w	#1,(RAM_EmiHide).w
; 		move.w	#1,(RAM_EmiUpd).w

.mode1_loop:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq.s	.no_mode1
		move.w	#0,(RAM_CurrMode).w
		move.w	#$9200,(RAM_WindowNew).w
.no_mode1:
		move.w	(Controller_1+on_press),d7
		lsr.w	#8,d7
		btst	#bitJoyZ,d7
		beq.s	.noc_up
.wait:		move.b	(sysmars_reg+comm15),d7
		and.w	#%11110000,d7
		bne.s	.wait
		move.b	(sysmars_reg+comm15),d7
		or.w	#1,d7
		move.b	d7,(sysmars_reg+comm15)
.noc_up:
		move.w	(Controller_1+on_press),d7
		lsr.w	#8,d7
		btst	#bitJoyY,d7
		beq.s	.noy2
		cmp.w	#1,(RAM_CurrIndx).w
		beq.	.noy2
		add.w	#1,(RAM_CurrIndx).w
		bsr	.print_cursor
.noy2:
		move.w	(Controller_1+on_hold),d7
		lsr.w	#8,d7
		btst	#bitJoyX,d7
		beq.s	.nox2
		tst.w	(RAM_CurrIndx).w
		beq.s	.nox2
		sub.w	#1,(RAM_CurrIndx).w
		bsr	.print_cursor
.nox2:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyUp,d7
		beq.s	.nou2
		tst.w	(RAM_CurrSelc).w
		beq.s	.nou2
		sub.w	#1,(RAM_CurrSelc).w
		bsr	.print_cursor
.nou2:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyDown,d7
		beq.s	.nod2
		cmp.w	#MAX_TSTENTRY,(RAM_CurrSelc).w
		bge.s	.nod2
		add.w	#1,(RAM_CurrSelc).w
		bsr	.print_cursor
.nod2:

	; LEFT/RIGHT
		lea	(RAM_CurrTrack),a1
		cmp.w	#3,(RAM_CurrSelc).w
		bne.s	.toptrk
		add	#2,a1
.toptrk:
		cmp.w	#5,(RAM_CurrSelc).w
		bne.s	.toptrk2
		add	#2*2,a1
.toptrk2:

		move.w	(Controller_1+on_hold),d7
		and.w	#JoyB,d7
		beq.s	.noba
		add.w	#1,(a1)
		bsr	.print_cursor
.noba:
		move.w	(Controller_1+on_hold),d7
		and.w	#JoyA,d7
		beq.s	.noaa
		sub.w	#1,(a1)
		bsr	.print_cursor
.noaa:



		move.w	(Controller_1+on_press),d7
		btst	#bitJoyLeft,d7
		beq.s	.nol
; 		tst.w	(a1)
; 		beq.s	.nol
		sub.w	#1,(a1)
		bsr	.print_cursor
.nol:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyRight,d7
		beq.s	.nor
; 		cmp.w	#MAX_TSTTRKS,(a1)
; 		bge.s	.nor
		add.w	#1,(a1)
		bsr	.print_cursor
.nor:

		move.w	(Controller_1+on_press),d7
		and.w	#JoyC,d7
		beq.s	.noc_c
		move.w	(RAM_CurrIndx).w,d0
		bsr	.procs_task
.noc_c:

		bsr	.wave_backgrnd
; 		lea	str_COMM(pc),a0
; 		move.l	#locate(0,2,9),d0
; 		bsr	Video_Print
		rts

; --------------------------------------------------

.print_cursor:
		lea	str_Status(pc),a0
		move.l	#locate(2,20,4),d0
		bsr	Video_Print
		lea	str_Cursor(pc),a0
		moveq	#0,d0
		move.w	(RAM_CurrSelc).w,d0
		add.l	#locate(2,2,5),d0
		bsr	Video_Print
		rts

; d1 - Track slot
.procs_task:
		move.w	(RAM_CurrSelc).w,d7
		add.w	d7,d7
		move.w	.tasklist(pc,d7.w),d7
		jmp	.tasklist(pc,d7.w)
.tasklist:
		dc.w .task_00-.tasklist
		dc.w .task_01-.tasklist
		dc.w .task_02-.tasklist
		dc.w .task_03-.tasklist
		dc.w .task_04-.tasklist
; 		dc.w .task_05-.tasklist

; d0 - Track slot
.task_00:
		lea	MasterTrkList(pc),a0
		move.w	(RAM_CurrTrack).w,d7
		lsl.w	#4,d7
		lea	(a0,d7.w),a0
		move.w	$C(a0),d1
		moveq	#0,d2
		move.w	$E(a0),d3
		bra	Sound_TrkPlay
.task_01:
		bra	Sound_TrkStop
.task_02:
		bra	Sound_TrkResume
.task_03:
		move.w	(RAM_CurrTicks).w,d1
		bra	Sound_TrkTicks
.task_04:
		move.w	(RAM_CurrTempo).w,d1
		bra	Sound_GlbTempo

; test playlist
MasterTrkList:
	dc.l GemaPat_Test,GemaBlk_Test,GemaIns_Test
	dc.w 14,%001
	dc.l GemaPat_Test2,GemaBlk_Test2,GemaIns_Test2
	dc.w 3,%001
	dc.l GemaPat_Test3,GemaBlk_Test3,GemaIns_Test3
	dc.w 3,%001

	align 2

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

; d2 - BLOCK
PlayThisSfx:
		lea	(GemaTrkData_Sfx),a0
		moveq	#1,d0
		moveq	#6,d1
; 		moveq	#0,d2
		moveq	#0,d3
		bra	Sound_TrkPlay


Emilie_Move:
		add.w	#1,(RAM_EmiAnim).w
		lea	(Controller_2),a0
		move.b	(a0),d0
		cmp.b	#$03,d0
		bne.s	.not_mouse

		move.w	#320,d2
		move.w	(RAM_EmiPosX).w,d1
		move.w	mouse_x(a0),d0
		muls.w	#$0E,d0
		asr.w	#4,d0
		add.w	d0,d1
		or.w	d1,d1
		bpl.s	.left_x
		clr.w	d1
.left_x:
		cmp.w	d2,d1
		blt.s	.right_x
		move.w	d2,d1
.right_x:
		move.w	d1,(RAM_EmiPosX).w

		move.w	#224,d2
		move.w	(RAM_EmiPosY).w,d1
		move.w	mouse_Y(a0),d0
		muls.w	#$0E,d0
		asr.w	#4,d0
		add.w	d0,d1
		or.w	d1,d1
		bpl.s	.left_y
		clr.w	d1
.left_y:
		cmp.w	d2,d1
		blt.s	.right_y
		move.w	d2,d1
.right_y:
		move.w	d1,(RAM_EmiPosY).w

.not_mouse:
		rts

; Emilie_MkSprite:
; 		lea	(RAM_Sprites),a6
; 		move.l	(RAM_EmiPosY),d0
; 		move.l	(RAM_EmiPosX),d1
; 		swap	d0
; 		swap	d1
; 		add.w	#$80+32,d0
; 		add.w	#$80+32,d1
; 		move.w	(RAM_EmiAnim),d2
; 		lsr.w	#3,d2
; 		and.w	#7,d2
; 		add.w	d2,d2
; 		lea	Map_Nicole(pc),a0
; 		move.w	(a0,d2.w),d2
; 		adda	d2,a0
; 		move.b	(a0)+,d4
; 		and.w	#$FF,d4
; 		sub.w	#1,d4
; 		move.w	#$0001,d5
; 		move.w	#$0500,d6
; .nxt_pz:
; 		move.b	(a0)+,d3
; 		ext.w	d3
; 		add.w	d0,d3
; 		move.w	d3,(a6)+
;
; 		move.b	(a0)+,d3
; 		lsl.w	#8,d3
; 		add.w	d5,d3
; 		move.w	d3,(a6)+
;
; 		move.b	(a0)+,d3
; 		lsl.w	#8,d3
; 		move.b	(a0)+,d2
; 		and.w	#$FF,d2
; 		add.w	d3,d2
; 		add.w	d6,d2
; 		move.w	d2,(a6)+
;
; 		move.b	(a0)+,d3
; 		ext.w	d3
; 		add.w	d1,d3
; 		move.w	d3,(a6)+
; 		add.w	#1,d5
; 		dbf	d4,.nxt_pz
; 		clr.l	(a6)+
; 		clr.l	(a6)+
;
; 	; DPLC
; 		move.w	(RAM_EmiAnim),d2
; 		lsr.w	#3,d2
; 		and.w	#7,d2
; 		add.w	d2,d2
; 		lea	Dplc_Nicole(pc),a0
; 		move.w	(a0,d2.w),d2
; 		adda	d2,a0
; 		move.w	(a0)+,d4
; 		and.w	#$FF,d4
; 		sub.w	#1,d4
; 		move.w	#$500,d5
;
;
; 	; d0 - graphics
; 	; d5 - VRAM OUTPUT
; 		lsl.w	#5,d5
; .nxt_dpz:
; 		move.l	#ART_EMI,d0
; 		move.w	(a0)+,d1
; 		move.w	d1,d2
; 		and.w	#$7FF,d1
; 		lsl.w	#5,d1
; 		add.l	d1,d0
; 		move.w	d5,d1
; 		lsr.w	#7,d2
; 		add.w	#$20,d2
; 		move.w	d2,d3
; 		bsr	Video_DmaSet
; 		add.w	d3,d5
; 		dbf	d4,.nxt_dpz
; .no_upd:
; 		rts
; ;
; .hidefuji:
; 		lea	(RAM_Sprites),a6
; 		move.l	#0,(a6)+
; 		move.l	#0,(a6)+
; 		move.l	#0,(a6)+
; 		move.l	#0,(a6)+
; 		rts
;
; ; VBLANK only
; Emilie_Show:
; 		lea	(vdp_data),a6
; 		move.l	#$78000003,4(a6)
; 		lea	(RAM_Sprites),a5
; 		move.w	#8-1,d7
; .sprdata:
; 		move.l	(a5)+,(a6)
; 		move.l	(a5)+,(a6)
; 		move.l	(a5)+,(a6)
; 		move.l	(a5)+,(a6)
; 		dbf	d7,.sprdata
; 		rts

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

str_Title:
		dc.b "Project MARSIANO 202X",0
		align 2

str_Cursor:	dc.b " ",$A
		dc.b ">",$A
		dc.b " ",0

str_Status:
		dc.b "\\w",$A,$A
		dc.b "\\w",$A,$A,$A
		dc.b "\\w",$A
		dc.b "\\w",0
		dc.l RAM_CurrIndx
		dc.l RAM_CurrTrack
		dc.l RAM_CurrTicks
		dc.l RAM_CurrTempo
		align 2
str_Gema:
		dc.b "GEMA SOUND DRIVER TESTER",$A
		dc.b $A
		dc.b "Track index -----",$A,$A
		dc.b "  Sound_TrkPlay",$A
		dc.b "  Sound_TrkStop",$A
		dc.b "  Sound_TrkResume",$A
		dc.b "  Sound_TrkTicks",$A
		dc.b "  Sound_GlbTempo",0
		align 2
; str_COMM:
; 		dc.b "\\w \\w \\w \\w",$A
; 		dc.b "\\w \\w \\w \\w",0
; 		dc.l sysmars_reg+comm0
; 		dc.l sysmars_reg+comm2
; 		dc.l sysmars_reg+comm4
; 		dc.l sysmars_reg+comm6
; 		dc.l sysmars_reg+comm8
; 		dc.l sysmars_reg+comm10
; 		dc.l sysmars_reg+comm12
; 		dc.l sysmars_reg+comm14
; 		align 2

str_InfoMouse:
		dc.b "comm12: \\w MD Frames: \\l",0
		dc.l sysmars_reg+comm12
		dc.l RAM_Framecount
		align 2

PAL_EMI:
		dc.w 0
		binclude "data/md/sprites/emi_pal.bin",2
		align 2

PAL_TESTBOARD:
		binclude "data/md/bg/fg_pal.bin"
		align 2
PAL_BG:
		binclude "data/md/bg/bg_pal.bin"
		align 2

Map_Nicole:
		include "data/md/sprites/emi_map.asm"
		align 2
Dplc_Nicole:
		include "data/md/sprites/emi_plc.asm"
		align 2


; ====================================================================
; Report size
	if MOMPASS=6
.end:
		message "This 68K RAM-CODE uses: \{.end-thisCode_Top}"
	endif
