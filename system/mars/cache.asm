; ====================================================================
; ----------------------------------------------------------------
; CACHE code for Master CPU
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_MASTER:
		phase $C0000000

; ------------------------------------------------
; Watchdog tasks
; ------------------------------------------------

; Cache_OnInterrupt:
m_irq_custom:
		mov	.tag_FRT,r1
		mov.b	@(7,r1), r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		rts
		nop
		align 4
.tag_FRT:	dc.l _FRT

; ---------------------------------------
; DREQ DMA Transfer, might perform
; better here...
; ---------------------------------------

Mars_DoDreq:
		mov	#_sysreg,r4
		mov	#_DMASOURCE0,r3
		mov	#_sysreg+comm14,r2
		mov	#%0100010011100000,r0	; Transfer mode but DMA enable bit is 0
		mov	r0,@($C,r3)
		mov	@(marsGbl_DreqRead,gbr),r0
		mov	r0,r1
		mov	@(marsGbl_DreqWrite,gbr),r0
		mov	r0,@(marsGbl_DreqRead,gbr)
		mov	r1,r0
		mov	r0,@(marsGbl_DreqWrite,gbr)
		mov	#_sysreg+dreqfifo,r1
		mov	r1,@r3			; Source
		mov	r0,@(4,r3)		; Destination
		mov.w	@(dreqlen,r4),r0
		mov	r0,@(8,r3)		; Length
		mov.b	@r2,r0
		or	#%00100000,r0		; Tell MD we are ready.
		mov.b	r0,@r2
		mov	@($C,r3),r0		; dummy readback(?)
		mov	#%0100010011100001,r0	; Transfer mode: + DMA enable
		mov	r0,@($C,r3)		; Dest:IncFwd(01) Src:Stay(00) Size:Word(01)
		mov	#1,r0			; _DMAOPERATION = 1
		mov	r0,@($30,r3)
; .wait_dma:
; 		mov	@($C,r3),r0		; Wait until DMA finishes
; 		and	#%10,r0
; 		tst	r0,r0
; 		bt	.wait_dma
		rts
		nop
		align 4

; ---------------------------------------
; Draw Left/Right sections
; ---------------------------------------

MarsVideo_BgDrawLR:
		mov	#RAM_Mars_Background,r14
		mov	@(mbg_data,r14),r0
		cmp/pl	r0
		bf	.nxt_drawud
		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r13
		mov.w	@(mbg_intrl_blk,r14),r0
		neg	r0,r4
		shlr2	r0
		mov	r0,r12
		mov	#Cach_BgFbPos_H,r11
		mov	@r11,r11
		mov	#Cach_BgFbPos_V,r3
		mov	@r3,r3
		mov.w	@(mbg_intrl_w,r14),r0
		muls	r3,r0
		sts	macl,r0
		add	r0,r11
		mov	@(mbg_intrl_size,r14),r10
		mov	@(mbg_fbdata,r14),r9
		mov	#_framebuffer,r0
		add	r0,r9
		mov	@(mbg_data,r14),r0
		mov	r0,r8
		mov	r0,r7
		mov.w	@(mbg_height,r14),r0
		mov	r0,r6
		mov.w	@(mbg_width,r14),r0
		mulu	r6,r0
		sts	macl,r6
		add	r7,r6
		mov	r0,r3
		mov	#Cach_YHead_U,r0
		mov	@r0,r0
		mulu	r3,r0
		sts	macl,r0
		add	r0,r8
		mov	#Cach_Drw_R,r1
		mov	#Cach_Drw_L,r2
		mov	@r1,r0
		cmp/eq	#0,r0
		bf	.dtsk01_dright
		mov	@r2,r0
		cmp/eq	#0,r0
		bf	.dtsk01_dleft
.nxt_drawud:
		rts
		nop
		align 4

.dtsk01_dleft:
		dt	r0
		mov	r0,@r2
		mov	#Cach_XHead_L,r0
		mov	@r0,r0
		bra	dtsk01_lrdraw
		mov	r0,r5
.dtsk01_dright:
		dt	r0
		mov	r0,@r1
		mov	#320,r3			; Set FB position
		mov.b	@(mbg_flags,r14),r0
		and	#1,r0
		tst	r0,r0
		bt	.indxmode
		shll	r3
.indxmode:
		add	r3,r11
		and	r4,r11
		mov	#Cach_XHead_R,r0
		mov	@r0,r0
		bra	dtsk01_lrdraw
		mov	r0,r5
		align 4
		ltorg

	; r13 - Y lines
	; r12 - X block width
	; r11 - drawzone pos
	; r10 - drawzone size
	;  r9 - Framebuffer BASE
	;  r8 - Pixeldata Y-Current
	;  r7 - Pixeldata Y-Start
	;  r6 - Pixeldata Y-End
	;  r5 - Xadd
dtsk01_lrdraw:
		cmp/ge	r6,r8
		bf	.yres
		mov	r7,r8
.yres:
		mov	r12,r4
		mov	r11,r3
		mov	r8,r2
		add	r5,r2
; X draw
.xline:
		cmp/ge	r10,r3
		bf	.prefix_r
		sub	r10,r3
		mov	r3,r11
.prefix_r:
		mov	r3,r1
		add	r9,r1
		mov	@r2,r0
		mov	r0,@r1
		mov	#320,r1			; Hidden line
		mov.b	@(mbg_flags,r14),r0
		and	#1,r0
		tst	r0,r0
		bt	.indxmode
		shll	r1
.indxmode:
		cmp/gt	r1,r3
		bt	.not_l2
		mov	r3,r1
		add	r9,r1
		add	r10,r1
		mov	@r2,r0
		mov	r0,@r1
.not_l2:
		add	#4,r2
		dt	r4
		bf/s	.xline
		add	#4,r3
		mov.w	@(mbg_width,r14),r0
		add	r0,r8
		mov.w	@(mbg_intrl_w,r14),r0
		dt	r13
		bf/s	dtsk01_lrdraw
		add	r0,r11
		rts
		nop
		align 4

; ---------------------------------------
; Draw Up/Down sections
; ---------------------------------------

MarsVideo_BgDrawUD:
		mov	@(mbg_fbdata,r14),r13
		mov	#_framebuffer,r0
		add	r0,r13
		mov	@(mbg_data,r14),r0
		mov	r0,r11
		mov	r0,r12
		mov	#Cach_BgFbPos_H,r0
		mov	@r0,r10
		mov	#Cach_BgFbPos_V,r0
		mov	@r0,r9
		mov	@(mbg_intrl_size,r14),r8
		mov.w	@(mbg_width,r14),r0
		mov	r0,r7
; 		mov.b	@(mbg_flags,r14),r0
; 		and	#1,r0
; 		tst	r0,r0
; 		bt	.indxmodew
; 		shll	r7
; .indxmodew:
		mov	#Cach_XHead_L,r0
		mov	@r0,r0
		add	r0,r12
		mov	r9,r6

		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r5
		mov	r0,r4
		mov.w	@(mbg_intrl_blk,r14),r0
		sub	r0,r4
		add	r4,r6
.wrpagain:	cmp/gt	r5,r6
		bf	.upwrp
		bra	.wrpagain
		sub	r5,r6
.upwrp:
		mov	#Cach_Drw_U,r1
		mov	#Cach_Drw_D,r2
		mov	@r1,r0
		cmp/eq	#0,r0
		bf	.tsk00_up
		mov	@r2,r0
		cmp/eq	#0,r0
		bt	drw_ud_exit
.tsk00_down:
		dt	r0
		mov	r0,@r2

		mov	#Cach_YHead_D,r0
		mov	@r0,r0
		mulu	r7,r0
		sts	macl,r0
		add	r0,r12
		add	r0,r11
		bra	.do_updown
		mov	r6,r9
.tsk00_up:
		dt	r0
		mov	r0,@r1
		mov	#Cach_YHead_U,r0
		mov	@r0,r0
		mulu	r7,r0
		sts	macl,r0
		add	r0,r12
		add	r0,r11

	; Main U/D loop
	; r12 - pixel-data current pos
	; r11 - pixel-data loop pos
	; r10 - Internal scroll TOPLEFT
	; r9 - Internal scroll Y-add
	; r8 - Internal scroll drawarea size
	; r7 - pixel-data WIDTH
.do_updown:
		mov.w	@(mbg_intrl_w,r14),r0
		mulu	r9,r0
		sts	macl,r0
		add	r0,r10
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r6
.y_loop:
		mov	r12,r3
		mov	r11,r4
		add	r7,r4
		mov.w	@(mbg_intrl_w,r14),r0	; WIDTH / 4
		shlr2	r0
		mov	r0,r5
.x_loop:
		cmp/ge	r8,r10			; topleft fb pos
		bf	.lwrfb
		sub	r8,r10
.lwrfb:
		cmp/ge	r4,r3
		bf	.srclow
		mov	r11,r3
.srclow:
		mov	@r3+,r1
		mov	r10,r2
		add	r13,r2
		mov	r1,r0
		mov	r0,@r2

		mov	#320,r2			; Hidden line
		mov.b	@(mbg_flags,r14),r0
		and	#1,r0
		tst	r0,r0
		bt	.indxmode
		shll	r2
.indxmode:
		cmp/gt	r2,r10
		bt	.hdnx
		mov	r10,r2
		add	r13,r2
		add	r8,r2
		mov	r1,r0
		mov	r0,@r2
.hdnx
		dt	r5
		bf/s	.x_loop
		add	#4,r10
		add	r7,r11			; Next SRC Y
		dt	r6
		bf/s	.y_loop
		add	r7,r12
drw_ud_exit:
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------

		align 4
Cach_Drw_All	ds.l 1		; Draw timers moved here
Cach_Drw_U	ds.l 1
Cach_Drw_D	ds.l 1
Cach_Drw_L	ds.l 1
Cach_Drw_R	ds.l 1
Cach_XHead_L	ds.l 1		; Left draw beam
Cach_XHead_R	ds.l 1		; Right draw beam
Cach_YHead_D	ds.l 1		; Bottom draw beam
Cach_YHead_U	ds.l 1		; Top draw beam
Cach_BgFbPos_V	ds.l 1		; Framebuffer Y direct pos (mutiply externally)
Cach_BgFbPos_H	ds.l 1		; Framebuffer TOPLEFT position
Cach_Drw_Cntr	ds.l 1
; ------------------------------------------------
.end:		phase CACHE_MASTER+.end&$1FFF
CACHE_MASTER_E:
		align 4
	if MOMPASS=6
		message "SH2 MASTER CACHE uses: \{(CACHE_MASTER_E-CACHE_MASTER)}"
	endif

; ====================================================================
; ----------------------------------------------------------------
; CACHE code for Slave CPU
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_SLAVE:
		phase $C0000000

; ------------------------------------------------
; Small sample storage for the DMA-protection
; ------------------------------------------------

MarsSnd_PwmCache	ds.b $80*MAX_PWMCHNL
MarsSnd_PwmChnls	ds.b sizeof_sndchn*MAX_PWMCHNL
MarsSnd_PwmControl	ds.b $38	; 7 bytes per channel.

; ------------------------------------------------
; Mars PWM playback (Runs on PWM interrupt)
; r0-r10 only
; ------------------------------------------------

; **** CRITICAL ROUTINE, MUST BE FAST ***

MarsSound_ReadPwm:
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		mov	r10,@-r15
		sts	macl,@-r15

; ------------------------------------------------

		mov	#MarsSnd_PwmCache,r10
		mov	#MarsSnd_PwmChnls,r9	; r9 - Channel list
		mov 	#MAX_PWMCHNL,r8		; r8 - Number of channels
		mov 	#0,r7			; r7 - RIGHT BASE wave
		mov 	#0,r6			; r6 - LEFT BASE wave
.loop:
		mov	@(mchnsnd_enbl,r9),r0	; Channel enabled? (non-Zero)
		cmp/eq	#0,r0
		bf	.on
.silent:
		mov	#$7F,r0
		mov	r0,r2
		bra	.skip
		mov	r0,r1
.on:
		mov 	@(mchnsnd_read,r9),r4
		mov	r4,r3
		mov 	@(mchnsnd_end,r9),r0
		mov	#$00FFFFFF,r1
		shlr8	r3
		shlr8	r0
		and	r1,r3
		and	r1,r0
		cmp/hs	r0,r3
		bf	.read
		mov 	@(mchnsnd_flags,r9),r0
		tst	#%00000100,r0
		bf	.loop_me
		mov 	#0,r0
		mov 	r0,@(mchnsnd_enbl,r9)
; 		mov	@(mchnsnd_start,r9),r0
; 		mov	r0,@(mchnsnd_start,r9)
		bra	.silent
		nop
.loop_me:
		mov 	@(mchnsnd_flags,r9),r0
		mov	@(mchnsnd_loop,r9),r1
		mov 	@(mchnsnd_start,r9),r4
		tst	#%00001000,r0
		bt	.mono_l
		shll	r1
.mono_l:
		add	r1,r4

; read wave
; r4 - WAVE READ pointer
.read:
		mov 	@(mchnsnd_pitch,r9),r5	; Check if sample is on ROM
		mov 	@(mchnsnd_bank,r9),r2
		mov	#CS1,r0
		cmp/eq	r0,r2
		bf	.not_rom
		mov	#MarsSnd_RvMode,r1
		mov	@r1,r0
		cmp/eq	#1,r0
		bf	.not_rom

	; r1 - left WAV
	; r3 - right WAV
	; r4 - original READ point
	; r5 - Pitch
		mov 	@(mchnsnd_flags,r9),r0
		mov	r5,r1
		tst	#%00001000,r0
		bt	.mono_c
		shll	r1
.mono_c:
		mov	@(mchnsnd_cchread,r9),r2
		shlr8	r2
		mov	#$7F,r1
		and	r1,r2
		add	r10,r2
		mov.b	@r2+,r1
		mov.b	@r2+,r3			; null in MONO samples
		bra	.from_rv
		nop

; Play as normal
; r0 - flags
; r4 - READ pointer
.not_rom:
; 		mov	#_sysreg+comm15,r0	; *** TESTING
; 		mov.w	@r0,r0
; 		and	#%00010000,r0
; 		tst	r0,r0
; 		bf	*
; 		mov	#_sysreg+dreqctl,r0
; 		mov.w	@r0,r0
; 		tst	#$01,r0
; 		bf	*			; *** TESTING

		mov 	@(mchnsnd_flags,r9),r0
		mov 	r4,r3
		shlr8	r3
		mov	#$00FFFFFF,r1
		tst	#%00001000,r0
		bt	.mono_a
		add	#-1,r1
.mono_a:
		and	r1,r3
		or	r2,r3
		mov.b	@r3+,r1
		mov.b	@r3+,r3
; 		mov	#$7F,r2
; 		cmp/eq	r2,r1
; 		bt	*
.from_rv:
		mov	r1,r2
		tst	#%00001000,r0
		bt	.mono
		mov	r3,r2
		shll	r5
.mono:
		add	r5,r4
		mov	r4,@(mchnsnd_read,r9)
		mov	@(mchnsnd_cchread,r9),r3
		add	r5,r3
		mov	r3,@(mchnsnd_cchread,r9)
		mov	#$FF,r3
		and	r3,r1
		and	r3,r2
		tst	#%00000010,r0	; LEFT enabled?
		bf	.no_l
		mov	#$7F,r1		; Force LEFT off
.no_l:
		tst	#%00000001,r0	; RIGHT enabled?
		bf	.no_r
		mov	#$7F,r2		; Force RIGHT off
.no_r:
		mov	@(mchnsnd_vol,r9),r0
		cmp/pl	r0
		bf	.skip
		add	#1,r0
		mulu	r0,r1
		sts	macl,r4
		shlr8	r4
		sub	r4,r1
		mulu	r0,r2
		sts	macl,r4
		shlr8	r4
		sub	r4,r2
		mov	#$7F,r4
		mulu	r0,r4
		sts	macl,r0
		shlr8	r0
		add	r0,r1
		add	r0,r2
.skip:
		add	#1,r1
		add	#1,r2
		add	r1,r6
		add	r2,r7
		mov	#$80,r0
		add	r0,r10
		dt	r8
		bf/s	.loop
		add	#sizeof_sndchn,r9
		mov	#$3FF,r0		; Overflow protection
		cmp/gt	r0,r6
		bf	.lmuch
		mov	r0,r6
.lmuch:
		cmp/gt	r0,r7
		bf	.rmuch
		mov	r0,r7
.rmuch:
		mov	#_sysreg+lchwidth,r1	; Write WAVE result
		mov	#_sysreg+rchwidth,r2
 		mov.w	r6,@r1
 		mov.w	r7,@r2
; 		mov	#_sysreg+monowidth,r3	; Works fine without this...
; 		mov.b	@r3,r0
; 		tst	#$80,r0
; 		bf	.retry
		lds	@r15+,macl
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
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

; ------------------------------------------------
		align 4
MarsSnd_RvMode	ds.l 1
MarsSnd_Active	ds.l 1
; ------------------------------------------------
.end:		phase CACHE_SLAVE+.end&$1FFF
CACHE_SLAVE_E:
		align 4
	if MOMPASS=6
		message "SH2 SLAVE CACHE uses: \{(CACHE_SLAVE_E-CACHE_SLAVE)}"
	endif
