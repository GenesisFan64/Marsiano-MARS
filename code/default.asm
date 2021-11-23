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
RAM_MdlCurrMd	ds.w 1
RAM_BgCamera	ds.w 1
RAM_BgCamCurr	ds.w 1
RAM_CurrSelc	ds.w 1
RAM_CurrIndx	ds.w 1
RAM_CurrTrack	ds.w 1
RAM_CurrTicks	ds.w 1
RAM_CurrTempo	ds.w 1
RAM_EmiChar	ds.w 1
RAM_EmiAnim	ds.w 1
RAM_EmiUpd	ds.w 1
sizeof_mdglbl	ds.l 0
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
		lea	PAL_EMI(pc),a0
		moveq	#0,d0
		move.w	#$F,d1
		bsr	Video_LoadPal
; 		move.l	#ART_EMI,d0
; 		move.w	#ART_EMI_e-ART_EMI,d1
; 		move.w	#1,d2
; 		bsr	Video_LoadArt

		move.w	#1,(RAM_EmiUpd).w
		move.w	#0,(RAM_MdlCurrMd).w
		move.w	#208,(RAM_CurrTempo).w
		move.w	#320/2+80,(RAM_EmiPosX).w
		move.w	#224/2-90,(RAM_EmiPosY).w
		bsr	thisMode_Sprites

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

		bsr	thisMode_Sprites
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
		move.b	#$80,(sysmars_reg+comm14)
		bsr	.print_cursor

; Mode 0 mainloop
.mode0_loop:
		move.w	(Controller_1+on_press),d7
		lsr.w	#8,d7
		btst	#bitJoyY,d7
		beq.s	.noc_up
		move.w	#1,d0
		move.b	d0,(sysmars_reg+comm15)
.noc_up:

		move.w	#0,d0
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyDown,d7
		beq.s	.noz_down
		add.l	#$10000,(RAM_EmiPosY).w
		move.w	d0,(RAM_EmiChar).w
		move.w	#1,(RAM_EmiUpd).w
; 		bsr	thisMode_Sprites
		add.w	#1,(RAM_EmiAnim).w
.noz_down:
		move.w	#4,d0
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyUp,d7
		beq.s	.noz_up
		add.l	#-$10000,(RAM_EmiPosY).w
		move.w	d0,(RAM_EmiChar).w
		move.w	#1,(RAM_EmiUpd).w
; 		bsr	thisMode_Sprites
		add.w	#1,(RAM_EmiAnim).w
.noz_up:
		move.w	#8,d0
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyRight,d7
		beq.s	.noz_r
		add.l	#$10000,(RAM_EmiPosX).w
		move.w	d0,(RAM_EmiChar).w
		move.w	#1,(RAM_EmiUpd).w
; 		bsr	thisMode_Sprites
		add.w	#1,(RAM_EmiAnim).w
.noz_r:
		move.w	#$C,d0
		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyLeft,d7
		beq.s	.noz_l
		add.l	#-$10000,(RAM_EmiPosX).w
		move.w	d0,(RAM_EmiChar).w
		move.w	#1,(RAM_EmiUpd).w
; 		bsr	thisMode_Sprites
		add.w	#1,(RAM_EmiAnim).w
.noz_l:

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
; 		cmp.w	#1,(RAM_CurrIndx).w
; 		beq.	.nob
; 		add.w	#1,(RAM_CurrIndx).w
; 		bsr	.print_cursor
		add.w	#1,(a1)
		bsr	.print_cursor
.nob:
		move.w	(Controller_1+on_hold),d7
		and.w	#JoyA,d7
		beq.s	.noa
; 		tst.w	(RAM_CurrIndx).w
; 		beq.s	.noa
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

.print_cursor:
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
		dc.w .task_05-.tasklist

; d0 - Track slot
.task_00:
		lea	.playlist(pc),a0
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
.playlist:
	dc.l GemaTrk_patt_TEST,GemaTrk_blk_TEST,GemaTrk_ins_TEST
	dc.w $A,0
	dc.l GemaTrk_patt_HILLS,GemaTrk_blk_HILLS,GemaTrk_ins_HILLS
	dc.w 7,0
	dc.l GemaTrk_patt_TEST2,GemaTrk_blk_TEST2,GemaTrk_ins_TEST2
	dc.w 2,1
	dc.l GemaTrk_patt_chrono,GemaTrk_blk_chrono,GemaTrk_ins_chrono
	dc.w 3,1
	dc.l GemaTrk_mecano_patt,GemaTrk_mecano_blk,GemaTrk_mecano_ins
	dc.w 1,1
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

thisMode_Sprites:
		tst.w	(RAM_EmiUpd).w
		beq.s	.no_upd
		clr.w	(RAM_EmiUpd).w
		move.w	(RAM_EmiChar),d2
		move.w	(RAM_EmiAnim),d3
		lsr.w	#3,d3
		and.w	#3,d3
		add.w	d3,d2
		move.w	#$20*$18,d1
		mulu.w	d1,d2
		move.l	#ART_EMI,d0
		add.l	d2,d0
		and.l	#-2,d0
		move.w	#1,d2
		bsr	Video_LoadArt

		lea	(vdp_data),a6
		move.l	#$78000003,4(a6)
		move.w	(RAM_EmiPosY),d0
		move.w	(RAM_EmiPosX),d1
; 		move.w	(RAM_EmiChar),d2
; 		move.w	(RAM_EmiAnim),d3
; 		lsr.w	#3,d3
; 		and.w	#3,d3
; 		add.w	d3,d2
; 		mulu.w	#$18,d2
; 		add.w	#1,d2
		move.w	#1,d2
		add.w	#$80,d0
		add.w	#$80,d1
		move.w	d0,(a6)			; TOP 32x32
		move.w	#$0F01,(a6)
		move.w	d2,(a6)
		move.w	d1,(a6)
		add.w	#$20,d0
		add.w	#$10,d2
		move.w	d0,(a6)			; BOT 32x24
		move.w	#$0D00,(a6)
		move.w	d2,(a6)
		move.w	d1,(a6)
.no_upd:
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
str_Title:
		dc.b "GEMA sound driver tester",$A
		dc.b $A
		dc.b "Track index -----",$A,$A
		dc.b "  Sound_TrkPlay",$A
		dc.b "  Sound_TrkStop",$A
		dc.b "  Sound_TrkPause",$A
		dc.b "  Sound_TrkResume",$A
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

PAL_EMI:
		dc.w 0
		binclude "data/md/sprites/emi_pal.bin",2
; 		dc.w $0000,$0CAE,$0C6E,$062E
; 		dc.w $0448,$08EE,$06CE,$04AE
; 		dc.w $026E,$0EEA,$0EA2,$0C62
; 		dc.w $0ACE,$0226,$0222,$0EEE
		align 2

; ====================================================================
; Report size
	if MOMPASS=6
.end:
		message "This 68K RAM-CODE uses: \{.end-thisCode_Top}"
	endif
