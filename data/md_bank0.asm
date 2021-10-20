; ====================================================================
; ----------------------------------------------------------------
; Single 68k DATA BANK for MD ($900000-$9FFFFF)
; for stuff other than MD's DMA data
; 
; Maximum size: $0FFFFF bytes per bank
; ----------------------------------------------------------------

		align $8000
		include "data/sound/tracks.asm"
		align 2
		include "data/sound/instr.asm"
		align 2

; CAMERA_INTRO:	binclude "data/mars/objects/anim/intro_anim.bin"
; 		align 4
; CAMERA_INTNAME:	binclude "data/mars/objects/anim/projcam_anim.bin"
; 		align 4
; CAMERA_CITY:	binclude "data/mars/maps/anim/camera_anim.bin"
; 		align 4

; MdMap_Bg:
; 		binclude "data/md/bg/bg_map.bin"
; 		align 2
; MdMap_BgTestB:
; 		binclude "data/md/bg/bg_b_map.bin"
; 		align 2
; MdMap_BgTestT:
; 		binclude "data/md/bg/bg_t_map.bin"
; 		align 2
;
;

PCM_START:	binclude "data/sound/test_md.wav",$2C,$05FFFF
PCM_END:
