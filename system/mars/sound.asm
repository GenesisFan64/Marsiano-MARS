; ====================================================================
; ----------------------------------------------------------------
; 32X Sound (For SLAVE CPU ONLY)
;
; Playback code (the PWM interrupt) is located at cache_slv.asm
; ----------------------------------------------------------------

; --------------------------------------------------------
; Settings
; --------------------------------------------------------

SAMPLE_RATE	equ 22050	; 22050
MAX_PWMCHNL	equ 7
MAX_PWMBACKUP	equ $80		; 1-byte SIZES ONLY

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

; 32X sound channel
		struct 0
mchnsnd_enbl	ds.l 1		; %E000 SLlr | Enable-Stereo,Loop,left,right
mchnsnd_read	ds.l 1		; READ point
mchnsnd_cread	ds.l 1
mchnsnd_bank	ds.l 1		; CS1 or CS3
mchnsnd_start	ds.l 1		; Start point $00xxxxxx << 8
mchnsnd_len	ds.l 1		; Lenght << 8
mchnsnd_loop	ds.l 1		; Loop point << 8
mchnsnd_pitch	ds.l 1		; Pitch $xx.xx
mchnsnd_vol	ds.l 1		; Volume ($0000-Max)
sizeof_marssnd	ds.l 0
		endstruct

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

; ; --------------------------------------------------------
; ; MarsSound_SetPwm
; ;
; ; Sets new sound data to a channel slot, automaticly
; ; plays.
; ;
; ; Input:
; ; r1 | Channel (0-6)
; ; r2 | Start address (SH2 AREA)
; ; r3 | End address (SH2 AREA)
; ; r4 | Loop address (SH2 AREA, ignored if loop bit isn't set)
; ; r5 | Starting pitch ($xxxxxx.xx, $100 default speed)
; ; r6 | Volume (0-High)
; ; r7 | Flags: %xxxxslLR
; ;      LR - Enable output to these speakers
; ;       l - LOOP flag
; ;       s - Sample data is in Stereo (16-bit)
; ;
; ; Breaks:
; ; r0,r8-r9,macl
; ; --------------------------------------------------------
;
; MarsSound_SetPwm:
; 		mov	#RAM_Mars_PwmList,r8
; 		mov 	#sizeof_marssnd,r0
; 		mulu	r1,r0
; 		sts	macl,r0
; 		add 	r0,r8
; 		mov 	#0,r0
; 		mov 	r0,@(mchnsnd_enbl,r8)
; ; 		mov 	r0,@(mchnsnd_read,r8)
; ; 		mov 	r0,@(mchnsnd_bank,r8)
; 		mov 	r5,@(mchnsnd_pitch,r8)
; 		mov 	r6,@(mchnsnd_vol,r8)
; 		mov	r7,r0
; 		or	#$80,r0
; 		mov 	r0,@(mchnsnd_enbl,r8)
; 		mov 	r2,r0				; Set MSB
; 		mov	#-1,r9				; r9 - FF000000
; 		shll16	r9
; 		shll8	r9
; 		and	r9,r0
; ; 		mov 	#$FF000000,r9
; ; 		and 	r9,r0
; 		mov 	r0,@(mchnsnd_bank,r8)
; 		mov 	r4,r0				; Set POINTS
; 		cmp/eq	#-1,r0
; 		bt	.endmrk
; 		shll8	r0
; .endmrk:
; 		mov	r0,@(mchnsnd_loop,r8)
; 		mov 	r3,r0
; 		shll8	r0
; 		mov	r0,@(mchnsnd_len,r8)
; 		mov 	r2,r0
; 		shll8	r0
; 		mov 	r0,@(mchnsnd_start,r8)
; 		mov 	r0,@(mchnsnd_read,r8)
; ; 		mov 	#1,r0
; ; 		mov 	r0,@(mchnsnd_enbl,r8)
; 		rts
; 		nop
; 		align 4
;
; ; --------------------------------------------------------
; ; MarsSound_SetPwmPitch
; ;
; ; Sets pitch data of a channel slot
; ;
; ; Input:
; ; r1 | Channel (0-6)
; ; r2 | Pitch ($xxxxxx.xx, $100 default speed)
; ;
; ; Breaks:
; ; r8,macl
; ; --------------------------------------------------------
;
; MarsSound_SetPwmPitch:
; 		mov	#RAM_Mars_PwmList,r8
; 		mov 	#sizeof_marssnd,r0
; 		mulu	r1,r0
; 		sts	macl,r0
; 		add 	r0,r8
; 		mov	@(mchnsnd_enbl,r8),r0
; 		tst	#$80,r0
; 		bt	.off_1
; 		mov	@(mchnsnd_read,r8),r0
; 		mov	r2,@(mchnsnd_pitch,r8)
; .off_1:
; 		rts
; 		nop
; 		align 4
;
; ; --------------------------------------------------------
; ; MarsSound_SetVolume
; ;
; ; Changes the volume of a channel slot
; ;
; ; Input:
; ; r1 | Channel (0-6)
; ; r2 | Volume (in reverse: higher value is low)
; ;
; ; Breaks:
; ; r8,macl
; ; --------------------------------------------------------
;
; MarsSound_SetVolume:
; 		mov	#RAM_Mars_PwmList,r8
; 		mov 	#sizeof_marssnd,r0
; 		mulu	r1,r0
; 		sts	macl,r0
; 		add 	r0,r8
; 		mov	@(mchnsnd_enbl,r8),r0
; 		tst	#$80,r0
; 		bt	.off_1
; 		mov	r2,r0
; 		mov	r0,@(mchnsnd_vol,r8)
; .off_1:
; 		rts
; 		nop
; 		align 4
;
; ; --------------------------------------------------------
; ; MarsSound_PwmEnable
; ;
; ; Turns ON or OFF Current PWM slot
; ;
; ; Input:
; ; r1 | Channel (0-6)
; ; r2 | Enable/Disable
; ;
; ; Breaks:
; ; r8,macl
; ; --------------------------------------------------------
;
; MarsSound_PwmEnable:
; 		mov	#RAM_Mars_PwmList,r8
; 		mov 	#sizeof_marssnd,r0
; 		mulu	r1,r0
; 		sts	macl,r0
; 		add 	r0,r8
; 		mov	r2,r0
; 		shll8	r0
; 		shlr	r0
; 		mov 	r0,@(mchnsnd_enbl,r8)
; 		rts
; 		nop
; 		align 4

; ====================================================================

		ltorg			; Save literals
