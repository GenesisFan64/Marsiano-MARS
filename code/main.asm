; ====================================================================
; ----------------------------------------------------------------
; Default gamemode
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

emily_VRAM	equ $380

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
RAM_EmiFrame	ds.w 1
RAM_EmiAnim	ds.w 1
RAM_EmiPosX	ds.w 1
RAM_EmiPosY	ds.w 1
RAM_EmiUpd	ds.w 1
		finish

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

MD_Mode0:
; 		bra	MD_Mode1

		move.w	#$2700,sr
		bclr	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update
		bsr	Mode_Init
		bsr	Video_PrintInit

		lea	str_Main(pc),a0
		move.l	#locate(0,2,2),d0
		bsr	Video_Print

		lea	Pal_Emily(pc),a0
		moveq	#0,d0
		move.w	#16,d1
		bsr	Video_FadePal
; 		lea	Pal_TestMap(pc),a0
; 		moveq	#$10,d0
; 		move.w	#16,d1
; 		bsr	Video_FadePal

; 		move.l	#Art_TestMap,d0
; 		move.w	#$20*$0001,d1
; 		move.w	#Art_TestMap_e-Art_TestMap,d2
; 		bsr	Video_LoadArt
; 		lea	(Map_TestMap),a0
; 		move.l	#locate(0,0,0),d0
; 		move.l	#mapsize(512,256),d1
; 		move.w	#$2000|$0001,d2
; 		bsr	Video_LoadMap

; 		lea	(RAM_MdDreq+Dreq_Objects),a0
; 		move.l	#MarsObj_test,mdl_data(a0)
; 		move.l	#-$600,mdl_z_pos(a0)
; 		move.w	#4,d0
; 		bsr	Video_MarsSetGfx
; 		lea	(MDLDATA_PAL_TEST),a0
; 		moveq	#0,d0
; 		move.w	#256,d1
; 		moveq	#1,d2
; 		bsr	Video_FadePal_Mars
; 		clr.w	(RAM_MdMarsPalFd).w

	; variables
		move.w	#(320/2)+16,(RAM_EmiPosX).w
		move.w	#(224/2)+8,(RAM_EmiPosY).w

		lea	(GemaTrkData_Test),a0
		moveq	#0,d0
		moveq	#2,d1
		moveq	#0,d2
		moveq	#0,d3
		bsr	Sound_TrkPlay
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#4,(RAM_FadeMarsIncr).w
		move.w	#0,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l
		move.b	#%000,(RAM_VdpRegs+$B).l
		move.b	#$10,(RAM_VdpRegs+7).l
		bsr	Video_Update

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
; 		bsr	System_MarsUpdate
		bsr	System_WaitFrame
		bsr	Video_RunFade
		bne.s	.loop


	; Move Emily Fujiwara
	; UDLR
		move.w	(Controller_1+on_hold),d7
		move.w	d7,d6
		btst	#bitJoyDown,d7
		beq.s	.noz_down
		move.w	#0,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w
		add.w	#1,(RAM_EmiPosY).w
.noz_down:
		move.w	d7,d6
		btst	#bitJoyUp,d6
		beq.s	.noz_up
		move.w	#4,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w
		add.w	#-1,(RAM_EmiPosY).w
.noz_up:
		move.w	d7,d6
		btst	#bitJoyRight,d6
		beq.s	.noz_r
		move.w	#8,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w
		add.w	#1,(RAM_EmiPosX).w
.noz_r:
		move.w	d7,d6
		btst	#bitJoyLeft,d6
		beq.s	.noz_l
		move.w	#$C,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w
		add.w	#-1,(RAM_EmiPosX).w
.noz_l:
		bsr	Emilie_MkSprite

		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq	.loop
		bra	MD_Mode1

; ====================================================================
; ----------------------------------------------
; common subs
; ----------------------------------------------

.fade_in:
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#4,(RAM_FadeMarsIncr).w
		move.w	#0,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		rts

.fade_out:
		move.w	#2,(RAM_FadeMdReq).w
		move.w	#2,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#4,(RAM_FadeMarsIncr).w
		move.w	#0,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		rts


; 		lea	(MDLDATA_PAL_TEST),a0
; 		cmp.w	#4,(RAM_CurrGfx).w
; 		beq.s	.thispal
; 		lea	(PalData_Mars_Test2),a0
; 		cmp.w	#3,(RAM_CurrGfx).w
; 		beq.s	.thispal
; 		lea	(PalData_Mars_Test),a0
; .thispal:
; 		moveq	#0,d0
; 		move.w	#256,d1
; 		moveq	#0,d2
; 		bsr	Video_FadePal_Mars
; 		move.w	#1,(RAM_FadeMdReq).w		; FadeIn request on both sides
; 		move.w	#1,(RAM_FadeMarsReq).w
; 		move.w	#1,(RAM_FadeMdIncr).w
; 		move.w	#4,(RAM_FadeMarsIncr).w
; 		move.w	#2,(RAM_FadeMdDelay).w
; 		move.w	#2,(RAM_FadeMarsDelay).w
; 		move.w	(RAM_CurrGfx).w,d0
; 		bsr	Video_MarsSetGfx
; .page0_loop:
; ; 		bsr	Emilie_MkSprite
; 		bsr	Video_RunFade
; 		bne	.loop
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyStart,d7
; 		beq.s	.no_mode0
; 		move.w	#1,(RAM_CurrPage).w
; 		move.w	#$920D,(RAM_WindowNew).w
; .no_mode0:
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyZ,d7
; 		beq.s	.noah
; 		moveq	#0,d2
; 		bsr	PlayThisSfx
; .noah:
;
; 		move.l	(RAM_MdDreq+Dreq_BgEx_X).w,d0
; 		move.l	(RAM_MdDreq+Dreq_BgEx_Y).w,d1
; 		move.l	#$10000,d5
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
; 		move.l	d0,(RAM_MdDreq+Dreq_BgEx_X).w
; 		move.l	d1,(RAM_MdDreq+Dreq_BgEx_Y).w
;
; 		move.l	#0,d0
; 		move.l	#0,d1
; 		moveq	#0,d2
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyB,d7
; 		beq.s	.nor_m2
; 		add.w	#1,(RAM_CurrGfx).w
; 		moveq	#1,d2
; .nor_m2:
; 		btst	#bitJoyA,d7
; 		beq.s	.nol_m2
; 		sub.w	#1,(RAM_CurrGfx).w
; 		moveq	#1,d2
; .nol_m2:
;
; 		tst.w	d2
; 		beq.s	.no_chng
;
; 		move.w	#2,(RAM_FadeMdReq).w		; FadeIn request on both sides
; 		move.w	#2,(RAM_FadeMarsReq).w
; 		move.w	#1,(RAM_FadeMdIncr).w
; 		move.w	#4,(RAM_FadeMarsIncr).w
; 		move.w	#2,(RAM_FadeMdDelay).w
; 		move.w	#2,(RAM_FadeMarsDelay).w
; .fadeout:
; 		bsr	Video_RunFade
; 		beq.s	.exit
; 		bsr	System_WaitFrame
; 		lea	(RAM_MdDreq),a0
; 		move.w	#sizeof_dreq,d0
; 		bsr	System_SendDreq
; 		bra.s	.fadeout
; .exit
; 		move.w	#0,(RAM_CurrPage).w
; ; .thispal:
; ; 		moveq	#0,d2
; ; 		moveq	#0,d0
; ; 		move.w	#256,d1
; ; 		bsr	Video_LoadPal_Mars
; ; 		clr.w	(RAM_MdDreq+Dreq_Palette).w
; .no_chng:
; 		bsr	.move_model



; 		lea	(RAM_MdDreq),a0
; 		move.l	Dreq_SclX(a0),d0
; 		move.l	Dreq_SclY(a0),d1
; 		move.l	Dreq_SclDX(a0),d2
; 		move.l	Dreq_SclDY(a0),d3
; 		move.l	#$100,d4
; 		move.l	#$200,d5
;
; 		move.w	(Controller_1+on_hold),d7
; 		move.w	d7,d6
; 		btst	#bitJoyDown,d7
; 		beq.s	.noz_down
; 		add.l	d4,d1
; 		sub.l	d5,d3
; .noz_down:
; 		move.w	d7,d6
; 		btst	#bitJoyUp,d6
; 		beq.s	.noz_up
; 		sub.l	d4,d1
; 		add.l	d5,d3
; .noz_up:
; 		move.w	d7,d6
; 		btst	#bitJoyRight,d6
; 		beq.s	.noz_r
; 		add.l	d4,d0
; 		sub.l	d5,d2
; .noz_r:
; 		move.w	d7,d6
; 		btst	#bitJoyLeft,d6
; 		beq.s	.noz_l
; 		sub.l	d4,d0
; 		add.l	d5,d2
; .noz_l:
; 		move.l	d0,Dreq_SclX(a0)
; 		move.l	d1,Dreq_SclY(a0)
; 		move.l	d2,Dreq_SclDX(a0)
; 		move.l	d3,Dreq_SclDY(a0)
;
; 		move.w	d7,d6
; 		btst	#bitJoyX,d6
; 		beq.s	.nox_x
; 		lea	(RAM_MdDreq+Dreq_SclX),a0
; 		move.l	#$00000000,(a0)+	; X pos
; 		move.l	#$00000000,(a0)+	; Y pos
; 		move.l	#$00010000,(a0)+	; DX
; 		move.l	#$00010000,(a0)+	; DY
; .nox_x:


; 		move.w	d7,d6
; 		btst	#bitJoyY,d6
; 		beq.s	.noy
; 		move.l	Dreq_SclDX(a0),d0
; 		move.l	Dreq_SclDY(a0),d1
; 		move.l	#$100,d2
; 		add.l	d2,d0
; 		add.l	d2,d1
; 		move.l	d0,Dreq_SclDX(a0)
; 		move.l	d1,Dreq_SclDY(a0)
; .noy:

; 		bsr	Emilie_Move
; 		bsr	.wave_backgrnd
		rts

; .wave_backgrnd:
; 	; wave background
; 		lea	(RAM_HorScroll),a0
; 		moveq	#112-1,d7
; 		move.w	(RAM_WaveTmr),d0
; 		move.w	#8,d1
; .next:
; 		bsr	System_SineWave
; 		lsr.l	#8,d2
; 		move.w	d2,2(a0)
; 		adda	#4,a0
; 		add.w	#1,d0
; 		bsr	System_SineWave
; 		lsr.l	#8,d2
; 		move.w	d2,2(a0)
; 		adda	#4,a0
; 		add.w	#1,d0
; 		dbf	d7,.next
; 		add.w	#1,(RAM_WaveTmr).w
;
; 		lea	(RAM_VerScroll),a0
; 		moveq	#(320/16)-1,d7
; 		move.w	(RAM_WaveTmr),d0
; 		move.w	#6,d1
; .next2:
; 		bsr	System_SineWave_Cos
; 		lsr.l	#8,d2
; 		move.w	d2,2(a0)
; 		adda	#4,a0
; 		add.w	#4,d0
; 		dbf	d7,.next2
; 		add.w	#1,(RAM_WaveTmr2).w
;
; ; 		bsr	Emilie_Move
; ; 		bsr	Emilie_MkSprite
; 		rts
;
; ; --------------------------------------------------
; ; Mode 1
; ; --------------------------------------------------
;
; .mode1:
; 		tst.w	(RAM_CurrPage).w
; 		bmi	.mode1_loop
; 		or.w	#$8000,(RAM_CurrPage).w
; 		bsr	.print_cursor
; ; 		move.w	#1,(RAM_EmiHide).w
; ; 		move.w	#1,(RAM_EmiUpd).w
;
; .mode1_loop:
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyStart,d7
; 		beq.s	.no_mode1
; 		move.w	#0,(RAM_CurrPage).w
; 		move.w	#$9200,(RAM_WindowNew).w
; .no_mode1:
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyY,d7
; 		beq.s	.noy2
; 		cmp.w	#1,(RAM_CurrIndx).w
; 		beq.	.noy2
; 		add.w	#1,(RAM_CurrIndx).w
; 		bsr	.print_cursor
; .noy2:
; 		move.w	(Controller_1+on_hold),d7
; 		btst	#bitJoyX,d7
; 		beq.s	.nox2
; 		tst.w	(RAM_CurrIndx).w
; 		beq.s	.nox2
; 		sub.w	#1,(RAM_CurrIndx).w
; 		bsr	.print_cursor
; .nox2:
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyUp,d7
; 		beq.s	.nou2
; 		tst.w	(RAM_CurrSelc).w
; 		beq.s	.nou2
; 		sub.w	#1,(RAM_CurrSelc).w
; 		bsr	.print_cursor
; .nou2:
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyDown,d7
; 		beq.s	.nod2
; 		cmp.w	#MAX_GEMAENTRY,(RAM_CurrSelc).w
; 		bge.s	.nod2
; 		add.w	#1,(RAM_CurrSelc).w
; 		bsr	.print_cursor
; .nod2:
;
; 	; LEFT/RIGHT
; 		lea	(RAM_CurrTrack),a1
; 		cmp.w	#3,(RAM_CurrSelc).w
; 		bne.s	.toptrk
; 		add	#2,a1
; .toptrk:
; 		cmp.w	#4,(RAM_CurrSelc).w
; 		bne.s	.toptrk2
; 		add	#2*2,a1
; .toptrk2:
;
; 		move.w	(Controller_1+on_hold),d7
; 		and.w	#JoyB,d7
; 		beq.s	.noba
; 		add.w	#1,(a1)
; 		bsr	.print_cursor
; .noba:
; 		move.w	(Controller_1+on_hold),d7
; 		and.w	#JoyA,d7
; 		beq.s	.noaa
; 		sub.w	#1,(a1)
; 		bsr	.print_cursor
; .noaa:
;
;
;
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyLeft,d7
; 		beq.s	.nol
; ; 		tst.w	(a1)
; ; 		beq.s	.nol
; 		sub.w	#1,(a1)
; 		bsr	.print_cursor
; .nol:
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyRight,d7
; 		beq.s	.nor
; ; 		cmp.w	#MAX_TSTTRKS,(a1)
; ; 		bge.s	.nor
; 		add.w	#1,(a1)
; 		bsr	.print_cursor
; .nor:
;
; 		move.w	(Controller_1+on_press),d7
; 		and.w	#JoyC,d7
; 		beq.s	.noc_c
; 		move.w	(RAM_CurrIndx).w,d0
; 		bsr	.procs_task
; .noc_c:
;
; ; 		bsr	.wave_backgrnd
; ; 		lea	str_COMM(pc),a0
; ; 		move.l	#locate(0,2,9),d0
; ; 		bsr	Video_Print
; ; 		rts
;
; .move_model:
; 		lea	(RAM_MdDreq+Dreq_Objects),a0
; 		add.l	#$4000,mdl_x_rot(a0)
; ; 		add.l	#$1000,mdl_z_rot(a0)
; 		rts
;
; ; --------------------------------------------------
;
; .print_cursor:
; ; 		lea	str_Status(pc),a0
; ; 		move.l	#locate(2,20,4),d0
; ; 		bsr	Video_Print
; 		lea	str_Cursor(pc),a0
; 		moveq	#0,d0
; 		move.w	(RAM_CurrSelc).w,d0
; 		add.l	#locate(2,2,5),d0
; 		bsr	Video_Print
; 		rts
;
; ; d1 - Track slot
; .procs_task:
; 		move.w	(RAM_CurrSelc).w,d7
; 		add.w	d7,d7
; 		move.w	.tasklist(pc,d7.w),d7
; 		jmp	.tasklist(pc,d7.w)
; .tasklist:
; 		dc.w .task_00-.tasklist
; 		dc.w .task_01-.tasklist
; 		dc.w .task_02-.tasklist
; 		dc.w .task_03-.tasklist
; 		dc.w .task_04-.tasklist
; ; 		dc.w .task_05-.tasklist
;
; ; d0 - Track slot
; .task_00:
; 		lea	MasterTrkList(pc),a0
; 		move.w	(RAM_CurrTrack).w,d7
; 		lsl.w	#4,d7
; 		lea	(a0,d7.w),a0
; 		move.w	$C(a0),d1
; 		moveq	#0,d2
; 		move.w	$E(a0),d3
; 		bra	Sound_TrkPlay
; .task_01:
; 		bra	Sound_TrkStop
; .task_02:
; 		bra	Sound_TrkResume
; .task_03:
; 		move.w	(RAM_CurrTicks).w,d1
; 		bra	Sound_TrkTicks
; .task_04:
; 		move.w	(RAM_CurrTempo).w,d1
; 		bra	Sound_GlbTempo
;
;
; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------
;
; ; d2 - BLOCK
; PlayThisSfx:
; 		lea	(GemaTrkData_Sfx),a0
; 		moveq	#1,d0
; 		moveq	#6,d1
; ; 		moveq	#0,d2
; 		moveq	#0,d3
; 		bra	Sound_TrkPlay
;
;
; Emilie_Move:
;
; 		lea	(Controller_2),a0
; 		move.b	(a0),d0
; 		cmp.b	#$03,d0
; 		bne.s	.not_mouse
;
; 		move.w	#320,d2
; 		move.w	(RAM_EmiPosX).w,d1
; 		move.w	mouse_x(a0),d0
; 		muls.w	#$0E,d0
; 		asr.w	#4,d0
; 		add.w	d0,d1
; 		or.w	d1,d1
; 		bpl.s	.left_x
; 		clr.w	d1
; .left_x:
; 		cmp.w	d2,d1
; 		blt.s	.right_x
; 		move.w	d2,d1
; .right_x:
; 		move.w	d1,(RAM_EmiPosX).w
;
; 		move.w	#224,d2
; 		move.w	(RAM_EmiPosY).w,d1
; 		move.w	mouse_Y(a0),d0
; 		muls.w	#$0E,d0
; 		asr.w	#4,d0
; 		add.w	d0,d1
; 		or.w	d1,d1
; 		bpl.s	.left_y
; 		clr.w	d1
; .left_y:
; 		cmp.w	d2,d1
; 		blt.s	.right_y
; 		move.w	d2,d1
; .right_y:
; 		move.w	d1,(RAM_EmiPosY).w
;
; .not_mouse:
; 		rts
;
Emilie_MkSprite:
		lea	(RAM_Sprites),a6
		move.l	(RAM_EmiPosY),d0
		move.l	(RAM_EmiPosX),d1
		swap	d0
		swap	d1
		add.w	#$80+32,d0
		add.w	#$80+32,d1
		move.w	(RAM_EmiAnim),d2
		lsr.w	#3,d2
		and.w	#%11,d2
		move.w	(RAM_EmiFrame),d3
		add.w	d3,d2
		add.w	d2,d2
		lea	Map_Nicole(pc),a0
		move.w	(a0,d2.w),d2
		adda	d2,a0
		move.b	(a0)+,d4
		and.w	#$FF,d4
		sub.w	#1,d4
		move.w	#$0001,d5
		move.w	#emily_VRAM,d6
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
		and.w	#%11,d2
		move.w	(RAM_EmiFrame),d3
		add.w	d3,d2
		add.w	d2,d2
		lea	Dplc_Nicole(pc),a0
		move.w	(a0,d2.w),d2
		adda	d2,a0
		move.w	(a0)+,d4
		and.w	#$FF,d4
		sub.w	#1,d4
		move.w	#emily_VRAM,d5


	; d0 - graphics
	; d5 - VRAM OUTPUT
		lsl.w	#5,d5
		moveq	#0,d1
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
		bsr	Video_DmaMkEntry
		add.w	d3,d5
		dbf	d4,.nxt_dpz
.no_upd:
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

; PAL_TESTBOARD:
; 		binclude "data/md/bg/bg_pal.bin"
; 		binclude "data/md/bg/fg_pal.bin"
; 		align 2
Pal_Emily:
		dc.w 0
		binclude "data/md/sprites/emi_pal.bin",2
		align 2
; Pal_TestMap:
; 		binclude "data/md/bg/test_pal.bin"
; 		align 2
; Map_TestMap:
; 		binclude "data/md/bg/test_map.bin"
; 		align 2

Map_Nicole:
		include "data/md/sprites/emi_map.asm"
		align 2
Dplc_Nicole:
		include "data/md/sprites/emi_plc.asm"
		align 2

str_Main:
		dc.b "Main screen",0
		align 2
