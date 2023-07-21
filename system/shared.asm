; ====================================================================
; ----------------------------------------------------------------
; MD/32X shared structs and values
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
; MAIN DREQ-RAM control
;
; To read these labels:
;
; On the Genesis Side:
; 	lea	(RAM_MdDreq+DREQ_LABEL),a0
; On the 32X Side:
; 	mov	#RAM_Mars_DreqRead+DREQ_LABEL,r1
;
; Call System_MarsUpdate DURING DISPLAY to transfer your
; changes.
; ----------------------------------------------------------------

; *** List MUST be aligned in 8bytes, end with 0 or 8 ***

; 	if MARS|MARSCD
		struct 0
Dreq_Palette	ds.w 256				; 256-color palette
; Dreq_BgExBuff	ds.b $80				; Buffer for current screen mode (NOTE: manual size)
; Dreq_ObjCam	ds.b sizeof_camera
; Dreq_Objects	ds.b sizeof_mdlobj*MAX_MODELS		; 3D Objects
; Dreq_SuperSpr	ds.b sizeof_marsspr*MAX_SUPERSPR	; Super sprites
sizeof_dreq	ds.l 0
		endstruct

	if MOMPASS=5
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif

; 	endif
