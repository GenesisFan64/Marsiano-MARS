; ====================================================================
; ----------------------------------------------------------------
; CACHE code for Master CPU
;
; LIMIT: $800 bytes for each CPU
; ----------------------------------------------------------------

		align 4
CACHE_MASTER:
		phase $C0000000

; ------------------------------------------------
; Watchdog interrupt
; ------------------------------------------------

; *** THIS USES DIVISION ***

m_irq_custom:
		mov	#$F0,r0
		ldc	r0,sr
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
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
		mov	r12,@-r15
		mov	r13,@-r15
		mov	r14,@-r15
		sts	macl,@-r15
		sts	mach,@-r15

		mov.w	@(marsGbl_NumOfPlygn,gbr),r0
		cmp/pl	r0
		bt	wdm_valid
		mov.l   #$FFFFFE80,r1			; Stop watchdog
		mov.w   #$A518,r0
		mov.w   r0,@r1
		bra	wdm_exit
		nop
		align 4
		ltorg
wdm_valid:
		dt	r0
		mov.w	r0,@(marsGbl_NumOfPlygn,gbr)
		mov	@(marsGbl_CurrPlgn,gbr),r0
		mov	r0,r14
		sts	pr,@-r15
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

	; Copy texture source points
	; to Cache
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
		mov	#1,r0
		mov.w	r0,@(marsGbl_DrwPause,gbr)	; Tell watchdog we are mid-write
		bsr	put_piece
		nop
		mov	#0,r0
		mov.w	r0,@(marsGbl_DrwPause,gbr)	; Unlock.

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
		lds	@r15+,pr
; 		mov	#CS3|$40,r1
; 		mov	@r1,r0
; 		add	#1,r0
; 		mov	r0,@r1
		mov	#sizeof_polygn,r0
		add	r0,r14
		mov	r14,r0
		mov	r0,@(marsGbl_CurrPlgn,gbr)

		mov.l   #$FFFFFE80,r1
		mov.w   #$A518,r0	; OFF
		mov.w   r0,@r1
		or      #$20,r0		; ON
		mov.w   r0,@r1
		mov.w   #$5A20,r0	; Timer for the next WD
		mov.w   r0,@r1
wdm_exit:
		lds	@r15+,mach
		lds	@r15+,macl
		mov	@r15+,r14
		mov	@r15+,r13
		mov	@r15+,r12
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
		rts
		nop
		align 4
		ltorg

; --------------------------------

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
		mov	#1,r0				; Tell WD we are using
		mov.w	r0,@(marsGbl_DivStop_M,gbr)	; HW Division
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
		mov	#0,r0				; Unlock HW division
		mov.w	r0,@(marsGbl_DivStop_M,gbr)
		shll8	r5
.lft_skip:
		rts
		nop
		align 4

; --------------------------------

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
		mov	#1,r0				; Tell WD we are using
		mov.w	r0,@(marsGbl_DivStop_M,gbr)	; HW Division
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
		mov	#0,r0				; Unlock HW division
		mov.w	r0,@(marsGbl_DivStop_M,gbr)
		shll8	r7
.rgt_skip:
		rts
		nop
		align 4
		ltorg

; --------------------------------
; Mark piece
; --------------------------------

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
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r5,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
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
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r5
		mov	@r15+,r3
		mov	@r15+,r2
		rts
		nop
		align 4
		ltorg

; ; ------------------------------------------------
; ; Read polygon make output pieces to
; ; be processed later.
; ;
; ; Input:
; ; r14 - Polygon data:
; ; dc.l %tp------ -------- xxxxxxxx xxxxxxxx
; ; dc.l texture_data
; ; dc.l X,Y... (SCREEN points 0000.0000)
; ; dc.w X,Y... (TEXTURE points)
; ;
; ; polygn_type:
; ; p - Polygon type: Quad (0) or Triangle (1)
; ; t - Polygon has texture data (1):
; ;     polygn_mtrlopt: Texture width
; ;     polygn_mtrl   : Texture data address
; ;     polygn_srcpnts: Texture X/Y positions for
; ;                     each edge (3 or 4)
; ; x - Indexed-color increment (full word)
; ;     / Texture WIDTH
; ;
; ; Output is stored on the
; ; RAM_Mars_VdpDrwList buffer
; ; ------------------------------------------------
;
; MarsVideo_SlicePlgn:
; 		sts	pr,@-r15
; 		mov	#Cach_DDA_Last,r13		; r13 - DDA last point
; 		mov	#Cach_DDA_Top,r12		; r12 - DDA first point
; 		mov	@(polygn_type,r14),r0		; Read type settings
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
;
; ; ----------------------------------------
; ; Polygon points
; ; ----------------------------------------
;
; 	; Copy polygon points Cache's DDA
; 		mov	#4,r8
; 		mov	#SCREEN_WIDTH/2,r6
; 		mov	#SCREEN_HEIGHT/2,r7
; .setpnts:
; 		mov	@r1+,r4			; Get X
; 		mov	@r1+,r5			; Get Y
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
; 		mov.w	r0,@(marsGbl_DrwPause,gbr)	; Tell watchdog we are mid-write
; 		bsr	put_piece
; 		nop
; 		mov	#0,r0
; 		mov.w	r0,@(marsGbl_DrwPause,gbr)	; Unlock.
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
; 		mov.w	@(marsGbl_PlyPzCntr,gbr),r0
; 		add	#1,r0
; 		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
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
.hdnx
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

; ------------------------------------------------

		align 4
Cach_Drw_All	ds.l 1		; Draw timers moved here
Cach_Drw_U	ds.l 1
Cach_Drw_D	ds.l 1
Cach_Drw_L	ds.l 1
Cach_Drw_R	ds.l 1
Cach_XHead_L	ds.l 1		; Left draw beam
Cach_XHead_R	ds.l 1		; Right draw beam
Cach_YHead_U	ds.l 1		; Top draw beam
Cach_YHead_D	ds.l 1		; Bottom draw beam
Cach_BgFbPos_V	ds.l 1		; Framebuffer Y DIRECT position (then multiply internal WIDTH externally)
Cach_BgFbPos_H	ds.l 1		; Framebuffer TOPLEFT position

Cach_LnDrw_L	ds.l 14		;
Cach_LnDrw_S	ds.l 0		; <-- Reads backwards
Cach_DDA_Top	ds.l 2*2	; First 2 points
Cach_DDA_Last	ds.l 2*2	; Triangle or Quad (+8)
Cach_DDA_Src	ds.l 4*2
Cach_DDA_Src_L	ds.l 4		; X/DX/Y/DX result for textures
Cach_DDA_Src_R	ds.l 4
Cach_ClrLines	ds.l 1		; Current lines to clear

; ------------------------------------------------
.end:		phase CACHE_MASTER+.end&$1FFF
CACHE_MASTER_E:
		align 4
	if MOMPASS=6
		message "SH2 MASTER CACHE uses: \{(CACHE_MASTER_E-CACHE_MASTER)}"
	endif

; ====================================================================
; ----------------------------------------------------------------
; CACHE code for Slave CPU
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_SLAVE:
		phase $C0000000

; ------------------------------------------------
; Small sample storage for the DMA-protection
; ------------------------------------------------

MarsSnd_PwmCache	ds.b $80*MAX_PWMCHNL
MarsSnd_PwmChnls	ds.b sizeof_sndchn*MAX_PWMCHNL
MarsSnd_PwmControl	ds.b $38	; 7 bytes per channel.

; ------------------------------------------------
; Mars PWM playback (Runs on PWM interrupt)
; r0-r10 only
; ------------------------------------------------

; **** CRITICAL ROUTINE, MUST BE FAST ***

MarsSound_ReadPwm:
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

; ------------------------------------------------

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
; 		mov	#_sysreg+monowidth,r3	; Works fine without this...
; 		mov.b	@r3,r0
; 		tst	#$80,r0
; 		bf	.retry
		lds	@r15+,macl
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r3
		mov	@r15+,r2
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
		align 4
MarsSnd_RvMode	ds.l 1
MarsSnd_Active	ds.l 1
; ------------------------------------------------
.end:		phase CACHE_SLAVE+.end&$1FFF
CACHE_SLAVE_E:
		align 4
	if MOMPASS=6
		message "SH2 SLAVE CACHE uses: \{(CACHE_SLAVE_E-CACHE_SLAVE)}"
	endif
