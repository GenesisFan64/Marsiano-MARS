# Marsiano-MARS
A GameBase/Engine/Library for making Sega 32X Games, in pure assembly for ALL CPUs
I'm also using this to research those real-hardware bugs and limitations that current emulators ignore.
*WORK IN PROGRESS*

Graphics:
- Various pseudo-screens modes: Ex. 3D polygons, A scrolling 256-color background...
- 256-color background: Drawing is done using dirty-section method, moves smoothly and saves CPU processing.
- 256-color BG: Source data can be either a static image in ROM (NOTE: not RV protected) or a buffer section in RAM in any WIDTH and HEIGHT, BUT aligned in "blocks" (Usable: 4x4, 8x8, 16x16, 32x32)
- 3D polygons: Uses both SH2s, Reads 3D models in a custom format: Python3 .obj importer is included.

Sound, Genesis and 32X:
- Runs on Z80, with DMA-protection (on the Genesis side)
- Supports PSG, FM and PWM. Up to 17 channels.
- PSG: supports effects like Attack and Release. can autodetect if the NOISE channel uses Tone3(frequency-steal) mode.
- YM2612: DAC sample playback at 18000hz aprox. with pitch, supports FM3 special mode for extra frequencies.
- PWM: 7-psuedo channels at 22050hz in both Stereo and Mono with Pitch, Volume and Panning, controlled by the sound driver in the Genesis side. Has PWM-overflow and ROM RV protection. (RV protection currently disabled, 16/03/2022)
- Supports Ticks and Global tempo (default tempos: 150 for NTSC and 120 for PAL)
- Channel-link system: Any track channel automaticly picks the available channel in the soundchip. (PSG, FM, PWM)
- Two playback slots: Second slot has priority for SFX sound effects, it can temporally override channels used by the first slot.
- Can autodetect each soundchips' special features (PSG, DAC and FM3 special) and swap those features mid-playback in the same slot. (ex. FM6 to DAC or DAC to FM6)
- Music can be composed in any tracker that supports ImpulseTracker (.IT), then imported with a simple python3 script

Notes/Current issues:
- SOFT reset takes a LOT to go back, and may freeze.
- (256-color bg) If the X/Y positions are moving in the middle of switching modes the image might fail draw
- (PWM) RV-backup: If Genesis' DMA takes too long to process (in the DMA BLAST list) it might play corrupt wave data.

Planned/TODO:
- Implement NORMAL sprites on the 256-color background pseudomode

LIST OF UNEMULATED 32X HARDWARE FEATURES, BUGS AND ERRORS:

-- General --
- ALL Emulators doesn't trigger the SH2's Error handlers (Address Error, Zero Divide, etc.)
- MOST Emulators doesn't SOFT reset like in hardware (only Picodrive does): 68k resets like usual BUT the SH2 side it doesn't restart: it triggers the VRES interrupt and keep going on return. commonly the code it's just a jump to go back to the "HotStart" code. ALL values will remain unmodified including comm's
- The 4-byte LONG alignment limitation is ignored.

-- 68000 --
- RV bit: This bit sets the ROM map temporally to it's original location on the Genesis side as a workaround for the DMA's ROM-to-VDP transfers. (from $88xxxx/$9xxxxx to $0xxxxx, all 4MB view area) If you do any DMA-transfer without setting this bit it will read trash data. Your Genesis DMA-to-VDP transfer routines MUST be located on RAM (recommended method) OR if you need to use the ROM area: just put the RV writes (on and off) AND the and last VDP write on the RAM area. (Note: Transferring RAM data to VDP doesn't require the RV bit) Also for the SH2 side: If RV is set, any read from the ROM area will return trash data.
- Writing to the DREQ's FIFO only works properly on the $880000/$900000 68k areas. If doing the writes in the RAM area ($FF0000) some WORD writes will get lost during transfer.

-- SH2---
- The SDRAM, Framebuffer, ROM area and Cache run at different speeds for Reading/Writing and depending where the Program Counter (PC) is currently located. Cache being the fastest BUT with the lowest space to store code or data.
- BUS fighting: If any of the SH2 CPUs READ/WRITE the same location at the same time it will crash the add-on. Only tested on the SDRAM area but believe the video and audio registers are affected too. only the comm's are safe for both sides (and Genesis too.)
- After DMA (Channel 0) finishes: If the DESTINATION data gets read or rewritten, the next DMA transfer will stop early when it reaches the last part that got modified.
- After setting _DMAOPERATION to 1 it takes a little to start. add 5 nops in case you need to wait for the transfer to finish (reading bit 1 of _DMACHANNEL0)
- If you force _DMAOPERATION to OFF while DMA is active it crashes the system. (or maybe not, needs more testing)

-- SuperVDP --
- Writing pixels in to the framebuffer in BYTEs cause a small delay.
- If any entry of the linetable ends with $xxFF and the XShift register is set to 1, that line will NOT get shifted.

-- PWM --
- It's 3-word FIFO isn't emulated properly, on emulators it behaves like a normal write-register. (I imagine...)
- The output limit for both LEFT and RIGHT channels is 1023 ($03FF), NOT 4095 ($0FFF) mentioned in the docs.

--- Both sides ---
- FM bit: This bit tells which system side (Genesis or 32X) can read/write to the SuperVDP (The framebuffer and 256-color palette, EXCEPT the registers), If a CPU with NO permission touches the SuperVDP's Framebuffer or it's Palette it will freeze the entire system (either Genesis 68K or 32X SH2).

A prebuilt binary is located in the /out folder (rom_mars.bin) for testing, works on any Genesis/MD flashcart WITH the 32X inserted. ROM is for NTSC systems, can be played on PAL but with slowdown.
If it doesn't boot or it freezes: I probably broke something without testing on HW

For more info check the official hardware manual (32X Hardware Manual.pdf)
