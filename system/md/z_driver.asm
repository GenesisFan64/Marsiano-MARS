; --------------------------------------------------------
; GEMA sound driver, inspired by GEMS (kinda)
;
; Two playable track slots: BGM(0) and SFX(1)
;
; Slot 1 can either overwrite chip channels or
; if possible grab unused slots
;
; WARNING: DAC sample playback has to be sync'd manually
; on every code change, sample rate is at the
; 18000hz range
; --------------------------------------------------------

; --------------------------------------------------------
; User settings
; --------------------------------------------------------

MAX_TRKCHN	equ 17		; Max internal tracker channels (4PSG + 6FM + 7PWM)
ZSET_WTUNE	equ -24		; Manual frequency adjustment for DAC WAVE playback
ZSET_TESTME	equ 0		; Set to 1 to "hear" test the DAC playback

; --------------------------------------------------------
; Structs
;
; NOTE: struct doesn't work here. use equs instead
; --------------------------------------------------------

; trkBuff struct
; LIMIT: 20h (32) bytes
trk_romBlk	equ 0	; 24-bit base block data
trk_romPatt	equ 3	; 24-bit base patt data
trk_romIns	equ 6	; 24-bit ROM instrument pointers
trk_romPattRd	equ 9	; same but for reading
trk_Read	equ 12	; Current track position (in cache)
trk_Rows	equ 14	; Current track length
trk_Halfway	equ 16	; Only 00h or 80h
trk_currBlk	equ 17	; Current block
trk_setBlk	equ 18	; Start on this block
trk_status	equ 19	; %ERPB Sxxx | E-enabled / R-Init|Restart track / P-refill-on-playback / B-use global beats / S-silence
trk_tickTmr	equ 20	; Ticks timer
trk_tickSet	equ 21	; Ticks set for this track
trk_numChnls	equ 22	; Number of channels for this track slot (max: MAX_TRKCHN)
trk_sizeIns	equ 23	; Max instruments used
trk_rowPause	equ 24	; Row pause timer
trk_HdHalfway	equ 25	; Track heads reload byte
trk_CachNotes	equ 26	; Track pattern buffer location (100h bytes)
trk_CmdReq	equ 28	; Track command requests

; Track data: 8 bytes only
chnl_Chip	equ 0		; MUST BE at 0
chnl_Note	equ 1
chnl_Ins	equ 2
chnl_Vol	equ 3
chnl_EffId	equ 4
chnl_EffArg	equ 5
chnl_Type	equ 6		; Impulse-note bits
chnl_Flags	equ 7		; playback requests and other specific bits

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; To brute force DAC playback
; on or off
zopcNop		equ	00h
zopcEx		equ	08h
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
PVOL		equ	48

; FMCOM		equ	0
FMKEYS		equ	6
FMVOL		equ	12
FMPAN 		equ	18
FMFRQH		equ	24
FMFRQL		equ	30

PWCOM		equ	0
PWPTH_V		equ	8	; Volume | Pitch MSB
PWPHL		equ	16	; Pitch LSB
PWOUTF		equ	24	; Output mode/bits | SH2 section (ROM $02 or SDRAM $06)
PWINSH		equ	32	; 24-bit sample address
PWINSM		equ	40
PWINSL		equ	48

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
; keep playing the sample while processing code
;
; Input (EXX):
;  c - WAVE buffer MSB
; de - Pitch (xx.00)
; h  - WAVE buffer LSB (as xx.00)
;
; Uses (EXX):
; b
;
; *** self-modifiable code ***
;
; call dac_on to enable WAVE playback
; or
; call dac_off to disable it
; (check for FM6 manually)
; --------------------------------------------------------

; NOTE: This plays at 18000hz
		org 8
dac_me:		exx			; <-- this changes between EXX(play) and RET(stop)
		ex	af,af'		; Swap af
		ld	b,l		; Save pitch's .00 to b
		ld	a,2Ah		; Prepare YM register 2Ah
		ld	(Zym_ctrl_1),a
		ld	l,h		; L - xx.00 to 00xx
		ld	h,c		; H - Wave buffer MSB | 00xx
		ld	a,(hl)		; Now read byte from the wave buffer
		ld	(Zym_data_1),a	; and write it to DAC
		ld	h,l		; get hl back
		ld	l,b		; Get .00 back from b to l
		add	hl,de		; Pitch increment hl
		ex	af,af'		; return af
		exx
		ret

; --------------------------------------------------------

commZRomBlk	db 0			; 68k ROM block flag
commZRomRd	db 0			; Z80 ROM reading flag
commZRead	db 0			; cmd read pointer (here)
commZWrite	db 0			; cmd fifo wptr (from 68k)

; --------------------------------------------------------
; RST 20h (dac_me)
;
; Checks if the WAVE cache needs refilling, this
; breaks ALL registers if refill is requested.
;
; *** self-modifiable code ***
; --------------------------------------------------------

		org 20h
dac_fill:	push	af		; <-- this changes between PUSH AF(playing) and RET(stopped)
		ld	a,(dDacFifoMid)	; a - Get current wavebuffer LSB (00h or 80h)
		exx
		xor	h		; 00xx.00
		exx
		and	80h		; Compare bit
		jp	nz,dac_refill	; If not, refill and update LSB to check
		pop	af
		ret

; --------------------------------------------------------

x68ksrclsb	db 0		; transferRom temporal LSB
x68ksrcmid	db 0		; transferRom temporal MID
currTickBits	db 0		; Current Tick/Tempo bitflags (000000BTb B-beat, T-tick)
marsUpd		db 0		; flag to request a PWM transfer
marsBlock	db 0		; flag to temporally disable PWM communication
palMode		db 0		; PAL speed flag (TODO)
sbeatPtck	dw 200+12	; Global tempo (sub beats)
sbeatAcc	dw 0		; Accumulates on each tick to trigger the sub beats

; --------------------------------------------------------
; Z80 Interrupt at 0038h
;
; Sets the TICK flag
; --------------------------------------------------------

		org 38h			; Align 38h
		ld	(tickFlag),sp	; Use sp to set TICK flag (xx1F, read as tickFlag+1)
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
		call	get_tick	; Check for Tick on VBlank
		rst	20h		; first dacfill
		rst	8
		ld	b,0		; b - Reset current flags (beat|tick)
		ld	a,(tickCnt)
		sub	1
		jr	c,.noticks
		ld	(tickCnt),a
		rst	8
		call	chip_env	; Process PSG volume and freqs manually
		call	get_tick	; Check for another tick
		ld 	b,01b		; Set TICK (01b) flag, and clear BEAT
.noticks:
		ld	a,(sbeatAcc+1)	; check beat counter (scaled by tempo)
		sub	1
		jr	c,.nobeats
		ld	(sbeatAcc+1),a	; 1/24 beat passed.
		set	1,b		; Set BEAT (10b) flag
		rst	8
.nobeats:
		rst	8
		ld	a,b
		or	a
		jr	z,.neither
		ld	(currTickBits),a; Save BEAT/TICK bits
		call	get_tick
		call	setupchip	; Send changes to sound chips
		call	get_tick
		call	updtrack	; Update track data
		call	get_tick
		rst	8
.neither:
		call	mars_scomm	; 32X communication for PWM playback
		call	get_tick
		rst	8
.next_cmd:
		ld	a,(commZWrite)	; Check command READ and WRITE indexes
		ld	b,a
		ld	a,(commZRead)
		cp	b
		jr	z,drv_loop	; If both are equal: no commands
		call	get_cmdbyte
		cp	-1		; Get -1 (Start of command)
		jr	nz,drv_loop
		call	get_cmdbyte	; Read cmd number
		add	a,a		; * 2
		ld	hl,.list
		ld	d,0
		ld	e,a
		add	hl,de
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		jp	(hl)
.list:
		dw .cmnd_trkplay	; $00 - Play
		dw .cmnd_trkstop	; $01 - Stop/Pause
		dw .cmnd_trkresume	; $02 - Resume
		dw .cmnd_0		; $03 -
		dw .cmnd_0		; $04 -
		dw .cmnd_0		; $05 -
		dw .cmnd_0		; $06 -
		dw .cmnd_0		; $07 -
		dw .cmnd_trkticks	; $08 - Set ticks
		dw .cmnd_0		; $09 -
		dw .cmnd_0		; $0A -
		dw .cmnd_0		; $0B -
		dw .cmnd_0		; $0C -
		dw .cmnd_0		; $0D -
		dw .cmnd_0		; $0E -
		dw .cmnd_0		; $0F -
		dw .cmnd_trktempo	; $10 - Set global subbeats
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
		call	get_cmdbyte		; Get track slot
		call	get_trkindx		; and read index iy
		call	get_cmdbyte		; Get ticks
		ld	(iy+trk_tickSet),a
		call	get_cmdbyte		; Start block
		ld	(iy+trk_setBlk),a
		call	get_cmdbyte		; Flag bits
		or	11000000b		; Enable + First fill bits
		ld	(iy+trk_status),a
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
		call	get_tick
		ld	(iy+(trk_romBlk+2)),a
		call	get_cmdbyte		; Instrument data
		ld	(iy+trk_romIns),a
		call	get_cmdbyte
		ld	(iy+(trk_romIns+1)),a
		call	get_cmdbyte
		ld	(iy+(trk_romIns+2)),a
		ld	a,1
		ld	(iy+trk_tickTmr),a
		rst	8
		jp	.next_cmd

; --------------------------------------------------------
; $02 - STOP track
; --------------------------------------------------------

.cmnd_trkstop:
; 		call	get_cmdbyte			; Get track slot
; 		call	get_trkindx			; and read index iy
; 		call	track_out
; 		jp	.next_cmd

; --------------------------------------------------------
; $03 - Pause track
; --------------------------------------------------------

.cmnd_trkpause:
		call	get_cmdbyte		; Get track slot
		call	get_trkindx		; and read index iy
		call	track_out
		jp	.next_cmd

; --------------------------------------------------------
; $04 - Resume track
; --------------------------------------------------------

.cmnd_trkresume:
		call	get_cmdbyte		; Get track slot
		call	get_trkindx		; and read index iy
		set	7,(iy+trk_status)	; Slot ON
		jp	.next_cmd

; --------------------------------------------------------
; $08 - Set tricks
; --------------------------------------------------------

.cmnd_trkticks:
		call	get_cmdbyte		; Get track slot
		call	get_trkindx		; and read index iyc
		call	get_cmdbyte
		ld	(iy+trk_tickSet),a
		ld	(iy+trk_tickTmr),a
		jp	.next_cmd

; --------------------------------------------------------
; $10 - Set global tempo
; --------------------------------------------------------

.cmnd_trktempo:
		call	get_cmdbyte		; Get track slot
		call	get_trkindx		; and read index iyc
		call	get_cmdbyte
		ld	(sbeatPtck),a
		call	get_cmdbyte
		ld	(sbeatPtck+1),a
		jp	.next_cmd

; --------------------------------------------------------
; a - track index

get_trkindx:
		ld	hl,trkPointers
		add	a,a
		ld	d,0
		ld	e,a
		rst	8
		add	hl,de
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		push	hl
		pop	iy
		ret
trkPointers:
		dw trkBuff_0
		dw trkBuff_1

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
		jr	z,.getcbytel	; wait for a command from 68k
		rst	8
		ld	b,0
		ld	c,a
		ld	hl,commZfifo
		add	hl,bc
		inc	a
		and	3Fh		; command list limit
		rst	8
		ld	(commZRead),a
		ld	a,(hl)		; a - the byte we got
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
		rst	20h
		ld	iy,trkBuff_0		; BGM
		rst	8
		ld	de,insDataC_0
		call	.read_track
		ld	iy,trkBuff_1		; SFX
		ld	de,insDataC_1
		rst	8
		call	.read_track
		ret

; ----------------------------------------
; Read current track
;
; iy - Track control
; ix - Track channels
; de - Instrument CACHE point
; ----------------------------------------

.read_track:
		ld	b,(iy+trk_status)	; b - Track status
		bit	7,b			; Active?
		ret	z
		ld	a,(iy+trk_CmdReq)	; Any mid-request?
		or	a
		ret	nz
		ld	(currInsData),de	; save temporal InsData
		rst	8
		ld	a,(currTickBits)	; a - Tick/Beat bits
		bit	0,b			; This track uses Beats?
		jr	z,.sfxmd		; Nope
		bit	1,a			; BEAT passed?
		ret	z
.sfxmd:
		bit	0,a			; TICK passed?
		ret	z
		ld	a,(iy+trk_tickTmr)	; TICK timer for this track
		dec	a
		ld	(iy+trk_tickTmr),a
		rst	8
		or	a
		ret	nz			; If != 0, exit
		bit	5,b			; Effect-requested track set?
		call	nz,.effect_fill
		bit	6,b			; Restart/First time?
		call	nz,.first_fill
		ld	a,(iy+trk_tickSet)	; Set new tick timer
		ld	(iy+trk_tickTmr),a
		rst	8
		ld	l,(iy+trk_Read)		; hl - Pattern data to read in cache
		ld	h,(iy+((trk_Read+1)))
		ld	c,(iy+trk_Rows)		; bc - Set row counter
		ld	b,(iy+(trk_Rows+1))
		ld	a,c
		or	b
		call	z,.next_track		; If rowtimer == 0, get next track data
		cp	-1			; or exit.
		ret	z
		rst	8

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
		jr	.exit			; make row-timer, set hl+1

; --------------------------------
; Exit
; --------------------------------

.exit:
		call	.inc_cpatt
		ld	(iy+trk_Read),l		; Update read location
		ld	(iy+((trk_Read+1))),h
		jr	.decrow_e
.decrow:
		dec	(iy+trk_rowPause)
.decrow_e:
		rst	8
		dec	bc			; Decrement this row
		ld	(iy+trk_Rows),c		; And update it
		ld	(iy+(trk_Rows+1)),b
		ret

; --------------------------------
; New note request
; --------------------------------

.has_note:
		push	bc		; Save rowcount
		ld	c,a		; c - Copy of control+channel
		call	.inc_cpatt
		ld	a,c
		push	iy
		pop	ix
		ld	de,20h		; Point to track-data
		add	ix,de
		rst	8
		ld 	d,0
		and	00111111b
		ld	b,(iy+trk_numChnls)
		cp	b
		jp	nc,.rnout_chnls
		add	a,a		; * 8
		add	a,a
		add	a,a
		ld	e,a
		add	ix,de
		rst	8
		ld	b,(ix+chnl_Type); b - our current Note type
		bit	6,c		; Next byte is new type?
		jr	z,.old_type
		ld	a,(hl)
		ld	(ix+chnl_Type),a
		ld	b,a
		inc 	l
.old_type:
	; b - evinEVIN
	;     E-effect/V-volume/I-instrument/N-note
	;     evin: byte is already stored on track-channel buffer
	;     EVIN: next byte(s) contain a new value, for eff:2 bytes
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
		rst	8
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
		ld	a,(hl)
		ld	(ix+chnl_EffArg),a
		call	.inc_cpatt
.no_eff:
		rst	8
		ld	a,b			; Merge the Impulse recycle bits to main bits
		srl	a
		srl	a
		srl	a
		srl	a
		and	00001111b
		ld	c,a
		rst	8
		ld	a,b
		and	00001111b
		or	c
		ld	c,a
		ld	a,(ix+chnl_Flags)
		or	c
		ld	(ix+chnl_Flags),a
		rst	8
		pop	bc			; Restore rowcount

	; Check for effects that change things
	; to internal playback (jump, tempo, etc.)
		and	1000b		; Filter EFFECT bit only
		or	a
		jp	z,.next_note
		ld	a,(ix+chnl_EffId)
		or	a		; 00h = invalid effect
		jp	z,.next_note
		cp	1		; Effect A: Tick set
		call	z,.eff_A
		cp	2		; Effect B: Position Jump
		call	z,.eff_B
		cp	3		; Effect C: Pattern break
		call	z,.eff_C
		jp	.next_note
.rnout_chnls:
		pop	bc
		jp	.next_note

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
		ld	a,(iy+trk_status)	; Increment-fill enabled?
		and	00010000b
		or	a
		ret	z
		rst	8
		ld	a,(iy+trk_Halfway)
		xor	l
		and	080h			; Check for 00h/80h
		ret	z
		rst	8
		ld	a,(commZRomBlk)		; Got mid-DMA?
		or	a
		jr	z,.grab_asap
		ld	a,l			; Last chance
		and	07Fh
		cp	070h
		ret	c
.grab_asap:
		rst	20h			; refill request
		ld	a,(iy+trk_Halfway)	; +80h to halfway
		ld	d,h
		ld	e,a
		rst	8
		add 	a,080h
		ld	(iy+trk_Halfway),a
		push	hl
		push	bc
		ld	bc,80h			; 80h size + increment value
		ld	l,(iy+trk_romPattRd)
		ld	h,(iy+(trk_romPattRd+1))
		rst	8
		ld	a,(iy+(trk_romPattRd+2))
		add	hl,bc
		adc	a,0
		ld	(iy+trk_romPattRd),l
		ld	(iy+(trk_romPattRd+1)),h
		ld	(iy+(trk_romPattRd+2)),a
		call	transferRom
		pop	bc
		pop	hl
		ret

; ----------------------------------------
; Effect A: Set ticks
; ----------------------------------------

.eff_A:
		ld	e,(ix+chnl_EffArg)	; e - ticks number
		ld	(iy+trk_tickSet),e	; set for both Set and Timer.
		ld	(iy+trk_tickTmr),e
		ret

; ----------------------------------------
; Effect B: jump to a new block
; ----------------------------------------

.eff_B:
		push	af
		ld	e,(ix+chnl_EffArg)	; e - Block SLOT to jump
		ld 	(iy+trk_currBlk),e
		rst	8
		ld	(iy+trk_rowPause),0	; Reset rowpause
		ld	(ix+chnl_EffId),0	; (failsafe)
		ld	(ix+chnl_EffArg),0
		set	5,(iy+trk_status)	; set fill-from-effect flag on exit
		pop	af
		ret

; ----------------------------------------
; Effect C: Pattern break/exit
; ***Not exactly as in Impulse but
; jumps to the next block
;
; If set to -1 it will end the track,
; so you can put multiple SFX into the
; track file and call them by block.
; ----------------------------------------

.eff_C:
		ld	bc,0			; clear rowcount
		ld	a,(ix+chnl_EffArg)
		cp	-1			; EffArg == -1?
		jp	z,.trkend_effC		; Use it as track-end (for SFX)

; ----------------------------------------
; If pattern finished, load the next one
; ----------------------------------------

.next_track:
		ld	a,(iy+trk_currBlk)	; Increment next block
		inc	a
		ld 	(iy+trk_currBlk),a

; Load track data to cache
; a - Block
;
; hl - trk_read on halfway
.set_track:
		rst	8
		ld	(iy+trk_Halfway),80h	; Reset halfway
; 		ld	l,(iy+trk_CachNotes)	; Set trk_read point on halfway
; 		ld	h,(iy+(trk_CachNotes+1))
; 		ld	de,80h
; 		add	hl,de
		ld	l,0			; quick reset trk_read
		ld	(iy+trk_Read),l
		ld	(iy+((trk_Read+1))),h

		push	hl			; Save hl
		ld	de,0
		ld	e,a
		rst	8
		ld	l,(iy+trk_romBlk)	; Get block position
		ld	h,(iy+(trk_romBlk+1))	; directly from ROM
		ld	a,(iy+(trk_romBlk+2))
		add	hl,de
		adc	a,0
		ld	b,a
		rst	8
		call	showRom
		call	readRomB
		cp	-1			; if block == -1, end
		jp	z,.track_end

	; a - head index
		add	a,a
		add	a,a
		ld	d,0
		ld	e,a
		ld	l,(iy+trk_romPatt)
		rst	8
		ld	h,(iy+(trk_romPatt+1))
		ld	a,(iy+(trk_romPatt+2))
		add	hl,de
		adc	a,0
		ld	de,trkHdOut
		push	de
		ld	bc,6			; thispoint, rowcount, nextpoint
		call	transferRom
		pop	hl
		ld	e,(hl)			; de - pointer increment
		inc	hl
		ld	d,(hl)
		inc	hl
		ld	c,(hl)			; bc - row count
		inc	hl
		ld	b,(hl)
		rst	8
		ld	(iy+trk_Rows),c		; Save this number of rows to buffer
		ld	(iy+(trk_Rows+1)),b	; on Tick pauses
		push	bc			; Save bc
		rst	20h			; refill wave

	; Detect pattern size... last moment addition
	; for patterns lower than 80h.
	; This saves cycles if using SFX
	; hl - next pattern point (includes final)
	; de - this pattern
	; bc - final size for transferRom
		ld	a,(trkHdOut+4)	; hl - de
		ld	l,a
		ld	a,(trkHdOut+5)
		ld	h,a
		ccf			; remove carry first
		sbc	hl,de
		ld	c,(iy+trk_status)
		res	4,c
		ld	a,h		; h == 0?
		or	a
; 		jp	m,$
		jr	nz,.szmuch
		bit	7,l
		jr	z,.szgood
.szmuch:
		ld	hl,080h			; bc - max transfer size 080h
		set	4,c
.szgood:
		ld	(iy+trk_status),c
		ld	b,h
		ld	c,l
		ld	l,(iy+trk_romPatt)	; hl - ROM pattern data pointer
		ld	h,(iy+(trk_romPatt+1))
		ld	a,(iy+(trk_romPatt+2))
		add	hl,de			; hl + de
		adc	a,0			; and highest byte too.
		rst	8
		ld	(iy+trk_romPattRd),l	; Save copy of the pointer for READ
		ld	(iy+(trk_romPattRd+1)),h
		ld	(iy+(trk_romPattRd+2)),a
		ld	d,(iy+(trk_Read+1))	; de - destination to data CACHE
		ld	e,(iy+trk_Read)
; 		ld	bc,080h			; bc - 080h
		call	transferRom
		rst	8
		pop	bc			; Get bc back
		pop	hl			; hl too.
		xor	a			; return 0
		ret

; ----------------------------------------
; First time playing or moving
; to next track.
; ----------------------------------------

.effect_fill:
		rst	20h			; Refill wave data
		res	5,b			; Reset refill-from-effect flag
		ld	(iy+trk_status),b
		jr	.go_effect
; 		call	.go_effect
; 		ret

; returns bc as row counter
.first_fill:
		rst	20h
		res	6,b			; Reset FILL flag
		ld	(iy+trk_status),b
		push	iy
		pop	ix			; copy iy to ix
		ld	de,20h			; go to channel data
		add	ix,de
		rst	8
		ld	bc,0
		ld	de,8
		ld	b,MAX_TRKCHN
.clrf:
		rst	8
		ld	a,(ix+chnl_Chip)
		or	a
		jr	z,.nochip
		ld	(ix+chnl_Note),-2
		ld	(ix+chnl_Flags),1
		rst	8
.nochip:
		add	ix,de
		djnz	.clrf
		ld	(iy+trk_rowPause),0	; Reset row timer
		ld	a,(iy+trk_setBlk)	; Set current block
		ld 	(iy+trk_currBlk),a
.go_effect:
		rst	8			; First cache fills
		ld	l,(iy+trk_romIns)	; Recieve almost 100h of instrument pointers
		ld	h,(iy+(trk_romIns+1))	; NOTE: transferRom can't do 100h
		ld	a,(iy+(trk_romIns+2))
		ld	de,(currInsData)
		ld	b,0
		ld	c,(iy+trk_sizeIns)
		call	transferRom
		rst	8
		ld	l,(iy+trk_CachNotes)	; Read first cache notes
		ld	h,(iy+(trk_CachNotes+1))
		ld	de,80h
		add	hl,de
		ld	(iy+trk_Read),l
		ld	(iy+((trk_Read+1))),h
		ld	a,(iy+trk_currBlk)
		jp	.set_track

; If -1, track ends
; Automutes channels too.
.track_end:
		pop	hl			; Get hl back
.trkend_effC:
		call	track_out
		rst	8
		ld	(iy+trk_rowPause),0
		ld	(iy+trk_tickTmr),0
		ld	bc,0			; Set bc rowcount to 0
		ld	a,-1			; Return -1
		ret

; ----------------------------------------
; Delete all track data
; ----------------------------------------

track_out:
		push	iy
		pop	ix
		ld	de,20h
		add	ix,de
		rst	8
		ld	de,8
		ld	b,MAX_TRKCHN
.clrfe:
		ld	a,(ix+chnl_Chip)
		or	a
		jr	z,.nochip
		ld	(ix+chnl_Note),-2
		ld	a,(ix+chnl_Flags)
		and	11110000b
		or	1
		ld	(ix+chnl_Flags),a
.nochip:
		add	ix,de
		djnz	.clrfe
		ld	a,-1			; STOPALL track command
		ld	(iy+trk_CmdReq),a
		ret

; --------------------------------------------------------
; ** 32X ONLY ***
; Communicate to Slave SH2 to play
; PWM sound channels
; --------------------------------------------------------

mars_scomm:
		ld	hl,6000h	; Point BANK closely
		rst	8		; to the 32X area
		ld	(hl),0
		ld	(hl),1
		ld	(hl),0
		ld	(hl),0
		rst	8
		ld	(hl),0
		ld	(hl),0
		ld	(hl),1
		ld	(hl),0
		ld	(hl),1
		rst	8
		ld	iy,5100h|8000h	; iy - mars sysreg
		ld	ix,pwmcom
		ld	a,(marsBlock)	; block MARS requests?
		or	a
		jr	nz,.blocked
		ld	a,(marsUpd)	; update?
		or	a
		ret	z
		rst	8
		xor	a
		ld	(marsUpd),a
.wait_enter:
		nop
		ld	a,(iy+comm15)	; check if 68k got first.
		and	00110000b
		or	a
		jr	nz,.wait_enter
		set	7,(iy+comm15)	; Prepare transfer loop
		set	1,(iy+standby)	; Request Slave CMD
.wait_cmd:
		bit	1,(iy+standby)	; Finished?
		jr	nz,.wait_cmd
		ld	c,14		; c - 14 longs
.next_pass:
		push	iy
		pop	hl
		rst	8
		ld	de,comm8	; hl - comm8
		add	hl,de
		ld	b,2
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
		set	6,(iy+comm15)	; Send CLK to Slave CMD
		rst	8
.w_pass2:
		bit	6,(iy+comm15)	; CLK cleared?
		jr	nz,.w_pass2
		dec	c
		jr	nz,.next_pass
		res	7,(iy+comm15)	; Break transfer loop

; clear COM bits
.blocked:
		ld	hl,pwmcom
		ld	b,7
.clrcom:
		ld	(hl),0
		inc	hl
		djnz	.clrcom
		ret

; --------------------------------------------------------
; Set and play instruments in their respective channels
; --------------------------------------------------------

setupchip:
		ld	hl,insDataC_0
		ld	iy,trkBuff_0		; iy - Tracker channels
		call	.mk_chip
		ld	hl,insDataC_1
		ld	iy,trkBuff_1
.mk_chip:
		ld	a,(iy+trk_status)	; enable bit? (as plus/minus test)
		or	a
		ret	p
		ld	a,(iy+trk_CmdReq)
		ld	(iy+trk_CmdReq),0
		cp	-1
		jr	nz,.clr
		res	7,(iy+trk_status)
.clr:
		ld	(currInsData),hl
		ld	(currTrkCtrl),iy
; 		rst	8
		ld	de,20h
		add	iy,de
		ld	b,MAX_TRKCHN
.nxt_chnl:
		ld	a,(iy+chnl_Flags)	; Get status bits
		and	00001111b
		or	a			; Check for non-zero
		call	nz,.do_chnl
		rst	8
		ld	de,8			; Next CHANNEL
		add	iy,de
		djnz	.nxt_chnl
		ret

; ----------------------------------------
; Channel requested update
;
; iy - Current channel
; ----------------------------------------

.do_chnl:
		push	bc
		call	.check_ins
		cp	-1			; NULL instrument?
		jr	z,.no_chnl
		call	.chip_swap		; check if this channel switched chip
		call	.check_chnl		; a - chip requested
		cp	-1
		jr	z,.ran_out
		ld	(currInsPos),hl
		ld	(currTblPos),ix
		rst	20h
		bit	1,(iy+chnl_Flags)
		call	nz,.req_ins
		bit	2,(iy+chnl_Flags)
		call	nz,.req_vol
		rst	8
		bit	3,(iy+chnl_Flags)
		call	nz,.req_eff
		bit	0,(iy+chnl_Flags)
		call	nz,.req_note
; 		ld	a,(iy+chnl_Flags)	; Instrument+effect also allowed.
; 		and	1010b
; 		or	a
; 		call	nz,.req_note

.ran_out:
		ld	a,(iy+chnl_Flags)	; Clear status bits
		and	11110000b
		ld	(iy+chnl_Flags),a
		pop	bc
		ret
.no_chnl:
; 		call	.chip_swap
		ld	(iy+chnl_Chip),0
; 		ld	(ix+chnl_Flags),0
		pop	bc
		ret

; ----------------------------------------
; bit 1: Intrument
; ----------------------------------------

.req_ins:
		ld	hl,(currInsPos)
		ld	ix,(currTblPos)
		ld	a,(hl)
		and	11110000b
		cp	80h		; PSG normal
		jr	z,.ins_psg
		cp	90h		; PSG noise
		jr	z,.ins_psgn
		rst	8
		cp	0A0h		; FM normal
		jp	z,.ins_fm
		cp	0B0h		; FM special
		jp	z,.ins_fm3
		cp	0C0h		; DAC
		jr	z,.ins_dac
		cp	0D0h		; PWM
		jp	z,.ins_pwm
		ret

; --------------------------------
; FM,FM3,FM6
; --------------------------------

.ins_pwm:
		ld	d,(hl)		; d - Flags
		inc	hl
		ld	a,(hl)		; Save pitch
		inc	hl
		ld	(ix+3),a
		ld	a,(ix+2)
		ld	ix,pwmcom	; ix - pwmcom
		and	000111b
		ld	b,0
		ld	c,a
		add	ix,bc
		ld	a,(hl)		; SH2 BANK
		inc	hl
		and	00001111b
		ld	b,a		; b - Section, ROM or SDRAM
		ld	a,(ix+PWOUTF)
		and	00110000b	; keep flag LR
		ld	c,a		; save them as C
		ld	a,d
		and	00000011b	; Stereo|Loop bits
		rrca			; carry...
		rrca
		or	c
		or	b
		ld	(ix+PWOUTF),a
		ld	a,(hl)		; Grab the 24-bit address (BIG endian)
		inc	hl
		ld	(ix+PWINSH),a
		rst	8
		ld	a,(hl)
		inc	hl
		ld	(ix+PWINSM),a
		ld	a,(hl)
		inc	hl
		ld	(ix+PWINSL),a
		ret

; --------------------------------
; PSG1-3,PSGN
; --------------------------------

.ins_psgn:
		ld	a,(hl)		; Extra bits for NOISE
		and	111b
		ld	(ix+4),a
.ins_psg:
		rst	8
		inc	hl		; Skip ID
		ld	a,(hl)
		ld	(ix+3),a	; Save pitch
		inc	hl
		ld	a,(ix+2)
		and	11b
		ld	d,0
		ld	e,a
		ld	ix,psgcom
		add	ix,de
		ld	a,(hl)

	; TODO: ponerlos en un buffer separado
		ld	(ix+ALV),a	; ALV
		inc	hl
		ld	a,(hl)
		ld	(ix+ATK),a	; ATK
		inc	hl
		rst	8
		ld	a,(hl)
		ld	(ix+SLV),a	; SLV
		inc	hl
		ld	a,(hl)
		ld	(ix+DKY),a	; DKY
		inc	hl
		ld	a,(hl)
		ld	(ix+RRT),a	; RRT
		ret

; --------------------------------
; FM,FM3,FM6
; --------------------------------

.ins_dac:
		ld	(ix+4),1	; e - alternate mode flag (FM6 as DAC)
		ld	a,(hl)		; Grab flags from ID
		and	001b
		ld	(wave_Flags),a
		inc	hl
		ld	a,(hl)		; Save pitch
		ld	(ix+3),a
		inc	hl
		ld	c,(hl)		; Grab the 24-bit address
		inc	hl		; big endian this time.
		rst	8
		ld	d,(hl)
		inc	hl
		ld	e,(hl)

		rst	8
		ld	l,e
		ld	h,d
		ld	a,c
		push	hl		; Recieve LEN and LOOP
		push	af		; from the WAVE itself
		ld	de,wave_Len
		ld	bc,6
		rst	8
		call	transferRom
		pop	af
		pop	hl
		ld	bc,6		; skip LEN point
		add	hl,bc
		adc	a,0
		ld	(wave_Start),hl	; save START point
		ld	(wave_Start+2),a
		ld	a,100b		; Force FM6 off
		ld	(fmcom+5),a
		ret

; FM3 special mode
.ins_fm3:
		ld	a,2		; manual index
		ld	e,1		; set as alternate FM
		call	.rd_fmins
		ld	hl,fmcom+2
		ld	a,(hl)		; instrument update bit
		or	00010000b	; flag
		ld	(hl),a
		ret
; Regular FM
.ins_fm:
		rst	8
		ld	e,0		; Set as normal FM
		ld	a,(ix+2)
		and	00000111b
		cp	5		; Check if we are on FM6
		jr	nz,.not_prdac
		ld	d,a
		ld	a,100b		; Force DAC stop
		rst	8
		ld	(daccom),a
		ld	a,d
.not_prdac:
		ld	e,0		; Set as Normal
		call	.rd_fmins
		ld	a,(ix+2)
		and	00000111b
		ld	d,0
		rst	8
		ld	e,a
		ld	hl,fmcom
		add	hl,de
		ld	a,(hl)		; instrument update bit
		or	00010000b	; flag
		ld	(hl),a
		ret

; Read FM instrument
;
; e - alternate mode flag
.rd_fmins:
		ld	(ix+4),e	; e - alternate mode flag
		inc	hl		; skip ID and pitch
		ld	e,(hl)
		ld	(ix+3),e	; save pitch
		inc	hl
		add	a,a
		ld	d,0
		ld	e,a
		rst	8
		push	hl		; save ins hl
		ld	hl,.fmpickins
		add	hl,de
		ld	e,(hl)		; get output location
		inc	hl		; from list
		ld	d,(hl)
		rst	8
		pop	hl
		ld	a,(hl)		; a - xx0000
		inc	hl
		ld	c,(hl)		; c - 00xx00
		inc	hl
		ld	l,(hl)		; l - 0000xx
		ld	h,c		; c to h
		push	de
		rst	8
		ld	c,a
		ld	a,(ix+7)
		cp	c
		jr	nz,.confm_rd
		ld	a,(ix+6)
		cp	h
		jr	nz,.confm_rd
		ld	a,(ix+5)
		cp	l
		jr	z,.fmsame_ins
.confm_rd:
		rst	8
		ld	(ix+5),l
		ld	(ix+6),h
		ld	(ix+7),c
		ld	a,c
		ld	bc,028h		; 28h bytes
		call	transferRom	; Transfer instrument data from ROM
.fmsame_ins:
		pop	hl
		ret

; manual location for each instr cache
; 28h bytes each
.fmpickins:
		dw fmins_com
		dw fmins_com2
		dw fmins_com3
		dw fmins_com4
		dw fmins_com5
		dw fmins_com6

; ----------------------------------------
; bit 2
; ----------------------------------------

.req_vol:
		ld	hl,(currInsPos)
		ld	ix,(currTblPos)
		ld	a,(hl)
		and	11110000b
		cp	80h		; PSG normal
		jr	z,.vol_psg
		cp	90h		; PSG noise
		jr	z,.vol_psg
		rst	8
		cp	0A0h		; FM normal
		jr	z,.vol_fm
		cp	0B0h		; FM special (same thing)
		jr	z,.vol_fm
; 		cp	0C0h		; DAC
; 		jr	z,.vol_dac
		cp	0D0h		; PWM
		jr	z,.vol_pwm
		ret

; --------------------------------
; FM,FM3,FM6
.vol_pwm:
		ld	bc,0
		ld	a,(ix+2)
		and	00000111b
		ld	c,a
		rst	8
		ld	ix,pwmcom
		add	ix,bc
		ld	a,(ix+PWPTH_V)
		and	00000011b
		ld	c,a		; c - MSB Pitch bits
		ld	a,(iy+chnl_Vol)
		sub	a,40h
		rst	8
		neg	a		; reverse impulse volume
		add	a,a
		add	a,a
		jr	nc,.pvmuch
		ld	a,-1
		rst	8
.pvmuch:
		or	c
		ld	(ix+PWPTH_V),a
		set	5,(ix)		; set volume update bit
		ld	a,1
		ld	(marsUpd),a
		ret

; --------------------------------
; PSG1-3,PSGN

.vol_psg:
		ld	a,(ix+2)
		ld	ix,psgcom
		and	11b
		ld	d,0
		ld	e,a
		add	ix,de
		ld	a,(iy+chnl_Vol)
		sub	a,40h
		neg	a
		ld	c,a
		cp	40h
		jr	nz,.vmuch
		ld	c,-1
.vmuch:
		ld	a,c
		add	a,a
		add	a,a
		ld	(ix+PVOL),a
; 		ld	a,(ix)
; 		or	00100000b	; Set volume
; 		ld	(ix),a		; update flag
		ret

; --------------------------------
; FM,FM3,FM6
.vol_fm:
		ld	bc,0
		ld	a,(ix+2)
		and	00000111b
		ld	c,a
		ld	ix,fmcom
		add	ix,bc
		ld	a,(iy+chnl_Vol)
		sub	a,40h
		rst	8
		neg	a		; reverse impulse volume
		srl	a		; /2
		ld	(ix+FMVOL),a
		ld	a,(ix)		; volume update
		or	00100000b	; flag, plus keyon
		ld	(ix),a
		ret

; ----------------------------------------
; bit 3
; ----------------------------------------

.req_eff:
		ld	hl,(currInsPos)
		ld	ix,(currTblPos)
		ld	a,(iy+chnl_EffId)	; effect id == 0?
		or	a
		ret	z
		ld	d,a
		ld	a,(hl)
		and	11110000b
		ld	e,(iy+chnl_EffArg)
		rst	8
		cp	80h			; PSG normal
		jr	z,.eff_psg
		cp	90h			; PSG noise
		jr	z,.eff_psg
		cp	0A0h			; FM Normal
		jr	z,.eff_fm
		rst	8
		cp	0B0h			; FM Special
		jr	z,.eff_fm
		cp	0C0h			; DAC
		jr	z,.eff_dac
		cp	0D0h			; PWM
		jr	z,.eff_pwm
		ret

; --------------------------------

.eff_psg:
		ld	a,d
		cp	4		; Effect D?
		jp	z,.effPsg_D
		cp	5		; Effect E?
		jp	z,.effPsg_E
		rst	8
		cp	6		; Effect F?
		jp	z,.effPsg_F
		rst	8
		ret
.eff_fm:
		ld	a,d
		cp	4		; Effect D?
		jp	z,.effFm_D
		cp	5		; Effect E?
		jp	z,.effFm_E
		rst	8
		cp	6		; Effect F?
		jp	z,.effFm_F
		cp	24		; Effect X?
		jp	z,.effFm_X
		ret
.eff_dac:
		ld	a,d
		cp	5		; Effect E?
		jp	z,.effDac_E
		cp	6		; Effect F?
		jp	z,.effDac_F
		rst	8
		cp	24		; Effect X?
		jp	z,.effFm_X
		ret
.eff_pwm:
		ld	a,1
		ld	(marsUpd),a
		ld	a,d
; 		cp	4		; Effect D?
; 		jp	z,.effFm_D
		cp	5		; Effect E?
		jp	z,.effPwm_E
		rst	8
		cp	6		; Effect F?
		jp	z,.effPwm_F
		cp	24		; Effect X?
		jp	z,.effPwm_X	; recycle FM's panning
		ret

; --------------------------------
; Effect D
; --------------------------------

.effPsg_D:
		ld	a,e
		or	a
		ret	z
		ld	b,0
		ld	a,(ix+2)
		and	011b
		ld	c,a
		ld	ix,psgcom
		add	ix,bc
		call	.grab_dval
		add	a,a
		add	a,a
		add	a,a
		ld	c,a
		bit	7,c
		jr	nz,.lowp
		ld	a,(ix+PVOL)
		add	a,c
		ret	c
		ld	(ix+PVOL),a
		ret
.lowp:
		ld	a,(ix+PVOL)
		add	a,c
		ret	nc
		ld	(ix+PVOL),a
		ret
.effFm_D:
		ld	a,e
		or	a
		ret	z
		ld	b,0
		ld	a,(ix+2)
		and	111b
		ld	c,a
		ld	ix,fmcom
		add	ix,bc
		call	.grab_dval
; 		srl	a		; TODO: checar que tanto
; 		srl	a		; shifteo esto
		ld	c,a
		set	5,(ix)
		bit	7,c
		jr	nz,.lowpf
		ld	a,(ix+FMVOL)
		add	a,c
		ret	c
		ld	(ix+FMVOL),a
		ret
.lowpf:
		ld	a,(ix+FMVOL)
		add	a,c
		ret	nc
		ld	(ix+FMVOL),a
		ret

; a - increment/decrement value
.grab_dval:
		ld	a,e
		and	11110000b
		cp	11110000b
		jr	z,.go_down
		or	a
		jr	nz,.go_up
.go_down:
		ld	a,e
		and	00001111b
		bit	7,e
		ret	nz
		add	a,a
		rst	8
		ret
.go_up:
		ld	a,e
		rrca
		rrca
		rrca
		rrca
		rst	8
		and	00001111b
		neg	a
		bit	3,e
		ret	nz
		add	a,a
		rst	8
		ret

; --------------------------------
; Effect E
; --------------------------------

.effPsg_E:
		call	.grab_prtm
		ld	d,0
		add	a,a
		ld	e,a
		jp	.freqinc_psg
.effFm_E:
		call	.grab_prtm
		neg	a
		or	a
		jr	z,.e_neg
		ld	d,-1
.e_neg:
		ld	e,a
		jp	.freqinc_fm
.effDac_E:
		call	.grab_prtm
		neg	a
		or	a
		jr	z,.e_negd
		ld	d,-1
.e_negd:
		ld	e,a
		jr	.freqinc_dac

.effPwm_E:
		call	.grab_prtm
; 		sra	a
; 		sra	a
		neg	a
		or	a
		jr	z,.e_fnegd2
		ld	d,-1
.e_fnegd2:
		ld	e,a
		jr	.freqinc_pwm

; --------------------------------
; Effect F
; --------------------------------

; PSG
.effPsg_F:
		call	.grab_prtm
		add	a,a
		neg	a
		or	a
		jr	z,.e_negp
		ld	d,-1
.e_negp:
		ld	e,a
		jr	.freqinc_psg
.effFm_F:
		call	.grab_prtm
		add	a,a
		ld	e,a
		jr	.freqinc_fm
.effDac_F:
		call	.grab_prtm
		ld	e,a
		jr	.freqinc_dac
.effPwm_F:
		call	.grab_prtm
; 		sra	a
; 		sra	a
		ld	e,a

; --------------------------------
; For effects E and F:
;
; de - freq incr/decr

.freqinc_pwm:
		ld	a,(ix+2)
		and	111b
		ld	ix,pwmcom
		ld	b,0
		ld	c,a
		rst	8
		add	ix,bc
		ld	a,(ix+PWPTH_V)
		and	00000011b
		ld	h,a
		ld	l,(ix+PWPHL)
		add	hl,de
		ld	a,(ix+PWPTH_V)
		and	11111100b
		rst	8
		or	h
		ld	(ix+PWPTH_V),a
		ld	(ix+PWPHL),l
		ld	a,(ix)			; pitch bend request
		or	00010000b
		ld	(ix),a
		ld	a,1
		ld	(marsUpd),a
		ret

.freqinc_dac:
		ld	hl,(wave_Pitch)		; tricky one...
		add	hl,de
		ld	(wave_Pitch),hl
		ld	a,(daccom)
		or	00010000b
		ld	(daccom),a
		ret

.freqinc_fm:
		ld	a,(ix+2)
		and	111b
		ld	ix,fmcom
		ld	b,0
		ld	c,a
		rst	8
		add	ix,bc
		ld	h,(ix+FMFRQH)
		ld	l,(ix+FMFRQL)
		add	hl,de
		ld	(ix+FMFRQH),h
		rst	8
		ld	(ix+FMFRQL),l
		ld	a,(ix)
		or	00000001b
		ld	(ix),a
		ret
.freqinc_psg:
		ld	a,(ix+2)
		and	011b
		ld	ix,psgcom
		ld	b,0
		ld	c,a
		add	ix,bc
		rst	8
		ld	h,(ix+DTH)
		ld	l,(ix+DTL)
		add	hl,de
		ld	a,h
		and	00000111b
		ld	h,a
		rst	8
		ld	(ix+DTH),h
		ld	(ix+DTL),l
		ld	a,(ix)
		or	00000001b
		ld	(ix),a
		ret
; grab portametro value
.grab_prtm:
		ld	d,0
		ld	a,e
		and	11110000b
		cp	0F0h
		jr	nz,.e_nof
		rst	8
		ld	a,e
		and	0Fh
		add	a,a
		jr	.e_go
.e_nof:
		rst	8
		cp	0E0h
		jr	nz,.e_noef
		ld	a,e
		and	0Fh
		jr	.e_go
.e_noef:
		rst	8
		ld	a,e
		add	a,a
		add	a,a
.e_go:
		ret

; --------------------------------
; Effect X: Panning
; --------------------------------

; PWM points here too.
.effPwm_X:
		ld	a,e
		rlca
		rlca
		and	00000011b
		ld	hl,.fmpan_list
		ld	de,0
		ld	e,a
		rst	8
		add	hl,de
		ld	e,(hl)
		ld	a,(iy+chnl_Flags)
		and	11001111b
		or	e
		ld	(iy+chnl_Flags),a
		ret

; PWM points here too.
.effFm_X:
		ld	a,(ix+2)
		and	111b
		ld	b,0
		ld	c,a
		ld	ix,fmcom
		add	ix,bc
		ld	a,e
		rlca
		rlca
		and	00000011b
		ld	hl,.fmpan_list
		ld	de,0
		ld	e,a
		rst	8
		add	hl,de
		ld	e,(hl)
		ld	a,(iy+chnl_Flags)
		and	11001111b
		or	e
		ld	(iy+chnl_Flags),a
		ld	a,(iy+chnl_Flags)
		add	a,a		; move LR bits
		add	a,a
		cpl
		and	11000000b	; Set Panning ENABLE bits
		ld	(ix+FMPAN),a

; 		ld	a,(iy+chnl_Flags)
; 		add	a,a		; move LR bits
; 		add	a,a
; 		cpl
; 		and	11000000b	; Set Panning ENABLE bits
; 		ld	(ix+FMPAN),a
; 		ld	e,11110000b	; ALLOWED keys (TEMPORAL)
; 		rst	8
; 		ld	(ix+FMKEYS),e
		ld	a,(ix)		; key on
		or	01000000b
		ld	(ix),a

		ret
.fmpan_list:
		db 00010000b	; 000h
		db 00010000b	; 040h
		db 00000000b	; 080h
		db 00100000b	; 0C0h

; ----------------------------------------
; bit 0
; ----------------------------------------

.req_note:
		ld	hl,(currInsPos)
		ld	ix,(currTblPos)
		ld	a,(hl)
		ld	c,a		; special copy
		and	11110000b
		cp	80h		; PSG normal
		jp	z,.note_psg
		cp	90h		; PSG noise
		jp	z,.note_psgn
		cp	0A0h
		jp	z,.note_fm
		rst	8
		cp	0B0h
		jp	z,.note_fm3
		cp	0C0h
		jp	z,.note_dac
		cp	0D0h
		jp	z,.note_pwm
		ret

; --------------------------------
; Note: PWM
; --------------------------------

.note_pwm:
		ld	a,1			; Send MARS request
		ld	(marsUpd),a
		ld	hl,pwmcom
		ld	a,(ix+2)
		and	000111b
		ld	b,0
		ld	c,a
		add	hl,bc
		rst	8
		ld	a,(iy+chnl_Note)
		cp	-1
		jp	z,.pwm_keyoff
		cp	-2
		jp	z,.pwm_keycut
		ld	de,0
		ld	e,(ix+3)		; Get pitch
		add	a,e
		add	a,a
		rst	8
		ld	e,a
		ld	a,c
		or	0D0h
		ld	(iy+chnl_Chip),a	; Set as PWM
		push	hl
		pop	ix
		ld	hl,wavFreq_List
		add	hl,de
		ld	e,(hl)
		inc	hl
		ld	d,(hl)			; note: max 111b
		rst	8
		set	0,(ix)			; Note-on
		ld	a,d
		bit	2,(iy+chnl_Flags)	; check if volume is being used
		jr	z,.pwmn_kpv
		ld	a,(ix+PWPTH_V)
		and	11111100b
		or	d
.pwmn_kpv:
		ld	(ix+PWPTH_V),a
		ld	(ix+PWPHL),e
		ld	a,(ix+PWOUTF)
		and	11001111b		; Keep other bits
		ld	c,a
		ld	a,(iy+chnl_Flags)	; 00LR 0000
		cpl
		and	00110000b
		or	c
		ld	(ix+PWOUTF),a
		ret

; PSG Keyoff
.pwm_keyoff:
		ld	c,010b
		ld	(hl),c
		ret
.pwm_keycut:
		ld	c,100b
		jr	.chnl_unlink

; 		ld	a,100b			; Request DAC stop
; 		ld	(daccom),a
; .doff:
; 		ld	hl,0
; 		ld	(tblFM6),hl
; 		ld	(iy+chnl_Chip),0
; 		ret

; --------------------------------
; Note: PSG1-3,PSGN
; --------------------------------

; PSG Keyoff
.poff:
		ld	c,010b
		ld	(hl),c
		ret
; PSG Keycut
.pcut:
		ld	c,100b
.chnl_unlink:
		rst	8
		push	iy
		pop	de
		ld	a,(ix)
		cp	e
		ret	nz
		ld	a,(ix+1)
		cp	d
		ret	nz
		rst	8
		ld	(hl),c
		ld	(ix),0
		ld	(ix+1),0
		ld	(ix+3),0	; pitch zero
		ld	(iy+chnl_Chip),0
		ret

; Play PSG note
.note_psgn:
		ld	a,(ix+2)
		or	90h
		ld	(iy+chnl_Chip),a
		ld 	hl,psgcom+3
		ld	a,(iy+chnl_Note)
		cp	-2
		jp	z,.pcut
		cp	-1
		jp	z,.poff
		ld	e,a
		ld 	a,(ix+4)
		ld	(psgHatMode),a
		and	011b
		cp	011b
		jr	nz,.np2_n
		ld	a,100b
		ld	(psgcom+2),a
.np2_n:
		ld	a,e
		jr	.notepsg_fn
.note_psg:
		ld	a,(ix+2)
		or	80h
		ld	(iy+chnl_Chip),a
		ld	a,(ix+2)
		rst	8
		and	11b
		ld	d,0
		ld	e,a
		ld 	hl,psgcom
		add	hl,de
		cp	2
		jr	nz,.notepsg_c
		ld	a,(psgHatMode)
		and	011b
		cp	011b
		jr	nz,.notepsg_c
		ld	(hl),100b	; key-cut PSG3 but dont unlink
		ret
.notepsg_c:
		ld	a,(iy+chnl_Note)
		cp	-2
		jp	z,.pcut
		cp	-1
		jp	z,.poff
.notepsg_fn:
		rst	8
		push	hl		; save psgcom
		ld	hl,psgFreq_List
		ld	c,(ix+3)
		add	a,c
		add	a,a
		ld	de,0
		ld	e,a
		add	hl,de
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		ld	bc,0
		and	11b
		ld	c,a
		push	ix		; swap ix to hl
		pop	hl
		rst	8
		inc	hl		; skip link
		inc	hl
		inc 	hl		; channel id
		inc	hl		; pitch
; 		ld	a,c
; 		cp	3
; 		jr	nz,.npsg2
; 		ld 	a,(ix+4)
; 		ld	(psgHatMode),a
; .npsg2:
		pop	ix			; restore psgcom as ix
		ld	a,(iy+chnl_Flags)	; Check is volume bit
		bit	2,a			; is being used
		jr	nz,.nodefv
		ld	(ix+PVOL),0		; if not, set max volume
.nodefv:
		ld	(ix+DTL),e
		ld	(ix+DTH),d
		ld	(ix+COM),001b	; Key ON
		ret

; --------------------------------
; Note: FM,FM3,FM6
; --------------------------------

.note_dac:
		ld	hl,daccom
		ld	a,(iy+chnl_Note)
		cp	-1
		jp	z,.fm_keyoff
		cp	-2
		jp	z,.fm_keycut
		ld	(iy+chnl_Chip),0C0h	; Set as DAC
		ld	de,0
		ld	e,(ix+3)		; Get pitch
		add	a,e
		add	a,a
		ld	e,a
		ld	hl,wavFreq_List
		add	hl,de
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		rst	8
		ld	l,a
		ld	de,ZSET_WTUNE		; Fine-tune to desired
		add	hl,de			; WAVE frequency
		ld	(wave_Pitch),hl
; 		ld	a,1
; 		and	001b
; 		ld	(wave_Flags),a
		ld	a,001b			; Request DAC play
		ld	(daccom),a
		ret
.dcut:
		ld	a,100b			; Request DAC stop
		ld	(daccom),a
.doff:
		ld	hl,0
		ld	(tblFM6),hl
		ld	(iy+chnl_Chip),0
		ret
; FM3 special
.note_fm3:
		ld	hl,fmcom+2		; Channel 3 fmcom
		ld	a,(iy+chnl_Note)
		cp	-1
		jp	z,.fm_keyoff
		cp	-2
		jp	z,.fm_keycut
		ld	(iy+chnl_Chip),0B0h	; Set as FM3 special
		ld	d,27h
		ld	a,01000000b
		ld	(fmSpcMode),a
		ld	e,a
		call	fm_send_1
		push	hl
		pop	ix
		jr	.fm_chnlkon
; Normal FM
.note_fm:
		ld	a,(iy+chnl_Note)
		ld	d,a
		ld	e,(ix+3)
		add	a,e
		rst	8
		ld	c,a			; c - Note+pitch
		ld	a,(ix+2)
		ld	b,a
		and	00000111b
		ld	hl,fmcom		; hl - fmcom list
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
		ld	a,b			; Set chip as FM
		and	111b
		cp	2			; Check if we got into channel 3
		jr	nz,.rd_nt3
		ld	b,a
		ld	d,27h			; Disable CH3 special mode
		ld	a,00000000b
		ld	(fmSpcMode),a
		rst	8
		ld	e,a
		call	fm_send_1
		ld	a,b
.rd_nt3:
		or	0A0h
		ld	(iy+chnl_Chip),a
		ld	a,c
		rst	8
		ld	b,0			; b - octave
		ld	e,7
.get_oct:
		ld	c,a
		sub	12
		or	a
		jp	m,.fnd_oct
		inc	b
		dec	e
		jr	nz,.get_oct
.fnd_oct:
	; b - octave / c - note
		push	de
		rst	8		; ix - current fmcom
		ld	a,c
		add	a,a
		ld	c,a		; c - freq word
		ld	a,b
		add	a,a
		add	a,a
		add	a,a
		ld	b,0
		push	hl
		rst	8
		pop	ix
		ld	hl,fmFreq_List
		add	hl,bc
		inc	hl
		ld	c,a		; c - octave << 3
		ld	a,(hl)		; Note MSB
		or	c		; add octave
		ld	d,a
		dec	hl
		rst	8
		ld	a,(hl)
		ld	e,a
		ld	(ix+FMFRQH),d	; Save freq MSB
		ld	(ix+FMFRQL),e	; Save freq LSB
		pop	de
.fm_chnlkon:
		ld	a,(iy+chnl_Flags)
		add	a,a		; move LR bits
		add	a,a
		cpl
		and	11000000b	; Set Panning ENABLE bits
		ld	(ix+FMPAN),a
		ld	e,11110000b	; ALLOWED keys (TEMPORAL)
		rst	8
		ld	(ix+FMKEYS),e
		ld	a,(ix)		; key on
		or	01000001b
		ld	(ix),a
		bit	2,(iy+chnl_Flags)	; check if volume is being used
		jr	nz,.fm_kpv
		ld	(ix+FMVOL),0
.fm_kpv:
		ret

; keyoff/cut
.fm_keycut:
		ld	c,100b
		jp	.chnl_unlink
.fm_keyoff:
		ld	c,010b
		ld	(hl),c
		ret

; ----------------------------------------
; Channel chip swap
; ----------------------------------------

.chip_swap:
		ld	c,a		; c - New chip ID
		and	11110000b
		ld	b,a
		ld	a,(iy+chnl_Chip)
		rst	8
		ld	e,a		; e - Old chip ID
		and	11110000b
		cp	b
		jr	z,.chip_out
		ld	d,a		; d - reuse last ID
		ld	a,c		; New chip-ins is null?
		cp	-1
		jr	nz,.from_nl
		ld	a,e		; Reuse OLD ID
		rst	8
		and	11110000b
		ld	d,a		; new id to check
.from_nl:
		ld	a,d
		ld	d,0
		cp	80h
		call	z,.psg_out
		cp	90h
		call	z,.psgn_out
		rst	8
		cp	0A0h
		call	z,.fm_out
		cp	0B0h
		call	z,.fm3_out
		cp	0C0h
		call	z,.dac_out
		cp	0D0h
		call	z,.pwm_out
		rst	8
.chip_out:
		ld	a,c
		ret

.pwm_out:
		push	hl
		ld	a,e
		and	111b
		ld	b,a
		ld	e,a
		rst	8
		add	a,a
		add	a,a
		add	a,a
		ld	e,a
		ld	hl,tblPWM
		add	hl,de
		call	.chp_unlk
		rst	8
		ld	d,0
		ld	e,b
		ld	hl,pwmcom
		add	hl,de
		ld	(hl),100b
		ld	a,1
		ld	(marsUpd),a
		jr	.p_out

.dac_out:
		push	hl
		ld	hl,tblFM6
		call	.chp_unlk
		ld	hl,daccom
		ld	(hl),100b
		pop	hl
		ret
.fm3_out:
		push	hl
		ld	hl,tblFM3
		call	.chp_unlk
		ld	hl,fmcom+2
		ld	(hl),100b
		pop	hl
		ret
.psgn_out:
		push	hl
		ld	hl,tblPSGN
		call	.chp_unlk
		ld	hl,psgcom+3
		ld	(hl),100b
		pop	hl
		ret
.psg_out:
		push	hl
		ld	a,e
		and	011b
		ld	b,a
		ld	e,a
		add	a,a
		rst	8
		add	a,a
		add	a,a
		ld	e,a
		ld	hl,tblPSG
		add	hl,de
		call	.chp_unlk
		jr	nz,.p_out
		rst	8
		ld	d,0
		ld	e,b
		ld	hl,psgcom
		add	hl,de
		ld	(hl),100b
.p_out:
		pop	hl
		ret
.fm_out:
		push	hl
		ld	a,e
		and	111b
		ld	b,a
		ld	e,a
		rst	8
		add	a,a
		add	a,a
		add	a,a
		ld	e,a
		ld	hl,tblFM
		add	hl,de
		call	.chp_unlk
		rst	8
		ld	d,0
		ld	e,b
		ld	hl,fmcom
		add	hl,de
		ld	(hl),100b
		jr	.p_out

.chp_unlk:
		push	iy
		pop	de
		rst	8
		ld	a,(hl)
		cp	e
		ret	nz
		inc	hl
		ld	a,(hl)
		cp	d
		ret	nz
		dec	hl
		rst	8
		ld	(hl),0
		inc	hl
		ld	(hl),0
		inc	hl
		ld	e,(hl)	; c - ID
		inc	hl
		ld	(hl),0	; reset 5 bytes of settings
		rst	8
		inc	hl
		ld	(hl),0
		inc	hl
		ld	(hl),0
		inc	hl
		ld	(hl),0
		inc	hl
		ld	(hl),0
		xor	a
		or	a
		ret

; ----------------------------------------
; Sets current instrument data
;
;   -1 - Null instrument
;  80h - PSG
;  90h - PSG Noise
; 0A0h - FM
; 0B0h - FM3 Special
; 0C0h - FM6 Sample
; 0D0h - PWM (or extra)
; ----------------------------------------

.check_ins:
		ld	a,(iy+chnl_Ins)
		dec	a		; minus 1
		ret	m		; return as -1 if no ins is used.
		add	a,a		; * 08h
		add	a,a
		rst	8
		add	a,a
		ld	hl,(currInsData)
		ld	de,0
		ld	e,a
		add	hl,de
		ld	a,(hl)
		ret

; ----------------------------------------
; Checks which channel type is using
; auto-set channel
;
; a - sound chip
; ----------------------------------------

.check_chnl:
		cp	-1		; if -1: Null
		ret	z
		rst	8
		ld	c,a		; save copy to c
		add	a,a		; * 2
		ld	d,0
		rrca
		rrca
		rrca
		rrca
		and	00001111b
		ld	e,a
		ld	ix,.tbllist	; get table from list
		add	ix,de
		ld	e,(ix)
		ld	d,(ix+1)
		rst	8
		push	de
		pop	ix
		ld	a,c		; restore from c
		cp	90h		; type PSGN?
		jr	z,.chk_tbln
		cp	0B0h		; type FM3?
		jr	z,.chk_tbln
		cp	0C0h		; type DAC?
		jr	z,.chk_tbln
		jr	.chk_tbl
.bad_ins:
		ld	a,-1
		ret

; --------------------------------------------

.tbllist:
		dw tblPSG	;  80h
		dw tblPSGN	;  90h
		dw tblFM	; 0A0h
		dw tblFM3	; 0B0h
		dw tblFM6	; 0C0h
		dw tblPWM	; 0D0h

; --------------------------------------------
; Check SINGLE channel table
; (FM3,FM6,PSGN)
; --------------------------------------------

; This auto-replaces the LINKED channel
.chk_tbln:

; 	TODO: priority overwrite goes here...
; 		push	iy
; 		pop	de		; de - Copy of curr track-channel
; 		rst	8
; 		ld	a,(ix+1)	; MSB | LSB
; 		or	(ix)		; Check if blank
; 		jr	z,.new
; 		ld	a,(ix+1)	; MSB | LSB
; 		cp	d		; Same MSB?
; 		jr	nz,.busy_s
; 		ld	a,(ix)
; 		cp	e		; Same LSB?
; 		jr	nc,.busy_s
.new:
		rst	8
		ld	(ix),e		; NEW slot
		ld	(ix+1),d
		xor	a		; Found free slot, pick it.
		ret
.busy_s:
		ld	a,-1
		ret

; --------------------------------------------
; Check available channel slot from list
; --------------------------------------------

.chk_tbl:
		ld	bc,0		; bc - Free slot point
.next:
		ld	a,(ix+1)	; Check MSB first
		cp	-1		; End of list? (as WORD: 0FFxxh)
		jr	z,.chkfree
		push	iy
		pop	de		; de - Copy of curr track-channel
		rst	8
		cp	d		; check if link matches
		jr	nz,.diffr
		ld	a,(ix)
		cp	e
		jr	nz,.diffr
		xor	a		; return 0
		ret
.diffr:
		ld	a,c		; bc link already set?
		or	b
		jr	nz,.alrdfnd
		rst	8
		ld	e,(ix+1)	; Check if this link == 0
		ld	a,(ix)
		or	e
		jr	z,.fndlink
		push	de		; Check if this link is
		ld	d,(ix+1)	; floating.
		ld	e,(ix)
		inc	de
		rst	8
		ld	a,(de)
		pop	de
		cp	-2
		jr	z,.fndlink
		cp	-1
		jr	z,.fndlink
		jr	.alrdfnd
; 		ld	a,e		; TODO: priority.
; 		cp	d
; 		jr	nc,.alrdfnd
.fndlink:
		push	ix		; bc - got new link
		pop	bc
		rst	8
.alrdfnd:
		ld	de,8		; Next channel table
		add	ix,de
		jr	.next

; free link slot
.chkfree:
		ld	a,c		; found free link?
		or	b
		jr	z,.fndslot
		push	bc
		pop	ix		; tell ix is the new slot
		push	iy
		pop	de		; and mark it on buffer
		rst	8
		ld	(ix),e
		ld	(ix+1),d
		xor	a
		ret
.fndslot:
		ld	a,-1		; linksteal check goes here
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
		ld	de,2208h|3	; Set default LFO
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

	; set each tracks' settings
		ld	iy,trkBuff_0
		ld	hl,trkData_0
		ld	e,MAX_TRKCHN
		ld	d,8*16			; maximum size
		call	.set_it
		ld	iy,trkBuff_1
		ld	hl,trkData_1
		ld	e,MAX_TRKCHN
		ld	d,8*16
.set_it:
		ld	(iy+trk_CachNotes),l
		ld	(iy+(trk_CachNotes+1)),h
		ld	(iy+trk_numChnls),e
		ld	(iy+trk_sizeIns),d
		ret

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
		ld	hl,tickFlag+1		; read last TICK flag
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
; showRom:
; Get ROM position visible for reading
;
; Input:
;  b - ROM address $xx0000
; hl - ROM address $00xxxx
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
		rst	8
		pop	bc
		pop	de
		set	7,h
		ret

; --------------------------------------------------------
; readRomB:
; Reads a byte from ROM safetly, for a single and quick
; byte-read only, NOT autoswitchable.
; CALL showRom FIRST, DO NOT CALL RST 20h (dac_fill)
; BEFORE GETTING HERE
;
; Input:
; hl - ROM position in Z80's area
;      (BANK must be set already)
;
; Output:
; a - byte recieved
; --------------------------------------------------------

; ALL this code just to read one byte without bothering
; the DMA from the 68k side

readRomB:
		push	ix
		ld	ix,commZRomBlk
		set	0,(ix+1)	; ROM read request
		bit	0,(ix)		; 68k is on DMA?
		jr	nz,.wait
.imback:	ld	a,(hl)		; Read the byte.
		res	0,(ix+1)
		rst	8
		pop	ix
		ret
.wait:
		res	0,(ix+1)	; Not reading ROM
.w2:
		rst	8
		nop
		nop
		rst	8
		bit	0,(ix)		; Is ROM free from 68K?
		jr	nz,.w2
		set	0,(ix+1)	; Reading ROM again.
		jr	.imback

; --------------------------------------------------------
; transferRom
;
; Transfer bytes from ROM to Z80, this also tells
; to 68k that we are reading fom ROM
;
; Input:
; a  - Source ROM address $xx0000
;  c - Byte count (size 0 NOT allowed, MAX: 0FFh)
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

; Note: got this from GEMS...

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

; ------------------------------------------------
; b  - Source ROM xx0000
;  c - Bytes to transfer (00h not allowed)
; hl - Source ROM 00xxxx (OR'd with 8000h)
; de - Destination address
;
; Uses:
; a
; ------------------------------------------------

.transfer:
		call	showRom

	; Transfer data in packs of bytes
	; while playing cache WAV in the process
	; *** CRITICAL PROCESS FOR WAV PLAYBACK ***
	;
	; pseudo-ref for ldir:
	; ld (de),(hl)
	; inc de
	; inc hl
	; dec bc
	;
		ld	b,0
		ld	a,c		; a - pieces counter
		set	0,(ix+1)	; Tell to 68k that we are reading from ROM
		sub	6		; LENGHT lower than 6?
		jr	c,.x68klast	; Process single piece only
.x68kloop:
		rst	8
		ld	c,6-1
		bit	0,(ix)		; If 68k requested ROM block from here
		jr	nz,.x68klpwt
.x68klpcont:
		rst	8
		ldir			; (de) to (hl) until bc==0
		sub	a,6-1
		jp	nc,.x68kloop
; last block
.x68klast:
		add	a,6
		ld	c,a
		bit	0,(ix)		; If 68k requested ROM block from here
		jp	nz,.x68klstwt
.x68klstcont:
		rst	8
		ldir
		res	0,(ix+1)	; Tell 68k we are done reading
		ret

; If Genesis wants to do DMA, loop indef here until it finishes.
; if on mid-loop
.x68klpwt:
		res	0,(ix+1)	; Tell 68k we are out, waiting.
.x68kpwtlp:
		rst	8
		nop
		rst	8
		bit	0,(ix)		; 68k finished?
		jr	nz,.x68kpwtlp
		set	0,(ix+1)	; Set Z80 read flag again, and return
		jr	.x68klpcont

; or in the last piece
.x68klstwt:
		res	0,(ix+1)	; Tell 68k we are out, waiting.
.x68klstwtlp:
		rst	8
		nop
		rst	8
		bit	0,(ix)		; 68k finished?
		jr	nz,.x68klstwtlp
		set	0,(ix+1)	; Set Z80 read flag again, and return
		jr	.x68klstcont

; ====================================================================
; ----------------------------------------------------------------
; Sound chip routines
; ----------------------------------------------------------------

; --------------------------------------------------------
; chip_env
;
; Process PSG and FM
; --------------------------------------------------------

; Read PSG list backwards so it autodetects
; Tone3 mode

chip_env:
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
		ld	a,e
		cp	4
		jr	nz,.ckof
		ld	a,0
		ld	(psgHatMode),a
		rst	8
.ckof:
		bit	1,c			; bit 1 - key off
		jr      z,.ckon
		ld	a,(iy+MODE)		; mode 0?
		or	a
		jr	z,.ckon
		ld	(iy+FLG),1		; psg update flag
		ld	(iy+MODE),100b		; set envelope mode 100b
		ld	a,e
		cp	4
		jr	nz,.ckon
		ld	a,0
		ld	(psgHatMode),a
		rst	8
.ckon:
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

		ld	a,(iy+DTL)	; Grab LSB 4 right bits
		and	00001111b
		or	d		; OR with current channel
		ld	(hl),a		; write it
		ld	a,(iy+DTL)	; Grab LSB 4 left bits
		rrca
		rrca
		rrca
		rrca
		and	00001111b
		ld	c,a
		ld	a,(iy+DTH)	; Grab MSB bits
		rlca
		rlca
		rlca
		rlca
		and	00110000b
		or	c
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
		rst	8
		ld	a,(iy+DTL)		; Steal PSG3's freq
		or	0C0h
		ld	(hl),a
		ld	a,(iy+DTH)
		ld	(hl),a
.sethat:
		rst	8
		ld	a,(psgHatMode)		; write hat mode only.
		or	d
		ld	(hl),a
.nskip:
		ld	(iy+FLG),1		; psg update flag
		ld	(iy+MODE),001b		; set to attack mode
		rst	8

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
		ld	c,a			; c - attack rate
		ld	a,b			; a - attack level
		rst	8
		ld	b,(iy+ALV)		; b - OLD attack level
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
		rst	8
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
		rst	8
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
		ld	(iy+FLG),0	; Reset until next one
		rst	8
		ld	a,(iy+LEV)	; a - Level
		add	a,(iy+PVOL)	; Level + master volume
		jr	nc,.vlmuch
		ld	a,-1
.vlmuch:
		srl	a		; (Level >> 4)
		srl	a
		srl	a
		rst	8
		srl	a
		and	00001111b
		or	90h		; Set volume-set mode
		or	d		; add current channel
	if ZSET_TESTME=0
		ld	(hl),a		; Write volume
	endif

.noupd:
		dec	iy		; next COM to check
		ld	a,d
		rst	8
		sub	a,20h		; next PSG (backwards)
		ld	d,a
		dec	e
		jp	nz,.vloop

; ----------------------------
; FM section
; ----------------------------

	; Read FM channels
	; iy - FM com
	; ix - FM current instrument data
	;  c - FM channel ID
		ld	iy,fmcom
		ld	ix,fmins_com
		ld	bc,0500h
.nextfm_1:	push	bc
		call	.fm_chnl	; Channel 1
		pop	bc
		ld	de,28h
		add	ix,de
		inc	iy
		rst	8
		inc	c
		ld	a,c
		cp	3		; c == 3?
		jr	nz,.nomidc
		inc	c
		rst	8
.nomidc:
		djnz	.nextfm_1

	; Special check for Channel 6
		ld	a,(daccom)	; Channel 6 / DAC
		ld	e,a
		xor	a
		ld	(daccom),a
		bit	0,e		; WAVE sample request
		jr	nz,.req_dac
		bit	4,e
		jr	nz,.req_pitch
		rst	8
		bit	2,e		; key-cut?
		jp	nz,dac_off
		bit	1,e		; key-off?
		ret	nz
		ld 	a,(dac_me)	; manually check if
		cp	zopcExx		; WAVE playback is active
		ret	z
		ld	de,28h
		add	ix,de
		rst	8
		ld	a,(ix)
		inc	iy
		inc	c
		jr	.fm_chnl			; Channel 6 (normal)
.req_dac:
		ld	d,0B6h			; Panning for DAC
		ld	a,((fmcom+5)+FMPAN)	; Reuse FM6's panning
		ld	e,11000000b
		call	fm_send_2
		jp	dac_play		; Set playback
.req_pitch:
		exx
		ld	hl,(wave_Pitch)
		exx
; 		bit	4,c
; 		ret	nz
; 		exx
; 		push	de
; 		exx
; 		pop	hl
; 		rst	8
; 		add	hl,de
; 		push	hl
; 		exx
; 		pop	de
; 		exx
		ret

; ----------------------------------------
; Control current FM channel
;
; iy - fmcom
; ix - Instrument data pointer
;  c - FM chip ID
; ----------------------------------------

	; 0pvi 0cop
	; pvi - update bits:
	;      volume(v)
	;      instrument(i)
	;      panning(p)
	;
	; c/o/p key cut, key off, key on
.fm_chnl:
		ld	a,(iy)		; Get comm bits
		or	a
		ret	z
		ld	(iy),0		; Reset
		bit	2,a		; Key-cut (010b) bit?
		jp	nz,.fm_keycut
		bit	1,a		; Key-off (100b) bit?
		jp	nz,.fm_keyoff
		ld	b,a		; b - other update bits
		ld	a,c		; check for Channel 6
		cp	6
		call	z,dac_off	; auto-mute WAVE playback
		rst	8
		bit	4,b		; Instrument-update bit?  (%0001xxxx)
		call	nz,.fm_insupd
		bit	5,b		; Volume-update bit? (%0010xxxx)
		call	nz,.fm_volupd	;
		bit	6,b		; Panning update bit? (%0100xxxx)
		call	nz,.fm_panupd
		bit	0,b		; Key-on (001b) bit?
		ret	z
	; freq update
	; all this code is for OP4 (if FM3 is in special)
		rst	8
		ld	a,c
		and	11b
		or	0A4h
		ld	d,a
		ld	e,(iy+FMFRQH)
		bit	2,c
		call	nz,fm_send_2
		call	z,fm_send_1
		rst	8
		dec	d
		dec	d
		dec	d
		dec	d
		ld	e,(iy+FMFRQL)
		bit	2,c
		call	nz,fm_send_2
		call	z,fm_send_1
		rst	8

		ld	a,c
		and	11b
		or	0B0h
		ld	d,a
		ld	e,(ix+1Ch)
		bit	2,c
		call	nz,fm_send_2
		call	z,fm_send_1
		inc	d
		inc	d
		rst	8
		inc	d
		inc	d
; 		call	.fm_panset

	; For Special FM3 mode it just copy-pastes regs
	; from a separate list
		ld	a,c		; FM3 special check
		cp	2
		jr	nz,.notfm3
		ld	a,(fmSpcMode)
		and	01000000b
		or	a
		jr	z,.notfm3
		rst	8
		ld	hl,fm3reg
		ld	b,3*2
.copyops:
		ld	e,(hl)
		inc	hl
		ld	d,(hl)
		inc	hl
		nop
		rst	8
		call	fm_send_1
		djnz	.copyops
.notfm3:

		rst	8
		ld	d,28h		; Keys
		ld	a,(ix+01Fh)	; a - Read this ins keys
		ld	b,(iy+FMKEYS)	; b - ALLOWED bits from fmcom
		and	b
		or	c
		ld	e,a
	if ZSET_TESTME=1
		ret
	endif
		jp	fm_send_1

.fm_keycut:
		ld	a,c
		and	11b
		or	0B4h
		ld	d,a
		rst	8
		ld	a,(ix+1Dh)
		and	00000111b
		ld	e,a
		bit	2,c
		call	z,fm_send_1
		call	nz,fm_send_2
.fm_keyoff:
		rst	8
		ld	e,c
		ld	d,28h
		jp	fm_send_1
; d - 0B4h+
.fm_panupd:
		ld	a,c
		and	11b
		or	0B4h
		ld	d,a
.fm_panset:
		ld	e,(ix+1Dh)
		ld	a,(iy+FMPAN)
		and	11000000b
		or	e
		ld	e,a
		bit	2,c
		call	nz,fm_send_2
		call	z,fm_send_1
		ret

; CPU-intense
; only call this if needed
.fm_insupd:
		push	bc
		call	.fm_keyoff		; restart chip channel
		rst	20h;call dac_fill	; TODO: ver si se pone lento aqui...
		push	ix			; copy ix to hl
		pop	hl
		ld	a,c
		and	011b
		or	30h
		rst	8
		ld	d,a
		ld	b,4*7
.copy_1:
		rst	8
		ld	e,(hl)
		bit	2,c
		call	z,fm_send_1
		call	nz,fm_send_2
		inc	hl
		inc	d
		rst	8
		nop
		inc	d
		inc	d
		inc	d
		djnz	.copy_1
		ld	de,4		; skip AMS, FMS,
		add	hl,de		; old FM3 check (oops) and keys
		ld	a,c		; check for Channel 3
		cp	2
		jr	nz,.fm_ins_ex
		rst	8
		ld	a,(fmSpcMode)	; Is it in special mode?
		bit	6,a
		jr	z,.fm_ins_ex
		push	ix
		ld	ix,fm3reg
		ld	b,3
.copyops3:
		ld	d,(hl)		; Read OP1-3 freqs
		inc	hl
		rst	8
		ld	e,(hl)
		inc	hl
		ld	(ix),d
		ld	(ix+2),e
		inc	ix
		rst	8
		inc	ix
		inc	ix
		inc	ix
		djnz	.copyops3
		ld	ix,fmcom+2	; Read OP4 freq
		ld	d,(hl)
		inc	hl
		rst	8
		ld	e,(hl)
		ld	(ix+FMFRQH),d
		ld	(ix+FMFRQL),e
		pop	ix
.fm_ins_ex:
		pop	bc
		ret

; b - Volume decrement
; c - Channel id
; d - 40h+ base reg
; h - Algorithm
.fm_volupd:
		push	bc
		ld	b,(iy+FMVOL)
.fm_chnlvol:
		push	ix
		ld	a,(ix+1Ch)
		and	111b
		ld	h,a
		ld	de,4
		add	ix,de
		ld	a,c
		and	11b
		rst	8
		or	40h
		ld	d,a
		ld	a,h		; Check 40h
		cp	7		; Algorithm == 07h?
		call	z,.do_vol
		ld	a,d
		add	a,4
		rst	8
		ld	d,a
		inc	ix
		ld	a,h		; Check 44h
		cp	5		; Algorithm > 05h?
		call	nc,.do_vol
		ld	a,d
		add	a,4
		ld	d,a
		inc	ix
		rst	8
		ld	a,h		; Check 48h
		cp	4		; Algorithm > 04h?
		call	nc,.do_vol
		ld	a,d
		add	a,4
		ld	d,a
		inc	ix
		call	.do_vol		; Do 4Ch
		pop	ix
		pop	bc
		rst	8
		ret
.do_vol:
		ld	a,(ix)
		add	a,b
		cp	7Fh
		jr	c,.vmuch
		ld	a,7Fh
.vmuch:
		ld	e,a
		bit	2,c
		call	z,fm_send_1
		call	nz,fm_send_2
		ret

; ---------------------------------------------
; FM send registers
;
; Input:
; d - ctrl
; e - data
; ---------------------------------------------

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
; --------------------------------------------------------

dac_play:
		di
		call	dac_off
		exx				; get exx regs
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

; First wave fill
dac_firstfill:
		call	get_tick
		push	af

; Wave refill request
; Got this from GEMS, but I changed it to play
; larger samples (7FFFFFh maximum)
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

; if wav's len-timer finished:
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

; TODO: some of these freqs need checking
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
		dw 03Eh		; C-3 5512
		dw 043h		; C#3
		dw 046h		; D-3
		dw 049h		; D#3
		dw 04Eh		; E-3
		dw 054h		; F-3
		dw 058h		; F#3
		dw 05Eh		; G-3 8363 -17
		dw 063h		; G#3
		dw 068h		; A-3
		dw 070h		; A#3
		dw 075h		; B-3
		dw 085h		; C-4 11025 -12
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
		dw 100h		; C-5 22050
		dw 110h		; C#5
		dw 120h		; D-5
		dw 12Eh		; D#5
		dw 142h		; E-5
		dw 15Ah		; F-5
		dw 16Ah		; F#5 32000 +6
		dw 17Fh		; G-5
		dw 191h		; G#5
		dw 1ACh		; A-5
		dw 1C2h		; A#5
		dw 1E0h		; B-5
		dw 1F8h		; C-6 44100 +12
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
		dw 400h		; C-7 88200
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

; --------------------------------------------------------

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
psgvol		db 00h,00h,00h,00h
fmcom:		db 00h,00h,00h,00h,00h,00h	;  0 - play bits: 2-cut 1-off 0-play
		db 00h,00h,00h,00h,00h,00h	;  6 - keys xxxx0000b
		db 00h,00h,00h,00h,00h,00h	; 12 - volume (for 40h+)
		db 00h,00h,00h,00h,00h,00h	; 18 - panning (%LR000000)
		db 00h,00h,00h,00h,00h,00h	; 24 - A4h+ (MSB FIRST)
		db 00h,00h,00h,00h,00h,00h	; 30 - A0h+
fmins_com:	ds 028h			; Current instrument data for each FM
fmins_com2:	ds 028h
fmins_com3:	ds 028h
fmins_com4:	ds 028h
fmins_com5:	ds 028h
fmins_com6:	ds 028h
fm3reg:		dw 0AC00h,0A800h	; S3-S1, S4 is at A6/A2
		dw 0AD00h,0A900h
		dw 0AE00h,0AA00h
daccom:		db 0			; single byte for key on, off and cut

; ====================================================================
; ----------------------------------------------------------------
; Z80 RAM
; ----------------------------------------------------------------

trkBuff_0	ds 20h+(MAX_TRKCHN*8)	;  *** TRACK BUFFER 0, 100h aligned ****
trkBuff_1	ds 20h+(MAX_TRKCHN*8)	;  *** TRACK BUFFER 1, 100h aligned ****

insDataC_0	ds 8*16		; Instrument data for each Track slot
insDataC_1	ds 8*16		; 8*MAX_INS
currInsData	dw 0
currTblPos	dw 0
currInsPos	dw 0
currTrkCtrl	dw 0
tickFlag	dw 0		; Tick flag from VBlank, Read as (tickFlag+1) for reading/reseting
tickCnt		db 0		; Tick counter (PUT THIS TAG AFTER tickFlag)
wave_Start	dw 0		; START: 68k 24-bit pointer
		db 0
wave_Len	dw 0		; LENGTH 24-bit
		db 0
wave_Loop	dw 0		; LOOP POINT 24-bit (MUST BE BELOW wave_Len)
		db 0
wave_Pitch	dw 0100h	; 01.00h
wave_Flags	db 0		; WAVE playback flags (%10x: 1 loop / 0 no loop)

	; Channel tables: 10h bytes
	; 0  - Link addr (0000h = free, used chnls start from +0020h)
	; 2  - Channel index (ID is set extrenally)
	; 3  - Pitch
	; 4+ - Channel specific...

	; PSG (80h+)
	;  4 - psgNoise mode
tblPSG:		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 1
		db 00h,00h,01h,00h,00h,00h,00h,00h	; Channel 2
		db 00h,00h,02h,00h,00h,00h,00h,00h	; Channel 3
		dw -1	; end-of-list
tblPSGN:	db 00h,00h,03h,00h,00h,00h,00h,00h	; Noise (DIRECT CHECK only)

	; FM: 90h+ FM3: 0A0h DAC: 0B0h
	;  4 - Special mode (FM3: Special, FM6: DAC)
	;  5 - 24-bit copy of ROM instrument pointer
tblFM:		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 1
		db 00h,00h,01h,00h,00h,00h,00h,00h	; Channel 2
		db 00h,00h,03h,00h,00h,00h,00h,00h	; Channel 4
		db 00h,00h,04h,00h,00h,00h,00h,00h	; Channel 5
tblFM3:		db 00h,00h,02h,00h,00h,00h,00h,00h	; Channel 3
tblFM6:		db 00h,00h,05h,00h,00h,00h,00h,00h	; Channel 6
		dw -1	; end-of-list

tblPWM:		db 00h,00h,00h,00h,00h,00h,00h,00h	; Channel 1
		db 00h,00h,01h,00h,00h,00h,00h,00h	; Channel 2
		db 00h,00h,02h,00h,00h,00h,00h,00h	; Channel 3
		db 00h,00h,03h,00h,00h,00h,00h,00h	; Channel 4
		db 00h,00h,04h,00h,00h,00h,00h,00h	; Channel 5
		db 00h,00h,05h,00h,00h,00h,00h,00h	; Channel 6
		db 00h,00h,06h,00h,00h,00h,00h,00h	; Channel 7
		dw -1

	; Format:
	; %00VP0CFO
	; $vp
	; $pp
	; $fi + flags
	; $ii
	; $ii
	; $ii
; 	 align 8
pwmcom:		db 00h,00h,00h,00h,00h,00h,00h,00h	; Playback bits: KeyOn/KeyOff/KeyCut/other update bits
		db 00h,00h,00h,00h,00h,00h,00h,00h	; Volume | Pitch MSB
		db 00h,00h,00h,00h,00h,00h,00h,00h	; Pitch LSB
		db 00h,00h,00h,00h,00h,00h,00h,00h	; Playback flags: Loop/Stereo/Left/Right | 32-bit
		db 00h,00h,00h,00h,00h,00h,00h,00h	; sample location
		db 00h,00h,00h,00h,00h,00h,00h,00h
		db 00h,00h,00h,00h,00h,00h,00h,00h

		org 1C00h
dWaveBuff	ds 100h			; WAVE data buffer: 100h bytes, updates every 80h
trkData_0	ds 100h			; Track note-cache buffers: 100h bytes, updates every 80h
trkData_1	ds 100h
commZfifo	ds 40h			; Buffer for command requests from 68k (40h bytes, loops)
dDacPntr	db 0,0,0		; WAVE play current ROM position
dDacCntr	db 0,0,0		; WAVE play length counter
dDacFifoMid	db 0			; WAVE play halfway refill flag (00h/80h)
psgHatMode	db 0
fmSpcMode	db 0
trkHdOut	ds 6			; temporal Header for reading Track position/row count

; Stack area
