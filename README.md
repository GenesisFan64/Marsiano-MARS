a# Marsiano-MARS
A GameBase/Engine/Library for making Sega 32X Games in pure assembly on ALL CPUs *WORK IN PROGRESS*

I'm also using this to research those real-hardware bugs and limitations that current emulators ignore.

Graphics:
- Uses custom pseudo-screens modes, currently working: 256-color with smooth scrolling, 256-color scaling image and 3D objects mode.

-- 256-color scrolling background --
- Drawing is done using dirty-section method, moves smoothly and saves CPU processing.
- Source data can be either a static image in ROM (NOTE: not RV protected) or a buffer section in RAM in any WIDTH and HEIGHT, BUT aligned in "blocks" (Usable: 4x4, 8x8, 16x16, 32x32)

-- 256-color scalable background --
- Infinite scaling. uses Slave CPU for speed up the drawing process (a little...)

-- 3D objects --
- Uses both SH2s, Reads 3D models in a custom format: Python3 .obj importer is included.


Sound, Genesis and 32X:
- Runs on Z80, with DMA-protection (on the Genesis side)
- Supports PSG, FM and PWM. Up to 17 channels.
- PSG: supports effects like Attack and Release. can autodetect if the NOISE channel uses Tone3(frequency-steal) mode.
- YM2612: DAC sample playback at 18000hz aprox. with pitch, supports FM3 special mode for extra frequencies.
- PWM: 7-psuedo channels at 22050hz in both Stereo and Mono with Pitch, Volume and Panning, controlled by the sound driver in the Genesis side. Has PWM-overflow and ROM RV protection. (RV protection currently disabled, 16/03/2022)
- Supports Ticks and Global tempo (default tempos: 150 for NTSC and 120 for PAL)
- Channel-link system: Any track-channel automaticly picks the available channel in the soundchip. (PSG, FM, PWM)
- Two playback slots: Second slot has priority for SFX sound effects, it can temporally override channels used by the first slot.
- Can autodetect each soundchips' special features (PSG, DAC and FM3 special) and swap those features mid-playback in the same slot. (ex. FM6 to DAC or DAC to FM6)
- Music can be composed in any tracker that supports ImpulseTracker (.IT), then imported with a simple python3 script

Notes/Current issues:
- SOFT reset has a low chance of freezing.
- (PWM) RV-backup: If Genesis' DMA takes too long to process (in the DMA BLAST list) it might play trash wave data.

Planned:
- Add map layout support on psd-Mode 2 (256-color scrolling background)

LIST OF UNEMULATED 32X HARDWARE FEATURES, BUGS AND ERRORS:

-- General --
- ALL Emulators doesn't trigger the SH2's Error handlers (Address Error, Zero Divide, etc.)
- MOST Emulators doesn't SOFT reset like in hardware (only Picodrive does, and not even close): 68k resets like usual BUT the SH2 side it doesn't restart: it triggers the VRES interrupt and keep going on return. commonly the code it's just a jump to go back to the "HotStart" code. ALL values will remain unmodified including comm's (unless 68k clears them first)
- The actual purpose of Cache isn't emulated at all. so emulators just treat everything as "Cache-thru"
- The 4-byte LONG alignment limitation is ignored.
- Fusion 3.64: vdpfill might randomly get stuck waiting for the framebuffer-busy bit.

-- 68000 --
- RV bit: This bit sets the ROM map temporally to it's original location on the Genesis side as a workaround for the DMA's ROM-to-VDP transfers. (from $88xxxx/$9xxxxx to $0xxxxx, all 4MB view area) If you do any DMA-transfer without setting this bit it will read trash data. Your Genesis DMA-to-VDP transfer routines MUST be located on RAM (recommended method) OR if you need to use the ROM area: just put the RV writes (on and off) AND the and last VDP write on the RAM area. (Note: Transferring RAM data to VDP doesn't require the RV bit) For the SH2 side: If RV is set, any read from the ROM area will return trash data.
- Writing to the DREQ's FIFO only works properly on the $880000/$900000 areas. Doing the writes in the RAM area ($FF0000) will cause to miss some WORD writes during transfer.

-- SH2---
- The SDRAM, Framebuffer, ROM area and Cache run at different speeds for Reading/Writing and depending where the Program Counter (PC) is currently located. Cache being the fastest BUT with the lowest space to store code or data.
- BUS fighting: If any of the SH2 CPUs READ/WRITE the same location at the same time it will crash the add-on. Only tested on the SDRAM area but believe the video and audio registers are affected too. only the comm's are safe for both sides (and Genesis too.)
- After setting _DMAOPERATION to 1 (Starting the DMA), it takes a little to start. add 5 nops in case you need to wait for the transfer to finish (reading bit 1 of _DMACHANNEL0)
- After DMA (Channel 0) finishes: If at any part of the DESTINATION data gets read or rewritten, the next DMA transfer will stop early when it reaches the last part that got modified.
- If you force _DMAOPERATION to OFF while DMA is active it crashes the system. (or maybe not, needs more testing)

-- SuperVDP --
- Writing pixels in to the framebuffer in BYTEs cause a small delay. 6 NOPs aprox.
- If any entry of the linetable ends with $xxFF and the XShift video register is set to 1, that line will NOT get shifted.

-- PWM --
- It's 3-word FIFO isn't emulated properly, on emulators it behaves like a normal write-register. (I imagine...)
- The output limit for both LEFT and RIGHT channels is 1023 ($03FF), NOT 4095 ($0FFF) mentioned in the docs.

--- Both sides ---
- FM bit: This bit tells which system side (Genesis or 32X) can read/write to the SuperVDP (The Framebuffer and 256-color palette, EXCEPT the registers), If a CPU with NO permission touches the SuperVDP it will freeze the entire system (either Genesis 68K or 32X SH2).

A prebuilt binary is located in the /out folder (rom_mars.bin) for testing, works on any Genesis/MD flashcart WITH the 32X inserted. ROM is for NTSC systems, can be played on PAL but with slowdown.
If it doesn't boot or it freezes: I probably broke something without testing on HW

For more info check the official hardware manual (32X Hardware Manual.pdf)
