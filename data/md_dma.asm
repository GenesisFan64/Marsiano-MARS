; ====================================================================
; ----------------------------------------------------------------
; DMA ROM DATA Transfer section
; 
; RV bit must be enabled to read from here
; ----------------------------------------------------------------

		align $8000
ASCII_FONT:	binclude "system/md/data/font.bin"
ASCII_FONT_e:
		align 2

ART_BGTEST:	binclude "data/md/bg/bg_art.bin"
ART_BGTEST_e:
ART_FGTEST:	binclude "data/md/bg/fg_art.bin"
ART_FGTEST_e:
ART_EMI:	binclude "data/md/sprites/emi_art.bin"
ART_EMI_e:

