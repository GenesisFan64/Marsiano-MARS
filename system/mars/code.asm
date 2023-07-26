; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 SDRAM section, shared for both SH2 CPUs
; ----------------------------------------------------------------

; *************************************************
; comm ports:
;
; comm0-comm7  - ** FREE ***
; comm8-comm11 - Used by Z80 for getting it's data
;                packets
; comm12       - Master CPU control
; comm14       - Slave CPU control
; *************************************************

		phase CS3	; Now we are at SDRAM
		cpu SH7600	; Should be SH7095 but this CPU mode works.

; ; CPU METER MACRO
; testme macro color
; 		mov	#color,r1
; 		mov	#_vdpreg,r2
; 		mov	#_vdpreg+bitmapmd,r3
; -		mov.b	@(vdpsts,r2),r0
; 		tst	#HBLK,r0
; 		bt	-
; 		mov.b	r1,@r3
; 	endm

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
	; Extra ON-chip interrupts (vbr+$120)
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
 		dc.l slave_irq		; Level 1 IRQ
		dc.l slave_irq		; Level 2 & 3 IRQ
		dc.l slave_irq		; Level 4 & 5 IRQ
		dc.l slave_irq		; Level 6 & 7 IRQ: PWM interupt
		dc.l slave_irq		; Level 8 & 9 IRQ: Command interupt
		dc.l slave_irq		; Level 10 & 11 IRQ: H Blank interupt
		dc.l slave_irq		; Level 12 & 13 IRQ: V Blank interupt
		dc.l slave_irq		; Level 14 & 15 IRQ: Reset Button
	; Extra ON-chip interrupts (vbr+$120)
		dc.l slave_irq		; Watchdog
		dc.l slave_irq		; DMA

; ====================================================================
; ----------------------------------------------------------------
; IRQ
;
; r0-r1 are saved
;
; sr: %xxxxMQIIIIxxST
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
		mov.b	#$F0,r0		; ** $F0
		extu.b	r0,r0
		ldc	r0,sr
		mova	int_m_list,r0
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

slave_irq:
		mov.l	r0,@-r15
		mov.l	r1,@-r15
		sts.l	pr,@-r15
		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov	r0,r1
		mov.b	#$F0,r0		; ** $F0
		extu.b	r0,r0
		ldc	r0,sr
		mova	int_s_list,r0
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
; ------------------------------------------------
; irq list
; ------------------------------------------------

		align 4
;				  Level:
int_m_list:
		dc.l m_irq_bad	; 0
		dc.l m_irq_bad	; 1
		dc.l m_irq_bad	; 2
		dc.l $C0000000	; 3 Watchdog (TOP code on Cache)
		dc.l m_irq_bad	; 4
		dc.l m_irq_dma	; 5 DMA exit
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
		dc.l s_irq_dma	; 5 DMA exit
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
;	 $00: Unknown error
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

m_irq_cmd:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1	; Clear CMD flag
		mov.w	r0,@r1
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	#_sysreg,r4		; r4 - sysreg base
		mov	#_DMASOURCE0,r3		; r3 - DMA base register
		mov	#_sysreg+comm12,r2	; r2 - comm to write the signal
		mov	#_sysreg+dreqfifo,r1	; r1 - Source point: DREQ FIFO
		mov	#%0100010011100000,r0	; Transfer mode + DMA enable OFF
		mov	r0,@($C,r3)
		mov	@(marsGbl_DmaWrite,gbr),r0
		mov	r0,@(4,r3)		; Destination
		mov.w	@(dreqlen,r4),r0	; NOTE: NO size check, be careful.
		extu.w	r0,r0
		mov	r0,@(8,r3)		; Length (set by 68k)
		mov	r1,@r3			; Source
		mov	#%0100010011100101,r0	; Transfer mode + DMA enable + Use DMA interrupt
		mov	r0,@($C,r3)		; Dest:Incr(01) Src:Keep(00) Size:Word(01)
		mov	#1,r0			; _DMAOPERATION = 1
		mov	r0,@($30,r3)
		mov.b	@r2,r0			; Set PASS bit to Genesis side.
		or	#%01000000,r0
		mov.b	r0,@r2
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
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
; Master | VRES Interrupt (RESET button)
; ------------------------------------------------

m_irq_vres:
		mov	#_sysreg,r1
		mov	r15,r0
		mov.w	r0,@(vresintclr,r1)
		mov	#_DMASOURCE0,r1		; Quickly cancel both DMA's
		mov	#0,r0
		mov	r0,@($30,r1)
		mov	#%0100010011100000,r0
		mov	r0,@($C,r1)
		mov	#_DMASOURCE1,r1
		mov	#0,r0
		mov	r0,@($30,r1)
		mov	@($C,r1),r0		; Dummy READ
		mov	#%0100010011100000,r0
		mov	r0,@($C,r1)
		mov	#_sysreg,r1		; If RV was active, freeze.
		mov.w	@(dreqctl,r1),r0
		tst	#1,r0
		bf	.rv_busy
		mov	#(STACK_MSTR)-8,r15	; Reset Master's STACK
		mov	#SH2_M_HotStart,r0	; Write return point and status
		mov	r0,@r15
		mov.w   #$F0,r0
		mov	r0,@(4,r15)
		mov	#_sysreg,r1		; Report as OK to everyone
		mov	#"M_OK",r0
		mov	r0,@(comm0,r1)
		nop
		nop
		nop
		nop
		nop
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

; =================================================================
; ------------------------------------------------
; Master | DMA Exit
; ------------------------------------------------

		align 4
m_irq_dma:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_DMASOURCE0,r1		; Check Channel 0
		mov	@($C,r1),r0		; Dummy READ
		mov	#%0100010011100000,r0
		mov	r0,@($C,r1)		; Transfer mode + DMA enable OFF
		mov	#_sysreg+comm12,r1	; Send signal
		mov.b	@r1,r0
		or	#%01000000,r0
		mov.b	r0,@r1
		rts
		nop
		align 4

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

s_irq_pwm:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1	; Clear CMD flag
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4

		ltorg	; Save literals

; =================================================================
; ------------------------------------------------
; Slave | CMD Interrupt
; ------------------------------------------------

; TEMPORAL
MarsGema_Table	equ $C0000000

		align 4
s_irq_cmd:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1	; Clear CMD flag
		mov.w	r0,@r1
	; --------------------------------
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15

	; --------------------------------
	; Task $01
	; --------------------------------
		mov	#_sysreg+comm8,r1	; Input
		mov	#MarsGema_Table,r2	; Output
		mov	#_sysreg+comm14,r3	; comm
		nop
.wait_1:
		mov.b	@r3,r0
		and	#%11110000,r0
		tst	#%10000000,r0		; LOCK exit?
		bt	.exit_c
		tst	#%01000000,r0		; Wait PASS
		bt	.wait_1
.copy_1:
		mov	@r1,r0			; Copy entire LONG
		mov	r0,@r2
		add	#4,r2			; Increment table pos
		mov.b	@r3,r0
		and	#%10111111,r0
		bra	.wait_1
		mov.b	r0,@r3			; Clear PASS bit, Z80 loops
.exit_c:
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
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
; Slave | HBlank
; ------------------------------------------------

s_irq_h:
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
		mov	#_DMASOURCE0,r1		; Quickly cancel both DMA's
		mov	#0,r0
		mov	r0,@($30,r1)
		mov	#%0100010011100000,r0
		mov	r0,@($C,r1)
		mov	#_DMASOURCE1,r1
		mov	#0,r0
		mov	r0,@($30,r1)
		mov	#%0100010011100000,r0
		mov	r0,@($C,r1)
		mov	#_sysreg,r1		; If RV was active, freeze.
		mov.w	@(dreqctl,r1),r0
		tst	#1,r0
		bf	.rv_busy
		mov	#(STACK_SLV)-8,r15	; Reset Slave's STACK
		mov	#SH2_S_HotStart,r0	; Write return point and status
		mov	r0,@r15
		mov.w   #$F0,r0
		mov	r0,@(4,r15)
		mov	#_sysreg,r1
		mov	#"S_OK",r0		; Report as OK to everyone
		mov	r0,@(comm4,r1)
		nop
		nop
		nop
		nop
		nop
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

; =================================================================
; ------------------------------------------------
; Slave | DMA Exit
; ------------------------------------------------

		align 4
s_irq_dma:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)

		mov	#_DMASOURCE1,r1			; Check Channel 0
		mov	@($C,r1),r0			; Dummy READ
		mov	#%0100010011100000,r0
		mov	r0,@($C,r1)			; Transfer mode + DMA enable OFF
	; ON/OFF flag goes here
		mov	@(marsGbl_PwmWrite,gbr),r0	; Flip PWM buffers
		mov	r0,r1
		mov	@(marsGbl_PwmRead,gbr),r0
		mov	r0,@(marsGbl_PwmWrite,gbr)
		mov	r1,r0
		mov	r0,@(marsGbl_PwmRead,gbr)
		or	#1,r0
		mov.w	r0,@(marsGbl_PwmRefill,gbr)
		mov	#_DMASOURCE1,r1			; Make new DMA
		mov	@(marsGbl_PwmRead,gbr),r0
		mov	r0,@r1				; Source
; 		mov	#$20004034,r0
; 		mov	r0,@(4,r1)			; Destination
		mov	#SAMPLE_SIZE/4,r0
		mov	r0,@(8,r1)			; Size (0 at first)
		mov	#%0001100011100101,r0
		mov	r0,@($C,r1)

		mov	#_sysreg+comm4,r1
		mov.w	@r1,r0
		add	#1,r0
		mov.w	r0,@r1

		rts
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
; 		mov.w	#$FE80,r1
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
; ; ----------------------------------------------------------------
; ; Mars_ClearCacheRam
; ;
; ; Clear the entire "fast code" section for the current CPU
; ; ----------------------------------------------------------------
;
; 		align 4
; Mars_ClearCacheRam:
; 		mov.l	#$C0000000+$800,r1
; 		mov	#0,r0
; 		mov.w	#$80,r2
; .loop:
; 		mov	r0,@-r1
; 		mov	r0,@-r1
; 		mov	r0,@-r1
; 		mov	r0,@-r1
; 		dt	r2
; 		bf	.loop
; 		rts
; 		nop
; 		align 4

; ; ----------------------------------------------------------------
; ; Mars_LoadCacheRam
; ;
; ; Loads "fast code" into the SH2's cache, $800 bytes maximum.
; ;
; ; Input:
; ; r1 - CACHE Code to send
; ; r2 - Size/4
; ;
; ; Breaks:
; ; r3
; ; ----------------------------------------------------------------
;
; 		align 4
; Mars_LoadCacheRam:
; 		stc	sr,@-r15	; Interrupts OFF
; 		mov.b	#$F0,r0		; ** $F0
; 		extu.b	r0,r0
; 		ldc	r0,sr
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
; 		mov 	#$C0000000,r3
; .copy:
; 		mov 	@r1+,r0
; 		mov 	r0,@r3
; 		dt	r2
; 		bf/s	.copy
; 		add 	#4,r3
; 		rts
; 		ldc	@r15+,sr
; 		align 4
; 		ltorg

; ; --------------------------------------------------------
; ; Mars_SetWatchdog
; ;
; ; Prepares watchdog interrupt
; ;
; ; Input:
; ; r1 - Watchdog CPU clock divider
; ; r2 - Watchdog Pre-timer
; ; --------------------------------------------------------
;
; 		align 4
; Mars_SetWatchdog:
; 		stc	sr,r4
; 		mov.b	#$F0,r0			; ** $F0
; 		extu.b	r0,r0
; 		ldc 	r0,sr
; 		mov.w	#_CCR&$FFFF,r3		; Reset CACHE
; 		mov	#%00001000,r0		; Two-way mode
; 		mov.w	r0,@r3
; 		mov	#%00011001,r0		; Cache purge / Two-way mode / Cache ON
; 		mov.w	r0,@r3
; 		mov.w	#$FE80,r3		; $FFFFFE80
; 		mov.w	#$5A00,r0		; Watchdog pre-timer
; 		or	r2,r0
; 		mov.w	r0,@r3
; 		mov.w	#$A538,r0		; Enable Watchdog
; 		or	r1,r0
; 		mov.w	r0,@r3
; 		ldc	r4,sr
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ====================================================================
; ----------------------------------------------------------------
; MARS System features
; ----------------------------------------------------------------

		include "system/mars/video.asm"
		include "system/mars/sound.asm"
; 		align 4

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
; 		mov.b	#$F2,r0				; <-- not needed here
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
		mov.b	#$A0,r0				; Vector jump number for DMACHANNEL0 ($FFFFFFA0)
		mov     #($124/4),r1			; (vbr+POINTER)
		mov	r1,@r0
		mov	#RAM_Mars_Global,r0		; Reset gbr
		ldc	r0,gbr
		mov	#MarsVideo_Init,r0		; Init Video
		jsr	@r0
		nop

; ====================================================================
; ----------------------------------------------------------------
; Master MAIN code
; ----------------------------------------------------------------

SH2_M_HotStart:
		mov.w	#$FE80,r1		; ($FFFFFE80)
		mov.w	#$A518,r0		; Disable Watchdog
		mov.w	r0,@r1
		mov.w	#_CCR&$FFFF,r1		; Reset CACHE
		mov	#$10,r0
		mov.b	r0,@r1
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		mov	#9,r0
		mov.b	r0,@r1
		mov	#_sysreg,r1
    		xor	r0,r0
		mov.w	r0,@(vresintclr,r1)
		mov.w	r0,@(vintclr,r1)
		mov.w	r0,@(hintclr,r1)
		mov.w	r0,@(cmdintclr,r1)
		mov.w	r0,@(pwmintclr,r1)
		mov.w	@r1,r0
		or	#CMDIRQ_ON,r0
		mov.w	r0,@r1
		mov	#_sysreg+comm14,r1
.wait_slv:	mov.w	@r1,r0
		tst	r0,r0
		bf	.wait_slv

	; TEMPORAL
		mov	#ArtMars_TEST,r1
		mov	#_framebuffer+$200,r2
		mov	#(320*224)/4,r3
.loopin:
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.loopin
		add	#4,r2
		mov	#$200,r1
		mov	#320,r2
		mov	#224,r3
		bsr	MarsVideo_MakeNameTbl
		mov	#0,r4

		mov	#_vdpreg,r1
		mov	#1,r0				; Start at BLANK
		mov.b	r0,@(bitmapmd,r1)
		mov.b	@(framectl,r1),r0		; Frameswap request
		xor	#1,r0
		mov	r0,r3
		mov.b	r0,@(framectl,r1)
.wait_frm:	mov.b	@(framectl,r1),r0		; And wait until it flips
		cmp/eq	r0,r3
		bf	.wait_frm

		mov.b	#$20,r0				; Interrupts ON
		ldc	r0,sr
		bra	master_loop
		nop
		align 4
		ltorg

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
		mov	#_sysreg+comm6,r1		; DEBUG counter
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1
	endif

	; ---------------------------------------
	; Copy the NEW DREQ data we just
	; got to the READ buffer
	; ---------------------------------------
		mov	#_vdpreg,r1			; Check if we got late
.waitl:		mov.b	@(vdpsts,r1),r0			; on VBlank
		tst	#VBLK,r0
		bf	.waitl
		stc	sr,@-r15
		mov.b	#$F0,r0				; ** $F0
		extu.b	r0,r0
		ldc	r0,sr
		mov	@(marsGbl_DmaWrite,gbr),r0	; Flip DMA Read/Write buffers
		mov	r0,r1
		mov	@(marsGbl_DmaRead,gbr),r0
		mov	r0,@(marsGbl_DmaWrite,gbr)
		mov	r1,r0
		mov	r0,@(marsGbl_DmaRead,gbr)
		ldc	@r15+,sr

	; ---------------------------------------
	; Write palette using DREQ data
	; ---------------------------------------
		mov	#_vdpreg,r1			; Wait until VBlank
.waitv:		mov.b	@(vdpsts,r1),r0
		tst	#VBLK,r0
		bt	.waitv
 		mov.w	@(marsGbl_XShift,gbr),r0	; Set SHIFT bit first (Xpos & 1)
		and	#1,r0
		mov.w	r0,@(shift,r1)
		mov	@(marsGbl_DmaRead,gbr),r0
; 		mov	#Dreq_Palette,r1
; 		add	r1,r0
		mov	r0,r1
		mov	#_palette,r2
 		mov	#(256/8),r3
	; PALETTE MUST BE AT THE TOP OF DREQ DATA
	; so I don't need to add Dreq_Palette...
.copy_pal:
	rept 4
		mov	@r1+,r0			; Copy colors as LONGs, works on hardware.
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

		bra	master_loop
		nop
		align 4
		ltorg

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
		mov.b	#$A8,r0			; Vector jump number for DMACHANNEL1 ($FFFFFFA8)
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
		mov.w	#$FE80,r1
		mov.w	#$A518,r0		; Disable Watchdog
		mov.w	r0,@r1
		mov.w	#_CCR&$FFFF,r1		; Reset CACHE
		mov	#$10,r0
		mov.b	r0,@r1
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		mov	#9,r0
		mov.b	r0,@r1
; 		mov	#CACHE_SLAVE,r1
; 		mov	#(CACHE_SLAVE_E-CACHE_SLAVE)/4,r2
; 		mov	#Mars_LoadCacheRam,r0
; 		jsr	@r0
; 		nop
		mov	#_sysreg,r1
    		xor	r0,r0
		mov.w	r0,@(vresintclr,r1)
		mov.w	r0,@(vintclr,r1)
		mov.w	r0,@(hintclr,r1)
		mov.w	r0,@(cmdintclr,r1)
		mov.w	r0,@(pwmintclr,r1)
		mov.w	@r1,r0
; 		or	#CMDIRQ_ON|PWMIRQ_ON,r0
		or	#CMDIRQ_ON,r0
		mov.w	r0,@r1
		mov	#_sysreg+comm12,r1
.wait_mst:	mov.w	@r1,r0
		tst	r0,r0
		bf	.wait_mst

; 	; ****
		bsr	MarsSound_Refill
		nop
; 	; ****

		mov.b	#$20,r0				; Interrupts ON
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
; l - MAIN LOOP command/task, clears on endstruct
; ----------------------------------------------------------------

		align 4
slave_loop:
	; GemaSoundDriver
		bsr	MarsSound_Loop
		nop


; 		mov	#_DMASOURCE1,r1		; Check Channel 1
; 		mov	@($C,r1),r0		; Dummy READ
; 		tst	#%10,r0
; 		bf	.dont
; 		mov	#%0100010011100000,r0
; 		mov	r0,@($C,r1)		; Transfer mode + DMA enable OFF

		mov	#_sysreg+comm7,r1
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1
		bra	slave_loop
		nop
		align 4
		ltorg

; ------------------------------------------------
; Includes
; ------------------------------------------------

; 		include "system/mars/cache/cache_m_2D.asm"
; 		include "system/mars/cache/cache_m_3D.asm"
; 		include "system/mars/cache/cache_slv.asm"

; ====================================================================
; ----------------------------------------------------------------
; Data
; ----------------------------------------------------------------

		align 4
sin_table	binclude "system/mars/data/sinedata.bin"
; m_ascii	binclude "system/mars/data/m_ascii.bin"
		align 4
		include "game/data/mars_sdram.asm"

; ====================================================================
; ----------------------------------------------------------------
; GLOBAL GBR Variables
;
; SHARED FOR BOTH CPUS, watch out for the Read/Write conflicts.
;
; use dc's to set their STARTING values
; ----------------------------------------------------------------

			align $10
RAM_Mars_Global:
			struct 0
marsGbl_XShift		dc.w 0
marsGbl_PwmRefill	dc.w 0				; Refill flag
marsGbl_DmaRead		dc.l RAM_Mars_DreqBuff_0|TH
marsGbl_DmaWrite	dc.l RAM_Mars_DreqBuff_1|TH
marsGbl_PwmRead		dc.l RAM_Mars_GemaWave_0|TH
marsGbl_PwmWrite	dc.l RAM_Mars_GemaWave_1|TH
	if MARS
marsGbl_TEMPORAL	dc.l TEST_DMA|TH
	endif
sizeof_MarsGbl		ds.l 0
			endstruct

; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 RAM
; ----------------------------------------------------------------

			align $80
SH2_RAM:
			struct SH2_RAM|TH	; CACHE-THRU
RAM_Mars_DreqBuff_0	ds.b sizeof_dreq	; DREQ data from Genesis ***DO NOT READ FROM HERE***
RAM_Mars_DreqBuff_1	ds.b sizeof_dreq	; Copy of DREQ for reading.
RAM_Mars_GemaWave_0	ds.b SAMPLE_SIZE	; ** DON'T SEPARATE THESE LABELS **
RAM_Mars_GemaWave_1	ds.b SAMPLE_SIZE	; **                             **
; RAM_Mars_PwmList	ds.b sizeof_marssnd*8
sizeof_sh2all		ds.l 0
			endstruct

; ====================================================================

.here:
		report "SH2 SDRAM CODE/DATA",sizeof_sh2all&$3FFFFF,(STACK_SLV-$1000)
