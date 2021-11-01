; ====================================================================
; ----------------------------------------------------------------
; PSG, FM and DAC instruments go here
; ----------------------------------------------------------------

; Fmins_Guitar_Heavy:
; 		binclude "sound/instr/fm/guitar_heavy.gsx",$2478,$20
FmIns_Brass_Eur:
		binclude "sound/instr/fm/brass_eur.gsx",$2478,$20
;
FmIns_Fm3_OpenHat:
		binclude "sound/instr/fm/fm3_openhat.gsx",$2478,$28
FmIns_Fm3_ClosedHat:
		binclude "sound/instr/fm/fm3_closedhat.gsx",$2478,$28
;
; FmIns_DrumKick_gem:
; 		binclude "sound/instr/fm/drum_kick_gem.gsx",$2478,$20
;
; FmIns_DrumKick:
; 		binclude "sound/instr/fm/drum_kick.gsx",$2478,$20
; FmIns_DrumSnare:
; 		binclude "sound/instr/fm/drum_snare.gsx",$2478,$20
; ; ; FmIns_DrumCloseHat:
; ; ; 		binclude "sound/instr/fm/drum_closehat.gsx",$2478,$20
; FmIns_PianoM1:
; 		binclude "sound/instr/fm/piano_m1.gsx",$2478,$20
; ;
; ; ; FmIns_Bass_gum:
; ; ; 		binclude "sound/instr/fm/bass_gum.gsx",$2478,$20
FmIns_Bass_calm:
		binclude "sound/instr/fm/bass_calm.gsx",$2478,$20
; FmIns_Bass_heavy:
; 		binclude "sound/instr/fm/bass_heavy.gsx",$2478,$20
; ; ; FmIns_Bass_ambient:
; ; ; 		binclude "sound/instr/fm/bass_ambient.gsx",$2478,$20
; ; ; FmIns_Brass_gummy:
; ; ; 		binclude "sound/instr/fm/brass_gummy.gsx",$2478,$20
; ; ; FmIns_Flaute_1:
; ; ; 		binclude "sound/instr/fm/flaute_1.gsx",$2478,$20
; FmIns_Bass_1:
; 		binclude "sound/instr/fm/bass_1.gsx",$2478,$20
; FmIns_Bass_2:
; 		binclude "sound/instr/fm/bass_2.gsx",$2478,$20
; FmIns_Bass_3:
; 		binclude "sound/instr/fm/bass_3.gsx",$2478,$20
; FmIns_Bass_4:
; 		binclude "sound/instr/fm/bass_4.gsx",$2478,$20
; FmIns_Bass_5:
; 		binclude "sound/instr/fm/bass_5.gsx",$2478,$20
; FmIns_Bass_6:
; 		binclude "sound/instr/fm/bass_6.gsx",$2478,$20
FmIns_Bass_groove:
		binclude "sound/instr/fm/bass_groove.gsx",$2478,$20
; FmIns_Bass_italo:
; 		binclude "sound/instr/fm/bass_italo.gsx",$2478,$20
; FmIns_Bass_mecan:
; 		binclude "sound/instr/fm/bass_mecan.gsx",$2478,$20
;
; ; ; FmIns_Bass_heavy:
; ; ; 		binclude "sound/instr/fm/bass_heavy.gsx",$2478,$20
; ; ; FmIns_Bass_metal:
; ; ; 		binclude "sound/instr/fm/bass_metal.gsx",$2478,$20
; FmIns_Bass_synth:
; 		binclude "sound/instr/fm/bass_synth_1.gsx",$2478,$20
; FmIns_Guitar_1:
; 		binclude "sound/instr/fm/guitar_1.gsx",$2478,$20
; ; ; FmIns_Horn_1:
; ; ; 		binclude "sound/instr/fm/horn_1.gsx",$2478,$20
FmIns_Organ_M1:
		binclude "sound/instr/fm/organ_m1.gsx",$2478,$20
; ; ; FmIns_Bass_Beach:
; ; ; 		binclude "sound/instr/fm/bass_beach.gsx",$2478,$20
; ; ; FmIns_Bass_Beach_2:
; ; ; 		binclude "sound/instr/fm/bass_beach_2.gsx",$2478,$20
; ; ; FmIns_Brass_Cave:
; ; ; 		binclude "sound/instr/fm/brass_cave.gsx",$2478,$20
; ; FmIns_Brass_Gem:
; ; 		binclude "sound/instr/fm/brass_gem.gsx",$2478,$20
; ; FmIns_Piano_Small:
; ; 		binclude "sound/instr/fm/piano_small.gsx",$2478,$20
; ; FmIns_Piano:
; ; 		binclude "sound/instr/fm/piano_m1.gsx",$2478,$20
FmIns_Trumpet_2:
		binclude "sound/instr/fm/trumpet_2.gsx",$2478,$20
; ; ; FmIns_Bell_Glass:
; ; ; 		binclude "sound/instr/fm/bell_glass.gsx",$2478,$20
; ; ; FmIns_Marimba_1:
; ; ; 		binclude "sound/instr/fm/marimba_1.gsx",$2478,$20

FmIns_Ambient_dark:
		binclude "sound/instr/fm/ambient_dark.gsx",$2478,$20
FmIns_Ambient_spook:
		binclude "sound/instr/fm/ambient_spook.gsx",$2478,$20
; FmIns_Ambient_3:
; 		binclude "sound/instr/fm/ambient_3.gsx",$2478,$20
FmIns_Ding_toy:
		binclude "sound/instr/fm/ding_toy.gsx",$2478,$20
FmIns_Bell_China:
		binclude "sound/instr/fm/bell_china.gsx",$2478,$20

; --------------------------------------------------------
; DAC samples
; --------------------------------------------------------

 align $8000
DacIns_Magic1:
		binclude "sound/instr/smpl/magic_1.wav",$2C
DacIns_Magic1_e:
DacIns_Magic2:
		binclude "sound/instr/smpl/magic_2.wav",$2C
DacIns_Magic2_e:

DacIns_Snare_Gem:
		binclude "sound/instr/smpl/snare_lobo.wav",$2C
DacIns_Snare_Gem_e:

DacIns_CdSnare:
		binclude "sound/instr/smpl/cd_snare.wav",$2C
DacIns_CdSnare_e:

DacIns_SaurKick:
		binclude "sound/instr/smpl/sauron_kick.wav",$2C
DacIns_SaurKick_e:
DacIns_SaurSnare:
		binclude "sound/instr/smpl/sauron_snare.wav",$2C
DacIns_SaurSnare_e:
DacIns_SaurTom:
		binclude "sound/instr/smpl/sauron_tom.wav",$2C
DacIns_SaurTom_e:

; Sampl_KickSpinb:
; 		binclude "sound/instr/smpl/spinb_kick.wav",$2C
; Sampl_KickSpinb_End:
;
; Sampl_Kick:	binclude "sound/instr/smpl/stKick.wav",$2C
; Sampl_Kick_End:
; Sampl_Snare:	binclude "sound/instr/smpl/snare.wav",$2C
; Sampl_Snare_End:

PCM_START:	binclude "sound/TEST_MD.wav",$2C,$90000
PCM_END:
