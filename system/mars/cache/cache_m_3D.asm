; ====================================================================
; ----------------------------------------------------------------
; CACHE code
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_MSTR_PLGN:
		phase $C0000000

; ====================================================================
; --------------------------------------------------------
; Watchdog interrupt
; --------------------------------------------------------

		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov.w	@(marsGbl_WdgHold,gbr),r0
		cmp/eq	#1,r0
		bt	.exit_wdg
		mov.w	@(marsGbl_WdgMode,gbr),r0	; Framebuffer clear request ($07)?
		cmp/eq	#7,r0
		bf	maindrw_tasks

; ------------------------------------------------
; Clear Framebuffer
; ------------------------------------------------

		mov	#_vdpreg,r1
.wait_fb:	mov.w   @($A,r1),r0			; Framebuffer free?
		tst     #2,r0
		bf      .wait_fb
		mov.w   @(6,r1),r0			; SVDP-fill address
		add     #$5B,r0				; <-- Pre-increment
		mov.w   r0,@(6,r1)
		mov.w   #328/2,r0			; SVDP-fill size (320+ pixels)
		mov.w   r0,@(4,r1)
		mov.w	#$0000,r0			; SVDP-fill pixel data
		mov.w   r0,@(8,r1)			; now SVDP-fill is working.
		mov	#Cach_ClrLines,r1		; Decrement a line to progress
		mov	@r1,r0
		dt	r0
		bf/s	.exit_wdg
		mov	r0,@r1				; Write new value before branch
		mov	#1,r0				; Finished: Set task $01
		mov.w	r0,@(marsGbl_WdgMode,gbr)
.on_clr:
		rts
		nop
		align 4
.exit_wdg:
		mov.w   #$FE80,r1
		mov.w   #$A518,r0		; OFF
		mov.w   r0,@r1
		or      #$20,r0			; ON
		mov.w   r0,@r1
		mov.w   #$5A10,r0		; Timer: $10
		rts
		mov.w   r0,@r1
		align 4
		ltorg

; ------------------------------------------------
; Main drawing routines
; ------------------------------------------------

		align 4
maindrw_tasks:
		shll2	r0
		mov	#.list,r1
		mov	@(r1,r0),r0
		jmp	@r0
		nop
		align 4
.list:
		dc.l slvplgn_00		; NULL task, exit.
		dc.l slvplgn_01		; Main drawing routine
		dc.l slvplgn_02		; Resume from solid color

; --------------------------------
; Task $02
; --------------------------------

; NOTE: Only resumes from solid_color

slvplgn_02:
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
		mov	#Cach_LnDrw_L,r0
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
		mov	@r0+,r1
		mov	#1,r0
		mov.w	r0,@(marsGbl_WdgMode,gbr)
		bra	drwsld_updline
		nop
.exit:		bra	drwtask_exit
		mov	#$10,r2
		align 4

; --------------------------------
; Task $01
; --------------------------------

slvplgn_01:
		mov	r2,@-r15
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0	; Any pieces to draw?
		cmp/pl	r0
		bt	.has_pz
		mov.w	@(marsGbl_WdgReady,gbr),r0	; Finished with the pieces?
		tst	r0,r0
		bt	.exit
		mov	#0,r0				; Watchdog out.
		mov.w	r0,@(marsGbl_WdgMode,gbr)
.exit:		bra	drwtask_exit
		mov	#$10,r2
		align 4
.has_pz:
		mov	r3,@-r15			; Save all these regs
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
drwtsk1_newpz:
		mov	@(marsGbl_PlyPzList_R,gbr),r0
		mov	r0,r14
; 		mov	@(marsGbl_PlyPzList_W,gbr),r0
; 		cmp/eq	r0,r14
; 		bt	g_return
		mov	@(plypz_ytb,r14),r9	; Start grabbing StartY/EndY positions
		exts.w	r9,r10			; r10 - Bottom
		shlr16	r9
		exts.w	r9,r9			;  r9 - Top
		cmp/eq	r9,r10			; if Top==Bottom, exit
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
		bt	.valid_y
.invld_y:
		bra	drwsld_nextpz		; if LEN < 0 then check next one instead.
		nop
		align 4
.no_pz:
		bra	drwtask_exit
		mov	#$10,r2
		align 4
.valid_y:
		mov	@(plypz_xl,r14),r1
		mov	r1,r3
		mov	@(plypz_xl_dx,r14),r2		; r2 - DX left
		shlr16	r1
		mov	@(plypz_xr_dx,r14),r4		; r4 - DX right
		shll16	r1
		mov	@(plypz_type,r14),r0		; Check material options
		shll16	r3
		shlr16	r0
		shlr8	r0
 		tst	#PLGN_TEXURE,r0			; Texture mode?
 		bf	drwtsk_texmode
		bra	drwtsk_solidmode
		nop
		align 4
		ltorg
g_return:
		bra	drwtask_return
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

		align 4
go_drwsld_updline_tex:
		bra	drwsld_updline_tex
		nop
go_drwtex_gonxtpz:
		bra	drwsld_nextpz
		nop
		align 4
drwtsk_texmode:
		mov.w	@(marsGbl_WdgDivLock,gbr),r0	; Waste interrupt if MarsVideo_MakePolygon is in the
		cmp/eq	#1,r0				; middle of HW-division
		bf	.texvalid
		bra	drwtask_return
		nop
		align 4
.texvalid:
		mov	@(plypz_src_xl,r14),r5		; Texture X left/right
		mov	r5,r6
		mov	@(plypz_src_yl,r14),r7		; Texture Y up/down
		shlr16	r5
		mov	r7,r8
		shlr16	r7

		shll16	r5
		shll16	r6
		shll16	r7
		shll16	r8
drwsld_nxtline_tex:
		cmp/pz	r9				; Y Start below 0?
		bf	go_drwsld_updline_tex
		mov	tag_yhght,r0			; Y Start after 224?
		cmp/ge	r0,r9
		bt	go_drwtex_gonxtpz

		mov	#Cach_Bkup_S,r0
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

	; NOTE: r11-r12 are free
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
		mov	tag_width,r0			; X right < 0?
		cmp/pz	r3
		bf	.tex_skip_line
		cmp/gt	r0,r1				; X left > 320?
		bt	.tex_skip_line
		mov	r3,r2
		mov 	r1,r0
		sub 	r0,r2
		sub	r5,r6
		sub	r7,r8

	; Calculate new DX values
	; make sure DIV is not in use
	; before getting here.
	; (set marsGbl_WdgDivLock to 1)
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

; 		mov	#1,r0
; 		or	r0,r3

		mov	tag_width,r0		; XR point > 320?
		cmp/gt	r0,r3
		bf	.tr_fix
		mov	r0,r3			; Force XR to 320
.tr_fix:
		cmp/pz	r1			; XL point < 0?
		bt	.tl_fix
		neg	r1,r2			; Fix texture positions
		mul	r6,r2
		sts	macl,r0
		add	r0,r5
		mul	r8,r2
		sts	macl,r0
		add	r0,r7
		xor	r1,r1			; And reset XL to 0
.tl_fix:

	; start
		mov	#-2,r0
		and	r0,r1
		and	r0,r3
		sub 	r1,r3
		shar	r3
		cmp/pl	r3
		bf	.tex_skip_line
		mov	#_overwrite+$200,r10
		mov	@(plypz_type,r14),r4	;  r4 - texture width|palinc
		mov	r4,r13
		shlr16	r4
		extu.b	r13,r13
; 		mov	#$FF,r0
		mov	#$3FFF,r2
		and	r2,r4
; 		and	r0,r13
		mov 	r9,r0			; Y position * $200
		shll8	r0
		shll	r0
		add 	r0,r10			; Add Y
		add 	r1,r10			; Add X
		mov	@(plypz_mtrl,r14),r1
		mov	#_vdpreg,r2		; Any pending SVDP fill?
.w_fb:
		mov.w	@($A,r2),r0
		tst	#2,r0
		bf	.w_fb
.tex_xloop:
		mov	r7,r2
		shlr16	r2
		mulu	r2,r4
		mov	r5,r2	   		; Build column index
		sts	macl,r0
		shlr16	r2
		add	r2,r0
		mov.b	@(r0,r1),r0		; Read left pixel
		add	r13,r0			; color-index increment
		extu.b	r0,r0
; 		and	#$FF,r0
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
		mov.b	@(r0,r1),r0		; Read right pixel
		add	r13,r0			; color-index increment
		extu.b	r0,r0
; 		and	#$FF,r0

		sts	mach,r2
		or	r2,r0
		mov.w	r0,@r10
		add	#2,r10
		add	r6,r5			; Update X
		dt	r3
		bf/s	.tex_xloop
		add	r8,r7			; Update Y
.tex_skip_line:
		mov	#Cach_Bkup_LB,r0
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
		nop
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
		bt/s	drwtex_nextpz
		add	r4,r3
		bra	drwsld_nxtline_tex
		add	#1,r9
drwtex_nextpz:
		bra	drwsld_nextpz
		nop
		align 4
tag_JR:		dc.l _JR
tag_width:	dc.l	SCREEN_WIDTH
tag_yhght:	dc.l	SCREEN_HEIGHT

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
; 		mov	#$FF,r0
		mov	@(plypz_mtrl,r14),r6
		mov	@(plypz_type,r14),r5
		extu.b	r5,r5
		extu.b	r6,r6
; 		and	r0,r5
; 		and	r0,r6
		add	r5,r6
		mov	#_vdpreg,r13
.wait:		mov.w	@(10,r13),r0
		tst	#2,r0
		bf	.wait
drwsld_nxtline:
		cmp/pz	r9			; Y pos < 0?
		bf	drwsld_updline
		mov	#SCREEN_HEIGHT,r0	; Y pos > 224?
		cmp/gt	r0,r9
		bt	drwsld_nextpz
		mov	r9,r0			; r10-r9 < 0?
		add	r10,r0
		cmp/pl	r0
		bf	drwsld_nextpz

		mov	r1,r11
		mov	r3,r12
		shlr16	r11
		shlr16	r12
		exts.w	r11,r11
		exts.w	r12,r12
		mov	#-2,r0		; Make WORD aligned now.
		and	r0,r11
		and	r0,r12
		mov	r12,r0
		sub	r11,r0
		cmp/pz	r0
		bt	.revers
		mov	r12,r0
		mov	r11,r12
		mov	r0,r11
.revers:
		mov	#SCREEN_WIDTH,r0
		cmp/pl	r12		; XR < 0?
		bf	drwsld_updline
		cmp/ge	r0,r11		; XL > 320?
		bt	drwsld_updline
		cmp/ge	r0,r12		; XR > 320?
		bf	.r_fix
		mov	r0,r12		; MAX XR
.r_fix:
		cmp/pl	r11		; XL < 0?
		bt	.l_fix
		xor	r11,r11		; MIN XL
.l_fix:
		mov.w	@(10,r13),r0	; Pending SVDP fill?
		tst	#2,r0
		bf	.l_fix
		mov	r12,r0
		sub	r11,r0
		mov	r0,r12
		shlr	r0		; Len: (XR-XL)/2
		mov.w	r0,@(4,r13)	; Set SVDP-FILL len
		mov	r11,r0
		shlr	r0
		mov	r9,r5
		add	#1,r5
		shll8	r5
		add	r5,r0		; Address: (XL/2)*((Y+1)*$200)/2
		mov.w	r0,@(6,r13)	; Set SVDP-FILL address
		mov	r6,r0
		shll8	r0
		or	r6,r0		; Data: xxxx
		mov.w	r0,@(8,r13)	; Set pixels, SVDP-Fill begins
; .wait:	mov.w	@(10,r13),r0
; 		tst	#2,r0
; 		bf	.wait

; 	If the line is too large, leave it to VDP
; 	and exit watchdog, we will come back on
; 	next trigger.
		mov	#$28,r0				; If line > $28, leave the SVDP filling
		cmp/gt	r0,r12				; and wait for the next watchdog
		bf	drwsld_updline
		mov	#2,r0				; Set next mode on Resume
		mov.w	r0,@(marsGbl_WdgMode,gbr)
		mov	#Cach_LnDrw_S,r0		; Save ALL these regs for comeback
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
		mov	r12,@-r0
		mov	r13,@-r0
		mov	r14,@-r0
		bra	drwtask_return
		mov	#$10,r2			; Exit for now
; otherwise...
drwsld_updline:
		add	r2,r1			; Next X dst
		add	r4,r3			; Next Y dst
		dt	r10
		bf/s	drwsld_nxtline
		add	#1,r9

; ------------------------------------

drwsld_nextpz:
		xor	r0,r0
		mov	r0,@(plypz_type,r14)
		nop
		mov	@(marsGbl_PlyPzList_End,gbr),r0
		add	#sizeof_plypz,r14		; Do next piece
		cmp/ge	r0,r14				; If EOL, go back to the beginning.
		bf/s	.reset_rd
		mov	r14,r0				; ** pre-jump copy r14 to r0
		mov	@(marsGbl_PlyPzList_Start,gbr),r0
.reset_rd:
		mov	r0,@(marsGbl_PlyPzList_R,gbr)
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0	; Decrement piece counter
		add	#-1,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
		bra	drwtask_return
		mov	#$10,r2				; Timer for next watchdog

; --------------------------------
; Task $00
; --------------------------------

slvplgn_00:
		mov	r2,@-r15
		mov	#0,r0
		mov.w	r0,@(marsGbl_WdgMode,gbr)
		bra	drwtask_exit
		mov	#$10,r2

drwtask_return:
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
drwtask_exit:
		mov.w   #$FE80,r1
		mov.w   #$A518,r0	; OFF
		mov.w   r0,@r1
		or      #$20,r0		; ON
		mov.w   r0,@r1
		mov.w   #$5A00,r0	; r2 - Timer
		or	r2,r0
		mov.w   r0,@r1
		mov	@r15+,r2
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 3D Rendering routines
; ----------------------------------------------------------------

; ------------------------------------------------
; MarsVideo_SlicePlgn
;
; This slices polygons into pieces.
;
; Input:
; r14 | Polygon data
; ------------------------------------------------

		align 4
MarsVideo_SlicePlgn:
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

	; TODO: make these w/h halfs customizable
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
		mov	@(4,r2),r8
		mov	@(4,r3),r9
		sub	r10,r8
		sub	r10,r9
		mov	r8,r0
		cmp/gt	r8,r9
		bt	.lefth
		mov	r9,r0
.lefth:
		mov	#Cach_Bkup_SPZ,r0
		mov	r2,@-r0
		mov	r3,@-r0
		mov	r5,@-r0
		mov	r7,@-r0
		mov	r8,@-r0
		mov	r9,@-r0
		mov	r11,@-r0
		bsr	put_piece
		nop
		mov	#Cach_Bkup_LPZ,r0
		mov	@r0+,r11
		mov	@r0+,r9
		mov	@r0+,r8
		mov	@r0+,r7
		mov	@r0+,r5
		mov	@r0+,r3
		mov	@r0+,r2
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
		rts
		nop
		align 4
		ltorg

		align 4
set_left:
		mov	r2,r8				; Get a copy of Xleft pointer
		add	#$20,r8				; To read Texture SRC points
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

		mov	#1,r0
		mov.w	r0,@(marsGbl_WdgDivLock,gbr)
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
		mov	#0,r0
		mov.w	r0,@(marsGbl_WdgDivLock,gbr)
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

		mov	#1,r0
		mov.w	r0,@(marsGbl_WdgDivLock,gbr)
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
		mov	#0,r0
		mov.w	r0,@(marsGbl_WdgDivLock,gbr)
.rgt_skip:
		rts
		nop
		align 4

; --------------------------------------------------------

	; r2
	; r3
	; r4 - Left X
	; r5
	; r6 - Right X
	; r7
	; r8
	; r9
	; r10 - Top Y, gets updated after calling put_piece

put_piece:
		mov	#1,r0
		mov.w	r0,@(marsGbl_WdgHold,gbr)	; Tell watchdog we are mid-write
		mov	@(4,r2),r8	; Left DDA's Y
		mov	@(4,r3),r9	; Right DDA's Y
		sub	r10,r8
		sub	r10,r9
		cmp/gt	r9,r8
		bt	.lefth
		mov	r8,r9
.lefth:
		mov	r4,r8
		mov	r6,r0
		shlr16	r8
		xtrct	r8,r0
		mov	r0,@(plypz_xl,r1)
		mov 	r5,@(plypz_xl_dx,r1)
		mul	r9,r5
		mov 	r7,@(plypz_xr_dx,r1)
		sts	macl,r2
		mul	r9,r7
		sts	macl,r3
		add 	r2,r4
		add	r3,r6
		mov	r10,r2
		add	r9,r10
		mov	r10,r11
		shll16	r2
		or	r2,r11
		mov	r11,@(plypz_ytb,r1)

	; r9 - Y multiply
	;
	; free:
	; r2,r3,r5,r7,r8,r11
		mov	#Cach_DDA_Src_L,r8
		mov	#Cach_DDA_Src_R,r7
		mov	@r8,r2
		mov	@r7,r3
		mov	r2,r5
		mov	r3,r0
		shlr16	r5
		xtrct	r5,r0
		mov	r0,@(plypz_src_xl,r1)
; 		mov	r2,@(plypz_src_xl,r1)
; 		mov	r3,@(plypz_src_xr,r1)

		mov	@(4,r8),r0
		mov	@(4,r7),r5
		mov	r0,@(plypz_src_xl_dx,r1)
		mov	r5,@(plypz_src_xr_dx,r1)
		mul	r9,r0
		sts	macl,r0
		mul	r9,r5
		sts	macl,r5
		add 	r0,r2
		add	r5,r3
		mov	r2,@r8
		mov	r3,@r7

		add	#8,r8	; Go to Y/DY
		add	#8,r7
		mov	@r8,r2
		mov	@r7,r3
		mov	r2,r5
		mov	r3,r0
		shlr16	r5
		xtrct	r5,r0
		mov	r0,@(plypz_src_yl,r1)
; 		mov	r2,@(plypz_src_yl,r1)
; 		mov	r3,@(plypz_src_yr,r1)

		mov	@(4,r8),r0
		mov	@(4,r7),r5
		mov	r0,@(plypz_src_yl_dx,r1)
		mov	r5,@(plypz_src_yr_dx,r1)
		mul	r9,r0
		sts	macl,r0
		mul	r9,r5
		sts	macl,r5
		add 	r0,r2
		add	r5,r3
		mov	r2,@r8
		mov	r3,@r7

		cmp/pl	r11			; TOP check, 2 steps
		bt	.top_neg
		shll16	r11
		cmp/pl	r11
		bf	.bad_piece
.top_neg:
		mov	@(polygn_mtrl,r14),r0
		mov 	r0,@(plypz_mtrl,r1)
		mov	@(polygn_type,r14),r0
		mov 	r0,@(plypz_type,r1)

	; next piece
		add	#sizeof_plypz,r1
		mov	@(marsGbl_PlyPzList_End,gbr),r0
		cmp/ge	r0,r1
		bf	.dontres
		mov	@(marsGbl_PlyPzList_Start,gbr),r0
		mov	r0,r1
.dontres:
		mov	r1,r0
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
		mov.w	@(marsGbl_PlyPzCntr,gbr),r0
		add	#1,r0
		mov.w	r0,@(marsGbl_PlyPzCntr,gbr)
.bad_piece:
		mov	#0,r0
		mov.w	r0,@(marsGbl_WdgHold,gbr)	; Unlock.
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------

		align 4
Cach_ClrLines	ds.l 1		; Linecounter for the WDG task $07
Cach_DDA_Top	ds.l 2*2	; First 2 points
Cach_DDA_Last	ds.l 2*2	; Triangle or Quad (+8)
Cach_DDA_Src	ds.l 4*2
Cach_DDA_Src_L	ds.l 4		; X/DX/Y/DX result for textures
Cach_DDA_Src_R	ds.l 4
Cach_LnDrw_L	ds.l 14		;
Cach_LnDrw_S	ds.l 0		; <-- Reads backwards
Cach_Bkup_LB	ds.l 11
Cach_Bkup_S	ds.l 0		; <-- Reads backwards
Cach_Bkup_LPZ	ds.l 7
Cach_Bkup_SPZ	ds.l 0		; <-- Reads backwards

; ------------------------------------------------
.end:		phase CACHE_MSTR_PLGN+.end&$1FFF
		align 4
CACHE_MSTR_PLGN_E:
	if MOMPASS=6
		message "THIS CACHE CODE uses: \{(CACHE_MSTR_PLGN_E-CACHE_MSTR_PLGN)}"
	endif
