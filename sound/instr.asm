; ====================================================================
; FM instrument patches
;
; This must be located at the 900000 area.
;
; And the 68K BANK set to 0 currently.
; ====================================================================

; Savestate FM data at: $2478
;
; Sizes:
; Normal FM ins: $20
; Special FM ins: $28

; FM3 Special
FmIns_Fm3_OpenHat:
		binclude "sound/instr/fm/fm3_openhat.gsx",$2478,$28
FmIns_Fm3_ClosedHat:
		binclude "sound/instr/fm/fm3_closedhat.gsx",$2478,$28
FmIns_Fm3_Explosion:
		binclude "sound/instr/fm/fm3_sfx_boomworm.gsx",$2478,$28
FmIns_Bass_Oil:	binclude "sound/instr/fm/bass_oil.gsx",$2478,$20

FmIns_Organ_Ito:
		binclude "sound/instr/fm/organ_ito.gsx",$2478,$20
FmIns_Ding_Baseball:
		binclude "sound/instr/fm/ding_baseball.gsx",$2478,$20

; FmIns_Guitar_gem:
; 		binclude "sound/instr/fm/guitar_gem.gsx",$2478,$20
; Fmins_Guitar_Heavy:
; 		binclude "sound/instr/fm/guitar_heavy.gsx",$2478,$20
; Fmins_Guitar_puy:
; 		binclude "sound/instr/fm/guitar_puy.gsx",$2478,$20
; Fmins_Guitar_puy_2:
; 		binclude "sound/instr/fm/guitar_puy_2.gsx",$2478,$20
FmIns_DrumKick_gem:
		binclude "sound/instr/fm/drum_kick_gem.gsx",$2478,$20
;
; ; FmIns_DrumKick:
; ; 		binclude "sound/instr/fm/drum_kick.gsx",$2478,$20
; ; FmIns_DrumSnare:
; ; 		binclude "sound/instr/fm/drum_snare.gsx",$2478,$20
; ; ; ; FmIns_DrumCloseHat:
; ; ; ; 		binclude "sound/instr/fm/drum_closehat.gsx",$2478,$20
FmIns_PianoM1:
		binclude "sound/instr/fm/piano_m1.gsx",$2478,$20
; ; FmIns_PianoM116:
; ; 		binclude "sound/instr/fm/piano_m116.gsx",$2478,$20
;
; ; ;
; ; ; ; FmIns_Bass_gum:
; ; ; ; 		binclude "sound/instr/fm/bass_gum.gsx",$2478,$20
FmIns_Bass_calm:
		binclude "sound/instr/fm/bass_calm.gsx",$2478,$20
; FmIns_Bass_heavy:
; 		binclude "sound/instr/fm/bass_heavy.gsx",$2478,$20
; FmIns_Bass_ambient:
; 		binclude "sound/instr/fm/bass_ambient.gsx",$2478,$20
; ; ; FmIns_Brass_gummy:
; ; ; 		binclude "sound/instr/fm/brass_gummy.gsx",$2478,$20
; FmIns_Flaute_1:
; 		binclude "sound/instr/fm/flaute_1.gsx",$2478,$20
FmIns_Bass_1:
		binclude "sound/instr/fm/bass_low.gsx",$2478,$20
FmIns_Bass_2:
		binclude "sound/instr/fm/bass_strong.gsx",$2478,$20
; FmIns_Bass_3:
; 		binclude "sound/instr/fm/bass_3.gsx",$2478,$20
; FmIns_Bass_4:
; 		binclude "sound/instr/fm/bass_4.gsx",$2478,$20
; FmIns_Bass_5:
; 		binclude "sound/instr/fm/bass_5.gsx",$2478,$20
FmIns_Bass_club:
		binclude "sound/instr/fm/bass_club.gsx",$2478,$20
FmIns_Bass_donna:
		binclude "sound/instr/fm/bass_feellove.gsx",$2478,$20
FmIns_Bass_groove:
		binclude "sound/instr/fm/bass_groove.gsx",$2478,$20
FmIns_Bass_groove_2:
		binclude "sound/instr/fm/bass_groove_2.gsx",$2478,$20
FmIns_Bass_groove_gem:
		binclude "sound/instr/fm/bass_groove_gem.gsx",$2478,$20
FmIns_Bass_italo:
		binclude "sound/instr/fm/bass_italo.gsx",$2478,$20
FmIns_Bass_duck:
		binclude "sound/instr/fm/bass_duck.gsx",$2478,$20

; FmIns_Bass_kon:
; 		binclude "sound/instr/fm/bass_kon.gsx",$2478,$20

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
; FmIns_Organ_M1:
; 		binclude "sound/instr/fm/organ_m1.gsx",$2478,$20
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
FmIns_Piano_Aqua:
		binclude "sound/instr/fm/piano_aqua.gsx",$2478,$20

FmIns_Trumpet_1:
		binclude "sound/instr/fm/trumpet_1.gsx",$2478,$20
FmIns_Trumpet_2:
		binclude "sound/instr/fm/trumpet_2.gsx",$2478,$20
FmIns_Trumpet_kon:
		binclude "sound/instr/fm/trumpet_kon.gsx",$2478,$20
; FmIns_Trumpet_puy:
; 		binclude "sound/instr/fm/trumpet_puy.gsx",$2478,$20
FmIns_Trumpet_carnival:
		binclude "sound/instr/fm/trumpet_carnivl.gsx",$2478,$20

; FmIns_Bell_Glass:
; 		binclude "sound/instr/fm/bell_glass.gsx",$2478,$20
FmIns_Marimba:
		binclude "sound/instr/fm/marimba.gsx",$2478,$20

FmIns_Ambient_dark:
		binclude "sound/instr/fm/ambient_dark.gsx",$2478,$20
FmIns_Ambient_spook:
		binclude "sound/instr/fm/ambient_spook.gsx",$2478,$20
FmIns_Ambient_3:
		binclude "sound/instr/fm/ambient_3.gsx",$2478,$20
FmIns_Ding_toy:
		binclude "sound/instr/fm/ding_toy.gsx",$2478,$20
; FmIns_Bell_China:
; 		binclude "sound/instr/fm/bell_china.gsx",$2478,$20
FmIns_Brass_Eur:
		binclude "sound/instr/fm/brass_eur.gsx",$2478,$20
FmIns_Brass_Puy:
		binclude "sound/instr/fm/brass_puy.gsx",$2478,$20
FmIns_Flaute_cave:
		binclude "sound/instr/fm/flaute_sea.gsx",$2478,$20
FmIns_Banjo_puy:
		binclude "sound/instr/fm/banjo_puy.gsx",$2478,$20
; FmIns_Violin_gem:
; 		binclude "sound/instr/fm/violin_gem.gsx",$2478,$20

FmIns_PSynth_plus:
		binclude "sound/instr/fm/psynth_plus.gsx",$2478,$20
FmIns_Ding_1:
		binclude "sound/instr/fm/ding_gem.gsx",$2478,$20
FmIns_Trombone_gem:
		binclude "sound/instr/fm/trombone_gem.gsx",$2478,$20
