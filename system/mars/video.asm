; ====================================================================
; ----------------------------------------------------------------
; MARS Video
; ----------------------------------------------------------------

; ----------------------------------------
; Variables
; ----------------------------------------

MSCRL_BLKSIZE	equ $10			; Block size for both directions, aligned by 4
MSCRL_WIDTH	equ 320+MSCRL_BLKSIZE	; Internal width for scrolldata + hidden zone
MSCRL_HEIGHT	equ 240+MSCRL_BLKSIZE	; Internal height for scrolldata + hidden zone
FBVRAM_PATCH	equ $1D000		; Framebuffer location for the affected XShift pixel lines

; ----------------------------------------
; Structs
; ----------------------------------------

; Be careful modifing these...
; The SH2 has limited indexing
		struct 0
mbg_draw_all	ds.b 1		; Write 2 to request FULL redraw (OTHER draw bytes MUST be at 0)
mbg_draw_r	ds.b 1		; Write 2 to draw to the right
mbg_draw_l	ds.b 1		; ***** for left
mbg_draw_d	ds.b 1		; ***** for down
mbg_draw_u	ds.b 1		; ***** for up
mbg_xset	ds.b 1		; X-counter
mbg_yset	ds.b 1		; Y-counter
mbg_flags	ds.b 1		; Current type of pixel-data: Indexed or Direct
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
mbg_data	ds.l 1
mbg_size	ds.l 1		; Background FULL size, Width MUST be larger than 320.
mbg_xpos	ds.l 1		; 0000.0000
mbg_ypos	ds.l 1		; 0000.0000
mbg_fb		ds.l 1		; Framebuffer TOPLEFT position
mbg_fbdata	ds.l 1		; Pixeldata location on Framebuffer
mbg_intrl_size	ds.l 1		;
sizeof_marsbg	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Init MARS Video
; ----------------------------------------------------------------

MarsVideo_Init:
		sts	pr,@-r15
		mov	#_sysreg,r1
		mov 	#FM,r0			; Set SVDP permission to SH2
  		mov.b	r0,@(adapter,r1)
		mov 	#_vdpreg,r1
		mov	#0,r0			; Start at blank
		mov.b	r0,@(bitmapmd,r1)

		mov	#_framebuffer,r2
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
		mov	#$1FD80/2,r0	; very last usable line
		mov	#240,r4
.nxt_lne:
		mov.w	r0,@r3
		dt	r4
		bf/s	.nxt_lne
		add	#2,r3

		mov.b	@(framectl,r1),r0
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

; ------------------------------------
; MarsVdp_LoadPal
;
; Load palette to RAM
; then the Palette will be transfered
; on VBlank
;
; Input:
; r1 - Palette data
; r2 - Start index
; r3 - Number of colors
; r4 - OR value ($0000 or $8000)
;
; Uses:
; r0,r4-r6
; ------------------------------------

MarsVideo_LoadPal:
		mov.w	@(marsGbl_PalDmaMidWr,gbr),r0
		cmp/eq	#1,r0
		bt	MarsVideo_LoadPal
		mov 	r1,r5
		mov 	#RAM_Mars_Palette,r6
		mov 	r2,r0
		shll	r0
		add 	r0,r6
		mov 	r3,r0
; 		and	#$FF,r0
; 		cmp/pl	r0
; 		bf	.badlen
		mov	#256,r7
		cmp/gt	r7,r0
		bt	.loop
		mov	r0,r7
.loop:
		mov.w	@r5+,r0
		or	r4,r0
		mov.w	r0,@r6
		dt	r7
		bf/s	.loop
		add 	#2,r6
.badlen:
		mov	#RAM_Mars_Palette,r1	; lazy fix
		mov.w	@r1,r0			; for background
		mov	#$7FFF,r2
		and	r2,r0
		mov.w	r0,@r1
		rts
		nop
		align 4
		ltorg

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
		mov	@(mbg_fb,r14),r0
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
; r1 - String data
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
		mov	@(mbg_fb,r14),r0
		add	r0,r11
		mov	r2,r0
		shll2	r0
		shll	r0
		add	r0,r11
		sts	macl,r0
		add	r0,r11

		mov	@r1,r4
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
		mov	@(mbg_xpos,r14),r1
		mov	@(mbg_ypos,r14),r2
		shlr16	r1
		shlr16	r2
		exts.w	r1,r1
		exts.w	r2,r2
		mov	@(mbg_data,r14),r0
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
		mov	#-MSCRL_BLKSIZE,r7		; TODO

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
		mov	#320,r5
		add	r5,r0
.lwr_xnxt:	cmp/gt	r11,r0
		bf	.lwr_xvld
; 		bra	.lwr_xnxt
		sub	r11,r0
.lwr_xvld:
		mov.w	r0,@(mbg_xinc_r,r14)

		mov	r2,r0
		mov.w	r0,@(mbg_yinc_u,r14)
		mov	#240,r5
		add	r5,r0
.lwr_ynxt:	cmp/ge	r9,r0
		bf	.lwr_yvld
; 		bra	.lwr_ynxt
		sub	r9,r0
.lwr_yvld:
		mov.w	r0,@(mbg_yinc_d,r14)

	; r1 - X bg pos
	; r2 - Y bg pos
	; r3 - Framebuffer BASE
	; r4 - Y FB pos &BLKSIZE
	; Set X/Y framebuffer blocks
		mov.w	@(mbg_yfb,r14),r0
		mov	r0,r4
		mov	@(mbg_fb,r14),r3
		and	r7,r4
		and	r7,r3
		and	r7,r2
		and	r7,r1
		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r7
		mov.w	@(mbg_intrl_blk,r14),r0
		mulu	r7,r0
		sts	macl,r7
		shlr8	r7
.nxt_y:
		cmp/ge	r9,r2		; Y limiters
		bf	.ybg_l
		sub	r9,r2
.ybg_l:
		mov	r3,@-r15
		mov	r1,@-r15
		mov.w	@(mbg_intrl_w,r14),r0
		mov	r0,r6
		mov.w	@(mbg_intrl_blk,r14),r0
		mulu	r6,r0
		sts	macl,r6
		shlr8	r6
.nxt_x:
		cmp/ge	r11,r1		; X pixel-data wrap
		bf	.xbg_l
		sub	r11,r1
.xbg_l:
		mov.w	@(mbg_intrl_w,r14),r0
		mulu	r4,r0
		sts	macl,r5
		add	r3,r5
		mov	@(mbg_intrl_size,r14),r0
		cmp/ge	r0,r5
		bf	.lrgrfb
		sub	r0,r5
.lrgrfb:
		bsr	.mk_piece
		nop
		mov.w	@(mbg_intrl_blk,r14),r0
		add	r0,r1
		dt	r6
		bf/s	.nxt_x
		add	r0,r3		; No MAP WIDTH check needed here
		mov	@r15+,r1
		mov	@r15+,r3
		mov.w	@(mbg_intrl_blk,r14),r0
		add	r0,r4
		cmp/gt	r8,r4
		bf	.nxt_y_l
		sub	r8,r4
.nxt_y_l:
		add	r0,r2
		dt	r7
		bf	.nxt_y

		lds	@r15+,pr
		rts
		nop
		align 4

; r1 - X pos
; r2 - Y pos
; r5 - framebuffer topleft
.mk_piece:
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15

	; Framebuffer X/Y add
		mov	r13,r8		; BG X/Y add
		mulu	r11,r2
		sts	macl,r0
		add	r0,r8
		add	r1,r8
		mov	r12,r7		; FB X add
		add	r5,r7

	; Hidden line
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r9
		mov	#320,r0
		cmp/ge	r0,r5
		bt	.yblk_loopn
		mov	r5,r6
		mov	@(mbg_intrl_size,r14),r0
		add	r0,r6
		add	r12,r6
		mov	r8,r5
	rept MSCRL_BLKSIZE/4		; TODO
		mov	@r5+,r0
		mov	r0,@r6
		add	#4,r6
	endm

.yblk_loopn:
		mov	r8,r5
		mov	r7,r6
	rept MSCRL_BLKSIZE/4		; TODO
		mov	@r5+,r0
		mov	r0,@r6
		add	#4,r6
	endm
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
		rts
		nop
		align 4
		ltorg

; ---------------------------------------
; Move background and update it with
; the new values
;
; r14 - Background data
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
	; Y Framebuffer position (direct)
	; ---------------------------------------

; 	if MSCRL_HEIGHT=256
; 		mov.w	@(mbg_yfb,r14),r0
; 		add	r2,r0
; 		and	#$FF,r0
; 		mov.w	r0,@(mbg_yfb,r14)
; 		mov.w	@(mbg_yfb_d,r14),r0
; 		add	r2,r0
; 		and	#$FF,r0
; 		mov.w	r0,@(mbg_yfb_d,r14)
; 	else
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
		mov	@(mbg_fb,r14),r0
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
		mov	r0,@(mbg_fb,r14)

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

		mov	#0,r5
		mov.b	@(mbg_yset,r14),r0
		add	r2,r0
		mov	r0,r6
		tst	#(-MSCRL_BLKSIZE)&$FF,r0	; TODO
		bt	.ydr_busy
		mov	#-MSCRL_BLKSIZE,r3
		cmp/pl	r2
		bf	.reqd_b
		mov.b	@(mbg_draw_u,r14),r0
		mov	r0,r4
		mov.b	@(mbg_draw_d,r14),r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydr_busy
		mov	#2,r0
		mov.b	r0,@(mbg_draw_d,r14)
		add	#$01,r5
.reqd_b:
		cmp/pz	r2
		bt	.ydr_busy
		mov.b	@(mbg_draw_u,r14),r0
		mov	r0,r4
		mov.b	@(mbg_draw_d,r14),r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydr_busy
		mov	#2,r0
		mov.b	r0,@(mbg_draw_u,r14)
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
		tst	#(-MSCRL_BLKSIZE)&$FF,r0	; TODO
		bt	.ydl_busy
		mov	#-MSCRL_BLKSIZE,r3
		cmp/pl	r1
		bf	.reqr_b
		mov.b	@(mbg_draw_l,r14),r0
		mov	r0,r4
		mov.b	@(mbg_draw_r,r14),r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydl_busy

		mov	#2,r0
		mov.b	r0,@(mbg_draw_r,r14)
		add	#$02,r5
.reqr_b:
		cmp/pz	r1
		bt	.ydl_busy
		mov.b	@(mbg_draw_l,r14),r0
		mov	r0,r4
		mov.b	@(mbg_draw_r,r14),r0
		or	r4,r0
		cmp/eq	#0,r0
		bf	.ydl_busy

		mov	#2,r0
		mov.b	r0,@(mbg_draw_l,r14)
		add	#$02,r5
.ydl_busy:
		mov.w	@(mbg_intrl_blk,r14),r0
		mov	r0,r4
		mov	r6,r0
		dt	r4
		and	r4,r0
		mov.b	r0,@(mbg_xset,r14)

	; Make snapshot of scroll variables
	; to CACHE
		cmp/pl	r5
		bf	.dont_snap
		mov	#-MSCRL_BLKSIZE,r7	; TODO
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
		mov	@(mbg_fb,r14),r0
		and	r7,r0
		mov	r0,@r6
.dont_snap:

		rts
		nop
		align 4
		ltorg

; ---------------------------------------
; Build the linetable
;
; r1 - Background buffer
; r2 - Top Y
; r3 - Bottom Y
; ---------------------------------------

MarsVideo_MakeTbl:
		mov	#_framebuffer,r14		; r14 - Framebuffer BASE
		mov	@(mbg_fbdata,r1),r13		; r13 - Framebuffer pixeldata position
		mov	@(mbg_intrl_size,r1),r12	; r12 - Full size of screen-scroll
		mov	#RAM_Mars_LineTblCopy,r11	; r11 - HBlank mode/xshift list (later...)
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
		mov	@(mbg_fb,r1),r5
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
		mov	r5,r0		; $xxFF
		and	r4,r0
		cmp/eq	r4,r0
		bf	.hw_cont
		mov.w	@(marsGbl_XShift,gbr),r0
		and	#1,r0
		cmp/eq	#1,r0
		bf	.hw_cont
		mov.w	r10,@r11
		mov	r5,r0
		mov.w	r0,@(2,r11)
		add	#4,r11
.hw_cont:
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
; Call this after ALL Framebuffer tables
; are set, to fix that Xshift bit issue
; on Hardware
; ---------------------------------------

; TODO: este codigo rebota la imagen final en SDRAM
; checar si poniendo esto en CACHE ya no salta

MarsVideo_FixTblShift:
		mov	#_framebuffer,r14		; r14 - Framebuffer BASE
		mov.b	@(mbg_flags,r14),r0
		and	#%00000001,r0
		tst	r0,r0
		bf	.ptchset
		mov	#_framebuffer+FBVRAM_PATCH,r13	; r13 - Output for patched pixel lines
		mov	#RAM_Mars_LineTblCopy,r12
.loop:
		mov	@r12,r0
		cmp/eq	#0,r0
		bt	.tblexit
		mov	r0,r1
		mov	r0,r2
		shlr16	r2
		add	r14,r2
		mov	#$FFFF,r0
		and	r0,r1
		shll	r1
		add	r14,r1
		mov	r13,r0
		shlr	r0
		mov.w	r0,@r2
		mov	#320,r3
.copyline:
		add	#1,r1
		mov.b	@r1,r0
		mov.b	r0,@(1,r13)
		dt	r3
		bf/s	.copyline
		add	#1,r13
		xor	r0,r0
		mov	r0,@r12
		bra	.loop
		add	#4,r12
.tblexit:
; 		mov.w	@(marsGbl_XPatch,gbr),r0
; 		add	#1,r0
; 		mov.w	r0,@(marsGbl_XPatch,gbr)
.ptchset:
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; MarsVideo_MakeScreen
;
; Set pointer to read the pixel-data
;
; r1 - Background slot
; r2 - Output framebuffer data
; r3 - Scroll block size (best size: $10)
; r4 - Scroll width + blocksize (MUST BE LARGER THAN 320)
; r5 - Scroll height + blocksize
; ------------------------------------------------

MarsVideo_MakeScreen:
		mov	#RAM_Mars_Background,r14
		mov	r2,@(mbg_fbdata,r14)
		mov	r3,r0
		mov.w	r0,@(mbg_intrl_blk,r14)
		mov	r4,r0
		mov.w	r0,@(mbg_intrl_w,r14)
		mov	r5,r0
		mov.w	r0,@(mbg_intrl_h,r14)
		mulu	r4,r5
		sts	macl,r0
		mov	r0,@(mbg_intrl_size,r14)
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; MarsVideo_SetBg
;
; Set pointer to read the pixel-data
;
; r1 - Background slot
; r2 - Pixeldata output location on Framebuffer
; r3 - Source image WIDTH
; r4 - Source image HEIGHT
;
; WIDTH AND HEIGHT MUST BE ALIGNED IN "BLOCKS"
; ------------------------------------------------

MarsVideo_SetBg:
		mov	#RAM_Mars_Background,r14
		mov	r2,@(mbg_data,r14)
		mov	r3,r0
		mov.w	r0,@(mbg_width,r14)
		mov	r4,r0
		mov.w	r0,@(mbg_height,r14)
		rts
		nop
		align 4
		ltorg

; ; ------------------------------------------------
; ; MarsVideo_SetWatchdog
; ;
; ; Initialize watchdog interrupt with
; ; default settings
; ; ------------------------------------------------
;
; MarsVideo_SetWatchdog:
; 		stc	sr,@-r15			; Save interrupts
; 		mov	#$F0,r0
; 		ldc	r0,sr
;
; ; 	; Polygon start-values
; ; ; 		mov	#RAM_Mars_VdpDrwList,r0		; Reset the piece-drawing pointer
; ; ; 		mov	r0,@(marsGbl_PlyPzList_R,gbr)	; on both READ and WRITE pointers
; ; ; 		mov	r0,@(marsGbl_PlyPzList_W,gbr)
; ; ; 		mov	#0,r0				; Reset polygon pieces counter
; ; ; 		mov.w	r0,@(marsGbl_PzListCntr,gbr)
; ;
; ; 	; Vars that require reset
; ; 		mov	#MSCRL_HEIGHT,r2
; ; 		mov.w	@(marsGbl_CurrGfxMode,gbr),r0
; ; 		and	#$7F,r0
; ; 		cmp/eq	#1,r0
; ; 		bt	.mde1
; ; 		mov	#224,r2
; ; .mde1:
; ; 		mov	#Cach_LR_Lines,r1		; L/R lines to process
; ; 		mov	r2,@r1
; ; 		mov	#_framebuffer+$200,r0
; ; 		mov	r0,@(marsGbl_Bg_FbCurrR,gbr)
; ; 		mov	#Cach_Xadd,r1
; ; 		mov	#Cach_Yadd,r2
; ; 		mov.w	@(marsGbl_Bg_Xscale,gbr),r0
; ; 		shll8	r0
; ; 		mov	r0,@r1
; ; 		mov.w	@(marsGbl_Bg_Yscale,gbr),r0
; ; 		shll8	r0
; ; 		mov	r0,@r2
; ; 		mov.w	@(mbg_xinc_l,r14),r0
; ; 		mov	#Cach_Xpos,r1
; ; 		mov	r0,@r1
; ; 		mov.w	@(mbg_yinc_u,r14),r0
; ; 		shll16	r0
; ; 		mov	#Cach_Ycurr,r1
; ; 		mov	r0,@r1
; ;
; ; 	; X draw settings
; ; 		mov	@(marsGbl_BgData,gbr),r0
; ; 		mov	r0,@(marsGbl_BgData_R,gbr)
;
; ; 	; Y draw settings
; ; 		mov	#1,r0				; Set first task $01
; ; 		mov.w	r0,@(marsGbl_WdDrwTask,gbr)
; 		ldc	@r15+,sr			; Restore interrupts
; 		mov	#$FFFFFE80,r1
; 		mov.w	#$5A20,r0			; Watchdog timer
; 		mov.w	r0,@r1
; 		mov.w	#$A538,r0			; Enable this watchdog
; 		mov.w	r0,@r1
; 		mov	#_vdpreg,r1
; .wait_fb:	mov.w	@($A,r1),r0			; Wait until framebuffer is unlocked
; 		tst	#2,r0
; 		bf	.wait_fb
; 		mov.w	#$A1,r0				; ClearOnly: Pre-start at $A1
; ; 		mov.w	#$100,r0			; BG: Pre-start at $100
; 		mov.w	r0,@(6,r1)			;
;
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 3D MODELS SYSTEM
; ----------------------------------------------------------------

; ; ------------------------------------------------
; ; Object layout routines
; ; ------------------------------------------------
;
; ; ----------------------------------------
; ; Read layout
; ; ----------------------------------------
;
; MarsLay_Read:
; 		sts	pr,@-r15
; 		mov	#RAM_Mars_ObjLayout,r14
; 		mov	#RAM_Mars_ObjCamera,r13
; 		mov	#RAM_Mars_Objects,r12
; 		mov	@(mdllay_data,r14),r0
; 		cmp/pl	r0
; 		bf	.no_lay
; 		mov	r0,r11
;
; 		mov	#0,r10				; r10 - Update counter
; 		mov	#-$100000,r9			;  r9 - MAX Z block size
; 		mov	#-$100000,r8			;  r8 - MAX Y block size
; 		mov	#-$100000,r7			;  r7 - MAX X block size
; 		mov	#-$8000,r6			;  r6 - X Rotation update point
;
; 		mov	@(mdllay_z_last,r14),r5
; 		mov	@(cam_z_pos,r13),r0
; 		and	r9,r0
; 		and	r9,r5
; 		cmp/eq	r0,r5
; 		bt	.no_z_upd
; ; 		add	r9,r5
; ; 		neg	r5,r4
; ; 		cmp/gt	r5,r0
; ; 		bf	.set_z_upd
; ; 		cmp/ge	r4,r0
; ; 		bf	.no_z_upd
; ; .set_z_upd:
; 		and	r9,r0
; 		mov	r0,@(mdllay_z_last,r14)
; 		add	#1,r10
; .no_z_upd:
;
; 		mov	@(mdllay_y_last,r14),r5
; 		mov	@(cam_y_pos,r13),r0
; 		and	r8,r0
; 		and	r8,r5
; 		cmp/eq	r0,r5
; 		bt	.no_y_upd
; ; 		add	r8,r5
; ; 		neg	r5,r4
; ; 		cmp/gt	r5,r0
; ; 		bf	.set_y_upd
; ; 		cmp/ge	r4,r0
; ; 		bf	.no_y_upd
; ; .set_y_upd:
; 		and	r8,r0
; 		mov	r0,@(mdllay_y_last,r14)
; 		add	#1,r10
; .no_y_upd:
;
; 		mov	@(mdllay_x_last,r14),r5
; 		mov	@(cam_x_pos,r13),r0
; 		and	r7,r0
; 		and	r7,r5
; 		cmp/eq	r0,r5
; 		bt	.no_x_upd
; ; 		add	r7,r5
; ; 		neg	r5,r4
; ; 		cmp/gt	r5,r0
; ; 		bf	.set_x_upd
; ; 		cmp/ge	r4,r0
; ; 		bf	.no_x_upd
; ; .set_x_upd:
; 		and	r7,r0
; 		mov	r0,@(mdllay_x_last,r14)
; 		add	#1,r10
; .no_x_upd:
;
; 		mov	@(mdllay_xr_last,r14),r5
; 		mov	@(cam_x_rot,r13),r0
; 		and	r6,r0
; 		and	r6,r5
; 		cmp/eq	r0,r5
; 		bt	.no_xr_upd
; ; 		add	r6,r5
; ; 		neg	r5,r4
; ; 		cmp/gt	r5,r0
; ; 		bf	.set_xr_upd
; ; 		cmp/ge	r4,r0
; ; 		bf	.no_xr_upd
; ; .set_xr_upd:
; 		and	r6,r0
; 		mov	r0,@(mdllay_xr_last,r14)
; 		add	#1,r10
; .no_xr_upd:
;
; 		cmp/pl	r10
; 		bf	.no_lay
; 		bsr	MarsLay_Draw
; 		nop
; .no_lay:
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
; 		ltorg
;
; ; r1 - layout data pointer
; MarsLay_Make:
; 		mov	#RAM_Mars_ObjLayout,r14
; 		mov	#RAM_Mars_ObjCamera,r13
; 		xor	r0,r0
; 		mov	r1,@(mdllay_data,r14)
; 		mov	r0,@(mdllay_x_last,r14)
; 		mov	r0,@(mdllay_y_last,r14)
; 		mov	r0,@(mdllay_z_last,r14)
; 		mov	r0,@(mdllay_x,r14)
; 		mov	r0,@(mdllay_y,r14)
; 		mov	r0,@(mdllay_z,r14)
; 		rts
; 		nop
; 		align 4
;
; MarsLay_Draw:
; 		mov	#RAM_Mars_Objects,r10
; 		mov	r10,r2
; 		mov	#sizeof_mdlobj,r3
; 		mov	#0,r0
; 		mov	#9,r4
; .clrold:
; 		mov	r0,@(mdl_data,r2)
; 		mov	r0,@(mdl_x_pos,r2)
; 		mov	r0,@(mdl_y_pos,r2)
; 		mov	r0,@(mdl_z_pos,r2)
; 		mov	r0,@(mdl_x_rot,r2)
; 		mov	r0,@(mdl_y_rot,r2)
; 		mov	r0,@(mdl_z_rot,r2)
; 		dt	r4
; 		bf/s	.clrold
; 		add	r3,r2
;
; 	; r13 - Layout Ids
; 	; r12 - Layout model list
; 		mov	#0,r4
; 		mov	@(mdllay_data,r14),r13
; 		mov	@r13+,r12
; 		mov	.center_val,r0			; list center point
; 		add	r0,r13
;
; 	; X/Y add
; 		mov	@(mdllay_x_last,r14),r1
; 		mov	@(mdllay_z_last,r14),r2
; 		mov	#LAY_WIDTH,r0
; 		shlr16	r1
; 		shlr16	r2
; 		exts	r1,r1
; 		exts	r2,r2
; 	rept 3
; 		shar	r1
; 		shar	r2
; 	endm
; 		shar	r2			; extra shift
; 		muls	r0,r2
; 		sts	macl,r0
; 		add	r1,r13			; X add
; 		sub	r0,r13			; Y add
;
; 	; Rotation
; 		mov	@(mdllay_xr_last,r14),r0
; 		shlr16	r0
; 		and	#$3F,r0
; 		shll2	r0
; 		mov	#.list,r1
; 		mov	@(r0,r1),r0
; 		jmp	@r0
; 		nop
; 		align 4
; .center_val:	dc.l ($E*LAY_WIDTH)+($C*2)
;
; .list:
; 		dc.l .front
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .front_fr
;
; 		dc.l .front_fr
; 		dc.l .front_fr
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .right_dw
;
; 		dc.l .right_dw
; 		dc.l .right_dw
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .down_left
;
; 		dc.l .down_left
; 		dc.l .down_left
; 		dc.l .front_lf
; 		dc.l .front_lf
; 		dc.l .front_lf
; 		dc.l .front_lf
; 		dc.l .front_lf
; 		dc.l .front_lf
; 		dc.l .front_lf
; 		dc.l .front_lf
; 		dc.l .front_lf
; 		dc.l .front_lf
; 		dc.l .front_lf
; 		dc.l .front
; 		dc.l .front
; 		dc.l .front
;
; ; r5 - numof pieces
; ; uses: r6,r7
; .do_piece:
; 		mov	r1,@-r15
; 		mov	r13,@-r15
; 		mov	#$100000,r6
; .nxt_one:
; 		xor	r4,r4
; 		mov.w	@r13+,r0
; 		cmp/pl 	r0
; 		bf	.blank_mdl
; ; 		mov	r0,r7
; ; 		shlr8	r0
; ; 		shlr2	r0
; ; 		shlr	r0
; ; 		and	#%11100,r0
; ; 		mov	#.xrotlist,r8
; ; 		mov	@(r8,r0),r8
; ; 		mov	r7,r0
; 		add	#-1,r0
; 		shll2	r0
; ; 		shll	r0
; ; 		mov	#$1FFF,r7
; ; 		and	r7,r0
; 		mov	@(r12,r0),r4
; 		mov	#$40000000,r0	; OR val: set special object mode
; 		or	r0,r4
; .blank_mdl:
; 		mov	r1,@(mdl_x_pos,r10)
; 		mov	r2,@(mdl_y_pos,r10)
; 		mov	r3,@(mdl_z_pos,r10)
; ; 		mov	r8,@(mdl_x_rot,r10)
; 		mov	r4,@(mdl_data,r10)
; 		add	#sizeof_mdlobj,r10
; 		dt	r5
; 		bf/s	.nxt_one
; 		add	r6,r1
; 		mov	@r15+,r13
; 		mov	@r15+,r1
; 		rts
; 		nop
; 		align 4
; ; .xrotlist:	dc.l 0
; ; 		dc.l $100000
; ; 		dc.l $200000
; ; 		dc.l $300000
;
; ; o X X X o
; ; o X X X o
; ; o X C X o
; ; o - - - o
; ; o o o o o
; .front:
; 		mov	#-$100000,r1
; 		mov	#0,r2
; 		mov	#-$200000,r3
; 		add	#(1*2),r13
; 		mov	#$100000,r11
;
; 		sts	pr,@-r15
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
;
; ; front right view
; ; o o X X X
; ; o - X X X
; ; o - C X X
; ; o - - - o
; ; o o o o o
; .front_fr:
; 		mov	#0,r1
; 		mov	#0,r2
; 		mov	#-$200000,r3
; 		add	#(2*2),r13
; 		mov	#$100000,r11
; 		sts	pr,@-r15
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
;
;
; ; right view/down
; ; o o o o o
; ; o - - - o
; ; o - C X X
; ; o - X X X
; ; o o X X X
; .right_dw:
; 		mov	#0,r1
; 		mov	#0,r2
; 		mov	#-$100000,r3
; 		mov	#(2*2)+(LAY_WIDTH),r0
; 		add	r0,r13
; 		mov	#$100000,r11
; 		sts	pr,@-r15
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
;
; ; o o o o o
; ; o - - - o
; ; o X C X o
; ; o X X X o
; ; o X X X o
; .down:
; 		mov	#0,r1
; 		mov	#0,r2
; 		mov	#-$100000,r3
; 		mov	#(2*2)+(LAY_WIDTH*1),r0
; 		add	r0,r13
; 		mov	#$100000,r11
; 		sts	pr,@-r15
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
;
; ; o o o o o
; ; o - - - o
; ; X X C - o
; ; X X X - o
; ; X X X o o
; .down_left:
; 		mov	#-$100000,r1
; 		mov	#0,r2
; 		mov	#-$100000,r3
; 		mov	#(1*2)+(LAY_WIDTH*1),r0
; 		add	r0,r13
; 		mov	#$100000,r11
; 		sts	pr,@-r15
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
;
;
; ; X X X o o
; ; X X X - o
; ; X X C - o
; ; o - - - o
; ; o o o o o
; .front_lf:
; 		mov	#-$100000,r1
; 		mov	#0,r2
; 		mov	#-$200000,r3
; 		add	#(1*2),r13
; 		mov	#$100000,r11
; 		sts	pr,@-r15
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		add	#LAY_WIDTH,r13
; 		add	r11,r3
; 		bsr	.do_piece
; 		mov	#3,r5
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
; 		ltorg
;
; ; ------------------------------------------------
; ; MarsMdl_Init
; ;
; ; Reset ALL objects
; ; ------------------------------------------------
;
; MarsMdl_Init:
; 		mov	#RAM_Mars_Objects,r1
; 		mov	#MAX_MODELS,r2
; 		mov	#0,r0
; .clnup:
; 		mov	r0,@(mdl_data,r1)
; 		mov	r0,@(mdl_animdata,r1)
; 		mov	r0,@(mdl_x_pos,r1)
; 		mov	r0,@(mdl_x_rot,r1)
; 		mov	r0,@(mdl_y_pos,r1)
; 		mov	r0,@(mdl_y_rot,r1)
; 		mov	r0,@(mdl_y_pos,r1)
; 		mov	r0,@(mdl_y_rot,r1)
; 		dt	r2
; 		bf/s	.clnup
; 		add	#sizeof_mdlobj,r1
; 		rts
; 		nop
; 		align 4
; 		ltorg
;
; ; ------------------------------------------------
; ; Read model
; ; ------------------------------------------------
;
; MarsMdl_ReadModel:
; 		sts	pr,@-r15
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
; 	; Now start reading
; 		mov	#$3FFFFFFF,r0
; 		mov	#Cach_CurrPlygn,r13		; r13 - temporal face output
; 		mov	@(mdl_data,r14),r12		; r12 - model header
; 		and	r0,r12
; 		mov 	@(8,r12),r11			; r11 - face data
; 		mov 	@(4,r12),r10			; r10 - vertice data (X,Y,Z)
; 		mov.w	@r12,r9				;  r9 - Number of faces used on model
; 		mov	@(marsGbl_CurrZList,gbr),r0	;  r8 - Zlist for sorting
; 		mov	r0,r8
; .next_face:
; 		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0	; Ran out of space to store faces?
; 		mov	.tag_maxfaces,r1
; 		cmp/ge	r1,r0
; 		bf	.can_build
; 		bra	.exit_model
; 		nop
; 		align 4
; .tag_maxfaces:	dc.l	MAX_FACES
;
; ; --------------------------------
;
; .can_build:
; 		mov.w	@r11+,r4		; Read type
; 		mov	#3,r7			; r7 - Current polygon type: triangle (3)
; 		mov	r4,r0
; 		shlr8	r0
; 		tst	#PLGN_TRI,r0		; Model face uses triangle?
; 		bf	.set_tri
; 		add	#1,r7			; Face is quad, r7 = 4 points
; .set_tri:
; 		cmp/pl	r4			; Faces uses texture? ($8xxx)
; 		bt	.solid_type
;
; ; --------------------------------
; ; Set texture material
; ; --------------------------------
;
; 		mov	@($C,r12),r6		; r6 - Material data
; 		mov	r13,r5			; r5 - Go to UV section
; 		add 	#polygn_srcpnts,r5
; 		mov	r7,r3			; r3 - copy of current face points (3 or 4)
;
; 	; New method
; 	rept 3
; 		mov.w	@r11+,r0			; Read UV index
; 		extu	r0,r0
; 		shll2	r0
; 		mov	@(r6,r0),r0
; 		mov.w	r0,@(2,r5)
; 		shlr16	r0
; 		mov.w	r0,@r5
; 		add	#4,r5
; 	endm
; 		mov	#3,r0			; Triangle?
; 		cmp/eq	r0,r7
; 		bt	.alluvdone		; If yes, skip this
; 		mov.w	@r11+,r0		; Read extra UV index
; 		extu	r0,r0
; 		shll2	r0
; 		mov	@(r6,r0),r0
; 		mov.w	r0,@(2,r5)
; 		shlr16	r0
; 		mov.w	r0,@r5
; .alluvdone:
;
; 		mov	@(mdl_option,r14),r0
; 		and	#$FF,r0
; 		mov	r0,r1
; 		mov	r4,r0
; 		mov	.tag_andmtrl,r5
; 		and	r5,r0
; 		shll2	r0
; 		shll	r0
; 		mov	@($10,r12),r6
; 		add	r0,r6
; 		mov	#$E000,r0		; grab special bits
; 		and	r0,r4
; 		shll16	r4
; 		mov	@(4,r6),r0
; 		or	r0,r4
; 		add	r1,r4
; 		mov	r4,@(polygn_type,r13)
; 		mov	@r6,r0
; 		mov	r0,@(polygn_mtrl,r13)
; 		bra	.go_faces
; 		nop
; 		align 4
; .tag_andmtrl:
; 		dc.l $1FFF
;
; ; --------------------------------
; ; Set texture material
; ; --------------------------------
;
; .solid_type:
; 		mov	@(mdl_option,r14),r0
; 		and	#$FF,r0
; 		mov	r0,r1
; 		mov	r4,r0
; 		mov	#$E000,r5
; 		and	r5,r4
; 		shll16	r4
; 		add	r1,r4
; 		mov	r4,@(polygn_type,r13)		; Set type 0 (tri) or quad (1)
; 		and	#$FF,r0
; 		mov	r0,@(polygn_mtrl,r13)		; Set pixel color (0-255)
;
; ; --------------------------------
; ; Read faces
; ; --------------------------------
;
; .go_faces:
; 		mov	r13,r1
; 		add 	#polygn_points,r1
; 		mov	r11,r6
; 		mov	r7,r0
; 		shll	r0
; 		add	r0,r11
; 		mov 	r8,@-r15
; 		mov 	r9,@-r15
; 		mov 	r11,@-r15
; 		mov 	r12,@-r15
; 		mov 	r13,@-r15
; 		mov	.tag_xl,r8
; 		neg	r8,r9
; 		mov	#-112,r11
; 		neg	r11,r12
; 		mov	#$7FFFFFFF,r5
; 		mov	#$FFFFFFFF,r13
;
; 	; Do 3 points
; 	rept 3
; 		mov	#0,r0
; 		mov.w 	@r6+,r0
; 		mov	#$C,r4
; 		mulu	r4,r0
; 		sts	macl,r0
; 		mov	r10,r4
; 		add 	r0,r4
; 		mov	@r4,r2
; 		mov	@(4,r4),r3
; 		mov	@(8,r4),r4
; 		bsr	mdlrd_setpoint
; 		nop
; 		mov	r2,@r1
; 		mov	r3,@(4,r1)
; 		add	#8,r1
; 	endm
; 		mov	#3,r0			; Triangle?
; 		cmp/eq	r0,r7
; 		bt	.alldone		; If yes, skip this
; 		mov	#0,r0
; 		mov.w 	@r6+,r0
; 		mov	#$C,r4
; 		mulu	r4,r0
; 		sts	macl,r0
; 		mov	r10,r4
; 		add 	r0,r4
; 		mov	@r4,r2
; 		mov	@(4,r4),r3
; 		mov	@(8,r4),r4
; 		bsr	mdlrd_setpoint
; 		nop
; 		mov	r2,@r1
; 		mov	r3,@(4,r1)
; .alldone:
; 		mov	r8,r1
; 		mov	r9,r2
; 		mov	r11,r3
; 		mov	r12,r4
; 		mov	r13,r6
; 		mov	@r15+,r13
; 		mov	@r15+,r12
; 		mov	@r15+,r11
; 		mov	@r15+,r9
; 		mov	@r15+,r8
;
; 	; NOTE: if you don't like how the perspective works
; 	; change this register depending how you want to ignore
; 	; faces closer to the camera:
; 	;
; 	; r5 - Back Z point, keep affine limitations
; 	; r6 - Front Z point, skip face but larger faces are affected
;
; 		cmp/pz	r5
; 		bt	.go_fout
; ; 		cmp/pz	r6
; ; 		bt	.go_fout
;
;
; ; 		mov	#RAM_Mars_ObjCamera,r0
; ; 		mov	@(cam_y_pos,r0),r7
; ; 		shlr2	r7
; ; 		shlr2	r7
; ; 		shlr2	r7
; ; 		shlr	r7
; ; 		exts	r7,r7
; ; 		cmp/pl	r7
; ; 		bf	.revrscam
; ; 		neg	r7,r7
; ; .revrscam:
; ; 		mov	#MAX_ZDIST,r0
; ; 		cmp/ge	r0,r7
; ; 		bt	.camlimit
; ; 		mov	r0,r7
; ; .camlimit:
; ; 		cmp/pl	r6
; ; 		bt	.face_out
; 		mov	#MAX_ZDIST,r0		; Draw distance
; ; 		add 	r7,r0
; 		cmp/ge	r0,r5
; 		bf	.go_fout
; 		mov	#-(SCREEN_WIDTH/2),r0
; 		cmp/gt	r0,r1
; 		bf	.go_fout
; 		neg	r0,r0
; 		cmp/ge	r0,r2
; 		bt	.go_fout
; 		mov	#-(SCREEN_HEIGHT/2),r0
; 		cmp/gt	r0,r3
; 		bf	.go_fout
; 		neg	r0,r0
; 		cmp/ge	r0,r4
; 		bf	.face_ok
; .go_fout:	bra	.face_out
; 		nop
; 		align 4
; .tag_xl:	dc.l -160
;
; ; --------------------------------
;
; .face_ok:
; 		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0	; Add 1 face to the list
; 		add	#1,r0
; 		mov.w	r0,@(marsGbl_MdlFacesCntr,gbr)
; 		mov	@(marsGbl_CurrFacePos,gbr),r0
; 		mov	r0,r1
; 		mov	r13,r2
; 		mov	r5,@r8				; Store current Z to Zlist
; 		mov	r1,@(4,r8)			; And it's address
;
; ; 	Sort this face, SLOW
; ; 	r7 - Curr Z
; ; 	r6 - Past Z
; 		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0
; 		cmp/eq	#1,r0
; 		bt	.first_face
; 		cmp/eq	#2,r0
; 		bt	.first_face
; 		mov	r8,r7
; 		add	#-8,r7
; ; 		mov	@(marsGbl_CurrZList,gbr),r0
; ; 		mov	r0,r6
; 		mov	#RAM_Mars_Plgn_ZList_0,r6
; 		mov.w   @(marsGbl_PlgnBuffNum,gbr),r0
; 		tst     #1,r0
; 		bt	.page_2
; 		mov	#RAM_Mars_Plgn_ZList_1,r6
; .page_2:
; 		cmp/ge	r6,r7
; 		bf	.first_face
; 		mov	@(8,r7),r4
; 		mov	@r7,r5
; 		cmp/eq	r4,r5
; 		bt	.first_face
; 		cmp/gt	r4,r5
; 		bf	.swap_me
; 		mov	@r7,r4
; 		mov	@(8,r7),r5
; 		mov	r5,@r7
; 		mov	r4,@(8,r7)
; 		mov	@(4,r7),r4
; 		mov	@($C,r7),r5
; 		mov	r5,@(4,r7)
; 		mov	r4,@($C,r7)
; .swap_me:
; 		bra	.page_2
; 		add	#-8,r7
; .first_face:
;
;
; 		add	#8,r8				; Next Zlist entry
; 	rept sizeof_polygn/2				; Copy words manually
; 		mov.w	@r2+,r0
; 		mov.w	r0,@r1
; 		add	#2,r1
; 	endm
; 		mov	r1,r0
; 		mov	r0,@(marsGbl_CurrFacePos,gbr)
;
; ; 		mov	r0,r1
; ; 		mov	@(marsGbl_ZSortReq,gbr),r0
; ; 		cmp/eq	#1,r0
; ; 		bt	.face_out
; ; 		mov	#1,r0
; ; 		mov.w	r0,@(marsGbl_ZSortReq,gbr)
; .face_out:
; 		dt	r9
; 		bt	.finish_this
; 		bra	.next_face
; 		nop
; .finish_this:
; 		mov	r8,r0
; 		mov	r0,@(marsGbl_CurrZList,gbr)
;
; .exit_model:
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
; 		ltorg
;
; ; ----------------------------------------
; ; Modify position to current point
; ; ----------------------------------------
;
; 		align 4
; mdlrd_setpoint:
; 		sts	pr,@-r15
; 		mov 	r5,@-r15
; 		mov 	r6,@-r15
; 		mov 	r7,@-r15
; 		mov 	r8,@-r15
; 		mov 	r9,@-r15
; 		mov 	r10,@-r15
; 		mov 	r11,@-r15
;
; 	; Object rotation
; 		mov	r2,r5			; r5 - X
; 		mov	r4,r6			; r6 - Z
;   		mov 	@(mdl_x_rot,r14),r0
;   		shlr2	r0
;   		shlr	r0
;   		bsr	mdlrd_rotate
; 		shlr8	r0
;    		mov	r7,r2
;    		mov	r3,r5
;   		mov	r8,r6
;   		mov 	@(mdl_y_rot,r14),r0
;   		shlr2	r0
;   		shlr	r0
;   		bsr	mdlrd_rotate
; 		shlr8	r0
;    		mov	r8,r4
;    		mov	r2,r5
;    		mov	r7,r6
;    		mov 	@(mdl_z_rot,r14),r0
;   		shlr2	r0
;   		shlr	r0
;   		bsr	mdlrd_rotate
; 		shlr8	r0
;    		mov	r7,r2
;    		mov	r8,r3
; 		mov	@(mdl_x_pos,r14),r5
; 		mov	@(mdl_y_pos,r14),r6
; 		mov	@(mdl_z_pos,r14),r7
; 		shlr8	r5
; 		shlr8	r6
; 		shlr8	r7
; 		exts	r5,r5
; 		exts	r6,r6
; 		exts	r7,r7
; 		add 	r5,r2
; 		add 	r6,r3
; 		add 	r7,r4
;
; 	; Include camera changes
; 		mov 	#RAM_Mars_ObjCamera,r11
; 		mov	@(cam_x_pos,r11),r5
; 		mov	@(cam_y_pos,r11),r6
; 		mov	@(cam_z_pos,r11),r7
; 		mov	@(mdl_data,r14),r0		; Layout object?
; 		shll	r0
; 		cmp/pl	r0
; 		bt	.lay_move
; 		mov	#$FFFFF,r0			; Limit camera movement
; 		and	r0,r5
; ; 		and	r0,r6
; 		and	r0,r7
; .lay_move:
; 		shlr8	r5
; 		shlr8	r6
; 		shlr8	r7
; 		exts	r5,r5
; 		exts	r6,r6
; 		exts	r7,r7
; 		sub 	r5,r2
; 		sub 	r6,r3
; 		add 	r7,r4
;
; 		mov	r2,r5
; 		mov	r4,r6
;   		mov 	@(cam_x_rot,r11),r0
;   		shlr2	r0
;   		shlr	r0
;   		bsr	mdlrd_rotate
; 		shlr8	r0
;    		mov	r7,r2
;    		mov	r8,r4
;    		mov	r3,r5
;   		mov	r8,r6
;   		mov 	@(cam_y_rot,r11),r0
;   		shlr2	r0
;   		shlr	r0
;   		bsr	mdlrd_rotate
; 		shlr8	r0
;    		mov	r8,r4
;    		mov	r2,r5
;    		mov	r7,r6
;    		mov 	@(cam_z_rot,r11),r0
;   		shlr2	r0
;   		shlr	r0
;   		bsr	mdlrd_rotate
; 		shlr8	r0
;    		mov	r7,r2
;    		mov	r8,r3
;
; ; 		mov	#-(SCREEN_WIDTH/2)<<4,r6
; ; 		cmp/ge	r6,r2
; ; 		bf	.x_forz
; ; 		neg	r6,r6
; ; 		cmp/ge	r6,r2
; ; 		bf	.x_rsd
; ; .x_forz:
; ; 		mov	r6,r2
; ; .x_rsd:
;
; ; 		mov	#-(SCREEN_HEIGHT/2),r6
; ; 		cmp/ge	r6,r3
; ; 		bf	.y_forz
; ; 		neg	r6,r6
; ; 		cmp/ge	r6,r3
; ; 		bf	.y_rsd
; ; .y_forz:
; ; 		mov	r6,r3
; ; .y_rsd:
;
; 	; Weak perspective projection
; 	; this is the best I got,
; 	; It breaks on large faces
; 		mov 	#_JR,r8
; 		mov	#320<<16,r7
; 		neg	r4,r0		; reverse Z
; ; 		add	#-16,r0
; 		cmp/pl	r0
; 		bt	.inside
; 		shlr	r7
;
; 		dmuls	r7,r2
; 		sts	mach,r0
; 		sts	macl,r2
; 		xtrct	r0,r2
; 		dmuls	r7,r3
; 		sts	mach,r0
; 		sts	macl,r3
; 		xtrct	r0,r3
; 		bra	.zmulti
; 		nop
; .inside:
; 		mov 	r0,@r8
; 		mov 	r7,@(4,r8)
; 		nop
; 		mov 	@(4,r8),r7
; 		dmuls	r7,r2
; 		sts	mach,r0
; 		sts	macl,r2
; 		xtrct	r0,r2
; 		dmuls	r7,r3
; 		sts	mach,r0
; 		sts	macl,r3
; 		xtrct	r0,r3
; .zmulti:
;
; 		mov	@r15+,r11
; 		mov	@r15+,r10
; 		mov	@r15+,r9
; 		mov	@r15+,r8
; 		mov	@r15+,r7
; 		mov	@r15+,r6
; 		mov	@r15+,r5
;
; 	; Set the most far points
; 	; for each direction (X,Y,Z)
; 		cmp/gt	r13,r4
; 		bf	.save_z2
; 		mov	r4,r13
; .save_z2:
; 		cmp/gt	r5,r4
; 		bt	.save_z
; 		mov	r4,r5
; .save_z:
; 		cmp/gt	r8,r2
; 		bf	.x_lw
; 		mov	r2,r8
; .x_lw:
; 		cmp/gt	r9,r2
; 		bt	.x_rw
; 		mov	r2,r9
; .x_rw:
; 		cmp/gt	r11,r3
; 		bf	.y_lw
; 		mov	r3,r11
; .y_lw:
; 		cmp/gt	r12,r3
; 		bt	.y_rw
; 		mov	r3,r12
; .y_rw:
;
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
; 		ltorg
;
; ; ------------------------------
; ; Rotate point
; ;
; ; Entry:
; ; r5: x
; ; r6: y
; ; r0: theta
; ;
; ; Returns:
; ; r7: (x  cos @) + (y sin @)
; ; r8: (x -sin @) + (y cos @)
; ; ------------------------------
;
; mdlrd_rotate:
;     		mov	#$7FF,r7
;     		and	r7,r0
;    		shll2	r0
; 		mov	#sin_table,r7
; 		mov	#sin_table+$800,r8
; 		mov	@(r0,r7),r9
; 		mov	@(r0,r8),r10
;
; 		dmuls	r5,r10		; x cos @
; 		sts	macl,r7
; 		sts	mach,r0
; 		xtrct	r0,r7
; 		dmuls	r6,r9		; y sin @
; 		sts	macl,r8
; 		sts	mach,r0
; 		xtrct	r0,r8
; 		add	r8,r7
;
; 		neg	r9,r9
; 		dmuls	r5,r9		; x -sin @
; 		sts	macl,r8
; 		sts	mach,r0
; 		xtrct	r0,r8
; 		dmuls	r6,r10		; y cos @
; 		sts	macl,r9
; 		sts	mach,r0
; 		xtrct	r0,r9
; 		add	r9,r8
;  		rts
; 		nop
; 		align 4

; ; ------------------------------------------------
; ; Init current framebuffer
; ; ------------------------------------------------
;
; .this_fb:
;  		mov	#_framebuffer,r1
; 		mov	#$200/2,r0	; START line data
; 		mov	#240,r2		; Vertical lines to set
; 		mov	r0,r3		; Increment by (copy from r0)
; .loop:		mov.w	r0,@r1
; 		add	#2,r1
; 		add	r3,r0
; 		dt	r2
; 		bf	.loop
; .fb_wait1:	mov.w   @($A,r4),r0	; Swap for next table
; 		tst     #2,r0
; 		bf      .fb_wait1
; 		mov.w   @($A,r4), r0
; 		xor     #1,r0
; 		mov.w   r0,@($A,r4)
; 		and     #1,r0
; 		mov     r0,r1
; .wait_result:
; 		mov.w   @($A,r4),r0
; 		and     #1,r0
; 		cmp/eq  r0,r1
; 		bf      .wait_result
; 		rts
; 		nop
; 		align 4

; ; ------------------------------------------------
; ; Read polygon and build pieces
; ;
; ; Input:
; ; r14 - Polygon data
; ;
; ; polygn_type bits:
; ; %tsp----- -------- -------- --------
; ;
; ; p - Polygon type: Quad (0) or Triangle (1)
; ; s - Corrds are Normal (0) or Sprite (1) <-- Unused.
; ; t - Polygon has texture data (1):
; ;     polygn_mtrlopt: Texture width
; ;     polygn_mtrl   : Texture data address
; ;     polygn_srcpnts: Texture X/Y positions for
; ;                     each edge (3 or 4)
; ; ------------------------------------------------
;
; MarsVideo_SlicePlgn:
; 		sts	pr,@-r15
; 		mov	#Cach_DDA_Last,r13		; r13 - DDA last point
; 		mov	#Cach_DDA_Top,r12		; r12 - DDA first point
; 		mov	@(polygn_type,r14),r0
; 		shlr16	r0
; 		shlr8	r0
; 		tst	#PLGN_TRI,r0			; PLGN_TRI set?
; 		bf	.tringl
; 		add	#8,r13				; If quad: add 8
; .tringl:
; 		mov	r14,r1
; 		mov	r12,r2
; 		mov	#Cach_DDA_Src,r3
; 		add	#polygn_points,r1
; ; 		tst	#PLGN_SPRITE,r0			; PLGN_SPRITE set?
; ; 		bt	.plgn_pnts
; ;
; ; ; ----------------------------------------
; ; ; Sprite points
; ; ; ----------------------------------------
; ;
; ; ; TODO: rework or get rid of this
; ; .spr_pnts:
; ; 		mov.w	@r1+,r8		; X pos
; ; 		mov.w	@r1+,r9		; Y pos
; ;
; ; 		mov.w	@r1+,r4
; ; 		mov.w	@r1+,r6
; ; 		mov.w	@r1+,r5
; ; 		mov.w	@r1+,r7
; ; 		add	#2*2,r1
; ; 		add	r8,r4
; ; 		add 	r8,r5
; ; 		add	r9,r6
; ; 		add 	r9,r7
; ; 		mov	r5,@r2		; TR
; ; 		add	#4,r2
; ; 		mov	r6,@r2
; ; 		add	#4,r2
; ; 		mov	r4,@r2		; TL
; ; 		add	#4,r2
; ; 		mov	r6,@r2
; ; 		add	#4,r2
; ; 		mov	r4,@r2		; BL
; ; 		add	#4,r2
; ; 		mov	r7,@r2
; ; 		add	#4,r2
; ; 		mov	r5,@r2		; BR
; ; 		add	#4,r2
; ; 		mov	r7,@r2
; ; 		add	#4,r2
; ;
; ; 		mov.w	@r1+,r4
; ; 		mov.w	@r1+,r6
; ; 		mov.w	@r1+,r5
; ; 		mov.w	@r1+,r7
; ; 		mov	r5,@r3		; TR
; ; 		add	#4,r3
; ; 		mov	r6,@r3
; ; 		add	#4,r3
; ; 		mov	r4,@r3		; TL
; ; 		add	#4,r3
; ; 		mov	r6,@r3
; ; 		add	#4,r3
; ; 		mov	r4,@r3		; BL
; ; 		add	#4,r3
; ; 		mov	r7,@r3
; ; 		add	#4,r3
; ; 		mov	r5,@r3		; BR
; ; 		add	#4,r3
; ; 		mov	r7,@r3
; ; 		add	#4,r3
; ; ; 		mov	#4*2,r0
; ; ; .sprsrc_pnts:
; ; ; 		mov.w	@r1+,r0
; ; ; 		mov.w	@r1+,r4
; ; ; 		mov	r0,@r3
; ; ; 		mov	r4,@(4,r3)
; ; ; 		dt	r0
; ; ; 		bf/s	.sprsrc_pnts
; ; ; 		add	#8,r3
; ; 		bra	.start_math
; ; 		nop
; ;
; ; ; ----------------------------------------
; ; ; Polygon points
; ; ; ----------------------------------------
; ;
; ; .plgn_pnts:
;
; 	; Copy polygon points Cache's DDA
; 		mov	#4,r8
; 		mov	#SCREEN_WIDTH/2,r6
; 		mov	#SCREEN_HEIGHT/2,r7
; .setpnts:
; 		mov.w	@r1+,r4			; Get X
; 		mov.w	@r1+,r5			; Get Y
; 		add	r6,r4			; X + width
; 		add	r7,r5			; Y + height
; 		mov	r4,@r2
; 		mov	r5,@(4,r2)
; 		dt	r8
; 		bf/s	.setpnts
; 		add	#8,r2
;
; 	; Copy texture source points
; 	; to Cache
; 		mov	#4,r8
; .src_pnts:
; 		mov.w	@r1+,r4
; 		mov.w	@r1+,r5
; 		mov	r4,@r3
; 		mov	r5,@(4,r3)
; 		dt	r8
; 		bf/s	.src_pnts
; 		add	#8,r3
;
; 	; Here we search for the lowest Y point
; 	; and highest Y
; 	; r10 - Top Y
; 	; r11 - Bottom Y
; .start_math:
; 		mov	#3,r9
; 		tst	#PLGN_TRI,r0			; PLGN_TRI set?
; 		bf	.ytringl
; 		add	#1,r9
; .ytringl:
; 		mov	#$7FFFFFFF,r10
; 		mov	#$FFFFFFFF,r11
; 		mov 	r12,r7
; 		mov	r12,r8
; .find_top:
; 		mov	@(4,r7),r0
; 		cmp/gt	r11,r0
; 		bf	.is_low
; 		mov 	r0,r11
; .is_low:
; 		mov	@(4,r8),r0
; 		cmp/gt	r10,r0
; 		bt	.is_high
; 		mov 	r0,r10
; 		mov	r8,r1
; .is_high:
; 		add 	#8,r7
; 		dt	r9
; 		bf/s	.find_top
; 		add	#8,r8
; 		cmp/ge	r11,r10			; Top larger than Bottom?
; 		bt	.exit
; 		cmp/pl	r11			; Bottom < 0?
; 		bf	.exit
; 		mov	#SCREEN_HEIGHT,r0	; Top > 224?
; 		cmp/ge	r0,r10
; 		bt	.exit
;
; 	; r2 - Left DDA READ pointer
; 	; r3 - Right DDA READ pointer
; 	; r4 - Left X
; 	; r5 - Left DX
; 	; r6 - Right X
; 	; r7 - Right DX
; 	; r8 - Left width
; 	; r9 - Right width
; 	; r10 - Top Y, gets updated after calling put_piece
; 	; r11 - Bottom Y
; 	; r12 - First DST point
; 	; r13 - Last DST point
; 		mov	r1,r2				; r2 - X left to process
; 		mov	r1,r3				; r3 - X right to process
; 		bsr	set_left
; 		nop
; 		bsr	set_right
; 		nop
; .next_pz:
; 		mov	#SCREEN_HEIGHT,r0		; Current Y > 224?
; 		cmp/gt	r0,r10
; 		bt	.exit
; 		cmp/ge	r11,r10				; Y top => Y bottom?
; 		bt	.exit
; 		mov	@(marsGbl_PlyPzList_W,gbr),r0	; r1 - Current piece to WRITE
; 		mov	r0,r1
; 		mov	#RAM_Mars_VdpDrwList_e,r0	; pointer reached end of the list?
; 		cmp/ge	r0,r1
; 		bf	.dontreset
; 		mov	#RAM_Mars_VdpDrwList,r0		; Return WRITE pointer to the top of the list
; 		mov	r0,r1
; 		mov	r0,@(marsGbl_PlyPzList_W,gbr)
; .dontreset:
; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_WdDrwPause,gbr)	; Tell watchdog we are mid-write
; 		bsr	put_piece
; 		nop
; 		mov	#0,r0
; 		mov.w	r0,@(marsGbl_WdDrwPause,gbr)	; Unlock.
;
; 	; X direction update
; 		cmp/gt	r9,r8				; Left width > Right width?
; 		bf	.lefth2
; 		bsr	set_right
; 		nop
; 		bra	.next_pz
; 		nop
; .lefth2:
; 		bsr	set_left
; 		nop
; 		bra	.next_pz
; 		nop
; .exit:
; 		lds	@r15+,pr
; 		rts
; 		nop
; 		align 4
; 		ltorg
;
; ; --------------------------------
;
; set_left:
; 		mov	r2,r8			; Get a copy of Xleft pointer
; 		add	#$20,r8			; To read Texture SRC points
; 		mov	@r8,r4
; 		mov	@(4,r8),r5
; 		mov	#Cach_DDA_Src_L,r8
; 		mov	r4,r0
; 		shll16	r0
; 		mov	r0,@r8
; 		mov	r5,r0
; 		shll16	r0
; 		mov	r0,@(8,r8)
; 		mov	@r2,r1
; 		mov	@(4,r2),r8
; 		add	#8,r2
; 		cmp/gt	r13,r2
; 		bf	.lft_ok
; 		mov 	r12,r2
; .lft_ok:
; 		mov	@(4,r2),r0
; 		sub	r8,r0
; 		cmp/eq	#0,r0
; 		bt	set_left
; 		cmp/pz	r0
; 		bf	.lft_skip
;
; 		lds	r0,mach
; 		mov	r2,r8
; 		add	#$20,r8
; 		mov 	@r8,r0
; 		sub 	r4,r0
; 		mov 	@(4,r8),r4
; 		sub 	r5,r4
; 		mov	r0,r5
; 		shll8	r4
; 		shll8	r5
; 		sts	mach,r8
; 		mov	#1,r0				; Tell WD we are using
; 		mov.w	r0,@(marsGbl_DivStop_M,gbr)	; HW Division
; 		mov	#_JR,r0
; 		mov	r8,@r0
; 		mov	r5,@(4,r0)
; 		nop
; 		mov	@(4,r0),r5
; 		mov	#_JR,r0
; 		mov	r8,@r0
; 		mov	r4,@(4,r0)
; 		nop
; 		mov	@(4,r0),r4
; 		shll8	r4
; 		shll8	r5
; 		mov	#Cach_DDA_Src_L+$C,r0
; 		mov	r4,@r0
; 		mov	#Cach_DDA_Src_L+4,r0
; 		mov	r5,@r0
; 		mov	@r2,r5
; 		sub 	r1,r5
; 		mov 	r1,r4
; 		shll8	r5
; 		shll16	r4
; 		mov	#_JR,r0
; 		mov	r8,@r0
; 		mov	r5,@(4,r0)
; 		nop
; 		mov	@(4,r0),r5
; 		mov	#0,r0				; Unlock HW division
; 		mov.w	r0,@(marsGbl_DivStop_M,gbr)
; 		shll8	r5
; .lft_skip:
; 		rts
; 		nop
; 		align 4
;
; ; --------------------------------
;
; set_right:
; 		mov	r3,r9
; 		add	#$20,r9
; 		mov	@r9,r6
; 		mov	@(4,r9),r7
; 		mov	#Cach_DDA_Src_R,r9
; 		mov	r6,r0
; 		shll16	r0
; 		mov	r0,@r9
; 		mov	r7,r0
; 		shll16	r0
; 		mov	r0,@(8,r9)
;
; 		mov	@r3,r1
; 		mov	@(4,r3),r9
; 		add	#-8,r3
; 		cmp/ge	r12,r3
; 		bt	.rgt_ok
; 		mov 	r13,r3
; .rgt_ok:
; 		mov	@(4,r3),r0
; 		sub	r9,r0
; 		cmp/eq	#0,r0
; 		bt	set_right
; 		cmp/pz	r0
; 		bf	.rgt_skip
; 		lds	r0,mach
; 		mov	r3,r9
; 		add	#$20,r9
; 		mov 	@r9,r0
; 		sub 	r6,r0
; 		mov 	@(4,r9),r6
; 		sub 	r7,r6
; 		mov	r0,r7
; 		shll8	r6
; 		shll8	r7
; 		sts	mach,r9
; 		mov	#1,r0				; Tell WD we are using
; 		mov.w	r0,@(marsGbl_DivStop_M,gbr)	; HW Division
; 		mov	#_JR,r0
; 		mov	r9,@r0
; 		mov	r7,@(4,r0)
; 		nop
; 		mov	@(4,r0),r7
; 		mov	#_JR,r0
; 		mov	r9,@r0
; 		mov	r6,@(4,r0)
; 		nop
; 		mov	@(4,r0),r6
; 		shll8	r6
; 		shll8	r7
; 		mov	#Cach_DDA_Src_R+4,r0
; 		mov	r7,@r0
; 		mov	#Cach_DDA_Src_R+$C,r0
; 		mov	r6,@r0
; 		mov	@r3,r7
; 		sub 	r1,r7
; 		mov 	r1,r6
; 		shll16	r6
; 		shll8	r7
; 		mov	#_JR,r0
; 		mov	r9,@r0
; 		mov	r7,@(4,r0)
; 		nop
; 		mov	@(4,r0),r7
; 		mov	#0,r0				; Unlock HW division
; 		mov.w	r0,@(marsGbl_DivStop_M,gbr)
; 		shll8	r7
; .rgt_skip:
; 		rts
; 		nop
; 		align 4
; 		ltorg
;
; ; --------------------------------
; ; Mark piece
; ; --------------------------------
;
; put_piece:
; 		mov	@(4,r2),r8
; 		mov	@(4,r3),r9
; 		sub	r10,r8
; 		sub	r10,r9
; 		mov	r8,r0
; 		cmp/gt	r8,r9
; 		bt	.lefth
; 		mov	r9,r0
; .lefth:
; 		mov	r2,@-r15
; 		mov	r3,@-r15
; 		mov	r5,@-r15
; 		mov	r7,@-r15
; 		mov	r8,@-r15
; 		mov	r9,@-r15
; 		mov 	r4,@(plypz_xl,r1)
; 		mov 	r5,@(plypz_xl_dx,r1)
; 		mov 	r6,@(plypz_xr,r1)
; 		mov 	r7,@(plypz_xr_dx,r1)
; 		dmuls	r0,r5
; 		sts	macl,r2
; 		dmuls	r0,r7
; 		sts	macl,r3
; 		add 	r2,r4
; 		add	r3,r6
; 		mov	r10,r2
; 		add	r0,r10
; 		mov	r10,r3
; 		shll16	r2
; 		or	r2,r3
; 		mov	r3,@(plypz_ypos,r1)
; 		mov	r3,@-r15
; 		mov	#Cach_DDA_Src_L,r2
; 		mov	@r2,r5
; 		mov	r5,@(plypz_src_xl,r1)
; 		mov	@(4,r2),r7
; 		mov	r7,@(plypz_src_xl_dx,r1)
; 		mov	@(8,r2),r8
; 		mov	r8,@(plypz_src_yl,r1)
; 		mov	@($C,r2),r9
; 		mov	r9,@(plypz_src_yl_dx,r1)
; 		dmuls	r0,r7
; 		sts	macl,r2
; 		dmuls	r0,r9
; 		sts	macl,r3
; 		add 	r2,r5
; 		add	r3,r8
; 		mov	#Cach_DDA_Src_L,r2
; 		mov	r5,@r2
; 		mov	r8,@(8,r2)
; 		mov	#Cach_DDA_Src_R,r2
; 		mov	@r2,r5
; 		mov	r5,@(plypz_src_xr,r1)
; 		mov	@(4,r2),r7
; 		mov	r7,@(plypz_src_xr_dx,r1)
; 		mov	@(8,r2),r8
; 		mov	r8,@(plypz_src_yr,r1)
; 		mov	@($C,r2),r9
; 		mov	r9,@(plypz_src_yr_dx,r1)
; 		dmuls	r0,r7
; 		sts	macl,r2
; 		dmuls	r0,r9
; 		sts	macl,r3
; 		add 	r2,r5
; 		add	r3,r8
; 		mov	#Cach_DDA_Src_R,r2
; 		mov	r5,@r2
; 		mov	r8,@(8,r2)
; 		mov	@r15+,r3
; 		cmp/pl	r3			; TOP check, 2 steps
; 		bt	.top_neg
; 		shll16	r3
; 		cmp/pl	r3
; 		bf	.bad_piece
; .top_neg:
; 		mov	@(polygn_mtrl,r14),r0
; 		mov 	r0,@(plypz_mtrl,r1)
; 		mov	@(polygn_type,r14),r0
; 		mov 	r0,@(plypz_type,r1)
; 		add	#sizeof_plypz,r1
; 		mov	r1,r0
; 		mov	#RAM_Mars_VdpDrwList_e,r8
; 		cmp/ge	r8,r0
; 		bf	.dontreset_pz
; 		mov	#RAM_Mars_VdpDrwList,r0
; 		mov	r0,r1
; .dontreset_pz:
; 		mov	r0,@(marsGbl_PlyPzList_W,gbr)
; 		mov.w	@(marsGbl_PzListCntr,gbr),r0
; 		add	#1,r0
; 		mov.w	r0,@(marsGbl_PzListCntr,gbr)
; .bad_piece:
; 		mov	@r15+,r9
; 		mov	@r15+,r8
; 		mov	@r15+,r7
; 		mov	@r15+,r5
; 		mov	@r15+,r3
; 		mov	@r15+,r2
; 		rts
; 		nop
; 		align 4
; 		ltorg

; ; ------------------------------------
; ; MarsVideo_ClearFrame
; ;
; ; Clear the current framebuffer
; ; ------------------------------------
;
; MarsVideo_ClearFrame:
; 		mov	#_vdpreg,r1
; .wait2		mov.w	@(10,r1),r0		; Wait for FEN to clear
; 		and	#%10,r0
; 		cmp/eq	#2,r0
; 		bt	.wait2
;
; 		mov	#255,r2			; r2 - lenght: 256 words per pass
; 		mov	#$200/2,r3		; r3 - Start address / 2
; 		mov	#0,r4			; r4 - data (zero)
; 		mov	#256,r5			; Increment address by 256
; 		mov	#((512*240)/256)/2,r6	; 140 passes
; .loop
; 		mov	r2,r0
; 		mov.w	r0,@(4,r1)		; Set length
; 		mov	r3,r0
; 		mov.w	r0,@(6,r1)		; Set address
; 		mov	r4,r0
; 		mov.w	r0,@(8,r1)		; Set data
; 		add	r5,r3
;
; .wait		mov.w	@(10,r1),r0		; Wait for FEN to clear
; 		and	#%10,r0
; 		cmp/eq	#2,r0
; 		bt	.wait
; 		dt	r6
; 		bf	.loop
; 		rts
; 		nop
; 		align 4

; ------------------------------------
; MarsVideo_FrameSwap
; ------------------------------------

; MarsVideo_FrameSwap:
; 		mov.l	#_vdpreg,r2
; .wait_fb:
; 		mov.w	@($A,r2),r0
; 		tst	#2,r0
; 		bf	.wait_fb
; 		mov.w	@($A,r2),r0
; 		xor	#1,r0
; 		mov.w	r0,@($A,r2)
; 		and	#1,r0
; 		mov	r0,r1
; .wait_result:
; 		mov.w	@($A,r2),r0
; 		and	#1,r0
; 		cmp/eq	r0,r1
; 		bf	.wait_result
; 		rts
; 		nop
; 		align 4
