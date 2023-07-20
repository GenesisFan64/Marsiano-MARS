; ====================================================================
; ----------------------------------------------------------------
; DMA ROM-DATA Transfer section
; 
; RV bit must be enabled to read from here
; ----------------------------------------------------------------

		align $8000
ASCII_FONT:	binclude "system/md/data/font.bin"
ASCII_FONT_e:

ArtMd_TEST:	binclude "game/data/TESTS/md_art.bin"
ArtMd_TEST_e:
		align 2




