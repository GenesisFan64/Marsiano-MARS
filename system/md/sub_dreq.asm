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
; CALL THIS OUTSIDE OF VBLANK ONLY.
;
; NOTE:
; THIS CODE ONLY WORKS PROPERLY ON THE
; $880000/$900000 AREAS. (FOR real hardware)
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

; OLD, STABLE
; System_SendDreq:
; 		move.w	sr,d7
; 		move.w	#$2700,sr
; .l1:		btst	#2,(sysmars_reg+dreqctl+1).l	; Wait until 68S finishes.
; 		bne.s	.l1
; 		lea	($A15112).l,a5			; a5 - DREQ FIFO port
; 		move.w	d0,d6				; Length in bytes
; 		lsr.w	#1,d6				; d6 - (length/2)
; 		move.w	#0,(sysmars_reg+dreqctl).l	; Clear both 68S and RV
; 		move.w	d6,(sysmars_reg+dreqlen).l	; Set transfer length (size/2)
; 		bset	#2,(sysmars_reg+dreqctl+1).l	; Set 68S bit
; 		bset	#0,(sysmars_reg+standby).l	; Request Master CMD
; ; .wait_cmd:	btst	#0,(sysmars_reg+standby).l	; <-- not needed, we'll use this bit instead:
; ; 		bne.s	.wait_cmd
; .wait_bit:	btst	#6,(sysmars_reg+comm12).l	; Wait comm bit signal from SH2 to fill the first words.
; 		beq.s	.wait_bit
; 		bclr	#6,(sysmars_reg+comm12).l	; Clear it afterwards.
; 		move.w	d6,d5				; (length/2)/4
; 		lsr.w	#2,d5
; 		sub.w	#1,d5				; minus 1 for the loop
; .l0:		move.w  (a0)+,(a5)
; 		move.w  (a0)+,(a5)
; 		move.w  (a0)+,(a5)
; 		move.w  (a0)+,(a5)			; FIFO-FULL check not needed.
; 		dbf	d5,.l0
; .bad_trnsfr:
; 		move.w	d7,sr
; 		rts
