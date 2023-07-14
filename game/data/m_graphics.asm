; ====================================================================
; ----------------------------------------------------------------
; Put your 32X graphics here, indexed or direct
;
; These are located on the SH2's ROM area, this will be gone
; if RV is set to 1
;
; Labels MUST be aligned by 4
; ----------------------------------------------------------------

		align 4
Textr_marscity:
		binclude "game/data/maps/3D/mcity/mtrl/marscity_art.bin"
		align 4
SuperSpr_Test:
		binclude "game/data/sprites/mars/nicole/sprites_art.bin"
		align 4
