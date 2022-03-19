; ====================================================================
; ----------------------------------------------------------------
; MD/MARS shared constants
; ----------------------------------------------------------------

MAX_MDDMATSK	equ 16		; MAX DMA transfer requests for VBlank
MAX_MODELS	equ 16

; ====================================================================
; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MDRAM_START	equ $FFFF9000	; Start of working MD RAM
MAX_MDERAM	equ $800	; MAX RAM for current screen mode
varNullVram	equ $7FF	; Default Blank tile for some video routines

; ====================================================================
; ----------------------------------------------------------------
; Shared structs for both Genesis and 32X
; ----------------------------------------------------------------

; model objects
;
		struct 0
mdl_data	ds.l 1			; Model data pointer, if zero: no model
mdl_option	ds.l 1			; Model options: pixelvalue add
mdl_x_pos	ds.l 1			; X position $000000.00
mdl_y_pos	ds.l 1			; Y position $000000.00
mdl_z_pos	ds.l 1			; Z position $000000.00
mdl_x_rot	ds.l 1			; X rotation $000000.00
mdl_y_rot	ds.l 1			; Y rotation $000000.00
mdl_z_rot	ds.l 1			; Z rotation $000000.00
; mdl_animdata	ds.l 1			; Model animation data pointer, zero: no animation
; mdl_animframe	ds.l 1			; Current frame in animation
; mdl_animtimer	ds.l 1			; Animation timer
; mdl_animspd	ds.l 1			; Animation USER speed setting
sizeof_mdlobj	ds.l 0
		finish

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
bitJoyUp	equ 0		; right byte $00xx
bitJoyDown	equ 1
bitJoyLeft	equ 2
bitJoyRight	equ 3
bitJoyB		equ 4
bitJoyC		equ 5
bitJoyA		equ 6
bitJoyStart	equ 7
bitJoyZ		equ 0		; left byte $xx00 (Read Full WORD and shift 8 bits to the right)
bitJoyY		equ 1
bitJoyX		equ 2
bitJoyMode	equ 3

; Mega Mouse
; Read WORD in +on_hold or +on_press
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
; System RAM
; ----------------------------------------------------------------

		struct RAM_MdSystem
RAM_InputData	ds.b sizeof_input*4		; Input data section
RAM_SaveData	ds.b $200			; SRAM data cache
RAM_DmaCode	ds.b $180
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
RAM_SndSaveReg	ds.l 8			; Backup registers here instead of stack (TODO)
sizeof_mdsnd	ds.l 0
		finish
		
; ====================================================================
; ----------------------------------------------------------------
; Video RAM
; ----------------------------------------------------------------

			struct RAM_MdVideo
RAM_HorScroll		ds.l 240		; DMA Horizontal scroll data
RAM_VerScroll		ds.l 320/16		; DMA Vertical scroll data (TODO: check if this is the correct size)
RAM_Sprites		ds.w 8*70		; DMA Sprites
RAM_Palette		ds.w 64			; DMA palette
RAM_MdMarsPalFd		ds.w 256		; Target 32X palette for FadeIn/Out
RAM_PaletteFd		ds.w 64			; Target MD palette for FadeIn/Out
RAM_VdpDmaList		ds.w 7*MAX_MDDMATSK	; DMA BLAST Transfer list for VBlank
RAM_VidPrntList		ds.w 3*64		; Video_Print list: Address, Type
RAM_VdpDmaIndx		ds.w 1			; Current index in DMA BLAST list
RAM_VdpDmaMod		ds.w 1			; Mid-write flag (just to be safe)
RAM_VidPrntVram		ds.w 1			; Default VRAM location for ASCII text used by Video_Print
RAM_FadeMdReq		ds.w 1			; FadeIn/Out request for Genesis palette (01-FadeIn 02-FadeOut)
RAM_FadeMdIncr		ds.w 1			; Fading increment count
RAM_FadeMdDelay		ds.w 1			; Fading delay
RAM_FadeMdTmr		ds.w 1			; Fading delay timer (Write to both FadeMdDel and here)
RAM_FadeMarsReq		ds.w 1			; Same thing but for 32X's 256-color (01-FadeIn 02-FadeOut)
RAM_FadeMarsIncr	ds.w 1			; (Hint: Set to 4 to syncronize Genesis FadeIn/Out)
RAM_FadeMarsDelay	ds.w 1
RAM_FadeMarsTmr		ds.w 1
RAM_FrameCount		ds.l 1			; Frames counter
RAM_VdpRegs		ds.b 24			; VDP Register cache
sizeof_mdvid		ds.l 0
			finish

; ; ====================================================================
; ; ----------------------------------------------------------------
; ; 32X control using DREQ
; ;
; ; *** CALL System_MdMarsDreq AFTER DOING ANY CHANGE
; ; IN THIS AREA, OUTSIDE VBLANK ***
; ;
; ; Size for this buffer is set externally on
; ; the MAX_MDDREQ setting.
; ; ----------------------------------------------------------------
;
; 		struct RAM_MdDreq
; RAM_MdMarsPal	ds.w 256
; RAM_MdMarsBg	ds.l $10
; sizeof_dreqmd	ds.l 0
; 		finish
; 	if MOMPASS=7
; 		message "DREQ RAM: \{(sizeof_dreqmd-RAM_MdDreq)&$FFFFFF} of \{(MAX_MDDREQ)&$FFFFFF}"
; 	endif

; ====================================================================
; ----------------------------------------------------------------
; MD RAM
;
; NOTE for porting this to Sega CD (or SegaCD+32X):
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
RAM_MdDreq	ds.b sizeof_dreq
sizeof_mdram	ds.l 0
	endif

	if MOMPASS=7
		message "MD RAM: \{(MDRAM_START)&$FFFFFF}-\{(sizeof_mdram)&$FFFFFF}"
	endif
		finish
