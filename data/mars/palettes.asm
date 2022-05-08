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
		binclude "data/mars/tests/sprites/sprites_pal.bin"
		align 2
PalData_Mars_Test2:
		binclude "data/mars/tests/test2_pal.bin"
		align 2
MDLDATA_PAL_TEST:
		binclude "data/mars/objects/mtrl/smoke_pal.bin"
		align 2
