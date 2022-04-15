#======================================================================
# FRAMES TO MARS RLE
# BLACK AND WHITE ONLY
#======================================================================

#0:     47 49 46
       #38 39 61     GIF89a      Header
                                #Logical Screen Descriptor
#6:     03 00        3            - logical screen width in pixels
#8:     05 00        5            - logical screen height in pixels
#A:     F7                        - GCT follows for 256 colors with resolution 3 × 8 bits/primary; 
                                   #the lowest 3 bits represent the bit depth minus 1, the highest true bit means that the GCT is present
#B:     00           0            - background color #0
#C:     00                        - default pixel aspect ratio
                   #R    G    B  Global Color Table
#D:     00 00 00    0    0    0   - color #0 black
#10:    80 00 00  128    0    0   - color #1
 #:                                       :
#85:    00 00 00    0    0    0   - color #40 black
 #:                                       :
#30A:   FF FF FF  255  255  255   - color #255 white
#30D:   21 F9                    Graphic Control Extension (comment fields precede this in most files)
#30F:   04           4            - 4 bytes of GCE data follow
#310:   01                        - there is a transparent background color (bit field; the lowest bit signifies transparency)
#311:   00 00                     - delay for animation in hundredths of a second: not used
#313:   10          16            - color #16 is transparent
#314:   00                        - end of GCE block
#315:   2C                       Image Descriptor
#316:   00 00 00 00 (0,0)         - NW corner position of image in logical screen
#31A:   03 00 05 00 (3,5)         - image width and height in pixels
#31E:   00                        - no local color table
#31F:   08           8           Start of image - LZW minimum code size
#320:   0B          11            - 11 bytes of LZW encoded image data follow
#321:   00 51 FC 1B 28 70 A0 C1 83 01 01
#32C:   00                        - end of image data
#32D:   3B                       GIF file terminator

#======================================================================

import sys
import os.path

#======================================================================
# -------------------------------------------------
# SETTINGS
# -------------------------------------------------

# 0 = MD
# 1 = GG
# 2 = MS
SYSTEM_MODE = 0

# Mapping start at VRAM
START_MAP   = 0

# Blank Tile 
BLANK_TILE  = -1

# Save VRAM
TILE_SAVE   = False

#======================================================================

clist = list()

#======================================================================
# -------------------------------------------------
# Subs
# -------------------------------------------------

def make_cell(XPOS,YPOS,COLOR):
	global GLBL_WIDTH
	XPOS = XPOS * 8
	YPOS = (GLBL_WIDTH * YPOS) * 8
	
	d = IMG_POS+XPOS+YPOS
	c = 8
	while c:
		input_file.seek(d)
		b = 4
		while b:
			a = 0
			e = (ord(input_file.read(1)) & 0xFF)
			f = (ord(input_file.read(1)) & 0xFF)

			a = (e << 4) & 0xF0
			a += f & 0x0F
			
			#g = e >> 4
			#if g == COLOR:
				#a = (e << 4) & 0xF0
			#g = f >> 4
			#if g == COLOR:
				#a += f & 0x0F	
				
			#a = (ord(input_file.read(1)) & 0x0F) << 4
			#a += (ord(input_file.read(1)) & 0x0F)
			art_file.write( bytes([a]) )
			b -= 1	
		
		c -= 1
		d += GLBL_WIDTH
	
def chk_cell(XPOS,YPOS,COLOR):
	global GLBL_WIDTH
	XPOS = XPOS * 8
	YPOS = (GLBL_WIDTH * YPOS) * 8
	a = 0
	d = IMG_POS+XPOS+YPOS
	
	x = 0
	y = 0
	z = 0
	
	c = 8
	while c:
		input_file.seek(d)
		b = 8
		while b:
			f = (ord(input_file.read(1)) & 0xFF)
			
			g = f >> 4
			if g == COLOR:
				a += a + (f & 0x0F)
			
			x += 1
			b -= 1

		x = 0
		y += 1
		c -= 1
		d += GLBL_WIDTH

	return a

def make_map():
	global MAP_TILE
	
	b = (MAP_TILE >> 8) & 0xFF
	a = MAP_TILE & 0xFF
	MAP_TILE += 1
	map_file.write( bytes([b,a]) )
		

def clist_srch(a):
	global clist
	b = False
	c = 0

	d = len(clist)/2
	e = 0
	while d:
		if clist[e] == a:
			b = True
			c = clist[e+1]
			return b,c
		e += 2
		d -= 1
		
	return b,c

def show_int(value):
	b = str(value)
	c = (3-len(b))
	a = (str("0")*c+str(b))
	int(a,16)
	return a

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

#if len(sys.argv) != 2:
	#print("Usage: inputfile outputfile")
	#exit()
	
#if os.path.exists(sys.argv[1]) == False:
	#print("Input file not found")
	#exit()

#input_file  = open(sys.argv[1],"rb")
#MASTERNAME  = sys.argv[1][:-4]
#USER_HEIGHT = int(sys.argv[2])

#key_frames  = open(MASTERNAME+"_keys.bin","wb")

#======================================================================
# -------------------------------------------------
# Read headers
# -------------------------------------------------

#    0  -  No image data included.
#    1  -  Uncompressed, color-mapped images.
#    2  -  Uncompressed, RGB images.
#    3  -  Uncompressed, black and white images.
#    9  -  Runlength encoded color-mapped images.
#   10  -  Runlength encoded RGB images.
#   11  -  Compressed, black and white images.
#   32  -  Compressed color-mapped data, using Huffman, Delta, and
#          runlength encoding.
#   33  -  Compressed color-mapped data, using Huffman, Delta, and
#          runlength encoding.  4-pass quadtree-type process.
  
#input_file.seek(1)
#color_type = ord(input_file.read(1))
#image_type = ord(input_file.read(1))

## start checking
##print("CURRENT IMAGE TYPE: "+hex(image_type))

##if color_type == 1:
	##print("FOUND PALETTE")
#pal_start = ord(input_file.read(1))
#pal_start += ord(input_file.read(1)) << 8
#pal_len = ord(input_file.read(1))
#pal_len += ord(input_file.read(1)) << 8
#ignore_this = ord(input_file.read(1))
	
##if image_type == 1:
	##print("IMAGE TYPE 1: Indexed")
#img_xstart = ord(input_file.read(1))
#img_xstart += ord(input_file.read(1)) << 8
#img_ystart = ord(input_file.read(1))
#img_ystart += ord(input_file.read(1)) << 8
#img_width = ord(input_file.read(1))
#img_width += ord(input_file.read(1)) << 8
#img_height = ord(input_file.read(1))
#img_height += ord(input_file.read(1)) << 8
	
#img_pixbits = ord(input_file.read(1))
#img_type = ord(input_file.read(1))

##======================================================================
# -------------------------------------------------
# Picture
# -------------------------------------------------

FRAMES = 490
frmtag = 1

pal_file = open("pal_mars.bin","wb")
a = 0x0000
b = 32
while b:
	pal_file.write(bytes([a>>8&0xFF,a&0xFF]))
	a += 0x0421
	b -= 1
pal_file.close()

map_file = open("rle_head.bin","wb")
art_file = open("rle_data.bin","wb")
rle_head_cntr = 0
frame_curr = 0
width_trgt = 0
checksum_list = list()
last_map = 0
while FRAMES:
	input_file = open("frames/"+str(show_int(frmtag))+".tga","rb")
	#print("frames/"+str(show_int(frmtag))+".tga")
	
	input_file.seek(0,2)
	this_size = input_file.tell()
	rle_count = 0
	rle_indx  = 0
	

	
	# checksum
	new_frame = False
	input_file.seek(0x12)
	c = this_size-0x2C
	a = 0
	while c:
		a += ord(input_file.read(1)) & 0xFF
		c -= 1

	if a in checksum_list:
		b = checksum_list.index(a) + 1
		new_frame = False
		c = checksum_list[b]
		print(str(show_int(frmtag))+" DUPLICATE: "+str(hex(c)))
	else:
		c = art_file.tell()
		last_map = c
		new_frame = True
		checksum_list.append(a)
		checksum_list.append(c)
		
	map_file.write(bytes([c>>24&0xFF,c>>16&0xFF,c>>8&0xFF,c&0xFF]))	
	
	#print(checksum_list)
	if new_frame == True:
		d = -1
		input_file.seek(0x12)
		decomp = this_size-0x2C
		width_count = 0
		rle_index = -1
		while decomp:

			# RLE pack
			a = ord(input_file.read(1))
			if (a & 0x80) == 0x80:
				b = ord(input_file.read(1)) >> 3
				#if d == 0x7E:
					#rle_count = (d+1)+((a&0x7F)+1)
					#art_file.seek(-2,1)
					#decomp -= 2
					#d = -1
				#else:
				rle_count = (a&0x7F)
				rle_index = b
				d = rle_count
				decomp -= 2
				width_count += (a&0x7F)+1
				art_file.write(bytes([rle_count&0xFF,rle_index&0xFF]))
					
			# raw pack
			else:
				f = a+1
				decomp -= f+1
				while f:
					a = ord(input_file.read(1)) >> 3
					art_file.write(bytes([0&0xFF,a&0xFF]))
					width_count += 1
					f -= 1
			#if width_count >= 320:
				#width_count = 0
				#print("GOT IT",hex(width_count))

	frmtag += 1
	FRAMES -= 1
	input_file.close()

c = art_file.tell()
map_file.write(bytes([c>>24&0xFF,c>>16&0xFF,c>>8&0xFF,c&0xFF]))
map_file.close()
art_file.close()

#======================================================================
# ----------------------------
# End
# ----------------------------

print("Done.")

input_file.close()
#key_frames.close()
