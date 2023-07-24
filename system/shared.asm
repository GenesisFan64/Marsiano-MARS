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
; 	mov	@(marsGbl_DmaRead,gbr),r0
; 	add	#DREQ_LABEL,r0			; MAX $7F with add
; 	;Then r0 to any other rX
;
; Call System_MarsUpdate DURING DISPLAY to
; transfer the changes.
; ----------------------------------------------------------------

; *** List MUST be aligned in 8bytes, end with 0 or 8 ***

	if MARS|MARSCD
		struct 0
Dreq_Palette	ds.w 256		; 256-color palette (DON'T MOVE THIS)
; Dreq_DontUse	ds.w 8			; Last WORD gets corrupted, fill last writes with 0
sizeof_dreq	ds.l 0
		endstruct

	if MOMPASS=5
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif

	endif
