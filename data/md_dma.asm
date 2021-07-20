; ====================================================================
; ----------------------------------------------------------------
; DMA ROM DATA Transfer section, no bank limitations
; 
; RV bit must be set to access here
; ----------------------------------------------------------------

		align $8000
MdGfx_BgTestT:
		binclude "data/md/bg/bg_t_art.bin"
MdGfx_BgTestT_e:
		align 2

MdGfx_BgTestB:
		binclude "data/md/bg/bg_b_art.bin"
MdGfx_BgTestB_e:
		align 2

