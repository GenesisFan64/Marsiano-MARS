; ====================================================================
; ----------------------------------------------------------------
; Global RAM variables on the Genesis side
; (Score, Level, etc.)
; ----------------------------------------------------------------

		struct RAM_MdGlobal
RAM_Glbl_Scrn	ds.w 1				; Current screen number
sizeof_mdglbl	ds.l 0
		endstruct
		report "68K GLOBALS",sizeof_mdglbl-RAM_MdGlobal,MAX_MdGlobal

