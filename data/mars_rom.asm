; ====================================================================
; ----------------------------------------------------------------
; SH2 ROM user data
; 
; If your data is too much for SDRAM, place it here.
; Note that this section will be gone if the Genesis side is
; perfoming a DMA ROM-to-VDP Transfer (setting RV=1)
; 
; Note: Reading data from here is slow on hardware
; ----------------------------------------------------------------

; --------------------------------------------------------

TESTMARS_BG:
		binclude "data/mars/test_art.bin"
		align 4
TESTMARS_BG_PAL:
		binclude "data/mars/test_pal.bin"
		align 4

; --------------------------------------------------------
; PWM samples
; --------------------------------------------------------

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

; --------------------------------------------------------

; PWM_STEREO:	binclude "sound/TEST_MARS.wav",$2C,$240000
; PWM_STEREO_e:
; 		align 4
