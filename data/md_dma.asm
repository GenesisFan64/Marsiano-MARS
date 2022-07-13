; ====================================================================
; ----------------------------------------------------------------
; DMA ROM DATA Transfer section
; 
; RV bit must be enabled to read from here
; ----------------------------------------------------------------

		align $8000
ASCII_FONT:	binclude "system/md/data/font.bin"
ASCII_FONT_e:

		align $8000
ART_EMI:	binclude "data/md/sprites/emi_art.bin"
ART_EMI_e:
Art_level0:	binclude "data/md/maps/level0/art.bin"
Art_level0_e:




