; ====================================================================
; ----------------------------------------------------------------
; Put your 32X palettes here
;
; These are located on a single 68K $900000+ bank
;
; Labels MUST be aligned by 2
; ----------------------------------------------------------------

		align 2
PalMars_TEST:
		binclude "game/data/TESTS/mars_pal.bin"
		align 2

; PalMars_MarsCity:
; 		binclude "game/data/maps/3D/mcity/mtrl/marscity_pal.bin"
; 		align 2
;
; MapPal_M:	binclude "game/data/maps/2D/level0/m_pal.bin"
; 		align 2
; TestSupSpr_Pal:
; 		binclude "game/data/sprites/mars/nicole/sprites_pal.bin"
; 		align 2