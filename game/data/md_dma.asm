; ====================================================================
; ----------------------------------------------------------------
; DMA ROM-DATA Transfer section
; 
; RV bit must be enabled to read from here
; ----------------------------------------------------------------

	if MCD|MARSCD=0
		align $8000
	endif
ASCII_FONT:	binclude "system/md/data/font.bin"
ASCII_FONT_e:
ArtMd_TEST:	binclude "game/data/TESTS/md_art.bin"
ArtMd_TEST_e:
		align 2

		align $8000
ART_TESTBOARD:	binclude "game/data/md/bg/board_art.bin"
ART_TESTBOARD_e:
ART_EMI:	binclude "game/data/md/sprites/emi_art.bin"
ART_EMI_e:




