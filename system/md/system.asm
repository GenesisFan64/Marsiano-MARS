; ====================================================================
; ----------------------------------------------------------------
; Genesis system routines
; ----------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; RAM section
; ----------------------------------------------------------------

		struct RAM_MdSystem
RAM_InputData	ds.b sizeof_input*4		; Input data section
RAM_SaveData	ds.b $200			; SRAM data cache
RAM_DmaCode	ds.b $200
RAM_SysRandVal	ds.l 1				; Random value
RAM_SysRandSeed	ds.l 1				; Randomness seed
RAM_initflug	ds.l 1				; "INIT" flag
RAM_MdMarsVInt	ds.w 3				; VBlank jump (JMP xxxx xxxx)
RAM_MdMarsHint	ds.w 3				; HBlank jump (JMP xxxx xxxx)
RAM_MdVBlkWait	ds.w 1
RAM_SysFlags	ds.w 1				; Game engine flags (note: it's a byte)
sizeof_mdsys	ds.l 0
		finish

; ====================================================================
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
		move.w	#$4EF9,d0		; Set JMP opcode for the Hblank/VBlank jumps
 		move.w	d0,(RAM_MdMarsVInt).l
		move.w	d0,(RAM_MdMarsHInt).l
; 		move.l	#$56255769,d0		; Set these random values
; 		move.l	#$95116102,d1
; 		move.l	d0,(RAM_SysRandVal).l
; 		move.l	d1,(RAM_SysRandSeed).l
		move.l	#VInt_Default,d0	; Set default ints
		move.l	#Hint_Default,d1
		bsr	System_SetInts
		lea	(RAM_InputData),a0	; Clear input data buffer
		move.w	#sizeof_input-1/2,d1
		moveq	#0,d0
.clrinput:
		move.w	#0,(a0)+
		dbf	d1,.clrinput
		move.w	(sp)+,sr
		rts

; 		lea	(vdp_ctrl),a6
; .wait_in:	move.w	(a6),d4
; 		btst	#bitVBlk,d4
; 		beq.s	.wait_in
; .wait_out:	move.w	(a6),d4
; 		btst	#bitVBlk,d4
; 		bne.s	.wait_out
; 		bra	System_MarsUpdate

; --------------------------------------------------------
; System_WaitFrame
;
; Call this to wait until the next frame.
;
; Before entering VBlank:
; - The DREQ section from here will be transfered
; to the 32X side then processed on the next
; frame.
;
; Inside VBlank this will:
; - Update the controller inputs
; - Transfer the Genesis palette, sprites and scroll
;   data from from RAM to VDP
;   (Doesn't require the RV bit)
; --------------------------------------------------------

System_WaitFrame:
		lea	(vdp_ctrl),a6		; <-- VSync IN
.wait_lag:	move.w	(a6),d4
		btst	#bitVBlk,d4
		bne.s	.wait_lag
; 		bsr	Video_Mars_WaitFrame
		bsr	System_MarsUpdate
		lea	(vdp_ctrl),a6
.wait_in:	move.w	(a6),d4			; We are on DISPLAY, wait for VBlank
		btst	#bitVBlk,d4
		beq.s	.wait_in
		bsr	System_Input		; Read inputs FIRST
		lea	(vdp_ctrl),a6		; *** DMA'd Scroll and Palette
		move.w	#$8100,d7		; DMA ON
		move.b	(RAM_VdpRegs+1),d7
		bset	#bitDmaEnbl,d7
		move.w	d7,(a6)
		bsr	System_DmaEnter_RAM
		move.l	#$94009328,(a6)
		move.l	#$96009500|(RAM_VerScroll<<7&$FF0000)|(RAM_VerScroll>>1&$FF),(a6)
		move.w	#$9700|(RAM_VerScroll>>17&$7F),(a6)
		move.w	#$4000,(a6)
		move.w	#$0010|$80,-(sp)
		move.w	(sp)+,(a6)
		move.l	#$940193E0,(a6)
		move.l	#$96009500|(RAM_HorScroll<<7&$FF0000)|(RAM_HorScroll>>1&$FF),(a6)
		move.w	#$9700|(RAM_HorScroll>>17&$7F),(a6)
		move.w	#$7C00,(a6)
		move.w	#$0003|$80,-(sp)
		move.w	(sp)+,(a6)
		move.l	#$940193C0,(a6)
		move.l	#$96009500|(RAM_Sprites<<7&$FF0000)|(RAM_Sprites>>1&$FF),(a6)
		move.w	#$9700|(RAM_Sprites>>17&$7F),(a6)
		move.w	#$7800,(a6)
		move.w	#$0003|$80,-(sp)
		move.w	(sp)+,(a6)
		move.l	#$94009340,(a6)
		move.l	#$96009500|(RAM_Palette<<7&$FF0000)|(RAM_Palette>>1&$FF),(a6)
		move.w	#$9700|(RAM_Palette>>17&$7F),(a6)
		move.w	#$C000,(a6)
		move.w	#$0000|$80,-(sp)
		move.w	(sp)+,(a6)
		bsr	System_DmaExit_RAM
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1).w,d7
		move.w	d7,(a6)
		add.l	#1,(RAM_Framecount).l
		rts

; --------------------------------------------------------
; System_DmaEnter_(from) and System_DmaEnter_(from)
; (from): ROM or RAM
;
; Call to these labels BEFORE and AFTER doing
; DMA-to-VDP transers.
; These calls are not needed for FILL or COPY.
;
; ** For stock Genesis:
;  | The Z80 cannot read from ROM while the
;  | DMA ROM-to-VDP transfer is active.
;  | THIS INCLUDES RAM TRANSFERS
;  | ** Solution:
;  | STOP the Z80 entirely OR
;  | First stop, set a flag and turn ON the
;  | Z80 again, If the Z80 reads the flags it
;  | should be stuck on a loop until you clear
;  | the flag from here after finishing your
;  | DMA transfer(s)
;
; ** For the 32X:
;  | SAME rule for the Genesis, but this time the
;  | ROM-to-VDP transfer requires the RV bit to be set.
;  | (RAM transfers doesn't require this bit at all.)
;  | Setting the RV bit blocks the SH2 from accessing
;  | the ROM area, THIS ALSO affects the Z80.
;  | ** Solution:
;  | First, make sure the SH2 isn't reading from ROM
;  | while the bit is active, or it will read garbage
;  | data.
;  | In the case where you need to read from ROM
;  | a lot (Playing PWM's for example):
;  | First request an CMD interrupt and tell the
;  | SH2 to backup a small amount of sample data
;  | and temporally relocate the read point to the
;  | backup until you make another
;  | interrupt telling that you finished here and set
;  | RV back to 0.
;
; This is where you put your Sound driver's Z80 stop
; or pause calls go here
; --------------------------------------------------------

System_DmaEnter_RAM:
		bra	gemaDmaPause
System_DmaExit_RAM:
		bra	gemaDmaResume

; --------------------------------------------------------

System_DmaEnter_ROM:
		bra	gemaDmaPauseRom
System_DmaExit_ROM:
		bra	gemaDmaResumeRom

; ====================================================================
; ----------------------------------------------------------------
; 32X ONLY
; ----------------------------------------------------------------

; --------------------------------------------------------
; System_MarsUpdate
; --------------------------------------------------------

System_MarsUpdate:
	if MARS=1
		lea	(RAM_MdDreq),a0		; Send DREQ
		move.w	#sizeof_dreq,d0
		jmp	(System_RomSendDreq).l	; <-- external jump
	else
		rts
	endif

; --------------------------------------------------------
; System_GrabRamCode
;
; Send new code to the USER side of RAM and
; jump into it.
;
; Input:
; d0 - Location of the RAM code to copy
;      in the 880000/900000 areas
; --------------------------------------------------------

System_GrabRamCode:
	if MARS
		or.l	#$880000,d0
		move.l	d0,a0
		lea	(RAMCODE_USER),a1
		move.w	#$5000-1,d7	; TODO: make custom sizes.
.copyme2:
		move.b	(a0)+,(a1)+
		dbf	d7,.copyme2
		jmp	(RAMCODE_USER).l
	else
		rts
	endif

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; System_Input
;
; Reads data from the Controller ports
; *** CALL THIS ON VBLANK ONLY ***
; 
; Uses:
; d4-d6,a4-a6
; --------------------------------------------------------

System_Input:
; 		move.w	#$0100,(z80_bus).l
.wait:
; 		btst	#0,(z80_bus).l
; 		bne.s	.wait
		lea	(sys_data_1),a5		; a5 - BASE Genesis Input regs area
		lea	(RAM_InputData),a6	; a6 - Output
		bsr.s	.this_one
		adda	#2,a5
		adda	#sizeof_input,a6
; 		bsr.s	.this_one
; ; 		move.w	#0,(z80_bus).l
; 		rts

; --------------------------------------------------------	
; Read port
; 
; a5 - Current port
; a6 - Output data
; --------------------------------------------------------

.this_one:
		bsr	.pick_id
		move.b	d4,pad_id(a6)
		cmp.w	#$F,d4
		beq.s	.exit
		and.w	#$F,d4
		add.w	d4,d4
		move.w	.list(pc,d4.w),d5
		jmp	.list(pc,d5.w)
.exit:
		clr.b	pad_ver(a6)
		rts

; --------------------------------------------------------
; Grab ID
; --------------------------------------------------------

.list:
		dc.w .exit-.list	; $00
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .id_03-.list	; $03 - Mega mouse
		dc.w .exit-.list	; $04
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $08
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list
		dc.w .exit-.list	; $0C
		dc.w .id_0D-.list	; $0D - Genesis controller (3 or 6 button)
		dc.w .exit-.list
		dc.w .exit-.list	; $0F - No controller OR Master System controller (2 Buttons: 1(B),2(C))

; --------------------------------------------------------
; ID $03
;
; Mega Mouse
; --------------------------------------------------------

; *** NOT TESTED ON HARDWARE ***
.id_03:
		move.b	#$20,(a5)
		move.b	#$60,6(a5)
		btst	#4,(a5)
		beq.w	.invalid
		move.b	#$00,(a5)	; $0F
		nop
		nop
		move.b	#$20,(a5)	; $0F
		nop
		nop
		move.b	#$00,(a5)	; Yo | Xo | Ys | Xs
		nop
		nop
		move.b	(a5),d5		; d5 - X/Y direction bits (Ys Xs)
		move.b	#$20,(a5)	; C | M | R | L
		nop
		nop
		move.b	(a5),d7
 		and.w	#%1111,d7
		move.w	on_hold(a6),d6
		eor.w	d7,d6
		move.w	d7,on_hold(a6)
		and.w	d7,d6
		move.w	d6,on_press(a6)
		move.b	#$00,(a5)	; X7 | X6 | X5 | X4
		nop
		nop
		move.b	(a5),d7
		move.b	#$20,(a5)	; X3 | X2 | X1 | X0
		and.w	#%1111,d7
		lsl.w	#4,d7
		nop
		move.b	(a5),d6
		and.w	#%1111,d6
		or.w	d6,d7
		btst    #0,d5
		beq.s	.x_neg
		neg.b	d7
		neg.w	d7
.x_neg:
		move.w	d7,mouse_x(a6)
		move.b	#$00,(a5)	; Y7 | Y6 | Y5 | Y4
		nop
		nop
		move.b	(a5),d7
		move.b	#$20,(a5)	; Y3 | Y2 | Y1 | Y0
		and.w	#%1111,d7
		lsl.w	#4,d7
		nop
		move.b	(a5),d6
		and.w	#%1111,d6
		or.w	d6,d7
		btst    #1,d5
		beq.s	.y_neg
		neg.b	d7
		neg.w	d7
.y_neg:
		neg.w	d7		; Reverse Y
		move.w	d7,mouse_y(a6)

.invalid:
		move.b	#$60,(a5)
		rts

; --------------------------------------------------------
; ID $0D
; 
; Normal controller: 3 button or 6 button.
; --------------------------------------------------------

.id_0D:
		move.b	#$40,(a5)	; Show CB|RLDU
		nop
		nop
		move.b	(a5),d5
		and.w	#%00111111,d5
		move.b	#$00,(a5)	; Show SA|RLDU
		nop
		nop
		move.b	(a5),d4		; The following flips are for
		lsl.w	#2,d4		; the 6pad's internal counter:
		and.w	#%11000000,d4
		or.w	d5,d4
		move.b	#$40,(a5)	; Show CB|RLDU (2)
		not.w	d4
		move.b	on_hold+1(a6),d5
		eor.b	d4,d5
		move.b	#$00,(a5)	; Show SA|RLDU (3)
		move.b	d4,on_hold+1(a6)
		and.b	d4,d5
		move.b	d5,on_press+1(a6)
		move.b	#$40,(a5)	; 6 button responds (4)
		nop
		nop
		move.b	(a5),d4		; Grab ??|MXYZ
 		move.b	#$00,(a5)	; (5)
  		nop
  		nop
 		move.b	(a5),d6		; Type: $03 old, $0F new
 		move.b	#$40,(a5)	; (6)
 		nop
 		nop
		and.w	#$F,d6
		lsr.w	#2,d6
		and.w	#1,d6
		beq.s	.oldpad
		not.b	d4
 		and.w	#%1111,d4
		move.b	on_hold(a6),d5
		eor.b	d4,d5
		move.b	d4,on_hold(a6)
		and.b	d4,d5
		move.b	d5,on_press(a6)
.oldpad:
		move.b	d6,pad_ver(a6)
		rts
		
; --------------------------------------------------------
; Grab ID
; --------------------------------------------------------

.pick_id:
		moveq	#0,d4
		move.b	#%01110000,(a5)		; TH=1,TR=1,TL=1
		nop
		nop
		bsr	.read
		move.b	#%00110000,(a5)		; TH=0,TR=1,TL=1
		nop
		nop
		add.w	d4,d4
.read:
		move.b	(a5),d5
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
; Makes a random number.
; 
; Input:
; d0 | Seed
;
; Output:
; d0 | LONG
;
; Uses:
; d4-d5
; --------------------------------------------------------

System_Random:
		move.l	d4,-(sp)
		move.l	(RAM_SysRandSeed).l,d4
		bne.s	.good_s
		move.l	#$23B51947,d4
.good_s:
		move.l	d4,d0
		rol.l	#5,d4
		add.l	d0,d4
		asr.w	#3,d4
		add.l	d0,d4
		move.w	d4,d0
		swap	d4
		add.w	d4,d0
		move.w	d0,d4
		swap	d4
		move.l	d4,(RAM_SysRandSeed).l
		move.l	(sp)+,d4
		rts

; --------------------------------------------------------
; System_SineWave_Cos / System_SineWave
;
; Get sinewave value
;
; Input:
; d0 | WORD - Tan
; d1 | WORD - Multiply
;
; Output:
; d2 | LONG - Result (as 0000.0000)
; --------------------------------------------------------

; TODO: improve this.
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

; ====================================================================
; ----------------------------------------------------------------
; Screen mode subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Initialize current screen mode
; --------------------------------------------------------

Mode_Init:
		jsr	(Video_Clear).l
		lea	(RAM_ModeBuff),a4
		move.w	#(MAX_MDERAM/2)-1,d5
		moveq	#0,d4
.clr:
		move.w	d4,(a4)+
		dbf	d5,.clr

		lea	(RAM_MdDreq+Dreq_Objects),a4	; Patch
		move.w	#MAX_MODELS-1,d5
.clr_mdls:
		move.l	d4,mdl_data(a4)
		adda	#sizeof_mdlobj,a4
		dbf	d5,.clr_mdls

		move.w	#0,d0
		bra	Video_Mars_GfxMode

; --------------------------------------------------------

Mode_FadeOut:
		move.w	#2,(RAM_FadeMdReq).w
		move.w	#2,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#4,(RAM_FadeMarsIncr).w
		move.w	#0,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
.loopw:
		bsr	System_WaitFrame
		jsr	(Video_RunFade).l
		bne.s	.loopw
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
		add.l	#1,(RAM_FrameCount).l
		movem.l	(sp)+,d0-a6		
		rte

; --------------------------------------------------------
; HBlank
; --------------------------------------------------------

HInt_Default:
		rte

; ====================================================================
; ----------------------------------------------------------------
; System data
; ----------------------------------------------------------------
