; ====================================================================
; --------------------------------------------------------
; GEMA/Nikona PWM instruments
;
; These MUST be located at SH2's ROM area: $02000000
; THE SDRAM area ($06000000) CAN be used but there's
; no enough storage the samples, the SH2 side supports
; ROM-protection in case the RV-bit is set for
; Genesis' DMA transfers.
;
; Sample data is 8-bit at 22050hz
; INCLUDING STEREO SAMPLES.
;
; *** PUT align 4 AT THE TOP OF EVERY LABEL ***
; --------------------------------------------------------

; ; Special sample data macro
; gSmpHead macro len,loop
; 	dc.b ((len)&$FF),(((len)>>8)&$FF),(((len)>>16)&$FF)	; length
; 	dc.b ((loop)&$FF),(((loop)>>8)&$FF),(((loop)>>16)&$FF)
; 	endm

	align 4
SmpIns_Nadie:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/nadie_st.wav",$2C
.end:

	align 4
SmpIns_MoveMe_Hit:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/moveme_hit.wav",$2C
.end:

	align 4
SmpIns_MoveMe_Brass:
	gSmpHead .end-.start,6478
.start:	binclude "sound/instr/smpl/brass_moveme.wav",$2C
.end:

	align 4
SmpIns_Kick:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/kick_moveme.wav",$2C
.end:

	align 4
SmpIns_Snare_moveme:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/snare_moveme.wav",$2C
.end:

	align 4
SmpIns_snare_1:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/snare_1.wav",$2C
.end:

	align 4
SmpIns_Vctr01:
	gSmpHead .end-.start,58
.start:	binclude "sound/instr/smpl/pwm/vctr01.wav",$2C
.end:

	align 4
SmpIns_Vctr04:
	gSmpHead .end-.start,124
.start:	binclude "sound/instr/smpl/pwm/vctr04.wav",$2C
.end:

	align 4
SmpIns_VctrSnare:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/pwm/vctrSnare.wav",$2C
.end:

	align 4
SmpIns_VctrKick:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/pwm/vctrKick.wav",$2C
.end:

	align 4
SmpIns_VctrTimpani:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/pwm/vctrTimpani.wav",$2C
.end:

	align 4
SmpIns_VctrCrash:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/pwm/vctrCrash.wav",$2C
.end:

	align 4
SmpIns_VctrBrass:
	gSmpHead .end-.start,1004
.start:	binclude "sound/instr/smpl/pwm/vctrBrass.wav",$2C
.end:

	align 4
SmpIns_VctrAmbient:
	gSmpHead .end-.start,124
.start:	binclude "sound/instr/smpl/pwm/vctrBrass.wav",$2C
.end:

	align 4
SmpIns_Snare_2:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/snare_2.wav",$2C
.end:

	align 4

