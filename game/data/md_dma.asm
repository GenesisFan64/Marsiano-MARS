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
ART_TEST3D:	binclude "game/data/maps/3D/md_bg/md_bg_art.bin"
ART_TEST3D_e:
		align $8000
Art_level0:	binclude "game/data/maps/2D/level0/art.bin"
Art_level0_e:




