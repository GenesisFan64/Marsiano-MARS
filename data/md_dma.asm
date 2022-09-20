; ====================================================================
; ----------------------------------------------------------------
; DMA ROM-DATA Transfer section
; 
; RV bit must be enabled to read from here
; ----------------------------------------------------------------

		align $8000
ASCII_FONT:	binclude "system/md/data/font.bin"
ASCII_FONT_e:

		align $8000
ART_TEST3D:	binclude "data/bg/md/test_3d/md_bg_art.bin"
ART_TEST3D_e:
Art_level0:	binclude "data/maps/level0/art.bin"
Art_level0_e:




