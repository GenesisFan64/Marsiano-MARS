; ====================================================================
; ----------------------------------------------------------------
; 2D Part
; ----------------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Settings
; ------------------------------------------------------

TEST_MAINSPD	equ $04

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
; This screen's RAM
; ------------------------------------------------------

		struct RAM_ScreenBuff
RAM_MapX	ds.w 1
RAM_MapY	ds.w 1
		endstruct

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

		move.w	#$2700,sr
		bclr	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update
		bsr	Video_PrintInit
		bsr	Mode_Init

		bsr	gemaStopAll

		lea	(RAM_PaletteFd+$60),a0
		move.w	#0,(a0)+
		move.w	#$EEE,(a0)+
		move.w	#$CCC,(a0)+
		move.w	#$AAA,(a0)+
		move.w	#$888,(a0)+
		move.w	#$222,(a0)+
		clr.w	(RAM_PaletteFd).w		; <-- quick patch
		clr.w	(RAM_MdMarsPalFd).w
		lea	(PalMars_TEST),a0
		moveq	#0,d0
		move.w	#256,d1
		moveq	#0,d2
		bsr	Video_FadePal_Mars

		lea	str_Stats(pc),a0
		move.l	#locate(0,1,1),d0
		bsr	Video_Print


; 	Set Fade-in settings


		bset	#bitDispEnbl,(RAM_VdpRegs+1).l
		move.b	#%10000001,(RAM_VdpRegs+$C).w		; H40 + shadow mode
		bsr	Video_Update
; 		bsr	.fade_in

		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#2,(RAM_FadeMarsIncr).w
		move.w	#1,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w

	if MCD|MARSCD
		moveq	#$10,d0
		bsr	System_McdSubTask
	endif

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	System_WaitFrame
		bsr	Video_RunFade

		lea	str_Stats2(pc),a0
		move.l	#locate(0,1,3),d0
		bsr	Video_Print

		addi.l	#1,(RAM_Framecount).w
		bra.s	.loop

; ====================================================================
; ----------------------------------------------
; common subs
; ----------------------------------------------

.fade_in:
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#1,(RAM_FadeMarsIncr).w
		move.w	#4,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		bra.s	.loop2

.fade_out:
		move.w	#2,(RAM_FadeMdReq).w
		move.w	#2,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#1,(RAM_FadeMarsIncr).w
		move.w	#4,(RAM_FadeMdDelay).w
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

; ====================================================================
; ------------------------------------------------------
; DATA
;
; Small stuff goes here
; ------------------------------------------------------

str_Stats:
		dc.b "MARSIANO SCD32X! NO FEIK! AYY LMAO!",$A
; 		dc.b $A
		dc.b 0
		align 2

str_Stats2:
; 	if MARS
		dc.b "\\l",$A,$A
		dc.b "MCD COMM: \\b \\b RW/RD",$A,$A
		dc.b "\\w \\w \\w \\w RW",$A
		dc.b "\\w \\w \\w \\w",$A,$A
		dc.b "\\w \\w \\w \\w RD",$A
		dc.b "\\w \\w \\w \\w",$A
		dc.b $A
		dc.b "MARS COMM",$A,$A
		dc.b "\\w \\w \\w \\w",$A
		dc.b "\\w \\w \\w \\w",$A,$A
		dc.b "\\l",$A
		dc.b 0
; ; 	else
; 		dc.b "\\l",0
; 	endif
		dc.l RAM_Framecount
; 	if MARS
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

		dc.l sysmars_reg+comm0
		dc.l sysmars_reg+comm2
		dc.l sysmars_reg+comm4
		dc.l sysmars_reg+comm6
		dc.l sysmars_reg+comm8
		dc.l sysmars_reg+comm10
		dc.l sysmars_reg+comm12
		dc.l sysmars_reg+comm14

		dc.l $FFFFFFF0
; 	endif
		align 2

; ====================================================================
