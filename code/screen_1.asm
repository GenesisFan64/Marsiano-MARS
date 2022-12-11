; ====================================================================
; ----------------------------------------------------------------
; 2D Part
; ----------------------------------------------------------------

		phase RAMCODE_USER

; ====================================================================
; ------------------------------------------------------
; Settings
; ------------------------------------------------------

TEST_MAINSPD	equ $04

; ====================================================================
; ------------------------------------------------------
; Structs
; ------------------------------------------------------

; 		struct 0
; strc_xpos	ds.w 1
; strc_ypos	ds.w 1
; 		finish

; ====================================================================
; ------------------------------------------------------
; This screen's RAM
; ------------------------------------------------------

		struct RAM_ModeBuff
RAM_MapX	ds.l 1
RAM_MapY	ds.l 1
RAM_ThisSpeed	ds.l 1
; RAM_EmiFrame	ds.w 1
; RAM_EmiAnim	ds.w 1
; RAM_EmiTimer	ds.w 1
RAM_KeepSong	ds.w 1
		finish

; ====================================================================
; ------------------------------------------------------
; Code start
; ------------------------------------------------------

MD_2DMODE:
		move.w	#$2700,sr
		bclr	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update
		bsr	Mode_Init
		bsr	Video_PrintInit
		bsr	Objects_Init
; 		bsr	SuperSpr_Init

	; MAP TESTING
		move.l	#Art_level0,d0			; Genesis VDP graphics
		move.w	#1,d1
		move.w	#Art_level0_e-Art_level0,d2
		bsr	Video_LoadArt
		lea	(Pal_level0),a0			; 16-color palette
		moveq	#$10,d0
		move.w	#32,d1
		bsr	Video_FadePal
		lea	(MapPal_M),a0			; index-color palette
		moveq	#0,d0
		move.w	#128,d1
		moveq	#1,d2
		bsr	Video_FadePal_Mars
		lea	(TestSupSpr_Pal),a0
		move.w	#128,d0
		move.w	#128,d1
		moveq	#1,d2
		bsr	Video_FadePal_Mars
		clr.w	(RAM_PaletteFd).w		; <-- quick patch
		and.w	#$7FFF,(RAM_MdMarsPalFd).w
		move.l	#$10000,(RAM_ThisSpeed).l
		move.w	#0,(RAM_MapX).l
		move.w	#0,(RAM_MapY).l

		bsr	MdMap_Init
		bsr	.update_pos
		bsr	Level_PickMap
		bsr	MdMap_DrawAll

	; Object
		lea	(RAM_Objects),a6
		move.l	#ObjMd_Player,obj_code(a6)
		bsr	Objects_Run

; 		lea	(RAM_Sprites),a0
; 		move.w	#$80+$30,(a0)+
; 		move.w	#$0F00,(a0)+
; 		move.w	#$2000|$50,(a0)+
; 		move.w	#$80+$50,(a0)+

	; Set Fade-in settings
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#2,(RAM_FadeMarsIncr).w
		move.w	#1,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w
		move.b	#%000,(RAM_VdpRegs+$B).l
		move.b	#0,(RAM_VdpRegs+7).l
		bset	#bitDispEnbl,(RAM_VdpRegs+1).l
		bsr	Video_Update
		bsr 	System_WaitFrame	; Send first DREQ

		moveq	#0,d0
		bsr	Sound_TrkStop
		move.w	#200+32,d1
		bsr	Sound_GlbBeats
		lea	(GemaTrkData_MOVEME),a0
; 		lea	(GemaTrkData_Nadie_MD),a0
		moveq	#0,d0
		moveq	#7,d1
		moveq	#0,d2
		moveq	#0,d3
		bsr	Sound_TrkPlay

		moveq	#2,d0			; and set this psd-graphics mode
		bsr	Video_Mars_GfxMode

; ====================================================================
; ------------------------------------------------------
; Loop
; ------------------------------------------------------

.loop:
		bsr	Objects_Run
		bsr	Map_Camera
		bsr	MdMap_Update

.ploop:		bsr	System_WaitFrame
		bsr	Video_RunFade
		bne.s	.ploop


; 		lea	str_Stats3(pc),a0
; 		move.l	#locate(0,0,10),d0
; 		bsr	Video_Print

		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyMode,d7
		beq.s	.not_mode
		bsr	.fade_out
		move.w	#1,(RAM_Glbl_Scrn).w
		rts
.not_mode:

		move.w	(Controller_1+on_hold),d7
		btst	#bitJoyUp,d7
		beq.s	.z_up2
		sub.w	#$10,mdl_z_pos(a0)
.z_up2:
		btst	#bitJoyDown,d7
		beq.s	.z_dw2
		add.w	#$10,mdl_z_pos(a0)
.z_dw2:


; 		bsr	SuperSpr_Main
; 		move.w	(Controller_1+on_press),d7
; 		btst	#bitJoyC,d7
; 		beq.s	.z_up
; 		add.l	#$10000,(RAM_ThisSpeed).l
; 		cmp.l	#TEST_MAINSPD<<16,(RAM_ThisSpeed).l
; 		ble.s	.z_up
; 		move.l	#$10000,(RAM_ThisSpeed).l
; .z_up:
;
; 		move.w	(Controller_1+on_hold),d7
; 		btst	#bitJoyB,d7
; 		bne.s	.not_hold3
;
; 		move.l	(RAM_ThisSpeed),d0
; 		move.l	(RAM_ThisSpeed),d1
; 		move.w	(Controller_1+on_hold),d7
; 		move.w	d7,d6
; 		btst	#bitJoyDown,d7
; 		beq.s	.noz_down
; ; 		move.w	#0,(RAM_EmiFrame).w
; ; 		add.w	#1,(RAM_EmiAnim).w
; 		add.l	d1,(RAM_MapY).w
; .noz_down:
; 		move.w	d7,d6
; 		btst	#bitJoyUp,d6
; 		beq.s	.noz_up
; ; 		move.w	#4,(RAM_EmiFrame).w
; ; 		add.w	#1,(RAM_EmiAnim).w
; 		sub.l	d1,(RAM_MapY).w
; .noz_up:
; 		move.w	d7,d6
; 		btst	#bitJoyRight,d6
; 		beq.s	.noz_r
; ; 		move.w	#8,(RAM_EmiFrame).w
; ; 		add.w	#1,(RAM_EmiAnim).w
; 		add.l	d0,(RAM_MapX).w
; .noz_r:
; 		move.w	d7,d6
; 		btst	#bitJoyLeft,d6
; 		beq.s	.noz_l
; ; 		move.w	#$C,(RAM_EmiFrame).w
; ; 		add.w	#1,(RAM_EmiAnim).w
; 		sub.l	d0,(RAM_MapX).w
; .noz_l:

; 		bsr.s	.update_pos
; .not_hold3:
		move.w	(Controller_1+on_press),d7
		btst	#bitJoyStart,d7
		beq	.loop
		move.w	#2,(RAM_Glbl_Scrn).w
		rts


.update_pos:
		moveq	#-1,d0
		move.w	(RAM_MapX),d1
		move.w	(RAM_MapY),d2
		bsr	MdMap_Move
		moveq	#0,d0
		asr.w	#1,d1
		asr.w	#1,d2
		move.w	d1,(RAM_HorScroll).w
		move.w	d2,(RAM_VerScroll).w
		bsr	MdMap_Move
		moveq	#1,d0
		asr.w	#1,d1
		asr.w	#1,d2
		move.w	d1,(RAM_HorScroll+2).w
		move.w	d2,(RAM_VerScroll+2).w
		bsr	MdMap_Move
		neg.l	(RAM_HorScroll).w
		rts

; ====================================================================
; ----------------------------------------------
; common subs
; ----------------------------------------------

.fade_in:
		move.w	#1,(RAM_FadeMdReq).w
		move.w	#1,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#1,(RAM_FadeMarsIncr).w
		move.w	#4,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
		bra.s	.loop2

.fade_out:
		move.w	#2,(RAM_FadeMdReq).w
		move.w	#2,(RAM_FadeMarsReq).w
		move.w	#1,(RAM_FadeMdIncr).w
		move.w	#1,(RAM_FadeMarsIncr).w
		move.w	#4,(RAM_FadeMdDelay).w
		move.w	#0,(RAM_FadeMarsDelay).w
.loop2:
		bsr	System_WaitFrame
		bsr	Video_RunFade
		bne.s	.loop2
		rts

; ====================================================================
; ------------------------------------------------------
; Subroutines
; ------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Pick map
; ------------------------------------------------------

Level_PickMap:
		move.l	#MapHead_M,a0
		move.l	#MapBlk_M|TH,a1
		move.l	#MapFg_M|TH,a2
		move.l	#0,a3
		move.l	#MapCol_M,a4
		moveq	#-1,d0
		moveq	#0,d1
		moveq	#0,d2
		bsr	MdMap_Set

		move.l	#MapHead_0,a0
		move.l	#MapBlk_0,a1
		move.l	#MapFgL_0,a2
		move.l	#MapFgH_0,a3
		move.l	#MapFgC_0,a4
		moveq	#0,d0
		move.w	#$C000,d1
		move.w	#$2000,d2
		bsr	MdMap_Set

		move.l	#MapHead_0,a0
		move.l	#MapBlk_0,a1
		move.l	#MapBgL_0,a2
		move.l	#MapBgH_0,a3
		move.l	#0,a4
		moveq	#1,d0
		move.w	#$E000,d1
		move.w	#$2000,d2
		bsr	MdMap_Set

		rts

Map_Camera:
		lea	(RAM_Objects),a6
		lea	(RAM_BgBufferM),a5
		moveq	#0,d3
		move.w	md_bg_wf(a5),d2
		move.w	#320/2,d1
		move.w	obj_x(a6),d0
		sub.w	d1,d0
		bmi.s	.low_x
		move.w	d0,d3
.low_x:
		move.w	d3,md_bg_x(a5)

		moveq	#0,d3
		move.w	md_bg_hf(a5),d2
		move.w	#224/2,d1
		move.w	obj_y(a6),d0
		sub.w	d1,d0
		bmi.s	.low_y
		move.w	d0,d3
.low_y:
		move.w	d3,md_bg_y(a5)

		rts

; ====================================================================
; ------------------------------------------------------
; VBlank
; ------------------------------------------------------

; ------------------------------------------------------
; HBlank
; ------------------------------------------------------

; ====================================================================
; ------------------------------------------------------
; Objects
; ------------------------------------------------------

; ====================================================================
; -----------------------------------------
; Object
;
; Player
; -----------------------------------------

; -----------------------------------------
; RAM
; -----------------------------------------

; 		reserve obj_ram
; plyr_ctrlwho	rs.l 1
; 		endres

; -----------------------------------------
; Code
; -----------------------------------------

ObjMd_Player:
		moveq	#0,d0
		move.b	obj_index(a6),d0
		add.w	d0,d0
		move.w	.list(pc,d0.w),d1
		jsr	.list(pc,d1.w)

; 		move.l	#ani_plyr,d1
; 		bsr	Object_Animate

		bra	Object_Display

; -----------------------------------------
; Objects
; -----------------------------------------

.list:
		dc.w .init-.list
		dc.w .main-.list
; ---------------------------------
.mars_spr:
		dc.l SuperSpr_Test|TH	; Spritesheet location
		dc.w 512		; Spritesheet WIDTH
		dc.w $80		; Palette index
		dc.b 64,72		; Frame width and height

; ---------------------------------
; INIT
; ---------------------------------

.init:
		move.l	#.mars_spr,obj_map(a6)
		lea	(RAM_BgBufferM),a5
		add.b	#1,obj_index(a6)
		move.l	#$05040404,obj_size(a6)	; UDLR
		clr.w	d0
		clr.w	d1

; ---------------------------------
; MAIN
; ---------------------------------

.main:
		lea	(RAM_BgBufferM),a5
		lea	(Controller_1),a4

; ----------------------
		move.w	on_hold(a4),d0
		move.w	obj_x_spd(a6),d1
		move.w	#1,d2
		move.w	#$30,d3
		tst.w	d1
		bmi.s	.leftx
		sub.w	d3,d1
		bpl.s	.keepx
.stopx:
		clr.w	d1
		clr.w	d2
		bra.s	.keepx
.leftx:
		add.w	d3,d1
		bpl.s	.stopx
.keepx:

; ----------------------
; Move Left/Right
; ----------------------

		btst	#bitobj_air,obj_status(a6)
		bne.s	.dontduck
		btst	#bitJoyDown,d0
		beq.s	.dontduck
		move.w	#2,d2
		bra.s	.contlr
.dontduck:
		btst	#bitJoyRight,d0
		beq.s	.nrm
		bclr	#bitobj_flipH,obj_status(a6)
		move.w	#$160,d1
		move.w	#1,d2
.nrm
		btst	#bitJoyLeft,d0
		beq.s	.contlr
		bset	#bitobj_flipH,obj_status(a6)
		move.w	#-$160,d1
		move.w	#1,d2
.contlr:
		move.w	d1,obj_x_spd(a6)

; ----------------------
; JUMP
; ----------------------

		move.w	on_press(a4),d0
		move.w	on_hold(a4),d3
; 		btst	#bitobj_air,obj_status(a6)
; 		bne.s	.nc
		btst	#bitJoyC,d0
		beq.s	.nc
		bset	#bitobj_air,obj_status(a6)
		move.w	#-$3B0,obj_y_spd(a6)
		move.w	obj_x_spd(a6),d3
		asr.w	#2,d3
		tst.w	d3
		bpl.s	.swpx
		neg.w	d3
.swpx:
		sub.w	d3,obj_y_spd(a6)
		move.b	#3,obj_anim_id(a6)
.nc

; ----------------------
; Set Animation
; ----------------------

		btst	#bitobj_air,obj_status(a6)
		bne.s	.noovr
		move.b	d2,obj_anim_id(a6)
		bra.s	.contanim
.noovr:
		move.b	#3,d2
		tst.w	obj_y_spd(a6)
		bmi.s	.jumpup
		move.w	#6,d2
.jumpup:

; 		move.b	obj_anim_id(a6),d2
		move.w	on_hold(a4),d3
		btst	#bitJoyDown,d3
		beq.s	.goinup
		clr.w	obj_anim_pos(a6)
		move.w	#5,d2
		bra.s	.goindwn
.goinup:
		tst.w	obj_y_spd(a6)
		bpl.s	.goindwn
		btst	#bitJoyUp,d3
		beq.s	.goindwn
		move.w	#4,d2
.goindwn:
		move.b	d2,obj_anim_id(a6)

.contanim:

; ----------------------
; Result
; ----------------------

	; X Physics
		moveq	#0,d4
		move.w	obj_x_spd(a6),d3
		move.w	d3,d4
		ext.l	d4
		asl.l	#8,d4
		add.l	d4,obj_x(a6)
; 		bsr	object_LayCol_LR
		beq.s	.touchx
		clr.w	d3
.touchx:
		move.w	d3,obj_x_spd(a6)

	; Y Fall
		moveq	#0,d4
		move.w	obj_y_spd(a6),d3
		move.w	d3,d4
		ext.l	d4
		asl.l	#8,d4
		add.l	d4,obj_y(a6)

		bsr	object_ColM_Floor
		beq.s	.falling
		bra	object_FloorRead
.falling:
		move.w	obj_y_spd(a6),d3
		add.w	#$40,d3		; Fall speed
		cmp.w	#$800,d3
		blt.s	.touchy
		move.w	#$800,d3
		bra.s	.touchy
.ceily:
		move.w	#$100,d3
.touchy:
		move.w	d3,obj_y_spd(a6)
		rts

; -----------------------------------------
; DEBUG CONTROL
; -----------------------------------------

.tempctrl:
		lea	(RAM_BgBufferM),a5
		move.w	(Controller_1+on_press).l,d1
		btst	#bitJoyZ,d1
		beq.s	.nrz
		bchg	#bitobj_flipH,obj_status(a6)
.nrz
		btst	#bitJoyY,d1
		beq.s	.nly
		bchg	#bitobj_flipV,obj_status(a6)
.nly

		move.b	(Controller_1+on_hold).l,d1
		btst	#bitJoyUp,d1
		beq.s	.nu
		sub.w	#1,obj_y(a6)
; 		bsr	object_laycol_ud
.nu
		move.b	(Controller_1+on_hold).l,d1
		btst	#bitJoyDown,d1
		beq.s	.nd
		add.w	#1,obj_y(a6)
; 		bsr	object_laycol_ud
.nd

		btst	#bitJoyRight,d1
		beq.s	.nr
		add.w	#1,obj_x(a6)
		bclr	#bitobj_flipH,obj_status(a6)
; 		bsr	object_laycol_lr
.nr
		btst	#bitJoyLeft,d1
		beq.s	.nl
		sub.w	#1,obj_x(a6)
		bset	#bitobj_flipH,obj_status(a6)
; 		bsr	object_laycol_lr
.nl
		rts

; ---------------------------------------

ani_plyr:	dc.w .idle-ani_plyr	; $00
		dc.w .walk-ani_plyr
		dc.w .duck-ani_plyr
		dc.w .jump-ani_plyr
		dc.w .upstb-ani_plyr	; $04
		dc.w .dwnstb-ani_plyr
		dc.w .fall-ani_plyr
		dc.w .fall-ani_plyr

.idle:		dc.b 7
		dc.b 0

		dc.b -1
		align 2

.walk:		dc.b 4
		dc.b 1,2,3
		dc.b -1
		align 2

.duck:		dc.b 4
		dc.b 6
		dc.b -1
		align 2

.jump:		dc.b 16
		dc.b 11
		dc.b -1
		align 2

.upstb:		dc.b 4
		dc.b 8
		dc.b -1
		align 2
.dwnstb:
		dc.b 4
		dc.b 9
		dc.b -1
		align 2
.fall:
		dc.b 4
		dc.b 1
		dc.b -1
		align 2

; ====================================================================
; ------------------------------------------------------
; DATA
;
; Small stuff goes here
; ------------------------------------------------------

; str_Stats3:
; 		dc.b "\\w \\w \\w \\w",$A
; 		dc.b "\\w \\w \\w \\w",$A,$A
; 		dc.b "\\l",0
; 		dc.l sysmars_reg+comm0
; 		dc.l sysmars_reg+comm2
; 		dc.l sysmars_reg+comm4
; 		dc.l sysmars_reg+comm6
; 		dc.l sysmars_reg+comm8
; 		dc.l sysmars_reg+comm10
; 		dc.l sysmars_reg+comm12
; 		dc.l sysmars_reg+comm14
; 		dc.l RAM_Framecount
; 		align 2

; Pal_Emily:
; 		dc.w 0
; 		binclude "data/md/sprites/emi_pal.bin",2
; 		align 2
; Map_Nicole:
; 		include "data/md/sprites/emi_map.asm"
; 		align 2
; Dplc_Nicole:
; 		include "data/md/sprites/emi_plc.asm"
; 		align 2

; ====================================================================

.here:
	if MOMPASS=6
		message "THIS RAM-CODE ends at: \{.here}"
	endif
		dephase
