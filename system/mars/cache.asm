; ====================================================================
; ----------------------------------------------------------------
; CACHE code for Master CPU
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_MASTER:
		phase $C0000000

; ------------------------------------------------
; Watchdog tasks
; ------------------------------------------------

; Cache_OnInterrupt:
m_irq_custom:
		mov	.tag_FRT,r1
		mov.b	@(7,r1), r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov.w	@(marsGbl_WdDrwTask,gbr),r0
		and	#$FF,r0
		shll2	r0
		mov	#.list,r1
		mov	@(r1,r0),r0
		jmp	@r0
		nop
		align 4
.list:
		dc.l drwtsk_00		; (null entry)
		dc.l drwtsk_01		; Draw background
		dc.l drwtsk_02		; Main polygons jump
; 		dc.l drwtsk_03		; Resume from solid-color
.tag_FRT:	dc.l _FRT

; --------------------------------
; Task $01: Left/Right drawing
;
; (Called on Watchdog)
; --------------------------------

		align 4
drwtsk_01:
		mov	r2,@-r15
		mov	r3,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
		sts	macl,@-r15

		mov.l   #$FFFFFE80,r1
		mov.w   #$A518,r0		; OFF
		mov.w   r0,@r1
		or      #$20,r0			; ON
		mov.w   r0,@r1
		mov.w   #$5A10,r0		; Timer before next watchdog
		mov.w   r0,@r1
		mov	#Cach_LR_Lines,r1	; Decrement a line to progress
		mov	@r1,r0
		dt	r0
		bf/s	tsk00_exit
		mov	r0,@r1

; 		mov.w	@(marsGbl_Bg_DrwReqR,gbr),r0
; 		cmp/pl	r0
; 		bf	.ndrw_r
; 		dt	r0
; 		mov.w	r0,@(marsGbl_Bg_DrwReqR,gbr)
; .ndrw_r:
; 		mov.w	@(marsGbl_Bg_DrwReqL,gbr),r0
; 		cmp/pl	r0
; 		bf	tsk00_gonext
; 		dt	r0
; 		mov.w	r0,@(marsGbl_Bg_DrwReqL,gbr)
tsk00_gonext:
		mov	#2,r0			; If finished: Set task $02
		mov.w	r0,@(marsGbl_WdDrwTask,gbr)
tsk00_exit:
		lds	@r15+,macl
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

; 		mov.w	@(marsGbl_CurrGfxMode,gbr),r0
; 		and	#$7F,r0
; 		cmp/eq	#1,r0
; 		bt	drtsk_gm1
; 		cmp/eq	#2,r0
; 		bt	drtsk_gm2
; 		mov	#_vdpreg,r1
; .wait_fb:	mov.w   @($A,r1),r0		; Framebuffer free?
; 		tst     #2,r0
; 		bf      .wait_fb
; 		mov.w   @(6,r1),r0		; SVDP-fill address
; 		add     #$5F,r0			; Preincrement
; 		mov.w   r0,@(6,r1)
; 		mov.w   #320/2,r0		; SVDP-fill size (320 pixels)
; 		mov.w   r0,@(4,r1)
; 		mov.w	#$0000,r0		; SVDP-fill pixel data and start filling
; 		mov.w   r0,@(8,r1)		; After finishing, SVDP-address got updated
; 		bra	dtsk01_exit
; 		nop
; 		align 4
; 		ltorg
;
; ; Mode1 draw routine
; ; Left/Right scroll
; drtsk_gm1:
; 		bra	dtsk01_exit
; 		nop
; 		align 4
;
; ; Mode2 draw routine
; ; Full scaling
; drtsk_gm2:
; 		mov	#Cach_Ycurr,r1
; 		mov	@r1,r1
; 		shlr16	r1
; 		mov.w	@(marsGbl_BgWidth,gbr),r0
; 		muls	r1,r0
; 		sts	macl,r1
; 		mov	@(marsGbl_Bg_FbCurrR,gbr),r0
; 		mov	r0,r9
; 		mov	@(marsGbl_BgData,gbr),r0
; 		mov	r0,r8
; 		add	r1,r8
; 		mov	#Cach_Xpos,r1
; 		mov 	@r1,r7
; 		mov.w	@(marsGbl_BgWidth,gbr),r0
; 		mov	r0,r6
; 		mov	#-2,r0		; pixel size
; 		and	r0,r7
; 		and	r0,r6
; 		shll16	r7
; 		shll16	r6
; 		mov	#Cach_Xadd,r4
; 		mov	@r4,r4
; 		shll	r4
; 		mov	r4,r0
; 		xor	r5,r5
; 		mov	#20,r2
; .x_next:
; 	rept 8
; 		cmp/ge	r6,r7
; 		bf	.lowr
; 		sub	r6,r7
; .lowr:
; 		mov	r7,r1
; 		shlr16	r1
; 		mov	#-2,r0
; 		and	r0,r1
; 		add	r8,r1
;
; ; 		mov.b	@r1,r0
; ; 		and	#$FF,r0
; ; 		mov	r0,r5
; ; 		shll8	r5
; ; 		or	r0,r5
; ; 		shll8	r5
; ; 		or	r0,r5
; ; 		shll8	r5
; ; 		or	r0,r5
; ; 		mov	r5,@r9
; 		mov.w	@r1,r0
; 		mov.w	r0,@r9
; 		add	#2,r9
; 		add	r4,r7
; 	endm
; 		dt	r2
; 		bt	.x_ex
; 		bra	.x_next
; 		nop
; .x_ex:
; 		mov	#$200,r1
; 		mov	@(marsGbl_Bg_FbCurrR,gbr),r0
; 		add	r1,r0
; 		mov	r0,@(marsGbl_Bg_FbCurrR,gbr)
;
; 		mov.w	@(marsGbl_BgHeight,gbr),r0
; 		mov	r0,r3
; 		shll16	r3
; 		mov	#Cach_Yadd,r2
; 		mov	@r2,r2
; ; 		shll	r2
; 		mov	#Cach_Ycurr,r1
; 		mov	@r1,r0
; 		add	r2,r0
; 		cmp/ge	r3,r0
; 		bf	.ylarge
; 		sub	r3,r0
; .ylarge:
; 		mov	r0,@r1
; 		bra	dtsk01_exit
; 		nop
; 		align 4
;
; dtsk01_exit:

; --------------------------------
; Task $02
; --------------------------------

; TODO: a "not using polygons" flag.

; enters-and-exits until marsGbl_PzListCntr != 0
drwtsk_02:
		mov	r2,@-r15
		mov.w	@(marsGbl_WdDrwPause,gbr),r0
		cmp/eq	#1,r0
		bt	.exit
		mov.w	@(marsGbl_PzListCntr,gbr),r0	; Any pieces to draw?
		cmp/pl	r0
		bt	.has_pz
		mov	#0,r0
		mov.w	r0,@(marsGbl_WdDrwTask,gbr)
.exit:		bra	drwtask_exit
		mov	#$10,r2
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

; Piece loop
drwtsk02_newpz:
		mov	@(marsGbl_PlyPzList_R,gbr),r0	; r14 - Current pieces pointer to READ
		mov	r0,r14
		mov	@(plypz_ypos,r14),r9		; Grab StartY/EndY positions
		mov	r9,r10
		mov	#$FFFF,r0
		shlr16	r9
		exts	r9,r9				;  r9 - Top
		and	r0,r10				; r10 - Bottom
		cmp/eq	r9,r0				; if Top==Bottom, exit
		bt	.invld_y
		mov	#SCREEN_HEIGHT,r0		; if Top > 224, exit
		cmp/ge	r0,r9
		bt	.invld_y			; if Bottom > 224, add limit
		cmp/gt	r0,r10
		bf	.len_max
		mov	r0,r10
.len_max:
		sub	r9,r10				; Turn r10 into line length (Bottom - Top)
		cmp/pl	r10
		bt	drwtsk1_vld_y
.invld_y:
		bra	drwsld_nextpz			; if LEN < 0 then check next one instead.
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
 		tst	#PLGN_TEXURE,r0			; Texture-enable bit?
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
		mov.w	@(marsGbl_DivStop_M,gbr),r0	; Waste interrupt if MarsVideo_MakePolygon is in the
		cmp/eq	#1,r0				; middle of HW-division
		bf	.texvalid
		bra	drwtask_return
		nop
		align 4
.texvalid:
		mov	@(plypz_src_xl,r14),r5		; Texture X left
		mov	@(plypz_src_xr,r14),r6		; Texture X right
		mov	@(plypz_src_yl,r14),r7		; Texture Y up
		mov	@(plypz_src_yr,r14),r8		; Texture Y down

drwsld_nxtline_tex:
		cmp/pz	r9				; Y Start below 0?
		bf	go_drwsld_updline_tex
		mov	#SCREEN_HEIGHT,r0		; Y Start after 224?
		cmp/ge	r0,r9
		bt	go_drwtex_gonxtpz
		mov	r1,@-r15
		mov	r2,@-r15
		mov	r4,@-r15
		mov	r5,@-r15
		mov	r6,@-r15
		mov	r7,@-r15
		mov	r8,@-r15
		mov	r9,@-r15
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
		cmp/eq	r11,r12			; Same X position?
		bt	.tex_skip_line
		mov	#SCREEN_WIDTH,r0	; X right < 0?
		cmp/pl	r12
		bf	.tex_skip_line
		cmp/gt	r0,r11			; X left > 320?
		bt	.tex_skip_line
		mov	r12,r2
		mov 	r11,r0
		sub 	r0,r2
		sub	r5,r6
		sub	r7,r8

	; Calculate new DX values
	; make sure DIV is available
	; (marsGbl_DivStop_M == 0)
		mov	#_JR,r0		; r6 / r2
		mov	r2,@r0
		mov	r6,@(4,r0)
		nop
		mov	@(4,r0),r6		; r8 / r2
		mov	r2,@r0
		mov	r8,@(4,r0)
		nop
		mov	@(4,r0),r8

	; Limit X destination points
	; and correct the texture's X positions
		mov	#SCREEN_WIDTH,r0		; XR point > 320?
		cmp/gt	r0,r12
		bf	.tr_fix
		mov	r0,r12			; Force XR to 320
.tr_fix:
		cmp/pl	r11			; XL point < 0?
		bt	.tl_fix
		neg	r11,r2			; Fix texture positions
		dmuls	r6,r2
		sts	macl,r0
		add	r0,r5
		dmuls	r8,r2
		sts	macl,r0
		add	r0,r7
		xor	r11,r11			; And reset XL to 0
.tl_fix:
; 		mov	#-2,r0
; 		and	r0,r11
; 		and	r0,r12

	; X right - X left
		sub 	r11,r12
; 		shar	r12
; 		shar	r12
		cmp/pl	r12
		bf	.tex_skip_line
; 		mov	#$20,r0			; (Limiter test)
; 		cmp/ge	r0,r12
; 		bf	.testlwrit
; 		mov	r0,r12
; .testlwrit:

	; Mode 1
		mov.w	@(marsGbl_CurrGfxMode,gbr),r0
		and	#$7F,r0
		cmp/eq	#1,r0
		bf	.not_m1
		mov.w	@(marsGbl_Bg_YFbPos_U,gbr),r0
		mov	#MSCRL_WIDTH,r10
		mulu	r10,r0
		sts	macl,r10
		mov	@(marsGbl_Bg_FbBase,gbr),r0
		add	r10,r0
; 		mov	#-4,r10
; 		and	r10,r0
		mov	r0,r10
		mov	#MSCRL_WIDTH*MSCRL_HEIGHT,r0
		cmp/ge	r0,r10
		bf	.fbbaset
		sub	r0,r10
.fbbaset:
	if MSCRL_WIDTH=256
		shll8	r9
		shll	r9
	else
		mov	#MSCRL_WIDTH,r0
		muls	r9,r0
		sts	macl,r9
	endif
		add	r9,r10
		add 	r11,r10				; Add X
		mov	#(MSCRL_WIDTH*MSCRL_HEIGHT),r0
		cmp/ge	r0,r10
		bf	.xl_r
		sub	r0,r10
.xl_r:
		cmp/pz	r10
		bt	.xl_l
		add	r0,r10
.xl_l:
		bra	.c_m1
		nop

	; Mode 0 and 2
.not_m1:
		mov	r11,r10
		shll8	r9
		shll	r9
		add	r9,r10
.c_m1:

	; r10 - Framebuff base
		mov	#_overwrite+$200,r0
		add	r0,r10
		mov	#$1FFF,r2
		mov	#$FF,r0
		mov	@(plypz_mtrl,r14),r11		; r11 - texture data
		mov	@(plypz_type,r14),r4		;  r4 - texture palinc|width
		mov	r4,r13
		shlr16	r13
		and	r0,r13

	; r5 - X curr
	; r6 - X inc
	; r7 - Y Curr
	; r8 - Y add
.tex_xloop:
		mov	r7,r2
		shlr16	r2
		muls	r2,r4
		mov	r5,r2	   			; Build column index
		add	r6,r5				; Update X
		add	r8,r7				; Update Y
		sts	macl,r0
		shlr16	r2
		add	r2,r0
		mov.b	@(r0,r11),r0			; Read pixel
		add	r13,r0
		and	#$FF,r0
		mov.b	r0,@r10	   			; Write pixels
		dt	r12
		bf/s	.tex_xloop
		add 	#1,r10

.tex_skip_line:
		mov	@r15+,r13
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		mov	@r15+,r4
		mov	@r15+,r2
		mov	@r15+,r1
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
		bra	drwsld_nextpz			; if LEN < 0 then check next one instead.
		nop
		align 4
		ltorg

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

; BUG: Not working anymore because
; of the scrolling system.

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
; .wait:		mov.w	@(10,r13),r0
; 		tst	#2,r0
; 		bf	.wait

; 	If the line is too large, leave it to VDP
; 	and exit watchdog, we will come back on
; 	next trigger.
		mov	#$28,r0
		cmp/gt	r0,r12
		bf	drwsld_updline
		mov	#3,r0
		mov.w	r0,@(marsGbl_WdDrwTask,gbr)
		mov	#Cach_LnDrw_S,r0
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
		mov	#$10,r2			; Exit and re-enter
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
		mov.w	@(marsGbl_PzListCntr,gbr),r0	; Decrement piece
		add	#-1,r0
		mov.w	r0,@(marsGbl_PzListCntr,gbr)
		cmp/pl	r0
		bt	.activ
; 		bf	.finish_it
; 		bra	drwtsk02_newpz2
; 		nop
.finish_it:
		mov	#0,r0
		mov.w	r0,@(marsGbl_WdDrwTask,gbr)
.activ:
		bra	drwtask_return
		mov	#$10,r2			; Timer for next watchdog

; --------------------------------
; Task $00
; --------------------------------

drwtsk_00:
		mov	r2,@-r15
		mov	#0,r0
		mov.w	r0,@(marsGbl_WdDrwTask,gbr)
		bra	drwtask_exit
		mov	#$10,r2

; --------------------------------

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
		mov.l   #$FFFFFE80,r1
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

; ; --------------------------------
; ; Task $03
; ; --------------------------------
;
; drwtsk_03:
; 		mov	r2,@-r15
; 		mov.w	@(marsGbl_WdDrwPause,gbr),r0
; 		cmp/eq	#1,r0
; 		bt	.exit
; 		mov	r3,@-r15
; 		mov	r4,@-r15
; 		mov	r5,@-r15
; 		mov	r6,@-r15
; 		mov	r7,@-r15
; 		mov	r8,@-r15
; 		mov	r9,@-r15
; 		mov	r10,@-r15
; 		mov	r11,@-r15
; 		mov	r12,@-r15
; 		mov	r13,@-r15
; 		mov	r14,@-r15
; 		sts	macl,@-r15
; 		sts	mach,@-r15
; 		mov	#Cach_LnDrw_L,r0
; 		mov	@r0+,r14
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
; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_WdDrwTask,gbr)
; 		bra	drwsld_updline
; 		nop
; .exit:		bra	drwtask_exit
; 		mov	#$10,r2
; 		align 4

; ------------------------------------------------

		align 4
Cach_Xpos	ds.l 1			; Mode2 X position
Cach_Xadd	ds.l 1			; Mode2 XDX (xxxx.xxxx)
Cach_Yadd	ds.l 1			; Mode2 YDX (xxxx.xxxx)
Cach_Ycurr	ds.l 1			; Mode2 Y current pos (updates)
Cach_XHead_L	ds.l 1			; Left draw beam
Cach_XHead_R	ds.l 1			; Right draw beam
Cach_YHead_D	ds.l 1			; Bottom draw beam
Cach_YHead_U	ds.l 1			; Top draw beam
Cach_BgFbPos_U	ds.l 1			; Upper Y FB pos
Cach_BgFbPos_D	ds.l 1			; Lower Y FB pos
Cach_BgFbPos_LR	ds.l 1			; Left/Right FB pos
Cach_LR_Lines	ds.l 1			; (L/R) X Lines to process

Cach_Md2_Lines	ds.l 1
Cach_DDA_Top	ds.l 2*2		; First 2 points
Cach_DDA_Last	ds.l 2*2		; Triangle or Quad (+8)
Cach_DDA_Src	ds.l 4*2
Cach_DDA_Src_L	ds.l 4			; X/DX/Y/DX positions for textures
Cach_DDA_Src_R	ds.l 4
Cach_LnDrw_L	ds.l 14			; Own stack: Read foward (-->)
Cach_LnDrw_S	ds.l 0			; Read this backwards (<--)

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

MarsSnd_PwmCache	ds.b $80*MAX_PWMCHNL

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
; 		mov	@(mchnsnd_start,r9),r0
; 		mov	r0,@(mchnsnd_start,r9)
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
; 		mov	#_sysreg+comm15,r0	; *** TESTING
; 		mov.w	@r0,r0
; 		and	#%00010000,r0
; 		tst	r0,r0
; 		bf	*
; 		mov	#_sysreg+dreqctl,r0
; 		mov.w	@r0,r0
; 		tst	#$01,r0
; 		bf	*			; *** TESTING

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
; 		mov	#$7F,r2
; 		cmp/eq	r2,r1
; 		bt	*
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
		mov	#$7F,r4		; align wave to pwm
		mulu	r0,r4
		sts	macl,r4
		shlr8	r4
		add	r4,r1
		add	r4,r2
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

	; ***This check is for emus only***
	; It recreates what happens to the PWM
	; in real hardware when it overflows
; 		mov	#$3FF,r0
; 		cmp/gt	r0,r5
; 		bf	.lmuch
; 		mov	r0,r5
; .lmuch:	cmp/gt	r0,r6
; 		bf	.rmuch
; 		mov	r0,r6
; .rmuch:
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
