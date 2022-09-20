; ====================================================================
; ----------------------------------------------------------------
; CACHE code
;
; LIMIT: $800 bytes
; ----------------------------------------------------------------

		align 4
CACHE_SLAVE:
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
; --------------------------------------------------------
; PWM Interrupt for playback
;
; **** MUST BE FAST ***
; --------------------------------------------------------

s_irq_pwm:
		mov	#_FRT,r1
		mov.b	@(7,r1),r0
		xor	#2,r0
		mov.b	r0,@(7,r1)
		mov	#_sysreg+pwmintclr,r1
		mov.w	r0,@r1
		mov.w	@r1,r0

; ------------------------------------------------

		mov	#Cach_SlvStack_S,r0
		mov	r2,@-r0
		mov	r3,@-r0
		mov	r4,@-r0
		mov	r5,@-r0
		mov	r6,@-r0
		mov	r7,@-r0
		mov	r8,@-r0
		mov	r9,@-r0
		mov	r10,@-r0
		sts	macl,@-r0

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
		mov	#$7F,r0			; Silence...
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
		mov	#MAX_PWMBACKUP-1,r1	; backup size limit
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
		extu.b	r1,r1
		extu.b	r2,r2
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
		mov	#MAX_PWMBACKUP,r0
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

		mov	#Cach_SlvStack_L,r0
		lds	@r0+,macl
		mov	@r0+,r10
		mov	@r0+,r9
		mov	@r0+,r8
		mov	@r0+,r7
		mov	@r0+,r6
		mov	@r0+,r5
		mov	@r0+,r4
		mov	@r0+,r3
		rts
		mov	@r0+,r2
		align 4
		ltorg

; ====================================================================
; ----------------------------------------------------------------
; 3D Section
; ----------------------------------------------------------------

; --------------------------------------------------------
; MarsMdl_MdlLoop
;
; Call this to start building the 3D objects
; --------------------------------------------------------

		align 4
MarsMdl_MdlLoop:
		sts	pr,@-r15
		mov 	#RAM_Mars_Polygons_0,r1
		mov	#RAM_Mars_PlgnList_0,r2
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bt	.go_mdl
		mov 	#RAM_Mars_Polygons_1,r1
		mov	#RAM_Mars_PlgnList_1,r2
.go_mdl:
		mov	r1,r0
		mov	r0,@(marsGbl_CurrFacePos,gbr)
		mov	r2,r0
		mov	r0,@(marsGbl_CurrZList,gbr)
		mov	r0,@(marsGbl_CurrZTop,gbr)
		xor	r0,r0
		mov.w	r0,@(marsGbl_CurrNumFaces,gbr)
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
		bf	.invlid
		mov	r1,r0
		bra	.skip
		mov	r0,@(marsGbl_CurrNumFaces,gbr)
.invlid:
		dt	r13
		bf/s	.loop
		add	#sizeof_mdlobj,r14
.skip:
		mov 	#RAM_Mars_PlgnNum_0,r1
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bt	.page_2
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
		mov	#Cach_CurrPlygn,r13		; r13 - temporal face output
		mov	@(mdl_data,r14),r12		; r12 - model header
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
.no_model:
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
		extu.b	r0,r0
; 		and	#$FF,r0
		mov	r0,r1
		mov	r4,r0
		mov	.tag_andmtrl,r5
		and	r5,r0
		shll2	r0
		shll	r0
		mov	@($10,r12),r6
		add	r0,r6
		mov	#$C000,r0		; grab special bits
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
		align 4
.tag_andmtrl:
		dc.l $3FFF

; --------------------------------
; Set texture material
; --------------------------------

.solid_type:
		mov	@(mdl_option,r14),r0
		extu.b	r0,r0
; 		and	#$FF,r0
		mov	r0,r1
		mov	r4,r0
		mov	#$E000,r5
		and	r5,r4
		shll16	r4
		add	r1,r4
		mov	r4,@(polygn_type,r13)		; Set type 0 (tri) or quad (1)
		extu.b	r0,r0
; 		and	#$FF,r0
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
		mov	#-1,r13		; $FFFFFFFF

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

; ****
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
		mov	@(marsGbl_CurrZTop,gbr),r0
		mov	r0,r6
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
; ****

		add	#8,r8			; Next Zlist entry
	rept sizeof_polygn/4			; Copy words manually
		mov	@r2+,r0
		mov	r0,@r1
		add	#4,r1
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
  		mov.w 	@(mdl_x_rot,r14),r0
  		bsr	mdlrd_rotate
  		shlr2	r0
   		mov	r7,r2
   		mov	r3,r5
  		mov	r8,r6
  		mov.w	@(mdl_z_rot,r14),r0
  		shlr	r0
  		bsr	mdlrd_rotate
  		shlr2	r0
   		mov	r8,r4
   		mov	r2,r5
   		mov	r7,r6
   		mov.w	@(mdl_y_rot,r14),r0
  		shlr	r0
  		bsr	mdlrd_rotate
  		shlr2	r0
   		mov	r7,r2
   		mov	r8,r3
		mov.w	@(mdl_x_pos,r14),r0
		exts.w	r0,r5
		mov.w	@(mdl_y_pos,r14),r0
		exts.w	r0,r6
		mov.w	@(mdl_z_pos,r14),r0
		exts.w	r0,r7
 		shar	r5
 		shar	r6
 		shar	r7
		add 	r5,r2
		add 	r6,r3
		add 	r7,r4

	; Include camera changes
		mov 	#RAM_Mars_ObjCamera,r11
		mov	@(cam_x_pos,r11),r5
		mov	@(cam_y_pos,r11),r6
		mov	@(cam_z_pos,r11),r7
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
MarsSnd_PwmChnls	ds.b sizeof_sndchn*MAX_PWMCHNL
Cach_CurrPlygn		ds.b sizeof_polygn		; Current reading polygon
MarsSnd_PwmControl	ds.b $38			; 8 bytes per channel.
MarsSnd_RvMode		ds.l 1				; ROM RV protection flag
Cach_BkupPnt_L		ds.l 8				; **
Cach_BkupPnt_S		ds.l 0				; <-- Reads backwards
Cach_BkupS_L		ds.l 5				; **
Cach_BkupS_S		ds.l 0				; <-- Reads backwards
Cach_SlvStack_L		ds.l 10				; **
Cach_SlvStack_S		ds.l 0				; <-- Reads backwards

; ------------------------------------------------
.end:		phase CACHE_SLAVE+.end&$1FFF

		align 4
CACHE_SLAVE_E:
	if MOMPASS=6
		message "SH2 SLAVE CACHE uses: \{(CACHE_SLAVE_E-CACHE_SLAVE)}"
	endif
