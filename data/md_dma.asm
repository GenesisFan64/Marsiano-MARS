; ====================================================================
; ----------------------------------------------------------------
; DMA ROM DATA Transfer section, no bank limitations
; 
; RV bit must be set to access here
; ----------------------------------------------------------------

		align $8000
ART_BGTEST:	binclude "data/md/bg/bg_art.bin"
ART_BGTEST_e:
ART_FGTEST:	binclude "data/md/bg/fg_art.bin"
ART_FGTEST_e:
ART_EMI:	binclude "data/md/sprites/emi_art.bin"
ART_EMI_e:

