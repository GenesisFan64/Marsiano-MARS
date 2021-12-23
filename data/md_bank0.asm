; ====================================================================
; ----------------------------------------------------------------
; BANK 0 of 68k data ($900000-$9FFFFF)
; for big stuff like maps, levels, etc.
;
; For the graphics see md_dma.asm
;
; Maximum size: $0FFFFF bytes per bank
; ----------------------------------------------------------------

		align 2
TESTMARS_BG_PAL:
		binclude "data/mars/test_pal.bin"
		align 2
MAP_FGTEST:	binclude "data/md/bg/fg_map.bin"
		align 2
MAP_BGTEST:	binclude "data/md/bg/bg_map.bin"
		align 2
