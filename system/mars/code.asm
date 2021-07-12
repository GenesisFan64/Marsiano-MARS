; ====================================================================		
; ----------------------------------------------------------------
; MARS SH2 Section
;
; CODE for both CPUs
; RAM and some DATA go here
; ----------------------------------------------------------------

		phase CS3		; now we are at SDRAM
		cpu SH7600		; should be SH7095 but this works too.

; ====================================================================
; ----------------------------------------------------------------
; MARS GBR variables for both SH2
; ----------------------------------------------------------------

			struct 0
marsGbl_BgData		ds.l 1		; Background pixel data location (ROM or RAM)
marsGbl_BgData_R	ds.l 1		; Background data pointer
marsGbl_BgFbPos_R	ds.l 1		; Framebuffer (output) BASE position
marsGbl_PlyPzList_R	ds.l 1		; Current graphic piece to draw
marsGbl_PlyPzList_W	ds.l 1		; Current graphic piece to write
marsGbl_CurrZList	ds.l 1		; Current Zsort entry
marsGbl_CurrFacePos	ds.l 1		; Current top face of the list while reading model data
marsGbl_Bg_Yincr	ds.l 1
marsGbl_BgWidth		ds.w 1
marsGbl_BgHeight	ds.w 1
marsGbl_Bg_Xpos		ds.w 1
marsGbl_Bg_Ypos		ds.w 1
marsGbl_Bg_Xincr	ds.w 1
marsGbl_Bg_Update	ds.w 1
marsGbl_MdlFacesCntr	ds.w 1		; And the number of faces stored on that list
marsGbl_PolyBuffNum	ds.w 1		; PolygonBuffer switch: READ/WRITE or WRITE/READ
marsGbl_PzListCntr	ds.w 1		; Number of graphic pieces to draw
marsGbl_DrwTask		ds.w 1		; Current Drawing task for Watchdog
marsGbl_DrwPause	ds.w 1		; Pause background drawing
marsGbl_VIntFlag_M	ds.w 1		; Sets to 0 if VBlank finished on Master CPU
marsGbl_VIntFlag_S	ds.w 1		; Same thing but for the Slave CPU
marsGbl_DivStop_M	ds.w 1		; Flag to tell Watchdog we are in the middle of hardware division
marsGbl_CurrFb		ds.w 1		; Current framebuffer number
marsGbl_ZSortReq	ds.w 1		; Flag to request Zsort in Slave's watchdog
marsGbl_PwmTrkUpd	ds.w 1		; Flag to update PWM tracks (from Z80 then PWM IRQ)
marsGbl_PalDmaMidWr	ds.w 1		; Flag to tell we are in middle of transfering palette
sizeof_MarsGbl		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MASTER CPU HEADER (vbr)
; ----------------------------------------------------------------

		align 4
SH2_Master:
		dc.l SH2_M_Entry,CS3|$40000	; Cold PC,SP
		dc.l SH2_M_Entry,CS3|$40000	; Manual PC,SP

		dc.l SH2_Error			; Illegal instruction
		dc.l 0				; reserved
		dc.l SH2_Error			; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l SH2_Error			; CPU address error
		dc.l SH2_Error			; DMA address error
		dc.l SH2_Error			; NMI vector
		dc.l SH2_Error			; User break vector

		dc.l 0,0,0,0,0,0,0,0,0,0	; reserved
		dc.l 0,0,0,0,0,0,0,0,0

		dc.l SH2_Error,SH2_Error	; Trap vectors
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error

 		dc.l master_irq			; Level 1 IRQ
		dc.l master_irq			; Level 2 & 3 IRQ's
		dc.l master_irq			; Level 4 & 5 IRQ's
		dc.l master_irq			; PWM interupt
		dc.l master_irq			; Command interupt
		dc.l master_irq			; H Blank interupt
		dc.l master_irq			; V Blank interupt
		dc.l master_irq			; Reset Button
		dc.l master_irq			; Watchdog

; ====================================================================
; ----------------------------------------------------------------
; SLAVE CPU HEADER (vbr)
; ----------------------------------------------------------------

		align 4
SH2_Slave:
		dc.l SH2_S_Entry,CS3|$3F000	; Cold PC,SP
		dc.l SH2_S_Entry,CS3|$3F000	; Manual PC,SP

		dc.l SH2_Error			; Illegal instruction
		dc.l 0				; reserved
		dc.l SH2_Error			; Invalid slot instruction
		dc.l $20100400			; reserved
		dc.l $20100420			; reserved
		dc.l SH2_Error			; CPU address error
		dc.l SH2_Error			; DMA address error
		dc.l SH2_Error			; NMI vector
		dc.l SH2_Error			; User break vector

		dc.l 0,0,0,0,0,0,0,0,0,0	; reserved
		dc.l 0,0,0,0,0,0,0,0,0

		dc.l SH2_Error,SH2_Error	; Trap vectors
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error
		dc.l SH2_Error,SH2_Error

 		dc.l slave_irq			; Level 1 IRQ
		dc.l slave_irq			; Level 2 & 3 IRQ's
		dc.l slave_irq			; Level 4 & 5 IRQ's
		dc.l slave_irq			; PWM interupt
		dc.l slave_irq			; Command interupt
		dc.l slave_irq			; H Blank interupt
		dc.l slave_irq			; V Blank interupt
		dc.l slave_irq			; Reset Button
		dc.l slave_irq			; Watchdog

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

SH2_Error:
		nop
		bra	SH2_Error
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
; 
; Recieve data from Genesis (DREQ-less)
; ------------------------------------------------

m_irq_cmd:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1
		mov.w	r0,@r1
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		stc	sr,@-r15
		mov	#$F0,r0
		ldc	r0,sr

; ; ----------------------------------------
;
; ; 		mov	#_sysreg+comm4,r1	; Check if Z80
; ; 		mov.b	@(0,r1),r0		; called first
; ; 		cmp/eq	#0,r0
; ; 		bf	.pwm_play
;
; ; ----------------------------------------
; ; Transfer from 68K
; ; ----------------------------------------
;
; 		mov	#_sysreg+comm8,r1
; 		mov	#RAM_Mars_MdTasksFifo_M,r2
; 		mov	#_sysreg+comm14,r3	; Also process tasks
; 		mov.b	@r3,r0			; after this
; 		or	#$80,r0
; 		mov.b	r0,@r3
; .next_comm:
; 		mov	#2,r0		; SH is ready
; 		mov.b	r0,@(1,r1)
; .wait_md_b:
; 		mov.b	@(0,r1),r0	; get MD status
; 		cmp/eq	#0,r0
; 		bt	.finish
; 		and	#$80,r0
; 		cmp/eq	#0,r0		; is MD busy?
; 		bt	.wait_md_b
; 		mov	#1,r0		; SH is busy
; 		mov.b	r0,@(1,r1)
; .wait_md_c:
; 		mov.b	@(0,r1),r0
; 		cmp/eq	#0,r0
; 		bt	.finish
; 		and	#$40,r0
; 		cmp/eq	#$40,r0		; MD ready?
; 		bf	.wait_md_c
; 		mov.w	@(2,r1),r0	; comm10
; 		mov.w	r0,@r2
; 		mov.w	@(4,r1),r0	; comm12
; 		mov.w	r0,@(2,r2)
; 		bra	.next_comm
; 		add	#4,r2

; ; ----------------------------------------
; ; Transfer from Z80
; ; ----------------------------------------
; 
; .pwm_play:
; 		cmp/eq	#$20,r0
; 		bt	.finish_s
; 		mov	#MarsSnd_PwmTrkData,r2
; 		cmp/eq	#$21,r0
; 		bt	.next_commz
; 		mov	#MarsSnd_PwmPlyData,r2
; 		add	#-1,r0
; 		and	#%11111,r0
; 		shll2	r0
; 		shll	r0
; 		add	r0,r2
; .next_commz:
; 		mov	#2,r0		; SH is ready
; 		mov.b	r0,@(1,r1)
; .wait_z_b:
; 		mov.b	@(0,r1),r0	; get Z80 status
; 		cmp/eq	#0,r0
; 		bt	.finish_s
; 		and	#$80,r0
; 		cmp/eq	#0,r0		; is Z80 busy?
; 		bt	.wait_z_b
; 		mov	#1,r0		; SH is busy
; 		mov.b	r0,@(1,r1)
; .wait_z_c:
; 		mov.b	@(0,r1),r0
; 		cmp/eq	#0,r0
; 		bt	.finish_s
; 		and	#$40,r0
; 		cmp/eq	#$40,r0		; Z80 ready?
; 		bf	.wait_z_c
; 		mov.w	@(2,r1),r0	; word write.
; 		mov.w	r0,@r2
; 		bra	.next_commz
; 		add	#2,r2
; 		align 4
; 
; ; ----------------------------------------
; 
; .finish_s:
; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_PwmTrkUpd,gbr)
; 		mov	#$80,r0
; 		mov.b	r0,@(1,r1)

.finish:
		ldc 	@r15+,sr
		mov 	@r15+,r4
		mov 	@r15+,r3
		mov 	@r15+,r2
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

	; Hardware BUG:
	; Using DMA to transfer palette
	; to _palette works on the first pass
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
; 		mov	r5,@-r15
		sts	macl,@-r15
		mov	#$F0,r0			; Disable interrupts
		ldc	r0,sr

	; X/Y scroll position
		mov	#1,r1				; X increment
		mov	#1,r2				; Y increment

; 	; Y scroll
		mov.w	@(marsGbl_BgWidth,gbr),r0
		mov	r0,r4
		mov.w	@(marsGbl_BgHeight,gbr),r0
		mov	r0,r3
		mov.w	@(marsGbl_Bg_Ypos,gbr),r0
		add	r2,r0
		cmp/pz	r2
		bf	.yneg
		cmp/ge	r3,r0
		bf	.ydwn
		sub	r3,r0
.ydwn:
		cmp/pz	r2
		bt	.yposc
.yneg:
		cmp/pl	r0
		bt	.yposc
		add	r3,r0
.yposc:
		mov.w	r0,@(marsGbl_Bg_Ypos,gbr)
		mulu	r4,r0
		sts	macl,r0
		mov	r0,@(marsGbl_Bg_Yincr,gbr)

	; X move
		mov.w	@(marsGbl_BgWidth,gbr),r0
		mov	r0,r2
		mov.w	@(marsGbl_Bg_Xpos,gbr),r0
		add	r1,r0
		mov	r0,r4
		tst	#%11111000,r0				; X Halfway?
		bt	.dontrgr
		mov.w	@(marsGbl_Bg_Xincr,gbr),r0
		cmp/pz	r1
		bf	.negtv
		add	#$08,r0
		cmp/gt	r2,r0
		bf	.negtv
		sub	r2,r0
.negtv:
		cmp/pz	r1
		bt	.postv
		add	#-$08,r0
		cmp/pz	r0
		bt	.postv
		add	r2,r0
.postv:
		mov.w	r0,@(marsGbl_Bg_Xincr,gbr)
.dontrgr:
		mov	r4,r0
		mov	#$07,r2
		and	r2,r4
		mov	#_vdpreg+shift,r2
		and	#1,r0
		mov.w	r0,@r2
		mov	r4,r0
		mov.w	r0,@(marsGbl_Bg_Xpos,gbr)

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

; 		mov	#1,r1
; 		mov	#MarsVideo_MoveBgX,r0
; 		jsr	@r0

; 		mov	@r15+,r5
		lds	@r15+,macl
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
; Master | Watchdog interrupt
; ------------------------------------------------

; m_irq_custom:
; MOVED: see cache.asm

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
; Recieve data from Genesis
; ------------------------------------------------

s_irq_cmd:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+cmdintclr,r1
		mov.w	r0,@r1
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		stc	sr,@-r15
		mov	#$F0,r0
		ldc	r0,sr

; ----------------------------------------
; Transfer from 68K
; ----------------------------------------

; 		mov	#_sysreg+comm8,r1
; 		mov	#RAM_Mars_MdTasksFifo_S,r2
; 		mov	#_sysreg+comm15,r3	; Also process tasks
; 		mov.b	@r3,r0			; after this
; 		or	#$80,r0
; 		mov.b	r0,@r3
; .next_comm:
; 		mov	#2,r0		; SH is ready
; 		mov.b	r0,@(1,r1)
; .wait_md_b:
; 		mov.b	@(0,r1),r0	; get MD status
; 		cmp/eq	#0,r0
; 		bt	.finish
; 		and	#$80,r0
; 		cmp/eq	#0,r0		; is MD busy?
; 		bt	.wait_md_b
; 		mov	#1,r0		; SH is busy
; 		mov.b	r0,@(1,r1)
; .wait_md_c:
; 		mov.b	@(0,r1),r0
; 		cmp/eq	#0,r0
; 		bt	.finish
; 		and	#$40,r0
; 		cmp/eq	#$40,r0		; MD ready?
; 		bf	.wait_md_c
; 		mov.w	@(2,r1),r0	; comm10
; 		mov.w	r0,@r2
; 		mov.w	@(4,r1),r0	; comm12
; 		mov.w	r0,@(2,r2)
; 		bra	.next_comm
; 		add	#4,r2
; .finish:
		ldc 	@r15+,sr
		mov 	@r15+,r4
		mov 	@r15+,r3
		mov 	@r15+,r2
		rts
		nop
		align 4
		ltorg
		
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
		mov.l   #$FFFFFEE2,r0			; Watchdog: Set interrupt priority bits (IPRA)
		mov     #%0101<<4,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1			; Watchdog: Set jump pointer (VBR + this/4) (WITV)
		shll8   r1
		mov.w   r1,@r0

; ------------------------------------------------
; Wait for Genesis and Slave CPU
; ------------------------------------------------

.wait_md:
		mov 	#_sysreg+comm0,r2		; Wait for Genesis
		mov.l	@r2,r0
		cmp/eq	#0,r0
		bf	.wait_md
		mov.l	#"SLAV",r1
.wait_slave:
		mov.l	@(8,r2),r0			; Wait for Slave CPU to finish booting
		cmp/eq	r1,r0
		bf	.wait_slave
		mov.l	#0,r0				; clear "SLAV"
		mov.l	r0,@(8,r2)
		mov.l	r0,@r2
		
; ====================================================================
; ----------------------------------------------------------------
; Master main code
; 
; This CPU is exclusively used for visual tasks:
; Polygons, Sprites, Backgrounds...
;
; To interact with the models use the Slave CPU and request
; a drawing task there
; ----------------------------------------------------------------

SH2_M_HotStart:
		mov	#CS3|$40000,r15				; Stack again if coming from RESET
		mov	#RAM_Mars_Global,r14			; GBR - Global values/variables
		ldc	r14,gbr
		mov	#$F0,r0					; Interrupts OFF
		ldc	r0,sr
		mov.l	#_CCR,r1
		mov	#%00001000,r0				; Cache OFF
		mov.w	r0,@r1
		mov	#%00011001,r0				; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r1
		mov	#_sysreg,r1
		mov	#VIRQ_ON|CMDIRQ_ON,r0			; Enable usage of these interrupts
    		mov.b	r0,@(intmask,r1)			; (Watchdog is external)
		mov 	#CACHE_MASTER,r1			; Transfer Master's fast-code to CACHE
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


	; TEMPORAL SETUP
		mov	#TESTMARS_BG_PAL,r1			; Load palette
		mov	#0,r2
		mov	#256,r3
		mov	#$8000,r4
		mov	#MarsVideo_LoadPal,r0
		jsr	@r0
		nop

		mov	#TESTMARS_BG,r1
		mov	#500,r2
		mov	#375,r3

		mov	r1,r0
		mov	r0,@(marsGbl_BgData,gbr)
		mov	r2,r0
		mov.w	r0,@(marsGbl_BgWidth,gbr)
		mov	r3,r0
		mov.w	r0,@(marsGbl_BgHeight,gbr)

; 		mov	#TESTMARS_BG,r1
; 		mov	#MarsVideo_TempDraw,r0
; 		jsr	@r0
; 		nop
; 		mov	#MarsVideo_DrawAllBg,r0
; 		jsr	@r0
; 		nop
		mov 	#_vdpreg,r1
.wait_fb:	mov.w   @($A,r1),r0
		tst     #2,r0
		bf      .wait_fb
		mov	#1,r0
		mov.b	r0,@(bitmapmd,r1)

		mov.l	#$20,r0				; Interrupts ON
		ldc	r0,sr

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

master_loop:
		mov	#_CCR,r1			; <-- Required for Watchdog
		mov	#%00001000,r0			; Two-way mode
		mov.w	r0,@r1
		mov	#%00011001,r0			; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r1
		mov	#MarsVideo_SetWatchdog,r0
		jsr	@r0
		nop
		
; 	; While we are doing this, the watchdog is
; 	; working on the background drawing the polygons
; 	; using the "pieces" list
; 	;
; 	; r14 - Polygon pointers list
; 	; r13 - Number of polygons to build
; 		mov.w   @(marsGbl_PolyBuffNum,gbr),r0	; Start drawing polygons from the READ buffer
; 		tst     #1,r0				; Check for which buffer to use
; 		bt	.page_2
; 		mov 	#RAM_Mars_Plgn_ZList_0,r14
; 		mov	#RAM_Mars_PlgnNum_0,r13
; 		bra	.cont_plgn
; 		nop
; .page_2:
; 		mov 	#RAM_Mars_Plgn_ZList_1,r14
; 		mov	#RAM_Mars_PlgnNum_1,r13
; 		nop
; 		nop
; .cont_plgn:
; 		mov.w	@r13,r13			; read from memory to register
; 		cmp/pl	r13				; zero?
; 		bf	.skip
; .loop:
; 		mov	r14,@-r15
; 		mov	r13,@-r15
; 		mov	@(4,r14),r14			; Get location of the polygon
; 		cmp/pl	r14				; Zero?
; 		bf	.invalid			; if yes, skip
; 		mov 	#MarsVideo_SlicePlgn,r0
; 		jsr	@r0
; 		nop
; .invalid:
; 		mov	@r15+,r13
; 		mov	@r15+,r14
; 		dt	r13				; Decrement numof_polygons
; 		bf/s	.loop
; 		add	#8,r14				; Move to next entry
; .skip:

; 		mov	#3000,r0
; .hastewey:
; 		dt	r0
; 		bf	.hastewey

	; --------------------------------------
; .wait_pz: 	mov.w	@(marsGbl_PzListCntr,gbr),r0	; Any pieces remaining on Watchdog?
; 		cmp/eq	#0,r0
; 		bf	.wait_pz
.wait_task:	mov.w	@(marsGbl_DrwTask,gbr),r0	; Any drawing task active?
		cmp/eq	#0,r0
		bf	.wait_task
		mov.l   #$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		mov	#_vdpreg,r1
.waitfb:	mov.w	@(vdpsts,r1),r0			; Wait until any line-fill finishes.
		tst	#%10,r0
		bf	.waitfb
		mov.b	@(framectl,r1),r0		; Frameswap request, Next Watchdog will
		xor	#1,r0				; check for it later.
		mov.b	r0,@(framectl,r1)		; Save new bit
		mov.b	r0,@(marsGbl_CurrFb,gbr)	; And a copy for checking

; 	; --------------------
; 	; DEBUG counter
; 		mov	#tempcntr,r2
; 		mov	@r2,r0
; 		add	#1,r0
; 		mov	r0,@r2
; 	; --------------------
;
; 		mov	#_sysreg+comm14,r1		; Clear task number
; 		mov.b	@r1,r0
; 		and	#$80,r0
; 		mov.b	r0,@r1

		bra	master_loop
		nop
		align 4
		ltorg

; 	; --------------------
; 	; DEBUG counter
; ; 		mov	#_sysreg+comm2,r4		; DEBUG COUNTER
; ; 		mov.b	@r4,r0
; ; 		add	#1,r0
; ; 		mov.b	r0,@r4
; 	; --------------------
;
; 		mov	#_sysreg+comm14,r1
; 		mov.b	@r1,r0
; 		mov	r0,r2
; 		and 	#$80,r0
; 		cmp/eq	#0,r0			; Genesis requested tasks? (bit 7)
; 		bf	.md_req			; If yes, process them first.
; 		mov	r2,r0			; OR Process tasks from Slave SH2
; 		and	#$7F,r0
; 		shll2	r0
; 		mov	#.list,r1
; 		mov	@(r1,r0),r0
; 		jmp	@r0
; 		nop
; 		align 4
;
; ; ------------------------------------------------
; ; Graphic processing list for Master
; ; ------------------------------------------------
;
; .list:
; 		dc.l .draw_objects	; Null task
; 		dc.l .draw_objects
; 		dc.l master_loop
;
; ; ------------------------------------------------
; ; Process Visual/Audio requests from Genesis
; ; ------------------------------------------------
;
; .md_req:
; 		stc	sr,@-r15
; 		mov	#$F0,r0			; Disable interrupts
; 		ldc	r0,sr
; 		mov	#MAX_MDTASKS,r13
; 		mov	#RAM_Mars_MdTasksFifo_M,r14
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
; 		mov	#_sysreg+comm14,r1
; 		mov.b	@r1,r0
; 		and	#$7F,r0
; 		mov.b	r0,@r1
; 		ldc 	@r15+,sr		; Re-enable interrupts
; 		bra	master_loop
; 		nop
;
; ; --------------------------------------------------------
; ; Drawing task $01
; ;
; ; Polygons mode
; ; --------------------------------------------------------

; .draw_objects:

; ====================================================================
; ----------------------------------------------------------------
; Slave entry
; ----------------------------------------------------------------

		align 4
SH2_S_Entry:
		mov.l	#CS3|$3F000,r15			; Reset stack
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
		mov.l   #$FFFFFEE2,r0			; Watchdog: Set interrupt priority bits (IPRA)
		mov     #%0101<<4,r1
		mov.w   r1,@r0
		mov.l   #$FFFFFEE4,r0
		mov     #$120/4,r1			; Watchdog: Set jump pointer (VBR + this/4) (WITV)
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
		mov	#CMDIRQ_ON|PWMIRQ_ON,r0		; Enable these interrupts
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
; 		mov	#0,r1
; 		mov	#PWM_STEREO,r2
; 		mov	#PWM_STEREO_e,r3
; 		mov	#0,r4
; 		mov	#$100,r5
; 		mov	#0,r6
; 		mov	#%11|%10000000,r7
; 		mov	#MarsSound_SetPwm,r0
; 		jsr	@r0
; 		nop
; 		mov	#1,r1
; 		mov	#PWM_STEREO,r2
; 		mov	#PWM_STEREO_e,r3
; 		mov	#0,r4
; 		mov	#$100,r5
; 		mov	#0,r6
; 		mov	#%11|%10000000,r7
; 		mov	#MarsSound_SetPwm,r0
; 		jsr	@r0
; 		nop
		mov.l	#$20,r0				; Interrupts ON
		ldc	r0,sr

; --------------------------------------------------------
; Loop
; --------------------------------------------------------

		mov	#-1,r0
slave_loop:
		nop
		nop
		nop
		nop
		nop
		nop
		add	#1,r1
		bra	slave_loop
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
; 		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
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
; 		mov	#MAX_FACES,r1
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
; 		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
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
; 		mov.w	@(marsGbl_PolyBuffNum,gbr),r0	; Swap polygon buffer
;  		xor	#1,r0
;  		mov.w	r0,@(marsGbl_PolyBuffNum,gbr)
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
; 	move.w	#16,d3
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

; ------------------------------------------------
; Make new object and insert it to specific slot
;
; @($04,r14) - Object slot
; @($08,r14) - Object data
; @($0C,r14) - Object animation data
; @($10,r14) - Object animation speed
; @($14,r14) - Object options:
;	       %????????????????????????pppppppp
;		p - index pixel increment value
; ------------------------------------------------

CmdTaskMd_ObjectSet:
		mov	#RAM_Mars_Objects+(sizeof_mdlobj*9),r12
		mov	r14,r13
		add	#4,r13
		mov	@r13+,r0
		mov	#sizeof_mdlobj,r1
		mulu	r1,r0
		sts	macl,r0
		add	r0,r12
		xor	r0,r0
		mov	@r13+,r1
		mov	r1,@(mdl_data,r12)
		mov	@r13+,r1
		mov	r1,@(mdl_animdata,r12)
		mov	@r13+,r1
		mov	r1,@(mdl_animspd,r12)
		mov	@r13+,r1
		mov	r1,@(mdl_option,r12)
		xor	r0,r0
		mov	r0,@(mdl_x_pos,r12)
		mov	r0,@(mdl_y_pos,r12)
		mov	r0,@(mdl_z_pos,r12)
		mov	r0,@(mdl_x_rot,r12)
		mov	r0,@(mdl_y_rot,r12)
		mov	r0,@(mdl_z_rot,r12)
		mov	r0,@(mdl_animframe,r12)
		mov	r0,@(mdl_animtimer,r12)
		rts
		nop
		align 4
		
; ------------------------------------------------
; Move/Rotate object from slot
; 
; @($04,r14) - Object slot
; @($08,r14) - Object X pos
; @($0C,r14) - Object Y pos
; @($10,r14) - Object Z pos
; @($14,r14) - Object X rot
; @($18,r14) - Object Y rot
; @($1C,r14) - Object Z rot
; ------------------------------------------------

CmdTaskMd_ObjectPos:
		mov	#RAM_Mars_Objects+(sizeof_mdlobj*9),r12
		mov	r14,r13
		add	#4,r13
		mov	@r13+,r0
		mov	#sizeof_mdlobj,r1
		mulu	r1,r0
		sts	macl,r0
		add	r0,r12
		mov	@r13+,r1
		mov	@r13+,r2
		mov	@r13+,r3
		mov	@r13+,r4
		mov	@r13+,r5
		mov	@r13+,r6
		mov	r1,@(mdl_x_pos,r12)
		mov	r2,@(mdl_y_pos,r12)
		mov	r3,@(mdl_z_pos,r12)
		mov	r4,@(mdl_x_rot,r12)
		mov	r5,@(mdl_y_rot,r12)
		mov	r6,@(mdl_z_rot,r12)
		rts
		nop
		align 4

; ------------------------------------------------
; Clear ALL objects, including layout
; ------------------------------------------------

CmdTaskMd_ObjectClrAll:
		sts	pr,@-r15
		mov	#MarsMdl_Init,r0
		jsr	@r0
		nop
		lds	@r15+,pr
		rts
		nop
		align 4

; ------------------------------------------------
; Set new map data
; 
; @($04,r14) - layout data (set to 0 to clear)
; ------------------------------------------------

CmdTaskMd_MakeMap:
		sts	pr,@-r15
; 		bsr	MarsVideo_ClearFrame
; 		nop
		mov	@(4,r14),r1
		mov	#MarsLay_Make,r0
		jsr	@r0
		mov	r14,@-r15
		mov	@r15+,r14
		lds	@r15+,pr
		rts
		nop
		align 4
		
; ------------------------------------------------
; Set camera position
; 
; @($04,r14) - Camera slot (TODO)
; @($08,r14) - Camera X pos
; @($0C,r14) - Camera Y pos
; @($10,r14) - Camera Z pos
; @($14,r14) - Camera X rot
; @($18,r14) - Camera Y rot
; @($1C,r14) - Camera Z rot
; ------------------------------------------------

CmdTaskMd_CameraPos:
		mov	#RAM_Mars_ObjCamera,r12
		mov	r14,r13
		add	#8,r13
		mov	@r13+,r1
		mov	@r13+,r2
		mov	@r13+,r3
		mov	@r13+,r4
		mov	@r13+,r5
		mov	@r13+,r6
		mov	r1,@(cam_x_pos,r12)
		mov	r2,@(cam_y_pos,r12)
		mov	r3,@(cam_z_pos,r12)
		mov	r4,@(cam_x_rot,r12)
		mov	r5,@(cam_y_rot,r12)
		mov	r6,@(cam_z_rot,r12)
		rts
		nop
		align 4

; ------------------------------------------------
; Set camera position
; 
; @($04,r14) - Camera slot (TODO)
; @($08,r14) - Camera X pos
; @($0C,r14) - Camera Y pos
; @($10,r14) - Camera Z pos
; @($14,r14) - Camera X rot
; @($18,r14) - Camera Y rot
; @($1C,r14) - Camera Z rot
; ------------------------------------------------

CmdTaskMd_UpdModels:
		mov	#_sysreg+comm15,r1
		mov	#1,r2
		mov.b	@r1,r0
		and	#$80,r0
		or	r2,r0
		mov.b	r0,@r1
		rts
		nop
		align 4

; ------------------------------------------------
; Set PWM to play
;
; @($04,r14) - Channel slot
; @($08,r14) - Start point
; @($0C,r14) - End point
; @($10,r14) - Loop point
; @($14,r14) - Pitch
; @($18,r14) - Volume
; @($1C,r14) - Settings: %00000000 00000000LR | LR - output bits
; ------------------------------------------------

CmdTaskMd_PWM_SetChnl:
		sts	pr,@-r15
		mov	@($04,r14),r1
		mov	@($08,r14),r2
		mov	@($0C,r14),r3
		mov	@($10,r14),r4
		mov	@($14,r14),r5
		mov	@($18,r14),r6
		mov	@($1C,r14),r7
		bsr	MarsSound_SetPwm
		nop
		lds	@r15+,pr
		rts
		nop
		align 4

; ------------------------------------------------
; Set PWM pitch to multiple channels
;
; @($04,r14) - Channel 0 pitch
; @($08,r14) - Channel 1 pitch
; @($0C,r14) - Channel 2 pitch
; @($10,r14) - Channel 3 pitch
; @($14,r14) - Channel 4 pitch
; @($18,r14) - Channel 5 pitch
; @($1C,r14) - Channel 6 pitch
; ------------------------------------------------

CmdTaskMd_PWM_MultPitch:
		sts	pr,@-r15
		mov	#$FFFF,r7
		mov	r14,r13
		add	#4,r13
		mov	#0,r1
	rept MAX_PWMCHNL		; MAX: 7
		mov	@r13+,r2
		and	r7,r2
		bsr	MarsSound_SetPwmPitch
		nop
		add	#1,r1
	endm
		lds	@r15+,pr
		rts
		nop
		align 4

; ------------------------------------------------
; Enable/Disable PWM channels from playing
;
; @($04,r14) - Channel slot
; @($08,r14) - Enable/Disable/Restart
; ------------------------------------------------

CmdTaskMd_PWM_Enable:
		sts	pr,@-r15
		mov	@($04,r14),r1
		mov	@($08,r14),r2
		bsr	MarsSound_PwmEnable
		nop
		lds	@r15+,pr
		rts
		nop
		align 4

; ----------------------------------------

		ltorg

; =================================================================
; ------------------------------------------------
; Slave | Watchdog interrupt
; ------------------------------------------------

s_irq_custom:
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	#_FRT,r1
		mov.b   @(7,r1),r0
		xor     #2,r0
		mov.b   r0,@(7,r1)
		mov.w	@(marsGbl_ZSortReq,gbr),r0
		cmp/eq	#1,r0
		bf	.no_req

	; DONT CALL THIS
	; IF NUMOF FACES < 2
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0
		mov	r0,r2
		mov	#3,r1
		cmp/gt	r1,r2
		bf	.no_faces
		mov	#RAM_Mars_Plgn_ZList_0,r3
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bt	.page_2
		mov	#RAM_Mars_Plgn_ZList_1,r3
.page_2:
		mov	r2,r4
		add	#-2,r4
		cmp/pz	r4
		bf	.no_req
.z_next:
		mov	@r3,r0
		mov	@(8,r3),r1
		cmp/gt	r1,r0
		bf	.z_keep
		mov	r1,@r3
		mov	r0,@(8,r3)
		mov	@(4,r3),r0
		mov	@($C,r3),r1
		mov	r1,@(4,r3)
		mov	r0,@($C,r3)
.z_keep:
		dt	r4
		bf/s	.z_next
		add	#8,r3
.no_faces:
		mov	#0,r0
		mov.w	r0,@(marsGbl_ZSortReq,gbr)

.no_req:
		mov	#$FFFFFE80,r1
		mov.w   #$A518,r0		; Watchdog OFF
		mov.w   r0,@r1
		or      #$20,r0			; ON again
		mov.w   r0,@r1
		mov	#1,r2
		mov.w   #$5A00,r0		; Timer for the next one
		or	r2,r0
		mov.w	r0,@r1

		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
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
MarsRam_Sound	ds.l 0
sizeof_marsram	ds.l 0
	else
MarsRam_System	ds.b (sizeof_marssys-MarsRam_System)
MarsRam_Video	ds.b (sizeof_marsvid-MarsRam_Video)
MarsRam_Sound	ds.b (sizeof_marssnd-MarsRam_Sound)
sizeof_marsram	ds.l 0
	endif

.here:
	if MOMPASS=6
		message "MARS RAM from \{((SH2_RAM)&$FFFFFF)} to \{((.here)&$FFFFFF)}"
	endif
		finish

; ====================================================================
; ----------------------------------------------------------------
; MARS Sound RAM
; ----------------------------------------------------------------

			struct MarsRam_Sound
MarsSnd_PwmChnls	ds.b sizeof_sndchn*MAX_PWMCHNL
; MarsSnd_PwmTrkData	ds.b $80*2
MarsSnd_PwmPlyData	ds.l 7
sizeof_marssnd		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MARS Video RAM
; ----------------------------------------------------------------

			struct MarsRam_Video
; RAM_Mars_Background	ds.b 336*232			; Third background
RAM_Mars_Palette	ds.w 256			; Indexed palette
RAM_Mars_ObjCamera	ds.b sizeof_camera		; Camera buffer
RAM_Mars_ObjLayout	ds.b sizeof_layout		; Layout buffer
RAM_Mars_Objects	ds.b sizeof_mdlobj*MAX_MODELS	; Objects list
RAM_Mars_Polygons_0	ds.b sizeof_polygn*MAX_FACES	; Polygon list 0
RAM_Mars_Polygons_1	ds.b sizeof_polygn*MAX_FACES	; Polygon list 1
RAM_Mars_VdpDrwList	ds.b sizeof_plypz*MAX_SVDP_PZ	; Pieces list
RAM_Mars_VdpDrwList_e	ds.l 0				; (end-of-list label)
RAM_Mars_Plgn_ZList_0	ds.l MAX_FACES*2		; Z value / foward faces
RAM_Mars_Plgn_ZList_1	ds.l MAX_FACES*2		; Z value / foward faces
RAM_Mars_PlgnNum_0	ds.w 1				; Number of polygons to read, both buffers
RAM_Mars_PlgnNum_1	ds.w 1				;
; RAM_Mars_Bg_X		ds.w 1
; RAM_Mars_Bg_XHead	ds.w 1
; RAM_Mars_Bg_Y		ds.w 1
sizeof_marsvid		ds.l 0
			finish

; ====================================================================
; ----------------------------------------------------------------
; MARS System RAM
; ----------------------------------------------------------------

			struct MarsRam_System
RAM_Mars_Global		ds.w sizeof_MarsGbl		; keep it as a word
sizeof_marssys		ds.l 0
			finish
