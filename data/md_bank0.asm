; ====================================================================
; ----------------------------------------------------------------
; BANK 0 of 68K data ($900000-$9FFFFF)
; for big stuff like maps, levels, etc.
;
; For graphics do a DMA transfer and place your graphics at
; md_dma.asm
;
; Maximum size: $0FFFFF bytes per bank
; (except for Bank 0, it's a little lower)
; ----------------------------------------------------------------

		align 2
PalData_Mars_Test:
		binclude "data/mars/test_pal.bin"
		align 2
PalData_Mars_Test2:
		binclude "data/mars/test2_pal.bin"
		align 2
MDLDATA_PAL_TEST:
		binclude "data/mars/objects/mtrl/pecsi_pal.bin"
		align 2
MAP_FGTEST:	binclude "data/md/bg/fg_map.bin"
		align 2
MAP_BGTEST:	binclude "data/md/bg/bg_map.bin"
		align 2
