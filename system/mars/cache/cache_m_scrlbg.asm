; ====================================================================
; ----------------------------------------------------------------
; CACHE code
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

		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#(Cach_WdgBuffWr+$20)-4,r1
		mov	@r1,r0				; Check U/D first
		tst	r0,r0
		bf	.draw_ud
		mov	#$20,r0				; <-- next timer
		sub	r0,r1
		mov	@r1,r0				; Check R/L
		tst	r0,r0
		bf	.draw_lr
.finish:
		mov	#0,r0
		mov.w	r0,@(marsGbl_WdgMode,gbr)
		mov	#$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		rts
		nop
		align 4

; ----------------------------------------
; Draw timer L/R
; ----------------------------------------

.draw_lr:
		dt	r0
		mov	r0,@r1
		mov	#Cach_WdBackup_S,r0
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
		mov	r12,@-r0
		mov	r13,@-r0
		mov	r14,@-r0
		sts	macl,@-r0

; $00 - Layout data (read)
; $04 - FB pos (read)
; $08 - Layout width (next block)
; $0C - FB width (next line)
; $10 - FB FULL size
; $14 - FB base
; $18 - Block data
; $1C - Block counter

		mov	#Cach_WdgBuffRd,r14
		mov	@($14,r14),r13		; r13 - FB base
		mov	@($10,r14),r12		; r12 - FB full size
		mov	@($0C,r14),r11		; r11 - FB width
		mov	@($04,r14),r10		; r10 - FB x/y pos
		mov	@($18,r14),r9		; r9 - Block data
		mov	@r14,r8			; r8 - Layout data
		mov	#320,r5
		mov.b	@r8,r0
		extu.b	r0,r0
		mov	#16*16,r1		; <-- Manual block size
		mulu	r0,r1
		sts	macl,r0
		add	r0,r9
		mov	#16,r7			; <-- Manual block size
.y_loop:
		cmp/ge	r12,r10
		bf	.lne_sz
		sub	r12,r10
.lne_sz:
		mov	r10,r3
		mov	#16,r6			; <-- Manual block size
		shlr2	r6
.x_loop:
		mov	r13,r4
		add	r3,r4
		mov	@r9+,r0
		mov	r0,@r4
		cmp/ge	r5,r3
		bt	.ex_line
		mov	r13,r4
		add	r3,r4
		add	r12,r4
		mov	r0,@r4
.ex_line:
		dt	r6
		bf/s	.x_loop
		add	#4,r3
		dt	r7
		bf/s	.y_loop
		add	r11,r10

		mov	@($08,r14),r0
		add	r0,r8
		mov	r8,@r14
		mov	r10,@($04,r14)	; Save FB pos

		mov	#Cach_WdBackup_L,r0
		lds	@r0+,macl
		mov	@r0+,r14
		mov	@r0+,r13
		mov	@r0+,r12
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
		bra	.next_wd
		nop

; ----------------------------------------
; Draw timer U/D
; ----------------------------------------

.draw_ud:
		dt	r0
		mov	r0,@r1
		mov	#Cach_WdBackup_S,r0
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
		mov	r12,@-r0
		mov	r13,@-r0
		mov	r14,@-r0
		sts	macl,@-r0

; $00 - Layout data (read)
; $04 - FB pos (read)
; $08 - Layout width (next block)
; $0C - FB width (next line)
; $10 - FB FULL size
; $14 - FB base
; $18 - Block data
; $1C - Block counter

		mov	#Cach_WdgBuffRd_UD,r14
		mov	@($14,r14),r13		; r13 - FB base
		mov	@($10,r14),r12		; r12 - FB full size
		mov	@($0C,r14),r11		; r11 - FB width
		mov	@($04,r14),r10		; r10 - FB x/y pos
		mov	@($18,r14),r9		; r9 - Block data
		mov	@r14,r8			; r8 - Layout data
		mov	#320,r5
		mov.b	@r8,r0
		extu.b	r0,r0
		mov	#16*16,r1		; <-- Manual block size
		mulu	r0,r1
		sts	macl,r0
		add	r0,r9
		mov	#16,r7			; <-- Manual block size

		lds	r10,macl
.y_loopud:
		cmp/ge	r12,r10
		bf	.lne_szud
		sub	r12,r10
.lne_szud:
		mov	r10,r3
		mov	#16,r6			; <-- Manual block size
		shlr2	r6
.x_loopud:
		mov	r13,r4
		add	r3,r4
		mov	@r9+,r0
		mov	r0,@r4
		cmp/ge	r5,r3
		bt	.exy_lineud
		mov	r13,r4
		add	r3,r4
		add	r12,r4
		mov	r0,@r4
.exy_lineud:
		dt	r6
		bf/s	.x_loopud
		add	#4,r3
		dt	r7
		bf/s	.y_loopud
		add	r11,r10
		sts	macl,r10

		mov	@($08,r14),r0
		add	#1,r8
		mov	r8,@r14
		mov	#16,r0
		add	r0,r10
		mov	r10,@($04,r14)	; Save FB pos

		mov	#Cach_WdBackup_L,r0
		lds	@r0+,macl
		mov	@r0+,r14
		mov	@r0+,r13
		mov	@r0+,r12
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

; ----------------------------------------

.next_wd:
		mov	#$FFFFFE80,r1
		mov.w   #$A518,r0		; OFF
		mov.w   r0,@r1
		or      #$20,r0			; ON
		mov.w   r0,@r1
		mov.w   #$5A20,r0		; Timer for the next WD
		mov.w   r0,@r1
		rts
		nop
		align 4

		ltorg

; 	; NEXT ENTER
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
; 		mov	#$FFFFFE80,r1		; Stop watchdog
; 		mov.w   #$A518,r0
; 		mov.w   r0,@r1
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Drawing routines for the smooth-scrolling background
;
; NOTE: NO RV-ROM PROTECTION
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_DrawAll
;
; Draws the entire map into the current section of
; the Framebuffer.
;
; NOTE: Call this TWICE to draw on BOTH Framebuffers.
;
; Input:
; r14 | Scrolling section (Output)
; r13 | Background buffer (Input)
;
; Breaks:
; ALL
; --------------------------------------------------------

		align 4
MarsVideo_DrawAll:
		sts	pr,@-r15
		mov	r14,@-r15
		mov	r13,@-r15
		mov	@(scrl_intrl_size,r13),r12
		mov	#_framebuffer,r5
		mov.w	@(scrl_intrl_w,r13),r0
		extu.w	r0,r11
		mov.w	@(scrl_intrl_h,r13),r0
		extu.w	r0,r10
		mov	@(scrl_fbdata,r13),r0
		add	r0,r5
		mov	@(md_bg_x,r14),r1
		shlr16	r1
		mov	@(md_bg_y,r14),r2
		shlr16	r2
		mov	@(md_bg_blk,r14),r9
		exts.w	r1,r1
		mov	@(md_bg_low,r14),r8
		exts.w	r2,r2
		mov.b	@(md_bg_bw,r14),r0
		extu.b	r0,r3
		mov.b	@(md_bg_bh,r14),r0
		extu.b	r0,r4
		mov.w	@(md_bg_w,r14),r0
		extu.w	r0,r7
		mov.w	@(md_bg_h,r14),r0
		extu.w	r0,r6
		lds	r5,mach

		mov	#-16,r0			; <- manual size
		and	r0,r1
		and	r0,r2

	; TODO: X/Y map wrap check
		mulu	r3,r1
		sts	macl,r0
		shlr8	r0
		add	r0,r8
		mulu	r4,r2
		sts	macl,r0
		shlr8	r0
		mulu	r7,r0
		sts	macl,r0
		add	r0,r8

.x_in:
		cmp/pl	r1		; X set
		bt	.x_pl
		bra	.x_in
		add	r12,r1		; <-- full size
.x_pl:
		cmp/ge	r12,r1
		bf	.x_fl
		bra	.x_pl
		sub	r12,r1
.x_fl:
		cmp/pl	r2		; Y set
		bt	.y_pl
		bra	.x_fl
		add	r10,r2
.y_pl:
		cmp/ge	r10,r2
		bf	.y_fl
		bra	.y_pl
		sub	r10,r2
.y_fl:
		mulu	r11,r2
		sts	macl,r2
		mov	r2,r5
		add	r1,r5

	; mach - _framebuffer area
	;  r12 - FULL Scroll area size
	;  r11 - Scroll area width
	;  r10 - Scroll area height
	;   r9 - Block graphics data
	;   r8 - Map data
	;   r7 - Map width
	;   r6 - Map height
	;   r5 - Current FB top

		mov	#16,r0			; <- manual size
		mulu	r10,r0
		sts	macl,r2
		shlr8	r2
.y_loop:
		mov	#Cach_InRead_S,r0
		mov	r5,@-r0
		mov	r8,@-r0
		cmp/ge	r12,r5
		bf	.xy_g
		sub	r12,r5
.xy_g:
		mov	#16,r0
		mulu	r11,r0
		sts	macl,r3
		shlr8	r3
.x_loop:
		bsr	.this_blk
		mov.b	@r8+,r0
		mov	#16,r0			; <- manual size
		dt	r3
		bf/s	.x_loop
		add	r0,r5
		mov	#Cach_InRead_L,r0
		mov	@r0+,r8
		mov	@r0+,r5

		mov	#16,r0			; <- manual size
		mulu	r11,r0
		sts	macl,r0
		add	r0,r5
		add	r7,r8
		dt	r2
		bf	.y_loop

		mov	@r15+,r13
		mov	@r15+,r14
		lds	@r15+,pr
		rts
		nop
		align 4
.this_blk:
		extu.b	r0,r0
		mov	#16*16,r1		; <- manual size
		mulu	r1,r0
		mov	#Cach_BlkBackup_S,r0
		mov	r2,@-r0
		mov	r3,@-r0
		mov	r4,@-r0
		mov	r5,@-r0
		mov	r6,@-r0
		mov	r9,@-r0
		sts	macl,r0
		add	r0,r9
		mov	#16,r4			; <- manual size
.yb_line:
		cmp/ge	r12,r5
		bf	.xy_g2
		sub	r12,r5
.xy_g2:
		mov	r5,r2
		mov	#16,r3			; <- manual size
		shlr2	r3
.xb_line:
		sts	mach,r1
		add	r2,r1
		mov	@r9,r0
		mov	r0,@r1
		mov	#320,r0
		cmp/ge	r0,r2
		bt	.x_ex
		sts	mach,r1
		add	r2,r1
		add	r12,r1
		mov	@r9,r0
		mov	r0,@r1
.x_ex:
		add	#4,r9
		dt	r3
		bf/s	.xb_line
		add	#4,r2
		dt	r4
		bf/s	.yb_line
		add	r11,r5

		mov	#Cach_BlkBackup_L,r0
		mov	@r0+,r9
		mov	@r0+,r6
		mov	@r0+,r5
		mov	@r0+,r4
		mov	@r0+,r3
		mov	@r0+,r2
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; Drawing routines for the Super-sprites
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_DrawSuperSpr
;
; Draws the Super-sprites directly recieved on DREQ
;
; Call MarsVideo_SetSuperSpr FIRST to setup the
; main screen coordinates
;
; Input:
; r14 - Super sprites data
;
; Breaks:
; ALL
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
		mov.w	@(marsspr_indx,r14),r0
		mov	r0,r12
		mov.w	@(marsspr_x,r14),r0
		exts.w	r0,r5
		mov.w	@(marsspr_y,r14),r0
		exts.w	r0,r6
		mov.b	@(marsspr_xs,r14),r0
		exts.b	r0,r7
		mov.b	@(marsspr_ys,r14),r0
		exts.b	r0,r8
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
		mulu	r1,r4
		sts	macl,r4
		extu.b	r0,r0
		mulu	r4,r0
		sts	macl,r0
		add	r0,r13
		mov	r2,r0
		shlr8	r0
		extu.b	r0,r0
		mulu	r3,r0
		sts	macl,r0
		add	r0,r13
	; XR / YB
		mov	#320,r0
		cmp/ge	r0,r7
		bf	.xb_e
		mov	r0,r7
.xb_e:
		mov	#224,r0
		cmp/ge	r0,r8
		bf	.yb_e
		mov	r0,r8
.yb_e:
		mov	#Cach_FbData,r2
		mov	@r2,r2
		mov	#_framebuffer,r0
		add	r2,r0
		lds	r0,mach
		mov.w	@(marsspr_dwidth,r14),r0
		extu.w	r0,r2
		mov.w	@(marsspr_flags,r14),r0
		tst	#%10,r0		; Y flip?
		bt	.flp_v
		add	r4,r13
		sub	r2,r13
		neg	r2,r2
.flp_v:
		mov	#1,r4
		tst	#%01,r0		; X flip?
		bt	.flp_h
		add	r3,r13		; move beam
		mov	#-1,r4		; decrement line
.flp_h:
		cmp/pz	r6
		bt	.yt_e
		neg	r6,r0
		xor	r6,r6
		muls	r0,r1
		sts	macl,r0
		cmp/pz	r2
		bt	.yfinc
		neg	r0,r0
.yfinc:
		add	r0,r13
.yt_e:
		cmp/pz	r5
		bt	.xt_e
		mov	r5,r0
		cmp/pz	r4
		bt	.xfinc
		neg	r0,r0
.xfinc:
		sub	r0,r13
		xor	r5,r5
.xt_e:
		extu.w	r4,r0
		shll16	r2
		or	r2,r0
		mov	#Cach_FbPos_Y,r4
		mov	#Cach_FbPos,r2
		mov	@r4,r4
		add	r6,r4
		cmp/ge	r10,r4
		bf	.y_snap
		sub	r10,r4
.y_snap:
		mulu	r11,r4
		mov	@r2,r2
		sts	macl,r4
		add	r2,r4
		lds	r0,macl

	; macl - Spritesheet Ydraw direction | Xdraw direction
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
	;   r4 - FB output position
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
		sts	macl,r0
		exts.w	r0,r0
		cmp/ge	r7,r2
		bf/s	.x_loop
		add	r0,r1			; Increment texture pos
		sts	macl,r0
		shlr16	r0
		exts.w	r0,r0
		add	r0,r13			; Next texture line
		add	#1,r6			; Increment loop Y
		cmp/ge	r8,r6			; Y start > Y end?
		bf/s	.y_loop
		add	r11,r4			; Next FB top-left line
.spr_out:
		bra	MarsVideo_NxtSuprSpr
		add 	#sizeof_marsspr,r14
		align 4
		ltorg

; --------------------------------------------------------
; MarsVideo_DrwSprBlk
;
; Refill the background sections overwritten by
; the Super-Sprites using a list generated by
; MarsVideo_SetSprFill
;
; Input:
; r14 | Scrolling buffer
; r13 | Background buffer
; r12 | List of blocks to redraw
;
; Note:
; CPU-intensive, and doesn't have any overflow protection.
; --------------------------------------------------------

		align 4
MarsVideo_DrwSprBlk:
		sts	pr,@-r15

	; mach - _framebuffer area
	;  r11 - Scroll current top-left
	;  r10 - FULL Scroll area size
	;   r9 - Scroll Width
	;   r8 - Block graphics
	;   r7 - Layout data
	;   r6 - Layout width
	;   r5 - Block size

		mov	#16,r2			; <-- (-)manual block size
		mov	@(scrl_intrl_size,r14),r10
		mov	#_framebuffer,r4
		mov	@(scrl_fbdata,r14),r0
		add	r0,r4
		mov	@(scrl_fbpos,r14),r11
		neg	r2,r1
		mov.w	@(scrl_fbpos_y,r14),r0
		extu.w	r0,r3
		mov.w	@(scrl_intrl_w,r14),r0
		extu.w	r0,r9
		mov	@(md_bg_blk,r13),r8
		and	r1,r3
		mov	@(md_bg_low,r13),r7
		and	r1,r11
		mov.w	@(md_bg_w,r13),r0
		extu.w	r0,r6
		mov.w	@(md_bg_xinc_l,r13),r0
		exts.w	r0,r1
		mov.w	@(md_bg_yinc_u,r13),r0
		exts.w	r0,r0
		lds	r4,mach
		muls	r2,r1
		sts	macl,r1
		muls	r2,r0
		sts	macl,r0
		shlr8	r0
		shlr8	r1
		exts.b	r0,r0
		exts.b	r1,r1
		muls	r6,r0
		sts	macl,r0
		add	r0,r1
		add	r1,r7

		mulu	r9,r3
		sts	macl,r0
		add	r0,r11
		cmp/gt	r10,r11
		bf	.fbmuch
		sub	r10,r11
.fbmuch:
		mov	#16,r5		; <-- manual block size
.next:
		mov	@r12,r0
		cmp/pz	r0
		bt	.no_val
		bsr	.drw_block
		mov	r0,r1
		xor	r0,r0
		mov	r0,@r12
		bra	.next
		add	#4,r12
.no_val:
		lds	@r15+,pr
		rts
		nop
		align 4

; read sprite block
.drw_block:
		mov	#Cach_BlkBackup_S,r0
		mov	r5,@-r0
		mov	r6,@-r0
		mov	r7,@-r0
		mov	r8,@-r0
		mov	r9,@-r0
		mov	r12,@-r0

		mov	r1,r2
		mov	r1,r3
		mov	r1,r4
		shlr16	r1
		shlr16	r2
		shlr8	r2
		mov	r2,r0
		and	#$7F,r0
		mov	r0,r2
		exts.b	r1,r1
		mov	r3,r0
		mov	#-1,r3	; $FFFF
		shlr16	r3
		and	r3,r0
		and	r3,r4
		shlr8	r4
		and	#$FF,r0
		mov	r0,r3

	; mach - _framebuffer area
	;  r11 - Scroll current top-left
	;  r10 - FULL Scroll area size
	;   r9 - Scroll Width
	;   r8 - Block graphics
	;   r7 - Layout data
	;   r6 - Layout width
	;   r5 - Block size
	;   r4 - Yend
	;   r3 - Xend
	;   r2 - Yindx
	;   r1 - Xindx

.y_rblk:
		mov	#Cach_InRead_S,r0
		mov	r1,@-r0
		mov	r2,@-r0
		mov	r4,@-r0
		mov	r6,@-r0
		mov	r7,@-r0
		mov	r8,@-r0

		mulu	r6,r2
		sts	macl,r0
		add	r0,r7
		add	r1,r7
.x_rblk:
		mulu	r5,r2
		sts	macl,r0
		mulu	r9,r0
		sts	macl,r6
		mulu	r5,r1
		sts	macl,r0
		add	r0,r6
		add	r11,r6

		mov	r8,r13
		mov.b	@r7,r0
		and	#$FF,r0
		mov	#16*16,r12	; <-- manual block size
		mulu	r12,r0
		sts	macl,r0
		add	r0,r13
		mov	r5,r4
.y_lne:
		cmp/gt	r10,r6
		bf	.fbmuch2
		sub	r10,r6
.fbmuch2:
		lds	r6,macl
		mov	r5,r12
		shlr2	r12
.x_lne:
; 		mov	#-1,r0
		mov	@r13+,r0
		sts	mach,r14
		add	r6,r14
		mov	r0,@r14
		mov	#320,r14
		cmp/gt	r14,r6
		bt	.xtrue
		sts	mach,r14
		add	r6,r14
		add	r10,r14
		mov	r0,@r14
.xtrue:
		dt	r12
		bf/s	.x_lne
		add	#4,r6
		sts	macl,r6
		dt	r4
		bf/s	.y_lne
		add	r9,r6

		add	#1,r1
		cmp/ge	r3,r1
		bf/s	.x_rblk
		add	#1,r7		; next layout X
		mov	#Cach_InSprRdrw,r0
		mov	@r0+,r8
		mov	@r0+,r7
		mov	@r0+,r6
		mov	@r0+,r4
		mov	@r0+,r2
		mov	@r0+,r1
		add	#1,r2
		cmp/ge	r4,r2
		bf	.y_rblk

		mov	#Cach_BlkBackup_L,r0
		mov	@r0+,r12
		mov	@r0+,r9
		mov	@r0+,r8
		mov	@r0+,r7
		mov	@r0+,r6
		mov	@r0+,r5
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------
; Quick RAM
; --------------------------------------------------------

; Cach_WdgDrawBuff:
; $00 - Layout data (read)
; $04 - FB pos (read)
; $08 - Layout width (next block)
; $0C - FB width (next line)
; $10 - FB FULL size
; $14 - FB base
; $18 - Block data
; $1C - Block counter
; $20 - ** Reserved **

			align 4
RAM_Mars_ScrlBuff	ds.w sizeof_mscrl*2	; Scrolling buffers
Cach_WdgBuffRd		ds.l 8
Cach_WdgBuffWr		ds.l 0			; <-- read backwards
Cach_WdgBuffRd_UD	ds.l 8
Cach_WdgBuffWr_UD	ds.l 0			; <-- read backwards

Cach_InSprRdrw		ds.l 4
Cach_InRead_L		ds.l 2
Cach_InRead_S		ds.l 0			; <-- read backwards
Cach_BlkBackup_L	ds.l 6
Cach_BlkBackup_S	ds.l 0			; <-- read backwards
Cach_WdBackup_L		ds.l 14
Cach_WdBackup_S		ds.l 0			; <-- read backwards
Cach_DrawTimers		ds.l 4			; Screen draw-request timers, write $02 to these

Cach_FbData		ds.l 1		; *** KEEP THIS ORDER
Cach_FbPos		ds.l 1
Cach_FbPos_Y		ds.l 1
Cach_Intrl_W		ds.l 1
Cach_Intrl_H		ds.l 1
Cach_Intrl_Size		ds.l 1		; ***

; --------------------------------------------------------
.end:		phase CACHE_MSTR_SCRL+.end&$1FFF
		align 4
CACHE_MSTR_SCRL_E:
	if MOMPASS=6
		message "THIS CACHE CODE uses: \{(CACHE_MSTR_SCRL_E-CACHE_MSTR_SCRL)}"
	endif
