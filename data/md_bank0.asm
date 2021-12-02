; ====================================================================
; ----------------------------------------------------------------
; Single 68k DATA BANK for MD ($900000-$9FFFFF)
; for stuff other than MD's DMA data
; 
; Maximum size: $0FFFFF bytes per bank
; ----------------------------------------------------------------

		align 2
MAP_FGTEST:
		binclude "data/md/bg/fg_map.bin"
		align 2
MAP_BGTEST:
		binclude "data/md/bg/bg_map.bin"
		align 2
