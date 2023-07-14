; ====================================================================
; ----------------------------------------------------------------
; MD RAM
;
; NOTE for porting this to Sega CD (or SegaCD+32X):
;
; Area $FFFD00 to $FFFDFF(aprox) is reserved
; for the MAIN-CPU's vectors and misc things
; ----------------------------------------------------------------

; Sega 32X
RAM_MdDreq		equ	RAM_MdOther

; --------------------------------------------------------
; Settings
; --------------------------------------------------------

; Quick
			struct $FFFF0000
RAM_SystemCode		ds.b MAX_SysCode	;
RAM_UserCode		ds.b MAX_UserCode	;
RAM_UserData		ds.b MAX_UserData	;
RAM_MdVideo		ds.b MAX_MdVideo	; $FF8000 DMA visuals
RAM_MdSystem		ds.b MAX_MdSystem	;
RAM_MdOther		ds.b MAX_MdOther	; 32X's DREQ goes here
RAM_MdGlobal		ds.b MAX_MdGlobal
RAM_ScreenBuff		ds.b MAX_ScrnBuff
sizeof_MdRam		ds.l 0
			endstruct
			report "GENESIS RAM",(sizeof_MdRam-$FFFF0000)

RAM_Stack		equ RAM_MegaCd		; <-- goes backwards
RAM_MegaCd		equ $FFFFFD00
RAM_ScreenJump		equ $FFFFFE80		; Fileloading routines ** TODO: check if this loc is safe
