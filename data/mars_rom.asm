; ====================================================================
; ----------------------------------------------------------------
; SH2 ROM data
;
; If your data is too much for SDRAM, place it here.
; BUT keep in mind that this entire section will be gone
; if the Genesis performs DMA-to-VDP Transfers
; which requires RV=1 (Revert ROM to original position)
; ***EMULATORS IGNORE THIS LIMITATION***
;
; Only access here on these conditions:
; - Stop all tracks that use PWM samples
; - If you wanna keep any tracks active: set 1 to marsBlock
;   in the Z80 driver, all tracks will continue playing using
;   only the PSG and FM instruments
;   (TODO: check how it peforms)
;
; The PWM samples are safe to use with the implementation
; of a sample-backup routine that the 68K requests before
; doing DMA
; ----------------------------------------------------------------

	align 4

; --------------------------------------------------------
; 32X MAP data: Block graphics and Layout
; --------------------------------------------------------

		align 4
MapBlk_M:	binclude "data/maps/level0/art_m.bin"
		align 4
MapFg_M:	binclude "data/maps/level0/fg_main.bin"
		align 4

; --------------------------------------------------------
; Graphics
; --------------------------------------------------------

		include "data/mars/graphics.asm"

; --------------------------------------------------------
; Models
; --------------------------------------------------------

		align 4
; MCity_Pz_Null:
; 		include "data/maps/mars/mcity/mdl/pz_null/head.asm"
		include "data/maps/mars/mcity/map_incl.asm"
		align 4
