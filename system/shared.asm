; ====================================================================
; ----------------------------------------------------------------
; MD/32X shared constants
; ----------------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_MODELS	equ 12		; MAX 3D Models
MAX_SUPERSPR	equ 32		; MAX Number of Super Sprites

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

; 3D Models
; RAM_MdDreq+Dreq_Objects
		struct 0
mdl_data	ds.l 1		; Model data pointer, if zero: no model
mdl_option	ds.l 1		; Model options: pixelvalue increment
mdl_x_pos	ds.w 1		; X position $08.00
mdl_y_pos	ds.w 1		; Y position $08.00
mdl_z_pos	ds.w 1		; Z position $08.00
mdl_x_rot	ds.w 1		; X rotation $08.00
mdl_y_rot	ds.w 1		; Y rotation $08.00
mdl_z_rot	ds.w 1		; Z rotation $08.00
mdl_frame	ds.w 1
mdl_flags	ds.w 1
sizeof_mdlobj	ds.l 0
		finish

; "Super" sprites:
; RAM_MdDreq+Dreq_SuperSpr
;
; ** = keep the order
		struct 0
marsspr_xfrm	ds.b 1		; Animation X frame pos **
marsspr_yfrm	ds.b 1		; Animation Y frame pos **
marsspr_xs	ds.b 1		; Sprite X size **
marsspr_ys	ds.b 1		; Sprite Y size **
marsspr_x	ds.w 1		; Screen X position **
marsspr_y	ds.w 1		; Screen Y position **
marsspr_dwidth	ds.w 1		; Spritesheet WIDTH
marsspr_indx	ds.w 1		; Palette index base
marsspr_flags	ds.w 1		; Sprite flags: %VH (flip)
marsspr_fill	ds.w 1		; <-- 2 filler bytes: free to use
marsspr_data	ds.l 1		; Spritesheet DATA location in SH2 area (0 == end-of-spritelist)
marsspr_map	ds.l 1		; MAP data
sizeof_marsspr	ds.l 0
		finish

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
; Call System_MarsUpdate DURING Display to transfer your
; changes, then the 32X recieves new data on the NEXT frame.
; ----------------------------------------------------------------

; *** List MUST be aligned in 8bytes (end with 0 or 8) ***

		struct 0
Dreq_Palette	ds.w 256				; 256-color palette
Dreq_BgExBuff	ds.b $80				; Buffer for current screen mode (NOTE: manual size)
Dreq_Objects	ds.b sizeof_mdlobj*MAX_MODELS		; 3D Objects
Dreq_SuperSpr	ds.b sizeof_marsspr*MAX_SUPERSPR	; Super sprites
sizeof_dreq	ds.l 0
		finish

	if MOMPASS=7
		message "DREQ RAM uses: \{sizeof_dreq}"
	endif
