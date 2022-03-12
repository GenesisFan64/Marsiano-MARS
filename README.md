# Marsiano-MARS
A GameBase/Engine/Library for making Sega 32X Games, in pure assembly for ALL CPUs
I'm also using this to research those real-hardware bugs and limitations that current emulators ignore.
*WORK IN PROGRESS*

Graphics:
- 2 Pseudo graphics modes: Scrolling 256-color background and 3D polygons mode.
- 256-color background: Drawing is done using dirty-section method, saves CPU time.
- Source data can be either a static image in ROM (NOTE: not RV protected) or a buffer section in RAM in any WIDTH and HEIGHT, BUT aligned in "blocks" (Ex. 4x4, 8x8, 16x16, 32x32)
- 3D polygons: Uses both SH2s, Reads 3D models in a custom format: Python3 .obj importer is included.

Sound, Genesis and 32X:
- Runs on Z80, with DMA-protection (Genesis side)
- Supports PSG, FM and PWM. Up to 17 channels.
- PSG: supports effects like Attack and Release. can autodetect if the NOISE channel uses Tone3(frequency-steal) mode.
- YM2612: DAC sample playback at 18000hz aprox. with pitch changes, supports FM3 special mode for extra frequencies.
- 32X: Supports PWM at 22050hz, 7-psuedo channels controlled by the sound driver in the Genesis side, in both Stereo and Mono with Pitch, Volume and Panning. Has PWM-overflow protection.
- Supports Ticks and Global tempo (default tempos: 150 for NTSC and 120 for PAL)
- It uses the channel-link system, It automaticly picks the available soundchip channel to play.
- Can autodetect each soundchips' special features (DAC and FM3 special) and swap those features mid-playback in the same slot. (ex. FM6 to DAC or DAC to FM6)
- Two playback slots: Second slot has priority for SFX sound effects, it can temporally override channels used by the first slot.
- Music can be composed in any tracker that supports ImpulseTracker (.IT), then imported with a simple python3 script

Notes/Issues:
- SOFT reset (Pressing RESET on Genesis) might freeze the SH2 side and get stuck on a infinite loop until the user turns off the system.
- PWM RV-backup: If Genesis' DMA takes too long to process (in the DMA BLAST list) it might break the PWM playback
- 256-color background: the X/Y postion gets corrupt on soft-reset

Planned/TODO:
- Implement NORMAL sprites on the 256-color background pseudomode

LIST OF UNEMULATED 32X HARDWARE FEATURES, BUGS AND ERRORS:
- ALL Emulators doesn't trigger the SH2's Error handlers (Address Error, Zero Divide, etc.)
- ALL Emulators doesn't SOFT reset like in hardware: 68k resets normally BUT the SH2 side it doesn't restart: it triggers the VRES interrupt and depending of the code it's normally a jump code to go back to the boot code. ALL values will remain unmodified including comm's
- The 4-byte alignment limitation is ignored.
- (SH2) The SDRAM, Framebuffer, ROM and Cache DO run at different speeds depending where the Program Counter (PC) is currently located. Cache being the fastest BUT with the lowest space to store code.
- (SH2) After setting _DMAOPERATION to 1 you must wait 5 nops or the DMA will get cancelled.
- (68K) Writing to the DREQ's FIFO only works properly on the $880000/$900000 68k areas. If doing the writes in the RAM area ($FF0000) some WORD writes will get lost during transfer.
- Writing pixels in to the framebuffer BYTEs cause a small delay.
- (68k, commonly) RV bit: This bit sets the ROM map temporally to it's original location on the Genesis side, as a workaround for the DMA's ROM-to-VDP transfers. If you do any DMA-transfer without setting this bit: it will transfer trash data, Your Genesis-DMA transfer routines MUST be located on RAM (recommended method). on the SH2 side: If RV is set, any read from SH2's ROM area will return trash data. (Note: RAM-to-VDP transfers doesn't require the RV bit)
- (both CPUs) FM bit: This bit tells which system side (Genesis or 32X) can read/write to the Super VDP (The framebuffer and 256-color palette), If a CPU with NO permission touches the Super VDP, it will freeze the entire system (32X add-on or Genesis).
- (SH2) BUS fighting: If any of the SH2 CPUs READ/WRITE the same location at the same time it will crash the add-on. Only tested on the SDRAM area but believe the video and audio registers are affected too. only the comm's are safe for both sides (and Genesis too.)
- PWM's sound limit for each channel (Left and Right) is $3FF, NOT $FFF mentioned in the docs
- PWM's FIFO isn't emulated properly: on emulators it behaves like a normal register.
- (SH2) After DMA (Channel 0) finishes: If the DESTINATION data gets read or rewritten, the next DMA transfer will stop early when it reaches the last part that got modified.

A prebuilt binary is located in the /out folder (rom_mars.bin) for testing, works on any Genesis/MD flashcart WITH the 32X inserted.
If it doesn't boot or it freezes: I probably broke something without testing on HW
ROM is for NTSC systems, can be played on PAL but with slowdown.

For more info check the official hardware manual (32X Hardware Manual.pdf)
