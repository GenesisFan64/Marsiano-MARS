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

; PwmIns_String_1:
; 	gPwm "sound/instr/smpl/string_1.wav",0
; PwmIns_Tropical:
; 	gPwm "sound/instr/smpl/tropical.wav",0


SmpIns_Bell_Ice:
	gSmpl "sound/instr/smpl/bell_ice.wav",0
SmpIns_Brass1_Hi:
	gSmpl "sound/instr/smpl/brass1_hi.wav",0
SmpIns_Brass1_Low:
	gSmpl "sound/instr/smpl/brass1_low.wav",0
SmpIns_Forest_1:
	gSmpl "sound/instr/smpl/forest1.wav",0
SmpIns_Kick_jam:
	gSmpl "sound/instr/smpl/kick_jam.wav",0
SmpIns_Snare_jam:
	gSmpl "sound/instr/smpl/snare_jam.wav",0
SmpIns_SnrTom_1:
	gSmpl "sound/instr/smpl/snrtom_1.wav",0
SmpIns_PIANO_1:
	gSmpl "sound/instr/smpl/PIANO__1.wav",0
SmpIns_SSTR162A:
	gSmpl "sound/instr/smpl/SSTR162A.wav",0


