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
mdl_x_pos	ds.w 1		; X position $0800
mdl_y_pos	ds.w 1		; Y position $0800
mdl_z_pos	ds.w 1		; Z position $0800
mdl_x_rot	ds.w 1		; X rotation $0800
mdl_y_rot	ds.w 1		; Y rotation $0800
mdl_z_rot	ds.w 1		; Z rotation $0800
mdl_frame	ds.w 1
mdl_flags	ds.w 1
sizeof_mdlobj	ds.l 0
		finish

; "Super" sprite
; RAM_MdDreq+Dreq_SuperSpr
		struct 0
marsspr_xs	ds.b 1		; Sprite X size
marsspr_ys	ds.b 1		; Sprite Y size
marsspr_xfrm	ds.b 1		; Animation X frame pos
marsspr_yfrm	ds.b 1		; Animation Y frame pos
marsspr_dwidth	ds.w 1		; Spritesheet WIDTH
marsspr_indx	ds.w 1		; Palette index base
marsspr_flags	ds.w 1		; Sprite flags: %VH
marsspr_x	ds.w 1		; Screen X position
marsspr_y	ds.w 1		; Screen Y position
marsspr_fill	ds.w 1		; <-- 2 filler bytes
marsspr_data	ds.l 1		; Spritesheet DATA location in SH2 area (0 == end-of-spritelist)
marsspr_map	ds.l 1		; MAP data
sizeof_marsspr	ds.l 0
		finish

; ------------------------------------------------
; Structs for each pseudo-Screen, max $20 bytes
;
; Read these as: RAM_MdDreq+Dreq_ScrnBuff
; then read these as indirect(aX)

		struct 0
scrlbg_flags	ds.w 1		; Flags
scrlbg_fill	ds.w 1
scrlbg_data	ds.l 1		; Screen mode 2: Source image (SH2's area)
scrlbg_x	ds.l 1		; X pos 0000.0000
scrlbg_y	ds.l 1		; Y pos 0000.0000
scrlbg_w	ds.l 1		; Width
scrlbg_h	ds.l 1		; Height
sizeof_scrlbg	ds.l 0
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

; *** List MUST be aligned in 8bytes (end with 0 or 8) ***

		struct 0
Dreq_Palette	ds.w 256				; 256-color palette
Dreq_ScrnBuff	ds.b $40				; Buffer for the current screen mode
Dreq_Objects	ds.b sizeof_mdlobj*MAX_MODELS		; 3D Objects
Dreq_SuperSpr	ds.b sizeof_marsspr*MAX_SUPERSPR	; Super sprites
sizeof_dreq	ds.l 0
		finish

	if MOMPASS=7
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif
