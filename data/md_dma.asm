; ====================================================================
; ----------------------------------------------------------------
; DMA ROM DATA Transfer section
; 
; RV bit must be enabled to read from here
; ----------------------------------------------------------------

		align 2

		align $8000
ART_EMI:	binclude "data/md/sprites/emi_art.bin"
ART_EMI_e:
; ART_TestMap:	binclude "data/md/bg/test_art.bin"
; ART_TestMap_e:

		align $8000
ASCII_FONT:	binclude "system/md/data/font.bin"
ASCII_FONT_e:

ART_FGTEST:	binclude "data/md/bg/fg_art.bin"
ART_FGTEST_e:
ART_BGTEST:	binclude "data/md/bg/bg_art.bin"
ART_BGTEST_e:


