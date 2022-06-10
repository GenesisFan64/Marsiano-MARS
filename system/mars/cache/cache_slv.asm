; ====================================================================
; ----------------------------------------------------------------
; CACHE code for SLAVE CPU
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_SLAVE:
		phase $C0000000

; ====================================================================
; --------------------------------------------------------
; Watchdog interrupt
; --------------------------------------------------------

		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)

; wdg_pzfull:
; 		mov.l   #$FFFFFE80,r1
; 		mov.w   #$A518,r0		; OFF
; 		mov.w   r0,@r1
; 		or      #$20,r0			; ON
; 		mov.w   r0,@r1
; 		mov.w   #$5A10,r0		; Timer for the next WD
; 		mov.w   r0,@r1
; 		rts
; 		nop
; 		align 4
; 		ltorg
; wdg_finish:
; 		xor	r0,r0
; 		mov.w	r0,@(marsGbl_WdgMode,gbr)
; 		add	#1,r0
		mov	#1,r0
		mov.w	r0,@(marsGbl_WdgStatus,gbr)
		mov	#$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		rts
		nop
		align 4

; ====================================================================
; --------------------------------------------------------
; PWM Interrupt for playback
; --------------------------------------------------------

; **** MUST BE FAST ***

s_irq_pwm:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1
		mov.w	r0,@r1
		mov.w	@r1,r0

; ------------------------------------------------

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
		mov	#$7F,r0			; Silence...
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
		mov	#MAX_PWMBACKUP-1,r1	; backup size limit
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

	; Clearly rushed...
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
		mov	#MAX_PWMBACKUP,r0
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

		lds	@r15+,macl
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		rts
		mov	@r15+,r2
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Mode 2: Scrolling background
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_DrawScrlLR
;
; Draws the left and right sides of
; the scrolling background on movement
; --------------------------------------------------------

		align 4
MarsVideo_DrawScrlLR:
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	#RAM_Mars_LR_Pixels,r13
		mov	@(mbg_intrl_size,r14),r0
		mov	r0,r6
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r7
		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r8
		mov.w	@(mbg_intrl_w,r14),r0
		mov	r0,r9
		mov	@(mbg_fbdata,r14),r4
		mov	#Cach_BgFbPos_V,r10
		mov	@r10,r10
		mov	#Cach_BgFbPos_H,r11
		mov	@r11,r11
		mov	#_framebuffer,r12
		add	r4,r12
		mov	#320,r5
; 		sub	r7,r5
		mov.w	@(marsGbl_BgDrwR,gbr),r0
		tst	r0,r0
		bf	.right
		mov.w	@(marsGbl_BgDrwL,gbr),r0
		tst	r0,r0
		bf	.left
		rts
		nop
		align 4
.left:
		dt	r0
		bra	.start
		mov.w	r0,@(marsGbl_BgDrwL,gbr)
.right:
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwR,gbr)
		add	r5,r11
.start:
		mulu	r9,r10
		sts	macl,r0
		add	r0,r11
.y_line:
		cmp/ge	r6,r11
		bf	.x_max
		sub	r6,r11
.x_max:
		mov	r13,r1
		mov	r11,r2
		mov	r7,r3
		shlr2	r3
		mov	r2,r4
		mov	r3,r5
		add	r12,r2
.x_line:
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.x_line
		add	#4,r2
		mov	#320,r0	; extra line
		cmp/ge	r0,r4
		bt	.no_ex
		mov	r13,r1
		add	r6,r4
		add	r12,r4
		nop
.xlne_2:
		mov	@r1+,r0
		mov	r0,@r4
		dt	r5
		bf/s	.xlne_2
		add	#4,r4
.no_ex:
		add	r9,r11
		dt	r8
		bf/s	.y_line
		add	#64,r13		; next RAM line
.bad_size:
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsVideo_DrawScrlUD
;
; Draws the top and bottom sides of the background on
; movement
; --------------------------------------------------------

		align 4
MarsVideo_DrawScrlUD:
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	#RAM_Mars_UD_Pixels,r13
		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r6
		mov	@(mbg_intrl_size,r14),r0
		mov	r0,r7
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r8
		mov.w	@(mbg_intrl_w,r14),r0
		mov	r0,r9
		mov	@(mbg_fbdata,r14),r4
		mov	#Cach_BgFbPos_V,r10
		mov	@r10,r10
		mov	#Cach_BgFbPos_H,r11
		mov	@r11,r11
		mov	#_framebuffer,r12
		add	r4,r12
		mov	#240,r5
; 		sub	r8,r5
		mov.w	@(marsGbl_BgDrwD,gbr),r0
		tst	r0,r0
		bf	.right
		mov.w	@(marsGbl_BgDrwU,gbr),r0
		tst	r0,r0
		bf	.left
		rts
		nop
		align 4
.left:
		dt	r0
		bra	.start
		mov.w	r0,@(marsGbl_BgDrwU,gbr)
.right:
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwD,gbr)
		add	r5,r10
.start:
		cmp/ge	r6,r10
		bf	.x_max2
		sub	r6,r10
.x_max2:
		mulu	r9,r10		; macl - FB topleft
		xor	r5,r5		; r5 - counter
.nxt_blk:
		sts	macl,r10
		lds	r5,mach
		mov	r8,r6
		mov	#320,r5
.y_line:
		mov	r13,r1
		mov	r10,r4
		add	r11,r4
		mov	r8,r3
		shlr2	r3
.x_line:
		mov	@r1+,r0
		cmp/ge	r7,r4
		bf	.x_max
		sub	r7,r4
.x_max:
		cmp/ge	r5,r4
		bt	.x_hdn
		mov	r4,r2
		add	r12,r2
		add	r7,r2
		mov	r0,@r2
.x_hdn:
		mov	r4,r2
		add	r12,r2
		mov	r0,@r2
		dt	r3
		bf/s	.x_line
		add	#4,r4

		add	r9,r10
		dt	r6
		bf/s	.y_line
		add	#64,r13
		sts	mach,r5
		add	r8,r5
		cmp/ge	r9,r5
		bf/s	.nxt_blk
		add	r8,r11
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------

			align 4
MarsSnd_RvMode		ds.l 1
MarsSnd_Active		ds.l 1
Cach_BkupPnt_L		ds.l 8			;
Cach_BkupPnt_S		ds.l 0			; <-- Reads backwards
Cach_BkupS_L		ds.l 5			;
Cach_BkupS_S		ds.l 0
Cach_CurrPlygn		ds.b sizeof_polygn	; Current polygon in modelread
MarsSnd_PwmChnls	ds.b sizeof_sndchn*MAX_PWMCHNL
MarsSnd_PwmControl	ds.b $38		; 7 bytes per channel.

; ------------------------------------------------
.end:		phase CACHE_SLAVE+.end&$1FFF

		align 4
CACHE_SLAVE_E:
	if MOMPASS=6
		message "SH2 SLAVE CACHE uses: \{(CACHE_SLAVE_E-CACHE_SLAVE)}"
	endif
