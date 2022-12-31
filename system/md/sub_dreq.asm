; --------------------------------------------------------
; System_RomSendDreq
;
; Send data to the 32X using DREQ and
; the CMD interrupt
;
; Input:
; a0 - LONG | Source data to transfer
; d0 - WORD | Size (aligned by 8, MUST end with 0 or 8)
;
; CALL THIS OUTSIDE OF VBLANK ONLY, THIS DISABLES
; INTERRUPTS.
;
; Hardware NOTE:
; THIS CODE ONLY WORKS PROPERLY ON THE
; $880000/$900000 AREAS.
; Emulators ignore this limitation.
; --------------------------------------------------------

System_RomSendDreq:
		move.w	sr,d7
		move.w	#$2700,sr
		lea	(sysmars_reg).l,a5
		lea	($A15112).l,a4
; 		btst	#7,comm12(a5)
; 		bne.s	.bad
; 		btst	#7,dreqctl+1(a5)	; If FIFO got full, skip.
; 		bne.s	.bad
		move.w	#%000,dreqctl(a5)	; Set 68S
		move.w	d0,d6			; Length in bytes
		lsr.w	#1,d6			; d6 - (length/2)
		move.w	d6,dreqlen(a5)		; Set transfer length (size/2)
		move.w	d6,d5			; d5 - (length/2)/4
		lsr.w	#2,d5
		sub.w	#1,d5
		bset	#0,standby(a5)
.wait_bit:	btst	#6,comm12(a5)
		beq.s	.wait_bit
		bclr	#6,comm12(a5)
		move.w	#%100,dreqctl(a5)	; Set 68S
.l0:		move.w  (a0)+,(a4)		; *** CRITICAL PART***
		move.w  (a0)+,(a4)
		move.w  (a0)+,(a4)
		move.w  (a0)+,(a4)
		dbf	d5,.l0
		move.w	#%000,dreqctl(a5)	; Set 68S
		move.w	d7,sr
		rts
.bad:
; 		move.w	#%000,dreqctl(a5)
		move.w	d7,sr
		rts
