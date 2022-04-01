; ====================================================================
; PWM samples
;
; For SH2's visible areas: ROM ($02000000) or SDRAM ($06000000)
;
; SDRAM is safest but it has very low storage
;
; ROM area can use all the 4 Megabytes of storage, BUT when the
; RV bit is set, the sample data will be lost... but luckily
; a "Wave-backup" feature is implemented to copy a small
; amount of bytes of the sample data to a safe place for playback
; while RV bit is active.
; Do note that if the RV bit stays active too long it will cause
; the sample to click.
; ====================================================================

; Special sample data macro
gPwm macro locate,loop
.start
	dc.b ((.end-.start)&$FF),(((.end-.start)>>8)&$FF),(((.end-.start)>>16)&$FF)	; length
	dc.b ((loop)&$FF),(((loop)>>8)&$FF),(((loop)>>16)&$FF)
	binclude locate,$2C	; actual data
.end
	align 4			; align 4 for pwm's
	endm

; --------------------------------------------------------
	align 4			; FIRST ALIGN FOR PWMs

; PwmIns_Test_st:
; 	gPwm "sound/instr/smpl/baila_st.wav",0

; DacIns_wegot_kick:
; 	gSmpl "sound/instr/smpl/wegot_kick.wav",0
; DacIns_wegot_crash:
; 	gSmpl "sound/instr/smpl/wegot_crash.wav",0
; ; DacIns_Snare_Gem:
; ; 	gSmpl "sound/instr/smpl/snare_lobo.wav",0
; ; DacIns_CdSnare:
; ; 	gSmpl "sound/instr/smpl/cd_snare.wav",0
; ; DacIns_SaurKick:
; ; 	gSmpl "sound/instr/smpl/sauron_kick.wav",0
; ; DacIns_SaurSnare:
; ; 	gSmpl "sound/instr/smpl/sauron_snare.wav",0
; ; DacIns_String1:
; ; 	gSmpl "sound/instr/smpl/string_1.wav",0
; ; DacIns_LowString:
; ; 	gSmpl "sound/instr/smpl/lowstring.wav",1200
