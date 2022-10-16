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

; SDRAM
MAX_SCRNBUFF	equ $2C000	; MAX SDRAM for each Screen mode
MAX_SSPRSPD	equ 4		; Supersprite box increment: Size+this (maximum SuSprites speed)
MAX_FACES	equ 500		; MAX polygon faces for 3D models
MAX_SVDP_PZ	equ 500+64	; MAX polygon pieces to draw
MAX_ZDIST	equ -$F80	; Maximum 3D field distance (-Z)

; FRAMEBUFFER
FBVRAM_BLANK	equ $1F800	; Location for the BLANK line
FBVRAM_PATCH	equ $1D000	; Framebuffer location for the affected XShift lines

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
scrl_xpos_old	ds.l 1		; OLD Xpos position
scrl_ypos_old	ds.l 1		; OLD Ypos position
scrl_xset	ds.l 1		; Scroll X counter
scrl_yset	ds.l 1		; Scroll Y counter
scrl_blksize	ds.l 1		; Block size for scrolling
scrl_intrl_size	ds.l 1		; Internal scroll FULL size (scrl_intrl_w*scrl_intrl_h)
scrl_intrl_w	ds.l 1		; Internal scroll Width (MUST be larger than 320)
scrl_intrl_h	ds.l 1		; Internal scroll Height
scrl_fbpos_y	ds.l 1		; Screen's Y position
scrl_fbpos	ds.l 1		; Screen's TOP-LEFT position
scrl_fbdata	ds.l 1		; Screen data location on framebuffer
scrl_xpos	ds.l 1		; $0000.0000
scrl_ypos	ds.l 1		; $0000.0000
sizeof_mscrl	ds.l 0
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

; Polygon data
; Size: $38
		struct 0
polygn_type	ds.l 1		; %MSww wwww aaaa aaaa | %MS w-Texture width, a-Pixel increment
polygn_mtrl	ds.l 1		; Material Type: Color (0-255) or Texture data address
polygn_points	ds.l 4*2	; X/Y positions
polygn_srcpnts	ds.w 4*2	; X/Y texture points 16-bit, Ignored on solid color.
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
		mov	#FBVRAM_BLANK/2,r0	; The very last usable (blank) line.
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
; --------------------------------------------------------

; TODO: Fix this.

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
; line (FBVRAM_BLANK)
;
; Breaks:
; r1-r2
; --------------------------------------------------------

MarsVideo_ResetNameTbl:
		mov	#_framebuffer,r1
		mov	#FBVRAM_BLANK,r0
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
		mov.b	@(bitmapmd,r5),r0
		and	#%11,r0
		cmp/eq	#3,r0			; Don't mess with the RLE lines.
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
; Fix the affected $xxFF lines
;
; Input:
; r1 | Start line
; r2 | Number of lines
; r3 | Location for the fixed lines
;
; Break:
; r7-r14
; --------------------------------------------------------

; TODO: Check this later.

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
; Routines that write to the framebuffer are
; located at cache_m_2D.asm
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_MkScrlField
;
; This builds a new internal scrolling background
;
; Input:
; r1 | Background buffer to initialize
; r2 | Framebuffer VRAM position
; r3 | Scroll Width (320 or large)
; r4 | Scroll Height
; r5 | Scroll block size (4 pixels minimum)
; r6 | X start
; r7 | Y start
;
; NOTE:
; At the very last scrollable line: The next 320
; pixels will be visible until that line resets
; into 0 again.
; When you write pixels in in the range of 0-320,
; write the same pixels at the very end of
; the scrolling area (add width*height)
;
; Breaks:
; r3-r5,macl
; --------------------------------------------------------

		align 4
MarsVideo_MkScrlField:
		mov	#sizeof_mscrl,r0
		mulu	r0,r1
		sts	macl,r1
		mov	#RAM_Mars_ScrlBuff,r0
		add	r0,r1

		mov	r5,@(scrl_blksize,r1)
		add	r5,r3	; add "block"
		mov	r2,@(scrl_fbdata,r1)
		add	r5,r4
		mov	r3,@(scrl_intrl_w,r1)
		mulu	r3,r4
		mov	r4,@(scrl_intrl_h,r1)
		sts	macl,r0
		mov	r0,@(scrl_intrl_size,r1)
		xor	r0,r0
		mov	r0,@(scrl_xpos_old,r1)
		mov	r0,@(scrl_ypos_old,r1)
		mov	r0,@(scrl_fbpos,r1)
		mov	r0,@(scrl_fbpos_y,r1)
		mov	r0,@(scrl_xset,r1)
		mov	r0,@(scrl_yset,r1)
		rts
		nop
		align 4

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
		mov	#0,r11				; r11 - line counter
		mov	@(scrl_fbdata,r1),r13		; r13 - Framebuffer pixeldata position
		mov	r2,r6
		mov	@(scrl_intrl_size,r1),r12	; r12 - Full size of screen-scroll
		mov	r2,r0
		mov	@(scrl_intrl_w,r1),r10		; r10 - Next line to add
		shll	r0
		mov	@(scrl_fbpos,r1),r7
		add	r0,r14
		mov	@(scrl_fbpos_y,r1),r0
		mulu	r10,r0
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
; MarsVideo_Bg_UpdPos
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
MarsVideo_Bg_UpdPos:
		mov	#0,r1
		mov	#0,r2
		mov	@(scrl_xpos,r13),r0		; 0000.0000
		shlr16	r0				; **
		mov.w	r0,@(marsGbl_XShift,gbr)	; ** Grab missing bit for xshift
		exts.w	r0,r0
		mov	r0,r3
		mov	@(scrl_xpos_old,r13),r0
		cmp/eq	r0,r3
		bt	.xequ
		mov	r3,r1
		sub	r0,r1
.xequ:
		mov	r3,r0
		mov	r0,@(scrl_xpos_old,r13)
		mov	@(scrl_ypos,r13),r0	; 0000.0000
		shlr16	r0
		exts.w	r0,r0
		mov	r0,r3
		mov	@(scrl_ypos_old,r13),r0
		cmp/eq	r0,r3
		bt	.yequ
		mov	r3,r2
		sub	r0,r2
.yequ:
		mov	r3,r0
		mov	r0,@(scrl_ypos_old,r13)
		exts.w	r1,r1			; r1 - X increment
		exts.w	r2,r2			; r2 - Y increment

	; ---------------------------------------
	; Increment Y pos (REAL)
	; ---------------------------------------

		mov	@(scrl_fbpos_y,r13),r4
		add	r2,r4
		mov	@(scrl_intrl_h,r13),r3
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
		mov	r4,@(scrl_fbpos_y,r13)

	; ---------------------------------------
	; Update Framebuffer top-left position
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
;  r1 | X increment
;  r2 | Y increment
; r14 | Genesis background buffer
; r13 | Scrolling-area buffer
;
; Breaks:
; ALL
; --------------------------------------------------------

		align 4
MarsVideo_Bg_DrawReq:
; 		sts	pr,@-r15

	; ---------------------------------------
	; Set block update timers
	; ---------------------------------------

	; X timers
		mov	#2,r7
		mov	#Cach_DrawTimers,r8
		mov	r8,r5
		mov	@(scrl_blksize,r13),r6
		mov	r6,r4
		dt	r4
		neg	r6,r6
		mov	@(scrl_xset,r13),r3
		add	r1,r3
		mov	r3,r0
		and	r6,r0
		tst	r0,r0
		bt	.x_k
		cmp/pz	r1
		bt	.x_r
		add	#4,r5
.x_r:
		mov	r7,@r5
		and	r4,r3
.x_k:
		mov	r3,@(scrl_xset,r13)
	; Y timers
		add	#8,r8
		mov	r8,r5
		mov	@(scrl_yset,r13),r3
		add	r2,r3
		mov	r3,r0
		and	r6,r0
		tst	r0,r0
		bt	.y_k
		cmp/pz	r2
		bt	.y_r
		add	#4,r5
.y_r:
		mov	r7,@r5
		and	r4,r3
.y_k:
		mov	r3,@(scrl_yset,r13)

		rts
		nop
		align 4


; 		mov	#Cach_DrawTimers,r2
; 		mov.b	@(md_bg_flags,r14),r0
; 		extu.b	r0,r0
; ; 		and	#$FF,r0
; 		mov	r2,r1			; Set NEW screen timers ($02)
; 		mov	#2,r3
; 		tst	#%00000001,r0		; bitDrwR
; 		bt	.no_r
; 		mov	r3,@r1
; .no_r:
; 		add	#4,r1
; 		tst	#%00000010,r0		; bitDrwL
; 		bt	.no_l
; 		mov	r3,@r1
; .no_l:
; 		add	#4,r1
; 		tst	#%00000100,r0		; bitDrwD
; 		bt	.no_d
; 		mov	r3,@r1
; .no_d:
; 		add	#4,r1
; 		tst	#%00001000,r0		; bitDrwU
; 		bt	.no_upd
; 		mov	r3,@r1
; .no_upd:
; 		nop

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

; 		mov	@(md_bg_low,r14),r12
; 		mov	#Cach_WdgBuffWr,r3
; 		mov	@(scrl_fbpos,r13),r11
; 		mov	#-16,r1				; <-- (-)manual block size
; 		mov.w	@(md_bg_w,r14),r0
; 		extu.w	r0,r10
; 		mov	@(scrl_intrl_w,r13),r9
; 		mov	#((224+16)/16),r5		; Timer for L/R
; 		mov	@(scrl_intrl_size,r13),r8
; 		mov	@(md_bg_blk,r14),r6
; 		and	r1,r11
; 		mov	@(scrl_fbpos_y,r13),r0
; 		and	r1,r0
; 		mov	@(scrl_fbdata,r13),r7
; 		mulu	r0,r9
; 		sts	macl,r0
; 		add	r0,r11
; 		lds	r3,mach
;
; 	; L/R columns
; 		mov	r12,r13				; <-- copy layout
; 		mov.w	@(md_bg_yinc_u,r14),r0		; Move top Y
; 		exts.w	r0,r0
; 		mov	#16,r1				; <-- manual block size
; 		muls	r1,r0
; 		sts	macl,r0
; 		shlr8	r0
; 		exts.w	r0,r0
; 		muls	r10,r0
; 		sts	macl,r0
; 		add	r0,r12
; 		mov.w	@(md_bg_xinc_r,r14),r0
; 		mov	#320,r4				; r4 - X increment
; 		bsr	.x_draw
; 		exts.w	r0,r3
; 		mov.w	@(md_bg_xinc_l,r14),r0
; 		exts.w	r0,r3
; 		mov	#0,r4
; 		bsr	.x_draw
; 		add	#4,r2
;
; 	; U/D rows
; 		mov	#((320+16)/16),r5		; Timer for U/D
; 		mov	r13,r12
; 		add	#4,r2				; Now check D/U timers
; 		sts	mach,r0
; 		add	#$20,r0
; 		lds	r0,mach
; 		mov.w	@(md_bg_xinc_l,r14),r0		; Move left
; 		exts.w	r0,r0
; 		mov	#16,r1				; <-- manual block size
; 		muls	r1,r0
; 		sts	macl,r0
; 		shlr8	r0
; 		exts.w	r0,r0
; 		add	r0,r12
; 		mov.w	@(md_bg_yinc_d,r14),r0
; 		mov	#224,r4
; 		bsr	.y_draw
; 		exts.w	r0,r3
; 		mov.w	@(md_bg_yinc_u,r14),r0
; 		extu.w	r0,r3
; 		mov	#0,r4
; 		bsr	.y_draw
; 		add	#4,r2
;
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4

; ----------------------------------------

; ; r3 - layout X increment
; ; r4 - framebuffer X increment
; ; mach - Cach_WdgBuffWr
;
; .x_draw:
; 		mov	@r2,r0
; 		tst	r0,r0
; 		bt	.no_timer
; 		dt	r0
; 		mov	r0,@r2
;
; 		mov	#16,r1		; <-- manual block size
; 		muls	r1,r3		; r3 - layout increment
; 		sts	macl,r3
; 		shlr8	r3
; 		mov	r11,r1
; 		add	r4,r1
; 		cmp/ge	r8,r1
; 		bf	.sz_safe
; 		sub	r8,r1
; .sz_safe:
; 		sts	mach,r0
; 		mov	r5,@-r0
; 		mov	r6,@-r0
; 		mov	r7,@-r0
; 		mov	r8,@-r0
; 		mov	r9,@-r0
; 		mov	r10,@-r0
; 		mov	 r1,@-r0	; <-- copy of r11
; 		mov	r12,r1		; <-- layout + X pos
; 		add	 r3,r1
; 		mov	 r1,@-r0
; .no_timer:
; 		rts
; 		nop
; 		align 4
;
; ; ----------------------------------------
;
; ; r3 - layout Y increment
; ; r4 - framebuffer Y increment
; ; mach - Cach_WdgBuffWr_UD
;
; .y_draw:
; 		mov	@r2,r0
; 		tst	r0,r0
; 		bt	.no_timer
; 		dt	r0
; 		mov	r0,@r2
;
; 		mov	#16,r1		; <-- manual block size
; 		muls	r1,r3		; r3 - layout increment
; 		sts	macl,r3
; 		shlr8	r3
; 		mulu	r10,r3
; 		sts	macl,r3
;
; 		mov	r11,r1
; 		mulu	r9,r4
; 		sts	macl,r0
; 		add	r0,r1
; 		cmp/ge	r8,r1
; 		bf	.sz_safey
; 		sub	r8,r1
; .sz_safey:
; 		sts	mach,r0
; 		mov	r5,@-r0
; 		mov	r6,@-r0
; 		mov	r7,@-r0
; 		mov	r8,@-r0
; 		mov	r9,@-r0
; 		mov	r10,@-r0
; 		mov	 r1,@-r0	; <-- copy of r11
; 		mov	r12,r1		; <-- layout + Y pos
; 		add	 r3,r1
; 		mov	 r1,@-r0
; 		rts
; 		nop
; 		align 4
; 		ltorg

; --------------------------------------------------------
; MarsVideo_DmaDraw
;
; Input:
; r1 - Source
; r2 - Destination
; r3 - Size / 4
; --------------------------------------------------------

		align 4
MarsVideo_DmaDraw:
		mov	#_DMAOPERATION,r5
		mov	#_DMASOURCE1,r4
		mov	#0,r0
		mov	r0,@r5
		mov	#%0101101011100000,r0
		mov	r0,@($0C,r4)
		mov	r1,r0
		mov	r0,@r4
		mov	r2,r0			; <-- point fbdata here
		mov	r0,@($04,r4)
		mov	r3,r0
		mov	r0,@($08,r4)
		mov	#%0101101011100001,r0
		mov	r0,@($0C,r4)
		mov	#1,r0
		mov	r0,@r5
.wait_dma:	mov	@($C,r4),r0		; Still on DMA?
		tst	#%10,r0
		bt	.wait_dma
		mov	#0,r0
		mov	r0,@r5
		mov	#%0101101011100000,r0
		mov	r0,@($C,r4)
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------
; MarsVideo_Bg_DrawScrl
;
; Input:
; r14 | Background buffer
; r13 | Scrolling-area buffer
; r12 | Draw timers
;
; Breaks:
; ALL
; --------------------------------------------------------

		align 4
MarsVideo_Bg_DrawScrl:
		sts	pr,@-r15

		mov	#_framebuffer,r0
		mov	@(scrl_fbdata,r13),r1
		add	r0,r1
		mov	@(scrl_intrl_w,r13),r11		; r11 - FB width
		lds	r1,mach				; mach - FB base
		mov	@(scrl_fbpos_y,r13),r0
		mov	#-$10,r1			; <-- CUSTOM BLOCK SIZE
		mov	@(scrl_fbpos,r13),r10		; r10 - FB x/y pos
		and	r1,r0
		mov	@(md_bg_blk,r14),r9		; r9 - Block data
		mulu	r0,r11
		mov.w	@(md_bg_w,r14),r0		; r7 - Layout increment
		extu.w	r0,r7
		mov	@(scrl_intrl_size,r13),r12	; r12 - FB full size
		sts	macl,r0
		add	r0,r10
		and	r1,r10
		mov	@(md_bg_low,r14),r8		; r8 - Layout data
		mov	#RAM_Mars_ScrlData,r13
		cmp/ge	r12,r10
		bf	.fb_y
		sub	r12,r10
.fb_y:
		mov	#Cach_DrawTimers,r1
		mov	@r1,r0
		tst	r0,r0
		bt	.no_r
		bsr	.draw_r
		nop
.no_r:
		mov	#Cach_DrawTimers+4,r1
		mov	@r1,r0
		tst	r0,r0
		bt	.no_l
		bsr	.draw_l
		nop
.no_l:
		mov	#Cach_DrawTimers+8,r1
		mov	@r1,r0
		tst	r0,r0
		bt	.no_d
		bsr	.draw_d
		nop
.no_d:
		mov	#Cach_DrawTimers+$C,r1
		mov	@r1,r0
		tst	r0,r0
		bt	.no_u
		bsr	.draw_u
		nop
.no_u:

		lds	@r15+,pr
		rts
		nop

; mach - FB base
; r13 - Background copy
; r12 - FB full size
; r11 - FB width
; r10 - FB x/y pos
; r9 - Block data
; r8 - Layout data
; r7 - Layout increment

; RIGHT/LEFT
.draw_r:
		dt	r0
		mov	r0,@r1
		mov.w	@(md_bg_xinc_r,r14),r0		; r7 - Layout increment
		exts.w	r0,r2
		mov	#320,r1
		bra	.go_lr
		nop
.draw_l:
		dt	r0
		mov	r0,@r1
		mov.w	@(md_bg_xinc_l,r14),r0		; r7 - Layout increment
		exts.w	r0,r2
		mov	#0,r1
.go_lr:
		mov	r10,r6
		add	r1,r6
; 		mov	#-$10,r0
; 		and	r0,r6		; r6 - curr out pos
		mov	r8,@-r15
		mov.w	@(md_bg_yinc_u,r14),r0		; r7 - Layout increment
		exts.w	r0,r1
		mov	#16,r3		; <-- MANUAL BLOCK SIZE
		mulu	r3,r1
		sts	macl,r0
		shlr8	r0
		mulu	r7,r0
		sts	macl,r0
		add	r0,r8
		mulu	r3,r2
		sts	macl,r0
		shlr8	r0
		add	r0,r8
		mov	#((224+16)/16),r1
.y_blk:
		mov	r1,@-r15
		mov	r9,r5
		mov.b	@r8,r0
		extu.b	r0,r0		; BYTE
		mov	#16*16,r3
		mulu	r3,r0
		sts	macl,r0
		mov	r9,r5
		add	r0,r5

		mov	#16,r3
.y_lne:
		cmp/ge	r12,r6
		bf	.y_res
		sub	r12,r6
.y_res:
		mov	#16/4,r4
.x_lne:
		mov	@r5+,r0
		lds	r0,macl
		sts	mach,r1
		add	r6,r1
		mov	r13,r2
		add	r6,r2
		mov	r0,@r1
		add	#4,r6
		mov	r0,@r2
		mov	#320,r0
		cmp/ge	r0,r6
		bt	.x_ex
		sts	macl,r0
		add	r12,r1
		mov	r0,@r1
		add	r12,r2
		mov	r0,@r2
		nop
.x_ex:
		dt	r4
		bf	.x_lne
		add	#-16,r6	; bring point back
		dt	r3
		bf/s	.y_lne
		add	r11,r6
		mov	@r15+,r1
		dt	r1
		bf/s	.y_blk
		add	r7,r8
		mov	@r15+,r8
		rts
		nop

; DOWN/UP
.draw_d:
		dt	r0
		mov	r0,@r1
		mov.w	@(md_bg_yinc_d,r14),r0		; r7 - Layout increment
		exts.w	r0,r2
		mov	#224,r1
		bra	.go_du
		nop
.draw_u:
		dt	r0
		mov	r0,@r1
		mov.w	@(md_bg_yinc_u,r14),r0		; r7 - Layout increment
		exts.w	r0,r2
		mov	#0,r1
.go_du:
		mulu	r1,r11
		sts	macl,r0
		mov	r10,r6
		add	r0,r6
; 		mov	#-$10,r0
; 		and	r0,r6			; r6 - curr out pos
		mov	r8,@-r15
		mov.w	@(md_bg_xinc_l,r14),r0		; r7 - Layout increment
		exts.w	r0,r1
		mov	#16,r3		; <-- MANUAL BLOCK SIZE
		mulu	r3,r1
		sts	macl,r0
		shlr8	r0
		add	r0,r8
		mulu	r3,r2
		sts	macl,r0
		shlr8	r0
		mulu	r7,r0
		sts	macl,r0
		add	r0,r8
		mov	#((320+16)/16),r1
.yd_blk:
		mov	r6,@-r15
		mov	r1,@-r15
		mov	r9,r5
		mov.b	@r8,r0
		extu.b	r0,r0		; BYTE
		mov	#16*16,r3
		mulu	r3,r0
		sts	macl,r0
		mov	r9,r5
		add	r0,r5
;
		mov	#16,r3
.yd_lne:
		cmp/ge	r12,r6
		bf	.yd_res
		sub	r12,r6
.yd_res:
		mov	#16/4,r4
.xd_lne:
		mov	@r5+,r0
		lds	r0,macl
		sts	mach,r1
		add	r6,r1
		mov	r13,r2
		add	r6,r2
		mov	r0,@r1
		add	#4,r6
		mov	r0,@r2
		mov	#320,r0
		cmp/ge	r0,r6
		bt	.xd_ex
		sts	macl,r0
		add	r12,r1
		mov	r0,@r1
		add	r12,r2
		mov	r0,@r2
		nop
.xd_ex:
		dt	r4
		bf	.xd_lne
		add	#-16,r6	; bring point back
		dt	r3
		bf/s	.yd_lne
		add	r11,r6

		mov	@r15+,r1
		mov	@r15+,r6
		mov	#16,r0
		add	r0,r6
		dt	r1
		bf/s	.yd_blk
		add	#1,r8
		mov	@r15+,r8
		rts
		nop

		align 4
		ltorg

; ; --------------------------------------------------------
; ; MarsVideo_Bg_DrawScrl_UD
; ;
; ; Input:
; ; r14 | Background buffer
; ; r13 | Scrolling-area buffer
; ; r12 | Draw timers
; ;
; ; Breaks:
; ; ALL
; ; --------------------------------------------------------
;
; 		align 4
; MarsVideo_Bg_DrawScrl_UD:
; 		sts	pr,@-r15
;
; 		mov	#_framebuffer,r0
; 		mov	@(scrl_fbdata,r13),r1
; 		add	r0,r1
; 		mov	@(scrl_intrl_w,r13),r11		; r11 - FB width
; 		lds	r1,mach				; mach - FB base
; 		mov	@(scrl_fbpos_y,r13),r0
; 		mov	#-$10,r1			; <-- CUSTOM BLOCK SIZE
; 		mov	@(scrl_fbpos,r13),r10		; r10 - FB x/y pos
; 		and	r1,r0
; 		mov	@(md_bg_blk,r14),r9		; r9 - Block data
; 		mulu	r0,r11
; 		mov.w	@(md_bg_w,r14),r0		; r7 - Layout increment
; 		extu.w	r0,r7
; 		mov	@(scrl_intrl_size,r13),r12	; r12 - FB full size
; 		sts	macl,r0
; 		add	r0,r10
; 		and	r1,r10
; 		mov	@(md_bg_low,r14),r8		; r8 - Layout data
; 		mov	#RAM_Mars_ScrlData,r13
; 		cmp/ge	r12,r10
; 		bf	.fb_y
; 		sub	r12,r10
; .fb_y:
; 		mov	#Cach_DrawTimers+8,r1
; 		mov	@r1,r0
; 		tst	r0,r0
; 		bt	.no_d
; 		bsr	.draw_d
; 		nop
; .no_d:
; 		mov	#Cach_DrawTimers+$C,r1
; 		mov	@r1,r0
; 		tst	r0,r0
; 		bt	.no_u
; 		bsr	.draw_u
; 		nop
; .no_u:
; 		lds	@r15+,pr
; 		rts
; 		nop
; ; DOWN/UP
; .draw_d:
; 		dt	r0
; 		mov	r0,@r1
; 		mov.w	@(md_bg_yinc_d,r14),r0		; r7 - Layout increment
; 		exts.w	r0,r2
; 		mov	#224,r1
; 		bra	.go_du
; 		nop
; .draw_u:
; 		dt	r0
; 		mov	r0,@r1
; 		mov.w	@(md_bg_yinc_u,r14),r0		; r7 - Layout increment
; 		exts.w	r0,r2
; 		mov	#0,r1
; .go_du:
; 		mulu	r1,r11
; 		sts	macl,r0
; 		mov	r10,r6
; 		add	r0,r6
; ; 		mov	#-$10,r0
; ; 		and	r0,r6			; r6 - curr out pos
; 		mov	r8,@-r15
; 		mov.w	@(md_bg_xinc_l,r14),r0		; r7 - Layout increment
; 		exts.w	r0,r1
; 		mov	#16,r3		; <-- MANUAL BLOCK SIZE
; 		mulu	r3,r1
; 		sts	macl,r0
; 		shlr8	r0
; 		add	r0,r8
; 		mulu	r3,r2
; 		sts	macl,r0
; 		shlr8	r0
; 		mulu	r7,r0
; 		sts	macl,r0
; 		add	r0,r8
; 		mov	#((320+16)/16),r1
; .yd_blk:
; 		mov	r6,@-r15
; 		mov	r1,@-r15
; 		mov	r9,r5
; 		mov.b	@r8,r0
; 		extu.b	r0,r0		; BYTE
; 		mov	#16*16,r3
; 		mulu	r3,r0
; 		sts	macl,r0
; 		mov	r9,r5
; 		add	r0,r5
; ;
; 		mov	#16,r3
; .yd_lne:
; 		cmp/ge	r12,r6
; 		bf	.yd_res
; 		sub	r12,r6
; .yd_res:
; 		mov	#16/4,r4
; .xd_lne:
; 		mov	@r5+,r0
; 		lds	r0,macl
; 		sts	mach,r1
; 		add	r6,r1
; 		mov	r13,r2
; 		add	r6,r2
; 		mov	r0,@r1
; 		add	#4,r6
; 		mov	r0,@r2
; 		mov	#320,r0
; 		cmp/ge	r0,r6
; 		bt	.xd_ex
; 		sts	macl,r0
; 		add	r12,r1
; 		mov	r0,@r1
; 		add	r12,r2
; 		mov	r0,@r2
; 		nop
; .xd_ex:
; 		dt	r4
; 		bf	.xd_lne
; 		add	#-16,r6	; bring point back
; 		dt	r3
; 		bf/s	.yd_lne
; 		add	r11,r6
;
; 		mov	@r15+,r1
; 		mov	@r15+,r6
; 		mov	#16,r0
; 		add	r0,r6
; 		dt	r1
; 		bf/s	.yd_blk
; 		add	#1,r8
; 		mov	@r15+,r8
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ----------------------------------------------------------------
; Super Sprites
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_MkSprCoords
;
; This creates a backup of the screen's position for
; the sprite-refill boxes
;
; Input:
; r1 - VRAM base
; r2 - X Top-Left position
; r3 - Y (real) position
; r4 - Scrolling area Width
; r5 - Scrolling area Height
; r6 - Scroll area size
; r7 - Output settings to this area
;
; Breaks:
; r7
; --------------------------------------------------------

		align 4
MarsVideo_MkSprCoords:
		add	#4,r7
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
; MarsVideo_MkSprBoxes
; --------------------------------------------------------

		align 4
MarsVideo_MkSprBoxes:
 		mov	#RAM_Mars_DreqRead+Dreq_SuperSpr,r14
		mov	#Cach_SprBoxList,r13
.next_save:
		mov	@(marsspr_data,r14),r0
		tst	r0,r0
		bt	.last
		mov	#MAX_SSPRSPD,r0		; expand box (max speed)
		mov	@(marsspr_x,r14),r5	; XXXX YYYY
		exts.w	r5,r6
		mov	@(marsspr_xfrm,r14),r7	; ?? ?? XX YY
		shlr16	r5
		exts.w	r5,r5
		extu.b	r7,r8
		shlr8	r7
		extu.b	r7,r7
		add	r5,r7
		add	r6,r8
; 		mov.w	@(marsspr_x,r14),r0
; 		exts.w	r0,r5
; 		mov.w	@(marsspr_y,r14),r0
; 		exts.w	r0,r6
; 		mov.b	@(marsspr_xs,r14),r0
; 		exts.b	r0,r7
; 		mov.b	@(marsspr_ys,r14),r0
; 		exts.b	r0,r8
; 		add	r5,r7
; 		add	r6,r8

		sub	r0,r5	; expand box
		sub	r0,r6
		add	r0,r7
		add	r0,r8
; 		shlr	r0
		add	r0,r7
; 		add	r0,r8
		mov	#-4,r0	; align by 4
		and	r0,r5
		and	r0,r7
		and	r0,r6
		and	r0,r8
		mov	#320+16,r1
		mov	#224+16,r2
		cmp/pl	r7
		bf	.spr_out
		cmp/pl	r8
		bf	.spr_out
		cmp/ge	r1,r5
		bt	.spr_out
		cmp/ge	r2,r6
		bt	.spr_out
		cmp/pz	r5
		bt	.xl_l
		xor	r5,r5
.xl_l:
		cmp/pz	r6
		bt	.yl_l
		xor	r6,r6
.yl_l:
		cmp/gt	r1,r7
		bf	.xr_l
		mov	r1,r7
.xr_l:
		cmp/gt	r2,r8
		bf	.yr_l
		mov	r2,r8
.yr_l:
		mulu	r11,r6
		sts	macl,r0
		add	r0,r4
.y_lp:
		cmp/gt	r12,r4
		bf	.y_keep
		sub	r12,r4
.y_keep:

	; r5 - X left
	; r6 - Y top
	; r7 - X right
	; r8 - Y bottom
	;
	; (Xend>>2)|$80,(Xstart>>2),Ybottom,Ytop
		mov	r7,r0
		shlr2	r0
		extu.b	r0,r0
		or	#$80,r0
		shll16	r0
		shll8	r0
		mov	r5,r2
		shll16	r2
		shlr2	r2
		mov	r0,r3
		mov	r6,r0
		mov	r8,r1
		extu.b	r1,r1
		shll8	r1
		and	#$FF,r0
		or	r3,r0
		or	r2,r0
		or	r1,r0
		mov	r0,@r13
		add	#4,r13
.spr_out:
		bra	.next_save
		add 	#sizeof_marsspr,r14
.last:
		rts
		nop
		align 4
		ltorg

; ; --------------------------------------------------------
; ; MarsVideo_DrawSuperSpr_M
; ;
; ; Draws the Super-sprites directly recieved on DREQ
; ;
; ; Call MarsVideo_MkSprCoords FIRST to setup the
; ; screen coordinates
; ;
; ; ** ONLY DRAWS THE TOP OF THE SCREEN, USE SLAVE
; ; SH2 TO DRAW FOR THE BOTTOM **
; ;
; ; Input:
; ; r14 - Super sprites data
; ;
; ; Breaks:
; ; ALL
; ; --------------------------------------------------------
;
; 		align 4
; MarsVideo_DrawSuperSpr_M:
; 		mov	#RAM_Mars_DreqRead+Dreq_SuperSpr,r14
; 		mov	#Cach_Intrl_W,r11
; 		mov	@r11,r11
; 		mov	#Cach_Intrl_Size,r10
; 		mov	@r10,r10
; 		nop
; MarsVideo_NxtSuprSpr:
; 		mov	@(marsspr_data,r14),r0
; 		tst	r0,r0
; 		bf	.valid
; 		rts
; 		nop
; 		align 4
; .valid:
; 		mov.w	@(marsspr_indx,r14),r0
; 		mov	r0,r12
; 		mov	@(marsspr_x,r14),r5	; XXXX YYYY
; 		exts.w	r5,r6
; 		mov	@(marsspr_xfrm,r14),r7	; ?? ?? XX YY
; 		shlr16	r5
; 		exts.w	r5,r5
; 		extu.b	r7,r8
; 		shlr8	r7
; 		extu.b	r7,r7
; ; 		mov.w	@(marsspr_x,r14),r0
; ; 		exts.w	r0,r5
; ; 		mov.w	@(marsspr_y,r14),r0
; ; 		exts.w	r0,r6
; ; 		mov.b	@(marsspr_xs,r14),r0
; ; 		exts.b	r0,r7
; ; 		mov.b	@(marsspr_ys,r14),r0
; ; 		exts.b	r0,r8
; 		mov	r7,r3			; Copy old XS / YS
; 		mov	r8,r4
; 		add	r5,r7
; 		add	r6,r8
;
; 		mov	#Cach_Intrl_H,r0
; 		mov	@r0,r0
; 		mov	#224,r0
; 		cmp/pl	r8
; 		bf	.spr_out
; 		cmp/pl	r7
; 		bf	.spr_out
; 		cmp/ge	r11,r5
; 		bt	.spr_out
; 		cmp/ge	r0,r6
; 		bt	.spr_out
; 	; XR / YB
; ; 		mov	#224,r0
; 		cmp/ge	r0,r8
; 		bf	.yb_e
; 		mov	r0,r8
; .yb_e:
; 		mov	#320,r0
; 		cmp/ge	r0,r7
; 		bf	.xb_e
; 		mov	r0,r7
; .xb_e:
;
; 		mov.w	@(marsspr_dwidth,r14),r0
; 		mov	r0,r1
; 		mov.w	@(marsspr_xfrm,r14),r0	; X frame
; 		mov	r0,r2
; 		mov	@(marsspr_data,r14),r13
; 		mulu	r1,r4
; 		sts	macl,r4
; 		extu.b	r0,r0
; 		mulu	r4,r0
; 		sts	macl,r0
; 		add	r0,r13
; 		mov	r2,r0
; 		shlr8	r0
; 		extu.b	r0,r0
; 		mulu	r3,r0
; 		sts	macl,r0
; 		add	r0,r13
;
; ; 		mov	#Cach_FbData,r2
; ; 		mov	@r2,r2
; ; 		mov	#_framebuffer,r0
; ; 		add	r2,r0
;
; 		mov	#RAM_Mars_SprData,r0
; 		lds	r0,mach
; 		mov.w	@(marsspr_dwidth,r14),r0
; 		extu.w	r0,r2
; 		mov.w	@(marsspr_flags,r14),r0
; 		tst	#%10,r0		; Y flip?
; 		bt	.flp_v
; 		add	r4,r13
; 		sub	r2,r13
; 		neg	r2,r2
; .flp_v:
; 		mov	#1,r4
; 		tst	#%01,r0		; X flip?
; 		bt	.flp_h
; 		add	r3,r13		; move beam
; 		mov	#-1,r4		; decrement line
; .flp_h:
; 		cmp/pz	r6
; 		bt	.yt_e
; 		neg	r6,r0
; 		xor	r6,r6
; 		muls	r0,r1
; 		sts	macl,r0
; 		cmp/pz	r2
; 		bt	.yfinc
; 		neg	r0,r0
; .yfinc:
; 		add	r0,r13
; .yt_e:
; 		cmp/pz	r5
; 		bt	.xt_e
; 		mov	r5,r9
; 		cmp/pz	r4
; 		bt	.xfinc
; 		neg	r9,r9
; .xfinc:
; 		sub	r9,r13
; 		xor	r5,r5
; .xt_e:
; 		extu.w	r4,r9
; 		shll16	r2
; 		or	r2,r9
; 		mov	#Cach_FbPos_Y,r4
; 		mov	#Cach_FbPos,r2
; 		mov	@r4,r4
; 		add	r6,r4
; ; 		cmp/ge	r10,r4
; ; 		bf	.y_snap
; ; 		sub	r10,r4
; ; .y_snap:
; 		mulu	r11,r4
; 		mov	@r2,r2
; 		sts	macl,r4
; 		add	r2,r4
;
; 	; mach - _framebuffer + base
; 	;  r14 - Sprite data
; 	;  r13 - Texture data
; 	;  r12 - Texture index
; 	;  r11 - Internal WIDTH
; 	;  r10 - Internal WIDTH+HEIGHT
; 	;   r9 - Spritesheet Ydraw direction | Xdraw direction
; 	;   r8 - Y End
; 	;   r7 - X End
; 	;   r6 - Y Start
; 	;   r5 - X Start
; 	;   r4 - FB output position
; 	;
; 	; *** start ***
; .y_loop:
; 		cmp/ge	r10,r4			; Wrap FB output
; 		bf	.y_max
; 		sub	r10,r4
; .y_max:
; 		mov	r13,r1			; r1 - Texture IN
; 		mov	r5,r2			; r2 - X counter
; .x_loop:
; 		sts	mach,r3			; r3 - Framebuffer + FbData
; 		add	r4,r3			; add top-left position
; 		add	r2,r3			; add X position
;
; 		mov.b	@r1,r0			; r0 - pixel
; 		tst	r0,r0			; blank pixel 0?
; 		bt	.blnk
; 		add	r12,r0			; add pixel increment
; .blnk:
; 		mov.b	r0,@r3			; Write pixel
; 		mov	#320,r0			; Check for hidden line (X < 320)
; 		cmp/ge	r2,r0
; 		bt	.ex_line
; 		mov.b	@r1,r0			; Repeat same thing but
; 		tst	r0,r0			; but add r12 to the
; 		bt	.blnk2			; destination
; 		add	r12,r0
; .blnk2:
; 		add	r10,r3
; 		mov.b	r0,@r3
; .ex_line:
; 		add	#1,r2			; Increment X pos
;
; 		mov	r9,r0
; 		exts.w	r0,r0
; 		cmp/ge	r7,r2
; 		bf/s	.x_loop
; 		add	r0,r1			; Increment texture pos
;
; 		mov	r9,r0
; 		shlr16	r0
; 		exts.w	r0,r0
; 		add	r0,r13			; Next texture line
; 		add	#1,r6			; Increment loop Y
; 		cmp/ge	r8,r6			; Y start > Y end?
; 		bf/s	.y_loop
; 		add	r11,r4			; Next FB top-left line
; .spr_out:
; 		bra	MarsVideo_NxtSuprSpr
; 		add 	#sizeof_marsspr,r14
; 		align 4
; 		ltorg
;
; ; --------------------------------------------------------
; ; MarsVideo_DrawBgSSpr
; ;
; ; Call this BEFORE updating Sprite info
; ; --------------------------------------------------------
;
; 		align 4
; MarsVideo_DrawBgSSpr:
; 		mov	#Cach_SprBoxList,r14
;
; 		mov	#Cach_Intrl_Size,r12
; 		mov	#Cach_FbPos,r10
; 		mov	#Cach_Intrl_W,r11
; 		mov	#Cach_FbPos_Y,r0
; 		mov	@r0,r0
; 		mov	#Cach_FbData,r9
; 		mov	@r9,r9
; 		mov	#_framebuffer,r1
; 		mov	@r11,r11
; 		mov	#-4,r2
; 		mov	@r10,r10
; 		add	r1,r9
; 		mov	@r12,r12
;
; ; 		mov	#RAM_Mars_ScrlBuff,r13
; ; 		mov	@(scrl_fbpos_y,r13),r0
; ; 		mov	#_framebuffer,r1
; ; 		mov	@(scrl_fbdata,r13),r9
; ; 		add	r1,r9
; ; 		mov	@(scrl_intrl_w,r13),r11
; ; 		mov	#-4,r2
; ; 		mov	@(scrl_fbpos,r13),r10
; ; 		and	r2,r0
; ; 		mov	@(scrl_intrl_size,r13),r12
;
; 		mulu	r0,r11
; 		sts	macl,r1
; 		mov	#RAM_Mars_ScrlData,r0
; 		add	r1,r10
; 		cmp/ge	r12,r10
; 		bf	.ygood
; 		sub	r12,r10
; .ygood:
; 		and	r2,r10
; 		lds	r0,mach
;
; .next_save:
; 		mov	@r14,r0
; 		cmp/pl	r0
; 		bt	.last
; 		mov	r10,r4
; 		mov	r0,r5
; 		mov	r0,r6
; 		mov	r0,r7
; 		mov	r0,r8
; 		xor	r0,r0
; 		mov	r0,@r14
; 		mov	#$7F,r0
; 		shlr16	r5
; 		shlr16	r7
; 		shlr8	r7
; 		and	r0,r5
; 		and	r0,r7
; 		shll2	r5
; 		shll2	r7
; 		shlr8	r8
; 		mov	#$FF,r0
; 		and	r0,r6
; 		and	r0,r8
; 		sub	r6,r8
; 		cmp/pl	r8
; 		bf	.spr_out
; 		mulu	r11,r6
; 		sts	macl,r0
; 		add	r0,r4
;
; 		mov	#320,r6
; .y_lp:
; 		mov	r5,r1
; 		mov	r4,r2
; 		add	r5,r2
; .x_lp:
; 		cmp/gt	r12,r2
; 		bf	.x_keep
; 		sub	r12,r2
; .x_keep:
; 		sts	mach,r13
; 		add	r2,r13
; 		mov	@r13+,r0
; ; 		or	r13,r0
;
; 		mov	r9,r3
; 		add	r2,r3
; 		mov	r0,@r3
; 		cmp/ge	r6,r2
; 		bt	.x_lrg
; 		add	r12,r3
; 		add	r12,r13
; 		mov	r0,@r3
; 		mov	r0,@r13
; .x_lrg:
; 		add	#4,r1
; 		cmp/ge	r7,r1
; 		bf/s	.x_lp
; 		add	#4,r2
; 		dt	r8
; 		bf/s	.y_lp
; 		add	r11,r4
; .spr_out:
; 		bra	.next_save
; 		add 	#4,r14
; .last:
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 3D Section
;
; Nothing to see here (yet), all stuff is
; located at cache_m_3D.asm
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsMdl_MdlLoop
;
; Call this to start building the 3D objects
; --------------------------------------------------------

		align 4
MarsMdl_MdlLoop:
		sts	pr,@-r15
		mov	#0,r11
		mov 	#RAM_Mars_Polygons_0,r13
		mov	#RAM_Mars_PlgnList_0,r1
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bt	.go_mdl
		mov 	#RAM_Mars_Polygons_1,r13
		mov	#RAM_Mars_PlgnList_1,r1
.go_mdl:
		mov	r1,r0
		mov	r0,@(marsGbl_CurrZList,gbr)
		mov	r0,@(marsGbl_CurrZTop,gbr)
		xor	r0,r0
		mov.w	r0,@(marsGbl_CurrNumFaces,gbr)
		mov	#RAM_Mars_DreqRead+Dreq_Objects,r14	; Copy CAMERA and OBJECTS for Slave
		mov	#MAX_MODELS,r10
.loop:
		mov	@(mdl_data,r14),r0		; Object model data == 0 or -1?
		cmp/pl	r0
		bf	.invlid
		mov	#MarsMdl_ReadModel,r0
		jsr	@r0
		mov	r10,@-r15
		mov	@r15+,r10
.invlid:
		dt	r10
		bf/s	.loop
		add	#sizeof_mdlobj,r14
.skip:
; 		mov 	#RAM_Mars_PlgnNum_0,r1
; 		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
; 		tst     #1,r0
; 		bt	.page_2
; 		mov 	#RAM_Mars_PlgnNum_1,r1
; .page_2:
; 		mov.w	@(marsGbl_CurrNumFaces,gbr),r0	; Ran out of space to store faces?
; 		mov	r0,@r1
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Read model
;
; r14 - Current model data
; r13 - Current polygon
; r12 - Z storage
; r11 - Used faces counter
; ------------------------------------------------

; 		dc.w 1,4
; 		dc.l .vert,.face,.vrtx,.mtrl
; .vert:	binclude "data/mars/objects/mdl/test/vert.bin"
; .face:	binclude "data/mars/objects/mdl/test/face.bin"
; .vrtx:	binclude "data/mars/objects/mdl/test/vrtx.bin"
; .mtrl:	include "data/mars/objects/mdl/test/mtrl.asm"
;
		align 4
; MarsMdl_ReadModel:
; 		sts	pr,@-r15
; 		mov	#RAM_Mars_ZStorage,r12
; 		mov	@(mdl_data,r14),r10	; r10 - Model header
; 		nop
; 		mov.w	@r10,r9			;  r9 - Number of polygons of this model
; 		extu.w	r9,r9
; 		mov 	@(8,r10),r8		; r11 - face data
; 		nop
; .next_face:
; 		mov.w	@r8+,r0
; 		mov	r0,r6			; r6 - Face type
; 		mov	#4,r7			; r7 - number of vertx (quad or tri)
; 		shlr8	r0			;
; 		tst	#PLGN_TRI,r0
; 		bt	.quad			; bit 0 = quad
; 		dt	r7
; .quad:
; 		cmp/pl	r6			; Solid or texture? ($8xxx)
; 		bf	.has_uv
;
; ; --------------------------------
; ; Face is solid color
;
; 		bra	.mk_face
; 		nop
;
; ; --------------------------------
; ; Face has UV settings
;
; .has_uv:
; 		mov	@($C,r10),r1		; r1 - Grab UV points
; 		mov	r7,r0
; 		mov	r13,r2			; r2 - Output to polygon
; 		add	#polygn_srcpnts,r2
; 		cmp/eq	#3,r0			; Polygon is tri?
; 		bt	.uv_tri
; 		mov.w	@r8+,r0			; Do extra quad point
; 		extu.w	r0,r0
; 		shll2	r0
; 		mov	@(r1,r0),r0
; 		mov	r0,@r2
; 		add	#4,r2
; .uv_tri:
; 	rept 3					; Grab UV points 3 times
; 		mov.w	@r8+,r0
; 		extu.w	r0,r0
; 		shll2	r0
; 		mov	@(r1,r0),r0
; 		mov	r0,@r2
; 		add	#4,r2
; 	endm
; 		mov	@($10,r10),r1		; r1 - Read material list
; 		mov	r6,r0			; r0 - Material slot
; 		and	#$FF,r0
; 		shll2	r0			; *8
; 		shll	r0
; 		add	r0,r1			; Increment r1 into mtrl slot
; 		mov	#%01100000,r3
; 		shll	r3
; 		shll8	r3			; r1 - AND $C0 value
; 		mov	r6,r2
; 		and	r2,r2			; r0 - Grab settings, move to long MSB
; 		shll16	r2
;
; 		mov	@r1,r0			; Pick texture ROM pointer
; 		mov	r0,@(polygn_mtrl,r13)
; 		mov
;
; 		bra *
; 		add	#8,r8

; 		mov	@(mdl_option,r14),r0
; 		mov	#-1,r5
; 		extu.b	r5,r5			; $FF

; 		extu.b	r0,r0
; 		mov	r0,r1
; 		mov	r4,r0	; ID
; 		and	r5,r0
; 		shll2	r0
; 		mov	@($10,r12),r6
; 		shll	r0
; 		add	r0,r6
; ; 		mov	#$C000,r0
; 		mov	#$60,r0		; grab special bits ($C000)
; 		shll	r0
; 		shll8	r0
; 		and	r0,r4
; 		shll16	r4
; 		mov	@(4,r6),r0
; 		or	r0,r4
; 		add	r1,r4
; 		mov	r4,@(polygn_type,r13)
; 		mov	@r6,r0
; 		mov	r0,@(polygn_mtrl,r13)
; 		bra	.do_faces
; 		nop
; 		align 4

		bra *
		nop

.mk_face:

		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Read model OLD
; ------------------------------------------------

		align 4
MarsMdl_ReadModel:
		sts	pr,@-r15

		mov	#Cach_CurrPlygn,r13		; r13 - temporal face output
		mov	@(mdl_data,r14),r12		; r12 - model header
		mov 	@(8,r12),r11			; r11 - face data
		mov 	@(4,r12),r10			; r10 - vertice data (X,Y,Z)
		mov.w	@r12,r9				;  r9 - Number of faces used on model
		mov	@(marsGbl_CurrZList,gbr),r0	;  r8 - Zlist for sorting
		mov	r0,r8
.next_face:
		mov.w	@(marsGbl_CurrNumFaces,gbr),r0	; Ran out of face storage?
		mov	.tag_maxfaces,r1
		cmp/gt	r1,r0
		bf	.can_build
.no_model:
		bra	.exit_model
		nop
		align 4
.tag_maxfaces:	dc.l	MAX_FACES

; --------------------------------

.can_build:
		mov.w	@r11+,r4		; Read type
		nop
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
	rept 3
		mov.w	@r11+,r0		; Read UV index
		extu.w	r0,r0
		shll2	r0
		mov	@(r6,r0),r0
		mov.w	r0,@(2,r5)
		shlr16	r0
		mov.w	r0,@r5
		add	#4,r5
	endm
		mov	r7,r0			; Triangle?
		cmp/eq	#3,r0
		bt	.alluvdone		; If yes, skip this
		nop
		mov.w	@r11+,r0		; Read extra UV index
		extu.w	r0,r0
		shll2	r0
		mov	@(r6,r0),r0
		mov.w	r0,@(2,r5)
		shlr16	r0
		mov.w	r0,@r5
.alluvdone:
		mov	#-1,r5
		extu.b	r5,r5			; $FF
		mov	@(mdl_option,r14),r0
		extu.b	r0,r0
		mov	r0,r1
		mov	r4,r0
		and	r5,r0
		shll2	r0
		mov	@($10,r12),r6
		shll	r0
		add	r0,r6
; 		mov	#$C000,r0
		mov	#$60,r0		; grab special bits ($C000)
		shll	r0
		shll8	r0
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

; --------------------------------
; Set texture material
; --------------------------------

.solid_type:
		mov	@(mdl_option,r14),r0
		extu.b	r0,r0
; 		and	#$FF,r0
		mov	r0,r1
		mov	r4,r0
; 		mov	#$E000,r5
		mov	#$70,r5		; $E000
		shll	r5
		shll8	r5
		and	r5,r4
		shll16	r4
		add	r1,r4
		mov	r4,@(polygn_type,r13)		; Set type 0 (tri) or quad (1)
		extu.b	r0,r0
; 		and	#$FF,r0
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
		mov	#-(320/2)>>1,r8
		shll	r8
		mov	#-(224/2),r11
		neg	r8,r9
		neg	r11,r12
		mov	#-1,r13		; $FFFFFFFF

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
		nop
	endm
		mov	#3,r0			; Triangle?
		cmp/eq	r0,r7
		bt	.alldone		; If yes, skip this
		nop
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
		mov	#MAX_ZDIST>>8,r0	; Draw distance
		shll8	r0
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

; ****
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
		mov	@(marsGbl_CurrZTop,gbr),r0
		mov	r0,r6
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
; ****

		add	#8,r8			; Next Zlist entry
	rept sizeof_polygn/4			; Copy words manually
		mov	@r2+,r0
		mov	r0,@r1
		add	#4,r1
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
; 		ltorg

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
  		mov.w 	@(mdl_x_rot,r14),r0
  		bsr	mdlrd_rotate
  		shlr2	r0
   		mov	r7,r2
   		mov	r3,r5
  		mov	r8,r6
  		mov.w	@(mdl_z_rot,r14),r0
  		shlr	r0
  		bsr	mdlrd_rotate
  		shlr2	r0
   		mov	r8,r4
   		mov	r2,r5
   		mov	r7,r6
   		mov.w	@(mdl_y_rot,r14),r0
  		shlr	r0
  		bsr	mdlrd_rotate
  		shlr2	r0
   		mov	r7,r2
   		mov	r8,r3
		mov.w	@(mdl_x_pos,r14),r0
		exts.w	r0,r5
		mov.w	@(mdl_y_pos,r14),r0
		exts.w	r0,r6
		mov.w	@(mdl_z_pos,r14),r0
		exts.w	r0,r7
;  		shar	r5
;  		shar	r6
;  		shar	r7
		add 	r5,r2
		add 	r6,r3
		add 	r7,r4

	; Include camera changes
		mov 	#RAM_Mars_DreqRead+Dreq_ObjCam,r11
		mov	@(cam_x_pos,r11),r5
		mov	@(cam_y_pos,r11),r6
		mov	@(cam_z_pos,r11),r7
; 		shlr	r5
; 		shlr	r6
; 		shlr	r7
		exts	r5,r5
		exts	r6,r6
		exts	r7,r7
		sub 	r5,r2
		sub 	r6,r3
		add 	r7,r4

		mov	r2,r5
		mov	r4,r6
  		mov 	@(cam_x_rot,r11),r0
;   		shlr2	r0
;   		shlr	r0
  		bsr	mdlrd_rotate
		shlr2	r0
   		mov	r7,r2
   		mov	r8,r4
   		mov	r3,r5
  		mov	r8,r6
  		mov 	@(cam_y_rot,r11),r0
;   		shlr2	r0
;   		shlr	r0
  		bsr	mdlrd_rotate
		shlr2	r0
   		mov	r8,r4
   		mov	r2,r5
   		mov	r7,r6
   		mov 	@(cam_z_rot,r11),r0
;   		shlr2	r0
;   		shlr	r0
  		bsr	mdlrd_rotate
		shlr2	r0
   		mov	r7,r2
   		mov	r8,r3

	; Weak perspective projection
	; this is the best I got,
	; It breaks on large faces
		mov	#320<<16,r7
		neg	r4,r0		; reverse Z
		cmp/pl	r0
		bt	.inside
		mov	#1,r0
		shlr2	r7
		shlr2	r7
; 		shlr	r7
; 		dmuls	r7,r2
; 		sts	mach,r0
; 		sts	macl,r2
; 		xtrct	r0,r2
; 		dmuls	r7,r3
; 		sts	mach,r0
; 		sts	macl,r3
; 		xtrct	r0,r3
		bra	.zmulti
		nop
.inside:
		mov 	#_JR,r9
		mov 	r0,@r9
		mov 	r7,@(4,r9)
		nop
		mov 	@(4,r9),r7
.zmulti:
		dmuls	r7,r2
		sts	mach,r0
		sts	macl,r2
		xtrct	r0,r2
		dmuls	r7,r3
		sts	mach,r0
		sts	macl,r3
		xtrct	r0,r3

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

Cach_CurrPlygn		ds.b sizeof_polygn		; Current reading polygon
Cach_BkupPnt_L		ds.l 8				; **
Cach_BkupPnt_S		ds.l 0				; <-- Reads backwards
