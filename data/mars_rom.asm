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
; PWM_STEREO:	binclude "sound/test_mars.wav",$2C,$200000
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
