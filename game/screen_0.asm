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
; 		endstruct

; ====================================================================
; ------------------------------------------------------
; This mode's RAM
; ------------------------------------------------------

			struct RAM_ScreenBuff
RAM_EmiPosX		ds.l 1
RAM_EmiPosY		ds.l 1
RAM_EmiMoveX		ds.l 1
RAM_EmiMoveY		ds.l 1
RAM_EmiJumpSpd		ds.l 1
RAM_EmiJumpY		ds.l 1
RAM_EmiFlags		ds.w 1
RAM_EmiBlockX		ds.w 1
RAM_EmiBlockY		ds.w 1
RAM_EmiChar		ds.w 1
RAM_EmiAnim		ds.w 1
RAM_EmiUpd		ds.w 1
RAM_EmiHide		ds.w 1
RAM_ShakeMe		ds.w 1
RAM_BoardUpd		ds.w 1
RAM_CurrType		ds.w 1
RAM_BgCamera		ds.w 1
RAM_Xpos		ds.w 1
RAM_CurrSelc		ds.w 1
RAM_CurrIndx		ds.w 1
RAM_CurrTrack		ds.w 1
RAM_CurrTicks		ds.w 1
RAM_CurrTempo		ds.w 1
RAM_WindowCurr		ds.w 1
RAM_WindowNew		ds.w 1
RAM_BoardBlocks		ds.b 6*6
sizeof_thisbuff0	ds.l 0
			endstruct

			erreport "SCREEN0 BUFF",sizeof_thisbuff0-RAM_ScreenBuff,MAX_ScrnBuff

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

thisCode_Top:
		move.w	#$2700,sr
		bsr	Mode_Init
		bsr	Video_PrintInit
		bsr	Video_Clear

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

		lea	(RAM_PaletteFd+$60),a0
		move.w	#0,(a0)+
		move.w	#$EEE,(a0)+
		move.w	#$CCC,(a0)+
		move.w	#$AAA,(a0)+
		move.w	#$888,(a0)+
		move.w	#$222,(a0)+
		clr.w	(RAM_PaletteFd).w		; <-- quick patch
		clr.w	(RAM_MdMarsPalFd).w
	; Test image
	if MARS|MARSCD
		lea	(PalMars_TEST),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#0,d2
		bsr	Video_FadePal_Mars
	endif
		move.l	#ART_TESTBOARD,d0
		move.w	#ART_TESTBOARD_e-ART_TESTBOARD,d2
		move.w	#cell_vram($0001),d1
		bsr	Video_LoadArt
		lea	(MAP_TESTBOARD),a0
		move.l	#locate(0,0,0),d0
		move.l	#mapsize(320,224),d1
		move.w	#$2000|$0001,d2
		bsr	Video_LoadMap
		bset	#0,(RAM_BoardUpd).w

		lea	PAL_EMI(pc),a0
		moveq	#0,d0
		move.w	#$F,d1
		bsr	Video_FadePal
		lea	PAL_TESTBOARD(pc),a0		; ON palette
		moveq	#$10,d0
		move.w	#$F,d1
		bsr	Video_FadePal

	; Shared:
; 		lea	str_Stats(pc),a0
; 		move.l	#locate(0,1,1),d0
; 		bsr	Video_Print
; 	Set Fade-in settings
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l
		move.b	#%10000001,(RAM_VdpRegs+$C).w		; H40 + shadow mode
		bsr	Video_Update
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#2,(RAM_FadeMarsIncr).w
		move.w	#1,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w

; 	if MCD|MARSCD
; 		moveq	#$10,d0
; 		bsr	System_McdSubTask
; ; 		move.l	#$7FFEC,d7
; ; .ll:
; ; 		nop
; ; 		nop
; ; 		nop
; ; 		nop
; ; 		nop
; ; 		nop
; ; 		nop
; ; 		dbf	d7,.ll
; 	endif
		moveq	#0,d0
		bsr	gemaPlayTrack

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	System_Render
		bsr	Video_RunFade
		lea	str_Title(pc),a0
		move.l	#locate(0,1,1),d0
		bsr	Video_Print
;
	; Visual updates go here
		bsr	Emilie_MkSprite
		bsr	Board_SwapPos

; 		move.l	#$7C000003,(vdp_ctrl).l
; 		move.l	(RAM_Xpos).l,d0
; 		move.l	d0,(vdp_data).l

		lea	(RAM_VerScroll),a0
		move.w	(RAM_ShakeMe).w,d3
		move.w	d3,d4
		lsr.w	#3,d3
		btst	#1,d4
		bne.s	.midshk
		neg.w	d3
.midshk:
		move.w	d3,(a0)


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
		bra.w	.mode0
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
		move.w	(Controller_1+on_press),d7
		lsr.w	#8,d7
		btst	#bitJoyMode,d7
		beq.s	.no_mode0
		move.w	#1,(RAM_CurrType).w
		move.w	#$920D,(RAM_WindowNew).w
.no_mode0:

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

	; Shake explosion
		move.w	(RAM_ShakeMe),d7
		tst.w	(RAM_ShakeMe).w
		beq.s	.no_shake
		sub.w	#1,(RAM_ShakeMe).w
		move.w	#1,(RAM_EmiUpd).w
		bset	#0,(RAM_BoardUpd).w
		tst.w	(RAM_ShakeMe).w
		bne.s	.no_shake
		bsr	Board_Reset
.no_shake:
; 		bset	#0,(RAM_BoardUpd).w

	; Emilie player input
		move.b	(RAM_EmiFlags).w,d7
		bsr	Emilie_Move
		btst	#7,(RAM_EmiFlags).w
		bne	.lockcontrl
		btst	#7,d7
		beq.s	.after
		lea	(RAM_BoardBlocks),a6
		move.w	(RAM_EmiBlockX).w,d7
		or.w	(RAM_EmiBlockY).w,d7
		bmi.s	.after
		move.w	(RAM_EmiBlockX).w,d0
		cmp.w	#6,d0
		bge.s	.after
		move.w	(RAM_EmiBlockY).w,d1
		cmp.w	#6,d1
		bge.s	.after
		mulu.w	#6,d1
		add.w	d1,d0
		adda	d0,a6
		bchg	#0,(a6)
		bset	#0,(RAM_BoardUpd).w
		moveq	#1,d1
		bsr	PlayThisSfx
		bsr	Board_CheckMatch
.after:

	; UDLR
		move.w	#0,d4
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyDown,d7
		beq.s	.noz_down
		add.w	#$18,(RAM_EmiMoveY).w
		add.w	#1,(RAM_EmiBlockY).w
		move.w	d4,(RAM_EmiChar).w
		move.l	#-$20000,(RAM_EmiJumpSpd).l
.noz_down:
		move.w	#4,d4
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyUp,d7
		beq.s	.noz_up
		add.w	#-$18,(RAM_EmiMoveY).w
		sub.w	#1,(RAM_EmiBlockY).w
		move.w	d4,(RAM_EmiChar).w
		move.l	#-$20000,(RAM_EmiJumpSpd).l
.noz_up:
		move.w	#8,d4
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyRight,d7
		beq.s	.noz_r
		add.w	#$20,(RAM_EmiMoveX).w
		add.w	#1,(RAM_EmiBlockX).w
		move.w	d4,(RAM_EmiChar).w
		move.l	#-$20000,(RAM_EmiJumpSpd).l
.noz_r:
		move.w	#$C,d4
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyLeft,d7
		beq.s	.noz_l
		add.w	#-$20,(RAM_EmiMoveX).w
		sub.w	#1,(RAM_EmiBlockX).w
		move.w	d4,(RAM_EmiChar).w
		move.l	#-$20000,(RAM_EmiJumpSpd).l
.noz_l:
		rts

.lockcontrl:
; 		add.w	#6,(RAM_EmiJumpTan).w
		rts

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

; d2 - BLOCK
PlayThisSfx:
		moveq	#$F,d0
		bra	gemaPlayFromBlk

; 		lea	(GemaTrkData_Sfx),a0
; 		moveq	#1,d0
; 		moveq	#6,d1
; ; 		moveq	#0,d2
; 		moveq	#0,d3
; 		bra	Sound_TrkPlay

Board_CheckMatch:
	; horizontal
		lea	(RAM_BoardBlocks),a6
		moveq	#0,d3
		move	#6-1,d6
.x_chk_n:
		move.w	#6-1,d7
		moveq	#0,d5
.x_chk:
		add.b	(a6),d5
		adda	#1,a6
		dbf	d7,.x_chk
		cmp.b	#6,d5
		bne.s	.x_off
		add.w	#1,d3
.x_off:
		dbf	d6,.x_chk_n
	; vertical
		lea	(RAM_BoardBlocks),a6
		move	#6-1,d6
.y_chk_n:
		move.l	a6,a5
		move.w	#6-1,d7
		moveq	#0,d5
.y_chk:
		add.b	(a5),d5
		adda	#6,a5
		dbf	d7,.y_chk
		cmp.b	#6,d5
		bne.s	.y_off
		add.w	#1,d3
.y_off:
		adda	#1,a6
		dbf	d6,.y_chk_n
		tst.w	d3
		beq.s	.xs_off
		move.w	#$20,(RAM_ShakeMe).w
		moveq	#0,d1
		bsr	PlayThisSfx
.xs_off:
		rts

Board_Reset:
	; horizontal
		lea	(RAM_BoardBlocks),a6
		moveq	#0,d3
		move	#6-1,d6
.x_chk_n:
		move.l	a6,a5
		move.w	#6-1,d7
		moveq	#0,d5
.x_chk:
		add.b	(a5),d5
		adda	#1,a5
		dbf	d7,.x_chk
		cmp.b	#6,d5
		bne.s	.x_off
		move.l	a6,a4
		moveq	#6-1,d3
.x_clr:
		bset	#2,(a4)
		adda	#1,a4
		dbf	d3,.x_clr
.x_off:
		adda	#6,a6
		dbf	d6,.x_chk_n
	; vertical
		lea	(RAM_BoardBlocks),a6
		move	#6-1,d6
.y_chk_n:
		move.l	a6,a5
		move.w	#6-1,d7
		moveq	#0,d5
.y_chk:
		move.b	(a5),d2
		and	#1,d2
		add.b	d2,d5
		adda	#6,a5
		dbf	d7,.y_chk
		cmp.b	#6,d5
		bne.s	.y_off
		move.l	a6,a4
		moveq	#6-1,d3
.y_clr:
		bset	#2,(a4)
		adda	#6,a4
		dbf	d3,.y_clr
.y_off:
		adda	#1,a6
		dbf	d6,.y_chk_n

	; clearall req
		lea	(RAM_BoardBlocks),a6
		moveq	#(6*6)-1,d7
.nxtclr:
		btst	#2,(a6)
		beq.s	.noclrrq
		clr.b	(a6)
.noclrrq:
		adda	#1,a6
		dbf	d7,.nxtclr
		rts

Board_SwapPos:
		btst	#0,(RAM_BoardUpd).w
		beq	.nbdw2
		bsr	.draw_all
		bclr	#0,(RAM_BoardUpd).w
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

; ; switched block
; .block_draw:
; 		move.w	(RAM_EmiBlockX).w,d7
; 		or.w	(RAM_EmiBlockY).w,d7
; 		bmi	.dont_upd
; 		cmp.w	#6,(RAM_EmiBlockX).w
; 		bge	.dont_upd
; 		cmp.w	#6,(RAM_EmiBlockY).w
; 		bge	.dont_upd
;
; 		lea	(RAM_BoardBlocks),a6
; 		moveq	#0,d7
; 		move.w	(RAM_EmiBlockX).w,d7
; 		adda	d7,a6
; 		add.w	d7,d7
; 		add.w	d7,d7
; 		move.w	(RAM_EmiBlockY).w,d6
; 		move.w	d6,d5
; 		add.w	d6,d6
; 		move.w	.ypos_ex(pc,d6.w),d6
; 		mulu.w	#6,d5
; 		adda	d5,a6
;
; 		add.w	d7,d7
; 		lsl.w	#7,d6			; *$80 size mode
; 		add.w	d6,d7
; 		add.w	#$4000|(8*$02)|(7*$80),d7
; 		swap	d7
; 		move.w	#3,d7
; 		move.l	d7,d6
; 		bchg	#0,(a6)
; 		lea	.switch_vram(pc),a0
; 		move.l	#$20012001,d4
; 		btst	#0,(a6)
; 		beq.s	.is_off
; 		add.l	#$000C000C,d4
; .is_off:
; 		move.w	#3-1,d5
; .next_y:
; 		move.l	d7,(vdp_ctrl).l
; 		move.l	(a0)+,d3
; 		add.l	d4,d3
; 		move.l	d3,(vdp_data).l
; 		move.l	(a0)+,d3
; 		add.l	d4,d3
; 		move.l	d3,(vdp_data).l
; 		add.l	#$800000,d7
; 		dbf	d5,.next_y
; .dont_upd:
; 		rts

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
; 		sub.l
		move.b	(RAM_EmiFlags),d2
		bclr	#7,d2
		move.w	(RAM_EmiPosX).w,d0
		move.w	(RAM_EmiMoveX).w,d1
		bsr	.move_it
		move.w	d0,(RAM_EmiPosX).w
		move.w	(RAM_EmiPosY).w,d0
		move.w	(RAM_EmiMoveY).w,d1
		bsr	.move_it
		move.w	d0,(RAM_EmiPosY).w
		move.b	d2,(RAM_EmiFlags).w

		move.l	(RAM_EmiJumpSpd).l,d5
		move.l	(RAM_EmiJumpY),d6
		add.l	d5,d6
		move.l	d6,(RAM_EmiJumpY)

		move.l	(RAM_EmiJumpSpd).l,d5
		add.l	#$2000,d5
; 		bmi.s	.toomuch
		move.l	(RAM_EmiJumpY),d6
		bmi.s	.toomuch
		clr.l	d5
		bra.s	.eximuch
.toomuch:
		move.w	#1,(RAM_EmiUpd).w
.eximuch:
		move.l	d5,(RAM_EmiJumpSpd).l
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
		bset	#7,d2
		add.w	#1,(RAM_EmiAnim).w
		add.w	d6,d0
.same_x:
		rts

Emilie_MkSprite:
		lea	(RAM_Sprites),a6
		tst.w	(RAM_EmiHide).w
		bne	.hidefuji

		tst.w	(RAM_EmiUpd).w
		beq	.no_updgfx
		clr.w	(RAM_EmiUpd).w
		move.w	(RAM_EmiChar),d1
		move.w	(RAM_EmiAnim),d3
		lsr.w	#3,d3
		and.w	#3,d3
		add.w	d3,d1
		move.w	#$20*$18,d2
		mulu.w	d2,d1
		move.l	#ART_EMI,d0
		add.l	d1,d0
		and.l	#-2,d0
		move.w	#cell_vram($40),d1
		bsr	Video_DmaMkEntry
.no_updgfx:
		move.l	(RAM_EmiPosY),d0
		add.l	(RAM_EmiJumpY),d0
		swap	d0
		move.w	(RAM_EmiPosX),d2
		move.w	(RAM_ShakeMe).w,d3
		move.w	d3,d4
		lsr.w	#3,d3
		btst	#0,d4
		bne.s	.midshk
		neg.w	d3
.midshk:
		lea	(RAM_Sprites),a6
		sub.w	d3,d0
		move.w	#$40,d1
		addi.w	#$80,d0
		addi.w	#$80,d2
		move.w	d0,(a6)			; TOP 32x32
		move.w	#$0F01,2(a6)
		move.w	d1,4(a6)
		move.w	d2,6(a6)
		adda	#8,a6
		addi.w	#$20,d0
		move.w	d0,(a6)			; BOT 32x24
		move.w	#$0D00,2(a6)
		addi.w	#$10,d1
		move.w	d1,4(a6)
		move.w	d2,6(a6)
.no_upd:
		rts

.hidefuji:
		move.l	#0,(a6)
		move.l	#0,$04(a6)
		move.l	#0,$08(a6)
		move.l	#0,$0C(a6)
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

		align 2
str_Title:
; 	if MARS
		dc.b "\\l \\w \\w",$A,$A
		dc.b "\\w \\w \\w \\w MARS",$A
		dc.b "\\w \\w \\w \\w",$A
		dc.b $A
		dc.b "\\b \\b",$A,$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b $A

		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b "\\w",$A
		dc.b 0

		dc.l RAM_Framecount
		dc.l Controller_1+on_hold
		dc.l Controller_2+on_hold

		dc.l sysmars_reg+comm0
		dc.l sysmars_reg+comm2
		dc.l sysmars_reg+comm4
		dc.l sysmars_reg+comm6
		dc.l sysmars_reg+comm8
		dc.l sysmars_reg+comm10
		dc.l sysmars_reg+comm12
		dc.l sysmars_reg+comm14

		dc.l sysmcd_reg+mcd_comm_m
		dc.l sysmcd_reg+mcd_comm_s

		dc.l sysmcd_reg+mcd_dcomm_m
		dc.l sysmcd_reg+mcd_dcomm_m+2
		dc.l sysmcd_reg+mcd_dcomm_m+4
		dc.l sysmcd_reg+mcd_dcomm_m+6
		dc.l sysmcd_reg+mcd_dcomm_m+8
		dc.l sysmcd_reg+mcd_dcomm_m+10
		dc.l sysmcd_reg+mcd_dcomm_m+12
		dc.l sysmcd_reg+mcd_dcomm_m+14
		dc.l sysmcd_reg+mcd_dcomm_s
		dc.l sysmcd_reg+mcd_dcomm_s+2
		dc.l sysmcd_reg+mcd_dcomm_s+4
		dc.l sysmcd_reg+mcd_dcomm_s+6
		dc.l sysmcd_reg+mcd_dcomm_s+8
		dc.l sysmcd_reg+mcd_dcomm_s+10
		dc.l sysmcd_reg+mcd_dcomm_s+12
		dc.l sysmcd_reg+mcd_dcomm_s+14

		align 2

PAL_EMI:
		dc.w 0
		binclude "game/data/md/sprites/emi_pal.bin",2
		align 2

PAL_TESTBOARD:	dc.w $0000,$0000,$0444,$0888,$0EEE,$0000,$0000,$0002,$0004,$0888
		align 2
; 		binclude "game/data/md/bg/board_pal.bin"
; 		align 2

