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
MAX_SSPRSPD	equ 8		; Supersprite box increment: Size+this (maximum Super Sprite speed)
MAX_FACES	equ 980		; MAX polygon faces for 3D models
MAX_SVDP_PZ	equ 980+96	; MAX polygon pieces to draw
MAX_ZDIST	equ -$1900	; Maximum 3D field distance (-Z)

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

; 	; ---------------------------------------
; 	; Set block update timers
; 	; ---------------------------------------
;
; 	; X timers
; 		mov	#2,r7
; 		xor	r6,r6
; 		mov	#Cach_DrawTimers,r8
; 		mov.b	@(md_bg_flags,r14),r0
; 		extu.b	r0,r0
; 		and	#%1111,r0
; 		tst	#%0001,r0		; bitDrwR
; 		bf	.x_r
; 		tst	#%0010,r0		; bitDrwL
; 		bt	.x_k
; 		mov	r6,@r8
; 		mov	r7,@(4,r8)
; 		bra	.x_k
; 		nop
; .x_r:
; 		mov	r7,@r8
; 		mov	r6,@(4,r8)
; .x_k:
; 		add	#8,r8
;
; 	; Y timers
; 		tst	#%0100,r0		; bitDrwD
; 		bf	.y_r
; 		tst	#%1000,r0		; bitDrwU
; 		bt	.y_k
; 		mov	r6,@r8
; 		mov	r7,@(4,r8)
; 		bra	.y_k
; 		nop
; .y_r:
; 		mov	r7,@r8
; 		mov	r6,@(4,r8)
; .y_k:
; 		rts
; 		nop
; 		align 4

; 	; ---------------------------------------
; 	; Set block update timers
; 	; ---------------------------------------
;
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
		mov	@(scrl_yset,r13),r3
		add	r2,r3
		mov	r3,r0
		and	r6,r0
		tst	r0,r0
		bt	.y_k
		cmp/pz	r2
		bt	.y_r
		add	#4,r8
.y_r:
		mov	r7,@r8
		and	r4,r3
.y_k:
		mov	r3,@(scrl_yset,r13)

		rts
		nop
		align 4

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
		mov	#CS3|$40,r3
		mov	r2,@r3

		mulu	r1,r11
		sts	macl,r0
		mov	r10,r6
		add	r0,r6
; 		mov	#-$10,r0
; 		and	r0,r6				; r6 - curr out pos
		mov	r8,@-r15
		mov.w	@(md_bg_xinc_l,r14),r0		; r7 - Layout increment
		exts.w	r0,r1
		mov	#16,r3				; <-- MANUAL BLOCK SIZE
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

; ====================================================================
; ----------------------------------------------------------------
; 3D Section
;
; Nothing to see here (yet), all stuff is
; located at cache_m_3D.asm
; ----------------------------------------------------------------
