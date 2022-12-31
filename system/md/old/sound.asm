; ====================================================================
; ----------------------------------------------------------------
; Genesis sound (GEMA Sound driver)
; ----------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; Sound 68k RAM
; ----------------------------------------------------------------

		struct RAM_MdSound
RAM_SndSaveReg	ds.l 8			; Backup registers
sizeof_mdsnd	ds.l 0
		finish

; ====================================================================
; --------------------------------------------------------
; Initialize Sound
;
; Uses:
; a0-a1,d0-d1
; --------------------------------------------------------

		align $80
Sound_Init:
		move.w	#$2700,sr
		move.w	#$0100,(z80_bus).l		; Get Z80 bus
		move.w	#$0100,(z80_reset).l		; Z80 reset
.wait:
		btst	#0,(z80_bus).l
		bne.s	.wait
		lea	(z80_cpu).l,a0			; Clean entire Z80 area first
		move.w	#$1FFF,d0
		moveq	#0,d1
.cleanup:
		move.b	d1,(a0)+
		dbf	d0,.cleanup
		lea	(Z80_CODE).l,a0			; a0 - Z80 code (on $880000)
		lea	(z80_cpu).l,a1			; a1 - Z80 CPU area
		move.w	#(Z80_CODE_END-Z80_CODE)-1,d0	; d0 - Size
.copy:
		move.b	(a0)+,(a1)+
		dbf	d0,.copy
		move.w	#0,(z80_reset).l		; Reset cancel
		nop
		nop
		nop
		nop
		move.w	#$100,(z80_reset).l
		move.w	#0,(z80_bus).l			; Start Z80
		rts

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; ------------------------------------------------
; Lock Z80, get bus
; ------------------------------------------------

sndLockZ80:
		move.w	#$0100,(z80_bus).l
.wait:
		btst	#0,(z80_bus).l
		bne.s	.wait
		rts

; ------------------------------------------------
; Unlock Z80, return bus
; ------------------------------------------------

sndUnlockZ80:
		move.w	#0,(z80_bus).l
		rts

; ------------------------------------------------
; 68k-to-z80 Sound request
; enter/exit routines
;
; d6 - commFifo index
; ------------------------------------------------

sndReq_Enter:
		movem.l	d6-d7/a5-a6,(RAM_SndSaveReg).l	; <-- stack didn't work this time
		moveq	#0,d6
		move.w	#$0100,(z80_bus).l		; Request Z80 Stop
		move.w	sr,d6
		swap	d6
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

; ------------------------------------------------
; Make CMD request
;
; d6 - command
; ------------------------------------------------

sndReqCmd:
.wait_in:	move.b	(sysmars_reg+comm14),d7
		and.w	#%11110000,d7
		bne.s	.wait_in
		and.w	#%00001111,d6
		or.b	d6,d7
		move.b	d7,(sysmars_reg+comm14).l
		move.b	(sysmars_reg+comm14).l,d7
		and.w	#%00001111,d7
		cmp.b	d6,d7
		bne.s	.wait_in
		bset	#7,(sysmars_reg+comm14).l
		bset	#1,(sysmars_reg+standby).l	; Request Slave CMD
; .wait_cmd:	btst	#1,(sysmars_reg+standby).l
; 		bne.s	.wait_cmd
.wait_out:	move.b	(sysmars_reg+comm14),d7
		and.w	#%11110000,d7
		bne.s	.wait_out
		rts

; --------------------------------------------------------
; Sound_DMA_Pause
;
; Call this BEFORE making any DMA task
;
; Uses:
; d6,d7
; --------------------------------------------------------

Sound_DMA_Pause:
		swap	d7
		swap	d6
.retry:
		bsr	sndLockZ80
		move.b	(z80_cpu+commZRomRd),d7		; Get mid-read bit
		bsr	sndUnlockZ80
		tst.b	d7
		beq.s	.safe
		moveq	#68,d7
		dbf	d7,*
		bra.s	.retry
.safe:
		bsr	sndLockZ80
		move.b	#1,(z80_cpu+commZRomBlk)	; Block flag for Z80
		bsr	sndUnlockZ80
		move.w	#2,d6
		bsr	sndReqCmd
		swap	d6
		swap	d7
		rts

; --------------------------------------------------------
; Sound_DMA_Resume
;
; Call this AFTER finishing DMA
; --------------------------------------------------------

Sound_DMA_Resume:
		swap	d7
		swap	d6
		bsr	sndLockZ80
		move.b	#0,(z80_cpu+commZRomBlk)
		bsr	sndUnlockZ80
		move.w	#3,d6
		bsr	sndReqCmd
		swap	d6
		swap	d7
		rts

; --------------------------------------------------------
; SoundReq_SetTrack
;
; a0 | Pointer to Pattern, Blocks and Instruments list
;      in this order:
;  	dc.l pattern_data
;  	dc.l block_data
;  	dc.l instrument_data
;  	(Pointers should be in the
;  	$880000/$900000 areas)
;
; d0 | BYTE - Track slot
; d1 | BYTE - Ticks
; d2 | BYTE - Start from this block position
; d3 | BYTE - Flags: %00004321
; 	      4321 - Use global tempos: 1,2,3 or 4
;
; Breaks:
; d6-d7,a5-a6
; --------------------------------------------------------

; ***
Sound_TrkPlay:
		bsr	sndReq_Enter
		move.w	#$00,d7		; Command $00
		bsr	sndReq_scmd
		move.b	d0,d7		; d0 - Slot
		bsr	sndReq_sbyte
		move.b	d1,d7		; d1 - Ticks
		bsr	sndReq_sbyte
		move.b	d2,d7		; d2 - Start block
		bsr	sndReq_sbyte
		move.b	d3,d7		; d3 - Flags (%321 enable these timers)
		and.w	#%111,d7
		bsr	sndReq_sbyte
		move.l	(a0)+,d7	; Patt data point
		bsr	sndReq_saddr
		move.l	(a0)+,d7	; Block data point
		bsr	sndReq_saddr
		move.l	(a0)+,d7	; Intrument data
		bsr	sndReq_saddr
		bra 	sndReq_Exit

; --------------------------------------------------------
; Sound_TrkStop (and pause)
;
; Stops OR Pauses current track
;
; Input:
; d0 | BYTE - Track slot
;
; Breaks:
; d6-d7,a5-a6
; --------------------------------------------------------

Sound_TrkStop:
		bsr	sndReq_Enter
		move.w	#$01,d7		; Command $01
		bsr	sndReq_scmd
		move.b	d0,d7		; d0 - Slot
		bsr	sndReq_sbyte
		bra 	sndReq_Exit

; --------------------------------------------------------
; Sound_TrkResume
;
; Resumes Stopped/Paused track
;
; Input:
; d0 | BYTE - Track slot
;
; Breaks:
; d6-d7,a5-a6
; --------------------------------------------------------

Sound_TrkResume:
		bsr	sndReq_Enter
		move.w	#$02,d7		; Command $01
		bsr	sndReq_scmd
		move.b	d0,d7		; d0 - Slot
		bsr	sndReq_sbyte
		bra 	sndReq_Exit

; --------------------------------------------------------
; Sound_TrkTicks
;
; Set ticks for the current track
; (NTSC: 150/tick, PAL: 120/tick)
;
; Input:
; d0 | BYTE - Track slot
; d1 | BYTE - Ticks
;
; Breaks:
; d6-d7,a5-a6
; --------------------------------------------------------

Sound_TrkTicks:
		bsr	sndReq_Enter
		move.w	#$08,d7		; Command $08
		bsr	sndReq_scmd
		move.b	d0,d7		; d0 - Slot
		bsr	sndReq_sbyte
		move.b	d1,d7		; d1 - Ticks
		bsr	sndReq_sbyte
		bra 	sndReq_Exit

; --------------------------------------------------------
; Sound_GlbBeats
;
; Set GLOBAL Sub-beats (different from a tempo...)
;
; Input:
; d0 | BYTE - Track slot
; d1 | WORD - Ticks
;
; Breaks:
; d6-d7,a5-a6
; --------------------------------------------------------

Sound_GlbBeats:
		bsr	sndReq_Enter
		move.w	#$10,d7		; Command $10
		bsr	sndReq_scmd
		move.b	d0,d7		; d0 - Slot
		bsr	sndReq_sbyte
		move.w	d1,d7		; d1 - Subbeats
		bsr	sndReq_sword
		bra 	sndReq_Exit

; --------------------------------------------------------

; Z80 code is located on the $880000 area

