; ====================================================================
; ----------------------------------------------------------------
; 32X Video
;
; Some routines are located on the cache folder for
; speed reasons.
; ----------------------------------------------------------------

; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_SCRNBUFF	equ $28000	; MAX SDRAM for each fake-screen mode
FBVRAM_LAST	equ $1F800	; BLANK line (the very last one)
FBVRAM_PATCH	equ $1D000	; Framebuffer location for the affected XShift lines
MAX_FACES	equ 700		; MAX polygon faces for models
MAX_SVDP_PZ	equ 700+128	; MAX polygon pieces to draw (MAX_FACES+few_pieces)
MAX_ZDIST	equ -$1000	; Maximum 3D field distance (-Z)
MAX_SSPRSPD	equ 8		; Maximum pixel speed for Super Sprites

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; Variables for 3D mode.
SCREEN_WIDTH	equ 320		; Screen width and height positions used
SCREEN_HEIGHT	equ 224		; by 3D object rendering
PLGN_TEXURE	equ %10000000	; plypz_type (MSB)
PLGN_TRI	equ %01000000

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

		struct 0
scrl_xpos_old	ds.w 1		; OLD Xpos position
scrl_ypos_old	ds.w 1		; OLD Ypos position
scrl_fbpos_y	ds.w 1		; This field's REAL Y position
scrl_null_w	ds.w 1		; ** FILLER, free to use **
scrl_intrl_w	ds.w 1		; Internal scroll Width (MUST be larger than 320)
scrl_intrl_h	ds.w 1		; Internal scroll Height
scrl_intrl_size	ds.l 1		; Internal scroll FULL size (scrl_intrl_w*scrl_intrl_h)
scrl_fbpos	ds.l 1		; Top-left position of this field
scrl_fbdata	ds.l 1		; Location of the pixel data in the framebuffer
scrl_xpos	ds.l 1		; 0000.0000
scrl_ypos	ds.l 1		; 0000.0000
sizeof_mscrl	ds.l 0
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
;
; Breaks:
; r1-r4
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
; r2 | Width/2
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
; Reset the nametable, points all lines into a blank
; line (FBVRAM_LAST)
;
; Breaks:
; r1-r2
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
; MarsVideo_MakeNameTbl
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
; r1-r11
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
; Fix the $xxFF lines
;
; Input:
; r1 | Start line
; r2 | Number of lines
; r3 | Location for the fixed lines
;
; Break:
; r7-r14
; --------------------------------------------------------

; TODO: customize Top/Bottom

MarsVideo_FixTblShift:
		mov	#_vdpreg,r14
		mov.b	@(bitmapmd,r14),r0	; Check if we are on indexed mode
		and	#%11,r0
		cmp/eq	#1,r0
		bf	.ptchset
		mov.w	@(marsGbl_XShift,gbr),r0	; XShift is set?
		and	#1,r0
		tst	r0,r0
		bt	.ptchset

		mov	#_framebuffer,r14	; r14 - Framebuffer BASE
		mov	r14,r12			; r12 - Framebuffer output for the patched pixel lines
		add	r3,r12
		mov	r1,r0
		shll2	r0
		add	r0,r14
		mov	r14,r13			; r13 - Framebuffer lines to check
		mov	r2,r11			; r11 - Lines to check
		mov	#-1,r0
		extu.b	r0,r10			; r10 - AND byte to check ($FF)
		extu.w	r0,r9			;  r9 - AND word limit ($FFFF)
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
; The routines that write to the framebuffer are
; located at cache_m_scrlbg.asm
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
; r2 | Framebuffer VRAM position
; r3 | Scroll Width (320 or large)
; r4 | Scroll Height
; r5 | Scroll block size (4 pixels minimum)
;
; NOTE:
; At the very last scrollable line, the next 320
; pixels will be visible until that line resets
; into 0 again.
; When you write pixels in in the range of 0-320,
; write the same pixels at the very end of
; the scrolling area (add width*height)
;
; Breaks:
; r3-r4,macl
; --------------------------------------------------------

		align 4
MarsVideo_MkScrlField:
		mov	#sizeof_mscrl,r0
		mulu	r0,r1
		sts	macl,r1
		mov	#RAM_Mars_ScrlBuff,r0
		add	r0,r1

		add	r5,r3	; add "block" into width/height
		add	r5,r4

		mov	r2,@(scrl_fbdata,r1)
		mov	r3,r0
		mov.w	r0,@(scrl_intrl_w,r1)
		mov	r4,r0
		mov.w	r0,@(scrl_intrl_h,r1)
; 		mov	r5,r0
; 		mov.w	r0,@(scrl_intrl_blk,r1)
		mulu	r3,r4
		sts	macl,r0
		mov	r0,@(scrl_intrl_size,r1)

		xor	r0,r0
; 		mov.b	r0,@(scrl_xset,r1)
; 		mov.b	r0,@(scrl_yset,r1)
		mov.w	r0,@(scrl_xpos_old,r1)
		mov.w	r0,@(scrl_ypos_old,r1)
		mov	r0,@(scrl_fbpos,r1)
		mov.w	r0,@(scrl_fbpos_y,r1)
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsVideo_SetScrlBg
;
; Sets the source data for the background
;
; Input:
; r1 | Background buffer
; r2 | Pixel data location
; r3 | Map data location
; r4 | Block size
; r5 | Map width in blocks
; r6 | Map height in blocks
;
; Breaks:
; r0,r1
;
; NOTES:
; - ROM data is NOT protected.
; --------------------------------------------------------

; MarsVideo_SetScrlBg:
; 		mov	r2,@(scrl_data,r1)
; 		mov	r3,@(scrl_mapdata,r1)
; 		mov	r4,r0
; 		mov.b	r0,@(scrl_bg_bw,r1)
; 		mov	r5,r0
; 		mov.w	r0,@(scrl_width,r1)
; 		mov	r6,r0
; 		mov.w	r0,@(scrl_height,r1)
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ; --------------------------------------------------------
; ; MarsVideo_SetScrlBg
; ;
; ; Sets the source data for the background
; ;
; ; Input:
; ; r1 | Background buffer
; ; r2 | Source image location (ROM or SDRAM)
; ; r3 | Source image Width
; ; r4 | Source image Height
; ;
; ; Breaks:
; ; r0,r1
; ;
; ; NOTES:
; ; - Width and Height must be aligned by the current
; ; buffer's block size
; ; - ROM data is NOT protected
; ; --------------------------------------------------------
;
; MarsVideo_SetScrlBg:
; 		mov	r2,@(scrl_data,r1)
; 		mov.b	@(scrl_flags,r1),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bt	.indxmode
; 		shll	r3
; .indxmode:
; 		mov	r3,r0
; 		mov.w	r0,@(scrl_width,r1)
; 		mov	r4,r0
; 		mov.w	r0,@(scrl_height,r1)
; 		rts
; 		nop
; 		align 4
; 		ltorg

; --------------------------------------------------------
; MarsVideo_ShowScrlBg
;
; Make a visible section of any scrolling area
; into the current framebuffer.
;
; Input:
; r1 | Background buffer
; r2 | Top Y
; r3 | Bottom Y
;
; Breaks:
; r4-r14
;
; NOTE:
; After finishing all your screens call
; MarsVideo_FixTblShift before doing frameswap
; --------------------------------------------------------

		align 4
MarsVideo_ShowScrlBg:
		mov	#_framebuffer,r14		; r14 - Framebuffer BASE
		mov	@(scrl_fbdata,r1),r13		; r13 - Framebuffer pixeldata position
		mov	@(scrl_intrl_size,r1),r12	; r12 - Full size of screen-scroll
		mov	#0,r11				; r11 - line counter
		mov.w	@(scrl_intrl_w,r1),r0
		mov	r0,r10				; r10 - Next line to add
		mov	r2,r6
		mov	r2,r0
		shll	r0
		add	r0,r14
		mov.w	@(scrl_fbpos_y,r1),r0
		mulu	r10,r0
		mov	@(scrl_fbpos,r1),r7
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
		add	r10,r7			; Add Y
		add	r13,r8			; Add Framebuffer position
		shlr	r8			; Divide by 2, use Xshift for the missing bit
		mov.w	r8,@r14			; Send to FB's table
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
; MarsVideo_Bg_MdMove
;
; Moves the scrolling area using X/Y values from
; the Genesis side.
;
; Input:
; r14 | Genesis background buffer
; r13 | Scrolling-area buffer
;
; Breaks:
; ALL
; --------------------------------------------------------

		align 4
MarsVideo_Bg_MdMove:
		mov	@(md_bg_x,r14),r0		; Copy-paste...
		mov	r0,@(scrl_xpos,r13)
		mov	@(md_bg_y,r14),r0
		mov	r0,@(scrl_ypos,r13)

		mov	#0,r1
		mov	#0,r2
		mov	@(scrl_xpos,r13),r0		; 0000.0000
		shlr16	r0				; **
		mov.w	r0,@(marsGbl_XShift,gbr)	; ** Grab missing bit for xshift
		exts.w	r0,r0
		mov	r0,r3
		mov.w	@(scrl_xpos_old,r13),r0
		cmp/eq	r0,r3
		bt	.xequ
		mov	r3,r1
		sub	r0,r1
.xequ:
		mov	r3,r0
		mov.w	r0,@(scrl_xpos_old,r13)
		mov	@(scrl_ypos,r13),r0	; 0000.0000
		shlr16	r0
		exts.w	r0,r0
		mov	r0,r3
		mov.w	@(scrl_ypos_old,r13),r0
		cmp/eq	r0,r3
		bt	.yequ
		mov	r3,r2
		sub	r0,r2
.yequ:
		mov	r3,r0
		mov.w	r0,@(scrl_ypos_old,r13)
		exts.w	r1,r1
		exts.w	r2,r2

	; ---------------------------------------
	; Move Y-Framebuffer pos
	; ---------------------------------------

		mov.w	@(scrl_intrl_h,r13),r0
		mov	r0,r3
		mov.w	@(scrl_fbpos_y,r13),r0
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
		mov.w	r0,@(scrl_fbpos_y,r13)

	; ---------------------------------------
	; Update Framebuffer Top-Left position
	; ---------------------------------------

		mov	@(scrl_intrl_size,r13),r3
		mov	@(scrl_fbpos,r13),r0
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
		mov	r0,@(scrl_fbpos,r13)
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsVideo_Bg_MdReq
;
; Input:
; r14 | Genesis background buffer
; r13 | Scrolling-area buffer
;
; Note:
; The R/L/D/U bits are cleared on the Genesis-side, no
; need to clear them here.
;
; Breaks:
; ALL
; --------------------------------------------------------

; TODO: merge the bits

		align 4
MarsVideo_Bg_MdReq:
		sts	pr,@-r15
		mov.b	@(md_bg_flags,r14),r0
		mov	#Cach_DrawTimers,r2
		extu.b	r0,r0
; 		and	#$FF,r0
		mov	r2,r1			; Set NEW screen timers ($02)
		mov	#2,r3
		tst	#%00000001,r0		; bitDrwR
		bt	.no_r
		mov	r3,@r1
.no_r:
		add	#4,r1
		tst	#%00000010,r0		; bitDrwL
		bt	.no_l
		mov	r3,@r1
.no_l:
		add	#4,r1
		tst	#%00000100,r0		; bitDrwD
		bt	.no_d
		mov	r3,@r1
.no_d:
		add	#4,r1
		tst	#%00001000,r0		; bitDrwU
		bt	.no_upd
		mov	r3,@r1
.no_upd:

	; mach - Watchdog settings
	;  r14 - Background buffer
	;  r13 - Scroll area buffer
	;  r12 - Layout data
	;  r11 - Framebuffer X/Y pos
	;  r10 - Layout width
	;   r9 - Scroll width (next line)
	;   r8 - Scroll FULL size (w*h)
	;   r7 - Framebuffer BASE
	;   r6 - Block data
	;   r5 - Block timer
	;   r4 - X or Y increment
	;   r3 - Layout increment
	;   r2 - Screen timers RLDU

		mov	@(md_bg_low,r14),r12
		mov	#Cach_WdgBuffWr,r3
		mov	@(scrl_fbpos,r13),r11
		mov	#-16,r1				; <-- (-)manual block size
		mov.w	@(md_bg_w,r14),r0
		extu.w	r0,r10
		mov.w	@(scrl_intrl_w,r13),r0
		extu.w	r0,r9
		mov	@(scrl_intrl_size,r13),r8
		mov	#_framebuffer,r0
		mov	@(scrl_fbdata,r13),r7
		add	r0,r7
		mov	@(md_bg_blk,r14),r6
		mov	#((224+16)/16),r5		; Timer for L/R
		mov.w	@(scrl_fbpos_y,r13),r0
		extu.w	r0,r0
		and	r1,r11
		and	r1,r0
		mulu	r0,r9
		sts	macl,r0
		add	r0,r11
		lds	r3,mach

	; L/R columns
		mov	r12,r13				; <-- copy layout
		mov.w	@(md_bg_yinc_u,r14),r0		; Move top Y
		exts.w	r0,r0
		mov	#16,r1				; <-- manual block size
		muls	r1,r0
		sts	macl,r0
		shlr8	r0
		exts.w	r0,r0
		muls	r10,r0
		sts	macl,r0
		add	r0,r12
		mov.w	@(md_bg_xinc_r,r14),r0
		mov	#320,r4				; r4 - X increment
		bsr	.x_draw
		exts.w	r0,r3
		mov.w	@(md_bg_xinc_l,r14),r0
		exts.w	r0,r3
		mov	#0,r4
		bsr	.x_draw
		add	#4,r2

	; U/D rows
		mov	#((320+16)/16),r5		; Timer for U/D
		mov	r13,r12
		add	#4,r2				; Now check D/U timers
		sts	mach,r0
		add	#$20,r0
		lds	r0,mach
		mov.w	@(md_bg_xinc_l,r14),r0		; Move left
		exts.w	r0,r0
		mov	#16,r1				; <-- manual block size
		muls	r1,r0
		sts	macl,r0
		shlr8	r0
		exts.w	r0,r0
		add	r0,r12
		mov.w	@(md_bg_yinc_d,r14),r0
		mov	#224,r4
		bsr	.y_draw
		exts.w	r0,r3
		mov.w	@(md_bg_yinc_u,r14),r0
		extu.w	r0,r3
		mov	#0,r4
		bsr	.y_draw
		add	#4,r2

		lds	@r15+,pr
		rts
		nop
		align 4

; ----------------------------------------

; r3 - layout X increment
; r4 - framebuffer X increment
; mach - Cach_WdgBuffWr

.x_draw:
		mov	@r2,r0
		tst	r0,r0
		bt	.no_timer
		dt	r0
		mov	r0,@r2

		mov	#16,r1		; <-- manual block size
		muls	r1,r3		; r3 - layout increment
		sts	macl,r3
		shlr8	r3
		mov	r11,r1
		add	r4,r1
		cmp/ge	r8,r1
		bf	.sz_safe
		sub	r8,r1
.sz_safe:
		sts	mach,r0
		mov	r5,@-r0
		mov	r6,@-r0
		mov	r7,@-r0
		mov	r8,@-r0
		mov	r9,@-r0
		mov	r10,@-r0
		mov	 r1,@-r0	; <-- copy of r11
		mov	r12,r1		; <-- layout + X pos
		add	 r3,r1
		mov	 r1,@-r0
.no_timer:
		rts
		nop
		align 4

; ----------------------------------------

; r3 - layout Y increment
; r4 - framebuffer Y increment
; mach - Cach_WdgBuffWr_UD

.y_draw:
		mov	@r2,r0
		tst	r0,r0
		bt	.no_timer
		dt	r0
		mov	r0,@r2

		mov	#16,r1		; <-- manual block size
		muls	r1,r3		; r3 - layout increment
		sts	macl,r3
		shlr8	r3
		mulu	r10,r3
		sts	macl,r3

		mov	r11,r1
		mulu	r9,r4
		sts	macl,r0
		add	r0,r1
		cmp/ge	r8,r1
		bf	.sz_safey
		sub	r8,r1
.sz_safey:
		sts	mach,r0
		mov	r5,@-r0
		mov	r6,@-r0
		mov	r7,@-r0
		mov	r8,@-r0
		mov	r9,@-r0
		mov	r10,@-r0
		mov	 r1,@-r0	; <-- copy of r11
		mov	r12,r1		; <-- layout + Y pos
		add	 r3,r1
		mov	 r1,@-r0
		rts
		nop
		align 4

		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Super sprites
;
; Some routines are located on cache_m_scrlbg.asm
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
;
; Breaks:
; r7
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

; ; --------------------------------------------------------
; ; MarsVideo_SetSprFill
; ;
; ; Builds a list of blocks to redraw for the
; ; next frame.
; ;
; ; Input:
; ; r14 | Scrolling buffer
; ; r13 | Background buffer
; ; r12 | List of blocks to redraw
; ; --------------------------------------------------------
;
; 		align 4
; MarsVideo_SetSprFill:
; 		mov	#$80000000,r11
; 		mov	#$7FFFFFFF,r10
; 		mov	#MAX_SUPERSPR,r9
; .next_one:
; 		mov	@(marsspr_data,r13),r0
; 		tst	r0,r0
; 		bt	.exit
; 		cmp/pl	r9
; 		bf	.exit
; 		mov.w	@(marsspr_x,r13),r0		; r1 - X pos (left)
; 		mov	r0,r1
; 		mov.w	@(marsspr_y,r13),r0		; r2 - Y pos (top)
; 		mov	r0,r2
; 		mov.b	@(marsspr_xs,r13),r0		; r3 - XS (right)
; 		extu.b	r0,r3
; 		mov.b	@(marsspr_ys,r13),r0		; r4 - YS (bottom)
; 		extu.b	r0,r4
; 		mov	@(scrl_xpos,r14),r8
; 		shlr16	r8
; 		mov	@(scrl_ypos,r14),r9
; 		shlr16	r9
; 		add	r1,r3
; 		add	r2,r4
; 		mov	#16,r5		; <-- manual block size
;
; 		mov	r5,r0		; extend box
; 		sub	r0,r1
; 		sub	r0,r2
; 		shlr	r0
; 		add	r0,r3
; 		add	r0,r4
;
; 		dt	r0
; 		and	r0,r8
; 		and	r0,r9
; ; 		shll	r8
; 		add	r8,r1
; 		add	r8,r3
; 		add	r8,r3
;
; 	; TODO: X/Y REVERSE CHECK
; 		mov	#320,r6			; <-- manual sizes
; 		mov	#224,r7
; 		add	r5,r6
; 		add	r5,r7
; 		cmp/pl	r1
; 		bt	.xl_l
; 		xor	r1,r1
; .xl_l:
; 		cmp/ge	r6,r1
; 		bf	.xl_r
; 		mov	r6,r1
; .xl_r:
; 		cmp/pl	r3
; 		bt	.xr_l
; 		xor	r3,r3
; .xr_l:
; 		cmp/ge	r6,r3
; 		bf	.xr_r
; 		mov	r6,r3
; .xr_r:
;
; 		cmp/pl	r2
; 		bt	.yt_l
; 		xor	r2,r2
; .yt_l:
; 		cmp/ge	r7,r2
; 		bf	.yt_r
; 		mov	r7,r2
; .yt_r:
; 		cmp/pl	r4
; 		bt	.yb_l
; 		xor	r4,r4
; .yb_l:
; 		cmp/ge	r7,r4
; 		bf	.yb_r
; 		mov	r7,r4
; .yb_r:
; 		cmp/eq	r1,r3
; 		bt	.bad_xy
; 		cmp/eq	r2,r4
; 		bt	.bad_xy
;
; 	; r1 - X direct
; 	; r2 - Y direct
; 	; r3 - X s
; 	; r4 - Y s
; 	; r5 - block size
; 	; r6 - last corrds
; 		mov	#-1,r6
; .y_mk:
; 		mov	r1,r9
; .x_mk:
; 		mulu	r5,r9
; 		sts	macl,r7
; 		shlr8	r7
; 		mulu	r5,r2
; 		sts	macl,r8
; 		shlr8	r8
; 		shll8	r8
; 		mov	r7,r0
; 		extu.b	r0,r0
; 		add	r8,r0
; 		mov	#$8000,r8
; 		or	r8,r0
; 		cmp/eq	r6,r0
; 		bt	.keep
; 		mov.w	r0,@r12
; 		mov	r0,r6
; 		add	#4,r12
; .keep:
; 		add	#16,r9
; 		cmp/ge	r3,r9
; 		bf	.x_mk
; 		add	#16,r2
; 		cmp/ge	r4,r2
; 		bf	.y_mk
;
; .bad_xy:
; 		bra	.next_one
; 		add	#sizeof_marsspr,r13
; .exit:
; 		rts
; 		nop
; 		align 4
; ; 		ltorg

; ; --------------------------------------------------------
; ; MarsVideo_WdSprBlk
; ;
; ; Refill the background sections overwritten by
; ; the Super-Sprites using a list generated by
; ; MarsVideo_SetSprFill
; ;
; ; Input:
; ; r14 | Scrolling buffer
; ; r13 | Background buffer
; ; r12 | List of blocks to redraw
; ;
; ; Note:
; ; CPU-intensive, and doesn't have any overflow protection.
; ; --------------------------------------------------------
;
; 		align 4
; MarsVideo_WdSprBlk:
; 		mov	#16,r2			; <-- (-)manual block size
; 		mov	@(scrl_intrl_size,r14),r10
; 		mov	#_framebuffer,r4
; 		mov	@(scrl_fbdata,r14),r0
; 		add	r0,r4
; 		mov	@(scrl_fbpos,r14),r11
; 		neg	r2,r1
; 		mov.w	@(scrl_fbpos_y,r14),r0
; 		extu.w	r0,r3
; 		mov.w	@(scrl_intrl_w,r14),r0
; 		extu.w	r0,r9
; 		mov	@(md_bg_blk,r13),r8
; 		and	r1,r3
; 		mov	@(md_bg_low,r13),r7
; 		and	r1,r11
; 		mov.w	@(md_bg_w,r13),r0
; 		extu.w	r0,r6
; 		mov.w	@(md_bg_xinc_l,r13),r0
; 		exts.w	r0,r1
; 		mov.w	@(md_bg_yinc_u,r13),r0
; 		exts.w	r0,r0
; 		lds	r4,mach
; 		muls	r2,r1
; 		sts	macl,r1
; 		muls	r2,r0
; 		sts	macl,r0
; 		shlr8	r0
; 		shlr8	r1
; 		exts.b	r0,r0
; 		exts.b	r1,r1
; 		muls	r6,r0
; 		sts	macl,r0
; 		add	r0,r1
; 		add	r1,r7
;
; 		mulu	r9,r3
; 		sts	macl,r0
; 		add	r0,r11
; 		cmp/gt	r10,r11
; 		bf	.fbmuch
; 		sub	r10,r11
; .fbmuch:
; 		mov	#16,r5		; <-- manual block size
; .next:
;
; 	; mach - _framebuffer area
; 	;  r13 - Counter
; 	;  r12 - Refill buffer
; 	;  r11 - Scroll current top-left
; 	;  r10 - FULL Scroll area size
; 	;   r9 - Scroll Width
; 	;   r8 - Block graphics
; 	;   r7 - Layout data
; 	;   r6 - Layout width
; 	;   r5 - Block size
;
; 		mov	#($80*(240/4))/16,r13
; 		mov	#Cach_BlkRefill_S,r0
; 		sts	mach,@-r0
; 		mov	r5,@-r0
; 		mov	r6,@-r0
; 		mov	r7,@-r0
; 		mov	r8,@-r0
; 		mov	r9,@-r0
; 		mov	r10,@-r0
; 		mov	r11,@-r0
; 		mov	r12,@-r0
; 		mov	r13,@-r0

		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 3D Section
; ----------------------------------------------------------------

; Moved to
; cache_slv.asm

; ====================================================================
; ----------------------------------------------------------------
; Other
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_SetWatchdog
;
; Prepares watchdog interrupt
;
; Input:
; r1 - Watchdog CPU clock divider
; r2 - Watchdog Pre-timer
; --------------------------------------------------------

		align 4
MarsVideo_SetWatchdog:
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
