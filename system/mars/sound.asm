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

; *** PWM INTERRUPT MOVED TO CACHE (see cache.asm)

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init Sound PWM
;
; Frequency values:
; 23011361 NTSC
; 22801467 PAL
;
; NOTE: The CLICK sound is normal.
; --------------------------------------------------------

MarsSound_Init:
		stc	gbr,@-r15
		mov	#_sysreg,r0
		ldc	r0,gbr
		mov	#$0105,r0
		mov.w	r0,@(timerctl,gbr)
		mov	#((((23011361<<1)/22050+1)>>1)+1),r0	; 22050
		mov.w	r0,@(cycle,gbr)
		mov	#1,r0
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
; 		mov	#0,r0
; 		mov	#MarsSnd_PwmChnls,r1
; 		mov	#MAX_PWMCHNL,r2
; 		mov	#sizeof_sndchn,r3
; .clr_enbl:
; 		mov	r0,@(mchnsnd_enbl,r1)
; 		dt	r2
; 		bf/s	.clr_enbl
; 		add	r3,r1
		ldc	@r15+,gbr
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
; r4 | Loop address (ignored if loop flag isn't set)
; r5 | Pitch ($xxxxxx.xx, $100 default speed)
; r6 | Volume
; r7 | Flags (Currently: %xxxxslLR)
;      LR - output
;      l - LOOP flag
;      s - Sample is in stereo
;
; Uses:
; r0,r8-r9
; --------------------------------------------------------

MarsSound_SetPwm:
		mov	#MarsSnd_PwmChnls,r8
		mov 	#sizeof_sndchn,r0
		mulu	r1,r0
		sts	macl,r0
		add 	r0,r8
		mov 	#0,r0
		mov 	r0,@(mchnsnd_enbl,r8)
; 		mov 	r0,@(mchnsnd_read,r8)
; 		mov 	r0,@(mchnsnd_bank,r8)
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
		shll8	r0
		mov 	r0,@(mchnsnd_start,r8)
		mov 	r0,@(mchnsnd_read,r8)
		mov 	#1,r0
		mov 	r0,@(mchnsnd_enbl,r8)
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
; r1 | Channel slot
; r2 | Pitch data
;
; Uses:
; r8
; --------------------------------------------------------

MarsSound_SetPwmPitch:
		mov	#MarsSnd_PwmChnls,r8
		mov 	#sizeof_sndchn,r0
		mulu	r1,r0
		sts	macl,r0
		add 	r0,r8
		mov	@(mchnsnd_enbl,r8),r0
		cmp/eq	#1,r0
		bf	.off_1
		mov	@(mchnsnd_read,r8),r0
		mov	r2,@(mchnsnd_pitch,r8)
.off_1:
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsSound_SetVolume
;
; Input:
; r1 | Channel slot
; r2 | Volume data
;
; Uses:
; r8
; --------------------------------------------------------

MarsSound_SetVolume:
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
		mov	#MarsSnd_PwmChnls,r8
		mov 	#sizeof_sndchn,r0
		mulu	r1,r0
		sts	macl,r0
		add 	r0,r8
		mov 	r2,@(mchnsnd_enbl,r8)
; 		mov 	#0,r0
; 		mov 	r0,@(mchnsnd_read,r8)
; 		mov 	r0,@(mchnsnd_bank,r8)
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsSound_Refill
;
; Uses:
; r1-r8
; --------------------------------------------------------

; The trick here is to keep PWM interrupt enabled while
; filling the backup data

MarsSnd_Refill:
		mov	#MarsSnd_PwmChnls,r8
		mov	#MAX_PWMCHNL,r6
		mov	#sizeof_sndchn,r7
		mov	#MarsSnd_PwmCache,r5
.next_one:
		mov	@(mchnsnd_enbl,r8),r0	; Finished already?
		cmp/eq	#1,r0
		bf	.not_enbl
		mov	@(mchnsnd_bank,r8),r0
		mov	#CS1,r2
		cmp/eq	r2,r0
		bf	.not_enbl
		mov	#0,r1
		mov	r1,@(mchnsnd_cchread,r8)
		mov	r5,r1
		mov	#$80/4,r2
		mov	@(mchnsnd_read,r8),r4	; r4 - OLD READ pos
		mov	r4,r3
		shlr8	r3
		add	r0,r3
.copy_now:
		mov.b	@r3+,r0
		mov.b	r0,@r1
		add	#1,r1
		mov.b	@r3+,r0
		mov.b	r0,@r1
		add	#1,r1
		mov.b	@r3+,r0
		mov.b	r0,@r1
		add	#1,r1
		mov.b	@r3+,r0
		mov.b	r0,@r1
		dt	r2
		bf/s	.copy_now
		add	#1,r1
.not_enbl:
		mov	#$80,r0
		add	r0,r5
		dt	r6
		bf/s	.next_one
		add	r7,r8
		rts
		nop
		align 4
		ltorg

; ====================================================================

		ltorg			; Save literals
