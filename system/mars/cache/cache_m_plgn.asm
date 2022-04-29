; ====================================================================
; ----------------------------------------------------------------
; CACHE code for MASTER CPU
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_MSTR_PLGN:
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

		mov.w	@(marsGbl_CntrRdPlgn,gbr),r0
		cmp/eq	#0,r0
		bf	.has_plgn
		bra	wdg_finish
		nop
		align 4
.has_plgn:
		dt	r0
		mov.w	r0,@(marsGbl_CntrRdPlgn,gbr)
		mov	@(marsGbl_CurrRdPlgn,gbr),r0
		mov	@(4,r0),r14
		mov	#Cach_Bkup_S,r0
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
		mov	#Cach_DDA_Last,r13		; r13 - DDA last point
		mov	#Cach_DDA_Top,r12		; r12 - DDA first point
		mov	@(polygn_type,r14),r0		; Read type settings
		shlr16	r0
		shlr8	r0
		tst	#PLGN_TRI,r0			; PLGN_TRI set?
		bf	.tringl
		add	#8,r13				; If quad: add 8
.tringl:
		mov	r14,r1
		mov	r12,r2
		mov	#Cach_DDA_Src,r3
		add	#polygn_points,r1

	; ----------------------------------------
	; Polygon points
	; ----------------------------------------

	; TODO: put custom WIDTH/HEIGHT halfs here
		mov	#4,r8			; Copy polygon points Cache's DDA
		mov	#SCREEN_WIDTH/2,r6
		mov	#SCREEN_HEIGHT/2,r7
.setpnts:
		mov	@r1+,r4			; Get X
		mov	@r1+,r5			; Get Y
		add	r6,r4			; X + width
		add	r7,r5			; Y + height
		mov	r4,@r2
		mov	r5,@(4,r2)
		dt	r8
		bf/s	.setpnts
		add	#8,r2
		mov	#4,r8			; Copy texture source points to Cache
.src_pnts:
		mov.w	@r1+,r4
		mov.w	@r1+,r5
		mov	r4,@r3
		mov	r5,@(4,r3)
		dt	r8
		bf/s	.src_pnts
		add	#8,r3

	; Search for the lowest Y and highest Y
	; r10 - Top Y
	; r11 - Bottom Y
.start_math:
		mov	#3,r9
		tst	#PLGN_TRI,r0		; PLGN_TRI set?
		bf	.ytringl
		add	#1,r9
.ytringl:
		mov	#$7FFFFFFF,r10
		mov	#-1,r11			; $FFFFFFFF
		mov 	r12,r7
		mov	r12,r8
.find_top:
		mov	@(4,r7),r0
		cmp/gt	r11,r0
		bf	.is_low
		mov 	r0,r11
.is_low:
		mov	@(4,r8),r0
		cmp/gt	r10,r0
		bt	.is_high
		mov 	r0,r10
		mov	r8,r1
.is_high:
		add 	#8,r7
		dt	r9
		bf/s	.find_top
		add	#8,r8
		cmp/ge	r11,r10			; Top larger than Bottom?
		bt	.exit
		cmp/pl	r11			; Bottom < 0?
		bf	.exit
		mov	#SCREEN_HEIGHT,r0	; Top > 224?
		cmp/ge	r0,r10
		bt	.exit

	; r2 - Left DDA READ pointer
	; r3 - Right DDA READ pointer
	; r4 - Left X
	; r5 - Left DX
	; r6 - Right X
	; r7 - Right DX
	; r8 - Left width
	; r9 - Right width
	; r10 - Top Y, gets updated after calling put_piece
	; r11 - Bottom Y
	; r12 - First DST point
	; r13 - Last DST point
		mov	r1,r2				; r2 - X left to process
		mov	r1,r3				; r3 - X right to process
		bsr	set_left
		nop
		bsr	set_right
		nop
.next_pz:
		mov	#SCREEN_HEIGHT,r0		; Current Y > 224?
		cmp/gt	r0,r10
		bt	.exit
		cmp/ge	r11,r10				; Y top => Y bottom?
		bt	.exit
		mov	@(marsGbl_PlyPzList_W,gbr),r0	; r1 - Current piece to WRITE
		mov	r0,r1
; 		mov	#RAM_Mars_SVdpDrwList_e,r0	; pointer reached end of the list?
; 		cmp/ge	r0,r1
; 		bf	.dontreset
; 		mov	#RAM_Mars_SVdpDrwList,r0	; Return WRITE pointer to the top of the list
; 		mov	r0,r1
; 		mov	r0,@(marsGbl_PlyPzList_W,gbr)
; .dontreset:
		mov	@(4,r2),r8
		mov	@(4,r3),r9
		sub	r10,r8
		sub	r10,r9
		mov	r8,r0
		cmp/gt	r8,r9
		bt	.lefth
		mov	r9,r0
.lefth:
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r5,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		bsr	put_piece
		nop
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r5
		mov	@r15+,r3
		mov	@r15+,r2
	; X direction update
		cmp/gt	r9,r8				; Left width > Right width?
		bf	.lefth2
		bsr	set_right
		nop
		bra	.next_pz
		nop
.lefth2:
		bsr	set_left
		nop
		bra	.next_pz
		nop
.exit:
		mov	#Cach_Bkup_L,r0
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
		mov	@(marsGbl_CurrRdPlgn,gbr),r0
		add	#8,r0
		mov	r0,@(marsGbl_CurrRdPlgn,gbr)
wdm_next:
		mov.l   #$FFFFFE80,r1
		mov.w   #$A518,r0		; OFF
		mov.w   r0,@r1
		or      #$20,r0			; ON
		mov.w   r0,@r1
		mov.w   #$5A10,r0		; Timer for the next WD
		mov.w   r0,@r1
		rts
		nop
		align 4
		ltorg
wdg_finish:
; 		xor	r0,r0
; 		mov.w	r0,@(marsGbl_WdgMode,gbr)
; 		add	#1,r0
		mov	#1,r0
		mov.w	r0,@(marsGbl_WdgStatus,gbr)
		mov	#$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		rts
		nop
		align 4

; --------------------------------------------------------

		align 4
set_left:
		mov	r2,r8			; Get a copy of Xleft pointer
		add	#$20,r8			; To read Texture SRC points
		mov	@r8,r4
		mov	@(4,r8),r5
		mov	#Cach_DDA_Src_L,r8
		mov	r4,r0
		shll16	r0
		mov	r0,@r8
		mov	r5,r0
		shll16	r0
		mov	r0,@(8,r8)
		mov	@r2,r1
		mov	@(4,r2),r8
		add	#8,r2
		cmp/gt	r13,r2
		bf	.lft_ok
		mov 	r12,r2
.lft_ok:
		mov	@(4,r2),r0
		sub	r8,r0
		cmp/eq	#0,r0
		bt	set_left
		cmp/pz	r0
		bf	.lft_skip

		lds	r0,mach
		mov	r2,r8
		add	#$20,r8
		mov 	@r8,r0
		sub 	r4,r0
		mov 	@(4,r8),r4
		sub 	r5,r4
		mov	r0,r5
		shll8	r4
		shll8	r5
		sts	mach,r8
		mov	#_JR,r0
		mov	r8,@r0
		mov	r5,@(4,r0)
		nop
		mov	@(4,r0),r5
		mov	#_JR,r0
		mov	r8,@r0
		mov	r4,@(4,r0)
		nop
		mov	@(4,r0),r4
		shll8	r4
		shll8	r5
		mov	#Cach_DDA_Src_L+$C,r0
		mov	r4,@r0
		mov	#Cach_DDA_Src_L+4,r0
		mov	r5,@r0
		mov	@r2,r5
		sub 	r1,r5
		mov 	r1,r4
		shll8	r5
		shll16	r4
		mov	#_JR,r0
		mov	r8,@r0
		mov	r5,@(4,r0)
		nop
		mov	@(4,r0),r5
		shll8	r5
.lft_skip:
		rts
		nop
		align 4

; --------------------------------------------------------

set_right:
		mov	r3,r9
		add	#$20,r9
		mov	@r9,r6
		mov	@(4,r9),r7
		mov	#Cach_DDA_Src_R,r9
		mov	r6,r0
		shll16	r0
		mov	r0,@r9
		mov	r7,r0
		shll16	r0
		mov	r0,@(8,r9)

		mov	@r3,r1
		mov	@(4,r3),r9
		add	#-8,r3
		cmp/ge	r12,r3
		bt	.rgt_ok
		mov 	r13,r3
.rgt_ok:
		mov	@(4,r3),r0
		sub	r9,r0
		cmp/eq	#0,r0
		bt	set_right
		cmp/pz	r0
		bf	.rgt_skip
		lds	r0,mach
		mov	r3,r9
		add	#$20,r9
		mov 	@r9,r0
		sub 	r6,r0
		mov 	@(4,r9),r6
		sub 	r7,r6
		mov	r0,r7
		shll8	r6
		shll8	r7
		sts	mach,r9
		mov	#_JR,r0
		mov	r9,@r0
		mov	r7,@(4,r0)
		nop
		mov	@(4,r0),r7
		mov	#_JR,r0
		mov	r9,@r0
		mov	r6,@(4,r0)
		nop
		mov	@(4,r0),r6
		shll8	r6
		shll8	r7
		mov	#Cach_DDA_Src_R+4,r0
		mov	r7,@r0
		mov	#Cach_DDA_Src_R+$C,r0
		mov	r6,@r0
		mov	@r3,r7
		sub 	r1,r7
		mov 	r1,r6
		shll16	r6
		shll8	r7
		mov	#_JR,r0
		mov	r9,@r0
		mov	r7,@(4,r0)
		nop
		mov	@(4,r0),r7
		shll8	r7
.rgt_skip:
		rts
		nop
		align 4

; --------------------------------------------------------

put_piece:
		mov	@(4,r2),r8
		mov	@(4,r3),r9
		sub	r10,r8
		sub	r10,r9
		mov	r8,r0
		cmp/gt	r8,r9
		bt	.lefth
		mov	r9,r0
.lefth:
		mov 	r4,@(plypz_xl,r1)
		mov 	r5,@(plypz_xl_dx,r1)
		mov 	r6,@(plypz_xr,r1)
		mov 	r7,@(plypz_xr_dx,r1)
		dmuls	r0,r5
		sts	macl,r2
		dmuls	r0,r7
		sts	macl,r3
		add 	r2,r4
		add	r3,r6
		mov	r10,r2
		add	r0,r10
		mov	r10,r3
		shll16	r2
		or	r2,r3
		mov	r3,@(plypz_ypos,r1)
		mov	r3,@-r15
		mov	#Cach_DDA_Src_L,r2
		mov	@r2,r5
		mov	r5,@(plypz_src_xl,r1)
		mov	@(4,r2),r7
		mov	r7,@(plypz_src_xl_dx,r1)
		mov	@(8,r2),r8
		mov	r8,@(plypz_src_yl,r1)
		mov	@($C,r2),r9
		mov	r9,@(plypz_src_yl_dx,r1)
		dmuls	r0,r7
		sts	macl,r2
		dmuls	r0,r9
		sts	macl,r3
		add 	r2,r5
		add	r3,r8
		mov	#Cach_DDA_Src_L,r2
		mov	r5,@r2
		mov	r8,@(8,r2)
		mov	#Cach_DDA_Src_R,r2
		mov	@r2,r5
		mov	r5,@(plypz_src_xr,r1)
		mov	@(4,r2),r7
		mov	r7,@(plypz_src_xr_dx,r1)
		mov	@(8,r2),r8
		mov	r8,@(plypz_src_yr,r1)
		mov	@($C,r2),r9
		mov	r9,@(plypz_src_yr_dx,r1)
		dmuls	r0,r7
		sts	macl,r2
		dmuls	r0,r9
		sts	macl,r3
		add 	r2,r5
		add	r3,r8
		mov	#Cach_DDA_Src_R,r2
		mov	r5,@r2
		mov	r8,@(8,r2)
		mov	@r15+,r3
		cmp/pl	r3			; TOP check, 2 steps
		bt	.top_neg
		shll16	r3
		cmp/pl	r3
		bf	.bad_piece
.top_neg:
		mov	@(polygn_mtrl,r14),r0
		mov 	r0,@(plypz_mtrl,r1)
		mov	@(polygn_type,r14),r0
		mov 	r0,@(plypz_type,r1)
		add	#sizeof_plypz,r1
		mov	r1,r0
		mov	#RAM_Mars_SVdpDrwList_e,r8
		cmp/ge	r8,r0
		bf	.dontreset_pz
		mov	#RAM_Mars_SVdpDrwList,r0
		mov	r0,r1
.dontreset_pz:
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0
		add	#1,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
.bad_piece:
		rts
		nop
		align 4
		ltorg
		align 4

; ====================================================================
; --------------------------------------------------------
; MarsVideo_DrawPzPlgns
;
; Draws polygons on framebuffer using the pieces list
; --------------------------------------------------------

		align 4
MarsVideo_DrawPzPlgns:
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0
		cmp/pl	r0
		bf	.no_pz
		mov	@(marsGbl_PlyPzList_R,gbr),r0	; r14 - Current pieces pointer to READ
		mov	r0,r14
		mov	@(plypz_ypos,r14),r9		; Start grabbing StartY/EndY positions
		mov	r9,r10
		mov	#$FFFF,r0
		shlr16	r9
		exts	r9,r9			;  r9 - Top
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
		bt	drwtsk1_vld_y
.invld_y:
		bra	drwsld_nextpz		; if LEN < 0 then check next one instead.
		nop
.no_pz:
		bra	drwtask_exit
		nop
		align 4
		ltorg
		align 4

	; ------------------------------------
	; If Y top / Y len are valid:
	; ------------------------------------

drwtsk1_vld_y:
		mov	@(plypz_xl,r14),r1		; r1 - X left
		mov	@(plypz_xl_dx,r14),r2		; r2 - DX left
		mov	@(plypz_xr,r14),r3		; r3 - X right
		mov	@(plypz_xr_dx,r14),r4		; r4 - DX right
		mov	@(plypz_type,r14),r0		; Check material options
		shlr16	r0
		shlr8	r0
 		tst	#PLGN_TEXURE,r0			; Texture mode?
 		bf	drwtsk_texmode
		bra	drwtsk_solidmode
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
; r9  - Y current
; r10  - Number of lines
; ------------------------------------

go_drwsld_updline_tex:
		bra	drwsld_updline_tex
		nop
go_drwtex_gonxtpz:
		bra	drwtex_gonxtpz
		nop
drwtsk_texmode:
		mov	@(plypz_src_xl,r14),r5		; Texture X left
		mov	@(plypz_src_xr,r14),r6		; Texture X right
		mov	@(plypz_src_yl,r14),r7		; Texture Y up
		mov	@(plypz_src_yr,r14),r8		; Texture Y down
drwsld_nxtline_tex:
		cmp/pz	r9			; Y Start below 0?
		bf	go_drwsld_updline_tex
		mov	tag_yhght,r0		; Y Start after 224?
		cmp/ge	r0,r9
		bt	go_drwtex_gonxtpz
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r10,@-r15
; 		mov	r13,@-r15
		mov	r1,r11			; r11 - X left copy
		mov	r3,r12			; r12 - X right copy
		shlr16	r11
		shlr16	r12
		exts	r11,r11
		exts	r12,r12
		mov	r12,r0			; r0: X Right - X Left
		sub	r11,r0
		cmp/pl	r0			; Line reversed?
		bt	.txrevers
		mov	r12,r0			; Swap XL and XR values
		mov	r11,r12
		mov	r0,r11
		mov	r5,r0
		mov	r6,r5
		mov	r0,r6
		mov	r7,r0
		mov	r8,r7
		mov	r0,r8
.txrevers:
		cmp/eq	r11,r12				; Same X position?
		bt	.tex_skip_line
		mov	tag_width,r0			; X right < 0?
		cmp/pl	r12
		bf	.tex_skip_line
		cmp/gt	r0,r11				; X left > 320?
		bt	.tex_skip_line
		mov	r12,r2
		mov 	r11,r0
		sub 	r0,r2
		sub	r5,r6
		sub	r7,r8

	; Calculate new DX values
	; make sure DIV is available
	; (marsGbl_DivStop_M == 0)
		mov	tag_JR,r0			; r6 / r2
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
		mov	tag_width,r0		; XR point > 320?
		cmp/gt	r0,r12
		bf	.tr_fix
		mov	r0,r12				; Force XR to 320
.tr_fix:
		cmp/pz	r11				; XL point < 0?
		bt	.tl_fix
		neg	r11,r2				; Fix texture positions
		dmuls	r6,r2
		sts	macl,r0
		add	r0,r5
		dmuls	r8,r2
		sts	macl,r0
		add	r0,r7
		xor	r11,r11				; And reset XL to 0
.tl_fix:
	; start
		mov	#-2,r0
		and	r0,r11
		and	r0,r12
		sub 	r11,r12
		shar	r12
		cmp/pl	r12
		bf	.tex_skip_line
		mov	#_overwrite+$200,r10
		mov	@(plypz_type,r14),r4	;  r4 - texture width|palinc
		mov	r4,r13
		shlr16	r4
		mov	#$FF,r0
		mov	#$3FFF,r2
		and	r2,r4
		and	r0,r13
		mov 	r9,r0			; Y position * $200
		shll8	r0
		shll	r0
		add 	r0,r10			; Add Y
		add 	r11,r10			; Add X
		mov	@(plypz_mtrl,r14),r11	; r11 - texture data
.tex_xloop:
		mov	r7,r2
		shlr16	r2
		mulu	r2,r4
		mov	r5,r2	   		; Build column index
		sts	macl,r0
		shlr16	r2
		add	r2,r0
		mov.b	@(r0,r11),r0		; Read texture pixel
		add	r13,r0			; Add index increment
		and	#$FF,r0
		shll8	r0
		lds	r0,mach			; Save left pixel
		add	r6,r5			; Update X
		add	r8,r7			; Update Y
		mov	r7,r2
		shlr16	r2
		mulu	r2,r4
		mov	r5,r2	   		; Build column index
		sts	macl,r0
		shlr16	r2
		add	r2,r0
		mov.b	@(r0,r11),r0		; Read texture pixel
		add	r13,r0			; Add index increment
		and	#$FF,r0
		dt	r12
		sts	mach,r2
		or	r2,r0
		mov.w	r0,@r10
		add	#2,r10
		add	r6,r5			; Update X
		bf/s	.tex_xloop
		add	r8,r7			; Update Y
.tex_skip_line:
; 		mov	@r15+,r13
		mov	@r15+,r10
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
drwsld_updline_tex:
		mov	@(plypz_src_xl_dx,r14),r0	; Update DX postions
		add	r0,r5
		mov	@(plypz_src_xr_dx,r14),r0
		add	r0,r6
		mov	@(plypz_src_yl_dx,r14),r0
		add	r0,r7
		mov	@(plypz_src_yr_dx,r14),r0
		add	r0,r8
		add	r2,r1				; Update X postions
		dt	r10
		bt/s	drwtex_gonxtpz
		add	r4,r3
		bra	drwsld_nxtline_tex
		add	#1,r9
drwtex_gonxtpz:
		add	#sizeof_plypz,r14		; And set new point
		mov	r14,r0
		mov	#RAM_Mars_SVdpDrwList_e,r14	; End-of-list?
		cmp/ge	r14,r0
		bf	.reset_rd
		mov	#RAM_Mars_SVdpDrwList,r0
.reset_rd:
		mov	r0,@(marsGbl_PlyPzList_R,gbr)
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0	; Decrement piece
		add	#-1,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
		cmp/pl	r0
		bf	.finish_it
		bra	MarsVideo_DrawPzPlgns
		nop
.finish_it:
		bra	drwtask_exit
		nop
		align 4
tag_JR:		dc.l _JR
tag_width:	dc.l SCREEN_WIDTH
tag_yhght:	dc.l SCREEN_HEIGHT

; ------------------------------------
; Solid Color
;
; r1  - XL
; r2  - XL DX
; r3  - XR
; r4  - XR DX
; r9  - Y current
; r10  - Number of lines
; ------------------------------------

drwtsk_solidmode:
		mov	#$FF,r0
		mov	@(plypz_mtrl,r14),r6
		mov	@(plypz_type,r14),r5
		and	r0,r5
		and	r0,r6
		add	r5,r6
		mov	#_vdpreg,r13
.wait:		mov.w	@(10,r13),r0
		tst	#2,r0
		bf	.wait
drwsld_nxtline:
		mov	r9,r0
		add	r10,r0
		cmp/pl	r0
		bf	drwsld_nextpz
		cmp/pz	r9
		bf	drwsld_updline
		mov	#SCREEN_HEIGHT,r0
		cmp/gt	r0,r9
		bt	drwsld_nextpz

		mov	r1,r11
		mov	r3,r12
		shlr16	r11
		shlr16	r12
		exts	r11,r11
		exts	r12,r12
		mov	r12,r0
		sub	r11,r0
		cmp/pz	r0
		bt	.revers
		mov	r12,r0
		mov	r11,r12
		mov	r0,r11
.revers:
		mov	#SCREEN_WIDTH-2,r0
		cmp/pl	r12
		bf	drwsld_updline
		cmp/gt	r0,r11
		bt	drwsld_updline
		cmp/gt	r0,r12
		bf	.r_fix
		mov	r0,r12
.r_fix:
		cmp/pl	r11
		bt	.l_fix
		xor	r11,r11
.l_fix:
		mov	#-2,r0
		and	r0,r11
		and	r0,r12
		mov	r12,r0
		sub	r11,r0
		cmp/pl	r0
		bf	drwsld_updline

.wait:		mov.w	@(10,r13),r0
		tst	#2,r0
		bf	.wait
		mov	r12,r0
		sub	r11,r0
		mov	r0,r12
		shlr	r0
		mov.w	r0,@(4,r13)	; length
		mov	r11,r0
		shlr	r0
		mov	r9,r5
		add	#1,r5
		shll8	r5
		add	r5,r0
		mov.w	r0,@(6,r13)	; address
		mov	r6,r0
		shll8	r0
		or	r6,r0
		mov.w	r0,@(8,r13)	; Set data
drwsld_updline:
		add	r2,r1
		add	r4,r3
		dt	r10
		bf/s	drwsld_nxtline
		add	#1,r9

; ------------------------------------

drwsld_nextpz:
		add	#sizeof_plypz,r14		; And set new point
		mov	r14,r0
		mov	#RAM_Mars_SVdpDrwList_e,r14	; End-of-list?
		cmp/ge	r14,r0
		bf	.reset_rd
		mov	#RAM_Mars_SVdpDrwList,r0
.reset_rd:
		mov	r0,@(marsGbl_PlyPzList_R,gbr)
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0	; Decrement piece
		add	#-1,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
		cmp/pl	r0
		bf	drwtask_exit
		bra	MarsVideo_DrawPzPlgns
		nop
drwtask_exit:
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------

		align 4
Cach_DDA_Top	ds.l 2*2	; First 2 points
Cach_DDA_Last	ds.l 2*2	; Triangle or Quad (+8)
Cach_DDA_Src	ds.l 4*2
Cach_DDA_Src_L	ds.l 4		; X/DX/Y/DX result for textures
Cach_DDA_Src_R	ds.l 4
Cach_Bkup_L	ds.l 16		;
Cach_Bkup_S	ds.l 0		; <-- Reads backwards
Cach_XHead_L	ds.l 1		; Left draw beam
Cach_XHead_R	ds.l 1		; Right draw beam
Cach_YHead_U	ds.l 1		; Top draw beam
Cach_YHead_D	ds.l 1		; Bottom draw beam
Cach_BgFbPos_V	ds.l 1		; Framebuffer Y DIRECT position (then multiply with internal WIDTH)
Cach_BgFbPos_H	ds.l 1		; Framebuffer TOPLEFT position

; ------------------------------------------------
.end:		phase CACHE_MSTR_PLGN+.end&$1FFF
		align 4
CACHE_MSTR_PLGN_E:
	if MOMPASS=6
		message "THIS CACHE CODE uses: \{(CACHE_MSTR_PLGN_E-CACHE_MSTR_PLGN)}"
	endif
