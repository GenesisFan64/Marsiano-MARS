; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

; Instrument macros
; do note that some 24-bit pointers add 90h to the MSB

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

; mode: noise mode %tmm (PSGN only)
gInsPsgN macro pitch,alv,atk,slv,dky,rrt,mode
	dc.b $90|mode,pitch,alv,atk
	dc.b slv,dky,rrt,0
	endm

; fmins - 24-bit ROM pointer to
; patch data
gInsFm macro pitch,fmins
	dc.b $A0,pitch,((fmins>>16)&$FF)|$90,((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; Same but for Channel 3 special, the last
; 4 words set each OP's frequency in this order:
; OP1 OP2 OP3 OP4
gInsFm3	macro pitch,fmins
	dc.b $B0,pitch,((fmins>>16)&$FF)|$90,((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; start: Pointer to sample data, the first 3 bytes of
;        the sample contains the LENGTH of the sample
; loop: Sample to jump to, 0-start
; flags: 0-dont loop, 1-loop
gInsDac	macro pitch,start,flags
	dc.b $C0|flags,pitch,((start>>16)&$FF)|$90,((start>>8)&$FF)
	dc.b start&$FF,0,0,0
	endm

; flags:
; %00SL
; S - Sample is in stereo
; L - Loop sample
gInsPwm	macro pitch,start,flags
	dc.b $D0|flags,pitch,((start>>24)&$FF),((start>>16)&$FF)
	dc.b ((start>>8)&$FF),start&$FF,0,0
	endm

; ------------------------------------------------------------
; PWM pitches:
; -17 - 8000

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

; GemaTrk_blk_TEST:
; 	binclude "sound/tracks/kid_blk.bin"
; GemaTrk_patt_TEST:
; 	binclude "sound/tracks/kid_patt.bin"
; GemaTrk_ins_TEST:
; 	gInsFm -12,FmIns_Bass_groove_gem
; 	gInsFm -12,FmIns_Guitar_gem
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull

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

; HILLS
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
