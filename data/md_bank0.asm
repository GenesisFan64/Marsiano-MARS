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

		include "data/mars/palettes.asm"	; All 32X palettes will be here.

		align 2
Pal_level0:	binclude "data/md/maps/level0/pal.bin"
		align 2
; ----------------------------------------------------------------

		align 2
MapHead_0:	binclude "data/md/maps/level0/head.bin"
MapBlk_0:	binclude "data/md/maps/level0/blocks.bin"
		align 2
MapFgL_0:	binclude "data/md/maps/level0/fg_low.bin"
		align 2
MapFgH_0:	binclude "data/md/maps/level0/fg_hi.bin"
		align 2
MapFgC_0:	binclude "data/md/maps/level0/fg_col.bin"
		align 2
MapBgL_0:	binclude "data/md/maps/level0/bg_low.bin"
		align 2
MapBgH_0:	binclude "data/md/maps/level0/bg_hi.bin"
		align 2
