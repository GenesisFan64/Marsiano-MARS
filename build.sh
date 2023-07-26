clear
echo "*** Building EMULATOR-ONLY ROM ***"

# GENESIS
echo "** GENESIS **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/emu/rom_md_emu.lst -A -L -D MCD=0,MARS=0,MARSCD=0,PICO=0,EMU=1
python tools/p2bin.py main.p out/emu/rom_md_emu.bin
rm main.p
rm main.h

# GENESIS
echo "** SEGA CD **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/emu/rom_mcd_emu.lst -A -L -D MCD=1,MARS=0,MARSCD=0,PICO=0,EMU=1
python tools/p2bin.py main.p out/emu/rom_mcd_emu.iso
rm main.p
rm main.h

# MARS
echo "** SEGA 32X **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/emu/rom_mars_emu.lst -A -L -D MCD=0,MARS=1,MARSCD=0,PICO=0,EMU=1
python tools/p2bin.py main.p out/emu/rom_mars_emu.32x
rm main.p
rm main.h

# MARSCD
echo "** SEGA CD32X **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/emu/rom_marscd_emu.lst -A -L -D MCD=0,MARS=0,MARSCD=1,PICO=0,EMU=1
python tools/p2bin.py main.p out/emu/rom_marscd_emu.iso
rm main.p
rm main.h

# PICO
echo "** PICO **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/emu/rom_pico_emu.lst -A -L -D MCD=0,MARS=0,MARSCD=0,PICO=1,EMU=1
python tools/p2bin.py main.p out/emu/rom_pico_emu.bin
rm main.p
rm main.h
