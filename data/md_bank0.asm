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
; MdMap_BgTestB:
; 		binclude "data/md/bg/bg_b_map.bin"
; 		align 2
; MdMap_BgTestT:
; 		binclude "data/md/bg/bg_t_map.bin"
; 		align 2
;
;

; --------------------------------------------------------
; DAC/PWM samples
; --------------------------------------------------------

DacIns_CdSnare:
		binclude "data/sound/instr/smpl/cd_snare.wav",$2C
DacIns_CdSnare_e:

DacIns_SaurKick:
		binclude "data/sound/instr/smpl/sauron_kick.wav",$2C
DacIns_SaurKick_e:
DacIns_SaurSnare:
		binclude "data/sound/instr/smpl/sauron_snare.wav",$2C
DacIns_SaurSnare_e:

; Sampl_KickSpinb:
; 		binclude "data/sound/instr/smpl/spinb_kick.wav",$2C
; Sampl_KickSpinb_End:
;
; Sampl_Kick:	binclude "data/sound/instr/smpl/stKick.wav",$2C
; Sampl_Kick_End:
; Sampl_Snare:	binclude "data/sound/instr/smpl/snare.wav",$2C
; Sampl_Snare_End:

PCM_START:	binclude "data/sound/test_md.wav",$2C,$03FFFF
PCM_END:
