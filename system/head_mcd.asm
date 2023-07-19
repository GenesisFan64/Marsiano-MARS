; ====================================================================
; ----------------------------------------------------------------
; SEGA CD header
; ----------------------------------------------------------------

		dc.b "SEGADISCSYSTEM  "		; Disc Type (Must be SEGADISCSYSTEM)
		dc.b "MARSIANO-CD",0		; Disc ID
		dc.w $100,1			; System ID, Type
		dc.b "MARSIANO-SY",0		; System Name
		dc.w 0,0			; System Version, Type
		dc.l IP_Start
		dc.l IP_End
		dc.l 0
		dc.l 0
		dc.l SP_Start
		dc.l SP_End
		dc.l 0
		dc.l 0
		align $100			; Pad to $100
		dc.b "SEGA GENESIS    "
		dc.b "(C)GF64 2023.???"
	if MARSCD
		dc.b "Marsiano CD32X                                  "
                dc.b "Marsiano CD32X                                  "
	else
		dc.b "Marsiano MCD                                    "
                dc.b "Marsiano MCD                                    "
	endif
		dc.b "GM TECHDEMO-01  "
		dc.b "J               "
		align $1F0
		dc.b "U               "

; 		binclude "system/mcd/region/jap.bin"
		binclude "system/mcd/region/usa.bin"
; 		binclude "system/mcd/region/eur.bin"

; ========================================================
; -------------------------------------------------
; IP
; -------------------------------------------------

IP_Start:
		move.w	#(RAM_MdMarsHInt)&$FFFF,(sysmcd_reg+mcd_hint).l
		jmp	($FF0600+MCD_Main).l
IP_End:
		align 2

; ========================================================
; -------------------------------------------------
; SP
; -------------------------------------------------

		align $800	; <-- REQUIRED
SP_Start:
		include "system/mcd/subcpu.asm"
SP_End:
		align 2

; ========================================================
; -------------------------------------------------
; Super-jump...
; -------------------------------------------------

		align $2000-$600
MCD_Main:
