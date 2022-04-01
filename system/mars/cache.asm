; ====================================================================
; ----------------------------------------------------------------
; CACHE code for MASTER CPU
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_MASTER:
		phase $C0000000

; ====================================================================
; --------------------------------------------------------
; Watchdog interrupt for MASTER CPU
; --------------------------------------------------------

; *** THIS USES HARDWARE DIVISION ***

m_irq_wdg:
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov.w	@(marsGbl_PlgnCntr,gbr),r0
		cmp/eq	#0,r0
		bf	wdg_task_0
		mov	#1,r0
		mov.w	r0,@(marsGbl_WdgMode,gbr)
		mov	#$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		bra	wdm_exit
		nop
		align 4
wdg_task_0:
		dt	r0
		mov.w	r0,@(marsGbl_PlgnCntr,gbr)
		mov	@(marsGbl_IndxPlgn,gbr),r0
; 		mov	r0,r1
		mov	@(4,r0),r14
; 		xor	r0,r0
; 		mov	r0,@r1
; 		mov	r0,@(4,r1)

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

	; Copy polygon points Cache's DDA
		mov	#4,r8
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

	; Copy texture source points to Cache
		mov	#4,r8
.src_pnts:
		mov.w	@r1+,r4
		mov.w	@r1+,r5
		mov	r4,@r3
		mov	r5,@(4,r3)
		dt	r8
		bf/s	.src_pnts
		add	#8,r3

	; Here we search for the lowest Y point
	; and highest Y
	; r10 - Top Y
	; r11 - Bottom Y
.start_math:
		mov	#3,r9
		tst	#PLGN_TRI,r0			; PLGN_TRI set?
		bf	.ytringl
		add	#1,r9
.ytringl:
		mov	#$7FFFFFFF,r10
		mov	#$FFFFFFFF,r11
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
		mov	#RAM_Mars_VdpDrwList_e,r0	; pointer reached end of the list?
		cmp/ge	r0,r1
		bf	.dontreset
		mov	#RAM_Mars_VdpDrwList,r0		; Return WRITE pointer to the top of the list
		mov	r0,r1
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
.dontreset:
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

		mov	@(marsGbl_IndxPlgn,gbr),r0
		add	#8,r0
		mov	r0,@(marsGbl_IndxPlgn,gbr)
		mov.l   #$FFFFFE80,r1
		mov.w   #$A518,r0	; OFF
		mov.w   r0,@r1
		or      #$20,r0		; ON
		mov.w   r0,@r1
		mov.w   #$5A08,r0	; Timer for the next WD
		mov.w   r0,@r1
wdm_exit:
		rts
		nop
		align 4
		ltorg

; --------------------------------------------------------

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
		mov	#RAM_Mars_VdpDrwList_e,r8
		cmp/ge	r8,r0
		bf	.dontreset_pz
		mov	#RAM_Mars_VdpDrwList,r0
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

; ====================================================================
; --------------------------------------------------------
; VideoMars_DrwPlgnPz
;
; Draws polygons on framebuffer using the pieces list
;
; NOTE:
; Line width must be set as 512 pixels long
; --------------------------------------------------------

VideoMars_DrwPlgnPz:
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
		mov	r13,@-r15
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

	; *** WORD WRITE ***
	; r11 - X left
	; r12 - X right
	; r9 - Current Y line
		mov	#-2,r0
		and	r0,r11
		and	r0,r12
		sub 	r11,r12
		shar	r12
		cmp/pl	r12
		bf	.tex_skip_line

		mov	#_overwrite+$200,r10
		mov 	r9,r0			; Y position * $200
		shll8	r0
		shll	r0
		add 	r0,r10			; Add Y
		add 	r11,r10			; Add X
; 		mov	#_vdpreg,r10
; .wait:	mov.w	@(10,r10),r0
; 		tst	#2,r0
; 		bf	.wait
; 		mov 	r9,r0		; Y position
; 		add	#1,r0		; move it to $200
; 		shll8	r0
; 		mov	r11,r2
; 		shlr	r2
; 		add	r2,r0
; 		mov.w	r0,@(6,r10)	; address

		mov	#$FF,r0
		mov	@(plypz_type,r14),r4	;  r4 - texture width|palinc
		mov	r4,r13
		shlr16	r4
		mov	#$1FFF,r2
		mov	@(plypz_mtrl,r14),r11	; r11 - texture data
		and	r2,r4
		and	r0,r13
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
; 		mov	r0,r2
; 		mov	#0,r0
; 		mov.w	r0,@(4,r10)		; length
; 		mov	r2,r0
; 		mov.w	r0,@(8,r10)		; Set data
		mov.w	r0,@r10
		add	#2,r10
		add	r6,r5			; Update X
		bf/s	.tex_xloop
		add	r8,r7			; Update Y
	; ***END***

; 	; *** BYTE WRITE
; 	; r11 - X left
; 	; r12 - X right
; 	; r9 - Current Y line
; 		sub 	r11,r12
; 		cmp/pl	r12
; 		bf	.tex_skip_line
; 		mov	#_overwrite+$200,r10
; 		mov 	r9,r0			; Y position * $200
; 		shll8	r0
; 		shll	r0
; 		add 	r0,r10			; Add Y
; 		add 	r11,r10			; Add X
; 		mov	#$FF,r0
; 		mov	@(plypz_type,r14),r4	;  r4 - texture width|palinc
; 		mov	r4,r13
; 		shlr16	r4
; 		mov	#$1FFF,r2
; 		mov	@(plypz_mtrl,r14),r11	; r11 - texture data
; 		and	r2,r4
; 		and	r0,r13
; .tex_xloop:
; 		mov	r7,r2
; 		shlr16	r2
; 		mulu	r2,r4
; 		mov	r5,r2	   		; Build column index
; 		sts	macl,r0
; 		shlr16	r2
; 		add	r2,r0
; 		mov.b	@(r0,r11),r0		; Read texture pixel
; 		add	r13,r0			; Add index increment
; 		and	#$FF,r0
; 		add 	#1,r10
; 		add	r6,r5			; Update X
; 		dt	r12
; 		mov.b	r0,@r10	   		; Write pixel to Framebuffer
; 		bf/s	.tex_xloop
; 		add	r8,r7			; Update Y
; ; 	; ***END***

.tex_skip_line:
		mov	@r15+,r13
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
		mov	#RAM_Mars_VdpDrwList_e,r14	; End-of-list?
		cmp/ge	r14,r0
		bf	.reset_rd
		mov	#RAM_Mars_VdpDrwList,r0
.reset_rd:
		mov	r0,@(marsGbl_PlyPzList_R,gbr)
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0	; Decrement piece
		add	#-1,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
		cmp/pl	r0
		bf	.finish_it
		bra	VideoMars_DrwPlgnPz
		nop
.finish_it:
		bra	drwtask_exit
		nop
		align 4
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

	; *** OLD ***
; .wait:	mov.w	@(10,r13),r0
; 		tst	#2,r0
; 		bf	.wait

; 	If the line is too large, leave it to VDP
; 	and exit watchdog, we will come back on
; 	next trigger.
; 		mov	#$28,r0
; 		cmp/gt	r0,r12
; 		bf	drwsld_updline
; 		mov	#2,r0
; 		mov.w	r0,@(marsGbl_DrwTask,gbr)
; 		mov	#Cach_Bkup_S,r0
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
; 		mov	r14,@-r0
; 		bra	drwtask_return
; 		mov	#$10,r2			; Exit and re-enter

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
		mov	#RAM_Mars_VdpDrwList_e,r14	; End-of-list?
		cmp/ge	r14,r0
		bf	.reset_rd
		mov	#RAM_Mars_VdpDrwList,r0
.reset_rd:
		mov	r0,@(marsGbl_PlyPzList_R,gbr)
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0	; Decrement piece
		add	#-1,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
		cmp/pl	r0
		bf	drwtask_exit
		bra	VideoMars_DrwPlgnPz
		nop
drwtask_exit:
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------

		align 4
Cach_Bkup_L	ds.l 16		;
Cach_Bkup_S	ds.l 0		; <-- Reads backwards
Cach_DDA_Top	ds.l 2*2	; First 2 points
Cach_DDA_Last	ds.l 2*2	; Triangle or Quad (+8)
Cach_DDA_Src	ds.l 4*2
Cach_DDA_Src_L	ds.l 4		; X/DX/Y/DX result for textures
Cach_DDA_Src_R	ds.l 4

Cach_XHead_L	ds.l 1		; Left draw beam
Cach_XHead_R	ds.l 1		; Right draw beam
Cach_YHead_U	ds.l 1		; Top draw beam
Cach_YHead_D	ds.l 1		; Bottom draw beam
Cach_BgFbPos_V	ds.l 1		; Framebuffer Y DIRECT position (then multiply with internal WIDTH externally)
Cach_BgFbPos_H	ds.l 1		; Framebuffer TOPLEFT position

; ------------------------------------------------
.end:		phase CACHE_MASTER+.end&$1FFF
CACHE_MASTER_E:
		align 4
	if MOMPASS=6
		message "SH2 MASTER CACHE uses: \{(CACHE_MASTER_E-CACHE_MASTER)}"
	endif

; ====================================================================
; ----------------------------------------------------------------
; CACHE code for SLAVE CPU
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_SLAVE:
		phase $C0000000

; ====================================================================
; --------------------------------------------------------
; PWM Interrupt for playback
; --------------------------------------------------------

; **** MUST BE FAST ***

s_irq_pwm:
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1
		mov.w	r0,@r1

; ------------------------------------------------

		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		mov	r10,@-r15
		sts	macl,@-r15

		mov	#MarsSnd_PwmCache,r10
		mov	#MarsSnd_PwmChnls,r9	; r9 - Channel list
		mov 	#MAX_PWMCHNL,r8		; r8 - Number of channels
		mov 	#0,r7			; r7 - RIGHT BASE wave
		mov 	#0,r6			; r6 - LEFT BASE wave
.loop:
		mov	@(mchnsnd_enbl,r9),r0	; Channel enabled? (non-Zero)
		cmp/eq	#0,r0
		bf	.on
.silent:
		mov	#$7F,r0
		mov	r0,r2
		bra	.skip
		mov	r0,r1
.on:
		mov 	@(mchnsnd_read,r9),r4
		mov	r4,r3
		mov 	@(mchnsnd_end,r9),r0
		mov	#$00FFFFFF,r1
		shlr8	r3
		shlr8	r0
		and	r1,r3
		and	r1,r0
		cmp/hs	r0,r3
		bf	.read
		mov 	@(mchnsnd_flags,r9),r0
		tst	#%00000100,r0
		bf	.loop_me
		mov 	#0,r0
		mov 	r0,@(mchnsnd_enbl,r9)
		bra	.silent
		nop
.loop_me:
		mov 	@(mchnsnd_flags,r9),r0
		mov	@(mchnsnd_loop,r9),r1
		mov 	@(mchnsnd_start,r9),r4
		tst	#%00001000,r0
		bt	.mono_l
		shll	r1
.mono_l:
		add	r1,r4

; read wave
; r4 - WAVE READ pointer
.read:
		mov 	@(mchnsnd_pitch,r9),r5	; Check if sample is on ROM
		mov 	@(mchnsnd_bank,r9),r2
		mov	#CS1,r0
		cmp/eq	r0,r2
		bf	.not_rom
		mov	#MarsSnd_RvMode,r1
		mov	@r1,r0
		cmp/eq	#1,r0
		bf	.not_rom

	; r1 - left WAV
	; r3 - right WAV
	; r4 - original READ point
	; r5 - Pitch
		mov 	@(mchnsnd_flags,r9),r0
		mov	r5,r1
		tst	#%00001000,r0
		bt	.mono_c
		shll	r1
.mono_c:
		mov	@(mchnsnd_cchread,r9),r2
		shlr8	r2
		mov	#$7F,r1
		and	r1,r2
		add	r10,r2
		mov.b	@r2+,r1
		mov.b	@r2+,r3			; null in MONO samples
		bra	.from_rv
		nop

; Play as normal
; r0 - flags
; r4 - READ pointer
.not_rom:
		mov 	@(mchnsnd_flags,r9),r0
		mov 	r4,r3
		shlr8	r3
		mov	#$00FFFFFF,r1
		tst	#%00001000,r0
		bt	.mono_a
		add	#-1,r1
.mono_a:
		and	r1,r3
		or	r2,r3
		mov.b	@r3+,r1
		mov.b	@r3+,r3
.from_rv:
		mov	r1,r2
		tst	#%00001000,r0
		bt	.mono
		mov	r3,r2
		shll	r5
.mono:
		add	r5,r4
		mov	r4,@(mchnsnd_read,r9)
		mov	@(mchnsnd_cchread,r9),r3
		add	r5,r3
		mov	r3,@(mchnsnd_cchread,r9)
		mov	#$FF,r3
		and	r3,r1
		and	r3,r2
		tst	#%00000010,r0	; LEFT enabled?
		bf	.no_l
		mov	#$7F,r1		; Force LEFT off
.no_l:
		tst	#%00000001,r0	; RIGHT enabled?
		bf	.no_r
		mov	#$7F,r2		; Force RIGHT off
.no_r:

	; Clearly rushed...
		mov	@(mchnsnd_vol,r9),r0
		cmp/pl	r0
		bf	.skip
		add	#1,r0
		mulu	r0,r1
		sts	macl,r4
		shlr8	r4
		sub	r4,r1
		mulu	r0,r2
		sts	macl,r4
		shlr8	r4
		sub	r4,r2
		mov	#$7F,r4
		mulu	r0,r4
		sts	macl,r0
		shlr8	r0
		add	r0,r1
		add	r0,r2
.skip:
		add	#1,r1
		add	#1,r2
		add	r1,r6
		add	r2,r7
		mov	#$80,r0
		add	r0,r10
		dt	r8
		bf/s	.loop
		add	#sizeof_sndchn,r9
		mov	#$3FF,r0		; Overflow protection
		cmp/gt	r0,r6
		bf	.lmuch
		mov	r0,r6
.lmuch:
		cmp/gt	r0,r7
		bf	.rmuch
		mov	r0,r7
.rmuch:
		mov	#_sysreg+lchwidth,r1	; Write WAVE result
		mov	#_sysreg+rchwidth,r2
 		mov.w	r6,@r1
 		mov.w	r7,@r2

		lds	@r15+,macl
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		rts
		mov	@r15+,r2
		align 4
		ltorg

; ====================================================================
; --------------------------------------------------------
; MarsMdl_MdlLoop
;
; Call this to start building the 3D objects
; --------------------------------------------------------

MarsMdl_MdlLoop:
		sts	pr,@-r15

		mov	#RAM_Mars_Objects,r14
		mov	#MAX_MODELS,r13
.loop:
		mov	@(mdl_data,r14),r0		; Object model data == 0 or -1?
		cmp/pl	r0
		bf	.invlid
		mov	#MarsMdl_ReadModel,r0
		jsr	@r0
		mov	r13,@-r15
		mov	@r15+,r13
		mov.w	@(marsGbl_CurrNumFaces,gbr),r0	; Ran out of space to store faces?
		mov	#MAX_FACES,r1
		cmp/ge	r1,r0
		bt	.skip
.invlid:
		dt	r13
		bf/s	.loop
		add	#sizeof_mdlobj,r14
.skip:
		mov 	#RAM_Mars_PlgnNum_0,r1
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bf	.page_2
		mov 	#RAM_Mars_PlgnNum_1,r1
.page_2:
		mov.w	@(marsGbl_CurrNumFaces,gbr),r0
		mov	r0,@r1

		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Read model
; ------------------------------------------------

		align 4
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

	; Faster read
	rept 3
		mov.w	@r11+,r0		; Read UV index
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

		mov	#Cach_BkupS_S,r0
		mov 	r8,@-r0
		mov 	r9,@-r0
		mov 	r11,@-r0
		mov 	r12,@-r0
		mov 	r13,@-r0
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

		mov	#MAX_ZDIST,r0		; Draw distance
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
; 		mov	@(marsGbl_CurrZList,gbr),r0
; 		mov	r0,r6
		mov	@(marsGbl_CurrZTop,gbr),r0
		mov	r0,r6
; 		mov	#RAM_Mars_PlgnList_0,r6
; 		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
; 		tst     #1,r0
; 		bf	.page_2
; 		mov	#RAM_Mars_PlgnList_1,r6
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
		add	#8,r8			; Next Zlist entry
	rept sizeof_polygn/2			; Copy words manually
		mov.w	@r2+,r0
		mov.w	r0,@r1
		add	#2,r1
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
		ltorg

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
; 		shlr8	r5
; 		shlr8	r6
; 		shlr8	r7
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
		mov	#256<<17,r7
		neg	r4,r0		; reverse Z
		cmp/pl	r0
		bt	.inside
		mov	#1,r0
		shlr2	r7
		shlr2	r7
; 		shlr	r7
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

; ------------------------------------------------
			align 4
MarsSnd_RvMode		ds.l 1
MarsSnd_Active		ds.l 1
Cach_CurrPlygn		ds.b sizeof_polygn	; Current polygon in modelread
Cach_BkupPnt_L		ds.l 8		;
Cach_BkupPnt_S		ds.l 0		; <-- Reads backwards
Cach_BkupS_L		ds.l 5		;
Cach_BkupS_S		ds.l 0
MarsSnd_PwmChnls	ds.b sizeof_sndchn*MAX_PWMCHNL
MarsSnd_PwmControl	ds.b $38	; 7 bytes per channel.

; ------------------------------------------------
.end:		phase CACHE_SLAVE+.end&$1FFF
CACHE_SLAVE_E:
		align 4
	if MOMPASS=6
		message "SH2 SLAVE CACHE uses: \{(CACHE_SLAVE_E-CACHE_SLAVE)}"
	endif
