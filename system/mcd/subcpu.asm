; ====================================================================
; ----------------------------------------------------------------
; SegaCD SUB-CPU code
; ----------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; Includes for this section ONLY
; ----------------------------------------------------------------

scpu_wram	equ	$80000
scpu_reg	equ	$FFFF8000

; ====================================================================
; ----------------------------------------------------------------
; Includes
; ----------------------------------------------------------------

; 		include "system/mcd/const.asm"
		include "system/mcd/cdbios.asm"
		
; ====================================================================
; ----------------------------------------------------------------
; MAIN CODE
; ----------------------------------------------------------------

		phase $6000
		dc.b "MAIN-BOOT  ",0
		dc.w 0,0
		dc.l 0
		dc.l 0
		dc.l $20
		dc.l 0
.table:
		dc.w SP_Init-.table
		dc.w SP_Main-.table
		dc.w SP_IRQ-.table
		dc.w 0

; ====================================================================
; ----------------------------------------------------------------
; Init
; ----------------------------------------------------------------

SP_Init:
; 		move.w	#$2700,sr
		move.b	(scpu_reg+mcd_memory).l,d0
		bclr	#bitWRamMode,d0
		move.b	d0,(scpu_reg+mcd_memory).l
		bsr	SP_InitISO
		move.b	#0,(scpu_reg+mcd_comm_s).w	; Reset SUB-status

; 		lea	(PCM),a0
; 		move.b	#$80,d3
; 		moveq	#$F,d5
; @Next:
; 		move.b	d3,Ctrl(a0)
; 		bsr	PCM_Wait
; 		lea	($FF2001),a2
; 		move.w	#$FFF,d0
; @loop1:
; 		move.b	#$FF,(a2)
; 		addq.l	#2,a2
; 		dbf	d0,@loop1
; 		move.b	d3,Ctrl(a0)
; 		bsr	PCM_Wait
; 		add.b	#1,d3
; 		dbf	d5,@Next


; 		BSET	#1,$FF8033
; 		BSET	#2,$FF8033
; 		BCLR	#3,$FF8033

	; SCD32X:
	;
	; Load the SH2 code from DISC to WORD-RAM
	;
	; TODO: I hope SUB has WRAM permission...
	; I don't have a SCD to test this.
	if MARSCD
		lea	fname_mars(pc),a0
		bsr	SP_FindFile
		move.w	#$800,d2
		subq.w	#1,d1
		lea	(scpu_wram),a0
		bsr	SP_IsoReadN
	endif
		rts
	if MARSCD
fname_mars:	dc.b "MARSCODE.BIN",0
		align 2
	endif

; ====================================================================
; ----------------------------------------------------------------
; Main
;
; mcd_comm_m COMMAND READ ONLY:
; %lp0iiiii
;
; mcd_comm_s STATUS READ/WRITE:
; %bp000000
;
; DONT USE BSET/BCLR/BTST or CLR DIRECTLY
; TO THE PORTS
;
; a6 - comm data MAIN (READ ONLY)
; a5 - comm data SUB (READ/WRITE)
; ----------------------------------------------------------------

SP_Main:
		lea	(scpu_reg+mcd_dcomm_m),a6
		lea	(scpu_reg+mcd_dcomm_s),a5
.wait_main:
		move.w	$E(a5),d7
		addq.w	#1,d7
		move.w	d7,$E(a5)
		move.b	(scpu_reg+mcd_comm_m).w,d0	; d7
		andi.w	#%11111,d0			; <-- current limit
		beq.s	.wait_main
		move.b	(scpu_reg+mcd_comm_s).w,d7
		bset	#7,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w	; Set as BUSY
		add.w	d0,d0				; * 2
		move.w	SP_cmdlist(pc,d0.w),d1
		jsr	SP_cmdlist(pc,d1.w)
		move.b	(scpu_reg+mcd_comm_s).w,d7
		bclr	#7,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w	; Remove BUSY bit, finished
		bra.s	SP_Main
		
; =====================================================================
; ----------------------------------------------------------------
; Level 2 IRQ
; ----------------------------------------------------------------

SP_IRQ:
		rts

; =====================================================================
; ----------------------------------------------------------------
; Commands list
; ----------------------------------------------------------------

SP_cmdlist:
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd01-SP_cmdlist
		dc.w SP_cmnd02-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist

		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist
		dc.w SP_cmnd00-SP_cmdlist

		dc.w SP_cmnd10-SP_cmdlist

; --------------------------------------------------------
; NULL COMMAND
; --------------------------------------------------------

SP_cmnd00:
		rts

; --------------------------------------------------------
; Command $01
;
; Read data from disc and transfer through
; dcomm_s as packets of $10 bytes
;
; mcd_comm_m: %lp------
; l - Lock bit, unlocking breaks data-loop.
; p - MAIN response bit
;
; mcd_comm_s: %-p------
; p - PASS bit
;
; mcd_dcomm_m:
; dc.b "FILENAME.BIN",0
;
; mcd_dcomm_s:
; packed data, all bytes used.
; --------------------------------------------------------

SP_cmnd01:
		move.l	a6,a0			; a0 - filename
		bsr	SP_FindFile
		move.w	#$800,d2
		addq.w	#1,d1			; TODO: check if 0 counts
		lea	(ISO_Output),a0
		bsr	SP_IsoReadN
		lea	(ISO_Output),a0
.next_packet:
		move.l	a5,a1
		move.w	(a0)+,(a1)+	; WORD writes to be safe...
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.w	(a0)+,(a1)+
		move.b	(scpu_reg+mcd_comm_s).w,d7	; PASS bit
		bset	#6,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w
.wait_main:	move.b	(scpu_reg+mcd_comm_m).w,d7	; MAIN got data?
		btst	#7,d7				; Unlocked?
		beq.s	.exit_now
		btst	#6,d7				; MAIN got the data?
		beq.s	.wait_main
		move.b	(scpu_reg+mcd_comm_s).w,d7	; Clear PASS
		bclr	#6,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w
.wait_main_o:	move.b	(scpu_reg+mcd_comm_m).w,d7	; Wait MAIN response.
		btst	#6,d7
		bne.s	.wait_main_o
		bra.s	.next_packet
.exit_now:	move.b	(scpu_reg+mcd_comm_s).w,d7	; Clear PASS
		bclr	#6,d7
		move.b	d7,(scpu_reg+mcd_comm_s).w
		rts

; --------------------------------------------------------
; Command $02
;
; Read data from disc and sends it to WORD-RAM
;
; mcd_dcomm_m:
; dc.b "FILENAME.BIN",0
; --------------------------------------------------------

SP_cmnd02:
		move.l	a6,a0				; a0 - filename
		bsr	SP_FindFile
		move.w	#$800,d2
		addq.w	#1,d1				; TODO: check if 0 counts
		lea	(scpu_wram),a0
		bsr	SP_IsoReadN
		move.b	(scpu_reg+mcd_memory).l,d0	; Return WORDRAM to MAIN, RET=1
		bset	#0,d0
		move.b	d0,(scpu_reg+mcd_memory).l
		rts


SP_cmnd10:
; 		movea.l	a6,a0
		lea	.this(pc),a0
		BIOS_MSCPLAYR
		rts

		align 2
.this:		dc.w 2

; =====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; CD-ROM data
; --------------------------------------------------------

; ------------------------------------------------
; SP_IsoReadN
;
; Input:
; a0 - Destination
; d0 - Sector start
; d1 - Number of sectors
; d2 - Destination increment ($0 or $800)
; ------------------------------------------------

SP_IsoReadN:
		movem.l	d3-d6,-(sp)
		andi.l	#$FFFF,d0
		andi.l	#$FFFF,d1
		move.l	d0,(Sub_BiosArgs)
		move.l	d1,(Sub_BiosArgs+4)
		movea.l	a0,a2
		BIOS_CDCSTOP			; Stop disc
		lea	(Sub_BiosArgs),a0
		BIOS_ROMREADN			; Start from this sector
.waitSTAT:
 		BIOS_CDCSTAT			; Ready?
 		bcs.s	.waitSTAT
.waitREAD:
		BIOS_CDCREAD			; Read data
		bcc.s	.waitREAD		; If not done, branch
.WaitTransfer:
		movea.l	a2,a0			; Set destination address
		lea	(Sub_BiosArgs+$10),a1	; Set head buffer
		BIOS_CDCTRN			; Transfer sector
		bcc.s	.waitTransfer		; If not done, branch
		BIOS_CDCACK			; Acknowledge transfer
		adda	d2,a2
		add.l	#1,(Sub_BiosArgs)
		sub.l	#1,(Sub_BiosArgs+4)
		bne.s	.waitSTAT
		movem.l	(sp)+,d3-d6
		rts

; ------------------------------------------------
; ISO9660 Driver
; ------------------------------------------------

SP_InitISO:
		movem.l	d0-d7/a0-a6,-(a7)
	; Load Volume VolumeDescriptor
		moveq	#$10,d0			; Start Sector (at $8000)
		moveq	#$10,d1			; Sector size
		move.w	#$800,d2
		lea	(ISO_Files),a0		; Destination
		bsr	SP_IsoReadN
	; Load Root Directory
		lea	(ISO_Files),a0		; Get pointer to sector buffer
		lea.l	$9C(a0),a1		; Get root directory record
		move.b	6(a1),d0		; Get first part of Sector address
		lsl.l	#8,d0			; bitshift
		move.b	7(a1),d0		; Get next part of sector address
		lsl.l	#8,d0			; bitshift
		move.b	8(a1),d0		; get next part of sector address
		lsl.l	#8,d0			; bitshift
		move.b	9(a1),d0		; get final part of sector address.
	; d0 now contains start sector address
		moveq	#$20,d1			; Size ($20 Sectors)
		move.w	#$800,d2
		bsr	SP_IsoReadN
		movem.l	(a7)+,d0-d7/a0-a6	; Restore all registers
		rts

; ------------------------------------------------
;  Find File (ISO9660)
;  Input:  a0.l - Pointer to filename
;  Output: d0.l - Start sector
;	   d1.l - Number of sectors
;          d2.l - Filesize
; ------------------------------------------------

SP_FindFile:
		movem.l	a1/a2/a6,-(a7)
		lea	(ISO_Files),a1		; Get sector buffer
.next_file:
		movea.l	a0,a6			; Store filename pointer
		move.b	(a6)+,d0		; Read character from filename
.findFirstChar:
		movea.l	a1,a2			; Store Sector buffer pointer
		cmp.b	(a1)+,d0		; Compare with first letter of filename and increment
		bne.b	.findFirstChar		; If not matched, branch
.checkChars:
		move.b	(a6)+,d0		; Read next charactor of filename and increment
		beq.s	.getInfo		; If all characters were matched, branch
		cmp.b	(a1)+,d0		; Else, check next character
		bne.b	.next_file		; If not matched, find next file
		bra.s	.checkChars		; else, check next character
.getInfo:
		sub.l	#$21,a2			; Move to beginning of directory entry
		move.b	6(a2),d0		; Get first part of Sector address
		lsl.l	#8,d0			; bitshift
		move.b	7(a2),d0		; Get next part of sector address
		lsl.l	#8,d0			; bitshift
		move.b	8(a2),d0		; get next part of sector address
		lsl.l	#8,d0			; bitshift
		move.b	9(a2),d0		; get final part of sector address.
						; d0 now contains start sector address
		move.b	$E(a2),d1		; Same as above, but for FileSize
		lsl.l	#8,d1
		move.b	$F(a2),d1
		lsl.l	#8,d1
		move.b	$10(a2),d1
		lsl.l	#8,d1
		move.b	$11(a2),d1
		move.l	d1,d2
		lsr.l	#8,d1			; Bitshift filesize (to get sector count)
		lsr.l	#3,d1
		movem.l	(a7)+,a1/a2/a6		; Restore used registers
		rts

; --------------------------------------------------------
; PCM sound
; --------------------------------------------------------

; -------------------------------------------
; PCM_Wait
; -------------------------------------------

PCM_Wait:
		movem.l	d0,-(sp)
		move.w	#6,d0
.WaitLoop:
		dbf	d0,.WaitLoop
		movem.l	(sp)+,d0
		rts  

; ====================================================================
; ----------------------------------------------------------------
; RAM
; ----------------------------------------------------------------

		align $100
SP_RAM:
		struct SP_RAM
Sub_BiosArgs:	ds.l $40
Sub_BiosOut:	ds.l $40
ISO_Files:	ds.b $800*$10
ISO_Output:	ds.b $800*$10
		endstruct
		dephase
