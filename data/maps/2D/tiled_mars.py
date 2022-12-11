#======================================================================
# Tiled level to MD
#
# tiled_md.py tmx_file out_folder tga_file
#======================================================================

import sys
import os.path
import xml.etree.ElementTree as ET

#======================================================================
# -------------------------------------------------
# Settings
# -------------------------------------------------

# False: Normal mode
# True: Compress prizes (the "prizes" layer MUST be included)
RLE_PRIZES  = False

# False: Normal mode
# True: Auto-alignfix for Interlace Double mode
#DOUBLE_MODE = False

# False: layout data is on bytes (0-255)
# True: layout data is on words (0-65535)
WIDE_LAYOUT = False

# False: don't write a blank tile
# True: make blank tile at start
BLANK_CELL  = True
# Values
VRAM_ZERO   = 0		# Blank tile
VRAM_START  = 1		# Start at
VRAM_STARTD = 2		# for Double mode
VRAM_MAX    = 0x5FF	# Max VRAM to use

#======================================================================
# -------------------------------------------------
# Subs
# -------------------------------------------------

def make_block(XPOS,YPOS):
	global IMG_WIDTH
	#XPOS = XPOS
	YPOS = (IMG_WIDTH*YPOS)

	d = image_addr+XPOS+YPOS
	c = TILE_HEIGHT
	while c:
		input_file.seek(d)
		b = TILE_WIDTH
		while b:
			a = (ord(input_file.read(1)) & 0xFF)
			out_art.write( bytes([a]) )
			b -= 1

		c -= 1
		d += IMG_WIDTH

def chk_block(XPOS,YPOS):
	global IMG_WIDTH
	YPOS = (IMG_WIDTH * YPOS)
	a = 0
	d = image_addr+XPOS+YPOS
	c = TILE_HEIGHT
	while c:
		input_file.seek(d)
		b = TILE_WIDTH
		while b:
			e = (ord(input_file.read(1)) & 0xFF)
			if e != 0:
				a = 1
			b -= 1

		c -= 1
		d += IMG_WIDTH

	return a

def seek_cell(x,y):
  x = x<<3
  y = y*(IMG_WIDTH*8)

  out_offset=x+y
  return(out_offset)

def chks_make(lay):
  d7 = 0
  d5 = 0

  d4 = 0
  d1 = 8
  while d1:
    input_file.seek(lay)
    d2 = 8
    while d2:
      byte = ord(input_file.read(1))
      if byte != 0:
        d3 = byte + d4 + d5 + d7
        d7 += d3
      d4 += 1
      d2 -= 1

    d4 = 0
    d5 += 1
    lay += IMG_WIDTH
    d1 -= 1

  return(d7)

def clist_srch(a,f):
	global clist
	b = False
	c = 0

	d = len(clist)/f
	e = 0
	while d:
		if clist[e] == a:
			b = True
			c = e#clist[e+1]
			return b,c
		e += f
		d -= 1

	return b,c

#======================================================================
# -------------------------------------------------
# Convert blocks
# -------------------------------------------------

# ------------------------------------

clist = list()
przrle	= [0,0]

# ------------------------------------

if len(sys.argv) != 4:
	print("Usage: inputfile outfolder tgafile(s)")
	exit()

if os.path.exists(sys.argv[1]) == False:
	print("Input file not found")
	exit()

MASTERNAME = sys.argv[1][:-4]
PROJFOLER = sys.argv[2]

if not os.path.exists(PROJFOLER):
	os.makedirs(PROJFOLER)

#======================================================================
# -------------------------------------------------
# Make mini head
# -------------------------------------------------

input_file = open(sys.argv[1],"r")
input_file.seek(0)
a = input_file.read().find('<map version="1.9"')
if a != -1:
	input_file.seek(a)
	b = input_file.tell()
	a = input_file.read().find('>')
	input_file.seek(b+1)
	a = input_file.read(a-1).split()

	#if a[2] != 'tiledversion="1.1.4"':
		#print("invalid Tiled version")
		#input_file.close()
		#quit()
	if a[3] != 'orientation="orthogonal"':
		print("invalid orientation: should be orthogonal")
		input_file.close()
		quit()
	if a[4] != 'renderorder="right-down"':
		print("invalid layout order: should be right-down")
		input_file.close()
		quit()

	width = a[5].split('"')
	height = a[6].split('"')
	blkwidth = a[7].split('"')
	blkheight = a[8].split('"')

	TILE_WIDTH = int(blkwidth[1])
	TILE_HEIGHT = int(blkheight[1])
	LAY_WIDTH = int(width[1])
	LAY_HEIGHT = int(height[1])
	#print(hex(LAY_WIDTH),hex(LAY_HEIGHT))
	out_head = open(PROJFOLER+"/"+"m_head.bin","wb")

	# make LSL value
	c = 0x10
	LAY_LSLW = 1
	d = True
	while d:
		#print(c)
		e = c-LAY_WIDTH
		if e > 0:
			d = False
			break
		LAY_LSLW += 1
		c = c << 1

	## make special WIDTH value
	#LAY_INTRW = 0x10
	#d = True
	#while d:
		#e = LAY_INTRW-LAY_WIDTH
		#if e > 0:
			#d = False
			#break
		#LAY_INTRW = LAY_INTRW << 1

	# write header
	# lay_width,lay_height,
	out_head.write( bytes([ int((LAY_WIDTH>>8)&0xFF),int(LAY_WIDTH&0xFF),
				int((LAY_HEIGHT>>8)&0xFF),int(LAY_HEIGHT&0xFF),
				int(TILE_WIDTH&0xFF),
				int(TILE_HEIGHT&0xFF)
				#int((LAY_INTRW>>8)&0xFF),int(LAY_INTRW&0xFF),
				#int((LAY_LSLW>>8)&0xFF),int(LAY_LSLW&0xFF)
				]) )

	# Layout Flags
	#a = 0
	#if WIDE_LAYOUT == True:
		#a = 0x40 #bitWide bit 6
	#out_head.write( bytes([a>>8,a]) )
	#out_head.close()

#======================================================================
# -------------------------------------------------
# Convert layout
# -------------------------------------------------

input_file.seek(0)
layer_tiletops = list()
tree = ET.parse(sys.argv[1])
root = tree.getroot()
for a in root.findall('tileset'):
	#b = a.find('data').text.replace("\n","")
	layer_tiletops.append(int(a.get('firstgid')))
#print(layer_tiletops)

max_layers = 0
input_file.seek(0)
layer_tags = list()
layer_data = list()
tree = ET.parse(sys.argv[1])
root = tree.getroot()
for a in root.findall('layer'):
	b = a.find('data').text.replace("\n","")
	layer_tags.append(a.get('name'))
	layer_data.append(b)
	max_layers += 1
#print(layer_data)

cntr_lyrs = max_layers
indx_lyrs = 0
while cntr_lyrs:
	lyr_file = open(PROJFOLER+"/"+layer_tags[indx_lyrs]+".bin","wb")

	#lyr_read = layer_data[indx_lyrs].split(",")
	#indx_blk = 0

	#curr_hght = LAY_HEIGHT
	#this_line = 0
	#while curr_hght:
		#curr_hght -= 1

		## calculate auto-width
		#c = 0x10
		#d = True
		#while d:
			#e = c-LAY_WIDTH
			#if e > 0:
				#d = False
				#break
			#c = c << 1
		#b = int(c)
		#a = [0]*b	# make fixed line
		#curr_wdth = LAY_WIDTH
		#in_wdth = 0
		#while curr_wdth:
			#b = int(lyr_read[in_wdth+this_line])
			#c = len(layer_tiletops)
			#d = c-1
			#while c:
				#if b > layer_tiletops[d]-1:
					#b -= layer_tiletops[d]-1
					#break
				#d -= 1
				#c -= 1

			## b = block byte
			#a[in_wdth] = b
			#in_wdth += 1
			#curr_wdth -= 1
		#lyr_file.write(bytes(a))

		#this_line += LAY_WIDTH






	a = layer_data[indx_lyrs].split(",")
	b = len(a)
	e = 0
	while b:
		lyr_data = int(a[e])
		if lyr_data != 0:
			h = len(layer_tiletops)
			g = h-1
			while h:
				if lyr_data > layer_tiletops[g]-1:
					lyr_data -= layer_tiletops[g]-1
					break
				g -= 1
				h -= 1

		if WIDE_LAYOUT == True:
			lyr_file.write(bytes([ f>>8&0xFF , f&0xFF ]))
		else:
			if lyr_data > 255:
				print("WARNING: ran out of bytes, value:",hex(lyr_data))
				lyr_data = lyr_data&0xFF
			lyr_file.write(bytes([ lyr_data&0xFF ]))
			#print("LEL")
		e += 1
		b -= 1

	lyr_file.close()
	indx_lyrs += 1  # next layer
	cntr_lyrs -= 1	# decrement counter

#======================================================================
# -------------------------------------------------
# Compress Prizes to RLE
# -------------------------------------------------

if RLE_PRIZES == True:
	in_prz = open(PROJFOLER+"/"+"prizes"+".bin","rb")
	out_prz = open(PROJFOLER+"/"+"prizes_rle"+".bin","wb")
	in_prz.seek(0,os.SEEK_END)
	c = in_prz.tell()
	in_prz.seek(0)

	while c:
		a = ord(in_prz.read(1)) & 0xFF
		c -= 1

		b = przrle[1]
		if b != a:
			przrle[0] = 0
			out_prz.seek(+2,1)

		przrle[1] = a
		przrle[0] +=1
		if przrle[0] > 0xFE:
			przrle[0] = 1
			out_prz.seek(+2,1)
		out_prz.write( bytes([ int(przrle[0]&0xFF) ]))
		out_prz.write( bytes([ int(przrle[1]&0xFF) ]))
		out_prz.seek(-2,1)

	out_prz.seek(+2,1)
	out_prz.write( bytes([0xFF]))
	out_prz.close()
	in_prz.close()

#======================================================================
# -------------------------------------------------
# Convert objects
# -------------------------------------------------

input_file.seek(0)
has_objects = False

c = input_file.tell()
b = input_file.read()
a = b.find("<objectgroup")
if a != -1:
	input_file.seek( (c+a)+1 )

	c = input_file.tell()
	b = input_file.read()
	a = b.find('<object')
	if a != -1:
		has_objects = True
		input_file.seek( c+a )
		c = input_file.tell()
		b = input_file.read()
		flen = b.find("</objectgroup>")
		input_file.seek( c )

		d = 0
		b = input_file.read(flen).replace("<","").replace("/>","").replace("\n","").split()
		e = len(b)

		OBJ_NAME = list()
		OBJ_X    = list()
		OBJ_Y    = list()
		OBJ_TYPE = list()

		f = -1
		while e:
			c = b[d].replace("=","").split('"')
			if c[0] == "id":
				f += 1
				OBJ_NAME.append(0)
				OBJ_TYPE.append(0)
				OBJ_X.append(0)
				OBJ_Y.append(0)

			if c[0] == "name":
				OBJ_NAME[f] = c[1]
			if c[0] == "type":
				OBJ_TYPE[f] = c[1]
			if c[0] == "x":
				OBJ_X[f] = int(float(c[1]))
			if c[0] == "y":
				OBJ_Y[f] = int(float(c[1]))
			d += 1
			e -= 1

	out_obj = open(PROJFOLER+"/"+"objects"+".asm","w")
	if has_objects == True:
		a = len(OBJ_NAME)
		b = 0
		while a:
			out_obj.write("\t\tdc.l "+OBJ_NAME[b]+"\n")
			out_obj.write("\t\tdc.w "+str(OBJ_X[b])+","+str(OBJ_Y[b])+"\n")
			out_obj.write("\t\tdc.w "+str(OBJ_TYPE[b])+","+"0"+"\n")
			b += 1
			a -= 1

	out_obj.write("\t\tdc.l -1\n")
	out_obj.close()

input_file.close()


input_file = open(sys.argv[3],"rb")
out_art    = open(PROJFOLER+"/"+"m_art.bin","wb")
out_pal    = open(PROJFOLER+"/"+"m_pal.bin","wb")

input_file.seek(0x5)					#$05, palsize
a = ord(input_file.read(1)) & 0xFF
b = ord(input_file.read(1)) & 0xFF
a = a | (b << 8)
size_pal = a

input_file.seek(0xC)					#$0C, xsize,ysize (little endian)
x_r = ord(input_file.read(1))
x_l = (ord(input_file.read(1))<<8)
IMG_WIDTH = x_l+x_r
y_r = ord(input_file.read(1))
y_l = (ord(input_file.read(1))<<8)
IMG_HEIGHT = (y_l+y_r)

a = IMG_WIDTH&7
b = IMG_HEIGHT&7
c = "X SIZE IS MISALIGNED"
d = "Y SIZE IS MISALIGNED"
e = " "
f = " "
g = False
if a != 0:
  print( hex(a) )
  e = c
  g = True
if b !=0:
  f = d
  g = True

if g == True:
  print( "WARNING:",e,f )

# ----------------------
# Write palette
# ----------------------

input_file.seek(0x12)
d0 = size_pal
while d0:
  b = ord(input_file.read(1))
  g = ord(input_file.read(1))
  r = ord(input_file.read(1))

  r = (r>>3)&0x1F
  g = (g>>3)&0x1F
  b = (b>>3)&0x1F

  r = (g<<5)+r & 0xFF
  b = (g>>3)+(b<<2) & 0xFF

  #print(hex(b),hex(r))

  out_pal.write( bytes([b,r]) )
  d0 -= 1

# ----------------------
# Make NULL block
# ----------------------

out_art.write(bytes(TILE_WIDTH*TILE_HEIGHT))

#======================================================================
# -------------------------------------------------
# Convert TGA
# -------------------------------------------------

# --------------------------------
# NORMAL MODE
# --------------------------------

image_addr=input_file.tell()
y_pos=0
cell_y_size=IMG_HEIGHT/TILE_HEIGHT
while cell_y_size:
	x_pos=0
	cell_x_size=IMG_WIDTH/TILE_WIDTH
	while cell_x_size:
		# ----

		#a = chk_block(x_pos,y_pos)
		#if a != 0:
		make_block(x_pos,y_pos)

		# ----
		x_pos += TILE_WIDTH
		cell_x_size -= 1
	y_pos += TILE_HEIGHT
	cell_y_size -= 1

    #x_pos=0
    #cell_x_size=IMG_WIDTH/TILE_WIDTH
    #while cell_x_size:
      #x_at = 0
      #x_size = TILE_WIDTH>>3
      #while x_size:
        #y_at = 0
        #y_size = TILE_HEIGHT>>3
        #while y_size:
          #d1 = VRAM_ZERO & 0x7FF
          #d2 = 0
          #d4 = 0
          #d5 = 4
          #while d5:
            #d2 = chk_block(x_pos+x_at,y_pos+y_at,d4)
            #if d2 != 0:
              #d3 = d4
              #d5 = False
              #break
            #d4 += 1
            #d5 -= 1
          #if d2 != 0:
            #if clist_srch(d2,2)[0] == True:
              #d7=clist_srch(d2,2)[1]
              #d1=clist[d7+1]
            #else:
              #make_block(x_pos+x_at,y_pos+y_at,d3)
              #cells_used += 1
              #if last_warn == False:
                #if cells_used > VRAM_MAX:
                  #print("WARNING: ran out of vram, ignoring new cells")
                  #map_vram = 0
                  #last_warn = True
              #d3 = d3 << 13
              #d1=map_vram|d3
              #clist.append(d2)
              #clist.append(d1)
              #map_vram+=1
          #out_map.write( bytes([(d1>>8)&0xFF,d1&0xFF]) )
          #y_at += 1
          #y_size -= 1
        #x_at += 1
        #x_size -= 1

      #x_pos += TILE_WIDTH>>3
      #cell_x_size -= 1

    #y_pos += TILE_HEIGHT>>3
    #cell_y_size -= 1

print("Done.")
input_file.close()
out_art.close()
out_pal.close()
#out_map.close()
