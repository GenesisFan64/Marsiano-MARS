; ================================================================
; ------------------------------------------------------------
; DATA SECTION
;
; SOUND
; ------------------------------------------------------------

; PWM pitches:
; -17 - 8000
; NORMAL FM TL LEVEL:
; $0F

; Instrument macros
; do note that some 24-bit pointers add 90h to the MSB automaticly.
;
; TODO: this might fail to work.
gInsNull macro
	dc.b  -1,$00,$00,$00
	dc.b $00,$00,$00,$00
	endm

; alv: attack level (00=high)
; atk: attack rate
; slv: sustain (00=high)
; dky: decay rate (up)
; rrt: release rate (down)
gInsPsg	macro pitch,alv,atk,slv,dky,rrt
	dc.b $80,pitch,alv,atk
	dc.b slv,dky,rrt,$00
	endm

; same arguments as gInsPsg, but for the last one:
; mode: noise mode %tmm (PSGN only) t-Bass(0)|Noise(1) mm-Clock(0)|Clock/2(1)|Clock/4(2)|Tone3(3)
gInsPsgN macro pitch,alv,atk,slv,dky,rrt,mode
	dc.b $90|mode,pitch,alv,atk
	dc.b slv,dky,rrt,0
	endm

; fmins - 24-bit ROM pointer to patch data
gInsFm macro pitch,fmins
	dc.b $A0,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; Same as gInsFm
; But the last 4 words on the patch data are the custom freqs
; for each operator in this order: OP1 OP2 OP3 OP4
gInsFm3	macro pitch,fmins
	dc.b $B0,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; start: Pointer to sample data:
;        dc.b end,end,end	; 24-bit LENGTH of the sample
;        dc.b loop,loop,loop	; 24-bit Loop point
;        dc.b (sound data)	; Then the actual sound data
; flags: 0-don't loop
; 	 1-loop
gInsDac	macro pitch,start,flags
	dc.b $C0|flags,pitch,((start>>16)&$FF),((start>>8)&$FF)
	dc.b start&$FF,0,0,0
	endm

; start: Pointer to sample data:
;        dc.b end,end,end	; 24-bit LENGTH of the sample
;        dc.b loop,loop,loop	; 24-bit Loop point
;        dc.b (data)		; Then the actual sound data
; flags: %00SL
;        L - Loop sample No/Yes
;        S - Sample data is in stereo
gInsPwm	macro pitch,start,flags
	dc.b $D0|flags,pitch,((start>>24)&$FF),((start>>16)&$FF)
	dc.b ((start>>8)&$FF),start&$FF,0,0
	endm

; ------------------------------------------------------------
; SFX tracks
; ------------------------------------------------------------

GemaTrkData_Sfx:
	dc.l GemaSfxPat_Boom
	dc.l GemaSfxBlk_Boom
	dc.l GemaSfxIns_Boom
GemaSfxBlk_Boom:
	binclude "sound/tracks/sfxpack_blk.bin"
	align 2
GemaSfxPat_Boom:
	binclude "sound/tracks/sfxpack_patt.bin"
	align 2
GemaSfxIns_Boom:
	gInsFm3 0,FmIns3_Explosion
	gInsPsgN 0,$00,$00,$00,$00,$02,%110
	gInsFm 0,FmIns_Ding_toy

; ------------------------------------------------------------
; BGM tracks
; ------------------------------------------------------------

GemaTrk_BodyOver:
	dc.l .pat
	dc.l .blk
	dc.l .ins
.blk:
	binclude "sound/tracks/bodyover_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/bodyover_patt.bin"
	align 2
.ins:
	gInsPwm 0,SmpIns_Nadie,%10
	gInsPwm 0,SmpIns_Kick,%10;gInsFm -38,FmIns_DrumKick_gem
	gInsPwm 0,SmpIns_snare_2,%00
	gInsFm -24,FmIns_Bass_groove_2
	gInsFm -36,FmIns_Ding_Baseball
	gInsFm 0,FmIns_Trumpet_1
; 	gInsFm 0,FmIns_Bass_1
	gInsFm3 0,FmIns3_ClosedHat
	gInsFm3 0,FmIns3_OpenHat
	gInsPsg +12,$00,$00,$00,$00,$02

GemaTrkData_MOVEME:
	dc.l .pat
	dc.l .blk
	dc.l .ins
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
	gInsPsgN 0,$00,$00,$00,$00,$04,%110
	gInsFm -12,FmIns_HBeat_tom
	gInsPwm 0,SmpIns_Snare,%10
	gInsPwm 0,SmpIns_Kick,%10;gInsFm -38,FmIns_DrumKick_gem
	gInsFm -12,FmIns_Trumpet_carnival;FmIns_Trumpet_2
	gInsPsg 0,$20,$20,$10,$01,$08;gInsFm -12,FmIns_Ding_Baseball;
	gInsFm3 0,FmIns3_OpenHat
	gInsPwm -17,SmpIns_MyTime,%10
	gInsPsg +12,$20,$10,$10,$0C,$0C
	gInsPsg 0,$00,$00,$00,$00,$06
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull

GemaTrk_xtrim:
	dc.l .pat
	dc.l .blk
	dc.l .ins
.blk:
	binclude "sound/tracks/xtrim_blk.bin"
	align 2
.pat:
	binclude "sound/tracks/xtrim_patt.bin"
	align 2
.ins:
	gInsFm 0,FmIns_Bass_calm
	gInsFm 0,FmIns_ClosedHat
	gInsPsg 0,$00,$00,$00,$02,$04
	gInsFm3 0,FmIns3_OpenHat
	gInsDac 0,DacIns_wegot_kick,%10

; 	gInsFm -24,FmIns_Bass_groove_2
; 	gInsFm -36,FmIns_Ding_Baseball
; 	gInsFm 0,FmIns_Trumpet_1
; ; 	gInsFm 0,FmIns_Bass_1
; 	gInsFm3 0,FmIns3_ClosedHat
; 	gInsFm3 0,FmIns3_OpenHat



; GemaTrkData_Test3:
; 	dc.l GemaPat_Test3
; 	dc.l GemaBlk_Test3
; 	dc.l GemaIns_Test3
; GemaBlk_Test3:
; 	binclude "sound/tracks/vuela_blk.bin"
; 	align 2
; GemaPat_Test3:
; 	binclude "sound/tracks/vuela_patt.bin"
; 	align 2
; GemaIns_Test3:
; 	gInsFm -12,FmIns_Brass_Eur
; 	gInsFm 0,FmIns_Bass_italo
; 	gInsDac -36,DacIns_wegot_kick,0
; 	gInsPsgN 0,$00,$00,$00,$00,$0E,%100
; 	gInsNull
; 	gInsPsg 0,$20,$40,$10,$06,$08
; 	gInsDac +16,DacIns_snare_magn,0
; 	gInsFm -24,FmIns_Brass_Eur
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsFm -24,FmIns_Trumpet_carnival
; 	gInsFm -12,FmIns_Ding_toy
; 	gInsNull
