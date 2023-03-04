; ====================================================================
; --------------------------------------------------------
; GEMA/Nikona Z80 code v0.5
; (C)2023 GenesisFan64
;
; TIP:
; For the 32X put this on the 880000 area as this is
; only loaded once.
; --------------------------------------------------------

Z80_TOP:
		cpu Z80		; [AS] Enter Z80
		phase 0		; [AS]

; --------------------------------------------------------
; SETTINGS
; --------------------------------------------------------

; !! = leave as is unless you know what you are doing.
MAX_TRKCHN	equ 17		; !! Max Internal tracker channels: 4PSG + 6FM + 7PWM (**AFFECTS 32X SIDE)
MAX_TRFRPZ	equ 8		; !! Max transferRom packets(bytes) (**AFFECTS WAVE QUALITY)
MAX_RCACH	equ 40h		; Max storage for ROM pattern data *1-BIT SIZES ONLY, MUST BE ALIGNED*
MAX_TBLSIZE	equ 10h		; Max size for chip tables
MAX_INS		equ 16		; Max Cache'd ROM instruments per track
MAX_BLOCKS	equ 24		; Max Cache'd ROM blocks per track
MAX_HEADS	equ 24		; Max Cache'd ROM headers per track
ZSET_TESTME	equ 0		; Set to 1 to "hear"-test the DAC playback

; --------------------------------------------------------
; Structs
; --------------------------------------------------------

; trkBuff struct: 00h-30h
; unused bytes are free.
;
; trk_Status: %ERPx xxx0
; E - enabled
; R - Init|Restart track
; P - refill-on-playback
; 0 - Use global sub-beat
trk_status	equ 00h	; ** Track Status and flags (MUST BE at 00h)
trk_seqId	equ 01h ; ** Track ID to play.
trk_setBlk	equ 02h	; ** Start on this block
trk_tickSet	equ 03h	; ** Ticks for this track
trk_Blocks	equ 04h ; [W] Current track's blocks
trk_Patt	equ 06h ; [W] Current track's heads and patterns
trk_Instr	equ 08h ; [W] Current track's instruments
trk_Read	equ 0Ah	; [W] Track current pattern-read pos
trk_Rows	equ 0Ch	; [W] Track current row length
trk_cachHalf	equ 0Eh ; ROM-cache halfcheck
trk_cachInc	equ 0Fh ; ROM-cache increment
trk_rowPause	equ 10h	; Row-pause timer
trk_tickTmr	equ 11h	; Ticks timer
trk_currBlk	equ 12h	; Current block
trk_Panning	equ 13h ; Global panning for this track %LR000000
trk_Priority	equ 14h ; Priority level for this buffer
trk_LastBkIns	equ 15h
trk_LastBkBlk	equ 16h
trk_LastBkHdrs	equ 17h
trk_MaxChnls	equ 1Ch	; MAX avaialble channels
trk_MaxBlks	equ 1Dh ;     ----      blocks
trk_MaxHdrs	equ 1Eh ;     ----      headers
trk_MaxIns	equ 1Fh ;     ----      intruments
trk_RomCPatt	equ 20h ; [3b] ROM current pattern data to be cache'd
trk_RomPatt	equ 23h ; [3b] ROM TOP pattern data
trk_ChnList	equ 26h ; ** [W] Pointer to channel list for this buffer
trk_ChnCBlk	equ 28h ; ** [W] Pointer to block storage
trk_ChnCHead	equ 2Ah ; ** [W] Pointer to header storage
trk_ChnCIns	equ 2Ch	; ** [W] Pointer to intrument storage (ALWAYS used)
trk_ChnCach	equ 2Eh	; ** [W] Pointer to pattern storage

; chnBuff struct, 8 bytes ONLY
;
; chnl_Flags: LR00evin
; LR - Left/Right panning bits (REVERSE: 0-ON 1-OFF)
; e  - Effect*
; v  - Volume*
; i  - Intrument*
; n  - Note*
; * Gets cleared later.

chnl_Flags	equ 0	; Playback flags
chnl_Chip	equ 1	; Current Chip ID + priority for this channel
chnl_Note	equ 2
chnl_Ins	equ 3	; Starting from 01h
chnl_Vol	equ 4	; MAX to MIN: 40h-00h
chnl_EffId	equ 5
chnl_EffArg	equ 6
chnl_Type	equ 7	; Impulse-note update bits

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; Z80 opcode labels for the wave playback routines:
zopcNop		equ	00h
zopcEx		equ	08h
zopcRet		equ 	0C9h
zopcExx		equ	0D9h		; (dac_me ONLY)
zopcPushAf	equ	0F5h		; (dac_fill ONLY)

; PSG external control
; GEMS style.
COM		equ	0
LEV		equ	4
ATK		equ	8
DKY		equ	12
SLV		equ	16
RRT		equ	20
MODE		equ	24
DTL		equ	28
DTH		equ	32
ALV		equ	36
FLG		equ	40
TMR		equ	44
PVOL		equ	48
PARP		equ	52
PTMR		equ	56

; PWM control
PWCOM		equ	0
PWPTH_V		equ	8	; Volume | Pitch MSB (VVVVVVPPb)
PWPHL		equ	16	; Pitch LSB
PWOUTF		equ	24	; Output mode/bits | 32-bit address (%SlLRxiix) ii=$02 or $06
PWINSH		equ	32	; **
PWINSM		equ	40	; **
PWINSL		equ	48	; **

; ====================================================================
; --------------------------------------------------------
; Code starts here
; --------------------------------------------------------

		di			; Disable interrputs
		im	1		; Interrupt mode 1
		ld	sp,2000h	; Set stack at the end of Z80
		jr	z80_init	; Jump to z80_init

; --------------------------------------------------------
; RST 8 (dac_me)
; *** self-modifiable code ***
;
; Writes wave data to DAC using data stored
; on the wave buffer, call this routine every 6 or 8
; opcodes to keep the samplerate stable.
;
; Input (EXX):
;  c - WAVE buffer MSB
; de - Pitch (xx.00)
; h  - WAVE buffer LSB (as xx.00)
;
; Uses (EXX):
; b
;
; Notes:
; ONLY USE dac_on and dac_off to control
; wave playback.
;
; call dac_on to enable wave playback, locks FM6
; and
; call dac_off to disable and enable FM6.
; --------------------------------------------------------

; Samplerate is at 16000hz with minimal quality loss.
		org 8
dac_me:		exx			; <-- this changes between EXX(play) and RET(stop)
		ex	af,af'		; Swap af
		ld	b,l		; Save pitch .00 to b
		ld	l,h		; l - xx.00 to 00xx
		ld	h,c		; h - Wave buffer MSB + 00xx
		ld	a,2Ah		; YM register 2Ah
		ld	(Zym_ctrl_1),a	; Set DAC write
		ld	a,(hl)		; Now read byte from the wave buffer
		ld	(Zym_data_1),a	; and write it to DAC
		ld	h,l		; get hl back
		ld	l,b		; Get .00 back from b to l
		add	hl,de		; Pitch increment hl
		ex	af,af'		; return af
		exx
		ret

; --------------------------------------------------------
; 1Ch
sbeatAcc	dw 0		; Accumulates on each tick to trigger the sub beats
sbeatPtck	dw 200+32	; Default global subbeats (-32 for PAL)

; --------------------------------------------------------
; RST 20h (dac_me)
; *** self-modifiable code ***
;
; Checks if the WAVE cache needs refilling to keep
; it playing.
;
; *** THIS BREAKS ALL REGISTERS IF REFILL
; IS REQUESTED ***
; --------------------------------------------------------

		org 20h
dac_fill:	push	af		; <-- changes between PUSH AF(playing) and RET(stopped)
		ld	a,(dDacFifoMid)	; a - Get mid-way value
		exx
		xor	h		; Grab LSB.00
		exx
		and	80h		; Check if bit changed
		jp	nz,dac_refill	; If yes: Refill and update LSB to check
		pop	af
		ret

; --------------------------------------------------------
; 02Eh
currTickBits	db 0			; 2Eh: Current Tick/Subbeat flags (000000BTb B-beat, T-tick)
dDacFifoMid	db 0			; 2Fh: WAVE play halfway refill flag (00h/80h)
dDacPntr	db 0,0,0		; 30h: WAVE play current ROM position
dDacCntr	db 0,0,0		; 33h: WAVE play length counter
x68ksrclsb	db 0			; 36h: transferRom temporal LSB
x68ksrcmid	db 0			; 37h: transferRom temporal MID

; --------------------------------------------------------
; Z80 Interrupt at 0038h
; --------------------------------------------------------

		org 38h			; Align 38h
		ld	(tickSpSet),sp	; Write TICK flag using sp (xx1F, use tickFlag+1)
		di			; Disable interrupt
		ret

; --------------------------------------------------------
; 03Eh
trkListPage	db 0			; 3Eh: Current PSGN mode
marsUpd		db 0			; 3Fh: Flag to request a PWM transfer

; --------------------------------------------------------
; 68K Read/Write area at 40h
; --------------------------------------------------------

		org 40h
commZfifo	ds 40h			; Buffer for commands: 40h bytes
commZWrite	db 0			; 80h: cmd fifo wptr (from 68k)
commZRomBlk	db 0			; 81h: 68k ROM block flag
marsBlock	db 0			; 82h: flag to BLOCK PWM transfers.

; --------------------------------------------------------
; Initilize
; --------------------------------------------------------

z80_init:
		call	gema_init		; Init values
		ei

; --------------------------------------------------------
; MAIN LOOP
; --------------------------------------------------------

drv_loop:
		rst	8
		call	get_tick		; Check for Tick on VBlank
		rst	20h			; Refill wave
		rst	8
		ld	b,0			; b - Reset current flags (beat|tick)
		ld	a,(tickCnt)
		sub	1
		jr	c,.noticks
		ld	(tickCnt),a
		call	chip_env		; Process PSG and YM
		call	get_tick		; Check for another tick
		ld 	b,01b			; Set TICK (01b) flag, and clear BEAT
.noticks:
		ld	a,(sbeatAcc+1)		; check beat counter (scaled by tempo)
		sub	1
		jr	c,.nobeats
		rst	8
		ld	(sbeatAcc+1),a		; 1/24 beat passed.
		set	1,b			; Set BEAT (10b) flag
.nobeats:
		rst	8
		ld	a,b			; Any beat/tick change?
		or	a
		jr	z,.neither
		ld	(currTickBits),a	; Save BEAT/TICK bits
		rst	8
		call	get_tick
		call	set_chips		; Send changes to sound chips
		call	get_tick
		rst	8
		call	upd_track		; Update track data
		call	get_tick
.neither:
		call	ex_comm			; External communication
		call	get_tick
.next_cmd:
		ld	a,(commZWrite)		; Check command READ and WRITE indexes
		ld	b,a
		ld	a,(commZRead)
		cp	b
		jr	z,drv_loop		; If both are equal: no requests
		rst	8
		call	.grab_arg
		cp	-1			; Got -1? (Start of command)
		jr	nz,drv_loop
		call	.grab_arg		; Read command number
		add	a,a			; * 2
		ld	hl,.list		; Then jump to one of these...
		rst	8
		ld	d,0
		ld	e,a
		add	hl,de
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		rst	8
		ld	l,a
		jp	(hl)

; --------------------------------------------------------
; Read cmd byte, auto re-rolls to 3Fh
; --------------------------------------------------------

.grab_arg:
		push	de
		push	hl
.getcbytel:
		ld	a,(commZWrite)
		ld	d,a
		rst	8
		ld	a,(commZRead)
		cp	d
		jr	z,.getcbytel	; wait until these counters change.
		rst	8
		ld	d,0
		ld	e,a
		ld	hl,commZfifo
		add	hl,de
		rst	8
		inc	a
		and	3Fh		; ** command list limit
		ld	(commZRead),a
		ld	a,(hl)		; a - the byte we got
		pop	hl
		pop	de
		ret

; --------------------------------------------------------

.list:
		dw .cmnd_0		; 00h -
		dw .cmnd_1		; 01h - Play by track number
		dw .cmnd_2		; 02h - Stop by track number
		dw .cmnd_0		; 03h - Resume by track number
		dw .cmnd_0		; 04h -
		dw .cmnd_0		; 05h -
		dw .cmnd_0		; 06h -
		dw .cmnd_0		; 07h -
		dw .cmnd_8		; 08h - Stop ALL
		dw .cmnd_0		; 09h -
		dw .cmnd_0		; 0Ah -
		dw .cmnd_0		; 0Bh -
		dw .cmnd_C		; 0Ch - Set GLOBAL sub-beats
		dw .cmnd_0		; 0Dh -
		dw .cmnd_0		; 0Eh -
		dw .cmnd_0		; 0Fh -

; --------------------------------------------------------
; Command 00h
;
; Reserved for TESTING purposes.
; --------------------------------------------------------

; TEST COMMAND

.cmnd_0:
; 		jp	.next_cmd

; 	if MARS
; 		ld	iy,pwmcom
; 		ld	hl,.tempset
; 		ld	de,8
; 		ld	b,e
; 		dec	b
; .copyme:
; 		ld	a,(hl)
; 		ld	(iy),a
; 		inc	hl
; 		add	iy,de
; 		djnz	.copyme
; 		ld	a,1
; 		ld	(marsUpd),a
; 		jp	.next_cmd
; .tempset:
; 		db 0001b
; 		db 01h
; 		db 00h
; 		db 11110000b|02h
; 		db (SmpIns_TEST>>16)&0FFh
; 		db (SmpIns_TEST>>8)&0FFh
; 		db (SmpIns_TEST)&0FFh
; 	else
; 		jp	.next_cmd
; 	endif

		call	dac_off
		ld	iy,wave_Start
		ld	hl,.tempset
		ld	b,0Bh
.copyme:
		ld	a,(hl)
		ld	(iy),a
		inc	hl
		inc	iy
		djnz	.copyme
		ld	hl,100h
		ld	(wave_Pitch),hl
		ld	a,1
		ld	(wave_Flags),a
		call	dac_play
		jp	.next_cmd
.tempset:
		dw TEST_WAVE&0FFFFh
		db TEST_WAVE>>16&0FFh
		dw (TEST_WAVE_E-TEST_WAVE)&0FFFFh
		db (TEST_WAVE_E-TEST_WAVE)>>16&0FFh
		dw 0
		db 0
		dw 0100h;+(ZSET_WTUNE)

; --------------------------------------------------------
; Command 01h:
;
; Make new track by sequence number
; --------------------------------------------------------

.cmnd_1:
		call	.grab_arg	; d0: Sequence ID
		ld	c,a		; copy to c
		call	.srch_frid	; Search buffer with same ID or FREE to use.
		cp	-1
		jp	z,.next_cmd	; Return if failed.
		ld	(hl),0C0h	; Flags: Enable+Restart bits
		inc	hl
		ld	(hl),c		; ** write trk_seqId
		call	get_RomTrcks
		jp	.next_cmd

; --------------------------------------------------------
; Command 02h:
;
; Stop track by sequence number
; --------------------------------------------------------

.cmnd_2:
		call	.grab_arg	; d0: Sequence ID
		ld	c,a		; copy to c
		call	.srch_frid
		cp	-1
		jp	z,.next_cmd
		ld	a,(hl)
		bit	7,a
		jp	z,.next_cmd
		ld	(hl),-1		; Flags | Enable+Restart bits
		inc	hl
		ld	(hl),-1		; Reset seqId
		rst	8
		jp	.next_cmd

; --------------------------------------------------------
; Command 08h:
;
; Stop ALL tracks
; --------------------------------------------------------

.cmnd_8:
		ld	ix,nikona_BuffList
.next_sall:
		ld	a,(ix)
		cp	-1
		jp	z,.next_cmd
		ld	h,(ix+1)
		ld	l,a
		ld	a,(hl)
		bit	7,a
		jr	z,.not_on
		ld	(hl),-1		; Flags | Enable+Restart bits
		inc	hl
		ld	(hl),-1		; Reset seqId
.not_on:
		ld	de,10h
		add	ix,de
		jp	.next_sall

; --------------------------------------------------------
; Command 0Ch:
;
; Set global sub-beats
; --------------------------------------------------------

.cmnd_C:
		call	.grab_arg	; d0.w: $00xx
		ld	c,a
		call	.grab_arg	; d0.w: $xx00
		ld	(sbeatPtck+1),a
		ld	a,c
		ld	(sbeatPtck),a
		jp	.next_cmd

; ------------------------------------------------

.srch_frid:
		ld	ix,nikona_BuffList
		ld	de,10h
.next:
		ld	a,(ix)
		cp	-1
		ret	z
		ld	h,(ix+1)
		ld	l,a
		add	ix,de
		inc	hl
		rst	8
		ld	a,(hl)		; ** a - trk_Id
		dec	hl
		cp	c
		jr	z,.found
		ld	a,(hl)		; ** a - trk_status
		or	a
		jp	m,.next
.found:
		rst	8
		xor	a
		ret

; ====================================================================
; ----------------------------------------------------------------
; MAIN Playback section
; ----------------------------------------------------------------

; ============================================================
; --------------------------------------------------------
; Read INTERNAL mini-impulse-tracker data
; --------------------------------------------------------

upd_track:
		rst	20h			; Refill wave
		ld	iy,nikona_BuffList
.trk_buffrs:
		rst	8
		ld	a,(iy)
		cp	-1
		ret	z
		push	iy
		ld	l,(iy)
		ld	h,(iy+1)
		call	.read_track
		rst	8
		pop	iy
		ld	de,10h
		add	iy,de
		jr	.trk_buffrs

; ----------------------------------------
; iy - Track buffer

.read_track:
		rst	8
		push	hl
		pop	iy
		ld	b,(iy+trk_status)	; b - Track status and settings
		bit	7,b			; bit7: Track active?
		ret	z
		cp	-1			; Mid-silence request?
		ret	z
		ld	a,(currTickBits)	; a - Tick/Beat bits
		bit	0,b			; bit0: This track uses Beats?
		jr	z,.sfxmd
		bit	1,a			; BEAT passed?
		ret	z			;
		rst	8
.sfxmd:
		bit	0,a			; TICK passed?
		ret	z
	; *** Start reading notes ***
		bit	6,b			; bit6: Restart/First time?
		call	nz,.first_fill
		bit	5,b			; bit5: FILL request by effect?
		call	nz,.effect_fill
		ld	a,(iy+trk_tickTmr)	; TICK ex-timer for this track
		dec	a
		ld	(iy+trk_tickTmr),a
		or	a
		ret	nz			; If TICK != 0, Exit
		rst	8
		ld	a,(iy+trk_tickSet)	; Set new tick timer
		ld	(iy+trk_tickTmr),a
		ld	c,(iy+trk_Rows)		; bc - Set row counter
		ld	b,(iy+(trk_Rows+1))
		ld	a,c			; Check rowcount
		or	b
		jr	nz,.row_active
		ld	a,(iy+trk_currBlk)	; If bc == 0: Next block
		inc	a
		ld 	(iy+trk_currBlk),a
		call	.set_track
		cp	-1			; Track finished?
		ret	z
		ld	c,(iy+trk_Rows)
		ld	b,(iy+(trk_Rows+1))
.row_active:
		rst	8
		ld	l,(iy+trk_Read)		; hl - CURRENT pattern to read
		ld	h,(iy+((trk_Read+1)))

; --------------------------------
; Main reading loop
; --------------------------------

.next_note:
		ld	a,(iy+trk_rowPause)	; Check rowtimer
		or	a
		jr	nz,.decrow
		ld	a,(hl)			; Check if timer or note
		or	a
		jr	z,.exit			; If == 00h: exit
		jp	m,.has_note		; 80h-0FFh: note data
		ld	(iy+trk_rowPause),a

; --------------------------------
; Exit
; --------------------------------

.exit:
		rst	8
		call	.inc_cpatt
		ld	(iy+trk_Read),l		; Update read location
		ld	(iy+((trk_Read+1))),h
		jr	.decrow_e
.decrow:
		dec	(iy+trk_rowPause)
.decrow_e:
		dec	bc			; Decrement this row
		ld	(iy+trk_Rows),c		; Write last row and exit.
		ld	(iy+(trk_Rows+1)),b
		ret

; --------------------------------
; New note request
; --------------------------------

.has_note:
		rst	8
		push	bc			; Save rowcount
		ld	c,a			; Backup control|channel to c
		call	.inc_cpatt		; Increment hl
		ld	a,c			; Read control|channel
		ld	e,(iy+trk_ChnList)	; Point to track-data
		ld	d,(iy+(trk_ChnList+1))
		push	de
		pop	ix
		and	00111111b		; Filter channel bits
		add	a,a
		add	a,a
		add	a,a			; * 8
		ld 	d,0
		ld	e,a
		rst	8
		add	ix,de
		ld	b,(ix+chnl_Type)	; b - Current TYPE byte
		bit	6,c			; Next byte is new type?
		jr	z,.old_type
		ld	a,(hl)
		ld	(ix+chnl_Type),a	; Update TYPE byte
		ld	b,a			; Set to b
		call	.inc_cpatt
.old_type:
	; b - evinEVIN
	;     E-effect/V-volume/I-instrument/N-note
	;     evin: byte is already stored on track-channel buffer
	;     EVIN: next byte(s) contain a new value. for eff:2 bytes
		rst	8
		bit	0,b
		jr	z,.no_note
		ld	a,(hl)
		ld	(ix+chnl_Note),a
		call	.inc_cpatt
.no_note:
		bit	1,b
		jr	z,.no_ins
		ld	a,(hl)
		ld	(ix+chnl_Ins),a
		call	.inc_cpatt
.no_ins:
		bit	2,b
		jr	z,.no_vol
		ld	a,(hl)
		ld	(ix+chnl_Vol),a
		call	.inc_cpatt
.no_vol:
		bit	3,b
		jr	z,.no_eff
		ld	a,(hl)
		ld	(ix+chnl_EffId),a
		call	.inc_cpatt
		rst	8
		ld	a,(hl)
		ld	(ix+chnl_EffArg),a
		call	.inc_cpatt
.no_eff:
		ld	a,b		; Merge the Impulse recycle bits into main bits
		rrca
		rrca
		rrca
		rrca
		and	00001111b
		ld	c,a
		ld	a,b
		and	00001111b
		or	c
		rst	8
		ld	c,a
		ld	a,(ix+chnl_Flags)
		or	c
		ld	(ix+chnl_Flags),a
		pop	bc		; Restore rowcount

	; Check for effects that affect
	; internal playback:
	; Jump, Ticks, etc.
		and	1000b		; Only check for the EFFECT bit
		jp	z,.next_note
		ld	a,(ix+chnl_EffId)
		or	a		; 00h = invalid effect
		jp	z,.next_note
		cp	1		; Effect A: Tick set
		call	z,.eff_A
		cp	2		; Effect B: Position Jump
		call	z,.eff_B
		cp	3		; Effect C: Pattern break
		jp	z,.eff_C	; <-- JUMP and exit.
		jp	.next_note

; ----------------------------------------
; Effect A: Set ticks
; ----------------------------------------

.eff_A:
		rst	8
		ld	e,(ix+chnl_EffArg)	; e - ticks number
		ld	(iy+trk_tickSet),e	; set for both Set and Timer.
		ld	(iy+trk_tickTmr),e
		res	3,(ix+chnl_Flags)	; <-- Clear EFFECT bit
		ret

; ----------------------------------------
; Effect B: jump to a new block
; ----------------------------------------

.eff_B:
		push	af			; Save Flagbits
		ld	e,(ix+chnl_EffArg)	; e - Block SLOT to jump
		ld 	(iy+trk_currBlk),e
		rst	8
		ld	(iy+trk_rowPause),0	; Reset rowpause
		res	3,(ix+chnl_Flags)	; <-- Clear EFFECT bit
		set	5,(iy+trk_status)	; set fill-from-effect flag on exit
		pop	af
		ret

; ----------------------------------------
; Effect C: Pattern break/exit
;
; Only used on SFX, arguments ignored.
; ----------------------------------------

.eff_C:
		jp	.track_end

; ----------------------------------------
; Increment the current patt position
; and recieve more data
;
; Breaks:
; a,e
; ----------------------------------------

.inc_cpatt:
		ld	e,(iy+trk_ChnCach)
		ld	a,l
		inc	a
		and	MAX_RCACH-1
		cp	MAX_RCACH-2	; RAN OUT of bytes?
		jr	nc,.ran_out
		or	e
		ld	l,a
		ret
.ran_out:
		ld	l,(iy+trk_ChnCach)
		push	hl
		push	bc
		ld	b,0
		ld	c,a
		rst	8
		ld	e,l
		ld	d,h
		ld	l,(iy+trk_RomCPatt)
		ld	h,(iy+(trk_RomCPatt+1))
		ld	a,(iy+(trk_RomCPatt+2))
		add	hl,bc
		adc	a,0
		ld	(iy+trk_RomCPatt),l
		ld	(iy+(trk_RomCPatt+1)),h
		rst	8
		ld	(iy+(trk_RomCPatt+2)),a
		ld	bc,MAX_RCACH
		call	transferRom	; *** ROM ACCESS ***
		pop	bc
		pop	hl
		ret

; ----------------------------------------
; Set track pattern by trk_currBlk
; ----------------------------------------

.set_track:
		rst	8
		ld	d,0
		ld	e,(iy+trk_currBlk)	; e - current block
		ld	l,(iy+trk_Blocks)	; hl - block data
		ld	h,(iy+(trk_Blocks+1))
		add	hl,de
		ld	a,(hl)			; Read byte
		cp	-1			; If block == -1, end track
		jp	z,.track_end
		rst	20h			; dacfill
		rlca
		rlca
		ld	d,a
		and	11111100b
		ld	e,a
		ld	a,d
		and	00000011b
		ld	d,a
		ld	l,(iy+trk_Patt)		; Read CACHE patt heads
		ld	h,(iy+(trk_Patt+1))
		rst	8
		add	hl,de
		ld	e,(hl)			; de - Pos
		inc	hl
		ld	d,(hl)
		inc	hl
		ld	a,(hl)
		inc	hl
		ld	(iy+trk_Rows),a
		rst	8
		ld	a,(hl)
		inc	hl
		ld	(iy+(trk_Rows+1)),a
		ld	l,(iy+trk_RomPatt)	; Transfer FIRST patt
		ld	h,(iy+(trk_RomPatt+1))	; packet
		rst	8
		ld	a,(iy+(trk_RomPatt+2))
		add	hl,de
		adc	a,0
		ld	(iy+trk_RomCPatt),l
		ld	(iy+(trk_RomCPatt+1)),h
		ld	(iy+(trk_RomCPatt+2)),a
		ld	e,(iy+trk_ChnCach)
		ld	d,(iy+(trk_ChnCach+1))
		rst	8
		ld	(iy+trk_Read),e
		ld	(iy+(trk_Read+1)),d
		ld	c,MAX_RCACH
		ld	(iy+trk_cachHalf),0
		ld	(iy+trk_rowPause),0
		jp	transferRom		; ** ROM access **

; ----------------------------------------

.track_end:
		call	track_out
		rst	8
		ld	(iy+trk_rowPause),0
		ld	(iy+trk_tickTmr),0
		ld	(iy+trk_Status),0
		ld	bc,0			; Set bc rowcount to 0
		rst	8
		ld	a,-1			; Return -1
		ret

; ----------------------------------------
; Track refill
; ----------------------------------------

.effect_fill:
		res	5,(iy+trk_status)	; Reset refill-from-effect flag
		jp	.set_track

; ----------------------------------------
; Track Start/Reset
;
; iy - Track buffer
; ----------------------------------------

.first_fill:
		res	6,(iy+trk_status)	; Reset FILL flag
		call	track_out
		ld	(iy+trk_tickTmr),1	; <-- Reset tick timer
		ld	a,(iy+trk_setBlk)	; Make start block as current block
		rst	8
		ld 	(iy+trk_currBlk),a	; block
		ld	de,0
		ld	hl,trkListCach		; Read MASTER Nicona track list
		ld	a,(iy+trk_seqId)
		and	00001111b		; Filter sequence bits
		add	a,a			; *4
		add	a,a
		rst	8
		ld	e,a
		add	hl,de
		ld	a,(hl)
		inc	hl
		bit	7,a
		jr	z,.no_glbl
		set	0,(iy+trk_status)	; Enable GLOBAL sub-beats
.no_glbl:
		and	01111111b
		ld	(iy+trk_tickSet),a
		ld	a,(hl)			; Read and temporally
		inc	hl			; grab it's pointers
		ld	c,(hl)
		rst	8
		inc	hl
		ld	l,(hl)
		ld	h,c
		rst	8
		ld	de,headerOut
		ld	c,0Ch
		call	transferRom		; ** ROM access **
		ld	ix,headerOut_e-1

	; headerOut:
	; dc.l .blk,.pat,.ins
	; *** READING BACKWARDS ***
		call	.grab_rhead		; Instrument data
		ld	c,(iy+trk_MaxIns)
		sla	c			; *8
		sla	c
		sla	c
		ld	a,b
		ld	e,(iy+trk_ChnCIns)
		ld	d,(iy+(trk_ChnCIns+1))
		ld	(iy+trk_Instr),e
		ld	(iy+(trk_Instr+1)),d
		rst	8
		call	transferRom		; ** ROM access **
		rst	20h			; Wave refill
		call	.grab_rhead		; Pattern data
		ld	c,(iy+trk_MaxHdrs)
		sla	c			; *4
		sla	c
		ld	a,b
		ld	(iy+trk_RomPatt),l	; Save ROM patt base
		ld	(iy+(trk_RomPatt+1)),h
		ld	(iy+(trk_RomPatt+2)),a
		ld	e,(iy+trk_ChnCHead)
		ld	d,(iy+(trk_ChnCHead+1))
		ld	(iy+trk_Patt),e
		ld	(iy+(trk_Patt+1)),d
		rst	8
		call	transferRom		; ** ROM access **
		call	.grab_rhead		; Block data
		ld	c,(iy+trk_MaxBlks)
		ld	a,b
		ld	e,(iy+trk_ChnCBlk)
		ld	d,(iy+(trk_ChnCBlk+1))
		ld	(iy+trk_Blocks),e
		ld	(iy+(trk_Blocks+1)),d
		rst	8
		call	transferRom		; ** ROM access **
		jp	.set_track

; Read 68K pointer:
; hl - 00xxxx
;  b - xx0000
.grab_rhead:
		ld	l,(ix)
		dec	ix
		rst	8
		ld	h,(ix)
		dec	ix
		ld	b,(ix)
		dec	ix
; 		ld	c,(ix)
		rst	8
		dec	ix
		ret

; ----------------------------------------
; Reset tracker channels
;
; iy - Track buffer
;
; Breaks:
; ix
; ----------------------------------------

track_out:
; 		push	iy
		ld	e,(iy+trk_ChnList)	; Point to track-data
		ld	d,(iy+(trk_ChnList+1))
		push	de
		pop	ix
		rst	8
		ld	de,8
		ld	b,(iy+trk_MaxChnls)	; MAX_TRKCHN
		xor	a
.clrfe:
; 		ld	a,(ix+chnl_Ins)
; 		or	a
; 		jr	z,.nochip
		ld	(ix+chnl_Note),-2
		ld	(ix+chnl_Flags),1
		ld	(ix+chnl_Vol),64
		rst	8
.nochip:
		add	ix,de
		djnz	.clrfe
		ld	a,1
		ld	(marsUpd),a
; 		pop	iy
		ret

; ----------------------------------------
; Load tracklist from ROM
;
; a - SeqID
; ----------------------------------------

get_RomTrcks:
		and	11110000b
		ld	e,a
		ld	a,(trkListPage)
		cp	e
		ret	z
init_RomTrcks:
		ld	a,e
		ld	(trkListPage),a
		rlca
		rlca			; 10h*4=40h
		and	11000000b
		ld	e,a
		ld	a,d
		rst	8
		and	00000011b	; * 40h
		ld	d,a
		ld	hl,nikona_SetMstrList
		inc	hl
		ld	a,(hl)
		inc	hl
		ld	c,(hl)
		inc	hl
		ld	l,(hl)
		rst	8
		ld	h,c
		add	hl,de
		adc	a,0
		ld	de,trkListCach
		ld	bc,4*10h
		jp	transferRom	; *** ROM ACCESS ***

; ============================================================
; --------------------------------------------------------
; Convert notes to soundchips
; --------------------------------------------------------

set_chips:
		rst	20h			; Refill wave
		ld	iy,nikona_BuffList
.trk_buffrs:
		rst	8
		ld	a,(iy)
		cp	-1
		jr	z,proc_chips
		push	iy
		ld	l,(iy)
		ld	h,(iy+1)
		call	tblbuff_read
		rst	8
		pop	iy
		ld	de,10h
		add	iy,de
		jr	.trk_buffrs
proc_chips:
		rst	20h
		ld	iy,tblPSGN		; PSG Noise (FIRST)
		call	dtbl_singl
		nop
		nop
		ld	iy,tblPSG		; PSG Squares
		call	dtbl_multi
		ld	iy,tblFM
		call	dtbl_multi
		ld	iy,tblPWM
		call	dtbl_multi
		ret

; ----------------------------------------
; Read current track
tblbuff_read:
; 		rst	20h
		push	hl
		pop	iy
		ld	b,(iy+trk_status)	; bit7: Track active?
		bit	7,b
		ret	z
; 		ret
; .go_read:
		ld	a,b			; trk_Status == -1?
		cp	-1
		jp	nz,.track_cont
		call	track_out
		ld	(iy+trk_Status),0
.track_cont:
		rst	8
		ld	l,(iy+trk_ChnList)
		ld	h,(iy+(trk_ChnList+1))
		push	hl
		pop	ix			; iy - channel list
		ld	b,(iy+trk_MaxChnls)	;MAX_TRKCHN

; ** Needs special delays to
; keep the samplerate
.next_chnl:
		push	bc
		ld	a,(ix)			; ** chnl_Flags
		and	00001111b
		call	nz,.do_chip
		pop	bc
		ld	de,8
		add	ix,de
		rst	8	; wave sync
		djnz	.next_chnl
		ret

; ----------------------------------------
; iy - Track buffer
; ix - Current channel

.do_chip:
		ld	a,(ix+chnl_Ins)		; Check intrument type FIRST
		or	a
		ret	z
		ld	d,(iy+trk_MaxIns)
		cp	d
		ret	z
		ret	nc
		dec	a			; ins-1
		rrca				; * 08h
		rrca
		rrca
		rrca
		rst	8
		rrca
		ld	d,a
		and	11111000b
		ld	e,a
		ld	a,d
		and	00000111b
		ld	d,a
		ld	l,(iy+trk_Instr)	; hl - Intrument data
		ld	h,(iy+(trk_Instr+1))
		ld	a,e
		add	hl,de
		rst	8
		push	hl			; <-- save ins pos
		call	.grab_link
		pop	de			; --> recover as de
		cp	-1			; Found any link?
		ret	z
		ld	a,(iy+trk_Priority)	; a - Set priority level
		inc	hl			; Skip link
		inc	hl
		ld	(hl),a			; Write priority
		inc	hl
		ld	(hl),e			; Write Instrument pointer
		inc	hl
		ld	(hl),d
		ret

; ----------------------------------------
; Search for a linked channel on the
; chip table
;
; Input:
; hl - Intrument position
;
; Returns:
; hl - Channel table to use
;  a - Return value:
;       0 - Found
;      -1 - Not found
; ----------------------------------------

.grab_link:
		ld	a,(hl)
		and	11110000b
		ld	e,a			; e - NEW chip
		rst	8
		ld	a,(ix+chnl_Chip)	; a - Check OUR chip
		and	11110000b		; Filter chip bits
		jp	z,.new_chip		; If zero: Set new chip
		cp 	e
		jp	z,.srch_link		; If same: Grab our link
		ld	d,a			; d - OLD chip
		push	de
		call	.srch_link		; Search our link (first)
		pop	de
		cp	-1
		ret	z
		call	.reset_link
		ld	(ix+chnl_Chip),0
		jr	.do_newchip

; ** RELINK **
; e - Our current chip
.srch_link:
		rst	8
		call	.pick_tbl	; Pick our table
		or	a
		jp	m,.singl_link
		push	ix		; copy ix to bc
		pop	bc
.srch_lloop:
		rst	8
		ld	a,(hl)		; Read LSB
		cp	-1		; If -1, return -1
		jr	z,.refill
		cp	c
		jr	nz,.invldl
		inc	hl
		rst	8
		ld	a,(hl)
		dec	hl
		cp	b
		jr	z,.reroll
.invldl:
		push	de
		ld	de,MAX_TBLSIZE
		rst	8
		add	hl,de
		pop	de
		jr	.srch_lloop
.reroll:
	; *** PSG3 tone 3 check ***
		ld	a,e
		cp	80h		; PSG?
		jr	z,.chk_psg
		jr	.rnot_psg
.chk_psg:
		ld	a,(psgHatMode)
		and	011b
		cp	011b
		jr	nz,.rnot_psg
		push	hl
		rst	8
		ld	de,5		; <-- fake "iy+05h"
		add	hl,de
		ld	a,(hl)
		pop	hl
		cp	2
		jr	nz,.rnot_psg
		rst	8
		ld	d,80h		; Set PSG silence
		call	.reset_link
		ld	a,-1		; Return FULL
		ret
; PSGN/FM3/FM6
.singl_link:
		push	ix			; copy ix to bc
		pop	bc
		inc	hl			; Read MSB first
		rst	8
		ld	a,(hl)
		dec	hl
		cp	b			; MSB match?
		jr	nz,.refill
		ld	a,(hl)			; Read LSB
		cp	c
		jr	nz,.refill
.rnot_psg:
		rst	8
		xor	a
		ret
; ***
.refill:
		ld	e,(ix+chnl_Chip)
.do_newchip:
		ld	a,e

; *** NEW CHIP ***
; e - Chip to set
.new_chip:
		ld	a,e			; Read NEW chip
		or	a			; If non-minus, exit.
		ret	p
		call	.pick_tbl
		rst	8
		ld	c,(iy+trk_Priority)	; c - OUR priority level
		or	a
		jp	m,.singl_free
		push	hl
; PASS 1
.srch_free:
		ld	a,(hl)			; Read LSB
		cp	-1			; If -1, return -1
		jr	z,.pass_2
		inc	hl
		ld	b,(hl)			; Read MSB
		rst	8
		dec	hl
		or	b
		jr	z,.new_link_z
		call	.nextsrch_tbl
		jr	.srch_free
; PASS 2
.pass_2:
		rst	8
		pop	hl
.next_prio:
		ld	a,(hl)		; Read LSB
		cp	-1		; If -1, return -1
		ret	z
		inc	hl
		inc	hl
		ld	a,(hl)
		dec	hl
		dec	hl
		cp	c
		jr	c,.new_link
		or	a
		jr	z,.new_link
		rst	8
		call	.nextsrch_tbl
		jr	.next_prio

.nextsrch_tbl:
		push	de
		ld	de,MAX_TBLSIZE
		add	hl,de
		pop	de
		rst	8
		nop	; wave sync
		nop
		nop
		nop
		ret
.new_link_z:
		inc	sp		; dummy pop
		inc	sp
.new_link:
		rst	8
		inc	hl
		inc	hl
; hl+2
.l_hiprio:
	; TODO: check this later.
; 		ld	a,e
; 		and	11110000b
; 		cp	80h
; 		jr	nz,.not_psg
; 		ld	a,(psgHatMode)
; 		and	011b
; 		cp	011b
; 		jr	nz,.not_psg
; 		rst	8
; 		push	de		; W
; 		ld	de,5
; 		add	hl,de
; 		ld	a,(hl)
; 		scf
; 		ccf
; 		sbc	hl,de
; 		pop	de
; 		rst	8
; 		cp	2
; 		jr	nz,.not_psg
; 		ld	a,-1
; 		ret
; .not_psg:
		ld	(ix+chnl_Chip),e
		push	ix
		pop	de
		rst	8
		ld	(hl),c		; write priority
		dec	hl		; -1
		ld 	(hl),d		; MSB
		dec	hl
		ld	(hl),e		; LSB
		xor	a
		ret
; Single slot
.singl_free:
		rst	8
		ld	b,(hl)
		inc	hl
		ld	a,(hl)
		inc	hl
		or	b
		jr	z,.l_hiprio
		ld	a,(hl)
		cp	c
		jr	c,.l_hiprio		; PRIORITY
		or	a
		jr	z,.l_hiprio
.sngl_sprio:
		rst	8
		ld	a,-1
		ret

; Pick chip table
; In:
;  e - ID
;
; Out:
; hl - Table
.pick_tbl:
		push	de
		rrca
		rrca
		rrca
		rrca
		and	00000111b
		add	a,a
		ld	hl,tblList
		push	hl
		ld	d,0
		ld	e,a
		add	hl,de
		ld	e,(hl)
		inc	hl
		ld	a,(hl)
		ld	d,a
		res	7,d
		pop	hl
		add	hl,de
		pop	de
		ret

; d - Silence chip
;
; Uses:
; bc
.reset_link:
		rst	8
		ld	(hl),0			; Delete link
		inc	hl
		ld	(hl),0
		inc	hl
		ld	(hl),d			; Set "silence" chip ID.
		ld	bc,8-2			; Go to 08h
		add	hl,bc
		rst	8
		ld	b,8/2
.clrfull:
		ld	(hl),0			; Reset settings 08-0Bh
		inc	hl
		ld	(hl),0
		inc	hl
		rst	8
		djnz	.clrfull
		ret

; ============================================
; ----------------------------------------
; Process chip using it's table
;
; iy - table to read
;  c - Chip ID
; ----------------------------------------

dtbl_multi:
		ld	a,(iy)
		cp	-1
		ret	z
		call	dtbl_frommul
		rst	8
		ld	de,MAX_TBLSIZE
		add	iy,de
		nop
		nop
		rst	8
		jr	dtbl_multi
dtbl_singl:
		rst	8

dtbl_frommul:
		ld	e,(iy)
		ld	d,(iy+1)
		ld	a,d
		or	e
		jr	nz,.linked
		ld	a,(iy+2)	; Any 80h+ Flag?
		or	a
		ret	p
		ld	a,(iy+2)	; a - chip type
		rst	8
		ld	(iy+2),0	; Reset priority

; ----------------------------------------
; chip-silence request
; iy - Table
		and	11110000b
		cp	80h
		jr	z,.siln_psg
		cp	90h
		jr	z,.siln_psg_n
		cp	0A0h
		jr	z,.siln_fm
		cp	0B0h
		jr	z,.siln_fm
		rst	8
		cp	0C0h
		jr	z,.siln_dac
		cp	0D0h
		jr	z,.siln_pwm
		ret
.siln_psg_n:
		xor	a
		ld	(psgHatMode),a
.siln_psg:
		rst	8
		ld	ix,psgcom
		jr	.rcyl_com

; --------------------------------

.siln_dac:
		call	dac_off
.siln_fm:
		call	.fm_keyoff
		jp	.fm_tloff

; --------------------------------

.siln_pwm:
		ld	a,1
		ld	(marsUpd),a
		rst	8
		ld	ix,pwmcom
		rst	8
.rcyl_com:
		ld	b,0
		ld	c,(iy+05h)
		add	ix,bc
		ld	(ix),100b
		ret

; ----------------------------------------
; Process channel now
; iy - Table
; ix - Tracker channel
.linked:
		ld	a,(de)		; ** chnl_Flags
		ld	b,a		; b - flags to check
		and	00001111b	; Filter flags
		ret	z
		ld	a,b
		and	11110000b	; Keep OTHER bits
		ld	(de),a		; ** clear chnl_Flags
		push	de
		pop	ix
		ld	l,(iy+03h)
		ld	h,(iy+04h)
		rst	20h

	;  b - Flags LR00evin (Eff|Vol|Ins|Note)
	; iy - Our chip table
	; ix - Track channel
	; hl - Intrument data
		bit	0,b		; Note
		call	nz,.note
		bit	1,b		; Intrument
		call	nz,.inst
		rst	8
		bit	2,b		; Volume
		call	nz,.volu
		bit	3,b		; Effect
		call	nz,.effc
		ld	a,b
		and	00001111b
		ret	z
		rst	8

; ----------------------------------------
; Process channel now
;
; b - Note bits
; ----------------------------------------

		ld	a,(hl)
		and	11110000b
		cp	80h
		jr	z,.mk_psg
		cp	90h
		jr	z,.mk_psgn
		cp	0A0h
		jp	z,.mk_fm
		cp	0B0h
		jp	z,.mk_fmspc
		rst	8
		cp	0C0h
		jp	z,.mk_dac
		cp	0D0h
		jp	z,.mk_pwm
		ret

; --------------------------------

.mk_psgn:
		ld	a,(ix+chnl_Note)
		push	ix
		ld	ix,psgcom+3	; <-- direct ix point
		rst	8
		cp	-2
		jr	z,.kycut_psgn
		cp	-1
		jr	z,.kyoff_psgn
		ld	e,a
		ld	a,(psgHatMode)	; Tone 3?
		and	011b
		cp	011b
		jr	nz,.psg_keyon	; Normal
		jr	.from_psgn	; Tone 3
.mk_psg:
		rst	8
		ld	a,(ix+chnl_Note)
		push	ix
		ld	ix,psgcom	; ix - psgcom
		ld	e,(iy+05h)
		ld	d,0
		add	ix,de
		cp	-2
		jr	z,.kycut_psg
		cp	-1
		jr	z,.kyoff_psg
.from_psgn:
		rst	8
		ld	e,(iy+06h)	; Read pitch
		ld	d,(iy+07h)
		ld	(ix+DTL),e
		ld	(ix+DTH),d
.psg_keyon:
		call	.dopsg_vol
		rst	8
		ld	(ix+COM),001b	; Key ON
		pop	ix
		ret
; -1
.kyoff_psgn:
		ld	a,000b
		ld	(psgHatMode),a	; ** GLOBAL SETTING
.kyoff_psg:
		rst	8
		ld	c,010b
		ld	(ix),c
		pop	ix
		jp	.chnl_ulnkoff
; -2
.kycut_psgn:
		ld	a,000b
		ld	(psgHatMode),a	; ** GLOBAL SETTING
.kycut_psg:
		rst	8
		ld	c,100b
		ld	(ix),c
		pop	ix
		jp	.chnl_ulnkcut

.dopsg_vol:
		ld	a,(iy+08h)	; Set volume
		neg	a
		ld	c,a
		rst	8
		cp	40h
		jr	nz,.vmuch
		ld	c,-1
.vmuch:
		ld	a,c
		add	a,a
		add	a,a
		ld	(ix+PVOL),a
		ret

; --------------------------------

.mk_fm:
		ld	a,(ix+chnl_Note)
		cp	-2
		jp	z,.fm_cut
		cp	-1
		jp	z,.fm_off
		rst	8
		ld	c,(iy+05h)	; c - KeyID
		ld	a,b		; Note bit?
		and	0001b
		jr	z,.nofm_note
		ld	b,(iy+05h)	; Check channel 3
		ld	a,b
		cp	2
		jr	nz,.not_dspc
		ld	de,2700h	; CH3 off
		call	fm_send_1
		ld	a,0
		ld	(fmSpecial),a
.not_dspc:
		ld	a,b
		cp	6
		jr	nz,.not_dac
		rst	8
		call	dac_off
.not_dac:
		call	.fm_keyoff
		ld	l,(iy+06h)	; Read pitch
		ld	h,(iy+07h)
		call	.fm_setfreq
		rst	8
.nofm_note:
		call	.fm_wrtalpan	; Panning and effects
		call	.fm_wrtlvol	; FM volume control
	if ZSET_TESTME
		ret
	else
		ld	a,(iy+0Fh)	; 0Eh - keys
		and	11110000b
		or	c
		rst	8
		ld	e,a
		ld	d,28h
		jp	fm_send_1
	endif

; --------------------------------

.mk_fmspc:
		ld	a,(ix+chnl_Note)
		cp	-2
		jp	z,.fm_cut
		cp	-1
		jp	z,.fm_off
		rst	8
		ld	c,(iy+05h)	; c - KeyID
		ld	a,b
		and	0001b
		jr	z,.nofm_note
		call	.fm_keyoff
		ld	hl,fmcach_list	; Manual freqs
		ld	a,(iy+05h)
		and	0111b
		ld	d,0
		add	a,a
		ld	e,a
		add	hl,de
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		ld	de,20h		; point to regs
		add	hl,de
		rst	8
		ld	d,0ADh
		ld	e,(hl)
		call	fm_send_1
		inc	hl
		ld	d,0A9h
		ld	e,(hl)
		call	fm_send_1
		inc	hl
		rst	8
		ld	d,0ACh
		ld	e,(hl)
		call	fm_send_1
		inc	hl
		ld	d,0A8h
		ld	e,(hl)
		call	fm_send_1
		inc	hl
		rst	8
		ld	d,0AEh
		ld	e,(hl)
		call	fm_send_1
		inc	hl
		ld	d,0AAh
		ld	e,(hl)
		call	fm_send_1
		inc	hl
		rst	8
		ld	d,0A6h
		ld	e,(hl)
		call	fm_send_1
		inc	hl
		ld	d,0A2h
		ld	e,(hl)
		call	fm_send_1
		inc	hl
		rst	8
		ld	de,2740h	; CH3 on
		call	fm_send_1
		ld	a,1
		ld	(fmSpecial),a
		jp	.nofm_note

; --------------------------------

.fm_off:
		call	.fm_keyoff
		jp	.chnl_ulnkoff
.fm_cut:
		call	.fm_keyoff
		call	.fm_tloff
		jp	.chnl_ulnkcut

; --------------------------------

.mk_dac:
		ld	a,(ix+chnl_Note)
		cp	-2
		jp	z,.dac_cut
		cp	-1
		jp	z,.dac_off
		ld	a,b		; Note ONLY?
		and	0001b
		ret	z
		call	dac_off
		ld	a,(ix+chnl_Flags)	; Read panning
		cpl				; REVERSE bits
		and	11000000b
		ld	e,a
		ld	d,0B6h		; Channel 6
		call	fm_send_2
		ld	l,(iy+06h)	; Read pitch
		ld	h,(iy+07h)
		ld	(wave_Pitch),hl
; 		ld	a,(iy+0Ah)
; 		ld	(wave_Flags),a
		jp	dac_play
.dac_cut:
		call	dac_off
		jp	.chnl_ulnkoff
.dac_off:
		jp	.chnl_ulnkcut

; --------------------------------

.mk_pwm:
		ld	a,(ix+chnl_Note)
		ld	d,0
		ld	e,(iy+05h)
		ld	c,(ix+chnl_Flags)	; c - Panning bits
		push	ix
		ld	ix,pwmcom
		add	ix,de
		cp	-2
		jp	z,.pwm_cut
		cp	-1
		jp	z,.pwm_off
		rst	8
		ld	a,b		; Note ONLY?
		and	0001b
		jr	z,.nopwm_note
		ld	a,c
		rrca
		rrca
		cpl
		and	00110000b
		ld	e,a
		ld	l,(iy+06h)	; Read pitch
		ld	h,(iy+07h)
		rst	8
		ld	a,(iy+08h)	; Read volume
		neg	a
		add	a,a
		add	a,a
		jr	nc,.pwv_much
		ld	a,-1
.pwv_much:
; 		add	a,a
		and	11111100b
		ld	(iy+08h),a	; vvvvvv00b
		rst	8
		or	h		; Merge MSB freq
		ld	bc,8
		ld	(ix),001b	; KeyON
		add	ix,bc
		ld	(ix),a
		add	ix,bc
		ld	(ix),l
		add	ix,bc
		rst	8
		ld	a,(ix)
		and	11001111b
		or	e
		ld	(ix),a
	if ZSET_TESTME=0
		ld	a,1
		ld	(marsUpd),a
	endif
.nopwm_note:
		pop	ix
		ret
; -1
.pwm_off:
		rst	8
		ld	(ix),010b
		ld	a,1
		ld	(marsUpd),a
		pop	ix
		jp	.chnl_ulnkoff
; -2
.pwm_cut:
		rst	8
		ld	(ix),100b
		ld	a,1
		ld	(marsUpd),a
		pop	ix
		jp	.chnl_ulnkcut

; ----------------------------------------
; NEW effect
; ----------------------------------------

; TODO: agregar mas efectos para la ver 1.0
.effc:
		ld	a,(ix+chnl_EffArg)
		ld	e,a			; e - effect data
		ld	a,(ix+chnl_EffId)
		ld	d,a			; d - effect id
		rst	8
; 		cp	4
; 		jr	z,.effc_D
		cp	24			; Effect X?
		jp	z,.effc_X
		ret

; ----------------------------------------
; Effect D
;
; Volume slide

; .effc_D:
; 		ld	d,(iy+0Ah)
; 		ld	a,e
; 		or	a
; 		jr	z,.D_cont	; 00h = slide continue
; 		rst	8
; 		ld	d,a
; 		ld	(iy+0Ah),d	; Store slide setting
; .D_cont:
; 		ld	a,d
; 		or	a
; 		ret	z
; 		ld	c,(iy+08h)	; Current volume
; 		and	00001111b
; 		jr	z,.n_down
; 		rst	8
; 		ld	a,c
; 		sla	d
; 		add	a,d
; 		cp	40h
; 		jr	c,.wr_dvol
; 		ld	a,40h
; 		jr	.wr_dvol
; .n_down:
; 		rst	8
; 		ld	a,d
; 		and	11110000b
; 		jr	z,.n_up
; 		ld	a,c
; 		sla	d
; 		sub	a,d
; 		or	a
; 		jp	p,.wr_dvol
; 		rst	8
; 		xor	a
; 		jr	.wr_dvol
; .n_up:
; 		ret
; .wr_dvol:
; 		ld	(iy+08h),a
		ret

; ----------------------------------------
; Effect X
;
; Panning arg:
; 00h LEFT <- 80h MIDDLE -> FFh RIGHT
;
; FM style %LR000000 (REVERSE: 0-on 1-off)

.effc_X:
		ld	d,0
		ld	a,(hl)
		cp	80h
		jr	z,.res_pan
		cp	90h
		jr	z,.res_pan
		rst	8
		push	hl
		ld	hl,.fm_panlist
		ld	a,e
		rlca
		rlca
		rlca
		and	0111b
; 		ld	d,0
		ld	e,a
		rst	8
		add	hl,de
		ld	d,(hl)
		pop	hl
.res_pan:
		ld	a,(ix+chnl_Flags)	; Save panning
		and	00111111b
		or	d
		ld	(ix+chnl_Flags),a
		ret

; 0 - ENABLE, 1 - DISABLE
.fm_panlist:
		db 01000000b
		db 01000000b
		db 01000000b
		db 00000000b
		db 00000000b
		db 10000000b
		db 10000000b
		db 10000000b

; ----------------------------------------
; NEW volume
; ----------------------------------------

.volu:
		ld	a,(ix+chnl_Vol)
		sub	a,64
		ld	(iy+08h),a	; <-- BASE volume
		rst	8
		ret

; ----------------------------------------
; NEW instrument
; ----------------------------------------

.inst:
		ld	a,(hl)
		and	11110000b
		cp	80h
		jr	z,.ps_ins
		cp	90h
		jr	z,.pn_ins
		cp	0A0h
		jr	z,.fm_ins
		cp	0B0h
		jr	z,.fm_ins
		cp	0C0h
		jp	z,.dac_ins
		rst	8
		cp	0D0h
		jp	z,.pwm_ins
.invl_ins:
		ret
; PSG
.pn_ins:
		ld	a,(hl)		; Grab noise setting
		and	0111b
		ld	(psgHatMode),a	; ** GLOBAL SETTING
.ps_ins:
		rst	8
		push	ix
		push	hl
		inc	hl		; Skip ID
		ld	ix,psgcom	; Read psg control
		ld	e,(iy+05h)
		ld	d,0
		add	ix,de
		ld	a,(hl)
		rst	8
		inc	hl
		ld	a,(hl)
		ld	(ix+ALV),a	; ALV
		inc	hl
		ld	a,(hl)
		ld	(ix+ATK),a	; ATK
		inc	hl
		ld	a,(hl)
		rst	8
		ld	(ix+SLV),a	; SLV
		inc	hl
		ld	a,(hl)
		ld	(ix+DKY),a	; DKY
		inc	hl
		ld	a,(hl)
		ld	(ix+RRT),a	; RRT
		inc	hl
		ld	a,(hl)
		rst	8
		ld	(ix+PARP),a	; ARP
		pop	hl
		pop	ix
		ret

; --------

.fm_ins:
		push	ix
		push	hl
		push	bc
; 		ld	b,(ix+chnl_Ins)	; b - current Ins
		ld	b,(iy+02h)
		ld	a,(iy+05h)
		and	0111b
		ld	d,0
		add	a,a
		ld	e,a
		ld	ix,fmcach_list
		add	ix,de
		rst	8
		ld	e,(ix)
		inc	ix
		ld	d,(ix)
		push	de
; 		ld	a,(iy+0Bh)	; 0Bh: DON'T reload flag
; 		cp	b
; 		jr	z,.same_patch
; 		ld	(iy+0Bh),b
		inc	hl		; Skip id and pitch
		inc	hl
		rst	8
		ld	b,(hl)
		inc	hl
		ld	c,(hl)
		inc	hl
		ld	l,(hl)
		ld	h,c
		ld	a,(iy+0Ah)
		cp	h
		jr	nz,.new_romdat
		rst	8
		ld	a,(iy+0Bh)
		cp	l
		jr	nz,.new_romdat
		ld	a,(iy+09h)
		cp	b
		jr	z,.same_patch
.new_romdat:
		rst	8
		ld	(iy+09h),b
		ld	(iy+0Ah),h
		ld	(iy+0Bh),l
		ld	a,b
		ld	bc,28h		; <- size
		call	transferRom	; *** ROM ACCESS ***
.same_patch:
		pop	hl
		ld	a,(iy+05h)
		ld	c,a		; c - FM Key ID
; 		call	.fm_keyoff

	; hl - fmcach intrument
	; de - FM reg and data: 3000h
	;  c - FM keyChannel
		ld	a,c
		and	011b
		or	30h		; Start at reg 30h
		ld	d,a
		ld	e,0
		rst	8
		ld	b,7*4		; Write ALL base FM registers
		call	.fm_setrlist
; 		ld	b,4
; 		call	.fm_setrlist
; 		ld	b,5*4
; 		call	.fm_setrlist
		rst	8
		ld	a,(hl)		; 0B0h
		ld	(iy+0Ch),a	; ** Save 0B0h to 0Ch
		inc	hl
		ld	a,(hl)		; 0B4h
		ld	(iy+0Dh),a	; ** Save 0B4h to 0Dh
		inc	hl
		ld	a,(hl)
		ld	(iy+0Eh),a	; LFO
		inc	hl
		ld	a,(hl)		; 028h keys
		and	11110000b
		rst	8
		ld	(iy+0Fh),a	; ** Save keys to 0Eh
; .same_patch:
		pop	bc
		pop	hl
		pop	ix
		ret
; b - numof_regs
.fm_setrlist:
		ld	e,(hl)
		inc	hl
		call	fm_autoreg
		nop
		nop
		rst	8
		nop
		inc	d		; +4
		inc	d
		inc	d
		inc	d
		djnz	.fm_setrlist
		ret
; --------

.dac_ins:
		ld	e,(ix+chnl_Ins)	; b - current Ins
; 		ld	a,(iy+0Bh)	; 0Bh: DON'T reload flag
; 		cp	e
; 		jr	z,.same_dac
		ld	(iy+0Bh),e
		push	hl
		push	bc
		ld	a,(hl)
		and	01111b
; 		ld	(iy+0Ah),a
		ld	(wave_Flags),a
		rst	8
		inc	hl
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	a,(hl)
		inc	hl
		ld	l,(hl)
		ld	h,a
		push	hl
		ld	a,e
		ld	bc,6		; Skip header
		rst	8
		add	hl,bc
		adc	a,0
		ld	(wave_Start),hl	; Set START point
		ld	(wave_Start+2),a
		pop	hl
		ld	a,e
		ld	de,sampleHead
		ld	bc,6
		push	de
		call	transferRom	; *** ROM ACCESS ***
		pop	hl
	; hl - temporal header
		rst	8
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		inc	hl
		ld	a,(hl)
		inc	hl
		ld	(wave_Len),de	; LEN
		ld	(wave_Len+2),a
		ld	e,(hl)
		inc	hl
		rst	8
		ld	d,(hl)
		inc	hl
		ld	a,(hl)
		inc	hl
		ld	(wave_Loop),de	; LOOP
		ld	(wave_Loop+2),a
		ld	de,2806h	; keys off
		call	fm_send_1
		pop	bc
		pop	hl
; .same_dac:
		ret

; --------

.pwm_ins:
		push	ix
		push	hl
		push	bc
		ld	a,(hl)		; Stereo|Loop bits
		and	00000011b
		rrca
		rrca
		ld	c,a
; 		ld	(iy+0Ah),a	; 0Ah flags: %SlLR
		rst	8
		inc	hl		; Skip ID and Pitch
		inc	hl
		ld	d,(hl)
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	a,(hl)
		inc	hl
		ld	l,(hl)
		ld	h,a
		ld	a,c
		or	d
		ld	d,a
	; de,hl - 32-bit PWM pointer
		ld	ix,pwmcom
		ld	b,0
		ld	c,(iy+05h)
		add	ix,bc
		ld	bc,PWOUTF
		add	ix,bc	; Move to PWOUTF
		ld	bc,8
		ld	(ix),d
		add	ix,bc
		ld	(ix),e
		add	ix,bc
		ld	(ix),h
		add	ix,bc
		ld	(ix),l
		pop	bc
		pop	hl
		pop	ix
		ret

; ----------------------------------------
; NEW note
; ----------------------------------------

.note:
		ld	a,b		; Volume bit?
		and	0100b
		jr	nz,.fm_hasvol
		ld	(iy+08h),0	; Reset to default volume
		rst	8
.fm_hasvol:
		ld	a,(ix+chnl_Note)
		ld	c,a
		cp	-1
		ret	z
		cp	-2
		ret	z
		ld	a,(hl)
		and	11110000b
		cp	80h
		jr	z,.n_psg
		rst	8
		cp	90h
		jr	z,.n_psgn
		cp	0A0h
		jr	z,.n_fm
; 		cp	0B0h		; ** Can't use notes on FM3 **
; 		jr	z,.n_fm
		cp	0C0h
		jr	z,.n_dac
		cp	0D0h
		jr	z,.n_dac
		ret

; --------------------------------

.n_psgn:
		ld	a,c
		add	a,12		; <-- Manual adjust for NOISE
		jr	.n_stfreq
.n_psg:
		ld	a,c
.n_stfreq:
		push	hl
		inc	hl		; Skip ID
		ld	e,(hl)		; Read pitch
		add	a,e		; Note + pitch
		rst	8
		add	a,a		; * 2
		ld	d,0		; de - note*2
		ld	e,a
		ld	hl,psgFreq_List
		add	hl,de
		ld	e,(hl)		; Read pitch
		inc	hl
		ld	d,(hl)
		rst	8
		pop	hl
		ld	(iy+06h),e	; Save frequency to 06h
		ld	(iy+07h),d
		ret
.n_fm:
		ld	a,c
		push	hl
		inc	hl		; Skip ID
		ld	e,(hl)		; Read pitch
		rst	8
		add	a,e		; Note + pitch
	; Search for octave and note
		ld	c,0		; c - octave
		ld	d,7
.get_oct:
		ld	e,a		; e - note
		sub	12
		or	a
		jp	m,.fnd_oct
		inc	c
		rst	8
		nop	; wave sync
		nop
		nop
		nop
		dec	d
		jr	nz,.get_oct
.fnd_oct:
		ld	a,e
		add	a,a		; Note * 2
		ld	e,a
		ld	d,0
		ld	hl,fmFreq_List
		add	hl,de
		rst	8
		ld	a,c		; a - Octave << 3
		add	a,a
		add	a,a
		add	a,a
		ld	e,(hl)
		inc	hl
		ld	h,(hl)
		or	h
		ld	h,a
		rst	8
		ld	l,e
		ld	(iy+06h),l	; Save frequency to 06h
		ld	(iy+07h),h
		pop	hl
		ret

; *** Both DAC and PWM ***
.n_dac:
		ld	a,c
		push	hl
		inc	hl		; Skip ID
		ld	e,(hl)		; Read pitch
		add	a,e		; Note + pitch
		rst	8
		ld	hl,wavFreq_List
		add	a,a
		ld	d,0
		ld	e,a
		add	hl,de
		ld	a,(hl)
		inc	hl
		rst	8
		ld	h,(hl)
		ld	l,a
		ld	(iy+06h),l	; Save frequency to 06h
		ld	(iy+07h),h
		pop	hl
		ret

; ----------------------------------------

.fm_keyoff:
		ld	d,28h
		ld	e,(iy+05h)
		jp	fm_send_1
.fm_tloff:
		ld	b,4
		ld	c,(iy+05h)
		ld	a,c
		and	011b
		or	40h	; TL regs
.tl_down:
		ld	d,a
		ld	e,7Fh
		call	fm_autoreg
		rst	8
		ld	a,d
		add	a,4
		djnz	.tl_down
		ret
; c - KeyID
.fm_setfreq:
		ld	a,c
		and	011b
		or	0A4h
		ld	d,a
		ld	e,h
		rst	8
		call	fm_autoreg
		ld	a,c
		and	011b
		or	0A0h
		ld	d,a
		ld	e,l
		call	fm_autoreg
		rst	8
		ret

; --------------------------------
; WRITE TL volume

.fm_wrtlvol:
		ld	hl,fmcach_list
		ld	a,(iy+05h)
		and	0111b
		ld	d,0
		rst	8
		add	a,a
		ld	e,a
		add	hl,de
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		inc	hl
		inc	hl
		inc	hl
		rst	8
		inc	hl		; Point to TL's
		ld	a,(iy+05h)
		and	011b
		or	40h		; TL registers
		ld	d,a
; d - 40h+
; hl - TL data
; .fm_wrtlvol:
		push	bc
		push	hl
		ld	hl,.fm_cindx
		ld	a,(iy+0Ch)	; Read 0B0h copy
		and	0111b
		ld	b,0
		ld	c,a
		add	hl,bc
		ld	a,(iy+08h)
		sra	a		; volume / 2
		and	01111111b
		ld	c,a
		rst	8
		ld	b,(hl)
		pop	hl
		rrc	b		; OP1
		call	c,.write_tl
		inc	hl
		inc	d
		inc	d
		rst	8
		inc	d
		inc	d
		rrc	b		; OP2
		call	c,.write_tl
		inc	hl
		inc	d
		inc	d
		inc	d
		inc	d
		rrc	b		; OP3
		call	c,.write_tl
		inc	hl
		rst	8
		inc	d
		inc	d
		inc	d
		inc	d
		rrc	b		; OP4
		call	c,.write_tl
		inc	hl
		inc	d
		inc	d
		inc	d
		inc	d
		rst	8
		pop	bc
		ret
.write_tl:
		ld	a,(hl)
		sub	a,c
		push	bc
		ld	e,a
		ld	c,(iy+05h)
		call	fm_autoreg
		rst	8
		pop	bc
		ret
; Jump carry list
.fm_cindx:
		db 1000b
		db 1000b
		db 1000b
		db 1000b
		db 1100b
		db 1110b
		db 1110b
		db 1111b
; c - KeyId
.fm_wrtalpan:
		ld	a,(iy+0Ch)	; 0B0h algorithm
		ld	e,a
		ld	a,c
		and	011b
		or	0B0h
		ld	d,a
		call	fm_autoreg
		rst	8
		ld	a,(ix+chnl_Flags)	; Read panning bits
		cpl				; REVERSE bits
		and	11000000b
		ld	e,a
		ld	a,(iy+0Dh)		; 0B4h %LRaa0ppp
		and	00111111b
		or	e
		ld	e,a
		ld	a,c
		and	011b
		or	0B4h
		ld	d,a
		call	fm_autoreg
		rst	8
		ld	a,(iy+0Eh)
		bit	3,a
		jr	z,.no_lfo
		ld	e,a
		ld	d,22h
		call	fm_send_1
.no_lfo:
		ret

; ----------------------------------------

.chnl_ulnkoff:
		ld	c,0
.chnl_ulnk:
		rst	8
		xor	a
		ld	(ix+chnl_Chip),a
		ld	(iy),a		; Delete link, chip and prio
		ld	(iy+1),a
		ld	(iy+2),c
		ret
.chnl_ulnkcut:
		ld	c,(ix+chnl_Chip)
		call	.chnl_ulnk
		ld	(iy+08h),a
		ld	(iy+09h),a
		ld	(iy+0Ah),a
		ld	(iy+0Bh),a
; 		push	iy
; 		pop	hl
; 		ld	bc,8-2		; Go to 08h
; 		add	hl,bc
; 		rst	8
; 		ld	b,8/2
; .clrfull:
; 		ld	(hl),0		; Reset settings 08-0Bh
; 		inc	hl
; 		ld	(hl),0
; 		inc	hl
; 		rst	8
; 		djnz	.clrfull
		ret

; ============================================================
; --------------------------------------------------------
; Communicate with the 32X from here.
; --------------------------------------------------------

ex_comm:
		rst	8
	if MARS
		ld	a,(marsBlock)	; Enable MARS requests?
		or	a
		jp	nz,.blocked
		ld	iy,8000h|5100h	; iy - mars sysreg (now $A15100)
		ld	ix,pwmcom
; 		ld	hl,6000h	; Point BANK closely to the 32X area ($A10000)
; 		ld	(hl),0
; 		ld	(hl),1
; 		rst	8
; 		ld	(hl),0
; 		ld	(hl),0
; 		ld	(hl),0
; 		ld	(hl),0
; 		ld	(hl),1
; 		ld	(hl),0
; 		ld	(hl),1
	; SLOW bankswitch to keep
	; the wave playback stable.
		xor	a
		ld	(6000h),a	; 0
		ld	a,10100001b
		ld	(6000h),a	; 1
		rrca
		ld	(6000h),a	; 0
		rrca
		ld	(6000h),a	; 0
		rrca
		ld	(6000h),a	; 0
		rst	8
		rrca
		ld	(6000h),a	; 0
		rrca
		ld	(6000h),a	; 1
		rrca
		ld	(6000h),a	; 0
		rrca
		ld	(6000h),a	; 1
		rst	8
		ld	a,(marsUpd)	; NEW transfer?
		or	a
		ret	z
		xor	a
		ld	(marsUpd),a
.wait_enter:
		nop
		nop
		ld	a,(iy+comm14)	; check if 68k got first.
		bit	7,a
		jr	nz,.wait_enter
		and	11110000b
		or	1		; Set CMD task mode $01
		ld	(iy+comm14),a
		rst	8
		and	00001111b	; Did it write?
		cp	1
		jr	nz,.wait_enter	; If not, retry.
		set	7,(iy+comm14)	; Lock bit
		set	1,(iy+standby)	; Request Slave CMD
		nop
		nop
		nop
		nop
		nop
		rst	8
		nop
		nop
		nop
		nop
		nop
; .wait_cmd:
; 		bit	1,(iy+standby)
; 		jr	nz,.wait_cmd
		ld	c,14		; c - 14 words/2-byte
.next_pass:
		rst	8
		push	iy
		pop	hl
		ld	de,comm8	; hl - comm8
		add	hl,de
		ld	b,2
		rst	8
.next_comm:
		ld	d,(ix)
		ld	e,(ix+1)
		inc	ix
		inc	ix
		rst	8
		ld	(hl),d
		inc	hl
		ld	(hl),e
		inc	hl
		djnz	.next_comm
		set	6,(iy+comm14)	; PASS data bit
		rst	8
.w_pass2:
		nop
		bit	6,(iy+comm14)	; PASS cleared?
		jr	nz,.w_pass2
		dec	c
		jr	nz,.next_pass
		res	7,(iy+comm14)	; Break transfer loop
		res	6,(iy+comm14)	; Clear CLK
.blocked:
		rst	8
		ld	hl,pwmcom
		ld	b,7		; MAX PWM channels
		xor	a
.clrcom:
		ld	(hl),a		; Reset our COM bytes
		inc	hl
		djnz	.clrcom
	endif
		ret

; ====================================================================
; ----------------------------------------------------------------
; Subroutines
; ----------------------------------------------------------------

; --------------------------------------------------------
; Init sound engine
; --------------------------------------------------------

gema_init:
		call	dac_off
		ld	a,0
		ld	(marsUpd),a
		ld	hl,dWaveBuff	; hl - Wave buffer START
		ld	de,dWaveBuff+1	; de - Wave next byte
		ld	bc,100h-1	; bc - length for copying
		ld	(hl),80h	; Set first byte
		ldir			; Start copying
		ld	hl,Zpsg_ctrl	; Silence PSG channels
		ld	(hl),09Fh
		ld	(hl),0BFh
		ld	(hl),0DFh
		ld	(hl),0FFh
		ld	de,2208h|3	; Set Default LFO
		call	fm_send_1
		ld	de,2700h	; CH3 special and timers off
		call	fm_send_1
		ld	de,2800h	; FM KEYS off
		call	fm_send_1
		inc	e
		call	fm_send_1
		inc	e
		call	fm_send_1
		inc	e
		inc	e
		call	fm_send_1
		inc	e
		call	fm_send_1
		inc	e
		call	fm_send_1
		ld	hl,6000h
		ld	a,1
		ld	(hl),a
		ld	(hl),a
		ld	(hl),a
		ld	(hl),a
		ld	(hl),a
		ld	(hl),a
		ld	(hl),a
		ld	(hl),a
		ld	(hl),a
		ld	iy,nikona_BuffList
		ld	c,1		; Start at this priority
.setup_list:
		ld	a,(iy)
		cp	-1
		jr	z,.end_setup
		inc	iy
		ld	l,a
		ld	h,(iy)
		push	hl
		pop	ix
		ld	(ix+trk_Priority),c
		ld	(ix+trk_seqId),-1	; Reset sequence ID
		inc	iy
		ld	de,trk_ChnList		; ** settings
		add	hl,de
	; iy - src
	; hl - dst
		ld	b,5*2
.st_copy:
		ld	a,(iy)
		ld	(hl),a
		inc	iy
		inc	hl
		djnz	.st_copy
		inc	c
		ld	a,(iy)			; MAX blocks
		ld	(ix+trk_MaxBlks),a
		inc	iy
		ld	a,(iy)			; MAX heads
		ld	(ix+trk_MaxHdrs),a
		inc	iy
		ld	a,(iy)			; MAX intruments
		ld	(ix+trk_MaxIns),a
		inc	iy
		ld	a,(iy)			; MAX channels
		ld	(ix+trk_MaxChnls),a
		inc	iy
		jr	.setup_list
.end_setup:
		ld	e,0
		jp	init_RomTrcks

; --------------------------------------------------------
; get_tick
;
; Checks if VBlank triggred a TICK
; (1/150 NTSC, 1/120 PAL)
; --------------------------------------------------------

get_tick:
		di				; Disable ints
		push	af
		push	hl
		ld	hl,tickFlag		; read last TICK flag
		ld	a,(hl)			; non-zero value (1Fh)?
		or 	a
		jr	z,.ctnotick
		ld	(hl),0			; Reset TICK flag
		inc	hl			; Move to tickCnt
		inc	(hl)			; and increment
		rst	8
		push	de
		ld	hl,(sbeatAcc)		; Increment subbeats
		ld	de,(sbeatPtck)
		rst	8
		add	hl,de
		ld	(sbeatAcc),hl
		pop	de
.ctnotick:
		pop	hl
		pop	af
		ei				; Enable ints again
		ret

; --------------------------------------------------------
; showRom
; Get ROM bank position.
;
; Input:
;  b - 68k address $xx0000
; hl - 68k address $00xxxx
;
; Output:
; hl - ROM position ready to use for reading
; --------------------------------------------------------

showRom:
		rst	8
		push	de
		push	bc
		ld	de,6000h
		ld	a,h
		rlca
		rst	8
		ld	(de),a
		ld	a,b
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		rst	8
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		pop	bc
		pop	de
		set	7,h
		ret

; --------------------------------------------------------
; transferRom
;
; Transfer bytes from ROM to RAM. This also tells
; to 68k that we want to access ROM
;
; Input:
; a  - 68K Address $xx0000
;  c - Byte count (size 0 NOT allowed, MAX: 0FFh)
; hl - 68K Address $00xxxx
; de - Destination pointer
;
; Uses:
; b
;
; Notes:
; call RST 20h first if transfering anything other
; than sample data, just to be safe.
; --------------------------------------------------------

transferRom:
		rst	8
		push	ix
		ld	ix,commZRomBlk	; ix - rom read/block flags
		ld	(x68ksrclsb),hl	; save hl copy
		res	7,h
		ld	b,0
		dec	bc
		add	hl,bc
		bit	7,h
		jr	nz,.double
		ld	hl,(x68ksrclsb)	; single transfer
		inc	c
		ld	b,a
		call	.transfer
		pop	ix
		ret
.double:
		rst	8
		ld	b,a		; double transfer
		push	bc
		push	hl
		ld	a,c
		sub	a,l
		ld	c,a
		ld	hl,(x68ksrclsb)
		call	.transfer
		pop	hl
		pop	bc
; 		rst	8
		ld	c,l
		inc	c
		ld	a,(x68ksrcmid)
		and	80h
		add	a,80h
		ld	h,a
		ld	l,0
		jr	nc,.x68knocarry
		inc	b
.x68knocarry:
		call	.transfer
		pop	ix
		ret

; ------------------------------------------------
; b  - Source ROM xx0000
;  c - Bytes to transfer (00h not allowed)
; hl - Source ROM 00xxxx (OR'd with 8000h)
; de - Destination address
; ix - Location of the ROM block flag(s)
;
; Uses:
; a
; ------------------------------------------------

.transfer:
		call	showRom		; Pick ROM bank

	; Transfer ROM data in packets
	; while playing the cache'd sample
	; *** CRITICAL PROCESS ***
	;
	; pseudo-reference
	; for ldir:
	; ld (de),(hl)	; load (hl) to (de), no a
	; inc de	; next de
	; inc hl	; next hl
	; dec bc	; decrement bc
	;
		ld	b,0
		ld	a,c		; a - Size counter
		sub	MAX_TRFRPZ	; Length lower than MAX_TRFRPZ?
		jr	c,.x68klast	; Process single piece only
.x68kloop:
		rst	8
		nop
		ld	c,MAX_TRFRPZ-1
		bit	0,(ix)		; Genesis requests LOCK?
		call	nz,.x68klpwt
		ldir			; (de) to (hl) until bc == 0
		rst	8
		nop
		sub	a,MAX_TRFRPZ-1
		jp	nc,.x68kloop
; last block
.x68klast:
		rst	8
		add	a,MAX_TRFRPZ
		ld	c,a
		bit	0,(ix)		; Genesis requests LOCK?
		call	nz,.x68klpwt
		ldir
		ret

; Wait here until Genesis unlocks ROM
.x68klpwt:
		rst	8
		nop
		nop
		nop
		nop
.x68kpwtlp:
		rst	8
		nop
		nop
		nop
		nop
		bit	0,(ix)		; 68k finished?
		jr	nz,.x68kpwtlp
		rst	8
		ret

; ====================================================================
; ----------------------------------------------------------------
; Sound chip routines
; ----------------------------------------------------------------

; --------------------------------------------------------
; chip_env
;
; Process PSG and FM
; --------------------------------------------------------

chip_env:
		ld	iy,psgcom+3		; Start from NOISE first
		ld	ix,Zpsg_ctrl
		ld	c,0E0h			; c - PSG first ctrl command
		ld	b,4			; b - 4 channels
.vloop:
		rst	8
		ld	e,(iy+COM)		; e - current command
		ld	(iy+COM),0

	; ----------------------------
	; bit 2 - stop sound
		bit	2,e
		jr	z,.ckof
		ld	(iy+LEV),-1		; reset level
		ld	(iy+FLG),1		; and update
		ld	(iy+MODE),0		; envelope off
.ckof:

	; ----------------------------
	; bit 1 - key off
		bit	1,e
		jr      z,.ckon
		ld	a,(iy+MODE)		; mode 0?
		or	a
		jr	z,.ckon
		ld	(iy+FLG),1		; psg update flag
		ld	(iy+MODE),100b		; set envelope mode 100b
		rst	8
.ckon:

	; ----------------------------
	; bit 0 - key on
		bit	0,e
		jr	z,.envproc
		ld	(iy+LEV),-1		; reset level
		ld	a,b
		cp	4			; NOISE channel?
		jr	nz,.nskip
		rst	8			; Set NOISE mode
		ld	a,(psgHatMode)		; write hat mode only.
		or	c
		ld	(ix),a
.nskip:
		ld	(iy+FLG),1		; psg update flag
		rst	8
		ld	(iy+MODE),001b		; set to attack mode
.nblock:

	; ----------------------------
	; Process effects
	; ----------------------------
.envproc:
		ld	a,(iy+MODE)
		or	a			; no modes
		jp	z,.vedlp
		cp 	001b			; Attack mode
		jr	nz,.chk2
		ld	(iy+FLG),1		; psg update flag
		ld	e,(iy+ALV)
		ld	a,(iy+ATK)		; if ATK == 0, don't use
		or	a
		jr	z,.atkend
		ld	d,a			; c - attack rate
		ld	a,e			; a - attack level
		rst	8
		ld	e,(iy+ALV)		; b - OLD attack level
		sub	a,d			; (attack rate) - (level)
		jr	c,.atkend		; if carry: already finished
		jr	z,.atkend		; if zero: no attack rate
		cp	e			; attack rate == level?
		jr	c,.atkend
		jr	z,.atkend
		ld	(iy+LEV),a		; set new level
		rst	8
		jr	.vedlp
.atkend:
		ld	(iy+LEV),e		; attack level = new level
.atkzero:
		ld	(iy+MODE),010b		; set to decay mode
		jr	.vedlp
.chk2:

		cp	010b			; Decay mode
		jr	nz,.chk4
.dectmr:
		ld	(iy+FLG),1		; psg update flag
		ld	a,(iy+LEV)		; a - Level
		ld	e,(iy+SLV)		; b - Sustain
		cp	e
		jr	c,.dkadd		; if carry: add
		jr	z,.dkyend		; if zero:  finish
		rst	8
		sub	(iy+DKY)		; substract decay rate
		jr	c,.dkyend		; finish if wraped.
		cp	e			; compare level
		jr	c,.dkyend		; and finish
		jr	.dksav
.dkadd:
		add	a,(iy+DKY)		;  (level) + (decay rate)
		jr	c,.dkyend		; finish if wraped.
		cp	e			; compare level
		jr	nc,.dkyend
.dksav:
		ld	(iy+LEV),a		; save new level
		jr	.vedlp
.dkyend:
		rst	8
		ld	(iy+LEV),e		; save last attack
		ld	(iy+MODE),100b		; and set to sustain
		jr	.vedlp
.chk4:
		cp	100b			; Sustain phase
		jr	nz,.vedlp
		ld	(iy+FLG),1		; psg update flag
		ld	a,(iy+LEV)		; a - Level
		rst	8
		add 	a,(iy+RRT)		; add Release Rate
		jr	c,.killenv		; release done
		ld	(iy+LEV),a		; set new Level
		jr	.vedlp
.killenv:
		ld	(iy+LEV),-1		; Silence this channel
		ld	(iy+MODE),0		; Reset mode
.vedlp:

	; ----------------------------
	; PSG UPDATE
	; ----------------------------
		ld	a,(iy+FLG)
		or	a
		jr	z,.noupd
		ld	(iy+FLG),0	; Reset until next one
		ld	e,c
		ld	a,(psgHatMode)
		ld	d,a
		and	011b
		cp	011b
		jr	nz,.normal
		rst	8
		ld	a,b		; Channel 4?
		cp	3
		jr	z,.silnc_3
		cp	4
		jr	nz,.do_nfreq
		ld	a,(psgHatMode)
		ld	d,a
		and	011b
		rst	8
		cp	011b
		jr	nz,.vonly
		ld	e,0C0h
		jr	.do_nfreq
.silnc_3:
		ld	a,-1
		jr	.vlmuch
.normal:
		ld	a,b
		cp	4
		jr	z,.vonly
.do_nfreq:
		ld	l,(iy+DTL)
		ld	h,(iy+DTH)

	; freq effects go here
	; (save e FIRST.)
	;	push	de
	;	pop	de
		ld	a,l		; Grab LSB 4 right bits
		and	00001111b
		or	e		; OR with channel set in e
		rst	8
		ld	(ix),a		; write it
		ld	a,l		; Grab LSB 4 left bits
		rrca
		rrca
		rrca
		rrca
		and	00001111b
		ld	e,a
		ld	a,h		; Grab MSB bits
		rst	8
		rlca
		rlca
		rlca
		rlca
		and	00110000b
		or	e
		ld	(ix),a
		rst	8
.vonly:
		ld	a,(iy+LEV)		; c - Level
		add	a,(iy+PVOL)		; Add MASTER volume
		jr	nc,.vlmuch
		ld	a,-1
.vlmuch:
		srl	a			; (Level >> 4)
		srl	a
		srl	a
		rst	8
		srl	a
		and	00001111b		; Filter volume value
		or	c			; and OR with current channel
		or	90h			; Set volume-set mode
	if ZSET_TESTME=0
		ld	(ix),a			; *** WRITE volume
	endif
		inc	(iy+PTMR)		; Update general timer
.noupd:
	; ----------------------------
		dec	iy			; next COM to check
		ld	a,c
		rst	8
		sub	a,20h			; next PSG backwards
		ld	c,a
		dec	b
		jp	nz,.vloop
		ret

; ---------------------------------------------
; FM register writes
;
; Input:
; d - ctrl
; e - data
; ---------------------------------------------

; c - KeyID
fm_autoreg:
		bit	2,c
		call	z,fm_send_1
		call	nz,fm_send_2
		ret
; Channels 1-3 and global registers
fm_send_1:
		ld	a,d
		ld	(Zym_ctrl_1),a
		nop
		ld	a,e
		ld	(Zym_data_1),a
		nop
		ret
; Channels 4-6
fm_send_2:
		ld	a,d
		ld	(Zym_ctrl_2),a
		nop
		ld	a,e
		ld	(Zym_data_2),a
		nop
		ret

; --------------------------------------------------------
; brute-force WAVE ON/OFF playback
; --------------------------------------------------------

dac_on:
		ld	a,2Bh
		ld	(Zym_ctrl_1),a
		ld	a,80h
		ld	(Zym_data_1),a
		ld 	a,zopcExx
		ld	(dac_me),a
		ld 	a,zopcPushAf
		ld	(dac_fill),a
		ret
dac_off:
		ld	a,2Bh
		ld	(Zym_ctrl_1),a
		ld	a,00h
		ld	(Zym_data_1),a
		ld 	a,zopcRet
		ld	(dac_me),a
		ld 	a,zopcRet
		ld	(dac_fill),a
		ret

; --------------------------------------------------------
; dac_play
;
; Plays a new sample
;
; NOTE:
; Set wave_Flags and wave_Pitch externally
; getting here.
; --------------------------------------------------------

dac_play:
		di
		call	dac_off
		exx				; flip exx regs
		ld	bc,dWaveBuff>>8		; bc - WAVFIFO MSB
		ld	de,(wave_Pitch)		; de - Pitch
		ld	hl,(dWaveBuff&0FFh)<<8	; hl - WAVFIFO LSB pointer (xx.00)
		exx				; move them back
		ld	hl,(wave_Start)
		ld 	a,(wave_Start+2)
		ld	(dDacPntr),hl
		ld	(dDacPntr+2),a
		ld	hl,(wave_Len)
		ld 	a,(wave_Len+2)
		ld	(dDacCntr),hl
		ld	(dDacCntr+2),a
		xor	a
		ld	(dDacFifoMid),a
		call	dac_firstfill
		call	dac_on
		ei
		ret

; --------------------------------------------------------

dac_firstfill:
		push	af
dac_refill:
		rst	8
		push	bc
		push	de
		push	hl
		ld	a,(wave_Flags)	; Already finished?
		cp	111b
		jp	nc,.dacfill_end
		ld	a,(dDacCntr+2)	; Last bytes
		ld	hl,(dDacCntr)
		ld	bc,80h
		scf
		ccf
		sbc	hl,bc
		sbc	a,0
		ld	(dDacCntr+2),a
		ld	(dDacCntr),hl
		ld	d,dWaveBuff>>8
		or	a
		jp	m,.dac_over
		ld	a,(dDacFifoMid)	; Update halfway value
		ld	e,a
		add 	a,80h
		ld	(dDacFifoMid),a
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		call	transferRom	; *** ROM ACCESS ***
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		ld	bc,80h
		add	hl,bc
		adc	a,0
		ld	(dDacPntr),hl
		ld	(dDacPntr+2),a
		jp	.dacfill_ret

; NOTE:
; This doesn't finish at the exact
; the END point.
.dac_over:
		ld	d,dWaveBuff>>8
		ld	a,(wave_Flags)	; LOOP enabled?
		and	001b
		jp	nz,.dacfill_loop
		ld	a,l
		add	a,80h
		ld	c,a
		ld	b,0
		push	bc
		ld	a,(dDacFifoMid)
		ld	e,a
		add	a,80h
		ld	(dDacFifoMid),a
		pop	bc
		ld	a,c
		or	b
		jr	z,.dacfill_end
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		call	transferRom	; *** ROM ACCESS ***
		jr	.dacfill_end
.dacfill_loop:
	; loop sample
		push	bc
		push	de
		ld	a,(wave_Loop+2)
		ld	c,a
		ld	de,(wave_Loop)
		ld	hl,(wave_Start)
		ld 	a,(wave_Start+2)
		add	a,c
		add	hl,de
		adc	a,0
		ld	(dDacPntr),hl
		ld	(dDacPntr+2),a
		ld	hl,(wave_Len)
		ld 	a,(wave_Len+2)
		sub	a,c
		scf
		ccf
		sbc	hl,de
		sbc	a,0
		ld	(dDacCntr),hl
		ld	(dDacCntr+2),a
		pop	de
		pop	bc
		ld	a,b
		or	c
		jr	z,.dacfill_ret
		ld	a,(dDacFifoMid)
		ld	e,a
		add	a,80h
		ld	(dDacFifoMid),a
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		call	transferRom	; *** ROM ACCESS ***
		jr	.dacfill_ret

.dacfill_end:
		call	dac_off		; DAC finished

.dacfill_ret:
		pop	hl
		pop	de
		pop	bc
		pop	af
		ret

; ====================================================================
; ----------------------------------------------------------------
; Tables
; ----------------------------------------------------------------

fmFreq_List:	dw 644
		dw 681
		dw 722
		dw 765
		dw 810
		dw 858
		dw 910
		dw 964
		dw 1021
		dw 1081
		dw 1146
		dw 1214
psgFreq_List:
		dw -1		; C-0 00
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1		; C-1 0C
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1		; C-2 18
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1		; C-3 24
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw -1
		dw 3F8h
		dw 3BFh
		dw 389h
		dw 356h		; C-4 30
		dw 326h
		dw 2F9h
		dw 2CEh
		dw 2A5h
		dw 280h
		dw 25Ch
		dw 23Ah
		dw 21Ah
		dw 1FBh
		dw 1DFh
		dw 1C4h
		dw 1ABh		; C-5 3C
		dw 193h
		dw 17Dh
		dw 167h
		dw 153h
		dw 140h
		dw 12Eh
		dw 11Dh
		dw 10Dh
		dw 0FEh
		dw 0EFh
		dw 0E2h
		dw 0D6h		; C-6 48
		dw 0C9h
		dw 0BEh
		dw 0B4h
		dw 0A9h
		dw 0A0h
		dw 097h
		dw 08Fh
		dw 087h
		dw 07Fh
		dw 078h
		dw 071h
		dw 06Bh		; C-7 54
		dw 065h
		dw 05Fh
		dw 05Ah
		dw 055h
		dw 050h
		dw 04Bh
		dw 047h
		dw 043h
		dw 040h
		dw 03Ch
		dw 039h
		dw 036h		; C-8 60
		dw 033h
		dw 030h
		dw 02Dh
		dw 02Bh
		dw 028h
		dw 026h
		dw 024h
		dw 022h
		dw 020h
		dw 01Fh
		dw 01Dh
		dw 01Bh		; C-9 6C
		dw 01Ah
		dw 018h
		dw 017h
		dw 016h
		dw 015h
		dw 013h
		dw 012h
		dw 011h
 		dw 010h
 		dw 009h
 		dw 008h
		dw 006h

wavFreq_List:	dw 100h		; C-0
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h		; C-1
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h		; C-2
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 036h
		dw 03Bh
		dw 03Eh		; C-3
		dw 043h		; C#3
		dw 046h		; D-3
		dw 049h		; D#3
		dw 04Eh		; E-3
		dw 054h		; F-3
		dw 058h		; F#3
		dw 05Eh		; G-3 -17
		dw 063h		; G#3
		dw 068h		; A-3
		dw 070h		; A#3
		dw 075h		; B-3
		dw 085h		; C-4 -12
		dw 087h		; C#4
		dw 08Ch		; D-4
		dw 09Ah		; D#4
		dw 09Eh		; E-4
		dw 0ADh		; F-4
		dw 0B2h		; F#4
		dw 0C0h		; G-4
		dw 0CCh		; G#4
		dw 0D7h		; A-4
		dw 0E6h		; A#4
		dw 0F0h		; B-4
		dw 100h		; C-5 ****
		dw 110h		; C#5
		dw 120h		; D-5
		dw 12Eh		; D#5
		dw 142h		; E-5
		dw 15Ah		; F-5
		dw 16Ah		; F#5 +6
		dw 17Fh		; G-5
		dw 191h		; G#5
		dw 1ACh		; A-5
		dw 1C2h		; A#5
		dw 1E0h		; B-5
		dw 1F8h		; C-6 +12
		dw 210h		; C#6
		dw 240h		; D-6
		dw 260h		; D#6
		dw 280h		; E-6
		dw 2A0h		; F-6
		dw 2D0h		; F#6
		dw 2F8h		; G-6
		dw 320h		; G#6
		dw 350h		; A-6
		dw 380h		; A#6
		dw 3C0h		; B-6
		dw 400h		; C-7
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h		; C-8
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h		; C-9
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h
		dw 100h

fmcach_list:	dw fmcach_1
		dw fmcach_2
		dw fmcach_3
		dw 0		; <-- skipped
		dw fmcach_4
		dw fmcach_5
		dw fmcach_6

; ====================================================================
; ----------------------------------------------------------------
; MASTER buffers list
;
; dw track_buffer
; dw channel_list,block_cache,header_cache,instr_cache,track_cache
; db max_blocks,max_headers,max_instr,max_chnls
;
; (track_cache: 1BIT SIZES ONLY, ALIGNED)
; ----------------------------------------------------------------

nikona_BuffList:
	dw trkBuff_0,trkChnl_0,trkBlks_0,trkHdrs_0,trkInsD_0,trkCach_0
	db MAX_BLOCKS,MAX_HEADS,MAX_INS,MAX_TRKCHN
	dw trkBuff_1,trkChnl_1,trkBlks_1,trkHdrs_1,trkInsD_1,trkCach_1
	db MAX_BLOCKS,MAX_HEADS,MAX_INS,MAX_TRKCHN
; 	dw trkBuff_2,trkChnl_2,trkBlks_2,trkHdrs_2,trkInsD_2,trkCach_2
; 	db MAX_BLOCKS,MAX_HEADS,MAX_INS,MAX_TRKCHN
	dw -1

nikona_SetMstrList:
	db 0				; ** 32-bit 68k address **
	db (Gema_MasterList>>16)&0FFh
	db (Gema_MasterList>>8)&0FFh
	db Gema_MasterList&0FFh

; ====================================================================
; ----------------------------------------------------------------
; Buffer section
; ----------------------------------------------------------------

; --------------------------------------------------------
; Channel table struct:
; 00  - Linked tracker channel
; 02  - 00h-7Fh: Priority level / 80h+ Silence request (chip ID)
; 03  - Intrument cache pointer
; 05  - Chip index (YM2612: KEY index)
; 06  - Frequency/Note value
; 08  - Current volume: 00-max
; 09  - FREE
; 0A  - FREE
; 0B  - FREE
; 0C+ - Misc. settings for the current chip

; PSG   80h
; PSGN  90h
; FM   0A0h
; FM3  0B0h
; DAC  0C0h
; PWM  0D0h
; --------------------------------------------------------

tblList:	dw tblPSG-tblList		;  80h
		dw tblPSGN-tblList|8000h	;  90h *
		dw tblFM-tblList		; 0A0h
		dw tblFM3-tblList|8000h		; 0B0h *
		dw tblFM6-tblList|8000h		; 0C0h *
		dw tblPWM-tblList		; 0D0h
		dw 0
		dw 0
tblPSG:		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 1
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,01h,00h,00h	; Channel 2
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,02h,00h,00h	; Channel 3
		db 00h,00h,00h,00h,00h,00h,00h,00h
		dw -1	; end-of-list
tblPSGN:	db 00h,00h,00h,00h,00h,03h,00h,03h	; Noise
		db 00h,00h,00h,00h,00h,00h,00h,00h
tblFM:		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 1
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,01h,00h,00h	; Channel 2
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,04h,00h,00h	; Channel 4 <--
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,05h,00h,00h	; Channel 5
		db 00h,00h,00h,00h,00h,00h,00h,00h
tblFM3:		db 00h,00h,00h,00h,00h,02h,00h,00h	; Channel 3 <--
		db 00h,00h,00h,00h,00h,00h,00h,00h
tblFM6:		db 00h,00h,00h,00h,00h,06h,00h,00h	; Channel 6 <--
		db 00h,00h,00h,00h,00h,00h,00h,00h
		dw -1	; end-of-list
tblPWM:		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 1
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,01h,00h,00h	; Channel 2
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,02h,00h,00h	; Channel 3
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,03h,00h,00h	; Channel 4
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,04h,00h,00h	; Channel 5
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,05h,00h,00h	; Channel 6
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,06h,00h,00h	; Channel 7
		db 00h,00h,00h,00h,00h,00h,00h,00h
		dw -1	; end-of-list

; FM patch storage
fmcach_1	ds 28h
fmcach_2	ds 28h
fmcach_3	ds 28h
fmcach_4	ds 28h
fmcach_5	ds 28h
fmcach_6	ds 28h

pwmcom:	db 00h,00h,00h,00h,00h,00h,00h,00h	; 0 - Playback bits: KeyOn/KeyOff/KeyCut bits
	db 00h,00h,00h,00h,00h,00h,00h,00h	; 8 - Volume | Pitch MSB
	db 00h,00h,00h,00h,00h,00h,00h,00h	; 16 - Pitch LSB
	db 00h,00h,00h,00h,00h,00h,00h,00h	; 24 - Flags: Stereo/Loop/Left/Right | 32-bit**
	db 00h,00h,00h,00h,00h,00h,00h,00h	; 32 - **sample location
	db 00h,00h,00h,00h,00h,00h,00h,00h
	db 00h,00h,00h,00h,00h,00h,00h,00h

psgcom:	db 00h,00h,00h,00h	;  0 - command 1 = key on, 2 = key off, 4 = stop snd
	db -1, -1, -1, -1	;  4 - output level attenuation (%llll.0000, -1 = silent)
	db 00h,00h,00h,00h	;  8 - attack rate (START)
	db 00h,00h,00h,00h	; 12 - decay rate
	db 00h,00h,00h,00h	; 16 - sustain level attenuation (MAXIMUM)
	db 00h,00h,00h,00h	; 20 - release rate
	db 00h,00h,00h,00h	; 24 - envelope mode 0 = off, 1 = attack, 2 = decay, 3 = sustain
	db 00h,00h,00h,00h	; 28 - freq bottom 4 bits
	db 00h,00h,00h,00h	; 32 - freq upper 6 bits
	db 00h,00h,00h,00h	; 36 - attack level attenuation
	db 00h,00h,00h,00h	; 40 - flags to indicate hardware should be updated
	db 00h,00h,00h,00h	; 44 - timer for sustain
	db 00h,00h,00h,00h	; 48 - MAX Volume
	db 00h,00h,00h,00h	; 52 - Vibrato value
	db 00h,00h,00h,00h	; 56 - General timer

; mailboxes	ds 40h		; GEMS style mailboxes/events
trkListCach	ds 4*10h	; 40h bytes
wave_Start	dw 0		; START: 68k 24-bit pointer
		db 0
wave_Len	dw 0		; LENGTH 24-bit
		db 0
wave_Loop	dw 0		; LOOP POINT 24-bit
		db 0
wave_Pitch	dw 0100h	; 01.00h
wave_Flags	db 0		; WAVE playback flags (%10x: 1 loop / 0 no loop)


tickSpSet	db 0		; **
tickFlag	db 0		; Tick flag from VBlank
tickCnt		db 0		; ** Tick counter (PUT THIS AFTER tickFlag)
psgHatMode	db 0		; Current PSGN mode
fmSpecial	db 0		; copy of FM3 enable bit
headerOut	ds 00Ch		; Temporal storage for 68k pointers
headerOut_e	ds 2
sampleHead	ds 006h
commZRead	db 0			; cmd fifo READ pointer (here)

; --------------------------------------------------------
; * USER customizable section *
;
; trkCach's MUST BE 00h ALIGNED.
; --------------------------------------------------------

trkBuff_0	ds 30h			; TRACK BUFFER 0
trkBuff_1	ds 30h			; TRACK BUFFER 1
trkBuff_2	ds 30h			; TRACK BUFFER 2
; trkBuff_3	ds 30h			; TRACK BUFFER 3
trkChnl_0	ds 8*MAX_TRKCHN
trkChnl_1	ds 8*MAX_TRKCHN
trkChnl_2	ds 8*MAX_TRKCHN
; trkChnl_3	ds 8*MAX_TRKCHN
trkHdrs_0	ds 4*MAX_HEADS		; dw point,rowcntr
trkHdrs_1	ds 4*MAX_HEADS
trkHdrs_2	ds 4*MAX_HEADS
; trkHdrs_3	ds 4*MAX_HEADS
trkInsD_0	ds 8*MAX_INS
trkInsD_1	ds 8*MAX_INS
trkInsD_2	ds 8*MAX_INS
; trkInsD_3	ds 8*MAX_INS
trkBlks_0	ds MAX_BLOCKS
trkBlks_1	ds MAX_BLOCKS
trkBlks_2	ds MAX_BLOCKS
; trkBlks_3	ds MAX_BLOCKS

; ====================================================================
; ----------------------------------------------------------------
; WAVE playback buffer
;
; Located at 200h
; ----------------------------------------------------------------

		org 1D00h
dWaveBuff	ds 100h		; WAVE data buffer: 100h bytes, updates every 80h
trkCach_0	ds MAX_RCACH	; ** MUST BE aligned **
trkCach_1	ds MAX_RCACH
trkCach_2	ds MAX_RCACH
trkCach_3	ds MAX_RCACH

; --------------------------------------------------------

		cpu 68000	; [AS] Exit Z80
		padding off	; [AS] NO padding (again)
		phase Z80_TOP+*	; [AS] Relocate PC
		align 2		; [AS] Align by 2
