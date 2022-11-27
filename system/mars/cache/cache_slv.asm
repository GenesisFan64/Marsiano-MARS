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
		mov	#0,r11
		mov 	#RAM_Mars_Polygons_0,r13
		mov	#RAM_Mars_PlgnList_0,r12
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bt	.go_mdl
		mov 	#RAM_Mars_Polygons_1,r13
		mov	#RAM_Mars_PlgnList_1,r12
.go_mdl:
		mov	#RAM_Mars_Objects,r14
		mov	#MAX_MODELS,r10
.loop:
		mov	@(mdl_data,r14),r0		; Object model data == 0 or -1?
		cmp/pl	r0
		bf	.invlid
		mov	#MAX_FACES,r0
		cmp/gt	r0,r11
		bt	.invlid
		mov	#MarsMdl_ReadModel,r0
		jsr	@r0
		mov	r10,@-r15
		mov	@r15+,r10
.invlid:
		dt	r10
		bf/s	.loop
		add	#sizeof_mdlobj,r14
.skip:
		mov	#RAM_Mars_Polygons_0,r14
		mov	#RAM_Mars_PlgnList_0,r13
		mov 	#RAM_Mars_PlgnNum_0,r12
		mov.w   @(marsGbl_PolyBuffNum,gbr),r0
		tst     #1,r0
		bt	.page_2
		mov	#RAM_Mars_Polygons_1,r14
		mov	#RAM_Mars_PlgnList_1,r13
		mov 	#RAM_Mars_PlgnNum_1,r12
.page_2:
		mov	r11,@r12	; Save faces counter

	; FACE SORTING is done on the
	; Master CPU now

		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ------------------------------------------------
; Read model
;
; r14 - Current model data
; r13 - Current polygon
; r12 - Z storage
; r11 - Used faces counter
; ------------------------------------------------

; Mdl_Object:
; 		dc.w num_faces,num_vertex_old
; 		dc.l .vert,.face,.vrtx,.mtrl
; .vert:	binclude "data/mars/objects/mdl/test/vert.bin"
; .face:	binclude "data/mars/objects/mdl/test/face.bin"
; .vrtx:	binclude "data/mars/objects/mdl/test/vrtx.bin"
; .mtrl:	include "data/mars/objects/mdl/test/mtrl.asm"
;
		align 4
MarsMdl_ReadModel:
		sts	pr,@-r15
		mov	@(mdl_data,r14),r10	; r10 - Model header
		nop
		mov.w	@r10,r9			;  r9 - Number of polygons of this model
		extu.w	r9,r9
		mov 	@(8,r10),r8		;  r8 - face data
		mov	@(4,r10),r7		;  r7 - Vertex data
		nop
.next_face:
		mov	#MAX_FACES,r0
		cmp/ge	r0,r11
		bf	.valid
		bra	.exit
		mov	r0,r11
.valid:
		mov.w	@r8+,r0
		mov	r0,r5			; r5 - Face type
		mov	#4,r6			; r6 - number of vertex (quad or tri)
		shlr8	r0			;
		tst	#PLGN_TRI,r0
		bt	.quad			; bit 0 = quad
		dt	r6
.quad:
		mov	r13,r4
		cmp/pl	r5			; Solid or texture? ($8xxx)
		bf	.has_uv

; --------------------------------
; Face is solid color
		mov	r5,r0
		and	#$FF,r0
		mov	#%01100000,r3
		shll	r3
		shll8	r3			; r1 - AND $C0 value
		and	r3,r5			; r0 - Grab settings, move to long MSB
		shll16	r5
		mov	r0,@(polygn_mtrl,r4)
		mov	r5,@(polygn_type,r4)
		bra	.mk_face
		nop
		align 4

; --------------------------------
; Face has UV settings

.has_uv:
		mov	@($C,r10),r1		; r1 - Grab UV points
		mov	r6,r0
		mov	r13,r2			; r2 - Output to polygon
		add	#polygn_srcpnts,r2
		cmp/eq	#3,r0			; Polygon is tri?
		bt	.uv_tri
		mov.w	@r8+,r0			; Do quad point
		extu.w	r0,r0
		shll2	r0
		mov	@(r1,r0),r0
		mov	r0,@r2
		add	#4,r2
.uv_tri:
	rept 3					; Grab UV points 3 times
		mov.w	@r8+,r0
		extu.w	r0,r0
		shll2	r0
		mov	@(r1,r0),r0
		mov	r0,@r2
		add	#4,r2
	endm
		mov	@($10,r10),r1		; r1 - Read material list
		mov	r5,r0			; r0 - Material slot
		and	#$FF,r0
		shll2	r0			; *8
		shll	r0
		add	r0,r1			; Increment r1 into mtrl slot
		mov	#%01100000,r3
		shll	r3
		shll8	r3			; r3 - $C0
		and	r3,r5			; Filter settings bits
		mov.w	@(4,r1),r0		; r0 - Texture
		or	r0,r5
		mov	@r1,r3			; r3 - Texture ROM pointer
		shll16	r5
		mov	@(mdl_option,r14),r0
		extu.b	r0,r0
		mov	r3,@(polygn_mtrl,r4)
		or	r0,r5
		mov	r5,@(polygn_type,r4)
		nop
.mk_face:
		xor	r0,r0			; Clear Zslot for this face.
		mov	r0,@r12
		mov	r0,@(4,r12)
		mov	r4,r1			; r1 - OUTPUT face (X/Y) points
		add 	#polygn_points,r1
		mov	r6,r0
		cmp/eq	#3,r0			; Polygon is tri?
		bt	.fc_tri
		mov.w 	@r8+,r0			; Do quad point
		extu.w	r0,r0
; 		mov	#$C,r4
; 		mulu	r4,r0
; 		sts	macl,r0
		mov	r7,r4
		add 	r0,r4
		mov	@r4,r2
		nop
		mov	@(4,r4),r3
		mov	@(8,r4),r4
		bsr	mdlrd_setpoint
		nop
		mov	r2,@r1
		mov	r3,@(4,r1)
		add	#8,r1
		mov	@r12,r0
		cmp/ge	r0,r4
		bt	.fc_tri	; ** bt .higher
		mov	r4,@r12
.fc_tri:
	rept 3
		mov.w 	@r8+,r0			; Grab face index 3 times
		extu.w	r0,r0
; 		mov	#$C,r4			; *** TODO: muliply on script later
; 		mulu	r4,r0
; 		sts	macl,r0
		mov	r7,r4			; r2 - vertex data + index
		add 	r0,r4
		mov	@r4,r2
		mov	@(4,r4),r3
		mov	@(8,r4),r4
		bsr	mdlrd_setpoint
		nop
		mov	r2,@r1			; Save X/Y into polygon
		mov	r3,@(4,r1)
		add	#8,r1
		mov	@r12,r0
		cmp/ge	r0,r4
		dc.w $8900	; ** bt .higher
		mov	r4,@r12
;.higher:
	endm

	; *** Z-offscreen check***
		mov	#MAX_ZDIST>>8,r1
		shll8	r1
		cmp/pz	r0
		bt	.bad_face
		cmp/ge	r1,r0
		bf	.bad_face
		mov	r13,@(4,r12)

; 	; *** X/Y-offscreen check***
		lds	r6,mach
		mov	r13,r1
		add	#polygn_points,r1
		mov	@r1,r2
		mov	r2,r3
		mov	#-(320/2),r4
		neg	r4,r5
.nxt_x:
		mov	@r1,r0
		cmp/ge	r4,r0
		bf	.x_l
		mov	r0,r2
.x_l:
		cmp/ge	r5,r0
		bt	.x_r
		mov	r0,r3
.x_r:
		dt	r6
		bf/s	.nxt_x
		add	#8,r1
		sts	mach,r6
		cmp/ge	r4,r2
		bf	.bad_face
		cmp/ge	r5,r3
		bt	.bad_face


		mov	r13,r1
		add	#polygn_points+4,r1
		mov	@r1,r2
		mov	r2,r3
		mov	#-(224/2),r4
		neg	r4,r5
.nxt_y:
		mov	@r1,r0
		cmp/ge	r4,r0
		bf	.y_l
		mov	r0,r2
.y_l:
		cmp/ge	r5,r0
		bt	.y_r
		mov	r0,r3
.y_r:
		dt	r6
		bf/s	.nxt_y
		add	#8,r1
		cmp/ge	r4,r2
		bf	.bad_face
		cmp/ge	r5,r3
		bt	.bad_face

	; *** Validate face
		add	#sizeof_polygn,r13	; Next X/Y polygon
		add	#8,r12			; Next Z storage
		add	#1,r11			; Mark as a valid face
		nop
.bad_face:
		dt	r9
		bt	.exit
		bra	.next_face
		nop
.exit:
; 		mov.w	@r10,r9			;  r9 - Number of polygons of this model
; 		extu.w	r9,r9
;
; 		dt	r9
; 		cmp/pl	r9
; 		bf	.exitn
; .roll:
; 		xor	r8,r8
; 		mov	r12,r7
; 		mov	r9,r10
; .next:
; 		mov	r7,r0
; 		mov	@r0+,r1		; Z top
; 		mov	@r0+,r2
; 		mov	@r0+,r3		; Z bottom
; 		mov	@r0+,r4
; 		cmp/gt	r3,r1
; 		bf	.higher
; 		mov	r2,@-r0
; 		mov	r1,@-r0
; 		mov	r4,@-r0
; 		mov	r3,@-r0
; 		add	#1,r8
; .higher:
; 		dt	r10
; 		bf/s	.next
; 		add	#8,r7
; 		tst	r8,r8
; 		bf	.roll
; .exitn:
		lds	@r15+,pr
		rts
		nop
		align 4
		ltorg

; ----------------------------------------
; Modify position to current point
; ----------------------------------------

; r2 - X
; r3 - Y
; r4 - Z
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
;  		shar	r5
;  		shar	r6
;  		shar	r7
		add 	r5,r2
		add 	r6,r3
		add 	r7,r4

	; Include camera changes
; 		mov 	#RAM_Mars_DreqRead+Dreq_ObjCam,r11
		mov	#RAM_Mars_ObjCamera,r11
		mov	@(cam_x_pos,r11),r5
		mov	@(cam_y_pos,r11),r6
		mov	@(cam_z_pos,r11),r7
; 		shlr	r5
; 		shlr	r6
; 		shlr	r7
		exts	r5,r5
		exts	r6,r6
		exts	r7,r7
		sub 	r5,r2
		sub 	r6,r3
		add 	r7,r4

		mov	r2,r5
		mov	r4,r6
  		mov 	@(cam_x_rot,r11),r0
  		bsr	mdlrd_rotate
		shlr2	r0
   		mov	r7,r2
   		mov	r8,r4
   		mov	r3,r5
  		mov	r8,r6
  		mov 	@(cam_y_rot,r11),r0
  		bsr	mdlrd_rotate
		shlr2	r0
   		mov	r8,r4
   		mov	r2,r5
   		mov	r7,r6
   		mov 	@(cam_z_rot,r11),r0
  		bsr	mdlrd_rotate
		shlr2	r0
   		mov	r7,r2
   		mov	r8,r3

	; Weak perspective projection
	; this is the best I got,
	; It breaks on large faces
		mov	#320<<16,r7
		neg	r4,r8		; reverse Z
		cmp/pl	r8
		bt	.inside
		shlr2	r7
		bra	.zmulti
		shlr2	r7
.inside:
; 		mov	#1,r0
; 		mov.w	r0,@(marsGbl_WdgDivLock,gbr)
		mov 	#_JR,r9
		mov 	r8,@r9
		mov 	r7,@(4,r9)
		nop
		mov 	@(4,r9),r7
; 		xor	r0,r0
; 		mov.w	r0,@(marsGbl_WdgDivLock,gbr)
.zmulti:
		dmuls	r7,r2
		sts	mach,r0
		sts	macl,r2
		xtrct	r0,r2
		dmuls	r7,r3
		sts	mach,r0
		sts	macl,r3
		xtrct	r0,r3

		mov	#Cach_BkupPnt_L,r0
		mov	@r0+,r11
		mov	@r0+,r10
		mov	@r0+,r9
		mov	@r0+,r8
		mov	@r0+,r7
		mov	@r0+,r6
		mov	@r0+,r5
		lds	@r0+,pr

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
		rts
		nop
		align 4

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
Cach_BkupPnt_L		ds.l 8				; **
Cach_BkupPnt_S		ds.l 0				; <-- Reads backwards
Cach_BkupS_L		ds.l 5				; **
Cach_BkupS_S		ds.l 0				; <-- Reads backwards
Cach_SlvStack_L		ds.l 10				; **
Cach_SlvStack_S		ds.l 0				; <-- Reads backwards
MarsSnd_RvMode		ds.l 1				; ROM RV protection flag
MarsSnd_PwmControl	ds.b 8*7			; 8 bytes per channel.
MarsSnd_PwmChnls	ds.b sizeof_sndchn*MAX_PWMCHNL

; ------------------------------------------------
.end:		phase CACHE_SLAVE+.end&$1FFF

		align 4
CACHE_SLAVE_E:
	if MOMPASS=6
		message "SH2 SLAVE CACHE uses: \{(CACHE_SLAVE_E-CACHE_SLAVE)}"
	endif
