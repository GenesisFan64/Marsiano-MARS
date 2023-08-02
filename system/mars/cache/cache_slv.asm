; ====================================================================
; ----------------------------------------------------------------
; CACHE code
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_SLAVE:
		phase $C0000000

; ====================================================================
; --------------------------------------------------------
; PWM Interrupt
;
; **** MUST BE FAST ***
; --------------------------------------------------------

; MarsPwm_Playback:
s_irq_pwm:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1
		mov.w	r0,@r1
		mov.w	@r1,r0
		mov	#Cach_SlvStack_S,r0
		mov	r2,@-r0
		mov	r3,@-r0
		mov	r4,@-r0
		mov	r5,@-r0
		mov	r6,@-r0
		mov	r7,@-r0
		mov	r8,@-r0
		mov	r9,@-r0
		mov	r10,@-r0
		sts	macl,@-r0
; ------------------------------------------------

		mov	#RAM_Mars_PwmList,r10
		mov	#RAM_Mars_PwmRomRV,r9
		mov	#MAX_PWMCHNL,r8
		mov	#0,r6		; r6 - left
		mov	#0,r7		; r7 - right
.next_chnl:
		mov	@(mchnsnd_enbl,r10),r0
		tst	#$80,r0
		bf	.enabled
.silence:	mov	#$80,r1
		bra	.chnl_off
		mov	r1,r2
.enabled:
		mov	@(mchnsnd_read,r10),r5
		mov	@(mchnsnd_len,r10),r4
		mov	@(mchnsnd_pitch,r10),r3
		tst	#%1000,r0
		bt	.st_pitch
		shll	r3
.st_pitch:	add	r3,r5
		cmp/ge	r4,r5
		bf	.keep
		tst	#%0100,r0
		bf	.loopit
		xor	r0,r0		; r0 gone
		bra	.silence
		mov	r0,@(mchnsnd_enbl,r10)
.loopit:
		mov	@(mchnsnd_start,r10),r5
		mov	@(mchnsnd_loop,r10),r3
		add	r3,r5
.keep:
		mov	r5,@(mchnsnd_read,r10)

		shlr8	r5
		mov	@(mchnsnd_bank,r10),r4
		or	r4,r5
		lds	r0,macl

		mov.b	@r5+,r3
		extu.b	r3,r3
		tst	#%1000,r0
		bt	.do_mono
		mov.b	@r5+,r4
		bra	.go_wave
		extu.b	r4,r4
.do_mono:
		mov	r3,r4

; r3 - left byte
; r4 - right byte
.go_wave:	tst	r3,r3
		bf	.l_nonz
		add	#1,r3
.l_nonz:	tst	r4,r4
		bf	.mnon_z
		add	#1,r4
		mov.b	#$80,r1
		extu.b	r1,r1
		mov	r1,r2
.mnon_z:	tst	#%0010,r0
		bt	.ml_out
		mov	r3,r1
.ml_out:	tst	#%0001,r0
		bt	.do_vol
		mov	r4,r2
; r1 - left
; r2 - right
.do_vol:
		mov	@(mchnsnd_vol,r10),r0
		cmp/pl	r0
		bf	.chnl_off
		add	#1,r0
		mulu	r0,r1
		sts	macl,r4
		shlr8	r4
		sub	r4,r1
		mulu	r0,r2
		sts	macl,r4
		shlr8	r4
		sub	r4,r2
		mov	#$80,r4
		mulu	r0,r4
		sts	macl,r0
		shlr8	r0
		add	r0,r1
		add	r0,r2
.chnl_off:
		add	r1,r6
		add	r2,r7
		add	#sizeof_marssnd,r10
		mov	#MAX_PWMBACKUP,r0
		dt	r8
		bf/s	.next_chnl
		add	r0,r9
		mov	#$3FF,r0
		cmp/ge	r0,r6
		bf	.l_max
		mov	r0,r6
.l_max:
		cmp/ge	r0,r7
		bf	.r_max
		mov	r0,r7
.r_max:
		shll16	r6
		or	r6,r7
		mov	#_sysreg+lchwidth,r0
		mov	r7,@r0

; ------------------------------------------------
		mov	#Cach_SlvStack_L,r0
		lds	@r0+,macl
		mov	@r0+,r10
		mov	@r0+,r9
		mov	@r0+,r8
		mov	@r0+,r7
		mov	@r0+,r6
		mov	@r0+,r5
		mov	@r0+,r4
		mov	@r0+,r3
		rts
		mov	@r0+,r2
		align 4
		ltorg

; ====================================================================

			align $10
Cach_SlvStack_L		ds.l 10				; ** Reg backup for PWM playback
Cach_SlvStack_S		ds.l 0				; **

; ------------------------------------------------
.end:		phase CACHE_SLAVE+.end&$1FFF

		align 4
CACHE_SLAVE_E:
	if MOMPASS=6
		message "SH2 SLAVE CACHE uses: \{(CACHE_SLAVE_E-CACHE_SLAVE)}"
	endif
