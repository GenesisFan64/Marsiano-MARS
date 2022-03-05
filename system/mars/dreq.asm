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
;	mov	#DREQ_LABEL,r1
; 	mov	@(marsGbl_DreqRead,gbr),r0
; 	add	r0,r1
; ----------------------------------------------------------------

			struct 0
Dreq_Palette		ds.w 256
Dreq_Models		ds.b sizeof_mdlobj*MAX_MODELS
Dreq_BgXpos		ds.l 1
Dreq_BgYpos		ds.l 1
sizeof_dreq		ds.l 0
			finish

MAX_DREQ		equ sizeof_dreq

	if MOMPASS=7
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif
