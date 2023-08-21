; ====================================================================
; --------------------------------------------------------
; GEMA/Nikona PWM instruments ROM AREA (Cartridge ONLY)
;
; *** PUT align 4 AT THE TOP OF EVERY LABEL ***
; --------------------------------------------------------

; Special sample data macro
; gSmpHead macro len,loop
; 	dc.b ((len)&$FF),(((len)>>8)&$FF),(((len)>>16)&$FF)	; length
; 	dc.b ((loop)&$FF),(((loop)>>8)&$FF),(((loop)>>16)&$FF)
; 	endm

; 	align 4
; SmpIns_TEST:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/test_st.wav",$2C
; .end:
; 	align 4



