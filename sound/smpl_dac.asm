; ====================================================================
; DAC samples
;
; This must be located at the 900000 area.
; ====================================================================

; Special sample data macro
;
; aligns by 4 at the end so the sample can recycled on 32X
gSmpl macro locate,loop
.start
	dc.b ((.end-.start)&$FF),(((.end-.start)>>8)&$FF),(((.end-.start)>>16)&$FF)	; length
	dc.b ((loop)&$FF),(((loop)>>8)&$FF),(((loop)>>16)&$FF)
	binclude locate,$2C	; actual data
.end
	align 4			; align 4 for pwm's
	endm

	align 4			; FIRST ALIGN FOR PWMs
DacIns_wegot_kick:
	gSmpl "sound/instr/smpl/wegot_kick.wav",0
DacIns_wegot_crash:
	gSmpl "sound/instr/smpl/wegot_crash.wav",0
; DacIns_Snare_Gem:
; 	gSmpl "sound/instr/smpl/snare_lobo.wav",0
; DacIns_CdSnare:
; 	gSmpl "sound/instr/smpl/cd_snare.wav",0
; DacIns_SaurKick:
; 	gSmpl "sound/instr/smpl/sauron_kick.wav",0
; DacIns_SaurSnare:
; 	gSmpl "sound/instr/smpl/sauron_snare.wav",0
; DacIns_String1:
; 	gSmpl "sound/instr/smpl/string_1.wav",0
; DacIns_LowString:
; 	gSmpl "sound/instr/smpl/lowstring.wav",1200
