; ====================================================================
; ----------------------------------------------------------------
; Genesis side constants
; ----------------------------------------------------------------

MAX_MDDMATSK	equ 16			; MAX DMA BLAST entries

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MDRAM_START	equ $FFFF9000		; Start of Genesis working RAM
MAX_MDERAM	equ $1000		; Maximum RAM for current Screen mode

; ====================================================================
; ----------------------------------------------------------------
; Input
; ----------------------------------------------------------------

; --------------------------------------------------------
; Controller
; --------------------------------------------------------

; Controller buffer data (after calling System_Input)
;
; Type/Revision byte:
;
; ID    |
; $0D   | $00 - Original 3 button
;       | $01 - 6 button version: XYZM

		struct 0
pad_id		ds.b 1			; Controller ID
pad_ver		ds.b 1			; Controller type/revision
on_hold		ds.w 1			; User HOLD bits
on_press	ds.w 1			; User PRESSED bits
mouse_x		ds.w 1			; Mouse X add/sub
mouse_y		ds.w 1			; Mouse Y add/sub
extr_3		ds.w 1
extr_4		ds.w 1
extr_5		ds.w 1
sizeof_input	ds.l 0
		finish

; Read as (Controller_1) then add +on_hold or +on_press
Controller_1	equ RAM_InputData
Controller_2	equ RAM_InputData+sizeof_input

; Read WORD in +on_hold or +on_press
JoyUp		equ $0001
JoyDown		equ $0002
JoyLeft		equ $0004
JoyRight	equ $0008
JoyB		equ $0010
JoyC		equ $0020
JoyA		equ $0040
JoyStart	equ $0080
JoyZ		equ $0100
JoyY		equ $0200
JoyX		equ $0400
JoyMode		equ $0800
bitJoyUp	equ 0		; READ THESE AS A WORD
bitJoyDown	equ 1
bitJoyLeft	equ 2
bitJoyRight	equ 3
bitJoyB		equ 4
bitJoyC		equ 5
bitJoyA		equ 6
bitJoyStart	equ 7
bitJoyZ		equ 8
bitJoyY		equ 9
bitJoyX		equ 10
bitJoyMode	equ 11

; Mega Mouse
; Read WORD as +on_hold or +on_press
ClickR		equ $0001
ClickL		equ $0002
ClickM		equ $0004	; US MOUSE ONLY
ClickS		equ $0008	; (Untested)
bitClickR	equ 0
bitClickL	equ 1
bitClickM	equ 2
bitClickS	equ 3

; ====================================================================
; ----------------------------------------------------------------
; MD RAM
;
; NOTE for porting this to Sega CD (or SegaCD+32X):
; From $FFFD00 to $FFFDFF is reserved for the MAIN-CPU's vectors
; ----------------------------------------------------------------

		struct MDRAM_START
	; First pass: empty sizes
	if MOMPASS=1
; RAM_MdSound	ds.l 0
RAM_MdVideo	ds.l 0
RAM_MdSystem	ds.l 0
RAM_MdDreq	ds.l 0
RAM_ModeBuff	ds.l 0
RAM_MdGlobal	ds.l 0
sizeof_mdram	ds.l 0
	else
	; Second pass: sizes are set
; RAM_MdSound	ds.b sizeof_mdsnd-RAM_MdSound
RAM_MdVideo	ds.b sizeof_mdvid-RAM_MdVideo
RAM_MdSystem	ds.b sizeof_mdsys-RAM_MdSystem
RAM_MdDreq	ds.b sizeof_dreq
RAM_ModeBuff	ds.b MAX_MDERAM
RAM_MdGlobal	ds.b sizeof_mdglbl-RAM_MdGlobal	; code/global.asm
sizeof_mdram	ds.l 0
	endif

	if MOMPASS=7
		message "MD RAM: \{(MDRAM_START)&$FFFFFF}-\{(sizeof_mdram)&$FFFFFF}"
	endif
		finish

