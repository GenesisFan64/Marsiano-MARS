; ====================================================================
; --------------------------------------------------------
; GEMA/Nikona DAC instruments "digital"
;
; This must be located at the 68k's 900000 area.
; ** 68K BANK 0 only **
;
; BASE Samplerate is at 16000hz
; --------------------------------------------------------

; Special sample data macro
gSmpHead macro len,loop
	dc.b ((len)&$FF),(((len)>>8)&$FF),(((len)>>16)&$FF)	; length
	dc.b ((loop)&$FF),(((loop)>>8)&$FF),(((loop)>>16)&$FF)
	endm

	align $8000	; <-- just to be safe.
DacIns_wegot_crash:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/wegot_crash.wav",$2C
.end:
DacIns_wegot_kick:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/wegot_kick.wav",$2C
.end:
DacIns_Snare_1:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/snare_1.wav",$2C
.end:

DacIns_TESTINS:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/test.wav",$2C
.end:

; TEST SAMPLE
TEST_WAVE:
	binclude "sound/instr/smpl/test.wav",$2C
TEST_WAVE_E:
	align 2
