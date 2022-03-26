; ====================================================================
; ----------------------------------------------------------------
; SH2 SDRAM data
; 
; This data is always available to use on the 32X
; side and can be rewritible too.
;
; If you need data that must be available even after
; the RV bit put it here, Watch out for the size of this section
; as it will get lower if you use a lot of RAM on the SH2 side.
; ----------------------------------------------------------------

	align 4		; align first.

; --------------------------------------------------------
; Models
; --------------------------------------------------------

	include "data/mars/objects/mdl/test/head.asm"
