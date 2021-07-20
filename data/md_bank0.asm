; ====================================================================
; ----------------------------------------------------------------
; Single 68k DATA BANK for MD ($900000-$9FFFFF)
; for stuff other than MD's DMA data
; 
; Maximum size: $0FFFFF bytes per bank
; ----------------------------------------------------------------

		align $8000
		include "data/sound/tracks.asm"
		align 4
; CAMERA_INTRO:	binclude "data/mars/objects/anim/intro_anim.bin"
; 		align 4
; CAMERA_INTNAME:	binclude "data/mars/objects/anim/projcam_anim.bin"
; 		align 4
; CAMERA_CITY:	binclude "data/mars/maps/anim/camera_anim.bin"
; 		align 4

; MdMap_Bg:
; 		binclude "data/md/bg/bg_map.bin"
; 		align 2
MdMap_BgTestB:
		binclude "data/md/bg/bg_b_map.bin"
		align 2
MdMap_BgTestT:
		binclude "data/md/bg/bg_t_map.bin"
		align 2


Sampl_Magic1:	binclude "data/sound/instr/smpl/magic_1.wav",$2C
Sampl_Magic1_End:
Sampl_Magic2:	binclude "data/sound/instr/smpl/magic_2.wav",$2C
Sampl_Magic2_End:
Sampl_MyTime:	binclude "data/sound/instr/smpl/mytime.wav",$2C
Sampl_MyTime_End:

; PWM_START:	binclude "data/sound/pwm_m.wav",$2C,$05FFFF
; PWM_END:
