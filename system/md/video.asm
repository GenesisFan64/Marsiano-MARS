; ====================================================================
; ----------------------------------------------------------------
; MD Video
; ----------------------------------------------------------------

; ------------------------------------------------
; vdp_ctrl READ bits
; ------------------------------------------------

bitHint		equ 2
bitVint		equ 3
bitDma		equ 1

; ------------------------------------------------
; VDP register variables
; ------------------------------------------------

; Register $80
HVStop		equ $02
HintEnbl	equ $10
bitHVStop	equ 1
bitHintEnbl	equ 4

; Register $81
DispEnbl 	equ $40
VintEnbl 	equ $20
DmaEnbl		equ $10
bitDispEnbl	equ 6
bitVintEnbl	equ 5
bitDmaEnbl	equ 4
bitV30		equ 3

; --------------------------------------------------------
; Init Video
; 
; Uses:
; a0-a2,d0-d1
; --------------------------------------------------------

Video_Init:		
		lea	(RAM_MdVideo),a6	; Clear RAM
		moveq	#0,d6
		move.w	#(sizeof_mdvid-RAM_MdVideo)-1,d7
.clrram:
		move.b	d6,(a6)+
		dbf	d7,.clrram
		lea	list_vdpregs(pc),a6	; Init registers
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
		rts

; ====================================================================
; ----------------------------------------------------------------
; Video subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Video_Clear
; 
; Clear all video data from VRAM
; --------------------------------------------------------

Video_Clear:
		move.w	#0,d0			; Clears until $57F
		move.w	#0,d1
		move.w	#$57F*$20,d2
		bsr	Video_Fill

		move.w	#$FFF,d2		; FG/BG size
		move.b	(RAM_VdpRegs+2).l,d1	; FG
		andi.w	#%111000,d1
		lsl.w	#8,d1
		lsl.w	#2,d1
		bsr	Video_Fill
		move.b	(RAM_VdpRegs+3).l,d1	; BG
		andi.w	#%000111,d1
		lsl.w	#8,d1
		lsl.w	#5,d1
		bsr	Video_Fill

		move.w	#$FFF,d2		; WD Size
		move.b	(RAM_VdpRegs+4).l,d1	; Window
		andi.w	#%111110,d1
		lsl.w	#8,d1
		lsl.w	#2,d1
		bra	Video_Fill
		
; ---------------------------------
; Video_Update
; 
; Sends register data specified
; in RAM to VDP
; from regs $80 to $90
; 
; Uses:
; d6-d7,a5-a6
; ---------------------------------

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
; Video_LoadPal
; Load palette to VDP directly
; 
; Input:
; a0 - Palette data
; d0 - Start position
; d1 - Number of colors
; 
; Uses:
; d5-d7,a6
; 
; Note:
; It waits for VBlank so the CRAM dots doesn't get
; in the middle of the screen.
; --------------------------------------------------------

Video_LoadPal:
		lea	(vdp_data),a6
		moveq	#0,d7
		move.w	d0,d7
		add.w	d7,d7
		ori.w	#$C000,d7
		swap	d7
		move.l	d7,4(a6)
		move.w	d1,d7
.outv: 		move.w	4(a6),d6
		btst	#bitVint,d6
		beq.s	.outv
.loop:
		move.w	(a0)+,(a6)
		dbf	d7,.loop
		rts
		
; --------------------------------------------------------
; Video_LoadMap
; 
; Load map data, Horizontal order
; 
; a0 - Map data
; d0 | LONG - 00|Layer|X|Y, locate(lyr,x,y)  
; d1 | LONG - Width|Height (cells),  mapsize(x,y)
; d2 | WORD - VRAM
;
; Can autodetect layer size setting
;
; Uses:
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
		cmp.w	#-1,d5
		bne.s	.nonull
		move.w	#varNullVram,d5
		bra.s	.cont
.nonull:
		add.w	d2,d5
.cont:
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

; ; --------------------------------------------------------
; ; Video_LoadMap_Vert
; ;
; ; Load map data, Vertical order
; ;
; ; a0 - Map data
; ; d0 | LONG - 00|Lyr|X|Y,  locate(lyr,x,y)
; ; d1 | LONG - Width|Height (cells),  mapsize(x,y)
; ; d2 | WORD - VRAM
;
; ; Uses:
; ; a4-a5,d4-d7
; ; --------------------------------------------------------
;
; Video_LoadMap_Vert:
; 		lea	(vdp_data),a4
; 		bsr	vid_PickLayer
; 		move.l	d1,d5		; Start here
; 		swap	d5
; .xloop:
; 		swap	d5
; 		move.l	d4,-(sp)
; 		move.w	d1,d7
; 		btst	#2,(RAM_VdpRegs+$C).l
; 		beq.s	.yloop
; 		lsr.w	#1,d7
; .yloop:
; 		move.l	d4,4(a4)
; 		move.w	(a0),d5
; 		cmp.w	#-1,d5
; 		bne.s	.nonull
; 		move.w	#varNullVram,d5
; 		bra.s	.cont
; .nonull:
; 		add.w	d2,d5
; .cont:
; 		swap	d7
; 		adda	#2,a0
; 		btst	#2,(RAM_VdpRegs+$C).l
; 		beq.s	.nodble
; 		adda	#2,a0
; 		move.w	d5,d7
; 		lsr.w	#1,d7
; 		and.w	#$7FF,d7
; 		and.w	#$F800,d5
; 		or.w	d7,d5
; .nodble:
; 		swap	d7
; 		move.w	d5,(a4)
; 		add.l	d6,d4
; 		dbf	d7,.yloop
; .outdbl:
; 		move.l	(sp)+,d4
; 		add.l	#$20000,d4
; 		swap	d5
; 		dbf	d5,.xloop
; 		rts
		
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
; ; Uses:
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

; --------------------------------------------------------
; Video_PrintInit
; 
; Load palette and font for printing text
; --------------------------------------------------------

Video_PrintInit:
		lea	ASCII_PAL(pc),a0
		moveq	#$30,d0
		move.w	#$F,d1
		bsr	Video_LoadPal
		move.l	#ASCII_FONT,d0
		move.w	#$580*$20,d1
		move.w	#ASCII_FONT_e-ASCII_FONT,d2
		move.w	#$580|$6000,d3
		move.w	d3,(RAM_VidPrntVram).w
		bra	Video_LoadArt

; --------------------------------------------------------
; Video_Print
;
; Prints string to layer
; requires ASCII font
; 
; a0 - string data + RAM address to peek (optional)
; d0 | LONG - 00|Lyr|X|Y, locate(lyr,x,y)
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
; CALL Video_PrintInit ONCE to use this feature.
;
; Uses:
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
		move.w	#"\\",d7			; nothing to do
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

; --------------------------------------------------------
; Print values
; 
; vvvv vvvv tttt
; v - vdp pos
; t - value type
; --------------------------------------------------------

; reading byte by byte because longs doens't get
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
		
; --------------------------------------------------------
; Video_Fill
; 
; Fill data to VRAM
;
; d0 | WORD - Bytes to fill
; d1 | WORD - VRAM position
; d2 | WORD - Size
;
; Uses:
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
		move.l	#$94009300,d6
		lsr.w	#1,d7
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
; Uses:
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
		lsr.w	#1,d7
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

; ====================================================================
; --------------------------------------------------------
; DMA ROM to VDP Transfer, sets RV=1
; --------------------------------------------------------

; --------------------------------------------------------
; Video_DmaBlast
;
; Process DMA tasks from a predefined list in RAM
; **CALL THIS DURING VBLANK ONLY**
;
; Uses:
; d5-d7,a3-a6
; --------------------------------------------------------

; Entry format:
; $94xx,$93xx,$95xx,$96xx,$97xx (SIZE,SOURCE)
; $40000080 (vdp destination + dma bit)

Video_DmaBlast:
		lea	(vdp_ctrl),a4
		lea	(RAM_VdpDmaList).w,a3
		move.w	#$8100,d7			; DMA ON
		move.b	(RAM_VdpRegs+1),d7
		bset	#bitDmaEnbl,d7
		move.w	d7,(a4)
		bsr	Sound_DMA_Pause			; Request Z80 stop and SH2 backup
		move.w	(sysmars_reg+dreqctl).l,d7	; Set RV=1
		or.w	#%00000001,d7
		move.w	d7,(sysmars_reg+dreqctl).l

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
; 		bsr	Sound_DMA_Pause
; 		move.w	(sysmars_reg+dreqctl).l,d7	; Set RV=1
; 		or.w	#%00000001,d7			; 68k ROM map moves to $000000, $880000/$900000=trash
; 		move.w	d7,(sysmars_reg+dreqctl).l
		move.w	d6,(a4)
		move.w	d5,(a4)
; 		move.w	(sysmars_reg+dreqctl).l,d7	; Set RV=0
; 		and.w	#%11111110,d7
; 		move.w	d7,(sysmars_reg+dreqctl).l
; 		bsr	Sound_DMA_Resume
		sub.w	#7*2,(RAM_VdpDmaIndx).w
		bra.s	.next
.end:
		move.w	(sysmars_reg+dreqctl).l,d7	; Set RV=0
		and.w	#%11111110,d7
		move.w	d7,(sysmars_reg+dreqctl).l
		bsr	Sound_DMA_Resume		; Resume Z80 and SH2 direct
		move.w	#$8100,d7			; DMA OFF
		move.b	(RAM_VdpRegs+1).w,d7
		move.w	d7,(a4)
		rts

; --------------------------------------------------------
; Sets a new DMA transfer task to the Blast list
;
; *** ONLY CALL THIS OUTSIDE OF VBLANK ***
;
; d0 | LONG - Art data
; d1 | WORD - VRAM location
; d2 | WORD - Size
;
; Uses:
; d6-d7,a6
; --------------------------------------------------------

Video_DmaSet:
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
		rts

; --------------------------------------------------------
; Load graphics using DMA, direct
;
; d0 | LONG - Art data
; d1 | WORD - VRAM location
; d2 | WORD - Size
;
; *** For faster transfers wait for VBlank first ***
;
; Uses:
; d5-d7,a4-a6
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
; 		and.w	#$7FF,d6
; 		lsl.w	#5,d6
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
		bsr	Sound_DMA_Pause
		move.w	(sysmars_reg+dreqctl).l,d7	; Set RV=1
		or.w	#%00000001,d7			; 68k ROM map moves to $000000, $880000/$900000=trash
		move.w	d7,(sysmars_reg+dreqctl).l
 		move.w	d5,-(sp)
		move.w	d6,(a4)				; d6 - First word
		move.w	(sp)+,(a4)			; *** Second write, CPU freezes until it DMA ends
		move.w	(sysmars_reg+dreqctl).l,d6	; Set RV=0
		and.w	#%11111110,d6			; 68k ROM map returns to $880000/$900000
		move.w	d6,(sysmars_reg+dreqctl).l
		move.w	#$8100,d6			; DMA OFF
		move.b	(RAM_VdpRegs+1),d6
		move.w	d6,(a4)
		move.w	(sp)+,sr
		bra	Sound_DMA_Resume

; TODO: check if Source RAM transfers are safe without turining off Z80
.from_ram:
		move.w	d4,(a4)
 		move.w	d5,-(sp)
		move.w	(sp)+,(a4)			; Second write
		move.w	#$8100,d4
		move.b	(RAM_VdpRegs+1),d4
		move.w	d4,(a4)
		move.w	(sp)+,sr
		rts

; ====================================================================
; --------------------------------------------------------
; Video data
; --------------------------------------------------------

list_vdpregs:
		dc.b $04			; HBlank int off, HV Counter on
		dc.b $44			; Display ON, VBlank int off
		dc.b (($C000)>>10)		; ForeGrd at VRAM $C000 (%00xxx000)
		dc.b (($D000)>>10)		; Window  at VRAM $D000 (%00xxxxy0)
		dc.b (($E000)>>13)		; BackGrd at VRAM $E000 (%00000xxx)
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
		dc.b $02			; VDP Auto increment by $02
		dc.b (%00<<4)|%01		; Layer size: V32 H64
		dc.b $00
		dc.b $00
		align 2
ASCII_PAL:	dc.w $0000,$0EEE,$0CCC,$0AAA,$0888,$0444,$000E,$0008
		dc.w $00EE,$0088,$00E0,$0080,$0E00,$0800,$0000,$0000
ASCII_PAL_e:
ASCII_FONT:	binclude "system/md/data/font.bin"
ASCII_FONT_e:
		align 2
