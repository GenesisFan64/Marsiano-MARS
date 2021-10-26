; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

; Null instrument
trkInsNull	macro
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
trkInsPsg	macro pitch,alv,atk,slv,dky,rrt
		dc.b $00,pitch,alv,atk
		dc.b slv,dky,rrt,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

; mode: noise mode (PSGN only)
trkInsPsgN	macro pitch,alv,atk,slv,dky,rrt,mode
		dc.b $01,pitch,alv,atk
		dc.b slv,dky,rrt,mode
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

trkInsFm	macro pitch,fmins
		dc.b $02,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
		dc.b fmins&$FF,$00,$00,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

; ex freq order: OP4 OP3 OP2 OP1
trkInsFm3	macro pitch,fmins,freq1,freq2,freq3,freq4
		dc.b $03,pitch,((fmins>>16)&$FF),((fmins>>8)&$FF)
		dc.b fmins&$FF,((freq1>>8)&$FF),freq1&$FF,((freq2>>8)&$FF)
		dc.b freq2&$FF,((freq3>>8)&$FF),freq3&$FF,((freq4>>8)&$FF)
		dc.b freq4&$FF,$00,$00,$00
		endm

trkInsDac	macro pitch,start,end,loop,flags
		dc.b $04,pitch
		dc.b start&$FF,((start>>8)&$FF),((start>>16)&$FF)
		dc.b ((end-start)&$FF),(((end-start)>>8)&$FF),(((end-start)>>16)&$FF)
		dc.b loop&$FF,((loop>>8)&$FF),((loop>>16)&$FF)
		dc.b flags,0,0,0,0
		endm

trkInsPwm	macro pitch,start,end,loop,flags
		dc.b $05,pitch
		dc.b start&$FF,((start>>8)&$FF),((start>>16)&$FF)
		dc.b ((end-start)&$FF),(((end-start)>>8)&$FF),(((end-start)>>16)&$FF)
		dc.b loop&$FF,((loop>>8)&$FF),((loop>>16)&$FF)
		dc.b flags,0,0,0,0
		endm

; ------------------------------------------------------------

; OLD:
; PsgIns_00:	db 00h,0FFh,40h,00h, 80h
; PsgIns_01:	db 00h,0FFh,00h,03h, 03h
; PsgIns_02:	db 00h,0FFh,80h,04h, 04h
; PsgIns_03:	db 30h,0FFh, -1,00h, 04h
; PsgIns_Bass:	db 00h,0FFh, -1,01h, 01h
; PsgIns_Snare:	db 00h,0FFh,00h,0F0h,0F0h

; TEST_BLOCKS	binclude "sound/tracks/temple_blk.bin"
; TEST_PATTERN	binclude "sound/tracks/temple_patt.bin"
; TEST_INSTR
; 		trkInsPsg  0,PsgIns_01
; 		trkInsPsgN 0,PsgIns_Snare,%101

; GemaTrk_base_blk:
; 	binclude "sound/tracks/base_blk.bin"
; GemaTrk_base_patt:
; 	binclude "sound/tracks/base_patt.bin"
; GemaTrk_base_ins:
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull

GemaTrk_cirno_blk:
	binclude "sound/tracks/feellove_blk.bin"
GemaTrk_cirno_patt:
	binclude "sound/tracks/feellove_patt.bin"
GemaTrk_cirno_ins:
	trkInsFm  -12,FmIns_Brass_Eur,0
	trkInsFm  0,FmIns_Bass_synth,0
	trkInsFm3   0,FmIns_Fm3_OpenHat,$251C,$2328,$205E,$2328
	trkInsNull
	trkInsNull
	trkInsPsgN  0,$20,$FF,$20,$10,$10,%100
	trkInsNull
	trkInsFm 0,FmIns_Bass_3,0
	trkInsFm  -12,FmIns_Brass_Eur,0
	trkInsPsg   0,$00,$FF,$00,$00,$01

GemaTrk_doom_blk:
	binclude "sound/tracks/doom_blk.bin"
GemaTrk_doom_patt:
	binclude "sound/tracks/doom_patt.bin"
GemaTrk_doom_ins:
	trkInsFm    0,FmIns_Bass_3,0
	trkInsDac -12,DacIns_Snare_Gem,DacIns_Snare_Gem_e,0,0
	trkInsFm  -36,FmIns_DrumKick_gem,0
	trkInsDac -12,DacIns_Snare_Gem,DacIns_Snare_Gem_e,0,0
	trkInsFm    0,FmIns_Bass_heavy,0
	trkInsFm    0,FmIns_Guitar_1,0
	trkInsFm3   0,FmIns_Fm3_OpenHat,$251C,$2328,$205E,$2328


GemaTrk_moon_blk:
	binclude "sound/tracks/moon_blk.bin"
GemaTrk_moon_patt:
	binclude "sound/tracks/moon_patt.bin"
GemaTrk_moon_ins:
	trkInsFm  -24,FmIns_Bass_calm,0
	trkInsPsg   0,$10,$80,$10,$20,$04
	trkInsFm  -12,FmIns_Brass_Eur,0
	trkInsPsg   0,$10,$80,$10,$F0,$01
	trkInsDac -12,DacIns_SaurKick,DacIns_SaurKick_e,0,0
	trkInsPsgN  0,$00,$FF,$00,$08,$08,%100


GemaTrk_brinstr_blk:
	binclude "sound/tracks/brinstr_blk.bin"
GemaTrk_brinstr_patt:
	binclude "sound/tracks/brinstr_patt.bin"
GemaTrk_brinstr_ins:
	trkInsPsg   0,$40,$10,$10,$01,$01
	trkInsPsgN  0,$00,$FF,$00,$01,$01,%011

GemaTrk_gigalo_blk:
	binclude "sound/tracks/gigalo_blk.bin"
GemaTrk_gigalo_patt:
	binclude "sound/tracks/gigalo_patt.bin"
GemaTrk_gigalo_ins:
	trkInsPsg   0,$20,$80,$40,$08,$08
	trkInsPsgN  0,$00,$FF,$00,$10,$10,%100
	trkInsPsgN  0,$00,$FF,$00,$10,$10,%101
	trkInsPsgN  0,$00,$FF,$00,$10,$10,%110
	trkInsNull

GemaTrk_mecano_blk:
	binclude "sound/tracks/ttzgf_blk.bin"
GemaTrk_mecano_patt:
	binclude "sound/tracks/ttzgf_patt.bin"
GemaTrk_mecano_ins:
	trkInsFm    0,FmIns_Bass_7
	trkInsPsg   0,$40,$C0,$20,$10,$10
	trkInsPsg   0,$60,$80,$20,$F0,$01
	trkInsFm  -12,FmIns_Brass_Eur
	trkInsPsgN 60,$00,$FF,$20,$10,$10,%111
	trkInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
	trkInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
	trkInsFm  -12,FmIns_Trumpet_2
	trkInsFm  -12,FmIns_Ding_toy
	trkInsNull
	trkInsNull
	trkInsNull
	trkInsNull
	trkInsNull
	trkInsNull
	trkInsNull
	trkInsNull
	trkInsNull
	trkInsNull
	trkInsNull

; 	trkInsPsgN  0,$00,$00,$00,$08,$08,%100
; 	trkInsPsgN  0,$00,$00,$00,$10,$10,%100
; 	trkInsFm    0,FmIns_PianoM1,0
; 	trkInsPsg   0,$10,$00,$10,$02,$02
; 	trkInsFm    0,FmIns_Bass_mecan,0
; 	trkInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
; 	trkInsNull
; 	trkInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsNull
; 	trkInsFm    0,FmIns_Trumpet_2,0
; 	trkInsNull

GemaTrk_mars_blk:
	binclude "sound/tracks/mars_blk.bin"
GemaTrk_mars_patt:
	binclude "sound/tracks/mars_patt.bin"
GemaTrk_mars_ins:
	trkInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
	trkInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
	trkInsPsgN  0,$20,$FF,$00,$30,$30,%100
	trkInsFm    0,FmIns_PianoM1,0
	trkInsPsg   0,$40,$20,$20,$00,$00
	trkInsFm    0,FmIns_Bass_7,0
	trkInsNull
	trkInsNull
	trkInsFm    0,FmIns_Guitar_heavy,0
	trkInsNull
	trkInsNull

GemaTrk_jackrab_blk:
	binclude "sound/tracks/jackrab_blk.bin"
GemaTrk_jackrab_patt:
	binclude "sound/tracks/jackrab_patt.bin"
GemaTrk_jackrab_ins:
	trkInsFm    0,FmIns_Ambient_Spook,0
	trkInsNull
	trkInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
	trkInsPsgN  0,$20,$FF,$10,$10,$10,%100
	trkInsNull
	trkInsNull
	trkInsFm    0,FmIns_PianoM1,0
	trkInsNull
	trkInsNull
	trkInsPsg   0,$20,$FF,$20,$04,$04
	trkInsFm    0,FmIns_Ambient_Dark,0
	trkInsNull
	trkInsFm    0,FmIns_Ding_Toy,0
	trkInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
	trkInsFm    0,FmIns_Trumpet_2,0
	trkInsNull
