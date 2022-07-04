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
RAM_Xtemp	ds.l 1
RAM_Ytemp	ds.l 1
		finish

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

MD_Mode0:
		move.w	#$2700,sr
		bclr	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update
		bsr	Mode_Init
		bsr	Video_PrintInit
		bsr	MdMap_Init

	; Emily variables
		move.w	#(320/2)+16,(RAM_EmiPosX).w
		move.w	#(224/2)+8,(RAM_EmiPosY).w
		lea	Pal_Emily(pc),a0
		moveq	#0,d0
		move.w	#16,d1
		bsr	Video_FadePal

	; Prepare sound
		moveq	#0,d0
		bsr	Sound_TrkStop
		move.w	#128+16,d1
		bsr	Sound_GlbBeats
		lea	(GemaTrkData_Test2),a0
		moveq	#0,d0
		move.w	#2,d1
		moveq	#0,d2
		move.w	#%01,d3
		bsr	Sound_TrkPlay

	; Pick and draw scroll maps
		bsr	Level_PickMap
		bsr	MdMap_DrawAll

	; 32X stuff
		lea	(RAM_MdDreq+Dreq_ScrnBuff),a0
		move.l	#TESTMARS_BG,Dreq_ScrlBg_Data(a0)
		move.l	#320,Dreq_ScrlBg_W(a0)
		move.l	#448,Dreq_ScrlBg_H(a0)
		move.l	#$00000000,Dreq_ScrlBg_X(a0)
		move.l	#$00000000,Dreq_ScrlBg_Y(a0)
		bsr	System_MarsUpdate
		lea	(PalData_Mars_Test),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#0,d2
		bsr	Video_FadePal_Mars
		move.w	#2,d0
		bsr	Video_Mars_GfxMode
	; ****

		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#4,(RAM_FadeMarsIncr).w
		move.w	#1,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l
		move.b	#%000,(RAM_VdpRegs+$B).l
		move.b	#$10,(RAM_VdpRegs+7).l
		bsr	Video_Update

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	System_WaitFrame
		bsr	Video_RunFade
		bne.s	.loop

		bsr	MdMap_Run

	; temporal Emily Fujiwara object
		lea	(RAM_MdDreq+Dreq_ScrnBuff),a1
		move.l	#$20000,d0
		move.l	#$20000,d1
		move.w	(Controller_1+on_hold),d7
		move.w	d7,d6
		btst	#bitJoyDown,d7
		beq.s	.noz_down
		move.w	#0,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w

		add.l	d1,(RAM_Ytemp).w
		move.l	d1,d4
		asr.l	#2,d4
		add.l	d4,Dreq_ScrlBg_Y(a1)

.noz_down:
		move.w	d7,d6
		btst	#bitJoyUp,d6
		beq.s	.noz_up
		move.w	#4,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w

		sub.l	d1,(RAM_Ytemp).w
		move.l	d1,d4
		asr.l	#2,d4
		sub.l	d4,Dreq_ScrlBg_Y(a1)

.noz_up:
		move.w	d7,d6
		btst	#bitJoyRight,d6
		beq.s	.noz_r
		move.w	#8,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w

		add.l	d0,(RAM_Xtemp).w
		move.l	d0,d4
		asr.l	#2,d4
		add.l	d4,Dreq_ScrlBg_X(a1)
.noz_r:
		move.w	d7,d6
		btst	#bitJoyLeft,d6
		beq.s	.noz_l
		move.w	#$C,(RAM_EmiFrame).w
		add.w	#1,(RAM_EmiAnim).w

		sub.l	d0,(RAM_Xtemp).w
		move.l	d0,d4
		asr.l	#2,d4
		sub.l	d4,Dreq_ScrlBg_X(a1)
.noz_l:
		bsr	Emilie_MkSprite

		move.l	(RAM_Xtemp).w,d0
		move.l	(RAM_Ytemp).w,d1
		neg.l	d0
		swap	d0
		swap	d1
		move.w	d0,(RAM_HorScroll).w
		move.w	d1,(RAM_VerScroll).w
		lsr.w	#1,d0
		lsr.w	#1,d1
		move.w	d0,(RAM_HorScroll+2).w
		move.w	d1,(RAM_VerScroll+2).w

		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq	.loop
		bra	MD_DebugMenu

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
; Pick map
; ------------------------------------------------------

Level_PickMap:
		move.l	#MapHead_0,a0
		move.l	#MapBlk_0,a1
		move.l	#MapFgL_0,a2
		move.l	#MapFgH_0,a3
		move.l	#MapFgC_0,a4
		moveq	#0,d0
		move.w	#$C000,d1
		move.w	#$2000,d2
		move.l	#dword($80,$40),d3
		bsr	MdMap_Set

		move.l	#MapHead_0,a0
		move.l	#MapBlk_0,a1
		move.l	#MapBgL_0,a2
		move.l	#MapBgH_0,a3
		move.l	#0,a4
		moveq	#1,d0
		move.w	#$E000,d1
		move.w	#$2000,d2
		move.l	#dword($80,$40),d3
		bsr	MdMap_Set

		lea	(Pal_level0),a0
		moveq	#$10,d0
		move.w	#32,d1
		bsr	Video_FadePal
		move.l	#Art_level0,d0
		move.w	#1,d1
		move.w	#Art_level0_e-Art_level0,d2
		bra	Video_LoadArt

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

Pal_Emily:
		dc.w 0
		binclude "data/md/sprites/emi_pal.bin",2
		align 2
Map_Nicole:
		include "data/md/sprites/emi_map.asm"
		align 2
Dplc_Nicole:
		include "data/md/sprites/emi_plc.asm"
		align 2

