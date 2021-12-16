; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

; PWM pitches:
; -17 - 8000

; Instrument macros
; do note that some 24-bit pointers add 90h to the MSB
;
; TODO: this might fail to work. if possible use ALL instruments
; on your tracks
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
; automaticly sets to the $900000 area
gInsFm macro pitch,fmins
	dc.b $A0,pitch,((fmins>>16)&$FF)|$90,((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; Same as gInsFm
; But the last 4 words are manually-set frequencies
; for each operator in this order: OP1 OP2 OP3 OP4
gInsFm3	macro pitch,fmins
	dc.b $B0,pitch,((fmins>>16)&$FF)|$90,((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; start: Pointer to sample data:
;        dc.b end,end,end	; 24-bit LENGTH of the sample
;        dc.b loop,loop,loop	; 24-bit Loop point
;        dc.b (sound data)	; Then the actual sound data
;
; flags: %0-dont loop, %1-loop
gInsDac	macro pitch,start,flags
	dc.b $C0|flags,pitch,((start>>16)&$FF)|$90,((start>>8)&$FF)
	dc.b start&$FF,0,0,0
	endm

; start: Pointer to sample data:
;        dc.b end,end,end	; 24-bit LENGTH of the sample
;        dc.b loop,loop,loop	; 24-bit Loop point
;        dc.b (sound data)	; Then the actual sound data
;
; flags: %00SL
;        L - Loop sample
;        S - Sample is in stereo
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
GemaSfxPat_Boom:
	binclude "sound/tracks/sfxpack_patt.bin"
GemaSfxIns_Boom:
	gInsFm3 0,FmIns_Fm3_Explosion
	gInsPsgN 0,$00,$00,$00,$00,$02,%110
	gInsFm 0,FmIns_Ding_toy

GemaTrk_blk_Vectr:
	binclude "sound/tracks/vectr_blk.bin"
GemaTrk_patt_Vectr:
	binclude "sound/tracks/vectr_patt.bin"
GemaTrk_ins_Vectr:
	gInsPwm -17,SmpIns_Vctr01,%001
	gInsNull
	gInsPwm -15,SmpIns_VctrCrash,0
	gInsPwm -17,SmpIns_Vctr04,%001
	gInsNull
	gInsPwm -15,SmpIns_VctrTimpani,%001
	gInsFm -22,FmIns_Bass_4
	gInsPsg 0,$00,$00,$00,$00,$01
	gInsPsg 0,$00,$00,$00,$00,$01
	gInsPwm -17,SmpIns_VctrSnare,%000
	gInsPwm -17,SmpIns_VctrKick,%000
	gInsPsgN 0,$00,$00,$00,$00,$10,%100
	gInsPsgN 0,$00,$00,$00,$00,$08,%100
	gInsPwm -17,SmpIns_VctrBrass,%001

GemaTrk_blk_BeMine:
	binclude "sound/tracks/bemine_blk.bin"
GemaTrk_patt_BeMine:
	binclude "sound/tracks/bemine_patt.bin"
GemaTrk_ins_BeMine:
	gInsPwm -17,SmpIns_Bell_Ice,0
	gInsPwm -17,SmpIns_Brass1_Hi,%01
	gInsPwm -17,SmpIns_Brass1_Low,%01
	gInsFm  -24,FmIns_Bass_groove
	gInsFm3   0,FmIns_Fm3_OpenHat
	gInsPwm -17,SmpIns_Snare_jam,0
	gInsPwm -17,SmpIns_Kick_jam,0
	gInsPwm -17,SmpIns_SnrTom_1,0
	gInsPwm -17,SmpIns_Forest_1,0
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull

GemaTrk_blk_HILLS:
	binclude "sound/tracks/hill_blk.bin"
GemaTrk_patt_HILLS:
	binclude "sound/tracks/hill_patt.bin"
GemaTrk_ins_HILLS:
	gInsPsg +2,$40,$02,$30,$10,$00
	gInsFm -10,FmIns_Trumpet_1
	gInsPsgN 0,$00,$00,$00,$00,$04,%110
	gInsDac -3,DacIns_LowString,1;gInsPwm -8,DacIns_LowString,1
	gInsFm -8-12,FmIns_Ding_Toy
	gInsFm -25,FmIns_Bass_3
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
