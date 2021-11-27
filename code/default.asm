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
MAX_TSTENTRY	equ	5

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
RAM_EmiMoveX	ds.l 1
RAM_EmiMoveY	ds.l 1
RAM_EmiJumpTan	ds.l 1
RAM_EmiFlags	ds.w 1
RAM_EmiBlockX	ds.w 1
RAM_EmiBlockY	ds.w 1
RAM_EmiChar	ds.w 1
RAM_EmiAnim	ds.w 1
RAM_EmiUpd	ds.w 1
RAM_EmiHide	ds.w 1
RAM_ShakeMe	ds.w 1
RAM_BoardUpd	ds.w 1
RAM_CurrType	ds.w 1
RAM_BgCamera	ds.w 1
RAM_Xpos	ds.w 1
RAM_CurrSelc	ds.w 1
RAM_CurrIndx	ds.w 1
RAM_CurrTrack	ds.w 1
RAM_CurrTicks	ds.w 1
RAM_CurrTempo	ds.w 1
RAM_WindowCurr	ds.w 1
RAM_WindowNew	ds.w 1
RAM_BoardBlocks	dc.b 6*6
sizeof_mdglbl	ds.l 0
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
		move.w	#0,(RAM_CurrType).w
		move.w	#208,(RAM_CurrTempo).w
		move.w	#$9200,d0
		move.w	d0,(RAM_WindowCurr).w
		move.w	d0,(RAM_WindowNew).w

	; Default Emilie vars
		move.w	#$20,d0
		move.w	d0,(RAM_EmiPosX).w
		move.w	d0,(RAM_EmiMoveX).w
		move.w	#$42,d0
		move.w	d0,(RAM_EmiPosY).w
		move.w	d0,(RAM_EmiMoveY).w
		move.w	#-1,(RAM_EmiBlockX).w
		move.w	#2,(RAM_EmiBlockY).w
		move.w	#1,(RAM_EmiUpd).w

		move.l	#ART_TESTBOARD,d0
		move.w	#ART_TESTBOARD_e-ART_TESTBOARD,d1
		move.w	#1,d2
		bsr	Video_LoadArt
		lea	MAP_TESTBOARD(pc),a0
		move.l	#locate(0,0,0),d0
		move.l	#mapsize(320,224),d1
		move.w	#1|$2000,d2
		bsr	Video_LoadMap
		lea	str_Title(pc),a0		; Main title
		move.l	#locate(0,2,2),d0
		bsr	Video_Print
		lea	str_Gema(pc),a0			; GEMA tester text on WINDOW
		move.l	#locate(2,2,2),d0
		bsr	Video_Print
		move.b	#$80,(sysmars_reg+comm14)	; Unlock MASTER

		lea	PAL_EMI(pc),a0
		moveq	#0,d0
		move.w	#$F,d1
		bsr	Video_LoadPal
		lea	PAL_TESTBOARD(pc),a0		; ON palette
		moveq	#$10,d0
		move.w	#$F,d1
		bsr	Video_LoadPal

		bset	#bitDispEnbl,(RAM_VdpRegs+1).l	; Enable display
		bsr	Video_Update

; 		move.b	(sysmars_reg+comm15),d7
; 		or.w	#1,d7
; 		move.b	d7,(sysmars_reg+comm15)

		lea	MasterTrkList(pc),a0
		moveq	#0,d0
		move.w	#8,d1
		moveq	#0,d2
		move.w	#0,d3
		bsr	Sound_TrkPlay

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		beq.s	.loop
		bsr	System_Input

	; Visual updates go here
		add.l	#1,(RAM_Framecount).l
		bsr	Emilie_MkSprite
		bsr	Board_SwapPos
		move.l	#$7C000003,(vdp_ctrl).l
		move.l	(RAM_Xpos).l,d0
		move.l	d0,(vdp_data).l
		move.l	#$40000010,(vdp_ctrl).l
		move.w	(RAM_ShakeMe).w,d3
		move.w	d3,d4
		lsr.w	#3,d3
		btst	#1,d4
		bne.s	.midshk
		neg.w	d3
.midshk:
		move.w	d3,(vdp_data).l

		move.w	(RAM_WindowCurr).w,d2
		move.w	(RAM_WindowNew).w,d1
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
.inside:	move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		bne.s	.inside


	; Main loop is back
		move.w	(RAM_CurrType).w,d0
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
		tst.w	(RAM_CurrType).w
		bmi	.mode0_loop
		or.w	#$8000,(RAM_CurrType).w
		move.w	#0,(RAM_EmiHide).w
		move.w	#1,(RAM_EmiUpd).w

; Mode 0 mainloop
.mode0_loop:
; 		lea	str_TempVal(pc),a0		; Main title
; 		move.l	#locate(0,0,0),d0
; 		bsr	Video_Print

	; BOOM TEST
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyA,d7
		beq.s	.noah
		move.w	#$20,(RAM_ShakeMe).w
		moveq	#0,d2
		bsr	SndPickSfx
.noah:
	; Shake explosion
		tst.w	(RAM_ShakeMe).w
		beq.s	.no_shake
		sub.w	#1,(RAM_ShakeMe).w
		move.w	#1,(RAM_EmiUpd).w
		bset	#1,(RAM_BoardUpd).w
.no_shake:


	; Emilie player input
		move.b	(RAM_EmiFlags).w,d7
		bsr	Emilie_Move
		btst	#0,(RAM_EmiFlags).w
		bne	.lockcontrl
		btst	#0,d7
		beq.s	.after
		bset	#0,(RAM_BoardUpd).w
		move.w	(RAM_EmiBlockX).w,d7
		or.w	(RAM_EmiBlockY).w,d7
		bmi.s	.after
		move.w	(RAM_EmiBlockX).w,d7
		cmp.w	#6,d7
		bge.s	.after
		move.w	(RAM_EmiBlockY).w,d7
		cmp.w	#6,d7
		bge.s	.after
		moveq	#1,d2
		bsr	SndPickSfx
.after:
		move.w	(Controller_1+on_press),d7
		lsr.w	#8,d7
		btst	#bitJoyMode,d7
		beq.s	.no_mode0
		move.w	#1,(RAM_CurrType).w
		move.w	#$920D,(RAM_WindowNew).w
.no_mode0:
		move.w	#0,d4
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyDown,d7
		beq.s	.noz_down
		add.w	#$18,(RAM_EmiMoveY).w
		add.w	#1,(RAM_EmiBlockY).w
		move.w	d4,(RAM_EmiChar).w
.noz_down:
		move.w	#4,d4
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyUp,d7
		beq.s	.noz_up
		add.w	#-$18,(RAM_EmiMoveY).w
		sub.w	#1,(RAM_EmiBlockY).w
		move.w	d4,(RAM_EmiChar).w
.noz_up:
		move.w	#8,d4
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyRight,d7
		beq.s	.noz_r
		add.w	#$20,(RAM_EmiMoveX).w
		add.w	#1,(RAM_EmiBlockX).w
		move.w	d4,(RAM_EmiChar).w
.noz_r:
		move.w	#$C,d4
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyLeft,d7
		beq.s	.noz_l
		add.w	#-$20,(RAM_EmiMoveX).w
		sub.w	#1,(RAM_EmiBlockX).w
		move.w	d4,(RAM_EmiChar).w
.noz_l:

.lockcontrl:
		rts

; --------------------------------------------------
; Mode 1
; --------------------------------------------------

.mode1:
		tst.w	(RAM_CurrType).w
		bmi	.mode1_loop
		or.w	#$8000,(RAM_CurrType).w
		bsr	.print_cursor
		move.w	#1,(RAM_EmiHide).w
		move.w	#1,(RAM_EmiUpd).w

.mode1_loop:
		move.w	(Controller_1+on_press),d7
		lsr.w	#8,d7
		btst	#bitJoyMode,d7
		beq.s	.no_mode1
		move.w	#0,(RAM_CurrType).w
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
		cmp.w	#4,(RAM_CurrSelc).w
		bne.s	.toptrk
		add	#2,a1
.toptrk:
		cmp.w	#5,(RAM_CurrSelc).w
		bne.s	.toptrk2
		add	#2*2,a1
.toptrk2:

		move.w	(Controller_1+on_hold),d7
		and.w	#JoyB,d7
		beq.s	.nob
		add.w	#1,(a1)
		bsr	.print_cursor
.nob:
		move.w	(Controller_1+on_hold),d7
		and.w	#JoyA,d7
		beq.s	.noa
		sub.w	#1,(a1)
		bsr	.print_cursor
.noa:



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
		dc.w .task_05-.tasklist

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
		bra	Sound_TrkPause
.task_03:
		bra	Sound_TrkResume
.task_04:
		move.w	(RAM_CurrTicks).w,d1
		bra	Sound_TrkTicks
.task_05:
		move.w	(RAM_CurrTempo).w,d1
		bra	Sound_GlbTempo

; test playlist
MasterTrkList:
	dc.l GemaTrk_patt_TEST,GemaTrk_blk_TEST,GemaTrk_ins_TEST
	dc.w 7,0
	dc.l GemaTrk_patt_HILLS,GemaTrk_blk_HILLS,GemaTrk_ins_HILLS
	dc.w 7,0
	dc.l GemaTrk_patt_TEST2,GemaTrk_blk_TEST2,GemaTrk_ins_TEST2
	dc.w 2,1
	dc.l GemaTrk_patt_chrono,GemaTrk_blk_chrono,GemaTrk_ins_chrono
	dc.w 3,1
	dc.l GemaTrk_mecano_patt,GemaTrk_mecano_blk,GemaTrk_mecano_ins
	dc.w 1,1
	align 2

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

SndPickSfx:
		lea	(GemaTrkData_Sfx),a0
		moveq	#1,d0
		moveq	#6,d1
; 		moveq	#0,d2
		moveq	#0,d3
		bra	Sound_TrkPlay

Board_SwapPos:
		btst	#0,(RAM_BoardUpd).w
		beq	.nbdw1
		bsr	.block_draw
		bclr	#0,(RAM_BoardUpd).w
.nbdw1:
		btst	#1,(RAM_BoardUpd).w
		beq	.nbdw2
		bsr	.draw_all
		bclr	#1,(RAM_BoardUpd).w
.nbdw2:
		rts

; draw all
.draw_all:
		lea	(RAM_BoardBlocks),a6
		move.w	#$4000|(8*$02)|(7*$80),d7
		swap	d7
		move.w	#3,d7
		moveq	#6-1,d0
.nxt_y:
		move.l	d7,d6
		move	#6-1,d1
.nxt_x:
		bsr	.this_blk
		adda	#1,a6
		add.l	#$80000,d6
		dbf	d1,.nxt_x
		add.l	#$1800000,d7
		dbf	d0,.nxt_y
		rts
.this_blk:
		move.l	d6,d5
		lea	.switch_vram(pc),a1
		move.l	#$20012001,d4
		btst	#0,(a6)
		beq.s	.is_off2
		add.l	#$000C000C,d4
.is_off2:
		move.l	a1,a0
		move.w	#3-1,d2
.next_y2:
		move.l	d5,(vdp_ctrl).l
		move.l	(a0)+,d3
		add.l	d4,d3
		move.l	d3,(vdp_data).l
		move.l	(a0)+,d3
		add.l	d4,d3
		move.l	d3,(vdp_data).l
		add.l	#$800000,d5
		dbf	d2,.next_y2
		rts

; switched block
.block_draw:
		move.w	(RAM_EmiBlockX).w,d7
		or.w	(RAM_EmiBlockY).w,d7
		bmi	.dont_upd
		cmp.w	#6,(RAM_EmiBlockX).w
		bge	.dont_upd
		cmp.w	#6,(RAM_EmiBlockY).w
		bge	.dont_upd

		lea	(RAM_BoardBlocks),a6
		moveq	#0,d7
		move.w	(RAM_EmiBlockX).w,d7
		adda	d7,a6
		add.w	d7,d7
		add.w	d7,d7
		move.w	(RAM_EmiBlockY).w,d6
		move.w	d6,d5
		add.w	d6,d6
		move.w	.ypos_ex(pc,d6.w),d6
		mulu.w	#6,d5
		adda	d5,a6

		add.w	d7,d7
		lsl.w	#7,d6			; *$80 size mode
		add.w	d6,d7
		add.w	#$4000|(8*$02)|(7*$80),d7
		swap	d7
		move.w	#3,d7
		move.l	d7,d6
		bchg	#0,(a6)
		lea	.switch_vram(pc),a0
		move.l	#$20012001,d4
		btst	#0,(a6)
		beq.s	.is_off
		add.l	#$000C000C,d4
.is_off:
		move.w	#3-1,d5
.next_y:
		move.l	d7,(vdp_ctrl).l
		move.l	(a0)+,d3
		add.l	d4,d3
		move.l	d3,(vdp_data).l
		move.l	(a0)+,d3
		add.l	d4,d3
		move.l	d3,(vdp_data).l
		add.l	#$800000,d7
		dbf	d5,.next_y
.dont_upd:
		rts

.ypos_ex:	dc.w 0
		dc.w 3
		dc.w 6
		dc.w 9
		dc.w 12
		dc.w 15
		align 2
.switch_vram:
		dc.w $0000,$0001,$0001,$0002
		dc.w $0003,$0004,$0004,$0005
		dc.w $0006,$0007,$0007,$0008

; 		move.l	(RAM_EmiMoveX).w,d4
; 		add.l	d4,(RAM_EmiPosX).l
; 		move.l	d0,d5
; 		bsr.s	.floatpos
; 		tst.l	d4
; 		bne.s	.resx
; 		and.l	#$FFE00000,(RAM_EmiPosX).l
; .resx:
; 		move.l	d4,(RAM_EmiMoveX).w
; 		move.l	(RAM_EmiMoveY).w,d4
; 		add.l	d4,(RAM_EmiPosY).l
; 		move.l	d0,d5
; 		bsr.s	.floatpos
; 		tst.l	d4
; 		bne.s	.resy
; 		and.l	#$FFE00000,(RAM_EmiPosY).l
; .resy:
; 		move.l	d4,(RAM_EmiMoveY).w
;
; 		move.l	(RAM_EmiPosX).l,d7
; 		or.l	(RAM_EmiPosY).l,d7
; 		beq.s	.no_yspd
; 		move.w	#1,(RAM_EmiUpd).w
; .no_yspd:
; 		rts
;
; .floatpos:
; 		tst.l	d4
; 		bmi.s	.xleft
; 		sub.l	d5,d4
; 		bpl.s	.xstop
; 		clr.l	d4
; .xleft:
; 		tst.l	d4
; 		beq.s	.xstop
; 		add.l	d5,d4
; 		bmi.s	.xstop
; 		clr.l	d4
; .xstop:
; 		rts

Emilie_Move:
		move.b	(RAM_EmiFlags),d2
		bclr	#0,d2
		move.w	(RAM_EmiPosX).w,d0
		move.w	(RAM_EmiMoveX).w,d1
		bsr	.move_it
		move.w	d0,(RAM_EmiPosX).w
		move.w	(RAM_EmiPosY).w,d0
		move.w	(RAM_EmiMoveY).w,d1
		bsr	.move_it
		move.w	d0,(RAM_EmiPosY).w
		move.b	d2,(RAM_EmiFlags).w
		rts
.move_it:
		move.w	d0,d5
		move.w	d1,d4
		cmp.w	d5,d4
		beq.s	.same_x
		move.w	#1,d6
		sub.w	d5,d4
		bpl.s	.reversx
		move.w	#-1,d6
.reversx:
		bset	#0,d2
		add.w	#1,(RAM_EmiAnim).w
		add.w	d6,d0
		move.w	#1,(RAM_EmiUpd).w
.same_x:
		rts

Emilie_MkSprite:
		tst.w	(RAM_EmiUpd).w
		beq	.no_upd
		lea	(vdp_data),a6
		tst.w	(RAM_EmiHide).w
		bne	.hidefuji
		clr.w	(RAM_EmiUpd).w
		move.w	(RAM_EmiChar),d2
		move.w	(RAM_EmiAnim),d3
		lsr.w	#3,d3
		and.w	#3,d3
		add.w	d3,d2
		move.w	#$20*$18,d1
		mulu.w	d1,d2
		move.l	#ART_EMI,d0
		add.l	d2,d0
		and.l	#-2,d0
		move.w	#$400,d2
		bsr	Video_LoadArt
		move.l	#$78000003,4(a6)
		move.w	(RAM_EmiPosY),d0
		move.w	(RAM_EmiPosX),d1
		move.w	(RAM_ShakeMe).w,d3
		move.w	d3,d4
		lsr.w	#3,d3
		btst	#0,d4
		bne.s	.midshk
		neg.w	d3
.midshk:
		sub.w	d3,d0

		add.w	#$80,d0
		add.w	#$80,d1
		move.w	d0,(a6)			; TOP 32x32
		move.w	#$0F01,(a6)
		move.w	d2,(a6)
		move.w	d1,(a6)
		add.w	#$20,d0
		add.w	#$10,d2
		move.w	d0,(a6)			; BOT 32x24
		move.w	#$0D00,(a6)
		move.w	d2,(a6)
		move.w	d1,(a6)
.no_upd:
		rts

.hidefuji:
		move.l	#$78000003,4(a6)
		move.l	#0,(a6)
		move.l	#0,(a6)
		move.l	#0,(a6)
		move.l	#0,(a6)
		rts

; NORMAL
; 		lea	(vdp_data),a6
; 		move.l	#$78000003,4(a6)
; 		move.w	(RAM_EmiPosY),d0
; 		move.w	(RAM_EmiPosX),d1
; 		move.w	(RAM_EmiChar),d2
; 		move.w	(RAM_EmiAnim),d3
; 		lsr.w	#3,d3
; 		and.w	#3,d3
; 		add.w	d3,d2
; 		mulu.w	#$18,d2
; 		add.w	#1,d2
; 		add.w	#$80,d0
; 		add.w	#$80,d1
; 		move.w	d0,(a6)			; TOP 32x32
; 		move.w	#$0F01,(a6)
; 		move.w	d2,(a6)
; 		move.w	d1,(a6)
; 		add.w	#$20,d0
; 		add.w	#$10,d2
; 		move.w	d0,(a6)			; BOT 32x24
; 		move.w	#$0D00,(a6)
; 		move.w	d2,(a6)
; 		move.w	d1,(a6)
; 		rts

; ====================================================================
; ------------------------------------------------------
; FIFO TEST
; ------------------------------------------------------

; TODO: ver como fregados consigo mandar
; RAM al 32X sin que se trabe

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

str_Title:
		dc.b "Project MARSIANO           (MODE)",$A
		dc.b "Test game                GEMA Tester",0
		align 2

str_Cursor:	dc.b " ",$A
		dc.b ">",$A
		dc.b " ",0

str_Status:
		dc.b "\\w",$A,$A
		dc.b "\\w",$A,$A,$A,$A
		dc.b "\\w",$A
		dc.b "\\w",0
		dc.l RAM_CurrIndx
		dc.l RAM_CurrTrack
		dc.l RAM_CurrTicks
		dc.l RAM_CurrTempo
		align 2
str_Gema:
		dc.b "GEMA SOUND DRIVER     2021-2022 GF64",$A
		dc.b $A
		dc.b "Track index -----",$A,$A
		dc.b "  Sound_TrkPlay",$A
		dc.b "  Sound_TrkStop",$A
		dc.b "  Sound_TrkPause**",$A
		dc.b "  Sound_TrkResume**",$A
		dc.b "  Sound_TrkTicks",$A
		dc.b "  Sound_GlbTempo",0
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

str_TempVal:
		dc.b "\\w",0
		dc.l RAM_EmiFlags
		align 2

PAL_EMI:
		dc.w 0
		binclude "data/md/sprites/emi_pal.bin",2
		align 2

PAL_TESTBOARD:	dc.w $0000,$0000,$0440,$0880,$0EEE,$0000,$0000,$0220,$0440,$0888
		align 2
; 		binclude "data/md/bg/board_pal.bin"
; 		align 2
MAP_TESTBOARD:
		binclude "data/md/bg/board_map.bin"
		align 2

; ====================================================================
; Report size
	if MOMPASS=6
.end:
		message "This 68K RAM-CODE uses: \{.end-thisCode_Top}"
	endif
