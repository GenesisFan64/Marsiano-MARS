; ====================================================================
; ----------------------------------------------------------------
; Genesis Video
; ----------------------------------------------------------------

RAM_BgBufferM	equ	RAM_MdDreq+Dreq_BgExBuff	; Relocate MARS layer control

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_MDOBJ	equ 16		; Max objects for Genesis
varNullVram	equ $7FF	; Default Blank cell for some video routines
varPrintVram	equ $580	; Location of the PRINT text graphics
varPrintPal	equ 3		; Palette to use for the printable text

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; VDP Register $80
HVStop		equ $02
HintEnbl	equ $10
bitHVStop	equ 1
bitHintEnbl	equ 4

; VDP Register $81
DispEnbl 	equ $40
VintEnbl 	equ $20
DmaEnbl		equ $10
bitDispEnbl	equ 6
bitVintEnbl	equ 5
bitDmaEnbl	equ 4
bitV30		equ 3

; vdp_ctrl READ bits (full WORD)
bitFifoE	equ 9		; DMA FIFO empty
bitFifoF	equ 8		; DMA FIFO full
bitVInt		equ 7		; Vertical interrupt
bitSprOvr	equ 6		; Sprite overflow
bitSprCol	equ 5		; Sprite collision
bitOdd		equ 4		; EVEN or ODD frame displayed on interlace mode
bitVBlk		equ 3		; Inside VBlank
bitHBlk		equ 2		; Inside HBlank
bitDma		equ 1		; Only works for FILL and COPY
bitPal		equ 0

; md_bg_flags
bitDrwR		equ 0
bitDrwL		equ 1
bitDrwD		equ 2
bitDrwU		equ 3
bitBgOn		equ 7
bitMarsBg	equ 6

; ====================================================================
; ----------------------------------------------------------------
; Structs
; ----------------------------------------------------------------

; IN SH2 ORDER
; still works fine on this side.
; md_bg_flags: %EM..UDLR
; UDLR - off-screen update bits
;    M - Map belongs to Genesis or 32X
;    E - Enable this map

		struct 0
md_bg_bw	ds.b 1		; Block Width
md_bg_bh	ds.b 1		; Block Height
md_bg_blkw	ds.b 1		; Bitshift block size (LSL)
md_bg_flags	ds.b 1		; Drawing flags: %EM00UDLR
md_bg_xset	ds.b 1		; X-counter
md_bg_yset	ds.b 1		; Y-counter
md_bg_movex	ds.b 1		; *** ALIGNMENT, FREE TO USE
md_bg_movey	ds.b 1		; ***
md_bg_w		ds.w 1		; Width in blocks
md_bg_h		ds.w 1		; Height in blocks
md_bg_wf	ds.w 1		; FULL Width in pixels
md_bg_hf	ds.w 1		; FULL Height in pixels
md_bg_xinc_l	ds.w 1		; Layout draw-beams L/R/U/D
md_bg_xinc_r	ds.w 1
md_bg_yinc_u	ds.w 1
md_bg_yinc_d	ds.w 1
md_bg_x_old	ds.w 1		; OLD X position
md_bg_y_old	ds.w 1		; OLD Y position
md_bg_vpos	ds.w 1		; VRAM output for map
md_bg_vram	ds.w 1		; VRAM start for cells
md_bg_low	ds.l 1		; MAIN layout data
md_bg_hi	ds.l 1		; HI layout data
md_bg_blk	ds.l 1		; Block data
md_bg_col	ds.l 1		; Collision data (if needed)
md_bg_x		ds.l 1		; X pos 0000.0000
md_bg_y		ds.l 1		; Y pos 0000.0000
sizeof_mdbg	ds.l 0
		finish

; --------------------------------
; object struct
; --------------------------------

		struct 0
obj_code	ds.l 1		; Object code
obj_size	ds.l 1		; Object size (see below)
obj_x		ds.l 1		; Object X Position
obj_y		ds.l 1		; Object Y Position
obj_map		ds.l 1		; Object image settings
obj_vram	ds.w 1		; Object VRAM position (MD-side only)
obj_x_spd	ds.w 1		; Object X Speed
obj_y_spd	ds.w 1		; Object Y Speed
obj_anim_indx	ds.w 1		; Object animation increment (obj_anim + obj_anim_indx)
obj_anim_id	ds.w 1		; Object animation to read (current|saved)
obj_frame	ds.w 1		; Object display frame (MD: $FFFF, MARS: $YY,$XX)
obj_anim_spd	ds.b 1		; Object animation delay
obj_index	ds.b 1		; Object code index
obj_subid	ds.b 1		; Object SubID
obj_set		ds.b 1		; Object settings
obj_status	ds.b 1		; Object custom status
obj_spwnid	ds.b 1		; Object respawn index (this - 1)
obj_ram		ds.b $40	; Object RAM
sizeof_mdobj	ds.l 0
		finish
; 		message "\{sizeof_mdobj}"

; --------------------------------
; obj_settings
; --------------------------------

bitobj_Mars	equ	7	; This object is for 32X side.
bitobj_flipV	equ	1	; set to flip Sprite Vertically
bitobj_flipH	equ	0	; set to flip Sprite Horizontally

; --------------------------------
; obj_set
; --------------------------------

bitobj_air	equ	0	; set if floating/jumping

; --------------------------------
; obj_size
; --------------------------------

at_u		equ	3
at_d		equ	2
at_l		equ	1
at_r		equ	0

; ====================================================================
; ----------------------------------------------------------------
; Video RAM
; ----------------------------------------------------------------

			struct RAM_MdVideo
RAM_Objects		ds.b MAX_MDOBJ*sizeof_mdobj
RAM_BgBuffer		ds.b sizeof_mdbg*4	; Map backgrounds, back to front.
RAM_FrameCount		ds.l 1			; Frames counter
RAM_HorScroll		ds.l 240		; DMA Horizontal scroll data
RAM_VerScroll		ds.l 320/16		; DMA Vertical scroll data
RAM_ObjDispList		ds.w MAX_MDOBJ		; Objects half-RAM pointers for display (Obj|Extra)
RAM_SprDrwPz		ds.w 8*70		; External sprite pieces
RAM_Sprites		ds.w 8*70		; DMA Sprites
RAM_Palette		ds.w 64			; DMA palette
RAM_PaletteFd		ds.w 64			; Target MD palette for FadeIn/Out
RAM_MdMarsPalFd		ds.w 256		; Target 32X palette for FadeIn/Out (NOTE: it's slow)
RAM_VdpDmaList		ds.w 7*MAX_MDDMATSK	; DMA BLAST list for VBlank
RAM_VidPrntList		ds.w 3*64		; Video_Print list: Address, Type
RAM_SprDrwCntr		ds.w 1
RAM_SprShowIndx		ds.w 1
RAM_VdpDmaIndx		ds.w 1			; Current index in DMA BLAST list
RAM_VdpDmaMod		ds.w 1			; Mid-write flag (just to be safe)
RAM_VidPrntVram		ds.w 1			; Default VRAM location for ASCII text used by Video_Print
RAM_FadeMdReq		ds.w 1			; FadeIn/Out request for Genesis palette (01-FadeIn 02-FadeOut)
RAM_FadeMdIncr		ds.w 1			; Fading increment count
RAM_FadeMdDelay		ds.w 1			; Fading delay
RAM_FadeMdTmr		ds.w 1			; Fading delay timer
RAM_FadeMarsReq		ds.w 1			; Same thing but for 32X's 256-color (01-FadeIn 02-FadeOut)
RAM_FadeMarsIncr	ds.w 1			; (Hint: Set to 4 to syncronize with Genesis' FadeIn/Out)
RAM_FadeMarsDelay	ds.w 1
RAM_FadeMarsTmr		ds.w 1
RAM_VdpRegs		ds.b 24			; VDP Register cache
sizeof_mdvid		ds.l 0
			finish

; ====================================================================
; --------------------------------------------------------
; Init Genesis video
; --------------------------------------------------------

Video_Init:
		lea	(RAM_MdVideo),a6	; Clear RAM
		moveq	#0,d6
		move.w	#(sizeof_mdvid-RAM_MdVideo)-1,d7
.clrram:
		move.b	d6,(a6)+
		dbf	d7,.clrram
		lea	list_vdpregs(pc),a6
		lea	(RAM_VdpRegs).w,a5
		lea	(vdp_ctrl),a4
		move.w	#$8000,d6
		move.w	#19-1,d7
.loop:
		move.b	(a6)+,d6
		move.b	d6,(a5)+
		move.w	d6,(a4)
		add.w	#$100,d6
		dbf	d7,.loop
.exit:

; --------------------------------------------------------
; Video_Update
;
; Writes register data stored in RAM to VDP
; from Registers $80 to $90, WINDOW registers
; $91 and $92 can be written manually.
;
; Breaks:
; d6-d7,a5-a6
; --------------------------------------------------------

Video_Update:
		lea	(RAM_VdpRegs).w,a6
		lea	(vdp_ctrl),a5
		move.w	#$8000,d6
		move.w	#17-1,d7
.loop:
		move.b	(a6)+,d6
		move.w	d6,(a5)
		add.w	#$100,d6
		dbf	d7,.loop
.exit:
		rts

; --------------------------------------------------------

list_vdpregs:
		dc.b $04			; No HBlank interrupt, HV Counter on
		dc.b $04			; Display ON, No VBlank interrupt
		dc.b (($C000)>>10)		; Layer A at VRAM $C000 (%00xxx000)
		dc.b (($D000)>>10)		; Window  at VRAM $D000 (%00xxxxy0)
		dc.b (($E000)>>13)		; Layer B at VRAM $E000 (%00000xxx)
		dc.b (($F800)>>9)		; Sprites at VRAM $F800 (%0xxxxxxy)
		dc.b $00			; Unused
		dc.b $00			; Background color: 0
		dc.b $00			; Unused
		dc.b $00			; Unused
		dc.b $00			; HInt value
		dc.b (%000|%00)			; No ExtInt, Scroll: VSCR:full HSCR:full
		dc.b $81			; H40, No shadow mode, Normal resolution
		dc.b (($FC00)>>10)		; HScroll at VRAM $FC00 (%00xxxxxx)
		dc.b $00			; Unused
		dc.b $02			; VDP Auto increment: $02
		dc.b (%00<<4)|%01		; Layer size: V32 H64
		dc.b $00
		dc.b $00
		align 2

ASCII_PAL:	dc.w $0000,$0EEE,$0CCC,$0AAA,$0888,$0444,$000E,$0008
		dc.w $00EE,$0088,$00E0,$0080,$0E00,$0800,$0000,$0000
ASCII_PAL_e:
		align 2

; --------------------------------------------------------
; Video_Clear
;
; Clear all video data from VRAM
; --------------------------------------------------------

Video_Clear:
; 		move.w	#0,d0			; Clears until $57F
; 		move.w	#0,d1
; 		move.w	#$57F*$20,d2
; 		bsr	Video_Fill

Video_ClearScreen:
		moveq	#0,d0
		move.w	#$FFF,d2		; FG/BG size
		move.b	(RAM_VdpRegs+2).l,d1	; FG
		andi.w	#%111000,d1
		lsl.w	#8,d1
		lsl.w	#2,d1
		bsr	Video_Fill
		move.b	(RAM_VdpRegs+4).l,d1	; BG
		andi.w	#%000111,d1
		lsl.w	#8,d1
		lsl.w	#5,d1
		bsr	Video_Fill
		move.w	#$FFF,d2		; WD Size
		move.b	(RAM_VdpRegs+3).l,d1	; Window
		andi.w	#%111110,d1
		lsl.w	#8,d1
		lsl.w	#2,d1
		bsr	Video_Fill
	; RAM...
		lea	(RAM_HorScroll),a0
		move.w	#240-1,d7
		moveq	#0,d0
.xnext:
		move.l	d0,(a0)+
		dbf	d7,.xnext
		lea	(RAM_VerScroll),a0
		move.w	#(320/16)-1,d7
		moveq	#0,d0
.ynext:
		move.l	d0,(a0)+
		dbf	d7,.ynext
		lea	(RAM_Sprites),a0
		move.w	#((70*8)/4)-1,d7
		moveq	#0,d0
.snext:
		move.l	d0,(a0)+
		dbf	d7,.snext

		lea	(RAM_Palette),a0
		lea	(RAM_PaletteFd),a1
		move.w	#(64/2)-1,d7
		moveq	#0,d0
.pnext:
		move.l	d0,(a0)+
		move.l	d0,(a1)+
		dbf	d7,.pnext

		lea	(RAM_MdDreq+Dreq_Palette),a0
		lea	(RAM_MdMarsPalFd),a1
		move.w	#(256/2)-1,d7
		moveq	#0,d0
.pmnext:
		move.l	d0,(a0)+
		move.l	d0,(a1)+
		dbf	d7,.pmnext
		rts

; ====================================================================
; ----------------------------------------------------------------
; Generic screen-drawing routines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Video_LoadMap
;
; Loads map data, in Horizontal order
; Can autodetect layer width, height and
; double interlace mode
;
; Input:
; a0 - Map data
;
; d0 | LONG - locate(lyr,x,y) / 00|Layer|X|Y
; d1 | LONG - mapsize(x,y) / Width|Height (in cells)
; d2 | WORD - VRAM
;
; Breaks:
; d4-d7,a6
; --------------------------------------------------------

Video_LoadMap:
		lea	(vdp_data),a6
		bsr	vid_PickLayer
		move.w	d1,d5		; Start here
.yloop:
		swap	d5
		move.l	d4,4(a6)
		move.l	d1,d7
		swap	d7
.xloop:
		move.w	(a0)+,d5
		cmp.w	#-1,d5		; -1 ?
		bne.s	.nonull
		move.w	#varNullVram,d5	; Replace with custom blank tile
		bra.s	.cont
.nonull:
		add.w	d2,d5
.cont:

	; Check for double interlace
		swap	d7
		move.b	(RAM_VdpRegs+$C).l,d7
		and.w	#%110,d7
		cmp.w	#%110,d7
		bne.s	.nodble
		move.w	d5,d7
		lsr.w	#1,d7
		and.w	#$7FF,d7
		and.w	#$F800,d5
		or.w	d7,d5
.nodble:
		swap	d7
		move.w	d5,(a6)
		dbf	d7,.xloop
		add.l	d6,d4
		swap	d5
		dbf	d5,.yloop
		rts

; --------------------------------------------------------
; Video_LoadMap_Vert
;
; Load map data, Vertical order
;
; a0 - Map data
; d0 | LONG - 00|Lyr|X|Y,  locate(lyr,x,y)
; d1 | LONG - Width|Height (cells),  mapsize(x,y)
; d2 | WORD - VRAM

; Breaks:
; a4-a5,d4-d7
; --------------------------------------------------------

Video_LoadMap_Vert:
		lea	(vdp_data),a4
		bsr	vid_PickLayer
		move.l	d1,d5		; Start here
		swap	d5
.xloop:
		swap	d5
		move.l	d4,-(sp)
		move.w	d1,d7
		btst	#2,(RAM_VdpRegs+$C).l
		beq.s	.yloop
		lsr.w	#1,d7
.yloop:
		move.l	d4,4(a4)
		move.w	(a0),d5
		cmp.w	#-1,d5
		bne.s	.nonull
		move.w	#varNullVram,d5
		bra.s	.cont
.nonull:
		add.w	d2,d5
.cont:
		swap	d7
		adda	#2,a0
		btst	#2,(RAM_VdpRegs+$C).l
		beq.s	.nodble
		adda	#2,a0
		move.w	d5,d7
		lsr.w	#1,d7
		and.w	#$7FF,d7
		and.w	#$F800,d5
		or.w	d7,d5
.nodble:
		swap	d7
		move.w	d5,(a4)
		add.l	d6,d4
		dbf	d7,.yloop
.outdbl:
		move.l	(sp)+,d4
		add.l	#$20000,d4
		swap	d5
		dbf	d5,.xloop
		rts

; ; --------------------------------------------------------
; ; Video_AutoMap_Vert
; ;
; ; Make automatic map, Vertical order
; ;
; ; MCD: Use this to make a virtual screen
; ; for Stamps
; ;
; ; d0 | LONG - 00|Lyr|X|Y,  locate(lyr,x,y)
; ; d1 | LONG - Width|Height (cells),  mapsize(x,y)
; ; d2 | WORD - VRAM
;
; ; Breaks:
; ; a4-a5,d4-d7
; ; --------------------------------------------------------
;
; ; TODO: double interlace
; Video_AutoMap_Vert:
; 		lea	(vdp_data),a4
; 		bsr	vid_PickLayer
; 		move.w	d2,d7		; Start here
; 		move.l	d1,d5
; 		swap	d5
; .xloop:
; 		swap	d5
; 		move.l	d4,-(sp)
; 		move.w	d1,d5
; 		btst	#2,(RAM_VdpRegs+$C).l
; 		beq.s	.yloop
; 		lsr.w	#1,d5
; .yloop:
; 		move.l	d4,4(a4)
; 		move.w	d7,(a4)
; 		add.w	#1,d7
; 		add.l	d6,d4
; 		dbf	d5,.yloop
;
; 		move.l	(sp)+,d4
; 		add.l	#$20000,d4
; 		swap	d5
; 		dbf	d5,.xloop
; 		rts

; ====================================================================
; ----------------------------------------------------------------
; Custom "PRINT" system, for debugging or quick texts.
; ----------------------------------------------------------------

; --------------------------------------------------------
; Video_PrintInit
;
; Initializes the default Graphics and Palette
; for the font.
;
; *** ON VBLANK OR DISPLAY OFF ONLY ***
; *** MAKE SURE SH2 IS NOT READING ROM DATA ***
; --------------------------------------------------------

Video_PrintInit:
		move.l	#ASCII_FONT,d0
		move.w	#varPrintVram*$20,d1
		move.w	#ASCII_FONT_e-ASCII_FONT,d2
		move.w	#varPrintVram|(varPrintPal<<13),d3
		move.w	d3,(RAM_VidPrntVram).w
		bsr	Video_LoadArt
Video_PrintPal:
		lea	ASCII_PAL(pc),a0
		moveq	#(varPrintPal<<4),d0
		move.w	#$F,d1
		bsr	Video_LoadPal	; Write to both palette buffers
		bra	Video_FadePal

; --------------------------------------------------------
; Video_Print
;
; Prints string to layer
; requires ASCII font
;
; a0 | DATA - String data w/special characters +
;             list of RAM locations to read
; d0 | LONG - Print location on-screen:
;             00|Lyr|X|Y or locate(layer,x,y)
;
; Special characters:
; "//b" - Shows BYTE value
; "//w" - Shows WORD value
; "//l" - Shows LONG value
;   $0A - Next line
;   $00 - End of line
;
; After $00, put your RAM addresses in LONGS
; don't forget to put align 2 at the end.
;
; CALL Video_PrintInit FIRST before using this.
;
; Breaks:
; d4-d7,a4-a6
; --------------------------------------------------------

Video_Print:
; 		movem.l	d3-d7,-(sp)
; 		movem.l	a4-a6,-(sp)

		lea	(vdp_data),a6
		bsr	vid_PickLayer
		lea	(RAM_VidPrntList),a5
.newjump:
		move.l	d4,4(a6)
		move.l	d4,d5
.loop:
		move.b	(a0)+,d7
		beq	.exit
		cmpi.b	#$A,d7			; $A - next line?
		beq.s	.next
		cmpi.b	#$5C,d7			; $27 ("\") special?
		beq.s	.special
		andi.w	#$FF,d7
.puttext:
		add.w	(RAM_VidPrntVram).w,d7	; VRAM add
		move.w	d7,(a6)
		add.l	#$20000,d5
		bra.s	.loop
; Next line
.next:
		add.l	d6,d4
		bra.s	.newjump

; Specials
.special:
		move.b	(a0)+,d7
		cmpi.b	#"b",d7
		beq.s	.isbyte
		cmpi.b	#"w",d7
		beq.s	.isword
		cmpi.b	#"l",d7
		beq.s	.islong
		move.w	#"\\",d7		; normal " \ "
		bra.s	.puttext

	; TEMPORAL VALUES
.isbyte:
		move.l	d5,(a5)+
		move.w	#1,(a5)+
		add.l	#$40000,d5
		move.l	d5,4(a6)
		bra	.loop
.isword:
		move.l	d5,(a5)+
		move.w	#2,(a5)+
		add.l	#$80000,d5
		move.l	d5,4(a6)
		bra	.loop
.islong:
		move.l	d5,(a5)+
		move.w	#3,(a5)+
		add.l	#$100000,d5
		move.l	d5,4(a6)
		bra	.loop
.exit:

	; ----------------------------------------
	; Print values
	;
	; vvvv vvvv tttt
	; v - vdp pos
	; t - value type
	; ----------------------------------------

	; reading byte by byte because longs doesn't get
	; aligned after $00...

		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		lea	(RAM_VidPrntList),a5
.nextv:
		tst.l	(a5)
		beq	.nothing

	; grab value
		moveq	#0,d4
		move.b	(a0)+,d4
		rol.l	#8,d4
		move.b	(a0)+,d4
		rol.l	#8,d4
		move.b	(a0)+,d4
		rol.l	#8,d4
		move.b	(a0)+,d4
		movea.l	d4,a4
		moveq	#0,d4

	; get value
		move.w	4(a5),d6
		cmp.w	#1,d6		; byte?
		bne.s	.vbyte
		move.b	(a4),d4
		move.l	(a5),4(a6)
		rol.b	#4,d4
		bsr.s	.donibl
		rol.b	#4,d4
		bsr.s	.donibl
.vbyte:
		cmp.w	#2,d6		; word?
		bne.s	.vword
		move.b	(a4),d4
		rol.w	#8,d4
		move.b	1(a4),d4
		move.l	(a5),4(a6)
		rol.w	#4,d4
		bsr.s	.donibl
		rol.w	#4,d4
		bsr.s	.donibl
		rol.w	#4,d4
		bsr.s	.donibl
		rol.w	#4,d4
		bsr.s	.donibl
.vword:

	; TODO: might break on negative values
		cmp.w	#3,d6		; long?
		bne.s	.vlong
		move.b	(a4),d4
		rol.l	#8,d4
		move.b	1(a4),d4
		rol.l	#8,d4
		move.b	2(a4),d4
		rol.l	#8,d4
		move.b	3(a4),d4
		move.l	(a5),4(a6)
		move.w	#7,d6
.lngloop:	rol.l	#4,d4
		bsr.s	.donibl
		dbf	d6,.lngloop
.vlong:
		clr.l	(a5)+
		clr.w	(a5)+
		bra	.nextv

; make nibble byte
.donibl:
		move.w	d4,d5
		andi.w	#%1111,d5
		cmp.b	#$A,d5
		blt.s	.lowr
		add.b	#7,d5
.lowr:
		add.w	#"0",d5
		add.w	(RAM_VidPrntVram),d5
		move.w	d5,(a6)
		rts
; exit
.nothing:
; 		movem.l	(sp)+,a4-a6
; 		movem.l	(sp)+,d3-d7
		rts

; --------------------------------------------------------
; Shared: pick layer / x pos / y pos and set size
; --------------------------------------------------------

vid_PickLayer:
		move.l	d0,d6			; Pick layer
		swap	d6
		btst	#0,d6
		beq.s	.plawnd
		move.b	(RAM_VdpRegs+4).l,d4	; BG
		move.w	d4,d5
		lsr.w	#1,d5
		andi.w	#%11,d5
		swap	d4
		move.w	d5,d4
		swap	d4
		andi.w	#1,d4
		lsl.w	#8,d4
		lsl.w	#5,d4
		bra.s	.golyr
.plawnd:
		move.b	(RAM_VdpRegs+2).l,d4	; FG
		btst	#1,d6
		beq.s	.nowd
		move.b	(RAM_VdpRegs+3).l,d4	; WINDOW
.nowd:
		move.w	d4,d5
		lsr.w	#4,d5
		andi.w	#%11,d5
		swap	d4
		move.w	d5,d4
		swap	d4
		andi.w	#%00001110,d4
		lsl.w	#8,d4
		lsl.w	#2,d4
.golyr:
		ori.w	#$4000,d4
		move.w	d0,d5			; Y start pos
		andi.w	#$FF,d5			; Y only
		lsl.w	#6,d5
		move.b	(RAM_VdpRegs+$10).w,d6
		andi.w	#%11,d6
		beq.s	.thissz
		add.w	d5,d5			; H64
		andi.w	#%10,d6
		beq.s	.thissz
		add.w	d5,d5			; H128
.thissz:
		add.w	d5,d4
		move.w	d0,d5
		andi.w	#$FF00,d5		; X only
		lsr.w	#7,d5
		add.w	d5,d4			; X add
		swap	d4
		moveq	#0,d6
		move.w	#$40,d6			; Set jump size
		move.b	(RAM_VdpRegs+$10).w,d5
		andi.w	#%11,d5
		beq.s	.thisszj
		add.w	d6,d6			; H64
		andi.w	#%10,d5
		beq.s	.thisszj
		add.w	d6,d6			; H128
.thisszj:
		swap	d6
		rts

; ====================================================================
; ----------------------------------------------------------------
; Palette fade system, Genesis side
; ----------------------------------------------------------------

; --------------------------------------------------------
; Video_RunFade
;
; Processes palette fading and reports if requests
; finished on exit.
;
; Returns:
; bne - Still active
; beq - Finished
;
; *** CALL System_WaitFrame FIRST ***
; --------------------------------------------------------

Video_RunFade:
		bsr	Video_DoPalFade
		bsr	Video_MarsPalFade
		move.w	(RAM_FadeMarsReq),d7
		move.w	(RAM_FadeMdReq),d6
		or.w	d6,d7
		rts

; --------------------------------------------------------
; Video_LoadPal
;
; Input:
; a0 - Palette data
; d0 - Start position
; d1 - Number of colors
;
; Breaks:
; d5-d7,a6
; --------------------------------------------------------

Video_FadePal:
		lea	(RAM_PaletteFd),a6
		clr.w	(RAM_FadeMdTmr).w
		bra.s	vidMd_Pal
Video_LoadPal:
		lea	(RAM_Palette),a6
vidMd_Pal:
		move.l	a0,a5
		moveq	#0,d7
		move.w	d0,d7
		add.w	d7,d7
		adda	d7,a6
		move.w	d1,d7
		sub.w	#1,d7
		move.w	d2,d6
		and.w	#1,d6
		ror.w	#1,d6
.loop:
		move.w	(a5)+,(a6)+
		dbf	d7,.loop
		rts

; --------------------------------------------------------
; Video_DoPalFade
;
; RAM_ReqFadeMars: (WORD)
; $00 - No task or finished.
; $01 - Fade in
; $02 - Fade out to black
;
; NOTE: ONLY CALL THIS OUTSIDE OF VBLANK
; --------------------------------------------------------

Video_DoPalFade:
		sub.w	#1,(RAM_FadeMdTmr).w
		bpl.s	.active
		move.w	(RAM_FadeMdDelay).w,(RAM_FadeMdTmr).w
		move.w	(RAM_FadeMdReq).w,d7
		add.w	d7,d7
		move.w	.fade_list(pc,d7.w),d7
		jmp	.fade_list(pc,d7.w)
.active:
		rts

; --------------------------------------------

.fade_list:
		dc.w .fade_done-.fade_list
		dc.w .fade_in-.fade_list
		dc.w .fade_out-.fade_list

; --------------------------------------------
; No fade or finished.
; --------------------------------------------

.fade_done:
		rts

; --------------------------------------------
; Fade in
; --------------------------------------------

.fade_in:
		lea	(RAM_PaletteFd),a6
		lea	(RAM_Palette),a5
		move.w	#64,d0				; Num of colors
		move.w	(RAM_FadeMdIncr).w,d1		; Speed
		add.w	d1,d1
		move.w	d0,d6
		swap	d6
		sub.w	#1,d0
.nxt_pal:
		clr.w	d2		; Reset finished colorbits
		move.w	(a6),d7		; d7 - Input
		move.w	(a5),d6		; d6 - Output
		move.w	d7,d3		; RED
		move.w	d6,d4
		and.w	#%0000111011100000,d6
		and.w	#%0000000000001110,d4
		and.w	#%0000000000001110,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_red
		move.w	d3,d4
		or.w	#%001,d2	; RED is ready
.no_red:
		or.w	d4,d6
		lsl.w	#4,d1
		move.w	d7,d3		; GREEN
		move.w	d6,d4
		and.w	#%0000111000001110,d6
		and.w	#%0000000011100000,d4
		and.w	#%0000000011100000,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_grn
		move.w	d3,d4
		or.w	#%010,d2	; GREEN is ready
.no_grn:
		or.w	d4,d6
		lsl.w	#4,d1
		move.w	d7,d3		; BLUE
		move.w	d6,d4
		and.w	#%0000000011101110,d6
		and.w	#%0000111000000000,d4
		and.w	#%0000111000000000,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_blu
		move.w	d3,d4
		or.w	#%100,d2	; BLUE is ready
.no_blu:
		or.w	d4,d6
		lsr.w	#8,d1
		move.w	d6,(a5)+
		adda	#2,a6
		cmp.w	#%111,d2
		bne.s	.no_fnsh
		swap	d6
		sub.w	#1,d6
		swap	d6
.no_fnsh:
		dbf	d0,.nxt_pal
		swap	d6
		tst.w	d6
		bne.s	.no_move
		clr.w	(RAM_FadeMdReq).w
.no_move:
		rts

; --------------------------------------------
; Fade out
; --------------------------------------------

.fade_out:
		lea	(RAM_Palette),a6
		move.w	#64,d0				; Num of colors
		move.w	(RAM_FadeMdIncr).w,d1		; Speed
		move.w	d0,d6
		swap	d6
		sub.w	#1,d0
.nxt_pal_o:
		clr.w	d2			; Reset finished colorbits
		move.w	(a6),d7			; d7 - Input
		move.w	d7,d6
		and.w	#%0000111011100000,d7
		and.w	#%0000000000001110,d6
		sub.w	d1,d6
		bpl.s	.no_red_o
		clr.w	d6
		or.w	#%001,d2		; RED is ready
.no_red_o:
		or.w	d6,d7
		lsl.w	#4,d1
		move.w	d7,d6
		and.w	#%0000111000001110,d7
		and.w	#%0000000011100000,d6
		sub.w	d1,d6
		bpl.s	.no_grn_o
		clr.w	d6
		or.w	#%010,d2		; GREEN is ready
.no_grn_o:
		or.w	d6,d7
		lsl.w	#4,d1
		move.w	d7,d6
		and.w	#%0000000011101110,d7
		and.w	#%0000111000000000,d6
		sub.w	d1,d6
		bpl.s	.no_blu_o
		clr.w	d6
		or.w	#%100,d2		; BLUE is ready
.no_blu_o:
		or.w	d6,d7
		lsr.w	#8,d1
		move.w	d7,(a6)+
		cmp.w	#%111,d2
		bne.s	.no_fnsh_o
		swap	d6
		sub.w	#1,d6
		swap	d6
.no_fnsh_o:
		dbf	d0,.nxt_pal_o
		swap	d6
		tst.w	d6
		bne.s	.no_move_o
		clr.w	(RAM_FadeMdReq).w
.no_move_o:
		rts

; ====================================================================
; --------------------------------------------------------
; Genesis DMA
; --------------------------------------------------------

; --------------------------------------------------------
; Video_DmaMkEntry
;
; Sets a new DMA transfer task to the Blast list
;
; *** ONLY CALL THIS OUTSIDE OF VBLANK ***
;
; d0 | LONG - Art data
; d1 | WORD - VRAM location
; d2 | WORD - Size
;
; Breaks:
; d6-d7,a6
; --------------------------------------------------------

Video_DmaMkEntry:
		move.w	#1,(RAM_VdpDmaMod).w
		lea	(RAM_VdpDmaList).w,a6
		move.w	(RAM_VdpDmaIndx).w,d7
		adda	d7,a6
		add.w	#7*2,d7
		move.w	d7,(RAM_VdpDmaIndx).w
		move.w	d2,d7			; Length
		move.l	#$94009300,d6
		lsr.w	#1,d7
		move.b	d7,d6
		swap	d6
		lsr.w	#8,d7
		move.b	d7,d6
		swap	d6
		move.l	d6,(a6)+
		move.l	d0,d7			; Source
  		lsr.l	#1,d7
 		move.l	#$96009500,d6
 		move.b	d7,d6
 		lsr.l	#8,d7
 		swap	d6
 		move.b	d7,d6
 		move.l	d6,(a6)+
 		move.w	#$9700,d6
 		lsr.l	#8,d7
 		move.b	d7,d6
 		move.w	d6,(a6)+
		move.w	d1,d7			; Destination
; 		and.w	#$7FF,d7
; 		lsl.w	#5,d7
		move.w	d7,d6
		and.l	#$3FE0,d7
		ori.w	#$4000,d7
		lsr.w	#8,d6
		lsr.w	#6,d6
		andi.w	#%11,d6
		ori.w	#$80,d6
		move.w	d7,(a6)+
		move.w	d6,(a6)+
		move.w	#0,(RAM_VdpDmaMod).w
		rts

; --------------------------------------------------------
; Video_Fill
;
; Fill data to VRAM
;
; d0 | WORD - WORD to fill
; d1 | WORD - VRAM position
; d2 | WORD - Size
;
; Breaks:
; d6-d7,a6
; --------------------------------------------------------

Video_Fill:
		lea	(vdp_ctrl),a6
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1),d7
		bset	#bitDmaEnbl,d7
		move.w	d7,(a6)
.dmaw:		move.w	(a6),d7
		btst	#bitDma,d7
		bne.s	.dmaw
		move.w	#$8F01,(a6)	; Increment $01
		move.w	d2,d7		; d2 - Size
		sub.w	#1,d7
		move.l	#$94009300,d6
		move.b	d7,d6
		swap	d6
		lsr.w	#8,d7
		move.b	d7,d6
		swap	d6
		move.l	d6,(a6)
		move.w	#$9780,(a6)	; DMA Fill mode
		move.w	d1,d7		; d1 - Destination
; 		lsl.w	#5,d7
		move.w	d7,d6
		andi.w	#$3FFF,d6
		ori.w	#$4000,d6
		swap	d6
		move.w	d7,d6
		lsr.w	#8,d6
		lsr.w	#6,d6
		andi.w	#%11,d6
		ori.w	#$80,d6
		move.l	d6,(a6)
		move.w	d0,-4(a6)
.dmawe:		move.w	(a6),d7
		btst	#bitDma,d7
		bne.s	.dmawe
		move.w	#$8F02,(a6)	; Increment $02
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1),d7
		move.w	d7,(a6)
		rts

; --------------------------------------------------------
; Video_Copy
;
; Copy VRAM data to another location
;
; d0 | WORD - VRAM Source
; d1 | WORD - VRAM Destination
; d2 | WORD - Size
;
; Breaks:
; d6-d7,a6
; --------------------------------------------------------

; TODO: test if this works again...

Video_Copy:
		lea	(vdp_ctrl),a6
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1),d7
		bset	#bitDmaEnbl,d7
		move.w	d7,(a6)
.dmaw:		move.w	(a6),d7
		btst	#bitDma,d7
		bne.s	.dmaw
		move.w	#$8F01,(a6)		; Increment $01
		move.w	d2,d7			; SIZE
		move.l	#$94009300,d6
; 		lsr.w	#1,d7
		move.b	d7,d6
		swap	d6
		lsr.w	#8,d7
		move.b	d7,d6
		swap	d6
		move.l	d6,(a6)
		move.l	#$96009500,d6		; SOURCE
		move.w	d0,d7
		move.b	d7,d6
		swap	d6
		lsr.w	#8,d7
		move.b	d7,d6
		move.l	d6,(a6)
		move.w	#$97C0,(a6)		; DMA Copy mode
		move.l	d2,d7			; DESTINATION
; 		lsl.w	#5,d7
		move.w	d7,d6
		andi.w	#$3FFF,d6
		ori.w	#$4000,d6
		swap	d6
		move.w	d7,d6
		lsr.w	#8,d6
		lsr.w	#6,d6
		andi.w	#%11,d6
		ori.w	#$C0,d6
		move.l	d6,(a6)
		move.w	d1,-4(a6)
.dmawe:		move.w	(a6),d7
		btst	#bitDma,d7
		bne.s	.dmawe
		move.w	#$8F02,(a6)		; Increment $02
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1),d7
		move.w	d7,(a6)
		rts

; --------------------------------------------------------
; Load graphics using DMA, direct
;
; d0 | LONG - Art data
; d1 | WORD - VRAM location
; d2 | WORD - Size
;
; Breaks:
; d5-d7,a4-a6
;
; *** For faster transfers call this during VBlank ***
; *** MAKE SURE SH2 IS NOT IN THE MIDDLE OF READING
; ROM ***
; --------------------------------------------------------

Video_LoadArt:
		move.w	sr,-(sp)
		or	#$700,sr
		lea	(vdp_ctrl),a4
		move.w	#$8100,d6		; DMA ON
		move.b	(RAM_VdpRegs+1),d6
		bset	#bitDmaEnbl,d6
		move.w	d6,(a4)
		move.w	d2,d6			; Length
		move.l	#$94009300,d5
		lsr.w	#1,d6
		move.b	d6,d5
		swap	d5
		lsr.w	#8,d6
		move.b	d6,d5
		swap	d5
		move.l	d5,(a4)
		move.l	d0,d6			; Source
  		lsr.l	#1,d6
 		move.l	#$96009500,d5
 		move.b	d6,d5
 		lsr.l	#8,d6
 		swap	d5
 		move.b	d6,d5
 		move.l	d5,(a4)
 		move.w	#$9700,d5
 		lsr.l	#8,d6
 		move.b	d6,d5
 		move.w	d5,(a4)
		move.w	d1,d6			; Destination
		move.w	d6,d5
		and.l	#$3FE0,d6
		ori.w	#$4000,d6
		lsr.w	#8,d5
		lsr.w	#6,d5
		andi.w	#%11,d5
		ori.w	#$80,d5
		move.l	d0,d7
		swap	d7
		lsr.w	#8,d7
		cmp.b	#$FF,d7
		beq.s	.from_ram
		bsr	System_DmaEnter_ROM
 		move.w	d5,-(sp)
		move.w	d6,(a4)				; d6 - First word
		move.w	(sp)+,(a4)			; *** Second write, 68k freezes until DMA ends
		move.w	#$8100,d6			; DMA OFF
		move.b	(RAM_VdpRegs+1),d6
		move.w	d6,(a4)
		move.w	(sp)+,sr
		bra	System_DmaExit_ROM
.from_ram:
		move.w	d7,(a4)
 		move.w	d5,-(sp)
		move.w	(sp)+,(a4)			; Second write
		move.w	#$8100,d7
		move.b	(RAM_VdpRegs+1),d7
		move.w	d7,(a4)
		move.w	(sp)+,sr
		rts

; --------------------------------------------------------
; Video_DmaBlast
;
; Process DMA tasks from a predefined list in RAM
; **CALL THIS DURING VBLANK ONLY**
;
; Breaks:
; d5-d7,a3-a4
; --------------------------------------------------------

; Entry format:
; $94xx,$93xx,$96xx,$95xx,$97xx (SIZE,SOURCE)
; $40000080 (vdp destination + dma bit)

Video_DmaBlast:
		tst.w	(RAM_VdpDmaMod).w		; Got mid-write?
		bne.s	.exit
		tst.w	(RAM_VdpDmaIndx).w		; Any requests?
		beq.s	.exit
		lea	(vdp_ctrl),a4			; Enter processing loop
		lea	(RAM_VdpDmaList).w,a3
		move.w	#$8100,d7			; DMA ON
		move.b	(RAM_VdpRegs+1),d7
		bset	#bitDmaEnbl,d7
		move.w	d7,(a4)
		bsr	System_DmaEnter_ROM		; Request Z80 stop and SH2 backup
	if MARS
		bset	#0,(sysmars_reg+dreqctl+1).l	; Set RV=1
	endif
.next:		tst.w	(RAM_VdpDmaIndx).w
		beq.s	.end
		move.l	(a3),(a4)			; Size
		clr.l	(a3)+
		move.l	(a3),(a4)			; Source
		clr.l	(a3)+
		move.w	(a3),(a4)
		clr.w	(a3)+
		move.w	(a3),d6				; Destination
		clr.w	(a3)+
		move.w	(a3),d5
		clr.w	(a3)+
		move.w	d6,(a4)
		move.w	d5,(a4)
		sub.w	#7*2,(RAM_VdpDmaIndx).w
		bra.s	.next
.end:
	if MARS
		bclr	#0,(sysmars_reg+dreqctl+1).l	; Set RV=0
	endif
		bsr	System_DmaExit_ROM		; Resume Z80 and SH2 direct
		move.w	#$8100,d7			; DMA OFF
		move.b	(RAM_VdpRegs+1).w,d7
		move.w	d7,(a4)
.exit:
		rts

; ====================================================================
; ----------------------------------------------------------------
; Video routines for 32X
; ----------------------------------------------------------------

; --------------------------------------------------------
; Video_Mars_GfxMode
; Sets graphics mode on the 32X side
;
; Input:
; d0 - Graphics mode
; --------------------------------------------------------

Video_Mars_GfxMode:
	if MARS
		move.w	d0,d7
		and.w	#%00000111,d7			; Current limit: 8 Master modes
		or.w	#$C0,d7
		move.b	d7,(sysmars_reg+comm12+1).l
		bsr	System_MarsUpdate
.wait_slv:	move.w	(sysmars_reg+comm14).l,d7	; Wait for Slave
		and.w	#%00001111,d7
		bne.s	.wait_slv
.wait:		move.w	(sysmars_reg+comm12).l,d7	; Wait for Master
		and.w	#%11000000,d7
		bne.s	.wait
	endif
		rts

; --------------------------------------------------------
; Video_Mars_WaitFrame
; --------------------------------------------------------

Video_Mars_WaitFrame:
	if MARS
		bset	#5,(sysmars_reg+comm12+1).l	; Set R bit
.wait:
; 		move.w	(vdp_ctrl),d7
; 		btst	#bitVBlk,d7
; 		bne.s	.late
		move.w	(sysmars_reg+comm12).l,d7
		btst	#5,d7
		bne.s	.wait
.late:
	endif
		rts

; --------------------------------------------------------
; Video_LoadPal_Mars
;
; Load Indexed palette directly to Buffer
;
; d0 - Start at
; d1 - Number of colors
; d2 - Priority bit OFF/ON
; --------------------------------------------------------

Video_FadePal_Mars:
		lea	(RAM_MdMarsPalFd),a6
		clr.w	(RAM_FadeMarsTmr).w
		bra.s	vidMars_Pal
Video_LoadPal_Mars:
		lea	(RAM_MdDreq+Dreq_Palette).w,a6
vidMars_Pal:
		move.l	a0,a5
		moveq	#0,d7
		move.w	d0,d7
		add.w	d7,d7
		adda	d7,a6
		move.w	d1,d7
		sub.w	#1,d7
		move.w	d2,d6
		and.w	#1,d6
		ror.w	#1,d6
.loop:
		move.w	(a5)+,d5
		or.w	d6,d5
		move.w	d5,(a6)+
		dbf	d7,.loop
		rts

; --------------------------------------------------------
; Video_MarsPalFade
;
; a0 - Palette data
; d0 - Number of colors
; d1 - Speed
;
; RAM_ReqFadeMars: (WORD)
; $00 - No task (or finished)
; $01 - Fade in
; $02 - Fade out to black
;
; CALL THIS OUTSIDE OF VBLANK
; --------------------------------------------------------

; TODO: luego ver que hago con el priority bit

Video_MarsPalFade:
		sub.w	#1,(RAM_FadeMarsTmr).w
		bpl.s	.active
		move.w	(RAM_FadeMarsDelay).w,(RAM_FadeMarsTmr).w
		move.w	(RAM_FadeMarsReq).w,d7
		add.w	d7,d7
		move.w	.fade_list(pc,d7.w),d7
		jmp	.fade_list(pc,d7.w)
.active:
		rts

; --------------------------------------------

.fade_list:
		dc.w .fade_done-.fade_list
		dc.w .fade_in-.fade_list
		dc.w .fade_out-.fade_list

; --------------------------------------------
; No fade or finished.
; --------------------------------------------

.fade_done:
		rts

; --------------------------------------------
; Fade in
; --------------------------------------------

.fade_in:
		lea	(RAM_MdMarsPalFd),a6
		lea	(RAM_MdDreq+Dreq_Palette).w,a5
		move.w	#256,d0				; Num of colors
		move.w	(RAM_FadeMarsIncr).w,d1		; Speed
		move.w	d0,d6
		swap	d6
		sub.w	#1,d0
.nxt_pal:
		clr.w	d2		; Reset finished colorbits
		move.w	(a6),d7		; d7 - Input
		move.w	(a5),d6		; d6 - Output
		move.w	d7,d3		; RED
		move.w	d6,d4
		and.w	#%1111111111100000,d6
		and.w	#%0000000000011111,d4
		and.w	#%0000000000011111,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_red
		move.w	d3,d4
		or.w	#%001,d2	; RED is ready
.no_red:
		or.w	d4,d6
		lsl.w	#5,d1
		move.w	d7,d3		; GREEN
		move.w	d6,d4
		and.w	#%1111110000011111,d6
		and.w	#%0000001111100000,d4
		and.w	#%0000001111100000,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_grn
		move.w	d3,d4
		or.w	#%010,d2	; GREEN is ready
.no_grn:
		or.w	d4,d6
		lsl.w	#5,d1
		move.w	d7,d3		; BLUE
		move.w	d6,d4
		and.w	#%1000001111111111,d6
		and.w	#%0111110000000000,d4
		and.w	#%0111110000000000,d3
		add.w	d1,d4
		cmp.w	d3,d4
		bcs.s	.no_blu
		move.w	d3,d4
		or.w	#%100,d2	; BLUE is ready
.no_blu:
		or.w	d4,d6
		lsr.w	#8,d1
		lsr.w	#2,d1
		and.w	#$8000,d7	; Keep priority bit
		or.w	d7,d6
		move.w	d6,(a5)+
		adda	#2,a6
		cmp.w	#%111,d2
		bne.s	.no_fnsh
		swap	d6
		sub.w	#1,d6
		swap	d6
.no_fnsh:
		dbf	d0,.nxt_pal
		swap	d6
		tst.w	d6
		bne.s	.no_move
		clr.w	(RAM_FadeMarsReq).w
.no_move:
		rts

; --------------------------------------------
; Fade out
; --------------------------------------------

.fade_out:
		lea	(RAM_MdDreq+Dreq_Palette).w,a6
		move.w	#256,d0				; Num of colors
		move.w	(RAM_FadeMarsIncr).w,d1		; Speed
		move.w	d0,d6
		swap	d6
		sub.w	#1,d0
.nxt_pal_o:
		clr.w	d2		; Reset finished colorbits
		move.w	(a6),d7		; d7 - Input
		move.w	d7,d6
		and.w	#%1111111111100000,d7
		and.w	#%0000000000011111,d6
		sub.w	d1,d6
		bpl.s	.no_red_o
		clr.w	d6
		or.w	#%001,d2	; RED is ready
.no_red_o:
		or.w	d6,d7
		lsl.w	#5,d1
		move.w	d7,d6
		and.w	#%1111110000011111,d7
		and.w	#%0000001111100000,d6
		sub.w	d1,d6
		bpl.s	.no_grn_o
		clr.w	d6
		or.w	#%010,d2	; GREEN is ready
.no_grn_o:
		or.w	d6,d7
		lsl.w	#5,d1
		move.w	d7,d6
		and.w	#%1000001111111111,d7
		and.w	#%0111110000000000,d6
		sub.w	d1,d6
		bpl.s	.no_blu_o
		clr.w	d6
		or.w	#%100,d2	; BLUE is ready
.no_blu_o:
		or.w	d6,d7
		lsr.w	#8,d1
		lsr.w	#2,d1
		move.w	d7,(a6)+
		cmp.w	#%111,d2
		bne.s	.no_fnsh_o
		swap	d6
		sub.w	#1,d6
		swap	d6
.no_fnsh_o:
		dbf	d0,.nxt_pal_o
		swap	d6
		tst.w	d6
		bne.s	.no_move_o
		clr.w	(RAM_FadeMarsReq).w
.no_move_o:
		rts

; ====================================================================
; ----------------------------------------------------------------
; MAP layout system
;
; Note: uses some RAM'd video registeds.
; ----------------------------------------------------------------

; --------------------------------------------------------
; MdMap_Init
;
; Initializes all BG buffers
; --------------------------------------------------------

MdMap_Init:
		lea	(RAM_BgBuffer),a0
		move.w	#((sizeof_mdbg*4)/4)-1,d1
		moveq	#0,d0
.clr:
		move.l	d0,(a0)+
		dbf	d1,.clr
		rts

; --------------------------------------------------------
; MdMap_Set
;
; Sets a new scrolling section to use.
;
; **SET YOUR X and Y COORDS EXTERNALLY
; BEFORE GETTING HERE**
;
; Input:
; ** Genesis side **
; d0 | WORD - BG internal slot (-1: 32X only)
; d1 | WORD - VRAM location for map data
; d2 | WORD - VRAM add + palette
; a0 - Level header data:
; 	dc.w width,height
; 	dc.b blkwidth,blkheight
; a1 - Block data
; a2 - LOW priority layout data
; a3 - HIGH priority layout data
; d4 - Collision data
;
; Then load the graphics externally at the same
; VRAM location set in d2
;
; ** 32X side **
; d0 | WORD - Write as -1
; d1 | WORD - Scroll buffer to use on the 32X side (0 - default)
; d2 | WORD - Index-palette increment
; a0 - Level header data: (68K AREA)
; 	dc.w width,height
; 	dc.b blkwidth,blkheight
; a1 - Graphics data stored as blocks (SH2 AREA)
; a2 - MAIN layout (SH2 AREA)
; a3 - *** UNUSED, set to 0
; a4 - Collision data (68K AREA)
;
; Uses:
; d0,d6-d7
; --------------------------------------------------------

MdMap_Set:
		tst.w	d0
		bpl.s	.md_side
		lea	(RAM_BgBufferM),a6
		bset	#bitMarsBg,md_bg_flags(a6)
		bra.s	.mars_side
.md_side:
		lea	(RAM_BgBuffer),a6
		mulu.w	#sizeof_mdbg,d0
		adda	d0,a6
		bclr	#bitMarsBg,md_bg_flags(a6)
.mars_side:
		move.w	d1,md_bg_vpos(a6)
		move.w	d2,md_bg_vram(a6)

		moveq	#0,d7
		move.w	md_bg_x(a6),d7
		move.b	d7,md_bg_xset(a6)
		move.w	d7,md_bg_x_old(a6)
		swap	d7
		move.l	d7,md_bg_x(a6)
		moveq	#0,d7
		move.w	md_bg_y(a6),d7
		move.b	d7,md_bg_yset(a6)
		move.w	d7,md_bg_y_old(a6)
		swap	d7
		move.l	d7,md_bg_y(a6)
		and.w	#$F,d3
		and.w	#$F,d4

		swap	d3
		swap	d4
		move.l	a1,md_bg_blk(a6)
		move.l	a2,md_bg_low(a6)
		move.l	a3,md_bg_hi(a6)
		move.l	a4,md_bg_col(a6)
		move.l	a0,a5
		move.w	(a5)+,d7	; Layout Width (blocks)
		move.w	(a5)+,d6	; Layout Height (blocks)
		move.b	(a5)+,d4	; BLOCK width
		move.b	(a5)+,d3	; BLOCK height
		and.w	#$FF,d4
		and.w	#$FF,d3
		move.w	d7,md_bg_w(a6)
		move.w	d6,md_bg_h(a6)
		move.b	d4,md_bg_bw(a6)
		move.b	d3,md_bg_bh(a6)
		mulu.w	d4,d7
		mulu.w	d3,d6
		move.w	d7,md_bg_wf(a6)
		move.w	d6,md_bg_hf(a6)
		sub.w	#1,d4
		sub.w	#1,d3
		and.b	d4,md_bg_xset(a6)
		and.b	d3,md_bg_yset(a6)
		swap	d3
		swap	d4

	; TODO: improve this...
		move.w	md_bg_x(a6),d3
		move.w	md_bg_y(a6),d4
	; X beams
.xl_l:		cmp.w	d7,d3
		blt.s	.xl_g
		sub.w	d7,d3
		bra.s	.xl_l
.xl_g:
		move.w	d3,md_bg_xinc_l(a6)
		add.w	#320,d3				; <-- X resolution R
.xr_l:		cmp.w	d7,d3
		blt.s	.xr_g
		sub.w	d7,d3
		bra.s	.xr_l
.xr_g:
		move.w	d3,md_bg_xinc_r(a6)

	; Y beams
.yt_l:		cmp.w	d6,d4
		blt.s	.yt_g
		sub.w	d6,d4
		bra.s	.yt_l
.yt_g:
		move.w	d4,md_bg_yinc_u(a6)
		add.w	#224,d4				; <-- Y resolution B
.yb_l:		cmp.w	d6,d4
		blt.s	.yb_g
		sub.w	d6,d4
		bra.s	.yb_l
.yb_g:
		move.w	d4,md_bg_yinc_d(a6)

		bset	#bitBgOn,md_bg_flags(a6)	; Enable this BG
		rts

; --------------------------------------------------------
; MdMap_Move
;
; Moves the current background/foreground
; and checks for overflow.
;
; Input:
; d0 | WORD - Background slot, if -1 32X's
; d1 | WORD - Current X position
; d2 | WORD - Current Y position
; a0 - Background to move and check.
;
; Uses:
; d6-d7
; --------------------------------------------------------

MdMap_Move:
		lea	(RAM_BgBufferM),a6
		tst.w	d0
		bmi.s	.mars_side
		lea	(RAM_BgBuffer),a6
		mulu.w	#sizeof_mdbg,d0
		adda	d0,a6
.mars_side:
; 		btst	#bitBgOn,md_bg_flags(a6)
; 		beq	.not_enabld
		move.w	md_bg_wf(a6),d0
		tst.w	d1
		bpl.s	.x_left
		clr.w	d1
.x_left:
		sub.w	#320,d0
		cmp.w	d0,d1
		bcs.s	.x_right
		move.w	d0,d1
.x_right:
		move.w	md_bg_hf(a6),d0
		tst.w	d2
		bpl.s	.y_left
		clr.w	d2
.y_left:
		sub.w	#224,d0
		cmp.w	d0,d2
		bcs.s	.y_right
		move.w	d0,d2
.y_right:
		move.w	d1,md_bg_x(a6)
		move.w	d2,md_bg_y(a6)
.not_enabld:
		rts

; --------------------------------------------------------
; MdMap_Update
;
; Updates backgrounds internally, call this
; BEFORE going into VBlank.
;
; Then later call MdMap_DrawScrl on VBlank,
; this also applies for the 32X as this routine also
; resets the drawing bits.
;
; For the 32X:
; Call System_MarsUpdate AFTER this.
; --------------------------------------------------------

MdMap_Update:
		lea	(RAM_BgBufferM),a6
		bsr.s	.this_bg
		lea	(RAM_BgBuffer),a6
		bsr.s	.this_bg
		adda	#sizeof_mdbg,a6
.this_bg:
		btst	#bitBgOn,md_bg_flags(a6)
		beq	.no_bg
		moveq	#0,d1
		moveq	#0,d2
		move.w	md_bg_x(a6),d3
		move.w	md_bg_x_old(a6),d0
		cmp.w	d0,d3
		beq.s	.xequ
		move.w	d3,d1
		sub.w	d0,d1
		move.w	d3,md_bg_x_old(a6)
.xequ:
		move.w	md_bg_y(a6),d3
		move.w	md_bg_y_old(a6),d0
		cmp.w	d0,d3
		beq.s	.yequ
		move.w	d3,d2
		sub.w	d0,d2
		move.w	d3,md_bg_y_old(a6)
.yequ:

	; Increment drawing beams
		move.w	d1,d0
		move.w	md_bg_wf(a6),d5
		move.w	md_bg_xinc_l(a6),d4
		bsr.s	.beam_incr
		move.w	d4,md_bg_xinc_l(a6)
		move.w	md_bg_xinc_r(a6),d4
		bsr.s	.beam_incr
		move.w	d4,md_bg_xinc_r(a6)
		move.w	d2,d0
		move.w	md_bg_hf(a6),d5
		move.w	md_bg_yinc_u(a6),d4
		bsr.s	.beam_incr
		move.w	d4,md_bg_yinc_u(a6)
		move.w	md_bg_yinc_d(a6),d4
		bsr.s	.beam_incr
		move.w	d4,md_bg_yinc_d(a6)

	; Update internal counters
		moveq	#0,d3
		move.b	md_bg_bw(a6),d3		; X set
		move.b	md_bg_xset(a6),d0
		add.b	d1,d0
		move.b	d0,d4
		and.w	d3,d4
		beq.s	.x_k
		moveq	#bitDrwR,d4
		tst.w	d1
		bpl.s	.x_r
		moveq	#bitDrwL,d4
.x_r:
		bset	d4,md_bg_flags(a6)
.x_k:
		sub.w	#1,d3
		and.b	d3,d0
		move.b	d0,md_bg_xset(a6)
		move.b	md_bg_bh(a6),d3		; Y set
		move.b	md_bg_yset(a6),d0
		add.b	d2,d0
		move.b	d0,d4
		and.w	d3,d4
		beq.s	.y_k
		moveq	#bitDrwD,d4
		tst.w	d2
		bpl.s	.y_d
		moveq	#bitDrwU,d4
.y_d:
		bset	d4,md_bg_flags(a6)
.y_k:
		sub.w	#1,d3
		and.b	d3,d0
		move.b	d0,md_bg_yset(a6)
.no_bg:
		rts

; d0 - Increment by
; d4 - X/Y beam
; d5 - Max Width/Height
.beam_incr:
		add.w	d0,d4
.xd_l:		tst.w	d4
		bpl.s	.xd_g
		add.w	d5,d4
		bra.s	.xd_l
.xd_g:		cmp.w	d5,d4
		blt.s	.val_h
		sub.w	d5,d4
		bra.s	.xd_g
.val_h:
		rts

; --------------------------------------------------------
; MdMap_DrawAll
;
; Call this only if DISPLAY is OFF or in VBlank
;
; Notes:
; - Does NOT check for off-bounds blocks
; - Blocks with ID $00 are skipped.
; --------------------------------------------------------

MdMap_DrawAll:
		lea	(RAM_BgBuffer),a6
		bsr	.this_bg
		adda	#sizeof_mdbg,a6
.this_bg:
		btst	#bitBgOn,md_bg_flags(a6)
		beq	.no_bg
		move.l	md_bg_blk(a6),a5
		move.l	md_bg_low(a6),a4
		move.l	md_bg_hi(a6),a3
		move.w	md_bg_x(a6),d0		; X start
		move.w	md_bg_y(a6),d1		; Y start
		move.b	md_bg_bw(a6),d2
		move.b	md_bg_bh(a6),d3
		move.w	md_bg_w(a6),d4
; 		move.w	md_bg_wf(a6),d5
; 		move.w	md_bg_hf(a6),d6

		moveq	#0,d6
		move.w	d0,d6
		and.w	#-$10,d6
		lsr.w	#2,d6
		and.w	#$7F,d6

		moveq	#0,d5
		move.w	d1,d5
		and.w	#-$10,d5
		lsl.w	#4,d5
		and.w	#$F00,d5

		add.w	d5,d6
		add.w	md_bg_vpos(a6),d6
		move.w	d6,d5
		rol.w	#2,d6
		and.w	#%11,d6
		swap	d6
		and.w	#$3FFF,d5
		move.w	d5,d6			; d6 - VDP 2nd|1st writes

		and.w	#$FF,d2
		muls.w	d2,d0
		lsr.w	#8,d0
		and.w	#$FF,d3
		muls.w	d3,d1
		lsr.w	#8,d1
		muls.w	d4,d1
		add.l	d1,d0
		add.l	d0,a4
		add.l	d0,a3
		move.w	#$80,d1
		move.w	d1,d3
		swap	d1
		sub.w	#1,d3
		moveq	#0,d2
		move.w	md_bg_vram(a6),d2	; d2 - VRAM cell pos
		swap	d3
		move.w	#4,d3			; d3 - X wrap | X next block
		move.w	#$0FFF,d4		; d4 - Y wrap | Y next block + bits
		swap	d4
		move.w	#$100,d4
		move.w	d5,d0
		moveq	#0,d5			; d5 - temporal | X-add read
		move.w	#(512/16)-1,d7		; d7 - X cells | Y cells
		swap	d7
		move.w	#(256/16)-1,d7

	; a6 - Current BG buffer
	; a5 - Block-data base
	; a4 - LOW layout data Y
	; a3 - HI layout data Y
	; a2 - a4 current
	; a1 - a3 current
	; a0 - Block-data read

	; d7 - X loop        | Y loop
	; d6 - VDP 2nd Write | X/Y VDP pos + addr bits
	; d5 - X loop-save   | X VDP current
	; d4 - Y wrap        | Y next block pos
	; d3 - X wrap        | X next block pos
	; d2 - Y block size  | VRAM-cell base
	; d1 - Y-next line   | VRAM-cell read + prio
	; d0 -    ---        | ---

.y_loop:
		swap	d7
		move.l	a4,a2		; a2 - LOW line
		move.l	a3,a1		; a1 - HI line
		move.w	d7,d5
.x_loop:
		swap	d5
		move.w	d2,d1
		move.b	(a2),d0		; HI block?
		bne.s	.got_blk
		add.w	#$8000,d1
		move.b	(a1),d0
		beq.s	.blank
.got_blk:
		bsr	.mk_block
.blank:
		move.l	d3,d0
		swap	d0
		add.w	d3,d5		; next VDP X pos
		and.w	d0,d5
		adda	#1,a2
		adda	#1,a1
		swap	d5
		dbf	d5,.x_loop

		move.w	d6,d0
		and.w	#$3000,d0
		add.w	d4,d6		; <-- next VDP Y block
		swap	d4
		and.w	d4,d6
		or.w	d0,d6
		swap	d4

		move.w	md_bg_w(a6),d0 ; ***
		adda	d0,a4
		adda	d0,a3
		swap	d7
		dbf	d7,.y_loop
.no_bg:
		rts

; barely got free regs without using stack
.mk_block:
		swap	d2
		move.l	a5,a0
		and.w	#$FF,d0
		lsl.w	#3,d0		; * 8 bytes
		adda	d0,a0		; a0 - cell word data
		move.w	d6,d0
		add.w	d5,d0
		or.w	#$4000,d0
		swap	d6

	; d0 - topleft VDP write | $4000
	; d6 - right VDP write
	; d2 is free
	;
	; currently working: 16x16
		bsr.s	.drwy_16	; 1-
		add.w	#2,d0		; 2-
		bsr.s	.drwy_16	; -3
					; -4
		swap	d6
		swap	d2
		rts

; d0 - left vdp
; d6 - right vdp
.drwy_16:
		move.w	d0,d2
		swap	d0
		move.w	(a0)+,d0
		add.w	d1,d0
		move.w	d2,(vdp_ctrl).l
		move.w	d6,(vdp_ctrl).l
		move.w	d0,(vdp_data).l
		swap	d1
		add.w	d1,d2		; Next line
		swap	d1
		move.w	(a0)+,d0
		add.w	d1,d0
		move.w	d2,(vdp_ctrl).l
		move.w	d6,(vdp_ctrl).l
		move.w	d0,(vdp_data).l
		swap	d0
		rts

	; Block: 16x16 as 13
	;                 24
	; d0 - block ID
	; d1 - VRAM-add base
	; d6 - VDP out R | VDP out L
; 		and.w	#$FF,d0
; 		lsl.w	#3,d0		; * 8 bytes
; 		move.l	(a5,d0.w),d2
; 		add.l	d1,d2
; 		swap	d2
; 		move.l	4(a5,d0.w),d3
; 		add.l	d1,d3
; 		swap	d3
; 		move.w	d6,d0
; 		swap	d5
; 		add.w	d5,d0
; 		or.w	#$4000,d0
; 		swap	d5
; 		move.l	a0,d1
; 		and.w	d1,d5
; 		add.w	d5,d0
; 		swap	d6
; 		move.w	d0,(vdp_ctrl).l
; 		move.w	d6,(vdp_ctrl).l
; 		move.w	d2,(vdp_data).l
; 		move.w	d3,(vdp_data).l
; 		swap	d2
; 		swap	d3
; 		add.w	#$80,d0		; line add
; 		move.w	d0,(vdp_ctrl).l
; 		move.w	d6,(vdp_ctrl).l
; 		move.w	d2,(vdp_data).l
; 		move.w	d3,(vdp_data).l
; 		swap	d6
; 		rts

; --------------------------------------------------------
; MdMap_DrawScrlMd
;
; Draws map off-screen changes, only on Genesis-side.
;
; CALL THIS ON VBLANK ONLY, MUST BE QUICK.
; --------------------------------------------------------

MdMap_DrawScrlMd:
		lea	(RAM_BgBuffer),a6
		lea	(vdp_data),a5
		bsr.s	.this_bg
		adda	#sizeof_mdbg,a6
	; SH2-side handles the
	; RAM_BgBufferM's drawing

.this_bg:
		move.b	md_bg_flags(a6),d7
		btst	#bitBgOn,d7
		beq	.no_bg
		move.w	md_bg_x(a6),d0		; X start
		move.w	md_bg_y(a6),d1		; Y start
		move.w	md_bg_xinc_l(a6),d2
		move.w	md_bg_yinc_u(a6),d3
		bclr	#bitDrwU,d7
		beq.s	.no_u
		bsr	.mk_row
.no_u:
		bclr	#bitDrwD,d7
		beq.s	.no_d
		move.w	md_bg_yinc_d(a6),d3
		add.w	#224,d1			; X add
		bsr	.mk_row
.no_d:
		move.w	md_bg_x(a6),d0		; X start
		move.w	md_bg_y(a6),d1		; Y start
		move.w	md_bg_xinc_l(a6),d2
		move.w	md_bg_yinc_u(a6),d3
		bclr	#bitDrwL,d7
		beq.s	.no_l
		bsr.s	.mk_clmn
.no_l:
		bclr	#bitDrwR,d7
		beq.s	.no_r
		move.w	md_bg_xinc_r(a6),d2
		add.w	#320,d0			; X add
		bsr.s	.mk_clmn
.no_r:

		move.b	d7,md_bg_flags(a6)
.no_bg:
		rts

; ------------------------------------------------
; Make column
; d0 - X
; d1 - Y
; d2 - X increment
; d3 - Y increment
; ------------------------------------------------

.mk_clmn:
; 		btst	#bitMarsBg,d7
; 		bne	.mars_ret_c
		swap	d7
		bsr	.get_coords
		swap	d0
		move.w	d4,d0
		swap	d0
		move.w	#$FFF,d3
		swap	d3
		move.w	#$100,d3

	; d0 -    X curr | Current cell X/Y (1st)
	; d1 -    Y curr | VDP 1st write
	; d2 - Cell VRAM | VDP 2nd write
	; d3 -    Y wrap | Y add
	; d4 -         *****
	; d5 -         *****
	; d6 -         *****
	; d7 - lastflags | loop blocks

		move.w	#(256/16)-1,d7
.y_blk:
		moveq	#0,d4
		moveq	#0,d5
		move.b	(a3),d6
		bne.s	.vld
		move.b	(a2),d6
		bne.s	.prio
.blnk:
		moveq	#0,d4
		moveq	#0,d5
		bra.s	.frce
.prio:
		move.l	#$80008000,d4
		move.l	#$80008000,d5
.vld:
		move.l	a4,a0
		and.w	#$FF,d6
		lsl.w	#3,d6
		adda	d6,a0
		swap	d2
		add.w	(a0)+,d4
		add.w	(a0)+,d5
		add.w	d2,d4
		add.w	d2,d5
		swap	d4
		swap	d5
		add.w	(a0)+,d4
		add.w	(a0)+,d5
		add.w	d2,d4
		add.w	d2,d5
		swap	d2
.frce:
		move.w	d0,d6
		add.w	d1,d6
		or.w	#$4000,d6
		move.w	d6,4(a5)
		move.w	d2,4(a5)
		move.l	d4,(a5)
		add.w	#$80,d6
		move.w	d6,4(a5)
		move.w	d2,4(a5)
		move.l	d5,(a5)
		move.l	d3,d4		; Next Y block
		swap	d4
		add.w	d3,d0
		and.w	d4,d0
		move.w	md_bg_w(a6),d6
		adda	d6,a3
		adda	d6,a2
		swap	d1		; <-- TODO: improve this later.
		add.w	#$10,d1
		cmp.w	md_bg_hf(a6),d1
		blt.s	.y_low
		swap	d0
		clr.w	d1
		move.l	md_bg_low(a6),a3
		move.l	md_bg_hi(a6),a2
		adda	d0,a2
		adda	d0,a3
		swap	d0
.y_low:
		swap	d1

		dbf	d7,.y_blk
		swap	d7
.mars_ret_c:
		rts

; ------------------------------------------------
; Make row
; d0 - X
; d1 - Y
; d2 - X increment
; d3 - Y increment
; ------------------------------------------------

.mk_row:
; 		btst	#bitMarsBg,d7
; 		bne.s	.mars_ret_c
		swap	d7
		bsr	.get_coords
		swap	d1
		move.w	d5,d1
		swap	d1
		move.w	#$7F,d3
		swap	d3
		move.w	#4,d3

	; d0 -    X curr | Current cell X/Y (1st)
	; d1 -    Y curr | VDP 1st write
	; d2 - Cell VRAM | VDP 2nd write
	; d3 -    X wrap | X add
	; d4 -         *****
	; d5 -         *****
	; d6 - loopflags | *****
	; d7 - lastflags | loop blocks

		move.w	d0,d6
		and.w	#-$100,d6	; Merge d1
		add.w	d6,d1
		move.l	d3,d5
		swap	d5
		and.w	d5,d0
		move.w	#((320+16)/16)-1,d7
.x_blk:
		moveq	#0,d4
		moveq	#0,d5
		move.b	(a3),d6
		bne.s	.xvld
		move.b	(a2),d6
		bne.s	.xprio
.xblnk:
		moveq	#0,d4
		moveq	#0,d5
		bra.s	.xfrce
.xprio:
		move.l	#$80008000,d4
		move.l	#$80008000,d5
.xvld:
		move.l	a4,a0
		and.w	#$FF,d6
		lsl.w	#3,d6
		adda	d6,a0
		swap	d2
		add.w	(a0)+,d4
		add.w	(a0)+,d5
		add.w	d2,d4
		add.w	d2,d5
		swap	d4
		swap	d5
		add.w	(a0)+,d4
		add.w	(a0)+,d5
		add.w	d2,d4
		add.w	d2,d5
		swap	d2
.xfrce:
		move.w	d0,d6
		add.w	d1,d6
		or.w	#$4000,d6
		move.w	d6,4(a5)
		move.w	d2,4(a5)
		move.l	d4,(a5)
		add.w	#$80,d6
		move.w	d6,4(a5)
		move.w	d2,4(a5)
		move.l	d5,(a5)
		add.w	d3,d0
		swap	d3
		and.w	d3,d0
		swap	d3

	; X wrap
		swap	d0
		add.w	#$10,d0
		cmp.w	md_bg_wf(a6),d0
		blt.s	.x_low
		sub.w	md_bg_wf(a6),d0
		moveq	#0,d4
		move.w	md_bg_w(a6),d4
		sub.l	d4,a2
		sub.l	d4,a3
.x_low:
		adda	#1,a3
		adda	#1,a2
.x_new:
		swap	d0

		dbf	d7,.x_blk
		swap	d7
		rts

; ------------------------------------------------
; Input
; d0 - X position
; d1 - Y position
; d2 - X increment beam
; d3 - Y increment beam
;
; Out:
; d4 - X LEFT increment
; d5 - Y TOP increment

.get_coords:
		move.l	md_bg_blk(a6),a4
		move.l	md_bg_low(a6),a3
		move.l	md_bg_hi(a6),a2
		and.w	#-$10,d0		; block X/Y limit
		and.w	#-$10,d1
		and.w	#-$10,d2
		and.w	#-$10,d3
		swap	d0
		swap	d1
		move.w	d2,d0
		move.w	d3,d1
		swap	d0
		swap	d1

		moveq	#0,d4
		moveq	#0,d5
		move.b	md_bg_bw(a6),d6
		move.b	md_bg_bh(a6),d7
		and.w	#$FF,d6
		and.w	#$FF,d7

		move.w	d2,d4
		muls.w	d6,d4
		asr.w	#8,d4
		move.w	d3,d5
		muls.w	d7,d5
		asr.w	#8,d5
		muls.w	md_bg_w(a6),d5
		moveq	#0,d3
		move.l	d4,d3
		add.l	d5,d3
		add.l	d3,a3
		add.l	d3,a2

		move.w	md_bg_vram(a6),d2
		swap	d2
		lsr.w	#2,d1			; Y >> 2
		lsl.w	#6,d1			; Y * $40
		lsr.w	#2,d0			; X >> 2
		and.w	#$FFF,d1
		and.w	#$7C,d0
		add.w	d1,d0
		move.w	md_bg_vpos(a6),d1
		move.w	d1,d2
		and.w	#$3FFF,d1
		rol.w	#2,d2
		and.w	#%11,d2
		rts

; ====================================================================
; ----------------------------------------------------------------
; Objects system
;
; MD and MARS
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init objects
; --------------------------------------------------------

Objects_Init:
		lea	(RAM_Objects),a6
		move.w	#(sizeof_mdobj*MAX_MDOBJ)-1,d7
.clr:
		clr.b	(a6)+
		dbf	d7,.clr
		lea	(RAM_ObjDispList),a6
		move.w	#MAX_MDOBJ-1,d7
.clr_d:
		clr.w	(a6)+
		dbf	d7,.clr_d
		clr.w	(RAM_SprDrwCntr).w
		rts

; --------------------------------------------------------
; Process objects
; --------------------------------------------------------

Objects_Run:
		lea	(RAM_Objects),a6
		move.w	#MAX_MDOBJ-1,d7
.next_one:
		move.l	obj_code(a6),d6
		beq.s	.no_code	; Free slot
		move.l	d7,-(sp)
		move.l	d6,a5
		jsr	(a5)
		move.l	(sp)+,d7
.no_code:
		adda	#sizeof_mdobj,a6
		dbf	d7,.next_one
		rts

; --------------------------------------------------------
; Draw ALL Objects from display list
;
; Call this BEFORE VBlank.
; --------------------------------------------------------

Objects_Show:
		moveq	#1,d7				; d7 - MD Link
		lea	(RAM_Sprites),a6		; a6 - Genesis sprites

		move.w	(RAM_SprDrwCntr),d6
		beq.s	.no_sprdrw
		clr.w	(RAM_SprDrwCntr).w
		lea	(RAM_SprDrwPz),a5
		sub.w	#1,d6
.nexts:
		cmp.w	#70,d7
		bge.s	.no_sprdrw
		move.w	(a5)+,d0
		move.w	(a5)+,d1	; custom
		and.w	#$FF,d1
		lsl.w	#8,d1
		or.w	d7,d1
		move.w	(a5)+,d2
		move.w	(a5)+,d3
		move.w	d0,(a6)+
		move.w	d1,(a6)+
		move.w	d2,(a6)+
		move.w	d3,(a6)+
		add.w	#1,d7
		dbf	d6,.nexts
.no_sprdrw:

	; Draw mappings from sprites
		lea	(RAM_ObjDispList),a5
		lea	(RAM_MdDreq+Dreq_SuperSpr),a4	; a4 - 32X SUPER Sprites
		move.w	#MAX_MDOBJ-1,d6
.next:
		move.w	(a5),d0
		beq	.finish
		moveq	#-1,d1
		move.w	d0,d1
		move.l	d1,a2
		move.l	obj_map(a2),a0		; Read mapping
		btst	#bitobj_Mars,obj_set(a2)
		bne.s	.mars_mode
		cmp.w	#70,d7
		bge	.mk_spr
		move.w	obj_frame(a2),d0
		add.w	d0,d0
		move.w	(a0,d0.w),d0
		adda	d0,a0
		move.w	(a0)+,d5
		beq	.mk_spr
		sub.w	#1,d5
.mk_pz:
	; TODO: H/V flip
		move.b	(a0)+,d0
		ext.w	d0
		add.w	obj_y(a2),d0
		add.w	#$80,d0
		move.b	(a0)+,d1
		lsl.w	#8,d1
		or.w	d7,d1
		move.w	(a0)+,d2
		add.w	obj_vram(a2),d2
		adda	#2,a0
		move.w	(a0)+,d3
		add.w	obj_x(a2),d3
		add.w	#$80,d3
		move.w	d0,(a6)+
		move.w	d1,(a6)+
		move.w	d2,(a6)+
		move.w	d3,(a6)+
		add.w	#1,d7
		dbf	d5,.mk_pz
		bra.s	.mk_spr

.mars_mode:
		move.l	(a0)+,marsspr_data(a4)
		move.w	(a0)+,marsspr_dwidth(a4)
		move.w	(a0)+,marsspr_indx(a4)
		move.b	(a0)+,d2
		move.b	(a0)+,d3
		move.b	d2,marsspr_xs(a4)
		move.b	d3,marsspr_ys(a4)
		move.w	obj_frame(a2),d0	; Read frame
		move.b	d0,marsspr_xfrm(a4)
		ror.w	#8,d0
		move.b	d0,marsspr_yfrm(a4)
		move.w	obj_x(a2),d4
		move.w	obj_y(a2),d5
		and.w	#$FF,d2
		and.w	#$FF,d3
		lsr.w	#1,d2
		lsr.w	#1,d3
; 		divu.w	#2,d2			; **
		sub.w	d2,d4
; 		divu.w	#2,d3			; **
		sub.w	d3,d5
; 		move.l	obj_size(a2),d2		; d2 - UDLR sizes
; 		move.w	d2,d3			; Grab LR
; 		lsr.w	#5,d3
; 		and.w	#%11111000,d3
; 		sub.w	d3,d4			; Subtract X
; 		swap	d2
; 		move.w	d2,d3			; Grab UD
; 		lsr.w	#8,d3
; 		lsl.b	#3,d3
; 		and.w	#$FF,d3
; 		sub.w	d3,d5			; Subtract Y
		lea	(RAM_BgBufferM),a1
		sub.w	md_bg_x(a1),d4
		sub.w	md_bg_y(a1),d5
		move.w	d4,marsspr_x(a4)
		move.w	d5,marsspr_y(a4)
		moveq	#0,d4
		btst	#bitobj_flipH,obj_set(a2)
		beq.s	.flip_h
		bset	#0,d4
.flip_h:
		btst	#bitobj_flipV,obj_set(a2)
		beq.s	.flip_v
		bset	#1,d4
.flip_v:
		move.w	d4,marsspr_flags(a4)
		adda	#sizeof_marsspr,a4	; Next SuperSprite
.mk_spr:
		clr.w	(a5)+			; Clear request
		dbf	d6,.next
.finish:
		lea	(RAM_Sprites),a6	; a6 - Genesis sprites
		move.w	d7,d6
		cmp.w	#70,d7
		bge.s	.ran_out
		sub.w	#1,d6
		lsl.w	#3,d6
		adda	d6,a6
		clr.l	(a6)			; TODO: endoflist check
.ran_out:
		rts

; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; object_Display
;
; Builds a sprite using map data specified in
; obj_map(a6)
;
; *** GENESIS map ***
; mapdata:
;       dc.w .frame0-mapdata
;       dc.w .frame1-mapdata
;       ...
; .frame0:
;       dc.w numofpz
;       dc.b YY,SS
;       dc.w vram_normal
;       dc.w vram_half
;       dc.w XXXX
;       align 2
;
; *** 32X map ***
; mapdata:
; 	dc.l SH2_ADDR|TH ; Spritesheet location (TH opt.)
; 	dc.w 512	 ; Spritesheet WIDTH
; 	dc.b 64,72	 ; Frame width and height
; 	dc.w $80	 ; Palette index
;
; obj_frame(a6) is in YYXX direction
;
; Input:
; a6 - Object
;
; Uses:
; a5,d7
; --------------------------------------------------------

object_Display:
		lea	(RAM_ObjDispList),a5
		move.w	#MAX_MDOBJ-1,d7
.srch:
		tst.w	(a5)
		beq.s	.this_one
		adda	#2,a5
		dbf	d7,.srch
.this_one:
		move.w	a6,(a5)
		rts

; --------------------------------------------------------
; object_MkSprPz
;
; Makes separate sprite pieces using
;
; Input:
; d0 - X pos
; d1 - Y pos
; d2 - VRAM
; d3 - Size
:
; Uses:
; a5,d7
; --------------------------------------------------------

object_MkSprPz:
		move.w	(RAM_SprDrwCntr).w,d7
		cmp.w	#70,d7
		bge.s	.nope
		lsl.w	#3,d7
		lea	(RAM_SprDrwPz),a5
		adda	d7,a5
		add.w	#$80,d0
		add.w	#$80,d1
		and.w	#$FF,d3
; 		lsl.w	#8,d3
		move.w	d1,(a5)+
		move.w	d3,(a5)+
		move.w	d2,(a5)+
		move.w	d0,(a5)+
		add.w	#1,(RAM_SprDrwCntr).w
.nope:
		rts

; --------------------------------------------------------
; Object_Animate
;
; Animates the sprite
;
; Input
; a0 | LONG - Animation data
;
; Output
; d0 | WORD - Frame
;
; Uses:
; d2
; --------------------------------------------------------

; NOTE: to restart an animation
; clear obj_anim_indx(a6) manually

Object_Animate:
;  		tst.l	d1
;   		beq.s	.return
 		moveq	#0,d2
 		move.b	obj_anim_id+1(a6),d2
 		cmp.b	obj_anim_id(a6),d2
 		beq.s	.sameThing
 		move.b	obj_anim_id(a6),obj_anim_id+1(a6)
 		clr.w	obj_anim_indx(a6)
 		clr.b	obj_anim_spd(a6)
.sameThing:
 		move.b	obj_anim_id(a6),d2
 		cmp.b	#-1,d2
 		beq.s	.return
 		add.w	d2,d2
 		move.w	(a0,d2.w),d2
 		lea	(a0,d2.w),a0

 		move.w	(a0)+,d2
 		cmp.w	#-1,d2
 		beq.s	.keepspd
 		sub.b	#1,obj_anim_spd(a6)
 		bpl.s	.return
		move.b	d2,obj_anim_spd(a6)
.keepspd:
 		moveq	#0,d1
 		move.w	obj_anim_indx(a6),d2
 		add.w	d2,d2
 		move.w	(a0),d1
 		adda	d2,a0
 		move.w	(a0),d0
 		cmp.w	#-1,d0
 		beq.s	.noAnim		; loop
 		cmp.w	#-2,d0
 		beq.s	.lastFrame	; finish
 		cmp.w	#-3,d0
 		beq.s	.goToFrame

 		move.w	d0,obj_frame(a6)
 		add.w	#1,obj_anim_indx(a6)
.return:
 		rts

.noAnim:
 		move.w	#1,obj_anim_indx(a6)
 		move.w	d1,d0
 		move.w	d0,obj_frame(a6)
		rts
.lastFrame:
 		clr.b	obj_anim_spd(a6)
		rts
.goToFrame:
		clr.w	obj_anim_indx(a6)
		move.w	2(a0),obj_anim_indx(a6)
		rts

; --------------------------------------------------------
; object_Speed
;
; Moves the object using speed settings
;
; Input:
; a6 - Object
;
; Uses:
; d7
; --------------------------------------------------------

object_UpdX:
		moveq	#0,d7
		move.w	obj_x_spd(a6),d7
		ext.l	d7
		asl.l	#8,d7
		add.l	d7,obj_x(a6)
		rts
object_Speed:
		bsr.s	object_UpdX
object_UpdY:
		moveq	#0,d7
		move.w	obj_y_spd(a6),d7
		ext.l	d7
		asl.l	#8,d7
		add.l	d7,obj_y(a6)
		rts

; --------------------------------------------------------
; object_ColM_Floor
;
; Check object collision on 32X map's floor
;
; Input:
; a6 - Object to check
;
; Returns:
; beq  - No collision
; bne  - Found collision
; d4.b - Collision block number
; d5.w - Y-pos center snap
;
; Uses:
; d4-d7,a4-a5
; --------------------------------------------------------

; 32X MAP SIDE

object_ColM_Floor:
		lea	(RAM_BgBufferM),a5
		moveq	#0,d5
		moveq	#0,d4
		move.l	md_bg_col(a5),a4
		move.w	md_bg_wf(a5),d7
		sub.w	#1,d7
		move.w	obj_x(a6),d4
		bpl.s	.v_x
		clr.w	d4
.v_x:
		cmp.w	d7,d4
		blt.s	.v_xr
		move.w	d7,d4
.v_xr:
		move.w	md_bg_hf(a5),d7
		sub.w	#1,d7
		move.w	obj_y(a6),d5
		bpl.s	.v_y
		clr.w	d5
.v_y:
		cmp.w	d7,d5
		blt.s	.v_yd
		move.w	d7,d5
.v_yd:
		move.l	obj_size(a6),d7
		swap	d7		; Add Y
		and.w	#$FF,d7
		move.w	d7,d6
		lsl.w	#3,d6
		add.w	d6,d5

	; d5 - Ypos + size
	; d6 - Xpos
	; d7 - Dsize/2

	; 16x16 only
		lsr.w	#1,d7		; Dsize/2
		asr.w	#4,d4		; X >> 16
		add.l	d4,a4		; Add X
		move.l	d5,d4		; Copy d5 to d4
		asr.w	#4,d4		; Y >> 16
		moveq	#0,d6
		move.w	md_bg_w(a5),d6	; d6: map width
		mulu.w	d6,d4		; (Y>>16)*(mwidth)
		add.l	d4,a4		; Add Y
		and.w	#-$10,d5	; Filter Y Snap
		move.b	(a4),d4		; d4: Start ID
		sub.l	d6,a4
		sub.w	#1,d7		; Dsize - 1
		bmi.s	.valid
.next:
		swap	d7
		move.b	(a4),d7		; New ID != 0?
		beq.s	.blnk
		move.b	d7,d4		; Set new ID
		sub.w	#$10,d5		; Decrement Y Snap
.blnk:
		sub.l	d6,a4		; Decrement width
		swap	d7
		dbf	d7,.next
.valid:
		and.w	#$FF,d4		; Filter ID
		rts

; ----------------------------------------
; object_SetColFloor
;
; Snaps the object to the map's floor.
;
; Call object_ColM_Floor first
;
; Input:
; d4.b - Collision block
; d5.w - Y-pos center snap
; ----------------------------------------

object_SetColFloor:
		and.w	#$FF,d4
		beq.s	.no_col
		lsl.w	#4,d4
		move.w	obj_x(a6),d7		; Grab CENTER X
		and.w	#$0F,d7			; limit to 16
		lea	slope_data_16(pc),a0
		adda	d4,a0
		move.b	(a0,d7.w),d4
		and.w	#$0F,d4

		moveq	#0,d6
		move.w	obj_y(a6),d7
		move.l	obj_size(a6),d6
		swap	d6
		and.w	#$FF,d6
		lsl.w	#3,d6
		sub.w	d6,d5
		add.w	d4,d5	; target slope
		cmp.w	d5,d7
		ble.s	.no_col
		move.w	#$800,d6
		move.w	d6,obj_y_spd(a6)
; .set_me:
; 		move.w	obj_x_spd(a6),d6
; 		bpl.s	.x_spd
; 		neg.w	d6
; .x_spd:

		bclr	#bitobj_air,obj_status(a6)
		move.w	d5,obj_y(a6)
.no_col:
		rts

; ----------------------------------------

; Slope data 16x16
slope_data_16:
		dc.b  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		dc.b  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		dc.b  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
		dc.b 15,14,13,12,11,10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0
		dc.b  0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15
		dc.b 15,15,14,14,13,13,12,12,11,11,10,10, 9, 9, 8, 8
		dc.b  7, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1, 1, 0, 0
		dc.b  0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7
		dc.b  8, 8, 9, 9,10,10,11,11,12,12,13,13,14,14,15,15
		align 2
