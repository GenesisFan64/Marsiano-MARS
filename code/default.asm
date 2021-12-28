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
RAM_Ypos	ds.l 1
RAM_XposFg	ds.l 1
RAM_XposBg	ds.l 1
RAM_EmiChar	ds.w 1
RAM_EmiAnim	ds.w 1
RAM_EmiHide	ds.w 1
RAM_ShakeMe	ds.w 1
RAM_BoardUpd	ds.w 1
RAM_CurrMode	ds.w 1
RAM_BgCamera	ds.w 1
RAM_CurrSelc	ds.w 1
RAM_CurrIndx	ds.w 1
RAM_CurrTrack	ds.w 1
RAM_CurrTicks	ds.w 1
RAM_CurrTempo	ds.w 1
RAM_WindowCurr	ds.w 1
RAM_WindowNew	ds.w 1
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
		move.l	#ART_FGTEST,d0
		move.w	#1*$20,d1
		move.w	#ART_FGTEST_e-ART_FGTEST,d2
		bsr	Video_LoadArt
		lea	(MAP_FGTEST),a0
		move.l	#locate(0,8,0),d0
		move.l	#mapsize(192,224),d1
		move.w	#1+$2000,d2
		bsr	Video_LoadMap
		lea	(MAP_FGTEST),a0
		move.l	#locate(0,8+32,0),d0
		move.l	#mapsize(192,224),d1
		move.w	#1+$2000,d2
		bsr	Video_LoadMap

		lea	str_Gema(pc),a0			; GEMA tester text on WINDOW
		move.l	#locate(2,2,2),d0
		bsr	Video_Print

	; Load palettes for fade-in
		lea	PAL_TESTBOARD(pc),a0
		moveq	#$10,d0
		move.w	#$F,d1
		bsr	Video_PalTarget
		lea	(TESTMARS_BG_PAL),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#1,d2
		bsr	Video_PalTarget_Mars
		move.w	#1,(RAM_FadeMdSpd).w		; Fade-in speed(s)
		move.w	#2,(RAM_FadeMarsSpd).w
		move.w	#1,(RAM_FadeMdReq).w		; FadeIn request on both sides
		move.w	#1,(RAM_FadeMarsReq).w
		bset	#4,(sysmars_reg+comm14).l	; Request REDRAW on Master
.wait2:		btst	#4,(sysmars_reg+comm14).l	; and wait until it finishes
		bne.s	.wait2
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l	; Enable Genesis display
		bsr	Video_Update

		lea	MasterTrkList(pc),a0
		move.w	$C(a0),d1
		move.w	$E(a0),d3
		moveq	#0,d0
		moveq	#0,d2
		bsr	Sound_TrkPlay

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
		bsr	System_VBlank_Exit

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
	; This mode's initial values go here

.mode0_loop:
		bsr	Video_PalFade
		bsr	Video_MarsPalFade

		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq.s	.no_mode0
		move.w	#1,(RAM_CurrMode).w
		move.w	#$920D,(RAM_WindowNew).w
.no_mode0:

	; Test movement
		move.l	(RAM_MdMarsBg).w,d0
		move.l	(RAM_MdMarsBg+4).w,d1
		move.w	(RAM_HorScroll).w,d2
		move.w	(RAM_VerScroll).w,d3
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


; 		move.l	#$10000,d2
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyB,d7
		beq.s	.nor_m2
		add.l	d5,d0
		sub.w	d6,d2
.nor_m2:
		btst	#bitJoyA,d7
		beq.s	.nol_m2
		sub.l	d5,d0
		add.w	d6,d2
.nol_m2:
		move.l	d0,(RAM_MdMarsBg).w
		move.l	d1,(RAM_MdMarsBg+4).w
		move.w	d2,(RAM_HorScroll).w
		move.w	d3,(RAM_VerScroll).w
		bsr	System_MdMarsDreq

; 		tst.w	(RAM_MdMarsDreq+8).w
; 		beq.s	.noclr
; 		clr.w	(RAM_MdMarsDreq+8).w
; .noclr:
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyC,d7
; 		beq.s	.nor_m3
; 		move.w	#1,(RAM_MdMarsDreq+8).w
; .nor_m3:

; 		bsr	Emilie_Move
; 		bsr	Emilie_MkSprite
		rts

; 		lea	str_TempVal(pc),a0		; Main title
; 		move.l	#locate(0,0,0),d0
; 		bsr	Video_Print

	; BOOM TEST
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyA,d7
; 		beq.s	.noah
; 		move.w	#$20,(RAM_ShakeMe).w
; 		moveq	#0,d2
; 		bsr	PlayThisSfx
; .noah:


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
		move.w	#1,(RAM_EmiHide).w
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
	dc.l GemaTrk_patt_Vectr,GemaTrk_blk_Vectr,GemaTrk_ins_Vectr
	dc.w 7,0
	dc.l GemaTrk_patt_bemine,GemaTrk_blk_bemine,GemaTrk_ins_bemine
	dc.w $A,0
	dc.l GemaTrk_patt_HILLS,GemaTrk_blk_HILLS,GemaTrk_ins_HILLS
	dc.w 7,0
; 	dc.l GemaTrk_patt_TEST2,GemaTrk_blk_TEST2,GemaTrk_ins_TEST2
; 	dc.w 2,1
; 	dc.l GemaTrk_patt_chrono,GemaTrk_blk_chrono,GemaTrk_ins_chrono
; 	dc.w 3,1
; 	dc.l GemaTrk_mecano_patt,GemaTrk_mecano_blk,GemaTrk_mecano_ins
; 	dc.w 1,1
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


; 		sub.l
; 		move.b	(RAM_EmiFlags),d2
; 		bclr	#7,d2
; 		move.w	(RAM_EmiPosX).w,d0
; 		move.w	(RAM_EmiMoveX).w,d1
; 		bsr	.move_it
; 		move.w	d0,(RAM_EmiPosX).w
; 		move.w	(RAM_EmiPosY).w,d0
; 		move.w	(RAM_EmiMoveY).w,d1
; 		bsr	.move_it
; 		move.w	d0,(RAM_EmiPosY).w
; 		move.b	d2,(RAM_EmiFlags).w
;
; 		move.l	(RAM_EmiJumpSpd).l,d5
; 		move.l	(RAM_EmiJumpY),d6
; 		add.l	d5,d6
; 		move.l	d6,(RAM_EmiJumpY)
;
; 		move.l	(RAM_EmiJumpSpd).l,d5
; 		add.l	#$2000,d5
; ; 		bmi.s	.toomuch
; 		move.l	(RAM_EmiJumpY),d6
; 		bmi.s	.toomuch
; 		clr.l	d5
; 		bra.s	.eximuch
; .toomuch:
; 		move.w	#1,(RAM_EmiUpd).w
; .eximuch:
; 		move.l	d5,(RAM_EmiJumpSpd).l
; 		rts
; .move_it:
; 		move.w	d0,d5
; 		move.w	d1,d4
; 		cmp.w	d5,d4
; 		beq.s	.same_x
; 		move.w	#1,d6
; 		sub.w	d5,d4
; 		bpl.s	.reversx
; 		move.w	#-1,d6
; .reversx:
; 		bset	#7,d2
; 		add.w	#1,(RAM_EmiAnim).w
; 		add.w	d6,d0
; .same_x:
		rts

Emilie_MkSprite:
		lea	(vdp_data),a6
		tst.w	(RAM_EmiHide).w
		bne	.hidefuji

; 		move.w	(RAM_EmiChar),d2
; 		move.w	(RAM_EmiAnim),d3
; 		lsr.w	#3,d3
; 		and.w	#7,d3
; 		add.w	d3,d2
; 		move.w	#$20*$20,d1
; 		mulu.w	d1,d2
; 		move.l	#ART_EMI,d0
; 		add.l	d2,d0
; 		and.l	#-2,d0
; 		move.w	#1,d2
; 		bsr	Video_DmaSet
.no_updgfx:
		lea	(RAM_SpriteData),a6
		move.l	(RAM_EmiPosY),d0
		move.l	(RAM_EmiPosX),d1
		swap	d0
		swap	d1
		add.w	#$80+32,d0
		add.w	#$80+32,d1
		move.w	(RAM_EmiAnim),d2
		lsr.w	#3,d2
		and.w	#7,d2
		add.w	d2,d2
		lea	Map_Nicole(pc),a0
		move.w	(a0,d2.w),d2
		adda	d2,a0
		move.b	(a0)+,d4
		and.w	#$FF,d4
		sub.w	#1,d4
		move.w	#$0001,d5
		move.w	#$0001,d6
.nxt_pz:
		move.b	(a0)+,d3
		ext.w	d3
		add.w	d0,d3
		move.w	d3,(a6)+

		move.b	(a0)+,d3
		lsl.w	#8,d3
		add.w	d5,d3
		move.w	d3,(a6)+

		move.b	(a0)+,d3
		lsl.w	#8,d3
		move.b	(a0)+,d2
		and.w	#$FF,d2
		add.w	d3,d2
		add.w	d6,d2
		move.w	d2,(a6)+

		move.b	(a0)+,d3
		ext.w	d3
		add.w	d1,d3
		move.w	d3,(a6)+
		add.w	#1,d5
		dbf	d4,.nxt_pz
		clr.l	(a6)+
		clr.l	(a6)+

	; DPLC
		move.w	(RAM_EmiAnim),d2
		lsr.w	#3,d2
		and.w	#7,d2
		add.w	d2,d2
		lea	Dplc_Nicole(pc),a0
		move.w	(a0,d2.w),d2
		adda	d2,a0
		move.w	(a0)+,d4
		and.w	#$FF,d4
		sub.w	#1,d4
		move.w	#1,d5


	; d0 - graphics
	; d5 - VRAM OUTPUT
		lsl.w	#5,d5
.nxt_dpz:
		move.l	#ART_EMI,d0
		move.w	(a0)+,d1
		move.w	d1,d2
		and.w	#$7FF,d1
		lsl.w	#5,d1
		add.l	d1,d0
		move.w	d5,d1
		lsr.w	#7,d2
		add.w	#$20,d2
		move.w	d2,d3
		bsr	Video_DmaSet
		add.w	d3,d5
		dbf	d4,.nxt_dpz
.no_upd:
		rts
;
.hidefuji:
		lea	(RAM_SpriteData),a6
		move.l	#0,(a6)+
		move.l	#0,(a6)+
		move.l	#0,(a6)+
		move.l	#0,(a6)+
		rts

; VBLANK only
Emilie_Show:
		lea	(vdp_data),a6
		move.l	#$78000003,4(a6)
		lea	(RAM_SpriteData),a5
		move.w	#8-1,d7
.sprdata:
		move.l	(a5)+,(a6)
		move.l	(a5)+,(a6)
		move.l	(a5)+,(a6)
		move.l	(a5)+,(a6)
		dbf	d7,.sprdata
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
		dc.b "Project MARSIANO",0
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
		dc.b "GEMA SOUND DRIVER",$A
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

; str_DreqMe:
; 		dc.b "Genesis manda por DREQ:",$A
; 		dc.b "\\l \\l",0
; 		dc.l RAM_MdMarsDreq
; 		dc.l RAM_MdMarsDreq+(256*2)-4
; 		align 2
; str_TempVal:
; 		dc.b "\\w",0
; 		dc.l RAM_EmiFlags
; 		align 2

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
