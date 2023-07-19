; =====================================================================
; -------------------------------------------
; Variables
; -------------------------------------------

CD_Load_Hadagi		equ	4
CD_WordRamToMain	equ	8
CD_LoadHadagi_PrgRam	equ	5

; -------------------------------------------
; SubCommand
; -------------------------------------------

SubCpu_Task_Wait:
		tst.b	(ThisCpu+CommSub)	; is sub cpu free?
		bne.s	SubCpu_Task_Wait	; if not, wait for it to finish corrent operation

		move.b	#0,(ThisCpu+CommMain)	; Clear Command
@wait1:
		tst.b	(ThisCpu+CommSub)	; sub cpu ready?
		beq.s	@wait1			; if not, branch
	
		move.b	d0,(ThisCpu+CommMain)	; Send the command
@wait2:
		tst.b	(ThisCpu+CommSub)	; Is sub CPU done?
		bne.s	@wait2			; if not, branch
		rts

; -------------------------------------------
; ASyncSubCommand
; -------------------------------------------

SubCpu_Task:
		tst.b	(ThisCpu+CommSub)	; is sub cpu free?
		bne.s	SubCpu_Task		; if not, wait for it to finish corrent operation

		move.b	#0,(ThisCpu+CommMain)	; Clear Command
@wait:
		tst.b	(ThisCpu+CommSub)	; sub cpu ready?
		beq.s	@wait			; if not, branch
	
		move.b	d0,(ThisCpu+CommMain)	; Send the command
		rts
		
; -------------------------------------------
; SubCpu_Wait
; -------------------------------------------

SubCpu_Wait:
		tst.b	(ThisCpu+CommSub)	; is sub cpu free?
		bne.s	SubCpu_Wait		; if not, wait for it to finish corrent operation
		move.b	#0,(ThisCpu+CommMain)	; Clear Command
@wait1:
		tst.b	(ThisCpu+CommSub)	; sub cpu ready?
		beq.s	@wait1			; if not, branch
		rts
	
; -------------------------------------------
; SubCpu_Wait
; -------------------------------------------

SubCpu_Wait_Flag:
		moveq	#-1,d0
		tst.b	(ThisCpu+CommSub)	; is sub cpu free?
		bne.s	@flagset		; if not, wait for it to finish corrent operation
		move.b	#0,(ThisCpu+CommMain)	; Clear Command
		tst.b	(ThisCpu+CommSub)	; sub cpu ready?
		beq.s	@flagset		; if not, branch
		moveq	#0,d0
@flagset:
		rts
		
; -------------------------------------------
; Load Program to WordRAM
; -------------------------------------------

Load_PrgWord:
		move.l	d0,(ThisCpu+CommDataM)
		move.l	d1,(ThisCpu+CommDataM+4)
		move.l	d2,(ThisCpu+CommDataM+8)
 		bset	#1,(ThisCpu+MemoryMode+1)		; WordRAM -> SubCPU
		moveq	#CD_Load_Hadagi,d0
		bsr	SubCpu_Task_Wait
 		moveq	#CD_WordRamToMain,d0			; WordRAM -> MainCPU
 		bra	SubCpu_Task_Wait

; -------------------------------------------
; Load Program to RAM
; -------------------------------------------

Load_PrgRam:
 		bset	#1,(ThisCpu+MemoryMode+1)		; WordRAM -> SubCPU
 		
		move.l	d0,(ThisCpu+CommDataM)
		move.l	d1,(ThisCpu+CommDataM+4)
		move.l	d2,(ThisCpu+CommDataM+8)
		move.b	#0,(ThisCpu+CommDataM+$C)
		move.b	#0,(ThisCpu+CommDataM+$D)		; Step 1
		moveq	#CD_LoadHadagi_PrgRam,d0
		bsr	SubCpu_Task_Wait
		
		move.b	#1,(ThisCpu+CommDataM+$D)		; Step 2
		moveq	#CD_LoadHadagi_PrgRam,d0
		bsr	SubCpu_Task_Wait
		
 		moveq	#CD_WordRamToMain,d0			; WordRAM -> MainCPU
 		bsr	SubCpu_Task_Wait
  		lea	($200000),a5
  		lea	($FF0000),a6
  		move.w	#(sizeof_prg)-1,d6
@Step_1:
 		move.b	(a5)+,(a6)+
 		dbf	d6,@Step_1
  		
    		bset	#1,(ThisCpu+MemoryMode+1)		; WordRAM -> SubCPU
   		move.b	#2,(ThisCpu+CommDataM+$D)		; Step 3
   		moveq	#CD_LoadHadagi_PrgRam,d0
   		bsr	SubCpu_Task_Wait		
    		moveq	#CD_WordRamToMain,d0			; WordRAM -> MainCPU
    		bra	SubCpu_Task_Wait
    		
