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

gInsPwm	macro pitch,start,flags
	dc.b $D0|flags,pitch,((start>>24)&$FF),((start>>16)&$FF)
	dc.b ((start>>8)&$FF),start&$FF,0,0
	endm

; ------------------------------------------------------------
; PWM pitches:
; -17 - 8000

GemaTrk_blk_TEST:
	binclude "sound/tracks/bemine_blk.bin"
GemaTrk_patt_TEST:
	binclude "sound/tracks/bemine_patt.bin"
GemaTrk_ins_TEST:
	gInsPwm -17,SmpIns_Bell_Ice,0
	gInsPwm -17,SmpIns_Brass1_Hi,1
	gInsPwm -17,SmpIns_Brass1_Low,1
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

;  align $8000

; GemaTrk_cirno_blk:
; 	binclude "sound/tracks/mecano_blk.bin"
; GemaTrk_cirno_patt:
; 	binclude "sound/tracks/mecano_patt.bin"
; GemaTrk_cirno_ins:
; 	gInsNull
; 	gInsPsgN   0,$00,$00,$00,$00,$00,%100
; 	gInsFm    0,FmIns_PianoM1
; 	gInsNull;gInsPsg   0,$00,$00,$00,$00,$02
; 	gInsFm    0,FmIns_Bass_italo
; 	gInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
; 	gInsNull
; 	gInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull

;


GemaTrk_blk_chrono:
	binclude "sound/tracks/chrono_blk.bin"
GemaTrk_patt_chrono:
	binclude "sound/tracks/chrono_patt.bin"
GemaTrk_ins_chrono:
	gInsPsg  +12,$50,$20,$30,$10,$04
	gInsFm     0,FmIns_Bell_China
	gInsFm     0,FmIns_Bass_calm
	gInsPsgN   0,$00,$00,$00,$08,$08,%110
	gInsPsgN   0,$00,$00,$00,$08,$08,%101
	gInsPsgN   0,$00,$00,$00,$10,$10,%100
	gInsFm   -12,FmIns_Brass_Eur,0
	gInsNull

GemaTrk_blk_TEST2:
	binclude "sound/tracks/nokiaarab_blk.bin"
GemaTrk_patt_TEST2:
	binclude "sound/tracks/nokiaarab_patt.bin"
GemaTrk_ins_TEST2:
	gInsNull
	gInsFm -12,FmIns_Bass_calm
	gInsPsg 0,$80,$00,$10,$40,$06
	gInsNull
	gInsFm -12,FmIns_Violin_gem
	gInsNull
	gInsNull
	gInsNull
	gInsFm -12,FmIns_Trumpet_1
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

; 	gInsDac +07,DacIns_Snare_Gem,0,0
; 	gInsFm -12,FmIns_Trumpet_2
; 	gInsFm -12,FmIns_Bass_groove
; 	gInsDac +20,DacIns_SaurKick,0,0
; 	gInsNull
; 	gInsFm -12,FmIns_PianoM1
; 	gInsPsg -12,$00,$00,$00,$02,$02
; 	gInsPsgN  0,$10,$10,$00,$10,$40,%100
; 	gInsNull
; 	gInsFm  -24,FmIns_Brass_Eur,0
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull


; 	gInsPsg   0,$40,$FF,$00,$10,$01
; 	gInsDac +24,DacIns_SaurKick,0,0
;
; 	gInsFm 0,FmIns_Organ_M1
; 	gInsNull
; 	gInsDac +24,DacIns_CdSnare,0,0
; 	gInsNull
; 	gInsFm 0,FmIns_Trumpet_2
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull

; GemaTrk_doom_blk:
; 	binclude "sound/tracks/doom_blk.bin"
; GemaTrk_doom_patt:
; 	binclude "sound/tracks/doom_patt.bin"
; GemaTrk_doom_ins:
; 	gInsFm    0,FmIns_Bass_3,0
; 	gInsDac -12,DacIns_Snare_Gem,DacIns_Snare_Gem_e,0,0
; 	gInsFm  -36,FmIns_DrumKick_gem,0
; 	gInsDac -12,DacIns_Snare_Gem,DacIns_Snare_Gem_e,0,0
; 	gInsFm    0,FmIns_Bass_heavy,0
; 	gInsFm    0,FmIns_Guitar_1,0
; 	gInsFm3   0,FmIns_Fm3_OpenHat
;
;
; GemaTrk_moon_blk:
; 	binclude "sound/tracks/brinstar_blk.bin"
; GemaTrk_moon_patt:
; 	binclude "sound/tracks/brinstar_patt.bin"
; GemaTrk_moon_ins:
; 	gInsPsg   0,$40,$FF,$00,$10,$10
; 	gInsPsgN  0,$00,$FF,$20,$10,$10,%100
; 	gInsDac  +17,DacIns_CdSnare,0,0
; 	gInsDac  +17,DacIns_CdSnare,0,0
; 	gInsFm  -12,FmIns_Brass_Eur,0
; 	gInsNull
; 	gInsFm    0,FmIns_Bass_groove,0
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsFm  0,FmIns_Bass_calm,0
; 	gInsPsg   0,$20,$10,$80,$00,$00


; 	gInsFm  -24,FmIns_Bass_calm,0
; 	gInsPsg   0,$10,$80,$10,$20,$04
; 	gInsFm  -12,FmIns_Brass_Eur,0
; 	gInsPsg   0,$10,$80,$10,$F0,$01
; 	gInsDac -12,DacIns_SaurKick,DacIns_SaurKick_e,0,0
; 	gInsPsgN  0,$00,$FF,$00,$08,$08,%100
;
;
; GemaTrk_brinstr_blk:
; 	binclude "sound/tracks/brinstr_blk.bin"
; GemaTrk_brinstr_patt:
; 	binclude "sound/tracks/brinstr_patt.bin"
; GemaTrk_brinstr_ins:
; 	gInsPsg   0,$40,$70,$30,$F0,$01
; 	gInsPsgN  0,$00,$FF,$00,$01,$01,%011
;
; GemaTrk_gigalo_blk:
; 	binclude "sound/tracks/gigalo_blk.bin"
; GemaTrk_gigalo_patt:
; 	binclude "sound/tracks/gigalo_patt.bin"
; GemaTrk_gigalo_ins:
; 	gInsPsg   0,$20,$80,$40,$08,$08
; 	gInsPsgN  0,$00,$FF,$00,$10,$10,%100
; 	gInsPsgN  0,$00,$FF,$00,$10,$10,%101
; 	gInsPsgN  0,$00,$FF,$00,$10,$10,%110
; 	gInsNull
;
GemaTrk_mecano_blk:
	binclude "sound/tracks/ttzgf_blk.bin"
GemaTrk_mecano_patt:
	binclude "sound/tracks/ttzgf_patt.bin"
GemaTrk_mecano_ins:
	gInsFm    0,FmIns_Bass_groove
	gInsPsg   0,$40,$C0,$20,$10,$10
	gInsPsg   0,$60,$80,$20,$F0,$01
	gInsFm  -12,FmIns_Brass_Eur
	gInsPsgN 60,$00,$FF,$20,$10,$10,%111
	gInsDac   0,DacIns_SaurKick,0,0
	gInsDac   0,DacIns_CdSnare,0,0
	gInsFm  -12,FmIns_Trumpet_2
	gInsFm  -12,FmIns_Ding_toy
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
;
; ; 	gInsPsgN  0,$00,$00,$00,$08,$08,%100
; ; 	gInsPsgN  0,$00,$00,$00,$10,$10,%100
; ; 	gInsFm    0,FmIns_PianoM1,0
; ; 	gInsPsg   0,$10,$00,$10,$02,$02
; ; 	gInsFm    0,FmIns_Bass_mecan,0
; ; 	gInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
; ; 	gInsNull
; ; 	gInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
; ; 	gInsNull
; ; 	gInsNull
; ; 	gInsNull
; ; 	gInsNull
; ; 	gInsNull
; ; 	gInsNull
; ; 	gInsFm    0,FmIns_Trumpet_2,0
; ; 	gInsNull
;
GemaTrk_mars_blk:
	binclude "sound/tracks/mars_blk.bin"
GemaTrk_mars_patt:
	binclude "sound/tracks/mars_patt.bin"
GemaTrk_mars_ins:
	gInsDac   0,DacIns_CdSnare,0,0
	gInsDac   0,DacIns_SaurKick,0,0
	gInsPsgN  0,$20,$FF,$00,$30,$30,%100
	gInsFm    0,FmIns_PianoM1,0
	gInsPsg   0,$50,$20,$40,$00,$01
	gInsFm    0,FmIns_Bass_groove,0
	gInsNull
	gInsNull
	gInsFm    0,FmIns_Guitar_heavy,0
	gInsNull
	gInsNull
