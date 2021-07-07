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
		
gemaInsDac	macro pitch,dacins,flags
		dc.b 4,pitch
		dc.b dacins&$FF,((dacins>>8)&$FF)
		dc.b flags,0		; flags: 0-dont loop, 1-loop
		dc.b 0,0
		endm

; Pointers go to instr_sdram.asm
; 
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

; GemaTrk_Yuki_blk:
; 		binclude "data/sound/tracks/marscomm_blk.bin"
; GemaTrk_Yuki_patt:
; 		binclude "data/sound/tracks/marscomm_patt.bin"
; GemaTrk_Yuki_ins:
; 		gemaInsPwm -17,PwmIns_TECHNOBASSD
; 		gemaInsFm    0,FmIns_Bass_metal
; 		gemaInsPwm -17,PwmIns_WHODSNARE
; 		gemaInsPsgN  0,PsgIns_00,%100
; 		gemaInsFm    0,FmIns_Bass_2
; 		gemaInsPwm -17,PwmIns_TECHNOBASSD
; 		gemaInsPwm -17,PwmIns_SPHEAVY1
; 		gemaInsPwm -17,PwmIns_MCLSTRNG

GemaTrk_Demo_blk:
		binclude "data/sound/tracks/demo_blk.bin"
GemaTrk_Demo_patt:
		binclude "data/sound/tracks/demo_patt.bin"
GemaTrk_Demo_ins:
		gemaInsDac  0,DacIns_MyTime,0
		gemaInsDac  0,DacIns_Magic1,0
		gemaInsDac  0,DacIns_Magic2,0
		gemaInsNull;Fm   0,FmIns_Ambient_dark
		gemaInsFm   0,FmIns_Bass_Calm
		gemaInsNull
