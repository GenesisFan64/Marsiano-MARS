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

; mode: noise mode (PSGN only)
gInsPsgN macro pitch,alv,atk,slv,dky,rrt,mode
	dc.b $90,pitch,alv,atk
	dc.b slv,dky,rrt,mode
	endm

gInsFm macro pitch,fmins
	dc.b $A0,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; ex freq order: OP4 OP3 OP2 OP1
gInsFm3	macro pitch,fmins
	dc.b $B0,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
	dc.b fmins&$FF,$00,$00,$00
	endm

; start: Pointer to sample data, the first 3 bytes of
;        the sample contains the LENGTH of the sample
; loop: Sample to jump to, 0-start
; flags: 0-dont loop, 1-loop
gInsDac	macro pitch,start,loop,flags
	dc.b $C0|flags,pitch,((start>>16)&$FF),((start>>8)&$FF)
	dc.b start&$FF,((loop)&$FF),(((loop)>>8)&$FF),(((loop)>>16)&$FF)
	endm

gInsPwm	macro pitch,start,end,loop
	dc.b $D0|flags,pitch,start&$FF,((start>>8)&$FF)
	dc.b ((start>>16)&$FF),((loop)&$FF),(((loop)>>8)&$FF),(((loop)>>16)&$FF)
	endm

; ------------------------------------------------------------

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


; GemaTrk_cirno_blk:
; 	binclude "sound/tracks/chrono_blk.bin"
; GemaTrk_cirno_patt:
; 	binclude "sound/tracks/chrono_patt.bin"
; GemaTrk_cirno_ins:
; 	gInsPsg  +12,$30,$00,$20,$10,$02
; 	gInsFm     0,FmIns_Bell_China
; 	gInsFm     0,FmIns_Bass_calm
; 	gInsPsgN   0,$00,$00,$00,$08,$08,%110
; 	gInsPsgN   0,$00,$00,$00,$08,$08,%101
; 	gInsPsgN   0,$00,$00,$00,$10,$10,%100
; 	gInsFm   -12,FmIns_Brass_Eur,0
; 	gInsNull

GemaTrk_blk_TEST:
	binclude "sound/tracks/test_blk.bin"
GemaTrk_patt_TEST:
	binclude "sound/tracks/test_patt.bin"
GemaTrk_ins_TEST:
; 	gInsPsg 0,$00,$00,$00,$00,$00
; 	gInsPsgN 0,$00,$00,$00,$00,$00,%000
; 	gInsPsgN +24,$00,$00,$00,$00,$00,%011

	gInsFm    0,FmIns_Bass_groove
	gInsFm3   0,FmIns_Fm3_OpenHat
	gInsDac   0,DacIns_CdSnare,0,0

; 	gInsFm3   0,FmIns_Fm3_ClosedHat
; 	gInsFm3   0,FmIns_Fm3_OpenHat
; 	gInsFm 0,FmIns_Trumpet_2
; 	gInsFm 0,FmIns_bass_kon

GemaTrk_blk_TEST2:
	binclude "sound/tracks/puyo2_blk.bin"
GemaTrk_patt_TEST2:
	binclude "sound/tracks/puyo2_patt.bin"
GemaTrk_ins_TEST2:
	gInsFm 0,FmIns_guitar_puy
	gInsNull
	gInsFm 0,FmIns_Bass_groove_2
	gInsFm -12,FmIns_Brass_Puy
	gInsDac +24,DacIns_SaurKick,0,0
	gInsNull
	gInsNull
	gInsFm3   0,FmIns_Fm3_OpenHat
	gInsDac +24,DacIns_CdSnare,0,0
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsFm -36,FmIns_Banjo_puy
	gInsFm -12,FmIns_Trumpet_Puy
	gInsFm 0,FmIns_guitar_puy_2
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull
	gInsNull

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
GemaTrk_moon_blk:
	binclude "sound/tracks/brinstar_blk.bin"
GemaTrk_moon_patt:
	binclude "sound/tracks/brinstar_patt.bin"
GemaTrk_moon_ins:
	gInsPsg   0,$40,$FF,$00,$10,$10
	gInsPsgN  0,$00,$FF,$20,$10,$10,%100
	gInsDac  +17,DacIns_CdSnare,0,0
	gInsDac  +17,DacIns_CdSnare,0,0
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
