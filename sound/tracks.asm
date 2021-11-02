; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

; Null instrument
gInsNull	macro
		dc.b  -1,$00,$00,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

; alv: attack level (00=high)
; atk: attack rate
; slv: sustain (00=high)
; dky: decay rate
; rrt: release rate
gInsPsg	macro pitch,alv,atk,slv,dky,rrt
		dc.b $00,pitch,alv,atk
		dc.b slv,dky,rrt,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

; mode: noise mode (PSGN only)
gInsPsgN	macro pitch,alv,atk,slv,dky,rrt,mode
		dc.b $01,pitch,alv,atk
		dc.b slv,dky,rrt,mode
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

gInsFm	macro pitch,fmins
		dc.b $02,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
		dc.b fmins&$FF,$00,$00,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

; ex freq order: OP4 OP3 OP2 OP1
gInsFm3	macro pitch,fmins,freq1,freq2,freq3,freq4
		dc.b $03,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
		dc.b fmins&$FF,((freq1>>8)&$FF),freq1&$FF,((freq2>>8)&$FF)
		dc.b freq2&$FF,((freq3>>8)&$FF),freq3&$FF,((freq4>>8)&$FF)
		dc.b freq4&$FF,$00,$00,$00
		endm

gInsDac	macro pitch,start,end,loop,flags
		dc.b $04,pitch
		dc.b start&$FF,((start>>8)&$FF),((start>>16)&$FF)
		dc.b ((end-start)&$FF),(((end-start)>>8)&$FF),(((end-start)>>16)&$FF)
		dc.b loop&$FF,((loop>>8)&$FF),((loop>>16)&$FF)
		dc.b flags,0,0,0,0
		endm

gInsPwm	macro pitch,start,end,loop,flags
		dc.b $05,pitch
		dc.b start&$FF,((start>>8)&$FF),((start>>16)&$FF)
		dc.b ((end-start)&$FF),(((end-start)>>8)&$FF),(((end-start)>>16)&$FF)
		dc.b loop&$FF,((loop>>8)&$FF),((loop>>16)&$FF)
		dc.b flags,0,0,0,0
		endm

; ------------------------------------------------------------

 align $8000
GemaTrk_cirno_blk:
	binclude "sound/tracks/chrono_blk.bin"
GemaTrk_cirno_patt:
	binclude "sound/tracks/chrono_patt.bin"
GemaTrk_cirno_ins:
	gInsPsg  +12,$80,$01,$40,$20,$10
	gInsFm     0,FmIns_Bell_China
	gInsFm     0,FmIns_Bass_calm
	gInsPsgN   0,$00,$00,$00,$08,$08,%110
	gInsPsgN   0,$00,$00,$00,$08,$08,%101
	gInsPsgN   0,$00,$00,$00,$10,$10,%100
	gInsFm   -12,FmIns_Brass_Eur,0
	gInsNull

GemaTrk_blk_TEST:
	binclude "sound/tracks/test_blk.bin"
GemaTrk_patt_TEST:
	binclude "sound/tracks/test_patt.bin"
GemaTrk_ins_TEST:
	gInsFm3   0,FmIns_Fm3_ClosedHat,$251C,$2328,$205E,$2328
	gInsFm3   0,FmIns_Fm3_OpenHat,$251C,$2328,$205E,$2328
	gInsFm    0,FmIns_Trumpet_2
	gInsPsgN +36,$00,$FF,$00,$00,$00,%011
	gInsPsg   0,$10,$FF,$10,$01,$01

; GemaTrk_blk_TEST3:
; 	binclude "sound/tracks/test3_blk.bin"
; GemaTrk_patt_TEST3:
; 	binclude "sound/tracks/test3_patt.bin"
; GemaTrk_ins_TEST3:
; 	gInsDac 0,DacIns_Magic1,DacIns_Magic1_e,0,0
; 	gInsDac 0,DacIns_Magic2,DacIns_Magic2_e,0,0
; 	gInsFm3   0,FmIns_Fm3_ClosedHat,$251C,$2328,$205E,$2328
; 	gInsFm3   0,FmIns_Fm3_OpenHat,$251C,$2328,$205E,$2328
; 	gInsFm    0,FmIns_Ding_toy
; 	gInsFm    0,FmIns_Ambient_Dark
; 	gInsFm    0,FmIns_Bass_Calm
; 	gInsNull;gInsPsg   0,$10,$FF,$10,$01,$01
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
; 	gInsNull
;
; ; 	gInsPsg   0,$00,$FF,$00,$00,$01
;
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
; 	gInsFm3   0,FmIns_Fm3_OpenHat,$251C,$2328,$205E,$2328
;
;
GemaTrk_moon_blk:
	binclude "sound/tracks/brinstar_blk.bin"
GemaTrk_moon_patt:
	binclude "sound/tracks/brinstar_patt.bin"
GemaTrk_moon_ins:
	gInsPsg   0,$40,$FF,$00,$10,$10
	gInsPsgN  0,$00,$FF,$20,$10,$10,%100
	gInsDac  +17,DacIns_CdSnare,DacIns_CdSnare_e,0,0
	gInsDac  +17,DacIns_CdSnare,DacIns_CdSnare_e,0,0
	gInsFm  -12,FmIns_Brass_Eur,0
	gInsNull
	gInsFm    0,FmIns_Bass_groove,0
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsFm  0,FmIns_Bass_calm,0
	gInsPsg   0,$20,$10,$80,$00,$00


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
	gInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
	gInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
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
; GemaTrk_mars_blk:
; 	binclude "sound/tracks/mars_blk.bin"
; GemaTrk_mars_patt:
; 	binclude "sound/tracks/mars_patt.bin"
; GemaTrk_mars_ins:
; 	gInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
; 	gInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
; 	gInsPsgN  0,$20,$FF,$00,$30,$30,%100
; 	gInsFm    0,FmIns_PianoM1,0
; 	gInsPsg   0,$40,$20,$20,$00,$00
; 	gInsFm    0,FmIns_Bass_groove,0
; 	gInsNull
; 	gInsNull
; 	gInsFm    0,FmIns_Guitar_heavy,0
; 	gInsNull
; 	gInsNull
;
; GemaTrk_jackrab_blk:
; 	binclude "sound/tracks/jackrab_blk.bin"
; GemaTrk_jackrab_patt:
; 	binclude "sound/tracks/jackrab_patt.bin"
; GemaTrk_jackrab_ins:
; 	gInsFm    0,FmIns_Ambient_Spook,0
; 	gInsNull
; 	gInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
; 	gInsPsgN  0,$20,$FF,$10,$10,$10,%100
; 	gInsNull
; 	gInsNull
; 	gInsFm    0,FmIns_PianoM1,0
; 	gInsNull
; 	gInsNull
; 	gInsPsg   0,$20,$FF,$20,$04,$04
; 	gInsFm    0,FmIns_Ambient_Dark,0
; 	gInsNull
; 	gInsFm    0,FmIns_Ding_Toy,0
; 	gInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
; 	gInsFm    0,FmIns_Trumpet_2,0
; 	gInsNull
