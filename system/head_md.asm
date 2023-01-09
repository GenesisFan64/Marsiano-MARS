; ====================================================================
; ----------------------------------------------------------------
; Genesis header
; ----------------------------------------------------------------

		dc.l 0			; Stack point
		dc.l MD_Entry		; Entry point MUST point to $3F0
		dc.l MD_ErrBus		; Bus error
		dc.l MD_ErrAddr		; Address error
		dc.l MD_ErrIll		; ILLEGAL Instruction
		dc.l MD_ErrZDiv		; Divide by 0
		dc.l MD_ErrChk		; CHK Instruction
		dc.l MD_ErrTrapV	; TRAPV Instruction
		dc.l MD_ErrPrivl	; Privilege violation
		dc.l MD_Trace		; Trace
		dc.l MD_Line1010	; Line 1010 Emulator
		dc.l MD_Line1111	; Line 1111 Emulator
		dc.l MD_ErrorEx		; Error exception
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
		dc.l RAM_MdMarsHInt	; RAM jump for HBlank (JMP xxxx xxxx)
		dc.l MD_ErrorTrap
		dc.l RAM_MdMarsVInt	; RAM jump for VBlank (JMP xxxx xxxx)
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
		dc.b "SEGA GENESIS    "
		dc.b "(C)GF64 2023.FEB"
		dc.b "Bloque eswap                                    "
		dc.b "SwapBlok                                        "
		dc.b "GM PUZZLSWP-01"
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
		dc.b "JU              "

; ====================================================================
; ----------------------------------------------------------------
; Error handlers
;
; all these do nothing currently
; ----------------------------------------------------------------

MD_ErrBus:				; Bus error
MD_ErrAddr:				; Address error
MD_ErrIll:				; ILLEGAL Instruction
MD_ErrZDiv:				; Divide by 0
MD_ErrChk:				; CHK Instruction
MD_ErrTrapV:				; TRAPV Instruction
MD_ErrPrivl:				; Privilege violation
MD_Trace:				; Trace
MD_Line1010:				; Line 1010 Emulator
MD_Line1111:				; Line 1111 Emulator
MD_ErrorEx:				; Error exception
MD_ErrorTrap:
		rte			; Return from Exception

; ====================================================================
; ----------------------------------------------------------------
; Entry point
; ----------------------------------------------------------------

MD_Entry:
	; --------------------------------
	; Check if the system has TMSS
		move	#$2700,sr			; Disable interrputs
		move.b	(sys_io).l,d0			; Read IO port
		andi.b	#%1111,d0			; Get version, right 4 bits
		beq.s	.oldmd				; If == 0, skip this part
		move.l	($100).l,(sys_tmss).l		; Write "SEGA" to port sys_tmss
.oldmd:
		tst.w	(vdp_ctrl).l			; Random VDP test, to unlock it

	; --------------------------------

		lea	($FFFF0000),a0		; Clean our "work" RAM
		move.l	#sizeof_mdram,d1
		moveq	#0,d0
.loop_ram:	move.w	d0,(a0)+
		cmp.l	d1,a0
		bcs.s	.loop_ram
		movem.l	($FF0000),d0-a6		; Clean registers using zeros from RAM
		lea	(vdp_ctrl).l,a6
.wait_dma:	move.w	(a6),d7			; Check if our DMA is active.
		btst	#1,d7
		bne.s	.wait_dma

; 		moveq	#0,d0				; d0 = 0
; 		movea.l	d0,a6				; a6 = d0
; 		move.l	a6,usp				; move a6 to usp
; .waitframe:	move.w	(vdp_ctrl).l,d0			; Wait for VBlank
; 		btst	#4,d0
; 		beq.s	.waitframe
; 		move.l	#$80048104,(vdp_ctrl).l		; VDP: Set special bits, and keep Display (TMSS screen stays on)
; 		lea	($FFFF0000),a0			; a0 - RAM Address
; 		move.w	#($F000/4)-1,d0			; d0 - Bytes to clear / 4, minus 1
; .clrram:
; 		clr.l	(a0)+				; Clear 4 bytes, and increment by 4
; 		dbf	d0,.clrram			; Loop until d0 == 0
; 		movem.l	($FF0000),d0-a6			; Trick: Grab clean RAM memory to clear all registers except a7 (Stack point)
; 		bra	MD_Main				; Branch to MD_Main
