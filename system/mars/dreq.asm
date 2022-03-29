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
				; Screen Mode 02:
Dreq_BgEx_X	ds.l 1		; X pos 0000.0000
Dreq_BgEx_Y	ds.l 1		; Y pos 0000.0000
Dreq_BgEx_Data	ds.l 1		; Source data (ON SH2's MAP)
Dreq_BgEx_W	ds.l 1		; Width
Dreq_BgEx_H	ds.l 1		; Height

				; Screen mode 03:
Dreq_SclData	ds.l 1		; Source data (ON SH2's MAP)
Dreq_SclX	ds.l 1		; X pos 0000.0000
Dreq_SclY	ds.l 1		; Y pos 0000.0000
Dreq_SclDX	ds.l 1		; DX 0000.0000
Dreq_SclDY	ds.l 1		; DY 0000.0000
Dreq_SclWidth	ds.l 1		; Width
Dreq_SclHeight	ds.l 1		; Height

Dreq_Palette	ds.w 256
Dreq_Objects	ds.b sizeof_mdlobj*MAX_MODELS	; <-- labels from SH2 side

sizeof_dreq	ds.l 0
		finish

; MAX_DREQ		equ sizeof_dreq

	if MOMPASS=7
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif
