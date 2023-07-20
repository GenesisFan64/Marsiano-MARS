clear

# GENESIS
echo "** GENESIS **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/rom_md.lst -A -L -D MCD=0,MARS=0,MARSCD=0,PICO=0
python tools/p2bin.py main.p out/rom_md.bin
rm main.p
rm main.h

# GENESIS
echo "** SEGA CD **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/rom_mcd.lst -A -L -D MCD=1,MARS=0,MARSCD=0,PICO=0
python tools/p2bin.py main.p out/rom_mcd.iso
rm main.p
rm main.h

# MARS
echo "** SEGA 32X **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/rom_mars.lst -A -L -D MCD=0,MARS=1,MARSCD=0,PICO=0
python tools/p2bin.py main.p out/rom_mars.bin
rm main.p
rm main.h

# MARSCD
echo "** SEGA CD32X **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/rom_marscd.lst -A -L -D MCD=0,MARS=0,MARSCD=1,PICO=0
python tools/p2bin.py main.p out/rom_marscd.iso
rm main.p
rm main.h

# PICO
echo "** PICO **"
tools/AS/linux/asl main.asm -q -xx -c -A -olist out/rom_pico.lst -A -L -D MCD=0,MARS=0,MARSCD=0,PICO=1
python tools/p2bin.py main.p out/rom_pico.bin
rm main.p
rm main.h
