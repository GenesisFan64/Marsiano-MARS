; ====================================================================
; ----------------------------------------------------------------
; SH2 MAP
; ----------------------------------------------------------------

; --------------------------------------------------------
; SH2 SIDE MAP
; --------------------------------------------------------

CS0		equ	$00000000	; Boot rom & system registers
CS1		equ	$02000000	; ROM data (all 4MB), Locked if RV=1
CS2		equ	$04000000	; Framebuffer section
CS3		equ	$06000000	; SDRAM
TH		equ	$20000000	; Cache-thru OR|value
_sysreg		equ	$00004000|TH	; MARS System registers, for MD: sysmars_reg
_vdpreg		equ	$00004100|TH	; SuperVDP registers
_palette	equ	$00004200|TH	; Palette RAM for Pixel-Packed or RLE mode
_framebuffer:	equ	CS2|TH		; Framebuffer, first 240 are the linetable
_overwrite:	equ	CS2|TH+$20000	; Overwrite, $00-byte writes are ignored

; --------------------------------------------------------
; Variables
; --------------------------------------------------------

; ------------------------------------------------
; System
; ------------------------------------------------

; _sysreg
adapter		equ	$00		; adapter control register
intmask		equ	$01		; interrupts mask
standby		equ	$02		; CMD interrupt request bit by MD side (slave|master)
hcount		equ	$05		; H Counter
dreqctl		equ	$06		; DREQ control
dreqsource	equ	$08		; DREQ source address
dreqdest	equ	$0C		; DREQ destination address
dreqlen		equ	$10		; DREQ length
dreqfifo	equ	$12		; DREQ FIFO
vresintclr	equ	$14		; VRES interrupt clear
vintclr		equ	$16		; V interrupt clear
hintclr		equ	$18		; H interrupt clear
cmdintclr	equ	$1a		; CMD interrupt clear
pwmintclr	equ	$1C		; PWM interrupt clear
comm0		equ	$20		; Communication ports
comm2		equ	$22		; (If 2 CPUs either SH2 or 68K writes to
comm4		equ	$24		; the same location, it will freeze the
comm6		equ	$26		; system)
comm8		equ	$28		;
comm10		equ	$2A		;
comm12		equ	$2C		;
comm14		equ	$2E		;
comm15		equ	$2F		;
timerctl	equ	$30		; PWM Timer Control
pwmctl		equ	$31		; PWM Control
cycle		equ	$32		; PWM Cycle
lchwidth	equ	$34		; PWM L ch Width
rchwidth	equ	$36		; PWM R ch Width
monowidth	equ	$38		; PWM Monaural Width

; _sysreg
; adapter
CART		equ	%00000001	; CD or Cartridge
ADEN		equ	%00000010	; MARS Enabled: No/Yes
FM		equ	%10000000	; SuperVDP permission: MD or SH
; framectl
FS		equ	%00000001	; Current framebuffer DRAM pixel data
FEN		equ	%00000010	; Can write to Framebuffer: Yes/No
; vdpsts
VBLK		equ	%10000000	; VBlank bit
HBLK		equ	%01000000	; HBlank bit
PEN		equ	%00100000	; Can write to Palette: Yes/No
; intmask
VIRQ_ON		equ	$08		; IRQ masks for IRQ mask register
HIRQ_ON		equ	$04
CMDIRQ_ON	equ	$02
PWMIRQ_ON	equ	$01

; _vdpreg
tvmode		equ	$00		; TV mode register
bitmapmd	equ	$01		; Bitmap mode register
shift		equ	$03		; Shift Control register
filllength	equ	$05		; Auto Fill Length register
fillstart	equ	$06		; Auto Fill Start Address register
filldata	equ	$08		; Auto Fill Data register
vdpsts		equ	$0a		; VDP Status register
framectl	equ	$0b		; Frame Buffer Control register

; --------------------------------------------------------
; SH2 Internal registers, independent for each CPU
; --------------------------------------------------------

; DMA Channel 0: General data transfer
; DMA Channel 1: PWM exclusive
_SERIAL		equ	$FFFFFE00	; Serial Control
_FRT		equ	$FFFFFE10	; Free run timer
_TIER		equ	$00		; Timer interrupt enable register
_TCSR		equ	$01		; Timer control & status register
_FRC_H		equ	$02		; free running counter High
_FRC_L		equ	$03		; free running counter Low
_OCR_H		equ	$04		; Output compare register High
_OCR_L		equ	$05		; Output compare register Low
_TCR		equ	$06		; Timer control register
_TOCR		equ	$07		; timer output compare control register
_CCR:		equ	$FFFFFE92
_JR		equ	$FFFFFF00	; DIVU (--- / val)
_HRL32		equ	$FFFFFF04	; DIVU (val / ---) or LOW Result if read
_HRH		equ	$FFFFFF10	; DIVU Result, HIGH
_HRL		equ	$FFFFFF14	; DIVU Result, LOW
_DMASOURCE0	equ	$FFFFFF80	; DMA source address 0
_DMADEST0	equ	$FFFFFF84	; DMA destination address 0
_DMACOUNT0	equ	$FFFFFF88	; DMA transfer count 0
_DMACHANNEL0	equ	$FFFFFF8C	; DMA channel control 0
_DMASOURCE1	equ	$FFFFFF90	; DMA source address 1
_DMADEST1	equ	$FFFFFF94	; DMA destination address 1
_DMACOUNT1	equ	$FFFFFF98	; DMA transfer count 1
_DMACHANNEL1	equ	$FFFFFF9C	; DMA channel control 1
_DMAVECTORN0	equ	$FFFFFFA0	; DMA vector number N0
_DMAVECTORE0	equ	$FFFFFFA4	; DMA vector number E0
_DMAVECTORN1	equ	$FFFFFFA8	; DMA vector number N1
_DMAVECTORE1	equ	$FFFFFFAC	; DMA vector number E1
_DMAOPERATION	equ	$FFFFFFB0	; DMA operation
_DMAREQACK0	equ	$FFFFFFB4	; DMA request/ack select control 0
_DMAREQACK1	equ	$FFFFFFB8	; DMA request/ack select control 1
