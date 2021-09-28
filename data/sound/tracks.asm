; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; 
; SOUND
; ------------------------------------------------------------

gemaInsPsg	macro pitch,psgins
		dc.b 0,pitch
		dc.b psgins&$FF,((psgins>>8)&$FF)
		dc.b 0,0
		dc.b 0,0
		endm

gemaInsPsgN	macro pitch,psgins,type
		dc.b 1,pitch
		dc.b psgins&$FF,((psgins>>8)&$FF)
		dc.b type,0
		dc.b 0,0
		endm

gemaInsFm	macro pitch,fmins
		dc.b 2,pitch
		dc.b fmins&$FF,((fmins>>8)&$FF)
		dc.b 0,0
		dc.b 0,0
		endm

gemaInsFm3	macro pitch,fmins,freq1,freq2,freq3
		dc.b 3,pitch
		dc.b fmins&$FF,((fmins>>8)&$FF)
		dc.b 0,0
		dc.b 0,0		
		endm

; Dac samples:
; first dacins points to a zSmpl stored on Z80
; (see instr_z80.asm)
; then in your zSmpl, it will have the
; ROM pointers for START, ENDING and LOOP
; (LEN is automaticly set in the macro)
gemaInsDac	macro pitch,dacins,flags
		dc.b 4,pitch
		dc.b dacins&$FF,((dacins>>8)&$FF)
		dc.b flags,0		; flags: 0-dont loop, 1-loop
		dc.b 0,0
		endm

; TODO: rework on this
; gemaInsPwm	macro pitch,pointer
; 		dc.b 5,pitch
; 		dc.b 0,0		; filler
; 		dc.b ((pointer>>24)&$FF),((pointer>>16)&$FF)
; 		dc.b ((pointer>>8)&$FF),pointer&$FF
; 		endm

gemaInsNull	macro
		dc.b -1,0
		dc.b  0,0
		dc.b  0,0
		dc.b  0,0
		endm

; ------------------------------------------------------------

; TEST_BLOCKS	binclude "data/sound/tracks/temple_blk.bin"
; TEST_PATTERN	binclude "data/sound/tracks/temple_patt.bin"
; TEST_INSTR
; 		gemaInsPsg  0,PsgIns_01
; 		gemaInsPsg  0,PsgIns_01
; 		gemaInsPsgN 0,PsgIns_Snare,%101
; 
; TEST_BLOCKS_2	binclude "data/sound/tracks/kraid_blk.bin"
; TEST_PATTERN_2	binclude "data/sound/tracks/kraid_patt.bin"
; TEST_INSTR_2
; 		gemaInsPsgN 0,PsgIns_Bass,%011
; 		gemaInsPsg  0,PsgIns_03

GemaTrk_brinstr_blk:
		binclude "data/sound/tracks/brinstr_blk.bin"
GemaTrk_brinstr_patt:
		binclude "data/sound/tracks/brinstr_patt.bin"
GemaTrk_brinstr_ins:
		gemaInsPsg  0,PsgIns_03
		gemaInsPsgN 0,PsgIns_Bass,%011

GemaTrk_yuki_blk:
		binclude "data/sound/tracks/yuki_blk.bin"
GemaTrk_yuki_patt:
		binclude "data/sound/tracks/yuki_patt.bin"
GemaTrk_yuki_ins:
		gemaInsDac 0,DacIns_Snare,0
		gemaInsNull
		gemaInsFm  0,FmIns_Bass_4,0
		gemaInsDac 0,DacIns_KickSpnb,0
		gemaInsNull
		gemaInsFm  0,FmIns_PianoM1,0
		gemaInsPsg  0,PsgIns_03
		gemaInsPsgN 0,PsgIns_03,%100
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
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull
		gemaInsNull

; 		gemaInsPwm -17,PwmIns_TECHNOBASSD
; 		gemaInsFm    0,FmIns_Bass_metal
; 		gemaInsPwm -17,PwmIns_WHODSNARE
; 		gemaInsPsgN  0,PsgIns_00,%100
; 		gemaInsFm    0,FmIns_Bass_2
; 		gemaInsPwm -17,PwmIns_TECHNOBASSD
; 		gemaInsPwm -17,PwmIns_SPHEAVY1
; 		gemaInsPwm -17,PwmIns_MCLSTRNG
