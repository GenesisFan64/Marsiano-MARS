; ====================================================================
; ----------------------------------------------------------------
; MARS Sound
; ----------------------------------------------------------------

MAX_PWMCHNL	equ	7

; 32X sound channel
		struct 0
mchnsnd_enbl	ds.l 1
mchnsnd_read	ds.l 1		; 0 - off
mchnsnd_cchread	ds.l 1
mchnsnd_bank	ds.l 1		; CS0-3 OR value
mchnsnd_start	ds.l 1
mchnsnd_end	ds.l 1
mchnsnd_loop	ds.l 1
mchnsnd_pitch	ds.l 1
mchnsnd_flags	ds.l 1		; %SLR S-wave format mono/stereo | LR-wave output bits
mchnsnd_vol	ds.l 1
sizeof_sndchn	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Mars PWM playback (Runs on PWM interrupt)
;
; READ/START/END/LOOP points are floating values (xxxxxx.00)
;
; r0-r9 only
; ----------------------------------------------------------------

		align 4
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
;
		mov	#$C0000000,r10
		mov	#MarsSnd_PwmChnls,r9	; r9 - Channel list
		mov 	#MAX_PWMCHNL,r8		; r8 - Number of channels
		mov 	#0,r7			; r7 - RIGHT BASE wave
		mov 	#0,r6			; r6 - LEFT BASE wave
.loop:
		mov	@(mchnsnd_enbl,r9),r0
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
		tst	#%00001000,r0
		bf	.loop_me
		mov 	#0,r0
		mov 	r0,@(mchnsnd_enbl,r9)
		bra	.silent
		nop
.loop_me:
		mov	@(mchnsnd_loop,r9),r0
		mov 	@(mchnsnd_start,r9),r4
		add	r0,r4

; read wave
; r4 - WAVE READ pointer
.read:
		mov 	@(mchnsnd_pitch,r9),r5
		mov 	@(mchnsnd_bank,r9),r2
		mov	#CS1,r0
		cmp/eq	r0,r2
		bf	.not_rom

	; TODO: backup mode bit instead of
	; direct RV
		mov	#_sysreg+dreqctl,r0	; Check for RV bit
		mov.w	@r0,r0			; If set, play backup below.
		tst	#$01,r0
		bt	.not_rom

	; r1 - left WAV
	; r2 - ROM BANK
	; r3 - right WAV
	; r4 - normal READ point
	; r5 - Pitch
		mov	@(mchnsnd_cchread,r9),r3
		mov	r3,r2
		mov	#$FFFF,r0
		add	r5,r3
		and	r0,r3
		mov	r3,@(mchnsnd_cchread,r9)
		mov	#$FF,r0
		shlr8	r2
		mov	r2,r1
		add	r10,r1
		mov.b	@r1,r1
		add	#1,r2
		and	r0,r2
		mov	r2,r3
		add	r10,r3
		mov.b	@r3,r3
		mov 	@(mchnsnd_flags,r9),r0
		bra	.from_rv
		nop

; Play as normal
; r0 - flags
; r4 - READ pointer
.not_rom:
		mov 	@(mchnsnd_flags,r9),r0
		mov	#$00FFFFFF,r1		; limit BYTE
		mov 	r4,r3
		shlr8	r3
		tst	#%00000100,r0
		bt	.mono_a
		add	#-1,r1			; limit WORD
.mono_a
		and	r1,r3
		or	r2,r3
		mov.b	@r3+,r1
		mov.b	@r3+,r3
.from_rv:
		mov	r1,r2
		tst	#%00000100,r0
		bt	.mono
		mov	r3,r2
		shll	r5
.mono:
		add	r5,r4
		mov	r4,@(mchnsnd_read,r9)

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
		mov	@(mchnsnd_vol,r9),r5
		cmp/pl	r5
		bf	.skip
		add	#1,r5
		mulu	r5,r1
		sts	macl,r4
		shlr8	r4
		sub	r4,r1
		mulu	r5,r2
		sts	macl,r4
		shlr8	r4
		sub	r4,r2
		mov	#$7F,r3		; align wave to pwm
		mulu	r5,r3
		sts	macl,r3
		shlr8	r3
		add	r3,r1
		add	r3,r2
.skip:
		add	#1,r1
		add	#1,r2
		add	r1,r6
		add	r2,r7
		add	#sizeof_sndchn,r9
		mov	#$100,r0
		add	r0,r10
		dt	r8
		bf	.loop

	; ***This check is for emus only***
	; It recreates what happens to the PWM
	; in real hardware when it overflows
; 		mov	#$3FF,r0
; 		cmp/gt	r0,r5
; 		bf	.lmuch
; 		mov	r0,r5
; .lmuch:	cmp/gt	r0,r6
; 		bf	.rmuch
; 		mov	r0,r6
; .rmuch:
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

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init Sound PWM
;
; 23011361 NTSC
; 22801467 PAL
; --------------------------------------------------------

MarsSound_Init:
		sts	pr,@-r15
		stc	gbr,@-r15
		mov	#_sysreg,r0
		ldc	r0,gbr
		mov	#$0105,r0
		mov.w	r0,@(timerctl,gbr)
		mov	#((((23011361<<1)/22050+1)>>1)+1),r0	; 22050 best
		mov.w	r0,@(cycle,gbr)
		mov	#1,r0
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		mov	#0,r0
		mov	#MarsSnd_PwmChnls,r1
		mov	#MAX_PWMCHNL,r2
		mov	#sizeof_sndchn,r3
.clr_enbl:
		mov	r0,@(mchnsnd_enbl,r1)
		dt	r2
		bf/s	.clr_enbl
		add	r3,r1
		add	#4,r2
		ldc	@r15+,gbr
		lds	@r15+,pr
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsSound_SetPwm
;
; Set new sound data to a single channel
;
; Input:
; r1 | Channel
; r2 | Start address
; r3 | End address
; r4 | Loop address
; r5 | Pitch ($xxxxxx.xx)
; r6 | Volume
; r7 | Flags (Currently: %xxxFLSLR)
;
; Uses:
; r0,r7-r9
; --------------------------------------------------------

MarsSound_SetPwm:
; 		stc	sr,@-r15
; 		mov	#$F0,r0
		mov	#MarsSnd_PwmChnls,r8
		mov 	#sizeof_sndchn,r0
		mulu	r1,r0
		sts	macl,r0
		add 	r0,r8
		mov 	#0,r0
		mov 	r0,@(mchnsnd_enbl,r8)
		mov 	r0,@(mchnsnd_read,r8)
		mov 	r0,@(mchnsnd_bank,r8)
		mov 	r5,@(mchnsnd_pitch,r8)
		mov 	r6,@(mchnsnd_vol,r8)
		mov 	r7,@(mchnsnd_flags,r8)
		mov 	r2,r0				; Set MSB
		mov 	#$FF000000,r9
		and 	r9,r0
		mov 	r0,@(mchnsnd_bank,r8)
		mov 	r4,r0				; Set POINTS
		cmp/eq	#-1,r0
		bt	.endmrk
		shll8	r0
.endmrk:
		mov	r0,@(mchnsnd_loop,r8)
		mov 	r3,r0
		shll8	r0
		mov	r0,@(mchnsnd_end,r8)
		mov 	r2,r0
		mov	r0,r9
		shll8	r0
		mov 	r0,@(mchnsnd_start,r8)
		mov 	r0,@(mchnsnd_read,r8)
		mov 	#1,r0
		mov 	r0,@(mchnsnd_enbl,r8)

; 		mov	r1,r0
; 		shll8	r0
; 		mov	r0,r9
; 		shll8	r0
; 		mov	r0,@(mchnsnd_cchread,r8)
; 		mov	#$C0000000,r0
; 		or	r0,r9
; 		mov	#$100/4,r8
; .copycach:
; 		mov	@r2+,r0
; 		mov	r0,@r9
; 		dt	r8
; 		bf/s	.copycach
; 		add	#4,r9
; 		ldc	@r15+,sr
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsSound_MulPwmPitch
;
; Set pitch data to 8 consecutive sound channels
; starting from specific slot
;
; Input:
; r1 | Channel pitch slot 0
; r2 | Pitch data
;
; Uses:
; r3,r4
; --------------------------------------------------------

MarsSound_SetPwmPitch:
; 		stc	sr,@-r15
; 		mov	#$F0,r0
		mov	#MarsSnd_PwmChnls,r8
		mov 	#sizeof_sndchn,r0
		mulu	r1,r0
		sts	macl,r0
		add 	r0,r8
		mov	@(mchnsnd_enbl,r8),r0
		cmp/eq	#1,r0
		bf	.off_1
; 		mov	@(mchnsnd_read,r8),r0
		mov	r2,@(mchnsnd_pitch,r8)
.off_1:
; 		ldc	@r15+,sr
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsSound_SetVolume
;
; Input:
; r1 | Channel pitch slot 0
; r2 | Pitch data
;
; Uses:
; r3,r4
; --------------------------------------------------------

MarsSound_SetVolume:
; 		stc	sr,@-r15
; 		mov	#$F0,r0
		mov	#MarsSnd_PwmChnls,r8
		mov 	#sizeof_sndchn,r0
		mulu	r1,r0
		sts	macl,r0
		add 	r0,r8
		mov	@(mchnsnd_enbl,r8),r0
		cmp/eq	#1,r0
		bf	.off_1
		mov	r2,r0
		mov	r0,@(mchnsnd_vol,r8)
.off_1:
; 		ldc	@r15+,sr
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsSound_PwmEnable
;
; Turns ON or OFF Current PWM slot
;
; Input:
; r1 | Slot
; r2 | Enable/Disable
;
; Uses:
; r8
; --------------------------------------------------------

MarsSound_PwmEnable:
; 		stc	sr,@-r15
; 		mov	#$F0,r0
		mov	#MarsSnd_PwmChnls,r8
		mov 	#sizeof_sndchn,r0
		mulu	r1,r0
		sts	macl,r0
		add 	r0,r8
		mov 	r2,@(mchnsnd_enbl,r8)
; 		mov 	#0,r0
; 		mov 	r0,@(mchnsnd_read,r8)
; 		mov 	r0,@(mchnsnd_bank,r8)
; 		ldc	@r15+,sr
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsSound_Refill
;
; Call this if MD wants to do DMA, which sets RV=1
; starting from specific slot
;
; Uses:
; r1-r8
; --------------------------------------------------------

MarsSnd_Refill:
		mov	#MarsSnd_PwmChnls,r8
		mov	#MAX_PWMCHNL,r6
		mov	#sizeof_sndchn,r7
		mov	#$C0000000,r5
.next_one:
		mov	@(mchnsnd_enbl,r8),r0
		cmp/eq	#1,r0
		bf	.not_activ
		mov	#0,r3
		mov	r3,@(mchnsnd_cchread,r8)
		mov	@(mchnsnd_read,r8),r4
		mov	@(mchnsnd_bank,r8),r0
		shlr8	r4
		add	r0,r4
		add	r5,r3

		mov	#_DMASOURCE0,r1
		mov	#_DMAOPERATION,r2
		mov	r4,@r1			; set source address
		add	#4,r1
		mov	r3,@r1			; set destination address
		add	#4,r1
		mov	#$100,r0
		mov	r0,@r1			; set length
		add	#4,r1
		mov	#0,r0
		mov	r0,@r2			; Stop OPERATION
		xor	r0,r0
		mov	r0,@r1			; clear TE bit
		mov	#%0101001011100001,r0	; transfer mode bits, ON
		mov	r0,@r1			; load mode
		mov	#1,r0
		mov	r0,@r2			; Start OPERATION
.wait_dma:
		mov	@r1,r0
		and	#%10,r0
		tst	r0,r0
		bt	.wait_dma
		mov	@r1,r0
		mov	#-1,r2
		and	r2,r0
		mov	r0,@r1

; 		mov	#_DMAOPERATION,r1
; 		mov	#0,r0
; 		mov	r0,@r1			; Start OPERATION
; 		mov	#_DMACHANNEL0,r1
; 		xor	r0,r0
; 		mov	r0,@r1
; 		mov	#%0101011011100000,r0	; transfer mode bits, but OFF
; 		mov	r0,@r1

; 		mov	#$100,r2
; 		mov	#$000000FF,r1
; .copy_now:
; 		mov.b	@r4,r0
; 		mov.b	r0,@r3
; 		add	#1,r3
; 		and	r1,r3
; 		add	r5,r3
; 		dt	r2
; 		bf/s	.copy_now
; 		add	#1,r4
.not_activ:
		mov	#$100,r0
		add	r0,r5
		dt	r6
		bf/s	.next_one
		add	r7,r8
		rts
		nop
		align 4
		ltorg

		mov 	#sizeof_sndchn,r0
		mulu	r1,r0
		sts	macl,r0
		add 	r0,r8
		mov	@(mchnsnd_enbl,r8),r0
		cmp/eq	#1,r0
		bf	.off_1
; 		mov	@(mchnsnd_read,r8),r0
		mov	r2,@(mchnsnd_pitch,r8)
.off_1:
; 		ldc	@r15+,sr
		rts
		nop
		align 4

; ====================================================================

		ltorg	; Save variables
