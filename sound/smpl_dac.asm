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
	endm
	align $8000
; DacIns_Test:
; 	gSmpl "sound/instr/smpl/baila.wav",0

DacIns_wegot_kick:
	gSmpl "sound/instr/smpl/wegot_kick.wav",0
DacIns_wegot_crash:
	gSmpl "sound/instr/smpl/wegot_crash.wav",0

DacIns_snare_lobo:
	gSmpl "sound/instr/smpl/snare_lobo.wav",0
DacIns_snare_magn:
	gSmpl "sound/instr/smpl/snare_magn.wav",0


DacIns_kick:
	gSmpl "sound/instr/smpl/stKick.wav",0
