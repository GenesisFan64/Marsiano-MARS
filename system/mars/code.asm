; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 Section
;
; CODE for both CPUs
; RAM and some DATA go here
; ----------------------------------------------------------------

; *************************************************
; communication setup will be like this:
;
; comm0-comm7  - ** FREE to use ***
; comm8-comm11 - Used to transfer data manually
;                from Z80 to SH2 side, 68K
;                uses DREQ.
; comm12       - Master CPU control
; comm14       - Slave CPU control
;
; CPU control bits:
;
; %BsssCCCC Immmmmmm
;
; B - BUSY bit, Manually set by 68K or Z80
;     and cleared here on finish.
; s - STATUS bits for the CMD interrupt
; C - CMD Interrupt task mode
;
; I - Initialitation bit
; m - Current mode for main loop, depending of
;     the CPU
; *************************************************

		phase CS3	; Now we are at SDRAM
		cpu SH7600	; Should be SH7095 but this CPU mode works.

; ====================================================================
; ----------------------------------------------------------------
; MARS GLOBAL gbr variables for both SH2
; ----------------------------------------------------------------

			struct 0
marsGbl_PlyPzList_R	ds.l 1	; Current graphic piece to draw
marsGbl_PlyPzList_W	ds.l 1	; Current graphic piece to write
marsGbl_IndxPlgn	ds.l 1	; Current polygon to slice
marsGbl_CurrZList	ds.l 1	; Current Zsort entry
marsGbl_CurrZTop	ds.l 1	; Current Zsort list
marsGbl_CurrFacePos	ds.l 1	; Current top face of the list while reading model data
marsGbl_CurrNumFaces	ds.w 1	; and the number of faces stored on that list
marsGbl_UpdModels	ds.w 1	; Flag to update models
marsGbl_WdgMode		ds.w 1	; Current Watchdog task
marsGbl_PolyBuffNum	ds.w 1	; Polygon-list swap number
marsGbl_PlyPzCntr	ds.w 1	; Number of graphic pieces to draw
marsGbl_PlgnCntr	ds.w 1	; Number of polygons to slice
marsGbl_XShift		ds.w 1	; Xshift bit at the start of master_loop (TODO: maybe a HBlank list?)
marsGbl_CurrFb		ds.w 1
marsGbl_RomBlkM		ds.w 1	; Flag to report that MASTER is reading from ROM area
marsGbl_RomBlkS		ds.w 1	; Flag to report that SLAVE is reading from ROM area
marsGbl_BgDrwAll	ds.w 1	; Write 2 to request FULL redraw
marsGbl_BgDrwR		ds.w 1	; Write 2 to only redraw offscreen section(s)
marsGbl_BgDrwL		ds.w 1	;
marsGbl_BgDrwU		ds.w 1	;
marsGbl_BgDrwD		ds.w 1	;
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
		dc.l m_irq_custom,m_irq_custom
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

SH2_M_Error:
		nop
		bra	SH2_M_Error
		nop
		align 4
SH2_S_Error:
		nop
		bra	SH2_S_Error
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
		mov	#_sysreg+comm12,r2	; LSB only
		mov	#_sysreg+dreqfifo,r1
		mov	@($C,r3),r0		; Check if last DMA is active
		and	#%01,r0
		tst	r0,r0
		bt	.not_yet
		mov	#0,r0			; Force DMA off
		mov	r0,@($30,r3)
		mov	r0,@($C,r3)
.not_yet:
		mov	r0,@($C,r3)
		mov	#RAM_Mars_DreqDma,r0
		mov	r1,@r3			; Source
		mov	r0,@(4,r3)		; Destination
		mov.w	@(dreqlen,r4),r0	; TODO: a check if this gets Zero'd
		exts.w	r0,r0
		mov	r0,@(8,r3)		; Length (set by 68k)
		mov	#%0100010011100001,r0	; Transfer mode + DMA enable bit
		mov	r0,@($C,r3)		; Dest:Incr(01) Src:Keep(00) Size:Word(01)
		mov	#1,r0			; _DMAOPERATION = 1
		mov	r0,@($30,r3)

	; *** HARDWARE NOTE ***
	; DMA takes a little to properly start:
	; Put 5 instructions (or 5 nops) after
	; writing _DMAOPERATION = 1
	;
	; On 32X Emulators it starts right away.
		mov.b	@r2,r0			; Tell Genesis we are ready to
		or	#%01000000,r0		; recieve the data from DREQ
		mov.b	r0,@r2
		nop
		nop
.wait_dma:
		mov	@($C,r3),r0	; Read DMA's mode for the active/enabled bits
; 		tst	#%01,r0		; DMA is enabled first? (fail-safe)
; 		bt	.time_out	; TODO: ver si todavia necesito esto
		tst	#%10,r0		; Active?
		bt	.wait_dma
.time_out:
		mov	#0,r0		; _DMAOPERATION = 0
		mov	r0,@($30,r3)

	; *** HARDWARE NOTE ***
	; If the CPU reads or writes to the DESTINATION data
	; as we just recieved at any location: The DMA
	; will finish early when it reaches the location
	; that got modified.
	;
	; The only workaround is to copy-paste the data
	; we just received into another buffer for reading
	; it safetly.
	;
	; 32X Emulators doesn't recreate this limitation.
		mov	#RAM_Mars_DreqDma,r1
		mov	#RAM_Mars_DreqRead,r2
		mov	#sizeof_dreq/4,r3	; NOTE: copying as 4bytes
.copy_safe:
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.copy_safe
		add	#4,r2
.bad_size:

		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		rts
		nop
		align 4

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

; =================================================================
; ------------------------------------------------
; Master | VRES Interrupt (RESET button on Genesis)
; ------------------------------------------------

m_irq_vres:
		mov.l	#$F0,r0				; Interrupts OFF
		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov.l	#_sysreg,r1
		mov.w	r0,@(vresintclr,r1)
		mov	#_DMASOURCE0,r2
		mov	@($C,r2),r0
		and	#%01,r0
		tst	r0,r0
		bt	.not_yet
		mov	#0,r0		; Force DMA off
		mov	r0,@($30,r2)
		nop
		nop
		nop
		mov	r0,@($C,r2)
.not_yet:
; 		mov.b   @(7,r1),r0
; 		tst     #%001,r0
; .rv_stuck:
; 		bf	.rv_stuck
; 		mov	#"68UP",r2
; .wait_md:	mov	@(comm12,r1),r0
; 		cmp/eq	r2,r0
; 		bf	.wait_md
		mov	#"M_OK",r0
		mov	r0,@(comm0,r1)
		mov	#SH2_M_HotStart,r0
		jmp	@r0
		nop
		align 4
		ltorg		; Save MASTER IRQ literals here

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

; check cache.asm
; s_irq_pwm:

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

	; ---------------------------------
	; *** GEMA PWM DRIVER ***
	; ---------------------------------

		mov	#_sysreg+comm14,r1	; LSB only
		mov.b	@r1,r0
		and	#%00001111,r0
		cmp/eq	#0,r0
		bt	.get_out
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
		cmp/eq	#1,r0
		bt	.mode_1
		cmp/eq	#2,r0
		bt	.mode_2
		cmp/eq	#3,r0
		bt	.mode_3
		bra	.no_trnsfrex
		nop
.get_out:
		bra	.no_ztrnsfr
		nop

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

; ---------------------------------
; CMD Mode 1: Z80 transfer
; ---------------------------------

.mode_1:
	; First we recieve changes from Z80
	; using comm8  for data
	;  and  comm14 for busy/clock bits (bits 7,6)
		mov	#_sysreg+comm8,r1
		mov	#MarsSnd_PwmControl,r2
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
	; TODO: clearly rushed... but it works.
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

.no_ztrnsfr:

; 		nop
; 		nop
; 		nop
; 		nop
; 		nop
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
; Slave | VRES Interrupt (RESET button on Genesis)
; ------------------------------------------------

s_irq_vres:
		mov.l	#$F0,r0				; Interrupts OFF
		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov.l	#_sysreg,r1
		mov.w	r0,@(vresintclr,r1)
		mov	#_DMASOURCE0,r2
		mov	@($C,r2),r0
		and	#%01,r0
		tst	r0,r0
		bt	.not_yet
		mov	#0,r0		; Force DMA off
		mov	r0,@($30,r2)
		nop
		nop
		nop
		mov	r0,@($C,r2)
.not_yet:
; 		mov	#$FFFFFE80,r1
; 		mov.w	#$A518,r0	; Disable Watchdog
; 		mov.w	r0,@r1

; 		mov.b   @(7,r1),r0
; 		tst     #%001,r0
; .rv_stuck:
; 		bf	.rv_stuck
; 		mov	#"68UP",r2
; .wait_md:	mov	@(comm12,r1),r0
; 		cmp/eq	r2,r0
; 		bf	.wait_md
		mov	#"S_OK",r0
		mov	r0,@(comm4,r1)
		mov	#SH2_S_HotStart,r0
		jmp	@r0
		nop
		align 4
		ltorg			; Save SLAVE IRQ literals here

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
		mov.l	#$FFFFFE10,r14
		mov	#0,r0
		mov.b	r0,@(0,r14)
		mov	#$FFFFFFE2,r0
		mov.b	r0,@(7,r14)
		mov	#0,r0
		mov.b	r0,@(4,r14)
		mov	#1,r0
		mov.b	r0,@(5,r14)
		mov	#0,r0
		mov.b	r0,@(6,r14)
		mov	#1,r0
		mov.b	r0,@(1,r14)
		mov	#0,r0
		mov.b	r0,@(3,r14)
		mov.b	r0,@(2,r14)
		mov	#$FFFFFFF2,r0
		mov.b	r0,@(7,r14)
		mov	#0,r0
		mov.b	r0,@(4,r14)
		mov	#1,r0
		mov.b	r0,@(5,r14)
		mov	#$FFFFFFE2,r0
		mov.b	r0,@(7,r14)
		mov.l   #$FFFFFEE2,r0			; Watchdog: Set interrupt priority bits (IPRA)
		mov     #%0101<<4,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1			; Watchdog: Set jump pointer: VBR + (this/4) (WITV)
		shll8   r1
		mov.w   r1,@r0
		mov.l	#_CCR,r1
		mov	#$10,r0
		mov.w	r0,@r1
		mov	#$09,r0
		mov.w	r0,@r1
		mov 	#CACHE_MASTER,r1		; Transfer Master's "fast code" to CACHE
		mov 	#$C0000000,r2
		mov 	#(CACHE_MASTER_E-CACHE_MASTER)/4,r3
.copy:
		mov 	@r1+,r0
		mov 	r0,@r2
		dt	r3
		bf/s	.copy
		add 	#4,r2
		mov	#MarsVideo_Init,r0		; Init Video
		jsr	@r0
		nop
		mov	#_sysreg,r1
		mov	#CMDIRQ_ON,r0			; Enable usage of these interrupts
    		mov.b	r0,@(intmask,r1)
.wait_md:
; 		mov 	#_sysreg+comm12,r2
; 		mov.w	@r2,r0
; 		cmp/eq	#0,r0
; 		bf	.wait_md

; ====================================================================
; ----------------------------------------------------------------
; Master main code
;
; This CPU is exclusively used for Visual tasks:
; Background, Sprites and Polygons.
; ----------------------------------------------------------------

SH2_M_HotStart:
		mov	#$F0,r0				; Interrupts OFF
		ldc	r0,sr
		mov	#$FFFFFE80,r1
		mov.w	#$A518,r0			; Disable Watchdog
		mov.w	r0,@r1
		mov	#CS3|$40000,r15			; Set default Stack for Master
		mov	#RAM_Mars_Global,r14		; GBR - Global values/variables go here.
		ldc	r14,gbr
		mov	#$20004000,r14
		mov	#0,r0
		mov.w	r0,@($14,r14)
		mov.w	r0,@($16,r14)
		mov.w	r0,@($18,r14)
		mov.w	r0,@($1A,r14)
		mov	#RAM_Mars_DreqRead,r1		; Clear DREQ output
		mov	#sizeof_dreq/4,r2		; NOTE: copying as 4bytes
		mov	#0,r0
.clrram:
		mov	r0,@r1
		dt	r2
		bf/s	.clrram
		add	#4,r1
		mov	#$20,r0				; Interrupts ON
		ldc	r0,sr
		bra	master_loop
		nop
		align 4
		ltorg

; ----------------------------------------------------------------
; MASTER Loop
; ----------------------------------------------------------------

master_loop:
		mov	#_sysreg+comm0,r1
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1

	; ---------------------------------------
	; Wait frameswap
		mov	#_vdpreg,r1			; r1 - SVDP area
.wait_fb:	mov.w	@(vdpsts,r1),r0			; SVDP FILL active?
		tst	#%10,r0
		bf	.wait_fb
		mov.b	@(framectl,r1),r0		; Framebuffer swap REQUEST.
		xor	#1,r0				; manually Wait for VBlank after this
		mov.b	r0,@(framectl,r1)
; 		mov.b	r0,@(marsGbl_CurrFb,gbr)
; 		mov.b	@(marsGbl_CurrFb,gbr),r0	; r2 - NEW Framebuffer number
		mov	r0,r2
.wait_frmswp:	mov.b	@(framectl,r1),r0		; Framebuffer ready?
		cmp/eq	r0,r2
		bf	.wait_frmswp
		stc	sr,@-r15			; Interrupts OFF
		mov	#$F0,r0
		ldc	r0,sr

	; ---------------------------------------
	; New frame is now shown on screen but
	; we are still on VBlank
	; ---------------------------------------

 		mov.w	@(marsGbl_XShift,gbr),r0	; Set SHIFT bit first
		mov	#_vdpreg+shift,r1		; For the indexed-scrolling
		and	#1,r0
		mov.w	r0,@r1
		mov	#_vdpreg,r1
.wait:		mov.b	@(vdpsts,r1),r0
		and	#$20,r0
		tst	r0,r0				; Palette unlocked?
		bt	.wait
		mov	#RAM_Mars_DreqRead+Dreq_Palette,r1
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
	; Mode-specific VBlank changes

		mov	#.list+8,r1		; Point to VBLANK jumps
		mov	#_sysreg+comm12,r2
		mov.w	@r2,r0			; r0 - INIT bit
		and	#%111,r0
		shll2	r0
		shll2	r0
		mov	@(r1,r0),r1
		jsr	@r1
		nop

	; ---------------------------------------

		ldc	@r15+,sr		; Interrupts ON

; ---------------------------------------
; Pick graphics mode on comm12
; ---------------------------------------

		mov	#.list,r3		; Default LOOP points
		mov	#_sysreg+comm12,r2
		mov.w	@r2,r0			; r0 - INIT bit
		mov	r0,r1			; r1 - mode
		tst	#$80,r0			; First time/Full redraw?
		bt	.no_init
		and	#$7F,r0			; Reset bit after this.
		mov.w	r0,@r2
		add	#4,r3			; Grab the INIT jumps
.no_init:
		mov	r1,r0
		and	#%111,r0
		shll2	r0
		shll2	r0
		mov	@(r3,r0),r3
		jmp	@r3
		nop
		align 4

.list:
	dc.l mstr_gfx0,mstr_gfx0_init,mstr_gfx0_vblk,mstr_gfx0_hblk
	dc.l mstr_gfx1,mstr_gfx1_init,mstr_gfx1_vblk,mstr_gfx1_hblk
	dc.l mstr_gfx2,mstr_gfx2_init,mstr_gfx2_vblk,mstr_gfx2_hblk
	dc.l mstr_gfx3,mstr_gfx3_init,mstr_gfx3_vblk,mstr_gfx3_hblk

	dc.l mstr_gfx4,mstr_gfx4_init,mstr_gfx4_vblk,mstr_gfx4_hblk
	dc.l mstr_gfx0,mstr_gfx0_init,mstr_gfx0_vblk,mstr_gfx0_hblk
	dc.l mstr_gfx0,mstr_gfx0_init,mstr_gfx0_vblk,mstr_gfx0_hblk
	dc.l mstr_gfx0,mstr_gfx0_init,mstr_gfx0_vblk,mstr_gfx0_hblk

	ltorg

; ============================================================
; ---------------------------------------
; Mode 0: BLANK, nothing.
; ---------------------------------------

mstr_gfx0_hblk:
		rts
		nop
mstr_gfx0_vblk:
		rts
		nop
mstr_gfx0_init:
		mov 	#_vdpreg,r1
		mov	#0,r0
		mov.b	r0,@(bitmapmd,r1)
mstr_gfx0:
		bra	master_loop
		nop

; ============================================================
; ---------------------------------------
; Mode 1:
; Generic static screen in any
; bitmap mode: Indexed, Direct or RLE
;
; Direct's HEIGHT will be limited
; to 200 lines.
; ---------------------------------------

mstr_gfx1_hblk:
		rts
		nop
mstr_gfx1_vblk:
		rts
		nop
mstr_gfx1_init:
		mov 	#_vdpreg,r1
		mov	#0,r0
		mov.b	r0,@(bitmapmd,r1)
mstr_gfx1:
		bra	master_loop
		nop

; ============================================================
; ---------------------------------------
; Mode 2: 256-color scrolling image
;
; *** WAIT 2 FRAMES TO PROPERLY START
; THIS MODE WHEN SWITCHING ***
; ---------------------------------------

mstr_gfx2_hblk:
		rts
		nop
mstr_gfx2_vblk:
		sts	pr,@-r15
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	#RAM_Mars_DreqRead+Dreq_BgXpos,r13
		mov	@r13+,r1
		mov	@r13+,r2
		mov	r1,@(mbg_xpos,r14)
		mov	r2,@(mbg_ypos,r14)
		mov	r1,r0
		shlr16	r0
		mov.w	r0,@(marsGbl_XShift,gbr)
		bsr	MarsVideo_MoveBg
		nop
		lds	@r15+,pr
		rts
		nop
mstr_gfx2_init:
		mov	#2,r0
		mov.w	r0,@(marsGbl_BgDrwAll,gbr)
		mov	#RAM_Mars_BgBuffScrl,r1
		mov	#$200,r2
		mov	#16,r3
		mov	#320,r4
		mov	#256,r5
		bsr	MarsVideo_MkScrlField
		mov	#0,r6
		mov	#RAM_Mars_BgBuffScrl,r1
		mov	#TESTMARS_BG,r2			; Image / RAM section
		mov	#320,r3
		mov	#224,r4
		bsr	MarsVideo_SetBg
		nop
mstr_gfx2:
		mov.w	@(marsGbl_BgDrwAll,gbr),r0
		cmp/eq	#0,r0
		bt	.no_redraw
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwAll,gbr)
		cmp/pl	r0
		bf	.no_btmp
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
.no_btmp:
		bsr	MarsVideo_DrawAllBg		; Process FULL image (only two times)
		nop
		xor	r0,r0
		mov.w	r0,@(marsGbl_BgDrwR,gbr)	; Cancel
		mov.w	r0,@(marsGbl_BgDrwL,gbr)	; all
		mov.w	r0,@(marsGbl_BgDrwU,gbr)	; these
		mov.w	r0,@(marsGbl_BgDrwD,gbr)	; draw requests
		bra	.from_drwall
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
		mov	#RAM_Mars_BgBuffScrl,r1		; Make visible background
		mov	#0,r2				; section on screen
		mov	#224,r3
		bsr	MarsVideo_MakeTbl
		nop
		bsr	MarsVideo_FixTblShift		; Fix those broken lines that
		nop					; the Xshift register can't move
		bra	master_loop
		nop
		align 4
		ltorg

; ============================================================
; ---------------------------------------
; Mode 3:
; Scalable 256-color screen, low FPS
; ---------------------------------------

mstr_gfx3_hblk:
		rts
		nop
mstr_gfx3_vblk:
		rts
		nop
mstr_gfx3_init:
		mov	#2,r0
		mov.w	r0,@(marsGbl_BgDrwAll,gbr)
		mov	#0,r0
		mov.w	r0,@(marsGbl_XShift,gbr)
mstr_gfx3:
		mov.w	@(marsGbl_BgDrwAll,gbr),r0
		cmp/eq	#0,r0
		bt	.no_redraw
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwAll,gbr)
		cmp/pl	r0
		bf	.no_btmp
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
.no_btmp:
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

	; MAIN scaler
	; r1 - X pos xxxx.0000
	; r2 - Y pos yyyy.0000
	; r3 - X dx  xxxx.0000
	; r4 - Y dx  yyyy.0000
	; r5 - Source WIDTH
	; r6 - Source HEIGHT
	; r7 - Source DATA
	; r8 - Output
	; r9 - line size / 2
	; r10 - Number of lines
		mov	#$F0,r0				; Interrupts OFF
		ldc	r0,sr
		mov	#RAM_Mars_DreqRead+Dreq_SclX,r14
		mov	@r14+,r1			; r1 - X pos (4 pixels wide)
		mov	@r14+,r2			; r2 - Y pos
		mov	@r14+,r3			; r3 - DX
		mov	@r14+,r4			; r4 - DY
		mov	#$FFFF,r7
		mov	@r14+,r5			; r5 - X width
		mov	r5,r6				; r6 - Y height
		shlr16	r5
		and	r7,r6
		mov	@r14+,r7			; r7 - Input
		mov	#$20,r0				; Interrupts ON
		ldc	r0,sr
		mov	#_framebuffer+$200,r8		; r8 - Output
		mov	#320/2,r9			; r9  - X loop
		mov	#224,r10			; r10 - Y loop
.y_loop:
		mov	r6,r0
		shll16	r0
.y_loop2:	cmp/gt	r0,r2
		bf	.y_high
		bra	.y_loop2
		sub	r0,r2
.y_high:
		mov	r1,r11
		shlr	r11
		mov	r7,r12
		mov	r8,r13
		mov	r9,r14
		mov	r2,r0
		shlr16	r0
		muls	r5,r0
		sts	macl,r0
		add	r0,r12
.x_loop:
		mov	r11,r0
		shlr16	r0
		exts	r0,r0
		shll	r0
		mov.w	@(r12,r0),r0
		add	r3,r11
		lds	r0,macl
		mov	r5,r0
		shll16	r0
		shlr	r0
.x_loop2:
		cmp/gt	r0,r11
		bf	.x_high
		bra	.x_loop2
		sub	r0,r11
.x_high:
		sts	macl,r0
		mov.w	r0,@r13
		dt	r14
		bf/s	.x_loop
		add	#2,r13
		add	r4,r2
		mov	#$200,r0
		dt	r10
		bf/s	.y_loop
		add	r0,r8

		bra	master_loop
		nop

; ============================================================
; ---------------------------------------
; Mode 4: 3D MODE Polygons-only
; ---------------------------------------

mstr_gfx4_hblk:
		rts
		nop

mstr_gfx4_vblk:
		mov	#_sysreg+comm14,r4
		mov.w	@r4,r0
		and	#%01111111,r0
		tst	r0,r0
		bf	.wait_slv
		mov	#RAM_Mars_DreqRead+Dreq_Objects,r1	; Copy Dreq models from here.
		mov	#RAM_Mars_Objects,r2
		mov	#(sizeof_mdlobj*MAX_MODELS)/4,r3
.copy_safe:
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.copy_safe
		add	#4,r2
		mov.w	@(marsGbl_PolyBuffNum,gbr),r0
		xor	#1,r0
		mov.w	r0,@(marsGbl_PolyBuffNum,gbr)
		mov.w	@r4,r0
		or	#%00000001,r0
		mov.w	r0,@r4
.wait_slv:
		rts
		nop

mstr_gfx4_init:
		mov	#2,r0
		mov.w	r0,@(marsGbl_BgDrwAll,gbr)
		mov	#0,r0
		mov.w	r0,@(marsGbl_XShift,gbr)
mstr_gfx4:
		mov.w	@(marsGbl_BgDrwAll,gbr),r0
		cmp/eq	#0,r0
		bt	.no_redraw
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwAll,gbr)
		cmp/pl	r0
		bf	.no_btmp
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
.no_btmp:
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
; 		mov	#_CCR,r1			; <-- Required for Watchdog
; 		mov	#%00001000,r0			; Two-way mode
; 		mov.w	r0,@r1
; 		mov	#%00011001,r0			; Cache purge / Two-way mode / Cache ON
; 		mov.w	r0,@r1
		mov	#$FFFFFE80,r1
		mov.w	#$5A10,r0			; Watchdog pre-timer
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
		tst	#%10,r0
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
.no_swap:
		bra	master_loop
		nop
		align 4
		ltorg

; ============================================================
;
; mstr_waitdma:
; 		mov	#_DMACHANNEL0,r1
; 		mov	@r1,r0
; 		and	#%01,r0
; 		tst	r0,r0
; 		bt	.not_yet
; .wait_dma:	mov	@r1,r0
; 		tst	#%10,r0
; 		bt	.wait_dma
; .not_yet:
; 		rts
; 		nop
; 		align 4

; ====================================================================
; ----------------------------------------------------------------
; Slave entry
; ----------------------------------------------------------------

		align 4
SH2_S_Entry:
		mov.l	#$FFFFFE10,r14
		mov	#0,r0
		mov.b	r0,@(0,r14)
		mov	#$FFFFFFE2, r0
		mov.b	r0,@(7,r14)
		mov	#0,r0
		mov.b	r0,@(4,r14)
		mov	#1,r0
		mov.b	r0,@(5,r14)
		mov	#0,r0
		mov.b	r0,@(6,r14)
		mov	#1,r0
		mov.b	r0,@(1,r14)
		mov	#0,r0
		mov.b	r0,@(3,r14)
		mov.b	r0,@(2,r14)
		mov.l   #$FFFFFEE2,r0			; Watchdog: Set interrupt priority bits (IPRA)
		mov     #%0101<<4,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1			; Watchdog: Set jump pointer (VBR + this/4) (WITV)
		shll8   r1
		mov.w   r1,@r0
		mov.l	#_CCR,r1
		mov	#$10,r0
		mov.w	r0,@r1
		mov	#$09,r0
		mov.w	r0,@r1
		mov 	#CACHE_SLAVE,r1			; Transfer Slave's fast-code to CACHE
		mov 	#$C0000000,r2
		mov 	#(CACHE_SLAVE_E-CACHE_SLAVE)/4,r3
.copy:
		mov 	@r1+,r0
		mov 	r0,@r2
		dt	r3
		bf/s	.copy
		add 	#4,r2
		mov	#_sysreg,r1
		mov	#CMDIRQ_ON|PWMIRQ_ON,r0			; Enable these interrupts
    		mov.b	r0,@(intmask,r1)		; (Watchdog is external)
		bsr	MarsSound_Init			; Init PWM
		nop
.wait_md:
; 		mov 	#_sysreg+comm12,r2
; 		mov.w	@r2,r0
; 		cmp/eq	#0,r0
; 		bf	.wait_md

; ====================================================================
; ----------------------------------------------------------------
; Slave main code
; ----------------------------------------------------------------

SH2_S_HotStart:
		mov	#$F0,r0				; Interrupts OFF
		ldc	r0,sr
		mov	#$FFFFFE80,r1
		mov.w	#$A518,r0			; Disable Watchdog
		mov.w	r0,@r1
		mov	#CS3|$3F000,r15			; Reset stack
		mov	#RAM_Mars_Global,r14		; Reset gbr
		ldc	r14,gbr
		mov	#$20004000, r14
		mov	#0,r0
		mov.w	r0,@($14,r14)
		mov.w	r0,@($16,r14)
		mov.w	r0,@($18,r14)
		mov.w	r0,@($1A,r14)
		mov	#0,r0				; Stop ALL active PWM channels
		mov	#MarsSnd_PwmChnls,r1
		mov	#MAX_PWMCHNL,r2
		mov	#sizeof_sndchn,r3
.clr_enbl:
		mov	r0,@(mchnsnd_enbl,r1)
		dt	r2
		bf/s	.clr_enbl
		add	r3,r1
		mov	#$20,r0				; Interrupts ON
		ldc	r0,sr
		bra	slave_loop
		nop
		align 4

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

slave_loop:
		mov	#_sysreg+comm1,r1
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1

; ---------------------------------------
; ***READ MODELS HERE AND UPDATE POLYGONS
; ---------------------------------------

		mov	#_sysreg+comm14,r4
		mov.w	@r4,r0
		and	#%01111111,r0
		cmp/eq	#1,r0
		bf	slave_loop
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
		mov	r0,@(marsGbl_CurrZTop,gbr)
		mov	#MarsMdl_MdlLoop,r0
		jsr	@r0
		nop
		mov	#_sysreg+comm14,r4
		mov	#$FF00,r1
		mov.w	@r4,r0
		and	r1,r0
		mov.w	r0,@r4
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
		struct SH2_RAM|TH
	if MOMPASS=1
MarsRam_System		ds.l 0
MarsRam_Video		ds.l 0
MarsRam_Sound		ds.l 0
sizeof_marsram		ds.l 0
	else
MarsRam_System		ds.b (sizeof_marssys-MarsRam_System)
MarsRam_Video		ds.b (sizeof_marsvid-MarsRam_Video)
MarsRam_Sound		ds.b (sizeof_marssnd-MarsRam_Sound)
sizeof_marsram		ds.l 0
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

			struct MarsRam_Sound
MarsSnd_PwmCache	ds.b $80*MAX_PWMCHNL
sizeof_marssnd		ds.l 0
			finish

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
RAM_Mars_BgBuffScrl	ds.w sizeof_marsbg
RAM_Mars_BgBuffScale	ds.w sizeof_marsscbg
sizeof_marsvid		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MARS System RAM
; ----------------------------------------------------------------

			struct MarsRam_System
RAM_Mars_DreqDma	ds.b sizeof_dreq	; DREQ data recieved from Genesis in DMA ***DO NOT READ FROM HERE***
RAM_Mars_DreqRead	ds.b sizeof_dreq	; Copy of DREQ for reading.
RAM_Mars_Global		ds.l sizeof_MarsGbl	; gbr values go here.
sizeof_marssys		ds.l 0
			finish

; ====================================================================
