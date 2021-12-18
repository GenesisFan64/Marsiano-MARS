; ====================================================================
; ----------------------------------------------------------------
; System
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init System
; 
; Uses:
; a0-a2,d0-d1
; --------------------------------------------------------

System_Init:
		move.w	#$2700,sr		; Disable interrupts
		move.w	sr,-(sp)
		move.w	#$0100,(z80_bus).l	; Stop Z80
.wait:
		btst	#0,(z80_bus).l		; Wait for it
		bne.s	.wait
		moveq	#%01000000,d0		; Init ports, TH=1
		move.b	d0,(sys_ctrl_1).l	; Controller 1
		move.b	d0,(sys_ctrl_2).l	; Controller 2
		move.b	d0,(sys_ctrl_3).l	; Modem
		move.w	#0,(z80_bus).l		; Enable Z80
		lea	(RAM_InputData),a0	; Clear input data buffer
		move.w	#sizeof_input-1/2,d1
		moveq	#0,d0
.clrinput:
		move.w	#0,(a0)+
		dbf	d1,.clrinput
		move.w	#$4EF9,d0		; Set JMP opcode for the Hblank/VBlank jumps
 		move.w	d0,(RAM_MdMarsVInt).l
		move.w	d0,(RAM_MdMarsHInt).l
		move.l	#$56255769,d0		; Set these random values
		move.l	#$95116102,d1
		move.l	d0,(RAM_SysRandVal).l
		move.l	d1,(RAM_SysRandSeed).l
		move.l	#VInt_Default,d0	; Set default ints
		move.l	#Hint_Default,d1
		bsr	System_SetInts
		move.w	(sp)+,sr
		rts

; ====================================================================
; --------------------------------------------------------
; System_Input (VBLANK ONLY)
; 
; Uses:
; d4-d6,a4-a5
; --------------------------------------------------------

; TODO:
; Check if it still required to turn OFF the Z80
; while reading the controller

System_Input:
; 		move.w	#$0100,(z80_bus).l	; Stop Z80
.wait:
; 		btst	#0,(z80_bus).l		; Wait for it
; 		bne.s	.wait
		lea	($A10003),a4
		lea	(RAM_InputData),a5
		bsr.s	.this_one
		adda	#2,a4
		adda	#sizeof_input,a5
; 		bsr.s	.this_one
; 		move.w	#0,(z80_bus).l
; 		rts

; --------------------------------------------------------	
; Read port
; 
; a4 - Current port
; a5 - Output data
; --------------------------------------------------------

.this_one:
		bsr	.pick_id
		move.b	d4,pad_id(a5)
		cmp.w	#$F,d4
		beq.s	.exit
		and.w	#$F,d4
		add.w	d4,d4
		move.w	.list(pc,d4.w),d5
		jmp	.list(pc,d5.w)
.exit:
		clr.b	pad_ver(a5)
		rts

; --------------------------------------------------------
; Grab ID
; --------------------------------------------------------

.list:		dc.w .exit-.list	; $0
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $4
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $8
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $C
		dc.w .id_0D-.list
		dc.w .exit-.list
		dc.w .exit-.list

; --------------------------------------------------------
; ID $0D
; 
; Normal controller, Old or New
; --------------------------------------------------------

.id_0D:
		move.b	#$40,(a4)	; Show CB|RLDU
		nop
		nop
		move.b	(a4),d5
		and.w	#%00111111,d5
		move.b	#$00,(a4)	; Show SA|RLDU
		nop
		nop
		move.b	(a4),d4
		lsl.w	#2,d4
		and.w	#%11000000,d4
		or.w	d5,d4
		move.b	#$40,(a4)	; Show CB|RLDU
		not.w	d4
		move.b	on_hold+1(a5),d5
		eor.b	d4,d5
		move.b	#$00,(a4)	; Show SA|RLDU
		move.b	d4,on_hold+1(a5)
		and.b	d4,d5
		move.b	d5,on_press+1(a5)
		move.b	#$40,(a4)	; 6 button responds
		nop
		nop
		move.b	(a4),d4		; Grab ??|MXYZ
 		move.b	#$00,(a4)
  		nop
  		nop
 		move.b	(a4),d6		; Type: $03 old, $0F new
 		move.b	#$40,(a4)
 		nop
 		nop
		and.w	#$F,d6
		lsr.w	#2,d6
		and.w	#1,d6
		beq.s	.oldpad
		not.b	d4
 		and.w	#%1111,d4
		move.b	on_hold(a5),d5
		eor.b	d4,d5
		move.b	d4,on_hold(a5)
		and.b	d4,d5
		move.b	d5,on_press(a5)
.oldpad:
		move.b	d6,pad_ver(a5)
		rts
		
; --------------------------------------------------------
; Grab ID
; --------------------------------------------------------

.pick_id:
		moveq	#0,d4
		move.b	#%01110000,(a4)		; TH=1,TR=1,TL=1
		nop
		nop
		bsr	.read
		move.b	#%00110000,(a4)		; TH=0,TR=1,TL=1
		nop
		nop
		add.w	d4,d4
.read:
		move.b	(a4),d5
		move.b	d5,d6
		and.b	#$C,d6
		beq.s	.step_1
		addq.w	#1,d4
.step_1:
		add.w	d4,d4
		move.b	d5,d6
		and.w	#3,d6
		beq.s	.step_2
		addq.w	#1,d4
.step_2:
		rts

; --------------------------------------------------------
; System_Random
; 
; Set random value
; 
; Output:
; d0 | LONG
; --------------------------------------------------------

; TODO: rewrite this
System_Random:
		move.l	(RAM_SysRandSeed),d5
		move.l	(RAM_SysRandVal),d4
		rol.l	#1,d5
		asr.l	d5,d4
		add.l	d5,d4
		move.l	d5,(RAM_SysRandSeed).l
		move.l	d4,(RAM_SysRandVal).l
		move.l	d4,d0
		rts

; --------------------------------------------------------
; System_SineWave_Cos / System_SineWave
;
; Read sinewave value
;
; Input:
; d0 | WORD - Tan
; d1 | WORD - Multiply by
;
; Output:
; d2 | LONG - Result (as 0000.0000)
; --------------------------------------------------------

System_SineWave_Cos:
		movem.w	d0,-(sp)
		moveq	#0,d2
		add.b	#$40,d0
		move.b	d0,d2
		asl.b	#1,d2
		move.w	MdSys_SineData(pc,d2.w),d2
		mulu.w	d1,d2
		or.b	d0,d0
		bpl.s	.dont_neg
		neg.l	d2
.dont_neg:
		movem.w	(sp)+,d0
		rts

System_SineWave:
		movem.w	d0,-(sp)
		and.w	#$7F,d0
		asl.w	#1,d0
		move.w	MdSys_SineData(pc,d0.w),d2
		mulu.w	d1,d2
		movem.w	(sp)+,d0
		subq.l	#8,d2
		or.b	d0,d0
		bpl.s	.dont_neg
		neg.l	d2
.dont_neg:
		rts

MdSys_SineData:	dc.w 0,	6, $D, $13, $19, $1F, $26, $2C,	$32, $38, $3E
		dc.w $44, $4A, $50, $56, $5C, $62, $68,	$6D, $73, $79
		dc.w $7E, $84, $89, $8E, $93, $98, $9D,	$A2, $A7, $AC
		dc.w $B1, $B5, $B9, $BE, $C2, $C6, $CA,	$CE, $D1, $D5
		dc.w $D8, $DC, $DF, $E2, $E5, $E7, $EA,	$ED, $EF, $F1
		dc.w $F3, $F5, $F7, $F8, $FA, $FB, $FC,	$FD, $FE, $FF
		dc.w $FF, $100,	$100, $100, $100, $100,	$FF, $FF, $FE
		dc.w $FD, $FC, $FB, $FA, $F8, $F7, $F5,	$F3, $F1, $EF
		dc.w $ED, $EA, $E7, $E5, $E2, $DF, $DC,	$D8, $D5, $D1
		dc.w $CE, $CA, $C6, $C2, $BE, $B9, $B5,	$B1, $AC, $A7
		dc.w $A2, $9D, $98, $93, $8E, $89, $84,	$7E, $79, $73
		dc.w $6D, $68, $62, $5C, $56, $50, $4A,	$44, $3E, $38
		dc.w $32, $2C, $26, $1F, $19, $13, $D, 6

; --------------------------------------------------------
; System_SetInts
;
; Set new interrputs
;
; d0 | LONG - VBlank
; d1 | LONG - HBlank
;
; Uses:
; d4
;
; Notes:
; Writing 0 or a negative number will skip change
; to the interrupt pointer
; --------------------------------------------------------

System_SetInts:
		move.l	d0,d4
		beq.s	.novint
		bmi.s	.novint
		or.l	#$880000,d4
 		move.l	d4,(RAM_MdMarsVInt+2).l
.novint:
		move.l	d1,d4
		beq.s	.nohint
		bmi.s	.nohint
		or.l	#$880000,d4
		move.l	d4,(RAM_MdMarsHInt+2).l
.nohint:
		rts

; --------------------------------------------------------
; System_SramInit
; 
; Init save data
; 
; Uses:
; a4,d4-d5
; --------------------------------------------------------

; TODO: Check if RV bit is needed here...
System_SramInit:
		move.b	#1,(md_bank_sram).l
		lea	($200001).l,a4
		moveq	#0,d4
		move.w	#($4000/2)-1,d5
.initsave:
		move.b	d4,(a4)
		adda	#2,a4
		dbf	d5,.initsave
		move.b	#0,(md_bank_sram).l
		rts

; --------------------------------------------------------
; System_VSync
; 
; Waits for VBlank manually
; 
; Uses:
; d4
; --------------------------------------------------------

System_VSync:
		move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		beq.s	System_VSync
		bsr	System_Input
; 		bsr	Sound_Update
		add.l	#1,(RAM_FrameCount).l
.inside:	move.w	(vdp_ctrl),d4
		btst	#bitVint,d4
		bne.s	.inside
		rts

; --------------------------------------------------------
; System_JumpRamCode
;
; Transfer user code to RAM and jump to it.
;
; Input:
; d0 - Location of the RAM code
; --------------------------------------------------------

System_JumpRamCode:
		or.l	#$880000,d0
		move.l	d0,a0
		lea	(RAMCODE_USER),a1
		move.w	#$4000-1,d7
.copyme2:
		move.b	(a0)+,(a1)+
		dbf	d7,.copyme2
		jmp	(RAMCODE_USER).l

; --------------------------------------------------------
; Initialize current screen mode
; --------------------------------------------------------

Mode_Init:
		bsr	Video_Clear
		lea	(RAM_ModeBuff),a4
		move.w	#(MAX_MDERAM/2)-1,d5
		moveq	#0,d4
.clr:
		move.w	d4,(a4)+
		dbf	d5,.clr
		rts

; ====================================================================
; ----------------------------------------------------------------
; Default interrupts
; ----------------------------------------------------------------

; --------------------------------------------------------
; VBlank
; --------------------------------------------------------

VInt_Default:
		movem.l	d0-a6,-(sp)
		bsr	System_Input
; 		bsr	Sound_Update
		add.l	#1,(RAM_FrameCount).l
		movem.l	(sp)+,d0-a6		
		rte

; --------------------------------------------------------
; HBlank
; --------------------------------------------------------

HInt_Default:
		rte
		
; ====================================================================
; --------------------------------------------------------
; 32X Communication, using DREQ
; --------------------------------------------------------

System_MdMarsDreq:
		lea	(RAM_MdMarsDreq),a6
		lea	($A15112).l,a5
		move.w	#$100,d6
		move.w	sr,d7
		move.w	#$2700,sr
.retry:
		move.w	d6,(sysmars_reg+dreqlen).l
		bset	#2,(sysmars_reg+dreqctl).l
.wait_bit:
		btst	#6,(sysmars_reg+comm14).l
		beq.s	.wait_bit
		bclr	#6,(sysmars_reg+comm14).l
		move.w	d6,d5
		lsr.w	#2,d5
		sub.w	#1,d5
.l0:		move.w  (a6)+,(a5)
		move.w  (a6)+,(a5)
		move.w  (a6)+,(a5)
		move.w  (a6)+,(a5)
.l1:		btst	#7,dreqctl(a5)		; Got Full ?
		bne.s	.l1
		dbf	d5,.l0
		btst	#2,dreqctl(a5)		; DMA All OK ?
		bne	.retry
		move.w	d7,sr
		rts

; 		lea	(RAM_MdMarsDreq),a6
; 		lea	($A15112).l,a5
; 		bsr	.blast_me
; 		bsr	.blast_me
; .blast_me:
; 	rept 128
; 		move.w	(a6)+,(a5)
; 	endm
; 		rts

; .l0:		move.w	(a6)+,(a4)		; Fill FIFO ...
; 		move.w	(a6)+,(a4)
; 		move.w	(a6)+,(a4)
; 		move.w	(a6)+,(a4)
; ; .l1:		btst	#7,dreqctl(a5)	; Got Full ?
; ; 		bne.s	.l1
; ; 		subq	#4,d4
; ; 		bcc.s	.l0
; ; 		move.w	($A15110).l,d4
; ; 		bne.s	.retry
; ; 		btst	#2,dreqctl(a5)		; DMA All OK ?
; ; 		bne	.retry
; 		move.l	#$C0000000,(vdp_ctrl).l	; DEBUG EXIT
; 		move.w	#$000,(vdp_data).l
; 		move.w	d7,sr			; Restore SR
; 		rts

; ; ------------------------------------------------
; ; Add new task to the list
; ; ------------------------------------------------
;
; System_MdMars_MstAddTask:
; 		lea	(RAM_MdMarsTskM).w,a0
; 		lea	(RAM_MdMarsTCntM).w,a1
; 		bra	sysMdMars_instask
;
; System_MdMars_SlvAddTask:
; 		lea	(RAM_MdMarsTskS).w,a0
; 		lea	(RAM_MdMarsTCntS).w,a1
; 		bra	sysMdMars_instask
;
; ; ------------------------------------------------
; ; Single task
; ; ------------------------------------------------
;
; System_MdMars_MstTask:
; 		lea	(RAM_MdMarsTsSgl),a0
; 		lea	(sysmars_reg+comm14),a1
; 		movem.l	d0-d7,(a0)
; 		move.w	#(MAX_MDTSKARG*4),d0
; 		moveq	#1,d1
; 		moveq	#0,d2
; 		bra	sysMdMars_Transfer
;
; System_MdMars_SlvTask:
; 		lea	(RAM_MdMarsTsSgl),a0
; 		lea	(sysmars_reg+comm15),a1
; 		movem.l	d0-d7,(a0)
; 		move.w	#(MAX_MDTSKARG*4),d0
; 		moveq	#1,d1
; 		moveq	#1,d2
; 		bra	sysMdMars_Transfer
;
; ; ------------------------------------------------
; ; Queued tasks
; ; ------------------------------------------------
;
; System_MdMars_MstSendAll:
; 		lea	(RAM_MdMarsTskM),a0
; 		lea	(sysmars_reg+comm14),a1
; 		move.w	(RAM_MdMarsTCntM).w,d0
; 		clr.w	(RAM_MdMarsTCntM).w
; 		moveq	#1,d1
; 		moveq	#0,d2
; 		bra	sysMdMars_Transfer
;
; System_MdMars_SlvSendAll:
; 		lea	(RAM_MdMarsTskS),a0
; 		lea	(sysmars_reg+comm15),a1
; 		move.w	(RAM_MdMarsTCntS).w,d0
; 		clr.w	(RAM_MdMarsTCntS).w
; 		moveq	#1,d1
; 		moveq	#1,d2
; 		bra.s	sysMdMars_Transfer
;
; System_MdMars_MstSendDrop:
; 		lea	(RAM_MdMarsTskM),a0
; 		lea	(sysmars_reg+comm14),a1
; 		move.w	(RAM_MdMarsTCntM).w,d0
; 		moveq	#1,d1
; 		moveq	#0,d2
; 		nop
; 		nop
; 		move.b	(a1),d7
; 		and.w	#$80,d7
; 		beq.s	.go_m
; 		rts
; .go_m:		clr.w	(RAM_MdMarsTCntM).w
; 		bra	sysMdMars_Transfer
;
; System_MdMars_SlvSendDrop:
; 		lea	(RAM_MdMarsTskS),a0
; 		lea	(sysmars_reg+comm15),a1
; 		move.w	(RAM_MdMarsTCntS).w,d0
; 		moveq	#1,d1
; 		moveq	#1,d2
; 		nop
; 		nop
; 		move.b	(a1),d7
; 		and.w	#$80,d7
; 		beq.s	.go_s
; 		moveq	#-1,d7
; 		rts
; .go_s:		clr.w	(RAM_MdMarsTCntS).w
; 		bsr	sysMdMars_Transfer
; 		moveq	#0,d7
; 		rts
;
; ; a0 - task pointer and args
; ; a1 - task list counter
; sysMdMars_instask:
; 		cmp.w	#(MAX_MDTSKARG*MAX_MDTASKS)*4,(a1)
; 		bge.s	.ran_out
; 		adda.w	(a1),a0
; 		movem.l	d0-d7,(a0)		; Set variables to RAM (d0 is the label to jump)
; 		add.w	#MAX_MDTSKARG*4,(a1)
; .ran_out:
; 		rts
;
; ; ------------------------------------------------
; ; sysMdMars_Transfer
; ;
; ; a0 - Data to transfer
; ; a1 - Status byte from the target CPU
; ; d0 - Num of LONGS(4bytes) to transfer
; ; d1 - Transfer type ID
; ; d2 - CMD Interrupt bitset value
; ; 	($00-Master/$01-Slave)
; ; ------------------------------------------------
;
; sysMdMars_Transfer:
; 		nop
; 		nop
; 		move.b	(a1),d4
; 		and.w	#$80,d4
; 		bne.s	sysMdMars_Transfer
; 		lea	(sysmars_reg),a4
; 		move.w	sr,d5
; 		move.w	#$2700,sr		; Disable interrupts
; 		lea	comm8(a4),a3		; comm transfer method
; 		move.b	d1,(a3)			; Set MD task ID
; 		move.b	#$01,1(a3)		; Set SH as busy first
; 		move.w	standby(a4),d4		; Request CMD interrupt
; 		bset	d2,d4
; 		move.w	d4,standby(a4)
; .wait_cmd:	move.w	standby(a4),d4		; CMD cleared?
; 		btst    d2,d4
; 		bne.s   .wait_cmd
; .loop:
; 		cmpi.b	#2,1(a3)		; SH ready?
; 		bne.s	.loop
; 		move.w	d1,d4
; 		or.w	#$80,d4
; 		move.b	d4,(a3)			; MD is busy
; 		tst.w	d0
; 		beq.s	.exit
; 		bmi.s	.exit
; 		move.l	(a0),d4
; 		clr.l	(a0)+
; 		move.w	d4,4(a3)
; 		swap	d4
; 		move.w	d4,2(a3)
; 		move.w	d1,d4
; 		or.w	#$40,d4
; 		move.b	d4,(a3)			; MD is ready
; 		sub.w	#4,d0
; 		bra.s	.loop
; .exit:
; 		move.b	#0,(a3)			; MD finished
; 		move.w	d5,sr
; .mid_write:
; 		rts

; MdMars_FIFO:
; 		move.w	#$100,d4
; 		move.w	d4,($A15110).l
; 		move.b	#%100,($A15107).l
; loc_0_28E2:
; 		btst	#1,(sysmars_reg+comm14).l
; 		beq.s	loc_0_28E2
; 		bclr	#1,(sysmars_reg+comm14).l
; 		lea	($FF0000).l,a4
; 		lea	($A15112).l,a5
; 		lsr.w	#2,d4
; 		beq.s	.exit
; .fifo_blast:
; 		btst	#7,($A15107).l
; 		bne.s	.fifo_blast
; 		move.w	(a4)+,(a5)
; 		dbf	d4,.fifo_blast
; .exit:
; 		rts

; ====================================================================
; ----------------------------------------------------------------
; System data
; ----------------------------------------------------------------


