; ====================================================================
; ----------------------------------------------------------------
; Titlescreen
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Settings
; ------------------------------------------------------

SET_MENUTOPLINE		equ 123
MAX_TITLOPT		equ 6
VRAMTTL_PUZBG		equ $0001
VRAMTTL_CELLHIDE	equ $0780

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

			struct RAM_ScreenBuff
RAM_Ttle_SpriteData	ds.w 4*70
RAM_Ttle_HorVal		ds.l 1
RAM_Ttle_VerVal		ds.l 1
RAM_Tite_VerBot		ds.l 1			; 0000.0000
RAM_Tite_VerBgMenu	ds.l 1
RAM_Ttle_VerBg		ds.l 1
RAM_Ttle_HorBg  	ds.l 1
RAM_Ttle_SpdUsr		ds.w 1
RAM_Ttle_SFX		ds.w 1
RAM_Tite_PickOpt	ds.w 1
RAM_Tite_UsrOpt_T	ds.w 1
RAM_Tite_UsrOpt_B	ds.w 1
RAM_Titl_DbgValues	ds.w 17
			endstruct

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

; MD_2DMODE:
		move.w	#$2700,sr
		bclr	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update
		bsr	Video_PrintInit
		bsr	Mode_Init
		bsr	Objects_Init

		lea	str_TitleS(pc),a0
		move.l	#locate(0,2,3),d0
		bsr	Video_Print
		bsr	Debug_PrintCursor
		lea	str_TitleSfx(pc),a0	; Print menu
		move.l	#locate(0,2,5),d0
		bsr	Video_Print
		bsr	.sfx_draw

		lea	(RAM_Palette+$60),a0
		move.w	#0,(a0)+
		move.w	#$EEE,(a0)+
		move.w	#$CCC,(a0)+
		move.w	#$AAA,(a0)+
		move.w	#$888,(a0)+
		move.w	#$222,(a0)+
		clr.w	(RAM_Palette).w		; <-- quick patch
		clr.w	(RAM_MdMarsPalFd).w
		bsr	gemaStopAll


	; Set Fade-in settings
; 		move.w	#1,(RAM_FadeMdIncr).w
; 		move.w	#2,(RAM_FadeMarsIncr).w
; 		move.w	#1,(RAM_FadeMdDelay).w
; 		move.w	#0,(RAM_FadeMarsDelay).w
; 		move.w	#1,(RAM_FadeMdReq).w
; 		move.w	#1,(RAM_FadeMarsReq).w
		move.b	#%111,(RAM_VdpRegs+$B).l
		move.b	#0,(RAM_VdpRegs+7).l
		bset	#bitHintEnbl,(RAM_VdpRegs).l
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l
		bclr	#bitVintEnbl,(RAM_VdpRegs+1).l
		move.b	#SET_MENUTOPLINE,(RAM_VdpRegs+$A).w	; Hint line
		move.b	#%10000001,(RAM_VdpRegs+$C).w		; H40 + shadow mode
		move.w	#$9200,(vdp_ctrl).l		; Set WINDOW Bottom
		bsr	Video_Update
		move.l	#VInt_Default,(RAM_MdMarsVInt+2).w
		move.l	#HInt_Default,(RAM_MdMarsHInt+2).w
		bsr 	System_WaitFrame		; Send first DREQ

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
; 		bsr	System_Random
; 		bsr	Objects_Show
; 		bsr	MdMap_Update
.ploop:		bsr	System_WaitFrame
		bsr	Video_RunFade
		bne.s	.ploop
; 		bsr	Debug_AnimateFg
		bsr	System_Random		; <-- reroll every frame
; 		bsr	Objects_Run
; 		bsr	Map_Camera
; 		bsr	DEBUG_GRABZ80

		lea	(RAM_MdDreq+Dreq_Objects),a0
		add.w	#8*1,mdl_x_rot(a0)
		add.w	#8*1,mdl_y_rot(a0)
		add.w	#8*2,mdl_z_rot(a0)
		bsr	Debug_PrintCursor

	; Controls
		lea	(RAM_Tite_UsrOpt_T),a0
		move.w	(RAM_Tite_PickOpt),d0
		add.w	d0,d0
		adda	d0,a0
		move.w	(Controller_1+on_press).l,d4
		and.w	#JoyUp,d4
		beq.s	.no_up
		tst.w	(a0)
		beq.s	.no_up
		sub.w	#1,(a0)
		bsr	Debug_PrintCursor
.no_up:
		move.w	(Controller_1+on_press).l,d4
		and.w	#JoyDown,d4
		beq.s	.no_down
		cmp.w	#MAX_TITLOPT,(a0)	; RECICLADO
		beq.s	.no_down
		add.w	#1,(a0)
		bsr	Debug_PrintCursor
.no_down:
; 		move.w	(Controller_1+on_press).l,d7
; 		and.w	#JoyA,d7
; 		beq.s	.no_a
; 		bchg	#0,(RAM_Tite_PickOpt+1).w
; .no_a:

; 		tst.w	(RAM_Tite_PickOpt).w
; 		bne.s	.no_r
		move.w	(Controller_1+on_press).l,d7
		and.w	#JoyLeft,d7
		beq.s	.no_l
		tst.w	(RAM_Ttle_SFX).w
		beq.s	.no_l
		sub.w	#1,(RAM_Ttle_SFX).w
		bsr	.sfx_draw
.no_l:
		move.w	(Controller_1+on_press).l,d7
		and.w	#JoyRight,d7
		beq.s	.no_r
		add.w	#1,(RAM_Ttle_SFX).w
		bsr	.sfx_draw
.no_r:
		move.w	(Controller_1+on_press).l,d7
		and.w	#JoyC,d7
		beq.s	.no_c
		bsr	.gema_test
.no_c:
; 		move.w	(Controller_1+on_press).l,d7
; 		and.w	#JoyB,d7
; 		beq.s	.no_b
; 		bsr	gemaTest
; .no_b:

; 		move.w	(Controller_1+on_press).l,d7
; 		and.w	#JoyB,d7
; 		beq.s	.no_b
; 		moveq	#1,d0
; 		bsr	.sfx_play
; .no_b:
; 		move.w	(Controller_1+on_press).l,d7
; 		and.w	#JoyA,d7
; 		beq.s	.no_a
; 		moveq	#0,d0
; 		bsr	Sound_TESTCMD
; .no_a:

; 		lea	(RAM_BoxPlayers),a6
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyMode,d7
; 		beq	.loop3
; 		move.w	#4,(RAM_MGame_Sfx).w
; .loop3:

; 		bra	.loop

; 	; Exit
; 		tst.w	(RAM_Tite_PickOpt).w
; 		beq	.loop
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyA,d7
		beq	.loop
; 		bsr	.fade_out
; 		bsr	Debug_PickSetting
; 		move.w	#$2700,sr
		move.w	#0,(RAM_Glbl_Scrn).w
		rts

.sfx_draw:
		lea	str_TitlDrwID(pc),a0	; Print menu
		move.l	#locate(0,10,5),d0
		bra	Video_Print

.gema_test:
		move.w	(RAM_Tite_UsrOpt_T),d0
		add.w	d0,d0
		move.w	.list(pc,d0.w),d0
		jmp	.list(pc,d0.w)
.list:
		dc.w .play-.list
		dc.w .stop-.list
		dc.w .stopall-.list
		dc.w .null-.list
		dc.w .null-.list
		dc.w .null-.list
		dc.w .null-.list
.play:
		move.w	(RAM_Ttle_SFX).w,d0
		move.w	d0,d2
		move.w	d0,d1
		add.w	d1,d1
		move.w	.tempolist(pc,d1.w),d0
		bmi.s	.no_beats
		bsr	gemaSetBeats
.no_beats:
		move.w	d2,d0
		bra	gemaPlayTrack
.stop:
		move.w	(RAM_Ttle_SFX).w,d0
		bra	gemaStopTrack
.stopall:
		move.w	(RAM_Ttle_SFX).w,d0
		bra	gemaStopAll
.null:
		rts

; GLOBAL SUBBEATS FOR EACH TRACK.
; -1 = don't set
.tempolist:
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w 200+8
		dc.w -1
		dc.w 200+13 ; $0006
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1

		dc.w 200+32
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1
		dc.w -1

; ====================================================================
; ----------------------------------------------
; common subs
; ----------------------------------------------

.fade_in:
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#1,(RAM_FadeMarsIncr).w
		move.w	#2,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		bra.s	.loop2

.fade_out:
		move.w	#2,(RAM_FadeMdReq).w
		move.w	#2,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#1,(RAM_FadeMarsIncr).w
		move.w	#2,(RAM_FadeMdDelay).w
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

; ------------------------------------------------
; Animate title
; ------------------------------------------------

Debug_AnimateFg:
; 		lea	(RAM_HorScroll),a5
; 		move.w	#224-1,d7
; 		move.w	(RAM_Ttle_HorBg).w,d4
; 		lsr.w	#2,d4
; 		neg.w	d4
; .hnextfg:
; 		move.w	d4,2(a5)
; 		adda	#4,a5
; 		dbf	d7,.hnextfg

		lea	(RAM_HorScroll),a5
		move.w	#SET_MENUTOPLINE-1,d7
		move.w	(RAM_Ttle_HorVal).w,d4
.hnext:
		move.w	d4,d0
		bsr	System_SineWave
		asr.l	#8,d2
		asr.l	#7,d2
		move.w	d2,(a5)
		adda	#4,a5
		move.w	(RAM_Ttle_SpdUsr).w,d5
		lsr.w	#1,d5
		add.w	d5,d4
; 		add.w	#2,d4
		dbf	d7,.hnext
;
		lea	(RAM_VerScroll),a5
		move.w	#(320/16)-1,d7
		move.w	(RAM_Ttle_VerVal).w,d4
.vnext:
		move.w	d4,d0
		bsr	System_SineWave
		asr.l	#8,d2
		asr.l	#7,d2
		neg.w	d2
		move.w	d2,(a5)
		adda	#4,a5
		add.w	(RAM_Ttle_SpdUsr).w,d4
; 		add.w	#2,d4
		dbf	d7,.vnext
		move.w	(RAM_Ttle_SpdUsr).w,d7
		add.w	d7,(RAM_Ttle_VerVal).w
		add.w	d7,(RAM_Ttle_HorVal).w
		rts

Debug_PrintCursor:
		move.l	#locate(0,2,6),d1
		lea	str_Cursor(pc),a0
; 		btst	#0,(RAM_Tite_PickOpt+1).w
; 		beq.s	.nocur_0
; 		lea	str_CursorOut(pc),a0
; .nocur_0:
		moveq	#0,d0
		move.w	(RAM_Tite_UsrOpt_T).w,d0
		add.l	d1,d0
		bra	Video_Print

; 		move.l	#locate(0,2,16+1),d1
; 		lea	str_Cursor(pc),a0
; 		btst	#0,(RAM_Tite_PickOpt+1).w
; 		bne.s	.nocur_1
; 		lea	str_CursorOut(pc),a0
; .nocur_1:
; 		moveq	#0,d0
; 		move.w	(RAM_Tite_UsrOpt_B).w,d0
; 		add.l	d1,d0
; 		bra	Video_Print

; ====================================================================
; ------------------------------------------------------
; VBlank
; ------------------------------------------------------

; ------------------------------------------------------
; HBlank
; ------------------------------------------------------

HInt_Title:
		move.w	#$2700,sr
		move.l	#$40000010,(vdp_ctrl).l
	rept (320/16)
		move.l	#0,(vdp_data).l
	endm

; 	; Third 2cell is cursor
; 		move.w	#0,(vdp_data).l
; 		move.w	(RAM_Tite_VerBgMenu),(vdp_data).l
; 		move.w	#0,(vdp_data).l
; 		move.w	(RAM_Tite_VerBgMenu),(vdp_data).l
; 		move.w	(RAM_Tite_VerBot),(vdp_data).l
; 		move.w	(RAM_Tite_VerBgMenu),(vdp_data).l
; 	rept (320/16)
; 		move.w	#0,(vdp_data).l
; 		move.w	(RAM_Tite_VerBgMenu),(vdp_data).l
; 	endm
		rte

; ====================================================================
; ------------------------------------------------------
; Objects
; ------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; Small data
; ----------------------------------------------------------------

str_TitleS:	dc.b "GEMA/Nikona sound driver",0
		align 2
str_TitleSfx:	dc.b "TrackID",$A
		dc.b $A
		dc.b "  gemaPlayTrack",$A
		dc.b "  gemaStopTrack",$A
		dc.b "  gemaStopAll",$A
		dc.b "  ????",$A
		dc.b "  ????",$A
		dc.b "  ????",$A
		dc.b "  ????",0
		align 2
str_TitlDrwID:	dc.b "\\w",0
		dc.l RAM_Ttle_SFX
		align 2

str_CursorOut:	dc.b " ",$A
		dc.b " ",$A
		dc.b " ",0
		align 2
str_Cursor:	dc.b " ",$A
		dc.b ">",$A
		dc.b " ",0
		align 2

; ====================================================================
