; ====================================================================
; ----------------------------------------------------------------
; DREQ RAM control
;
; To read these labels...
;
; On the Genesis Side:
; 	lea	(RAM_MdDreq+DREQ_LABEL),a0
;
; On the 32X Side:
; 	mov	#RAM_Mars_DreqRead+DREQ_LABEL,r1
; ----------------------------------------------------------------

		struct 0
Dreq_Objects	ds.b sizeof_mdlobj*MAX_MODELS	; <-- labels from SH2 side
Dreq_Palette	ds.w 256
Dreq_BgXpos	ds.l 1
Dreq_BgYpos	ds.l 1
sizeof_dreq	ds.l 0
		finish

; MAX_DREQ		equ sizeof_dreq

	if MOMPASS=7
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif
