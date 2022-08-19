; ====================================================================
; ----------------------------------------------------------------
; Default gamemode
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Variables
; ------------------------------------------------------

TEST_MAINSPD	equ $04
; emily_VRAM	equ $380

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
RAM_MapX	ds.l 1
RAM_MapY	ds.l 1
RAM_ThisSpeed	ds.l 1
RAM_EmiFrame	ds.w 1
RAM_EmiAnim	ds.w 1
RAM_EmiTimer	ds.w 1
		finish

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

MD_Mode0:
; 		bra	MD_DebugMenu

		move.w	#$2700,sr
		bclr	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update
		bsr	Mode_Init
		bsr	Video_PrintInit

	; 3D TEST
; 		lea	(RAM_MdDreq+Dreq_Objects),a0
; 		move.l	#MarsObj_test|TH,mdl_data(a0)
; 		move.w	#-$300,mdl_z_pos(a0)
; 		lea	str_Page4(pc),a0	; Print text
; 		move.l	#locate(0,2,2),d0
; 		bsr	Video_Print
; 		lea	(MDLDATA_PAL_TEST),a0
; 		moveq	#0,d0
; 		move.w	#256,d1
; 		moveq	#0,d2
; 		bsr	Video_FadePal_Mars
; 		clr.w	(RAM_PaletteFd).w		; <-- quick patch
; ; 		clr.w	(RAM_MdMarsPalFd).w
; 		and.w	#$7FFF,(RAM_MdMarsPalFd).w
; 		move.w	#3,d0
; 		bsr	Video_Mars_GfxMode

	; MAP TESTING
		move.l	#Art_level0,d0			; Genesis VDP graphics
		move.w	#1,d1
		move.w	#Art_level0_e-Art_level0,d2
		bsr	Video_LoadArt
		lea	(Pal_level0),a0			; 16-color palette
		moveq	#$10,d0
		move.w	#32,d1
		bsr	Video_FadePal
		lea	(MapPal_M),a0			; index-color palette
		moveq	#0,d0
		move.w	#128,d1
		moveq	#1,d2
		bsr	Video_FadePal_Mars
		lea	(TestSupSpr_Pal),a0
		move.w	#128,d0
		move.w	#128,d1
		moveq	#1,d2
		bsr	Video_FadePal_Mars
		clr.w	(RAM_PaletteFd).w		; <-- quick patch
		and.w	#$7FFF,(RAM_MdMarsPalFd).w
		move.l	#$10000,(RAM_ThisSpeed).l
		move.w	#0,(RAM_MapX).l
		move.w	#0,(RAM_MapY).l
		bsr	.update_pos
		bsr	MdMap_Init
		bsr	Level_PickMap
		bsr	SuperSpr_Init
		bsr	System_MarsUpdate		; Send first DREQ
		moveq	#2,d0
		bsr	Video_Mars_GfxMode
		bsr	MdMap_DrawAll

	; Testing track
		moveq	#0,d0
		bsr	Sound_TrkStop
		move.w	#200+32,d1
		bsr	Sound_GlbBeats
		lea	(GemaTrkData_Nadie_MARS),a0
; 		lea	(GemaTrkData_Nadie_MD),a0
		moveq	#0,d0
		move.w	#6,d1
		moveq	#0,d2
		move.w	#%01,d3
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

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	MdMap_Update
		bsr	System_WaitFrame
		bsr	Video_RunFade
		bne.s	.loop
;
; 		lea	str_Stats(pc),a0
; 		move.l	#locate(0,8,4),d0
; 		bsr	Video_Print
		lea	(RAM_MdDreq+Dreq_Objects),a0
		add.w	#8*2,mdl_x_rot(a0)
; 		add.w	#8*2,mdl_y_rot(a0)
; 		add.w	#8*5,mdl_z_rot(a0)
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyUp,d7
		beq.s	.z_up2
		sub.w	#$10,mdl_z_pos(a0)
.z_up2:
		btst	#bitJoyDown,d7
		beq.s	.z_dw2
		add.w	#$10,mdl_z_pos(a0)
.z_dw2:


		bsr	SuperSpr_Main
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyC,d7
		beq.s	.z_up
		add.l	#$10000,(RAM_ThisSpeed).l
		cmp.l	#$70000,(RAM_ThisSpeed).l
		ble.s	.z_up
		move.l	#$10000,(RAM_ThisSpeed).l
.z_up:

		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyB,d7
		bne.s	.not_hold3

		move.l	(RAM_ThisSpeed),d0
		move.l	(RAM_ThisSpeed),d1
		move.w	(Controller_1+on_hold),d7
		move.w	d7,d6
		btst	#bitJoyDown,d7
		beq.s	.noz_down
		move.w	#0,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w
		add.l	d1,(RAM_MapY).w
.noz_down:
		move.w	d7,d6
		btst	#bitJoyUp,d6
		beq.s	.noz_up
		move.w	#4,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w
		sub.l	d1,(RAM_MapY).w
.noz_up:
		move.w	d7,d6
		btst	#bitJoyRight,d6
		beq.s	.noz_r
		move.w	#8,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w
		add.l	d0,(RAM_MapX).w
.noz_r:
		move.w	d7,d6
		btst	#bitJoyLeft,d6
		beq.s	.noz_l
		move.w	#$C,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w
		sub.l	d0,(RAM_MapX).w
.noz_l:

		bsr.s	.update_pos
.not_hold3:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq	.loop
		bra	MD_DebugMenu


.update_pos:
		moveq	#-1,d0
		move.w	(RAM_MapX),d1
		move.w	(RAM_MapY),d2
		bsr	MdMap_Move
		moveq	#0,d0
		asr.w	#1,d1
		asr.w	#1,d2
		move.w	d1,(RAM_HorScroll).w
		move.w	d2,(RAM_VerScroll).w
		bsr	MdMap_Move
		moveq	#1,d0
		asr.w	#1,d1
		asr.w	#1,d2
		move.w	d1,(RAM_HorScroll+2).w
		move.w	d2,(RAM_VerScroll+2).w
		bsr	MdMap_Move
		neg.l	(RAM_HorScroll).w

; 		move.w	(RAM_MapX),d0
; 		move.w	(RAM_MapY),d1
; 		lea	(RAM_BgBufferM),a0
; 		move.w	d0,md_bg_x(a0)
; 		move.w	d1,md_bg_y(a0)
; 		lea	(RAM_BgBuffer),a0
; 		asr.w	#1,d0
; 		asr.w	#1,d1
; 		move.w	d0,md_bg_x(a0)
; 		move.w	d1,md_bg_y(a0)
; 		move.w	d0,(RAM_HorScroll).w
; 		move.w	d1,(RAM_VerScroll).w
; 		adda	#sizeof_mdbg,a0
; 		asr.w	#1,d0
; 		asr.w	#1,d1
; 		move.w	d0,md_bg_x(a0)
; 		move.w	d1,md_bg_y(a0)
; 		move.w	d0,(RAM_HorScroll+2).w
; 		move.w	d1,(RAM_VerScroll+2).w
; 		neg.l	(RAM_HorScroll).w
		rts

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

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

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
; 		and.w	#%11,d2
; 		move.w	(RAM_EmiFrame),d3
; 		add.w	d3,d2
; 		add.w	d2,d2
; 		lea	Map_Nicole(pc),a0
; 		move.w	(a0,d2.w),d2
; 		adda	d2,a0
; 		move.b	(a0)+,d4
; 		and.w	#$FF,d4
; 		sub.w	#1,d4
; 		move.w	#$0001,d5
; 		move.w	#emily_VRAM,d6
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
; 		and.w	#%11,d2
; 		move.w	(RAM_EmiFrame),d3
; 		add.w	d3,d2
; 		add.w	d2,d2
; 		lea	Dplc_Nicole(pc),a0
; 		move.w	(a0,d2.w),d2
; 		adda	d2,a0
; 		move.w	(a0)+,d4
; 		and.w	#$FF,d4
; 		sub.w	#1,d4
; 		move.w	#emily_VRAM,d5
;
;
; 	; d0 - graphics
; 	; d5 - VRAM OUTPUT
; 		lsl.w	#5,d5
; 		moveq	#0,d1
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
; 		bsr	Video_DmaMkEntry
; 		add.w	d3,d5
; 		dbf	d4,.nxt_dpz
; .no_upd:
; 		rts

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

SuperSpr_Init:
		lea	(RAM_MdDreq+Dreq_SuperSpr),a0
		move.l	#SuperSpr_Test,d0
		move.l	d0,d1
		or.l	#TH,d1
		move.l	d1,marsspr_data(a0)
		move.w	#64,marsspr_dwidth(a0)
		move.w	#$50,marsspr_x(a0)
		move.w	#$90,marsspr_y(a0)
		move.b	#32,marsspr_xs(a0)
		move.b	#48,marsspr_ys(a0)
		move.w	#$80,marsspr_indx(a0)

		move.l	#SuperSpr_Test,d0
		move.l	d0,d1
		or.l	#TH,d1
		adda	#sizeof_marsspr,a0
		move.l	d1,marsspr_data(a0)
		move.w	#64,marsspr_dwidth(a0)
		move.w	#$60,marsspr_x(a0)
		move.w	#$50,marsspr_y(a0)
		move.b	#32,marsspr_xs(a0)
		move.b	#48,marsspr_ys(a0)
		move.w	#$80,marsspr_indx(a0)

		move.l	#SuperSpr_Test,d0
		move.l	d0,d1
		or.l	#TH,d1
		adda	#sizeof_marsspr,a0
		move.l	d1,marsspr_data(a0)
		move.w	#64,marsspr_dwidth(a0)
		move.w	#$10,marsspr_x(a0)
		move.w	#$10,marsspr_y(a0)
		move.b	#32,marsspr_xs(a0)
		move.b	#48,marsspr_ys(a0)
		move.w	#$80,marsspr_indx(a0)
		move.b	#1,marsspr_yfrm(a0)

		adda	#sizeof_marsspr,a0
		move.l	#0,marsspr_data(a0)

SuperSpr_Main:
		lea	(RAM_MdDreq+Dreq_SuperSpr),a0
		sub.w	#1,(RAM_EmiTimer).w
		bpl.s	.wspr
		move.w	#14,(RAM_EmiTimer).w

		move.b	marsspr_xfrm(a0),d0
		add.w	#1,d0
		and.w	#1,d0
		move.b	d0,marsspr_xfrm(a0)
		adda	#sizeof_marsspr,a0
		move.b	marsspr_yfrm(a0),d0
		add.w	#1,d0
		and.w	#%11,d0
		move.b	d0,marsspr_yfrm(a0)
.wspr:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyX,d7
		beq	.not_hold3
		lea	(RAM_MdDreq+Dreq_SuperSpr),a0
		add.w	#1,marsspr_flags(a0)
		and.w	#%11,marsspr_flags(a0)
.not_hold3:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyY,d7
		beq	.not_hold4
		lea	(RAM_MdDreq+Dreq_SuperSpr),a0
		add.b	#1,marsspr_yfrm(a0)
		and.b	#%11,marsspr_yfrm(a0)
.not_hold4:

		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyB,d7
		beq	.not_hold2
		lea	(RAM_MdDreq+Dreq_SuperSpr),a0
		move.w	marsspr_x(a0),d0
		move.w	marsspr_y(a0),d1
		moveq	#TEST_MAINSPD,d2
		moveq	#TEST_MAINSPD,d3
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyRight,d7
		beq.s	.nor_s
		add.w	d2,d0
.nor_s:
		btst	#bitJoyLeft,d7
		beq.s	.nol_s
		sub.w	d2,d0
.nol_s:
		btst	#bitJoyDown,d7
		beq.s	.nod_s
		add.w	d3,d1
.nod_s:
		btst	#bitJoyUp,d7
		beq.s	.nou_s
		sub.w	d3,d1
.nou_s:
		move.w	d0,marsspr_x(a0)
		move.w	d1,marsspr_y(a0)
.not_hold2:

		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyA,d7
		beq.s	.not_hold
		lea	(RAM_MdDreq+Dreq_SuperSpr),a0
		move.w	marsspr_xs(a0),d0
		move.w	marsspr_ys(a0),d1
		moveq	#TEST_MAINSPD,d2
		moveq	#TEST_MAINSPD,d3
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyRight,d7
		beq.s	.nor_s2
		add.w	d2,d0
.nor_s2:
		btst	#bitJoyLeft,d7
		beq.s	.nol_s2
		sub.w	d2,d0
.nol_s2:
		btst	#bitJoyDown,d7
		beq.s	.nod_s2
		add.w	d3,d1
.nod_s2:
		btst	#bitJoyUp,d7
		beq.s	.nou_s2
		sub.w	d3,d1
.nou_s2:
		move.w	d0,marsspr_xs(a0)
		move.w	d1,marsspr_ys(a0)
.not_hold:

		add.w	#1,(RAM_EmiFrame).w
		rts

; ====================================================================
; ------------------------------------------------------
; Pick map
; ------------------------------------------------------

Level_PickMap:
		move.l	#MapHead_M|TH,a0
		move.l	#MapBlk_M|TH,a1
		move.l	#MapFg_M|TH,a2
		move.l	#0,a3
		move.l	#0,a4
		moveq	#-1,d0
		moveq	#0,d1
		moveq	#0,d2
		bsr	MdMap_Set

		move.l	#MapHead_0,a0
		move.l	#MapBlk_0,a1
		move.l	#MapFgL_0,a2
		move.l	#MapFgH_0,a3
		move.l	#MapFgC_0,a4
		moveq	#0,d0
		move.w	#$C000,d1
		move.w	#$2000,d2
		bsr	MdMap_Set

		move.l	#MapHead_0,a0
		move.l	#MapBlk_0,a1
		move.l	#MapBgL_0,a2
		move.l	#MapBgH_0,a3
		move.l	#0,a4
		moveq	#1,d0
		move.w	#$E000,d1
		move.w	#$2000,d2
		bsr	MdMap_Set

		rts

; 		lea	(RAM_MdDreq+Dreq_ScrnBuff),a0
; 		move.l	#TESTMARS_BG,scrlbg_Data(a0)
; 		move.l	#512,scrlbg_W(a0)
; 		move.l	#256,scrlbg_H(a0)
; 		move.l	#$00000000,scrlbg_X(a0)
; 		move.l	#$00000000,scrlbg_Y(a0)

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

