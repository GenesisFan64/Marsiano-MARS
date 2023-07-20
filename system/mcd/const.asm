; ====================================================================
; ----------------------------------------------------------------
; Sega CD shared constants
; ----------------------------------------------------------------

; ====================================================================
; ----------------------------------------------------------------
; Register area
;
; MAIN-CPU: $A12000 (sysmcd_reg)
; SUB-CPU:  $FF8000 (scpu_reg)
; ----------------------------------------------------------------

; -------------
; bits
; -------------

bitWRamMode	equ 2		;2M | 1M

; -------------
; Registers
; -------------

mcd_memory	equ $03
mcd_hint	equ $06		; [W] HBlank RAM redirection-jump (MAIN CPU ONLY)
mcd_comm_m	equ $0E		; [B] Comm port MAIN R/W | SUB READ ONLY
mcd_comm_s	equ $0F		; [B] Comm port SUB R/W  | MAIN READ ONLY
mcd_dcomm_m	equ $10		; [S: $0E] Communication MAIN
mcd_dcomm_s	equ $20		; [S: $0E] Communication SUB

; MemoryMode	equ	$02		;WORD
; CommMain	equ	$0E		;BYTE
; CommSub		equ	$0F		;BYTE
; CommDataM	equ	$10		;Array (size: $E)
; CommDataS	equ	$20		;Array (size: $E)

; ; =================================================================
; ; ----------------------------------------
; ; SUB CPU ONLY
; ; ----------------------------------------
;
; ; -------------
; ; PCM
; ; -------------
;
; PCM		equ	$FF0000
; ENV		equ	$01		; Envelope
; PAN		equ	$03		; Panning (%RRRRLLLL, and negative)
; FDL		equ	$05		; Sample rate $00xx
; FDH		equ	$07		; Sample rate $xx00
; LSL		equ	$09		; Loop address $xx00
; LSH		equ	$0B		; Loop address $00xx
; ST		equ	$0D		; Start address (only $x0, $x000)
; Ctrl		equ	$0F		; Control register ($80 - Bank select, $C0 - Channel select)
; OnOff		equ	$11		; Channel On/Off (BITS: 1 - off, 0 - on)

; =================================================================
