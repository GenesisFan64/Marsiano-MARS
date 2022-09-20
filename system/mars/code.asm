; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 SDRAM section, shared for both CPUs
;
; Do note that both CPUs doesn't like each other, if both
; CPUs read/write the same place it will trigger a crash.
; ----------------------------------------------------------------

; *************************************************
; communication setup:
;
; comm0-comm7  - ** FREE ***
; comm8-comm11 - Used to transfer data manually
;                from Z80 to SH2 side, 68k uses DREQ.
; comm12       - Master CPU control
; comm14       - Slave CPU control
; *************************************************

		phase CS3	; Now we are at SDRAM
		cpu SH7600	; Should be SH7095 but this CPU mode works.

; CPU TEST MACRO
testme macro color
		mov	#color,r1
		mov	#_vdpreg,r2
		mov	#_vdpreg+bitmapmd,r3
-		mov.b	@(vdpsts,r2),r0
		tst	#HBLK,r0
		bt	-
		mov.b	r1,@r3
	endm

; ====================================================================
; ----------------------------------------------------------------
; Settings
; ----------------------------------------------------------------

SH2_DEBUG	equ 1			; Set to 1 too see if CPUs are active using comm counters (0 and 1)
STACK_MSTR	equ CS3|$40000
STACK_SLV	equ CS3|$3F000

; ====================================================================
; ----------------------------------------------------------------
; MARS GLOBAL gbr variables for both SH2
; ----------------------------------------------------------------

			struct 0
marsGbl_PlyPzList_R	ds.l 1	; Current graphic piece to draw
marsGbl_PlyPzList_W	ds.l 1	; Current graphic piece to write
marsGbl_PlyPzList_Start	ds.l 1	; Polygon pieces list Start point
marsGbl_PlyPzList_End	ds.l 1	; Polygon pieces list End point
marsGbl_CurrRdPlgn	ds.l 1	; Current polygon to read for slicing
marsGbl_CurrZList	ds.l 1	; Current Zsort entry
marsGbl_CurrZTop	ds.l 1	; Current Zsort list
marsGbl_CurrFacePos	ds.l 1	; Current top face of the list while reading model data
marsGbl_CurrNumFaces	ds.w 1	; and the number of faces stored on that list
marsGbl_WdgMode		ds.w 1	; Current watchdog task
marsGbl_WdgHold		ds.w 1	; Watchdog pause
marsGbl_WdgDivLock	ds.w 1	; Tell Watchdog we are mid-division.
marsGbl_PolyBuffNum	ds.w 1	; Polygon-list swap number
marsGbl_PlyPzCntr	ds.w 1	; Number of graphic pieces to draw
marsGbl_CntrRdPlgn	ds.w 1	; Number of polygons to slice
marsGbl_CntrRdSpr	ds.w 1	; Number of sprites to read
marsGbl_XShift		ds.w 1	; Xshift bit at the start of master_loop (TODO: a HBlank list)
marsGbl_MdDrawTmr	ds.w 1	; Screen init counter for redrawing the entire screen (Write $02)
marsGbl_WaveEnable	ds.w 1	; General linetable wave effect: Disable/Enable
marsGbl_WaveSpd		ds.w 1	; Linetable wave speed
marsGbl_WaveMax		ds.w 1	; Maximum wave
marsGbl_WaveDeform	ds.w 1	; Wave increment value
marsGbl_WaveTan		ds.w 1	; Linetable wave tan
marsGbl_GotDreq		ds.w 1
sizeof_MarsGbl		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MASTER CPU VECTOR LIST (vbr)
; ----------------------------------------------------------------

		align 4
SH2_Master:
		dc.l SH2_M_Entry,STACK_MSTR	; Power PC, Stack
		dc.l SH2_M_Entry,STACK_MSTR	; Reset PC, Stack
		dc.l SH2_M_ErrIllg		; Illegal instruction
		dc.l 0				; reserved
		dc.l SH2_M_ErrInvl		; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l SH2_M_ErrAddr		; CPU address error
		dc.l SH2_M_ErrDma		; DMA address error
		dc.l SH2_M_ErrNmi		; NMI vector
		dc.l SH2_M_ErrUser		; User break vector
		dc.l 0,0,0,0,0,0,0,0,0		; reserved
		dc.l 0,0,0,0,0,0,0,0,0
		dc.l 0
		dc.l SH2_M_Error		; Trap user vectors
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
		dc.l SH2_M_Error
 		dc.l master_irq		; Level 1 IRQ
		dc.l master_irq		; Level 2 & 3 IRQ
		dc.l master_irq		; Level 4 & 5 IRQ
		dc.l master_irq		; Level 6 & 7 IRQ: PWM interupt
		dc.l master_irq		; Level 8 & 9 IRQ: Command interupt
		dc.l master_irq		; Level 10 & 11 IRQ: H Blank interupt
		dc.l master_irq		; Level 12 & 13 IRQ: V Blank interupt
		dc.l master_irq		; Level 14 & 15 IRQ: Reset Button
	; ON-chip interrupts go here (vbr+$120)
		dc.l master_irq		; Watchdog (custom)
		dc.l master_irq		; DMA

; ====================================================================
; ----------------------------------------------------------------
; SLAVE CPU VECTOR LIST (vbr)
; ----------------------------------------------------------------

		align 4
SH2_Slave:
		dc.l SH2_S_Entry,STACK_SLV	; Cold PC,SP
		dc.l SH2_S_Entry,STACK_SLV	; Manual PC,SP
		dc.l SH2_S_ErrIllg		; Illegal instruction
		dc.l 0				; reserved
		dc.l SH2_S_ErrInvl		; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l SH2_S_ErrAddr		; CPU address error
		dc.l SH2_S_ErrDma		; DMA address error
		dc.l SH2_S_ErrNmi		; NMI vector
		dc.l SH2_S_ErrUser		; User break vector
		dc.l 0,0,0,0,0,0,0,0,0		; reserved
		dc.l 0,0,0,0,0,0,0,0,0
		dc.l 0
		dc.l SH2_S_Error		; Trap user vectors
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
		dc.l SH2_S_Error
 		dc.l slave_irq			; Level 1 IRQ
		dc.l slave_irq			; Level 2 & 3 IRQ
		dc.l slave_irq			; Level 4 & 5 IRQ
		dc.l slave_irq			; Level 6 & 7 IRQ: PWM interupt
		dc.l slave_irq			; Level 8 & 9 IRQ: Command interupt
		dc.l slave_irq			; Level 10 & 11 IRQ: H Blank interupt
		dc.l slave_irq			; Level 12 & 13 IRQ: V Blank interupt
		dc.l slave_irq			; Level 14 & 15 IRQ: Reset Button
	; ON-chip interrupts go here (vbr+$120)
		dc.l slave_irq			; Watchdog
		dc.l slave_irq			; DMA

; ====================================================================
; ----------------------------------------------------------------
; IRQ
;
; r0-r1 are saved first.
; ----------------------------------------------------------------

		align 4
master_irq:
		mov.l	r0,@-r15
		mov.l	r1,@-r15
		sts.l	pr,@-r15
		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov	r0,r1
		mov	#$F0,r0
		ldc	r0,sr
		mov	#int_m_list,r0
		add	r1,r0
		mov	@r0,r1
		jsr	@r1
		nop
		lds.l	@r15+,pr
		mov.l	@r15+,r1
		mov.l	@r15+,r0
		rte
		nop
		align 4

; ====================================================================
; ----------------------------------------------------------------
; IRQ
;
; r0-r1 are saved first
; ----------------------------------------------------------------

slave_irq:
		mov.l	r0,@-r15
		mov.l	r1,@-r15
		sts.l	pr,@-r15
		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov	r0,r1
		mov	#$F0,r0
		ldc	r0,sr
		mov	#int_s_list,r0
		add	r1,r0
		mov	@r0,r1
		jsr	@r1
		nop
		lds.l	@r15+,pr
		mov.l	@r15+,r1
		mov.l	@r15+,r0
		rte
		nop
		align 4
		ltorg

; ------------------------------------------------
; irq list
; ------------------------------------------------

		align 4
;				Level
int_m_list:
		dc.l m_irq_bad	; 0
		dc.l m_irq_bad	; 1
		dc.l m_irq_bad	; 2
		dc.l $C0000000	; 3 Watchdog (TOP code on Cache)
		dc.l m_irq_bad	; 4
		dc.l m_irq_dma	; 5 DMA
		dc.l m_irq_pwm	; 6
		dc.l m_irq_pwm	; 7
		dc.l m_irq_cmd	; 8
		dc.l m_irq_cmd	; 9
		dc.l m_irq_h	; A
		dc.l m_irq_h	; B
		dc.l m_irq_v	; C
		dc.l m_irq_v	; D
		dc.l m_irq_vres	; E
		dc.l m_irq_vres	; F
int_s_list:
		dc.l s_irq_bad	; 0
		dc.l s_irq_bad	; 1
		dc.l s_irq_bad	; 2
		dc.l $C0000000	; 3 Watchdog (TOP code on Cache)
		dc.l s_irq_bad	; 4
		dc.l s_irq_bad	; 5 DMA
		dc.l s_irq_pwm	; 6
		dc.l s_irq_pwm	; 7
		dc.l s_irq_cmd	; 8
		dc.l s_irq_cmd	; 9
		dc.l s_irq_h	; A
		dc.l s_irq_h	; B
		dc.l s_irq_v	; C
		dc.l s_irq_v	; D
		dc.l s_irq_vres	; E
		dc.l s_irq_vres	; F

; ====================================================================
; ----------------------------------------------------------------
; Error handler
; ----------------------------------------------------------------

; *** Only works on HARDWARE ***
;
; comm2: (CPU)(CODE)
; comm4: PC counter
;
;  CPU | The CPU who got the error:
;        $00 - Master
;        $01 - Slave
;
; CODE | Error type:
;	  -1: Unknown error
;	 $01: Illegal instruction
;	 $02: Invalid slot instruction
;	 $03: Address error
;	 $04: DMA error
;	 $05: NMI vector
;	 $06: User break

SH2_M_Error:
		bra	SH2_M_ErrCode
		mov	#0,r0
SH2_M_ErrIllg:
		bra	SH2_M_ErrCode
		mov	#1,r0
SH2_M_ErrInvl:
		bra	SH2_M_ErrCode
		mov	#2,r0
SH2_M_ErrAddr:
		bra	SH2_M_ErrCode
		mov	#3,r0
SH2_M_ErrDma:
		bra	SH2_M_ErrCode
		mov	#4,r0
SH2_M_ErrNmi:
		bra	SH2_M_ErrCode
		mov	#5,r0
SH2_M_ErrUser:
		bra	SH2_M_ErrCode
		mov	#6,r0
; r0 - value
SH2_M_ErrCode:
		mov	#_sysreg+comm2,r1
		mov.w	r0,@r1
		mov	#_sysreg+comm4,r1
		mov	@r15,r0
		mov	r0,@r1
		bra	*
		nop
		align 4

; ----------------------------------------------------

SH2_S_Error:
		bra	SH2_S_ErrCode
		mov	#0,r0
SH2_S_ErrIllg:
		bra	SH2_S_ErrCode
		mov	#-1,r0
SH2_S_ErrInvl:
		bra	SH2_S_ErrCode
		mov	#-2,r0
SH2_S_ErrAddr:
		bra	SH2_S_ErrCode
		mov	#-3,r0
SH2_S_ErrDma:
		bra	SH2_S_ErrCode
		mov	#-4,r0
SH2_S_ErrNmi:
		bra	SH2_S_ErrCode
		mov	#-5,r0
SH2_S_ErrUser:
		bra	SH2_S_ErrCode
		mov	#-6,r0
; r0 - value
SH2_S_ErrCode:
		mov	#_sysreg+comm2,r1
		mov.w	r0,@r1
		mov	#_sysreg+comm4,r1
		mov	@r15,r0
		mov	r0,@r1
		bra	*
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Interrupts
; ----------------------------------------------------------------

; =================================================================
; ------------------------------------------------
; Master | Unused interrupt
; ------------------------------------------------

		align 4
m_irq_bad:
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | PWM Interrupt
; ------------------------------------------------

m_irq_pwm:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | CMD Interrupt
; ------------------------------------------------

	; *** HARDWARE NOTE ***
	; DMA takes a little to start properly:
	; after writing _DMAOPERATION = 1 put
	; 2 instructions (or 2 nops) in case
	; you need to manually check if the
	; DMA it's active.
	;
	; On Emulators it just starts right away.
m_irq_cmd:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1	; Clear CMD flag
		mov.w	r0,@r1
		mov.w	@r1,r0
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	#_sysreg,r4		; r4 - sysreg base
		mov	#_DMASOURCE0,r3		; r3 - DMA base register
		mov	#_sysreg+comm12,r2	; r2 - comm to write the signal
		mov	#_sysreg+dreqfifo,r1	; r1 - Source point: DREQ FIFO
		mov	#0,r0			; _DMAOPERATION = 0
		mov	r0,@($30,r3)
		mov	#%0100010011100000,r0	; Transfer mode + DMA enable bit OFF
		mov	r0,@($C,r3)
		mov	#RAM_Mars_DreqDma,r0
		mov	r0,@(4,r3)		; Destination
		mov.w	@(dreqlen,r4),r0	; TODO: needs a 0-size check.
		extu.w	r0,r0
		mov	r0,@(8,r3)		; Length (set by 68k)
		mov	r1,@r3			; Source
		mov	#%0100010011100101,r0	; Transfer mode + DMA enable bit ON + Enable interrupt
		mov	r0,@($C,r3)		; Dest:Incr(01) Src:Keep(00) Size:Word(01)
		mov	#1,r0			; _DMAOPERATION = 1
		mov	r0,@($30,r3)
		mov.b	@r2,r0			; Tell Genesis we can recieve DREQ data
		or	#%01000000,r0
		mov.b	r0,@r2
; .wait_dma:	mov	@($C,r3),r0		; Still on DMA?
; 		tst	#%10,r0
; 		bt	.wait_dma
; 		mov	#0,r0			; _DMAOPERATION = 0
; 		mov	r0,@($30,r3)
; 		mov	#%0100010011100000,r0	; Transfer mode + DMA enable = 0
; 		mov	r0,@($C,r3)
; .wait_dis:
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		rts
		nop
		align 4

; ------------------------------------------------
; Master | DMA Exit
; ------------------------------------------------

		align 4
m_irq_dma:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_DMASOURCE0,r1
.wait_dma:	mov	@($C,r1),r0		; Still on DMA?
		tst	#%10,r0
		bt	.wait_dma
		mov	#0,r0			; _DMAOPERATION = 0
		mov	r0,@($30,r1)
		mov	#%0100010011100000,r0	; Transfer mode + DMA enable = 0
		mov	r0,@($C,r1)
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | HBlank
; ------------------------------------------------

m_irq_h:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+hintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | VBlank
; ------------------------------------------------

m_irq_v:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+vintclr,r1
		mov.w	r0,@r1

; 		mov	#_vdpreg,r1			; Check if we got here
; -		mov.b	@(vdpsts,r1),r0			; too late.
; 		tst	#VBLK,r0
; 		bt	-
; 		xor	r0,r0
; 		mov.w	r0,@(marsGbl_FrameReady,gbr)
; 		mov	r2,@-r15
; 		mov	r3,@-r15
; 		mov	r4,@-r15
;  		mov.w	@(marsGbl_XShift,gbr),r0	; Set SHIFT bit first
; 		mov	#_vdpreg+shift,r1		; For the indexed-scrolling mode.
; 		and	#1,r0
; 		mov.w	r0,@r1
; 		mov	#RAM_Mars_DreqRead+Dreq_Palette,r1
; 		mov	#_palette,r2
;  		mov	#(256/8),r3
; .copy_pal:
; 	rept 4
; 		mov	@r1+,r0				; Copy as LONGs, works on HW
; 		mov	r0,@r2
; 		add	#4,r2
; 	endm
; 		dt	r3
; 		bf	.copy_pal
; .not_ready:
; 		mov	#_sysreg+comm12+1,r1		; Clear comm R bit
; 		mov.b	@r1,r0				; this tells to 68k that the frame is ready.
; 		and	#%10111111,r0
; 		mov.b	r0,@r1
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | VRES Interrupt (RESET button on Genesis)
; ------------------------------------------------

m_irq_vres:
		mov	#_sysreg,r1
		mov	r15,r0
		mov.w	r0,@(vresintclr,r1)
		mov	#_DMASOURCE0,r1
		mov	#0,r0
		mov	r0,@($30,r1)
		mov	#%0100010011100000,r0
		mov	r0,@($C,r1)
		mov	#_DMASOURCE1,r1
		mov	#0,r0
		mov	r0,@($30,r1)
		mov	#%0100010011100000,r0
		mov	r0,@($C,r1)

		mov	#_sysreg,r1
		mov.w	@(dreqctl,r1),r0
		tst	#1,r0
		bf	.rv_busy
		mov	#(CS3|$40000)-8,r15
		mov	#SH2_M_HotStart,r0
		mov	r0,@r15
		mov.w   #$F0,r0
		mov	r0,@(4,r15)
		mov	#_sysreg,r1
		mov	#"M_OK",r0
		mov	r0,@(comm0,r1)
		rte
		nop
		align 4
.rv_busy:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		bra	*
		nop
		align 4
		ltorg		; Save literals

; =================================================================
; ------------------------------------------------
; Slave | Unused Interrupt
; ------------------------------------------------

		align 4
s_irq_bad:
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | PWM Interrupt
; ------------------------------------------------

; check cache_slv.asm
; s_irq_pwm:

; =================================================================
; ------------------------------------------------
; Slave | CMD Interrupt
; ------------------------------------------------

		align 4
s_irq_cmd:
		mov	.tag_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1	; Clear CMD flag
		mov.w	r0,@r1
		mov.w	@r1,r0

	; ---------------------------------
		mov	#_sysreg+comm14,r1
		mov.b	@r1,r0			; MSB only
		and	#%00001111,r0
		tst	r0,r0
		bt	.go_exit
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		mov	r10,@-r15
		mov	r11,@-r15
		mov	r12,@-r15
		mov	r13,@-r15
		mov	r14,@-r15
		sts	macl,@-r15
		sts	mach,@-r15
		sts	pr,@-r15
		shll2	r0
		mov	#.list,r1
		add	r0,r1
		mov	@r1,r0
		jmp	@r0
		nop
		align 4
.go_exit:
		bra	.no_cmdtask
		nop
		align 4
.tag_F0:	dc.l $F0
.tag_FRT:	dc.l _FRT

; ---------------------------------

.list:
		dc.l .no_trnsfrex
		dc.l .mode_1		; PWM transfer from Z80
		dc.l .mode_2		; PWM backup enter
		dc.l .mode_3		; PWM backup exit
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex
		dc.l .no_trnsfrex

; ---------------------------------
; CMD Mode 2: PWM Backup enter
; ---------------------------------

.mode_2:
		mov	#MarsSnd_Refill,r0
		jsr	@r0
		nop
		mov	#MarsSnd_RvMode,r1	; Set backup-playback flag
		mov	#1,r0
		mov	r0,@r1
		mov	#_sysreg+comm14,r1
		mov	#0,r0
		bra	.no_trnsfrex
		mov.b	r0,@r1
		align 4

; ---------------------------------
; CMD Mode 3: PWM Backup exit
; ---------------------------------

.mode_3:
		mov	#MarsSnd_RvMode,r1	; Clear backup-playback flag
		mov	#0,r0
		mov	r0,@r1
		mov	#_sysreg+comm14,r1
		mov	#0,r0
		bra	.no_trnsfrex
		mov.b	r0,@r1
		align 4

; ---------------------------------
; CMD Mode 1: Z80 transfer
; AND process new PWM's
; ---------------------------------

.mode_1:
	; First we recieve changes from Z80
	; using comm8  for data
	;  and  comm14 for busy/clock bits (bits 7,6)
		mov	#_sysreg+comm8,r1	; Input
		mov	#MarsSnd_PwmControl,r2	; Output
		mov	#_sysreg+comm14,r3	; control comm
.wait_1:
		mov.b	@r3,r0
		tst	#%10000000,r0		; Z80 enter/exit
		bt	.exit_c
		tst	#%01000000,r0		; wait CLOCK
		bt	.wait_1
.copy_1:
		mov	@r1,r0
		mov	r0,@r2
		add	#4,r2
		mov.b	@r3,r0			; CLK done
		and	#%10111111,r0
		mov.b	r0,@r3
		bra	.wait_1
		nop
.exit_c:

	; Now loop for channels that need updating
	;
	; TODO: rushed... but it works.
		mov	#0,r1				; r1 - Current PWM slot
		mov	#MarsSnd_PwmControl,r14
		mov	#MAX_PWMCHNL,r10
.next_chnl:
		mov.b	@r14,r0
		and	#$FF,r0
		cmp/eq	#0,r0
		bt	.no_req2
		xor	r13,r13
		mov.b	r13,@r14
		mov	r0,r7
		and	#%111,r0
		cmp/eq	#%001,r0
		bt	.no_keyoff
		cmp/eq	#%010,r0
		bt	.pwm_keyoff
		cmp/eq	#%100,r0
		bt	.pwm_keycut
		bra	.no_req
		nop
.pwm_keyoff:
		mov	#$40,r2
		mov	#MarsSound_SetVolume,r0
		jsr	@r0
		nop
.no_req2:
		bra	.no_req
		nop
.pwm_keycut:
		mov	#0,r2
		mov	#MarsSound_PwmEnable,r0
		jsr	@r0
		nop
		bra	.no_req
		nop
		align 4
	; Normal playback
.no_keyoff:
		mov	r7,r0
		tst	#$10,r0
		bt	.no_pitchbnd
		mov	r14,r13
		add	#8,r13		; skip COM
		mov.b	@r13,r0		; r2 - Get pitch MSB bits
		add	#8,r13
		and	#%11,r0
		shll8	r0
		mov	r0,r2
		mov.b	@r13,r0		; Pitch LSB
		add	#8,r13
		and	#$FF,r0
		or	r2,r0
		mov	r0,r2
		mov	#MarsSound_SetPwmPitch,r0
		jsr	@r0
		nop
.no_pitchbnd:
		mov	r7,r0
		tst	#$20,r0
		bt	.no_volumebnd
		mov	r0,r7
		mov	r14,r13
		add	#8,r13		; point to volume values
		mov.b	@r13,r0
		and	#%11111100,r0	; skip MSB pitch bits
		mov	r0,r2
		mov	#MarsSound_SetVolume,r0
		jsr	@r0
		nop
.no_volumebnd:
		mov	r7,r0
		tst	#$01,r0		; key-on?
		bt	.no_req
		mov	r14,r13
		add	#8,r13		; skip COM
		mov.b	@r13,r0
		add	#8,r13
		mov	r0,r5
		and	#%11111100,r0	; skip MSB pitch bits
		mov	r0,r6		; r6 - Volume
		mov	r5,r0		; r5 - Get pitch MSB bits
		and	#%00000011,r0
		shll8	r0
		mov	r0,r5
		mov.b	@r13,r0		; Pitch LSB
		add	#8,r13
		and	#$FF,r0
		or	r5,r0
		mov	r0,r5
		mov.b	@r13,r0		; flags | SH2 BANK
		add	#8,r13
		mov	r0,r7		; r7 - Flags
		and	#%1111,r0
		mov	r0,r8		; r8 - SH2 section (ROM or SDRAM)
		shll16	r8
		shll8	r8
		shlr2	r7
		shlr2	r7
		mov.b	@r13,r0		; r2 - START point
		add	#8,r13
		and	#$FF,r0
		shll16	r0
		mov	r0,r3
		mov.b	@r13,r0
		add	#8,r13
		and	#$FF,r0
		shll8	r0
		mov	r0,r2
		mov.b	@r13,r0
		add	#8,r13
		and	#$FF,r0
		or	r3,r0
		or	r2,r0
		mov	r0,r2
		mov	r2,r4		; r4 - START copy
		or	r8,r2		; add CS2
		mov.b	@r2+,r0		; r3 - Length
		and	#$FF,r0
		mov	r0,r3
		mov.b	@r2+,r0
		and	#$FF,r0
		shll8	r0
		or	r0,r3
		mov.b	@r2+,r0
		and	#$FF,r0
		shll16	r0
		or	r0,r3
		add	r4,r3		; add end+start
		or	r8,r3		; add CS2
		mov.b	@r2+,r0		; get loop point
		and	#$FF,r0
		mov	r0,r4
		mov.b	@r2+,r0
		and	#$FF,r0
		shll8	r0
		or	r0,r4
		mov.b	@r2+,r0
		and	#$FF,r0
		shll16	r0
		or	r0,r4
		mov	#%11111100,r0
		and	r0,r8
		mov	#MarsSound_SetPwm,r0
		jsr	@r0
		nop
.no_req:
		add	#1,r1		; next PWM slot
		dt	r10
		bt	.end_chnls
		bra	.next_chnl
		add	#1,r14		; next PWM entry
.end_chnls:
	; ---------------------------------
	; *** END of PWM driver for GEMA
	; ---------------------------------

.no_trnsfrex:
		lds	@r15+,pr
		lds	@r15+,mach
		lds	@r15+,macl
		mov	@r15+,r14
		mov	@r15+,r13
		mov	@r15+,r12
		mov	@r15+,r11
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
.no_cmdtask:
		rts
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Slave | HBlank
; ------------------------------------------------

s_irq_h:
; 		mov	#$F0,r0
; 		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+hintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | VBlank
; ------------------------------------------------

s_irq_v:
; 		mov	#$F0,r0
; 		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+vintclr,r1
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | VRES Interrupt (RESET button on Genesis)
; ------------------------------------------------

s_irq_vres:
		mov	#_sysreg,r1
		mov	r15,r0
		mov.w	r0,@(vresintclr,r1)
		mov	#_DMASOURCE0,r1
		mov	#0,r0
		mov	r0,@($30,r1)
		mov	#%0100010011100000,r0
		mov	r0,@($C,r1)
		mov	#_sysreg,r1
		mov.w	@(dreqctl,r1),r0
		tst	#1,r0
		bf	.rv_busy
		mov	#(CS3|$3F000)-8,r15
		mov	#SH2_S_HotStart,r0
		mov	r0,@r15
		mov.w   #$F0,r0
		mov	r0,@(4,r15)
		mov	#_sysreg,r1
		mov	#"S_OK",r0
		mov	r0,@(comm4,r1)
; 		mov	#_DMAOPERATION,r1
; 		mov     #0,r0
; 		mov	r0,@r1
; 		mov	#_DMACHANNEL0,r1
; 		mov     #0,r0
; 		mov	r0,@r1
; 		mov	#$44E0,r1
; 		mov	r0,@r1
		rte
		nop
		align 4
.rv_busy:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		bra	*
		nop
		align 4
		ltorg		; Save literals

; ; =================================================================
; ; ------------------------------------------------
; ; Master | Watchdog interrupt
; ; ------------------------------------------------
;
; ; m_irq_wdg:
; ; check cache_m_plgn.asm
;
; ; =================================================================
; ; ------------------------------------------------
; ; Slave | Watchdog interrupt
; ; ------------------------------------------------
;
; 		align 4
; s_irq_wdg:
; ; 		mov	#$F0,r0
; ; 		ldc	r0,sr
; 		mov	r2,@-r15
; 		mov	#_FRT,r1
; 		mov.b   @(7,r1),r0
; 		xor     #2,r0
; 		mov.b   r0,@(7,r1)
;
; 		mov	#$FFFFFE80,r1
; 		mov.w   #$A518,r0		; Watchdog OFF
; 		mov.w   r0,@r1
; 		or      #$20,r0			; ON again
; 		mov.w   r0,@r1
; 		mov	#$10,r2
; 		mov.w   #$5A00,r0		; Timer for the next one
; 		or	r2,r0
; 		mov.w	r0,@r1
;
; 		mov	@r15+,r2
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Mars_ClearCacheRam
;
; Clear the entire "fast code" section for the current CPU
; ----------------------------------------------------------------

		align 4
Mars_ClearCacheRam:
		mov.l	#$C0000000+$800,r1
		mov	#0,r0
		mov.w	#$80,r2
.loop:
		mov	r0,@-r1
		mov	r0,@-r1
		mov	r0,@-r1
		mov	r0,@-r1
		dt	r2
		bf	.loop
		rts
		nop
		align 4

; ----------------------------------------------------------------
; Mars_LoadCacheRam
;
; Loads "fast code" into the SH2's cache, $800 bytes maximum.
;
; Input:
; r1 - CACHE Code to send
; r2 - Size/4
;
; Breaks:
; r3
; ----------------------------------------------------------------

		align 4
Mars_LoadCacheRam:
		stc	sr,@-r15	; Interrupts OFF
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_CCR,r3
		mov	#%00010000,r0	; Cache purge + Disable
		mov.w	r0,@r3
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		mov	#%00001001,r0	; Cache two-way mode + Enable
		mov.w	r0,@r3
		mov 	#$C0000000,r3
.copy:
		mov 	@r1+,r0
		mov 	r0,@r3
		dt	r2
		bf/s	.copy
		add 	#4,r3
		rts
		ldc	@r15+,sr
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; MARS System features
; ----------------------------------------------------------------

		include "system/mars/video.asm"
		include "system/mars/sound.asm"
		align 4

; ====================================================================
; ----------------------------------------------------------------
; Master entry
; ----------------------------------------------------------------

		align 4
SH2_M_Entry:
		mov	#STACK_MSTR,r15			; Reset stack
		mov	#SH2_Master,r0			; Reset vbr
		ldc	r0,vbr
		mov.l	#_FRT,r1
		mov	#0,r0
		mov.b	r0,@(0,r1)
		mov.b	#$E2,r0
		mov.b	r0,@(7,r1)
		mov	#0,r0
		mov.b	r0,@(4,r1)
		mov	#1,r0
		mov.b	r0,@(5,r1)
		mov	#0,r0
		mov.b	r0,@(6,r1)
		mov	#1,r0
		mov.b	r0,@(1,r1)
		mov	#0,r0
		mov.b	r0,@(3,r1)
		mov.b	r0,@(2,r1)
; 		mov.b	#$F2,r0			; <-- not needed here
; 		mov.b	r0,@(7,r1)
; 		mov	#0,r0
; 		mov.b	r0,@(4,r1)
; 		mov	#1,r0
; 		mov.b	r0,@(5,r1)
; 		mov.b	#$E2,r0
; 		mov.b	r0,@(7,r1)

	; Extra interrupt settings
		mov.w   #$FEE2,r0			; Extra interrupt priority levels ($FFFFFEE2)
		mov     #(3<<4)|(5<<8),r1		; (DMA_LVL<<8)|(WDG_LVL<<4) Current: WDG 3 DMA 5
		mov.w   r1,@r0
		mov.w   #$FEE4,r0			; Vector jump number for Watchdog ($FFFFFEE4)
		mov     #($120/4)<<8,r1			; (vbr+POINTER)<<8
		mov.w   r1,@r0
		mov	#-$60,r0			; Vector jump number for DMACHANNEL0 ($FFFFFFA0)
		mov     #($124/4),r1			; (vbr+POINTER)
		mov	r1,@r0

		mov	#RAM_Mars_Global,r0		; Reset gbr
		ldc	r0,gbr
		mov	#MarsVideo_Init,r0		; Init Video
		jsr	@r0
		nop

; ====================================================================
; ----------------------------------------------------------------
; Master main code
;
; This CPU is exclusively used for the visuals:
; software-rendered backgrounds, sprites and polygons.
; ----------------------------------------------------------------

; HARDWARE NOTE: If the 68k and/or Z80 requested any of both
; CMD interrupts in the middle of Soft-Reset (RESET button) the
; interrupt will get stuck on "pending" and any new requests will
; not gonna happen.
; The workaround is to write intmask to 0 then set back again the
; interrupt bits that you are going to use.
; (this applies for BOTH SH2)

SH2_M_HotStart:
		mov	#$FFFFFE80,r1
		mov.w	#$A518,r0		; Disable Watchdog
		mov.w	r0,@r1
		mov	#_CCR,r1		; Reset CACHE
		mov	#$10,r0
		mov.b	r0,@r1
		nop
		nop
		nop
		nop
		nop
		xor	r0,r0
		mov	#_sysreg+comm12,r2
		mov.w	r0,@r2
		mov	#9,r0
		mov.b	r0,@r1
		bsr	Mars_ClearCacheRam
		nop
		mov	#_sysreg,r1
		mov.w	@r1,r0
		or	#CMDIRQ_ON,r0
		mov.w	r0,@r1
;     		mov	#0,r0
; 		mov.w	r0,@(vresintclr,r1)
; 		mov.w	r0,@(vintclr,r1)
; 		mov.w	r0,@(hintclr,r1)
; 		mov.w	r0,@(cmdintclr,r1)
; 		mov.w	r0,@(pwmintclr,r1)
		mov	#_sysreg+comm8,r1
		mov.w	@r1,r0
.wait_md:	tst	r0,r0
		bf	.wait_md
		mov	#_sysreg+comm14,r1
.wait_slv:	mov.w	@r1,r0
		tst	r0,r0
		bf	.wait_slv
		mov	#$20,r0				; Interrupts ON
		ldc	r0,sr
		bra	master_loop
		nop
		align 4
		ltorg

; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_WaveEnable,gbr)	; *** TEMPORAL
; 		mov	#16,r0
; 		mov.w	r0,@(marsGbl_WaveSpd,gbr)	; ***
; 		mov	#8,r0
; 		mov.w	r0,@(marsGbl_WaveMax,gbr)	; ***
; 		mov	#16,r0
; 		mov.w	r0,@(marsGbl_WaveDeform,gbr)	; ***

; ----------------------------------------------------------------
; MASTER CPU loop
;
; comm12:
; bssscccc iir00lll
;
; b - Busy bit, this CPU can't be interrupted for CMD requests
; r - Clears when frame is ready.
; s - Status bits for some of the CMD interrupt tasks
; c - Command number for CMD interrupt
; i - Screen initialization bit(s)
; l - MAIN LOOP command/task, For any mode change fill the
;     ii bits: $C0+mode.
; ----------------------------------------------------------------

		align 4
master_loop:
	if SH2_DEBUG
		mov	#_sysreg+comm0,r1		; DEBUG counter
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1
	endif
	; ---------------------------------------
		mov	#_vdpreg,r1			; Check if we got late
.waitl:		mov.b	@(vdpsts,r1),r0			; on VBlank
		tst	#VBLK,r0
		bf	.waitl
		stc	sr,@-r15
		mov	#$F0,r0
		ldc	r0,sr
		mov	#RAM_Mars_DreqDma,r1		; Copy DREQ data into a safe
		mov	#RAM_Mars_DreqRead,r2		; location for reading
		mov	#sizeof_dreq/4,r3
.copy_safe:
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.copy_safe
		add	#4,r2
		ldc	@r15+,sr

	; ---------------------------------------
		mov	#_vdpreg,r1			; Now wait for VBlank.
.waitv:		mov.b	@(vdpsts,r1),r0
		tst	#VBLK,r0
		bt	.waitv
 		mov.w	@(marsGbl_XShift,gbr),r0	; Set SHIFT bit first
		mov	#_vdpreg+shift,r1		; For the indexed-scrolling mode.
		and	#1,r0
		mov.w	r0,@r1
		mov	#RAM_Mars_DreqRead+Dreq_Palette,r1
		mov	#_palette,r2
 		mov	#(256/8),r3
.copy_pal:
	rept 4
		mov	@r1+,r0				; Copy colors as LONGs, works on HW.
		mov	r0,@r2
		add	#4,r2
	endm
		dt	r3
		bf	.copy_pal
.not_ready:
		mov	#_sysreg+comm12+1,r1		; Clear comm R bit
		mov.b	@r1,r0				; this tells to 68k that the frame is ready
		and	#%11011111,r0
		mov.b	r0,@r1

; ---------------------------------------
; Init/Loop the current mode
;
; Init uses 2 separate jumps in case
; some routines need to be called twice.
; (Framebuffer updates)
;
; NOTE:
; The LOOP part starts very early at
; VBlank, add some work to make sure it
; exits on display.
; ---------------------------------------

		mov	#%00000011,r5		; <-- current modes limit (0-3)
		mov	#_sysreg+(comm12+1),r4
		mov	#%11000000,r3
		mov	#0,r1
		mov.b	@r4,r0			; r0 - bit check
		exts.w	r0,r0
		cmp/pz	r0
		bt	.no_init
		extu.b	r0,r1
		mov	r1,r2
		shll	r2
		and	r3,r2
		and	r3,r1
		and	r5,r0
		add	r2,r0
		mov.b	r0,@r4
		shlr2	r1
		shlr2	r1
.no_init:
		and	r5,r0
		shll2	r0
		shll2	r0
		add	r1,r0
		mov	#mstr_gfxlist,r1
		mov	@(r1,r0),r1
		jmp	@r1
		nop
		align 4
		ltorg

; ---------------------------------------
; jump lists
;
; NOTE: the LOOP parts starts at
; very top of VBlank.

		align 4
mstr_gfxlist:	dc.l mstr_gfx0_loop	; $00
		dc.l mstr_gfx0_hblk
		dc.l mstr_gfx0_init_2
		dc.l mstr_gfx0_init_1
		dc.l mstr_gfx1_loop	; $01
		dc.l mstr_gfx1_hblk
		dc.l mstr_gfx1_init_2
		dc.l mstr_gfx1_init_1
		dc.l mstr_gfx2_loop	; $02
		dc.l mstr_gfx2_hblk
		dc.l mstr_gfx2_init_2
		dc.l mstr_gfx2_init_1
		dc.l mstr_gfx3_loop	; $03
		dc.l mstr_gfx3_hblk
		dc.l mstr_gfx3_init_2
		dc.l mstr_gfx3_init_1

; ============================================================
; ---------------------------------------
; Pseudo-screen mode $00: BLANK
;
; YOU must use set this mode if you are
; doing using these VDP settings
; on the Genesis side:
;
; - H32 mode
; - Double interlace mode
;   (both H32 and H40)
; ---------------------------------------

		align 4

; -------------------------------
; HBlank
; -------------------------------

mstr_gfx0_hblk:
		rts
		nop
		align 4

; -------------------------------
; Init
; -------------------------------

mstr_gfx0_init_2:
		mov 	#_vdpreg,r1
		mov	#0,r0
		mov.b	r0,@(bitmapmd,r1)
mstr_gfx0_init_1:
; 		mov	#$200,r1
; 		mov	#511,r2
; 		mov	#240,r3
; 		mov	#0,r4
; 		mov	#MarsVideo_ClearScreen,r0
; 		jsr	@r0
; 		nop
; 		mov	#_vdpreg,r1		; In case we are still on VBlank...
; -		mov.b	@(vdpsts,r1),r0
; 		tst	#VBLK,r0
; 		bf	-
; 		mov	#_vdpreg,r1		; Framebuffer swap REQUEST
; 		mov.b	@(framectl,r1),r0
; 		xor	#1,r0
; 		mov.b	r0,@(framectl,r1)

; -------------------------------
; Loop
; -------------------------------

mstr_gfx0_loop:
		bra	mstr_ready
		nop
		align 4

; ============================================================
; ---------------------------------------
; Pseudo-screen mode $01:
;
; Super Sprites ONLY
; ---------------------------------------

		align 4

; -------------------------------
; HBlank
; -------------------------------

mstr_gfx1_hblk:
		rts
		nop
		align 4

; -------------------------------
; Init
; -------------------------------

; -------------------------------
; Init
; -------------------------------

mstr_gfx1_init_1:
		mov	#CACHE_MSTR_SCRL,r1		; Load CACHE code
		mov	#(CACHE_MSTR_SCRL_E-CACHE_MSTR_SCRL)/4,r2
		mov	#Mars_LoadCacheRam,r0
		jsr	@r0
		nop
		bra	mstr_gfx1_cont
		nop
mstr_gfx1_init_2:
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
mstr_gfx1_cont:
		mov	#$200,r1
		mov	#512,r2
		mov	#240,r3
		mov	#MarsVideo_MakeNametbl,r0
		jsr	@r0
		mov	#0,r4

; -------------------------------
; Loop
; -------------------------------

mstr_gfx1_loop:
		mov	#$200,r1		; *** This also counts as a delay for Watchdog ***
		mov	#(320+16)/2,r2
		mov	#240,r3
		mov	#MarsVideo_ClearScreen,r0
		jsr	@r0
		mov	#0,r4
		mov	#$200,r1
		mov	#0,r2
		mov	#0,r3
		mov	#512,r4
		mov	#240,r5
		mov	#512*240,r6
		mov	#Cach_Intrl_Size,r7
		mov	#MarsVideo_SetSuperSpr,r0
		jsr	@r0
		nop
		mov	#MarsVideo_DrawSuperSpr_M,r0	; Draw Super Sprites
		jsr	@r0
		nop
		mov	#_vdpreg,r1			; Framebuffer swap REQUEST
		mov.b	@(framectl,r1),r0
		xor	#1,r0
		mov.b	r0,@(framectl,r1)

		bra	mstr_ready
		nop
		align 4
		ltorg

; ============================================================
; ---------------------------------------
; Pseudo-screen mode $02:
;
; 256-color smooth scrolling map
; ---------------------------------------

		align 4

; -------------------------------
; HBlank
; -------------------------------

mstr_gfx2_hblk:
		rts
		nop
		align 4

; -------------------------------
; Init
; -------------------------------

mstr_gfx2_init_1:
		mov	#CACHE_MSTR_SCRL,r1			; Load CACHE code
		mov	#(CACHE_MSTR_SCRL_E-CACHE_MSTR_SCRL)/4,r2
		mov	#Mars_LoadCacheRam,r0
		jsr	@r0
		nop

	; *** Create scrolling Section 0
		mov	#0,r1			; Make a scrolling section
		mov	#$200,r2		; Framebuffer VRAM position
		mov	#320,r3
		mov	#224,r4
		bsr	MarsVideo_MkScrlField
		mov	#16,r5			; <-- expand size
		mov	#RAM_Mars_DreqRead+Dreq_BgExBuff,r14
		mov	#RAM_Mars_ScrlBuff,r13
		mov	#MarsVideo_DrwMapData,r0
		jsr	@r0
		nop
		bra	mstr_gfx2_init_cont
		nop

mstr_gfx2_init_2:
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
mstr_gfx2_init_cont:

	; Copy-paste the entire pixel data
		mov	#RAM_Mars_ScrlBuff,r14
		mov	#RAM_Mars_ScrlData,r1
		mov	#_framebuffer,r2
		mov	@(scrl_fbdata,r14),r0
		add	r0,r2
		mov	#(((320+16)*(224+16))+320)/4,r3
		mov	#MarsVideo_DrawScrl,r0
		jsr	@r0
		nop
; 		mov	#RAM_Mars_DreqRead+Dreq_BgExBuff,r14
; 		mov	#RAM_Mars_ScrlBuff,r13
; 		mov	#MarsVideo_DrawAll,r0
; 		jsr	@r0
; 		nop

; -------------------------------
; Loop
; -------------------------------

mstr_gfx2_loop:
; 		mov	#_CCR,r3
; 		mov	#%00010000,r0	; Cache purge + Disable
; 		mov.w	r0,@r3
; 		nop
; 		nop
; 		nop
; 		nop
; 		nop
; 		nop
; 		nop
; 		nop
; 		mov	#%00001001,r0	; Cache two-way mode + Enable
; 		mov.w	r0,@r3
		mov	#RAM_Mars_DreqRead+Dreq_BgExBuff,r14	; Move this scrolling area
		mov	#RAM_Mars_ScrlBuff,r13
		mov	@(md_bg_x,r14),r0
		mov	r0,@(scrl_xpos,r13)
		mov	@(md_bg_y,r14),r0
		mov	r0,@(scrl_ypos,r13)
		bsr	MarsVideo_Bg_UpdPos
		nop
		bsr	MarsVideo_Bg_DrawReq		; Process draw-requests from Genesis
		nop
		mov.w	#1,r0
		mov.w	r0,@(marsGbl_WdgMode,gbr)
		mov	#0,r1
		mov	#$08,r2
		mov	#MarsVideo_SetWatchdog,r0	; Start watchdog
		jsr	@r0
		nop
 		mov	#MarsVideo_DrawBgSSpr,r0	; Draw backup BG using OLD values
		jsr	@r0
		nop
 testme 2
		mov	#RAM_Mars_ScrlBuff,r14
		mov	@(scrl_fbdata,r14),r1
		mov	@(scrl_fbpos,r14),r2
		mov	@(scrl_fbpos_y,r14),r3
		mov	@(scrl_intrl_w,r14),r4
		mov	@(scrl_intrl_h,r14),r5
		mov	@(scrl_intrl_size,r14),r6
		mov	#Cach_Intrl_Size,r7
		mov	#MarsVideo_SetSuperSpr,r0	; Update sprite "layer" with NEW values
		jsr	@r0
		nop
		mov	#MarsVideo_MkSprBgBoxes,r0	; Make sprite-refill boxes for the next frame
		jsr	@r0
		nop
		mov	#MarsVideo_DrawSuperSpr_M,r0	; Now draw the sprites using stored pixels
		jsr	@r0
		nop
 testme 1

		mov	#RAM_Mars_ScrlBuff,r1		; *** Make a visible section
		mov	#0,r2				; of the scrolling data
		mov	#240,r3				; From Y 0 to 240
		mov	#MarsVideo_ShowScrlBg,r0
		jsr	@r0
		nop
.wait_wdg:	mov.w	@(marsGbl_WdgMode,gbr),r0		; Watchdog finished?
		tst	r0,r0
		bf	.wait_wdg
		mov.l   #$FFFFFE80,r1				; Watchdog OFF
		mov.w   #$A518,r0
		mov.w   r0,@r1
		mov	#0,r1
		mov	#224,r2
		mov	#FBVRAM_PATCH,r3
		mov	#MarsVideo_FixTblShift,r0	; HW: Fix those broken lines that
		jsr	@r0				; the Xshift register can't move.
		nop
		mov	#_vdpreg,r1
.waitv:
		mov.b	@(vdpsts,r1),r0
		tst	#VBLK,r0
		bf	.waitv
		mov.b	@(framectl,r1),r0
		xor	#1,r0
		mov.b	r0,@(framectl,r1)

		bra	mstr_ready
		nop
		align 4
		ltorg

; ============================================================
; ---------------------------------------
; Mode 4: 3D MODE Polygons-only
;
; Objects are divided into read/write
; buffers:
;
; - This CPU draws the polygons from
; the READ buffer
; - at the same time the Slave CPU is
; building the 3d models and
; sorts the polygons FOR THE NEXT FRAME
; (NOT current)
; ---------------------------------------

		align 4

; -------------------------------
; HBlank
; -------------------------------

mstr_gfx3_hblk:
		rts
		nop
		align 4

; -------------------------------
; Init
; -------------------------------

mstr_gfx3_init_1:
		mov	#_sysreg+comm14,r1
.slv_init:	mov.w	@r1,r0
		and	#%01111111,r0
		tst	r0,r0
		bf	.slv_init
		mov	#CACHE_MSTR_PLGN,r1
		mov	#(CACHE_MSTR_PLGN_E-CACHE_MSTR_PLGN)/4,r2
		mov	#Mars_LoadCacheRam,r0
		jsr	@r0
		nop
		mov	#0,r0
		mov.w	r0,@(marsGbl_XShift,gbr)
		bra	mstr_gfx3_init_cont
		nop

mstr_gfx3_init_2:
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
mstr_gfx3_init_cont:
		mov	#_vdpreg,r1
.wait_fb:	mov.w	@(vdpsts,r1),r0			; Wait until framebuffer is unlocked
		tst	#2,r0
		bf	.wait_fb
		nop

; -------------------------------
; Loop
; -------------------------------

mstr_gfx3_loop:
		mov	#_sysreg+comm12,r1
		mov	#_sysreg+comm14,r4
.slv_busy:
		mov.w	@r1,r0
		and	#%1111,r0
		cmp/eq	#3,r0			; MODE $03?
		bf	mstr_ready
		mov.w	@r4,r0
		and	#%00001111,r0
		tst	r0,r0
		bf	mstr_ready;.slv_busy
		stc	sr,@-r15
		mov	#$F0,r0
		ldc	r0,sr
		mov	#RAM_Mars_DreqRead+Dreq_Objects,r1	; Copy Dreq models into a safe place
		mov	#RAM_Mars_Objects,r2			; to prevent BUS problems.
		mov	#(sizeof_mdlobj*MAX_MODELS)/4,r3	; <-- LONG size
.copy_safe:
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.copy_safe
		add	#4,r2
		ldc	@r15+,sr
		mov.w	@(marsGbl_PolyBuffNum,gbr),r0		; Swap Read/Write sections
		xor	#1,r0
		mov.w	r0,@(marsGbl_PolyBuffNum,gbr)
		mov.w	@r4,r0
		or	#$02,r0				; Slave task $02
		mov.w	r0,@r4
		mov	#_vdpreg,r1
.wait_fb:	mov.w	@(vdpsts,r1),r0			; Wait until framebuffer is unlocked
		tst	#2,r0
		bf	.wait_fb
		mov	#$A5,r0				; VDPFILL: Pre-start at $A5
		mov.w	r0,@(6,r1)
		mov	#RAM_Mars_SVdpDrwList,r0	; Reset DDA Start/End/Read/Write points
		mov	r0,@(marsGbl_PlyPzList_R,gbr)
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
		mov	r0,@(marsGbl_PlyPzList_Start,gbr)
		mov	#RAM_Mars_SVdpDrwList_E,r0
		mov	r0,@(marsGbl_PlyPzList_End,gbr)
		mov	#0,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)	; And pieces counter
		mov	#7,r0				; Start on last mode
		mov.w	r0,@(marsGbl_WdgMode,gbr)
		mov	#224,r0				; Lines to clear (WdgMode $07)
		mov	#Cach_ClrLines,r1
		mov	r0,@r1
		mov	#$200,r1
		mov	#512,r2			; <-- fixed WIDTH
		mov	#240,r3
		mov	#MarsVideo_MakeNametbl,r0
		jsr	@r0
		mov	#0,r4

		mov	#0,r1
		mov	#$10,r2
		mov	#MarsVideo_SetWatchdog,r0
		jsr	@r0
		nop

	; While doing this: the watchdog is
	; drawing the polygons using the "pieces" list
	;
	; r14 - Polygon pointers list
	; r13 - Number of polygons to build
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0	; Start drawing polygons from the READ buffer
		tst     #1,r0				; Check for which buffer to use
		bt	.page_2
		mov 	#RAM_Mars_PlgnList_0,r14
		bra	.cont_plgn
		mov	#RAM_Mars_PlgnNum_0,r13
.page_2:
		mov 	#RAM_Mars_PlgnList_1,r14
; 		nop
		mov	#RAM_Mars_PlgnNum_1,r13
.cont_plgn:
		mov	@r13,r13
		cmp/pl	r13
		bf	.skip
.loop:
		mov	@(4,r14),r0			; Get location of the polygon
		cmp/pl	r0				; Zero?
		bf	.invalid			; if yes, skip
		mov	r14,@-r15
		mov	r13,@-r15
		mov	r0,r14
		mov 	#MarsVideo_SlicePlgn,r0
		jsr	@r0
		nop
		mov	@r15+,r13
		mov	@r15+,r14
.invalid:
		dt	r13				; Decrement numof_polygons
		bf/s	.loop
		add	#8,r14				; Move to next entry
.skip:
; 		testme 1
.wait_pz: 	mov.w	@(marsGbl_PlyPzCntr,gbr),r0	; Any pieces remaining?
		tst	r0,r0
		bf	.wait_pz
.wait_wdg:	mov.w	@(marsGbl_WdgMode,gbr),r0	; Watchdog finished?
		tst	r0,r0
		bf	.wait_wdg
		mov.l   #$FFFFFE80,r1
		mov.w   #$A518,r0
		mov.w   r0,@r1
		mov	#_vdpreg,r1
.wait_sv:	mov.w	@($A,r1),r0			; Wait until FB is free
		tst	#2,r0
		bf	.wait_sv
.waitv:		mov.b	@(vdpsts,r1),r0			; Check for framedrop
		tst	#VBLK,r0
		bf	.waitv
		mov.b	@(framectl,r1),r0
		xor	#1,r0
		mov.b	r0,@(framectl,r1)

; ============================================================

mstr_ready:

		bra	master_loop
		nop
		align 4
		ltorg

; ; ============================================================
; ; ---------------------------------------
; ; Pseudo-screen mode $01:
; ;
; ; A Generic screen in any
; ; bitmap mode: Indexed, Direct or RLE
; ;
; ; Watch out for the limited lines
; ; available for DIRECT COLOR
; ; ---------------------------------------
;		align 4
; ; -------------------------------
; ; HBlank
; ; -------------------------------
;
; mstr_gfx1_hblk:
; 		rts
; 		nop
; 		align 4
;
; ; -------------------------------
; ; Init
; ; -------------------------------
;
; mstr_gfx1_init_2:
; 		mov	#0,r0
; 		mov.w	r0,@(marsGbl_XShift,gbr)
; 		mov 	#_vdpreg,r1
; 		mov	#2,r0
; 		mov.b	r0,@(bitmapmd,r1)
; mstr_gfx1_init_1:
; 		mov	#MarsVideo_ResetNameTbl,r0
; 		jsr	@r0
; 		nop
;
; ; -------------------------------
; ; Loop
; ; -------------------------------
;
; mstr_gfx1_loop:
; 		mov	#RAM_Mars_DreqRead+Dreq_ScrlBuff,r1
; 		mov	@(Dreq_Scrn_Type,r1),r0
; 		and	#%11,r0
; 		shll2	r0
; 		mov	#.m1list,r2
; 		mov	@(r0,r2),r2
; 		jmp	@r2
; 		nop
; 		align 4
; .m1list:
; 		dc.l mstr_ready
; 		dc.l mstr_ready		; Indexed
; 		dc.l .direct		; Direct
; 		dc.l mstr_ready
;
; ; -------------------------------
; ; Direct color
; ; currently 320x200 (DOS-style)
; .direct:
; 		mov	@(Dreq_Scrn_Data,r1),r1
; 		mov	#_framebuffer+$200,r2
; 		mov	#(320*200/2)/2,r3	; <- fixed size
; .copy_me:
; 		mov	@r1+,r0
; 		mov	r0,@r2
; 		add	#4,r2
; 		mov	@r1+,r0
; 		mov	r0,@r2
; 		dt	r3
; 		bf/s	.copy_me
; 		add	#4,r2
; .dont_rdrw:
; 		mov	#$200,r1
; 		mov	#320*2,r2
; 		mov	#200,r3
; 		mov	#MarsVideo_MakeNametbl,r0
; 		jsr	@r0
; 		mov	#12,r4
; 		mov	#_vdpreg,r1		; In case we are still on VBlank...
; -		mov.b	@(vdpsts,r1),r0
; 		tst	#VBLK,r0
; 		bf	-
; 		mov	#_vdpreg,r1		; Framebuffer swap REQUEST
; 		mov.b	@(framectl,r1),r0
; 		xor	#1,r0
; 		mov.b	r0,@(framectl,r1)
;
; 		bra	mstr_ready
; 		nop
;
; ; -------------------------------
; ; RLE indexed-compressed image
;
; .rle:
; 		bra	mstr_ready
; 		nop

; ; ============================================================
; ; ---------------------------------------
; ; Pseudo-screen mode $03:
; ; Scalable 256-color screen
; ;
; ; Not as smooth as Mode 2
; ; ---------------------------------------
;
; ; -------------------------------
; ; HBlank
; ; -------------------------------
;
; mstr_gfx3_hblk:
; 		rts
; 		nop
; 		align 4
;
; ; -------------------------------
; ; Init
; ; -------------------------------
;
; mstr_gfx3_init_1:
; 		mov	#CACHE_MSTR_SCRL,r1
; 		mov	#(CACHE_MSTR_SCRL_E-CACHE_MSTR_SCRL)/4,r2
; 		mov	#Mars_LoadCacheRam,r0
; 		jsr	@r0
; 		nop
; 		mov	#0,r0
; 		mov.w	r0,@(marsGbl_XShift,gbr)
; 		bra	mstr_gfx3_loop
; 		nop
;
; mstr_gfx3_init_2:
; 		mov 	#_vdpreg,r1
; 		mov	#1,r0
; 		mov.b	r0,@(bitmapmd,r1)
;
; ; -------------------------------
; ; Loop
; ; -------------------------------
;
; mstr_gfx3_loop:
; 		mov	#$200,r1
; 		mov	#0,r2
; 		mov	#0,r3
; 		mov	#320,r4
; 		mov	#240,r5
; 		mov	#320*240,r6
; 		mov	#Cach_Intrl_Size,r7
; 		mov	#MarsVideo_SetSuperSpr,r0
; 		jsr	@r0
; 		nop
; 		mov	#MarsVideo_DrawScaled,r0
; 		jsr	@r0
; 		nop
; 		mov	#MarsVideo_DrawSuperSpr_M,r0	; Draw Super Sprites
; 		jsr	@r0
; 		nop
; 		mov	#$200,r1
; 		mov	#320,r2
; 		mov	#240,r3
; 		mov	#MarsVideo_MakeNametbl,r0
; 		jsr	@r0
; 		mov	#0,r4
; 		mov	#_vdpreg,r1			; Framebuffer swap REQUEST
; 		mov.b	@(framectl,r1),r0
; 		xor	#1,r0
; 		mov.b	r0,@(framectl,r1)
; 		bra	mstr_ready
; 		nop
; 		align 4
; 		ltorg
; 		align 4

; ============================================================

; 	; ---------------------------------------
; 	; Prepare WATCHDOG interrupt
; 		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
; 		tst     #1,r0
; 		bf	.page_2
; 		mov	#RAM_Mars_PlgnList_0,r0
; 		mov	#RAM_Mars_PlgnNum_0,r1
; 		bra	.cont_plgn
; 		nop
; .page_2:
; 		mov	#RAM_Mars_PlgnList_1,r0
; 		mov	#RAM_Mars_PlgnNum_1,r1
; 		nop
; .cont_plgn:
; 		mov	r0,@(marsGbl_CurrRdPlgn,gbr)
; 		mov	@r1,r0
; 		mov.w	r0,@(marsGbl_CntrRdPlgn,gbr)
;
; 		mov	#RAM_Mars_SVdpDrwList,r0		; Reset DDA pieces Read/Write points
; 		mov	r0,@(marsGbl_PlyPzList_R,gbr)		; And counter
; 		mov	r0,@(marsGbl_PlyPzList_W,gbr)
; 		mov	r0,@(marsGbl_PlyPzList_Start,gbr)
; 		mov	#RAM_Mars_SVdpDrwList_E,r0
; 		mov	r0,@(marsGbl_PlyPzList_End,gbr)
; 		mov	#0,r1
; 		mov	#$20,r2
; 		mov	#MarsVideo_SetWatchdog,r0
; 		jsr	@r0
; 		nop
;
; 	; ---------------------------------------
; 	; Clear screen
; 	; ---------------------------------------
; 		mov.w	@(marsGbl_MdDrawTmr,gbr),r0
; 		tst	r0,r0
; 		bf	.no_redraw_2
; 		mov	#$200,r1		; *** This also counts as a delay for Watchdog ***
; 		mov	#(320+16)/2,r2
; 		mov	#240,r3
; 		mov	#0,r4
; 		mov	#MarsVideo_ClearScreen,r0
; 		jsr	@r0
; 		nop
; .no_redraw_2:
; 		mov	#$200,r1
; 		mov	#512,r2			; <-- fixed WIDTH
; 		mov	#240,r3
; 		mov	#MarsVideo_MakeNametbl,r0
; 		jsr	@r0
; 		mov	#0,r4
;
; 	; ---------------------------------------
;
; .wait_wd:	mov.w	@(marsGbl_WdgStatus,gbr),r0
; 		tst	r0,r0
; 		bt	.wait_wd
; 		mov	#MarsVideo_DrawPzPlgns,r0
; 		jsr	@r0
; 		nop
; .no_swap:
; 		mov	#_sysreg+comm14,r1	; Wait Slave CPU
; .wait:		mov.w	@r1,r0
; 		and	#$FF,r0
; 		tst	r0,r0
; 		bf	.wait
; 		mov	#_vdpreg,r1		; Framebuffer swap REQUEST
; 		mov.b	@(framectl,r1),r0
; 		xor	#1,r0
; 		mov.b	r0,@(framectl,r1)

; 		bra	mstr_ready
; 		nop
; 		align 4
; 		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Slave entry
; ----------------------------------------------------------------

		align 4
SH2_S_Entry:
		mov	#STACK_SLV,r15		; Reset stack
		mov	#SH2_Slave,r0		; Reset vbr
		ldc	r0,vbr
		mov.l	#_FRT,r1		; Free-run timer settings
		mov	#0,r0			; ** REQUIRED FOR REAL HARDWARE **
		mov.b	r0,@(0,r1)
		mov.b	#$E2,r0
		mov.b	r0,@(7,r1)
		mov	#0,r0
		mov.b	r0,@(4,r1)
		mov	#1,r0
		mov.b	r0,@(5,r1)
		mov	#0,r0
		mov.b	r0,@(6,r1)
		mov	#1,r0
		mov.b	r0,@(1,r1)
		mov	#0,r0
		mov.b	r0,@(3,r1)
		mov.b	r0,@(2,r1)
		mov.b	#$F2,r0			; <-- PWM interrupt needs this
		mov.b	r0,@(7,r1)
		mov	#0,r0
		mov.b	r0,@(4,r1)
		mov	#1,r0
		mov.b	r0,@(5,r1)
		mov.b	#$E2,r0
		mov.b	r0,@(7,r1)		; <-- ***

	; Extra interrupt settings
		mov.w   #$FEE2,r0		; Extra interrupt priority levels ($FFFFFEE2)
		mov     #(3<<4)|(5<<8),r1	; (DMA_LVL<<8)|(WDG_LVL<<4) Current: WDG 3 DMA 5
		mov.w   r1,@r0
		mov.w   #$FEE4,r0		; Vector jump number for Watchdog ($FFFFFEE4)
		mov     #($120/4)<<8,r1		; (vbr+POINTER)<<8
		mov.w   r1,@r0
		mov.b	#$A0,r0			; Vector jump number for DMACHANNEL0 ($FFFFFFA0)
		mov     #($124/4),r1		; (vbr+POINTER)
		mov	r1,@r0

		mov	#RAM_Mars_Global,r0	; Reset gbr
		ldc	r0,gbr
		bsr	MarsSound_Init		; Init sound
		nop

; ====================================================================
; ----------------------------------------------------------------
; Slave main code
; ----------------------------------------------------------------

SH2_S_HotStart:
		mov	#$FFFFFE80,r1
		mov.w	#$A518,r0		; Disable Watchdog
		mov.w	r0,@r1
		mov	#_CCR,r1		; Reset CACHE
		mov	#$10,r0
		mov.b	r0,@r1
		nop
		nop
		nop
		nop
		nop
		xor	r0,r0
		mov	#_sysreg+comm14,r2
		mov.w	r0,@r2
		mov	#9,r0
		mov.b	r0,@r1
		mov	#Mars_ClearCacheRam,r0
		jsr	@r0
		nop
		mov	#CACHE_SLAVE,r1
		mov	#(CACHE_SLAVE_E-CACHE_SLAVE)/4,r2
		mov	#Mars_LoadCacheRam,r0
		jsr	@r0
		nop
		mov	#0,r0			; Stop ALL active PWM channels
		mov	#MarsSnd_PwmChnls,r1
		mov	#MAX_PWMCHNL,r2
		mov	#sizeof_sndchn,r3
.clr_enbl:
		mov	r0,@(mchnsnd_enbl,r1)
		dt	r2
		bf/s	.clr_enbl
		add	r3,r1
		mov	#_sysreg,r1
		mov.w	@r1,r0
		or	#CMDIRQ_ON|PWMIRQ_ON,r0
		mov.w	r0,@r1
    		mov	#0,r0
		mov.w	r0,@(vresintclr,r1)
		mov.w	r0,@(vintclr,r1)
		mov.w	r0,@(hintclr,r1)
		mov.w	r0,@(cmdintclr,r1)
		mov.w	r0,@(pwmintclr,r1)
		mov	#_sysreg+comm10,r1
		mov.w	@r1,r0
.wait_md:	tst	r0,r0
		bf	.wait_md
		mov	#_sysreg+comm12,r1
.wait_mst:	mov.w	@r1,r0
		tst	r0,r0
		bf	.wait_mst
		mov	#$20,r0				; Interrupts ON
		ldc	r0,sr
		mov	#slave_loop,r0
		jmp	@r0
		nop
		align 4
		ltorg

; ----------------------------------------------------------------
; SLAVE CPU loop
;
; comm14:
; bssscccc llllllll
;
; b - busy bit on the CMD interrupt
;     (so 68k knows that the interrupt is active)
; s - status bits for some CMD interrupt tasks
; c - command number for CMD interrupt
; l - MAIN LOOP command/task, clears on finish
; ----------------------------------------------------------------

		align 4
slave_loop:
	if SH2_DEBUG
		mov	#_sysreg+comm1,r1	; DEBUG counter
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1
	endif
		mov	#.list,r3		; Default LOOP points
		mov	#_sysreg+comm14,r2
		mov.w	@r2,r0			; r0 - INIT bit
		and	#%00001111,r0
		shll2	r0
		mov	@(r3,r0),r4
		jmp	@r4
		nop
		align 4
.list:
		dc.l slave_loop		; $00
		dc.l slv_task_1		; $01 - Build 3D models for the next frame
		dc.l slv_task_2		; $02
		dc.l slave_loop		; $03

; ============================================================
; ---------------------------------------
; Slave task $01
; ---------------------------------------

		align 4
slv_task_1:

		bra	slv_exit
		nop
		align 4

; ============================================================
; ---------------------------------------
; Slave task $02
; ---------------------------------------

		align 4
slv_task_2:
		mov	#MarsMdl_MdlLoop,r0
		jsr	@r0
		nop
		bra	slv_exit
		nop
		align 4

; ============================================================

; JMP only
slv_exit:
		mov	#_sysreg+comm14,r4	; Finish task
		mov	#$FF00,r1
		mov.w	@r4,r0
		and	r1,r0
		mov.w	r0,@r4
		bra	slave_loop
		nop
		align 4
		ltorg

; ------------------------------------------------
; Includes
; ------------------------------------------------

		include "system/mars/cache/cache_m_2D.asm"
		include "system/mars/cache/cache_m_3D.asm"
		include "system/mars/cache/cache_slv.asm"

; ====================================================================
; ----------------------------------------------------------------
; Data
; ----------------------------------------------------------------

		align 4
sin_table	binclude "system/mars/data/sinedata.bin"
m_ascii		binclude "system/mars/data/m_ascii.bin"

		align 4
		include "data/mars_sdram.asm"

; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 RAM
; ----------------------------------------------------------------

		align $10
SH2_RAM:
		struct SH2_RAM|TH
	if MOMPASS=1
MarsRam_System		ds.l 0
MarsRam_Sound		ds.l 0
MarsRam_Video		ds.l 0
sizeof_marsram		ds.l 0
	else
MarsRam_System		ds.b (sizeof_marssys-MarsRam_System)
MarsRam_Sound		ds.b (sizeof_marssnd-MarsRam_Sound)
MarsRam_Video		ds.b (sizeof_marsvid-MarsRam_Video)
sizeof_marsram		ds.l 0
	endif

.here:
	if MOMPASS=6
		message "SH2 MARS RAM: \{((SH2_RAM)&$FFFFFF)}-\{((.here)&$FFFFFF)}"
	endif
		finish

; ====================================================================
; ----------------------------------------------------------------
; MARS Video RAM
;
; RAM_Mars_ScrnBuff is recycled for all pseudo-screen modes
; ----------------------------------------------------------------

			struct MarsRam_Video
RAM_Mars_ScrnBuff	ds.b MAX_SCRNBUFF			; Single buffer for all screen modes
sizeof_marsvid		ds.l 0
			finish

; --------------------------------------------------------
; per-screen RAM
			struct RAM_Mars_ScrnBuff
CachS_FbData		ds.l 1		; *** KEEP THIS ORDER
CachS_FbPos		ds.l 1
CachS_FbPos_Y		ds.l 1
CachS_Intrl_W		ds.l 1
CachS_Intrl_H		ds.l 1
CachS_Intrl_Size	ds.l 1		; ***
RAM_Mars_ScrlData	ds.b ((320+16)*(224+16))+320
end_scrn02		ds.l 0
			finish
			struct RAM_Mars_ScrnBuff
RAM_Mars_SVdpDrwList	ds.b sizeof_plypz*MAX_SVDP_PZ		; Sprites / Polygon pieces
RAM_Mars_SVdpDrwList_e	ds.l 0					; (END point label)
RAM_Mars_Polygons_0	ds.b sizeof_polygn*MAX_FACES
RAM_Mars_Polygons_1	ds.b sizeof_polygn*MAX_FACES
RAM_Mars_Objects	ds.b sizeof_mdlobj*MAX_MODELS
RAM_Mars_ObjCamera	ds.b sizeof_camera			; 3D Camera buffer
RAM_Mars_PlgnList_0	ds.l 2*MAX_FACES			; Zpos, polygondata
RAM_Mars_PlgnList_1	ds.l 2*MAX_FACES
; RAM_Mars_PlgnList_Rad	ds.l 2*MAX_FACES			; Temporal output for radix sorting.
RAM_Mars_PlgnNum_0	ds.l 1					; Number of polygons to process
RAM_Mars_PlgnNum_1	ds.l 1
; RAM_Mars_PlgnRadix	ds.b MAX_FACES*$0F			; Radix sort indexes
sizeof_scrn04		ds.l 0
			finish
	if MOMPASS=6
	if end_scrn02-RAM_Mars_ScrnBuff > MAX_SCRNBUFF
		error "RAN OUT OF RAM FOR 2D STUFF (\{(end_scrn02-RAM_Mars_ScrnBuff)} of \{(MAX_SCRNBUFF)})"
	elseif sizeof_scrn04-RAM_Mars_ScrnBuff > MAX_SCRNBUFF
		error "RAN OUT OF RAM FOR 3D STUFF (\{(sizeof_scrn04-RAM_Mars_ScrnBuff)} of \{(MAX_SCRNBUFF)})"
	endif
	endif

; ====================================================================
; ----------------------------------------------------------------
; MARS Sound RAM
; ----------------------------------------------------------------

			struct MarsRam_Sound
MarsSnd_PwmCache	ds.b $80*MAX_PWMCHNL
sizeof_marssnd		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MARS System RAM
; ----------------------------------------------------------------

			struct MarsRam_System
RAM_Mars_DreqDma	ds.b sizeof_dreq	; DREQ data from Genesis ***DO NOT READ FROM HERE***
RAM_Mars_DreqRead	ds.b sizeof_dreq	; Copy of DREQ for reading.
RAM_Mars_Global		ds.l sizeof_MarsGbl	; gbr values go here
sizeof_marssys		ds.l 0
			finish

; ====================================================================


