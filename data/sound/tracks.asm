; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

; Null instrument
gemaInsNull	macro
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
gemaInsPsg	macro pitch,alv,atk,slv,dky,rrt
		dc.b $00,pitch,alv,atk
		dc.b slv,dky,rrt,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

; mode: noise mode (PSGN only)
gemaInsPsgN	macro pitch,alv,atk,slv,dky,rrt,mode
		dc.b $01,pitch,alv,atk
		dc.b slv,dky,rrt,mode
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

gemaInsFm	macro pitch,fmins
		dc.b $02,pitch,fmins&$FF,((fmins>>8)&$FF)
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

gemaInsFm3	macro pitch,fmins,freq1,freq2,freq3
		dc.b $03,pitch,fmins&$FF,((fmins>>8)&$FF)
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		dc.b $00,$00,$00,$00
		endm

gemaInsDac	macro pitch,start,end,loop,flags
		dc.b $04,pitch
		dc.b start&$FF,((start>>8)&$FF),((start>>16)&$FF)
		dc.b ((end-start)&$FF),(((end-start)>>8)&$FF),(((end-start)>>16)&$FF)
		dc.b loop&$FF,((loop>>8)&$FF),((loop>>16)&$FF)
		dc.b flags,0,0,0,0
		endm

gemaInsPwm	macro pitch,start,end,loop,flags
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

; TEST_BLOCKS	binclude "data/sound/tracks/temple_blk.bin"
; TEST_PATTERN	binclude "data/sound/tracks/temple_patt.bin"
; TEST_INSTR
; 		gemaInsPsg  0,PsgIns_01
; 		gemaInsPsgN 0,PsgIns_Snare,%101

GemaTrk_brinstr_blk:
		binclude "data/sound/tracks/brinstr_blk.bin"
GemaTrk_brinstr_patt:
		binclude "data/sound/tracks/brinstr_patt.bin"
GemaTrk_brinstr_ins:
		gemaInsPsg   0,$30,$FF,$20,$01,$01
		gemaInsPsgN -12,$00,$FF,$00,$00,$01,%011

GemaTrk_gigalo_blk:
		binclude "data/sound/tracks/gigalo_blk.bin"
GemaTrk_gigalo_patt:
		binclude "data/sound/tracks/gigalo_patt.bin"
GemaTrk_gigalo_ins:
		gemaInsPsg   0,$30,$FF,$30,$08,$08
		gemaInsPsgN  0,$00,$FF,$00,$04,$04,%100
		gemaInsPsgN  0,$00,$FF,$00,$04,$04,%101
		gemaInsPsgN  0,$00,$FF,$00,$04,$04,%110
		gemaInsNull

GemaTrk_mecano_blk:
		binclude "data/sound/tracks/mecano_blk.bin"
GemaTrk_mecano_patt:
		binclude "data/sound/tracks/mecano_patt.bin"
GemaTrk_mecano_ins:
		gemaInsPsgN  0,$00,$FF,$00,$08,$08,%100
		gemaInsPsgN  0,$00,$FF,$00,$10,$10,%100
		gemaInsFm    0,FmIns_PianoM1,0
		gemaInsPsg   0,$10,$FF,$10,$04,$02
		gemaInsFm    0,FmIns_Bass_3,0
		gemaInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
		gemaInsNull
		gemaInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsFm    0,FmIns_Bass_6,0
		gemaInsFm    0,FmIns_Trumpet_2,0
		gemaInsNull

GemaTrk_mars_blk:
		binclude "data/sound/tracks/mars_blk.bin"
GemaTrk_mars_patt:
		binclude "data/sound/tracks/mars_patt.bin"
GemaTrk_mars_ins:
		gemaInsDac   0,DacIns_CdSnare,DacIns_CdSnare_e,0,0
		gemaInsDac   0,DacIns_SaurKick,DacIns_SaurKick_e,0,0
		gemaInsPsgN  0,$20,$FF,$00,$30,$30,%100
		gemaInsFm    0,FmIns_PianoM1,0
		gemaInsPsg   0,$50,$20,$30,$00,$00
		gemaInsFm    0,FmIns_Bass_7,0
		gemaInsNull
		gemaInsNull
		gemaInsFm    0,FmIns_Guitar_heavy,0
		gemaInsNull
		gemaInsNull

GemaTrk_jackrab_blk:
		binclude "data/sound/tracks/jackrab_blk.bin"
GemaTrk_jackrab_patt:
		binclude "data/sound/tracks/jackrab_patt.bin"
GemaTrk_jackrab_ins:
		gemaInsFm    0,FmIns_Ambient_Spook,0
		gemaInsNull
		gemaInsNull
		gemaInsPsgN  0,$20,$FF,$10,$10,$10,%100
		gemaInsNull
		gemaInsNull
		gemaInsFm    0,FmIns_PianoM1,0
		gemaInsNull
		gemaInsNull
		gemaInsPsg   0,$30,$FF,$20,$08,$08
		gemaInsFm    0,FmIns_Ambient_Dark,0
		gemaInsNull
		gemaInsFm    0,FmIns_Ding_Toy,0
		gemaInsNull
		gemaInsFm    0,FmIns_Trumpet_2,0
		gemaInsNull
