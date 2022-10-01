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
TESTMARS_BG:
		binclude "data/mars/tests/test_art.bin"
		align 4
; TESTMARS_BG2:
; 		binclude "data/mars/tests/test2_art.bin"
; 		align 4
TestMars_Yui:
		binclude "data/mars/tests/yui_mars_art.bin"
		align 4

; TESTMARS_DIRECT_1:
; 		binclude "data/mars/tests/direct/frame0_art.bin"
; 		align 4
; TESTMARS_DIRECT_2:
; 		binclude "data/mars/tests/direct/frame1_art.bin"
; 		align 4
; TESTMARS_DIRECT_3:
; 		binclude "data/mars/tests/direct/frame2_art.bin"
; 		align 4

; Textr_smoke:
; 		binclude "data/mars/objects/mtrl/smoke_art.bin"
; 		align 4

Textr_pecsi:
		binclude "data/mars/objects/mtrl/pecsi_art.bin"
		align 4

SuperSpr_Test:
	binclude "data/sprites/mars/nicole/sprites_art.bin"
	align 4
