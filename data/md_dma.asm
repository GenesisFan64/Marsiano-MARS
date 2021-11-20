; ====================================================================
; ----------------------------------------------------------------
; DMA ROM DATA Transfer section, no bank limitations
; 
; RV bit must be set to access here
; ----------------------------------------------------------------

		align $8000
ART_EMI:	binclude "data/md/sprites/emi_art.bin"
ART_EMI_e:

