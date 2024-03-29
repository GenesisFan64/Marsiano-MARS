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
SmpIns_TEST:
	gSmpHead .end-.start,0
.start:	binclude "sound/instr/smpl/livin_st.wav",$2C
.end:

; --------------------------------------------------------
; 32X MAP data: Block graphics and Layout
; --------------------------------------------------------

; 		align 4
; MapBlk_M:	binclude "game/data/maps/2D/level0/m_art.bin"
; 		align 4
; MapFg_M:	binclude "game/data/maps/2D/level0/m_fg.bin"
; 		align 4

; --------------------------------------------------------
; Graphics
; --------------------------------------------------------

		include "game/data/m_graphics.asm"

; --------------------------------------------------------
; Models
; --------------------------------------------------------

; 		align 4
; 		include "game/data/maps/3D/mcity/mars_data.asm"
; 		align 4

; MarsObj_test:
; 		include "game/data/mars/objects/mdl/test/head.asm"

