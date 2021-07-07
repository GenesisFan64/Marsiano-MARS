; ====================================================================
; ----------------------------------------------------------------
; PSG, FM, FM3, DAC instruments go here.
; Stored on Z80's RAM space
; 
; NOTE: Very low storage space
; ----------------------------------------------------------------

zSmpl 		macro start,end,loop,flags
		db start&0FFh,((start>>8)&0FFh),((start>>16)&0FFh)
		db ((end-start)&0FFh),(((end-start)>>8)&0FFh),(((end-start)>>16)&0FFh)
		db loop&0FFh,((loop>>8)&0FFh),((loop>>16)&0FFh)
		db 0
		endm

DacIns_Magic1:	zSmpl Sampl_Magic1,Sampl_Magic1_End,0
DacIns_Magic2:	zSmpl Sampl_Magic2,Sampl_Magic2_End,0
DacIns_MyTime:	zSmpl Sampl_MyTime,Sampl_MyTime_End,0

PsgIns_00:	db 00h,0FFh,40h,00h, 80h
PsgIns_01:	db 00h,0FFh,00h,03h, 03h
PsgIns_02:	db 00h,0FFh,80h,04h, 04h
PsgIns_03:	db 30h,0FFh, -1,00h, 04h
PsgIns_Bass:	db 00h,0FFh, -1,01h, 01h
PsgIns_Snare:	db 00h,0FFh,00h,0F0h,0F0h

Fmins_Guitar_Heavy:
		binclude "data/sound/instr/fm/guitar_heavy.gsx",2478h,28h
FmIns_Fm3_OpenHat:
		binclude "data/sound/instr/fm/fm3_openhat.gsx",2478h,28h
FmIns_Fm3_ClosedHat:
		binclude "data/sound/instr/fm/fm3_closedhat.gsx",2478h,28h
		
FmIns_DrumKick:
		binclude "data/sound/instr/fm/drum_kick.gsx",2478h,20h
; FmIns_DrumSnare:
; 		binclude "data/sound/instr/fm/drum_snare.gsx",2478h,20h
; FmIns_DrumCloseHat:
; 		binclude "data/sound/instr/fm/drum_closehat.gsx",2478h,20h
; FmIns_Piano_m1:
; 		binclude "data/sound/instr/fm/piano_m1.gsx",2478h,20h

; FmIns_Bass_gum:
; 		binclude "data/sound/instr/fm/bass_gum.gsx",2478h,20h
FmIns_Bass_calm:
		binclude "data/sound/instr/fm/bass_calm.gsx",2478h,20h
; FmIns_Bass_heavy:
; 		binclude "data/sound/instr/fm/bass_heavy.gsx",2478h,20h
; FmIns_Bass_ambient:
; 		binclude "data/sound/instr/fm/bass_ambient.gsx",2478h,20h
; FmIns_Brass_gummy:
; 		binclude "data/sound/instr/fm/brass_gummy.gsx",2478h,20h
; FmIns_Flaute_1:
; 		binclude "data/sound/instr/fm/flaute_1.gsx",2478h,20h
; FmIns_Bass_1:
; 		binclude "data/sound/instr/fm/bass_2.gsx",2478h,20h
; FmIns_Bass_2:
; 		binclude "data/sound/instr/fm/bass_2.gsx",2478h,20h
; FmIns_Bass_3:
; 		binclude "data/sound/instr/fm/bass_3.gsx",2478h,20h
; FmIns_Bass_4:
; 		binclude "data/sound/instr/fm/bass_4.gsx",2478h,20h
; FmIns_Bass_5:
; 		binclude "data/sound/instr/fm/bass_5.gsx",2478h,20h
; FmIns_Bass_6:
; 		binclude "data/sound/instr/fm/bass_6.gsx",2478h,20h
; FmIns_Bass_7:
; 		binclude "data/sound/instr/fm/bass_7.gsx",2478h,20h
; FmIns_Bass_heavy:
; 		binclude "data/sound/instr/fm/bass_heavy.gsx",2478h,20h
; FmIns_Bass_metal:
; 		binclude "data/sound/instr/fm/bass_metal.gsx",2478h,20h
; FmIns_Bass_synth:
; 		binclude "data/sound/instr/fm/bass_synth_1.gsx",2478h,20h
; FmIns_Guitar_1:
; 		binclude "data/sound/instr/fm/guitar_1.gsx",2478h,20h
; FmIns_Horn_1:
; 		binclude "data/sound/instr/fm/horn_1.gsx",2478h,20h
; FmIns_Organ_M1:
; 		binclude "data/sound/instr/fm/organ_m1.gsx",2478h,20h
; FmIns_Bass_Beach:
; 		binclude "data/sound/instr/fm/bass_beach.gsx",2478h,20h
; FmIns_Bass_Beach_2:
; 		binclude "data/sound/instr/fm/bass_beach_2.gsx",2478h,20h
; FmIns_Brass_Cave:
; 		binclude "data/sound/instr/fm/brass_cave.gsx",2478h,20h
FmIns_Brass_Gem:
		binclude "data/sound/instr/fm/brass_gem.gsx",2478h,20h
FmIns_Piano_Small:
		binclude "data/sound/instr/fm/piano_small.gsx",2478h,20h
FmIns_Piano:
		binclude "data/sound/instr/fm/piano_m1.gsx",2478h,20h
FmIns_Trumpet_2:
		binclude "data/sound/instr/fm/trumpet_2.gsx",2478h,20h
; FmIns_Bell_Glass:
; 		binclude "data/sound/instr/fm/bell_glass.gsx",2478h,20h
; FmIns_Marimba_1:
; 		binclude "data/sound/instr/fm/marimba_1.gsx",2478h,20h
FmIns_Ambient_dark:
		binclude "data/sound/instr/fm/ambient_dark.gsx",2478h,20h
FmIns_Ambient_spook:
		binclude "data/sound/instr/fm/ambient_spook.gsx",2478h,20h
FmIns_Ambient_3:
		binclude "data/sound/instr/fm/ambient_3.gsx",2478h,20h
; FmIns_Ding_toy:
; 		binclude "data/sound/instr/fm/ding_toy.gsx",2478h,20h
