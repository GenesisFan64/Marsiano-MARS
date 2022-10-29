; ====================================================================
; DAC samples
;
; This must be located at the 900000 area.
; ====================================================================

; Special sample data macro
gSmpHead macro len,loop
	dc.b ((len)&$FF),(((len)>>8)&$FF),(((len)>>16)&$FF)	; length
	dc.b ((loop)&$FF),(((loop)>>8)&$FF),(((loop)>>16)&$FF)
	endm

	align $8000
; DacIns_wegot_kick:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/wegot_kick.wav",$2C
; .end:
; DacIns_snare_lobo:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/snare_lobo.wav",$2C
; .end:


; DacIns_wegot_crash:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/wegot_crash.wav",$2C
; .end:


; DacIns_snare_scd:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/snare_scd.wav",$2C
; .end:
; DacIns_snare_magn:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/snare_magn.wav",$2C
; .end:
; DacIns_kick:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/stKick.wav",$2C
; .end:
;
; DacIns_Nadie:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/nadie.wav",$2C
; 	align 4
; .end:

