; ====================================================================
; ----------------------------------------------------------------
; BANK 0 of 68k data ($900000-$9FFFFF)
; for big stuff like maps, levels, etc.
;
; For graphics use DMA and place your files at
; md_dma.asm (Watch out for the $20000 limit.)
;
; Maximum size: $0FFFFF bytes per bank
; ----------------------------------------------------------------

		include "game/data/m_palettes.asm"	; All 32X palettes will be here.

		align 2
Pal_level0:	binclude "game/data/maps/2D/level0/pal.bin"
		align 2
Pal_Test3D:	binclude "game/data/maps/3D/md_bg/md_bg_pal.bin"
		align 2
Map_Test3D:	binclude "game/data/maps/3D/md_bg/md_bg_map.bin"
		align 2

; ----------------------------------------------------------------

		align 2
MapHead_0:	binclude "game/data/maps/2D/level0/head.bin"
MapBlk_0:	binclude "game/data/maps/2D/level0/blocks.bin"
		align 2
MapFgL_0:	binclude "game/data/maps/2D/level0/fg_low.bin"
		align 2
MapFgH_0:	binclude "game/data/maps/2D/level0/fg_hi.bin"
		align 2
MapFgC_0:	binclude "game/data/maps/2D/level0/fg_col.bin"
		align 2
MapBgL_0:	binclude "game/data/maps/2D/level0/bg_low.bin"
		align 2
MapBgH_0:	binclude "game/data/maps/2D/level0/bg_hi.bin"
		align 2

; ----------------------------------------------------------------
; 68k data for 32X maps go here:
; Headers and Collision

		align 2
MapHead_M:	binclude "game/data/maps/2D/level0/m_head.bin"
		align 2
MapCol_M:	binclude "game/data/maps/2D/level0/m_col.bin"
		align 2

; ----------------------------------------------------------------

MapCamera_0:
		binclude "game/data/maps/3D/mcity/anim/mcity_anim.bin"
		align 4
