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
MAX_TSTENTRY	equ	3

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
RAM_MdlCurrMd	ds.w 1
RAM_BgCamera	ds.w 1
RAM_BgCamCurr	ds.w 1
RAM_CurrTrack	ds.w 2
RAM_CurrSelc	ds.w 1
sizeof_mdglbl	ds.l 0
		finish

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

thisCode_Top:
		move.w	#$2700,sr
		bsr	Mode_Init
		bsr	Video_PrintInit
		move.w	#0,(RAM_MdlCurrMd).w
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l		; Enable display
		bsr	Video_Update

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		beq.s	.loop
		bsr	System_Input
		add.l	#1,(RAM_Framecount).l
.inside:	move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		bne.s	.inside

		move.l	#$7C000003,(vdp_ctrl).l
		move.w	(RAM_BgCamCurr).l,d0
		neg.w	d0
		asr.w	#2,d0
		move.w	d0,(vdp_data).l
		asr.w	#1,d0
		move.w	d0,(vdp_data).l
		move.w	(RAM_MdlCurrMd).w,d0
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
		tst.w	(RAM_MdlCurrMd).w
		bmi	.mode0_loop
		or.w	#$8000,(RAM_MdlCurrMd).w
		lea	str_Title(pc),a0
		move.l	#locate(0,2,2),d0
		bsr	Video_Print
		move.w	#$8080,(sysmars_reg+comm14)
		bsr	.print_cursor

; Mode 0 mainloop
.mode0_loop:
		move.w	(Controller_1+on_press),d7
		lsr.w	#8,d7
		btst	#bitJoyZ,d7
		beq.s	.noc_up
		move.w	#1,d0
		move.b	d0,(sysmars_reg+comm15)
.noc_up:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyUp,d7
		beq.s	.nou
		tst.w	(RAM_CurrSelc).w
		beq.s	.nou
		sub.w	#1,(RAM_CurrSelc).w
		bsr	.print_cursor
.nou:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyDown,d7
		beq.s	.nod
		cmp.w	#MAX_TSTENTRY,(RAM_CurrSelc).w
		bge.s	.nod
		add.w	#1,(RAM_CurrSelc).w
		bsr	.print_cursor
.nod:
		lea	(RAM_CurrTrack),a1
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyLeft,d7
		beq.s	.nol
		tst.w	(a1)
		beq.s	.nol
		sub.w	#1,(a1)
		bsr	.print_cursor
.nol:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyRight,d7
		beq.s	.nor
		cmp.w	#MAX_TSTTRKS,(a1)
		bge.s	.nor
		add.w	#1,(a1)
		bsr	.print_cursor
.nor:
		move.w	(Controller_1+on_press),d7
		and.w	#JoyA+JoyB+JoyC,d7
		beq.s	.noc_c
		move.w	(RAM_CurrSelc).w,d0
		add.w	d0,d0
		move.w	.tasklist(pc,d0.w),d0
		jsr	.tasklist(pc,d0.w)
.noc_c:
; 		lea	str_COMM(pc),a0
; 		move.l	#locate(0,2,9),d0
; 		bsr	Video_Print
		rts

.print_cursor:
		lea	str_Status(pc),a0
		move.l	#locate(0,12,4),d0
		bsr	Video_Print
		lea	str_Cursor(pc),a0
		moveq	#0,d0
		move.w	(RAM_CurrSelc).w,d0
		add.l	#locate(0,2,5),d0
		bsr	Video_Print
		rts

.tasklist:
		dc.w .task_00-.tasklist
		dc.w .task_01-.tasklist
		dc.w .task_00-.tasklist
		dc.w .task_00-.tasklist
		dc.w .task_00-.tasklist
		dc.w .task_00-.tasklist
		dc.w .task_00-.tasklist
		dc.w .task_00-.tasklist

; Gema_Play
.task_00:
		lea	.playlist(pc),a0
		move.w	(RAM_CurrTrack).w,d0
		lsl.w	#4,d0
		lea	(a0,d0.w),a0
		move.w	$C(a0),d1
		move.w	#0,d2
		bra	Sound_TrkPlay
.task_01:
		move.w	#0,d1
		bra	Sound_TrkStop

; test playlist
.playlist:
	dc.l GemaTrk_patt_TEST,GemaTrk_blk_TEST,GemaTrk_ins_TEST
	dc.w 4,0


	dc.l GemaTrk_patt_TEST2,GemaTrk_blk_TEST2,GemaTrk_ins_TEST2
	dc.w 2,0
	dc.l GemaTrk_patt_chrono,GemaTrk_blk_chrono,GemaTrk_ins_chrono
	dc.w 3,0
	dc.l GemaTrk_mecano_patt,GemaTrk_mecano_blk,GemaTrk_mecano_ins
	dc.w 1,0
	align 2

; ====================================================================
; ------------------------------------------------------
; Subroutines
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

str_Cursor:	dc.b " ",$A
		dc.b ">",$A
		dc.b " ",0

str_Status:
		dc.b "\\w",0
		dc.l RAM_CurrTrack
		align 2
str_Title:
		dc.b "GEMA sound driver tester",$A
		dc.b $A
		dc.b "Song/SFX:      ",$A,$A
		dc.b "  Sound_TrkPlay",$A
		dc.b "  Sound_TrkStop",$A
		dc.b "  Sound_TrkPause",$A
		dc.b "  Sound_TrkResume",0
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

; ====================================================================

	if MOMPASS=6
.end:
		message "This 68K RAM-CODE uses: \{.end-thisCode_Top}"
	endif
