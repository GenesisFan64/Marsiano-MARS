; ====================================================================
; ----------------------------------------------------------------
; GEMA Sound driver
; ----------------------------------------------------------------

; --------------------------------------------------------
; Initialize Sound
;
; Uses:
; a0-a1,d0-d1
; --------------------------------------------------------

	; This align is for GEMS emulator only
	; in case gets stuck in a black screen
; 		align $80

Sound_Init:
		move.w	#$0100,(z80_bus).l		; Request Z80 stop
		move.b	#1,(z80_reset).l		; And reset
.wait:
		btst	#0,(z80_bus).l
		bne.s	.wait
		lea	(z80_cpu).l,a0			; Clean entire Z80 area first
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
		move.b	#1,(z80_reset).l		; Reset again
		nop
		nop
		nop
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
		movem.l	d6-d7/a5-a6,(RAM_SndSaveReg).l
		moveq	#0,d6
		move.w	sr,d6
		move.w	#$0100,(z80_bus).l		; Request Z80 Stop
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

; --------------------------------------------------------
; Sound_DMA_Pause
;
; Call this BEFORE making any DMA task
;
; Uses:
; d7
; --------------------------------------------------------

Sound_DMA_Pause:
		swap	d7
.retry:
		bsr	sndLockZ80
		move.b	(z80_cpu+commZRomRd),d7		; Get mid-read bit
		bsr	sndUnlockZ80
		tst.b	d7
		beq.s	.safe
		moveq	#68,d7
		dbf	d7,*
		bra.s	.retry
	; TODO: ver si necesito un timeout...
		;rts
.safe:
		bsr	sndLockZ80
		move.b	#1,(z80_cpu+commZRomBlk)	; Block flag for Z80
		bsr	sndUnlockZ80

	; Make a data-backup of the current PWM's
.wait_mars1:	move.b	(sysmars_reg+comm15),d7		; Wait for
		and.w	#%11010000,d7			; BUSY/CLOCK/0/RESTORE
		bne.s	.wait_mars1
		move.b	(sysmars_reg+comm15),d7		; Request PWM Backup
		bset	#5,d7
		move.b	d7,(sysmars_reg+comm15)
.wait_mars2:	move.b	(sysmars_reg+comm15),d7		; Wait for
		and.w	#%11100000,d7			; BUSY/CLOCK/BACKUP
		bne.s	.wait_mars2
		swap	d7
		rts

; --------------------------------------------------------
; Sound_DMA_Resume
;
; Call this AFTER finishing DMA
; --------------------------------------------------------

Sound_DMA_Resume:
		swap	d7
		bsr	sndLockZ80
		move.b	#0,(z80_cpu+commZRomBlk)
		bsr	sndUnlockZ80

.wait_mars1:	move.b	(sysmars_reg+comm15),d7		; Wait for
		and.w	#%11100000,d7			; BUSY/CLOCK/BACKUP
		bne.s	.wait_mars1
		move.b	(sysmars_reg+comm15),d7		; Request PWM Restore
		bset	#4,d7
		move.b	d7,(sysmars_reg+comm15)
.wait_mars2:	move.b	(sysmars_reg+comm15),d7		; Wait for
		and.w	#%11010000,d7			; BUSY/CLOCK/0/RESTORE
		bne.s	.wait_mars2
		swap	d7
		rts

; --------------------------------------------------------
; SoundReq_SetTrack
;
; a0 - Pointer to Pattern, Blocks and Instruments list
;      in this order:
;  	dc.l pattern_data
;  	dc.l block_data
;  	dc.l instrument_data
;
; d0 - Slot
; d1 - Ticks
; d2 - From block
; d3 - Flags: %00004321
; 	1234 - Use global tempos 1,2,3 or 4
;
; Uses:
; d6-d7,a5-a6
; --------------------------------------------------------

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
; SoundReq_StopTrack (Pause too.)
;
; d0 - Slot
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
; d0 - Slot
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
; d0 - Slot
; d1 - Ticks
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
; Sound_GlbTempo
;
; d0 - Slot
; d1 - Tempo (WORD)
; --------------------------------------------------------

Sound_GlbTempo:
		bsr	sndReq_Enter
		move.w	#$10,d7		; Command $10
		bsr	sndReq_scmd
		move.b	d0,d7		; d0 - Slot
		bsr	sndReq_sbyte
		move.w	d1,d7		; d1 - Tempo MSB
		bsr	sndReq_sword
		bra 	sndReq_Exit

; --------------------------------------------------------

		align 4
Z80_CODE:
		cpu Z80			; Set Z80 here
		phase 0			; And set PC to 0
		include "system/md/z_driver.asm"
		cpu 68000
		padding off
		phase Z80_CODE+*
Z80_CODE_END:
		align 2


