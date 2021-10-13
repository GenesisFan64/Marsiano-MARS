; --------------------------------------------------------
; Marsiano/GEMA sound driver, inspired by GEMS
;
; WARNING: The sample playback has to be sync'd manually
; on any code change, DAC sample rate is in
; the 16000hz range
; --------------------------------------------------------

		cpu Z80			; Set Z80 here
		phase 0			; And set PC to 0

; --------------------------------------------------------
; Settings
; --------------------------------------------------------

MAX_TRKS	equ 3		; Max tracks to read
MAX_TRKCHN	equ 18		; Max internal tracker channels
ZSET_TESTWAV	equ 0		; DEBUG ONLY, to test WAVE quality playback

; --------------------------------------------------------
; Structs
;
; NOTE: struct doesn't work here. use equs instead
; --------------------------------------------------------

; trkBuff struct
; LIMIT: 20h bytes
trk_romBlk	equ 0			; 24-bit base block data
trk_romPatt	equ 3			; 24-bit base patt data
trk_romIns	equ 6			; 24-bit ROM instrument pointers
trk_romPattRd	equ 9			; same but for reading
trk_Read	equ 12			; Current track position (in cache)
trk_Rows	equ 14			; Current track length
trk_Halfway	equ 16			; Only 00h or 80h
trk_currBlk	equ 17			; Current block
trk_setBlk	equ 18			; Start on this block
trk_status	equ 19			; %ERSx xxxx | E-enabled / R-Init or Restart track / S-sfx mode
trk_tickTmr	equ 20			; Ticks timer
trk_tickSet	equ 21			; Ticks set for this track

; Tracker channel buffer MAX 8 bytes
chnl_Chip	equ 0			; Channel chip: etti iiii | e-enable t-type i-chip channel
chnl_Type	equ 1			; Impulse note bits
chnl_Note	equ 2
chnl_Ins	equ 3
chnl_Vol	equ 4
chnl_EffId	equ 5
chnl_EffArg	equ 6
chnl_Status	equ 7			; 000e uuuu | u-update bits from Tracker (resets)

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; To brute force DAC playback
; on or off
zopcEx		equ	08h
zopcNop		equ	00h
zopcRet		equ 	0C9h
zopcExx		equ	0D9h		; (dac_me ONLY)
zopcPushAf	equ	0F5h		; (dac_fill ONLY)

; PSG external control
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

;FMCOM		equ	0
FMKEYS		equ	6
FMVOL		equ	12
FMRG_A4		equ	18
FMRG_A0		equ	24
FMRG_B0		equ	30
FMRG_B4		equ	36

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
;
; Writes wave data to DAC using the data stored
; on the wave buffer.
; call this routine every 6 or more lines of code to
; keep playing the sample while processing stuff
; (use any emu-debugger to check if it still plays
; at stable 16000hz)
;
; Input (EXX):
;  c - WAVEFIFO MSB
; de - Pitch (xx.00)
; h  - WAVEFIFO LSB (as xx.00)
;
; Uses (EXX):
; b
;
; *** self-modifiable code ***
; call dac_on to enable playback
; or
; call dac_off to disable it.
; (check for FM6 manually)
; --------------------------------------------------------

		org	8
dac_me:		exx	; <-- code changes between EXX(play) and RET(stop)
		ex	af,af'
		ld	b,l
		ld	a,2Ah
		ld	(Zym_ctrl_1),a
		nop
		ld	l,h
		ld	h,c
		ld	a,(hl)
		ld	(Zym_data_1),a
		nop
		ld	h,l
		ld	l,b
		add	hl,de
		ex	af,af'
		exx
		ret

; --------------------------------------------------------
; Z80 Interrupt at 0038h
;
; Sets the TICK flag
; --------------------------------------------------------

		org 0038h		; Align to 0038h
		ld	(tickFlag),sp	; Use sp to set TICK flag (xx1F, check for tickFlag+1)
		di			; Disable interrupt until next request
		ret

; --------------------------------------------------------
; Initilize
; --------------------------------------------------------

z80_init:
		call	gema_init	; Initilize VBLANK sound driver
		ei

; --------------------------------------------------------
; MAIN LOOP
; --------------------------------------------------------

drv_loop:
		rst	8
		call	check_tick	; Check for tick on VBlank
		call	dac_fill
		rst	8

	; Check for tick and tempo
		ld	b,0		; b - Reset current flags (beat|tick)
		ld	a,(tickCnt)
		sub	1
		jr	c,.noticks
		ld	(tickCnt),a
		call	chip_env	; Process PSG volume and freqs manually
		call	check_tick	; Check for another tick
		ld 	b,01b		; Set TICK (01b) flag, and clear BEAT
.noticks:
		rst	8
		ld	a,(sbeatAcc+1)	; check beat counter (scaled by tempo)
		sub	1
		jr	c,.nobeats
		ld	(sbeatAcc+1),a	; 1/24 beat passed.
		set	1,b		; Set BEAT (10b) flag
		rst	8
.nobeats:
		ld	a,b
		or	a
		jr	z,.neither
		rst	8
		ld	(currTickBits),a; Save BEAT/TICK bits
		call	check_tick
		call	setupchip	; Setup note changes to soundchips
		call	check_tick
		call	updtrack	; Update track data
		call	check_tick
.neither:
; 		call	mars_scomm
		nop
		nop
		rst	8

.next_cmd:
		call	dac_fill
		rst	8
		ld	a,(commZWrite)
		ld	b,a
		ld	a,(commZRead)
		cp	b
		jr	z,drv_loop
		call	get_cmdbyte
		cp	-1			; Read -1 (Start of command)
		jr	nz,drv_loop
		call	get_cmdbyte		; Read cmd number
		add	a,a
		ld	hl,.list
		ld	d,0
		ld	e,a
		add	hl,de
		rst	8
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		jp	(hl)
.list:
		dw .cmnd_trkplay	; $00
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $04
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $08
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $0C
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $10
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $14
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $18
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $1C
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0
		dw .cmnd_0		; $20
		dw .cmnd_wav_set	; $21
		dw .cmnd_wav_pitch	; $22

; --------------------------------------------------------
; Command list
; --------------------------------------------------------

.cmnd_0:
		jr	$
		jr	.next_cmd

; --------------------------------------------------------
; $01 - Set NEW track
; --------------------------------------------------------

; Slot
; Ticks
; 24-bit patt data
; 24-bit block data

.cmnd_trkplay:
		call	get_cmdbyte		; Get slot position
		ld	iy,trkBuff
		ld	de,0			; Get $0x00
		ld	d,a
		add	iy,de
		call	get_cmdbyte		; Get ticks
		ld	(iy+trk_tickSet),a
		call	get_cmdbyte		; Pattern data
		ld	(iy+trk_romPatt),a
		call	get_cmdbyte
		ld	(iy+(trk_romPatt+1)),a
		call	get_cmdbyte
		ld	(iy+(trk_romPatt+2)),a
		call	get_cmdbyte		; Block data
		ld	(iy+trk_romBlk),a
		call	get_cmdbyte
		ld	(iy+(trk_romBlk+1)),a
		call	get_cmdbyte
		ld	(iy+(trk_romBlk+2)),a
		call	get_cmdbyte		; Instrument data
		ld	(iy+trk_romIns),a
		call	get_cmdbyte
		ld	(iy+(trk_romIns+1)),a
		call	get_cmdbyte
		ld	(iy+(trk_romIns+2)),a
		ld	a,1
		ld	(iy+trk_tickTmr),a
		ld	a,(iy+trk_status)
		rst	8
		or	11000000b		; Set Enable + REFILL flags
		ld	(iy+trk_status),a
		jp	.next_cmd

; --------------------------------------------------------
; $21 - change current wave pitch
; --------------------------------------------------------

.cmnd_wav_set:
		ld	iy,wave_Start
		call	get_cmdbyte		; Start address
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte		; Length
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte		; Loop point
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte		; Pitch
		ld	(iy),a
		inc	iy
		call	get_cmdbyte
		ld	(iy),a
		inc	iy
		call	get_cmdbyte		; Flags
		ld	(iy),a
		inc	iy
		call	dac_play
		jp	.next_cmd

; --------------------------------------------------------
; $22 - change current wave pitch
; --------------------------------------------------------

.cmnd_wav_pitch:
		exx
		push	de
		exx
		pop	hl
		rst	8
		call	get_cmdbyte	; $00xx
		ld	e,a
		call	get_cmdbyte	; $xx00
		ld	d,a
		push	de
		rst	8
		exx
		pop	de
		exx
		jp	drv_loop

; --------------------------------------------------------
; Read cmd byte, auto re-aligns to 7Fh
; --------------------------------------------------------

get_cmdbyte:
		push	bc
		push	de
		push	hl
.getcbytel:
		ld	a,(commZWrite)
		ld	b,a
		ld	a,(commZRead)
		cp	b
		jr	z,.getcbytel		; wait for a command from 68k
		rst	8
		ld	b,0
		ld	c,a
		ld	hl,commZfifo
		add	hl,bc
		inc	a
		and	3Fh			; limit to 128
		rst	8
		ld	(commZRead),a
		ld	a,(hl)
		pop	hl
		pop	de
		pop	bc
		ret

; ====================================================================
; ----------------------------------------------------------------
; Sound playback code
; ----------------------------------------------------------------

; --------------------------------------------------------
; Read track data
; --------------------------------------------------------

updtrack:
		call	dac_fill
		ld	iy,trkBuff
		ld	hl,blkHeadC
		ld	de,trkDataC
		ld	bc,insDataC
		ld	(currTrkBlkHd),hl
		ld	(currTrkData),de
		ld	(currInsData),bc
		ld	b,MAX_TRKS
.next:
		push	bc
		call	.read_track
		pop	bc

		ld	de,100h			; Next blocks
		add	iy,de
		ld	hl,(currTrkData)
		add	hl,de
		ld	(currTrkData),hl
		ld	de,100h			; Next intruments
		ld	hl,(currInsData)
		add	hl,de
		ld	(currInsData),hl
		ld	de,80h			; Next track points
		ld	hl,(currTrkBlkHd)
		add	hl,de
		rst	8
		ld	(currTrkBlkHd),hl

		djnz	.next
		ret

; ----------------------------------------
; Read current track
; ----------------------------------------

.read_track:
		rst	8
		ld	b,(iy+trk_status)	; b - Track status
		bit	7,b			; Active?
		ret	z
		ld	a,(currTickBits)
		bit	5,b			; Status: sfx mode?
		jp	nz,.sfxmd
		nop
		nop
		nop
; 		bit	1,a			; BEAT passed?
; 		ret	z
.sfxmd:
		bit	0,a			; TICK passed?
		ret	z
		bit	6,b			; Restart/First time?
		call	nz,.first_fill
		ld	a,(iy+trk_tickTmr)	; Tick timer for this track
		dec	a
		ld	(iy+trk_tickTmr),a
		or	a
		ret	nz			; If != 0, exit
		ld	a,(iy+trk_tickSet)	; Set new tick timer
		ld	(iy+trk_tickTmr),a
		rst	8
		ld	l,(iy+trk_Read)		; hl - Pattern data to read in cache
		ld	h,(iy+((trk_Read+1)))
		ld	c,(iy+trk_Rows)		; bc - Set row counter
		ld	b,(iy+(trk_Rows+1))
		ld	a,c
		or	b
		call	z,.next_track
		rst	8

; --------------------------------
; Main reading loop
; --------------------------------

.next_note:
		ld	a,(hl)			; Check if timer or note
		or	a
		jp	z,.exit			; If == 00h: exit
		jp	m,.has_note		; 80h-0FFh: note data
		ld	a,(hl)			; 01h-07Fh: delay timer
		dec	a
		ld	(hl),a
		jp	.decrow

; --------------------------------
; Exit
; --------------------------------

.exit:
		call	.inc_cpatt
		ld	(iy+trk_Read),l		; Update read location
		ld	(iy+((trk_Read+1))),h
.decrow:
		rst	8
		dec	bc			; Decrement this row
		ld	(iy+trk_Rows),c		; And update it
		ld	(iy+(trk_Rows+1)),b
		ret

; --------------------------------
; New note request
; --------------------------------

.has_note:
		push	bc			; Save rowcount
		ld	c,a			; c - Copy of control+channel
		call	.inc_cpatt
		ld	a,c
		push	iy
		pop	ix
		ld	de,20h
		add	ix,de
		rst	8
		ld 	d,0
		and	00111111b
		add	a,a			; * 8
		add	a,a
		add	a,a
		ld	e,a
		add	ix,de
		rst	8
		ld	b,(ix+chnl_Type)	; b - our current Note type
		bit	6,c			; Next byte is new type?
		jp	z,.old_type
		ld	a,(hl)			;
		ld	(ix+chnl_Type),a
		ld	b,a
		inc 	l
.old_type:

	; b - evinEVIN
	;     E-effect/V-volume/I-instrument/N-note
	;     evin: recycle value stored on the buffer
	;     EVIN: next byte(for eff:2 bytes) contains new value
		rst	8
		bit	0,b
		jp	z,.no_note
		ld	a,(hl)
		ld	(ix+chnl_Note),a
		call	.inc_cpatt
.no_note:
		bit	1,b
		jp	z,.no_ins
		ld	a,(hl)
		ld	(ix+chnl_Ins),a
		call	.inc_cpatt
.no_ins:
		rst	8
		bit	2,b
		jp	z,.no_vol
		ld	a,(hl)
		ld	(ix+chnl_Vol),a
		call	.inc_cpatt
.no_vol:
		bit	3,b
		jp	z,.no_eff
		ld	a,(hl)
		ld	(ix+chnl_EffId),a
		call	.inc_cpatt
		ld	a,(hl)
		ld	(ix+chnl_EffArg),a
		call	.inc_cpatt
.no_eff:
		rst	8
		ld	a,b		; Merge Impulse recycle bits to main bits
		srl	a
		srl	a
		srl	a
		srl	a
		and	1111b
		ld	c,a
		rst	8
		ld	a,b
		and	1111b
		or	c
		ld	c,a
		ld	a,(ix+chnl_Status)
		or	c
		ld	(ix+chnl_Status),a
		rst	8
		pop	bc			; Restore rowcount

	; Effects that manipulate internal playback
		or	a			; Any status change?
		jp	z,.no_updst
		ld	a,(ix+chnl_EffId)
		cp	1
		call	z,.eff_A
		cp	2			; Effect B: position jump?
		call	z,.eff_B
.no_updst:
		jp	.next_note

; ----------------------------------------
; Effect A: Set ticks
; ----------------------------------------

.eff_A:
		ld	e,(ix+chnl_EffArg)
		ld	(iy+trk_tickSet),e
		ld	(iy+trk_tickTmr),e
		ret

; ----------------------------------------
; Effect B: jump to a new block
; ----------------------------------------

; TODO: add auto-silence
.eff_B:
		call	dac_fill
		ld	a,(ix+chnl_EffArg)
		ld 	(iy+trk_currBlk),a
		push	iy			; Clear all channels first
		pop	ix
		ld	de,20h
		rst	8
		add	ix,de
		ld	de,8
		xor	a
		ld	b,MAX_TRKCHN*8/2
.clrf2:
		ld	(ix),a
		inc	ix
		rst	8
		nop
		nop
		ld	(ix),a
		inc	ix
		djnz	.clrf2
		rst	8
		ld	a,(iy+trk_currBlk)
		jr	.set_track

; ----------------------------------------
; Call this to increment the
; cache pattern read pointer (iy+trk_Read)
; it also refills the next section to
; read if needed.
;
; NOTE: breaks A
; ----------------------------------------

.inc_cpatt:
		inc	l
		ld	a,(iy+trk_Halfway)
		xor	l
		and	080h
		ret	z

		call	dac_fill
		push	hl
		push	bc
		ld	d,h
		ld	a,(iy+trk_Halfway)
		ld	e,a
		add 	a,080h
		ld	(iy+trk_Halfway),a
		ld	bc,80h
		ld	l,(iy+trk_romPattRd)
		rst	8
		ld	h,(iy+(trk_romPattRd+1))
		ld	a,(iy+(trk_romPattRd+2))
		add	hl,bc
		adc	a,0
		ld	(iy+trk_romPattRd),l
		ld	(iy+(trk_romPattRd+1)),h
		ld	(iy+(trk_romPattRd+2)),a
		call	transferRom
		rst	8
		pop	bc
		pop	hl
		ret

; ----------------------------------------
; If pattern finished, load the next one
; ----------------------------------------

.next_track:
		ld	a,(iy+trk_currBlk)
		inc	a
		ld 	(iy+trk_currBlk),a
.set_track:
		call 	dac_fill
		rst	8
		ld	l,80h			; Set LSB as 40h
		ld	(iy+trk_Read),l
		push	hl
		rst	8
		ld	hl,(currTrkBlkHd)	; Block section
		ld	de,0
		ld	e,a
		xor	a			; Reset halfway, next pass
		ld	(iy+trk_Halfway),a	; will load the first section
		add	hl,de
		ld	a,(hl)			; a - block
		pop	hl
		cp	-1
		jp	z,.track_end
		ld	hl,(currTrkBlkHd)	; Read block again
		rst	8
		ld	de,40h
		add	hl,de			; +80h, point to heads
		add	a,a
		add	a,a
		ld	e,a			; block * 4
		add	hl,de
		ld	c,(hl)
		inc	hl
		ld	b,(hl)			; bc - numof Rows
		inc	hl
		rst	8
		ld	e,(hl)
		inc	hl
		ld	d,(hl)			; de - pointer (base+increment by this)
		ld	(iy+trk_Rows),c		; Save this number of rows
		ld	(iy+(trk_Rows+1)),b
		ld	l,(iy+trk_romPatt)	; hl - Low and Mid pointer of ROM patt data
		ld	h,(iy+(trk_romPatt+1))
		ld	a,(iy+(trk_romPatt+2))
		add	hl,de			; increment to get new pointer
		adc	a,0			; and highest byte too.
		ld	(iy+trk_romPattRd),l	; Save copy of the pointer
		ld	(iy+(trk_romPattRd+1)),h
		ld	(iy+(trk_romPattRd+2)),a
		ld	d,(iy+(trk_Read+1))
		ld	e,(iy+trk_Read)
		ld	bc,080h			; bc - 080h
		call	transferRom
		call	dac_fill
		ld	h,(iy+(trk_Read+1))
		ld	l,(iy+trk_Read)
		ld	c,(iy+trk_Rows)
		ld	b,(iy+(trk_Rows+1))
		ret

; If -1, track ends
.track_end:
		push	iy
		pop	ix
		ld	de,20h
		add	ix,de
		ld	de,8
		xor	a
		ld	b,MAX_TRKCHN
.clrfe:
		ld	(ix+chnl_Note),-2
		ld	(ix+chnl_Status),001b
		add	ix,de
		djnz	.clrfe
		rst	8
		ld	(iy+trk_status),0
		ret

; ----------------------------------------
; First play
; ----------------------------------------

.first_fill:
		call	dac_fill
		res	6,b			; Reset FILL flag
		ld	(iy+trk_status),b
		push	iy
		pop	ix
		ld	de,20h			; go to channel data
		add	ix,de
		rst	8
		ld	bc,0
		ld	de,8
		ld	b,MAX_TRKCHN
.clrf:
		push	de
		ld	a,(ix+chnl_Chip)
		or	a
		call	nz,.silnc_chip
		rst	8
		ld	(ix+chnl_Note),-2
		ld	(ix+chnl_Status),001b
		pop	de
		add	ix,de
		djnz	.clrf
		ld	a,(iy+trk_setBlk)
		ld 	(iy+trk_currBlk),a
		ld	(iy+trk_Halfway),0	; Reset halfway
		rst	8

		ld	l,(iy+trk_romIns)	; Recieve 0FFh (almost 100h) of instrument data
		ld	h,(iy+(trk_romIns+1))	; NOTE: the last byte is ignored.
		ld	a,(iy+(trk_romIns+2))
		ld	de,(currInsData)
		ld	bc,0FFh
		call	transferRom
		call	dac_fill
		ld	l,(iy+trk_romBlk)	; Recieve 40h of block data
		ld	h,(iy+(trk_romBlk+1))
		ld	a,(iy+(trk_romBlk+2))
		ld	de,(currTrkBlkHd)
		ld	bc,40h
		push	de
		call	transferRom
		pop	de
		rst	8
		ld	a,e
		add	a,40h
		ld	e,a
		ld	l,(iy+trk_romPatt)	; Recieve 40h of header data
		ld	h,(iy+(trk_romPatt+1))
		call	dac_fill
		ld	a,(iy+(trk_romPatt+2))
		ld	bc,40h
		call	transferRom
		ld	a,0

		ld	hl,(currTrkBlkHd)	; hl - Cache'd Block section
		ld	de,0
		ld	e,a
		add	hl,de
		rst	8
		ld	a,(hl)			; a - block
		cp	-1
		jp	z,.track_end
		call	dac_fill
		ld	hl,(currTrkBlkHd)	; hl - Header section
		ld	de,40h			;
		add	hl,de
		add	a,a
		add	a,a
		ld	e,a			; block * 4
		rst	8
		add	hl,de
		ld	c,(hl)
		inc	hl
		ld	b,(hl)			; bc - numof Rows
		inc	hl
		rst	8
		ld	e,(hl)
		inc	hl
		ld	d,(hl)			; de - pointer (base+increment by this)
		ld	(iy+trk_Rows),c		; Save this number of rows
		ld	(iy+(trk_Rows+1)),b
		rst	8
		ld	l,(iy+trk_romPatt)	; hl - Low and Mid pointer of ROM patt data
		ld	h,(iy+(trk_romPatt+1))
		ld	a,(iy+(trk_romPatt+2))
		add	hl,de			; increment to get new pointer
		adc	a,0			; and it's LSB
		rst	8
		ld	(iy+trk_romPattRd),l	; Save copy of the pointer
		ld	(iy+(trk_romPattRd+1)),h
		ld	(iy+(trk_romPattRd+2)),a
		ld	de,(currTrkData)	; de - Output data
		ld	b,a
		rst	8
		ld	a,e
		add	a,80h
		ld	e,a
		ld	a,b
		ld	(iy+trk_Read),e
		ld	(iy+((trk_Read+1))),d
		call	dac_fill
		ld	bc,080h			; fill sections 2,3,4
		call	transferRom
		ret

; PSG: 80h
; FM:  90h + keys
; FM3: A0h
; DAC: B0h
; PWM: C0h
.silnc_chip:
		ld	c,a
		and	11110000b
		cp	10000000b
		jp	z,.is_psg
		cp	090h
		jp	z,.is_fm
		;cp	0A0h
		;jp	z,.is_fm3
		cp	0B0h
		jp	z,.is_dac
		;cp	0C0h
		;jp	z,.is_pwm
		ret
; FM
.is_fm:
; 		ld	hl,tblFM
; 		bit	2,c
; 		jr	z,.topl
; 		ld	hl,tblFM_mid
; .topl:
; 		ld	a,c
; 		and	11b
; 		add	a,a		; * 10h
; 		add	a,a
; 		add	a,a
; 		add	a,a
; 		ld	de,0
; 		ld	e,a
; 		add	hl,de
; 		ld	(hl),0
; 		inc	hl
; 		ld	(hl),0
;
; ; 		ld	a,c
; ; 		and	111b
; ; 		ld	e,a
; ; 		ld	d,28h
; ; 		call	fm_send_1
; 		ld	hl,fmcom_OLD
; 		ld	d,0
; 		add	hl,de
; 		ld	(hl),100b
		ret

; FM6
.is_dac:
		call	dac_off
		ld	hl,tblFM6
		ld	(hl),0
		ret

; PSG
.is_psg:
		ld	a,c
		and	111b
		cp	3		; PSGN later
		jr	z,.is_psgn
		rst	8
		ld	c,a
		add	a,a		; * 10h
		add	a,a
		add	a,a
		add	a,a
		rst	8
		ld	de,0
		ld	e,a
		ld	hl,tblPSG
		add	hl,de
		ld	(hl),0		; delete Link
		inc	hl
		ld	(hl),0
		rst	8
		dec	hl
		dec	hl
	; same-link check goes here
		ld	hl,psgcom
		ld	de,0
		ld	e,c
		add	hl,de
		ld	(hl),100b	; KEY STOP
		ret
; PSGN
.is_psgn:
		rst	8
		ld	hl,0
		ld	(tblPSGN),hl	; delete Link
		rst	8
	; same-link check goes here
		xor	a
		ld	(psgHatMode),a
		ld	hl,psgcom+3	; KEY STOP
		ld	(hl),100b
		ret

; ; --------------------------------------------------------
; ; For 32X:
; ; Communicate to Master SH2 using CMD interrupt
; ; --------------------------------------------------------
;
; mars_scomm:
; 		ret
; 		ld	de,(reqMarsTrnf)	; New PWM ins data?
; 		ld	a,e
; 		or	d
; 		jp	z,.playbck
; 		call	dac_fill
; 		ld	hl,(reqMarsTrnf)
; 		ld	c,21h			; 21h: Send copy of Instrlist
; 		ld	b,80h/2			; num of words to transfer
; 		call	mars_zcomm
; 		ld	de,0			; Reset wordflag
; 		ld	(reqMarsTrnf),de
; 		ret
; .playbck:
; 		ld	iy,PWMVTBL
; 		ld	b,7			; 7 channels
; .next:
; 		push	bc
; 		push	iy
; 		ld	a,(iy)
; 		or	a
; 		jp	p,.disbld
; 		and	01100000b
; 		or	a
; 		call	nz,.play
; 		res	6,(iy)
; 		res	5,(iy)
; .disbld:
; 		pop	iy
; 		pop	bc
; 		ld	de,8
; 		rst	8
; 		add	iy,de
; 		djnz	.next
;
; ; 	; All this code just to tell SH2
; ; 	; to update PWM list...
; ; 		rst	8
; ; 		ld	hl,6000h		; Set bank
; ; 		ld	(hl),0
; ; 		ld	(hl),1
; ; 		ld	(hl),0
; ; 		ld	(hl),0
; ; 		ld	(hl),0
; ; 		ld	(hl),0
; ; 		ld	(hl),1
; ; 		rst	8
; ; 		ld	(hl),0
; ; 		ld	(hl),1
; ; 		ld	ix,5100h|8000h		; ix - mars sysreg
; ; .wait_md:	ld	a,(ix+comm8)		; 68k got it first?
; ; 		or	a
; ; 		jp	nz,.wait_md
; ; 		rst	8
; ; 		ld	(ix+comm4),20h		; Z80 ready
; ; 		ld	(ix+3),01b		; Master CMD interrupt
; ; .wait_cmd:	bit	0,(ix+3)		; CMD clear?
; ; 		jp	nz,.wait_cmd
; ; 		rst	8
; 		ret
;
; ; bit 6
; .play:
; 		ld	a,(iy)
; 		and	00001111b
; 		inc	a
; 		ld	c,a
; 		rst	8
; 		push	iy
; 		pop	hl
; 		ld	b,8/2
; 		call	mars_zcomm
; 		ld	a,(iy)
; 		and	10011111b
; 		ld	(iy),a
; 		ret

; --------------------------------------------------------
; Set and play instruments in their respective channels
; --------------------------------------------------------

setupchip:
		call	dac_fill
		ld	c,MAX_TRKS		; c - numof_tracks
		ld	hl,insDataC
		ld	(currInsData),hl
		ld	iy,trkBuff+20h		; iy - Tracker channels
.nxt_track:
		push	iy			; Save iy
		ld	b,MAX_TRKCHN		; Pass 1
.nxt_chnl:
		push	bc			; Save b
		ld	a,(iy+chnl_Status)	; Get status
		or	a			; Check for non-zero
		call	nz,.do_chnl
		pop	bc			; Restore b
		ld	de,8			; Next CHANNEL
		add	iy,de
		rst	8
		djnz	.nxt_chnl

		pop	iy			; Recover iy
		ld	de,100h			; Next TRACK
		add	iy,de
		ld	de,100h			; Next instrument
		rst	8
		ld	hl,(currInsData)	; data
		add	hl,de
		ld	(currInsData),hl
		dec	c
		jp	nz,.nxt_track
		ret

; ----------------------------------------
; Channel requested update
;
; iy - Current channel
; ----------------------------------------

.do_chnl:
		;call	dac_fill		; TODO
		bit	1,(iy+chnl_Status)
		call	nz,.req_ins
		bit	2,(iy+chnl_Status)
		call	nz,.req_vol
		bit	3,(iy+chnl_Status)
		call	nz,.req_eff
		bit	0,(iy+chnl_Status)
		call	nz,.req_note
		ld	a,(iy+chnl_Status)	; Clear status
		and	11110000b
		ld	(iy+chnl_Status),a
		ret

; ----------------------------------------
; bit 1
; ----------------------------------------

.req_ins:
		call	.check_ins
		cp	-1		; Null
		ret	z
		cp	0		; PSG normal
		jr	z,.ins_psg
		cp	1		; PSG noise
		jr	z,.ins_psgn
		rst	8
		cp	2		; FM normal
		jr	z,.ins_fm
; 		cp	3		; FM special
; 		ret	z
		cp	4		; DAC
		jp	z,.ins_dac
; 		cp	5		; PWM
; 		jp	z,.ins_pwm
		ret

; --------------------------------
; PSG1-3,PSGN
.ins_psgn:
		call	.pick_psgn	; Search PSGN
		cp	-1
		ret	z
		call	.getins_psg	; same thing as normal PSG
		rst	8
		inc	hl		; one more for hatMode
		ld	a,(hl)
		ld	(psgHatMode),a
		ret
.ins_psg:
		call	.pick_psg	; Search PSG
		cp	-1
		ret	z
.getins_psg:
		ld	a,(hl)
		inc	hl		; Skip ID
		ld	e,(hl)
		ld	(ix+3),a	; Pitch
		inc	hl
		ld	a,(hl)
		ld	(ix+4),a	; ALV
		rst	8
		inc	hl
		ld	a,(hl)
		ld	(ix+5),a	; ATK
		inc	hl
		ld	a,(hl)
		ld	(ix+6),a	; SLV
		inc	hl
		ld	a,(hl)
		ld	(ix+7),a	; DKY
		inc	hl
		ld	a,(hl)
		ld	(ix+8),a	; RRT
		rst	8
		ret

; --------------------------------
; FM,FM3,FM6

.ins_dac:
		call	.pick_dac	; Check if FM6 is busy
		cp	-1
		ret	z
		inc	hl		; skip ID and pitch
		inc	hl
		ld	de,wave_Start

	; TODO: rushed code
	; copypastes START,END,LOOP and FLAGS
		ld	b,4
.copypas1:
		ld	a,(hl)
		ld	(de),a
		inc	hl
		inc	de
		rst	8
		ld	a,(hl)
		ld	(de),a
		inc	hl
		inc	de
		rst	8
		djnz	.copypas1
		ld	a,(hl)
		inc	hl
		ld	(de),a
		ld	a,(hl)		; flag
		ld	(wave_Flags),a
		ret
.ins_fm:
		call	.pick_fm	; Search FM
		cp	-1
		ret	z
		inc	hl		; skip ID and pitch
		inc	hl
		rst	8
		ld	de,0
		ld	a,(ix+2)
		rrca
		rrca
		rrca
		and	11100000b
		ld	e,a
		rst	8
		push	hl
		ld	hl,fminsdc
		add	hl,de
		push	hl
		pop	de
		pop	hl
		rst	8
		ld	a,(hl)		; xx0000
		inc	hl
		ld	c,(hl)		; 00xx00
		inc	hl
		ld	l,(hl)		; 0000xx
		ld	h,c
		ld	c,a
		rst	8
		push	de
		ld	a,(ix+10)
		cp	c
		jp	nz,.confm_rd
		ld	a,(ix+9)
		cp	h
		jr	nz,.confm_rd
		rst	8
		ld	a,(ix+8)
		cp	l
		jr	z,.fmsame_ins
.confm_rd:
		ld	(ix+8),l	; Register current instruemnt
		ld	(ix+9),h
		ld	(ix+10),c
		rst	8
		ld	a,c
		ld	bc,020h
		call	transferRom
		ld	hl,fmcom
		ld	bc,0
		rst	8
		ld	c,(ix+2)
		add	hl,bc
		ld	a,(hl)		; instrument update
		or	10h		; flag
		ld	(hl),a
		ld	de,FMVOL
		add	hl,de
		ld	(hl),0
.fmsame_ins:
		pop	hl
		ld	de,01Ch
		add	hl,de
		ld	a,(hl)
		ld	(ix+4),a	; Save 0B0h
		inc 	hl
		rst	8
		ld	a,(hl)		; Get 0B4h
		or	11000000b	; default panning
		ld	(ix+5),a	; Save 0B4h
		inc	hl		; FM3 enable bit is here
		inc	hl
		ld	a,(hl)		; keys (xxxx0000b)
		ld	(ix+6),a
		rst	8
		ret

; ----------------------------------------
; bit 2
; ----------------------------------------

.req_vol:
		call	.check_ins
		cp	-1		; Null
		ret	z
		cp	0		; PSG normal
		jr	z,.vol_psg
		cp	1		; PSG noise
		jr	z,.vol_psgn
		rst	8
		cp	2		; FM normal
		jr	z,.vol_fm
; 		cp	3		; FM special
; 		ret	z
; 		cp	4		; DAC
; 		jp	z,.dac_ins
; 		cp	5		; PWM
; 		jp	z,.pwm_ins
		ret

; --------------------------------
; PSG1-3,PSGN
.vol_psgn:
		call	.pick_psgn	; Search PSGN
		cp	-1
		ret	z
		jr	.getvol_psg	; same thing as normal PSG
.vol_psg:
		call	.pick_psg	; Search PSG
		cp	-1
		ret	z
.getvol_psg:
		ld	a,(iy+chnl_Vol)
		sub	a,40h
		add	a,a
		ld	e,a
		ld	a,(ix+4)	; ALV
		rst	8
		ccf
		sub	a,e
		ld	(ix+4),a
		ld	a,(ix+6)	; SLV
		ccf
		sub	a,e
		ld	(ix+6),a
		ret

; --------------------------------
; FM,FM3,FM6
.vol_fm:
		call	.pick_fm	; Search FM
		cp	-1
		ret	z
		ld	bc,0
		ld	c,(ix+2)
		ld	ix,fmcom
		rst	8
		add	ix,bc
		ld	a,(iy+chnl_Vol)
		sub	a,40h
		neg	a
		srl	a
		ld	(ix+FMVOL),a
		ld	a,(ix)		; volume update
		or	20h		; flag
		ld	(ix),a
		ret

; ----------------------------------------
; bit 3
; ----------------------------------------

.req_eff:
		call	.check_ins
		cp	-1		; Null
		ret	z
		;cp	0		; PSG normal
		;jr	z,.note_psg
		;cp	1		; PSG noise
		;jp	z,.note_psgn
		cp	2
		jp	z,.eff_fm
		ret

; --------------------------------
; FM,FM3,FM6

.eff_fm:
		call	.pick_fm	; Search FM
		cp	-1
		ret	z
		rst	8
		ld	e,(iy+chnl_EffArg)
		ld	a,(iy+chnl_EffId)
		cp	24		; Effect X?
		jr	z,.effFm_X
		ret
.effFm_X:
		rst	8
		ld	a,e
		rlca
		rlca
		and	00000011b
		ld	hl,.fmpan_list
		ld	de,0
		rst	8
		ld	e,a
		add	hl,de
		ld	b,(hl)
		ld	a,(ix+5)
		and	00111111b
		or	b
		ld	(ix+5),a
		rst	8
		ret
.fmpan_list:
		db 10000000b	; 000h
		db 10000000b	; 040h
		db 11000000b	; 080h
		db 01000000b	; 0C0h

; ----------------------------------------
; bit 0
; ----------------------------------------

.req_note:
		call	.check_ins
		cp	-1		; Null
		ret	z
		cp	0		; PSG normal
		jr	z,.note_psg
		rst	8
		cp	1		; PSG noise
		jp	z,.note_psgn
		cp	2
		jp	z,.note_fm
		cp	4
		jp	z,.note_dac
		ret

; --------------------------------
; PSG1-3,PSGN
.pstop:
		ld	(ix),0
		ld	(ix+1),0
		rst	8
		ld	de,0
		ld	e,(ix+2)
		ld 	hl,psgcom
		add	hl,de
		ld	(hl),100b	; Full stop
		ret
.poff:
		ld	(ix),0
		ld	(ix+1),0
		rst	8
		ld	de,0
		ld	e,(ix+2)
		ld 	hl,psgcom
		add	hl,de
		ld	(hl),010b	; Key off ===
		ret
.note_psgn:
		call	.pick_psgn	; Search PSGN
		cp	-1
		ret	z
		jr	.no_p3
.note_psg:
		call	.pick_psg	; Search PSG
		cp	-1
		ret	z
		rst	8
		ld	a,(ix+2)	; Check if PSGN is in
		cp	02h		; Tone3 mode
		jr	nz,.no_p3
		ld	a,(psgHatMode)
		and	011b
		cp	011b
		jr	nz,.no_p3
		jr	.pstop
.no_p3:
		rst	8
		ld	a,(iy+chnl_Note)
		cp	-2
		jr	z,.pstop
		cp	-1
		jr	z,.poff
		ld	c,(ix+3)
		add	a,c
		add	a,a
		ld	de,0
		ld	e,a
		ld	hl,psgFreq_List
		rst	8
		add	hl,de
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ld	bc,0
		ld	c,(ix+2)
		ld	a,c
		or	80h		; Add 80h for PSG
		ld	(iy+chnl_Chip),a
		push	ix		; swap ix to hl
		pop	hl
		inc	hl		; skip link
		inc	hl
		inc 	hl		; channel id
		inc	hl		; pitch
		rst	8
		ld 	ix,psgcom
		add	ix,bc
		ld	a,(hl)		; Copy our saved ins to pseudo psg
		ld	(ix+ALV),a	; ALV
		inc	hl
		ld	a,(hl)
		ld	(ix+ATK),a	; ATK
		inc	hl
		ld	a,(hl)
		ld	(ix+SLV),a	; SLV
		inc	hl
		ld	a,(hl)
		ld	(ix+DKY),a	; DKY
		inc	hl
		rst	8
		ld	a,(hl)
		ld	(ix+RRT),a	; RRT
		inc	hl
		ld	(hl),c
		inc	hl
		ld	(hl),b
		ld	a,e		; bc - freq
		and	0Fh
		ld	(ix+DTL),a
		ld	a,e
		sra	a
		sra	a
		sra	a
		sra	a
		and	0Fh
		rst	8
		ld	b,a
		inc	hl
		ld	a,d
		sla	a
		sla	a
		sla	a
		sla	a
		and	0F0h
		or	b
		ld	(ix+DTH),a
	if ZSET_TESTWAV=0
		ld	(ix+COM),001b	; Key ON
	endif
; 		call	dac_fill
		ret

; --------------------------------
; FM,FM3,FM6
; TODO: change the play/stop as flags
; instead of direct

.note_dac:
		call	.pick_dac	; Check if FM6 is busy
		cp	-1
		ret	z
		ld	a,(iy+chnl_Note)
		cp	-1
		jr	z,.doff
		cp	-2
		jr	z,.dcut
		ld	(iy+chnl_Chip),0B0h
		ld	de,100h		; default pitch
		ld	(wave_Pitch),de
		ld	a,0
		ld	(wave_Flags),a
	if ZSET_TESTWAV=0
		ld	a,001b		; Request DAC play
		ld	(daccom),a
	endif
		ret

.dcut:
	if ZSET_TESTWAV=0
		ld	a,010b		; Request DAC stop
		ld	(daccom),a
	endif
.doff:
		ld	hl,0
		ld	(tblFM6),hl
		ret

; TODO: this may cause wav scretching
.note_fm:
		call	.pick_fm	; Search FM
		cp	-1
		ret	z
		ld	a,(ix+2)	;
		and	00000111b
		or	90h		; Mark as FM (90h)
		rst	8
		ld	(iy+chnl_Chip),a
		ld	a,(iy+chnl_Note)
		ld	d,a
		inc	hl
		ld	e,(hl)		; Add pitch
		add	a,e
		ld	c,a		; c - temporal
		ld	a,(ix+2)
		rst	8
		ld	hl,fmcom	; hl - fmcom list
		ld	de,0
		and	111b
		ld	e,a
		add	hl,de
		rst	8
		ld	a,(iy+chnl_Note)
		cp	-1
		jr	z,.fm_keyoff
		cp	-2
		jr	z,.fm_keycut
		rst	8
		ld	a,c
		ld	e,(ix+7)
		cp	e
		jr	nz,.newnote
	; same note...
		ld	d,(ix+5)	; d - tbl 0B4h (and panning)
		ld	e,(ix+6)	; e - tbl keys
		push	de
		ld	e,(ix+4)	; e - tbl 0B0h
		push	hl
		pop	ix
		jr	.fmsame_note
.newnote:
		ld	(ix+7),c
		ld	b,0		; b - octave
		ld	e,7
.get_oct:
		ld	c,a
		sub	12
; 		rst	8		; TODO: ver si aun necesito esto
		or	a
		jp	m,.fnd_oct
		inc	b
		dec	e
		jr	nz,.get_oct
.fnd_oct:
		ld	d,(ix+5)	; d - tbl 0B4h (and panning)
		ld	e,(ix+6)	; e - tbl keys
		push	de
		ld	e,(ix+4)	; e - tbl 0B0h
		push	hl
		pop	ix
		rst	8		; ix - current fmcom
		ld	a,c		; c - Note
		add	a,a
		ld	c,a		; c - Freq slot
		ld	a,b
		add	a,a
		add	a,a
		add	a,a
		ld	b,0
		rst	8
		ld	hl,fmFreq_List
		add	hl,bc
		inc	hl
		ld	c,a		; c - octave << 3
		ld	a,(hl)		; Note MSB
		or	c		; add octave
		ld	(ix+FMRG_A4),a	; Save freq MSB
		dec	hl
		rst	8
		ld	a,(hl)
		ld	(ix+FMRG_A0),a	; Save freq LSB
.fmsame_note:
		ld	(ix+FMRG_B0),e	; Set 0B0h data
		pop	de
		ld	(ix+FMRG_B4),d	; Set 0B4h data
		ld	(ix+FMKEYS),e
		ld	a,(ix)		; key on | ins update flag
		or	001b
		ld	(ix),a
		ret
.fm_keyoff:
		ld	(hl),010b
		ld	(ix),0
		ld	(ix+1),0
		ret
.fm_keycut:
		ld	(hl),100b
		ld	(ix),0
		ld	(ix+1),0
		ret

; ----------------------------------------
; Grabs instrument data, also returns
; which sound chip it uses
;
; Returns:
;  a - Type
; hl - Instrument data
;
; Types:
; -1 - Null
;  0 - PSG
;  1 - PSG Noise
;  2 - FM
;  3 - FM Special
;  4 - FM Sample
;  5 - PWM
; ----------------------------------------

.check_ins:
		ld	a,(iy+chnl_Ins)
		dec	a
		add	a,a		; * 10h
		add	a,a
		add	a,a
		rst	8
		add	a,a
		ld	hl,(currInsData)
		ld	de,0
		ld	e,a
		add	hl,de
		ld	a,(hl)		; check type
		ret

; --------------------------------------------
; Auto-search channels
; --------------------------------------------

.pick_dac:
		ld	ix,tblFM6		; PSGN
		jr	.chk_only
.pick_psgn:
		ld	ix,tblPSGN		; PSGN
		jr	.chk_only
.pick_psg:
		ld	ix,tblPSG		; PSG1-3
		jr	.chk_srch
.pick_fm:
		ld	ix,tblFM		; FM
		;jr	.chk_srch

; --------------------------------------------
; iy - Current channel
; ix - Channel table to read
;
; Returns:
; ix - Free or Current table slot
;
; Uses:
; bc
.chk_srch:
		ld	bc,0		; Free slot start point
.next:
		ld	a,(ix+1)	; Check MSB first
		cp	-1		; End of list? (0FFxxh)
		jr	z,.chk_free
		push	iy
		pop	de		; de - Copy of curr track-channel
		rst	8
		cp	d		; check if link == ours
		jr	nz,.diffr
		ld	a,(ix)
		cp	e
		jr	nz,.diffr
		xor	a		; return 0
		ret
.chk_free:
		ld	a,c		; found free link?
		or	b
		jr	nz,.fndslot
		ld	a,-1		; linksteal check goes here
		ret
.fndslot:
		push	bc
		pop	ix		; tell ix is the new slot
		push	iy
		pop	de		; and mark it on buffer
		rst	8
		ld	a,e
		ld	(bc),a
		inc	bc
		ld	a,d
		ld	(bc),a
		xor	a
		ret
.diffr:
		ld	a,c		; already found link?
		or	b
		jr	nz,.alrdfnd
		rst	8
		ld	e,(ix+1)	; Check MSB first
		ld	a,(ix)
		or	e
		jr	nz,.alrdfnd
		push	ix		; bc - got free link
		pop	bc
		rst	8
.alrdfnd:
		ld	de,10h		; Next channel table
		add	ix,de
		jr	.next

; --------------------------------------------
; Same thing but doesn't increment
; returns a == -1 if busy

; TODO: check if I need to rethink this
.chk_only:
		push	iy
		pop	de		; de - Copy of curr track-channel
		rst	8
		ld	c,(ix)
		ld	a,(ix+1)
		cp	d
		jr	nz,.same_s
		ld	a,c
		cp	e
		jr	nz,.same_s
		xor	a		; Same channel found
		ret
.same_s:
		rst	8
		ld	a,c
		or	a
		jr	nz,.busy_s
		ld	(ix),e		; NEW slot
		ld	(ix+1),d
		xor	a		; Found free slot, pick it.
		ret
.busy_s:
		ld	a,-1
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
		ld	a,09Fh
		ld	(Zpsg_ctrl),a
		ld	a,0BFh
		ld	(Zpsg_ctrl),a
		ld	a,0DFh
		ld	(Zpsg_ctrl),a
		ld	a,0FFh
		ld	(Zpsg_ctrl),a
		ld	de,2700h
		call	fm_send_1
		ld	de,2800h
		call	fm_send_1
		ld	de,2801h
		call	fm_send_1
		ld	de,2802h
		call	fm_send_1
		ld	de,2804h
		call	fm_send_1
		ld	de,2805h
		call	fm_send_1
		ld	de,2806h
		call	fm_send_1
		ld	de,2B00h
		call	fm_send_1
		ld	hl,dWaveBuff			; Initilize WAVE FIFO
		ld	de,dWaveBuff+1
		ld	bc,100h-1
		ld	(hl),80h
		ldir
		ret

; --------------------------------------------------------
; check_tick
;
; Checks if VBlank triggred a TICK (1/150)
; --------------------------------------------------------

check_tick:
		di				; Disable ints
		push	af
		push	hl
		ld	hl,tickFlag+1		; read last TICK flag
		ld	a,(hl)			; non-zero value?
		or 	a
		jr	z,.ctnotick
	; ints are disabled from here
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
		call	dac_fill
.ctnotick:
		pop	hl
		pop	af
		ei				; Enable ints again
		ret

; --------------------------------------------------------
; set_tempo
;
; Input:
; a - Beats per minute
;
; Uses:
; de,hl
; --------------------------------------------------------

;set_tempo:
		;ld	de,218
		;call	do_multiply
		;xor	a
		;sla	l
		;rl	h
		;rla			; AH <- sbpt, 8 fracs
		;ld	l,h
		;ld	h,a		; HL <- AH
		;ld	(sbeatPtck),hl
		;ret
;do_multiply:
		;ld	hl,0
;.mul_add:
		;srl	a
		;jr	nc,.mulbitclr
		;add	hl,de
;.mulbitclr:
		;ret	z
		;sla	e		; if more bits still set in A, DE*=2 and loop
		;rl	d
		;jr	.mul_add

; --------------------------------------------------------
; transferRom
;
; Transfer bytes from ROM to Z80, this also tells
; to 68k that we are reading fom ROM
;
; Input:
; a  - Source ROM address $xx0000
; bc - Byte count (size 0 NOT allowed, MAX: 0FFh)
; hl - Source ROM address $00xxxx
; de - Destination address
;
; Uses:
; b, ix
;
; Notes:
; call dac_fill first if transfering anything other than
; sample data, just to be safe
; --------------------------------------------------------

transferRom:
		rst	8
		push	ix
		ld	ix,commZRomBlk
		ld	(x68ksrclsb),hl
		res	7,h
		ld	b,0
		dec	bc
		add	hl,bc
		bit	7,h
		jr	nz,.double
		ld	hl,(x68ksrclsb)		; single transfer
		inc	c
		ld	b,a
		call	.transfer
		pop	ix
		ret
.double:
		rst	8
		ld	b,a			; double transfer
		push	bc
		push	hl
		ld	a,c
		sub	a,l
		ld	c,a
		ld	hl,(x68ksrclsb)
		call	.transfer
		pop	hl
		pop	bc
		rst	8
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

; b  - Source ROM xx0000
;  c - Bytes to transfer (00h not allowed)
; hl - Source ROM 00xxxx
; de - Destination address
;
; Uses:
; a
.transfer:
		rst	8
		push	de
		ld	de,6000h
		ld	a,h
		rlc	a
		ld	(de),a
		ld	a,b
		rst	8
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rst	8
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rst	8
		pop	de
		set	7,h

	; Transfer data in parts of 3bytes
	; while playing cache WAV in the process
		ld	a,c
		ld	b,0
		set	0,(ix+1)	; Tell to 68k that we are reading from ROM
		sub	3
		jr	c,.x68klast
.x68kloop:
		ld	c,3-1
		bit	0,(ix)		; If 68k requested ROM block from here
		jr	nz,.x68klpwt
.x68klpcont:
		ldir
		rst	8
		sub	a,3-1
		jp	nc,.x68kloop
; last block
.x68klast:
		add	a,3
		ld	c,a
		bit	0,(ix)		; If 68k requested ROM block from here
		jp	nz,.x68klstwt
.x68klstcont:
		ldir
		rst	8
		res	0,(ix+1)
		ret

; If Genesis wants to do a DMA job...
; This MIGHT cause the DAC to ran out of sample data
.x68klpwt:
		res	0,(ix+1)		; Not reading ROM
.x68kpwtlp:
		rst	8
		bit	0,(ix)			; Is ROM free from 68K?
		jr	nz,.x68kpwtlp
		set	0,(ix+1)		; Reading ROM again.
		jr	.x68klpcont

; For last write
.x68klstwt:
		res	0,(ix+1)		; Not reading ROM
.x68klstwtlp:
		rst	8
		bit	0,(ix)			; Is ROM free from 68K?
		jr	nz,.x68klstwtlp
		set	0,(ix+1)		; Reading ROM again.
		jr	.x68klstcont

; --------------------------------------------------------
; bruteforce WAVE ON/OFF playback
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

; ====================================================================
; ----------------------------------------------------------------
; Sound chip routines
; ----------------------------------------------------------------

; --------------------------------------------------------
; chip_env
;
; Process PSG for effects and
; control FM frequency and effects
; --------------------------------------------------------

chip_env:
	; NOTE: this reads the channels backwards
	; so it automutes PSG3 if NOISE is in
	; Tone3 mode (psgHatMode)
		ld	iy,psgcom+3		; Start from NOISE first
		ld	hl,Zpsg_ctrl
		ld	d,0E0h			; PSG first ctrl command
		ld	e,4			; 4 channels
.vloop:
		rst	8
		ld	c,(iy+COM)		; c - current command
		ld	(iy+COM),0
		bit	2,c			; bit 2 - stop sound
		jr	z,.ckof
		ld	(iy+LEV),-1		; reset level
		ld	(iy+FLG),1		; and update
		ld	(iy+MODE),0		; envelope off
.ckof:
		bit	1,c			; bit 1 - key off
		jr      z,.ckon
		ld	a,(iy+MODE)		; mode 0?
		or	a
		jr	z,.ckon
		ld	(iy+FLG),1		; psg update flag
		ld	(iy+MODE),100b		; set envelope mode 100b
.ckon:
		rst	8
		bit	0,c			; bit 0 - key on
		jr	z,.envproc
		ld	(iy+LEV),-1		; reset level
		ld	a,(psgHatMode)		; check if using tone3 mode.
		ld	c,a
		and	11b
		cp	11b
		jr	z,.tnmode
.wrfreq:
		ld	a,e
		cp	4
		jr	z,.sethat
		rst	8
		ld	a,(iy+DTL)		; load frequency LSB or NOISE data
		or	d			; OR with current channel
		ld	(hl),a			; write it
		ld	a,(iy+DTH)
		ld	(hl),a
		jr	.nskip

; Tone3 mode
.tnmode:
		ld	a,e
		cp	4			; NOISE
		jr	z,.psteal
		cp	3			; PSG3, can't play
		jr	z,.nskip
		jr	.wrfreq
.psteal:
		ld	a,(iy+DTL)		; Steal PSG3's freq
		or	0C0h
		ld	(hl),a
		rst	8
		ld	a,(iy+DTH)
		ld	(hl),a
.sethat:
		ld	a,(psgHatMode)		; write hat mode only.
		or	d
		ld	(hl),a
.nskip:
		rst	8
		ld	(iy+FLG),1		; psg update flag
		ld	(iy+MODE),001b		; set to attack mode

; ----------------------------
; Process effects
; ----------------------------

.envproc:
		rst	8
		ld	a,(iy+MODE)
		or	a			; no modes
		jp	z,.vedlp
		cp 	001b			; Attack mode
		jr	nz,.chk2
		ld	(iy+FLG),1		; psg update flag
		ld	b,(iy+ALV)
		ld	a,(iy+ATK)		; if ATK == 0, don't use
		or	a
		jr	z,.atkend
		ld	c,a
		ld	a,b			; a - current level (volume)
		rst	8
		ld	b,(iy+ALV)		; b - attack level
		sub	a,c			; (attack rate) - (level)
		jr	c,.atkend		; if carry: already finished
		jr	z,.atkend		; if zero: no attack rate
		cp	b			; attack rate == level?
		jr	c,.atkend
		jr	z,.atkend
		ld	(iy+LEV),a		; set new level
		rst	8
		jr	.vedlp
.atkend:
		ld	(iy+LEV),b		; attack level = new level
.atkzero:
		ld	(iy+MODE),010b		; set to decay mode
		jr	.vedlp
.chk2:

		cp	010b			; Decay mode
		jr	nz,.chk4
.dectmr:
		ld	(iy+FLG),1		; psg update flag
		ld	a,(iy+LEV)		; a - Level
		ld	b,(iy+SLV)		; b - Sustain
		cp	b
		jr	c,.dkadd		; if carry: add
		jr	z,.dkyend		; if zero:  finish
		sub	(iy+DKY)		; substract decay rate
		jr	c,.dkyend		; finish if wraped.
		cp	b			; compare level
		jr	c,.dkyend		; and finish
		jr	.dksav
.dkadd:
		add	a,(iy+DKY)		;  (level) + (decay rate)
		jr	c,.dkyend		; finish if wraped.
		cp	b			; compare level
		jr	nc,.dkyend
.dksav:
		ld	(iy+LEV),a		; save new level
		jr	.vedlp
.dkyend:
		rst	8
		ld	(iy+LEV),b		; save last attack
		ld	(iy+MODE),100b		; and set to sustain
		jr	.vedlp
.chk4:
		cp	100b			; Sustain phase
		jr	nz,.vedlp
		ld	(iy+FLG),1		; psg update flag
		ld	a,(iy+LEV)		; a - Level
		add 	a,(iy+RRT)		; add Release Rate
		jr	c,.killenv		; release done
		ld	(iy+LEV),a		; set new Level
		jr	.vedlp
.killenv:
		ld	(iy+LEV),-1		; Silence this channel
		ld	(iy+MODE),0		; Reset mode
.vedlp:
		ld	a,(iy+FLG)
		or	a
		jr	z,.noupd
		ld	(iy+FLG),0		; Reset until next one
		rst	8
		ld	a,(iy+LEV)		; a - Level
		srl	a			; (Level >> 4)
		srl	a
		srl	a
		srl	a
		rst	8
		and	00001111b
		or	90h			; Add volume bits
		or	d			; add current channel
		ld	(hl),a			; Write volume
.noupd:
		dec	iy			; next COM to check
		ld	a,d
		sub	a,20h			; next PSG (backwards)
		ld	d,a
		dec	e
		jp	nz,.vloop

; ----------------------------
; FM section
; ----------------------------

		call	dac_fill
		ld	iy,fmcom
		ld	ix,fminsdc
		ld	bc,0
		call	.fm_set_1
		rst	8
		ld	de,20h
		add	ix,de
		inc	iy
		inc	c
		rst	8
		call	.fm_set_1
		ld	de,20h
		add	ix,de
		inc	iy
		inc	c
		rst	8
		call	.fm_set_1
		ld	de,20h		; FM set 2
		add	ix,de
		inc	iy
		ld	bc,4
		rst	8
		call	.fm_set_2
		ld	de,20h
		add	ix,de
		inc	iy
		inc	c
		rst	8
		call	.fm_set_2
		ld	a,(daccom)
		or	a
		jp	nz,.req_dac
		ld	de,20h
		add	ix,de
		inc	iy
		inc	c
		rst	8
		jp	.fm_set_2
.req_dac:
		bit	1,a
		call	nz,dac_off
		xor	a
		ld	(daccom),a
		jp	dac_play

.fm_set_1:
		ld	a,(iy)
		or	a
		ret	z
		ld	(iy),0
		rst	8
		bit	2,a
		call	nz,.fm_keycut
		rst	8
		bit	1,a
		call	nz,.fm_keyoff
		bit	0,a
		call	nz,.fm_send1
		ret
; Second set
.fm_set_2:
		ld	a,(iy)
		or	a
		ret	z
		ld	(iy),0
		rst	8
		bit	2,a
		call	nz,.fm_keycut
		rst	8
		bit	1,a
		call	nz,.fm_keyoff
		bit	0,a
		call	nz,.fm_send2
		ret
.fm_send1:
		ld	b,a
		ld	d,28h		; Keys off
		ld	e,c
		call	fm_send_1
		bit	4,b
		call	nz,.fm_insupd
		call	.fm_volupd

		ld	a,c
		and	11b
		or	0A4h
		ld	d,a
		ld	e,(iy+FMRG_A4)
		call	fm_send_1
		rst	8
		dec	d
		dec	d
		dec	d
		dec	d
		ld	e,(iy+FMRG_A0)
		call	fm_send_1
		rst	8
		ld	a,c
		and	11b
		or	0B0h
		ld	d,a
		ld	e,(iy+FMRG_B0)
		call	fm_send_1
		inc	d
		inc	d
		inc	d
		inc	d
		ld	e,(iy+FMRG_B4)
		call	fm_send_1
		rst	8
		ld	d,28h		; Keys
		ld	a,(iy+FMKEYS)
		and	11110000b
		or	c
		ld	e,a
		jp	fm_send_1
.fm_send2:
		ld	b,a
		ld	d,28h		; Keys off
		ld	e,c
		call	fm_send_1
		bit	4,b
		call	nz,.fm_insupd
		call	.fm_volupd

		ld	a,c
		and	11b
		or	0A4h
		ld	d,a
		ld	e,(iy+FMRG_A4)
		call	fm_send_2
		rst	8
		dec	d
		dec	d
		dec	d
		dec	d
		ld	e,(iy+FMRG_A0)
		call	fm_send_2
		rst	8
		ld	a,c
		and	11b
		or	0B0h
		ld	d,a
		ld	e,(iy+FMRG_B0)
		call	fm_send_2
		inc	d
		inc	d
		inc	d
		inc	d
		ld	e,(iy+FMRG_B4)
		call	fm_send_2
		rst	8
		ld	d,28h		; Keys
		ld	a,(iy+FMKEYS)
		and	11110000b
		or	c
		ld	e,a
		jp	fm_send_1
.fm_keyoff:
		rst	8
		ld	e,c
		ld	d,28h
		jp	fm_send_1
.fm_keycut:
		rst	8
		ld	e,c
		ld	d,28h
		call	fm_send_1
		ld	a,c		; panning off
		and	11b
		or	0B4h
		ld	d,a
		rst	8
		ld	a,(iy+8)
		and	00111111b
		ld	e,a
		bit	2,c
		jp	nz,fm_send_2
		jp	fm_send_1
.fm_insupd:
		call	dac_fill
		push	ix
		ld	a,c
		and	011b
		or	30h
		ld	d,a
		ld	b,4*7
.copy:
		ld	e,(ix)
		bit	2,c
		call	z,fm_send_1
		call	nz,fm_send_2
		rst	8
		inc	ix
		inc	d
		inc	d
		inc	d
		inc	d
		djnz	.copy
		pop	ix
		ret
.fm_volupd:
	; b - volume decrement
	; c - channel id
	; d - 40h+ reg
	; h - Algorithm
		push	ix
		ld	a,(ix+1Ch)
		and	111b
		ld	h,a
		ld	de,4
		add	ix,de
		ld	a,c
		and	11b
		or	40h
		ld	d,a
		ld	b,(iy+FMVOL)
		ld	a,h		; Check 40h
		cp	7		; Algorithm == 07h?
		call	z,.do_vol
		inc	d		; Next...
		inc	d
		inc	d
		inc	d
		inc	ix
		ld	a,h		; Check 44h
		cp	4		; Algorithm > 04h?
		call	nc,.do_vol
		inc	d		; Next...
		inc	d
		inc	d
		inc	d
		inc	ix
		ld	a,h		; Check 48h
		cp	5		; Algorithm > 05h?
		call	nc,.do_vol
		inc	d		; Next...
		inc	d
		inc	d
		inc	d
		inc	ix
		call	.do_vol
		pop	ix
		ret

.do_vol:
		ld	a,(ix)
		add	a,b
		ld	e,a
		bit	2,c
		call	z,fm_send_1
		call	nz,fm_send_2
		ret

; 	; copy-pasted from PulseMini
; 	; b - 0B0h
; 	; c - Volume
; 		ld	a,(iy+chnl_Vol)
; 		sub	a,40h
; 		neg	a
; 		srl	a
; 		rst	8
; 		ld	c,a
; 		ld	a,(ix+4)	; get 0B0h
; 		and	111b
; 		ld	b,a
; 		ld	d,40h
; 		ld	a,(ix+2)
; 		and	11b
; 		or	d
; 		ld	d,a
; 		ld	e,(hl)
; 		inc 	hl
; 		rst	8
; 		ld	a,b
; 		cp	7
; 		jr	nz,.tlv_lv1
; 		ld	a,e
; 		add 	a,c
; 		ld	e,a
; 		or	a
; 		jp	p,.tlv_lv1
; 		ld	e,7Fh
; .tlv_lv1:
; 		call	fm_autoset
; 		inc 	d
; 		inc 	d
; 		inc 	d
; 		rst	8
; 		inc 	d
; 		ld	e,(hl)
; 		ld	a,b
; 		cp	7
; 		jr	z,.tlv_lv2_ok
; 		cp	6
; 		jr	z,.tlv_lv2_ok
; 		cp	5
; 		jr	nz,.tlv_lv2
; .tlv_lv2_ok:
; 		ld	a,e
; 		rst	8
; 		add 	a,c
; 		ld	e,a
; 		or	a
; 		jp	p,.tlv_lv2
; 		ld	e,7Fh
; .tlv_lv2:
; 		call	fm_autoset
; 		inc 	hl
; 		inc 	d
; 		inc 	d
; 		inc 	d
; 		inc 	d
; 		ld	e,(hl)
; 		ld	a,b
; 		and	100b
; 		rst	8
; 		or	a
; 		jr	z,.tlv_lv3
; 		ld	a,e
; 		add 	a,c
; 		ld	e,a
; 		or	a
; 		jp	p,.tlv_lv3
; 		ld	e,7Fh
; .tlv_lv3:
; 		call	fm_autoset
; 		inc 	hl
; 		rst	8
; 		inc 	d
; 		inc 	d
; 		inc 	d
; 		inc 	d
; 		ld	a,(hl)
; 		add 	a,c
; 		ld	e,a
; 		or	a
; 		jp	p,.tlv_lv4
; 		ld	e,7Fh
; .tlv_lv4:
; 		inc 	hl
; 		jp	fm_autoset

; 		ld
; 		jr	$
; 		jr
; 		inc	hl		; skip ID and pitch
; 		inc	hl
; 		ld	a,(hl)		; grab Z80 pointer
; 		inc	hl
; 		rst	8
; 		ld	h,(hl)
; 		ld	l,a
; 		ld	de,4
; 		add	hl,de		; Point to 40h+ regs
;


; ---------------------------------------------
; FM send registers
;
; Input:
; d - ctrl
; e - data
; ---------------------------------------------

; Channels 1-3
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
; dac_play
;
; Plays a new sample
; --------------------------------------------------------

dac_play:
		di
		call	dac_off
		exx
		ld	bc,dWaveBuff>>8			; bc - WAVFIFO MSB
		ld	de,(wave_Pitch)			; de - Pitch
		ld	hl,(dWaveBuff&0FFh)<<8		; hl - WAVFIFO LSB pointer (xx.00)
		exx
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
; dac_fill
;
; Refills a half of the WAVE FIFO data, automatic
;
; *** self-modifiable code ***
; --------------------------------------------------------

dac_fill:	push	af		; <-- code changes between PUSH AF(playing) and RET(stopped)
		ld	a,(dDacFifoMid)
		exx
		xor	h		; xx.00
		exx
		and	80h
		jp	nz,dac_refill
		pop	af
		ret

; First wave fill
dac_firstfill:
; 		call	check_tick
		push	af

; Auto-fill
; Got this from GEMS, but i changed it to play
; longer samples (7FFFFFh maximum)

dac_refill:
		rst	8
		push	bc
		push	de
		push	hl
		ld	a,(wave_Flags)
		cp	111b
		jp	nc,.FDF7

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
.keepcntr:
		ld	a,(dDacFifoMid)
		ld	e,a
		add 	a,80h
		ld	(dDacFifoMid),a
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		call	transferRom
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		ld	bc,80h
		add	hl,bc
		adc	a,0
		ld	(dDacPntr),hl
		ld	(dDacPntr+2),a
		jp	.FDFreturn

; if wav's timer finished:
.dac_over:
		ld	d,dWaveBuff>>8
		ld	a,(wave_Flags)
		and	01b
		or	a
		jp	nz,.FDF72
		ld	a,l
		add	a,80h
		ld	c,a
		ld	b,0
		push	bc
		ld	a,(dDacFifoMid)
		ld	e,a
		add	a,80h
		ld	(dDacFifoMid),a
		pop	bc			; C <- # just xfered
		ld	a,c
		or	b
		jr	z,.FDF7
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		call	transferRom
		jr	.FDF7
.FDF72:

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
		jr	z,.FDFreturn
		ld	a,(dDacFifoMid)
		ld	e,a
		add	a,80h
		ld	(dDacFifoMid),a
		ld	hl,(dDacPntr)
		ld	a,(dDacPntr+2)
		call	transferRom
		jr	.FDFreturn
.FDF7:
		call	dac_off		; DAC finished
		;ld	hl,0		; release FM6 from table
		;ld	(tblFM6),hl
.FDFreturn:
		pop	hl
		pop	de
		pop	bc
		pop	af
		ret

; ====================================================================
; ----------------------------------------------------------------
; Tables
; ----------------------------------------------------------------

fmFreq_List:	dw 644		; C-0
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
		dw -1		; C-0 $0
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
		dw -1		; C-1 $C
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
		dw -1		; C-2 $18
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
		dw -1		; C-3 $24
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
		dw 356h		;C-4 30
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
		dw 1ABh		;C-5 3C
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
		dw 0D6h		;C-6 48
		dw 0C9h
		dw 0BEh
		dw 0B4h
		dw 0A9h
		dw 0A0h
		dw 97h
		dw 8Fh
		dw 87h
		dw 7Fh
		dw 78h
		dw 71h
		dw 6Bh		; C-7 54
		dw 65h
		dw 5Fh
		dw 5Ah
		dw 55h
		dw 50h
		dw 4Bh
		dw 47h
		dw 43h
		dw 40h
		dw 3Ch
		dw 39h
		dw 36h		; C-8 $60
		dw 33h
		dw 30h
		dw 2Dh
		dw 2Bh
		dw 28h
		dw 26h
		dw 24h
		dw 22h
		dw 20h
		dw 1Fh
		dw 1Dh
		dw 1Bh		; C-9 $6C
		dw 1Ah
		dw 18h
		dw 17h
		dw 16h
		dw 15h
		dw 13h
		dw 12h
		dw 11h
 		dw 10h
 		dw 9h
 		dw 8h
		dw 0

;wavFreq_Pwm:	dw 100h		; C-0
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h		; C-1
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h		; C-2
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 03Bh
		;dw 03Eh		; C-3 5512
		;dw 043h		; C#3
		;dw 046h		; D-3
		;dw 049h		; D#3
		;dw 04Eh		; E-3
		;dw 054h		; F-3
		;dw 058h		; F#3
		;dw 05Eh		; G-3 8363 -17
		;dw 063h		; G#3
		;dw 068h		; A-3
		;dw 070h		; A#3
		;dw 075h		; B-3
		;dw 07Fh		; C-4 11025 -12
		;dw 088h		; C#4
		;dw 08Fh		; D-4
		;dw 097h		; D#4
		;dw 0A0h		; E-4
		;dw 0ADh		; F-4
		;dw 0B5h		; F#4
		;dw 0C0h		; G-4
		;dw 0CCh		; G#4
		;dw 0D7h		; A-4
		;dw 0E7h		; A#4
		;dw 0F0h		; B-4
		;dw 100h		; C-5 22050
		;dw 110h		; C#5
		;dw 120h		; D-5
		;dw 12Ch		; D#5
		;dw 142h		; E-5
		;dw 158h		; F-5
		;dw 16Ah		; F#5 32000 +6
		;dw 17Eh		; G-5
		;dw 190h		; G#5
		;dw 1ACh		; A-5
		;dw 1C2h		; A#5
		;dw 1E0h		; B-5
		;dw 1F8h		; C-6 44100 +12
		;dw 210h		; C#6
		;dw 240h		; D-6
		;dw 260h		; D#6
		;dw 280h		; E-6
		;dw 2A0h		; F-6
		;dw 2D0h		; F#6
		;dw 2F8h		; G-6
		;dw 320h		; G#6
		;dw 350h		; A-6
		;dw 380h		; A#6
		;dw 3C0h		; B-6
		;dw 400h		; C-7 88200
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h		; C-8
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h		; C-9
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h
		;dw 100h

; --------------------------------------------------------

		;align 10h

	; Channel tables: size 20h
	; TODO: shrink to 10h to save space
	; 0  - Link addr (0000h = free, used chnls start from 0020h)
	; 2  - Channel ID
	; 	PSG: psgcom indexes
	; 	 FM: BASE register ids + keys
	; 3  - Copy of current Impulse-intrument
	; 4+ - Channel specific:

	; PSG 4+
	;  4 - Attack level (ALV)
	;  5 - Attack rate (ATK)
	;  6 - Sustain (SLV)
	;  7 - Decay rate (DKY)
	;  8 - Release rate (RRT)
	;  9 - Frequency copy for effects
tblPSG:		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 1
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,01h,00h,00h,00h,00h,00h	; Channel 2
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,02h,00h,00h,00h,00h,00h	; Channel 3
		db 00h,00h,00h,00h,00h,00h,00h,00h
		dw -1
tblPSGN:	db 00h,00h,03h,00h,00h,00h,00h,00h	; Noise (DIRECT CHECK only)
		db 00h,00h,00h,00h,00h,00h,00h,00h

	; FM 4+
	;  4 - 0B0h register data
	;  5 - 0B4h register data (incl. panning: %LRxxxxxx)
	;  6 - FM keys
	;  7 - Last ImpulseNote used
tblFM:		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 1
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,01h,00h,00h,00h,00h,00h	; Channel 2
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,03h,00h,00h,00h,00h,00h	; Channel 4
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,04h,00h,00h,00h,00h,00h	; Channel 5
		db 00h,00h,00h,00h,00h,00h,00h,00h
tblFM3:		db 00h,00h,02h,00h,00h,00h,00h,00h	; Channel 3 (If ex-freqs are enabled:
		db 00h,00h,00h,00h,00h,00h,00h,00h	; DIRECT CHECK ONLY)
tblFM6:		db 00h,00h,05h,00h,00h,00h,00h,00h	; Channel 6 (If DAC is enabled:
		db 00h,00h,00h,00h,00h,00h,00h,00h	; DIRECT CHECK ONLY)
		dw -1

tblPWM:		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 1
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 2
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 3
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 4
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 5
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 6
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 7
		db 00h,00h,00h,00h,00h,00h,00h,00h
		dw -1

	; PSG psuedo-controls
psgcom		db 00h,00h,00h,00h	;  0 command 1 = key on, 2 = key off, 4 = stop snd
psglev		db -1, -1, -1, -1	;  4 output level attenuation (%llll.0000, -1 = silent)
psgatk		db 00h,00h,00h,00h	;  8 attack rate
psgdec		db 00h,00h,00h,00h	; 12 decay rate
psgslv		db 00h,00h,00h,00h	; 16 sustain level attenuation
psgrrt		db 00h,00h,00h,00h	; 20 release rate
psgenv		db 00h,00h,00h,00h	; 24 envelope mode 0 = off, 1 = attack, 2 = decay, 3 = sustain, 4
psgdtl		db 00h,00h,00h,00h	; 28 tone bottom 4 bits
psgdth		db 00h,00h,00h,00h	; 32 tone upper 6 bits
psgalv		db 00h,00h,00h,00h	; 36 attack level attenuation
whdflg		db 00h,00h,00h,00h	; 40 flags to indicate hardware should be updated
psgtim		db 00h,00h,00h,00h	; 44 timer for sustain


fmcom:		db 00h,00h,00h,00h,00h,00h	;  0 - play bits: 2-cut 1-off 0-play
		db 00h,00h,00h,00h,00h,00h	;  6 - keys xxxx0000b
		db 00h,00h,00h,00h,00h,00h	; 12 - volume (for 40h+)
		db 00h,00h,00h,00h,00h,00h	; 18 - A4h+ (MSB FIRST)
		db 00h,00h,00h,00h,00h,00h	; 24 - A0h+
		db 00h,00h,00h,00h,00h,00h	; 30 - B0h+ %00fffaaa Feedback | Algorithm
		db 00h,00h,00h,00h,00h,00h	; 36 - B4h+ (%LRaa0ppp) AMS(+AMbit, tremolo) PMS (vibrato)

		align 10h
fminsdc:	ds 020h				; Regins data for each FM
		ds 020h
		ds 020h
		ds 020h
		ds 020h
		ds 020h
daccom:		db 0		; single byte for key on, off, cut

; ====================================================================
; ----------------------------------------------------------------
; Z80 RAM
; ----------------------------------------------------------------

	; non-aligned values
wave_Start	dw 0			; START: 68k direct pointer ($00xxxxxx)
		db 0
wave_Len	dw 0			; LENGTH
		db 0
wave_Loop	dw 0			; LOOP POINT
		db 0
wave_Pitch	dw 0100h		; 01.00h
wave_Flags	db 0100b		; WAVE playback flags (%10x: 1 loop / 0 no loop)
currTrkBlkHd	dw 0
currTrkData	dw 0
currInsData	dw 0
tickFlag	dw 0			; Tick flag from VBlank, Read as (tickFlag+1) for reading/reseting
tickCnt		db 0			; Tick counter (PUT THIS TAG AFTER tickFlag)
sbeatPtck	dw 204			; Sub beats per tick (8frac), default is 120bpm
sbeatAcc	dw 0			; Accumulates ^^ each tick to track sub beats
currTickBits	db 0			; Current Tick/Tempo bitflags (000000BTb B-beat, T-tick)
dDacPntr	db 0,0,0		; WAVE play current ROM position
dDacCntr	db 0,0,0		; WAVE play length counter
dDacFifoMid	db 0			; WAVE play halfway refill flag (00h/80h)
x68ksrclsb	db 0			; transferRom temporal LSB
x68ksrcmid	db 0			; transferRom temporal MID
commZRead	db 0			; read pointer (here)
commZWrite	db 0			; cmd fifo wptr (from 68k)
commZRomBlk	db 0			; 68k ROM block flag
commZRomRd	db 0			; Z80 ROM reading flag
psgHatMode	db 0
commZfifo	ds 40h			; Buffer for command requests from 68k
fmInsCach	ds 20h			; FM instrument cache for reading

	; aligned buffers
		org 1300h
dWaveBuff	ds 100h			; WAVE data READ buffer: updated every 80h bytes *LSB must be 00h*
trkDataC	ds 100h*MAX_TRKS	; Track data READ buffer: 100h bytes each, updates every 80h
trkBuff		ds 100h*MAX_TRKS	; Track control (20h bytes) + channels (8h each)
insDataC	ds 100h*MAX_TRKS	; Instrument data+pointers for current track: 100h bytes
blkHeadC	ds 80h*MAX_TRKS		; Track blocks and heads: divided by 80h bytes
