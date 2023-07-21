; ====================================================================
; ----------------------------------------------------------------
; Shared internal structs
; ----------------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; 32X MAIN DREQ-RAM control
;
; To read these labels:
;
; On the Genesis Side:
; 	lea	(RAM_MdDreq+DREQ_LABEL),a0
; On the 32X Side:
; 	mov	#RAM_Mars_DreqRead+DREQ_LABEL,r1
;
; Call System_MarsUpdate DURING DISPLAY to
; transfer the changes.
; ----------------------------------------------------------------

; *** List MUST be aligned in 8bytes, end with 0 or 8 ***

	if MARS|MARSCD
		struct 0
Dreq_Palette	ds.w 256				; 256-color palette
sizeof_dreq	ds.l 0
		endstruct

	if MOMPASS=5
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif

	endif
