; ====================================================================
; ----------------------------------------------------------------
; MD Sound
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init Sound
; 
; Uses:
; a0-a1,d0-d1
; --------------------------------------------------------

; 		align $100				; (GENS emulator only)
Sound_Init:
		move.w	#$0100,(z80_bus).l		; Stop Z80
		move.b	#1,(z80_reset).l		; Reset
.wait:
		btst	#0,(z80_bus).l
		bne.s	.wait
		lea	(z80_cpu).l,a0
		move.w	#$1FFF,d0
		moveq	#0,d1
.cleanup:
		move.b	d1,(a0)+
		dbf	d0,.cleanup
		lea	(Z80_CODE|$880000).l,a0		; a0 - Z80 code (on $880000 area)
		lea	(z80_cpu).l,a1			; a1 - Z80 area
		move.w	#(Z80_CODE_END-Z80_CODE)-1,d0	; d0 - Size
.copy:
		move.b	(a0)+,(a1)+
		dbf	d0,.copy
		move.b	#1,(z80_reset).l		; Reset
		nop 
		nop 
		nop 
		move.w	#0,(z80_bus).l
		rts

; ; --------------------------------------------------------
; ; Routine to check if Z80 wants something from here
; ;
; ; Call this on VBlank only.
; ; --------------------------------------------------------
;
; Sound_Update:
; 		rts

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Sound_DMA_Pause
; 
; Call this before doing any DMA task
; --------------------------------------------------------

Sound_DMA_Pause:
		move.w	sr,-(sp)
		or.w	#$700,sr
.retry:
		move.w	#$0100,(z80_bus).l		; Stop Z80
.wait:
		btst	#0,(z80_bus).l			; Wait for it
		bne.s	.wait
		move.b	(z80_cpu+commZRomRd),d7		; Get mid-read bit
		move.w	#0,(z80_bus).l			; Resume Z80
		tst.b	d7
		beq.s	.safe
		moveq	#68,d7
		dbf	d7,*
		bra.s	.retry
.safe:
		move.b	#1,(z80_cpu+commZRomBlk)	; Block flag for Z80
		move.w	(sp)+,sr
		rts

; --------------------------------------------------------
; Sound_DMA_Resume
; 
; Call this after finishing DMA
; --------------------------------------------------------

Sound_DMA_Resume:
		move.w	sr,-(sp)
		or.w	#$700,sr
		bsr	sndLockZ80
		move.b	#0,(z80_cpu+commZRomBlk)
		bsr	sndUnlockZ80
		move.w	(sp)+,sr
		rts

; --------------------------------------------------------
; Sound_Request_Word
; 
; d0    - request id
; d1    - argument
; --------------------------------------------------------

Sound_Request:
		bsr	sndReq_Enter
		move.w	d0,d7
		bsr	sndReq_scmd
		move.l	d1,d7
		bsr	sndReq_sword
		bra 	sndReq_Exit

; --------------------------------------------------------
; SoundReq_SetTrack
; 
; d0 - Pattern data pointer
; d1 - Block data pointer
; d2 - Instrument data pointer
; d3 - Ticks (Tempo is set separately)
; d4 - Slot (0-2)
; --------------------------------------------------------

SoundReq_SetTrack:
		bsr	sndReq_Enter
		move.w	#$00,d7			; Command $00
		bsr	sndReq_scmd
		move.b	d4,d7			; d4 - Slot
		bsr	sndReq_sbyte
		move.b	d3,d7			; d3 - Ticks
		bsr	sndReq_sbyte
		move.l	d0,d7			; d0 - Patt data point
		bsr	sndReq_saddr
		move.l	d1,d7			; d1 - Block data point
		bsr	sndReq_saddr
		move.l	d2,d7			; d2 - Intrument data
		bsr	sndReq_saddr
		bra 	sndReq_Exit
		
; --------------------------------------------------------
; SoundReq_SetSample
; 
; d0 - Sample pointer
; d1 - length
; d2 - loop point
; d3 - Pitch ($01.00)
; d4 - Flags (%00l l-loop enable)
; --------------------------------------------------------

SoundReq_SetSample:
		bsr	sndReq_Enter
		move.w	#$21,d7			; Command $21
		bsr	sndReq_scmd
		move.l	d0,d7
		bsr	sndReq_saddr
		move.l	d1,d7
		bsr	sndReq_saddr
		move.l	d2,d7
		bsr	sndReq_saddr
		move.l	d3,d7
		bsr	sndReq_sword
		move.l	d4,d7
		bsr	sndReq_sbyte
		bra 	sndReq_Exit

; ------------------------------------------------
; Lock Z80, get bus
; ------------------------------------------------

sndLockZ80:
		move.w	#$0100,(z80_bus).l		; Stop Z80
.wait:
		btst	#0,(z80_bus).l			; Wait for it
		bne.s	.wait
		rts
		
; ------------------------------------------------
; Unlock Z80, return bus
; ------------------------------------------------

sndUnlockZ80:
		move.w	#0,(z80_bus).l
		rts
sndSendCmd:
		rts

; ------------------------------------------------
; 68k-to-z80 Sound request
; enter/exit routines
; ------------------------------------------------

sndReq_Enter:
		movem.l	d6-d7/a5-a6,(RAM_SndSaveReg).l
		moveq	#0,d6
		move.w	sr,d6
		swap	d6
		move.w	#$0100,(z80_bus).l		; Stop Z80
		or.w	#$0700,sr			; disable ints
		lea	(z80_cpu+commZWrite),a5		; a5 - commZWrite
		lea	(z80_cpu+commZfifo),a6		; a6 - fifo command list
.wait:
		btst	#0,(z80_bus).l			; Wait for Z80
		bne.s	.wait
		move.b	(a5),d6				; d6 - index fifo position
		ext.w	d6				; extend to 16 bits
		rts
; JUMP ONLY
sndReq_Exit:
		move.w	#0,(z80_bus).l
		swap	d6
		move.w	d6,sr
		movem.l	(RAM_SndSaveReg).l,d6-d7/a5-a6
		rts
		
; ------------------------------------------------
; Send request id and arguments
;
; Input:
; d7 - byte to write
; d6 - index pointer
; a5 - commZWrite, update index
; a6 - commZfifo command list
; 
; *** CALL sndReq_Enter FIRST ***
; ------------------------------------------------

sndReq_scmd:
		move.b	#-1,(a6,d6.w)			; write command-start flag
		addq.b	#1,d6				; next fifo pos
		andi.b	#$3F,d6
		bra.s	sndReq_sbyte
sndReq_slong:
		bsr	sndReq_sbyte
		ror.l	#8,d7
sndReq_saddr:
		bsr	sndReq_sbyte
		ror.l	#8,d7
sndReq_sword:
		bsr	sndReq_sbyte
		ror.l	#8,d7
sndReq_sbyte:
		move.b	d7,(a6,d6.w)			; write byte
		addq.b	#1,d6				; next fifo pos
		andi.b	#$3F,d6
		move.b	d6,(a5)				; update commZWrite
		rts
