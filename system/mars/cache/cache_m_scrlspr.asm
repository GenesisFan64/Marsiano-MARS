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

; TODO: mover el MarsVideo_SprBlkRefill aqui y
; que avance por piezas

		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
; 		mov	#Cach_SprBkup_S,r0
; 		mov	r2,@-r0
; 		mov	r3,@-r0
; 		mov	r4,@-r0
; 		mov	r5,@-r0
; 		mov	r6,@-r0
; 		mov	r7,@-r0
; 		mov	r8,@-r0
; 		mov	r9,@-r0
; 		mov	r10,@-r0
; 		sts	macl,@-r0
; 		sts	mach,@-r0

; 		mov	#Cach_SprBkup_LB,r0
; 		lds	@r0+,mach
; 		lds	@r0+,macl
; 		mov	@r0+,r10
; 		mov	@r0+,r9
; 		mov	@r0+,r8
; 		mov	@r0+,r7
; 		mov	@r0+,r6
; 		mov	@r0+,r5
; 		mov	@r0+,r4
; 		mov	@r0+,r3
; 		mov	@r0+,r2
		mov	#1,r0
		mov.w	r0,@(marsGbl_WdgStatus,gbr)
		mov	#$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		rts
		nop
		align 4
		ltorg

; 	; NEXT
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
; .finish_now:
; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_WdgStatus,gbr)
; 		mov	#$FFFFFE80,r1			; Stop watchdog
; 		mov.w   #$A518,r0
; 		mov.w   r0,@r1
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Mode 2: Scrolling background
; ----------------------------------------------------------------

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
		mov	@(mbg_intrl_size,r14),r5	;  r5 - internal WIDTH*HEIGHT
		neg	r7,r6				;  r6 - block limit bits
		mov	#320,r4			;  r4 - max
; 		sub	r7,r4
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
		cmp/ge	r1,r6
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
; MarsVideo_DrawScrlLR
;
; Draws the left and right sides of
; the scrolling background on movement
; --------------------------------------------------------

		align 4
MarsVideo_DrawScrlLR:
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	#RAM_Mars_LR_Pixels,r13
		mov	@(mbg_intrl_size,r14),r0
		mov	r0,r6
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r7
		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r8
		mov.w	@(mbg_intrl_w,r14),r0
		mov	r0,r9
		mov	@(mbg_fbdata,r14),r4
		mov	#Cach_BgFbPos_V,r10
		mov	@r10,r10
		mov	#Cach_BgFbPos_H,r11
		mov	@r11,r11
		mov	#_framebuffer,r12
		add	r4,r12
		mov	r9,r5
		sub	r7,r5
		mov.w	@(marsGbl_BgDrwR,gbr),r0
		tst	r0,r0
		bf	.right
		mov.w	@(marsGbl_BgDrwL,gbr),r0
		tst	r0,r0
		bf	.left
		rts
		nop
		align 4
.left:
		dt	r0
		bra	.start
		mov.w	r0,@(marsGbl_BgDrwL,gbr)
.right:
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwR,gbr)
		add	r5,r11
.start:
		mulu	r9,r10
		sts	macl,r0
		add	r0,r11
.y_line:
		cmp/ge	r6,r11
		bf	.x_max
		sub	r6,r11
.x_max:
		mov	r13,r1
		mov	r11,r2
		mov	r7,r3
		shlr2	r3
		mov	r2,r4
		mov	r3,r5
		add	r12,r2
.x_line:
		mov	@r1+,r0
		mov	r0,@r2
		dt	r3
		bf/s	.x_line
		add	#4,r2
		mov	#320,r0	; extra line
		cmp/ge	r0,r4
		bt	.no_ex
		mov	r13,r1
		add	r6,r4
		add	r12,r4
		nop
.xlne_2:
		mov	@r1+,r0
		mov	r0,@r4
		dt	r5
		bf/s	.xlne_2
		add	#4,r4
.no_ex:
		add	r9,r11
		dt	r8
		bf/s	.y_line
		add	#32,r13		; next RAM line
.bad_size:
		rts
		nop
		align 4

; --------------------------------------------------------
; MarsVideo_DrawScrlUD
;
; Draws the top and bottom sides of the background on
; movement
; --------------------------------------------------------

		align 4
MarsVideo_DrawScrlUD:
		mov	#RAM_Mars_BgBuffScrl,r14
		mov	#RAM_Mars_UD_Pixels,r13
		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r6
		mov	@(mbg_intrl_size,r14),r0
		mov	r0,r7
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r8
		mov.w	@(mbg_intrl_w,r14),r0
		mov	r0,r9
		mov	@(mbg_fbdata,r14),r4
		mov	#Cach_BgFbPos_V,r10
		mov	@r10,r10
		mov	#Cach_BgFbPos_H,r11
		mov	@r11,r11
		mov	#_framebuffer,r12
		add	r4,r12
		mov	r6,r5
		sub	r8,r5
		mov.w	@(marsGbl_BgDrwD,gbr),r0
		tst	r0,r0
		bf	.right
		mov.w	@(marsGbl_BgDrwU,gbr),r0
		tst	r0,r0
		bf	.left
		rts
		nop
		align 4
.left:
		dt	r0
		bra	.start
		mov.w	r0,@(marsGbl_BgDrwU,gbr)
.right:
		dt	r0
		mov.w	r0,@(marsGbl_BgDrwD,gbr)
		add	r5,r10
.start:
		cmp/ge	r6,r10
		bf	.x_max2
		sub	r6,r10
.x_max2:
		mulu	r9,r10		; macl - FB topleft
		xor	r5,r5		; r5 - counter
.nxt_blk:
		sts	macl,r10
		lds	r5,mach
		mov	r8,r6
		mov	#320,r5
.y_line:
		mov	r13,r1
		mov	r10,r4
		add	r11,r4
		mov	r8,r3
		shlr2	r3
.x_line:
		mov	@r1+,r0
		cmp/ge	r7,r4
		bf	.x_max
		sub	r7,r4
.x_max:
		cmp/ge	r5,r4
		bt	.x_hdn
		mov	r4,r2
		add	r12,r2
		add	r7,r2
		mov	r0,@r2
.x_hdn:
		mov	r4,r2
		add	r12,r2
		mov	r0,@r2
		dt	r3
		bf/s	.x_line
		add	#4,r4

		add	r9,r10
		dt	r6
		bf/s	.y_line
		add	#32,r13
		sts	mach,r5
		add	r8,r5
		cmp/ge	r9,r5
		bf/s	.nxt_blk
		add	r8,r11
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Super sprites
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_DrwSprBlk
;
; r14 - List of sprite-redraw pieces
; r13 - Background buffer to use
;
; - Call this BEFORE updating the X/Y background positions
; - Then CALL MarsVideo_MarkSprBlocks AFTER drawing
;   the sprites on the current framebuffer.
; --------------------------------------------------------

		align 4
MarsVideo_DrwSprBlk:
		sts	pr,@-r15

		mov	#_framebuffer,r12
		mov	@(mbg_fbdata,r13),r0
		add	r0,r12
		mov	@(mbg_data,r13),r0
		lds	r0,mach
		mov.w	@(mbg_intrl_blk,r13),r0
		mov	r0,r11
		mov	@(mbg_intrl_size,r13),r0
		mov	r0,r10
		mov.w	@(mbg_intrl_h,r13),r0
		mov	r0,r9
		mov.w	@(mbg_intrl_w,r13),r0
		mov	r0,r8
		mov.w	@(mbg_height,r13),r0
		mov	r0,r7
		mov.w	@(mbg_width,r13),r0
		mov	r0,r6
		mov	@(mbg_fbpos,r13),r5
		neg	r11,r1
		mov.w	@(mbg_ypos_old,r13),r0	; <-- use OLD position
		exts.w	r0,r4
		mov.w	@(mbg_xpos_old,r13),r0	; <-- use OLD position
		exts.w	r0,r3
		mov.w	@(mbg_fbpos_y,r13),r0
		mov	r0,r2
		exts.w	r4,r4
		exts.w	r3,r3
.xin:
		cmp/pz	r3
		bt	.xp_t
		bra	.xin
		add	r6,r3
.xp_t:
		cmp/gt	r6,r3
		bf	.xp_b
		bra	.xp_t
		sub	r6,r3
.xp_b:
		cmp/pz	r4
		bt	.yp_t
		bra	.xp_b
		add	r7,r4
.yp_t:
		cmp/gt	r7,r4
		bf	.yp_b
		bra	.yp_t
		sub	r7,r4
.yp_b:

		and	r1,r2
		and	r1,r5
		mulu	r8,r2
		sts	macl,r0
		add	r0,r5
		and	r1,r5
		and	r1,r4
		and	r1,r3
		cmp/ge	r10,r5
		bf	.fb_ovri
		sub	r10,r5
.fb_ovri:

	; mach - Image pixel-data
	;  r14 - Block-redraw list TOP
	;  r13 - Block-redraw list BOTTOM
	;  r12 - Framebuffer+FbBase
	;  r11 - Block size
	;  r10 - BG internal scroll size (W*H)
	;   r9 - BG internal scroll height
	;   r8 - BG internal scroll width
	;   r7 - Image height
	;   r6 - Image width
	;   r5 - Background internal X+Y position
	;   r4 - Background camera Y pos
	;   r3 - Background camera X pos
	;   r2 - Y read
	;   r1 - X read
	;
	;   Index format:
	;   %EEyyyyyy xxxxxxxx wwwwwwww hhhhhhhh
	;     y_pos/4  x_pos/4  width/4 height/4

.indx_read:
		mov	@r14,r0
		cmp/pz	r0
		bt	.end
		bsr	.mk_block
		mov	r0,r1
		xor	r0,r0
		mov	r0,@r14
		bra	.indx_read
		add	#4,r14
.end:
		lds	@r15+,pr
		rts
		nop
		align 4
.mk_block:
		mov	#Cach_SprBkup_S,r0
		mov	r1,@-r0
		mov	r2,@-r0
		mov	r3,@-r0
		mov	r4,@-r0
		mov	r5,@-r0
		mov	r8,@-r0
		mov	r9,@-r0
		mov	r11,@-r0
		mov	r13,@-r0
		mov	r14,@-r0

	; r14 - Y
	; r13 - X
		mov	r1,r2
		mov	r1,r14
		mov	r1,r13
		shlr8	r14
		extu.b	r14,r14
		extu.b	r13,r13


		shlr16	r1
		shlr16	r2
		mov	r2,r0
		shlr8	r0
		and	#$7F,r0
		extu.b	r0,r2
		extu.b	r1,r1
		shll2	r1
		shll2	r2
		shll2	r14
		shll2	r13
		sub	r2,r14
		sub	r1,r13
		mov	r5,r9
		mulu	r2,r8
		sts	macl,r0
		add	r0,r9
		add	r1,r9
		add	r3,r1
		add	r4,r2

.y_line:
		cmp/ge	r7,r2
		bf	.y_hght
		sub	r7,r2
.y_hght:
		mov	r1,r3
		mulu	r2,r6
		cmp/ge	r10,r9
		bf	.fb_m
		sub	r10,r9
.fb_m:
		mov	r13,r11
		shlr2	r11
		mov	r9,r5
.x_line:
		cmp/ge	r6,r3
		bf	.x_wdth
		sub	r6,r3
.x_wdth:
		sts	mach,r4
		sts	macl,r0
		add	r0,r4
		add	r3,r4
		mov	@r4,r0
		or	r4,r0	; TEST DOTS
		mov	r5,r4
		add	r12,r4
		mov	r0,@r4
		mov	#320,r4
		cmp/ge	r4,r5
		bt	.fb_ex
		mov	r5,r4
		add	r10,r4
		add	r12,r4
		mov	r0,@r4
.fb_ex:
		add	#4,r3
		dt	r11
		bf/s	.x_line
		add	#4,r5
		add	#1,r2
		dt	r14
		bf/s	.y_line
		add	r8,r9

		mov	#Cach_SprBkup_LB,r0
		mov	@r0+,r14
		mov	@r0+,r13
		mov	@r0+,r11
		mov	@r0+,r9
		mov	@r0+,r8
		mov	@r0+,r5
		mov	@r0+,r4
		mov	@r0+,r3
		mov	@r0+,r2
		mov	@r0+,r1
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
		mov	#RAM_Mars_DreqRead+Dreq_SuperSpr,r14
		mov	#Cach_Intrl_W,r11
		mov	@r11,r11
		mov	#Cach_Intrl_H,r10
		mov	@r10,r10
		mov	#Cach_Intrl_Size,r9
		mov	@r9,r9
		nop
MarsVideo_NxtSuprSpr:
		mov	@(marsspr_data,r14),r0
		tst	r0,r0
		bf	.valid
		rts
		nop
		align 4
.valid:
		mov	r14,@-r15

		mov	r14,r1		; Copy sprite to CACHE
		mov	#Cach_SprCopy,r14
		mov	r14,r2
	rept sizeof_marsspr/4
		mov	@r1+,r0
		mov	r0,@r2
		add	#4,r2
; 		nop
	endm
		nop
		mov.w	@(marsspr_indx,r14),r0
		mov	r0,r12
		mov.w	@(marsspr_x,r14),r0
		exts.w	r0,r5
		mov.w	@(marsspr_y,r14),r0
		exts.w	r0,r6
		mov.w	@(marsspr_xs,r14),r0
		exts.w	r0,r7
		mov.w	@(marsspr_ys,r14),r0
		exts.w	r0,r8
		mov	r7,r3			; Copy old XS / YS
		mov	r8,r4
		add	r5,r7
		add	r6,r8
		cmp/pl	r8
		bf	.spr_out
		cmp/pl	r7
		bf	.spr_out
		cmp/ge	r11,r5
		bt	.spr_out
		cmp/ge	r10,r6
		bt	.spr_out

		mov.w	@(marsspr_dwidth,r14),r0
		mov	r0,r1
		mov.w	@(marsspr_xfrm,r14),r0	; X frame
		mov	r0,r2
		mov	@(marsspr_data,r14),r13
		shlr8	r0
		and	#$FF,r0
		mulu	r3,r0
		sts	macl,r0
		add	r0,r13
		mov	r2,r0			; Y frame
		and	#$FF,r0
		mulu	r4,r0
		sts	macl,r0
		mulu	r1,r0
		sts	macl,r0
		add	r0,r13
		cmp/pz	r6
		bt	.yt_e
		neg	r6,r0
		xor	r6,r6
		muls	r0,r1
		sts	macl,r0
		add	r0,r13
.yt_e:
		cmp/pz	r5
		bt	.xt_e
		sub	r5,r13
		xor	r5,r5
.xt_e:
		mov	#320,r0
		cmp/ge	r0,r7
		bf	.xb_e
		mov	r0,r7
.xb_e:
; 		mov	#240,r0
		mov	#224,r0
		cmp/ge	r0,r8
		bf	.yb_e
		mov	r0,r8
.yb_e:
		mov	#Cach_FbPos_Y,r4
		mov	#Cach_FbPos,r3
		mov	@r4,r4
		add	r6,r4
		cmp/ge	r10,r4
		bf	.y_snap
		sub	r10,r4
.y_snap:
		mulu	r11,r4
		mov	@r3,r3
		sts	macl,r4
		add	r3,r4
		mov	#Cach_FbData,r1
		mov	@r1,r1
		mov	#_framebuffer,r0
		add	r1,r0
		lds	r0,mach
		nop

	; mach - _framebuffer + base
	;  r14 - Sprite data
	;  r13 - Texture data
	;  r12 - Texture index
	;  r11 - Internal WIDTH
	;  r10 - Internal HEIGHT
	;   r9 - Internal WIDTH+HEIGHT
	;   r8 - Y End
	;   r7 - X End
	;   r6 - Y Start
	;   r5 - X Start
	;
	; *** start ***
.y_loop:
		cmp/ge	r9,r4			; Wrap FB output
		bf	.y_max
		sub	r9,r4
.y_max:
		mov	r13,r1			; r1 - Texture IN
		mov	r5,r2			; r2 - X counter
.x_loop:
		mov.b	@r1,r0			; r0 - pixel
		tst	r0,r0			; blank pixel 0?
		bt	.blnk
		add	r12,r0			; add pixel increment
.blnk:
		sts	mach,r3			; r3 - Framebuffer + FbData
		add	r4,r3			; add top-left position
		add	r2,r3			; add X position
		mov.b	r0,@r3			; Write pixel
		mov	#320,r0			; Check for hidden line (X < 320)
		cmp/ge	r2,r0
		bt	.ex_line
		mov.b	@r1,r0			; Repeat same thing but
		tst	r0,r0			; but add r9 to the
		bt	.blnk2			; destination
		add	r12,r0
.blnk2:
		sts	mach,r3
		add	r4,r3
		add	r2,r3
		add	r9,r3
		mov.b	r0,@r3
.ex_line:
		add	#1,r2			; Increment X pos
		cmp/ge	r7,r2
		bf/s	.x_loop
		add	#1,r1			; Increment texture pos

		mov.w	@(marsspr_dwidth,r14),r0
		add	r0,r13			; Next texture line
		add	#1,r6			; Increment loop Y
		cmp/ge	r8,r6			; Y start > Y end?
		bf/s	.y_loop
		add	r11,r4			; Next FB top-left line
.spr_out:
		mov	@r15+,r14
		bra	MarsVideo_NxtSuprSpr
		add 	#sizeof_marsspr,r14
		align 4
		ltorg

; 	;  r9 - Y TOP
; 	; r10 - Y BOTTOM
; 		mov.w	@(marsspr_y,r13),r0
; 		mov	r0,r9
; 		mov.w	@(marsspr_ys,r13),r0
; 		mov	r0,r10
; 		add	r9,r10
; 		cmp/eq	r9,r10				; if Top==Bottom, exit
; 		bt	.invld_y
; 		mov	#SCREEN_HEIGHT,r0		; if Top > 224, skip
; 		cmp/ge	r0,r9
; 		bt	.invld_y			; if Bottom > 224, add max limit
; 		cmp/gt	r0,r10
; 		bf	.len_max
; 		mov	r0,r10
; .len_max:
; 		sub	r9,r10				; Turn r10 into line lenght (Bottom - Top)
; 		cmp/pl	r10
; 		bt	.drwtsk1_vld_y
; .invld_y:
; 		bra	.drwtex_gonxtpz			; if LEN < 0 then check next one...
; 		nop
; .no_pz:
; 		bra	.drwtask_exit
; 		nop
; 		align 4
;
; ; ------------------------------------
; ; Texture mode
; ;
; ; r1  - XL
; ; r2  - XL DX
; ; r3  - XR
; ; r4  - XR DX
; ; r5  - SRC XL
; ; r6  - SRC XR
; ; r7  - SRC YL
; ; r8  - SRC YR
; ; r9  - Y current
; ; r10  - Y length
; ; ------------------------------------
;
; .drwtsk1_vld_y:
; 		mov.w	@(marsspr_x,r13),r0
; 		mov	r0,r1
; 		mov.w	@(marsspr_xs,r13),r0
; 		mov	r0,r3
; 		add	r1,r3
; 		shll16	r1
; 		shll16	r3
;
; 		xor	r2,r2				; r2/r4 - DST DX XL / DX XR
; 		xor	r4,r4
;
; 	; SRC pos go here
; 		mov	#0,r5
; 		mov	#32<<16,r6
; 		mov	#0,r7
; 		mov	#0,r8
; .drwsld_nxtline_tex:
; 		cmp/pz	r9		; Y Start below 0?
; 		bf	.go_nxtline
; 		mov	.tag_yhght,r0	; Y Start after 224?
; 		cmp/ge	r0,r10
; 		bf	.valid_y
; 		bra	.drwtex_gonxtpz
; 		nop
; 		align 4
; .go_nxtline:
; 		bra	.drwsld_updline_tex
; 		nop
; 		align 4
; .tag_yhght:	dc.l SCREEN_HEIGHT
; .valid_y:
; 		mov	#Cach_SprBkup_S,r0
; 		mov	r1,@-r0
; 		mov	r2,@-r0
; 		mov	r3,@-r0
; 		mov	r4,@-r0
; 		mov	r5,@-r0
; 		mov	r6,@-r0
; 		mov	r7,@-r0
; 		mov	r8,@-r0
; 		mov	r9,@-r0
; 		mov	r10,@-r0
; 		mov	r11,@-r0
; 		mov	r12,@-r0
; 		mov	r13,@-r0
;
; 		shlr16	r1			; r1 - X left
; 		shlr16	r3			; r3 - X right
; 		exts	r1,r1
; 		exts	r3,r3
; 		mov	r3,r0			; r0: X Right - X Left
; 		sub	r1,r0
; 		cmp/pl	r0			; Line reversed?
; 		bt	.txrevers
; 		mov	r3,r0			; Swap XL and XR values
; 		mov	r1,r3
; 		mov	r0,r1
; 		mov	r5,r0
; 		mov	r6,r5
; 		mov	r0,r6
; 		mov	r7,r0
; 		mov	r8,r7
; 		mov	r0,r8
; .txrevers:
; 		cmp/eq	r1,r3				; Same X position?
; 		bt	.tex_skip_line
; 		mov	#SCREEN_WIDTH,r0		; X right < 0?
; 		cmp/pl	r3
; 		bf	.tex_skip_line
; 		cmp/gt	r0,r1				; X left > 320?
; 		bt	.tex_skip_line
; 		mov	r3,r2
; 		sub 	r1,r2		; r2 - (XL - XR)
; 		sub	r5,r6		; r6 - (XR - XL)
; 		mov	#_JR,r0				; r6 / r2
; 		mov	r2,@r0
; 		mov	r6,@(4,r0)
; 		nop
; 		mov	@(4,r0),r6			; r8 / r2
;
; 		mov	r10,r0
; 		add	r9,r0
; 		mov	r0,r2
; 		sub 	r9,r2		; r2 - (XL - XR)
; 		sub	r7,r8		; r8 - (YB - YT)
; 		mov	r2,@r0
; 		mov	r8,@(4,r0)
; 		nop
; 		mov	@(4,r0),r8
;
; 	; Limit X destination points
; 	; and correct the texture's X positions
; 		mov	#SCREEN_WIDTH,r0		; XR point > 320?
; 		cmp/gt	r0,r3
; 		bf	.tr_fix
; 		mov	r0,r3				; Force XR to 320
; .tr_fix:
; 		cmp/pl	r1				; XL point < 0?
; 		bt	.tl_fix
; 		neg	r1,r2				; Fix texture positions
; 		dmuls	r6,r2
; 		sts	macl,r0
; 		add	r0,r5
; ; 		dmuls	r8,r2
; ; 		sts	macl,r0
; ; 		add	r0,r7
; 		xor	r1,r1				; And reset XL to 0
; .tl_fix:
;
; 	; start
; 		sub 	r1,r3				; r3 - X line width
; 		cmp/pl	r3
; 		bf	.tex_skip_line
; 		mov	#Cach_Intrl_W,r2
; 		mov	@r2+,r11		; Y width
; 		mov	@r2+,r12		; Y height
; 		mov	@r2+,r0			; Y base pos
; 		add	r9,r0
; 		cmp/ge	r12,r0
; 		bf	.y_tp
; 		sub	r12,r0
; .y_tp:
; 		muls	r0,r11
; 		sts	macl,r0
; 		mov	@r2+,r11		; x pos
; 		add	r1,r11
; 		add	r0,r11
; 		mov	@r2+,r0			; data
; 		mov	@r2+,r12		; size
; 		mov	#_overwrite,r9
; 		add	r0,r9
;
; 		mov	@(marsspr_data,r13),r1
; 		mov.w	@(marsspr_dwidth,r13),r0
; 		mov	r0,r4
; 		mov.w	@(marsspr_indx,r13),r0
; 		mov	r0,r13
; .tex2_xloop:
; 		cmp/ge	r12,r11
; 		bf	.fb_tl
; 		sub	r12,r11
; .fb_tl:
; 		mov	r7,r2
; 		shlr16	r2
; 		mulu	r2,r4
; 		mov	r5,r2	   		; Build column index
; 		sts	macl,r0
; 		shlr16	r2
; 		add	r2,r0
; 		mov.b	@(r0,r1),r0		; Read texture pixel
; 		and	#$FF,r0
; 		tst	r0,r0			; If 0 == blank
; 		bt	.blnkpixl
; 		add	r13,r0			; Add index increment
; 		mov	r0,r10
;
; 		mov	#320,r0			; write pixel
; 		cmp/ge	r0,r11
; 		bt	.hdn_line
; 		mov	r11,r0
; 		add	r9,r0
; 		add	r12,r0
; 		mov.b	r10,@r0
; .hdn_line:
; 		mov	r11,r0
; 		add	r9,r0
; 		mov.b	r10,@r0
; .blnkpixl:
; 		add	#1,r11
; 		dt	r3
; 		bf/s	.tex2_xloop
; 		add	r6,r5			; Update X
; .tex_skip_line:
; 		mov	#Cach_SprBkup_LB,r0
; 		mov	@r0+,r13
; 		mov	@r0+,r12
; 		mov	@r0+,r11
; 		mov	@r0+,r10
; 		mov	@r0+,r9
; 		mov	@r0+,r8
; 		mov	@r0+,r7
; 		mov	@r0+,r6
; 		mov	@r0+,r5
; 		mov	@r0+,r4
; 		mov	@r0+,r3
; 		mov	@r0+,r2
; 		mov	@r0+,r1
; .drwsld_updline_tex:
; ; 		mov	@(plypz_src_xl_dx,r11),r0	; Update DX postions
; ; 		add	r0,r5
; ; 		mov	@(plypz_src_xr_dx,r11),r0
; ; 		add	r0,r6
; ; 		mov	@(plypz_src_yl_dx,r11),r0
; ; 		add	r0,r7
; ; 		mov	@(plypz_src_yr_dx,r11),r0
; ; 		add	r0,r8
; ; 		add	r2,r1				; Update X postions
;
; 		mov	#$10000,r0
; 		add	r0,r7
; 		add	r0,r8
;
; 		dt	r10
; 		bt/s	.drwtex_gonxtpz
; 		add	r4,r3
; 		bra	.drwsld_nxtline_tex
; 		add	#1,r9

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
Cach_XHead_L	ds.l 1		; ** Left draw beam
Cach_XHead_R	ds.l 1		; ** Right draw beam
Cach_YHead_U	ds.l 1		; ** Top draw beam
Cach_YHead_D	ds.l 1		; ** Bottom draw beam
Cach_BgFbPos_V	ds.l 1		; ** Framebuffer Y DIRECT position (then multiply with internal WIDTH)
Cach_BgFbPos_H	ds.l 1		; ** Framebuffer TOPLEFT position

Cach_FbData	ds.l 1		; *** KEEP THIS IN THIS ORDER
Cach_FbPos	ds.l 1
Cach_FbPos_Y	ds.l 1
Cach_Intrl_W	ds.l 1
Cach_Intrl_H	ds.l 1
Cach_Intrl_Size	ds.l 1		; ***
Cach_SprBkup_LB	ds.l 10
Cach_SprBkup_S	ds.l 0		; <-- Reads backwards
Cach_SprCopy	ds.b sizeof_plypz

; ------------------------------------------------
.end:		phase CACHE_MSTR_SCRL+.end&$1FFF
		align 4
CACHE_MSTR_SCRL_E:
	if MOMPASS=6
		message "THIS CACHE CODE uses: \{(CACHE_MSTR_SCRL_E-CACHE_MSTR_SCRL)}"
	endif
