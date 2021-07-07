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

; Example:		
; PwmIns_SPHEAVY1:
; 		dc.l PwmInsWav_SPHEAVY1		; Start
; 		dc.l PwmInsWav_SPHEAVY1_e	; End
; 		dc.l -1				; Sample loop point (-1: don't loop)
; 		dc.l %011			; Flags:
; 						; %S0000000 S-stereo sample
; 						; 

; 		align 4
; PwmIns_SPHEAVY1:
; 		dc.l PwmInsWav_SPHEAVY1
; 		dc.l PwmInsWav_SPHEAVY1_e
; 		dc.l -1
; 		dc.l 0
; PwmIns_MCLSTRNG:
; 		dc.l PwmInsWav_MCLSTRNG
; 		dc.l PwmInsWav_MCLSTRNG_e
; 		dc.l -1
; 		dc.l 0
; PwmIns_WHODSNARE:
; 		dc.l PwmInsWav_WHODSNARE
; 		dc.l PwmInsWav_WHODSNARE_e
; 		dc.l -1
; 		dc.l 0
; PwmIns_TECHNOBASSD:
; 		dc.l PwmInsWav_TECHNOBASSD
; 		dc.l PwmInsWav_TECHNOBASSD_e
; 		dc.l -1
; 		dc.l 0
; PwmIns_String:
; 		dc.l PwmInsWav_String
; 		dc.l PwmInsWav_String_e
; 		dc.l 0
; 		dc.l 0
; PwmIns_Piano:
; 		dc.l PwmInsWav_Piano
; 		dc.l PwmInsWav_Piano_e
; 		dc.l -1
; 		dc.l 0
