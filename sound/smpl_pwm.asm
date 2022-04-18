; ====================================================================
; PWM samples
;
; For SH2's visible areas: ROM ($02000000) or SDRAM ($06000000)
;
; - SDRAM is safest but it has very LOW storage
; - ROM area can use all the 4 Megabytes of storage, BUT when the
; RV bit is set: the sample data will be lost. Luckily
; a "Wave-backup" feature is implemented to copy a small
; amount of bytes of the sample data into a safe place for playback
; while RV bit is active.
;
; Do note that if the RV bit stays active too long it will ran out of
; backup data and the sample will play trash bytes.
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

PwmIns_String_1:
	gPwm "sound/instr/smpl/string_1.wav",0
PwmIns_Tropical:
	gPwm "sound/instr/smpl/tropical.wav",0

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
