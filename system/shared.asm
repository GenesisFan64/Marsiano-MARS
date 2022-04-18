; ====================================================================
; ----------------------------------------------------------------
; MD/MARS shared constants
; ----------------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_MODELS	equ 16		; MAX 3D Models

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

; model objects
;
		struct 0
mdl_data	ds.l 1			; Model data pointer, if zero: no model
mdl_option	ds.l 1			; Model options: pixelvalue add
mdl_x_pos	ds.l 1			; X position $000000.00
mdl_y_pos	ds.l 1			; Y position $000000.00
mdl_z_pos	ds.l 1			; Z position $000000.00
mdl_x_rot	ds.l 1			; X rotation $000000.00
mdl_y_rot	ds.l 1			; Y rotation $000000.00
mdl_z_rot	ds.l 1			; Z rotation $000000.00
; mdl_animdata	ds.l 1			; Model animation data pointer, zero: no animation
; mdl_animframe	ds.l 1			; Current frame in animation
; mdl_animtimer	ds.l 1			; Animation timer
; mdl_animspd	ds.l 1			; Animation USER speed setting
sizeof_mdlobj	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; DREQ RAM control, shared for both sides.
;
; To read these labels...
;
; On the Genesis Side:
; 	lea	(RAM_MdDreq+DREQ_LABEL),a0
;
; On the 32X Side:
; 	mov	#RAM_Mars_DreqRead+DREQ_LABEL,r1
; ----------------------------------------------------------------

; *** List MUST be aligned by 8bytes (end with 0 or 8) ***

		struct 0
Dreq_Scrn1_Data	ds.l 1		; Screen mode 1: Source image (SH2's area)
Dreq_Scrn1_Type	ds.l 1
Dreq_Scrn1_Flag	ds.l 1
Dreq_Scrn1_Free ds.l 1

Dreq_Scrn2_Data	ds.l 1		; Screen mode 2: Source image (SH2's area)
Dreq_Scrn2_X	ds.l 1		; X pos 0000.0000
Dreq_Scrn2_Y	ds.l 1		; Y pos 0000.0000
Dreq_Scrn2_W	ds.l 1		; Width
Dreq_Scrn2_H	ds.l 1		; Height
Dreq_SclData	ds.l 1		; Screen mode 3: Source data (SH2's area)
Dreq_SclX	ds.l 1		; X pos 0000.0000
Dreq_SclY	ds.l 1		; Y pos 0000.0000
Dreq_SclDX	ds.l 1		; DX 0000.0000
Dreq_SclDY	ds.l 1		; DY 0000.0000
Dreq_SclWidth	ds.l 1		; Width
Dreq_SclHeight	ds.l 1		; Height
Dreq_SclMode	ds.l 1

DREQ_FILLER	ds.l 1

Dreq_Palette	ds.w 256	; 256-color palette
Dreq_Objects	ds.b sizeof_mdlobj*MAX_MODELS	; <-- labels from SH2 side
sizeof_dreq	ds.l 0
		finish

; MAX_DREQ		equ sizeof_dreq

	if MOMPASS=7
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif
