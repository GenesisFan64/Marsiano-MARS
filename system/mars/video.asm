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

MAX_SCRNBUFF	equ $12800	; MAX storage for each screen mode
FBVRAM_LAST	equ $1FD80	; BLANK line (the very last one usable)

; Screen mode 02
FBVRAM_PATCH	equ $1E000	; Framebuffer location for the affected XShift lines

; Screen mode 04
MAX_FACES	equ 256
MAX_SVDP_PZ	equ 256+16
MAX_ZDIST	equ -$1000	; Max 3D drawing distance (-Z)

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
; The SH2 has extrange limitation with indexing, bytes go first.
; (don't forget to align it)

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
mbg_intrl_blk	ds.w 1		; Block size
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
plypz_type	ds.l 1		; Type | Option
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
		mov 	#FM,r0				; Set SVDP permission to SH2. (but the Genesis
  		mov.b	r0,@(adapter,r1)		; will control the pallete using DREQ)
		mov 	#_vdpreg,r1
		mov	#0,r0				; Start at blank
		mov.b	r0,@(bitmapmd,r1)
		mov	#_framebuffer,r2		; Make default nametables
		bsr	.def_fb
		nop
		bsr	.def_fb
		nop
		lds	@r15+,pr
		rts
		nop
		align 4

; Make default linetable, waits for frameswap.
.def_fb:
		mov	r2,r3
		mov	#FBVRAM_LAST/2,r0		; very last usable (blank) line
		mov	#240,r4
.nxt_lne:
		mov.w	r0,@r3
		dt	r4
		bf/s	.nxt_lne
		add	#2,r3
		mov.b	@(framectl,r1),r0		; Frameswap & wait
		xor	#1,r0
		mov	r0,r3
		mov.b	r0,@(framectl,r1)
.wait_frm:	mov.b	@(framectl,r1),r0
		cmp/eq	r0,r3
		bf	.wait_frm
		rts
		nop
		align 4
		ltorg
		align 4

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
; r1 - VRAM location
; r2 - Width
; r3 - height
; r4 - Pixel(s) to write
; --------------------------------------------------------

; TODO: check if this still works on SDRAM.

MarsVideo_ClearScreen:
		shlr	r1
		mov	r1,r5
		mov	#_vdpreg,r8
.fb_loop:
		mov	r2,r0
		mov.w	r0,@(filllength,r8)
		mov	r1,r0
		mov.w	r0,@(fillstart,r8)
		mov	r4,r0
		mov.w	r0,@(filldata,r8)
.wait_fb2:	mov.w	@(vdpsts,r8),r0
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
; Reset the nametable, makes all the lines point to
; a blank line.
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
; r1 | Background buffer
; r2 | Width (Width*2 for Direct color)
; r3 | Height
; r4 | Y index position
;
; NOTE: after finishing, for Indexed mode
; call MarsVideo_FixTblShift before swapping the
; framebuffer.
; --------------------------------------------------------

MarsVideo_MakeNameTbl:
		mov	#_framebuffer,r10
		shll	r4
		add	r4,r10
		mov 	#_vdpreg,r5
		mov.b	@(bitmapmd,r5),r0	; Cannot mess with the RLE lines.
		and	#%11,r0
		cmp/eq	#3,r0
		bt	.linetbl_normal
		mov.w	@(marsGbl_WaveEnable,gbr),r0
		tst	r0,r0
		bt	.linetbl_normal

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
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsVideo_FixTblShift
;
; Call this before swaping the framebuffer
; to solve a HARDWARE BUG that causes
; Xshift not to work with lines that end with $xxFF
;
; Emulators ignore this.
; --------------------------------------------------------

MarsVideo_FixTblShift:
	; TODO: A check for direct mode and RLE.
		mov.w	@(marsGbl_XShift,gbr),r0	; XShift is set?
		and	#1,r0
		cmp/eq	#1,r0
		bf	.ptchset
; 		mov.b	@(mbg_flags,r1),r0
; 		and	#%00000010,r0
; 		tst	r0,r0
; 		bf	.ptchset

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
		align 4

; --------------------------------------------------------
; MarsVideo_SetWatchdog
;
; Prepares watchdog interrupt for Master
;
; Input:
; r1 - Watchdog CPU clock divider
; r2 - Watchdog Pre-timer
; --------------------------------------------------------

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
		align 4

; 256-color Palette routines were here...
; but the 68k controls the pallete now.
; (Don't forget to transfer your changes using DREQ)

; ====================================================================
; ----------------------------------------------------------------
; Screen mode $02
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
; r1 | Background buffer to setup
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
; r2 | Source image location (ROM or RAM)
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
; NOTE: after finishing all your screens
; call MarsVideo_FixTblShift before doing frameswap
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
; MarsVideo_DrawAllBg
;
; Draws the entire image in the current framebuffer,
; this needs to be called twice to write to
; both framebuffers
;
; Input:
; r1 - X position ($0000.0000)
; r2 - Y position ($0000.0000)
; --------------------------------------------------------

		align 4
MarsVideo_DrawAllBg:
		sts	pr,@-r15
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	@(mbg_data,r14),r0
		cmp/eq	#0,r0
		bt	.no_data
		mov	r0,r13
		mov	@(mbg_xpos,r14),r1
		mov	@(mbg_ypos,r14),r2
		shlr16	r1
		shlr16	r2
		exts.w	r1,r1
		exts.w	r2,r2
		mov	r1,r0
		mov.w	r0,@(mbg_xpos_old,r14)
		mov	r2,r0
		mov.w	r0,@(mbg_ypos_old,r14)
		mov.w	@(mbg_intrl_blk,r14),r0
		neg	r0,r0
		and	r0,r1
		and	r0,r2

		mov	#_framebuffer,r12
		mov	@(mbg_fbdata,r14),r0
		add	r0,r12				; r12 - framebuffer output
		mov.w	@(mbg_width,r14),r0		; r11 - pixel-data WIDTH
		mov	r0,r11
		mov.w	@(mbg_intrl_w,r14),r0		; r10 - internal WIDTH
		mov	r0,r10
		mov.w	@(mbg_height,r14),r0		;  r9 - image WIDTH
		mov	r0,r9
		mov.w	@(mbg_intrl_h,r14),r0		;  r8 - internal HEIGHT
		mov	r0,r8
		mov.w	@(mbg_intrl_blk,r14),r0		;  r7 - block size
		mov	r0,r7
		neg	r7,r6				;  r6 - block limit bits
		mov	@(mbg_intrl_size,r14),r5	;  r5 - internal WIDTH*HEIGHT
		mov	#320,r4				;  r4 - max
		mov.b	@(mbg_flags,r14),r0
		and	#%10,r0
		tst	r0,r0
		bt	.indxmode
		shll	r4
; 		shll	r11
.indxmode:

	; Set X/Y draw heads
.xinit_l:
		cmp/pz	r1
		bt	.xbg_back
		bra	.xinit_l
		add	r11,r1
.xbg_back:
		cmp/gt	r11,r1			; First X limiter
		bf	.xbg_inc
		bra	.xbg_back
		sub	r11,r1
.xbg_inc:
		cmp/pz	r2
		bt	.ybg_back
		bra	.xbg_inc
		add	r9,r2
.ybg_back:
		cmp/gt	r9,r2			; First Y limiter
		bf	.ybg_inc
		bra	.ybg_back
		sub	r9,r2
.ybg_inc:
		mov	r1,r0
		mov.w	r0,@(mbg_xinc_l,r14)
		add	r4,r0
.lwr_xnxt:	cmp/gt	r11,r0
		bf	.lwr_xvld
		bra	.lwr_xnxt
		sub	r11,r0
.lwr_xvld:
		mov.w	r0,@(mbg_xinc_r,r14)

		mov	r2,r0
		mov.w	r0,@(mbg_yinc_u,r14)
		mov	r0,r3

		add	r8,r3
		sub	r7,r3
.lwr_ynxt:	cmp/ge	r9,r3
		bf	.lwr_yvld
		bra	.lwr_ynxt
		sub	r9,r3
.lwr_yvld:
		mov	r3,r0
		mov.w	r0,@(mbg_yinc_d,r14)

	; r1 - X bg pos
	; r2 - Y bg pos
	; r3 - Framebuffer BASE
	; r4 - Y FB pos &BLKSIZE
	; Set X/Y framebuffer blocks
		mov.w	@(mbg_fbpos_y,r14),r0
		mov	r0,r4
		mov	@(mbg_fbpos,r14),r3
		and	r6,r4
		and	r6,r3
		and	r6,r2
		and	r6,r1
		mov	#0,r6
.nxt_y:
		cmp/ge	r8,r4
		bf	.nxt_y_l
		sub	r8,r4
.nxt_y_l:
		cmp/ge	r9,r2		; Y limiters
		bf	.ybg_l
		sub	r9,r2
.ybg_l:
		mov	r6,@-r15
		mov	r3,@-r15
		mov	r1,@-r15
		mov	#0,r6
.nxt_x:
		cmp/ge	r11,r1		; X pixel-data wrap
		bf	.xbg_l
		sub	r11,r1
.xbg_l:
		cmp/ge	r5,r3
		bf	.nxt_x_l
		sub	r5,r3
.nxt_x_l:
		bsr	.mk_piece
		nop
		add	r7,r3
		add	r7,r6
		cmp/ge	r10,r6
		bf/s	.nxt_x
		add	r7,r1

		mov	@r15+,r1
		mov	@r15+,r3
		mov	@r15+,r6

		add	r7,r4
		add	r7,r2
		add 	r7,r6
		cmp/ge	r8,r6
		bf	.nxt_y


.no_data:
		lds	@r15+,pr
		rts
		nop
		align 4

	; r1 - X bg pos
	; r2 - Y bg pos
	; r3 - Framebuffer BASE
	; r4 - Y FB pos &BLKSIZE
	; Set X/Y framebuffer blocks
.mk_piece:
		mov	r1,@-r15
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r6,@-r15
		mov	r5,@-r15
		mov	r8,@-r15
		mov	r9,@-r15

		mov	r13,r8		; BG X/Y add
		mulu	r11,r2
		sts	macl,r0
		add	r0,r8
		add	r1,r8
		mulu	r4,r10		; Framebuffer X/Y add
		sts	macl,r9
		add	r3,r9

		mov	r7,r2
.yblk_loopn:
		cmp/ge	r5,r9
		bf	.ymax
		sub	r5,r9
.ymax:
		mov	r7,r3
		shlr2	r3
		mov	r8,r4
		mov	r9,r6
.nxtlng:
		mov	@r4,r0
		mov	r6,r1
		add	r12,r1
		mov	r0,@r1
		mov	#320,r1
		cmp/gt	r1,r6
		bt	.hdnpos
		mov	r6,r1
		add	r5,r1
		add	r12,r1
		mov	r0,@r1
.hdnpos:
		add	#4,r6
		dt	r3
		bf/s	.nxtlng
		add	#4,r4

		add	r11,r8	; TODO
		dt	r2
		bf/s	.yblk_loopn
		add	r10,r9
.yblk_ex:
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r5
		mov	@r15+,r6
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		mov	@r15+,r1
		rts
		nop
		align 4
		ltorg
		align 4

; --------------------------------------------------------
; MarsVideo_BgDrawLR
;
; Draws the left and right sides of the background on
; movement
; --------------------------------------------------------

MarsVideo_BgDrawLR:
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	@(mbg_data,r14),r0
		cmp/pl	r0
		bf	.nxt_drawud
		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r13
		mov.w	@(mbg_intrl_blk,r14),r0
		neg	r0,r4
		shlr2	r0
		mov	r0,r12
		mov	#Cach_BgFbPos_H,r11
		mov	@r11,r11
		mov	#Cach_BgFbPos_V,r3
		mov	@r3,r3
		mov.w	@(mbg_intrl_w,r14),r0
		muls	r3,r0
		sts	macl,r0
		add	r0,r11
		mov	@(mbg_intrl_size,r14),r10
		mov	@(mbg_fbdata,r14),r9
		mov	#_framebuffer,r0
		add	r0,r9
		mov	@(mbg_data,r14),r0
		mov	r0,r8
		mov	r0,r7
		mov.w	@(mbg_height,r14),r0
		mov	r0,r6
		mov.w	@(mbg_width,r14),r0
		mulu	r6,r0
		sts	macl,r6
		add	r7,r6
		mov	r0,r3
		mov	#Cach_YHead_U,r0
		mov	@r0,r0
		mulu	r3,r0
		sts	macl,r0
		add	r0,r8
		mov.w	@(marsGbl_BgDrwR,gbr),r0
		cmp/eq	#0,r0
		bf	.dtsk01_dright
		mov.w	@(marsGbl_BgDrwL,gbr),r0
		cmp/eq	#0,r0
		bf	.dtsk01_dleft
.nxt_drawud:
		rts
		nop
		align 4

.dtsk01_dleft:
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwL,gbr)
		mov	#Cach_XHead_L,r0
		mov	@r0,r0
		bra	dtsk01_lrdraw
		mov	r0,r5
.dtsk01_dright:
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwR,gbr)
		mov	#320,r3			; Set FB position
		mov.b	@(mbg_flags,r14),r0
		and	#%10,r0
		tst	r0,r0
		bt	.indxmode
		shll	r3
.indxmode:
		add	r3,r11
		and	r4,r11
		mov	#Cach_XHead_R,r0
		mov	@r0,r0
		bra	dtsk01_lrdraw
		mov	r0,r5
		align 4
		ltorg
		align 4

	; r13 - Y lines
	; r12 - X block width
	; r11 - drawzone pos
	; r10 - drawzone size
	;  r9 - Framebuffer BASE
	;  r8 - Pixeldata Y-Current
	;  r7 - Pixeldata Y-Start
	;  r6 - Pixeldata Y-End
	;  r5 - Xadd
dtsk01_lrdraw:
		cmp/ge	r6,r8
		bf	.yres
		mov	r7,r8
.yres:
		mov	r12,r4
		mov	r11,r3
		mov	r8,r2
		add	r5,r2
; X draw
.xline:
		cmp/ge	r10,r3
		bf	.prefix_r
		sub	r10,r3
		mov	r3,r11
.prefix_r:
		mov	r3,r1
		add	r9,r1
		mov	@r2,r0
		mov	r0,@r1
		mov	#320,r1			; Hidden line
		mov.b	@(mbg_flags,r14),r0
		and	#%10,r0
		tst	r0,r0
		bt	.indxmode
		shll	r1
.indxmode:
		cmp/gt	r1,r3
		bt	.not_l2
		mov	r3,r1
		add	r9,r1
		add	r10,r1
		mov	@r2,r0
		mov	r0,@r1
.not_l2:
		add	#4,r2
		dt	r4
		bf/s	.xline
		add	#4,r3
		mov.w	@(mbg_width,r14),r0
		add	r0,r8
		mov.w	@(mbg_intrl_w,r14),r0
		dt	r13
		bf/s	dtsk01_lrdraw
		add	r0,r11
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsVideo_BgDrawLR
;
; Draws the top and bottom sides of the background on
; movement
; --------------------------------------------------------

MarsVideo_BgDrawUD:
		mov	@(mbg_fbdata,r14),r13
		mov	#_framebuffer,r0
		add	r0,r13
		mov	@(mbg_data,r14),r0
		mov	r0,r11
		mov	r0,r12
		mov	#Cach_BgFbPos_H,r0
		mov	@r0,r10
		mov	#Cach_BgFbPos_V,r0
		mov	@r0,r9
		mov	@(mbg_intrl_size,r14),r8
		mov.w	@(mbg_width,r14),r0
		mov	r0,r7
; 		mov.b	@(mbg_flags,r14),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bt	.indxmodew
; 		shll	r7
; .indxmodew:
		mov	#Cach_XHead_L,r0
		mov	@r0,r0
		add	r0,r12
		mov	r9,r6

		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r5
		mov	r0,r4
		mov.w	@(mbg_intrl_blk,r14),r0
		sub	r0,r4
		add	r4,r6
.wrpagain:	cmp/gt	r5,r6
		bf	.upwrp
		bra	.wrpagain
		sub	r5,r6
.upwrp:
; 		mov	#Cach_Drw_U,r1
; 		mov	#Cach_Drw_D,r2
		mov.w	@(marsGbl_BgDrwU,gbr),r0
		cmp/eq	#0,r0
		bf	.tsk00_up
		mov.w	@(marsGbl_BgDrwD,gbr),r0
		cmp/eq	#0,r0
		bt	drw_ud_exit
.tsk00_down:
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwD,gbr)

		mov	#Cach_YHead_D,r0
		mov	@r0,r0
		mulu	r7,r0
		sts	macl,r0
		add	r0,r12
		add	r0,r11
		bra	.do_updown
		mov	r6,r9
.tsk00_up:
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwU,gbr)
		mov	#Cach_YHead_U,r0
		mov	@r0,r0
		mulu	r7,r0
		sts	macl,r0
		add	r0,r12
		add	r0,r11

	; Main U/D loop
	; r12 - pixel-data current pos
	; r11 - pixel-data loop pos
	; r10 - Internal scroll TOPLEFT
	; r9 - Internal scroll Y-add
	; r8 - Internal scroll drawarea size
	; r7 - pixel-data WIDTH
.do_updown:
		mov.w	@(mbg_intrl_w,r14),r0
		mulu	r9,r0
		sts	macl,r0
		add	r0,r10
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r6
.y_loop:
		mov	r12,r3
		mov	r11,r4
		add	r7,r4
		mov.w	@(mbg_intrl_w,r14),r0	; WIDTH / 4
		shlr2	r0
		mov	r0,r5
.x_loop:
		cmp/ge	r8,r10			; topleft fb pos
		bf	.lwrfb
		sub	r8,r10
.lwrfb:
		cmp/ge	r4,r3
		bf	.srclow
		mov	r11,r3
.srclow:
		mov	@r3+,r1
		mov	r10,r2
		add	r13,r2
		mov	r1,r0
		mov	r0,@r2

		mov	#320,r2			; Hidden line
		mov.b	@(mbg_flags,r14),r0
		and	#%10,r0
		tst	r0,r0
		bt	.indxmode
		shll	r2
.indxmode:
		cmp/gt	r2,r10
		bt	.hdnx
		mov	r10,r2
		add	r13,r2
		add	r8,r2
		mov	r1,r0
		mov	r0,@r2
.hdnx:
		dt	r5
		bf/s	.x_loop
		add	#4,r10
		add	r7,r11			; Next SRC Y
		dt	r6
		bf/s	.y_loop
		add	r7,r12
drw_ud_exit:
		rts
		nop
		align 4
		ltorg
		align 4

; --------------------------------------------------------
; MarsVideo_MoveBg
;
; This updates the background's X/Y position
; --------------------------------------------------------

MarsVideo_MoveBg:
		mov	#RAM_Mars_BgBuffScrl,r14
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

; 		mov	#Cach_Drw_U,r8
; 		mov	#Cach_Drw_D,r9
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
		mov.w	@(marsGbl_BgDrwU,gbr),r0
		mov	r0,r4
		mov.w	@(marsGbl_BgDrwD,gbr),r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydr_busy
		mov	#2,r0
		mov.w	r0,@(marsGbl_BgDrwD,gbr)
		add	#$01,r5
.reqd_b:
		cmp/pz	r2
		bt	.ydr_busy
		mov.w	@(marsGbl_BgDrwU,gbr),r0
		mov	r0,r4
		mov.w	@(marsGbl_BgDrwD,gbr),r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydr_busy
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
		mov.w	@(marsGbl_BgDrwL,gbr),r0
		mov	r0,r4
		mov.w	@(marsGbl_BgDrwR,gbr),r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydl_busy
		mov	#2,r0
		mov.w	r0,@(marsGbl_BgDrwR,gbr)
		add	#$02,r5
.reqr_b:
		cmp/pz	r1
		bt	.ydl_busy
		mov.w	@(marsGbl_BgDrwL,gbr),r0
		mov	r0,r4
		mov.w	@(marsGbl_BgDrwR,gbr),r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydl_busy
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
		align 4
