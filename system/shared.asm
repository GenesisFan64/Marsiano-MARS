; ====================================================================
; ----------------------------------------------------------------
; MD/MARS shared constants
; ----------------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_MODELS	equ 14		; MAX 3D Models
MAX_SUPERSPR	equ 64		; Number of Super Sprites

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

; "Super" sprite
		struct 0
marsspr_x	ds.l 1		; 0000.0000
marsspr_y	ds.l 1		; 0000.0000
marsspr_xs	ds.l 1		; 0000.0000
marsspr_ys	ds.l 1		; 0000.0000
marsspr_data	ds.l 1		; Pixel data
marsspr_anim	ds.l 1		; Animation data
marsspr_anitmr	ds.l 1		; Animation timer
marsspr_animspd	ds.l 1		; Animation speed
marsspr_frame	ds.l 1
sizeof_marsspr	ds.l 0
		finish

; ------------------------------------------------
; Variables for each pseudo-Screen
;
; Read these as:
; RAM_MdDreq+Dreq_ScrnBuff

		struct 0
Dreq_Scrn1_Data	ds.l 1		; Screen mode 1: Source image (SH2's area)
Dreq_Scrn1_Type	ds.l 1		; Source format: 0-NULL 1-Indexed 2-Direct 3-RLE
DREQ_FILLER	ds.l 1
		finish

		struct 0
Dreq_Scrn2_Data	ds.l 1		; Screen mode 2: Source image (SH2's area)
Dreq_Scrn2_X	ds.l 1		; X pos 0000.0000
Dreq_Scrn2_Y	ds.l 1		; Y pos 0000.0000
Dreq_Scrn2_W	ds.l 1		; Width
Dreq_Scrn2_H	ds.l 1		; Height
		finish

		struct 0
Dreq_SclData	ds.l 1		; Screen mode 3: Source data (SH2's area)
Dreq_SclX	ds.l 1		; X pos 0000.0000
Dreq_SclY	ds.l 1		; Y pos 0000.0000
Dreq_SclWidth	ds.l 1		; Width
Dreq_SclHeight	ds.l 1		; Height
Dreq_SclDX	ds.l 1		; DX 0000.0000
Dreq_SclDY	ds.l 1		; DY 0000.0000
Dreq_SclMode	ds.l 1
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
Dreq_Palette	ds.w 256			; 256-color palette
Dreq_ScrnBuff	ds.b $20			; <-- only one buffer per screen
Dreq_Objects	ds.b sizeof_mdlobj*MAX_MODELS		; <-- labels from SH2 side
Dreq_SuperSpr	ds.b sizeof_marsspr*MAX_SUPERSPR
sizeof_dreq	ds.l 0
		finish

; MAX_DREQ		equ sizeof_dreq

	if MOMPASS=7
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif
