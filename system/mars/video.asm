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

MAX_SCRNBUFF	equ $1A000	; MAX SDRAM for each fake-screen mode
FBVRAM_LAST	equ $1FD80	; BLANK line (the very last one usable)
FBVRAM_PATCH	equ $1E000	; Framebuffer location for the affected XShift lines (Screen mode 2)
MAX_FACES	equ 256		; Max polygon faces (Screen mode 4)
MAX_SVDP_PZ	equ 256+64	; Max polygon pieces to draw (Screen mode 4)
MAX_ZDIST	equ -$C00	; Max 3D drawing distance (-Z) (Screen mode 4)

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
mbg_xpos_old	ds.w 1
mbg_ypos_old	ds.w 1
mbg_xinc_l	ds.w 1
mbg_xinc_r	ds.w 1
mbg_yinc_u	ds.w 1
mbg_yinc_d	ds.w 1
mbg_width	ds.w 1
mbg_height	ds.w 1
mbg_fbpos_y	ds.w 1		; TOP Y position, multiply by WIDTH externally
mbg_intrl_blk	ds.w 1		; Scrolling Block size
mbg_intrl_w	ds.w 1		; Internal scrolling Width (MUST be larger than 320)
mbg_intrl_h	ds.w 1		; Internal scrolling Height
mbg_intrl_size	ds.l 1		;
mbg_data	ds.l 1		; Bitmap data or tiles
mbg_map		ds.l 1
mbg_fbpos	ds.l 1		; Framebuffer currrent TOPLEFT position
mbg_fbdata	ds.l 1		; Pixeldata located on Framebuffer
mbg_rfill	ds.l 1		; Refill buffer
mbg_indxinc	ds.l 1		; Index increment (NOTE: for all 4 pixels)
mbg_xpos	ds.l 1		; 0000.0000
mbg_ypos	ds.l 1		; 0000.0000
sizeof_marsbg	ds.l 0
		finish

; Current camera view values
		struct 0
cam_x_pos	ds.l 1			; X position $000000.00
cam_y_pos	ds.l 1			; Y position $000000.00
cam_z_pos	ds.l 1			; Z position $000000.00
cam_x_rot	ds.l 1			; X rotation $000000.00
cam_y_rot	ds.l 1			; Y rotation $000000.00
cam_z_rot	ds.l 1			; Z rotation $000000.00
; cam_animdata	ds.l 1			; Model animation data pointer, zero: no animation
; cam_animframe	ds.l 1			; Current frame in animation
; cam_animtimer	ds.l 1			; Animation timer
; cam_animspd	ds.l 1			; Animation speed
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
		mov	#$FF,r10			; r10 - AND byte to check ($FF)
		mov	#$FFFF,r9			;  r9 - AND word limit
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
		cmp/pz	r1
		bt	.x_stend
		exts	r1,r1
.x_stend:
		cmp/pz	r2
		bt	.y_stend
		exts	r2,r2
.y_stend:

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
		mov.w	r0,@(marsGbl_BgDrwD,gbr)
		add	#$01,r5
.reqd_b:
		cmp/pz	r2
		bt	.ydr_busy
		mov	#2,r0
		mov.w	r0,@(marsGbl_BgDrwU,gbr)
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
		mov.w	r0,@(marsGbl_BgDrwR,gbr)
		add	#$02,r5
.reqr_b:
		cmp/pz	r1
		bt	.ydl_busy
		mov	#2,r0
		mov.w	r0,@(marsGbl_BgDrwL,gbr)
		add	#$02,r5
.ydl_busy:
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r4
		mov	r6,r0
		dt	r4
		and	r4,r0
		mov.b	r0,@(mbg_xset,r14)

	; Make snapshot of scroll variables for drawing
		cmp/pl	r5
		bf	.dont_snap
		mov.w	@(mbg_intrl_blk,r14),r0
		neg	r0,r0
		mov	r0,r7
		mov	#Cach_XHead_L,r1
		mov	#Cach_XHead_R,r2
		mov	#Cach_YHead_U,r3
		mov	#Cach_YHead_D,r4
		mov	#Cach_BgFbPos_V,r5
		mov	#Cach_BgFbPos_H,r6
		mov.w	@(mbg_xinc_l,r14),r0
		and	r7,r0
		mov	r0,@r1
		mov.w	@(mbg_xinc_r,r14),r0
		and	r7,r0
		mov	r0,@r2
		mov.w	@(mbg_yinc_u,r14),r0
		and	r7,r0
		mov	r0,@r3
		mov.w	@(mbg_yinc_d,r14),r0
		and	r7,r0
		mov	r0,@r4
		mov.w	@(mbg_fbpos_y,r14),r0
		and	r7,r0
		mov	r0,@r5
		mov	@(mbg_fbpos,r14),r0
		and	r7,r0
		mov	r0,r7
		mov.b	@(mbg_flags,r14),r0
		and	#%10,r0
		tst	r0,r0
		bt	.indxmode
		shll	r7
.indxmode:
		mov	r7,@r6
.dont_snap:
		rts
		nop
		align 4
		ltorg
;
; --------------------------------------------------------
; MarsVideo_BldScrlUD
;
; Reads background data for Up/Down scrolling into a
; section of SDRAM, then call MarsVideo_DrwScrlUD
; after this.
;
; Input:
; r14 | Background buffer
; --------------------------------------------------------

; TODO: TEMPORAL

		align 4
MarsVideo_BldScrlUD:
		mov	@(mbg_data,r14),r0
		tst	r0,r0
		bt	.exit
		mov	r0,r13
		mov	#RAM_Mars_UD_Pixels,r12
		mov.w	@(mbg_width,r14),r0
		mov	r0,r11
		mov.w	@(mbg_height,r14),r0
		mov	r0,r10
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r9
		mov.w	@(mbg_intrl_w,r14),r0
		mov	r0,r8
		mov	#Cach_XHead_L,r7
		mov	@r7,r7
		mov	#Cach_YHead_D,r6
		mov.w	@(marsGbl_BgDrwD,gbr),r0
		tst	r0,r0
		bf	.cont
		mov	#Cach_YHead_U,r6
		mov.w	@(marsGbl_BgDrwU,gbr),r0
		tst	r0,r0
		bf	.cont
.exit:
		rts
		nop
		align 4
.cont:
		mov	@r6,r0
		mulu	r0,r11
		sts	macl,r0
		add	r0,r13

		mov	#4,r5
.nxt_blk:
		mov	r13,r6
		add	r7,r6
		mov	r9,r4
.y_line:
		mov	r6,r1
		mov	r12,r2
		mov	r9,r3
		shlr2	r3
.x_line:
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.x_line
		add	#4,r2
		add	#16,r12
		dt	r4
		bf/s	.y_line
		add 	r11,r6

		add	r9,r7
		cmp/ge	r11,r7
		bf	.x_wdth
		sub	r11,r7
.x_wdth:
		cmp/ge	r8,r5
		bf/s	.nxt_blk
		add	r9,r5

		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Super sprites
; ----------------------------------------------------------------

; NOTE: MarsVideo_DrawSuperSpr is located on cache_m_scrlspr.asm

; --------------------------------------------------------
; MarsVideo_SetSuperSpr
;
; Sets screen variables for drawing the Super Sprites
; (Cache'd variables)
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
; Call this AFTER drawing the Super Sprites.
;
; Input:
; r14 - Background buffer to use
; r13 - Super sprites list
; r12 - Block refill list
; --------------------------------------------------------

		align 4
MarsVideo_SetSprFill:
		mov	#$80000000,r11
		mov	#$7FFFFFFF,r10
.next_one:
		mov	@(marsspr_data,r13),r0
		tst	r0,r0
		bt	.exit
		mov.w	@(marsspr_x,r13),r0		; r1 - X pos (left)
		mov	r0,r1
		mov.w	@(marsspr_y,r13),r0		; r2 - Y pos (top)
		mov	r0,r2
		mov.w	@(marsspr_xs,r13),r0		; r3 - XS (right)
		mov	r0,r3
		mov.w	@(marsspr_ys,r13),r0		; r4 - YS (bottom)
		mov	r0,r4
		mov.w	@(mbg_intrl_blk,r14),r0		; r5 - block size
		mov	r0,r5
		mov	@(mbg_xpos,r14),r6
		shlr16	r6
		mov	@(mbg_ypos,r14),r7
		shlr16	r7
		add	r1,r3
		add	r2,r4

		mov	r5,r0	; Extra size add
		shlr	r0
		sub	r0,r1
		sub	r0,r2
		add	r0,r3
		add	r0,r4

		mov	r5,r0	; BG X/Y add
		dt	r0
		and	r0,r6
		and	r0,r7
		add	r6,r1
		add	r6,r3
		add	r7,r2
		add	r7,r4
; 		neg	r5,r0	; Fix into blocks
; 		and	r0,r1
; 		and	r0,r2
; 		and	r0,r3
; 		and	r0,r4

	; TODO: X/Y REVERSE CHECK
		mov	#320,r8
		mov	#224,r9
		add	r5,r8
		add	r5,r9
		cmp/pl	r1
		bt	.xl_l
		xor	r1,r1
.xl_l:
		cmp/ge	r8,r1
		bf	.xl_r
		mov	r8,r1
.xl_r:
		cmp/pl	r3
		bt	.xr_l
		xor	r3,r3
.xr_l:
		cmp/ge	r8,r3
		bf	.xr_r
		mov	r8,r3
.xr_r:

		cmp/pl	r2
		bt	.yt_l
		xor	r2,r2
.yt_l:
		cmp/ge	r9,r2
		bf	.yt_r
		mov	r9,r2
.yt_r:
		cmp/pl	r4
		bt	.yb_l
		xor	r4,r4
.yb_l:
		cmp/ge	r9,r4
		bf	.yb_r
		mov	r9,r4
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
		mov	@r12,r9
		and	r10,r9		; Filter draw bits
		cmp/eq	r9,r0
		bt	.same_en
		or	r11,r0		; Add draw bits
		mov	r0,@r12
.same_en:
		add	#4,r12

.bad_xy:
		bra	.next_one
		add	#sizeof_marsspr,r13
.exit:
		rts
		nop
		align 4
		ltorg


; ====================================================================
; ----------------------------------------------------------------
; 3D Section
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsMdl_MdlLoop
;
; Call this to start building the 3D objects
; --------------------------------------------------------

		align 4
MarsMdl_MdlLoop:
		sts	pr,@-r15

		mov	#RAM_Mars_Objects,r14
		mov	#MAX_MODELS,r13
.loop:
		mov	@(mdl_data,r14),r0		; Object model data == 0 or -1?
		cmp/pl	r0
		bf	.invlid
		mov	#MarsMdl_ReadModel,r0
		jsr	@r0
		mov	r13,@-r15
		mov	@r15+,r13
		mov.w	@(marsGbl_CurrNumFaces,gbr),r0	; Ran out of space to store faces?
		mov	#MAX_FACES,r1
		cmp/ge	r1,r0
		bt	.skip
.invlid:
		dt	r13
		bf/s	.loop
		add	#sizeof_mdlobj,r14
.skip:
		mov 	#RAM_Mars_PlgnNum_0,r1
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bf	.page_2
		mov 	#RAM_Mars_PlgnNum_1,r1
.page_2:
		mov.w	@(marsGbl_CurrNumFaces,gbr),r0
		mov	r0,@r1

		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Read model
; ------------------------------------------------

		align 4
MarsMdl_ReadModel:
		sts	pr,@-r15
; 		mov	@(mdl_animdata,r14),r13
; 		cmp/pl	r13
; 		bf	.no_anim
; 		mov	@(mdl_animtimer,r14),r0
; 		add	#-1,r0
; 		cmp/pl 	r0
; 		bt	.wait_camanim
; 		mov	@r13+,r2
; 		mov	@(mdl_animframe,r14),r0
; 		add	#1,r0
; 		cmp/eq	r2,r0
; 		bf	.on_frames
; 		xor	r0,r0
; .on_frames:
; 		mov	r0,r1
; 		mov	r0,@(mdl_animframe,r14)
; 		mov	#$18,r0
; 		mulu	r0,r1
; 		sts	macl,r0
; 		add	r0,r13
; 		mov	@r13+,r1
; 		mov	@r13+,r2
; 		mov	@r13+,r3
; 		mov	@r13+,r4
; 		mov	@r13+,r5
; 		mov	@r13+,r6
; ; 		neg	r4,r4
; 		mov	r1,@(mdl_x_pos,r14)
; 		mov	r2,@(mdl_y_pos,r14)
; 		mov	r3,@(mdl_z_pos,r14)
; 		mov	r4,@(mdl_x_rot,r14)
; 		mov	r5,@(mdl_y_rot,r14)
; 		mov	r6,@(mdl_z_rot,r14)
; 		mov	@(mdl_animspd,r14),r0		; TODO: make a timer setting
; .wait_camanim:
; 		mov	r0,@(mdl_animtimer,r14)
; .no_anim:

	; Now start reading
		mov	#Cach_CurrPlygn,r13		; r13 - temporal face output
		mov	@(mdl_data,r14),r12		; r12 - model header
		mov 	@(8,r12),r11			; r11 - face data
		mov 	@(4,r12),r10			; r10 - vertice data (X,Y,Z)
		mov.w	@r12,r9				;  r9 - Number of faces used on model
		mov	@(marsGbl_CurrZList,gbr),r0	;  r8 - Zlist for sorting
		mov	r0,r8
.next_face:
		mov.w	@(marsGbl_CurrNumFaces,gbr),r0	; Ran out of space to store faces?
		mov	.tag_maxfaces,r1
		cmp/ge	r1,r0
		bf	.can_build
.no_model:
		bra	.exit_model
		nop
		align 4
.tag_maxfaces:	dc.l	MAX_FACES

; --------------------------------

.can_build:
		mov.w	@r11+,r4		; Read type
		mov	#3,r7			; r7 - Current polygon type: triangle (3)
		mov	r4,r0
		shlr8	r0
		tst	#PLGN_TRI,r0		; Model face uses triangle?
		bf	.set_tri
		add	#1,r7			; Face is quad, r7 = 4 points
.set_tri:
		cmp/pl	r4			; Faces uses texture? ($8xxx)
		bt	.solid_type

; --------------------------------
; Set texture material
; --------------------------------

		mov	@($C,r12),r6		; r6 - Material data
		mov	r13,r5			; r5 - Go to UV section
		add 	#polygn_srcpnts,r5
		mov	r7,r3			; r3 - copy of current face points (3 or 4)

	; Faster read
	rept 3
		mov.w	@r11+,r0		; Read UV index
		extu	r0,r0
		shll2	r0
		mov	@(r6,r0),r0
		mov.w	r0,@(2,r5)
		shlr16	r0
		mov.w	r0,@r5
		add	#4,r5
	endm
		mov	#3,r0			; Triangle?
		cmp/eq	r0,r7
		bt	.alluvdone		; If yes, skip this
		mov.w	@r11+,r0		; Read extra UV index
		extu	r0,r0
		shll2	r0
		mov	@(r6,r0),r0
		mov.w	r0,@(2,r5)
		shlr16	r0
		mov.w	r0,@r5
.alluvdone:

		mov	@(mdl_option,r14),r0
		and	#$FF,r0
		mov	r0,r1
		mov	r4,r0
		mov	.tag_andmtrl,r5
		and	r5,r0
		shll2	r0
		shll	r0
		mov	@($10,r12),r6
		add	r0,r6
		mov	#$C000,r0		; grab special bits
		and	r0,r4
		shll16	r4
		mov	@(4,r6),r0
		or	r0,r4
		add	r1,r4
		mov	r4,@(polygn_type,r13)
		mov	@r6,r0
		mov	r0,@(polygn_mtrl,r13)
		bra	.go_faces
		nop
		align 4
.tag_andmtrl:
		dc.l $3FFF

; --------------------------------
; Set texture material
; --------------------------------

.solid_type:
		mov	@(mdl_option,r14),r0
		and	#$FF,r0
		mov	r0,r1
		mov	r4,r0
		mov	#$E000,r5
		and	r5,r4
		shll16	r4
		add	r1,r4
		mov	r4,@(polygn_type,r13)		; Set type 0 (tri) or quad (1)
		and	#$FF,r0
		mov	r0,@(polygn_mtrl,r13)		; Set pixel color (0-255)

; --------------------------------
; Read faces
; --------------------------------

.go_faces:
		mov	r13,r1
		add 	#polygn_points,r1
		mov	r11,r6
		mov	r7,r0
		shll	r0
		add	r0,r11

		mov	#Cach_BkupS_S,r0
		mov 	r8,@-r0
		mov 	r9,@-r0
		mov 	r11,@-r0
		mov 	r12,@-r0
		mov 	r13,@-r0
		mov	.tag_xl,r8
		neg	r8,r9
		mov	#-112,r11
		neg	r11,r12
		mov	#$7FFFFFFF,r5
		mov	#$FFFFFFFF,r13

	; Do 3 points
	rept 3
		mov	#0,r0
		mov.w 	@r6+,r0
		mov	#$C,r4
		mulu	r4,r0
		sts	macl,r0
		mov	r10,r4
		add 	r0,r4
		mov	@r4,r2
		mov	@(4,r4),r3
		mov	@(8,r4),r4
		bsr	mdlrd_setpoint
		nop
		mov	r2,@r1
		mov	r3,@(4,r1)
		add	#8,r1
	endm
		mov	#3,r0			; Triangle?
		cmp/eq	r0,r7
		bt	.alldone		; If yes, skip this
		mov	#0,r0
		mov.w 	@r6+,r0
		mov	#$C,r4
		mulu	r4,r0
		sts	macl,r0
		mov	r10,r4
		add 	r0,r4
		mov	@r4,r2
		mov	@(4,r4),r3
		mov	@(8,r4),r4
		bsr	mdlrd_setpoint
		nop
		mov	r2,@r1
		mov	r3,@(4,r1)
.alldone:
		mov	r8,r1
		mov	r9,r2
		mov	r11,r3
		mov	r12,r4
		mov	r13,r6

		mov	#Cach_BkupS_L,r0
		mov	@r0+,r13
		mov	@r0+,r12
		mov	@r0+,r11
		mov	@r0+,r9
		mov	@r0+,r8

	; NOTE: if you don't like how the perspective works
	; change this instruction depending how you want to ignore
	; faces closer to the camera:
	;
	; r5 - Back Z point, keep affine limitations
	; r6 - Front Z point, skip face but larger faces are affected

		cmp/pz	r5			; *** back z
		bt	.go_fout
; 		cmp/pz	r6			; *** front z
; 		bt	.go_fout

		mov	#MAX_ZDIST,r0		; Draw distance
		cmp/ge	r0,r5
		bf	.go_fout
		mov	#-(SCREEN_WIDTH/2),r0
		cmp/gt	r0,r1
		bf	.go_fout
		neg	r0,r0
		cmp/ge	r0,r2
		bt	.go_fout
		mov	#-(SCREEN_HEIGHT/2),r0
		cmp/gt	r0,r3
		bf	.go_fout
		neg	r0,r0
		cmp/ge	r0,r4
		bf	.face_ok
.go_fout:	bra	.face_out
		nop
		align 4
.tag_xl:	dc.l -160

; --------------------------------

.face_ok:
		mov.w	@(marsGbl_CurrNumFaces,gbr),r0	; Add 1 face to the list
		add	#1,r0
		mov.w	r0,@(marsGbl_CurrNumFaces,gbr)
		mov	@(marsGbl_CurrFacePos,gbr),r0
		mov	r0,r1
		mov	r13,r2
		mov	r5,@r8				; Store current Z to Zlist
		mov	r1,@(4,r8)			; And it's address

; 	Sort this face
; 	r7 - Curr Z
; 	r6 - Past Z
		mov.w	@(marsGbl_CurrNumFaces,gbr),r0
		cmp/eq	#1,r0
		bt	.first_face
		cmp/eq	#2,r0
		bt	.first_face
		mov	r8,r7
		add	#-8,r7
; 		mov	@(marsGbl_CurrZList,gbr),r0
; 		mov	r0,r6
		mov	@(marsGbl_CurrZTop,gbr),r0
		mov	r0,r6
; 		mov	#RAM_Mars_PlgnList_0,r6
; 		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
; 		tst     #1,r0
; 		bf	.page_2
; 		mov	#RAM_Mars_PlgnList_1,r6
.page_2:
		cmp/ge	r6,r7
		bf	.first_face
		mov	@(8,r7),r4
		mov	@r7,r5
		cmp/eq	r4,r5
		bt	.first_face
		cmp/gt	r4,r5
		bf	.swap_me
		mov	@r7,r4
		mov	@(8,r7),r5
		mov	r5,@r7
		mov	r4,@(8,r7)
		mov	@(4,r7),r4
		mov	@($C,r7),r5
		mov	r5,@(4,r7)
		mov	r4,@($C,r7)
.swap_me:
		bra	.page_2
		add	#-8,r7

.first_face:
		add	#8,r8			; Next Zlist entry
	rept sizeof_polygn/2			; Copy words manually
		mov.w	@r2+,r0
		mov.w	r0,@r1
		add	#2,r1
	endm
		mov	r1,r0
		mov	r0,@(marsGbl_CurrFacePos,gbr)
.face_out:
		dt	r9
		bt	.finish_this
		bra	.next_face
		nop
.finish_this:
		mov	r8,r0
		mov	r0,@(marsGbl_CurrZList,gbr)
.exit_model:
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ----------------------------------------
; Modify position to current point
; ----------------------------------------

		align 4
mdlrd_setpoint:
		mov	#Cach_BkupPnt_S,r0
		sts	pr,@-r0
		mov 	r5,@-r0
		mov 	r6,@-r0
		mov 	r7,@-r0
		mov 	r8,@-r0
		mov 	r9,@-r0
		mov 	r10,@-r0
		mov 	r11,@-r0

	; Object rotation
		mov	r2,r5			; r5 - X
		mov	r4,r6			; r6 - Z
  		mov 	@(mdl_x_rot,r14),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r7,r2
   		mov	r3,r5
  		mov	r8,r6
  		mov 	@(mdl_y_rot,r14),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r8,r4
   		mov	r2,r5
   		mov	r7,r6
   		mov 	@(mdl_z_rot,r14),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r7,r2
   		mov	r8,r3
		mov	@(mdl_x_pos,r14),r5
		mov	@(mdl_y_pos,r14),r6
		mov	@(mdl_z_pos,r14),r7
; 		shlr8	r5
; 		shlr8	r6
; 		shlr8	r7
		exts	r5,r5
		exts	r6,r6
		exts	r7,r7
		add 	r5,r2
		add 	r6,r3
		add 	r7,r4

	; Include camera changes
		mov 	#RAM_Mars_ObjCamera,r11
		mov	@(cam_x_pos,r11),r5
		mov	@(cam_y_pos,r11),r6
		mov	@(cam_z_pos,r11),r7
; 		mov	@(mdl_data,r14),r0		; Layout object?
; 		shll	r0
; 		cmp/pl	r0
; 		bt	.lay_move
; 		mov	#$FFFFF,r0			; Limit camera movement
; 		and	r0,r5
; ; 		and	r0,r6
; 		and	r0,r7
; .lay_move:
		shlr8	r5
		shlr8	r6
		shlr8	r7
		exts	r5,r5
		exts	r6,r6
		exts	r7,r7
		sub 	r5,r2
		sub 	r6,r3
		add 	r7,r4

		mov	r2,r5
		mov	r4,r6
  		mov 	@(cam_x_rot,r11),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r7,r2
   		mov	r8,r4
   		mov	r3,r5
  		mov	r8,r6
  		mov 	@(cam_y_rot,r11),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r8,r4
   		mov	r2,r5
   		mov	r7,r6
   		mov 	@(cam_z_rot,r11),r0
  		shlr2	r0
  		shlr	r0
  		bsr	mdlrd_rotate
		shlr8	r0
   		mov	r7,r2
   		mov	r8,r3

	; Weak perspective projection
	; this is the best I got,
	; It breaks on large faces
		mov 	#_JR,r8
		mov	#256<<17,r7
		neg	r4,r0		; reverse Z
		cmp/pl	r0
		bt	.inside
		mov	#1,r0
		shlr2	r7
		shlr2	r7
; 		shlr	r7
		dmuls	r7,r2
		sts	mach,r0
		sts	macl,r2
		xtrct	r0,r2
		dmuls	r7,r3
		sts	mach,r0
		sts	macl,r3
		xtrct	r0,r3
		bra	.zmulti
		nop
.inside:
		mov 	r0,@r8
		mov 	r7,@(4,r8)
		nop
		mov 	@(4,r8),r7
		dmuls	r7,r2
		sts	mach,r0
		sts	macl,r2
		xtrct	r0,r2
		dmuls	r7,r3
		sts	mach,r0
		sts	macl,r3
		xtrct	r0,r3
.zmulti:
		mov	#Cach_BkupPnt_L,r0
		mov	@r0+,r11
		mov	@r0+,r10
		mov	@r0+,r9
		mov	@r0+,r8
		mov	@r0+,r7
		mov	@r0+,r6
		mov	@r0+,r5
		lds	@r0+,pr

	; Set the most far points
	; for each direction (X,Y,Z)
		cmp/gt	r13,r4
		bf	.save_z2
		mov	r4,r13
.save_z2:
		cmp/gt	r5,r4
		bt	.save_z
		mov	r4,r5
.save_z:
		cmp/gt	r8,r2
		bf	.x_lw
		mov	r2,r8
.x_lw:
		cmp/gt	r9,r2
		bt	.x_rw
		mov	r2,r9
.x_rw:
		cmp/gt	r11,r3
		bf	.y_lw
		mov	r3,r11
.y_lw:
		cmp/gt	r12,r3
		bt	.y_rw
		mov	r3,r12
.y_rw:
		rts
		nop
		align 4
		ltorg

; ------------------------------
; Rotate point
;
; Entry:
; r5: x
; r6: y
; r0: theta
;
; Returns:
; r7: (x  cos @) + (y sin @)
; r8: (x -sin @) + (y cos @)
; ------------------------------

		align 4
mdlrd_rotate:
    		mov	#$7FF,r7
    		and	r7,r0
   		shll2	r0
		mov	#sin_table,r7
		mov	#sin_table+$800,r8
		mov	@(r0,r7),r9
		mov	@(r0,r8),r10

		dmuls	r5,r10		; x cos @
		sts	macl,r7
		sts	mach,r0
		xtrct	r0,r7
		dmuls	r6,r9		; y sin @
		sts	macl,r8
		sts	mach,r0
		xtrct	r0,r8
		add	r8,r7

		neg	r9,r9
		dmuls	r5,r9		; x -sin @
		sts	macl,r8
		sts	mach,r0
		xtrct	r0,r8
		dmuls	r6,r10		; y cos @
		sts	macl,r9
		sts	mach,r0
		xtrct	r0,r9
		add	r9,r8
 		rts
		nop
		align 4
		ltorg

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
		mov	#RAM_Mars_SVdpDrwList,r0		; Reset DDA pieces Read/Write points
		mov	r0,@(marsGbl_PlyPzList_R,gbr)		; And counter
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
		mov	r0,@(marsGbl_PlyPzList_Start,gbr)
		mov	#RAM_Mars_SVdpDrwList_E,r0
		mov	r0,@(marsGbl_PlyPzList_End,gbr)

		mov	#0,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
		mov.w	r0,@(marsGbl_WdgStatus,gbr)
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
