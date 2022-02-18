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
; MARS GLOBAL gbr variables for both SH2
; ----------------------------------------------------------------

			struct 0
marsGbl_DreqRead	ds.l 1	; DREQ Read/Write pointers
marsGbl_DreqWrite	ds.l 1	; these get swapped on VBlank
marsGbl_PlyPzList_R	ds.l 1	; Current graphic piece to draw
marsGbl_PlyPzList_W	ds.l 1	; Current graphic piece to write
marsGbl_IndxPlgn	ds.l 1	; Current polygon to slice
marsGbl_CurrZList	ds.l 1	; Current Zsort entry
marsGbl_CurrFacePos	ds.l 1	; Current top face of the list while reading model data
marsGbl_DreqSwap	ds.w 1	; DREQ mid-swap flag
marsGbl_CurrNumFaces	ds.w 1	; And the number of faces stored on that list
marsGbl_WdgMode		ds.w 1	; Current Watchdog task
marsGbl_PolyBuffNum	ds.w 1	; Polygon-list swap number
marsGbl_PlyPzCntr	ds.w 1	; Number of graphic pieces to draw
marsGbl_PlgnCntr	ds.w 1	; Number of polygons to slice
marsGbl_XShift		ds.w 1	; Xshift bit at the start of master_loop (TODO: maybe a HBlank list?)
marsGbl_CurrFb		ds.w 1	; Current framebuffer number (It's a byte)
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
		mov	#_sysreg+comm12,r1
		stc	sr,r0
		mov.b	r0,@r1
		mov	#$F0,r0
		ldc	r0,sr
.infin:		nop
		bra	.infin
		nop
		align 4

SH2_S_Error:
		mov	#_sysreg+comm12+1,r1
		stc	sr,r0
		mov.b	r0,@r1
		mov	#$F0,r0
		ldc	r0,sr
.infin:		nop
		bra	.infin
		nop
		align 4

; 		mov	#StrM_Oops,r1		; Print text on screen
; 		mov	#0,r2
; 		bsr	MarsVdp_Print
; 		mov	#0,r3
; 		mov	#_vdpreg,r1		; Show it on next FB
; 		mov.b	@(framectl,r1),r0
; 		xor	#1,r0
; 		mov.b	r0,@(framectl,r1)
;
; 		mov	#_sysreg+comm14,r1
; 		mov	#-1,r0
; 		mov.b	r0,@r1
; .infin:		nop
; 		bra	.infin
; 		nop
; 		align 4
; StrM_Oops:
; 		dc.b "Error on MASTER CPU",0
; 		align 4


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
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	#_sysreg+cmdintclr,r1
		mov.w	r0,@r1

		mov	#$FFFFFE80,r1
		mov.w	#$A518,r0		; Disable Watchdog
		mov.w	r0,@r1
		mov	#_sysreg+comm14,r3	; control comm
		mov	@(marsGbl_DreqRead,gbr),r0
		mov	r0,r2
.wait_1:
		mov.b	@r3,r0
		tst	#%10000000,r0		; 68k enter/exit
		bt	.exit_c
		tst	#%01000000,r0		; wait CLOCK
		bt	.wait_1
		mov	#_sysreg+comm0,r1
.copy_1:
		mov	@r1+,r0
		mov	r0,@r2
		add	#4,r2
		mov	@r1+,r0
		mov	r0,@r2
		add	#4,r2
		mov.b	@r3,r0			; CLK done
		and	#%10111111,r0
		mov.b	r0,@r3
		bra	.wait_1
		nop
.exit_c:
		mov	#$FFFFFE80,r1
		mov.w	#$5A20,r0		; Watchdog pre-timer
		mov.w	r0,@r1
		mov.w	#$A518|$20,r0		; Enable Watchdog
		mov.w	r0,@r1

; 		dt	r4
; 		bf	.wait_1

	; DREQ is not very stable.
; 		mov	#_sysreg+cmdintclr,r4
; 		mov	@(marsGbl_DreqRead,gbr),r0
; 		mov	r0,r1
; 		mov	#_DMASOURCE0,r2
; 		mov.l   #_sysreg,r3
; 		mov.l   #_sysreg+dreqfifo,r0
; 		mov.l   r0,@(0,r2)
; 		mov.l   r1,@(4,r2)
; 		mov.w   @($10,r3),r0
; 		mov.l   r0,@(8,r2)
; 		mov.l   #$44E1,r0
; 		mov.l   r0,@($0C,r2)
; 		mov.l   #1,r0
; 		mov.l   r0,@($30,r2)
; 		mov.w	r0,@r4
; .dma_wait:
; 		mov	@($C,r2),r0
; 		tst     #2,r0
; 		bt      .dma_wait
; 		mov     #0,r0
; 		mov	r0,@($30,r2)

		mov	@r15+,r5
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

		mov	#_sysreg+comm8,r5
		mov	#_sysreg+comm15,r4	; control comm
		mov	#MarsSnd_PwmControl,r2
		mov	#14,r3			; number of passes (hard-coded, check Z80)
.wait_1:
		mov.b	@r4,r0			; wait first CLOCK
		and	#%10000000,r0		; from Z80
		tst	r0,r0
		bt	.wait_1
		mov	@r5,r0
		mov	r0,@r2
		add	#4,r2
		mov.b	@r4,r0			; tell Z80 CLK finished
		and	#%01111111,r0
		mov.b	r0,@r4
		dt	r3
		bf	.wait_1

	; ---------------------------------
	; *** GEMA PWM DRIVER ***
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

; 	; ---------------------------------
; 	; PWM wave backup Enter/Exit bits
; 	;
; 	; In case Genesis side wants
; 	; to do it's DMA
; 	; ---------------------------------
;
; 		mov	#_sysreg+comm15,r9	; ENTER
; 		mov.b	@r9,r0
; 		and	#%00100000,r0
; 		cmp/eq	#%00100000,r0
; 		bf	.refill_in
; 		mov	#MarsSnd_Refill,r0
; 		jsr	@r0
; 		nop
; 		mov	#MarsSnd_RvMode,r1	; Set backup-playback flag
; 		mov	#1,r0
; 		mov	r0,@r1
; 		mov.b	@r9,r0			; Refill is ready.
; 		and	#%11011111,r0
; 		mov.b	r0,@r9
; .refill_in:
; 		mov	#_sysreg+comm15,r9	; EXIT
; 		mov.b	@r9,r0
; 		and	#%00010000,r0
; 		cmp/eq	#%00010000,r0
; 		bf	.refill_out
; 		mov	#MarsSnd_RvMode,r1	; Clear backup-playback flag
; 		mov	#0,r0
; 		mov	r0,@r1
; 		mov.b	@r9,r0
; 		and	#%11101111,r0
; 		mov.b	r0,@r9
; .refill_out:

	; ---------------------------------
	; *** END of PWM driver for GEMA
	; ---------------------------------

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
		mov	#_DMACHANNEL0,r1
		mov	#0,r0
		mov	r0,@($30,r1)
		mov	r0,@($C,r1)

		mov	#MarsVideo_Init,r0		; Init Video
		jsr	@r0
		nop
		mov	#MarsRam_Dreq0,r0
		mov	r0,@(marsGbl_DreqRead,gbr)
; 		mov	#MarsRam_Dreq1,r0
; 		mov	r0,@(marsGbl_DreqWrite,gbr)
		mov.l	#$20,r0				; Interrupts ON
		ldc	r0,sr

	; TODO: ver como mover esto al Genesis
		mov	#RAM_Mars_Background,r1
		mov	#$200,r2
		mov	#8,r3
		mov	#320,r4
		mov	#240,r5
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
		mov	#_sysreg+comm12,r1
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1

	; ---------------------------------------
	; Wait for frameswap
		mov	#_vdpreg,r1			; r1 - SVDP area
		mov.b	@(marsGbl_CurrFb,gbr),r0	; r2 - NEW Framebuffer number
		mov	r0,r2
.wait_frmswp:	mov.b	@(framectl,r1),r0		; Framebuffer ready?
		cmp/eq	r0,r2
		bf	.wait_frmswp
 		mov.w	@(marsGbl_XShift,gbr),r0	; Set SHIFT bit first
		mov	#_vdpreg+shift,r1		; For the indexed-scrolling
		and	#1,r0
		mov.w	r0,@r1

	; ---------------------------------------
	; New frame is now shown on screen but
	; we are still on VBlank
	; ---------------------------------------

		stc	sr,@-r15		; Interrupts OFF
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_vdpreg,r1
.wait:		mov.b	@(vdpsts,r1),r0
		and	#$20,r0
		tst	r0,r0			; Palette unlocked?
		bt	.wait
		mov	#Dreq_Palette,r1
		mov	@(marsGbl_DreqRead,gbr),r0
		add	r0,r1
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
		ldc	@r15+,sr
; 		mov	#_vdpreg,r1		; Still on VBlank?
; .no_vbl:
; 		mov.b	@(vdpsts,r1),r0
; 		and	#$80,r0
; 		tst	r0,r0
; 		bf	.no_vbl

; ---------------------------------------
; Pick graphics mode on comm14
; ---------------------------------------

		mov	#_sysreg+comm14,r1
		mov.b	@r1,r0
		mov	r0,r2
		mov	#%00100000,r3
		and	#%00000011,r0
		and	r3,r2
		shll2	r0
		mov	#.list,r3
		mov	@(r3,r0),r3
		jmp	@r3
		nop
		align 4
.list:
		dc.l mstr_gfx_0
		dc.l mstr_gfx_1
		dc.l mstr_gfx_2
		dc.l mstr_gfx_0

; ---------------------------------------
; Mode 0: BLANK
; ---------------------------------------

mstr_gfx_0:
		tst	r2,r2
		bt	.lel
		mov.b	@r1,r0
		and	#%11011111,r0
		mov.b	r0,@r1
		mov 	#_vdpreg,r1
		mov	#0,r0
		mov.b	r0,@(bitmapmd,r1)
.lel:
		bra	mstr_nextframe
		nop

; ---------------------------------------
; Mode 1: Scrolling background and
; sprites
; ---------------------------------------

mstr_gfx_1:
		tst	r2,r2
		bt	.lel
		mov.b	@r1,r0
		and	#%11011111,r0
		mov.b	r0,@r1
		mov	#Cach_Drw_All,r1		; DrawAll request (2 times)
		mov	#2,r0
		mov	r0,@r1
		mov	#RAM_Mars_Background,r1
		mov	#$200,r2
		mov	#16,r3
		mov	#320,r4
		mov	#256,r5
		bsr	MarsVideo_MkScrlField
		mov	#0,r6
		mov	#RAM_Mars_Background,r1
		mov	#TESTMARS_BG,r2			; Image / RAM section
		mov	#320,r3
		mov	#224,r4
		bsr	MarsVideo_SetBg
		nop
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
.lel:
	; ---------------------------------------
	; Control background position
	; ---------------------------------------
		stc	sr,@-r15		; Interrupts OFF
		mov	#$F0,r0
		ldc	r0,sr
		mov	#RAM_Mars_Background,r14
		mov	#Dreq_BgXpos,r13
		mov	@(marsGbl_DreqRead,gbr),r0
		add	r0,r13
		mov	@r13+,r1
		mov	@r13+,r2
		ldc	@r15+,sr
		mov	r1,@(mbg_xpos,r14)
		mov	r2,@(mbg_ypos,r14)
		bsr	MarsVideo_MoveBg
		nop
	; ---------------------------------------
		mov	#Cach_Drw_All,r13		; DrawAll != 0?
		mov	@r13,r0
		cmp/eq	#0,r0
		bt	.no_redraw
		dt	r0
		mov	r0,@r13
		bsr	MarsVideo_DrawAllBg
		nop
		bra	.from_drwall			; Don't need to draw off-screen
		nop
.no_redraw:
		mov	#MarsVideo_BgDrawLR,r0		; Process U/D/L/R
		jsr	@r0
		nop
		mov	#MarsVideo_BgDrawUD,r0
		jsr	@r0
		nop
.from_drwall:
	; ---------------------------------------
	; Build linetable
	; ---------------------------------------
		mov	#RAM_Mars_Background,r1		; Make visible background
		mov	#0,r2				; section on screen
		mov	#224,r3
		bsr	MarsVideo_MakeTbl
		nop
		bsr	MarsVideo_FixTblShift		; Fix those Xshift lines
		nop
; .wait_pz:	mov.w	@(marsGbl_PlgnCntr,gbr),r0	; Active polygon pieces?
; 		cmp/pl	r0
; 		bt	.wait_pz
		bra	mstr_nextframe
		nop
		align 4
		ltorg

; ---------------------------------------
; Mode 2: 3D MODE Polygons-only
; ---------------------------------------

mstr_gfx_2:
		tst	r2,r2
		bt	.lel
		mov.b	@r1,r0
		and	#%11011111,r0
		mov.b	r0,@r1
		mov	#Cach_Drw_All,r1		; DrawAll request (2 times)
		mov	#2,r0
		mov	r0,@r1
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
.lel:
		mov	#Cach_Drw_All,r13		; DrawAll != 0?
		mov	@r13,r0
		cmp/eq	#0,r0
		bt	.no_redraw
		dt	r0
		mov	r0,@r13
		mov	#_framebuffer,r3
		mov	#$200/2,r0
		mov	r0,r1
		mov	#240,r4
.nxt_lne:
		mov.w	r0,@r3
		add	r1,r0
		dt	r4
		bf/s	.nxt_lne
		add	#2,r3
.no_redraw:

		mov	#_sysreg+comm14,r1
.wait_1:	mov.b	@r1,r0
		and	#%00010000,r0
		tst	r0,r0
		bt	.wait_1

	; ---------------------------------------
	; Prepare WATCHDOG interrupt
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bf	.page_2
		mov	#RAM_Mars_PlgnList_0,r0
		mov	#RAM_Mars_PlgnNum_0,r1
		bra	.cont_plgn
		nop
.page_2:
		mov	#RAM_Mars_PlgnList_1,r0
		mov	#RAM_Mars_PlgnNum_1,r1
		nop
.cont_plgn:
		mov	r0,@(marsGbl_IndxPlgn,gbr)
		mov	@r1,r0
		mov.w	r0,@(marsGbl_PlgnCntr,gbr)
		mov	#RAM_Mars_VdpDrwList,r0		; Reset DDA pieces Read/Write points
		mov	r0,@(marsGbl_PlyPzList_R,gbr)	; And counter
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
		mov	#0,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
		mov.w	r0,@(marsGbl_WdgMode,gbr)

		mov	#_CCR,r1			; <-- Required for Watchdog
		mov	#%00001000,r0			; Two-way mode
		mov.w	r0,@r1
		mov	#%00011001,r0			; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r1
		mov	#$FFFFFE80,r1
		mov.w	#$5A20,r0			; Watchdog pre-timer
		mov.w	r0,@r1
		mov.w	#$A538,r0			; Enable Watchdog
		mov.w	r0,@r1

	; ---------------------------------------
	; Clear screen
	; ---------------------------------------

		mov	#_vdpreg,r1
		mov	#$100,r2
		mov	r2,r3
		mov	#240,r4
		mov	#320/2,r5
		mov	#0,r6
.fb_loop:
		mov	r5,r0
		mov.w	r0,@(filllength,r1)
		mov	r2,r0
		mov.w	r0,@(fillstart,r1)
		mov	r6,r0
		mov.w	r0,@(filldata,r1)
.wait_fb2:	mov.w	@(vdpsts,r1),r0
		and	#%10,r0
		tst	r0,r0
		bf	.wait_fb2
		dt	r4
		bf/s	.fb_loop
		add	r3,r2

	; ---------------------------------------

		mov.w	@(marsGbl_PlyPzCntr,gbr),r0
		tst	r0,r0
		bt	.no_swap
.wait_wd:	mov.w	@(marsGbl_WdgMode,gbr),r0
		tst	r0,r0
		bt	.wait_wd
		mov	#VideoMars_DrwPlgnPz,r0
		jsr	@r0
		nop
		mov	#_sysreg+comm14,r1
		mov.b	@r1,r0
		and	#%11101111,r0
		mov.b	r0,@r1
.no_swap:


; ---------------------------------------
; *** Frameswap exit, JUMP only
; ---------------------------------------

mstr_nextframe:
		mov	#_vdpreg,r1
.wait_fb:	mov.w	@(vdpsts,r1),r0			; SVDP FILL active?
		and	#2,r0
		tst	r0,r0
		bf	.wait_fb
		mov.b	@(framectl,r1),r0		; Framebuffer swap REQUEST
		xor	#1,r0
		mov.b	r0,@(framectl,r1)
		mov.b	r0,@(marsGbl_CurrFb,gbr)	; copy new bit for checking
		bra	master_loop
		nop

; 	; ---------------------------------------
; 	; Interact with background
; 	; ---------------------------------------
;
; 		mov	#_sysreg+comm14,r2	; bit 5: RedrawALL request
; 		mov.b	@r2,r0
; 		and	#%00100000,r0
; 		tst	r0,r0
; 		bt	.no_rdrw
; 		mov.b	@r2,r0
; 		and	#%11011111,r0
; 		mov.b	r0,@r2
; 		mov	#Cach_Drw_All,r1
; 		mov	#2,r0
; 		mov	r0,@r1
; .no_rdrw:
;
; 	; ---------------------------------------
; 	; Framebuffer redraw section
; 	; ---------------------------------------
;
; 		mov	#Cach_Drw_All,r13		; DrawAll != 0?
; 		mov	@r13,r0
; 		cmp/eq	#0,r0
; 		bt	.no_redraw
; 		dt	r0
; 		mov	r0,@r13
; 		bsr	MarsVideo_DrawAllBg
; 		nop
; .no_redraw:
; 		mov	#MarsVideo_BgDrawLR,r0		; Process U/D/L/R draw
; 		jsr	@r0
; 		nop
; 		mov	#MarsVideo_BgDrawUD,r0
; 		jsr	@r0
; 		nop
; 		mov	#RAM_Mars_Background,r1		; Make visible section on screen
; 		mov	#0,r2
; 		mov	#240,r3
; 		bsr	MarsVideo_MakeTbl
; 		nop
;
; 	; ---------------------------------------
; 	; Draw sprites and polygons now.
; 	; ---------------------------------------
; 		mov	#0,r0
; 		mov.w	r0,@(marsGbl_ModelsReady,gbr)
; 		bsr	MarsVideo_FixTblShift		; Call this AFTER all linetables are set
; 		nop
; 		mov	#_vdpreg,r1
; 		mov.b	@(framectl,r1),r0		; Framebuffer swap REQUEST
; 		xor	#1,r0
; 		mov.b	r0,@(framectl,r1)
; 		mov.b	r0,@(marsGbl_CurrFb,gbr)	; copy bit for checking
; 		bra	master_loop
; 		nop
; 		align 4
; 		ltorg

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

		mov	#RAM_Mars_Objects,r1
		mov	#MarsObj_test,r0
		mov	r0,@(mdl_data,r1)
		mov	#-$80000,r0
		mov	r0,@(mdl_z_pos,r1)

		bra	slave_loop
		nop
		ltorg
		align 4

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

slave_loop:

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
		mov	#_sysreg+comm14,r1
		mov.b	@r1,r0
		and	#%11,r0
		cmp/eq	#2,r0
		bf	slave_loop

; ---------------------------------------
; ***READ MODELS HERE AND UPDATE POLYGONS
; ---------------------------------------

		mov	#RAM_Mars_Objects,r2	; temporal rotation
		mov	#$10000,r1
		mov	@(mdl_x_rot,r2),r0
		add	r1,r0
		mov	r0,@(mdl_x_rot,r2)
; 		mov	#$1000,r1
; 		mov	@(mdl_z_pos,r2),r0
; 		sub	r1,r0
; 		mov	r0,@(mdl_z_pos,r2)

		mov	#_sysreg+comm12+1,r1
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1

		mov	#0,r0
		mov.w	r0,@(marsGbl_CurrNumFaces,gbr)
		mov 	#RAM_Mars_Polygons_0,r1
		mov	#RAM_Mars_PlgnList_0,r2
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bf	.go_mdl
		mov 	#RAM_Mars_Polygons_1,r1
		mov	#RAM_Mars_PlgnList_1,r2
.go_mdl:
		mov	r1,r0
		mov	r0,@(marsGbl_CurrFacePos,gbr)
		mov	r2,r0
		mov	r0,@(marsGbl_CurrZList,gbr)
		mov	#RAM_Mars_Objects,r14
		mov	#MAX_MODELS,r13
.loop:
		mov	@(mdl_data,r14),r0		; Object model data == 0 or -1?
		cmp/pl	r0
		bf	.invlid
		mov	#MarsMdl_ReadModel,r0
		jsr	@r0
		mov	r13,@-r15
		mov	@r15+,r13
		mov.w	@(marsGbl_CurrNumFaces,gbr),r0	; Ran out of space to store faces?
		mov	#MAX_FACES,r1
		cmp/ge	r1,r0
		bt	.skip
.invlid:
		dt	r13
		bf/s	.loop
		add	#sizeof_mdlobj,r14
.skip:
		mov 	#RAM_Mars_PlgnNum_0,r1
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bf	.page_2
		mov 	#RAM_Mars_PlgnNum_1,r1
.page_2:
		mov.w	@(marsGbl_CurrNumFaces,gbr),r0
		mov	r0,@r1
		mov	#_sysreg+comm14,r1
.wait_in:
		mov.b	@r1,r0
		and	#%00010000,r0
		tst	r0,r0
		bf	.wait_in
		mov.w	@(marsGbl_PolyBuffNum,gbr),r0
		xor	#1,r0
		mov.w	r0,@(marsGbl_PolyBuffNum,gbr)
		mov.b	@r1,r0
		or	#%00010000,r0
		mov.b	r0,@r1
		bra	slave_loop
		nop
		align 4
		ltorg

; =================================================================
; ------------------------------------------------
; Slave | Watchdog interrupt
; ------------------------------------------------

s_irq_custom:
		mov	#$F0,r0
		ldc	r0,sr
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
MarsRam_Dreq0	ds.l 0
MarsRam_System	ds.l 0
MarsRam_Video	ds.l 0
sizeof_marsram	ds.l 0
	else
MarsRam_Dreq0	ds.b MAX_MDDREQ				; Shared with Genesis side
MarsRam_System	ds.b (sizeof_marssys-MarsRam_System)
MarsRam_Video	ds.b (sizeof_marsvid-MarsRam_Video)
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
RAM_Mars_Polygons_0	ds.b sizeof_polygn*MAX_FACES
RAM_Mars_Polygons_1	ds.b sizeof_polygn*MAX_FACES
RAM_Mars_Objects	ds.b sizeof_mdlobj*MAX_MODELS
RAM_Mars_ObjCamera	ds.b sizeof_camera		; 3D Camera buffer
RAM_Mars_VdpDrwList	ds.b sizeof_plypz*MAX_SVDP_PZ	; Sprites / Polygon pieces
RAM_Mars_VdpDrwList_e	ds.l 0				; (END point label)
RAM_Mars_PlgnList_0	ds.l 2*MAX_FACES		; polygondata, Zpos
RAM_Mars_PlgnList_1	ds.l 2*MAX_FACES
RAM_Mars_PlgnNum_0	ds.l 1				; Number of polygons to process
RAM_Mars_PlgnNum_1	ds.l 1
RAM_Mars_Background	ds.w sizeof_marsbg
; RAM_Mars_BgData		ds.b (320+16)*(224+16)
RAM_Mars_Palette	ds.w 256
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
