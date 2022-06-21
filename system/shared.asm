; ====================================================================
; ----------------------------------------------------------------
; MD/MARS shared constants
; ----------------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_MODELS	equ 12		; MAX 3D Models
MAX_SUPERSPR	equ 32		; Number of Super Sprites

; --------------------------------------------------------
; Structs
;
; NOTE: SIZES MUST BE ALIGNED BY 4-bytes
; --------------------------------------------------------

		struct 0
mdl_data	ds.l 1		; Model data pointer, if zero: no model
mdl_option	ds.l 1		; Model options: pixelvalue add
mdl_x_pos	ds.l 1		; X position $000000.00
mdl_y_pos	ds.l 1		; Y position $000000.00
mdl_z_pos	ds.l 1		; Z position $000000.00
mdl_x_rot	ds.l 1		; X rotation $000000.00
mdl_y_rot	ds.l 1		; Y rotation $000000.00
mdl_z_rot	ds.l 1		; Z rotation $000000.00
sizeof_mdlobj	ds.l 0
		finish

; "Super" sprite
; RAM_MdDreq+Dreq_SuperSpr
		struct 0
marsspr_data	ds.l 1	; Spritesheet DATA location in SH2 area (MANUALLY ADD |TH IF NEEDED), 0 == end-of-spritelist
marsspr_dwidth	ds.w 1	; Spritesheet WIDTH
marsspr_indx	ds.w 1	; Palette index base
marsspr_flags	ds.w 1	; Sprite flags: %VH
marsspr_x	ds.w 1	; Screen X position
marsspr_y	ds.w 1	; Screen Y position
marsspr_xs	ds.b 1	; Sprite X size
marsspr_ys	ds.b 1	; Sprite Y size
marsspr_xt	ds.b 1	; Texture X size
marsspr_yt	ds.b 1	; Texture Y size
marsspr_xfrm	ds.b 1	; Animation X frame pos
marsspr_yfrm	ds.b 1	; Animation Y frame pos
sizeof_marsspr	ds.l 0
		finish

; ------------------------------------------------
; Structs for each pseudo-Screen, max $20 bytes
;
; Read these as:
; RAM_MdDreq+Dreq_ScrnBuff

			struct 0
Dreq_Scrn1_Data		ds.l 1		; Screen mode 1: Source image (SH2's area)
Dreq_Scrn1_Type		ds.l 1		; Source format: 0-NULL 1-Indexed 2-Direct 3-RLE
			finish

			struct 0
Dreq_ScrlBg_Data	ds.l 1		; Screen mode 2: Source image (SH2's area)
Dreq_ScrlBg_X		ds.l 1		; X pos 0000.0000
Dreq_ScrlBg_Y		ds.l 1		; Y pos 0000.0000
Dreq_ScrlBg_W		ds.l 1		; Width
Dreq_ScrlBg_H		ds.l 1		; Height
			finish

			struct 0
Dreq_SclData		ds.l 1		; Screen mode 3: Source data (SH2's area)
Dreq_SclX		ds.l 1		; X pos 0000.0000
Dreq_SclY		ds.l 1		; Y pos 0000.0000
Dreq_SclWidth		ds.l 1		; Width
Dreq_SclHeight		ds.l 1		; Height
Dreq_SclDX		ds.l 1		; DX 0000.0000
Dreq_SclDY		ds.l 1		; DY 0000.0000
Dreq_SclMode		ds.l 1
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
Dreq_Palette	ds.w 256				; 256-color palette
Dreq_ScrnBuff	ds.b $20				; Buffer for the current screen mode
Dreq_Objects	ds.b sizeof_mdlobj*MAX_MODELS		; 3D Objects
Dreq_SuperSpr	ds.b sizeof_marsspr*MAX_SUPERSPR	; SuperVDP sprites
sizeof_dreq	ds.l 0
		finish

	if MOMPASS=7
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif
