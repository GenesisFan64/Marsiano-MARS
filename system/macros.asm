; ===========================================================================
; ----------------------------------------------------------------
; MACROS
;
; Include this file FIRST
; ----------------------------------------------------------------

; --------------------------------------------------------
; AS Main settings
; --------------------------------------------------------

		!org 0				; Start at 0
		cpu 		68000		; Current CPU is 68k, gets changed later.
		padding		off		; Dont pad dc.b
		listing 	purecode	; Want listing file, but only the final code in expanded macros
		supmode 	on 		; Supervisor mode
		dottedstructs	off		; If needed
		page 		0

; ====================================================================
; ---------------------------------------------
; Functions
; ---------------------------------------------

dword 		function l,r,(l<<16&$FFFF0000|r&$FFFF)			; LLLL RRRR
mapsize		function l,r,(((l-1)/8)<<16&$FFFF0000|((r-1)/8)&$FFFF)	; Full w/h sizes, for cell sizes use doubleword
locate		function a,b,c,(c&$FF)|(b<<8&$FF00)|(a<<16&$FF0000)	; VDP locate: Layer|X pos|Y pos for some video routines

; ====================================================================
; ---------------------------------------------
; Macros
; ---------------------------------------------

paddingSoFar set 0
notZ80 function cpu,(cpu<>128)&&(cpu<>32988)

; -------------------------------------
; Reserve memory section
;
; NOTE: This doesn't work for Z80
; -------------------------------------

struct		macro thisinput			; Reserve memory address
GLBL_LASTPC	set *
		dephase
GLBL_LASTORG	set *
		phase thisinput
		endm
		
; -------------------------------------
; Finish struct
; -------------------------------------

finish		macro				; Then finish the custom struct.
		!org GLBL_LASTORG
		phase GLBL_LASTPC
		endm

; -------------------------------------
; Color debug
; -------------------------------------

colorme		macro this
		move.l	#$C0000000,(vdp_ctrl).l
		move.w	#this,(vdp_data).l
		endm

; -------------------------------------
; Custom ORG-filler
;
; (from s2disasm)
; -------------------------------------

org macro address
	if notZ80(MOMCPU)
		if address < *
			error "too much stuff before org $\{address} ($\{(*-address)} bytes)"
		elseif address > *
paddingSoFar	set paddingSoFar + address - *
			!org address
		endif
	else
		if address < $
			error "too much stuff before org 0\{address}h (0\{($-address)}h bytes)"
		else
			while address > $
				db 0
			endm
		endif
	endif
    endm
