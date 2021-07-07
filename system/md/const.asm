; ====================================================================
; ----------------------------------------------------------------
; MD/MARS shared constants
; ----------------------------------------------------------------

; MD to MARS Task transfer settings
MAX_MDTSKARG	equ 8			; MAX MD task arguments (FIXED)
MAX_MDTASKS	equ 16			; MAX requests from MD to here

; ====================================================================
; ----------------------------------------------------------------
; MD Sound
; ----------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; MD Video
; ----------------------------------------------------------------

; ------------------------------------------------
; vdp_ctrl READ bits
; ------------------------------------------------

bitHint		equ 2
bitVint		equ 3
bitDma		equ 1

; ------------------------------------------------
; VDP register variables
; ------------------------------------------------

; Register $80
HVStop		equ $02
HintEnbl	equ $10
bitHVStop	equ 1
bitHintEnbl	equ 4

; Register $81
DispEnbl 	equ $40
VintEnbl 	equ $20
DmaEnbl		equ $10
bitDispEnbl	equ 6
bitVintEnbl	equ 5
bitDmaEnbl	equ 4
bitV30		equ 3

; ====================================================================
; --------------------------------------------------------
; Contoller reading (call System_Input first)
; --------------------------------------------------------

; structure is below
Controller_1	equ RAM_InputData
Controller_2	equ RAM_InputData+sizeof_input

; read as full WORD (on_hold or on_press)
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

; right byte $00xx
bitJoyUp	equ 0
bitJoyDown	equ 1
bitJoyLeft	equ 2
bitJoyRight	equ 3
bitJoyB		equ 4
bitJoyC		equ 5
bitJoyA		equ 6
bitJoyStart	equ 7

; left byte $xx00
bitJoyZ		equ 0
bitJoyY		equ 1
bitJoyX		equ 2
bitJoyMode	equ 3

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MDRAM_START	equ $FFFF8800		; Start of working MD RAM (below it is free for CODE or decompression output)
MAX_MDERAM	equ $800		; MAX RAM for current screen mode (title,menu,or gameplay...)
varNullVram	equ $7FF		; Default Blank tile for some video routines

; ====================================================================
; ----------------------------------------------------------------
; Structures
; ----------------------------------------------------------------

; Controller buffer data (after calling System_Input)
		struct 0
pad_id		ds.b 1			; Controller ID
pad_ver		ds.b 1			; Controller type/revision: (ex. 0-3button 1-6button)
on_hold		ds.w 1			; User HOLD bits
on_press	ds.w 1			; User PRESSED bits
sizeof_input	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; System RAM
; ----------------------------------------------------------------

		struct RAM_MdSystem
RAM_InputData	ds.b sizeof_input*4		; Input data section
RAM_SaveData	ds.b $200			; Save data cache (for SRAM)
RAM_MdMarsTskM	ds.l MAX_MDTSKARG*MAX_MDTASKS	; Queue task list for MASTER SH2
RAM_MdMarsTskS	ds.l MAX_MDTSKARG*MAX_MDTASKS	; Queue task list for SLAVE SH2
RAM_MdMarsTsSgl	ds.l MAX_MDTSKARG		; Single task request for 32X, shared for both Mst and Slv
RAM_FrameCount	ds.l 1				; Global frame counter
RAM_SysRandVal	ds.l 1				; Random value
RAM_SysRandSeed	ds.l 1				; Randomness seed
RAM_initflug	ds.l 1				; "INIT" flag
RAM_MdMarsVInt	ds.w 3				; VBlank jump (JMP xxxx xxxx)
RAM_MdMarsHint	ds.w 3				; HBlank jump (JMP xxxx xxxx)
RAM_MdMarsTCntM	ds.w 1				; Counter for MASTER CPU's task list
RAM_MdMarsTCntS	ds.w 1				; Counter for SLAVE CPU's task list
RAM_SysFlags	ds.w 1				; Game engine flags (note: it's a byte)
sizeof_mdsys	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; Sound 68k RAM
; ----------------------------------------------------------------

		struct RAM_MdSound
RAM_SndSaveReg	ds.l 8
sizeof_mdsnd	ds.l 0
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; Video RAM
; ----------------------------------------------------------------

		struct RAM_MdVideo
RAM_VidPrntVram	ds.w 1			; Default VRAM location for ASCII text used by Video_Print
RAM_VidPrntList	ds.w 3*64		; Video_Print list: Address, Type
RAM_VdpRegs	ds.b 24			; VDP Register cache
sizeof_mdvid	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; MD RAM
;
; NOTE: If using MCD Uses $FFFD00-$FFFDFF, and
; stack point is $FFFD00
; ----------------------------------------------------------------

		struct MDRAM_START
	if MOMPASS=1				; First pass: empty sizes
RAM_ModeBuff	ds.l 0
RAM_MdSound	ds.l 0
RAM_MdVideo	ds.l 0
RAM_MdSystem	ds.l 0
RAM_MdGlobal	ds.l 0
sizeof_mdram	ds.l 0
	else
RAM_ModeBuff	ds.b MAX_MDERAM			; Second pass: sizes are set
RAM_MdSound	ds.b sizeof_mdsnd-RAM_MdSound
RAM_MdVideo	ds.b sizeof_mdvid-RAM_MdVideo
RAM_MdSystem	ds.b sizeof_mdsys-RAM_MdSystem
RAM_MdGlobal	ds.b sizeof_mdglbl-RAM_MdGlobal
sizeof_mdram	ds.l 0
	endif

	if MOMPASS=7
		message "MD RAM ends at: \{((sizeof_mdram)&$FFFFFF)}"
	endif
		finish
