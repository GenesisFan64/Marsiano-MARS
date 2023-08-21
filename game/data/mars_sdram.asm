; ====================================================================
; ----------------------------------------------------------------
; SH2 SDRAM data
; 
; This data is stored on SDRAM, always available to use on the 32X
; side and can be rewritible, but it is smaller than ROM
;
; PWM samples can be used here but those take a lot of space...
; use ROM (mars_rom.asm) instead, those are RV-protected on SH2
; ----------------------------------------------------------------

		align 4
		include "sound/smpl_pwm.asm"		; GEMA: PWM samples
ArtMars_TEST:
		binclude "game/data/TESTS/mars_art.bin"
		align 4



; SmpIns_TEST:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/test.wav",$2C
; .end:
;
; 	align 4

; SmpIns_TEST:
; 	gSmpHead .end-.start,0
; .start:	binclude "sound/instr/smpl/test.wav",$2C;,$4000
; .end:
; 	align 4
; TEST_DMA:
; ; 	if MARS
; 	binclude "bodytalk_dma.wav",$2C,$4000
; ; 	endif
; TEST_DMA_e:
; 	align 4

