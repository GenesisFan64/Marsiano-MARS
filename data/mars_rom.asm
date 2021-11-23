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
; Textures
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

; 		align 4
; 		include "data/mars/maps/map_marscity.asm"
; 		align 4
; 		include "data/mars/objects/mdl/projname/head.asm"
; 		align 4

; Textr_marscity:
; 		binclude "data/mars/maps/mtrl/marscity_art.bin"
; 		align 4
; Textr_projname:
; 		binclude "data/mars/objects/mtrl/projname_art.bin"
; 		align 4
; Textr_intro:
; 		binclude "data/mars/objects/mtrl/intro_art.bin"
; 		align 4

TESTMARS_BG:
		binclude "data/mars/test_art.bin"
		align 4
TESTMARS_BG_PAL:
		binclude "data/mars/test_pal.bin"
		align 4
; PWM_STEREO:	binclude "sound/TEST_MARS.wav",$2C
; PWM_STEREO_e:
; 		align 4
; PwmInsWav_SPHEAVY1:
; 		binclude "data/sound/instr/smpl/SPHEAVY1.wav",$2C
; PwmInsWav_SPHEAVY1_e:
; 		align 4
; PwmInsWav_MCLSTRNG:
; 		binclude "data/sound/instr/smpl/MCLSTRNG.wav",$2C
; PwmInsWav_MCLSTRNG_e:
; 		align 4
; PwmInsWav_WHODSNARE:
; 		binclude "data/sound/instr/smpl/ST-79_whodini-snare.wav",$2C
; PwmInsWav_WHODSNARE_e:
; 		align 4
; PwmInsWav_TECHNOBASSD:
; 		binclude "data/sound/instr/smpl/ST-72_techno-bassd3.wav",$2C
; PwmInsWav_TECHNOBASSD_e:
; 		align 4
; PwmInsWav_Synth:
; 		binclude "data/sound/instr/smpl/amiga_synth.wav",$2C
; PwmInsWav_Synth_e:
; 		align 4
; PwmInsWav_Piano:
; 		binclude "data/sound/instr/smpl/piano_1.wav",$2C
; PwmInsWav_Piano_e:
; 		align 4
; PwmInsWav_String:
; 		binclude "data/sound/instr/smpl/string_1.wav",$2C
; PwmInsWav_String_e:
; 		align 4
