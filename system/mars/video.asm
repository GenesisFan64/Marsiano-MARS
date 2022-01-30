; ====================================================================
; ----------------------------------------------------------------
; MARS Video section
; ----------------------------------------------------------------

; ----------------------------------------
; Settings
; ----------------------------------------

MAX_FACES	equ 384
MAX_SVDP_PZ	equ 384+64
MAX_MSPR	equ 70			; Maximum sprites

FBVRAM_PATCH	equ $1E000		; Framebuffer location for the affected XShift lines
MAX_ZDIST	equ -$14000		; Max drawing distance (-Z max)

; ----------------------------------------
; Variables
; ----------------------------------------

; 3D drawing area, affects 3D positions too.
SCREEN_WIDTH	equ 320
SCREEN_HEIGHT	equ 224

; MSB
PLGN_TEXURE	equ %10000000
PLGN_TRI	equ %01000000

; ----------------------------------------
; Structs
; ----------------------------------------

; Be careful modifing these...
; The SH2 has limitation with indexing, bytes go first.
; (dont forget to align it)

		struct 0
mbg_redraw	ds.b 1
mbg_flags	ds.b 1		; Current type of pixel-data: Indexed or Direct
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
mbg_yfb		ds.w 1		; TOP Y position, multiply by WIDTH externally
mbg_intrl_blk	ds.w 1		; Block size
mbg_intrl_w	ds.w 1		; Internal scrolling Width (MUST be larger than 320)
mbg_intrl_h	ds.w 1		; Internal scrolling Height
mbg_intrl_size	ds.l 1		;
mbg_data	ds.l 1
mbg_fbpos	ds.l 1		; Framebuffer TOPLEFT position
mbg_fbdata	ds.l 1		; Pixeldata location on Framebuffer
mbg_rfill	ds.l 1		; Refill buffer
mbg_indxinc	ds.l 1		; Index increment (NOTE: for all 4 pixels)
mbg_xpos	ds.l 1		; 0000.0000
mbg_ypos	ds.l 1		; 0000.0000
sizeof_marsbg	ds.l 0
		finish

; ----------------------------------------

; ; model objects
; moved to const.asm
; 		struct 0
; mdl_data	ds.l 1			; Model data pointer, if zero: no model
; mdl_option	ds.l 1			; Model options: pixelvalue add
; mdl_x_pos	ds.l 1			; X position $000000.00
; mdl_y_pos	ds.l 1			; Y position $000000.00
; mdl_z_pos	ds.l 1			; Z position $000000.00
; mdl_x_rot	ds.l 1			; X rotation $000000.00
; mdl_y_rot	ds.l 1			; Y rotation $000000.00
; mdl_z_rot	ds.l 1			; Z rotation $000000.00
; mdl_animdata	ds.l 1			; Model animation data pointer, zero: no animation
; mdl_animframe	ds.l 1			; Current frame in animation
; mdl_animtimer	ds.l 1			; Animation timer
; mdl_animspd	ds.l 1			; Animation USER speed setting
; sizeof_mdlobj	ds.l 0
; 		finish

; field view camera
		struct 0
cam_x_pos	ds.l 1			; X position $000000.00
cam_y_pos	ds.l 1			; Y position $000000.00
cam_z_pos	ds.l 1			; Z position $000000.00
cam_x_rot	ds.l 1			; X rotation $000000.00
cam_y_rot	ds.l 1			; Y rotation $000000.00
cam_z_rot	ds.l 1			; Z rotation $000000.00
cam_animdata	ds.l 1			; Model animation data pointer, zero: no animation
cam_animframe	ds.l 1			; Current frame in animation
cam_animtimer	ds.l 1			; Animation timer
cam_animspd	ds.l 1			; Animation speed
sizeof_camera	ds.l 0
		finish

; 		struct 0
; mdllay_data	ds.l 1			; Model layout data, zero: Don't use layout
; mdllay_x	ds.l 1			; X position
; mdllay_y	ds.l 1			; Y position
; mdllay_z	ds.l 1			; Z position
; mdllay_x_last	ds.l 1			; LAST saved X position
; mdllay_y_last	ds.l 1			; LAST saved Y position
; mdllay_z_last	ds.l 1			; LAST saved Z position
; mdllay_xr_last	ds.l 1			; LAST saved X rotation
; sizeof_layout	ds.l 0
; 		finish

		struct 0
plypz_type	ds.l 1			; Type | Option
plypz_mtrl	ds.l 1
plypz_ypos	ds.l 1			; Ytop | Ybottom
plypz_xl	ds.l 1
plypz_xl_dx	ds.l 1
plypz_xr	ds.l 1
plypz_xr_dx	ds.l 1
plypz_src_xl	ds.l 1
plypz_src_xl_dx	ds.l 1
plypz_src_yl	ds.l 1
plypz_src_yl_dx	ds.l 1
plypz_src_xr	ds.l 1
plypz_src_xr_dx	ds.l 1
plypz_src_yr	ds.l 1
plypz_src_yr_dx	ds.l 1
sizeof_plypz	ds.l 0
		finish

; $38 bytes
		struct 0
polygn_type	ds.l 1		; %MSTw wwww xxxx aaaa | Type bits and Material option (Width or PalIncr)
polygn_mtrl	ds.l 1		; Material Type: Color (0-255) or Texture data address
polygn_points	ds.l 4*2	; X/Y positions
polygn_srcpnts	ds.w 4*2	; X/Y texture points (16-bit), ignored on solidcolor
sizeof_polygn	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Init MARS Video
; ----------------------------------------------------------------

MarsVideo_Init:
		sts	pr,@-r15
		mov	#_sysreg,r1
		mov 	#FM,r0			; Set SVDP permission to SH2, but the Genesis
  		mov.b	r0,@(adapter,r1)	; will control the pallete using DREQ
		mov 	#_vdpreg,r1
		mov	#0,r0			; Start at blank
		mov.b	r0,@(bitmapmd,r1)
		mov	#_framebuffer,r2	; Make null nametables
		bsr	.def_fb
		nop
		bsr	.def_fb
		nop

	; Clear values
	; TODO: checar bien esto porque se rompe en RESET
		mov	#RAM_Mars_Background,r1
		mov	#0,r0
		mov	r0,@(mbg_data,r1)
		mov	r0,@(mbg_xpos,r1)
		mov	r0,@(mbg_ypos,r1)
		mov.w	r0,@(mbg_xpos_old,r1)
		mov.w	r0,@(mbg_ypos_old,r1)
		mov.b	r0,@(mbg_xset,r1)
		mov.b	r0,@(mbg_yset,r1)
		lds	@r15+,pr
		rts
		nop
		align 4

; Default linetable
.def_fb:
		mov	r2,r3
		mov	#$1FD80/2,r0		; very last usable (blank) line
		mov	#240,r4
.nxt_lne:
		mov.w	r0,@r3
		dt	r4
		bf/s	.nxt_lne
		add	#2,r3
		mov.b	@(framectl,r1),r0	; Frameswap & wait
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

; ====================================================================
; ----------------------------------------------------------------
; Default subroutines
; ----------------------------------------------------------------

; ; ------------------------------------
; ; MarsVdp_LoadPal
; ;
; ; Load palette to RAM
; ; then the Palette will be transfered
; ; on VBlank
; ;
; ; Input:
; ; r1 - Palette data
; ; r2 - Start index
; ; r3 - Number of colors
; ; r4 - OR value ($0000 or $8000)
; ;
; ; Uses:
; ; r0,r4-r6
; ; ------------------------------------
;
; MarsVideo_LoadPal:
; ; 		mov.w	@(marsGbl_PalDmaMidWr,gbr),r0
; ; 		cmp/eq	#1,r0
; ; 		bt	MarsVideo_LoadPal
; 		mov 	r1,r5
; 		mov 	#RAM_Mars_Palette,r6
; 		mov 	r2,r0
; 		shll	r0
; 		add 	r0,r6
; 		mov 	r3,r0
; ; 		and	#$FF,r0
; ; 		cmp/pl	r0
; ; 		bf	.badlen
; 		mov	#256,r7
; 		cmp/gt	r7,r0
; 		bt	.loop
; 		mov	r0,r7
; .loop:
; 		mov.w	@r5+,r0
; 		or	r4,r0
; 		mov.w	r0,@r6
; 		dt	r7
; 		bf/s	.loop
; 		add 	#2,r6
; .badlen:
; 		mov	#RAM_Mars_Palette,r1	; lazy fix
; 		mov.w	@r1,r0			; for background
; 		mov	#$7FFF,r2
; 		and	r2,r0
; 		mov.w	r0,@r1
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ------------------------------------
; MarsVdp_Print
;
; Prints text on screen
;
; Input:
; r1 - String data
; r2 - X pos
; r3 - Y pos
; ------------------------------------

; TODO: a ver si puedo copy-pastear
; el de Genesis, para los valores
; llamar _PrintVal

MarsVdp_Print:
		sts	pr,@-r15
		mov	#RAM_Mars_Background,r14
		mov	#_framebuffer,r13
		mov	#m_ascii,r9
		mov.w	@(mbg_intrl_w,r14),r0
		mov	r0,r10

		mov.w	@(mbg_yfb,r14),r0
		add	r3,r0
		mulu	r10,r0
		mov	@(mbg_fbdata,r14),r0
		mov	r0,r11
		mov	@(mbg_fbpos,r14),r0
		add	r0,r11
		mov	r2,r0
		shll2	r0
		shll	r0
		add	r0,r11
		sts	macl,r0
		add	r0,r11
		mov	r11,r12
.nxt_chr:
		mov.b	@r1,r0
		and	#$FF,r0
		cmp/eq	#$00,r0
		bt	.chr_exit
		cmp/eq	#$0A,r0
		bt	.chr_enter
		bsr	.put_chr
		nop
		add	#8,r11
		bra	.nxt_chr
		add	#1,r1

.chr_enter:
		mov	#8,r0
		mulu	r0,r10
		sts	macl,r0
		add	r0,r12
		mov	r12,r11
		bra	.nxt_chr
		add	#1,r1

.chr_exit:
		lds	@r15+,pr
		rts
		nop
		align 4

.put_chr:
		mov	#$20,r8
		sub	r8,r0
		shll2	r0		; *$40
		shll2	r0
		shll2	r0
		mov	r9,r8
		add	r0,r8
		mov	r13,r7
		add	r11,r7
		mov	#8,r6
.nxt_lns:
		mov	@r8+,r0
		mov	r0,@r7
		mov	@r8+,r0
		mov	r0,@(4,r7)
		dt	r6
		bf/s	.nxt_lns
		add	r10,r7
		rts
		nop
		align 4

; ------------------------------------
; MarsVdp_PrintVal
;
; Prints a value from ROM/RAM on
; screen
;
; Input:
; r1 - Value
; r2 - X pos
; r3 - Y pos
; r4 - Type
; ------------------------------------

; *** CURRENTLY 4BYTE LONGS ONLY ***

MarsVdp_PrintVal:
		sts	pr,@-r15
		mov	#RAM_Mars_Background,r14
		mov	#_framebuffer,r13
		mov	#m_ascii,r12
		mov.w	@(mbg_intrl_w,r14),r0
		mov	r0,r10
		mov.w	@(mbg_yfb,r14),r0
		add	r3,r0
		mulu	r10,r0
		mov	@(mbg_fbdata,r14),r0
		mov	r0,r11
		mov	@(mbg_fbpos,r14),r0
		add	r0,r11
		mov	r2,r0
		shll2	r0
		shll	r0
		add	r0,r11
		sts	macl,r0
		add	r0,r11

		mov	r1,r4
		bsr	.put_value
		nop
.chr_exit:
		lds	@r15+,pr
		rts
		nop
		align 4

; r4 - Value
; r5 - Type (1-byte 2-word 4-long)
;
; Uses:
; r7-r9

.put_value:
		mov	#4,r5		; LONG temporal
		shll	r5
.wrt_nibl:
		rotl	r4
		rotl	r4
		rotl	r4
		rotl	r4
		mov	r4,r0
		and	#%1111,r0
		mov	#$A,r7
		cmp/ge	r7,r0
		bf	.a_plus
		add	#7,r0
.a_plus:
		add	#$10,r0
		shll2	r0		; *$40
		shll2	r0
		shll2	r0
		mov	r12,r7
		add	r0,r7
		mov	r13,r8
		add	r11,r8
		mov	#-4,r0
		and	r0,r8
		mov	#8,r9
.nxt_lns:
		mov	@r7+,r0
		mov	r0,@r8
		mov	@r7+,r0
		mov	r0,@(4,r8)
		dt	r9
		bf/s	.nxt_lns
		add	r10,r8
		add	#8,r11
		dt	r5
		bf	.wrt_nibl
		rts
		nop
		align 4

	; write literals
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 256-color Scrolling background
; ----------------------------------------------------------------

; ---------------------------------------
; Draw ALL the pixel data on
; current framebuffer
;
; r1 - X pos
; r2 - Y pos
;
; *** THE OTHER DRAWING TIMERS U/D/L/R
; MUST BE ZERO BEFORE GETTING HERE ***
; ---------------------------------------

MarsVideo_DrawAllBg:
		sts	pr,@-r15
		mov	#RAM_Mars_Background,r14
		mov	@(mbg_data,r14),r0
		cmp/eq	#0,r0
		bt	.no_data
		mov	@(mbg_xpos,r14),r1
		mov	@(mbg_ypos,r14),r2
		shlr16	r1
		shlr16	r2
		exts.w	r1,r1
		exts.w	r2,r2
		mov	r0,r13				; r13 - pixel data
		mov	#_framebuffer,r12
		mov	@(mbg_fbdata,r14),r0
		add	r0,r12
		mov.w	@(mbg_width,r14),r0		; r11 - pixel-data WIDTH
		mov	r0,r11
		mov.w	@(mbg_intrl_w,r14),r0		; r10 - internal WIDTH
		mov	r0,r10
		mov.w	@(mbg_height,r14),r0
		mov	r0,r9
		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r8
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r7
		neg	r7,r6
		mov	@(mbg_intrl_size,r14),r5
		mov	#320,r4
		mov.b	@(mbg_flags,r14),r0
		and	#1,r0
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
		mov.w	@(mbg_yfb,r14),r0
		mov	r0,r4
		mov	@(mbg_fbpos,r14),r3
		and	r6,r4
		and	r6,r3
		and	r6,r2
		and	r6,r1
		mov	#0,r6
.nxt_y:
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
		bsr	.mk_piece
		nop
		add	r7,r1
		add	r7,r6
		cmp/ge	r10,r6
		bf/s	.nxt_x
		add	r7,r3		; No MAP WIDTH check needed here
		mov	@r15+,r1
		mov	@r15+,r3
		mov	@r15+,r6

		add	r7,r4
		cmp/gt	r8,r4
		bf	.nxt_y_l
		sub	r8,r4
.nxt_y_l:
		add	r7,r2
		add 	r7,r6
		cmp/ge	r8,r6
		bf	.nxt_y
.no_data:
		lds	@r15+,pr
		rts
		nop
		align 4

; r1 - X pos
; r2 - Y pos
.mk_piece:
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15

		mulu	r4,r10
		sts	macl,r6
		add	r3,r6
		cmp/ge	r5,r6
		bf	.lrgrfb
		sub	r5,r6
.lrgrfb:
	; Framebuffer X/Y add
		mov	r13,r8		; BG X/Y add
		mulu	r11,r2
		sts	macl,r0
		add	r0,r8
		add	r1,r8
		mov	r12,r7		; FB X add
		add	r6,r7

	; Hidden line
		mov	#320,r9
		mov.b	@(mbg_flags,r14),r0
		and	#1,r0
		tst	r0,r0
		bt	.indxmoden
		shll	r9
.indxmoden:
		cmp/ge	r9,r6
		bt	.y_nohdnln
		mov	r9,r3
		shlr2	r3
		mov	@(mbg_intrl_size,r14),r0
		add	r0,r6
		add	r12,r6
		mov	r8,r5
		mov.w	@(mbg_intrl_blk,r14),r0
.nxtlnghdn:
		mov	@r5+,r0
		mov	r0,@r6
		dt	r3
		bf/s	.nxtlnghdn
		add	#4,r6
.y_nohdnln:
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r9
.yblk_loopn:
		mov	r8,r5
		mov	r7,r6
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r3
		shlr2	r3
.nxtlng:
		mov	@r5+,r0
		mov	r0,@r6
		dt	r3
		bf/s	.nxtlng
		add	#4,r6

		add	r11,r8
		dt	r9
		bf/s	.yblk_loopn
		add	r10,r7
.yblk_ex:
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		rts
		nop
		align 4
		ltorg

; ---------------------------------------
; Background:
; Draw Left/Right sections
; ---------------------------------------

MarsVideo_BgDrawLR:
		mov	#RAM_Mars_Background,r14
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
		mov	#Cach_Drw_R,r1
		mov	#Cach_Drw_L,r2
		mov	@r1,r0
		cmp/eq	#0,r0
		bf	.dtsk01_dright
		mov	@r2,r0
		cmp/eq	#0,r0
		bf	.dtsk01_dleft
.nxt_drawud:
		rts
		nop
		align 4

.dtsk01_dleft:
		dt	r0
		mov	r0,@r2
		mov	#Cach_XHead_L,r0
		mov	@r0,r0
		bra	dtsk01_lrdraw
		mov	r0,r5
.dtsk01_dright:
		dt	r0
		mov	r0,@r1
		mov	#320,r3			; Set FB position
		mov.b	@(mbg_flags,r14),r0
		and	#1,r0
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
		and	#1,r0
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

; ---------------------------------------
; Background:
; Draw Up/Down sections
; ---------------------------------------

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
; 		and	#1,r0
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
		mov	#Cach_Drw_U,r1
		mov	#Cach_Drw_D,r2
		mov	@r1,r0
		cmp/eq	#0,r0
		bf	.tsk00_up
		mov	@r2,r0
		cmp/eq	#0,r0
		bt	drw_ud_exit
.tsk00_down:
		dt	r0
		mov	r0,@r2

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
		mov	r0,@r1
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
		and	#1,r0
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

; ---------------------------------------
; MarsVideo_MoveBg
;
; This updates the background's
; X/Y position
;
; Call this during VBlank.
; ---------------------------------------

MarsVideo_MoveBg:
		mov	#RAM_Mars_Background,r14
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

	; 256-color BG mode flag goes here
; 		mov	r1,r0
; 		or	r2,r0
; 		cmp/eq	#0,r0
; 		bt	.no_chng
; 		mov	#0,r0
; 		mov.w	r0,@(marsGbl_XPatch,gbr)
.no_chng:
		mov.w	@(marsGbl_XShift,gbr),r0	; Also update the XShift
		add	r1,r0				; bit for 256-color mode
		mov.w	r0,@(marsGbl_XShift,gbr)

	; ---------------------------------------
	; Y Framebuffer position
	; ---------------------------------------

		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r3
		mov.w	@(mbg_yfb,r14),r0
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
		mov.w	r0,@(mbg_yfb,r14)

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

		mov	#Cach_Drw_U,r8
		mov	#Cach_Drw_D,r9
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
		mov	@r8,r0
		mov	r0,r4
		mov	@r9,r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydr_busy
		mov	#2,r0
		mov	r0,@r9
		add	#$01,r5
.reqd_b:
		cmp/pz	r2
		bt	.ydr_busy
		mov	@r8,r0
		mov	r0,r4
		mov	@r9,r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydr_busy
		mov	#2,r0
		mov	r0,@r8
		add	#$01,r5
.ydr_busy:

		mov	#Cach_Drw_L,r8
		mov	#Cach_Drw_R,r9
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
		mov	@r8,r0
		mov	r0,r4
		mov	@r9,r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydl_busy
		mov	#2,r0
		mov	r0,@r9
		add	#$02,r5
.reqr_b:
		cmp/pz	r1
		bt	.ydl_busy
		mov	@r8,r0
		mov	r0,r4
		mov	@r9,r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydl_busy
		mov	#2,r0
		mov	r0,@r8
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
		mov.w	@(mbg_yfb,r14),r0
		and	r7,r0
		mov	r0,@r5
		mov	@(mbg_fbpos,r14),r0
		and	r7,r0
		mov	r0,r7
		mov.b	@(mbg_flags,r14),r0
		and	#1,r0
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

; ---------------------------------------
; Make a visible section on screen
;
; r1 - Background buffer
; r2 - Top Y
; r3 - Bottom Y
; ---------------------------------------

MarsVideo_MakeTbl:
		mov	#_framebuffer,r14		; r14 - Framebuffer BASE
		mov	@(mbg_fbdata,r1),r13		; r13 - Framebuffer pixeldata position
		mov	@(mbg_intrl_size,r1),r12	; r12 - Full size of screen-scroll
		mov	#0,r10				; r10 - line counter
		mov.w	@(mbg_intrl_w,r1),r0
		mov	r0,r9				;  r9 - Next line to add
		mov	r2,r6
		mov	r14,r8
		mov	r2,r0
		shll	r0
		add	r0,r8
		mov.w	@(mbg_yfb,r1),r0
		mulu	r9,r0
		mov	@(mbg_fbpos,r1),r5
; 		shll	r5
		mov	r5,r7
		sts	macl,r0
		add	r0,r7
		mov	#$FF,r4
.ln_loop:
		mov	r7,r5
		cmp/ge	r12,r5
		bf	.xl_r
		sub	r12,r5
.xl_r:
		cmp/pz	r5
		bt	.xl_l
		add	r12,r5
.xl_l:
		mov	r5,r7
		add	r9,r7		; Add Y
		add	r13,r5		; Add Framebuffer position
		shlr	r5		; divide by 2 (shift reg does the missing bit 0)
		mov.w	r5,@r8		; send to FB's table
		add	#2,r8
		add	#2,r10
		cmp/eq	r3,r6
		bf/s	.ln_loop
		add	#1,r6

.no_lines:
		rts
		nop
		align 4

; ---------------------------------------
; Call this after BEFORE swapping
; to fix that Xshift bit issue on
; Real Hardware
; ---------------------------------------

MarsVideo_FixTblShift:
		mov.w	@(marsGbl_XShift,gbr),r0
		and	#1,r0
		cmp/eq	#1,r0
		bf	.ptchset
		mov	#_framebuffer,r14		; r14 - Framebuffer BASE
; 		mov.b	@(mbg_flags,r1),r0		; Background is Indexed?
; 		and	#%00000001,r0
; 		tst	r0,r0
; 		bf	.ptchset
		mov	r14,r13
		mov	#_framebuffer+FBVRAM_PATCH,r12	; r13 - Output for patched pixel lines
		mov	#240,r11
		mov	#$FF,r10
		mov	#$FFFF,r9
; 		mov	#-2,r8
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

; ------------------------------------------------
; MarsVideo_MkScrlField
;
; Make a new internal background
; scrolling buffer
;
; First call this, set your values
; Then call MarsVideo_SetBg to set
; the source image (ROM or RAM)
;
; r1 - Background buffer
; r2 - Output framebuffer data
; r3 - Scroll block size (4 BYTE ALIGNED)
; r4 - Scroll visible width
; r5 - Scroll visible height
; r6 - Type: Indexed or Direct (TODO)
; ------------------------------------------------

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
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; MarsVideo_SetBg
;
; Set pointer to read the pixel-data
;
; r1 - Background buffer
; r2 - Pixeldata output location on Framebuffer
; r3 - Source image WIDTH
; r4 - Source image HEIGHT
;
; WIDTH AND HEIGHT MUST BE ALIGNED IN "BLOCKS"
; ------------------------------------------------

MarsVideo_SetBg:
		mov	#RAM_Mars_Background,r1
		mov	r2,@(mbg_data,r1)
		mov.b	@(mbg_flags,r1),r0
		and	#1,r0
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

; ------------------------------------------------

; ; r1 - Left X
; ; r2 - Right X
; ; r3 - Y Position (max 240)
; ; r4 - Using these pixel(s)
; ;
; ; Uses the first background's
; ; top-left and Y
;
; ; TODO: a DirectColor version of this
; VideoMars_DrawLine:
; 		cmp/eq	r1,r2
; 		bt	.same_x
; 		mov	r2,r6
; 		sub	r1,r6
; 		cmp/pl	r6
; 		bf	.same_x
; 		shlr	r6
; 		mov	#RAM_Mars_Background,r14
; 		mov	#_vdpreg,r13
;
; 		mov.w	@(mbg_intrl_h,r14),r0
; 		mov	r0,r7
; 		mov.w	@(mbg_intrl_w,r14),r0
; 		mov	r0,r5
; 		mov.w	@(mbg_yfb,r14),r0
; 		add	r3,r0
; 		cmp/ge	r7,r0
; 		bf	.ylowr
; 		sub	r7,r0
; .ylowr:
; 		mulu	r5,r0
; 		sts	macl,r5
; 		mov	@(mbg_fbdata,r14),r0
; 		add	r0,r5
; 		mov	@(mbg_fbpos,r14),r0
; 		add	r0,r5
; 		add	r1,r5
; 		mov	@(mbg_intrl_size,r14),r0
; 		cmp/gt	r0,r5
; 		bf	.fb_decr
; 		sub	r0,r5
; .fb_decr:
; 		shlr	r5
;
; 	; r5 - topleft pos
; 	; r6 - length
;
; 	; Cross-check
; 		mov	r6,r0
; 		add	r5,r0
; 		mov	r0,r7
; 		mov	r5,r8
; 		shlr8	r7
; 		shlr8	r8
; 		cmp/eq	r7,r8
; 		bt	.single
; 		mov	r0,r8
; 		and	#$FF,r0
; 		cmp/eq	#0,r0
; 		bt	.single
;
; 	; Left write
; 		mov	r6,r7
; 		sub	r0,r6
; 		mov	r6,r0
; 		dt	r0
; 		mov.w	r0,@(filllength,r13)
; 		mov	r5,r0
; 		mov.w	r0,@(fillstart,r13)
; 		mov	r4,r0
; 		mov.w	r0,@(filldata,r13)
; .wait_l:	mov.w	@(vdpsts,r13),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bf	.wait_l
;
; 		add	r7,r5
; 		mov	#$100,r6
; 		mov.w	@(fillstart,r13),r0
; 		add	r6,r0
; 		mov.w	r0,@(fillstart,r13)
; 		sub	r0,r5
; 		mov	r5,r0
; 		dt	r0
; 		mov.w	r0,@(filllength,r13)
; 		mov	r4,r0
; 		mov.w	r0,@(filldata,r13)
; .wait_r:	mov.w	@(vdpsts,r13),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bf	.wait_r
; 		rts
; 		nop
; 		align 4
;
; ; Single write
; .single:
; 		mov	r6,r0
; 		dt	r0
; 		mov.w	r0,@(filllength,r13)
; 		mov	r5,r0
; 		mov.w	r0,@(fillstart,r13)
; 		mov	r4,r0
; 		mov.w	r0,@(filldata,r13)
; .wait_fb:	mov.w	@(vdpsts,r13),r0
; 		and	#%10,r0
; 		tst	r0,r0
; 		bf	.wait_fb
; 		rts
; 		nop
; 		align 4
; .same_x:
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Polygons
; ----------------------------------------------------------------


; ====================================================================
; ----------------------------------------------------------------
; 3D Models
; ----------------------------------------------------------------

; ------------------------------------------------
; MarsMdl_Init
;
; Reset ALL objects
; ------------------------------------------------

MarsMdl_Init:
		mov	#RAM_Mars_Objects,r1
		mov	#MAX_MODELS,r2
		mov	#0,r0
.clnup:
		mov	r0,@(mdl_data,r1)
		mov	r0,@(mdl_animdata,r1)
		mov	r0,@(mdl_x_pos,r1)
		mov	r0,@(mdl_x_rot,r1)
		mov	r0,@(mdl_y_pos,r1)
		mov	r0,@(mdl_y_rot,r1)
		mov	r0,@(mdl_y_pos,r1)
		mov	r0,@(mdl_y_rot,r1)
		dt	r2
		bf/s	.clnup
		add	#sizeof_mdlobj,r1
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Read model
; ------------------------------------------------

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
		mov	#$3FFFFFFF,r0
		mov	#Cach_CurrPlygn,r13		; r13 - temporal face output
		mov	@(mdl_data,r14),r12		; r12 - model header
		and	r0,r12
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

	; New method
	rept 3
		mov.w	@r11+,r0			; Read UV index
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
		mov	#$E000,r0		; grab special bits
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
.tag_andmtrl:
		dc.l $1FFF

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
		mov 	r8,@-r15
		mov 	r9,@-r15
		mov 	r11,@-r15
		mov 	r12,@-r15
		mov 	r13,@-r15
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
		mov	@r15+,r13
		mov	@r15+,r12
		mov	@r15+,r11
		mov	@r15+,r9
		mov	@r15+,r8

	; NOTE: if you don't like how the perspective works
	; change this register depending how you want to ignore
	; faces closer to the camera:
	;
	; r5 - Back Z point, keep affine limitations
	; r6 - Front Z point, skip face but larger faces are affected

		cmp/pz	r5
		bt	.go_fout
; 		cmp/pz	r6
; 		bt	.go_fout


; 		mov	#RAM_Mars_ObjCamera,r0
; 		mov	@(cam_y_pos,r0),r7
; 		shlr2	r7
; 		shlr2	r7
; 		shlr2	r7
; 		shlr	r7
; 		exts	r7,r7
; 		cmp/pl	r7
; 		bf	.revrscam
; 		neg	r7,r7
; .revrscam:
; 		mov	#MAX_ZDIST,r0
; 		cmp/ge	r0,r7
; 		bt	.camlimit
; 		mov	r0,r7
; .camlimit:
; 		cmp/pl	r6
; 		bt	.face_out
		mov	#MAX_ZDIST,r0		; Draw distance
; 		add 	r7,r0
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

; 	Sort this face, SLOW
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
		mov	#RAM_Mars_PlgnList_0,r6
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bt	.page_2
		mov	#RAM_Mars_PlgnList_1,r6
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


		add	#8,r8				; Next Zlist entry
	rept sizeof_polygn/2				; Copy words manually
		mov.w	@r2+,r0
		mov.w	r0,@r1
		add	#2,r1
	endm
		mov	r1,r0
		mov	r0,@(marsGbl_CurrFacePos,gbr)

; 		mov	r0,r1
; 		mov	@(marsGbl_ZSortReq,gbr),r0
; 		cmp/eq	#1,r0
; 		bt	.face_out
; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_ZSortReq,gbr)
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
		sts	pr,@-r15
		mov 	r5,@-r15
		mov 	r6,@-r15
		mov 	r7,@-r15
		mov 	r8,@-r15
		mov 	r9,@-r15
		mov 	r10,@-r15
		mov 	r11,@-r15

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
		shlr8	r5
		shlr8	r6
		shlr8	r7
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
		mov	#320<<16,r7
		neg	r4,r0		; reverse Z
; 		add	#-16,r0
		cmp/pl	r0
		bt	.inside
		shlr	r7

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

		mov	@r15+,r11
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5

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

		lds	@r15+,pr
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

; r7 - rotate
; r5 - X
; r6 - Y
Rotate_Point
	shll2	r7
	mov	r7,r0
	mov	#sin_table,r1
	mov	#sin_table+$800,r2
	mov	@(r0,r1),r3
	mov	@(r0,r2),r4

	dmuls.l	r5,r4		; x cos @
	sts	macl,r0
	sts	mach,r1
	xtrct	r1,r0
	dmuls.l	r6,r3		; y sin @
	sts	macl,r1
	sts	mach,r2
	xtrct	r2,r1
	add	r1,r0

	neg	r3,r3
	dmuls.l	r5,r3		; x -sin @
	sts	macl,r1
	sts	mach,r2
	xtrct	r2,r1
	dmuls.l	r6,r4		; y cos @
	sts	macl,r2
	sts	mach,r3
	xtrct	r3,r2
	add	r2,r1

	rts
	nop
	align 4
	ltorg

