; ====================================================================
; ----------------------------------------------------------------
; MD/MARS shared constants
; ----------------------------------------------------------------

MAX_MDDMATSK	equ 16		; MAX DMA transfer requests for VBlank
MAX_MDDREQ	equ $400	; MAX size for DREQ RAM transfer in WORDS ($08 bytes aligned)

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MDRAM_START	equ $FFFF9000	; Start of working MD RAM
MAX_MDERAM	equ $800	; MAX RAM for current screen mode
varNullVram	equ $7FF	; Default Blank tile for some video routines

; ====================================================================
; ----------------------------------------------------------------
; Structures
; ----------------------------------------------------------------

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; Read as (Controller_1)
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
RAM_SaveData	ds.b $200			; SRAM data cache
RAM_SysRandVal	ds.l 1				; Random value
RAM_SysRandSeed	ds.l 1				; Randomness seed
RAM_initflug	ds.l 1				; "INIT" flag
RAM_MdMarsVInt	ds.w 3				; VBlank jump (JMP xxxx xxxx)
RAM_MdMarsHint	ds.w 3				; HBlank jump (JMP xxxx xxxx)
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
RAM_HorScroll	ds.l 240		; DMA'd Horizontal scroll data
RAM_VerScroll	ds.l 320/16		; DMA'd Vertical scroll data
RAM_SpriteData	ds.w 8*70		; DMA'd Sprites
RAM_MdMarsPalFd	ds.w 256		; Target 32X palette for FadeIn/Out
RAM_VdpDmaList	ds.w 7*MAX_MDDMATSK
RAM_VidPrntList	ds.w 3*64		; Video_Print list: Address, Type
RAM_VdpDmaIndx	ds.w 1
RAM_VdpDmaMod	ds.w 1
RAM_VidPrntVram	ds.w 1			; Default VRAM location for ASCII text used by Video_Print
RAM_ReqFadeMars	ds.w 1			; FadeIn/Out request for 32X palette
RAM_ReqFadeMSpd	ds.w 1			; Increment speed for 32X's fade
RAM_FrameCount	ds.l 1			; Global frame counter
RAM_VdpRegs	ds.b 24			; VDP Register cache
sizeof_mdvid	ds.l 0
		finish

; ====================================================================
; ----------------------------------------------------------------
; 32X control using DREQ
;
; Size for this buffer is set externally as MAX_MDDREQ
; ----------------------------------------------------------------

		struct RAM_MdDreq
RAM_MdMarsPal	ds.w 256
RAM_MdMarsBg	ds.l $10
sizeof_dreqmd	ds.l 0
		finish
	if MOMPASS=7
		message "DREQ RAM: \{(sizeof_dreqmd-RAM_MdDreq)&$FFFFFF} of \{(MAX_MDDREQ)&$FFFFFF}"
	endif

; ====================================================================
; ----------------------------------------------------------------
; MD RAM
;
; *** NOTE ***
; For SEGA CD support:
; $FFFD00 to $FFFDFF is reserved for the MAIN-CPU's vectors
; ----------------------------------------------------------------

		struct MDRAM_START
	if MOMPASS=1				; First pass: empty sizes
RAM_ModeBuff	ds.l 0
RAM_MdSound	ds.l 0
RAM_MdVideo	ds.l 0
RAM_MdSystem	ds.l 0
RAM_MdGlobal	ds.l 0
RAM_MdDreq	ds.l 0
sizeof_mdram	ds.l 0
	else
RAM_ModeBuff	ds.b MAX_MDERAM			; Second pass: sizes are set
RAM_MdSound	ds.b sizeof_mdsnd-RAM_MdSound
RAM_MdVideo	ds.b sizeof_mdvid-RAM_MdVideo
RAM_MdSystem	ds.b sizeof_mdsys-RAM_MdSystem
RAM_MdGlobal	ds.b sizeof_mdglbl-RAM_MdGlobal
RAM_MdDreq	ds.b MAX_MDDREQ
sizeof_mdram	ds.l 0
	endif

	if MOMPASS=7
		message "MD RAM: \{(MDRAM_START)&$FFFFFF}-\{(sizeof_mdram)&$FFFFFF}"
	endif
		finish
