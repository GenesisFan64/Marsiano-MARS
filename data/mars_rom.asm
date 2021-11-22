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

		align 4

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

SmpIns_Beats_1:
	gSmpl "sound/instr/smpl/beats_1.wav",0
SmpIns_Beats_2:
	gSmpl "sound/instr/smpl/beats_2.wav",0
SmpIns_KickFunk:
	gSmpl "sound/instr/smpl/kick_funk.wav",0
SmpIns_SnareClash:
	gSmpl "sound/instr/smpl/snare_clash.wav",0
SmpIns_Atmosphere_1:
	gSmpl "sound/instr/smpl/atmosphere_1.wav",53456
SmpIns_Brass_1:
	gSmpl "sound/instr/smpl/brass_1.wav",0
SmpIns_Lead_Guitar:
	gSmpl "sound/instr/smpl/lead_guitar.wav",11812
SmpIns_Revolution:
	gSmpl "sound/instr/smpl/revolution.wav",0
SmpIns_ViolinIguan:
	gSmpl "sound/instr/smpl/violin_iguan.wav",132

PWM_STEREO:	binclude "sound/TEST_MARS.wav",$2C,$300000
PWM_STEREO_e:
		align 4
