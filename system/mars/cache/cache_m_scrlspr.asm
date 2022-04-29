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
; Watchdog interrupt for MASTER CPU
; --------------------------------------------------------

		mov	#$F0,r0
		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)

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
		mov	r11,@-r0
		mov	r12,@-r0
		mov	r13,@-r0
		mov	r14,@-r0
		sts	macl,@-r0
		sts	mach,@-r0
		sts	pr,@-r0

	; r1 - current sprite
	; r2 - output piece
		mov	@(marsGbl_CurrRdSpr,gbr),r0
		mov	r0,r1
		mov	@(marsGbl_PlyPzList_W,gbr),r0
		mov	r0,r2
		mov	@(marsspr_data,r1),r0
		tst	r0,r0
		bt	.finish_now
		mov	r0,@(plypz_mtrl,r2)

		mov	#32,r0
		shll16	r0
		mov	r0,r3				; spritesheet width
		mov.w	@(marsspr_indx,r1),r0		; index palette
		and	#$FF,r0
		or	r3,r0
		mov	r0,@(plypz_type,r2)

		mov.w	@(marsspr_y,r1),r0		; Y top/bottom
		mov	r0,r3
		mov	r0,r4
		mov.w	@(marsspr_ys,r1),r0
		add	r0,r4
		mov	#$FFFF,r0
		and	r0,r4
		shll16	r3
		or	r4,r3
		mov	r3,@(plypz_ypos,r2)

		mov.w	@(marsspr_x,r1),r0		; XL/XR
		mov	r0,r3
		mov	r0,r4
		mov.w	@(marsspr_xs,r1),r0
		add	r0,r4
		shll16	r3
		shll16	r4
		mov	r3,@(plypz_xl,r2)
		mov	r4,@(plypz_xr,r2)
		mov	#0,r0				; no DX
		mov	r0,@(plypz_xl_dx,r2)
		mov	r0,@(plypz_xr_dx,r2)

		mov	#0,r3
		mov	#32<<16,r4
		mov	#0,r5
		mov	#0,r6
		mov	r3,@(plypz_src_xl,r2)
		mov	r4,@(plypz_src_xr,r2)
		mov	r5,@(plypz_src_yl,r2)
		mov	r6,@(plypz_src_yr,r2)

		mov	#1<<16,r0
; 		mov	r0,@(plypz_src_xl_dx,r2)
; 		mov	r0,@(plypz_src_xr_dx,r2)
		mov	r0,@(plypz_src_yl_dx,r2)
		mov	r0,@(plypz_src_yr_dx,r2)

		add	#sizeof_marsspr,r1
		add	#sizeof_plypz,r2
		mov	r1,r0
		mov	r0,@(marsGbl_CurrRdSpr,gbr)
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0	; add piece
		add	#1,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)

.finish_now:
		mov	#Cach_SprBkup_L,r0
		lds	@r0+,pr
		lds	@r0+,mach
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
; MarsVideo_BuildSuperSpr
;
; Builds super sprites into svdp-pieces
;
; r14 - Background buffer
; --------------------------------------------------------

		align 4
MarsVideo_DrawSuperSpr:


MarsVideo_NextSuperSpr:
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0
		cmp/pl	r0
		bf	.no_pz
		mov	@(marsGbl_PlyPzList_R,gbr),r0	; r11 - Current pieces pointer to READ
		mov	r0,r11
		mov	@(plypz_ypos,r11),r9		; Start grabbing StartY/EndY positions
		mov	r9,r10
		mov	#$FFFF,r0
		shlr16	r9
		exts	r9,r9				;  r9 - Top
		and	r0,r10				; r10 - Bottom
		cmp/eq	r9,r0				; if Top==Bottom, exit
		bt	.invld_y
		mov	#SCREEN_HEIGHT,r0		; if Top > 224, skip
		cmp/ge	r0,r9
		bt	.invld_y			; if Bottom > 224, add max limit
		cmp/gt	r0,r10
		bf	.len_max
		mov	r0,r10
.len_max:
		sub	r9,r10				; Turn r10 into line lenght (Bottom - Top)
		cmp/pl	r10
		bt	.drwtsk1_vld_y
.invld_y:
		bra	.drwtex_gonxtpz		; if LEN < 0 then check next one instead.
		nop
.no_pz:
		bra	.drwtask_exit
		nop
		align 4
.drwtsk1_vld_y:

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
; r9  - Y current
; r10  - Number of lines
; ------------------------------------

		mov	@(plypz_xl,r11),r1		; r1 - X left
		mov	@(plypz_xl_dx,r11),r2		; r2 - DX left
		mov	@(plypz_xr,r11),r3		; r3 - X right
		mov	@(plypz_xr_dx,r11),r4		; r4 - DX right
		mov	@(plypz_src_xl,r11),r5		; Texture X left
		mov	@(plypz_src_xr,r11),r6		; Texture X right
		mov	@(plypz_src_yl,r11),r7		; Texture Y up
		mov	@(plypz_src_yr,r11),r8		; Texture Y down
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
		mov	r1,@-r15
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		mov	r10,@-r15
		mov	r11,@-r15

	; r11
; 		mov	r1,r1			; r1 - X left
; 		mov	r3,r3			; r3 - X right
		shlr16	r1
		shlr16	r3
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

	; TODO: cache variables instead of
	; indirect r14
		mov.w	@(mbg_intrl_h,r14),r0
		mov	r0,r12
		mov.w	@(mbg_intrl_w,r14),r0
		mov	r0,r13
		mov.w	@(mbg_fbpos_y,r14),r0
		add	r9,r0
		cmp/ge	r12,r0
		bf	.y_tp
		sub	r12,r0
.y_tp:
		mov	@(mbg_intrl_size,r14),r12
		muls	r0,r13
		sts	macl,r0
		mov	@(mbg_fbpos,r14),r13
		add	r1,r13
		add	r0,r13			; r13 - FB topleft
		mov	@(mbg_fbdata,r14),r0
		mov	#_overwrite,r9
		add	r0,r9

		mov	@(plypz_mtrl,r11),r1
		mov	@(plypz_type,r11),r4
		mov	r4,r11
		shlr16	r4
		mov	#$FF,r0
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
		add	r11,r0			; Add index increment
		and	#$FF,r0
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

		add	#1,r13
		add	r6,r5			; Update X
		dt	r3
		bf/s	.tex2_xloop
		add	r8,r7			; Update Y
.tex_skip_line:
		mov	@r15+,r11
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		mov	@r15+,r1
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
.drwtex_gonxtpz:
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
		cmp/pl	r0
		bf	.finish_it
		bra	MarsVideo_NextSuperSpr
		nop
		align 4
.finish_it:
.drwtask_exit:
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------

		align 4
Cach_SprBkup_L	ds.l 16		;
Cach_SprBkup_S	ds.l 0		; <-- Reads backwards

; ------------------------------------------------
.end:		phase CACHE_MSTR_SCRL+.end&$1FFF
		align 4
CACHE_MSTR_SCRL_E:
	if MOMPASS=6
		message "THIS CACHE CODE uses: \{(CACHE_MSTR_SCRL_E-CACHE_MSTR_SCRL)}"
	endif
