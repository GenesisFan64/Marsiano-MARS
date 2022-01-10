; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 Section
;
; CODE for both CPUs
; RAM and some DATA go here
; ----------------------------------------------------------------

		phase CS3	; Now we are at SDRAM
		cpu SH7600	; Should be SH7095 but this CPU mode works.

; ====================================================================
; ----------------------------------------------------------------
; User settings
; ----------------------------------------------------------------

; ----------------------------------------
; Normal sprite settings
; ----------------------------------------

MAX_MSPR	equ	128	; Maximum sprites

; ====================================================================
; ----------------------------------------------------------------
; MARS DEFAULT gbr variables for both SH2
; ----------------------------------------------------------------

			struct 0
marsGbl_DreqRead	ds.l 1	; DREQ Read/Write pointers
marsGbl_DreqWrite	ds.l 1	; these get swapped on VBlank
marsGbl_PlyPzList_R	ds.l 1	; Current graphic piece to draw
marsGbl_PlyPzList_W	ds.l 1	; Current graphic piece to write
marsGbl_PzListCntr	ds.w 1	; Number of graphic pieces to draw
marsGbl_DrwPause	ds.w 1	; Pause background drawing
marsGbl_DivStop_M	ds.w 1	; Flag to tell Watchdog we are in the middle of hardware division
marsGbl_XShift		ds.w 1	; Xshift bit at the start of master_loop (TODO: maybe a HBlank list?)
marsGbl_XPatch		ds.w 1	; Redraw counter for the $xxFF fix, set to 0 on X/Y change
marsGbl_CurrFb		ds.w 1	; Current framebuffer number (Note: it's a byte)
sizeof_MarsGbl		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MASTER CPU VECTOR LIST (vbr)
; ----------------------------------------------------------------

		align 4
SH2_Master:
		dc.l SH2_M_Entry,CS3|$40000	; Power PC, Stack
		dc.l SH2_M_Entry,CS3|$40000	; Reset PC, Stack

		dc.l SH2_M_Error		; Illegal instruction
		dc.l 0				; reserved
		dc.l SH2_M_Error		; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l SH2_M_Error		; CPU address error
		dc.l SH2_M_Error		; DMA address error
		dc.l SH2_M_Error		; NMI vector
		dc.l SH2_M_Error		; User break vector

		dc.l 0,0,0,0,0,0,0,0,0,0	; reserved
		dc.l 0,0,0,0,0,0,0,0,0

		dc.l SH2_M_Error	; Trap user vectors
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

; ====================================================================
; ----------------------------------------------------------------
; SLAVE CPU VECTOR LIST (vbr)
; ----------------------------------------------------------------

		align 4
SH2_Slave:
		dc.l SH2_S_Entry,CS3|$3F000	; Cold PC,SP
		dc.l SH2_S_Entry,CS3|$3F000	; Manual PC,SP

		dc.l SH2_S_Error			; Illegal instruction
		dc.l 0				; reserved
		dc.l SH2_S_Error			; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l SH2_S_Error			; CPU address error
		dc.l SH2_S_Error			; DMA address error
		dc.l SH2_S_Error			; NMI vector
		dc.l SH2_S_Error			; User break vector

		dc.l 0,0,0,0,0,0,0,0,0,0	; reserved
		dc.l 0,0,0,0,0,0,0,0,0

		dc.l SH2_S_Error			; Trap user vectors
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
		dc.l slave_irq			; Watchdog (custom)

; ====================================================================
; ----------------------------------------------------------------
; irq
;
; r0-r1 are safe
; ----------------------------------------------------------------

		align 4
master_irq:
		mov.l	r0,@-r15
		mov.l	r1,@-r15
		sts.l	pr,@-r15

		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov	#int_m_list,r1
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
int_m_list:
		dc.l m_irq_bad,m_irq_bad
		dc.l m_irq_bad,m_irq_bad
		dc.l m_irq_bad,m_irq_custom
		dc.l m_irq_pwm,m_irq_pwm
		dc.l m_irq_cmd,m_irq_cmd
		dc.l m_irq_h,m_irq_h
		dc.l m_irq_v,m_irq_v
		dc.l m_irq_vres,m_irq_vres

; ====================================================================
; ----------------------------------------------------------------
; irq
;
; r0-r1 are safe
; ----------------------------------------------------------------

slave_irq:
		mov.l	r0,@-r15
		mov.l	r1,@-r15
		sts.l	pr,@-r15

		stc	sr,r0
		shlr2	r0
		and	#$3C,r0
		mov	#int_s_list,r1
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

; ------------------------------------------------
; irq list
; ------------------------------------------------

int_s_list:
		dc.l s_irq_bad,s_irq_bad
		dc.l s_irq_bad,s_irq_bad
		dc.l s_irq_bad,s_irq_custom
		dc.l s_irq_pwm,s_irq_pwm
		dc.l s_irq_cmd,s_irq_cmd
		dc.l s_irq_h,s_irq_h
		dc.l s_irq_v,s_irq_v
		dc.l s_irq_vres,s_irq_vres

; ====================================================================
; ----------------------------------------------------------------
; Noraml error trap
; ----------------------------------------------------------------

; Master only
SH2_M_Error:
		mov	#StrM_Oops,r1		; Print text on screen
		mov	#0,r2
		bsr	MarsVdp_Print
		mov	#0,r3
		mov	#_vdpreg,r1		; Show it on next FB
		mov.b	@(framectl,r1),r0
		xor	#1,r0
		mov.b	r0,@(framectl,r1)

		mov	#_sysreg+comm14,r1
		mov	#-1,r0
		mov.b	r0,@r1
.infin:		nop
		bra	.infin
		nop
		align 4
StrM_Oops:
		dc.b "Error on MASTER CPU",0
		align 4

; Slave only
; TODO: a way report that Slave failed
SH2_S_Error:
		mov	#_sysreg+comm15,r1
		mov	#-1,r0
		mov.b	r0,@r1
.infin:		nop
		bra	.infin
		nop
		align 4

; ====================================================================
; ----------------------------------------------------------------
; MARS Interrupts
; ----------------------------------------------------------------

; =================================================================
; ------------------------------------------------
; Master | Unused interrupt
; ------------------------------------------------

m_irq_bad:
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | PWM Interrupt
; ------------------------------------------------

m_irq_pwm:
		mov	#$F0,r0
		ldc	r0,sr
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
		nop
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | CMD Interrupt
; ------------------------------------------------

m_irq_cmd:
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1
		mov.w	r0,@r1

		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	#_sysreg,r4
		mov	#_DMASOURCE0,r3
		mov	#_sysreg+comm14,r2
		mov	#%0100010011100000,r0	; Transfer mode but DMA enable bit is 0
		mov	r0,@($C,r3)
		mov	#_sysreg+dreqfifo,r1
		mov	@(marsGbl_DreqWrite,gbr),r0
		mov	r1,@r3			; Source
		mov	r0,@(4,r3)		; Destination
		mov.w	@(dreqlen,r4),r0
		mov	r0,@(8,r3)		; Length
		mov.b	@r2,r0
		or	#%01000000,r0		; Tell Genesis we are few instructions away from
		mov.b	r0,@r2			; reading the DREQ FIFO port
		mov	@($C,r3),r0		; (?)
		mov	#%0100010011100001,r0	; Transfer mode: + DMA enable
		mov	r0,@($C,r3)		; Dest:IncFwd(01) Src:Stay(00) Size:Word(01)
		mov	#1,r0			; _DMAOPERATION = 1
		mov	r0,@($30,r3)
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		nop
		nop	; TODO: ver si todavia necesito estos NOPs
		nop	; (yo digo que si)
		nop
		nop
		rts
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Master | HBlank
; ------------------------------------------------

m_irq_h:
		mov	#$F0,r0
		ldc	r0,sr
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
		ltorg

; =================================================================
; ------------------------------------------------
; Master | VBlank
; ------------------------------------------------

m_irq_v:
		mov	#$F0,r0
		ldc	r0,sr
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
		ltorg

; =================================================================
; ------------------------------------------------
; Master | VRES Interrupt (RESET on Genesis)
; ------------------------------------------------

m_irq_vres:
		mov	#$F0,r0
		ldc	r0,sr
		mov.l	#_sysreg,r0
		ldc	r0,gbr
		mov.w	r0,@(vresintclr,gbr)	; V interrupt clear

	; TODO: Checar bien esto.
	; Ya no se traba mucho como antes pero
	; igual por si el USER resetea a lo wey.
	;
	; Mismo para SLAVE
		mov.b	@(dreqctl,gbr),r0
		tst	#1,r0
		bf	.mars_reset
.md_reset:
		mov.l	#"68UP",r1		; wait for the 68K to show up
		mov.l	@(comm12,gbr),r0
		cmp/eq	r0,r1
		bf	.md_reset
.sh_wait:
		mov.l	#"S_OK",r1		; wait for the Slave CPU to show up
		mov.l	@(comm4,gbr),r0
		cmp/eq	r0,r1
		bf	.sh_wait
		mov.l	#"M_OK",r0		; let the others know master ready
		mov.l	r0,@(comm0,gbr)
		mov.l   #$FFFFFE80,r1		; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		mov.b	r0,@r1

		mov.l	#CS3|$40000-8,r15	; Set reset values
		mov.l	#SH2_M_HotStart,r0
		mov.l	r0,@r15
		mov.w	#$F0,r0
		mov.l	r0,@(4,r15)
		mov.l	#_DMAOPERATION,r1
		mov.l	#0,r0
		mov.l	r0,@r1			; Turn any DMA tasks OFF
		mov.l	#_DMACHANNEL0,r1
		mov.l	#0,r0
		mov.l	r0,@r1
		mov.l	#%0100010011100000,r1
		mov.l	r0,@r1			; Channel control
		rte
		nop
.mars_reset:
		mov	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		or	#$01,r0
		mov.b	r0,@(_TOCR,r1)
.vresloop:
		bra	.vresloop
		nop
		align 4
		ltorg			; Save MASTER IRQ literals here

; =================================================================
; ------------------------------------------------
; Slave | Unused Interrupt
; ------------------------------------------------

s_irq_bad:
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | PWM Interrupt
; ------------------------------------------------

s_irq_pwm:
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1
		mov.w	r0,@r1

		mov	#_sysreg+monowidth,r1
		mov.b	@r1,r0
 		tst	#$80,r0
 		bf	.exit
		sts	pr,@-r15
		mov	#MarsSound_ReadPwm,r0
		jsr	@r0
		nop
		lds	@r15+,pr
.exit:
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Slave | CMD Interrupt
; ------------------------------------------------

s_irq_cmd:
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1	; Clear CMD flag
		mov.w	r0,@r1
		nop
		nop
		nop
		nop
		nop
		rts
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Slave | HBlank
; ------------------------------------------------

s_irq_h:
		mov	#$F0,r0
		ldc	r0,sr
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
		mov	#$F0,r0
		ldc	r0,sr
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
; Slave | VRES Interrupt (Pressed RESET on Genesis)
; ------------------------------------------------

s_irq_vres:
		mov	#$F0,r0
		ldc	r0,sr
		mov.l	#_sysreg,r0
		ldc	r0,gbr
		mov.w	r0,@(vresintclr,gbr)	; V interrupt clear
		mov.b	@(dreqctl,gbr),r0
		tst	#1,r0
		bf	.mars_reset
.md_reset:
		mov.l	#"68UP",r1		; wait for the 68k to show up
		mov.l	@(comm12,gbr),r0
		cmp/eq	r0,r1
		bf	.md_reset
		mov.l	#"S_OK",r0		; tell the others slave is ready
		mov.l	r0,@(comm4,gbr)
.sh_wait:
		mov.l	#"M_OK",r1		; wait for the slave to show up
		mov.l	@(comm0,gbr),r0
		cmp/eq	r0,r1
		bf	.sh_wait
		mov.l	#CS3|$3F000-8,r15
		mov.l	#SH2_S_HotStart,r0
		mov.l	r0,@r15
		mov.w	#$F0,r0
		mov.l	r0,@(4,r15)
		mov.l	#_DMAOPERATION,r1
		mov.l	#0,r0
		mov.l	r0,@r1			; DMA off
		mov.l	#_DMACHANNEL0,r1
		mov.l	#0,r0
		mov.l	r0,@r1
		mov.l	#%0100010011100000,r1
		mov.l	r0,@r1			; Channel control
		rte
		nop
.mars_reset:
		mov	#_FRT,r1
		mov.b	@(_TOCR,r1),r0
		or	#$01,r0
		mov.b	r0,@(_TOCR,r1)
.vresloop:
		bra	.vresloop
		nop
		align 4
		ltorg			; Save Slave IRQ literals

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
		mov	#CS3|$40000,r15		; Set default Stack for Master
		mov	#_FRT,r1
		mov     #0,r0
		mov.b   r0,@(0,r1)
		mov     #$FFFFFFE2,r0
		mov.b   r0,@(7,r1)
		mov     #0,r0
		mov.b   r0,@(4,r1)
		mov     #1,r0
		mov.b   r0,@(5,r1)
		mov     #0,r0
		mov.b   r0,@(6,r1)
		mov     #1,r0
		mov.b   r0,@(1,r1)
		mov     #0,r0
		mov.b   r0,@(3,r1)
		mov.b   r0,@(2,r1)
		mov.l   #$FFFFFEE2,r0		; Watchdog: Set interrupt priority bits (IPRA)
		mov     #%0101<<4,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1		; Watchdog: Set jump pointer: VBR + (this/4) (WITV)
		shll8   r1
		mov.w   r1,@r0

; ------------------------------------------------
; Wait for Genesis and Slave CPU
; ------------------------------------------------

.wait_md:
		mov 	#_sysreg+comm0,r2	; Wait for Genesis
		mov.l	@r2,r0
		cmp/eq	#0,r0
		bf	.wait_md
		mov.l	#"SLAV",r1
.wait_slave:
		mov.l	@(8,r2),r0		; Wait for Slave CPU to finish booting
		cmp/eq	r1,r0
		bf	.wait_slave
		mov	#0,r0			; clear "SLAV"
		mov	r0,@(8,r2)
		mov	r0,@r2

; ====================================================================
; ----------------------------------------------------------------
; Master main code
;
; This CPU is exclusively used for Visual tasks:
; Background, Sprites and Polygons.
;
; The GENESIS side will control almost(?) all of this.
; ----------------------------------------------------------------

SH2_M_HotStart:
		mov	#CS3|$40000,r15			; Stack reset
		mov	#RAM_Mars_Global,r14		; GBR - Global values/variables go here.
		ldc	r14,gbr
		mov	#$F0,r0				; Interrupts OFF
		ldc	r0,sr
		mov.l	#_CCR,r1
		mov	#%00001000,r0			; Cache OFF
		mov.w	r0,@r1
		mov	#%00011001,r0			; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r1
		mov	#_sysreg,r1
		mov	#CMDIRQ_ON,r0			; Enable usage of these interrupts
    		mov.b	r0,@(intmask,r1)
		mov 	#CACHE_MASTER,r1		; Transfer Master's "fast code" to CACHE
		mov 	#$C0000000,r2
		mov 	#(CACHE_MASTER_E-CACHE_MASTER)/4,r3
.copy:
		mov 	@r1+,r0
		mov 	r0,@r2
		dt	r3
		bf/s	.copy
		add 	#4,r2
		mov	#_DMACHANNEL0,r1		; Turn DMA Off
		mov	#0,r0
		mov	r0,@($30,r1)
		mov	r0,@($C,r1)

		mov	#MarsVideo_Init,r0		; Init Video
		jsr	@r0
		nop
		mov	#MarsRam_Dreq0,r0		; Set DREQ Read/Write points
		mov	r0,@(marsGbl_DreqRead,gbr)
		mov	#MarsRam_Dreq1,r0
		mov	r0,@(marsGbl_DreqWrite,gbr)
		mov.l	#$20,r0				; Enable interrupts
		ldc	r0,sr

	; TODO: ver como mover esto al Genesis
		mov	#RAM_Mars_Background,r1
		mov	#$200,r2
		mov	#32,r3
		mov	#320,r4
		mov	#256,r5
		bsr	MarsVideo_MkScrlField
		mov	#0,r6
		mov	#RAM_Mars_Background,r1
		mov	#TESTMARS_BG,r2			; Image OR RAM section
		mov	#320,r3
		mov	#224,r4
		bsr	MarsVideo_SetBg
		nop
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
		bra	master_loop
		nop
		align 4
		ltorg

; ----------------------------------------------------------------
; MASTER Loop
; ----------------------------------------------------------------

master_loop:

	; ---------------------------------------
	; Wait for frameswap
	; ---------------------------------------

		mov	#_vdpreg,r4			; r4 - SVDP area
		mov.b	@(marsGbl_CurrFb,gbr),r0	; r3 - NEW Framebuffer number
		mov	r0,r3
.wait_frmswp:	mov.b	@(framectl,r4),r0		; Framebuffer ready?
		cmp/eq	r0,r3
		bf	.wait_frmswp
 		mov.w	@(marsGbl_XShift,gbr),r0	; Set SHIFT bit first
		mov	#_vdpreg+shift,r1		; For indexed-scrolling
		and	#1,r0
		mov.w	r0,@r1

	; ---------------------------------------
	; New frame is now shown on screen but
	; we are still on VBlank
	; ---------------------------------------

		mov	#_vdpreg,r1
.wait:		mov.b	@(vdpsts,r1),r0
		and	#$20,r0
		tst	r0,r0				; Palette unlocked?
		bt	.wait
		mov	#Dreq_Palette,r13
		mov	@(marsGbl_DreqRead,gbr),r0
		add	r0,r13
		mov	r0,r1
		mov	#_palette,r2
 		mov	#256/16,r3
.copy_pal:
	rept 16
		mov.w	@r1+,r0
		mov.w	r0,@r2
		add	#2,r2
	endm
		dt	r3
		bf	.copy_pal

	; ---------------------------------------

		mov	#_DMACHANNEL0,r1
		mov	@r1,r0
		and	#%01,r0			; Check if DMA is enabled
		tst	r0,r0
		bt	.not_yet		; Not yet.
		stc	sr,@-r15
		mov.l	#$F0,r0			; Interrupts OFF, Ignore new requests
		ldc	r0,sr
.wait_dma:	mov	@r1,r0			; Middle of DMA transfer?
		and	#%10,r0
		tst	r0,r0
		bt	.wait_dma
		mov	@(marsGbl_DreqRead,gbr),r0	; Swap READ/WRITE pointers
		mov	r0,r1
		mov	@(marsGbl_DreqWrite,gbr),r0
		mov	r0,@(marsGbl_DreqRead,gbr)
		mov	r1,r0
		mov	r0,@(marsGbl_DreqWrite,gbr)
		ldc	@r15+,sr			; Interrupts ON, get CMD requests again.
.not_yet:

	; ---------------------------------------
	; Off-frame updates go here
	; ---------------------------------------

		mov	#RAM_Mars_Background,r14
		mov	#Dreq_BgControl,r13
		mov	@(marsGbl_DreqRead,gbr),r0
		add	r0,r13
		mov	@r13+,r1
		mov	@r13+,r2
		mov	r1,@(mbg_xpos,r14)
		mov	r2,@(mbg_ypos,r14)
		mov	#RAM_Mars_Background,r14
		bsr	MarsVideo_MoveBg
		nop
		mov	#RAM_Mars_VdpDrwList,r0		; Set DDA pieces Read/Write points
		mov	r0,@(marsGbl_PlyPzList_R,gbr)
		mov	#RAM_Mars_VdpDrwList,r0
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
		mov	#$FFFFFE80,r1
		mov.w	#$5A10,r0			; Watchdog timer
		mov.w	r0,@r1
		mov.w	#$A538,r0			; Enable this watchdog
		mov.w	r0,@r1

	; TEMPORAL, MOVE THIS TO WATCHDOG LATER

		mov	#Dreq_Polygons,r14
		mov	@(marsGbl_DreqRead,gbr),r0
		add	r0,r14
		mov	#MarsVideo_SlicePlgn,r0
		jsr	@r0
		nop

		mov	#_vdpreg,r1			; Still on VBlank?
.no_dreq:
		mov.b	@(vdpsts,r1),r0
		and	#$80,r0
		tst	r0,r0
		bf	.no_dreq

	; ---------------------------------------
	; Interact with background
	; ---------------------------------------

		mov	#_sysreg+comm14,r2	; quick bit 5:
		mov.b	@r2,r0			; Redraw background request
		and	#%00100000,r0
		tst	r0,r0
		bt	.no_rdrw
		mov.b	@r2,r0
		and	#%11011111,r0
		mov.b	r0,@r2
		mov	#Cach_Drw_All,r1
		mov	#2,r0
		mov	r0,@r1
.no_rdrw:

	; ---------------------------------------
	; Framebuffer redraw section
	; ---------------------------------------

		mov	#Cach_Drw_All,r13		; DrawAll != 0?
		mov	@r13,r0
		cmp/eq	#0,r0
		bt	.no_redraw
		dt	r0
		mov	r0,@r13
		bsr	MarsVideo_DrawAllBg
		nop
		bra	.from_drwall
		nop
.no_redraw:
		mov	#MarsVideo_BgDrawLR,r0		; Process U/D/L/R draw
		jsr	@r0
		nop
		mov	#MarsVideo_BgDrawUD,r0
		jsr	@r0
		nop
.from_drwall:

	; ---------------------------------------
	; Draw sprites and polygons now.
	; ---------------------------------------

		mov	#RAM_Mars_VdpDrwList,r14
		bsr	VideoMars_DrwPlgnPz
		nop

	; ---------------------------------------
	; Build linetable
	; ---------------------------------------

		mov.l   #$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		mov	#_vdpreg,r1			; SVDP FILL active?
.wait_fb:	mov.w	@(vdpsts,r1),r0
		and	#2,r0
		tst	r0,r0
		bf	.wait_fb
		mov	#RAM_Mars_Background,r1		; Make visible background
		mov	#0,r2				; section on screen
		mov	#240,r3
		bsr	MarsVideo_MakeTbl
		nop

		bsr	MarsVideo_FixTblShift		; Fix those broken lines with XShift
		nop
		mov	#_vdpreg,r1			; SVDP FILL active?
		mov.b	@(framectl,r1),r0		; Framebuffer swap REQUEST
		xor	#1,r0
		mov.b	r0,@(framectl,r1)
		mov.b	r0,@(marsGbl_CurrFb,gbr)	; copy bit for checking
		bra	master_loop
		nop
		align 4
		ltorg

; Draw polyon piece
; r14 - current piece

VideoMars_DrwPlgnPz:
		mov	#RAM_Mars_Background,r13
		mov	#_vdpreg,r12
		mov	#$FFFF,r0
		mov	@(plypz_ypos,r14),r10
		mov	r10,r11
		shlr16	r10
		and	r0,r11
		and	r0,r10

		mov.w	@(mbg_intrl_h,r13),r0
		mov	r0,r8
		mov.w	@(mbg_intrl_w,r13),r0
		mov	r0,r9
		mov.w	@(mbg_yfb,r13),r0
		add	r10,r0
		cmp/ge	r8,r0
		bf	.ylowr
		sub	r8,r0
.ylowr:
		mulu	r9,r0
		sts	macl,r9


	; r10 - Start Y
	; r11 - End Y
	; r9 - VDP topleft current
	; r8 - Length
	; r7 - XR add
	; r6 - XL add
	; r5 - XR pos
	; r4 - XL pos

		mov	@(plypz_mtrl,r14),r3
		mov	@(plypz_xl,r14),r4
		mov	@(plypz_xr,r14),r5
		mov	@(plypz_xl_dx,r14),r6
		mov	@(plypz_xr_dx,r14),r7
.next_l:
		mov	r7,@-r15
		mov	r6,@-r15
		mov	r5,@-r15
		mov	r4,@-r15

		mov	r4,r1
		mov	r5,r2
		shlr16	r1
		shlr16	r2

		cmp/eq	r1,r2
		bt	.off_x
		mov	r2,r0
		sub	r1,r0
		cmp/pl	r0
		bt	.plus
		mov	r2,r0
		mov	r1,r2
		mov	r0,r1
.plus:
		mov	r2,r8
		sub	r1,r8
		mov	#2,r0
		cmp/gt	r0,r8
		bf	.off_x
		shar	r8

		mov	r9,r5
		mov	@(mbg_fbdata,r13),r0
		add	r0,r5
		mov	@(mbg_fbpos,r13),r0
		add	r0,r5
		add	r1,r5
		mov	@(mbg_intrl_size,r13),r0
		cmp/gt	r0,r5
		bf	.fb_decr
		sub	r0,r5
.fb_decr:
		shlr	r5

	; Cross-check
		mov	r8,r0
		add	r5,r0
		mov	r0,r7
		mov	r5,r4
		shlr8	r7
		shlr8	r4
		cmp/eq	r7,r4
		bt	.single
		mov	r0,r4
		and	#$FF,r0
		cmp/eq	#0,r0
		bt	.single

	; Left write
		mov	r8,r7
		sub	r0,r8
		mov	r8,r0
		dt	r0
		mov.w	r0,@(filllength,r12)
		mov	r5,r0
		mov.w	r0,@(fillstart,r12)
		mov	r3,r0
		mov.w	r0,@(filldata,r12)
.wait_l:	mov.w	@(vdpsts,r12),r0
		and	#%10,r0
		tst	r0,r0
		bf	.wait_l
		add	r7,r5
		mov	#$100,r8
		mov.w	@(fillstart,r12),r0
		add	r8,r0
		mov.w	r0,@(fillstart,r12)
		sub	r0,r5
		mov	r5,r0
		dt	r0
		mov.w	r0,@(filllength,r12)
		mov	r3,r0
		mov.w	r0,@(filldata,r12)
.wait_r:	mov.w	@(vdpsts,r12),r0
		and	#%10,r0
		tst	r0,r0
		bf	.wait_r

		bra	.cont_l
		nop
.single:
		mov	r8,r0
		dt	r0
		mov.w	r0,@(filllength,r12)
		mov	r5,r0
		mov.w	r0,@(fillstart,r12)
		mov	r3,r0
		mov.w	r0,@(filldata,r12)
.wait_fb:	mov.w	@(vdpsts,r12),r0
		and	#%10,r0
		tst	r0,r0
		bf	.wait_fb
.cont_l:

		mov	@r15+,r4
		mov	@r15+,r5
		mov	@r15+,r6
		mov	@r15+,r7
		add	r6,r4
		add	r7,r5
		mov.w	@(mbg_intrl_w,r13),r0
		add	r0,r9

		cmp/ge	r11,r10
		bf/s	.next_l
		add	#1,r10
.off_x:
		rts
		nop
		align 4

; 	; r9 - topleft pos
; 	; r8 - length
;
; 	; Cross-check
; 		mov	r8,r0
; 		add	r9,r0
; 		mov	r0,r7
; 		mov	r9,r8
; 		shlr8	r7
; 		shlr8	r8
; 		cmp/eq	r7,r8
; 		bt	.single
; 		mov	r0,r8
; 		and	#$FF,r0
; 		cmp/eq	#0,r0
; 		bt	.single
;
; 	; Left write
; 		mov	r8,r7
; 		sub	r0,r8
; 		mov	r8,r0
; 		dt	r0
; 		mov.w	r0,@(filllength,r12)
; 		mov	r9,r0
; 		mov.w	r0,@(fillstart,r12)
; 		mov	r4,r0
; 		mov.w	r0,@(filldata,r12)
; .wait_l:	mov.w	@(vdpsts,r12),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bf	.wait_l
;
; 		add	r7,r9
; 		mov	#$100,r8
; 		mov.w	@(fillstart,r12),r0
; 		add	r8,r0
; 		mov.w	r0,@(fillstart,r12)
; 		sub	r0,r9
; 		mov	r9,r0
; 		dt	r0
; 		mov.w	r0,@(filllength,r12)
; 		mov	r4,r0
; 		mov.w	r0,@(filldata,r12)
; .wait_r:	mov.w	@(vdpsts,r12),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bf	.wait_r
; 		rts
; 		nop
; 		align 4
;
; Single write
; .single:
; 		mov	r8,r0
; 		dt	r0
; 		mov.w	r0,@(filllength,r12)
; 		mov	r9,r0
; 		mov.w	r0,@(fillstart,r12)
; 		mov	r4,r0
; 		mov.w	r0,@(filldata,r12)
; .wait_fb:	mov.w	@(vdpsts,r12),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bf	.wait_fb
; .same_x:
; 		rts
; 		nop
; 		align 4



; 		mov	#RAM_Mars_Background,r13

; 		cmp/eq	r1,r2
; 		bt	.same_x
; 		mov	r2,r6
; 		sub	r1,r6
; 		cmp/pl	r6
; 		bf	.same_x
; 		shlr	r6
; 		mov	#RAM_Mars_Background,r13
; 		mov	#_vdpreg,r12
;
; 		mov.w	@(mbg_intrl_h,r13),r0
; 		mov	r0,r7
; 		mov.w	@(mbg_intrl_w,r13),r0
; 		mov	r0,r5
; 		mov.w	@(mbg_yfb,r13),r0
; 		add	r3,r0
; 		cmp/ge	r7,r0
; 		bf	.ylowr
; 		sub	r7,r0
; .ylowr:
; 		mulu	r5,r0
; 		sts	macl,r5
; 		mov	@(mbg_fbdata,r13),r0
; 		add	r0,r5
; 		mov	@(mbg_fbpos,r13),r0
; 		add	r0,r5
; 		add	r1,r5
; 		mov	@(mbg_intrl_size,r13),r0
; 		cmp/gt	r0,r5
; 		bf	.fb_decr
; 		sub	r0,r5
; .fb_decr:
; 		shlr	r5
;
; 	; r5 - topleft pos
; 	; r6 - length
;
; 	; Cross-check
; 		mov	r6,r0
; 		add	r5,r0
; 		mov	r0,r7
; 		mov	r5,r8
; 		shlr8	r7
; 		shlr8	r8
; 		cmp/eq	r7,r8
; 		bt	.single
; 		mov	r0,r8
; 		and	#$FF,r0
; 		cmp/eq	#0,r0
; 		bt	.single
;
; 	; Left write
; 		mov	r6,r7
; 		sub	r0,r6
; 		mov	r6,r0
; 		dt	r0
; 		mov.w	r0,@(filllength,r12)
; 		mov	r5,r0
; 		mov.w	r0,@(fillstart,r12)
; 		mov	r4,r0
; 		mov.w	r0,@(filldata,r12)
; .wait_l:	mov.w	@(vdpsts,r12),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bf	.wait_l
;
; 		add	r7,r5
; 		mov	#$100,r6
; 		mov.w	@(fillstart,r12),r0
; 		add	r6,r0
; 		mov.w	r0,@(fillstart,r12)
; 		sub	r0,r5
; 		mov	r5,r0
; 		dt	r0
; 		mov.w	r0,@(filllength,r12)
; 		mov	r4,r0
; 		mov.w	r0,@(filldata,r12)
; .wait_r:	mov.w	@(vdpsts,r12),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bf	.wait_r
; 		rts
; 		nop
; 		align 4
;
; ; Single write
; .single:
; 		mov	r6,r0
; 		dt	r0
; 		mov.w	r0,@(filllength,r12)
; 		mov	r5,r0
; 		mov.w	r0,@(fillstart,r12)
; 		mov	r4,r0
; 		mov.w	r0,@(filldata,r12)
; .wait_fb:	mov.w	@(vdpsts,r12),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bf	.wait_fb
; 		rts
; 		nop
; 		align 4
; .same_x:
; 		rts
; 		nop
; 		align 4


; TEST_VALUE:	dc.l 0
; TEST_POLYGON:
; 		dc.l 0
; 		dc.l $0101
; 		dc.l 64,-64
; 		dc.l -64,-64
; 		dc.l -64, 64
; 		dc.l  64, 64
; 		dc.w 0,0
; 		dc.w 0,0
; 		dc.w 0,0
; 		dc.w 0,0

; r7 - rotate
; r5 - X
; r6 - Y
Rotate_Point
	shll2	r7
	mov	r7,r0
	mov	#sin_table,r1
	mov	#sin_table+$800,r2
	mov	@(r0,r1),r3
	mov	@(r0,r2),r4

	dmuls.l	r5,r4		; x cos @
	sts	macl,r0
	sts	mach,r1
	xtrct	r1,r0
	dmuls.l	r6,r3		; y sin @
	sts	macl,r1
	sts	mach,r2
	xtrct	r2,r1
	add	r1,r0

	neg	r3,r3
	dmuls.l	r5,r3		; x -sin @
	sts	macl,r1
	sts	mach,r2
	xtrct	r2,r1
	dmuls.l	r6,r4		; y cos @
	sts	macl,r2
	sts	mach,r3
	xtrct	r3,r2
	add	r2,r1

	rts
	nop
	align 4
	ltorg

; ====================================================================
; ----------------------------------------------------------------
; Slave entry
; ----------------------------------------------------------------

		align 4
SH2_S_Entry:
		mov.l	#CS3|$3F000,r15		; Reset stack
		mov	#_FRT,r1
		mov     #0,r0
		mov.b   r0,@(0,r1)
		mov     #$FFFFFFE2,r0
		mov.b   r0,@(7,r1)
		mov     #0,r0
		mov.b   r0,@(4,r1)
		mov     #1,r0
		mov.b   r0,@(5,r1)
		mov     #0,r0
		mov.b   r0,@(6,r1)
		mov     #1,r0
		mov.b   r0,@(1,r1)
		mov     #0,r0
		mov.b   r0,@(3,r1)
		mov.b   r0,@(2,r1)
		mov.l   #$FFFFFEE2,r0		; Watchdog: Set interrupt priority bits (IPRA)
		mov     #%0101<<4,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1		; Watchdog: Set jump pointer (VBR + this/4) (WITV)
		shll8   r1
		mov.w   r1,@r0

; ------------------------------------------------
; Wait for Genesis, report to Master SH2
; ------------------------------------------------

.wait_md:
		mov 	#_sysreg+comm0,r2
		mov.l	@r2,r0
		cmp/eq	#0,r0
		bf	.wait_md
		mov.l	#"SLAV",r0
		mov.l	r0,@(8,r2)

; ====================================================================
; ----------------------------------------------------------------
; Slave main code
; ----------------------------------------------------------------

SH2_S_HotStart:
		mov.l	#CS3|$3F000,r15			; Reset stack
		mov.l	#RAM_Mars_Global,r14		; Reset gbr
		ldc	r14,gbr
		mov.l	#$F0,r0				; Interrupts OFF
		ldc	r0,sr
		mov.l	#_CCR,r1
		mov	#%00001000,r0			; Cache OFF
		mov.w	r0,@r1
		mov	#%00011001,r0			; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r1
		mov	#_sysreg,r1
		mov	#PWMIRQ_ON|CMDIRQ_ON,r0		; Enable these interrupts
    		mov.b	r0,@(intmask,r1)		; (Watchdog is external)
		mov 	#CACHE_SLAVE,r1			; Transfer Slave's fast-code to CACHE
		mov 	#$C0000000,r2
		mov 	#(CACHE_SLAVE_E-CACHE_SLAVE)/4,r3
.copy:
		mov 	@r1+,r0
		mov 	r0,@r2
		dt	r3
		bf/s	.copy
		add 	#4,r2
		bsr	MarsSound_Init			; Init Sound
		nop
		mov	#$20,r0				; Interrupts ON
		ldc	r0,sr
		bra	slave_loop
		nop
		align 4
		ltorg

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

slave_loop:

	; *** GEMA PWM DRIVER ***
	;
	; COMM15: %RCIOxxxx
	; R - REQUEST
	;     Request new PWM channels to play from the Z80.
	;     it requires usage of the next bit:
	; C - CLOCK, for the Z80-to-SH2 transfer part
	;     The Z80 will copy the pwmcom buffer to
	;     comms 0,2,4,6,8,10,12, the writes CLOCK
	;     the SH2 side (here) will copy those bytes to the
	;     MarsSnd_PwmControl buffer in 4 packets
	;     (hardcoded on both CPUs), bit clears on finish.
	; I - PWM RV-protection Enter
	;     Makes a temporal backup of the playing sample in
	;     CACHE and sets a RV-backup flag so it keeps playing
	;     the sample like normal while the Genesis does it's
	;     DMA Transfers (Only for samples stored in the ROM area)
	;     Write to this bit on the Genesis side and wait
	;     until it clears.
	; O - PWM RV-protection exit
	;     Set this after ALL DMA task from the Genesis side
	;     are finished.
	;     Same thing: Write to this bit on the Genesis
	;     wait until it clears.
	;
	; the other bits are free to use
		mov	#_sysreg+comm15,r9	; control comm
		mov.b	@r9,r0
		mov	#%10000000,r1
		and	r1,r0
		tst	r0,r0
		bf	.non_zero
		bra	.no_ztrnsfr
		nop
.non_zero:
		mov	#MarsSnd_PwmControl,r7
		mov	#4,r5			; number of passes (hard-coded, check Z80)
.wait_1:
		nop
		nop
		mov.b	@r9,r0			; wait first CLOCK
		and	#%01000000,r0		; from Z80
		tst	r0,r0
		bt	.wait_1
		mov	#7,r6
		mov	#_sysreg+comm0,r8
.copy_1:
		mov.w	@r8+,r0
		mov.w	r0,@r7
		dt	r6
		bf/s	.copy_1
		add	#2,r7
		mov.b	@r9,r0			; tell Z80 CLK finished
		and	#%10111111,r0
		mov.b	r0,@r9
		dt	r5
		bf	.wait_1
	; *** TRANSFER END

	; ---------------------------------
	; Process PWM
	; ---------------------------------

		mov	#0,r1				; r1 - Current PWM slot
		mov	#MarsSnd_PwmControl,r14
		mov	#MAX_PWMCHNL,r10
.next_chnl:
		mov.b	@r14,r0
		and	#$FF,r0
		cmp/eq	#0,r0
		bt	.no_req
		xor	r13,r13
		mov.b	r13,@r14
		mov	r0,r7
		and	#%111,r0
		cmp/eq	#4,r0
		bt	.pwm_keycut
		cmp/eq	#2,r0
		bf	.no_keyoff
.pwm_keycut:
		mov	#0,r2
		mov	#MarsSound_PwmEnable,r0
		jsr	@r0
		nop
		bra	.no_req
		nop

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
		bf/s	.next_chnl
		add	#1,r14		; next PWM entry
		mov	#_sysreg+comm15,r1
		mov.b	@r1,r0		; Now we are free.
		and	#%01111111,r0
		mov.b	r0,@r1
.no_ztrnsfr:

	; ---------------------------------
	; PWM wave backup Enter/Exit bits
	;
	; In case Genesis side wants
	; to do it's DMA
	; ---------------------------------

		mov	#_sysreg+comm15,r9	; ENTER
		mov.b	@r9,r0
		and	#%00100000,r0
		cmp/eq	#%00100000,r0
		bf	.refill_in
		mov	#MarsSnd_Refill,r0
		jsr	@r0
		nop
		mov	#MarsSnd_RvMode,r1	; Set backup-playback flag
		mov	#1,r0
		mov	r0,@r1
		mov.b	@r9,r0			; Refill is ready.
		and	#%11011111,r0
		mov.b	r0,@r9
.refill_in:
		mov	#_sysreg+comm15,r9	; EXIT
		mov.b	@r9,r0
		and	#%00010000,r0
		cmp/eq	#%00010000,r0
		bf	.refill_out
		mov	#MarsSnd_RvMode,r1	; Clear backup-playback flag
		mov	#0,r0
		mov	r0,@r1
		mov.b	@r9,r0
		and	#%11101111,r0
		mov.b	r0,@r9
.refill_out:
	; *** END of PWM driver for GEMA

		bra	slave_loop
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Slave | Watchdog interrupt
; ------------------------------------------------

s_irq_custom:
		mov	r2,@-r15
		mov	#_FRT,r1
		mov.b   @(7,r1),r0
		xor     #2,r0
		mov.b   r0,@(7,r1)

		mov	#$FFFFFE80,r1
		mov.w   #$A518,r0		; Watchdog OFF
		mov.w   r0,@r1
		or      #$20,r0			; ON again
		mov.w   r0,@r1
		mov	#$10,r2
		mov.w   #$5A00,r0		; Timer for the next one
		or	r2,r0
		mov.w	r0,@r1

		mov	@r15+,r2
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Cache routines
; ----------------------------------------------------------------

		include "system/mars/cache.asm"

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
		struct SH2_RAM
	if MOMPASS=1
MarsRam_System	ds.l 0
MarsRam_Video	ds.l 0
MarsRam_Dreq0	ds.l 0
MarsRam_Dreq1	ds.l 0
sizeof_marsram	ds.l 0
	else
MarsRam_System	ds.b (sizeof_marssys-MarsRam_System)
MarsRam_Video	ds.b (sizeof_marsvid-MarsRam_Video)
MarsRam_Dreq0	ds.b MAX_MDDREQ				; Shared with Genesis side
MarsRam_Dreq1	ds.b MAX_MDDREQ
sizeof_marsram	ds.l 0
	endif

.here:
	if MOMPASS=6
		message "SH2 MARS RAM: \{((SH2_RAM)&$FFFFFF)}-\{((.here)&$FFFFFF)}"
	endif
		finish

; ====================================================================
; ----------------------------------------------------------------
; MARS Sound RAM
; ----------------------------------------------------------------

; MOVED TO CACHE
; 			struct MarsRam_Sound
; MarsSnd_PwmChnls	ds.b sizeof_sndchn*MAX_PWMCHNL
; MarsSnd_PwmControl	ds.b $38	; 7 bytes per channel.
; MarsSnd_PwmCache	ds.b $100*MAX_PWMCHNL
; MarsSnd_PwmTrkData	ds.b $80*2
; MarsSnd_Active		ds.l 1
; sizeof_marssnd		ds.l 0
; 			finish

; ====================================================================
; ----------------------------------------------------------------
; MARS Video RAM
; ----------------------------------------------------------------

			struct MarsRam_Video
RAM_Mars_Background	ds.w sizeof_marsbg
RAM_Mars_VdpDrwList	ds.b sizeof_plypz*256	; Output polygon pieces to process
RAM_Mars_VdpDrwList_e	ds.l 0			; (END point)
sizeof_marsvid		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MARS System RAM
; ----------------------------------------------------------------

			struct MarsRam_System
RAM_Mars_Global		ds.l sizeof_MarsGbl		; gbr values go here.
sizeof_marssys		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; DREQ Genesis control
;
; Read these labels directly and add
; marsGbl_DreqRead to them:
;
;	mov	#DREQ_LABEL,r14
; 	mov	@(marsGbl_DreqRead,gbr),r0
; 	add	r0,r14
;
; *** Make sure it matches on the Genesis side manually ***
; ----------------------------------------------------------------

			struct 0
Dreq_Palette		ds.w 256
Dreq_BgControl		ds.l 8
Dreq_Polygons		ds.b sizeof_polygn*70
			finish
