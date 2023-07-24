# Marsiano-MARS
A multi SEGA-system game codebase for Sega Genesis, Sega CD, Sega 32X, Sega CD32X and Sega Pico.

WORK IN PROGRESS, IN THE MIDDLE OF CLEANUP.

- Sega Genesis and Sega 32X roms are tested on real hardware.
- Sega CD, Sega CD32X and Sega Pico are UNTESTED as I don't have either Sega CD or the Sega Pico (There's no flashcarts for Pico anyway)

Prebuilt binaries are located in the /out folder for testing: ROMs are for NTSC systems, SCD isos are for the USA region.

If the Genesis and 32X versions doesn't boot or it freezes: I probably broke something without testing on HW, for the other systems I can't guarantee if those will work on their respective hardware. ON CD32X I'm using the DREQ transfer code on RAM that normally results in failing the FIFO writes.
