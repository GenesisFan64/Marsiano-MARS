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
		mov	#$FFFFFE80,r1	; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		rts
		nop
		align 4

; ====================================================================
; ----------------------------------------------------------------
; Drawing routines for the smooth-scrolling background
;
; NOTE: NO RV-ROM PROTECTION
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_DrwMapData
;
; Input:
; r14 | Background control buffer
; r13 | Scrolling section buffer
; r12 | Pixel storage (Frambuffer or RAM)
;
; Breaks:
; ALL
; --------------------------------------------------------

		align 4
MarsVideo_DrwMapData:
		sts	pr,@-r15
		mov	r14,@-r15
		mov	r13,@-r15
		lds	r12,mach

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
		mov	@(scrl_intrl_w,r13),r11
		mov	#-16,r0			; <- manual size
		mov	@(scrl_intrl_h,r13),r10
		and	r0,r1
		mov	@(scrl_intrl_size,r13),r12
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
;
; Note: hardcoded
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsVideo_DrawSuperSpr_M
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
;
; Note:
; Make sure the pixel data is set to Cache-thru (|TH)
; --------------------------------------------------------

		align 4
MarsVideo_DrawSuperSpr_M:
		mov	#RAM_Mars_DreqRead+Dreq_SuperSpr,r14
		mov	#Cach_Intrl_W,r11
		mov	@r11,r11
		mov	#Cach_Intrl_Size,r10
		mov	@r10,r10
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
		mov	@(marsspr_x,r14),r5	; XXXX YYYY
		exts.w	r5,r6
		mov	@(marsspr_xfrm,r14),r7	; ?? ?? XX YY
		shlr16	r5
		exts.w	r5,r5
		extu.b	r7,r8
		shlr8	r7
		extu.b	r7,r7
; 		mov.w	@(marsspr_x,r14),r0
; 		exts.w	r0,r5
; 		mov.w	@(marsspr_y,r14),r0
; 		exts.w	r0,r6
; 		mov.b	@(marsspr_xs,r14),r0
; 		exts.b	r0,r7
; 		mov.b	@(marsspr_ys,r14),r0
; 		exts.b	r0,r8
		mov	r7,r3			; Copy old XS / YS
		mov	r8,r4
		add	r5,r7
		add	r6,r8

		mov	#Cach_Intrl_H,r0
		mov	@r0,r0
		cmp/pl	r8
		bf	.spr_out
		cmp/pl	r7
		bf	.spr_out
		cmp/ge	r11,r5
		bt	.spr_out
		cmp/ge	r0,r6
		bt	.spr_out
	; XR / YB
		mov	#224,r0
		cmp/ge	r0,r8
		bf	.yb_e
		mov	r0,r8
.yb_e:
		mov	#320,r0
		cmp/gt	r0,r7
		bf	.xb_e
		mov	r0,r7
.xb_e:

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
		dt	r13
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
		mov	r5,r9
		cmp/pz	r4
		bt	.xfinc
		neg	r9,r9
.xfinc:
		sub	r9,r13
		xor	r5,r5
.xt_e:
		extu.w	r4,r9
		shll16	r2
		or	r2,r9
		mov	#Cach_FbPos_Y,r4
		mov	#Cach_FbPos,r2
		mov	@r4,r4
		add	r6,r4
; 		cmp/ge	r10,r4
; 		bf	.y_snap
; 		sub	r10,r4
; .y_snap:
		mulu	r11,r4
		mov	@r2,r2
		sts	macl,r4
		add	r2,r4

	; mach - _framebuffer + base
	;  r14 - Sprite data
	;  r13 - Texture data
	;  r12 - Texture index
	;  r11 - Internal WIDTH
	;  r10 - Internal WIDTH+HEIGHT
	;   r9 - Spritesheet Ydraw direction | Xdraw direction
	;   r8 - Y End
	;   r7 - X End
	;   r6 - Y Start
	;   r5 - X Start
	;   r4 - FB output position
	;
	; *** start ***
.y_loop:
		cmp/ge	r10,r4			; Wrap FB output
		bf	.y_max
		sub	r10,r4
.y_max:
		mov	r13,r1			; r1 - Texture IN
		mov	r5,r2			; r2 - X counter
.x_loop:
		sts	mach,r3			; r3 - Framebuffer + FbData
		add	r4,r3			; add top-left position
		add	r2,r3			; add X position

		mov.b	@r1,r0			; r0 - pixel
		tst	r0,r0			; blank pixel 0?
		bt	.blnk
		add	r12,r0			; add pixel increment
.blnk:
		mov.b	r0,@r3			; Write pixel
		mov	#320,r0			; Check for hidden line (X < 320)
		cmp/ge	r2,r0
		bt	.ex_line
		mov.b	@r1,r0			; Repeat same thing but
		tst	r0,r0			; but add r12 to the
		bt	.blnk2			; destination
		add	r12,r0
.blnk2:
		add	r10,r3
		mov.b	r0,@r3
.ex_line:
		add	#1,r2			; Increment X pos

		mov	r9,r0
		exts.w	r0,r0
		cmp/ge	r7,r2
		bf/s	.x_loop
		add	r0,r1			; Increment texture pos

		mov	r9,r0
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
; MarsVideo_RefillBgSpr
;
; Call this BEFORE updating Sprite info
; --------------------------------------------------------

		align 4
MarsVideo_RefillBgSpr:
		mov	#Cach_SprBoxList,r14

		mov	#Cach_Intrl_Size,r12
		mov	#Cach_FbPos,r10
		mov	#Cach_Intrl_W,r11
		mov	#Cach_FbPos_Y,r0
		mov	@r0,r0
		mov	#Cach_FbData,r9
		mov	@r9,r9
		mov	#_framebuffer,r1
		mov	@r11,r11
		mov	#-4,r2
		mov	@r10,r10
		add	r1,r9
		mov	@r12,r12

; 		mov	#RAM_Mars_ScrlBuff,r13
; 		mov	@(scrl_fbpos_y,r13),r0
; 		mov	#_framebuffer,r1
; 		mov	@(scrl_fbdata,r13),r9
; 		add	r1,r9
; 		mov	@(scrl_intrl_w,r13),r11
; 		mov	#-4,r2
; 		mov	@(scrl_fbpos,r13),r10
; 		and	r2,r0
; 		mov	@(scrl_intrl_size,r13),r12

		mulu	r0,r11
		sts	macl,r1
		mov	#RAM_Mars_ScrlData,r0		; <-- use this area
		add	r1,r10
		cmp/ge	r12,r10
		bf	.ygood
		sub	r12,r10
.ygood:
		and	r2,r10
		lds	r0,mach

.next_save:
		mov	@r14,r0
		cmp/pz	r0
		bt	.last
		mov	r10,r4
		mov	r0,r5
		mov	r0,r6
		mov	r0,r7
		mov	r0,r8
		xor	r0,r0
		mov	r0,@r14
		mov	#$7F,r0
		shlr16	r5
		shlr16	r7
		shlr8	r7
		and	r0,r5
		and	r0,r7
		shll2	r5
		shll2	r7
		shlr8	r8
		mov	#$FF,r0
		and	r0,r6
		and	r0,r8
		sub	r6,r8
		cmp/pl	r8
		bf	.spr_out
		mulu	r11,r6
		sts	macl,r0
		add	r0,r4

		mov	#320,r6
.y_lp:
		mov	r5,r1
		mov	r4,r2
		add	r5,r2
.x_lp:
		cmp/ge	r12,r2
		bf	.x_keep
		sub	r12,r2
.x_keep:
		sts	mach,r13
		add	r2,r13
		mov	@r13+,r0
; 		or	r13,r0

		mov	r9,r3
		add	r2,r3
		mov	r0,@r3
		cmp/ge	r6,r2
		bt	.x_lrg
		add	r12,r3
		add	r12,r13
		mov	r0,@r3
		mov	r0,@r13
.x_lrg:
		add	#4,r1
		cmp/ge	r7,r1
		bf/s	.x_lp
		add	#4,r2
		dt	r8
		bf/s	.y_lp
		add	r11,r4
.spr_out:
		bra	.next_save
		add 	#4,r14
.last:
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

Cach_WdgBuffRd		ds.l 8
Cach_WdgBuffWr		ds.l 0		; <-- read backwards
Cach_WdgBuffRd_UD	ds.l 8
Cach_WdgBuffWr_UD	ds.l 0		; <-- read backwards
Cach_InSprRdrw		ds.l 4
Cach_InRead_L		ds.l 2
Cach_InRead_S		ds.l 0		; <-- read backwards
Cach_BlkBackup_L	ds.l 6
Cach_BlkBackup_S	ds.l 0		; <-- read backwards
Cach_WdBackup_L		ds.l 14
Cach_WdBackup_S		ds.l 0		; <-- read backwards
Cach_BlkRefill		ds.l 10
Cach_BlkRefill_S	ds.l 0		; <-- read backwards
; Cach_DrawTimers		ds.l 4		; Screen draw-request timers, write $02 to these
Cach_FbData		ds.l 1		; *** KEEP THIS ORDER
Cach_FbPos		ds.l 1
Cach_FbPos_Y		ds.l 1
Cach_Intrl_W		ds.l 1
Cach_Intrl_H		ds.l 1
Cach_Intrl_Size		ds.l 1		; ***
Cach_SprBoxList		ds.l MAX_SUPERSPR
; RAM_Mars_ScrlBuff	ds.b sizeof_mscrl*2			; Scrolling buffers

; --------------------------------------------------------
.end:		phase CACHE_MSTR_SCRL+.end&$1FFF
		align 4
CACHE_MSTR_SCRL_E:
	if MOMPASS=6
		message "THIS CACHE CODE uses: \{(CACHE_MSTR_SCRL_E-CACHE_MSTR_SCRL)}"
	endif
