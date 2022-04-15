; ====================================================================
; ----------------------------------------------------------------
; Default gamemode
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

set_StartPage	equ	0
MAX_PAGE0_EN	equ	4
MAX_GEMAENTRY	equ	4

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
RAM_CurrPage	ds.w 1
RAM_CurrGfx	ds.w 1
RAM_CurrSelc	ds.w 1
RAM_CurrIndx	ds.w 1
RAM_CurrTrack	ds.w 1
RAM_CurrTicks	ds.w 1
RAM_CurrTempo	ds.w 1
		finish

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

MD_Mode1:
		move.w	#$2700,sr
		bsr	Mode_FadeOut
		bsr	Mode_Init

		moveq	#0,d0
		bsr	Sound_TrkStop
		moveq	#1,d0
		bsr	Sound_TrkStop
		clr.w	(RAM_PaletteFd).w

		bclr	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update
		move.w	#set_StartPage,(RAM_CurrPage).w
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l
		move.b	#%111,(RAM_VdpRegs+$B).l
		move.b	#0,(RAM_VdpRegs+7).l
		bsr	Video_Update

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	System_WaitFrame
		bsr	System_MarsUpdate
		bsr	Video_RunFade
		bne.s	.loop

		move.w	(RAM_CurrPage).w,d0
		and.w	#%11111,d0
		add.w	d0,d0
		add.w	d0,d0
		add.w	d0,d0
		tst.w	(RAM_CurrPage).w
		bmi.s	.on_loop
		add.l	#4,d0
.on_loop:
		jsr	.list(pc,d0.w)
		bra	.loop

; ====================================================================
; ------------------------------------------------------
; Mode sections
; ------------------------------------------------------

.list:
		bra.w	.page0
		bra.w	.page0_init

		bra.w	.page1
		bra.w	.page1_init

		bra.w	.page2
		bra.w	.page2_init

		bra.w	.page3
		bra.w	.page3_init

		bra.w	.page4
		bra.w	.page4_init

		bra.w	.page5
		bra.w	.page5_init

		bra.w	.page0
		bra.w	.page0_init

; ====================================================================
; --------------------------------------------------
; Page 0
; --------------------------------------------------

.page0_ret:
		rts
.page0_init:
		bsr	Video_ClearScreen
		bsr	Video_PrintInit
		or.w	#$8000,(RAM_CurrPage).w
		clr.w	(RAM_CurrSelc).w

		move.w	#0,d0
		bsr	Video_MarsSetGfx
		lea	str_Title(pc),a0	; Print menu
		move.l	#locate(0,2,2),d0
		bsr	Video_Print
		bsr	.page0_cursor
		bsr	.fade_in

.page0:
		lea	str_StatsPage0(pc),a0
		move.l	#locate(0,2,10),d0
		bsr	Video_Print

		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		bne.s	.page0_jump
		moveq	#MAX_PAGE0_EN,d0			; Numof entries
		bsr	.move_cursor_ud		; Move U/D
		beq	.page0_ret
.page0_cursor:
		move.l	#locate(0,2,3),d1
		bra	.print_cursor
.page0_jump:
		bsr	.fade_out
		move.w	(RAM_CurrSelc).w,d0
		add.w	#1,d0
		move.w	d0,(RAM_CurrPage).w
		rts

; ====================================================================
; --------------------------------------------------
; Page 1
; --------------------------------------------------

.page1_init:
		bsr	Video_ClearScreen
		or.w	#$8000,(RAM_CurrPage).w
		clr.w	(RAM_CurrSelc).w

		lea	(RAM_MdDreq),a0
		move.l	#TESTMARS_DIRECT|TH,Dreq_Scrn1_Data(a0)
		bsr	System_MarsUpdate

		lea	str_Page1(pc),a0	; Print text
		move.l	#locate(0,2,2),d0
		bsr	Video_Print
		move.w	#1,d0
		bsr	Video_MarsSetGfx
		bsr	.fade_in
.page1:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq.s	.page1_ret
		move.w	#0,(RAM_CurrPage).w
		bsr	.fade_out
.page1_ret:
		rts

; ====================================================================
; --------------------------------------------------
; Page 2
; --------------------------------------------------

.page2_init:
		bsr	Video_ClearScreen
		or.w	#$8000,(RAM_CurrPage).w
		clr.w	(RAM_CurrSelc).w

		lea	str_Page2(pc),a0	; Print text
		move.l	#locate(0,2,2),d0
		bsr	Video_Print

		lea	(RAM_MdDreq),a0
		move.l	#TESTMARS_BG,Dreq_BgEx_Data(a0)
		move.l	#1152,Dreq_BgEx_W(a0)
		move.l	#368,Dreq_BgEx_H(a0)
		move.l	#$00000000,Dreq_BgEx_X(a0)
		move.l	#$00900000,Dreq_BgEx_Y(a0)
		bsr	System_MarsUpdate

		move.l	#ART_FGTEST,d0
		move.w	#$280*$20,d1
		move.w	#ART_FGTEST_e-ART_FGTEST,d2
		bsr	Video_LoadArt
		move.l	#ART_BGTEST,d0
		move.w	#1*$20,d1
		move.w	#ART_BGTEST_e-ART_BGTEST,d2
		bsr	Video_LoadArt
		lea	(MAP_FGTEST),a0
		move.l	#locate(0,0,0),d0
		move.l	#mapsize(512,256),d1
		move.w	#$2000+$0280,d2
		bsr	Video_LoadMap
		lea	(MAP_BGTEST),a0
		move.l	#locate(1,0,0),d0
		move.l	#mapsize(512,256),d1
		move.w	#$0001,d2
		bsr	Video_LoadMap
		move.w	#2,d0
		bsr	Video_MarsSetGfx
		lea	(PalData_Mars_Test),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#1,d2
		bsr	Video_FadePal_Mars
		lea	PAL_TESTBOARD(pc),a0
		moveq	#0,d0
		move.w	#$20,d1
		bsr	Video_FadePal
		clr.w	(RAM_MdMarsPalFd).w
		clr.w	(RAM_MdDreq+Dreq_Palette).w
		bsr	.this_bg
		bsr	.fade_in
.page2:
		bsr	.this_bg

		move.l	(RAM_MdDreq+Dreq_BgEx_X).w,d0
		move.l	(RAM_MdDreq+Dreq_BgEx_Y).w,d1
		move.l	#$20000,d5
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyRight,d7
		beq.s	.nor_m
		add.l	d5,d0
.nor_m:
		btst	#bitJoyLeft,d7
		beq.s	.nol_m
		sub.l	d5,d0
.nol_m:
		btst	#bitJoyDown,d7
		beq.s	.nod_m
		add.l	d5,d1
.nod_m:
		btst	#bitJoyUp,d7
		beq.s	.nou_m
		sub.l	d5,d1
.nou_m:
		move.l	d0,(RAM_MdDreq+Dreq_BgEx_X).w
		move.l	d1,(RAM_MdDreq+Dreq_BgEx_Y).w

; 		add.l	#$10000,(RAM_MdDreq+Dreq_BgEx_X).w

		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq.s	.page2_ret
		move.w	#0,(RAM_CurrPage).w
		bsr	.fade_out
.page2_ret:
		rts

.this_bg:
		move.l	(RAM_MdDreq+Dreq_BgEx_X).w,d0
		move.l	d0,d1
		swap	d0
		swap	d1
		lsr.l	#1,d0
		lsr.l	#2,d1
		neg.w	d0
		neg.w	d1
		lea	(RAM_HorScroll),a0
		move.w	#(224/2)-1,d7
.next:
		move.w	d0,(a0)+
		move.w	d1,(a0)+
		move.w	d0,(a0)+
		move.w	d1,(a0)+
		dbf	d7,.next
		rts

; ====================================================================
; --------------------------------------------------
; Page 3
; --------------------------------------------------

.page3_init:
		bsr	Video_ClearScreen
		or.w	#$8000,(RAM_CurrPage).w
		clr.w	(RAM_CurrSelc).w

		lea	(RAM_MdDreq),a0
		move.l	#TESTMARS_BG2|TH,Dreq_SclData(a0)
		move.l	#$00000000,Dreq_SclX(a0)	; X pos
		move.l	#$00000000,Dreq_SclY(a0)	; Y pos
		move.l	#$00010000,Dreq_SclDX(a0)	; DX
		move.l	#$00010000,Dreq_SclDY(a0)	; DY
		move.l	#320,Dreq_SclWidth(a0)
		move.l	#224,Dreq_SclHeight(a0)
		move.l	#0,Dreq_SclMode(a0)		;
		bsr	System_MarsUpdate

		lea	str_Page3(pc),a0	; Print text
		move.l	#locate(0,2,2),d0
		bsr	Video_Print
		move.w	#3,d0
		bsr	Video_MarsSetGfx
		lea	(PalData_Mars_Test2),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#0,d2
		bsr	Video_FadePal_Mars
		clr.w	(RAM_MdMarsPalFd).w
		clr.w	(RAM_MdDreq+Dreq_Palette).w
		bsr	.fade_in
.page3:
		lea	(RAM_MdDreq),a0
		move.l	Dreq_SclX(a0),d0
		move.l	Dreq_SclY(a0),d1
		move.l	Dreq_SclDX(a0),d2
		move.l	Dreq_SclDY(a0),d3
		move.l	#$400,d4
		move.l	#$400*2,d5

		move.w	(Controller_1+on_hold),d7
		move.w	d7,d6
		btst	#bitJoyDown,d7
		beq.s	.noz_down
		add.l	d4,d1
		sub.l	d5,d3
.noz_down:
		move.w	d7,d6
		btst	#bitJoyUp,d6
		beq.s	.noz_up
		sub.l	d4,d1
		add.l	d5,d3
.noz_up:
		move.w	d7,d6
		btst	#bitJoyRight,d6
		beq.s	.noz_r
		add.l	d4,d0
		sub.l	d5,d2
.noz_r:
		move.w	d7,d6
		btst	#bitJoyLeft,d6
		beq.s	.noz_l
		sub.l	d4,d0
		add.l	d5,d2
.noz_l:
		move.l	d0,Dreq_SclX(a0)
		move.l	d1,Dreq_SclY(a0)
		move.l	d2,Dreq_SclDX(a0)
		move.l	d3,Dreq_SclDY(a0)

		move.w	d7,d6
		btst	#bitJoyX,d6
		beq.s	.nox_x
		lea	(RAM_MdDreq+Dreq_SclX),a0
		move.l	#$00000000,(a0)+	; X pos
		move.l	#$00000000,(a0)+	; Y pos
		move.l	#$00010000,(a0)+	; DX
		move.l	#$00010000,(a0)+	; DY
.nox_x:

		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq.s	.page3_ret
		move.w	#0,(RAM_CurrPage).w
		bsr	.fade_out
.page3_ret:
		rts

; ====================================================================
; --------------------------------------------------
; Page 4
; --------------------------------------------------

.page4_init:
		bsr	Video_ClearScreen
		or.w	#$8000,(RAM_CurrPage).w
		clr.w	(RAM_CurrSelc).w

		lea	(RAM_MdDreq+Dreq_Objects),a0
		move.l	#MarsObj_test,mdl_data(a0)
		move.l	#-$600,mdl_z_pos(a0)
; 		move.l	#$4000,mdl_y_pos(a0)
		bsr	System_MarsUpdate

		lea	str_Page4(pc),a0	; Print text
		move.l	#locate(0,2,2),d0
		bsr	Video_Print

		move.w	#4,d0
		bsr	Video_MarsSetGfx
		lea	(MDLDATA_PAL_TEST),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#0,d2
		bsr	Video_FadePal_Mars

		bsr	.fade_in
.page4:
		lea	str_StatsPage0(pc),a0
		move.l	#locate(0,2,4),d0
		bsr	Video_Print

		lea	(RAM_MdDreq+Dreq_Objects),a0
		add.l	#$4000,mdl_x_rot(a0)
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq.s	.page4_ret
		move.w	#0,(RAM_CurrPage).w
		bsr	.fade_out
.page4_ret:
		rts

; ====================================================================
; --------------------------------------------------
; Page 5
; --------------------------------------------------

.page5_init:
		bsr	Video_ClearScreen
		or.w	#$8000,(RAM_CurrPage).w
		clr.w	(RAM_CurrSelc).w

; 		move.l	#ART_FGTEST,d0
; 		move.w	#$280*$20,d1
; 		move.w	#ART_FGTEST_e-ART_FGTEST,d2
; 		bsr	Video_LoadArt
; 		move.l	#ART_BGTEST,d0
; 		move.w	#1*$20,d1
; 		move.w	#ART_BGTEST_e-ART_BGTEST,d2
; 		bsr	Video_LoadArt
; 		lea	(MAP_FGTEST),a0
; 		move.l	#locate(0,0,0),d0
; 		move.l	#mapsize(512,256),d1
; 		move.w	#$2000+$0280,d2
; 		bsr	Video_LoadMap
; 		lea	(MAP_BGTEST),a0
; 		move.l	#locate(1,0,0),d0
; 		move.l	#mapsize(512,256),d1
; 		move.w	#$0001,d2
; 		bsr	Video_LoadMap

		lea	str_Gema(pc),a0
		move.l	#locate(0,2,2),d0
		bsr	Video_Print
		move.w	#0,d0
		bsr	Video_MarsSetGfx
		bsr	.page5_update
		bsr	.fade_in
.page5:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyY,d7
		beq.s	.noy2
		cmp.w	#1,(RAM_CurrIndx).w
		beq.	.noy2
		add.w	#1,(RAM_CurrIndx).w
		bsr	.page5_update
.noy2:
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyX,d7
		beq.s	.nox2
		tst.w	(RAM_CurrIndx).w
		beq.s	.nox2
		sub.w	#1,(RAM_CurrIndx).w
		bsr	.page5_update
.nox2:

	; UP/DOWN
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyUp,d7
		beq.s	.nou2
		tst.w	(RAM_CurrSelc).w
		beq.s	.nou2
		sub.w	#1,(RAM_CurrSelc).w
		bsr	.page5_update
.nou2:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyDown,d7
		beq.s	.nod2
		cmp.w	#MAX_GEMAENTRY,(RAM_CurrSelc).w
		bge.s	.nod2
		add.w	#1,(RAM_CurrSelc).w
		bsr	.page5_update
.nod2:

; 	; LEFT/RIGHT
		lea	(RAM_CurrTrack),a1
		cmp.w	#3,(RAM_CurrSelc).w
		bne.s	.toptrk
		add	#2,a1
.toptrk:
		cmp.w	#4,(RAM_CurrSelc).w
		bne.s	.toptrk2
		add	#2*2,a1
.toptrk2:
		move.w	(Controller_1+on_hold),d7
		and.w	#JoyB,d7
		beq.s	.noba
		add.w	#1,(a1)
		bsr	.page5_update
.noba:
		move.w	(Controller_1+on_hold),d7
		and.w	#JoyA,d7
		beq.s	.noaa
		sub.w	#1,(a1)
		bsr	.page5_update
.noaa:

		move.w	(Controller_1+on_press),d7
		btst	#bitJoyLeft,d7
		beq.s	.nol
; 		tst.w	(a1)
; 		beq.s	.nol
		sub.w	#1,(a1)
		bsr	.page5_update
.nol:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyRight,d7
		beq.s	.nor
; 		cmp.w	#MAX_TSTTRKS,(a1)
; 		bge.s	.nor
		add.w	#1,(a1)
		bsr	.page5_update
.nor:

		move.w	(Controller_1+on_press),d7
		and.w	#JoyC,d7
		beq.s	.noc_c
		move.w	(RAM_CurrIndx).w,d0
		bsr	.procs_task
.noc_c:

		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq.s	.page5_ret
		move.w	#0,(RAM_CurrPage).w
		bsr	.fade_out
.page5_ret:
		rts

.page5_update:
		lea	str_Status(pc),a0
		move.l	#locate(0,20,4),d0
		bsr	Video_Print
		lea	str_Cursor(pc),a0
		moveq	#0,d0
		move.w	(RAM_CurrSelc).w,d0
		add.l	#locate(0,2,5),d0
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
		bra	Sound_GlbBeats

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

.print_cursor:
		lea	str_Cursor(pc),a0
		moveq	#0,d0
		move.w	(RAM_CurrSelc).w,d0
		add.l	d1,d0
		bsr	Video_Print
		rts

.move_cursor_ud:
		moveq	#0,d7
		move.w	(Controller_1+on_press),d6
		btst	#bitJoyUp,d6
		beq.s	.p0_down
		tst.w	(RAM_CurrSelc).w
		beq.s	.p0_down
		sub.w	#1,(RAM_CurrSelc).w
		moveq	#1,d7
.p0_down:
		btst	#bitJoyDown,d6
		beq.s	.p0_up
		move.w	(RAM_CurrSelc).w,d7
		cmp.w	d0,d7
		bge.s	.p0_up
		add.w	#1,(RAM_CurrSelc).w
		moveq	#1,d7
.p0_up:
		tst.w	d7
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

; 	; Move Emily Fujiwara
; 	; UDLR
; 		move.w	(Controller_1+on_hold),d7
; 		move.w	d7,d6
; 		btst	#bitJoyDown,d7
; 		beq.s	.noz_down
; 		move.w	#0,(RAM_EmiFrame).w
; 		add.w	#1,(RAM_EmiAnim).w
; 		add.w	#1,(RAM_EmiPosY).w
; .noz_down:
; 		move.w	d7,d6
; 		btst	#bitJoyUp,d6
; 		beq.s	.noz_up
; 		move.w	#4,(RAM_EmiFrame).w
; 		add.w	#1,(RAM_EmiAnim).w
; 		add.w	#-1,(RAM_EmiPosY).w
; .noz_up:
; 		move.w	d7,d6
; 		btst	#bitJoyRight,d6
; 		beq.s	.noz_r
; 		move.w	#8,(RAM_EmiFrame).w
; 		add.w	#1,(RAM_EmiAnim).w
; 		add.w	#1,(RAM_EmiPosX).w
; .noz_r:
; 		move.w	d7,d6
; 		btst	#bitJoyLeft,d6
; 		beq.s	.noz_l
; 		move.w	#$C,(RAM_EmiFrame).w
; 		add.w	#1,(RAM_EmiAnim).w
; 		add.w	#-1,(RAM_EmiPosX).w
; .noz_l:

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
; ; test playlist
MasterTrkList:
	dc.l GemaPat_Test,GemaBlk_Test,GemaIns_Test
	dc.w 3,%000
	dc.l GemaPat_Test2,GemaBlk_Test2,GemaIns_Test2
	dc.w 3,%001
	dc.l GemaPat_Test3,GemaBlk_Test3,GemaIns_Test3
	dc.w 3,%001

	align 2

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

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
		align 2

str_Title:
		dc.b "MARSIANO dev-menu",$A
		dc.b $A
		dc.b "  Pseudo-GFX mode 01",$A
		dc.b "  Pseudo-GFX mode 02",$A
		dc.b "  Pseudo-GFX mode 03",$A
		dc.b "  Pseudo-GFX mode 04",$A
		dc.b "  GEMA sound player",0
		align 2

; str_Page1:
; 		dc.b "Testing GfxMode 01",0
; 		align 2
; str_Page1_l:
; 		dc.b "\\l \\l",0
; 		dc.l RAM_MdDreq+Dreq_BgEx_X
; 		dc.l RAM_MdDreq+Dreq_BgEx_Y
; 		align 2

str_Page1:
		dc.b "Testing GfxMode 01",0
		align 2
str_Page2:
		dc.b "Testing GfxMode 02",0
		align 2
str_Page3:
		dc.b "Testing GfxMode 03",0
		align 2
str_Page4:
		dc.b "Testing model objects",0
		align 2
; str_Page4:	dc.b "GEMA",0
; 		align 2

;
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
str_StatsPage0:
		dc.b "\\w \\w \\w \\w",$A
		dc.b "\\w \\w \\w \\w",$A,$A
		dc.b "\\l",0
		dc.l sysmars_reg+comm0
		dc.l sysmars_reg+comm2
		dc.l sysmars_reg+comm4
		dc.l sysmars_reg+comm6
		dc.l sysmars_reg+comm8
		dc.l sysmars_reg+comm10
		dc.l sysmars_reg+comm12
		dc.l sysmars_reg+comm14
		dc.l RAM_Framecount
		align 2
;
; str_InfoMouse:
; 		dc.b "comm0: \\w",$A
; 		dc.b "comm12: \\w comm14: \\w",$A,$A
; ; 		dc.b "MD Framecount: \\l",$A
; 		dc.b "\\l \\l",$A
; 		dc.b "\\l \\l",0
; 		dc.l sysmars_reg+comm0
; 		dc.l sysmars_reg+comm12
; 		dc.l sysmars_reg+comm14
; ; 		dc.l RAM_Framecount
; 		dc.l RAM_MdDreq+Dreq_SclX
; 		dc.l RAM_MdDreq+Dreq_SclY
; 		dc.l RAM_MdDreq+Dreq_SclDX
; 		dc.l RAM_MdDreq+Dreq_SclDY
;
; ; 		dc.l RAM_MdDreq+Dreq_Objects+mdl_x_pos
; ; 		dc.l RAM_MdDreq+Dreq_Objects+mdl_y_pos
; ; 		dc.l RAM_MdDreq+Dreq_Objects+mdl_z_pos
; 		align 2

PAL_TESTBOARD:
		binclude "data/md/bg/bg_pal.bin"
		binclude "data/md/bg/fg_pal.bin"
		align 2
PAL_BG:
		binclude "data/md/bg/bg_pal.bin"
		align 2

; Map_Nicole:
; 		include "data/md/sprites/emi_map.asm"
; 		align 2
; Dplc_Nicole:
; 		include "data/md/sprites/emi_plc.asm"
; 		align 2

