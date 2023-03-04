; ================================================================
; ------------------------------------------------------------
; DATA SECTION
;
; SOUND
; ------------------------------------------------------------

; ticks - %gttttttt
;   loc - 68k pointer
;
; t-Ticks
; g-Use global tempo
gemaTrk macro ticks,loc
	dc.l ((ticks&$FF)<<24)|loc
	endm

; gemaHead
; block point, patt point, ins point
; numof_blocks,numof_patts,numof_ins
gemaHead macro blk,pat,ins
	dc.l blk
	dc.l pat
	dc.l ins
	endm

; Instrument macros
; do note that some 24-bit pointers add 90h to the MSB automaticly.
gInsNull macro
	dc.b $00,$00,$00,$00
	dc.b $00,$00,$00,$00
	endm

; alv: attack level
; atk: attack rate
; slv: sustain
; dky: decay rate (up)
; rrt: release rate (down)
; vib: (TODO)
gInsPsg	macro pitch,alv,atk,slv,dky,rrt,vib
	dc.b $80,pitch,alv,atk
	dc.b slv,dky,rrt,vib
	endm

; same args as gInsPsg
; only one more argument for the noise type:
; mode: noise mode
;       %tmm
;        t  - Bass(0)|Noise(1)
;         mm- Clock(0)|Clock/2(1)|Clock/4(2)|Tone3(3)
;
gInsPsgN macro pitch,alv,atk,slv,dky,rrt,vib,mode
	dc.b $90|mode,pitch,alv,atk
	dc.b slv,dky,rrt,vib
	endm

; 24-bit ROM pointer to FM patch data
gInsFm macro pitch,fmins
	dc.b $A0,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; Same args as gInsFm, but the last 4 words of the data
; are the custom freqs for each operator in this order:
; OP1 OP2 OP3 OP4
;
; NOTE: pitch is useless here...
gInsFm3	macro pitch,fmins
	dc.b $B0,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; start: Pointer to sample data:
;        dc.b end,end,end	; 24-bit LENGTH of the sample
;        dc.b loop,loop,loop	; 24-bit Loop point
;        dc.b (sound data)	; <-- Then the actual sound data
;
; flags: $00 - No Loop
; 	 $01 - Loop
gInsDac	macro pitch,start,flags
	dc.b $C0|flags,pitch,((start>>16)&$FF),((start>>8)&$FF)
	dc.b start&$FF,0,0,0
	endm

; start: Pointer to sample data:
;        dc.b end,end,end	; 24-bit LENGTH of the sample
;        dc.b loop,loop,loop	; 24-bit Loop point
;        dc.b (data)		; Then the actual sound data
;
; flags: %00SL
;            L - Loop sample No/Yes
;           S  - Sample data is on STEREO
gInsPwm	macro pitch,start,flags
 if MARS
	dc.b $D0|flags,pitch,((start>>24)&$FF),((start>>16)&$FF)
	dc.b ((start>>8)&$FF),start&$FF,0,0
 else
	dc.b $00,$00,$00,$00
	dc.b $00,$00,$00,$00
 endif
	endm

; ------------------------------------------------------------

	align $8000

; ------------------------------------------------------------
; Nikona MAIN track-list
;
; ONLY the ticks can be set here.
; You can change the ticks mid-track using effect A
;
; Add $80 to the ticks value to use the GLOBAL
; sub-beats
;
; To set the sub-beats send the SetBeats command
; BEFORE playing your track:
; 	move.w	#new_beats,d0
; 	bsr	gemaSetBeats
; 	move.w	#track_id,d0
;	bsr	gemaPlayTrack
; ------------------------------------------------------------

Gema_MasterList:
	gemaTrk 3,GemaTrk_TEST_0	; Ticks, Track pointer (Default tempo: 150/120)
	gemaTrk $80|6,GemaTrk_BodyOver
	gemaTrk 7,GemaTrk_MOVEME
	gemaTrk 4,GemaTrk_xtrim
	gemaTrk $80|3,GemaTrk_TEST_6
	gemaTrk 7,GemaTrk_TEST_1
	gemaTrk $80|3,GemaTrk_TEST_2
	gemaTrk 3,GemaTrk_TEST_3
	gemaTrk 3,GemaTrk_TEST_4
	gemaTrk 3,GemaTrk_TEST_5
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0

	gemaTrk $80|4,GemaTrk_TEST_1
	gemaTrk $80|2,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0

; ------------------------------------------------------------
; BGM tracks
; ------------------------------------------------------------

GemaTrk_TEST_2:
	gemaHead .blk,.pat,.ins
.blk:
	binclude "sound/tracks/wegot_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/wegot_patt.bin"
	align 2
.ins:
	gInsFm 0,FmIns_Synth_plus
	gInsFm 0,FmIns_Bass_4
	gInsDac 0,DacIns_wegot_kick,0
	gInsFm 0,FmIns_Bass_club
	gInsFm3 0,FmIns_Sp_Openhat
	gInsPsg 0,$10,$04,$20,$04,$02,$00;gInsFm -12,FmIns_Trumpet_carnival;;
	gInsDac 0,DacIns_wegot_crash,0

GemaTrk_TEST_1:
	gemaHead .blk,.pat,.ins
.blk:
	binclude "sound/tracks/vectr_blk.bin"
.pat:
	binclude "sound/tracks/vectr_patt.bin"
.ins:
	gInsPwm -17,SmpIns_Vctr01,%001
	gInsFm -3,FmIns_brass_eur
	gInsPwm -15,SmpIns_VctrCrash,0
	gInsPwm -17,SmpIns_Vctr04,%001
	gInsNull
	gInsPwm -15,SmpIns_VctrTimpani,%101
	gInsFm -22,FmIns_Bass_8
	gInsPsg 0,$40,$08,$10,$01,$01,$00
	gInsNull;gInsPsgN 0,$40,$08,$10,$01,$01,$00,%110
	gInsPwm -17,SmpIns_VctrSnare,%000
	gInsPwm -17,SmpIns_VctrKick,%000
	gInsFm3 0,FmIns_Sp_Closedhat
	gInsFm3 0,FmIns_Sp_Openhat
	gInsPwm -17,SmpIns_VctrBrass,%001
.ins_e:

GemaTrk_TEST_3:
	gemaHead .blk,.pat,.ins
.blk:
	binclude "sound/tracks/gigalo_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/gigalo_patt.bin"
	align 2
.ins:
	gInsPsg 0,$10,$04,$20,$06,$08,$00
	gInsPsgN 0,$00,$00,$00,$04,$20,$00,%100
	gInsPsgN 0,$00,$00,$00,$04,$20,$00,%101
	gInsPsgN 0,$00,$00,$00,$04,$40,$00,%110

GemaTrk_TEST_4:
	gemaHead .blk,.pat,.ins
.blk:
	binclude "sound/tracks/temple_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/temple_patt.bin"
	align 2
.ins:
	gInsPsg 0,$00,$08,$20,$06,$03,$00
	gInsPsg 0,$00,$00,$30,$04,$04,$00
	gInsPsgN 0,$00,$30,$08,$10,$38,$01,%101

GemaTrk_TEST_5:
	gemaHead .blk,.pat,.ins
.blk:
	binclude "sound/tracks/brinstr_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/brinstr_patt.bin"
	align 2
.ins:
	gInsPsg 0,$40,$08,$20,$01,$04,$00
	gInsPsgN 0,$10,$08,$20,$02,$01,$00,%011

GemaTrk_TEST_6:
	gemaHead .blk,.pat,.ins
.blk:
	binclude "sound/tracks/cirno_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/cirno_patt.bin"
	align 2
.ins:
	gInsFm -12,FmIns_PianoM1
	gInsNull
	gInsFm -12,FmIns_Bass_4
	gInsPsgN 0,$00,$00,$00,$00,$40,$00,%110
	gInsDac +12,DacIns_wegot_kick,0
	gInsDac +12,DacIns_wegot_kick,0
	gInsPsgN 0,$00,$00,$00,$00,$40,$00,%110
	gInsPsgN 0,$00,$00,$00,$00,$08,$00,%100
	gInsDac +6,DacIns_Snare_1,0
	gInsFm -12,FmIns_Marimba
	gInsPsg 0,$10,$20,$40,$01,$01,$00
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull

; ------------------------------------------------------------

GemaTrk_BodyOver:
	gemaHead .blk,.pat,.ins
.blk:
	binclude "sound/tracks/bodyover_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/bodyover_patt.bin"
	align 2
.ins:
	gInsPwm 0,SmpIns_Nadie,%10
	gInsPwm 0,SmpIns_Kick,%10
	gInsPwm 0,SmpIns_Snare_2,%00
	gInsFm -24,FmIns_Bass_groove_2
	gInsFm -36,FmIns_Ding_Baseball
	gInsFm 0,FmIns_Trumpet_1
	gInsFm3 0,FmIns_Sp_ClosedHat
	gInsFm3 0,FmIns_Sp_OpenHat
	gInsPsg +12,$00,$00,$00,$00,$02,0

GemaTrk_MOVEME:
	gemaHead .blk,.pat,.ins
.blk:
	binclude "sound/tracks/moveme_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/moveme_patt.bin"
	align 2
.ins:
	gInsPwm 0,SmpIns_MoveMe_Hit,%10
	gInsFm 0,FmIns_Bass_Duck
	gInsPwm 0,SmpIns_MoveMe_Brass,%11
	gInsFm 0,FmIns_ClosedHat
	gInsPsgN 0,$00,$00,$00,$00,$04,0,%110
	gInsFm -12,FmIns_HBeat_tom
	gInsPwm 0,SmpIns_Snare_moveme,%10
	gInsPwm 0,SmpIns_Kick,%10
	gInsFm -12,FmIns_Trumpet_carnival
	gInsPsg 0,$20,$20,$10,$01,$08,0
	gInsFm3 0,FmIns_Sp_OpenHat
	gInsNull;gInsPwm -17,SmpIns_MyTime,%10
	gInsPsg +12,$20,$10,$10,$0C,$0C,0
	gInsPsg 0,$00,$00,$00,$00,$06,0
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull

GemaTrk_xtrim:
	gemaHead .blk,.pat,.ins
.blk:
	binclude "sound/tracks/xtrim_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/xtrim_patt.bin"
	align 2
.ins:
	gInsFm 0,FmIns_Bass_calm
	gInsFm 0,FmIns_ClosedHat
	gInsPsg 0,$00,$20,$00,$04,$04,0
	gInsFm3 0,FmIns_Sp_OpenHat
	gInsDac 0,DacIns_wegot_kick,%10

; ------------------------------------------------------------
; FIRST TRACK

GemaTrk_TEST_0:
	gemaHead .blk,.pat,.ins

; Max. 24 blocks
.blk:
	binclude "sound/tracks/test_blk.bin"
; Max. 24 patterns
.pat:
	binclude "sound/tracks/test_patt.bin"

; Max. 16 instruments
; Starting from 1.
.ins:
	gInsPsg 0,$20,$20,$10,$00,$04,0
	gInsPsgN +12,$20,$20,$10,$00,$04,0,%011
	gInsFm -12,FmIns_Bass_calm
	gInsFm3 0,FmIns_Sp_OpenHat
	gInsDac -12,DacIns_Snare_1,0
	gInsPwm -17,SmpIns_VctrBrass,%001
