; ====================================================================
; ----------------------------------------------------------------
; ROM HEADER FOR 32X
;
; These labels still work even if the 32X isn't present
; ----------------------------------------------------------------

		dc.l 0				; Stack point
		dc.l $3F0			; Entry point (always $3F0)
		dc.l MD_ErrBus			; Bus error
		dc.l MD_ErrAddr			; Address error
		dc.l MD_ErrIll			; ILLEGAL Instruction
		dc.l MD_ErrZDiv			; Divide by 0
		dc.l MD_ErrChk			; CHK Instruction
		dc.l MD_ErrTrapV		; TRAPV Instruction
		dc.l MD_ErrPrivl		; Privilege violation
		dc.l MD_Trace			; Trace
		dc.l MD_Line1010		; Line 1010 Emulator
		dc.l MD_Line1111		; Line 1111 Emulator
		dc.l MD_ErrorEx			; Error exception
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorEx
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l RAM_MdMarsHInt		; RAM jump for HBlank (JMP xxxx xxxx)
		dc.l MD_ErrorTrap
		dc.l RAM_MdMarsVInt		; RAM jump for VBlank (JMP xxxx xxxx)
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.l MD_ErrorTrap
		dc.b "SEGA 32X        "
		dc.b "(C)GF64 2022.???"
		dc.b "Proyecto MARSIANO                               "
		dc.b "Project MARSIANO                                "
		dc.b "GM HOMEBREW-00"
		dc.w 0
		dc.b "J6              "
		dc.l 0
		dc.l ROM_END
		dc.l $FF0000
		dc.l $FFFFFF
		dc.l $20202020		; dc.b "RA",$F8,$20
		dc.l $20202020		; $200000
		dc.l $20202020		; $203FFF
		align $1F0
		dc.b "U               "

; ====================================================================
; ----------------------------------------------------------------
; Second header for 32X
;
; These new jumps are for the 68K if the 32X is currently
; active.
; ----------------------------------------------------------------

		jmp	($880000|MARS_Entry).l
		jmp	($880000|MD_ErrBus).l			; Bus error
		jmp	($880000|MD_ErrAddr).l			; Address error
		jmp	($880000|MD_ErrIll).l			; ILLEGAL Instruction
		jmp	($880000|MD_ErrZDiv).l			; Divide by 0
		jmp	($880000|MD_ErrChk).l			; CHK Instruction
		jmp	($880000|MD_ErrTrapV).l			; TRAPV Instruction
		jmp	($880000|MD_ErrPrivl).l			; Privilege violation
		jmp	($880000|MD_Trace).l			; Trace
		jmp	($880000|MD_Line1010).l			; Line 1010 Emulator
		jmp	($880000|MD_Line1111).l			; Line 1111 Emulator
		jmp	($880000|MD_ErrorEx).l			; Error exception
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorEx).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	(RAM_MdMarsHInt).l			; RAM jump for HBlank (JMP xxxx xxxx)
		jmp	($880000|MD_ErrorTrap).l
		jmp	(RAM_MdMarsVInt).l			; RAM jump for VBlank (JMP xxxx xxxx)
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l
		jmp	($880000|MD_ErrorTrap).l

; ----------------------------------------------------------------

		align $3C0
		dc.b "MARS CHECK MODE "			; Module name
		dc.l 0					; Version (always 0)
		dc.l MARS_RAMDATA			; Set to 0 if SH2 code points to ROM
		dc.l 0					; Zero.
		dc.l MARS_RAMDATA_e-MARS_RAMDATA	; Set to 4 if SH2 code points to ROM
		dc.l SH2_M_Entry			; Master SH2 PC (SH2 map area)
		dc.l SH2_S_Entry			; Slave SH2 PC (SH2 map area)
		dc.l SH2_Master				; Master SH2 default vector table (vbr)
		dc.l SH2_Slave				; Slave SH2 default vector table (vbr)
		binclude "system/mars/data/security.bin"

; ====================================================================
; ----------------------------------------------------------------
; Entry point, this must be located at $3F0
;
; At this point, the initialization
; returns the following bits:
;
; d0: %h0000000 rsc000ti
; 	h - Cold start / Hot Start
; 	r - SDRAM Self Check pass or error
; 	s - Security check pass or error
; 	c - Checksum pass or error
; 	t - TV mode pass or error
; 	i - MARS ID pass or error
;
; d1: %m0000000 jdk0vvv
; 	m - MARS TV mode
; 	j - Country: Japan / Overseas
; 	d - MD TV mode
; 	k - DISK connected: Yes / No
; 	v - Version
;
; Carry flag: "MARS ID" and Self Check result
; 	cc: Test passed
; 	cs: Test failed
; ----------------------------------------------------------------

MARS_Entry:
; 		bcs	.no_mars			; *** HARDWARE NOTE: this MAY trigger on soft-reset
		move.l	#0,(RAM_initflug).l		; Reset "INIT" flag
		btst	#15,d0				; Soft reset?
		beq	MD_Init
		lea	(sysmars_reg).l,a5		; a5 - MARS register
		btst.b	#0,adapter+1(a5)		; 32X enabled?
		bne	.adapterenable			; If yes, start booting
		move.l	#0,comm8(a5)			; If not, we can't use 32X or something went wrong
		lea	.ramcode(pc),a0			; Copy the adapter-retry code to RAM
		lea	($FF0000).l,a1			; and jump there.
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		lea	($FF0000).l,a0
		jmp	(a0)
.ramcode:
		move.b	#1,adapter+1(a5)		; Enable adapter.
		lea	.restarticd(pc),a0	; JUMP to the following code in
		adda.l	#$880000,a0		; the new 68k location
		jmp	(a0)
.restarticd:
		lea	($A10000).l,a5		; a5 - MD's I/O area
		move.l	#-64,a4			; a4 - $FFFFFF9C
		move.w	#3900,d7		; d7 - loop this many times
		lea	($880000+$6E4),a1	; Jump to ?res_wait (check ICD_MARS.PRG)
		jmp	(a1)
.adapterenable:
		lea	(sysmars_reg),a5
		btst.b	#1,adapter+1(a5)		; SH2 Reset request?
		bne.s	MD_HotStart		; If not, we are on hotstart
		bra.s	.restarticd

; ====================================================================
; ----------------------------------------------------------------
; If the internal setup fails... kinda.
;
; There a bug on the security that we may get
; in here on soft-reset.
; ----------------------------------------------------------------

.no_mars:
		btst	#5,d0				; Checksum passed anyway?
		bne.s	MD_HotStart
		move.w	#$2700,sr			; Disable interrupts
		move.l	#$C0000000,(vdp_ctrl).l		; VDP: Point to Color 0
		move.w	#$0E00,(vdp_data).l		; Write blue
		bra.s	*				; Infinite loop.

; ====================================================================
; ----------------------------------------------------------------
; Error traps
; ----------------------------------------------------------------

MD_ErrBus:		; Bus error
MD_ErrAddr:		; Address error
MD_ErrIll:		; ILLEGAL Instruction
MD_ErrZDiv:		; Divide by 0
MD_ErrChk:		; CHK Instruction
MD_ErrTrapV:		; TRAPV Instruction
MD_ErrPrivl:		; Privilege violation
MD_Trace:		; Trace
MD_Line1010:		; Line 1010 Emulator
MD_Line1111:		; Line 1111 Emulator
MD_ErrorEx:		; Error exception
MD_ErrorTrap:
		move.l	#$C0000000,(vdp_ctrl).l
		move.w	#$EE0,(vdp_data).l
		bra.s	*

; ------------------------------------------------
; Init
; ------------------------------------------------

MD_Init:
		move.w	#$2700,sr			; Disable interrupts
		move.l	#"INIT",(RAM_initflug).l	; Set "INIT" as our boot flag
MD_HotStart:
		cmp.l	#"INIT",(RAM_initflug).l	; Did it write?
		bne.s	MD_Init				; If not, restart everything and try again.
		moveq	#0,d0				; Clear USP
		movea.l	d0,a6
		move.l	a6,usp
		move.w	#$2FF,d7	; TODO: a better way to delay this CPU...
.loop:
		move.l	#$7F,d6
		dbf	d6,*
		dbf	d7,.loop
		movem.l	($FF0000),d0-a6
