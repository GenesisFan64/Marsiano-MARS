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
		dc.b freq1&$FF,((freq1>>8)&$FF)
		dc.b freq2&$FF,((freq2>>8)&$FF)
		dc.b freq3&$FF,((freq3>>8)&$FF)
		dc.b $00,$00,$00,$00
		endm

gemaInsFm6	macro pitch,start,end,loop
		dc.b 4,pitch
		dc.b start&$FF,((start>>8)&$FF),((start>>16)&$FF)
		dc.b ((end-start)&$FF),(((end-start)>>8)&$FF),(((end-start)>>16)&$FF)
		dc.b loop&$FF,((loop>>8)&$FF),((loop>>16)&$FF)
		dc.b 0,0,0,0
		endm

gemaInsPwm	macro pitch,start,end,loop
		dc.b 5,pitch
		dc.b start&$FF,((start>>8)&$FF),((start>>16)&$FF)
		dc.b ((end-start)&$FF),(((end-start)>>8)&$FF),(((end-start)>>16)&$FF)
		dc.b loop&$FF,((loop>>8)&$FF),((loop>>16)&$FF)
		dc.b 0,0,0,0
		endm

; ------------------------------------------------------------

; TEST_BLOCKS	binclude "data/sound/tracks/temple_blk.bin"
; TEST_PATTERN	binclude "data/sound/tracks/temple_patt.bin"
; TEST_INSTR
; 		gemaInsPsg  0,PsgIns_01
; 		gemaInsPsg  0,PsgIns_01
; 		gemaInsPsgN 0,PsgIns_Snare,%101

GemaTrk_brinstr_blk:
		binclude "data/sound/tracks/brinstr_blk.bin"
GemaTrk_brinstr_patt:
		binclude "data/sound/tracks/brinstr_patt.bin"
GemaTrk_brinstr_ins:
		gemaInsPsg    0,$30,$80,$10,$00,$01
		gemaInsPsgN -12,$00,$FF,$00,$00,$01,%011

GemaTrk_gigalo_blk:
		binclude "data/sound/tracks/gigalo_blk.bin"
GemaTrk_gigalo_patt:
		binclude "data/sound/tracks/gigalo_patt.bin"
GemaTrk_gigalo_ins:
		gemaInsPsg   0,$10,$FF,$10,$08,$08
		gemaInsPsgN  0,$00,$FF,$00,$04,$08,%100
		gemaInsPsgN  0,$00,$FF,$00,$04,$08,%101
		gemaInsPsgN  0,$00,$FF,$00,$04,$04,%110
		gemaInsNull

GemaTrk_mars_blk:
		binclude "data/sound/tracks/mars_blk.bin"
GemaTrk_mars_patt:
		binclude "data/sound/tracks/mars_patt.bin"
GemaTrk_mars_ins:
		gemaInsNull
		gemaInsNull
		gemaInsPsgN  0,$00,$FF,$00,$10,$10,%100
		gemaInsFm    0,FmIns_PianoM1,0
		gemaInsPsg   0,$40,$FF,$40,$00,$00
		gemaInsFm    0,FmIns_Bass_3,0
		gemaInsNull
		gemaInsNull
		gemaInsFm    0,FmIns_Guitar_heavy,0
		gemaInsNull
		gemaInsFm    0,FmIns_ding_toy,0

GemaTrk_jackrab_blk:
		binclude "data/sound/tracks/jackrab_blk.bin"
GemaTrk_jackrab_patt:
		binclude "data/sound/tracks/jackrab_patt.bin"
GemaTrk_jackrab_ins:
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsPsgN  0,$00,$FF,$00,$08,$08,%100
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsPsg   0,$10,$FF,$40,$04,$04
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
