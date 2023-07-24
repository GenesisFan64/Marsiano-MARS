; ====================================================================
; ----------------------------------------------------------------
; DREQ transfer section
; ----------------------------------------------------------------

; --------------------------------------------------------
; System_MarsSendDreq
;
; Transfers data to the 32X using DREQ
;
; Input:
; a0.l | Source data to transfer
; d0.w | Size aligned by 8, MUST end with 0 or 8.
;
; Uses:
; a4-a5/d5-d7
;
; Notes:
; Only call this during DISPLAY, not during VBlank.
; --------------------------------------------------------

System_RomSendDreq:
		move.w	sr,d7
		move.w	#$2700,sr
		lea	(sysmars_reg).l,a5
		lea	dreqfifo(a5),a4
; 		btst	#7,comm12(a5)
; 		bne.s	.bad
; 		btst	#7,dreqctl+1(a5)	; If FIFO got full, skip.
; 		bne.s	.bad
		move.w	#%000,dreqctl(a5)	; Reset 68S
		move.w	d0,d6			; d6 - Size in bytes
		lsr.w	#1,d6			; (length/2)
		move.w	d6,dreqlen(a5)		; Set transfer length (size/2)
		move.w	d6,d5			; d5 - (length/2)/4
		lsr.w	#2,d5
		subi.w	#1,d5
		bset	#0,standby(a5)		; Set CMD interrupt to MASTER
.wait_bit:	btst	#6,comm12(a5)		; Wait signal bit from Master
		beq.s	.wait_bit
		bclr	#6,comm12(a5)		; Clear it for later.
		move.w	#%100,dreqctl(a5)	; Set 68S
.l0:		move.w  (a0)+,(a4)		; *** CRITICAL PART ***
		move.w  (a0)+,(a4)
		move.w  (a0)+,(a4)
		move.w  (a0)+,(a4)
		dbf	d5,.l0
	; POPULAR 32X EMULATORS WILL GET STUCK HERE.
	;
	; ONLY ares-emu SUPPORTS THE
	; DMA INTERRUPT. (AS OF THIS COMMENT)
.wait_bit_e:	btst	#6,comm12(a5)		; Wait EXIT signal.
		beq.s	.wait_bit_e
		bclr	#6,comm12(a5)		; Clear again.
		move.w	#%000,dreqctl(a5)	; Disable 68S
		move.w	d7,sr
		rts
