; ====================================================================
; ----------------------------------------------------------------
; PICO header
;
; REMINDER: NO Z80 CPU, DO NOT USE THE Z80 AREA IF
; SHARING CODING WITH GENESIS.
; ----------------------------------------------------------------

		dc.l RAM_Stack		; Stack point
		dc.l Pico_Entry		; Entry point MUST point to $3F0
		dc.l Pico_ErrBus	; Bus error
		dc.l Pico_ErrAddr	; Address error
		dc.l Pico_ErrIll	; ILLEGAL Instruction
		dc.l Pico_ErrZDiv	; Divide by 0
		dc.l Pico_ErrChk	; CHK Instruction
		dc.l Pico_ErrTrapV	; TRAPV Instruction
		dc.l Pico_ErrPrivl	; Privilege violation
		dc.l Pico_Trace		; Trace
		dc.l Pico_Line1010	; Line 1010 Emulator
		dc.l Pico_Line1111	; Line 1111 Emulator
		dc.l Pico_ErrorEx	; Error exception
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_ErrorEx
		dc.l Pico_Error
		dc.l Pico_UserInt	; PICO: User interrupt
		dc.l Pico_PcmInt	; PICO: PCM-full interrupt
		dc.l RAM_MdMarsHInt	; RAM jump for HBlank (JMP xxxx xxxx)
		dc.l Pico_UnkInt	; PICO: Unknown
		dc.l RAM_MdMarsVInt	; RAM jump for VBlank (JMP xxxx xxxx)
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.l Pico_Error
		dc.b "SEGA PICO       "
		dc.b "(C)GF64 2023.???"
		dc.b "Marsiano PICO                                   "
		dc.b "Marsiano PICO                                   "
		dc.b "GM TECHDEMO-01"
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

Pico_ErrBus:				; Bus error
Pico_ErrAddr:				; Address error
Pico_ErrIll:				; ILLEGAL Instruction
Pico_ErrZDiv:				; Divide by 0
Pico_ErrChk:				; CHK Instruction
Pico_ErrTrapV:				; TRAPV Instruction
Pico_ErrPrivl:				; Privilege violation
Pico_Trace:				; Trace
Pico_Line1010:				; Line 1010 Emulator
Pico_Line1111:				; Line 1111 Emulator
Pico_ErrorEx:				; Error exception
Pico_Error:
		rte			; Return from Exception

; ----------------------------------------------------------------
; PICO exclusive interrupts
; ----------------------------------------------------------------

Pico_UserInt:
Pico_PcmInt:	; <-- Interrupt when the PCM chips gets full, Ojamajo# uses this.
Pico_UnkInt:
		rte

; ====================================================================
; ----------------------------------------------------------------
; Entry point
; ----------------------------------------------------------------

Pico_Entry:
	; --------------------------------
	; Activate PICO system
		move	#$2700,sr		; Disable interrputs
		lea	($800019),a0
		move.l	#"SEGA",d0
		movep.l	d0,(a0)			; Unlock PICO system
		tst.w	(vdp_ctrl).l		; Random VDP test to unlock it

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
