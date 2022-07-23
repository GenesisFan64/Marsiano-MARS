; ================================================================
; ------------------------------------------------------------
; DATA SECTION
;
; SOUND
; ------------------------------------------------------------

; PWM pitches:
; -17 - 8000

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
; But the last 4 words on the patch data are the custom frequencies
; for each operator in this order: OP1 OP2 OP3 OP4
gInsFm3	macro pitch,fmins
	dc.b $B0,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; start: Pointer to sample data:
;        dc.b end,end,end	; 24-bit LENGTH of the sample
;        dc.b loop,loop,loop	; 24-bit Loop point
;        dc.b (sound data)	; Then the actual sound data
; flags: %0-don't loop
; 	 %1-loop
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
	gInsFm3 0,FmIns_Fm3_Explosion
	gInsPsgN 0,$00,$00,$00,$00,$02,%110
	gInsFm 0,FmIns_Ding_toy

; ------------------------------------------------------------
; BGM tracks
; ------------------------------------------------------------

GemaTrkData_Test:
	dc.l GemaPat_Test
	dc.l GemaBlk_Test
	dc.l GemaIns_Test
GemaBlk_Test:
	binclude "sound/tracks/nadie_blk.bin"
	align 2
GemaPat_Test:
	binclude "sound/tracks/nadie_patt.bin"
	align 2
GemaIns_Test:
	gInsPwm 0,SmpIns_Nadie,%10
	gInsFm -36,FmIns_Piano_Aqua
	gInsFm +12,FmIns_PSynth_plus
	gInsPwm -12,SmpIns_PKick,%00
	gInsPsg 0,$10,$20,$08,$04,$06
	gInsFm 0,FmIns_Trumpet_1
	gInsPwm 0,SmpIns_Piano,%00
	gInsPwm -12,SmpIns_PTom,%00
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

GemaTrkData_Mecano:
	dc.l GemaPat_Mecano
	dc.l GemaBlk_Mecano
	dc.l GemaIns_Mecano
GemaBlk_Mecano:
	binclude "sound/tracks/mecano_blk.bin"
	align 2
GemaPat_Mecano:
	binclude "sound/tracks/mecano_patt.bin"
	align 2
GemaIns_Mecano:
	gInsNull
	gInsPsgN 0,$00,$00,$00,$00,$0C,%100
	gInsFm 0,FmIns_PianoM1
	gInsFm -12,FmIns_Trumpet_carnival
	gInsFm 0,FmIns_Bass_italo
	gInsDac 0,DacIns_wegot_kick,0
	gInsPsgN 0,$00,$00,$00,$00,$08,%110
	gInsDac -12,DacIns_snare_lobo,0
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsFm 0,FmIns_Bass_2
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull

GemaTrkData_Test2:
	dc.l GemaPat_Test2
	dc.l GemaBlk_Test2
	dc.l GemaIns_Test2
GemaBlk_Test2:
	binclude "sound/tracks/wegot_blk.bin"
	align 2
GemaPat_Test2:
	binclude "sound/tracks/wegot_patt.bin"
	align 2
GemaIns_Test2:
	gInsFm 0,FmIns_PSynth_plus
	gInsFm 0,FmIns_Bass_groove_2
	gInsDac -36,DacIns_wegot_kick,0
	gInsFm 0,FmIns_Bass_club
	gInsFm3 0,FmIns_Fm3_OpenHat
	gInsPsg 0,$20,$40,$10,$01,$04
	gInsDac -36,DacIns_wegot_crash,0
	gInsPsgN 0,$00,$00,$00,$00,$10,%100
	gInsNull
	gInsNull

GemaTrkData_Test3:
	dc.l GemaPat_Test3
	dc.l GemaBlk_Test3
	dc.l GemaIns_Test3
GemaBlk_Test3:
	binclude "sound/tracks/vuela_blk.bin"
	align 2
GemaPat_Test3:
	binclude "sound/tracks/vuela_patt.bin"
	align 2
GemaIns_Test3:
	gInsFm -12,FmIns_Brass_Eur
	gInsFm 0,FmIns_Bass_italo
	gInsDac -36,DacIns_wegot_kick,0
	gInsPsgN 0,$00,$00,$00,$00,$0E,%100
	gInsNull
	gInsPsg 0,$20,$40,$10,$06,$08
	gInsDac +16,DacIns_snare_magn,0
	gInsFm -24,FmIns_Brass_Eur
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsFm -24,FmIns_Trumpet_carnival
	gInsFm -12,FmIns_Ding_toy
	gInsNull

GemaTrkData_BeMine:
	dc.l GemaPat_BeMine
	dc.l GemaBlk_BeMine
	dc.l GemaIns_BeMine
GemaBlk_BeMine:
	binclude "sound/tracks/bemine_blk.bin"
GemaPat_BeMine:
	binclude "sound/tracks/bemine_patt.bin"
GemaIns_BeMine:
	gInsPwm -17,SmpIns_Bell_Ice,0
	gInsPwm -17,SmpIns_Brass1_Hi,%01
	gInsPwm -17,SmpIns_Brass1_Low,%01
	gInsFm  -24,FmIns_Bass_groove
	gInsFm3   0,FmIns_Fm3_OpenHat
	gInsPwm -17,SmpIns_Snare_jam,0
	gInsPwm -17,SmpIns_Kick_jam,0
	gInsPwm -17,SmpIns_SnrTom_1,0
	gInsPwm -17,SmpIns_Forest_1,0
	gInsFm -36,FmIns_Ambient_dark
	gInsPsg +12,$00,$00,$00,$08,$04
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
