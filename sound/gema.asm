; ====================================================================
; --------------------------------------------------------
; GEMA/Nikona sound driver v0.5
; (C)2023 GenesisFan64
;
; Reads custom "miniature" ImpulseTracker files
; and automaticly picks the soundchip(s) to play.
;
; Features:
; - Support for 32X's PWM:
;   | 7 extra pseudo-channels in either MONO
;   | or STEREO.
;   | ** REQUIRES specific code for the SH2 side
;   | and enabling the use of CMD interrupt.
;   | Uses Slave SH2.
; - DMA-protection
;   | This keeps DAC samplerate to a decent
;   | quality.
; - DAC Playback at 16000hz
; - FM special mode with custom frequencies
; - Autodetection for the PSG's Tone3 mode
;
; ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣶⡿⠿⠿⠿⣶⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⠀⠀⢀⣠⣶⢟⣿⠟⠁⢰⢋⣽⡆⠈⠙⣿⡿⣶⣄⡀⠀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⣠⣴⠟⠋⢠⣾⠋⠀⣀⠘⠿⠿⠃⣀⠀⠈⣿⡄⠙⠻⣦⣄⠀⠀⠀⠀
; ⠀⢀⣴⡿⠋⠁⠀⢀⣼⠏⠺⠛⠛⠻⠂⠐⠟⠛⠛⠗⠘⣷⡀⠀⠈⠙⢿⣦⡀⠀
; ⣴⡟⢁⣀⣠⣤⡾⢿⡟⠀⠀⠀⠘⢷⠾⠷⡾⠃⠀⠀⠀⢻⡿⢷⣤⣄⣀⡈⢻⣦
; ⠙⠛⠛⠋⠉⠁⠀⢸⡇⠀⠀⢠⣄⠀⠀⠀⠀⣠⡄⠀⠀⢸⡇⠀⠈⠉⠙⠛⠛⠋
; ⠀⠀⠀⠀⠀⠀⠀⢸⡇⢾⣦⣀⣹⡧⠀⠀⢼⣏⣀⣴⡷⢸⡇⠀⠀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⠀⠀⠀⠸⣧⡀⠈⠛⠛⠁⠀⠀⠈⠛⠛⠁⢀⣼⠇⠀⠀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⠀⠀⠀⢀⣘⣿⣶⣤⣀⣀⣀⣀⣀⣀⣤⣶⣿⣃⠀⠀⠀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⠀⣠⡶⠟⠋⢉⣀⣽⠿⠉⠉⠉⠹⢿⣍⣈⠉⠛⠷⣦⡀⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⢾⣯⣤⣴⡾⠟⠋⠁⠀⠀⠀⠀⠀⠀⠉⠛⠷⣶⣤⣬⣿⠀⠀⠀⠀⠀
; ⠀⠀⠀⠀⠀⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠁⠀⠀⠀⠀⠀
; --------------------------------------------------------

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; z80_cpu	equ $A00000		; Z80 CPU area, size: $2000
; z80_bus 	equ $A11100		; only read bit 0 (bit 8 as WORD)
; z80_reset	equ $A11200		; WRITE only: $0000 reset/$0100 cancel

; Z80-area points:
zDrvFifo	equ commZfifo		; FIFO command storage
zDrvFWrt	equ commZWrite		; FIFO command index
zDrvRomBlk	equ commZRomBlk		; ROM block flag
zDrvMarsBlk	equ marsBlock		; Disable PWM flag

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
		lea	(z80_cpu).l,a0			; Clean entire Z80 FIRST.
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
		movem.l	d6-d7/a5-a6,-(sp)		; Save these regs to the stack
		adda	#4*4,sp				; Go back to the RTS jump
		move.w	#$0100,(z80_bus).l		; Request Z80 Stop
		moveq	#0,d6
		move.w	sr,d6
		swap	d6
		or.w	#$0700,sr			; Disable interrupts
		lea	(z80_cpu+zDrvFWrt),a5		; a5 - commZWrite
		lea	(z80_cpu+zDrvFifo),a6		; a6 - fifo command list
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
		suba	#4*4,sp				; Roll to the last regs
		movem.l	(sp)+,d6-d7/a5-a6		; And pop those back
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
; gemaDmaPause
;
; Call this BEFORE doing any DMA transfer
; --------------------------------------------------------

gemaDmaPause:
		swap	d7
		swap	d6
		bsr	sndLockZ80
		move.b	#1,(z80_cpu+zDrvRomBlk)		; Block flag for Z80
		move.w	#1,
		bsr	sndUnlockZ80
		move.w	#96,d7				; ...Small delay...
		dbf	d7,*
		swap	d6
		swap	d7
		rts

; --------------------------------------------------------
; gemaDmaResume
;
; Call this AFTER finishing DMA transfer
; --------------------------------------------------------

gemaDmaResume:
		swap	d7
		swap	d6
		bsr	sndLockZ80
		move.b	#0,(z80_cpu+zDrvRomBlk)		; Block flag for Z80
		bsr	sndUnlockZ80
		swap	d6
		swap	d7
		rts

; --------------------------------------------------------
; gemaDmaPause
;
; Call this BEFORE doing any DMA transfer
; --------------------------------------------------------

gemaDmaPauseRom:
		swap	d7
		swap	d6
		bsr	sndLockZ80
		move.b	#1,(z80_cpu+zDrvRomBlk)		; Block flag for Z80
		bsr	sndUnlockZ80
		move.w	#96,d7				; ...Small delay...
		dbf	d7,*
	if MARS
		move.w	#2,d6
		bsr	sndReqCmd
		bset	#0,(sysmars_reg+dreqctl+1).l	; Set RV=1
	endif
		swap	d6
		swap	d7
		rts

; --------------------------------------------------------
; gemaDmaResume
;
; Call this AFTER finishing DMA transfer
; --------------------------------------------------------

gemaDmaResumeRom:
		swap	d7
		swap	d6
		bsr	sndLockZ80
		move.b	#0,(z80_cpu+zDrvRomBlk)		; Block flag for Z80
		bsr	sndUnlockZ80
	if MARS
		move.w	#3,d6
		bsr	sndReqCmd
		bclr	#0,(sysmars_reg+dreqctl+1).l	; Set RV=0
	endif
		swap	d6
		swap	d7
		rts

; ------------------------------------------------
; 32X ONLY: Request CMD interrupt with
; command
;
; d6 - command
; ------------------------------------------------

sndReqCmd:
	if MARS
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
	endif
		rts

; ============================================================
; --------------------------------------------------------
; gemaTest
;
; For TESTING only.
; --------------------------------------------------------

gemaTest:
		bsr	sndReq_Enter
		move.w	#$00,d7		; Command $00
		bsr	sndReq_scmd
		bra 	sndReq_Exit

; --------------------------------------------------------
; gemaPlayTrack
;
; Play a track by number
;
; d0.b - Track number
; --------------------------------------------------------

gemaPlayTrack:
		bsr	sndReq_Enter
		move.w	#$01,d7		; Command $01
		bsr	sndReq_scmd
		move.b	d0,d7
		bsr	sndReq_sbyte
		bra 	sndReq_Exit

; --------------------------------------------------------
; gemaStopTrack
;
; Stops a track using that ID
;
; d0.b - Track number
; --------------------------------------------------------

gemaStopTrack:
		bsr	sndReq_Enter
		move.w	#$02,d7		; Command $02
		bsr	sndReq_scmd
		move.b	d0,d7
		bsr	sndReq_sbyte
		bra 	sndReq_Exit

; --------------------------------------------------------
; gemaStopAll
;
; Stop ALL tracks from ALL buffers.
;
; No arguments.
; --------------------------------------------------------

gemaStopAll:
		bsr	sndReq_Enter
		move.w	#$08,d7		; Command $08
		bsr	sndReq_scmd
		bra 	sndReq_Exit

; --------------------------------------------------------
; gemaSetBeats
;
; Sets global subbeats
;
; d0.w - sub-beats
; --------------------------------------------------------

gemaSetBeats:
		bsr	sndReq_Enter
		move.w	#$0C,d7		; Command $0C
		bsr	sndReq_scmd
		move.w	d0,d7
		bsr	sndReq_sword
		bra 	sndReq_Exit
