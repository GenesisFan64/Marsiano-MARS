# Marsiano-MARS
An starting point for making Sega 32X homebrew software, was going to be used for a tech demo to show it's capabilities but ran out of time...

- 68k is being used for the main logic

- Z80 does the sound, including PWM (with the help of Slave SH2)

- MASTER SH2 controls the visuals (2D+3D), SLAVE SH2 does the PWM playback and sometimes it's used for dual-cpu tasks

This code provides: Smooth 2D 256-color scrolling background with "Super" sprites, 3D objects system, sound driver with PWM support and DREQ for controlling everything on the 68000 side.

This is also being used to research bugs and limitations of the real hardware that current emulators ignore... see hwnotes.txt for details.

A prebuilt binary is located in the /out folder for testing, works on any Genesis/MD flashcart WITH the 32X inserted. ROM is for NTSC systems, can be played on PAL but with slowdown.
If it doesn't boot or it freezes: I probably broke something without testing on HW
