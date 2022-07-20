; ====================================================================
; ----------------------------------------------------------------
; 32X Video
;
; Some routines are located on the cache.asm for
; speedup reasons.
; ----------------------------------------------------------------

; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_SCRNBUFF	equ $20000	; MAX SDRAM for each fake-screen mode
FBVRAM_LAST	equ $1F800	; BLANK line (the very last one)
FBVRAM_PATCH	equ $1E000	; Framebuffer location for the affected XShift lines
MAX_FACES	equ 640		; MAX polygon faces for models
MAX_SVDP_PZ	equ 640+32	; MAX polygon pieces to draw (MAX_FACES+few_pieces)
MAX_ZDIST	equ -$1000	; Maximum 3D field distance (-Z)

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; Screen mode 04
SCREEN_WIDTH	equ 320		; Screen width and height positions used
SCREEN_HEIGHT	equ 224		; by 3D object rendering
PLGN_TEXURE	equ %10000000	; plypz_type (MSB byte)
PLGN_TRI	equ %01000000

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

; Note: some structs are located on shared.asm
; Be careful modifing these...

		struct 0
mbg_flags	ds.b 1		; Current type of pixel-data: Indexed or Direct
mbg_mapblk	ds.b 1		; Map block size: 8, 16, 32...
mbg_xset	ds.b 1		; X-counter
mbg_yset	ds.b 1		; Y-counter
mbg_xdrw_l	ds.b 1		; Off-screen draw requests,
mbg_xdrw_r	ds.b 1		; write $02 to them.
mbg_ydrw_u	ds.b 1		;
mbg_ydrw_d	ds.b 1		; ***
mbg_xpos_old	ds.w 1		; OLD Xpos/Ypos positions
mbg_ypos_old	ds.w 1		;
mbg_xinc_l	ds.w 1		; Source data increment-beams
mbg_xinc_r	ds.w 1
mbg_yinc_u	ds.w 1		; <-- Y are direct, requires external mulitply
mbg_yinc_d	ds.w 1
mbg_fbpos_y	ds.w 1		; Map's Y position, multiply by WIDTH externally
mbg_intrl_blk	ds.w 1		; Scrolling block size
mbg_intrl_w	ds.w 1		; Internal scrolling Width (MUST be larger than 320)
mbg_intrl_h	ds.w 1		; Internal scrolling Height
mbg_width	ds.w 1		; Source image's Width
mbg_height	ds.w 1		; Source image's Height
mbg_indxinc	ds.l 1		; Index increment (full 4 bytes)
mbg_intrl_size	ds.l 1		;
mbg_data	ds.l 1		; Bitmap data or tiles
mbg_map		ds.l 1
mbg_fbpos	ds.l 1		; Map's currrent TopLeft position
mbg_fbdata	ds.l 1		; Framebuffer location of the playfield
mbg_xpos	ds.l 1		; 0000.0000
mbg_ypos	ds.l 1		; 0000.0000
sizeof_marsbg	ds.l 0
		finish

; Current camera view values
		struct 0
cam_x_pos	ds.l 1		; X position $000000.00
cam_y_pos	ds.l 1		; Y position $000000.00
cam_z_pos	ds.l 1		; Z position $000000.00
cam_x_rot	ds.l 1		; X rotation $000000.00
cam_y_rot	ds.l 1		; Y rotation $000000.00
cam_z_rot	ds.l 1		; Z rotation $000000.00
sizeof_camera	ds.l 0
		finish

		struct 0
plypz_type	ds.l 1		; Type + Material settings (width + index add)
plypz_mtrl	ds.l 1		; Material data (ROM or SDRAM)
plypz_ytb	ds.l 1		; Ytop | Ybottom
plypz_xl	ds.l 1		;  Screen X-Left | X-Right  16-bit
plypz_src_xl	ds.l 1		; Texture X-Left | X-Right  16-bit
plypz_src_yl	ds.l 1		; Texture Y-Top  | Y-Bottom 16-bit
plypz_xl_dx	ds.l 1		; 0000.0000
plypz_xr_dx	ds.l 1		; 0000.0000
plypz_src_xl_dx	ds.l 1
plypz_src_xr_dx	ds.l 1
plypz_src_yl_dx	ds.l 1
plypz_src_yr_dx	ds.l 1
sizeof_plypz	ds.l 0
		finish

; Polygon data, Size: $38
		struct 0
polygn_type	ds.l 1		; %MSww wwww 0000 aaaa | %MS w-Texture width, a-Pixel increment
polygn_mtrl	ds.l 1		; Material Type: Color (0-255) or Texture data address
polygn_points	ds.l 4*2	; X/Y positions
polygn_srcpnts	ds.w 4*2	; X/Y texture points (WORDS), ignored on solid colors
sizeof_polygn	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Init MARS Video
; ----------------------------------------------------------------

		align 4
MarsVideo_Init:
		sts	pr,@-r15
		mov	#_sysreg,r1
		mov 	#FM,r0			; Set SVDP permission to SH2.
  		mov.b	r0,@(adapter,r1)	; * The Genesis side will still control the
		mov 	#_vdpreg,r1		; 256-color palette using DREQ *
		mov	#0,r0			; Start at BLANK
		mov.b	r0,@(bitmapmd,r1)
		mov	#_framebuffer,r2	; Make default nametables
		bsr	.def_fb
		nop
		bsr	.def_fb
		nop
		lds	@r15+,pr
		rts
		nop
		align 4
.def_fb:
		mov	r2,r3
		mov	#FBVRAM_LAST/2,r0	; The very last usable (blank) line.
		mov	#240,r4
.nxt_lne:
		mov.w	r0,@r3
		dt	r4
		bf/s	.nxt_lne
		add	#2,r3
		mov.b	@(framectl,r1),r0	; Frameswap request
		xor	#1,r0
		mov	r0,r3
		mov.b	r0,@(framectl,r1)
.wait_frm:	mov.b	@(framectl,r1),r0	; And wait until it flips
		cmp/eq	r0,r3
		bf	.wait_frm
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; VideoMars_ClearScreen
;
; Clears screen using VDPFILL
;
; Input:
; r1 | Framebuffer VRAM location
; r2 | Width / 2
; r3 | Height
; r4 | Pixel(s) to write
;
; Uses:
; r5-r6
;
; *** 512-pixel lines ONLY ***
; --------------------------------------------------------

		align 4
MarsVideo_ClearScreen:
		shlr	r1
		mov	r1,r5
		mov	#_vdpreg,r6
.fb_loop:
		mov	r2,r0
		mov.w	r0,@(filllength,r6)
		mov	r1,r0
		mov.w	r0,@(fillstart,r6)
		mov	r4,r0
		mov.w	r0,@(filldata,r6)
.wait_fb2:	mov.w	@(vdpsts,r6),r0
		tst	#%10,r0
		bf	.wait_fb2
		dt	r3
		bf/s	.fb_loop
		add	r5,r1
.no_redraw_2:
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsVideo_ResetNameTbl
;
; Reset the nametable, all lines point to a BLANK line
; --------------------------------------------------------

MarsVideo_ResetNameTbl:
		mov	#_framebuffer,r1
		mov	#FBVRAM_LAST,r0
		mov	#240,r2
.nxt_lne2:
		mov.w	r0,@r1
		dt	r2
		bf/s	.nxt_lne2
		add	#2,r1
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsVideo_MakeNametbl
;
; Builds the nametable for a normal screen, if
; marsGbl_WaveEnable is set, it will add a
; wave effect to the linetable (in WORDS)
;
; Input:
; r1 | Framebuffer position
; r2 | Width (Width*2 for Direct color)
; r3 | Height
; r4 | Y line position
;
; Uses:
; r5-r11
; --------------------------------------------------------

MarsVideo_MakeNameTbl:
		mov	#_framebuffer,r10
		shll	r4
		add	r4,r10
		mov 	#_vdpreg,r5
		mov.b	@(bitmapmd,r5),r0	; Cannot mess with the RLE lines.
		and	#%11,r0
		cmp/eq	#3,r0
		bt	.cant_use
		mov.w	@(marsGbl_WaveEnable,gbr),r0
		tst	r0,r0
		bt	.linetbl_normal

	; Special linetable with
	; wave deformation.
		mov.w	@(marsGbl_WaveSpd,gbr),r0
		mov	r0,r4
		mov.w	@(marsGbl_WaveTan,gbr),r0
		mov	#$7FF,r5
		add	r4,r0			; wave speed
		and	r5,r0
		mov.w	r0,@(marsGbl_WaveTan,gbr)
		mov	r0,r7
		mov.w	@(marsGbl_WaveMax,gbr),r0
		mov	r0,r5
		mov.w	@(marsGbl_WaveDeform,gbr),r0
		mov	r0,r4
		mov	#0,r6
		mov	#$7FF,r11
		mov	#sin_table,r12
.nxt_lne:
		mov	r7,r0
		add	r4,r7			; wave distord
		and	r11,r7
		shll2	r0
		mov	@(r0,r12),r9
		dmuls	r5,r9
		sts	macl,r9
		shlr16	r9
		exts.w	r9,r9
		mov	r1,r0
		add	r6,r0
		add	r9,r0
		shlr	r0
		mov.w	r0,@r10
		add	r2,r6
		dt	r3
		bf/s	.nxt_lne
		add	#2,r10
		rts
		nop
		align 4

.linetbl_normal:
		shlr	r1
		shlr	r2
.nxt_lne2:
		mov.w	r1,@r10
		add	r2,r1
		dt	r3
		bf/s	.nxt_lne2
		add	#2,r10
.cant_use:
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsVideo_FixTblShift
;
; If your current screen mode manipulates the linetable
; for scrolling, call this BEFORE swaping the framebuffer
; to solve a HARDWARE BUG that causes
; Xshift not to work with lines that end with $xxFF
;
; Emulators ignore this.
; --------------------------------------------------------

MarsVideo_FixTblShift:
		mov	#_vdpreg,r14
		mov.b	@(bitmapmd,r14),r0		; Check if we are on indexed mode
		and	#%11,r0
		cmp/eq	#1,r0
		bf	.ptchset
		mov.w	@(marsGbl_XShift,gbr),r0	; XShift is set?
		and	#1,r0
		tst	r0,r0
		bt	.ptchset
		mov	#_framebuffer,r14		; r14 - Framebuffer BASE
		mov	r14,r13				; r13 - Framebuffer lines to check
		mov	#_framebuffer+FBVRAM_PATCH,r12	; r12 - Framebuffer output for the patched pixel lines
		mov	#240,r11			; r11 - Lines to check
		mov	#-1,r0
		extu.b	r0,r10				; r10 - AND byte to check ($FF)
		extu.w	r0,r9				;  r9 - AND word limit ($FFFF)
.loop:
		mov.w	@r13,r0
		and	r9,r0
		mov	r0,r7
		and	r10,r0
		cmp/eq	r10,r0
		bf	.tblexit
		shll	r7
		add	r14,r7
		mov	r12,r0
		shlr	r0
		mov.w	r0,@r13
		mov	#(320+4)/2,r3
.copy:
		mov.w	@r7,r0
		mov.w	r0,@r12
		add	#2,r7
		dt	r3
		bf/s	.copy
		add	#2,r12
.tblexit:
		dt	r11
		bf/s	.loop
		add	#2,r13
.ptchset:
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 2D Section
;
; SOME routines are located on cache_m_scrlbg.asm
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_MkScrlField
;
; This makes a new internal scrolling background
;
; Call this first to setup the internal scrolling values,
; then after this call MarsVideo_SetBg to set your
; source image and it's size.
;
; Input:
; r1 | Background buffer to initialize
; r2 | Output framebuffer data
; r3 | Scroll block size (MINIMUM: 4 pixels)
; r4 | Scroll visible width
; r5 | Scroll visible height
; r6 | Flags: %000000dt
;      t - Full picture or Tile map
;      d - Indexed or Direct
;
; Breaks:
; r0,r4-r6,macl
; --------------------------------------------------------

; VALID BLOCK SIZES:
; 4,8,16,32(224 height max)
;
; BROKEN:
; 64
;
; MAX Scrolling speed: (size/2)

		align 4
MarsVideo_MkScrlField:
		mov	r6,r0
		and	#1,r0
		tst	r0,r0
		bt	.no_indx
		shll	r4
.no_indx:
		add	r3,r4		; add block to width/height
		add	r3,r5
		mov	r2,@(mbg_fbdata,r1)
		mov	r3,r0
		mov.w	r0,@(mbg_intrl_blk,r1)
		mov	r4,r0
		mov.w	r0,@(mbg_intrl_w,r1)
		mov	r5,r0
		mov.w	r0,@(mbg_intrl_h,r1)
		mulu	r4,r5
		sts	macl,r0
		mov	r0,@(mbg_intrl_size,r1)
		mov	r6,r0
		mov.b	r0,@(mbg_flags,r1)

		xor	r0,r0
		mov.b	r0,@(mbg_xset,r1)
		mov.b	r0,@(mbg_yset,r1)
		mov.w	r0,@(mbg_xpos_old,r1)
		mov.w	r0,@(mbg_ypos_old,r1)
		mov	r0,@(mbg_fbpos,r1)
		mov.w	r0,@(mbg_fbpos_y,r1)
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------
; MarsVideo_SetScrlBg
;
; Sets the source data for the background
;
; Input:
; r1 | Background buffer
; r2 | Source image location (ROM or SDRAM)
; r3 | Source image Width
; r4 | Source image Height
;
; Breaks:
; r0,r1
;
; NOTES:
; - Width and Height must be aligned by the current
; buffer's block size
; - ROM data is NOT protected
; --------------------------------------------------------

MarsVideo_SetScrlBg:
		mov	r2,@(mbg_data,r1)
		mov.b	@(mbg_flags,r1),r0
		and	#%10,r0
		tst	r0,r0
		bt	.indxmode
		shll	r3
.indxmode:
		mov	r3,r0
		mov.w	r0,@(mbg_width,r1)
		mov	r4,r0
		mov.w	r0,@(mbg_height,r1)
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------
; MarsVideo_ShowScrlBg
;
; Show the background on the screen.
;
; Input:
; r1 | Background buffer
; r2 | Top Y
; r3 | Bottom Y
;
; NOTE:
; After finishing all your screens call
; MarsVideo_FixTblShift before doing frameswap
; --------------------------------------------------------

MarsVideo_ShowScrlBg:
		mov	#_framebuffer,r14		; r14 - Framebuffer BASE
		mov	@(mbg_fbdata,r1),r13		; r13 - Framebuffer pixeldata position
		mov	@(mbg_intrl_size,r1),r12	; r12 - Full size of screen-scroll
		mov	#0,r11				; r11 - line counter
		mov.w	@(mbg_intrl_w,r1),r0
		mov	r0,r10				; r10 - Next line to add
		mov	r2,r6
		mov	r2,r0
		shll	r0
		add	r0,r14
		mov.w	@(mbg_fbpos_y,r1),r0
		mulu	r10,r0
		mov	@(mbg_fbpos,r1),r7
		sts	macl,r0
		add	r0,r7
		mov.w	@(marsGbl_WaveEnable,gbr),r0
		tst	r0,r0
		bf	.ln_wavy
.ln_loop:
		mov	r7,r8
		cmp/ge	r12,r8
		bf	.xl_r
		sub	r12,r8
.xl_r:
		cmp/pz	r8
		bt	.xl_l
		add	r12,r8
.xl_l:
		mov	r8,r7
		add	r10,r7		; Add Y
		add	r13,r8		; Add Framebuffer position
		shlr	r8		; divide by 2 (shift reg does the missing bit 0)
		mov.w	r8,@r14		; send to FB's table
		add	#2,r14
		add	#2,r11
		cmp/eq	r3,r6
		bf/s	.ln_loop
		add	#1,r6
		rts
		nop
		align 4
.ln_wavy:
		mov.w	@(marsGbl_WaveSpd,gbr),r0
		mov	r0,r4
		mov.w	@(marsGbl_WaveTan,gbr),r0
		mov	#$7FF,r5
		add	r4,r0			; wave speed
		and	r5,r0
		mov.w	r0,@(marsGbl_WaveTan,gbr)
		mov	r0,r9
		mov.w	@(marsGbl_WaveMax,gbr),r0
		mov	r0,r5
		mov.w	@(marsGbl_WaveDeform,gbr),r0
		mov	r0,r4
.ln_loop_w:
		mov	#$7FF,r8
		mov	r9,r0
		add	r4,r9		; wave distord
		and	r8,r9
		shll2	r0
		mov	#sin_table,r8
		mov	@(r0,r8),r0
		dmuls	r5,r0
		sts	macl,r0
		shlr16	r0
		exts.w	r0,r0
		mov	r7,r8
		cmp/ge	r12,r8
		bf	.wxl_r
		sub	r12,r8
.wxl_r:
		cmp/pz	r8
		bt	.wxl_l
		add	r12,r8
.wxl_l:
		mov	r8,r7
		add	r10,r7		; Add Y
		add	r13,r8		; Add Framebuffer position
		add	r0,r8
		shlr	r8		; divide by 2 (shift reg does the missing bit 0)
		mov.w	r8,@r14		; send to FB's table
		add	#2,r14
		add	#2,r11
		cmp/eq	r3,r6
		bf/s	.ln_loop_w
		add	#1,r6
		rts
		nop
		align 4
.no_lines:
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------
; MarsVideo_MoveBg
;
; This updates the background's X/Y position and
; all it's internal variables, this includes
; some shared variables
;
; Input:
; r14 | Background buffer
; --------------------------------------------------------

		align 4
MarsVideo_MoveBg:
		mov	@(mbg_data,r14),r0
		cmp/eq	#0,r0
		bf	.has_scrldata
		rts
		nop
.has_scrldata:
		mov	#0,r1
		mov	#0,r2
		mov	@(mbg_xpos,r14),r0	; 0000.0000
		shlr16	r0
		exts.w	r0,r0
		mov	r0,r3
		mov.w	@(mbg_xpos_old,r14),r0
		cmp/eq	r0,r3
		bt	.xequ
		mov	r3,r1
		sub	r0,r1
.xequ:
		mov	r3,r0
		mov.w	r0,@(mbg_xpos_old,r14)
		mov	@(mbg_ypos,r14),r0	; 0000.0000
		shlr16	r0
		exts.w	r0,r0
		mov	r0,r3
		mov.w	@(mbg_ypos_old,r14),r0
		cmp/eq	r0,r3
		bt	.yequ
		mov	r3,r2
		sub	r0,r2
.yequ:
		mov	r3,r0
		mov.w	r0,@(mbg_ypos_old,r14)
		exts.w	r1,r1
		exts.w	r2,r2
; 		cmp/pz	r1
; 		bt	.x_stend
; 		exts	r1,r1
; .x_stend:
; 		cmp/pz	r2
; 		bt	.y_stend
; 		exts	r2,r2
; .y_stend:

	; ---------------------------------------
	; Y Framebuffer position
	; ---------------------------------------

		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r3
		mov.w	@(mbg_fbpos_y,r14),r0
		mov	r0,r4
		add	r2,r4
		cmp/pl	r2
		bf	.ypu_negtv
		cmp/ge	r3,r4
		bf	.ypu_negtv
		sub	r3,r4
.ypu_negtv:
		cmp/pz	r2
		bt	.ypu_postv
		cmp/pz	r4
		bt	.ypu_postv
		add	r3,r4
.ypu_postv:
		mov	r4,r0
		mov.w	r0,@(mbg_fbpos_y,r14)

	; ---------------------------------------
	; Update Framebuffer TOP-LEFT position
	; ---------------------------------------

		mov	@(mbg_intrl_size,r14),r3
		mov	@(mbg_fbpos,r14),r0
		add	r1,r0
		cmp/pl	r1
		bf	.yx_negtv
		cmp/ge	r3,r0
		bf	.yx_negtv
		sub	r3,r0
.yx_negtv:
		cmp/pz	r1
		bt	.yx_postv
		cmp/pz	r0
		bt	.yx_postv
		add	r3,r0
.yx_postv:
		mov	r0,@(mbg_fbpos,r14)

	; ---------------------------------------
	; Update background draw-heads
	; r1 - X left/right
	; r2 - Y up/down
	; ---------------------------------------

		mov.w	@(mbg_width,r14),r0
		mov	r0,r3
		mov.w	@(mbg_height,r14),r0
		mov	r0,r4
		mov.w	@(mbg_xinc_r,r14),r0
		mov	r0,r5
		mov.w	@(mbg_xinc_l,r14),r0
		mov	r0,r6
		mov.w	@(mbg_yinc_u,r14),r0
		mov	r0,r7
		mov.w	@(mbg_yinc_d,r14),r0
		mov	r0,r8

		add	r1,r5
		cmp/pl	r1
		bf	.xnegtv
		cmp/ge	r3,r5
		bf	.xnegtv
		sub	r3,r5
.xnegtv:
		cmp/pz	r1
		bt	.xpostv
		cmp/pz	r5
		bt	.xpostv
		add	r3,r5
.xpostv:
		add	r1,r6
		cmp/pl	r1
		bf	.xnegtvl
		cmp/ge	r3,r6
		bf	.xnegtvl
		sub	r3,r6
.xnegtvl:
		cmp/pz	r1
		bt	.xpostvl
		cmp/pz	r6
		bt	.xpostvl
		add	r3,r6
.xpostvl:

		add	r2,r7
		cmp/pl	r2
		bf	.ynegtv
		cmp/ge	r4,r7
		bf	.ynegtv
		sub	r4,r7
.ynegtv:
		cmp/pz	r2
		bt	.ypostv
		cmp/pz	r7
		bt	.ypostv
		add	r4,r7
.ypostv:
		add	r2,r8
		cmp/pl	r2
		bf	.ynegtvl
		cmp/ge	r4,r8
		bf	.ynegtvl
		sub	r4,r8
.ynegtvl:
		cmp/pz	r2
		bt	.ypostvl
		cmp/pz	r8
		bt	.ypostvl
		add	r4,r8
.ypostvl:
		mov	r5,r0
		mov.w	r0,@(mbg_xinc_r,r14)
		mov	r6,r0
		mov.w	r0,@(mbg_xinc_l,r14)
		mov	r7,r0
		mov.w	r0,@(mbg_yinc_u,r14)
		mov	r8,r0
		mov.w	r0,@(mbg_yinc_d,r14)

	; ---------------------------------------

		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r3
		and	r0,r3			; r3 - block size to check
		mov	#0,r5
		mov.b	@(mbg_yset,r14),r0
		add	r2,r0
		mov	r0,r6
		tst	r3,r0
		bt	.ydr_busy
		cmp/pl	r2
		bf	.reqd_b
		mov	#2,r0
		mov.b	r0,@(mbg_ydrw_d,r14)
		add	#$01,r5
.reqd_b:
		cmp/pz	r2
		bt	.ydr_busy
		mov	#2,r0
		mov.b	r0,@(mbg_ydrw_u,r14)
		add	#$01,r5
.ydr_busy:
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r4
		mov	r6,r0
		dt	r4
		and	r4,r0
		mov.b	r0,@(mbg_yset,r14)
		mov.b	@(mbg_xset,r14),r0
		add	r1,r0
		mov	r0,r6
		tst	r3,r0
		bt	.ydl_busy
		cmp/pl	r1
		bf	.reqr_b
		mov	#2,r0
		mov.b	r0,@(mbg_xdrw_r,r14)
		add	#$02,r5
.reqr_b:
		cmp/pz	r1
		bt	.ydl_busy
		mov	#2,r0
		mov.b	r0,@(mbg_xdrw_l,r14)
		add	#$02,r5
.ydl_busy:
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r4
		mov	r6,r0
		dt	r4
		and	r4,r0
		mov.b	r0,@(mbg_xset,r14)
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Super sprites
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_SetSuperSpr
;
; Sets external screen variables for drawing the
; Super Sprites (Cache'd variables)
;
; Input:
; r1 - VRAM base
; r2 - X VRAM position
; r3 - Y position
; r4 - Scrolling area Width
; r5 - Scrolling area Height
; r6 - Scroll area size
; --------------------------------------------------------

		align 4
MarsVideo_SetSuperSpr:
		mov	#Cach_Intrl_Size+4,r7
		mov	r6,@-r7
		mov	r5,@-r7
		mov	r4,@-r7
		mov	r3,@-r7
		mov	r2,@-r7
		mov	r1,@-r7
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------
; MarsVideo_SetSprFill
;
; Makes the redraw-boxes for Screen Mode 2
; call this AFTER drawing the Super Sprites.
;
; Input:
; r14 - Background buffer to use
; r13 - Super sprites list
; r12 - Block refill list
; --------------------------------------------------------

; TODO: make a duplicate-block check.

		align 4
MarsVideo_SetSprFill:
		mov	#$80000000,r11
		mov	#$7FFFFFFF,r10
		mov	#MAX_SUPERSPR,r9
		mov	@(marsspr_data,r13),r0
		tst	r0,r0
		bt	.exit
.next_one:
		cmp/pl	r9
		bf	.exit
		mov.w	@(marsspr_x,r13),r0		; r1 - X pos (left)
		mov	r0,r1
		mov.w	@(marsspr_y,r13),r0		; r2 - Y pos (top)
		mov	r0,r2
		mov.b	@(marsspr_xs,r13),r0		; r3 - XS (right)
		extu.b	r0,r3
		mov.b	@(marsspr_ys,r13),r0		; r4 - YS (bottom)
		extu.b	r0,r4
		mov.w	@(mbg_intrl_blk,r14),r0		; r5 - block size
		mov	r0,r5
		mov	@(mbg_xpos,r14),r6
		shlr16	r6
		mov	@(mbg_ypos,r14),r7
		shlr16	r7
		add	r1,r3
		add	r2,r4

		mov	r5,r0		; Extra size add
		shlr	r0		; <-- TODO: lower = faster
		sub	r0,r2
		add	r0,r4
		sub	r0,r1
		add	r0,r3
		mov	r5,r0		; BG X/Y add
		dt	r0
		and	r0,r6
		and	r0,r7
		add	r6,r1
		add	r6,r3
		add	r7,r2
		add	r7,r4

	; TODO: X/Y REVERSE CHECK
		mov	#320,r6
		mov	#224,r7
		add	r5,r6
		add	r5,r7
		cmp/pl	r1
		bt	.xl_l
		xor	r1,r1
.xl_l:
		cmp/ge	r6,r1
		bf	.xl_r
		mov	r6,r1
.xl_r:
		cmp/pl	r3
		bt	.xr_l
		xor	r3,r3
.xr_l:
		cmp/ge	r6,r3
		bf	.xr_r
		mov	r6,r3
.xr_r:

		cmp/pl	r2
		bt	.yt_l
		xor	r2,r2
.yt_l:
		cmp/ge	r7,r2
		bf	.yt_r
		mov	r7,r2
.yt_r:
		cmp/pl	r4
		bt	.yb_l
		xor	r4,r4
.yb_l:
		cmp/ge	r7,r4
		bf	.yb_r
		mov	r7,r4
.yb_r:
		shlr2	r1
		shlr2	r2
		shlr2	r3
		shlr2	r4
		cmp/eq	r1,r3
		bt	.bad_xy
		cmp/eq	r2,r4
		bt	.bad_xy

	; Set coords
		mov	r1,r0
		and	#$FF,r0
		mov	r2,r6
		shll8	r6
		or	r6,r0
		shll8	r4
		shll16	r0
		or	r4,r0
		or	r3,r0
		mov	@r12,r5
		and	r10,r5		; Filter draw bits
		cmp/eq	r5,r0
		bt	.same_en
		or	r11,r0		; Add draw bits
		mov	r0,@r12
.same_en:
		add	#4,r12
		dt	r9
.bad_xy:
		bra	.next_one
		add	#sizeof_marsspr,r13
.exit:
		rts
		nop
		align 4
		ltorg

; ******************************
; MarsVideo_DrawSuperSpr
; is located on cache_m_scrlbg.asm

; ====================================================================
; ----------------------------------------------------------------
; 3D Section
; ----------------------------------------------------------------

; Moved to cache_slv.asm

; ====================================================================
; ----------------------------------------------------------------
; Other
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_SetWatchdog
;
; Prepares watchdog interrupt for Master
;
; Input:
; r1 - Watchdog CPU clock divider
; r2 - Watchdog Pre-timer
; --------------------------------------------------------

		align 4
MarsVideo_SetWatchdog:
; 		mov	#0,r0
		stc	sr,r4
		mov	#$F0,r0
		ldc 	r0,sr
		mov.l	#_CCR,r3				; Refresh Cache
		mov	#%00001000,r0				; Two-way mode
		mov.w	r0,@r3
		mov	#%00011001,r0				; Cache purge / Two-way mode / Cache ON
		mov.w	r0,@r3
		mov	#$FFFFFE80,r3
		mov.w	#$5A00,r0				; Watchdog pre-timer
		or	r2,r0
		mov.w	r0,@r3
		mov.w	#$A538,r0				; Enable Watchdog
		or	r1,r0
		mov.w	r0,@r3
		ldc	r4,sr
		rts
		nop
		align 4
		ltorg
		align 4
