; ===========================================================================
; ----------------------------------------------------------------
; MACROS
; ----------------------------------------------------------------

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

endstruct	macro				; Then finish the custom struct.
		!org GLBL_LASTORG
		phase GLBL_LASTPC
		endm

; -------------------------------------
; Report RAM usage
; -------------------------------------

report		macro text,dis,dat
	if MOMPASS == 2
		if dat == -1
			message text+": \{(dis)&$FFFFFF}"
		else
			if dis > dat
				error "RAN OUT OF:"+text
			else
				message text+" uses \{(dis)&$FFFFFF} of \{(dat)&$FFFFFF}"
			endif
		endif
	endif
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

; -------------------------------------
; ZERO Fill padding
;
; if AS align doesn't work
; -------------------------------------

rompad		macro address			; Zero fill
diff := address - *
		if diff < 0
			error "too much stuff before org $\{address} ($\{(-diff)} bytes)"
		else
			while diff > 1024
				; AS can only generate 1 kb of code on a single line
				dc.b [1024]0
diff := diff - 1024
			endm
			dc.b [diff]0
		endif
	endm

; ====================================================================
; ---------------------------------------------
; ISO filesystem macros
; ---------------------------------------------

; Set a ISO file
; NOTE: a valid ISO head is required ($8000 to $B7FF)

iso_setfs	macro type,start,end
.fstrt:		dc.b .fend-.fstrt				; Block size
		dc.b 0						; zero
		dc.b (start>>11&$FF),(start>>19&$FF)		; Start sector, little
		dc.b (start>>27&$FF),(start>>35&$FF)
		dc.l start>>11					; Start sector, big
		dc.b ((end-start)&$FF),((end-start)>>8&$FF)	; Filesize, little
		dc.b ((end-start)>>16&$FF),((end-start)>>24&$FF)
		dc.l end-start					; Filesize, big
		dc.b (2018-1900)+1				; Year
		dc.b 0,0,0,0,0,0				; TODO
		dc.b 2						; File flags
		dc.b 0,0
		dc.b 1,0					; Volume sequence number, little
		dc.b 0,1					; Volume sequence number, big
		dc.b 1,type
.fend:
		endm

iso_file	macro filename,start,end
.fstrt:		dc.b .fend-.fstrt				; Block size
		dc.b 0						; zero
		dc.b (start>>11&$FF),(start>>19&$FF)		; Start sector, little
		dc.b (start>>27&$FF),(start>>35&$FF)
		dc.l start>>11					; Start sector, big
		dc.b ((end-start)&$FF),((end-start)>>8&$FF)	; Filesize, little
		dc.b ((end-start)>>16&$FF),((end-start)>>24&$FF)
		dc.l end-start					; Filesize, big
		dc.b (2023-1900)+1				; Year
		dc.b 0,0,0,0,0,0				; TODO
		dc.b 0						; File flags
		dc.b 0,0
		dc.b 1,0					; Volume sequence number, little
		dc.b 0,1					; Volume sequence number, big
		dc.b .flend-.flen
.flen:		dc.b filename,";1"
.flend:		dc.b 0
.fend:
		endm

