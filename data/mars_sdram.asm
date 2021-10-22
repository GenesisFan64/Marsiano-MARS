; ====================================================================
; ----------------------------------------------------------------
; SH2 SDRAM user data
; 
; This data is stored on SDRAM, it's always available to use
; and can be re-writeable
; Put small sections of data like palettes or small models
; ----------------------------------------------------------------

; --------------------------------------------------------
; Palettes
; --------------------------------------------------------

; Palette_Intro:	binclude "data/mars/objects/mtrl/intro_pal.bin"
; 		align 4
; Palette_Map:	binclude "data/mars/maps/mtrl/marscity_pal.bin"
; 		align 4
; Palette_projname:
; 		binclude "data/mars/objects/mtrl/projname_pal.bin"
; 		align 4

; --------------------------------------------------------
; Objects
; --------------------------------------------------------

; 		include "data/mars/objects/mdl/intro_1/head.asm"
; 		align 4
; 		include "data/mars/objects/mdl/intro_2/head.asm"
; 		align 4

; ====================================================================
; ----------------------------------------------------------------
; PWM Instrument pointers stored on 32X's SDRAM area
; the sample data is stored on the 32X's ROM view area
; (data/mars_rom.asm)
; ----------------------------------------------------------------
