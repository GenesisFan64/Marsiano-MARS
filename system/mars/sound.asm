; ====================================================================
; ----------------------------------------------------------------
; 32X Sound (For SLAVE CPU ONLY)
;
; Playback code (the PWM interrupt) is located at cache_slv.asm
; ----------------------------------------------------------------

; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_PWMCHNL	equ 7		; MAXIMUM usable PWM channels (TODO: keep it like this)
MAX_PWMBACKUP	equ $80		; 1-bit sizes only: $40,$80,$100...
SAMPLE_RATE	equ 22050

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

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
; --------------------------------------------------------
; Init Sound PWM
;
; Cycle register formulas:
; NTSC ((((23011361<<1)/SAMPLE_RATE+1)>>1)+1)
; PAL  ((((22801467<<1)/SAMPLE_RATE+1)>>1)+1)
;
; NOTE: The CLICK sound after calling this is normal.
; --------------------------------------------------------

		align 4
MarsSound_Init:
		stc	gbr,@-r15
		mov	#_sysreg,r0
		ldc	r0,gbr
		mov	#$0105,r0					; Timing interval $01, output L/R
		mov.w	r0,@(timerctl,gbr)
		mov	#((((23011361<<1)/SAMPLE_RATE+1)>>1)+1),r0	; Samplerate
		mov.w	r0,@(cycle,gbr)
		mov	#1,r0
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		mov.w	r0,@(monowidth,gbr)
		ldc	@r15+,gbr
		rts
		nop
		align 4

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsSound_SetPwm
;
; Sets new sound data to a channel slot, automaticly
; plays.
;
; Input:
; r1 | Channel (0-6)
; r2 | Start address (SH2 AREA)
; r3 | End address (SH2 AREA)
; r4 | Loop address (SH2 AREA, ignored if loop bit isn't set)
; r5 | Starting pitch ($xxxxxx.xx, $100 default speed)
; r6 | Volume (0-High)
; r7 | Flags: %xxxxslLR
;      LR - Enable output to these speakers
;       l - LOOP flag
;       s - Sample data is in Stereo (16-bit)
;
; Breaks:
; r0,r8-r9,macl
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
		mov	#-1,r9				; r9 - FF000000
		shll16	r9
		shll8	r9
		and	r9,r0
; 		mov 	#$FF000000,r9
; 		and 	r9,r0
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
; MarsSound_SetPwmPitch
;
; Sets pitch data of a channel slot
;
; Input:
; r1 | Channel (0-6)
; r2 | Pitch ($xxxxxx.xx, $100 default speed)
;
; Breaks:
; r8,macl
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
; Changes the volume of a channel slot
;
; Input:
; r1 | Channel (0-6)
; r2 | Volume (in reverse: higher value is low)
;
; Breaks:
; r8,macl
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
; r1 | Channel (0-6)
; r2 | Enable/Disable
;
; Breaks:
; r8,macl
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
; Call this before the 68K side closes ROM access
; (before 68k side sets RV=1)
;
; Breaks:
; r1-r8
;
; NOTE:
; The trick here is to keep PWM interrupt enabled
; while filling the backup data
; --------------------------------------------------------

MarsSnd_Refill:
		mov	#MarsSnd_PwmChnls,r8
		mov	#MAX_PWMCHNL,r6
		mov	#sizeof_sndchn,r7
		mov	#MarsSnd_PwmCache,r5
.next_one:
		mov	@(mchnsnd_enbl,r8),r0	; This channel is active?
		cmp/eq	#1,r0
		bf	.not_enbl
		mov	@(mchnsnd_bank,r8),r0	; ROM area?
		mov	#CS1,r2
		cmp/eq	r2,r0
		bf	.not_enbl
		mov	#0,r1			; Reset backup LSB
		mov	r1,@(mchnsnd_cchread,r8)
		mov	r5,r1
		mov	#MAX_PWMBACKUP/4,r2	; Max bytes / 4
		mov	@(mchnsnd_read,r8),r4	; r4 - OLD READ pos
		mov	r4,r3
		shlr8	r3
		add	r0,r3
.copy_now:
	rept 4-1
		mov.b	@r3+,r0		; byte by byte...
		mov.b	r0,@r1
		add	#1,r1
	endm
		mov.b	@r3+,r0
		mov.b	r0,@r1
		dt	r2
		bf/s	.copy_now
		add	#1,r1
.not_enbl:
		mov	#MAX_PWMBACKUP,r0
		add	r0,r5
		dt	r6
		bf/s	.next_one
		add	r7,r8
		rts
		nop
		align 4

; ====================================================================

		ltorg			; Save literals
