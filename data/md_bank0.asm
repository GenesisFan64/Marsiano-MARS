; ====================================================================
; ----------------------------------------------------------------
; Single 68k DATA BANK for MD ($900000-$9FFFFF)
; for stuff other than MD's DMA data
; 
; Maximum size: $0FFFFF bytes per bank
; ----------------------------------------------------------------

		align $8000
		include "data/sound/tracks.asm"
		align 4
; CAMERA_INTRO:	binclude "data/mars/objects/anim/intro_anim.bin"
; 		align 4
; CAMERA_INTNAME:	binclude "data/mars/objects/anim/projcam_anim.bin"
; 		align 4
; CAMERA_CITY:	binclude "data/mars/maps/anim/camera_anim.bin"
; 		align 4

; MdMap_Bg:
; 		binclude "data/md/bg/bg_map.bin"
; 		align 2
; MdMap_BgTestB:
; 		binclude "data/md/bg/bg_b_map.bin"
; 		align 2
; MdMap_BgTestT:
; 		binclude "data/md/bg/bg_t_map.bin"
; 		align 2
;
;

; ====================================================================
; ----------------------------------------------------------------
; FM instruments go here, stored on Z80's RAM
;
; PSG instruments are set in the track's instrument list
; and DAC samples are stored in ROM
; ----------------------------------------------------------------

Fmins_Guitar_Heavy:
		binclude "data/sound/instr/fm/guitar_heavy.gsx",$2478,$20
; FmIns_Fm3_OpenHat:
; 		binclude "data/sound/instr/fm/fm3_openhat.gsx",$2478,28h
; FmIns_Fm3_ClosedHat:
; 		binclude "data/sound/instr/fm/fm3_closedhat.gsx",$2478,28h

FmIns_DrumKick:
		binclude "data/sound/instr/fm/drum_kick.gsx",$2478,$20
FmIns_DrumSnare:
		binclude "data/sound/instr/fm/drum_snare.gsx",$2478,$20
; ; FmIns_DrumCloseHat:
; ; 		binclude "data/sound/instr/fm/drum_closehat.gsx",$2478,$20
FmIns_PianoM1:
		binclude "data/sound/instr/fm/piano_m1.gsx",$2478,$20
;
; ; FmIns_Bass_gum:
; ; 		binclude "data/sound/instr/fm/bass_gum.gsx",$2478,$20
; FmIns_Bass_calm:
; 		binclude "data/sound/instr/fm/bass_calm.gsx",$2478,$20
; ; FmIns_Bass_heavy:
; ; 		binclude "data/sound/instr/fm/bass_heavy.gsx",$2478,$20
; ; FmIns_Bass_ambient:
; ; 		binclude "data/sound/instr/fm/bass_ambient.gsx",$2478,$20
; ; FmIns_Brass_gummy:
; ; 		binclude "data/sound/instr/fm/brass_gummy.gsx",$2478,$20
; ; FmIns_Flaute_1:
; ; 		binclude "data/sound/instr/fm/flaute_1.gsx",$2478,$20
FmIns_Bass_1:
		binclude "data/sound/instr/fm/bass_1.gsx",$2478,$20
FmIns_Bass_2:
		binclude "data/sound/instr/fm/bass_2.gsx",$2478,$20
FmIns_Bass_3:
		binclude "data/sound/instr/fm/bass_3.gsx",$2478,$20
FmIns_Bass_4:
		binclude "data/sound/instr/fm/bass_4.gsx",$2478,$20
FmIns_Bass_5:
		binclude "data/sound/instr/fm/bass_5.gsx",$2478,$20
FmIns_Bass_6:
		binclude "data/sound/instr/fm/bass_6.gsx",$2478,$20
FmIns_Bass_7:
		binclude "data/sound/instr/fm/bass_7.gsx",$2478,$20
FmIns_Bass_italo:
		binclude "data/sound/instr/fm/bass_italo.gsx",$2478,$20
FmIns_Bass_mecan:
		binclude "data/sound/instr/fm/bass_mecan.gsx",$2478,$20

; ; FmIns_Bass_heavy:
; ; 		binclude "data/sound/instr/fm/bass_heavy.gsx",$2478,$20
; ; FmIns_Bass_metal:
; ; 		binclude "data/sound/instr/fm/bass_metal.gsx",$2478,$20
; ; FmIns_Bass_synth:
; ; 		binclude "data/sound/instr/fm/bass_synth_1.gsx",$2478,$20
; ; FmIns_Guitar_1:
; ; 		binclude "data/sound/instr/fm/guitar_1.gsx",$2478,$20
; ; FmIns_Horn_1:
; ; 		binclude "data/sound/instr/fm/horn_1.gsx",$2478,$20
; ; FmIns_Organ_M1:
; ; 		binclude "data/sound/instr/fm/organ_m1.gsx",$2478,$20
; ; FmIns_Bass_Beach:
; ; 		binclude "data/sound/instr/fm/bass_beach.gsx",$2478,$20
; ; FmIns_Bass_Beach_2:
; ; 		binclude "data/sound/instr/fm/bass_beach_2.gsx",$2478,$20
; ; FmIns_Brass_Cave:
; ; 		binclude "data/sound/instr/fm/brass_cave.gsx",$2478,$20
; FmIns_Brass_Gem:
; 		binclude "data/sound/instr/fm/brass_gem.gsx",$2478,$20
; FmIns_Piano_Small:
; 		binclude "data/sound/instr/fm/piano_small.gsx",$2478,$20
; FmIns_Piano:
; 		binclude "data/sound/instr/fm/piano_m1.gsx",$2478,$20
FmIns_Trumpet_2:
		binclude "data/sound/instr/fm/trumpet_2.gsx",$2478,$20
; ; FmIns_Bell_Glass:
; ; 		binclude "data/sound/instr/fm/bell_glass.gsx",$2478,$20
; ; FmIns_Marimba_1:
; ; 		binclude "data/sound/instr/fm/marimba_1.gsx",$2478,$20
FmIns_Ambient_dark:
		binclude "data/sound/instr/fm/ambient_dark.gsx",$2478,$20
FmIns_Ambient_spook:
		binclude "data/sound/instr/fm/ambient_spook.gsx",$2478,$20
; FmIns_Ambient_3:
; 		binclude "data/sound/instr/fm/ambient_3.gsx",$2478,$20
FmIns_Ding_toy:
		binclude "data/sound/instr/fm/ding_toy.gsx",$2478,$20

; --------------------------------------------------------
; DAC/PWM samples
; --------------------------------------------------------

DacIns_CdSnare:
		binclude "data/sound/instr/smpl/cd_snare.wav",$2C
DacIns_CdSnare_e:

DacIns_SaurKick:
		binclude "data/sound/instr/smpl/sauron_kick.wav",$2C
DacIns_SaurKick_e:
DacIns_SaurSnare:
		binclude "data/sound/instr/smpl/sauron_snare.wav",$2C
DacIns_SaurSnare_e:

; Sampl_KickSpinb:
; 		binclude "data/sound/instr/smpl/spinb_kick.wav",$2C
; Sampl_KickSpinb_End:
;
; Sampl_Kick:	binclude "data/sound/instr/smpl/stKick.wav",$2C
; Sampl_Kick_End:
; Sampl_Snare:	binclude "data/sound/instr/smpl/snare.wav",$2C
; Sampl_Snare_End:

PCM_START:	binclude "data/sound/test_md.wav",$2C,$03FFFF
PCM_END:
