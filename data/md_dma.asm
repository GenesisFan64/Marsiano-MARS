; ====================================================================
; ----------------------------------------------------------------
; DMA ROM DATA Transfer section
; 
; RV bit must be enabled to read from here
; ----------------------------------------------------------------


ASCII_FONT:	binclude "system/md/data/font.bin"
ASCII_FONT_e:

ART_FGTEST:	binclude "data/md/bg/fg_art.bin"
ART_FGTEST_e:

		align $8000
ART_EMI:	binclude "data/md/sprites/emi_art.bin"
ART_EMI_e:
		align 2

