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

; alv: attack level
; atk: attack rate
; slv: sustain
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
		gemaInsPsg    0,$40,$FF,$FF,$01,$01
		gemaInsPsgN -12,$00,$FF,$FF,$02,$04,%011

GemaTrk_mars_blk:
		binclude "data/sound/tracks/mars_blk.bin"
GemaTrk_mars_patt:
		binclude "data/sound/tracks/mars_patt.bin"
GemaTrk_mars_ins:
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
