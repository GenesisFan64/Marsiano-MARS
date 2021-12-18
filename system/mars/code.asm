; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 Section
;
; CODE for both CPUs
; RAM and some DATA go here
; ----------------------------------------------------------------

		phase CS3		; now we are at SDRAM
		cpu SH7600		; should be SH7095 but this works.

; ====================================================================
; ----------------------------------------------------------------
; User settings
; ----------------------------------------------------------------

; ----------------------------------------
; Normal sprite settings
; ----------------------------------------

MAX_MSPR	equ	128		; Maximum sprites

; ====================================================================
; ----------------------------------------------------------------
; MARS GBR variables for both SH2
; ----------------------------------------------------------------

			struct 0
marsGbl_XShift		ds.w 1		; Xshift bit at the start of master_loop
marsGbl_XPatch		ds.w 1		; Redraw counter for the $xxFF fix, set to 0 on X/Y change
marsGbl_MstrReqDraw	ds.w 1
marsGbl_CurrGfxMode	ds.w 1
marsGbl_VIntFlag_M	ds.w 1		; Sets to 0 after Masters's VBlank ends
marsGbl_VIntFlag_S	ds.w 1		; Sets to 0 after Slave's VBlank ends
marsGbl_CurrFb		ds.w 1		; Current framebuffer number (byte)
marsGbl_PalDmaMidWr	ds.w 1		; Flag to tell we are in middle of transfering palette
; marsGbl_FbMaxLines	ds.w 1		; Max lines to output to screen (MAX: 240 lines)
marsGbl_PwmCtrlUpd	ds.w 1		; Flag to update Pwm tracker channels
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
		mov	#StrM_Oops,r1
		mov	#0,r2
		bsr	MarsVdp_Print
		mov	#0,r3
		mov	#_vdpreg,r1
		mov.b	@(framectl,r1),r0
		xor	#1,r0
		mov.b	r0,@(framectl,r1)
.infin:		nop
		bra	.infin
		nop
		align 4
StrM_Oops:
		dc.b "Error on MASTER CPU",0
		align 4

; Slave only
SH2_S_Error:
		mov	#_sysreg+comm14,r1
		mov	#$1234,r0
		mov.w	r0,@r1

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
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1
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

		mov	#_vdpreg,r1		; Wait for palette access
.wait_fb:	mov.w	@(vdpsts,r1),r0		; Read status as WORD
		tst	#2,r0			; Framebuffer busy? (wait for FEN=1)
		bf	.wait_fb
.wait		mov.b	@(vdpsts,r1),r0		; Now read as a BYTE
		tst	#$20,r0			; Palette unlocked? (wait for PEN=0)
		bt	.wait
		stc	sr,@-r15
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		sts	macl,@-r15
		mov	#$F0,r0			; Disable interrupts
		ldc	r0,sr

	; Copy palette manually to SuperVDP
		mov	#1,r0
		mov.w	r0,@(marsGbl_PalDmaMidWr,gbr)
		mov	#RAM_Mars_Palette,r1
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
		mov	#0,r0
		mov.w	r0,@(marsGbl_PalDmaMidWr,gbr)

        ; OLD method: doesn't work on hardware
; 		mov	r4,@-r15
; 		mov	r5,@-r15
; 		mov	r6,@-r15
; 		mov	#RAM_Mars_Palette,r1		; Send palette stored on RAM
; 		mov	#_palette,r2
;  		mov	#256,r3
; 		mov	#%0101011011110001,r4		; transfer size 2 / burst
; 		mov	#_DMASOURCE0,r5 		; _DMASOURCE = $ffffff80
; 		mov	#_DMAOPERATION,r6 		; _DMAOPERATION = $ffffffb0
; 		mov	r1,@r5				; set source address
; 		mov	r2,@(4,r5)			; set destination address
; 		mov	r3,@(8,r5)			; set length
; 		xor	r0,r0
; 		mov	r0,@r6				; Stop OPERATION
; 		xor	r0,r0
; 		mov	r0,@($C,r5)			; clear TE bit
; 		mov	r4,@($C,r5)			; load mode
; 		add	#1,r0
; 		mov	r0,@r6				; Start OPERATION
; 		mov	@r15+,r6
; 		mov	@r15+,r5
; 		mov	@r15+,r4

		lds	@r15+,macl
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		ldc	@r15+,sr
.mid_pwrite:
		mov 	#0,r0				; Clear VintFlag for Master
		mov.w	r0,@(marsGbl_VIntFlag_M,gbr)
		rts
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Master | VRES Interrupt (RESET on Genesis)
; ------------------------------------------------

; TODO: Breaks on many RESETs

m_irq_vres:
		mov.l	#_sysreg,r0
		ldc	r0,gbr
		mov.w	r0,@(vresintclr,gbr)	; V interrupt clear
		nop
		nop
		nop
		nop
		mov	#$F0,r0
		ldc	r0,sr
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
; 		mov	#_vdpreg,r1		; Framebuffer swap request
; 		mov.b	@(framectl,r1),r0	; watchdog will check for it later
; 		xor	#1,r0
; 		mov.b	r0,@(framectl,r1)
; 		mov	#RAM_Mars_Global+marsGbl_CurrFb,r1
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
		ltorg				; Save MASTER IRQ literals here

; =================================================================
; ------------------------------------------------
; Unused
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
		mov	#_sysreg+monowidth,r1
		mov.b	@r1,r0
 		tst	#$80,r0
 		bf	.exit
		sts	pr,@-r15
		mov	#MarsSound_ReadPwm,r0
		jsr	@r0
		nop
		lds	@r15+,pr
.exit:		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1
		mov.w	r0,@r1
		rts
		nop
		align 4

; 		mov	#_FRT,r1
; 		mov.b	@(7,r1),r0
; 		xor	#2,r0
; 		mov.b	r0,@(7,r1)
; 		mov	#_sysreg+pwmintclr,r1
; 		mov.w	r0,@r1
; 		nop
; 		nop
; 		nop
; 		nop
; 		nop
; 		rts
; 		nop
; 		align 4

; =================================================================
; ------------------------------------------------
; Slave | CMD Interrupt
;
; Recieve data from Genesis using DREQ
; ------------------------------------------------

s_irq_cmd:
		stc	sr,@-r15
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)

; ----------------------------------

		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		sts	pr,@-r15
; 		mov	#MarsSnd_PwmControl,r9
; 		mov	#_sysreg+comm15,r7	; control comm
; 		mov	#4,r5			; number of passes
; .wait_1:
; 		nop
; 		nop
; 		mov.b	@r7,r0			; wait first CLOCK
; 		and	#%00100000,r0		; from Z80
; 		cmp/pl	r0
; 		bf	.wait_1
; 		mov	#7,r6
; 		mov	#_sysreg+comm0,r8
; .copy_1:
; 		mov.w	@r8+,r0
; 		mov.w	r0,@r9
; 		dt	r6
; 		bf/s	.copy_1
; 		add	#2,r9
; 		mov.b	@r7,r0			; tell Z80 CLK finished
; 		and	#%11011111,r0
; 		mov.b	r0,@r7
; 		dt	r5
; 		bf	.wait_1
; 		mov.w	#1,r0			; request SOUND update to main loop
; 		mov.w	r0,@(marsGbl_PwmCtrlUpd,gbr)
.cantupd:
		mov	#_sysreg+cmdintclr,r1	; Clear CMD flag
		mov.w	r0,@r1
; 		mov.w	@r1,r0
		lds	@r15+,pr
		mov 	@r15+,r9
		mov 	@r15+,r8
		mov 	@r15+,r7
		mov 	@r15+,r6
		mov 	@r15+,r5
		mov 	@r15+,r4
		mov 	@r15+,r3
		mov 	@r15+,r2
		ldc 	@r15+,sr
		rts
		nop
		align 4
		ltorg

; ; 		mov	#_sysreg+comm15,r1	; comm15 at bit 6
; ; 		mov.b	@r1,r0			; Clear DMA signal for MD
; ; 		and	#%10111111,r0
; ; 		mov.b	r0,@r1
; 		mov	#RAM_Mars_DREQ,r1	; r1 - Output destination
; 		mov	#$20004010,r2		; r2 - DREQ length address
; 		mov	#_DMASOURCE0,r3		; r3 - DMA Channel 0
; 		mov	#0,r0
; 		mov	r0,@($30,r3)		; DMA Stop (_DMAOPERATION)
; 		mov	r0,@($C,r3)		; _DMACHANNEL0
; 		mov	#%0100010011100000,r0
; 		mov	r0,@($C,r3)
; 		mov	#$20004012,r0		; Source data (DREQ FIFO)
; 		mov	r0,@(0,r3)
; 		mov	r1,@(4,r3)
; 		mov.w	@r2,r0
; 		mov	r0,@(8,r3)
; 		mov	#%0100010011100001,r0
; 		mov	r0,@($C,r3)
; 		mov	#1,r0
; 		mov	r0,@($30,r3)		; DMA Start (_DMAOPERATION)
; ; 		mov	#_sysreg+comm15,r1	; comm15 at bit 6
; ; 		mov.b	@r1,r0			; Tell MD to push FIFO
; ; 		or	#%01000000,r0
; ; 		mov.b	r0,@r1
;
; 		mov	#_sysreg+comm4,r2	; DEBUG
; 		mov	#RAM_Mars_DREQ,r1
; 		mov	@r1,r0
; 		mov	r0,@r2

; 		mov 	@r15+,r4
; 		mov 	@r15+,r3
; 		mov 	@r15+,r2

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
		mov 	#0,r0				; Clear VintFlag for Slave
		mov.w	r0,@(marsGbl_VIntFlag_S,gbr)
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+vintclr,r1
		rts
		mov.w	r0,@r1
		align 4

; =================================================================
; ------------------------------------------------
; Slave | VRES Interrupt (Pressed RESET on Genesis)
; ------------------------------------------------

s_irq_vres:
		mov.l	#_sysreg,r0
		ldc	r0,gbr
		mov.w	r0,@(vresintclr,gbr)	; V interrupt clear
		nop
		nop
		nop
		nop
		mov	#$F0,r0
		ldc	r0,sr
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
		mov	#CS3|$40000,r15			; Set default Stack for Master
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
; This CPU is exclusively used for visual tasks:
; Polygons, Sprites, Backgrounds...
;
; To interact with the models use the Slave CPU
; ----------------------------------------------------------------

SH2_M_HotStart:
		mov	#CS3|$40000,r15			; Stack again if coming from RESET
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
		mov	#VIRQ_ON,r0			; Enable usage of these interrupts
    		mov.b	r0,@(intmask,r1)		; (Watchdog is external)
		mov 	#CACHE_MASTER,r1		; Transfer Master's "fast code" to CACHE
		mov 	#$C0000000,r2
		mov 	#(CACHE_MASTER_E-CACHE_MASTER)/4,r3
.copy:
		mov 	@r1+,r0
		mov 	r0,@r2
		add 	#4,r2
		dt	r3
		bf	.copy
		mov	#MarsVideo_Init,r0		; Init Video
		jsr	@r0
		nop
		mov	#0,r0
		mov.w	r0,@(marsGbl_CurrGfxMode,gbr)

		mov	#_sysreg+comm14,r1
.lel:		mov.b	@r1,r0
		cmp/pz	r0
		bt	.lel

		mov	#_DMACHANNEL0,r1
		mov	#0,r0
		mov	r0,@($30,r1)
		mov	r0,@($C,r1)

		mov.l	#$20,r0				; Interrupts ON
		ldc	r0,sr
		bra	master_loop
		nop
		align 4
		ltorg

; ---------------------------------------

master_loop:

		mov.w	@(marsGbl_CurrGfxMode,gbr),r0
		mov	r0,r1
		mov	r1,r0
		and	#$80,r0
		cmp/eq	#0,r0
		bf	mstr_gfx1_loop
		mov	r1,r0
		or	#$80,r0
		mov.w	r0,@(marsGbl_CurrGfxMode,gbr)

	; Make default scroll section
		mov	#0,r1
		mov	#$200,r2
		mov	#MSCRL_BLKSIZE,r3
		mov	#MSCRL_WIDTH,r4
		mov	#MSCRL_HEIGHT,r5
		bsr	MarsVideo_MakeScreen
		nop
		mov	#0,r1
		mov	#TESTMARS_BG,r2			; Image OR RAM section
		mov	#320,r3
		mov	#240,r4
		bsr	MarsVideo_SetBg
		nop

	; TODO: buscar un lugar para estos settings
		mov	#RAM_Mars_Background,r14
		mov	#2,r0
		mov.b	r0,@(mbg_draw_all,r14)
		mov	#0,r1
		mov	#0,r2
		shll16	r1
		shll16	r2
		mov	r1,@(mbg_xpos,r14)
		mov	r2,@(mbg_ypos,r14)
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)

		mov	#TESTMARS_BG_PAL,r1		; Load palette
		mov	#0,r2
		mov	#256,r3
		mov	#$0000,r4
		mov	#MarsVideo_LoadPal,r0
		jsr	@r0
		nop

; ---------------------------------------
; Mode0 loop
; ---------------------------------------

mstr_gfx1_loop:
		mov.b	@(marsGbl_CurrFb,gbr),r0
		mov	r0,r3
		mov	#_vdpreg,r4			; Wait if frameswap is done
.wait_frmswp:	mov.b	@(framectl,r4),r0
		cmp/eq	r0,r3
		bf	.wait_frmswp
 		mov.w	@(marsGbl_XShift,gbr),r0	; Set SHIFT bit first
		mov	#_vdpreg+shift,r1
		and	#1,r0
		mov.w	r0,@r1

	; ---------------------------------------
	; New frame is now on the screen, but
	; we are still on VBlank
	; ---------------------------------------

		mov	#_vdpreg,r4		; Still on VBlank?
.wait_vblnk:	mov.b	@(vdpsts,r4),r0
		and	#$80,r0
		tst	r0,r0
		bf	.wait_vblnk

	; ---------------------------------------
	; Set DMA Channel 0 to recieve
	; DREQ FIFO data, even if the Genesis
	; side isn't doing any request
	; ---------------------------------------

		mov	#RAM_Mars_DREQ,r1
		mov	#_sysreg,r9
		mov	#_sysreg+dreqfifo,r0
		mov	#_DMASOURCE0,r8
		mov	r0,@r8			; Source
		mov	r1,@(4,r8)		; Destination
		mov.w	@(dreqlen,r9),r0
		mov	r0,@(8,r8)		; Length
		mov.l	#%0100010011100001,r0	; Transfer mode
		mov	r0,@($C,r8)		; Dest:IncFwd(01) Src:Stay(00) Size:Word(01)
		mov	#1,r0			; _DMAOPERATION = 1
		mov	r0,@($30,r8)
		mov	#_sysreg+comm14,r1	; Report that this DMA started
		mov.b	@r1,r0
		or	#%01000000,r0
		mov.b	r0,@r1
; .wait_dma:
; 		mov	@r1,r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bt	.wait_dma

	; ---------------------------------------
	; Framebuffer redraw goes here
	; ---------------------------------------

		mov	#StrM_Test,r1
		mov	#1,r2
		bsr	MarsVdp_Print
		mov	#11*8,r3
		mov	#RAM_Mars_DREQ,r1
		mov	#1,r2
		mov	#12*8,r3
		bsr	MarsVdp_PrintVal
		nop
		mov	#RAM_Mars_DREQ+(256*2)-4,r1
		mov	#10,r2
		mov	#12*8,r3
		bsr	MarsVdp_PrintVal
		nop

		mov	#RAM_Mars_Background,r14
		bsr	MarsVideo_MoveBg
		nop
		mov.b	@(mbg_draw_all,r14),r0
		cmp/eq	#0,r0
		bt	.no_redraw
		dt	r0
		mov.b	r0,@(mbg_draw_all,r14)
		bsr	MarsVideo_DrawAllBg
		nop
		mov	#0,r0
		mov.b	r0,@(mbg_draw_u,r14)	; Cancel
		mov.b	r0,@(mbg_draw_d,r14)	; the
		mov.b	r0,@(mbg_draw_l,r14)	; other
		mov.b	r0,@(mbg_draw_r,r14)	; timers
.no_redraw:
		mov	#MarsVideo_BgDrawLR,r0
		jsr	@r0
		nop
		mov	#MarsVideo_BgDrawUD,r0
		jsr	@r0
		nop
		mov	#RAM_Mars_Background,r1
		mov	#0,r2
		mov	#240,r3
		bsr	MarsVideo_MakeTbl
		nop
		bsr	MarsVideo_FixTblShift
		nop
		mov	#_vdpreg,r1
		mov.b	@(framectl,r1),r0		; Framebuffer swap REQUEST
		xor	#1,r0				; (swap is done during VBlank)
		mov.b	r0,@(framectl,r1)		; Save new bit
		mov.b	r0,@(marsGbl_CurrFb,gbr)	; And a copy for checking

		bra	master_loop
		nop
		align 4
		ltorg

StrM_Test:
		dc.b "32X recibe por DREQ:",0
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
		add 	#4,r2
		dt	r3
		bf	.copy
		bsr	MarsSound_Init			; Init Sound
		nop
; 		mov	#MarsMdl_Init,r0		; REMINDER: 1 meter = $10000
; 		jsr	@r0
; 		nop

		mov.l	#$20,r0				; Interrupts ON
		ldc	r0,sr

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

; 		mov	#_sysreg+comm15,r1
; .wait_s:	mov.b	@r1,r0
; 		cmp/pz	r0
; 		bt	.wait_s
; 		xor	r0,r0
; 		mov.b	r0,@r1
		bra	slave_loop
		nop
		align 4
		ltorg

slave_loop:
		mov	#_sysreg+comm15,r1
		mov.b	@r1,r0
		and	#$01,r0
		cmp/eq	#0,r0
		bt	.TEST_1
		and	#%11111110,r0
; 		xor	r0,r0
		mov.b	r0,@r1
		stc	sr,@-r15		; Interrupts OFF
		mov	#$F0,r0
		mov	#0,r1
		mov	#SmpIns_Bell_Ice+6,r2
		mov	#SmpIns_Bell_Ice+$3B2A,r3
		mov	#0,r4
		mov	#$80,r5
		mov	#0,r6
		mov	#%1011,r7
		mov	#MarsSound_SetPwm,r0
		jsr	@r0
		nop
; 		mov	#1,r1
; 		mov	#SmpIns_Brass1_Low+6,r2
; 		mov	#SmpIns_Brass1_Low+$3FD8,r3
; 		mov	#0,r4
; 		mov	#$30,r5
; 		mov	#0,r6
; 		mov	#%1011,r7
; 		mov	#MarsSound_SetPwm,r0
; 		jsr	@r0
; 		nop
; 		mov	#0,r1
; 		mov	#PWM_STEREO+6,r2
; 		mov	#PWM_STEREO_e,r3
; 		mov	#0,r4
; 		mov	#$100,r5
; 		mov	#0,r6
; 		mov	#%1111,r7
; 		mov	#MarsSound_SetPwm,r0
; 		jsr	@r0
; 		nop
; 		mov	#1,r1
; 		mov	#PWM_STEREO+6,r2
; 		mov	#PWM_STEREO_e,r3
; 		mov	#0,r4
; 		mov	#$100,r5
; 		mov	#0,r6
; 		mov	#%1111,r7
; 		mov	#MarsSound_SetPwm,r0
; 		jsr	@r0
; 		nop
		ldc	@r15+,sr
.TEST_1:

	; *** GEMA PWM DRIVER
	; %RCIOxxxx
	; R - REQUEST
	;     Request new PWM channels to play from the Z80,
	;     requires usage of the next bit:
	; C - CLOCK, for the Z80-to-SH2 transfer part
	;     The Z80 will copy the pwmcom buffer to
	;     comms 0,2,4,6,8,10,12, write CLOCK and the SH2 side
	;     will copy those bytes to the MarsSnd_PwmControl buffer
	;     in packs of 4 (hardcoded on both CPUs),
	;     clears when it finished processing
	; I - PWM RV-protection enter
	;     Makes a temporal backup of the playing sample in
	;     CACHE and sets a RV-backup flag so it keeps playing
	;     the sample even if the Genesis side is doing DMA
	;     (Only for samples stored in the ROM area)
	; O - PWM RV-protection exit
	;     Set this after ALL DMA task from the Genesis side
	;     are finished.
	;
	; xxxx bits are free to use
	;
		mov	#_sysreg+comm15,r9	; control comm
		mov.b	@r9,r0
		mov	#%10000000,r1
		and	r1,r0
		cmp/eq	r1,r0
		bt	.non_zero
		bra	.no_ztrnsfr
		nop
.non_zero:
	; TRANSFER START
		mov	#MarsSnd_PwmControl,r7
		mov	#4,r5			; number of passes
.wait_1:
		nop
		nop
		mov.b	@r9,r0			; wait first CLOCK
		and	#%01000000,r0		; from Z80
		cmp/pl	r0
		bf	.wait_1
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

		mov	#0,r1			; r1 - PWM slot
		mov	#MarsSnd_PwmControl,r14
		mov	#7,r10
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


	; TODO: Change reading struct if
	; it gets too CPU intensive
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

	; PWM backup enter/exit bits
	; In case Genesis side wants to do
	; DMA transfers
		mov	#_sysreg+comm15,r9
		mov.b	@r9,r0
		and	#%00100000,r0
		cmp/eq	#%00100000,r0
		bf	.refill_in
		mov	#MarsSnd_Refill,r0
		jsr	@r0
		nop
		mov	#MarsSnd_RvMode,r1
		mov	#1,r0
		mov	r0,@r1
		mov.b	@r9,r0			; Refill is ready.
		and	#%11011111,r0
		mov.b	r0,@r9
.refill_in:
		mov	#_sysreg+comm15,r9
		mov.b	@r9,r0
		and	#%00010000,r0
		cmp/eq	#%00010000,r0
		bf	.refill_out
		mov	#MarsSnd_RvMode,r1
		mov	#0,r0
		mov	r0,@r1
		mov.b	@r9,r0
		and	#%11101111,r0
		mov.b	r0,@r9
.refill_out:
	; *** END PWM driver for GEMA

		bra	slave_loop
		nop
		align 4
		ltorg

		align 4
; this_polygon:
; 		dc.w $8000
; 		dc.w 320
; 		dc.l TESTMARS_BG
; dest_data:	dc.w  32,-32
; 		dc.w -32,-32
; 		dc.w -32, 32
; 		dc.w  32, 32
; 		dc.w 274, 79
; 		dc.w 199, 79
; 		dc.w 199,142-1
; 		dc.w 274,142-1
rot_angle	dc.l 0
;
;

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

; ; ------------------------------------------------
; ; Process task requests from Genesis
; ; ------------------------------------------------
;
; 		mov	#_sysreg+comm15,r1
; 		mov.b	@r1,r0
; 		and	#$80,r0
; 		cmp/eq	#0,r0
; 		bt	.no_req
; 		mov	#MAX_MDTASKS,r13
; 		mov	#RAM_Mars_MdTasksFifo_S,r14
; .next_req:
; 		mov	r13,@-r15
; 		mov	@r14,r0
; 		cmp/eq	#0,r0
; 		bt	.no_task
; 		jsr	@r0
; 		nop
; 		xor	r0,r0
; 		mov	r0,@r14
; .no_task:
; 		mov	#MAX_MDTSKARG*4,r0
; 		mov	@r15+,r13
; 		dt	r13
; 		bf/s	.next_req
; 		add	r0,r14
; 		mov	#_sysreg+comm15,r1
; 		mov.b	@r1,r0
; 		and	#$7F,r0
; 		mov.b	r0,@r1
; .no_req:
; 		mov	#_sysreg+comm15,r1
; 		mov.b	@r1,r0
; 		and	#$7F,r0
; 		cmp/eq	#1,r0
; 		bf	slave_loop

; --------------------------------------------------------
; Start building polygons from models
;
; *** CAMERA ANIMATION IS DONE ON THE 68K ***
; --------------------------------------------------------

; 		mov	#0,r0
; 		mov.w	r0,@(marsGbl_MdlFacesCntr,gbr)
; 		mov 	#RAM_Mars_Polygons_0,r1
; 		mov	#RAM_Mars_Plgn_ZList_0,r2
; 		mov.w   @(marsGbl_PlgnBuffNum,gbr),r0
; 		tst     #1,r0
; 		bt	.go_mdl
; 		mov 	#RAM_Mars_Polygons_1,r1
; 		mov	#RAM_Mars_Plgn_ZList_1,r2
; .go_mdl:
; 		mov	r1,r0
; 		mov	r0,@(marsGbl_CurrFacePos,gbr)
; 		mov	r2,r0
; 		mov	r0,@(marsGbl_CurrZList,gbr)
; 		mov	#$FFFFFE80,r1
; 		mov.w	#$5A7F,r0			; Watchdog wait timer
; 		mov.w	r0,@r1
; 		mov.w	#$A538,r0			; Watchdog ON
; 		mov.w	r0,@r1
;
; ; ----------------------------------------
;
; 		mov	#_CCR,r1			; <-- Required for Watchdog
; 		mov	#%00001000,r0			; Two-way mode
; 		mov.w	r0,@r1
; 		mov	#%00011001,r0			; Cache purge / Two-way mode / Cache ON
; 		mov.w	r0,@r1
; 		mov	#MarsLay_Read,r0		; Build layout inside camera
; 		jsr	@r0				; takes 9 object slots
; 		nop
; 		mov	#RAM_Mars_Objects,r14		; Build all objects
; 		mov	#MAX_MODELS,r13
; .loop:
; 		mov	@(mdl_data,r14),r0		; Object model data == 0 or -1?
; 		cmp/pl	r0
; 		bf	.invlid
; 		mov	#MarsMdl_ReadModel,r0
; 		jsr	@r0
; 		mov	r13,@-r15
; 		mov	@r15+,r13
; 		mov	#0,r0
; 		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0	; Ran out of space to store faces?
; 		mov	#MAX_MPLGN,r1
; 		cmp/ge	r1,r0
; 		bt	.skip
; .invlid:
; 		dt	r13
; 		bf/s	.loop
; 		add	#sizeof_mdlobj,r14
; .skip:
; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_ZSortReq,gbr)
;
; ; ----------------------------------------
;
; .wait_z:
; 		mov.w	@(marsGbl_ZSortReq,gbr),r0
; 		cmp/eq	#1,r0
; 		bt	.wait_z
; 		mov.l   #$FFFFFE80,r1			; Stop watchdog
; 		mov.w   #$A518,r0
; 		mov.w   r0,@r1
;
; ; ----------------------------------------
;
; ; 		mov 	#RAM_Mars_Plgn_ZList_0,r14
; 		mov 	#RAM_Mars_PlgnNum_0,r13
; 		mov.w   @(marsGbl_PlgnBuffNum,gbr),r0
; 		tst     #1,r0
; 		bt	.page_2
; ; 		mov 	#RAM_Mars_Plgn_ZList_1,r14
; 		mov 	#RAM_Mars_PlgnNum_1,r13
; .page_2:
; 		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0
; 		mov.w	r0,@r13
;
; 		mov	#_sysreg+comm2,r4		; DEBUG COUNTER
; ; 		mov	#0,r0
; 		mov.w	r0,@r4
; 		mov	#_sysreg+comm14,r2
; .mstr_busy:
; 		mov.b	@r2,r0
; 		and	#$7F,r0
; 		cmp/eq	#0,r0
; 		bf	.mstr_busy			; Skip frame
; 		mov.w	@(marsGbl_PlgnBuffNum,gbr),r0	; Swap polygon buffer
;  		xor	#1,r0
;  		mov.w	r0,@(marsGbl_PlgnBuffNum,gbr)
;  		mov	#1,r1				; Set task $01 to Master
; 		mov.b	@r2,r0
; 		and	#$80,r0
; 		or	r1,r0
; 		mov.b	r0,@r2
;
; 		mov	#_sysreg+comm15,r1
; 		mov.b	@r1,r0
; 		and	#$80,r0
; 		mov.b	r0,@r1

; ====================================================================
; --------------------------------------------------------
; Task list for MD-to-MARS tasks, call these 68k side
; with the respective arguments
;
; *** 68k EXAMPLES ***
;
; Single task:
; 	move.l	#CmdTaskMd_SetBitmap,d0		; 32X display ON
; 	moveq	#1,d1
; 	bsr	System_MdMars_MstAddTask
;
; Queued task:
; 	move.l	#Palette_Intro,d1
; 	moveq	#0,d2
; 	mov.w	#16,d3
; 	moveq	#0,d4
; 	move.l	#CmdTaskMd_LoadSPal,d0		; Load palette
; 	bsr	System_MdMars_MstAddTask
;	; then add more requests
; 	bsr	System_MdMars_MstSendAll	; <-- Send all and wait
; 	; or
; 	bsr	System_MdMars_MstSendDrop	; <-- Send all but skip if busy
;
; Mst: for Master, processes until all draw-tasks finished
; Slv: for Slave, processes after sorting model faces
; --------------------------------------------------------

		align 4

; ------------------------------------------------
; CALLS EXCLUSIVE TO MASTER CPU
; ------------------------------------------------

; ------------------------------------------------
; Set SuperVDP bitmap value
;
; @($04,r14) - SuperVDP bitmap number (0-3)
; ------------------------------------------------

CmdTaskMd_SetBitmap:
		mov 	#_vdpreg,r1
.wait_fb:	mov.w   @($A,r1),r0
		tst     #2,r0
		bf      .wait_fb
		mov	@($04,r14),r0
		mov.b	r0,@(bitmapmd,r1)
		rts
		nop
		align 4

; ------------------------------------------------
; Load palette to SuperVDP from MD
;
; @($04,r14) - Palette data
; @($08,r14) - Start from
; @($0C,r14) - Number of colors
; @($10,r14) - OR value
; ------------------------------------------------

CmdTaskMd_LoadSPal:
		mov	r14,r13
		add	#4,r13
		mov	@r13+,r1
		mov	@r13+,r2
		mov	@r13+,r3
		mov	@r13+,r4
		mov	#MarsVideo_LoadPal,r0
		jmp	@r0
		nop
		align 4

; ------------------------------------------------
; CALLS EXCLUSIVE TO SLAVE CPU
; ------------------------------------------------

; ; ------------------------------------------------
; ; Make new object and insert it to specific slot
; ;
; ; @($04,r14) - Object slot
; ; @($08,r14) - Object data
; ; @($0C,r14) - Object animation data
; ; @($10,r14) - Object animation speed
; ; @($14,r14) - Object options:
; ;	       %????????????????????????pppppppp
; ;		p - index pixel increment value
; ; ------------------------------------------------
;
; CmdTaskMd_ObjectSet:
; 		mov	#RAM_Mars_Objects+(sizeof_mdlobj*9),r12
; 		mov	r14,r13
; 		add	#4,r13
; 		mov	@r13+,r0
; 		mov	#sizeof_mdlobj,r1
; 		mulu	r1,r0
; 		sts	macl,r0
; 		add	r0,r12
; 		xor	r0,r0
; 		mov	@r13+,r1
; 		mov	r1,@(mdl_data,r12)
; 		mov	@r13+,r1
; 		mov	r1,@(mdl_animdata,r12)
; 		mov	@r13+,r1
; 		mov	r1,@(mdl_animspd,r12)
; 		mov	@r13+,r1
; 		mov	r1,@(mdl_option,r12)
; 		xor	r0,r0
; 		mov	r0,@(mdl_x_pos,r12)
; 		mov	r0,@(mdl_y_pos,r12)
; 		mov	r0,@(mdl_z_pos,r12)
; 		mov	r0,@(mdl_x_rot,r12)
; 		mov	r0,@(mdl_y_rot,r12)
; 		mov	r0,@(mdl_z_rot,r12)
; 		mov	r0,@(mdl_animframe,r12)
; 		mov	r0,@(mdl_animtimer,r12)
; 		rts
; 		nop
; 		align 4
;
; ; ------------------------------------------------
; ; Move/Rotate object from slot
; ;
; ; @($04,r14) - Object slot
; ; @($08,r14) - Object X pos
; ; @($0C,r14) - Object Y pos
; ; @($10,r14) - Object Z pos
; ; @($14,r14) - Object X rot
; ; @($18,r14) - Object Y rot
; ; @($1C,r14) - Object Z rot
; ; ------------------------------------------------
;
; CmdTaskMd_ObjectPos:
; 		mov	#RAM_Mars_Objects+(sizeof_mdlobj*9),r12
; 		mov	r14,r13
; 		add	#4,r13
; 		mov	@r13+,r0
; 		mov	#sizeof_mdlobj,r1
; 		mulu	r1,r0
; 		sts	macl,r0
; 		add	r0,r12
; 		mov	@r13+,r1
; 		mov	@r13+,r2
; 		mov	@r13+,r3
; 		mov	@r13+,r4
; 		mov	@r13+,r5
; 		mov	@r13+,r6
; 		mov	r1,@(mdl_x_pos,r12)
; 		mov	r2,@(mdl_y_pos,r12)
; 		mov	r3,@(mdl_z_pos,r12)
; 		mov	r4,@(mdl_x_rot,r12)
; 		mov	r5,@(mdl_y_rot,r12)
; 		mov	r6,@(mdl_z_rot,r12)
; 		rts
; 		nop
; 		align 4
;
; ; ------------------------------------------------
; ; Clear ALL objects, including layout
; ; ------------------------------------------------
;
; CmdTaskMd_ObjectClrAll:
; 		sts	pr,@-r15
; 		mov	#MarsMdl_Init,r0
; 		jsr	@r0
; 		nop
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
;
; ; ------------------------------------------------
; ; Set new map data
; ;
; ; @($04,r14) - layout data (set to 0 to clear)
; ; ------------------------------------------------
;
; CmdTaskMd_MakeMap:
; 		sts	pr,@-r15
; ; 		bsr	MarsVideo_ClearFrame
; ; 		nop
; 		mov	@(4,r14),r1
; 		mov	#MarsLay_Make,r0
; 		jsr	@r0
; 		mov	r14,@-r15
; 		mov	@r15+,r14
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
;
; ; ------------------------------------------------
; ; Set camera position
; ;
; ; @($04,r14) - Camera slot (TODO)
; ; @($08,r14) - Camera X pos
; ; @($0C,r14) - Camera Y pos
; ; @($10,r14) - Camera Z pos
; ; @($14,r14) - Camera X rot
; ; @($18,r14) - Camera Y rot
; ; @($1C,r14) - Camera Z rot
; ; ------------------------------------------------
;
; CmdTaskMd_CameraPos:
; 		mov	#RAM_Mars_ObjCamera,r12
; 		mov	r14,r13
; 		add	#8,r13
; 		mov	@r13+,r1
; 		mov	@r13+,r2
; 		mov	@r13+,r3
; 		mov	@r13+,r4
; 		mov	@r13+,r5
; 		mov	@r13+,r6
; 		mov	r1,@(cam_x_pos,r12)
; 		mov	r2,@(cam_y_pos,r12)
; 		mov	r3,@(cam_z_pos,r12)
; 		mov	r4,@(cam_x_rot,r12)
; 		mov	r5,@(cam_y_rot,r12)
; 		mov	r6,@(cam_z_rot,r12)
; 		rts
; 		nop
; 		align 4
;
; ; ------------------------------------------------
; ; Set camera position
; ;
; ; @($04,r14) - Camera slot (TODO)
; ; @($08,r14) - Camera X pos
; ; @($0C,r14) - Camera Y pos
; ; @($10,r14) - Camera Z pos
; ; @($14,r14) - Camera X rot
; ; @($18,r14) - Camera Y rot
; ; @($1C,r14) - Camera Z rot
; ; ------------------------------------------------
;
; CmdTaskMd_UpdModels:
; 		mov	#_sysreg+comm15,r1
; 		mov	#1,r2
; 		mov.b	@r1,r0
; 		and	#$80,r0
; 		or	r2,r0
; 		mov.b	r0,@r1
; 		rts
; 		nop
; 		align 4
;
; ; ------------------------------------------------
; ; Set PWM to play
; ;
; ; @($04,r14) - Channel slot
; ; @($08,r14) - Start point
; ; @($0C,r14) - End point
; ; @($10,r14) - Loop point
; ; @($14,r14) - Pitch
; ; @($18,r14) - Volume
; ; @($1C,r14) - Settings: %00000000 00000000LR | LR - output bits
; ; ------------------------------------------------
;
; CmdTaskMd_PWM_SetChnl:
; 		sts	pr,@-r15
; 		mov	@($04,r14),r1
; 		mov	@($08,r14),r2
; 		mov	@($0C,r14),r3
; 		mov	@($10,r14),r4
; 		mov	@($14,r14),r5
; 		mov	@($18,r14),r6
; 		mov	@($1C,r14),r7
; 		bsr	MarsSound_SetPwm
; 		nop
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
;
; ; ------------------------------------------------
; ; Set PWM pitch to multiple channels
; ;
; ; @($04,r14) - Channel 0 pitch
; ; @($08,r14) - Channel 1 pitch
; ; @($0C,r14) - Channel 2 pitch
; ; @($10,r14) - Channel 3 pitch
; ; @($14,r14) - Channel 4 pitch
; ; @($18,r14) - Channel 5 pitch
; ; @($1C,r14) - Channel 6 pitch
; ; ------------------------------------------------
;
; CmdTaskMd_PWM_MultPitch:
; 		sts	pr,@-r15
; 		mov	#$FFFF,r7
; 		mov	r14,r13
; 		add	#4,r13
; 		mov	#0,r1
; 	rept MAX_PWMCHNL		; MAX: 7
; 		mov	@r13+,r2
; 		and	r7,r2
; 		bsr	MarsSound_SetPwmPitch
; 		nop
; 		add	#1,r1
; 	endm
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
;
; ; ------------------------------------------------
; ; Enable/Disable PWM channels from playing
; ;
; ; @($04,r14) - Channel slot
; ; @($08,r14) - Enable/Disable/Restart
; ; ------------------------------------------------
;
; CmdTaskMd_PWM_Enable:
; 		sts	pr,@-r15
; 		mov	@($04,r14),r1
; 		mov	@($08,r14),r2
; 		bsr	MarsSound_PwmEnable
; 		nop
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4

; ----------------------------------------

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
; MarsRam_Sound	ds.l 0
sizeof_marsram	ds.l 0
	else
MarsRam_System	ds.b (sizeof_marssys-MarsRam_System)
MarsRam_Video	ds.b (sizeof_marsvid-MarsRam_Video)
; MarsRam_Sound	ds.b (sizeof_marssnd-MarsRam_Sound)
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
RAM_Mars_Palette	ds.w 256	; Indexed palette
RAM_Mars_HBlMdShft	ds.w 240	; Mode and Xshift bit for each HBlank
RAM_Mars_Background	ds.w sizeof_marsbg
RAM_Mars_LineTblCopy	ds.l 240	; Index | BadLine
sizeof_marsvid		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MARS System RAM
; ----------------------------------------------------------------

			struct MarsRam_System
RAM_Mars_DREQ		ds.w 256			; 128 LONGS of storage
RAM_Mars_Global		ds.l sizeof_MarsGbl		; gbr values go here.
sizeof_marssys		ds.l 0
			finish
