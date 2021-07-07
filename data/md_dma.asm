; ====================================================================
; ----------------------------------------------------------------
; DMA ROM DATA Transfer section, no bank limitations
; 
; RV bit must be set to access here
; ----------------------------------------------------------------

		align $8000
MdGfx_BgTest:
		binclude "data/md/bg/bg_art.bin"
MdGfx_BgTest_e:	align 2

