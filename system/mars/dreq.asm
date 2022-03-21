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

; MUST be aligned by 8bytes (Size must end with 0 or 8)

		struct 0
Dreq_Objects	ds.b sizeof_mdlobj*MAX_MODELS	; <-- labels from SH2 side
Dreq_Palette	ds.w 256
Dreq_SclX	ds.l 1
Dreq_SclY	ds.l 1
Dreq_SclDX	ds.l 1
Dreq_SclDY	ds.l 1
Dreq_SclWidth	ds.w 1		; WORDs
Dreq_SclHeight	ds.w 1
Dreq_SclData	ds.l 1

Dreq_BgXpos	ds.l 1
Dreq_BgYpos	ds.l 1
Dreq_TEST2	ds.l 1
Dreq_TEST	ds.l 1
sizeof_dreq	ds.l 0
		finish

; MAX_DREQ		equ sizeof_dreq

	if MOMPASS=7
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif
