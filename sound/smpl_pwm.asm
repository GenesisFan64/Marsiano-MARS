; ====================================================================
; --------------------------------------------------------
; GEMA/Nikona PWM instruments
;
; Located at SDRAM, SAMPLES MUST BE SMALL
;
; *** PUT align 4 AT THE TOP OF EVERY LABEL ***
; --------------------------------------------------------



	align 4

; Special sample data macro
; gSmpHead macro len,loop
; 	dc.b ((len)&$FF),(((len)>>8)&$FF),(((len)>>16)&$FF)	; length
; 	dc.b ((loop)&$FF),(((loop)>>8)&$FF),(((loop)>>16)&$FF)
; 	endm

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
SmpIns_Snare_2:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/snare_2.wav",$2C
.end:
	align 4

; SmpIns_TEST:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/test_st.wav",$2C,$10000
; .end:
; 	align 4



