; ====================================================================
; ----------------------------------------------------------------
; MARS Video
; ----------------------------------------------------------------

; ----------------------------------------
; Settings
; ----------------------------------------

MAX_FACES	equ	950		; Maximum polygon faces (models,sprites) to store on buffer
MAX_SVDP_PZ	equ	950+128		; Pieces list: both read and write, increase the value if needed
MAX_MODELS	equ	24		; Note: First 9 models are reserved for layout map
MAX_ZDIST	equ	-$2400		; Max drawing distance (-Z max)
LAY_WIDTH	equ	$20*2		; Layout data width * 2

; ----------------------------------------
; Variables
; ----------------------------------------

; 3D drawing area, affects 3D positions too.
SCREEN_WIDTH	equ	320
SCREEN_HEIGHT	equ	224

; MSB
PLGN_TEXURE	equ	%10000000
PLGN_TRI	equ	%01000000
PLGN_SPRITE	equ	%00100000	; TODO: leftover.

; ----------------------------------------
; Structs
; ----------------------------------------

; model objects
		struct 0
mdl_data	ds.l 1			; Model data pointer, if zero: no model
mdl_option	ds.l 1			; Model options: pixelvalue add
mdl_x_pos	ds.l 1			; X position $000000.00
mdl_y_pos	ds.l 1			; Y position $000000.00
mdl_z_pos	ds.l 1			; Z position $000000.00
mdl_x_rot	ds.l 1			; X rotation $000000.00
mdl_y_rot	ds.l 1			; Y rotation $000000.00
mdl_z_rot	ds.l 1			; Z rotation $000000.00
mdl_animdata	ds.l 1			; Model animation data pointer, zero: no animation
mdl_animframe	ds.l 1			; Current frame in animation
mdl_animtimer	ds.l 1			; Animation timer
mdl_animspd	ds.l 1			; Animation USER speed setting
sizeof_mdlobj	ds.l 0
		finish
		
; field view camera
		struct 0
cam_x_pos	ds.l 1			; X position $000000.00
cam_y_pos	ds.l 1			; Y position $000000.00
cam_z_pos	ds.l 1			; Z position $000000.00
cam_x_rot	ds.l 1			; X rotation $000000.00
cam_y_rot	ds.l 1			; Y rotation $000000.00
cam_z_rot	ds.l 1			; Z rotation $000000.00
cam_animdata	ds.l 1			; Model animation data pointer, zero: no animation
cam_animframe	ds.l 1			; Current frame in animation
cam_animtimer	ds.l 1			; Animation timer
cam_animspd	ds.l 1			; Animation speed
sizeof_camera	ds.l 0
		finish
		
		struct 0
mdllay_data	ds.l 1			; Model layout data, zero: Don't use layout
mdllay_x	ds.l 1			; X position
mdllay_y	ds.l 1			; Y position
mdllay_z	ds.l 1			; Z position
mdllay_x_last	ds.l 1			; LAST saved X position
mdllay_y_last	ds.l 1			; LAST saved Y position
mdllay_z_last	ds.l 1			; LAST saved Z position
mdllay_xr_last	ds.l 1			; LAST saved X rotation
sizeof_layout	ds.l 0
		finish

		struct 0
plypz_ypos	ds.l 1			; Ytop | Ybottom
plypz_xl	ds.l 1
plypz_xl_dx	ds.l 1
plypz_xr	ds.l 1
plypz_xr_dx	ds.l 1
plypz_src_xl	ds.l 1
plypz_src_xl_dx	ds.l 1
plypz_src_yl	ds.l 1
plypz_src_yl_dx	ds.l 1
plypz_src_xr	ds.l 1
plypz_src_xr_dx	ds.l 1
plypz_src_yr	ds.l 1
plypz_src_yr_dx	ds.l 1
plypz_mtrl	ds.l 1
plypz_type	ds.l 1			; Type | Option
sizeof_plypz	ds.l 0
		finish

		struct 0
polygn_type	ds.l 1		; %MSTw wwww xxxx aaaa | Type bits and Material option (Width or PalIncr)
polygn_mtrl	ds.l 1		; Material Type: Color (0-255) or Texture data address
; polygn_zpos	ds.l 1
polygn_points	ds.l 4*2	; X/Y positions
polygn_srcpnts	ds.w 4*2	; X/Y texture points (16-bit), ignored on solidcolor
sizeof_polygn	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Init MARS Video
; ----------------------------------------------------------------

MarsVideo_Init:
		sts	pr,@-r15
		mov	#_sysreg,r4
		mov 	#FM,r0			; Set SVDP permission to SH2
  		mov.b	r0,@(adapter,r4)
		mov 	#_vdpreg,r4
		bsr	.this_fb		; Init line tables for both framebuffers
		nop
		bsr	.this_fb
		nop
		mov	#0,r0			; Start at blank
		mov.b	r0,@(bitmapmd,r4)
		lds	@r15+,pr
		rts
		nop
		align 4

; ------------------------------------------------
; Init current framebuffer
; ------------------------------------------------

.this_fb:
 		mov	#_framebuffer,r1
		mov	#$200/2,r0	; START line data
		mov	#240,r2		; Vertical lines to set
		mov	r0,r3		; Increment by (copy from r0)
.loop:		mov.w	r0,@r1
		add	#2,r1
		add	r3,r0
		dt	r2
		bf	.loop
.fb_wait1:	mov.w   @($A,r4),r0	; Swap for next table
		tst     #2,r0
		bf      .fb_wait1
		mov.w   @($A,r4), r0
		xor     #1,r0
		mov.w   r0,@($A,r4)
		and     #1,r0
		mov     r0,r1
.wait_result:
		mov.w   @($A,r4),r0
		and     #1,r0
		cmp/eq  r0,r1
		bf      .wait_result
		rts
		nop
		align 4
		
; ------------------------------------
; MarsVideo_ClearFrame
;
; Clear the current framebuffer
; ------------------------------------

MarsVideo_ClearFrame:
		mov	#_vdpreg,r1
.wait2		mov.w	@(10,r1),r0		; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	.wait2

		mov	#255,r2			; r2 - lenght: 256 words per pass
		mov	#$200/2,r3		; r3 - Start address / 2
		mov	#0,r4			; r4 - data (zero)
		mov	#256,r5			; Increment address by 256
		mov	#((512*240)/256)/2,r6	; 140 passes
.loop
		mov	r2,r0
		mov.w	r0,@(4,r1)		; Set length
		mov	r3,r0
		mov.w	r0,@(6,r1)		; Set address
		mov	r4,r0
		mov.w	r0,@(8,r1)		; Set data
		add	r5,r3

.wait		mov.w	@(10,r1),r0		; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	.wait
		dt	r6
		bf	.loop
		rts
		nop
		align 4

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

; ------------------------------------------------
; MarsVideo_SetWatchdog
; 
; Initialize watchdog interrupt with
; default settings
; ------------------------------------------------

MarsVideo_SetWatchdog:
		mov	#RAM_Mars_VdpDrwList,r0		; Reset the piece-drawing pointer
		mov	r0,@(marsGbl_PlyPzList_R,gbr)	; on both READ and WRITE pointers
		mov	r0,@(marsGbl_PlyPzList_W,gbr)
		mov	#0,r0				; Reset polygon pieces counter
		mov.w	r0,@(marsGbl_PzListCntr,gbr)

		mov	#Cach_ClrLines,r1		; Line counter for the framebuffer-clear routine
		mov	#224,r0
		mov	r0,@r1
		mov	#8,r0				; Set starting watchdog task to $08 (Clear framebuffer)
		mov.w	r0,@(marsGbl_DrwTask,gbr)
		mov	#TESTMARS_BG,r0			; BG data pointer
		mov	r0,@(marsGbl_Backdata,gbr)
		mov	#_framebuffer+$200,r0		; BG data pointer
		mov	r0,@(marsGbl_BackFb,gbr)

	; CRITICAL PART
		mov	#_vdpreg,r1
		mov.b	@(marsGbl_CurrFb,gbr),r0
		mov	r0,r2
		stc	sr,@-r15			; Save interrupts
		mov	#$F0,r0
		ldc	r0,sr
.wait_frmswp:	mov.b	@(framectl,r1),r0
		cmp/eq	r0,r2
		bf	.wait_frmswp
.wait_fb:	mov.w	@($A,r1),r0			; Wait until framebuffer is unlocked
		tst	#2,r0
		bf	.wait_fb
		mov.w	#$100,r0			; ClearOnly: Pre-start at $A1
		mov.w	r0,@(6,r1)			;
		ldc	@r15+,sr			; Restore interrupts

		mov	#$FFFFFE80,r1
		mov.w	#$5A7F,r0			; Watchdog timer
		mov.w	r0,@r1
		mov.w	#$A538,r0			; Enable this watchdog
		mov.w	r0,@r1
		rts
		nop
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 3D MODEL RENDERER
; ----------------------------------------------------------------

; ------------------------------------------------
; Object layout routines
; ------------------------------------------------

; ----------------------------------------
; Read layout
; ----------------------------------------

MarsLay_Read:
		sts	pr,@-r15
		mov	#RAM_Mars_ObjLayout,r14
		mov	#RAM_Mars_ObjCamera,r13
		mov	#RAM_Mars_Objects,r12
		mov	@(mdllay_data,r14),r0
		cmp/pl	r0
		bf	.no_lay
		mov	r0,r11

		mov	#0,r10				; r10 - Update counter
		mov	#-$100000,r9			;  r9 - MAX Z block size
		mov	#-$100000,r8			;  r8 - MAX Y block size	
		mov	#-$100000,r7			;  r7 - MAX X block size
		mov	#-$8000,r6			;  r6 - X Rotation update point

		mov	@(mdllay_z_last,r14),r5
		mov	@(cam_z_pos,r13),r0
		and	r9,r0
		and	r9,r5
		cmp/eq	r0,r5
		bt	.no_z_upd
; 		add	r9,r5
; 		neg	r5,r4
; 		cmp/gt	r5,r0
; 		bf	.set_z_upd
; 		cmp/ge	r4,r0
; 		bf	.no_z_upd
; .set_z_upd:
		and	r9,r0
		mov	r0,@(mdllay_z_last,r14)
		add	#1,r10
.no_z_upd:

		mov	@(mdllay_y_last,r14),r5
		mov	@(cam_y_pos,r13),r0
		and	r8,r0
		and	r8,r5
		cmp/eq	r0,r5
		bt	.no_y_upd
; 		add	r8,r5
; 		neg	r5,r4
; 		cmp/gt	r5,r0
; 		bf	.set_y_upd
; 		cmp/ge	r4,r0
; 		bf	.no_y_upd
; .set_y_upd:
		and	r8,r0
		mov	r0,@(mdllay_y_last,r14)
		add	#1,r10
.no_y_upd:

		mov	@(mdllay_x_last,r14),r5
		mov	@(cam_x_pos,r13),r0
		and	r7,r0
		and	r7,r5
		cmp/eq	r0,r5
		bt	.no_x_upd
; 		add	r7,r5
; 		neg	r5,r4
; 		cmp/gt	r5,r0
; 		bf	.set_x_upd
; 		cmp/ge	r4,r0
; 		bf	.no_x_upd
; .set_x_upd:
		and	r7,r0
		mov	r0,@(mdllay_x_last,r14)
		add	#1,r10
.no_x_upd:

		mov	@(mdllay_xr_last,r14),r5
		mov	@(cam_x_rot,r13),r0
		and	r6,r0
		and	r6,r5
		cmp/eq	r0,r5
		bt	.no_xr_upd
; 		add	r6,r5
; 		neg	r5,r4
; 		cmp/gt	r5,r0
; 		bf	.set_xr_upd
; 		cmp/ge	r4,r0
; 		bf	.no_xr_upd
; .set_xr_upd:
		and	r6,r0
		mov	r0,@(mdllay_xr_last,r14)
		add	#1,r10
.no_xr_upd:

		cmp/pl	r10
		bf	.no_lay
		bsr	MarsLay_Draw
		nop
.no_lay:
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; r1 - layout data pointer
MarsLay_Make:
		mov	#RAM_Mars_ObjLayout,r14
		mov	#RAM_Mars_ObjCamera,r13
		xor	r0,r0
		mov	r1,@(mdllay_data,r14)
		mov	r0,@(mdllay_x_last,r14)
		mov	r0,@(mdllay_y_last,r14)
		mov	r0,@(mdllay_z_last,r14)
		mov	r0,@(mdllay_x,r14)
		mov	r0,@(mdllay_y,r14)
		mov	r0,@(mdllay_z,r14)
		rts
		nop
		align 4

MarsLay_Draw:
		mov	#RAM_Mars_Objects,r10
		mov	r10,r2
		mov	#sizeof_mdlobj,r3
		mov	#0,r0
		mov	#9,r4
.clrold:
		mov	r0,@(mdl_data,r2)
		mov	r0,@(mdl_x_pos,r2)
		mov	r0,@(mdl_y_pos,r2)
		mov	r0,@(mdl_z_pos,r2)
		mov	r0,@(mdl_x_rot,r2)
		mov	r0,@(mdl_y_rot,r2)
		mov	r0,@(mdl_z_rot,r2)
		dt	r4
		bf/s	.clrold
		add	r3,r2

	; r13 - Layout Ids
	; r12 - Layout model list
		mov	#0,r4
		mov	@(mdllay_data,r14),r13
		mov	@r13+,r12
		mov	.center_val,r0			; list center point
		add	r0,r13
		
	; X/Y add
		mov	@(mdllay_x_last,r14),r1
		mov	@(mdllay_z_last,r14),r2
		mov	#LAY_WIDTH,r0
		shlr16	r1
		shlr16	r2
		exts	r1,r1
		exts	r2,r2
	rept 3
		shar	r1
		shar	r2
	endm
		shar	r2			; extra shift
		muls	r0,r2
		sts	macl,r0
		add	r1,r13			; X add
		sub	r0,r13			; Y add
		
	; Rotation
		mov	@(mdllay_xr_last,r14),r0
		shlr16	r0
		and	#$3F,r0
		shll2	r0
		mov	#.list,r1
		mov	@(r0,r1),r0
		jmp	@r0
		nop
		align 4
.center_val:	dc.l ($E*LAY_WIDTH)+($C*2)

.list:
		dc.l .front
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		dc.l .front_fr
		
		dc.l .front_fr
		dc.l .front_fr
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		dc.l .right_dw
		
		dc.l .right_dw
		dc.l .right_dw
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left
		dc.l .down_left

		dc.l .down_left
		dc.l .down_left
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front_lf
		dc.l .front
		dc.l .front
		dc.l .front

; r5 - numof pieces
; uses: r6,r7
.do_piece:
		mov	r1,@-r15
		mov	r13,@-r15
		mov	#$100000,r6
.nxt_one:
		xor	r4,r4
		mov.w	@r13+,r0
		cmp/pl 	r0
		bf	.blank_mdl
; 		mov	r0,r7
; 		shlr8	r0
; 		shlr2	r0
; 		shlr	r0
; 		and	#%11100,r0
; 		mov	#.xrotlist,r8
; 		mov	@(r8,r0),r8
; 		mov	r7,r0
		add	#-1,r0
		shll2	r0
; 		shll	r0
; 		mov	#$1FFF,r7
; 		and	r7,r0
		mov	@(r12,r0),r4
		mov	#$40000000,r0	; OR val: set special object mode
		or	r0,r4
.blank_mdl:
		mov	r1,@(mdl_x_pos,r10)
		mov	r2,@(mdl_y_pos,r10)
		mov	r3,@(mdl_z_pos,r10)
; 		mov	r8,@(mdl_x_rot,r10)	
		mov	r4,@(mdl_data,r10)
		add	#sizeof_mdlobj,r10
		dt	r5
		bf/s	.nxt_one
		add	r6,r1
		mov	@r15+,r13
		mov	@r15+,r1
		rts
		nop
		align 4
; .xrotlist:	dc.l 0
; 		dc.l $100000
; 		dc.l $200000
; 		dc.l $300000

; o X X X o
; o X X X o
; o X C X o
; o - - - o
; o o o o o
.front:
		mov	#-$100000,r1
		mov	#0,r2
		mov	#-$200000,r3
		add	#(1*2),r13
		mov	#$100000,r11

		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4

; front right view
; o o X X X
; o - X X X
; o - C X X
; o - - - o
; o o o o o
.front_fr:
		mov	#0,r1
		mov	#0,r2
		mov	#-$200000,r3
		add	#(2*2),r13
		mov	#$100000,r11
		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4


; right view/down
; o o o o o
; o - - - o
; o - C X X
; o - X X X
; o o X X X
.right_dw:
		mov	#0,r1
		mov	#0,r2
		mov	#-$100000,r3
		mov	#(2*2)+(LAY_WIDTH),r0
		add	r0,r13
		mov	#$100000,r11
		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4

; o o o o o
; o - - - o
; o X C X o
; o X X X o
; o X X X o
.down:
		mov	#0,r1
		mov	#0,r2
		mov	#-$100000,r3
		mov	#(2*2)+(LAY_WIDTH*1),r0
		add	r0,r13
		mov	#$100000,r11
		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4

; o o o o o
; o - - - o
; X X C - o
; X X X - o
; X X X o o
.down_left:
		mov	#-$100000,r1
		mov	#0,r2
		mov	#-$100000,r3
		mov	#(1*2)+(LAY_WIDTH*1),r0
		add	r0,r13
		mov	#$100000,r11
		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4


; X X X o o
; X X X - o
; X X C - o
; o - - - o
; o o o o o
.front_lf:
		mov	#-$100000,r1
		mov	#0,r2
		mov	#-$200000,r3
		add	#(1*2),r13
		mov	#$100000,r11
		sts	pr,@-r15
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		add	#LAY_WIDTH,r13
		add	r11,r3
		bsr	.do_piece
		mov	#3,r5
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; MarsMdl_Init
; 
; Reset ALL objects
; ------------------------------------------------

MarsMdl_Init:
		mov	#RAM_Mars_Objects,r1
		mov	#MAX_MODELS,r2
		mov	#0,r0
.clnup:
		mov	r0,@(mdl_data,r1)
		mov	r0,@(mdl_animdata,r1)
		mov	r0,@(mdl_x_pos,r1)
		mov	r0,@(mdl_x_rot,r1)
		mov	r0,@(mdl_y_pos,r1)
		mov	r0,@(mdl_y_rot,r1)
		mov	r0,@(mdl_y_pos,r1)
		mov	r0,@(mdl_y_rot,r1)
		dt	r2
		bf/s	.clnup
		add	#sizeof_mdlobj,r1
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Read model
; ------------------------------------------------

MarsMdl_ReadModel:
		sts	pr,@-r15
		mov	@(mdl_animdata,r14),r13
		cmp/pl	r13
		bf	.no_anim
		mov	@(mdl_animtimer,r14),r0
		add	#-1,r0
		cmp/pl 	r0
		bt	.wait_camanim
		mov	@r13+,r2
		mov	@(mdl_animframe,r14),r0
		add	#1,r0
		cmp/eq	r2,r0
		bf	.on_frames
		xor	r0,r0
.on_frames:
		mov	r0,r1
		mov	r0,@(mdl_animframe,r14)
		mov	#$18,r0
		mulu	r0,r1
		sts	macl,r0 	
		add	r0,r13
		mov	@r13+,r1
		mov	@r13+,r2
		mov	@r13+,r3
		mov	@r13+,r4
		mov	@r13+,r5
		mov	@r13+,r6
; 		neg	r4,r4
		mov	r1,@(mdl_x_pos,r14)
		mov	r2,@(mdl_y_pos,r14)
		mov	r3,@(mdl_z_pos,r14)
		mov	r4,@(mdl_x_rot,r14)
		mov	r5,@(mdl_y_rot,r14)
		mov	r6,@(mdl_z_rot,r14)
		mov	@(mdl_animspd,r14),r0		; TODO: make a timer setting
.wait_camanim:
		mov	r0,@(mdl_animtimer,r14)	
.no_anim:
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
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0	; Ran out of space to store faces?
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

	; New method
	rept 3
		mov.w	@r11+,r0			; Read UV index			
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
		mov 	r8,@-r15
		mov 	r9,@-r15
		mov 	r11,@-r15
		mov 	r12,@-r15
		mov 	r13,@-r15
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
		mov	@r15+,r13
		mov	@r15+,r12
		mov	@r15+,r11
		mov	@r15+,r9
		mov	@r15+,r8
		
	; NOTE: if you don't like how the perspective works
	; change this register depending how you want to ignore
	; faces closer to the camera:
	; 
	; r5 - Back Z point, keep affine limitations
	; r6 - Front Z point, skip face but larger faces are affected
	
		cmp/pz	r5
		bt	.go_fout
; 		cmp/pz	r6
; 		bt	.go_fout
		
		
; 		mov	#RAM_Mars_ObjCamera,r0
; 		mov	@(cam_y_pos,r0),r7
; 		shlr2	r7
; 		shlr2	r7
; 		shlr2	r7
; 		shlr	r7
; 		exts	r7,r7
; 		cmp/pl	r7
; 		bf	.revrscam
; 		neg	r7,r7
; .revrscam:
; 		mov	#MAX_ZDIST,r0
; 		cmp/ge	r0,r7
; 		bt	.camlimit
; 		mov	r0,r7
; .camlimit:
; 		cmp/pl	r6
; 		bt	.face_out
		mov	#MAX_ZDIST,r0		; Draw distance
; 		add 	r7,r0
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
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0	; Add 1 face to the list
		add	#1,r0
		mov.w	r0,@(marsGbl_MdlFacesCntr,gbr)
		mov	@(marsGbl_CurrFacePos,gbr),r0
		mov	r0,r1
		mov	r13,r2
		mov	r5,@r8				; Store current Z to Zlist
		mov	r1,@(4,r8)			; And it's address
		
; 	Sort this face, SLOW
; 	r7 - Curr Z
; 	r6 - Past Z
		mov.w	@(marsGbl_MdlFacesCntr,gbr),r0
		cmp/eq	#1,r0
		bt	.first_face
		cmp/eq	#2,r0
		bt	.first_face
		mov	r8,r7
		add	#-8,r7
; 		mov	@(marsGbl_CurrZList,gbr),r0
; 		mov	r0,r6
		mov	#RAM_Mars_Plgn_ZList_0,r6
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bt	.page_2
		mov	#RAM_Mars_Plgn_ZList_1,r6
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


		add	#8,r8				; Next Zlist entry
	rept sizeof_polygn/2				; Copy words manually
		mov.w	@r2+,r0
		mov.w	r0,@r1
		add	#2,r1
	endm
		mov	r1,r0
		mov	r0,@(marsGbl_CurrFacePos,gbr)

; 		mov	r0,r1
; 		mov	@(marsGbl_ZSortReq,gbr),r0
; 		cmp/eq	#1,r0
; 		bt	.face_out
; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_ZSortReq,gbr)
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
		sts	pr,@-r15
		mov 	r5,@-r15
		mov 	r6,@-r15
		mov 	r7,@-r15
		mov 	r8,@-r15
		mov 	r9,@-r15
		mov 	r10,@-r15
		mov 	r11,@-r15
		
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
		shlr8	r5
		shlr8	r6
		shlr8	r7
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
		mov	@(mdl_data,r14),r0		; Layout object?
		shll	r0
		cmp/pl	r0
		bt	.lay_move
		mov	#$FFFFF,r0			; Limit camera movement
		and	r0,r5
; 		and	r0,r6
		and	r0,r7
.lay_move:
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

; 		mov	#-(SCREEN_WIDTH/2)<<4,r6
; 		cmp/ge	r6,r2
; 		bf	.x_forz
; 		neg	r6,r6
; 		cmp/ge	r6,r2
; 		bf	.x_rsd
; .x_forz:
; 		mov	r6,r2
; .x_rsd:	

; 		mov	#-(SCREEN_HEIGHT/2),r6
; 		cmp/ge	r6,r3
; 		bf	.y_forz
; 		neg	r6,r6
; 		cmp/ge	r6,r3
; 		bf	.y_rsd
; .y_forz:
; 		mov	r6,r3
; .y_rsd:

	; Weak perspective projection
	; this is the best I got,
	; It breaks on large faces
		mov 	#_JR,r8
		mov	#320<<16,r7
		neg	r4,r0		; reverse Z
; 		add	#-16,r0
		cmp/pl	r0
		bt	.inside
		shlr	r7

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

		mov	@r15+,r11
		mov	@r15+,r10
		mov	@r15+,r9
		mov	@r15+,r8
		mov	@r15+,r7
		mov	@r15+,r6
		mov	@r15+,r5
		
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

		lds	@r15+,pr
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
