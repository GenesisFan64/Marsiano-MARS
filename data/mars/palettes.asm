; ====================================================================
; ----------------------------------------------------------------
; Put your 32X palettes here
;
; These are located on a single 68K $900000+ bank
;
; Labels MUST be aligned by 2
; ----------------------------------------------------------------

		align 2
PalData_Mars_Test:
		binclude "data/mars/tests/test_pal.bin"
		align 2
MDLDATA_PAL_TEST:
		binclude "data/mars/objects/mtrl/pecsi_pal.bin"
		align 2
; TestMars_YuiP:
; 		binclude "data/mars/tests/yui_mars_pal.bin"
; 		align 2

MapPal_M:	binclude "data/maps/level0/pal_m.bin"
		align 2

TestSupSpr_Pal:
		binclude "data/mars/tests/sprites/sprites_pal.bin"
		align 2
