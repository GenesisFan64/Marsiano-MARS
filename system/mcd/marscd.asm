; ====================================================================
; ----------------------------------------------------------------
; 32X BOOT ON SEGA CD
;
; include this AFTER the header
; ----------------------------------------------------------------

		lea	.file_marscode(pc),a0		; Load SH2 code from disc to WORD-RAM
		jsr	(System_McdTrnsfr_WRAM).l
		bra.s	.normal
.file_marscode:
		dc.b "MARSCODE.BIN",0
		align 2
.retry:
		lea	($A15100),a5
		move.b	#0,1(a5)
.normal:
		lea	($A10000),a5
		moveq	#1,d0
ID_loop:
		cmp.l	#"MARS",$30EC(a5)	; check MARS ID
		bne	ID_loop
;		bne	MarsError
.sh_wait:
		btst.b	#7,$5101(a5)		; adapter control reg. REN=1 ?
		beq.b	.sh_wait
		btst.b	#0,$5101(a5)		; check adapter mode
		bne	Hot_Start
.cold_start:					; power on (cold_start)
		move.b	#1,$5101(a5)		; MARS mode
						; SH2 reset - wait 10ms -
		bra	RestartPrg
		align 4

; ----------------------------------------------------------------
;	Copyright
; ----------------------------------------------------------------
CopyrightData:
	dc.b	"32X Initial Program            "
	dc.b	"             CD-ROM Version    "
	dc.b	"Copyright SEGA ENTERPRISES,LTD."
	dc.b	" 1994                          "
	dc.b	"                  Version 1.0"

; ----------------------------------------------------------------
;	Frame Buffer Clear
; ----------------------------------------------------------------

		align 4
FrameClear:
		movem.l	d0/d1/d7/a1,-(a7)

		lea	($A15180),a1
.fm1
		bclr.b	#7,-$80(a1)		; MD access
		bne.b	.fm1

		move.w	#($20000/$200-1),d7
		moveq	#0,d0
		moveq	#0,d1
		move.w	#-1,$4(a1)		; Fill Length Reg.
.fill0:
		move.w	d1,$6(a1)		; Fill Start Address Reg.
		move.w	d0,$8(a1)		; Fill Data Reg.
		nop
.fen0:
		btst.b	#1,$b(a1)		; FEN = 0 ?
		bne.b	.fen0
		add.w	#$100,d1		; Address = +200H
		dbra	d7,.fill0

		movem.l	(a7)+,d0/d1/d7/a1
		rts

; ----------------------------------------------------------------
;	Palette RAM Clear
; ----------------------------------------------------------------

PaletteClear:
		movem.l	d0/d7/a0,-(a7)

		lea	$a15200,a0
.fm2
		bclr.b	#7,-$100(a0)		; MD access
		bne.b	.fm2

		move.w	#(256/2/4-1),d7
.pl:
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		move.l	d0,(a0)+
		dbra	d7,.pl

		movem.l	(a7)+,d0/d7/a0
		rts

; ----------------------------------------------------------------
; (Re)Start
; ----------------------------------------------------------------

RestartPrg:
		move.w	#19170,d7		; 8
.res_wait:
		dbra	d7,.res_wait		; 12*d7+10
		lea	($A15100),a1		; ----	Mars Register Initialize
		moveq	#0,d0			; ----	Communication Reg. Clear
		move.l	d0,$20(a1)		; 0
		move.l	d0,$24(a1)		; 4
		move.b	#3,$5101(a5)		; SH2 start
.fm3
		bclr.b	#7,(a1)			; MD access
		bne.b	.fm3
		moveq	#0,d0
		move.w	d0,2(a1)		; Interrupt Reg.
		move.w	d0,4(a1)		; Bank Reg.
		move.w	d0,6(a1)		; DREQ Control Reg.
		move.l	d0,8(a1)		; DREQ Source Address Reg.
		move.l	d0,$c(a1)		; DREQ Destination Address Reg.
		move.w	d0,$10(a1)		; DREQ Length Reg.
		move.w	d0,$30(a1)		; PWM Control
		move.w	d0,$32(a1)		; PWM fs Reg.
		move.w	d0,$38(a1)		; PWM Mono Reg.
		move.w	d0,$80(a1)		; Bitmap Mode Reg.
		move.w	d0,$82(a1)		; Shift Reg.
.fs0:						; ----	Mars Frame Buffer Clear
		bclr.b	#0,$8b(a1)		; FS = 0
		bne.b	.fs0
		bsr	FrameClear
.fs1:
		bset.b	#0,$8b(a1)		; FS = 1
		beq.b	.fs1
		bsr	FrameClear
		bclr.b	#0,$8b(a1)		; FS = 0
		bsr	PaletteClear		; ----	Palette RAM Clear
	; *** Taken from SLAM CITY CD32X
		move.w	#2,d0
		moveq	#0,d1
		move.b	1(a5),d1
		move.b	$80(a1),d2
		lsl.w	#8,d2
		or.w	d2,d1
		btst	#$F,d1
		bne.s	loc_1DA
		btst	#6,d1
		beq.w	loc_21E
		bra.s	loc_1E2
loc_1DA:
		btst	#6,d1
		bne.w	loc_21E
loc_1E2:
	; ***
		move	#$80,d0			; ----	SH2 Check
		move.l	$20(a1),d1		; SDRAM Self Check
		cmp.l	#"SDER",d1
		beq	MarsError
		moveq	#0,d0			; ----	Communication Reg. Clear
		move.l	d0,$28(a1)		; 8
		move.l	d0,$2c(a1)		; 12
		movea.l	#-64,a6
		movem.l	(a6),d0/d3-d7/a0-a6
		move	#0,ccr			; Complete
		bra.b	IcdAllEnd
Hot_Start:
		lea	($a15100),a1
		move.w	d0,6(a1)		; DREQ Control Reg.
		move.w	#$8000,d0
		bra.b	IcdAllEnd
loc_21E:
		move	#1,ccr			; Error
IcdAllEnd:
; 		bcs	_error

; ----------------------------------------------------------------
; Sending the SH2 data using the framebuffer...
		lea	($A15100).l,a5
loc_2EE:
		bclr	#7,(a5)
		bne.s	loc_2EE
		lea	($840000).l,a0			; First the Module
		lea	MarsInitHeader(pc),a2
		move.w	#$E-1,d7
.send_head:
		move.l	(a2)+,(a0)+
		dbf	d7,.send_head
		lea	($200000).l,a2			; Then the entire SH2 code
		move.l	#((MARS_RAMDATA_E-MARS_RAMDATA)/4)-1,d7
.send_code:
		move.l	(a2)+,d0
		move.l	d0,(a0)+
		dbf	d7,.send_code
.wait_adapter:
		bset	#7,(a5)
		beq.s	.wait_adapter
		lea	($A15100).l,a5
		move.l	#"_CD_",$20(a5)			; SH2 Application Start
.master:	cmp.l	#"M_OK",$20(a5)
		bne.s	.master
.slave:		cmp.l	#"S_OK",$24(a5)
		bne.s	.slave
		lea	(vdp_ctrl).l,a6
		move.l	#$80048104,(a6)			; Default top VDP regs
		moveq	#0,d0				; Clear both Master and Slave comm's
		move.l	d0,comm12(a5)
MarsError:
		bra	MarsJumpHere

; ----------------------------------------------------------------
;	MARS User Header
; ----------------------------------------------------------------
MarsInitHeader:
		dc.b "MARS CDROM      "			; module name
		dc.l $00000000				; version
		dc.l $00000000				; Not Used
		dc.l $06000000				; SH2 (SDRAM)
		dc.l MARS_RAMDATA_E-MARS_RAMDATA	; SH2
		dc.l SH2_M_Entry			; Master SH2 PC (SH2 area)
		dc.l SH2_S_Entry			; Slave SH2 PC (SH2 area)
		dc.l SH2_Master				; Master SH2 default VBR
		dc.l SH2_Slave				; Slave SH2 default VBR
		dc.l $00000000				; Not Used
		dc.l $00000000				; Not Used
		align 2
MarsJumpHere:
