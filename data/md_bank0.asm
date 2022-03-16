; ====================================================================
; ----------------------------------------------------------------
; BANK 0 of 68k data ($900000-$9FFFFF)
; for big stuff like maps, levels, etc.
;
; For graphics use DMA and place your files at
; md_dma.asm (Watch out for the $20000-section limit.)
;
; Maximum size: $0FFFFF bytes per bank
; ----------------------------------------------------------------

		align 2
TESTMARS_BG_PAL:
		binclude "data/mars/test_pal.bin"
		align 2
MDLDATA_PAL_TEST:
		binclude "data/mars/objects/mtrl/pecsi_pal.bin"
		align 2

MAP_FGTEST:	binclude "data/md/bg/fg_map.bin"
		align 2
MAP_BGTEST:	binclude "data/md/bg/bg_map.bin"
		align 2
