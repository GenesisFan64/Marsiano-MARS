; ====================================================================
; ----------------------------------------------------------------
; CACHE code for MASTER CPU
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_MSTR_SCRL:
		phase $C0000000

; ====================================================================
; --------------------------------------------------------
; Watchdog interrupt
; --------------------------------------------------------

		mov	#$F0,r0
		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)

		mov	@(marsGbl_CurrRdSpr,gbr),r0
		mov	r0,r1
		mov	@(marsspr_data,r1),r0
		tst	r0,r0
		bt	.finish_now
		mov	#Cach_SprBkup_S,r0
		mov	r2,@-r0
		mov	r3,@-r0
		mov	r4,@-r0
		mov	r5,@-r0
		mov	r6,@-r0
		mov	r7,@-r0
		mov	r8,@-r0
		mov	r9,@-r0
		mov	r10,@-r0
		sts	macl,@-r0
		sts	mach,@-r0

	; quick.
	; r1 - current sprite
	; r2 - output piece

	; TODO: WIP
		mov	@(marsGbl_PlyPzList_W,gbr),r0
		mov	r0,r2
		mov	@(marsspr_data,r1),r0
		mov	r0,@(plypz_mtrl,r2)
		mov.w	@(marsspr_x,r1),r0		; r3 - X pos
		mov	r0,r3
		mov.w	@(marsspr_y,r1),r0		; r4 - Y pos
		mov	r0,r4
		mov.w	@(marsspr_xs,r1),r0		; r5 - XS
		mov	r0,r5
		mov.w	@(marsspr_ys,r1),r0		; r6 - YS
		mov	r0,r6
		mov.w	@(marsspr_dwidth,r1),r0
		mov	r0,r7
		shll16	r7
		mov	r7,r8				; spritesheet width
		mov.w	@(marsspr_indx,r1),r0		; index palette
		and	#$FF,r0
		or	r8,r0
		mov	r0,@(plypz_type,r2)
		mov	r4,r8
		mov	r4,r9
		add	r6,r9
		mov	#$FFFF,r0
		and	r0,r9
		shll16	r8
		or	r9,r8
		mov	r8,@(plypz_ytb,r2)
		mov	r3,r8
		mov	r3,r9
		add	r5,r9
		shll16	r8			; XL/XR
		extu.w	r9,r9
		or	r8,r9
		mov	r9,@(plypz_xl,r2)
		mov	#0,r0			; no screen DX/DY
		mov	r0,@(plypz_xl_dx,r2)
		mov	r0,@(plypz_xr_dx,r2)

		mov	#$00000020,r3
		mov	#$00000000,r4
		mov	r3,@(plypz_src_xl,r2)
		mov	r4,@(plypz_src_yl,r2)

		xor	r0,r0
		mov	r0,@(plypz_src_xl_dx,r2)
		mov	r0,@(plypz_src_xr_dx,r2)
		mov	#1<<16,r0
		mov	r0,@(plypz_src_yl_dx,r2)
		mov	r0,@(plypz_src_yr_dx,r2)

	; Next sprite and SVDP piece
		add	#sizeof_marsspr,r1
		add	#sizeof_plypz,r2
		mov	r1,r0
		mov	r0,@(marsGbl_CurrRdSpr,gbr)
		mov	r2,r0
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0	; add one
		add	#1,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)

		mov	#Cach_SprBkup_LB,r0
		lds	@r0+,mach
		lds	@r0+,macl
		mov	@r0+,r10
		mov	@r0+,r9
		mov	@r0+,r8
		mov	@r0+,r7
		mov	@r0+,r6
		mov	@r0+,r5
		mov	@r0+,r4
		mov	@r0+,r3
		mov	@r0+,r2
; wdm_next:

	; TODO: ver porque esto se
	; traba en hardware
; 		mov.l   #$FFFFFE80,r1
; 		mov.w   #$A518,r0		; OFF
; 		mov.w   r0,@r1
; 		or      #$20,r0			; ON
; 		mov.w   r0,@r1
; 		mov.w   #$5A20,r0		; Timer for the next WD
; 		mov.w   r0,@r1
; 		rts
; 		nop
; 		align 4
; 		ltorg

.finish_now:
		mov	#1,r0
		mov.w	r0,@(marsGbl_WdgStatus,gbr)
		mov	#$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Super sprites
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_SprBlkRefill
;
; Call MarsVideo_MarkSprBlocks first.
;
; r14 - Background buffer
; --------------------------------------------------------

		align 4
MarsVideo_SprBlkRefill:
		sts	pr,@-r15
		mov	@(mbg_data,r14),r0
		cmp/eq	#0,r0
		bt	.no_data
		lds	r0,mach

		mov	#RAM_Mars_RdrwBlocks,r13
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
; 		mov	r1,r0
; ; 		mov.w	r0,@(mbg_xinc_l,r14)
; 		add	r4,r0
; .lwr_xnxt:	cmp/gt	r11,r0
; 		bf	.lwr_xvld
; 		bra	.lwr_xnxt
; 		sub	r11,r0
; .lwr_xvld:
; ; 		mov.w	r0,@(mbg_xinc_r,r14)
;
; 		mov	r2,r0
; ; 		mov.w	r0,@(mbg_yinc_u,r14)
; 		mov	r0,r3
;
; 		add	r8,r3
; 		sub	r7,r3
; .lwr_ynxt:	cmp/ge	r9,r3
; 		bf	.lwr_yvld
; 		bra	.lwr_ynxt
; 		sub	r9,r3
; .lwr_yvld:
; 		mov	r3,r0
; 		mov.w	r0,@(mbg_yinc_d,r14)

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
		mov	r13,@-r15
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
		mov.b	@r13,r0
		tst	r0,r0
		bt	.no_pz
		xor	r0,r0
		mov.b	r0,@r13
		bsr	.mk_piece
		nop
.no_pz:
		mov	r7,r0
		shlr2	r0
		add	r0,r13
		add	r7,r3
		add	r7,r6
		cmp/ge	r10,r6
		bf/s	.nxt_x
		add	r7,r1

		mov	r7,r0
		neg	r7,r1
		and	r1,r0
		shll2	r0
		shll2	r0
		shll	r0

		mov	@r15+,r1
		mov	@r15+,r3
		mov	@r15+,r6
		mov	@r15+,r13


		add	r0,r13
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

; 		mov	r13,r8		; BG X/Y add
		sts	mach,r8
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

		add	r11,r8
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

; --------------------------------------------------------
; MarsVideo_DrawSuperSpr
;
; Draws pieces from the SVDP list using
; specific screen-coordinates.
;
; Set your screen coords by calling
; MarsVideo_SetSuperSpr first.
; --------------------------------------------------------

		align 4
MarsVideo_DrawSuperSpr:
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0
		cmp/pl	r0
		bf	.no_pz

		mov	@(marsGbl_PlyPzList_R,gbr),r0
		mov	r0,r13
		mov	#Cach_PzCopy,r12
		mov	r12,r11
	rept sizeof_plypz/4
		mov	@r13+,r0
		mov	r0,@r12
		add	#4,r12
	endm
		mov	@(plypz_ytb,r11),r9		; Grab StartY / EndY
		mov	r9,r10
		mov	#$FFFF,r0
		shlr16	r9
		exts.w	r9,r9			;  r9 - Top
		and	r0,r10			; r10 - Bottom
		cmp/eq	r9,r0			; if Top==Bottom, exit
		bt	.invld_y
		mov	#SCREEN_HEIGHT,r0	; if Top > 224, skip
		cmp/ge	r0,r9
		bt	.invld_y		; if Bottom > 224, add max limit
		cmp/gt	r0,r10
		bf	.len_max
		mov	r0,r10
.len_max:
		sub	r9,r10			; Turn r10 into line lenght (Bottom - Top)
		cmp/pl	r10
		bt	.drwtsk1_vld_y
.invld_y:
		bra	.drwtex_gonxtpz		; if LEN < 0 then check next one...
		nop
.no_pz:
		bra	.drwtask_exit
		nop
		align 4

; ------------------------------------
; Texture mode
;
; r1  - XL
; r2  - XL DX
; r3  - XR
; r4  - XR DX
; r5  - SRC XL
; r6  - SRC XR
; r7  - SRC YL
; r8  - SRC YR
; r9  - Y current"
; r10  - Number of lines
; ------------------------------------

.drwtsk1_vld_y:
		mov	@(plypz_xl,r11),r1
		mov	r1,r3
		mov	@(plypz_xl_dx,r11),r2		; r2 - DX left
		shlr16	r1
		mov	@(plypz_xr_dx,r11),r4		; r4 - DX right
		shll16	r1
		mov	@(plypz_src_xl,r11),r5		; Texture X left/right
		shll16	r3
		mov	@(plypz_src_yl,r11),r7		; Texture Y up/down
		mov	r5,r6

		mov	r7,r8
		shlr16	r5
		shlr16	r7
		shll16	r5
		shll16	r6
		shll16	r7
		shll16	r8

; 		mov	@(plypz_src_xl,r11),r5		; Texture X left
; 		mov	@(plypz_src_xr,r11),r6		; Texture X right
; 		mov	@(plypz_src_yl,r11),r7		; Texture Y up
; 		mov	@(plypz_src_yr,r11),r8		; Texture Y down
.drwsld_nxtline_tex:
		cmp/pz	r9		; Y Start below 0?
		bf	.go_nxtline
		mov	.tag_yhght,r0	; Y Start after 224?
		cmp/ge	r0,r10
		bf	.valid_y
.go_nxtpz:
		bra	.drwtex_gonxtpz
		nop
		align 4
.go_nxtline:
		bra	.drwsld_updline_tex
		nop
		align 4
.tag_yhght:	dc.l SCREEN_HEIGHT
.valid_y:
		mov	#Cach_SprBkup_S,r0
		mov	r1,@-r0
		mov	r2,@-r0
		mov	r3,@-r0
		mov	r4,@-r0
		mov	r5,@-r0
		mov	r6,@-r0
		mov	r7,@-r0
		mov	r8,@-r0
		mov	r9,@-r0
		mov	r10,@-r0
		mov	r11,@-r0

	; r11
		shlr16	r1			; r1 - X left
		shlr16	r3			; r3 - X right
		exts	r1,r1
		exts	r3,r3
		mov	r3,r0			; r0: X Right - X Left
		sub	r1,r0
		cmp/pl	r0			; Line reversed?
		bt	.txrevers
		mov	r3,r0			; Swap XL and XR values
		mov	r1,r3
		mov	r0,r1
		mov	r5,r0
		mov	r6,r5
		mov	r0,r6
		mov	r7,r0
		mov	r8,r7
		mov	r0,r8
.txrevers:
		cmp/eq	r1,r3				; Same X position?
		bt	.tex_skip_line
		mov	#SCREEN_WIDTH,r0		; X right < 0?
		cmp/pl	r3
		bf	.tex_skip_line
		cmp/gt	r0,r1				; X left > 320?
		bt	.tex_skip_line
		mov	r3,r2
		mov 	r1,r0
		sub 	r0,r2
		sub	r5,r6
		sub	r7,r8

		mov	#_JR,r0				; r6 / r2
		mov	r2,@r0
		mov	r6,@(4,r0)
		nop
		mov	@(4,r0),r6			; r8 / r2
		mov	r2,@r0
		mov	r8,@(4,r0)
		nop
		mov	@(4,r0),r8

	; Limit X destination points
	; and correct the texture's X positions
		mov	#SCREEN_WIDTH,r0		; XR point > 320?
		cmp/gt	r0,r3
		bf	.tr_fix
		mov	r0,r3				; Force XR to 320
.tr_fix:
		cmp/pl	r1				; XL point < 0?
		bt	.tl_fix
		neg	r1,r2				; Fix texture positions
		dmuls	r6,r2
		sts	macl,r0
		add	r0,r5
		dmuls	r8,r2
		sts	macl,r0
		add	r0,r7
		xor	r1,r1				; And reset XL to 0
.tl_fix:

	; start
		sub 	r1,r3			; r3 - X line width
		cmp/pl	r3
		bf	.tex_skip_line

		mov	#Cach_Intrl_W,r14
		mov	@r14+,r13			; width
		mov	@r14+,r12			; height
		mov	@r14+,r0			; y pos
		add	r9,r0
		cmp/ge	r12,r0
		bf	.y_tp
		sub	r12,r0
.y_tp:
		muls	r0,r13
		sts	macl,r0
		mov	@r14+,r13			; x pos
		add	r1,r13
		add	r0,r13
		mov	@r14+,r0			; data
		mov	@r14+,r12			; size
		mov	#_overwrite,r9
		add	r0,r9

		mov	@(plypz_mtrl,r11),r1
		mov	#$FF,r0
		mov	@(plypz_type,r11),r4
		mov	r4,r11
		shlr16	r4
		mov	#$3FFF,r2
		and	r2,r4
		and	r0,r11
.tex2_xloop:
		cmp/ge	r12,r13
		bf	.fb_tl
		sub	r12,r13
.fb_tl:
		mov	r7,r2
		shlr16	r2
		mulu	r2,r4
		mov	r5,r2	   		; Build column index
		sts	macl,r0
		shlr16	r2
		add	r2,r0
		mov.b	@(r0,r1),r0		; Read texture pixel
		and	#$FF,r0
		tst	r0,r0			; If 0 == blank
		bt	.blnkpixl
		add	r11,r0			; Add index increment
		mov	r0,r10

		mov	#320,r0			; write pixel
		cmp/ge	r0,r13
		bt	.hdn_line
		mov	r13,r0
		add	r9,r0
		add	r12,r0
		mov.b	r10,@r0
.hdn_line:
		mov	r13,r0
		add	r9,r0
		mov.b	r10,@r0
.blnkpixl:
		add	#1,r13
		add	r6,r5			; Update X
		dt	r3
		bf/s	.tex2_xloop
		add	r8,r7			; Update Y
.tex_skip_line:
		mov	#Cach_SprBkup_LB,r0
		mov	@r0+,r11
		mov	@r0+,r10
		mov	@r0+,r9
		mov	@r0+,r8
		mov	@r0+,r7
		mov	@r0+,r6
		mov	@r0+,r5
		mov	@r0+,r4
		mov	@r0+,r3
		mov	@r0+,r2
		mov	@r0+,r1
.drwsld_updline_tex:
		mov	@(plypz_src_xl_dx,r11),r0	; Update DX postions
		add	r0,r5
		mov	@(plypz_src_xr_dx,r11),r0
		add	r0,r6
		mov	@(plypz_src_yl_dx,r11),r0
		add	r0,r7
		mov	@(plypz_src_yr_dx,r11),r0
		add	r0,r8
		add	r2,r1				; Update X postions
		dt	r10
		bt/s	.drwtex_gonxtpz
		add	r4,r3
		bra	.drwsld_nxtline_tex
		add	#1,r9
; 		xor	r0,r0
; 		mov	r0,@(plypz_ytb,r11)
.drwtex_gonxtpz:
		mov	@(marsGbl_PlyPzList_R,gbr),r0
		mov	r0,r11
		add	#sizeof_plypz,r11		; And set new point
		mov	r11,r0
		mov	#RAM_Mars_SVdpDrwList_e,r11	; End-of-list?
		cmp/ge	r11,r0
		bf	.reset_rd
		mov	#RAM_Mars_SVdpDrwList,r0
.reset_rd:
		mov	r0,@(marsGbl_PlyPzList_R,gbr)
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0	; Decrement piece
		add	#-1,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
		bra	MarsVideo_DrawSuperSpr
		nop
		align 4
.finish_it:
.drwtask_exit:
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------
; MarsVideo_DrawScaled
;
; For graphics mode 3: This draws the
; main image with specific settings
; --------------------------------------------------------

	; MAIN scaler
	; r1 - X pos xxxx.0000
	; r2 - Y pos yyyy.0000
	; r3 - X dx  xxxx.0000
	; r4 - Y dx  yyyy.0000
	; r5 - Source WIDTH
	; r6 - Source HEIGHT
	; r7 - Source DATA
	; r8 - Output
	; r9 - Loop: Line width / 2
	; r10 - Loop: Number of lines
		align 4
MarsVideo_DrawScaled:
; 		mov	#RAM_Mars_BgBuffScale_M,r14
		mov	#RAM_Mars_DreqRead+Dreq_ScrnBuff,r14
		mov	#_framebuffer+$200,r13	; r13 - Output
		mov	@r14+,r7		; r7 - Input
		mov	@r14+,r1		; r1 - X pos (2 pixels wide)
		mov	@r14+,r2		; r2 - Y pos
		mov	@r14+,r5		; r5 - X width
		mov	@r14+,r6		; r6 - Y height
		mov	@r14+,r3		; r3 - DX
		mov	@r14+,r4		; r4 - DY
		mov	@r14+,r9		; r9 - Mode
		mov	#TH,r0			; Force source as Cache-Thru
		or	r0,r7
		shll16	r5
		shll16	r6
		dmuls	r1,r5			; Topleft X/Y calc
		sts	mach,r0
		sts	macl,r1
		xtrct	r0,r1
		dmuls	r2,r6
		sts	mach,r0
		sts	macl,r2
		xtrct	r0,r2
		lds	r9,mach			; mach - mode number
		mov	#320/2,r9		; r9  - X loop
		mov	#240,r10		; r10 - Y loop

	; X check
		sts	mach,r0
		tst	r0,r0
		bt	.x_cont
.x_fix:
		cmp/pz	r1
		bt	.x_cont
		bra	.x_fix
		add	r5,r1
.x_cont:


; *** LOOP
.y_loop:
		sts	mach,r0
		tst	r0,r0
		bt	.y_high
		cmp/pz	r2
		bt	.xy_set
		bra	.y_loop
		add	r6,r2
.xy_set:
		cmp/ge	r6,r2
		bf	.y_high
		bra	.xy_set
		sub	r6,r2
.y_high:
		mov	r1,r11
		shar	r11		; /2
		mov	r2,r0
		shlr16	r0
		mov	r5,r8
		shlr16	r8
		muls	r8,r0
		sts	macl,r12
		add	r7,r12
		mov	r13,r8
		mov	r9,r14
.x_loop:
	; 00 - single scale
		sts	mach,r0
		tst	r0,r0
		bf	.x_rept
		cmp/pz	r11
		bt	.xwpos
		bra	.x_next
		mov	#0,r0
.xwpos:
		mov	r5,r0
		shar	r0		; /2
		cmp/ge	r0,r11
		bf	.x_go
		bra	.x_next
		mov	#0,r0
.x_go:
		mov	#0,r0
		cmp/pz	r2		; <-- TODO: checar bien esto
		bf	.x_next
		cmp/ge	r6,r2
		bt	.x_next
		bra	.x_high
		nop
.x_rept:
	; 01 - repeat check
		mov	r5,r0
		shar	r0		; /2
		cmp/pl	r11
		bt	.xwpos2
.x_loopm:	cmp/ge	r0,r11
		bt	.x_high
		bra	.x_loopm
		add	r0,r11
.xwpos2:
		cmp/ge	r0,r11
		bf	.x_high
		bra	.xwpos2
		sub	r0,r11
.x_high:
		mov	r11,r0
		shlr16	r0
		exts	r0,r0
		shll	r0
		mov.w	@(r12,r0),r0
.x_next:
		add	r3,r11
		mov.w	r0,@r8
		dt	r14
		bf/s	.x_loop
		add	#2,r8
		add	r4,r2
		mov	#320,r0
		dt	r10
		bf/s	.y_loop
		add	r0,r13
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------

		align 4
Cach_PzCopy	ds.b sizeof_plypz
Cach_Intrl_W	ds.l 1		; *** KEEP THIS IN THIS ORDER
Cach_Intrl_H	ds.l 1
Cach_FbPos_Y	ds.l 1
Cach_FbPos	ds.l 1
Cach_FbData	ds.l 1
Cach_Intrl_Size	ds.l 1		; ***

Cach_SprBkup_LB	ds.l 11
Cach_SprBkup_S	ds.l 0		; <-- Reads backwards
Cach_XHead_L	ds.l 1		; Left draw beam
Cach_XHead_R	ds.l 1		; Right draw beam
Cach_YHead_U	ds.l 1		; Top draw beam
Cach_YHead_D	ds.l 1		; Bottom draw beam
Cach_BgFbPos_V	ds.l 1		; Framebuffer Y DIRECT position (then multiply with internal WIDTH)
Cach_BgFbPos_H	ds.l 1		; Framebuffer TOPLEFT position

; ------------------------------------------------
.end:		phase CACHE_MSTR_SCRL+.end&$1FFF
		align 4
CACHE_MSTR_SCRL_E:
	if MOMPASS=6
		message "THIS CACHE CODE uses: \{(CACHE_MSTR_SCRL_E-CACHE_MSTR_SCRL)}"
	endif
