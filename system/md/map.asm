; ====================================================================
; ----------------------------------------------------------------
; Genesis / MegaDrive 68k map
; ----------------------------------------------------------------

sys_exram	equ	$200000		; Second half of 4MB rom or external RAM (Normal or save data)
z80_cpu		equ	$A00000		; Z80 CPU area, size: $2000
ym_ctrl_1	equ	$A04000		; YM2612 reg 1
ym_data_1	equ	$A04001		; YM2612 reg 2
ym_ctrl_2	equ	$A04002		; YM2612 reg 1
ym_data_2	equ	$A04003		; YM2612 reg 2
sys_io		equ	$A10001		; bits: OVRSEAS(7)|PAL(6)|DISK(5)|VER(3-0)
sys_data_1	equ	$A10003		; Port 1 DATA
sys_data_2	equ	$A10005		; Port 2 DATA
sys_data_3	equ	$A10007		; Modem DATA
sys_ctrl_1	equ	$A10009		; Port 1 CTRL
sys_ctrl_2	equ	$A1000B		; Port 2 CTRL
sys_ctrl_3	equ	$A1000D		; Modem CTRL
z80_bus 	equ	$A11100		; only use bit 0 (bit 8 as WORD)
z80_reset	equ	$A11200		; WRITE only ($0000 reset/$0100 cancel)
md_bank_sram	equ	$A130F1		; Make SRAM visible at $200000
sys_tmss	equ	$A14000		; write "SEGA" here for ver > 0
vdp_data	equ	$C00000		; video data port
vdp_ctrl	equ	$C00004		; video control port
psg_ctrl	equ	$C00011		; PSG control

; ----------------------------------------------------------------
; Genesis / Mega drive Z80 map
; ----------------------------------------------------------------

zym_ctrl_1	equ	$4000		; YM2612 reg 1
zym_data_1	equ	$4001		; YM2612 reg 2
zym_ctrl_2	equ	$4002		; YM2612 reg 1
zym_data_2	equ	$4003		; YM2612 reg 2
zbank		equ	$6000		; Z80 ROM BANK 24bits, %XXXXXXXX X0000000 00000000 (9 writes)
; zvdp_data	equ	$7F00		; video data port
; zvdp_ctrl	equ	$7F04		; video control port
zpsg_ctrl	equ	$7F11		; PSG control

; ----------------------------------------------------------------
; 32X registers
; ----------------------------------------------------------------

sysmars_id	equ	$A130EC		; 32X's ID String: "MARS"
sysmars_reg	equ	$A15100		; MARS 32X registers section, see system/mars/map.asm for variables
