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
			struct $FF0000
RAM_SystemCode		ds.b MAX_SysCode	;
RAM_UserCode		ds.b MAX_UserCode	;
RAM_ExSoundData		ds.b MAX_RamSndData	; non-Cartridge ONLY
sizeof_thisram		ds.l 0
			endstruct

	if MCD|MARS|MARSCD
			erreport "non-Cart code",sizeof_thisram,$FF8000
	endif

			struct $FFFF8000
RAM_MdVideo		ds.b MAX_MdVideo	; $FF8000 DMA visuals
RAM_MdSystem		ds.b MAX_MdSystem	;
RAM_MdOther		ds.b MAX_MdOther	; 32X's DREQ goes here
RAM_MdGlobal		ds.b MAX_MdGlobal
RAM_ScreenBuff		ds.b MAX_ScrnBuff
sizeof_MdRam		ds.l 0
			endstruct
			report "MD RAM",(sizeof_MdRam-$FFFF8000),$FC00-$8000

RAM_Stack		equ RAM_MegaCd		; <-- goes backwards
RAM_MegaCd		equ $FFFFFD00
RAM_ScreenJump		equ $FFFFFE00;$FFFFFE80		; Screen change section
