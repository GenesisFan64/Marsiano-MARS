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
	dc.l ((ticks&$FF)<<24)|loc&$FFFFFF
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
 if MARS|MARSCD
	dc.b $D0|flags,pitch,((start>>24)&$FF),((start>>16)&$FF)
	dc.b ((start>>8)&$FF),start&$FF,0,0
 else
	dc.b $00,$00,$00,$00
	dc.b $00,$00,$00,$00
 endif
	endm

; ------------------------------------------------------------

	align 2

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
	gemaTrk 7,GemaTrk_TEST_0
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
	gemaTrk 7,GemaSfx_All		; $0F

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
	gemaTrk 3,GemaTrk_TEST_0
	gemaTrk 3,GemaTrk_TEST_0

; ------------------------------------------------------------
; BGM tracks
; ------------------------------------------------------------

GemaSfx_All:
	gemaHead .blk,.pat,.ins
.blk:
	binclude "sound/tracks/sfxall_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/sfxall_patt.bin"
	align 2
.ins:
	gInsFm3 0,FmIns_Fm3_Explosion
	gInsPsgN 0,$00,$00,$00,$00,$02,0,%110
	gInsFm 0,FmIns_Ding_toy

; ------------------------------------------------------------

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
; 	gInsDac 0,DacIns_TESTINS,0

	gInsPwm -5,SmpIns_TEST,%001

; 	gInsPsg 0,$00,$00,$00,$00,$00,0
; 	gInsFm -12,FmIns_Trumpet_2
; ; 	gInsPsgN +12,$20,$20,$10,$00,$04,0,%011
;
; 	gInsFm3 0,FmIns_Sp_OpenHat
; 	gInsDac -12,DacIns_Snare_1,0
; 	gInsPwm -17,SmpIns_VctrBrass,%001

; GemaTrk_TEST_2:
; 	gemaHead .blk,.pat,.ins
; .blk:
; 	binclude "sound/tracks/wegot_blk.bin"
; 	align 2
; .pat:
; 	binclude "sound/tracks/wegot_patt.bin"
; 	align 2
; .ins:
; 	gInsFm 0,FmIns_Synth_plus
; 	gInsFm 0,FmIns_Bass_4
; 	gInsDac 0,DacIns_wegot_kick,0
; 	gInsFm 0,FmIns_Bass_club
; 	gInsFm3 0,FmIns_Sp_Openhat
; 	gInsPsg 0,$10,$04,$20,$04,$02,$00;gInsFm -12,FmIns_Trumpet_carnival;;
; 	gInsDac 0,DacIns_wegot_crash,0

; GemaTrk_TEST_1:
; 	gemaHead .blk,.pat,.ins
; .blk:
; 	binclude "sound/tracks/vectr_blk.bin"
; .pat:
; 	binclude "sound/tracks/vectr_patt.bin"
; .ins:
; 	gInsPwm -17,SmpIns_Vctr01,%001
; 	gInsFm -3,FmIns_brass_eur
; 	gInsPwm -15,SmpIns_VctrCrash,0
; 	gInsPwm -17,SmpIns_Vctr04,%001
; 	gInsNull
; 	gInsPwm -15,SmpIns_VctrTimpani,%101
; 	gInsFm -22,FmIns_Bass_8
; 	gInsPsg 0,$40,$08,$10,$01,$01,$00
; 	gInsNull;gInsPsgN 0,$40,$08,$10,$01,$01,$00,%110
; 	gInsPwm -17,SmpIns_VctrSnare,%000
; 	gInsPwm -17,SmpIns_VctrKick,%000
; 	gInsFm3 0,FmIns_Sp_Closedhat
; 	gInsFm3 0,FmIns_Sp_Openhat
; 	gInsPwm -17,SmpIns_VctrBrass,%001
