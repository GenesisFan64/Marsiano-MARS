; ====================================================================
; ----------------------------------------------------------------
; MARS SH2 CODE section, stored on SDRAM
;
; CODE for both CPUs
; RAM and some DATA also goes here
; ----------------------------------------------------------------

; *************************************************
; communication setup:
;
; comm0-comm7  - ** FREE to use ***
; comm8-comm11 - Used to transfer data manually
;                from Z80 to SH2 side, 68K uses DREQ.
; comm12       - Master CPU control
; comm14       - Slave CPU control
; *************************************************

		phase CS3	; Now we are at SDRAM
		cpu SH7600	; Should be SH7095 but this CPU mode works.

; ====================================================================
; ----------------------------------------------------------------
; Settings
; ----------------------------------------------------------------

SH2_DEBUG		equ 0	; Set to 1 too see if CPUs are active using comm counters (0 and 1)

; ====================================================================
; ----------------------------------------------------------------
; MARS GLOBAL gbr variables for both SH2
; ----------------------------------------------------------------

			struct 0
marsGbl_PlyPzList_R	ds.l 1	; Current graphic piece to draw
marsGbl_PlyPzList_W	ds.l 1	; Current graphic piece to write
marsGbl_PlyPzList_Start	ds.l 1	; Polygon pieces list Start point
marsGbl_PlyPzList_End	ds.l 1	; Polygon pieces list End point
marsGbl_CurrRdSpr	ds.l 1	; Current sprite to process
marsGbl_CurrRdPlgn	ds.l 1	; Current polygon to slice
marsGbl_CurrZList	ds.l 1	; Current Zsort entry
marsGbl_CurrZTop	ds.l 1	; Current Zsort list
marsGbl_CurrFacePos	ds.l 1	; Current top face of the list while reading model data
marsGbl_CurrNumFaces	ds.w 1	; and the number of faces stored on that list
marsGbl_WdgStatus	ds.w 1	; Watchdog exit status
marsGbl_PolyBuffNum	ds.w 1	; Polygon-list swap number
marsGbl_PlyPzCntr	ds.w 1	; Number of graphic pieces to draw
marsGbl_CntrRdPlgn	ds.w 1	; Number of polygons to slice
marsGbl_CntrRdSpr	ds.w 1	; Number of sprites to read
marsGbl_XShift		ds.w 1	; Xshift bit at the start of master_loop (TODO: maybe a HBlank list?)
marsGbl_RomBlkM		ds.w 1	; Flag to report that MASTER is reading from ROM area
marsGbl_RomBlkS		ds.w 1	; Flag to report that SLAVE is reading from ROM area
marsGbl_MdInitTmr	ds.w 1	; Redraw counter (Write $02)
marsGbl_BgDrwR		ds.w 1	; Write 2 to redraw these offscreen sections
marsGbl_BgDrwL		ds.w 1	; ***
marsGbl_BgDrwU		ds.w 1	; ***
marsGbl_BgDrwD		ds.w 1	; ***
marsGbl_WaveEnable	ds.w 1	; General linetable wave effect: Disable/Enable
marsGbl_WaveSpd		ds.w 1	; Linetable wave speed
marsGbl_WaveMax		ds.w 1	; Maximum wave
marsGbl_WaveDeform	ds.w 1	; Wave increment value
marsGbl_WaveTan		ds.w 1	; Linetable wave tan
marsGbl_FrameReady	ds.w 1
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

; ====================================================================
; ----------------------------------------------------------------
; SLAVE CPU VECTOR LIST (vbr)
; ----------------------------------------------------------------

		align 4
SH2_Slave:
		dc.l SH2_S_Entry,CS3|$3F000	; Cold PC,SP
		dc.l SH2_S_Entry,CS3|$3F000	; Manual PC,SP
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
		dc.l slave_irq			; Watchdog (custom)

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
		ltorg

; ------------------------------------------------
; irq list
; ------------------------------------------------

		align 4
int_m_list:
		dc.l m_irq_bad,m_irq_bad
		dc.l m_irq_bad,m_irq_bad
		dc.l $C0000000,$C0000000	; <-- TOP code on Cache
		dc.l m_irq_pwm,m_irq_pwm
		dc.l m_irq_cmd,m_irq_cmd
		dc.l m_irq_h,m_irq_h
		dc.l m_irq_v,m_irq_v
		dc.l m_irq_vres,m_irq_vres
int_s_list:
		dc.l s_irq_bad,s_irq_bad
		dc.l s_irq_bad,s_irq_bad
		dc.l s_irq_wdg,s_irq_wdg
		dc.l s_irq_pwm,s_irq_pwm
		dc.l s_irq_cmd,s_irq_cmd
		dc.l s_irq_h,s_irq_h
		dc.l s_irq_v,s_irq_v
		dc.l s_irq_vres,s_irq_vres

; ====================================================================
; ----------------------------------------------------------------
; Error handler
; ----------------------------------------------------------------

; *** Only works on HARDWARE ***
;
; comm2: (CPU)(CODE)
; comm4: Last program counter
;
;  CPU | SH2 who got the error:
;        $00 - Master
;        $01 - Slave
;
; CODE | Error type:
;	 -1: Unknown error
;	 $01: Illegal instruction
;	 $02: Invalid slot instruction
;	 $03: Address error (most common if you don't align by 4)
;	 $04: DMA error
;	 $05: NMI vector
;	 $06: User break

SH2_M_Error:
		bra	SH2_M_ErrCode
		mov	#$00FF,r0
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
		mov	#$01FF,r0
SH2_S_ErrIllg:
		bra	SH2_S_ErrCode
		mov	#$0101,r0
SH2_S_ErrInvl:
		bra	SH2_S_ErrCode
		mov	#$0102,r0
SH2_S_ErrAddr:
		bra	SH2_S_ErrCode
		mov	#$0103,r0
SH2_S_ErrDma:
		bra	SH2_S_ErrCode
		mov	#$0104,r0
SH2_S_ErrNmi:
		bra	SH2_S_ErrCode
		mov	#$0105,r0
SH2_S_ErrUser:
		bra	SH2_S_ErrCode
		mov	#$0106,r0
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
		mov	#_sysreg,r4		; r4 - sysreg base
		mov	#_DMASOURCE0,r3		; r3 - DMA base register
		mov	#_sysreg+comm12,r2	; r2 - comm to write the signal
		mov	#_sysreg+dreqfifo,r1	; r1 - Source point: DREQ FIFO
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
	; On Emulators it starts right away...
		mov.b	@r2,r0			; Tell Genesis we are ready to
		or	#%01000000,r0		; recieve the data from DREQ
		mov.b	r0,@r2
		nop
		nop
.wait_dma:
		mov	@($C,r3),r0		; Read DMA's mode for the active/enabled bits
		tst	#%10,r0			; Active?
		bt	.wait_dma
.time_out:
		mov	#0,r0			; _DMAOPERATION = 0
		mov	r0,@($30,r3)

	; *** HARDWARE NOTE ***
	; If the CPU reads or writes to the DESTINATION data
	; as we just recieved at any location: The DMA
	; will finish early when it reaches the location
	; that got modified.
	;
	; The only workaround is to copy-paste the data
	; we just received into another buffer for reading
	; it safetly, as current 32X Emulators doesn't recreate
	; this limitation.
		mov	#RAM_Mars_DreqDma,r1
		mov	#RAM_Mars_DreqRead,r2
		mov	#sizeof_dreq/4,r3	; NOTE: copying as LONGS
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
		nop
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
		rts
		nop
		align 4

; =================================================================
; ------------------------------------------------
; Master | VRES Interrupt (RESET button on Genesis)
; ------------------------------------------------

m_irq_vres:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg,r2
		mov.w	r0,@(vresintclr,r2)
		mov.b	@(dreqctl+1,r2),r0
		tst	#%10,r0
		bf	.rv_busy
		mov	#(CS3|$40000)-8,r15
		mov	#SH2_M_HotStart,r0
		mov	r0,@r15
		mov.w   #$F0,r0
		mov	r0,@(4,r15)
		mov	#$FFFFFE80,r1
		mov.w	#$A518,r0		; Disable Watchdog
		mov.w	r0,@r1
		mov	#_DMAOPERATION,r1
		mov     #0,r0
		mov	r0,@r1
		mov	#_DMACHANNEL0,r1
		mov     #0,r0
		mov	r0,@r1
		mov	#$44E0,r1
		mov	r0,@r1
		mov	#"M_OK",r0
		mov	r0,@(comm0,r2)
		rte
		nop
		align 4
.rv_busy:
		bra	.rv_busy
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

; check cache.asm
; s_irq_pwm:

; =================================================================
; ------------------------------------------------
; Slave | CMD Interrupt
; ------------------------------------------------

s_irq_cmd:
		mov	#.tag_F0,r0
		ldc	r0,sr
		mov	#.tag_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1	; Clear CMD flag
		mov.w	r0,@r1

	; ---------------------------------

		mov	#_sysreg+comm14,r1
		mov.b	@r1,r0			; MSB only
		and	#%00001111,r0
		cmp/eq	#0,r0
		bf	.valid_cmd
		bra	.no_ztrnsfr
		nop
		align 4
.tag_FRT:	dc.l _FRT
.tag_F0:	dc.l $F0
.valid_cmd:
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
		align 4

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
.no_ztrnsfr:
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
; Slave | VRES Interrupt (RESET button on Genesis)
; ------------------------------------------------

s_irq_vres:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg,r2
		mov.w	r0,@(vresintclr,r2)
		mov.b	@(dreqctl+1,r2),r0
		tst	#%10,r0
		bf	.rv_busy
		mov	#(CS3|$3F000)-8,r15
		mov	#SH2_S_HotStart,r0
		mov	r0,@r15
		mov.w   #$F0,r0
		mov	r0,@(4,r15)
		mov	#$FFFFFE80,r1
		mov.w	#$A518,r0		; Disable Watchdog
		mov.w	r0,@r1
		mov	#_DMAOPERATION,r1
		mov     #0,r0
		mov	r0,@r1
		mov	#_DMACHANNEL0,r1
		mov     #0,r0
		mov	r0,@r1
		mov	#$44E0,r1
		mov	r0,@r1
		mov	#"S_OK",r0
		mov	r0,@(comm4,r2)
		rte
		nop
		align 4
.rv_busy:
		bra	.rv_busy
		nop
		align 4
		ltorg		; Save literals


; =================================================================
; ------------------------------------------------
; Master | Watchdog interrupt
; ------------------------------------------------

; m_irq_wdg:
; check cache_m_plgn.asm

; =================================================================
; ------------------------------------------------
; Slave | Watchdog interrupt
; ------------------------------------------------

s_irq_wdg:
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
		align 4

; ====================================================================
; ----------------------------------------------------------------
; Mars_LoadFastCode
;
; Loads "fast code" into the SH2's cache
; ($800 bytes max)
;
; Input:
; r1 - Code to transfer
; r2 - Size / 4
;
; Breaks:
; r3
;
; NOTE:
; Interrupts MUST be OFF
; ----------------------------------------------------------------

		align 4
Mars_LoadFastCode:
		stc	sr,@-r15	; Interrupts OFF
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_CCR,r3
		mov	#%00010000,r0	; Cache purge + Disable
		mov.w	r0,@r3
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
		align 4

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

		mov	#CS3|$40000,r15			; Set default Stack for Master
		mov	#RAM_Mars_Global,r14		; GBR - Global values/variables go here.
		ldc	r14,gbr
		mov.l   #$FFFFFEE2,r0			; Watchdog: Set interrupt priority bits (IPRA)
		mov     #%0101<<4,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1			; Watchdog: Set jump pointer: VBR + (this/4) (WITV)
		shll8   r1
		mov.w   r1,@r0

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
; This CPU is exclusively used for the visuals:
; software-rendered backgrounds, sprites and polygons.
; ----------------------------------------------------------------

SH2_M_HotStart:
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

; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_WaveEnable,gbr)
		mov	#8,r0
		mov.w	r0,@(marsGbl_WaveSpd,gbr)
		mov	#8,r0
		mov.w	r0,@(marsGbl_WaveMax,gbr)
		mov	#32,r0
		mov.w	r0,@(marsGbl_WaveDeform,gbr)

		bra	master_loop
		nop
		align 4
		ltorg

; ----------------------------------------------------------------
; MASTER CPU loop
;
; comm12:
; bssscccc ir000lll
;
; b - busy bit on the CMD interrupt
;     (68k knows that the interrupt is active)
; s - status bits for some CMD interrupt tasks
; c - command number for CMD interrupt
; i - Initialitation bit
; r - Clears on exit, set this bit on 68k side to wait for the
;     current screen to finish.
; l - MAIN LOOP command/task, inlcude the i bit to properly
;     (re)start
; ----------------------------------------------------------------

		align 4
master_loop:
; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_FrameReady,gbr)
; .wait_vblk:
; 		mov.w	@(marsGbl_FrameReady,gbr),r0
; 		tst	r0,r0
; 		bf	.wait_vblk

	if SH2_DEBUG
		mov	#_sysreg+comm0,r1		; DEBUG counter
		mov.b	@r1,r0
		add	#1,r0
		mov.b	r0,@r1
	endif

	; ---------------------------------------
	; Wait frameswap
	;
	; TODO: maybe use the VBlank interrupt now?
		mov	#_vdpreg,r1			; r1 - SVDP area
.wait_fb:	mov.w	@(vdpsts,r1),r0			; SVDP FILL active?
		tst	#%10,r0
		bf	.wait_fb
		mov.b	@(framectl,r1),r0		; Framebuffer swap REQUEST.
		xor	#1,r0				; manually Wait for VBlank after this
		mov.b	r0,@(framectl,r1)
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

		mov	#_sysreg+comm12+1,r1		; Clear R bit, this
		mov.b	@r1,r0				; tells to 68k that frame is ready.
		and	#%10111111,r0
		mov.b	r0,@r1
 		mov.w	@(marsGbl_XShift,gbr),r0	; Set SHIFT bit first
		mov	#_vdpreg+shift,r1		; For the indexed-scrolling
		and	#1,r0
		mov.w	r0,@r1
	; ---------------------------------------
	; TODO: cambiar esto a longwords, los docs dicen
	; que solo por WORDS pero el HWDIAG si escribe
	; en LONGS...
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
		ldc	@r15+,sr			; Interrupts ON
	; ---------------------------------------
	; Per-mode VBlank changes
		mov	#mstr_gfxlist_v,r1		; Point to VBLANK jumps
		mov	#_sysreg+comm12,r2
		mov.w	@r2,r0
		and	#%0111,r0
		shll2	r0
		shll2	r0
		mov	@(r1,r0),r1
		jsr	@r1
		nop

; ---------------------------------------
; Pick graphics mode on comm12
; ---------------------------------------

		mov	#mstr_gfxlist,r3		; Default LOOP points
		mov	#_sysreg+comm12,r2
		mov.w	@r2,r0				; r0 - INIT bit
		mov	r0,r1				; r1 - mode
		tst	#$80,r0				; First time/Full redraw?
		bt	.no_init
		mov	#_sysreg+comm14,r4		; Wait slave first.
.wait_slv:	mov.w	@r4,r0
		and	#$FF,r0
		tst	r0,r0
		bf	.wait_slv
		mov.w	@r2,r0
		and	#$7F,r0				; Reset init bit
		mov.w	r0,@r2
		mov	#2,r0
		mov.w	r0,@(marsGbl_MdInitTmr,gbr)
.no_init:
		mov.w	@(marsGbl_MdInitTmr,gbr),r0
		mov	r0,r2
		tst	r0,r0
		bt	.tmr_off
		dt	r0
		mov.w	r0,@(marsGbl_MdInitTmr,gbr)
.tmr_off:
		shll2	r2
		mov	r1,r0
		and	#%111,r0
		shll2	r0
		shll2	r0
		add	r2,r0
		mov	@(r3,r0),r3
		jmp	@r3
		nop
		align 4
		ltorg

; ---------------------------------------
; jump lists

		align 4
mstr_gfxlist_h:	dc.l mstr_gfx0_hblk	; $00
		dc.l mstr_gfx1_hblk	; $01
		dc.l mstr_gfx2_hblk	; $02
		dc.l mstr_gfx3_hblk	; $03
		dc.l mstr_gfx4_hblk	; $04
		dc.l mstr_gfx0_hblk	; $05
		dc.l mstr_gfx0_hblk	; $06
		dc.l mstr_gfx0_hblk	; $07
mstr_gfxlist:	dc.l mstr_gfx0_loop	; $00
		dc.l mstr_gfx0_init_2
		dc.l mstr_gfx0_init_1
mstr_gfxlist_v:	dc.l mstr_gfx0_vblk
		dc.l mstr_gfx1_loop	; $01
		dc.l mstr_gfx1_init_2
		dc.l mstr_gfx1_init_1
		dc.l mstr_gfx1_vblk
		dc.l mstr_gfx2_loop	; $02
		dc.l mstr_gfx2_init_2
		dc.l mstr_gfx2_init_1
		dc.l mstr_gfx2_vblk
		dc.l mstr_gfx3_loop	; $03
		dc.l mstr_gfx3_init_2
		dc.l mstr_gfx3_init_1
		dc.l mstr_gfx3_vblk
		dc.l mstr_gfx4_loop	; $04
		dc.l mstr_gfx4_init_2
		dc.l mstr_gfx4_init_1
		dc.l mstr_gfx4_vblk
		dc.l mstr_gfx0_loop	; $05
		dc.l mstr_gfx0_init_2
		dc.l mstr_gfx0_init_1
		dc.l mstr_gfx0_vblk
		dc.l mstr_gfx0_loop	; $06
		dc.l mstr_gfx0_init_2
		dc.l mstr_gfx0_init_1
		dc.l mstr_gfx0_vblk
		dc.l mstr_gfx0_loop	; $07
		dc.l mstr_gfx0_init_2
		dc.l mstr_gfx0_init_1
		dc.l mstr_gfx0_vblk

; ============================================================
; ---------------------------------------
; Pseudo-screen mode $00: BLANK
;
; YOU must use set this mode if you are
; doing these things on the Genesis side:
;
; - H32 mode
; - Double interlace mode
;   (both H32 and H40)
; ---------------------------------------

; -------------------------------
; HBlank
; -------------------------------

mstr_gfx0_hblk:
		rts
		nop
		align 4

; -------------------------------
; VBlank
; -------------------------------

mstr_gfx0_vblk:
		rts
		nop
		align 4

; -------------------------------
; Init
; -------------------------------

mstr_gfx0_init_1:
		mov 	#_vdpreg,r1
		mov	#0,r0
		mov.b	r0,@(bitmapmd,r1)
		mov.w	r0,@(marsGbl_BgDrwR,gbr)
		mov.w	r0,@(marsGbl_BgDrwL,gbr)
		mov.w	r0,@(marsGbl_BgDrwD,gbr)
		mov.w	r0,@(marsGbl_BgDrwU,gbr)
mstr_gfx0_init_2:

; -------------------------------
; Loop
; -------------------------------

mstr_gfx0_loop:
		bra	master_loop
		nop

; ============================================================
; ---------------------------------------
; Pseudo-screen mode $01:
;
; Generic static screen in any
; bitmap mode: Indexed, Direct or RLE
;
; Note that Direct's HEIGHT
; will be limited to 200 lines.
; ---------------------------------------

; -------------------------------
; HBlank
; -------------------------------

mstr_gfx1_hblk:
		rts
		nop
		align 4

; -------------------------------
; VBlank
; -------------------------------

mstr_gfx1_vblk:
		rts
		nop
		align 4

; -------------------------------
; Init
; -------------------------------

mstr_gfx1_init_2:
		mov 	#_vdpreg,r1
		mov	#2,r0
		mov.b	r0,@(bitmapmd,r1)
mstr_gfx1_init_1:
		bsr	MarsVideo_ResetNameTbl
		nop

; -------------------------------
; Loop
; -------------------------------

mstr_gfx1_loop:
		mov	#RAM_Mars_DreqRead+Dreq_ScrnBuff,r1
		mov	@(Dreq_Scrn1_Type,r1),r0
		and	#%11,r0
		shll2	r0
		mov	#.m1list,r2
		mov	@(r0,r2),r2
		jmp	@r2
		nop
		align 4
.m1list:
		dc.l master_loop
		dc.l master_loop	; Indexed
		dc.l .direct		; Direct
		dc.l master_loop

; -------------------------------
; Direct color
; currently 320x200 (DOS-style)
.direct:
; 		tst	r0,r0
; 		bt	.dont_rdrw
		mov	@(Dreq_Scrn1_Data,r1),r1
		mov	#_framebuffer+$200,r2
		mov	#(320*200/2)/2,r3
.copy_me:
		mov	@r1+,r0
		mov	r0,@r2
		add	#4,r2
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.copy_me
		add	#4,r2
.dont_rdrw:
		mov	#$200,r1
		mov	#320*2,r2
		mov	#200,r3
		bsr	MarsVideo_MakeNameTbl
		mov	#12,r4
		bra	master_loop
		nop

; -------------------------------
; RLE indexed-compressed image
; (maybe make the RLE frames
; compressed too.?)

.rle:
		bra	master_loop
		nop

; ============================================================
; ---------------------------------------
; Pseudo-screen mode $02:
;
; 256-color scrolling image
;
; *** WAIT 2 FRAMES TO PROPERLY
; START THIS MODE ***
; ---------------------------------------

; -------------------------------
; HBlank
; -------------------------------

mstr_gfx2_hblk:
		rts
		nop
		align 4

; -------------------------------
; VBlank
; -------------------------------

mstr_gfx2_vblk:
		mov	#RAM_Mars_DreqRead+Dreq_SuperSpr,r1	; Copypaste Supersprites from DREQ
		mov	#RAM_Mars_SuperSprites,r2
		mov	#(sizeof_marsspr*MAX_SUPERSPR)/4,r3	; LONG copies
.copy_safe:
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.copy_safe
		add	#4,r2
		mov.w	@(marsGbl_MdInitTmr,gbr),r0
		tst	r0,r0
		bf	.mid_draw
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	#RAM_Mars_DreqRead+Dreq_ScrnBuff,r0
		mov	@(Dreq_Scrn2_X,r0),r1
		mov	@(Dreq_Scrn2_Y,r0),r2
		mov	r1,@(mbg_xpos,r14)
		mov	r2,@(mbg_ypos,r14)
.mid_draw:
		rts
		nop
		align 4

; -------------------------------
; Init
; -------------------------------

mstr_gfx2_init_1:
		mov	#CACHE_MSTR_SCRL,r1
		mov	#(CACHE_MSTR_SCRL_E-CACHE_MSTR_SCRL)/4,r2
		mov	#Mars_LoadFastCode,r0
		jsr	@r0
		nop
		mov	#RAM_Mars_BgBuffScrl,r1		; <-- TODO: make these configurable
		mov	#$200,r2			; on Genesis side
		mov	#16,r3				; block size
		mov	#320,r4				; max width
		mov	#256,r5				; max height
		bsr	MarsVideo_MkScrlField
		mov	#0,r6
		xor	r0,r0
		mov.w	r0,@(marsGbl_BgDrwR,gbr)	; Cancel
		mov.w	r0,@(marsGbl_BgDrwL,gbr)	; all
		mov.w	r0,@(marsGbl_BgDrwU,gbr)	; these
		mov.w	r0,@(marsGbl_BgDrwD,gbr)	; draw requests
		mov	#RAM_Mars_DreqRead+Dreq_ScrnBuff,r0		; Set scrolling source data
		mov	#RAM_Mars_BgBuffScrl,r1
		mov	@(Dreq_Scrn2_Data,r0),r2
		mov	@(Dreq_Scrn2_W,r0),r3
		mov	@(Dreq_Scrn2_H,r0),r4
		bsr	MarsVideo_SetScrlBg
		nop
		bra	mstr_gfx2_init_cont
		nop
mstr_gfx2_init_2:
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)
mstr_gfx2_init_cont:
		bsr	MarsVideo_DrawAllBg	; Process FULL image
		nop

; -------------------------------
; Loop
; -------------------------------

mstr_gfx2_loop:
		mov	#RAM_Mars_SuperSprites,r0
		mov	r0,@(marsGbl_CurrRdSpr,gbr)	; Set watchdog for sprites
		mov	#0,r0
		mov.w	r0,@(marsGbl_CntrRdSpr,gbr)
		mov	#0,r1
		mov	#$20,r2
		bsr	MarsVideo_SetWatchdog
		nop
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	@(mbg_xpos,r14),r1
		mov	@(mbg_ypos,r14),r2
		mov	r1,r0
		shlr16	r0
		mov.w	r0,@(marsGbl_XShift,gbr)
		bsr	MarsVideo_MoveBg
		nop
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	@(mbg_fbdata,r14),r1
		mov	@(mbg_fbpos,r14),r2
		mov.w	@(mbg_fbpos_y,r14),r0
		mov	r0,r3
		mov.w	@(mbg_intrl_w,r14),r0
		mov	r0,r4
		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r5
		mov	@(mbg_intrl_size,r14),r6
		mov	#MarsVideo_SetSuperSpr,r0
		jsr	@r0
		nop
	; *** BG refill goes here
; 		mov.w	@(marsGbl_MdInitTmr,gbr),r0
; 		tst	r0,r0
; 		bt	.from_drwall
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	#MarsVideo_BgDrawLR,r0		; Process U/D/L/R
		jsr	@r0
		nop
		mov	#MarsVideo_BgDrawUD,r0
		jsr	@r0
		nop
; .from_drwall:
; 		mov.w	@(marsGbl_PlyPzCntr,gbr),r0
; 		tst	r0,r0
; 		bt	.no_swap
.wait_wd:	mov.w	@(marsGbl_WdgStatus,gbr),r0
		tst	r0,r0
		bt	.wait_wd
		mov	#MarsVideo_DrawSuperSpr,r0
		jsr	@r0
		nop
.no_swap:

	; ---------------------------------------
	; Build linetable
	; ---------------------------------------
		mov	#RAM_Mars_BgBuffScrl,r1		; Make visible background
		mov	#0,r2				; section on screen
		mov	#240,r3
		bsr	MarsVideo_ShowScrlBg
		nop
		bsr	MarsVideo_FixTblShift		; Fix those broken lines that
		nop					; the Xshift register can't move
		bra	master_loop
		nop
		align 4
		ltorg

; ============================================================
; ---------------------------------------
; Pseudo-screen mode $03:
; Scalable 256-color screen
;
; Not as smooth as Mode 2
; ---------------------------------------

; -------------------------------
; HBlank
; -------------------------------

mstr_gfx3_hblk:
		rts
		nop
		align 4

; -------------------------------
; VBlank
; -------------------------------

mstr_gfx3_vblk:
		mov	#RAM_Mars_DreqRead+Dreq_SuperSpr,r1	; Copypaste Supersprites from DREQ
		mov	#RAM_Mars_SuperSprites,r2
		mov	#(sizeof_marsspr*MAX_SUPERSPR)/4,r3	; LONG copies
.copy_safe:
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.copy_safe
		add	#4,r2
		mov	#RAM_Mars_DreqRead+Dreq_ScrnBuff,r1	; Copy-paste scale buffer
		mov	#RAM_Mars_BgBuffScale_M,r2
; 		mov	#RAM_Mars_BgBuffScale_S,r3
		mov	#8,r4
.copy_me:
		mov	@r1+,r0
		mov	r0,@r2
; 		mov	r0,@r3
		add	#4,r2
		dt	r4
		bf/s	.copy_me
		add	#4,r3
; 		mov	#_sysreg+comm14,r4
; 		mov.w	@r4,r0
; 		or	#$01,r0					; Slave task $01
; 		mov.w	r0,@r4
		rts
		nop
		align 4

; -------------------------------
; Init
; -------------------------------

mstr_gfx3_init_1:
		mov	#CACHE_MSTR_SCRL,r1
		mov	#(CACHE_MSTR_SCRL_E-CACHE_MSTR_SCRL)/4,r2
		mov	#Mars_LoadFastCode,r0
		jsr	@r0
		nop
		mov	#0,r0
		mov.w	r0,@(marsGbl_XShift,gbr)
		bra	mstr_gfx3_loop
		nop

mstr_gfx3_init_2:
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)

; -------------------------------
; Loop
; -------------------------------

mstr_gfx3_loop:
		mov	#RAM_Mars_SuperSprites,r0
		mov	r0,@(marsGbl_CurrRdSpr,gbr)	; Set watchdog for sprites
		mov	#0,r0
		mov.w	r0,@(marsGbl_CntrRdSpr,gbr)
		mov	#2,r1
		mov	#$20,r2
		bsr	MarsVideo_SetWatchdog
		nop
		mov	#$200,r1
		mov	#0,r2
		mov	#0,r3
		mov	#320,r4
		mov	#240,r5
		mov	#320*240,r6
		mov	#MarsVideo_SetSuperSpr,r0
		jsr	@r0
		nop

	; MAIN scaler
	; r1 - X pos xxxx.0000
	; r2 - Y pos yyyy.0000
	; r3 - X dx  xxxx.0000
	; r4 - Y dx  yyyy.0000
	; r5 - Source WIDTH
	; r6 - Source HEIGHT
	; r7 - Source DATA
	; r8 - Output
	; r9 - Loop: Line width / 2
	; r10 - Loop: Number of lines
		mov	#RAM_Mars_BgBuffScale_M,r14
		mov	#_framebuffer+$200,r13	; r13 - Output
		mov	@r14+,r7		; r7 - Input
		mov	@r14+,r1		; r1 - X pos (2 pixels wide)
		mov	@r14+,r2		; r2 - Y pos
		mov	@r14+,r5		; r5 - X width
		mov	@r14+,r6		; r6 - Y height
		mov	@r14+,r3		; r3 - DX
		mov	@r14+,r4		; r4 - DY
		mov	@r14+,r9		; r9 - Mode
		mov	#TH,r0			; Force source as Cache-Thru
		or	r0,r7
		shll16	r5
		shll16	r6
		dmuls	r1,r5			; Topleft X/Y calc
		sts	mach,r0
		sts	macl,r1
		xtrct	r0,r1
		dmuls	r2,r6
		sts	mach,r0
		sts	macl,r2
		xtrct	r0,r2
		lds	r9,mach			; mach - mode number
		mov	#320/2,r9		; r9  - X loop
		mov	#240,r10		; r10 - Y loop

	; X check
		sts	mach,r0
		tst	r0,r0
		bt	.x_cont
.x_fix:
		cmp/pz	r1
		bt	.x_cont
		bra	.x_fix
		add	r5,r1
.x_cont:


; *** LOOP
.y_loop:
		sts	mach,r0
		tst	r0,r0
		bt	.y_high
		cmp/pz	r2
		bt	.xy_set
		bra	.y_loop
		add	r6,r2
.xy_set:
		cmp/ge	r6,r2
		bf	.y_high
		bra	.xy_set
		sub	r6,r2
.y_high:
		mov	r1,r11
		shar	r11		; /2
		mov	r2,r0
		shlr16	r0
		mov	r5,r8
		shlr16	r8
		muls	r8,r0
		sts	macl,r12
		add	r7,r12
		mov	r13,r8
		mov	r9,r14
.x_loop:
	; 00 - single scale
		sts	mach,r0
		tst	r0,r0
		bf	.x_rept
		cmp/pz	r11
		bt	.xwpos
		bra	.x_next
		mov	#0,r0
.xwpos:
		mov	r5,r0
		shar	r0		; /2
		cmp/ge	r0,r11
		bf	.x_go
		bra	.x_next
		mov	#0,r0
.x_go:
		mov	#0,r0
		cmp/pz	r2		; <-- TODO: checar bien esto
		bf	.x_next
		cmp/ge	r6,r2
		bt	.x_next
		bra	.x_high
		nop
.x_rept:
	; 01 - repeat check
		mov	r5,r0
		shar	r0		; /2
		cmp/pl	r11
		bt	.xwpos2
.x_loopm:	cmp/ge	r0,r11
		bt	.x_high
		bra	.x_loopm
		add	r0,r11
.xwpos2:
		cmp/ge	r0,r11
		bf	.x_high
		bra	.xwpos2
		sub	r0,r11
.x_high:
		mov	r11,r0
		shlr16	r0
		exts	r0,r0
		shll	r0
		mov.w	@(r12,r0),r0
.x_next:
		add	r3,r11
		mov.w	r0,@r8
		dt	r14
		bf/s	.x_loop
		add	#2,r8
		add	r4,r2
		mov	#320,r0
		dt	r10
		bf/s	.y_loop
		add	r0,r13

		mov	#$200,r1
		mov	#320,r2
		mov	#240,r3
		bsr	MarsVideo_MakeNametbl
		mov	#0,r4

	; Wait Slave to finish
; 		mov	#_sysreg+comm14,r5
; .wait_slv:	mov.w	@r5,r0
; 		and	#%01111111,r0
; 		tst	r0,r0
; 		bf	.wait_slv
; 		mov.w	@(marsGbl_PlyPzCntr,gbr),r0
; 		tst	r0,r0
; 		bt	.no_pz
.wait_wd:	mov.w	@(marsGbl_WdgStatus,gbr),r0
		tst	r0,r0
		bt	.wait_wd
		mov	#MarsVideo_DrawSuperSpr,r0
		jsr	@r0
		nop
.no_pz:

		bra	master_loop
		nop
		align 4
		ltorg
		align 4

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

; -------------------------------
; HBlank
; -------------------------------

mstr_gfx4_hblk:
		rts
		nop
		align 4

; -------------------------------
; VBlank
; -------------------------------

mstr_gfx4_vblk:
		mov	#_sysreg+comm14,r4
		mov.w	@r4,r0
		and	#%01111111,r0
		tst	r0,r0
		bf	.slv_busy
		mov	#RAM_Mars_DreqRead+Dreq_Objects,r1	; Copy Dreq models from here.
		mov	#RAM_Mars_Objects,r2
		mov	#(sizeof_mdlobj*MAX_MODELS)/4,r3	; LONG copies
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
		or	#$01,r0
		mov.w	r0,@r4
.slv_busy:
		rts
		nop
		align 4

; -------------------------------
; Init
; -------------------------------

mstr_gfx4_init_1:
		mov	#CACHE_MSTR_PLGN,r1
		mov	#(CACHE_MSTR_PLGN_E-CACHE_MSTR_PLGN)/4,r2
		mov	#Mars_LoadFastCode,r0
		jsr	@r0
		nop
		mov	#0,r0
		mov.w	r0,@(marsGbl_XShift,gbr)
		bra	mstr_gfx4_init_cont
		nop

mstr_gfx4_init_2:
		mov 	#_vdpreg,r1
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)

mstr_gfx4_init_cont:
		mov	#$200,r1
		mov	#(511)/2,r2
		mov	#240,r3
		mov	#0,r4
		mov	#MarsVideo_ClearScreen,r0
		jsr	@r0
		nop

; -------------------------------
; Loop
; -------------------------------

mstr_gfx4_loop:
		mov	#$FFFFFE80,r1		; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1

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
		mov	r0,@(marsGbl_CurrRdPlgn,gbr)
		mov	@r1,r0
		mov.w	r0,@(marsGbl_CntrRdPlgn,gbr)
		mov	#2,r1
		mov	#$10,r2
		bsr	MarsVideo_SetWatchdog
		nop

	; ---------------------------------------
	; Clear screen
	; ---------------------------------------
		mov.w	@(marsGbl_MdInitTmr,gbr),r0
		tst	r0,r0
		bf	.no_redraw_2
	; *** This also counts as a delay for Watchdog ***
		mov	#$200,r1
		mov	#(320)/2,r2
		mov	#240,r3
		mov	#0,r4
		mov	#MarsVideo_ClearScreen,r0
		jsr	@r0
		nop
.no_redraw_2:
		mov	#$200,r1
		mov	#512,r2		; <-- fixed WIDTH
		mov	#240,r3
		bsr	MarsVideo_MakeNametbl
		mov	#0,r4

	; ---------------------------------------

; 		mov.w	@(marsGbl_PlyPzCntr,gbr),r0
; 		tst	r0,r0
; 		bt	.no_swap
; .wait_wd:	mov.w	@(marsGbl_WdgStatus,gbr),r0	; <-- enable this if something goes wrong.
; 		tst	r0,r0
; 		bt	.wait_wd
		mov	#MarsVideo_DrawPzPlgns,r0
		jsr	@r0
		nop
.no_swap:
		bra	master_loop
		nop
		align 4
		ltorg

; ============================================================

; r1 - start vram pos
; r2 - width
; r3 - height


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
		mov	#CS3|$3F000,r15			; Reset stack
		mov	#RAM_Mars_Global,r14		; Reset gbr
		ldc	r14,gbr
		mov.l   #$FFFFFEE2,r0			; Watchdog: Set interrupt priority bits (IPRA)
		mov     #%0101<<4,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1			; Watchdog: Set jump pointer (VBR + this/4) (WITV)
		shll8   r1
		mov.w   r1,@r0
		mov	#CACHE_SLAVE,r1
		mov	#(CACHE_SLAVE_E-CACHE_SLAVE)/4,r2
		mov	#Mars_LoadFastCode,r0
		jsr	@r0
		nop
		mov	#_sysreg,r1
		mov	#CMDIRQ_ON|PWMIRQ_ON,r0		; Enable these interrupts
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
		mov	#$20004000,r14
		mov	#0,r0
		mov.w	r0,@($14,r14)
		mov.w	r0,@($16,r14)
		mov.w	r0,@($18,r14)
		mov.w	r0,@($1A,r14)
		mov	#$F0,r0
		ldc	r0,sr
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
		tst	r0,r0
		bt	slave_loop
		shll2	r0
		mov	@(r3,r0),r4
		jmp	@r4
		nop
		align 4
.list:
		dc.l slave_loop		; $00
		dc.l .slv_task_1	; $01 - Build 3D models
		dc.l slave_loop		; $02
		dc.l slave_loop		; $03
		dc.l slave_loop		; $04
		dc.l slave_loop		; $05
		dc.l slave_loop		; $06
		dc.l slave_loop		; $07
		dc.l slave_loop		; $08
		dc.l slave_loop		; $09
		dc.l slave_loop		; $0A
		dc.l slave_loop		; $0B
		dc.l slave_loop		; $0C
		dc.l slave_loop		; $0D
		dc.l slave_loop		; $0E
		dc.l slave_loop		; $0F

; ; ============================================================
; ; ---------------------------------------
; ; Slave task $01
; ;
; ; Helps MASTER to draw the bottom half
; ; of the scaled background
; ; ---------------------------------------
;
; .slv_task_1:
;
; 	; MAIN scaler
; 	; r1 - X pos xxxx.0000
; 	; r2 - Y pos yyyy.0000
; 	; r3 - X dx  xxxx.0000
; 	; r4 - Y dx  yyyy.0000
; 	; r5 - Source WIDTH
; 	; r6 - Source HEIGHT
; 	; r7 - Source DATA
; 	; r8 - Output
; 	; r9 - line size / 2
; 	; r10 - Number of lines
; 		mov	#RAM_Mars_BgBuffScale_S,r14
; 		mov	#(_framebuffer+$200)+(320*120),r13	; r8 - Output
; 		mov	@r14+,r7		; r7 - Input
; 		mov	@r14+,r1		; r1 - X pos (2 pixels wide)
; 		mov	@r14+,r2		; r2 - Y pos
; 		mov	@r14+,r5		; r5 - X width
; 		mov	@r14+,r6		; r6 - Y height
; 		mov	@r14+,r3		; r3 - DX
; 		mov	@r14+,r4		; r4 - DY
; 		mov	@r14+,r9		; r9 - Mode
; 		mov	#TH,r0			; Force source as Cache-Thru
; 		or	r0,r7
; 		shll16	r5
; 		shll16	r6
; 		dmuls	r1,r5			; Topleft X/Y calc
; 		sts	mach,r0
; 		sts	macl,r1
; 		xtrct	r0,r1
; 		dmuls	r2,r6
; 		sts	mach,r0
; 		sts	macl,r2
; 		xtrct	r0,r2
;
; 	; SLAVE ONLY: Manually get to the middle...
; 		mov	#240/2,r10		; r10 - Y loop
; .ymiddle:
; 		cmp/pz	r2
; 		bt	.xy_set2
; 		bra	.ymiddle
; 		add	r6,r2
; .xy_set2:
; 		cmp/ge	r6,r2
; 		bf	.y_high2
; 		bra	.xy_set2
; 		sub	r6,r2
; .y_high2:
; 		dt	r10
; 		bf/s	.ymiddle
; 		add	r4,r2
;
; ; *** LOOP
; 		lds	r9,mach			; mach - mode number
; 		mov	#320/2,r9		; r9  - X loop
; 		mov	#240/2,r10		; r10 - Y loop
;
; 	; X check
; 		sts	mach,r0
; 		tst	r0,r0
; 		bt	.x_cont
; .x_fix:
; 		cmp/pz	r1
; 		bt	.x_cont
; 		bra	.x_fix
; 		add	r5,r1
; .x_cont:
;
;
; ; *** LOOP
; .y_loop:
; 		sts	mach,r0
; 		tst	r0,r0
; 		bt	.y_high
; 		cmp/pz	r2
; 		bt	.xy_set
; 		bra	.y_loop
; 		add	r6,r2
; .xy_set:
; 		cmp/ge	r6,r2
; 		bf	.y_high
; 		bra	.xy_set
; 		sub	r6,r2
; .y_high:
; 		mov	r1,r11
; 		shar	r11		; /2
; 		mov	r2,r0
; 		shlr16	r0
; 		mov	r5,r8
; 		shlr16	r8
; 		muls	r8,r0
; 		sts	macl,r12
; 		add	r7,r12
; 		mov	r13,r8
; 		mov	r9,r14
; .x_loop:
; 	; 00 - single scale
; 		sts	mach,r0
; 		tst	r0,r0
; 		bf	.x_rept
; 		cmp/pz	r11
; 		bt	.xwpos
; 		bra	.x_next
; 		mov	#0,r0
; .xwpos:
; 		mov	r5,r0
; 		shar	r0		; /2
; 		cmp/ge	r0,r11
; 		bf	.x_go
; 		bra	.x_next
; 		mov	#0,r0
; .x_go:
; 		mov	#0,r0
; 		cmp/pl	r2
; 		bf	.x_next
; 		cmp/ge	r6,r2
; 		bt	.x_next
; 		bra	.x_high
; 		nop
; .x_rept:
; 	; 01 - repeat check
; 		mov	r5,r0
; 		shar	r0		; /2
; 		cmp/pl	r11
; 		bt	.xwpos2
; .x_loopm:	cmp/ge	r0,r11
; 		bt	.x_high
; 		bra	.x_loopm
; 		add	r0,r11
; .xwpos2:
; 		cmp/ge	r0,r11
; 		bf	.x_high
; 		bra	.xwpos2
; 		sub	r0,r11
; .x_high:
; 		mov	r11,r0
; 		shlr16	r0
; 		exts	r0,r0
; 		shll	r0
; 		mov.w	@(r12,r0),r0
; .x_next:
; 		add	r3,r11
; 		mov.w	r0,@r8
; 		dt	r14
; 		bf/s	.x_loop
; 		add	#2,r8
; 		add	r4,r2
; 		mov	#320,r0
; 		dt	r10
; 		bf/s	.y_loop
; 		add	r0,r13
;
; 		bra	.slv_exit
; 		nop
; 		align 4

; ============================================================
; ---------------------------------------
; Slave task $01
;
; Build 3D Models FOR THE NEXT FRAME
; (not current)
; ---------------------------------------

		align 4
.slv_task_1:
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
		mov	#0,r0
		mov.w	r0,@(marsGbl_CurrNumFaces,gbr)
		mov	#MarsMdl_MdlLoop,r0
		jsr	@r0
		nop
; 		bra	.slv_exit
; 		nop
; 		align 4

; ============================================================

; JMP only
.slv_exit:
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

		include "system/mars/cache/cache_m_scrlspr.asm"
		include "system/mars/cache/cache_m_plgn.asm"
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
; MARS Sound RAM
; ----------------------------------------------------------------

			struct MarsRam_Sound
MarsSnd_PwmCache	ds.b $80*MAX_PWMCHNL
sizeof_marssnd		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MARS Video RAM
;
; RAM_Mars_ScrnBuff is recycled for all pseudo-screen modes,
; check MAX_SCRNBUFF to set the maximum size.
; ----------------------------------------------------------------

			struct MarsRam_Video
RAM_Mars_SVdpDrwList	ds.b sizeof_plypz*MAX_SVDP_PZ		; Sprites / Polygon pieces
RAM_Mars_SVdpDrwList_e	ds.l 0					; (END point label)
RAM_Mars_SuperSprites	ds.b sizeof_marsspr*MAX_SUPERSPR	; Sprites for screens that support them
RAM_Mars_ScrnBuff	ds.b MAX_SCRNBUFF			; Single buffer for all screen modes
sizeof_marsvid		ds.l 0
			finish

; --------------------------------------------------------
; per-screen RAM
			struct RAM_Mars_ScrnBuff
RAM_Mars_BgBuffScrl	ds.b sizeof_marsbg
RAM_Mars_RdrwBlocks	ds.b (512*256)/4	; Block redraw flags *FIXED SIZE* (WIDTH * $80)
RAM_Mars_UD_Pixels	ds.b 384*64		; RAM pixel-side
RAM_Mars_LR_Pixels	ds.b 64*256
sizeof_scrn02		ds.l 0
			finish
			struct RAM_Mars_ScrnBuff
RAM_Mars_BgBuffScale_M	ds.l 8
sizeof_scrn03		ds.l 0
			finish
			struct RAM_Mars_ScrnBuff
RAM_Mars_Polygons_0	ds.b sizeof_polygn*MAX_FACES
RAM_Mars_Polygons_1	ds.b sizeof_polygn*MAX_FACES
RAM_Mars_Objects	ds.b sizeof_mdlobj*MAX_MODELS
RAM_Mars_ObjCamera	ds.b sizeof_camera		; 3D Camera buffer
RAM_Mars_PlgnList_0	ds.l 2*MAX_FACES		; polygondata, Zpos
RAM_Mars_PlgnList_1	ds.l 2*MAX_FACES
RAM_Mars_PlgnNum_0	ds.l 1				; Number of polygons to process
RAM_Mars_PlgnNum_1	ds.l 1
sizeof_scrn04		ds.l 0
			finish
	if MOMPASS=6
	if sizeof_scrn02-RAM_Mars_ScrnBuff > MAX_SCRNBUFF
		error "RAN OUT OF RAM FOR MARS SCREEN 02 (\{(sizeof_scrn02-RAM_Mars_ScrnBuff)} of \{(MAX_SCRNBUFF)})"
	elseif sizeof_scrn03-RAM_Mars_ScrnBuff > MAX_SCRNBUFF
		error "RAN OUT OF RAM FOR MARS SCREEN 03 (\{(sizeof_scrn03-RAM_Mars_ScrnBuff)} of \{(MAX_SCRNBUFF)})"
	elseif sizeof_scrn04-RAM_Mars_ScrnBuff > MAX_SCRNBUFF
		error "RAN OUT OF RAM FOR MARS SCREEN 04 (\{(sizeof_scrn04-RAM_Mars_ScrnBuff)} of \{(MAX_SCRNBUFF)})"
	endif
	endif

; ====================================================================
; ----------------------------------------------------------------
; MARS System RAM
; ----------------------------------------------------------------

			struct MarsRam_System
RAM_Mars_DreqDma	ds.b sizeof_dreq	; DREQ data recieved from Genesis in DMA ***DO NOT READ FROM HERE***
RAM_Mars_DreqRead	ds.b sizeof_dreq	; Copy of DREQ for reading.
RAM_Mars_Global		ds.l sizeof_MarsGbl	; gbr values go here
sizeof_marssys		ds.l 0
			finish

; ====================================================================
