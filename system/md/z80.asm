; --------------------------------------------------------
; GEMA sound driver, inspired by GEMS
;
; WARNING: The sample playback has to be sync'd manually
; on any code change, DAC sample rate is 16000hz base
; --------------------------------------------------------

		cpu Z80			; Set Z80 here
		phase 0			; And set PC to 0

; --------------------------------------------------------
; Structs
;
; NOTE: struct doesn't work properly here. use
; equs instead
; --------------------------------------------------------

; trkBuff struct
; LIMIT: 10h bytes
trk_romBlk	equ 0			; 24-bit base block data
trk_romPatt	equ 3			; 24-bit base patt data
trk_romIns	equ 6			; 24-bit ROM instrument pointers
trk_romPattRd	equ 9			; same but for reading
trk_Read	equ 12			; Current track position (in cache)
trk_Rows	equ 14			; Current track length
trk_Halfway	equ 16			; Only 00h or 80h
trk_currBlk	equ 17			; Current block
trk_setBlk	equ 18			; Start on this block
trk_status	equ 19			; %ERSx xxxx | E-enabled / R-Init or Restart track
					;	       S-sfx mode
trk_tickTmr	equ 20			; Ticks timer
trk_tickSet	equ 21			; Ticks set for this track

; chnBuff
; 8 bytes
chnl_Chip	equ 0			; Channel chip: etti iiii | e-enable t-type i-chip channel
chnl_Type	equ 1			; Current type
chnl_Note	equ 2
chnl_Ins	equ 3
chnl_Vol	equ 4
chnl_EffId	equ 5
chnl_EffArg	equ 6
chnl_Status	equ 7			; 000e uuuu | p-priority overwrite, u-update bits from Tracker

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

MAX_TRKS	equ	2		; Max tracks to read
MAX_TRKCHN	equ	18		; Max internal tracker channels

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

; ====================================================================
; --------------------------------------------------------
; Code starts here
; --------------------------------------------------------

		di			; Disable interrputs
		im	1		; Interrupt mode 1
		ld	sp,2000h	; Set stack at the end of Z80
		jr	z80_init	; Jump to z80_init

; --------------------------------------------------------

wave_Start	dw 0;TEST_WAV&0FFFFh	; START: 68k direct pointer ($00xxxxxx)
		db 0;TEST_WAV>>16&0FFh
wave_Len	dw 0;(TEST_WAV_E-TEST_WAV)&0FFFFh
		db 0;(TEST_WAV_E-TEST_WAV)>>16
wave_Loop	dw 0
		db 0
wave_Pitch	dw 100h			; 01.00h
wave_Flags	db 100b			; WAVE playback flags (%10x: 1 loop / 0 no loop)
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
commZRomRd	db 0			; Z80 is reading ROM bit
psgHatMode	db 0,0,0		; noise mode bits + linked channel
currTblSrch	dw 0
reqSampl	db 0			; DAC play request

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
		call	dac_me
		call	check_tick	; Check for tick on VBlank
		call	dac_fill
		call	dac_me

	; Check for tick and tempo
		ld	b,0		; b - Reset current flags (beat|tick)
		ld	a,(tickCnt)
		sub	1
		jr	c,.noticks
		ld	(tickCnt),a
		call	psg_env		; Process PSG volume and freqs manually
		call	check_tick	; Check for another tick
		ld 	b,01b		; Set TICK (01b) flag, and clear BEAT
.noticks:
		call	dac_me
		ld	a,(sbeatAcc+1)	; check beat counter (scaled by tempo)
		sub	1
		jr	c,.nobeats
		ld	(sbeatAcc+1),a	; 1/24 beat passed.
		set	1,b		; Set BEAT (10b) flag
		call	dac_me
.nobeats:
		ld	a,b
		or	a
		jr	z,.neither
; 		call	dac_me
		ld	(currTickBits),a; Save BEAT/TICK bits
; 		call	doenvelope	; TODO: probably not doing this...
		call	check_tick
		call	playonchip	; Set channels to their respective sound chips
		call	check_tick
		call	updtrack	; Update track data
		call	check_tick
.neither:
; 		call	mars_scomm
; 		call	dac_me

.next_cmd:
		call	dac_fill
		call	dac_me
		ld	a,(commZWrite)
		ld	b,a
		ld	a,(commZRead)
		cp	b
		jp	z,drv_loop
		call	get_cmdbyte
		cp	-1			; Read -1 (Start of command)
		jp	nz,drv_loop
		call	get_cmdbyte		; Read cmd number
		add	a,a
		ld	hl,.list
		ld	d,0
		ld	e,a
		add	hl,de
		call	dac_fill
		call	dac_me
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
		jp	.next_cmd

; --------------------------------------------------------
; $01 - change current wave pitch
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
		or	0C0h			; Set Enable + REFILL flags
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
		call	dac_me
		call	get_cmdbyte	; $00xx
		ld	e,a
		call	get_cmdbyte	; $xx00
		ld	d,a
		push	de
		call	dac_me
		exx
		pop	de
		exx
		jp	drv_loop

; ====================================================================
; ----------------------------------------------------------------
; Sound playback code
; ----------------------------------------------------------------

; --------------------------------------------------------
; Set and play instruments in their respective channels
; --------------------------------------------------------

playonchip
		call	dac_fill
		call	dac_me

	; Play new notes
		ld	c,MAX_TRKS
		ld	hl,insDataC
		ld	(currInsData),hl
		ld	iy,trkBuff+20h		; Point to channels
.nxt_track:
		ld	b,MAX_TRKCHN
		push	iy
.nxt_chnl:
		push	bc
		ld	a,(iy+chnl_Status)
		or	a
		call	nz,.do_chnl
		nop
		nop
		call	dac_me
		pop	bc
		ld	de,8
		add	iy,de
		djnz	.nxt_chnl
		pop	iy
		ld	de,100h
		add	iy,de

		ld	de,80h
		ld	hl,(currInsData)
		add	hl,de
		ld	(currInsData),hl
		dec	c
		jp	nz,.nxt_track

		ld	a,(reqSampl)
		or	a
		ret	z
		xor	a
		ld	(reqSampl),a
		call	dac_play
		ret

; ----------------------------------------
; Channel wants to update
; ----------------------------------------

.do_chnl:
		call	dac_fill
		call	dac_me
		bit	1,(iy+chnl_Status)		; Update instrument first
		call	nz,.req_ins
		bit	2,(iy+chnl_Status)
		call	nz,.req_vol
		call	dac_me
		bit	3,(iy+chnl_Status)
		call	nz,.req_eff
		bit	0,(iy+chnl_Status)
		call	nz,.req_note
		call	dac_me
		ld	a,(iy+chnl_Status)		; clear update flags
		and	11110000b
		ld	(iy+chnl_Status),a
		ret

; ----------------------------------------
; Set new instrument
; ----------------------------------------

.req_eff:
		call	.get_instype
		cp	-1
		ret	z
		cp	0
		ret	z
		cp	1
		ret	z
		cp	2
		jp	z,.fm_eff
		cp	3
		jp	z,.fm_eff
		cp	4
		ret	z
; 		cp	5
; 		jp	z,.pwm_eff
		ret
.fm_eff:
		ld	a,(iy+chnl_EffId)	; Eff X?
		cp	24
		jp	z,.eff_X_fm
		ret
.eff_X_fm:
		call	.srch_fm
		cp	-1
		ret	z
		push	hl
		pop	ix
		ld	a,(iy+chnl_EffArg)
		rlca
		rlca
		and	00000011b
		ld	hl,.fmpan_list
		ld	de,0
		ld	e,a
		add	hl,de
		ld	a,(ix+7)
		and	00111111b
		ld	b,(hl)
		or	b
		ld	(ix+7),a
		ret
.fmpan_list:
		db 01000000b	; 000h
		db 01000000b	; 040h
		db 00000000b	; 080h
		db 10000000b	; 0C0h

; .pwm_eff:
; 		ld	a,(iy+chnl_EffId)	; Eff X?
; 		cp	24
; 		jp	z,.eff_X_pwm
; 		ret
; .eff_X_pwm:
; 		call	.srch_pwm
; 		cp	-1
; 		ret	z
; 		push	hl
; 		pop	ix
; 		ld	a,(iy+chnl_EffArg)
; 		rlca
; 		rlca
; 		and	00000011b
; 		ld	hl,.pwmpan_list
; 		ld	de,0
; 		ld	e,a
; 		add	hl,de
; 		ld	a,(hl)
; 		ld	(ix+7),a
; 		ret
;
; .pwmpan_list:
; 		db 001h		; 000h
; 		db 001h		; 040h
; 		db 003h		; 080h
; 		db 002h		; 0C0h

; ----------------------------------------
; Set new instrument
; ----------------------------------------

.req_ins:
		call	.get_instype
		cp	-1		; Null
		ret	z
		cp	0		; PSG normal
		jr	z,.ins_psg
		cp	1		; PSG noise
		jr	z,.ins_ns
		cp	2		; FM normal
		jr	z,.fm_ins
		cp	3		; FM special
		ret	z
		cp	4		; DAC
		jp	z,.dac_ins
; 		cp	5		; PWM
; 		jp	z,.pwm_ins
		ret

; PSG instrument
.ins_psg:
		push	hl
		call	dac_me
		call	.srch_psg	; Type 0: PSG
		pop	de
		cp	-1
		ret	z
		ld	a,(de)
		ld	c,a
		inc	de
		inc	de
		call	dac_me
		jr	.cont_psg
.ins_ns:
		push	hl
		call	.srch_psgn	; Type 1: PSG Noise
		pop	de
		cp	-1
		ret	z
		ld	a,(hl)
		ld	c,a
		inc	de
		inc	de
		call	dac_me
.cont_psg:
		inc	hl
		inc 	hl
		inc	hl
		call	dac_me
		ld	a,(de)
		ld	b,a
		inc	de
		ld	a,(de)
		inc	de
		push	de
		ld	d,a
		ld	e,b
	rept 5				; copypaste to psduochnl
		ld	a,(de)
 		ld	(hl),a
 		inc	de
		inc	hl
		call	dac_me
		nop
	endm
		pop	de
		ld	a,(de)
		ld	(hl),a
		ret
; Type 2
.fm_ins:
		push	hl
		call	.srch_fm
		cp	-1
		ret	z
		push	hl
		pop	ix
		pop	hl
		call	dac_me
		inc	hl
		ld	a,(hl)
		ld	(ix+5),a
		inc	hl
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		ld	(ix+3),l
		ld	(ix+4),h
		call	dac_me

		ld	a,(ix)		; Keys off
		and	0111b
		ld	e,a
		ld	d,28h
		call	fm_send_1

		ld	a,(ix)		; Prepare first FM reg
		and	11b
		or	30h
		ld	d,a
		ld	b,4*7
.setlv:
		call	dac_me
		ld	e,(hl)
		call	fm_autoset
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		inc	hl
		djnz	.setlv

		ld	a,d
		and	11b
		or	0B0h
		ld	d,a
		ld	e,(hl)			; 0B0h
		ld	(ix+6),e
		call	fm_autoset
		call	dac_me
		inc 	hl
		inc	d
		inc	d
		inc	d
		inc	d

		ld	a,(hl)			; 0B4h
		and	00111111b
		ld	b,a
		ld	a,(ix+7)
		and	11000000b
		or	b
		ld	(ix+7),a
		ld	e,a
		call	dac_me
		call	fm_autoset
		inc	hl			; TODO: FM3 enable bit
		inc	hl
		ld	a,(hl)			; Keys (xxxx0000b)
		ld	(ix+8),a
		ret

; Type 4
.dac_ins:
	; TODO: FM6/DAC LOCK
		inc	hl
		inc	hl
		ld	c,(hl)
		inc	hl
		call	dac_me
		ld	b,(hl)
		inc	hl
		ld	a,(hl)
		or	100b
		ld	(wave_Flags),a

		ld	h,b
		ld	l,c
		ld	de,wave_Start
		ld	b,9
.copybytes:
		ld	a,(hl)
		ld	(de),a
		inc	hl
		inc	de
		call	dac_me
		nop
		nop
		djnz	.copybytes
		ret

; 		jr	$

; Type 5
; .pwm_ins:
; 		push	hl
; 		call	.srch_pwm
; 		cp	-1
; 		ret	z
; 		push	hl
; 		pop	ix
; 		pop	hl
;  		ld	de,
;  		ld	a,(iy+chnl_Ins)
;  		dec	a
;  		ld	(ix+5),a		; put ins number
; 		ret

; ----------------------------------------
; Volume request
; ----------------------------------------

.req_vol:
		call	.get_instype
		cp	-1
		ret	z
		cp	2
		jp	z,.vol_fm
		cp	3
		ret	z
		cp	4
		ret	z
		cp	5
		jp	z,.vol_pwm

	; PSG volume
		cp	1
		jr	nz,.notnsev
		call	.srch_psgn
		jr	.pvcont
.notnsev:
		call	.srch_psg	; Type 0: PSG
.pvcont:
		cp	-1
		ret	z
		inc	hl
		inc 	hl
		inc 	hl		; Point to Attack level
		ld	a,(iy+chnl_Vol)
		sub	a,40h
		add	a,a
		call	dac_me
		ld	b,a
		ld	a,(hl)
		sub	b
		ld	(hl),a
		inc	hl
		inc	hl
		ret

.vol_fm:
		call	.srch_fm
		cp	-1
		ret	z
		push	hl
		pop	ix
		inc	hl
		inc	hl
		inc	hl
		call	dac_me
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a
		ld	de,4
		add	hl,de		; Point to 40h's

	; copy-pasted from PulseMini
	; b - 0B0h
	; c - Volume
		call	dac_fill
		call	dac_me
		ld	a,(iy+chnl_Vol)
		sub	a,40h
		neg	a
		ld	c,a
		ld	a,(ix+6)
		and	111b
		ld	b,a
		ld	d,40h
		ld	a,(ix)
		and	11b
		or	d
		ld	d,a
		call	dac_me
		ld	e,(hl)
		inc 	hl
		ld	a,b
		cp	7
		jp	nz,.tlv_lv1
		ld	a,e
		add 	a,c
		ld	e,a
		or	a
		jp	p,.tlv_lv1
		ld	e,7Fh
.tlv_lv1:
		call	fm_autoset
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		call	dac_me
		ld	e,(hl)
		ld	a,b
		cp	7
		jp	z,.tlv_lv2_ok
		cp	6
		jp	z,.tlv_lv2_ok
		cp	5
		jp	nz,.tlv_lv2
		call	dac_me
.tlv_lv2_ok:
		ld	a,e
		add 	a,c
		ld	e,a
		or	a
		jp	p,.tlv_lv2
		ld	e,7Fh
.tlv_lv2:
		call	fm_autoset
		inc 	hl
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		call	dac_me
		ld	e,(hl)
		ld	a,b
		and	100b
		or	a
		jp	z,.tlv_lv3
		ld	a,e
		add 	a,c
		ld	e,a
		or	a
		jp	p,.tlv_lv3
		call	dac_me
		ld	a,7Fh
.tlv_lv3:
		call	fm_autoset
		inc 	hl
		inc 	d
		inc 	d
		inc 	d
		inc 	d
		call	dac_me
		ld	a,(hl)
		add 	a,c
		or	a
		jp	p,.tlv_lv4
		ld	a,7Fh
.tlv_lv4:
		ld	e,a
		inc 	hl
		call	fm_autoset
		ret

; Type 5
.vol_pwm:
		push	hl
		call	.srch_pwm
		cp	-1
		ret	z
		push	hl
		pop	ix
		pop	hl
 		ld	de,
 		ld	a,(iy+chnl_Vol)
		sub	a,40h
		neg	a
; 		add	a,a
 		ld	(ix+6),a		; put vol number
		ret

; ----------------------------------------
; Note request
; ----------------------------------------

.req_note:
		call	.get_instype
		cp	-1
		ret	z
		cp	2
		jp	z,.note_fm
		cp	3
		jp	z,.note_fm3
		cp	4
		jp	z,.note_dac
		cp	5
		jp	z,.note_pwm
		call	dac_me
		inc	hl
		ld	c,(hl)
		push	bc

	; PSG mode 0 and 1
		cp	1
		jr	nz,.notnse
		call	.srch_psgn
		jr	.pncont
.notnse:
		call	.srch_psg	; Type 0: PSG
.pncont:
		cp	-1
		ret	z
		ld	a,(hl)		; Get pseudo channel slot
		cp	-1
		ret	z
		pop	bc
		push	hl		; save this hl
		and	11b
		call	dac_me
		ld	ix,psgcom
		ld	de,0
		ld	e,a
		add	ix,de
		ld	de,0		; Read freq
		ld	a,(iy+chnl_Note)
		cp	-2
		jp	z,.pstop
		cp	-1
		jp	z,.poff
		add	a,c
		ld	hl,psgFreq_List
		add	a,a
		ld	e,a
		add	hl,de
		call	dac_me
		ld	a,(hl)
		and	0Fh
		ld	(ix+DTL),a
		ld	a,(hl)
		sra	a
		sra	a
		sra	a
		sra	a
		and	0Fh
		call	dac_me
		ld	b,a
		inc	hl
		ld	a,(hl)
		sla	a
		sla	a
		sla	a
		sla	a
		and	0F0h
		or	b
		call	dac_me
		ld	(ix+DTH),a
		pop	hl		; get hl back
		ld	b,(hl)
		inc	hl
		inc	hl
		inc 	hl		; Point to our PSG ins data
		ld	a,(hl)
		inc	hl
		ld	(ix+ALV),a	; attack level
		ld	a,(hl)
		inc	hl
		call	dac_me
		ld	(ix+ATK),a	; attack rate
		ld	a,(hl)
		inc	hl
		ld	(ix+SLV),a	; sustain
		ld	a,(hl)
		inc	hl
		ld	(ix+DKY),a	; decay rate
		ld	a,(hl)
		inc	hl
		ld	(ix+RRT),a	; release rate
		ld	a,b
		and	10000011b
		ld	(iy+chnl_Chip),a
		call	dac_me
		and	11b
		cp	2
		jp	z,.psgchnl3
		cp	3
		jp	nz,.normlpsg
		ld	de,psgHatMode	; if chnl uses NOISE
		ld	a,(hl)
		push	iy
		pop	hl
		ld	c,a
		ld	(de),a		; NOISE mode
		inc	de
		ld	a,l
		ld	(de),a
		call	dac_me
		inc 	de
		ld	a,h
		ld	(de),a
		ld	a,c		; Auto-silence PSG3
		and	11b		; is Tone3 is active
		cp	3
		jp	nz,.normlpsg
		ld	a,100b		; Send stop com directly
		ld	(psgcom+2),a	; To PSG3
		jr	.normlpsg
	; if chnl uses PSG3
.psgchnl3:
		ld	a,(psgHatMode)
		and	11b
		cp	11b
		ret	z
		call	dac_me
.normlpsg:
		ld	(ix+COM),001b	; Key on.
		ret
; full stop
.pstop:
		pop	hl
		ld	a,(hl)		; Unlock this channel
		and	07Fh
		ld	(hl),a
		inc 	hl
		ld	(hl),0
		call	dac_me
		inc 	hl
		ld	(hl),0
		inc 	hl
		ld	(ix+COM),100b	; Full stop
		ld	(iy+chnl_Chip),0
		ret
; key off
.poff:
		pop	hl
		ld	a,(hl)		; unlock this channel
		and	07Fh
		ld	(hl),a
		inc 	hl
		ld	(hl),0
		call	dac_me
		inc 	hl
		ld	(hl),0
		inc 	hl
		ld	(ix+COM),010b	; Key off ===
		ld	(iy+chnl_Chip),0
		ret

; ----------------------------------------
; FM
; ----------------------------------------

.note_fm:
		call	.srch_fm
		cp	-1
		ret	z
		push	hl
		pop	ix
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		call	dac_fill
		call	dac_me

		ld	a,(ix)		; Keys off
		and	10000111b
		or	00100000b	; Mark as FM
		ld	(iy+chnl_Chip),a

		ld	a,(iy+chnl_Note)
		cp	-1		; Key off.
		jp	z,.keyoff
		cp	-2		; TODO: Total level force off
		jp	z,.keyoff
		ld	b,(ix+5)
		add	a,b
		ld	b,0
	rept 7				; Separate notedata as octave(b) and note(c)
		call	dac_me
		ld	c,a
		sub	12
		or	a
		jp	m,.getoct
		inc	b
	endm
.getoct:
		call	dac_me
		ld	de,0
		ld	a,(ix)
		and	11b
		or	0A4h
		ld	d,a
		ld	a,c		; c - Note
		add	a,a
		ld	c,a
		ld	a,b
		add	a,a
		add	a,a
		add	a,a		; a - Octave
		ld	b,0
		call	dac_me
		ld	hl,fmFreq_List
		add	hl,bc
		inc	hl
		ld	e,a
		ld	a,(hl)
		or	e
		ld	e,a
		ld	(ix+9),a
		call	fm_autoset
		call	dac_me
		dec	d
		dec	d
		dec	d
		dec	d
		dec	hl
		ld	e,(hl)
		ld	(ix+10),e
		call	fm_autoset
		ld	a,(ix)		; 0B4h
		and	111b
		ld	d,0B4h
		or	d
		ld	d,a

		ld	a,(ix+7)
		ld	c,a
		and	00111111b
		ld	e,a
		ld	a,c
		cpl
		and	11000000b
		or	e
		ld	e,a

		call	fm_autoset
		call	dac_me
		ld	a,(ix)		; Keys
		and	111b
		ld	e,(ix+8)
		or	e
		ld	e,a
		ld	d,28h
		call	fm_send_1
		ret
.note_fm3:
		ret

.keyoff:
		ld	a,(ix)		; Keys off
		and	111b
		ld	e,a
		ld	d,28h
		jp	fm_send_1

.note_dac:
	; TODO: FM6/DAC LOCK
		ld	hl,100h		; temporal.
		ld	(wave_Pitch),hl
		ld	a,1
		ld	(reqSampl),a
		ret

; ----------------------------------------
; PWM
; ----------------------------------------

.note_pwm:
; 		push	hl
; 		call	.srch_pwm
; 		push	hl
; 		pop	ix
; 		pop	hl
; 		inc	hl
;
; 		call	dac_me
; 		ld	a,(iy+chnl_Note)
; 		cp	-1
; 		jr	z,.pwm_stop
; 		cp	-2
; 		jr	z,.pwm_stop
; 		ld	l,(hl)
; 		call	dac_me
; 		add	a,l
; 		add	a,a
; 		ld	de,0
; 		ld	e,a
; 		ld	hl,wavFreq_Pwm
; 		add	hl,de
; 		ld	a,(hl)
; 		ld	(ix+3),a	; NOTE: big endian
; 		inc	hl
; 		ld	a,(hl)
; 		ld	(ix+4),a
;
; 		ld	a,(ix)		; Tell SH2 we want to play channel
; 		or	01000000b
; 		ld	(ix),a
; 		ret
; .pwm_stop:
; 		ld	a,(ix)		; Tell SH2 to stop this channel
; 		or	00100000b
; 		ld	(ix),a
		ret

; ----------------------------------------
; Check the current instrument type
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

.get_instype:
		ld	a,(iy+chnl_Ins)
		dec	a
		add	a,a
		add	a,a
		add	a,a
		call	dac_me
		ld	hl,(currInsData)
		ld	de,0
		ld	e,a
		add	hl,de
		ld	a,(hl)		; check type
		ret

; ----------------------------------------

.srch_psgn:
		ld	de,9
		ld	hl,PSGNVTBL
		jr	.srch_chnltbl
.srch_psg:
		ld	de,9
		ld	hl,PSGVTBL
		jr	.srch_chnltbl
.srch_fm:
		ld	de,17
		ld	hl,FMVTBL
		jr	.srch_chnltbl
.srch_fm3:
		ld	de,17		; TODO: don't autosearch this
		ld	hl,FM3VTBL
		jr	.srch_chnltbl
.srch_fm6:
		ld	de,17		; TODO: same thing
		ld	hl,FM6VTBL
		jr	.srch_chnltbl
.srch_pwm:
		ld	de,8
		ld	hl,PWMVTBL
		jr	.srch_chnltbl

; ----------------------------------------

.psgvoltbl:
		db 0F0h
		db 0F0h
		db 0E0h
		db 0D0h
		db 0C0h
		db 0B0h
		db 0A0h
		db 090h
		db 080h
		db 070h
		db 060h
		db 050h
		db 040h
		db 030h
		db 020h
		db 010h
		db 000h

; ----------------------------------------
; iy - track channel data
; de - Slot incrm
; hl - table
;
; Returns
; a  - Status: -1: error
;               0: ok
; hl - slot
; ----------------------------------------

.srch_chnltbl:
		call	dac_fill
		ld	(currTblSrch),hl	; save base hl
		push	iy
		pop	bc
; first search:
; check for linked track channel
.l_lp:
		call	dac_me
		ld	a,(hl)
		cp	-1
		jp	z,.nolnk
		inc	hl
		inc	hl
		ld	a,(hl)
		dec	hl
		dec	hl
		cp	b
		jr	nz,.ngood
		call	dac_me
		nop
		inc	hl
		ld	a,(hl)
		dec	hl
		cp	c
		jp	z,.setgood
.ngood:					; if it's ours, use it
		add	hl,de
		jr	.l_lp

.nolnk:
		ld	hl,(currTblSrch)

; second search:
; assign current track channel to a
; new sound channel
.f_lp:
		ld	a,(hl)
		cp	-1
		ret	z
		call	dac_me
		ld	a,(hl)
		or	a
		jp	p,.newp
		add	hl,de
		jr	.f_lp
.newp:
		ld	a,(hl)		; lock this channel
		or	80h
		ld	(hl),a
		inc	hl
		ld	(hl),c		; set owner LSB
		inc	hl
		ld	(hl),b		; and MSB
		dec	hl
		dec	hl
		call	dac_me
.setgood:
		xor	a
		ret

; --------------------------------------------------------
; Read track data
; --------------------------------------------------------

updtrack:
		call	dac_me
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
		call	dac_me

	; Next blocks
		ld	de,100h
		add	iy,de
		ld	hl,(currTrkData)
		add	hl,de
		ld	(currTrkData),hl
		ld	de,100h
		ld	hl,(currTrkBlkHd)
		add	hl,de
		call	dac_me
		ld	(currTrkBlkHd),hl
		ld	de,80h
		ld	hl,(currInsData)
		add	hl,de
		ld	(currInsData),hl
		djnz	.next
		ret

; ----------------------------------------
; Read current track
; ----------------------------------------

.read_track:
		call	dac_me
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
		ld	(iy+trk_tickTmr),a	; If 0, we can progress
		or	a
		ret	nz
		ld	a,(iy+trk_tickSet)	; Set new tick timer
		ld	(iy+trk_tickTmr),a
		call	dac_me
		ld	l,(iy+trk_Read)		; hl - Pattern data to read in cache
		ld	h,(iy+((trk_Read+1)))
		ld	c,(iy+trk_Rows)		; Check if this pattern finished
		ld	b,(iy+(trk_Rows+1))
		ld	a,c
		or	b
		call	z,.next_track
		call	dac_me

; --------------------------------
; Main reading loop
; --------------------------------

.next_note:
		ld	a,(hl)			; Check if timer or note
		or	a
		jp	z,.exit			; If == 00h: exit
		jp	m,.is_note		; If 80h-0FFh: note data, 01h-7Fh: timer
		ld	a,(hl)			; Countdown
		dec	a
		ld	(hl),a
		call	dac_me
		jp	.decrow
.is_note:
		push	bc
		ld	c,a			; c - Copy of control+channel
		call	.inc_cpatt
		ld	a,c
		push	iy
		pop	ix
		ld	de,20h
		add	ix,de
		call	dac_me
		ld 	d,0
		and	00111111b
		add	a,a			; * 8
		add	a,a
		add	a,a
		ld	e,a
		add	ix,de
; 		ld	a,c
; 		and	00111111b
; 		inc	a
; 		ld	(ix+chnl_Chip),a
		call	dac_me
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
		call	dac_me
		bit	0,b
		jp	z,.no_note
		ld	a,(hl)
		ld	(ix+chnl_Note),a
		call	.inc_cpatt
.no_note:
; 		call	dac_me
		bit	1,b
		jp	z,.no_ins
		ld	a,(hl)
		ld	(ix+chnl_Ins),a
		call	.inc_cpatt
.no_ins:
; 		call	dac_me
		bit	2,b
		jp	z,.no_vol
		ld	a,(hl)
		ld	(ix+chnl_Vol),a
		call	.inc_cpatt
.no_vol:
; 		call	dac_me
		bit	3,b
		jp	z,.no_eff
		ld	a,(hl)
		ld	(ix+chnl_EffId),a
		call	.inc_cpatt
		ld	a,(hl)
		ld	(ix+chnl_EffArg),a
		call	.inc_cpatt
.no_eff:
		call	dac_me
		ld	a,b			; Merge recycle bits to main bits
		srl	a
		srl	a
		srl	a
		srl	a
		and	1111b
		call	dac_me
		ld	c,a
		ld	a,b
		and	1111b
		or	c
		ld	c,a
		call	dac_me
		ld	a,(ix+chnl_Status)
		or	c
		ld	(ix+chnl_Status),a
		pop	bc

	; Special checks
		or	a
		jp	z,.no_updst
; 		cp	-2
; 		jp	z,.id_off
; 		cp	-1
; 		jp	nz,.id_stlon
; .id_off:
; 		ld	(ix+chnl_Chip),0
; .id_stlon:
		ld	a,(ix+chnl_EffId)
		cp	2			; Effect B: position jump?
		call	z,.eff_B
.no_updst:
		call	dac_fill
		call	dac_me
		jp	.next_note

; --------------------------------
; Exit
; --------------------------------

.exit:
		call	.inc_cpatt
		ld	(iy+trk_Read),l		; Update read location
		ld	(iy+((trk_Read+1))),h
.decrow:
		call	dac_me
		dec	bc			; Decrement this row
		ld	(iy+trk_Rows),c		; And update it
		ld	(iy+(trk_Rows+1)),b
		ret

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
		call	dac_me
		push	hl
		push	bc
		ld	d,h
		ld	a,(iy+trk_Halfway)
		ld	e,a
		add 	a,080h
		ld	(iy+trk_Halfway),a
		ld	bc,80h
		ld	l,(iy+trk_romPattRd)
		call	dac_me
		ld	h,(iy+(trk_romPattRd+1))
		ld	a,(iy+(trk_romPattRd+2))
		add	hl,bc
		adc	a,0
		ld	(iy+trk_romPattRd),l
		ld	(iy+(trk_romPattRd+1)),h
		ld	(iy+(trk_romPattRd+2)),a
		call	transferRom
		call	dac_me
		pop	bc
		pop	hl
		ret

; ----------------------------------------
; If effect B: jump to the block
; requested by the effect
; ----------------------------------------

.eff_B:
		ld	a,(ix+chnl_EffArg)
		ld 	(iy+trk_currBlk),a
		push	iy			; Clear all channels first
		pop	ix
		ld	de,20h
		add	ix,de
		ld	de,8
		xor	a
		ld	b,MAX_TRKCHN*8/2
.clrf2:
		ld	(ix),a
		inc	ix
		call	dac_me
		nop
		ld	(ix),a
		inc	ix
		djnz	.clrf2
		nop
		nop
		call	dac_me
		ld	a,(iy+trk_currBlk)
		jr	.set_track

; ----------------------------------------
; If pattern finished, load the next one
; ----------------------------------------

.next_track:
		ld	a,(iy+trk_currBlk)
		inc	a
		ld 	(iy+trk_currBlk),a

.set_track:
		call	dac_me
		ld	l,80h			; Set LSB as 40h
		ld	(iy+trk_Read),l
		push	hl
		call	dac_me
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
		ld	hl,(currTrkBlkHd)	; Header section
		call	dac_me
		ld	de,80h
		add	hl,de
		add	a,a
		add	a,a
		ld	e,a			; block * 4
		add	hl,de
		ld	c,(hl)
		inc	hl
		ld	b,(hl)			; bc - numof Rows
		inc	hl
		call	dac_me
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
		call	dac_fill
		call	transferRom
		call	dac_me
		ld	h,(iy+(trk_Read+1))
		ld	l,(iy+trk_Read)
		ld	c,(iy+trk_Rows)		; Check if this pattern finished
		ld	b,(iy+(trk_Rows+1))
		call	dac_me
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
		ld	(ix),a
		add	ix,de
		djnz	.clrfe
		call	dac_me
		ld	(iy+trk_status),0
		ret

; ----------------------------------------
; Playing first time
; Load Blocks/Pointers for 3 of 4 sections
; of pattern data, the remaining one is
; loaded after returning.
; ----------------------------------------

.first_fill:
		call	dac_fill
		call	dac_me
		res	6,b			; Reset FILL flag
		ld	(iy+trk_status),b

	; Stop last used sound chips
		push	iy
		pop	ix
		ld	de,20h
		add	ix,de
		ld	de,8
		ld	b,MAX_TRKCHN
.clrf:
		push	de
		ld	a,(ix+chnl_Chip)
		or	a
		call	nz,.silnc_chip
		ld	(ix+chnl_Note),-2
		ld	(ix+chnl_Status),11b
		pop	de
		add	ix,de
		djnz	.clrf

	; TODO: psgHat lock check
		xor	a
; 		ld	hl,psgHatMode+1
; 		ld	e,(hl)
; 		inc	hl
; 		ld	d,(hl)
; 		dec	hl
; 		dec	hl
; 		ld	a,(de)
; 		or	a
; 		jp	nz,.inuse
		ld	(psgHatMode),a		; already in use
; .inuse:

		ld	a,(iy+trk_setBlk)
		ld 	(iy+trk_currBlk),a
		ld	(iy+trk_Halfway),a	; Reset halfway
		call	dac_fill
		call	dac_me
		ld	l,(iy+trk_romIns)	; Recieve 80h of instrument pointers
		ld	h,(iy+(trk_romIns+1))
		ld	a,(iy+(trk_romIns+2))
		ld	de,(currInsData)
; 		ld	(reqMarsTrnf),de	; Tell 68k to copy instruments
		ld	bc,080h
		call	transferRom

		ld	l,(iy+trk_romBlk)	; Recieve 80h of block data
		ld	h,(iy+(trk_romBlk+1))
		ld	a,(iy+(trk_romBlk+2))
		ld	de,(currTrkBlkHd)
		ld	bc,80h
		push	de
		call	transferRom
		pop	de
		call	dac_fill
		call	dac_me
		ld	a,e
		add	a,80h
		ld	e,a
		ld	l,(iy+trk_romPatt)	; Recieve 80h of header data
		ld	h,(iy+(trk_romPatt+1))
		ld	a,(iy+(trk_romPatt+2))
		ld	bc,80h
		call	transferRom
		ld	a,0
		ld	hl,(currTrkBlkHd)	; Block section
		ld	de,0
		ld	e,a
		add	hl,de
		ld	a,(hl)			; a - block
		cp	-1
		jp	z,.track_end
		call	dac_fill
		call	dac_me
		ld	hl,(currTrkBlkHd)	; Header section
		ld	de,80h
		add	hl,de
		add	a,a
		add	a,a
		ld	e,a			; block * 4
		add	hl,de
		ld	c,(hl)
		inc	hl
		ld	b,(hl)			; bc - numof Rows
		inc	hl
		ld	e,(hl)
		inc	hl
		ld	d,(hl)			; de - pointer (base+increment by this)
		ld	(iy+trk_Rows),c		; Save this number of rows
		ld	(iy+(trk_Rows+1)),b
		call	dac_me
		ld	l,(iy+trk_romPatt)	; hl - Low and Mid pointer of ROM patt data
		ld	h,(iy+(trk_romPatt+1))
		ld	a,(iy+(trk_romPatt+2))
		add	hl,de			; increment to get new pointer
		adc	a,0			; and highest byte too.
		ld	(iy+trk_romPattRd),l	; Save copy of the pointer
		ld	(iy+(trk_romPattRd+1)),h
		ld	(iy+(trk_romPattRd+2)),a
		ld	de,(currTrkData)	; Set new Read point to this track
		ld	b,a
		ld	a,e
		add	a,80h
		ld	e,a
		ld	a,b
		ld	(iy+trk_Read),e
		ld	(iy+((trk_Read+1))),d
		ld	bc,080h			; fill sections 2,3,4
		call	dac_fill
		call	dac_me
		call	transferRom
		ret

; c - Chip
; PSG: 80h
; FM:  A0h + fm key
; PWM: C0h

.silnc_chip:
		ld	c,a
		and	01100000b	; Get curr used chip
		cp	00100000b	; FM?
		jr	z,.sil_fm
		cp	01000000b	; PWM?
		ret	z

	; chip ID: 00b
		ld	hl,PSGNVTBL	; Check for NOISE
		ld	de,9
		call	.chlst_unlk
		and	83h
		cp	83h
		jp	z,.unlknow
		ld	hl,PSGVTBL
		ld	de,9
		call	.chlst_unlk
		cp	-1
		jp	nz,.unlknow
		ret
.unlknow:
		ld	a,(hl)
		and	7Fh
		ld	(hl),a
		inc	hl		; delete link
		ld	(hl),0
		inc	hl
		ld	(hl),0
		inc	hl		; ALV to 0
		ld	(hl),0
		inc	hl		; ATK to 0
		ld	(hl),0
		ld	a,c
		and	11b

		ld	hl,psgcom
		ld	de,0
		ld	e,a
		add	hl,de
		ld	(hl),100b
		ret

; FM silence
.sil_fm:
		ld	a,c
		and	10000111b
		ld	c,a
		ld	de,17
		ld	hl,FMVTBL
		call	.chlst_unlk
		ld	a,c
		and	11b
		ld	d,40h
		or	d
		ld	d,a
		ld	e,7Fh
		call	fm_autoset		; ix is already our channel
		inc	d
		inc	d
		inc	d
		inc	d
		call	fm_autoset
		inc	d
		inc	d
		inc	d
		inc	d
		call	fm_autoset
		inc	d
		inc	d
		inc	d
		inc	d
		call	fm_autoset
		ld	a,c
		and	111b
		ld	e,a
		ld	d,28h
		call	fm_send_1
		ld	de,2800h
		ld	a,c
		and	111b
		or	e
		ld	e,a
		jp	fm_send_1
.chlst_unlk:
		ld	a,(hl)
		cp	-1
		ret	z
		cp	c
		ret	z
		add	hl,de
		jr	.chlst_unlk

; ; --------------------------------------------------------
; ; For 32X only:
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
; 		call	dac_me
; 		add	iy,de
; 		djnz	.next
;
; ; 	; All this code just to tell SH2
; ; 	; to update PWM list...
; ; 		call	dac_me
; ; 		ld	hl,6000h		; Set bank
; ; 		ld	(hl),0
; ; 		ld	(hl),1
; ; 		ld	(hl),0
; ; 		ld	(hl),0
; ; 		ld	(hl),0
; ; 		ld	(hl),0
; ; 		ld	(hl),1
; ; 		call	dac_me
; ; 		ld	(hl),0
; ; 		ld	(hl),1
; ; 		ld	ix,5100h|8000h		; ix - mars sysreg
; ; .wait_md:	ld	a,(ix+comm8)		; 68k got it first?
; ; 		or	a
; ; 		jp	nz,.wait_md
; ; 		call	dac_me
; ; 		ld	(ix+comm4),20h		; Z80 ready
; ; 		ld	(ix+3),01b		; Master CMD interrupt
; ; .wait_cmd:	bit	0,(ix+3)		; CMD clear?
; ; 		jp	nz,.wait_cmd
; ; 		call	dac_me
; 		ret
;
; ; bit 6
; .play:
; 		ld	a,(iy)
; 		and	00001111b
; 		inc	a
; 		ld	c,a
; 		call	dac_me
; 		push	iy
; 		pop	hl
; 		ld	b,8/2
; 		call	mars_zcomm
; 		ld	a,(iy)
; 		and	10011111b
; 		ld	(iy),a
; 		ret

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
; Read cmd byte, auto re-aligns to 7Fh
; --------------------------------------------------------

get_cmdbyte:
		push	bc
		push	de
		push	hl
.getcbytel:
		call	dac_me
		call	dac_fill
		ld	a,(commZWrite)
		ld	b,a
		ld	a,(commZRead)
		cp	b
		jp	z,.getcbytel		; wait for a command from 68k
		ld	b,0
		ld	c,a
		ld	hl,commZfifo
		call	dac_me
		add	hl,bc
		inc	a
		and	3Fh			; limit to 128
		ld	(commZRead),a
		ld	a,(hl)
		pop	hl
		pop	de
		pop	bc
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
		call	dac_me
		push	de
		ld	hl,(sbeatAcc)		; Increment subbeats
		ld	de,(sbeatPtck)
		call	dac_me
		add	hl,de
		ld	(sbeatAcc),hl
		pop	de
		call	dac_me
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

set_tempo:
		ld	de,218
		call	do_multiply
		xor	a
		sla	l
		rl	h
		rla			; AH <- sbpt, 8 fracs
		ld	l,h
		ld	h,a		; HL <- AH
		ld	(sbeatPtck),hl
		ret

; ---------------------------------------------
; do_multiply
;
; Input:
; hl - Start from
; de - Multply by this
; ---------------------------------------------

; 			      ; GETPATPTR
; 			      ; 		ld	HL,PATCHDATA
; 	dc.b	$21,$86,$18
; 			      ; 		ld	DE,39
; 	dc.b	$11,$27,$00
; 			      ; 		jr	MULADD
; 	dc.b	$18,$03

do_multiply:
		ld	hl,0
.mul_add:
		srl	a
		jr	nc,.mulbitclr
		add	hl,de
.mulbitclr:
		ret	z
		sla	e		; if more bits still set in A, DE*=2 and loop
		rl	d
		jr	.mul_add

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
; WAV sample data, just to be safe
; --------------------------------------------------------

; TODO: check if I can improve this

transferRom:
		call	dac_me
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
		call	dac_me
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
		call	dac_me
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
		call	dac_me
		push	de
		ld	de,6000h
		ld	a,h
		rlc	a
		ld	(de),a
		ld	a,b
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		call	dac_me
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		rra
		ld	(de),a
		pop	de
		set	7,h
		call	dac_me

	; Transfer data in parts of 3bytes
	; while playing cache'd WAV in the process
		ld	a,c
		ld	b,0
		set	0,(ix+1)	; Tell to 68k that we are reading from ROM
		sub	a,3
		jr	c,.x68klast
.x68kloop:
		ld	c,3-1
		bit	0,(ix)		; If 68k requested ROM block from here
		jr	nz,.x68klpwt
.x68klpcont:
		ldir
		nop
		call	dac_me
		nop
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
		call	dac_me
		res	0,(ix+1)
		ret

; If Genesis wants to do a DMA job...
; This MIGHT cause the DAC to ran out of sample data
.x68klpwt:
		res	0,(ix+1)		; Not reading ROM
.x68kpwtlp:
		nop
		call	dac_me
		nop
		bit	0,(ix)			; Is ROM free from 68K?
		jr	nz,.x68kpwtlp
		set	0,(ix+1)		; Reading ROM again.
		jr	.x68klpcont

; For last write
.x68klstwt:
		res	0,(ix+1)		; Not reading ROM
.x68klstwtlp:
		nop
		call	dac_me
		nop
		bit	0,(ix)			; Is ROM free from 68K?
		jr	nz,.x68klstwtlp
		set	0,(ix+1)		; Reading ROM again.
		jr	.x68klstcont

; --------------------------------------------------------
; bruteforce DAC ON/OFF playback
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
; psg_env
;
; Processes the PSG manually to add effects
; --------------------------------------------------------

psg_env:
	; NOTE: this now reads backwards, because
	; of the HAT mode check
		ld	iy,psgcom+3
		ld	hl,Zpsg_ctrl
		ld	d,0E0h			; PSG first ctrl command
		ld	e,4			; 4 channels
.vloop:
		call	dac_me
		ld	c,(iy+COM)		; c - current command
		ld	(iy+COM),0
		bit	2,c			; bit 2 - stop sound
		jr	z,.ckof
		ld	(iy+LEV),-1		; reset level
		ld	(iy+FLG),1		; and update
		ld	(iy+MODE),0		; envelope off
; 		ld	a,4			; PSG Channel 3?
; 		cp	e
; 		jr	nz,.ckof
; 		nop
; 		res	5,(ix)			; Unlock PSG3
.ckof:
		bit	1,c			; bit 1 - key off
		jr      z,.ckon
		ld	a,(iy+MODE)		; mode 0?
		or	a
		jr	z,.ckon
		ld	(iy+FLG),1		; psg update flag
		ld	(iy+MODE),100b		; set envelope mode 100b
.ckon:
		bit	0,c			; bit 0 - key on
		jr	z,.envproc
		ld	(iy+LEV),-1		; reset level
		ld	a,(psgHatMode)		; check if using tone3 mode.
		ld	c,a
		and	11b
		cp	11b
		jp	z,.tnmode
.wrfreq:
		ld	a,e
		cp	4
		jp	z,.sethat
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
		jp	z,.nskip
		jr	.wrfreq
.psteal:
		ld	a,(iy+DTL)		; Steal PSG3's freq
		or	0C0h
		ld	(hl),a
		ld	a,(iy+DTH)
		ld	(hl),a
.sethat:
		ld	a,(psgHatMode)		; write hat mode only.
		or	d
		ld	(hl),a
.nskip:
		ld	(iy+FLG),1		; psg update flag
		ld	(iy+MODE),001b		; set to attack mode

; ----------------------------
; Process effects
; ----------------------------

.envproc:
		call	dac_me
		ld	a,(iy+MODE)
		or	a			; no modes
		jp	z,.vedlp
		cp 	001b			; Attack mode
		jr	nz,.chk2
		ld	(iy+FLG),1		; psg update flag
		ld	a,(iy+LEV)		; a - current level (volume)
		ld	b,(iy+ALV)		; b - attack level
		sub	a,(iy+ATK)		; (attack rate) - (level)
		jr	c,.atkend		; if carry: already finished
		jr	z,.atkend		; if zero: no attack rate
		cp	b			; attack rate == level?
		jr	c,.atkend
		jr	z,.atkend
		ld	(iy+LEV),a		; set new level
		jp	.vedlp
.atkend:
		ld	(iy+LEV),b		; attack level = new level
		ld	(iy+MODE),2		; set to decay mode
		jp	.vedlp
.chk2:

		cp	010b			; Decay mode
		jp	nz,.chk4
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
		ld	a,4			; PSG Channel 3?
		cp	e
		jr	nz,.vedlp
; 		res	5,(ix)			; Unlock PSG3
.vedlp:
		dec	iy			; next COM to check
		ld	a,d
		sub	a,20h
		ld	d,a
		dec	e
		jp	nz,.vloop

	; ----------------------------
	; Set final volumes
		call	dac_me
		ld	iy,psgcom
		ld	ix,Zpsg_ctrl
		ld	hl,90h		; Channel + volumeset bit
		ld	de,20h		; next channel increment
		ld	b,4
.nextpsg:
		bit	0,(iy+FLG)	; PSG update?
		jr	z,.flgoff
		ld	(iy+FLG),0	; Reset until next one
		ld	a,(iy+LEV)	; a - Level
		srl	a		; (Level >> 4)
		srl	a
		srl	a
		srl	a
		or	l		; merge Channel bits
		ld	(ix),a		; Write volume
.flgoff:
		add	hl,de		; next channel
		inc	iy		; next com
		djnz	.nextpsg
		call	dac_me
		ret

; ; --------------------------------------------------------
; ; Communicate to 32X from here
; ; hl - Data to transfer
; ; b - WORDS to transfer
; ; c - Task id
; ;
; ; Uses comm4/comm6
; ; --------------------------------------------------------
;
; mars_zcomm:
; 		call	dac_me
; 		push	hl
; 		ld	hl,6000h		; Set bank
; 		ld	(hl),0
; 		ld	(hl),1
; 		ld	(hl),0
; 		ld	(hl),0
; 		ld	(hl),0
; 		ld	(hl),0
; 		ld	(hl),1
; 		call	dac_me
; 		ld	(hl),0
; 		ld	(hl),1
; 		pop	hl
; 		ld	ix,5100h|8000h		; ix - mars sysreg
; .wait_md:	ld	a,(ix+comm8)		; 68k got it first?
; 		or	a
; 		jp	nz,.wait_md
; .wait_md2:	ld	a,(ix+comm4+1)		; busy?
; 		or	a
; 		jp	m,.wait_md2
; 		call	dac_me
; 		ld	(ix+comm4),c		; Z80 ready
; 		ld	(ix+(comm4+1)),1	; SH busy
; 		ld	(ix+3),01b		; Master CMD interrupt
; .wait_cmd:	bit	0,(ix+3)		; CMD clear?
; 		jp	nz,.wait_cmd
; 		call	dac_me
; .loop:
; 		call	dac_me
; 		ld	a,(ix+(comm4+1))	; SH ready?
; 		cp	2
; 		jr	nz,.loop
; 		ld	a,(ix+(comm4+1))	; SH ready?
; 		cp	2
; 		jr	nz,.loop
; 		ld	a,c			; Z80 is busy
; 		or	80h
; 		ld	(ix+comm4),a
; 		call	dac_me
; 		ld	a,b			; check b
; 		or	a
; 		jr	z,.exit
; 		jp	m,.exit
; 		ld	a,(hl)
; 		ld	(ix+comm6),a
; 		call	dac_me
; 		inc	hl
; 		ld	a,(hl)
; 		ld	(ix+comm6+1),a
; 		inc	hl
; 		call	dac_me
; 		ld	a,c			; Z80 is ready
; 		or	40h
; 		ld	(ix+comm4),a
; 		dec	b
; 		jr	.loop
; .exit:
; 		ld	(ix+comm4),0		; Z80 finished
; 		ret

; ---------------------------------------------
; FM send registers
;
; Input:
; d - ctrl
; e - data
; ---------------------------------------------

; ix - first byte: FM id
fm_autoset:
		bit	2,(ix)
		jp	nz,fm_send_2

fm_send_1:
		ld	a,d
		ld	(Zym_ctrl_1),a
		nop
		ld	a,e
		ld	(Zym_data_1),a
		nop
		ret

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
; dac_me
;
; Writes wave data to DAC using data stored on buffer.
; Call this routine every 6 or more lines of code
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
; --------------------------------------------------------

dac_me:		exx				; <-- code changes between EXX(play) and RET(stop)
		ex	af,af'
		ld	b,l
		ld	a,2Ah
		ld	(Zym_ctrl_1),a
		ld	l,h
		ld	h,c
		ld	a,(hl)
		ld	(Zym_data_1),a
		ld	h,l
		ld	l,b
		add	hl,de
		ex	af,af'
		exx
		ret

; --------------------------------------------------------
; dac_fill
;
; Refills a half of the WAVE FIFO data, automatic
;
; *** self-modifiable code ***
; --------------------------------------------------------

dac_fill:	push	af			; <-- code changes between PUSH AF(play) and RET(stop)
		ld	a,(dDacFifoMid)
		exx
		xor	h			; xx.00
		exx
		and	80h
		jp	nz,dac_refill
		pop	af
		ret
; first time
dac_firstfill:
		call	check_tick
		push	af

; If auto-fill is needed
; TODO: improve this, it's rushed.

dac_refill:
		call	dac_me
		push	bc
		push	de
		push	hl
		ld	a,(wave_Flags)
		cp	111b
		jp	nc,.FDF7

		ld	a,(dDacCntr+2)
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
		jp	m,.FDF4DONE
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
.FDF4DONE:
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
		call	dac_off
; 		ld	HL,FMVTBLCH6
; 		ld	(HL),0C6H		; mark voice free, unlocked, and releasing
; 		inc	HL
; 		inc	HL
; 		inc	HL
; 		inc	HL
; 		ld	(HL),0			; clear any pending release timer value
; 		inc	HL
; 		ld	(HL),0
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

wavFreq_Pwm:	dw 100h		; C-0
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
		dw 100h
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
		dw 07Fh		; C-4 11025 -12
		dw 088h		; C#4
		dw 08Fh		; D-4
		dw 097h		; D#4
		dw 0A0h		; E-4
		dw 0ADh		; F-4
		dw 0B5h		; F#4
		dw 0C0h		; G-4
		dw 0CCh		; G#4
		dw 0D7h		; A-4
		dw 0E7h		; A#4
		dw 0F0h		; B-4
		dw 100h		; C-5 22050
		dw 110h		; C#5
		dw 120h		; D-5
		dw 12Ch		; D#5
		dw 142h		; E-5
		dw 158h		; F-5
		dw 16Ah		; F#5 32000 +6
		dw 17Eh		; G-5
		dw 190h		; G#5
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
		dw 0		; use +60 if using C-5 for tone 3 noise

; --------------------------------------------------------

PSGVTBL		db 00h			; 0 - PSG channel id + flags
		dw 0			; 1 - track channel link
		db 0			; 3 - ALV
		db 0			; 4 - ATK
		db 0			; 5 - SLV
		db 0			; 6 - DKY
		db 0			; 7 - RRT
		db 0
		db 01h
		dw 0			; link
		db 0			; ALV
		db 0			; ATK
		db 0			; SLV
		db 0			; DKY
		db 0			; RRT
		db 0
		db 02h
		dw 0			; link
		db 0			; ALV
		db 0			; ATK
		db 0			; SLV
		db 0			; DKY
		db 0			; RRT
		db 0
		db -1			; end-of-list
PSGNVTBL	db 03h
		dw 0			; track channel link
		db 0			; ALV
		db 0			; ATK
		db 0			; SLV
		db 0			; DKY
		db 0			; RRT
		db 0
		db -1			; end-of-list

FMVTBL		db 00h			;  0 - FM channel (chip's actual order)
		dw 0			;  1 - link
		dw 0			;  3 - FM instr pointer
		db 0			;  5 - Pitch
		db 0,0,0		;  6 - 0B0h,0B4h,keys
		dw 0			;  9 - Main frequency
		dw 0			; 11 - Ex freq 1
		dw 0			; 13 - Ex freq 2
		dw 0			; 15 - Ex freq 3
		db 01h
		dw 0
		dw 0
		db 0
		db 0,0,0
		dw 0
		dw 0
		dw 0
		dw 0
		db 04h
		dw 0
		dw 0
		db 0
		db 0,0,0
		dw 0
		dw 0
		dw 0
		dw 0
		db 05h
		dw 0
		dw 0
		db 0
		db 0,0,0
		dw 0
		dw 0
		dw 0
		dw 0
FM3VTBL		db 02h
		dw 0			;  1 - link
		dw 0			;  3 - FM instr pointer
		db 0
		db 0,0,0		;  5 - 0B0h,0B4h,keys
		dw 0			;  8 - Main frequency
		dw 0			; 10 - Ex freq 1
		dw 0			; 12 - Ex freq 2
		dw 0			; 14 - Ex freq 3
FM6VTBL		db 06h
		dw 0			;  1 - link
		dw 0			;  3 - FM instr pointer
		db 0
		db 0,0,0		;  5 - 0B0h,0B4h,keys
		dw 0			;  8 - Main frequency
		dw 0			; 10 - Ex freq 1
		dw 0			; 12 - Ex freq 2
		dw 0			; 14 - Ex freq 3
		db -1

; 		align 8
PWMVTBL		db 00h		; 0 - PWM entry, bit7:locked bit6:update for 68k
		dw 0		; 1 - track link
		dw 0		; 3 - Pitch (note)
		db 0		; 5 - Instrument number
		db 0		; 6 - Volume
		db 11b		; 7 - Panning
		db 01h
		dw 0
		dw 0
		db 0
		db 0
		db 11b
		db 02h
		dw 0
		dw 0
		db 0
		db 0
		db 11b
		db 03h
		dw 0
		dw 0
		db 0
		db 0
		db 11b
		db 04h
		dw 0
		dw 0
		db 0
		db 0
		db 11b
		db 05h
		dw 0
		dw 0
		db 0
		db 0
		db 11b
		db 06h
		dw 0
		dw 0
		db 0
		db 0
		db 11b
		db -1

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

; ====================================================================
; ----------------------------------------------------------------
; FM Voices
; ----------------------------------------------------------------

		include "data/sound/instr_z80.asm"
		; PWM instruments are stored in SDRAM

; ====================================================================
; ----------------------------------------------------------------
; Z80 RAM
; ----------------------------------------------------------------

; --------------------------------------------------------
; Buffers
; --------------------------------------------------------

		align 100h
dWaveBuff	ds 100h			; WAVE data buffer: updated every 80h bytes *LSB must be 00h*
trkDataC	ds 100h*MAX_TRKS	; Track data cache: 100h bytes each
trkBuff		ds 100h*MAX_TRKS	; Track control (20h) + channels (8h each)
blkHeadC	ds 100h*MAX_TRKS	; Track blocks and heads: 80h each
insDataC	ds 80h*MAX_TRKS		; Instrument pointers cache: 80h each
commZfifo	ds 40h			; Buffer for command requests from 68k
