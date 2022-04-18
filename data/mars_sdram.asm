; ====================================================================
; ----------------------------------------------------------------
; SH2 SDRAM data
; 
; This data is stored on SDRAM, always available to use on the 32X
; side and can be rewritible, but it is smaller than ROM
;
; Your palettes, textures, models go here
; PWM samples can be used here but those take a lot of space...
; use ROM (mars_rom.asm) instead, those are RV-protected on SH2
; ----------------------------------------------------------------

	align 4

; --------------------------------------------------------
; Models
; --------------------------------------------------------

	include "data/mars/objects/mdl/test/head.asm"
