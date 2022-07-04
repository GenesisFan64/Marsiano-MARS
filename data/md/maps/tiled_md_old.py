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
DOUBLE_MODE = True

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

def make_cell(XPOS,YPOS,COLOR):
	global IMG_WIDTH
	XPOS = XPOS * 8
	YPOS = (IMG_WIDTH * YPOS) * 8
	
	d = image_addr+XPOS+YPOS
	c = 8
	while c:
		input_file.seek(d)
		b = 4
		while b:
			a = 0
			e = (ord(input_file.read(1)) & 0xFF)
			f = (ord(input_file.read(1)) & 0xFF)
			
			g = e >> 4
			if g == COLOR:
				a = (e << 4) & 0xF0
			g = f >> 4
			if g == COLOR:
				a += f & 0x0F	
				
			#a = (ord(input_file.read(1)) & 0x0F) << 4
			#a += (ord(input_file.read(1)) & 0x0F)
			out_art.write( bytes([a]) )
			b -= 1	
		
		c -= 1
		d += IMG_WIDTH
		
def chk_cell(XPOS,YPOS,COLOR):
	global IMG_WIDTH
	XPOS = XPOS * 8
	YPOS = (IMG_WIDTH * YPOS) * 8
	a = 0
	d = image_addr+XPOS+YPOS
	
	x = 0
	y = 0
	
	c = 8
	while c:
		input_file.seek(d)
		b = 8
		while b:
			f = (ord(input_file.read(1)) & 0xFF)
			
			g = f >> 4
			if g == COLOR:
				if DOUBLE_MODE == True:
					if (f & 0x0F) != 0:
						a += a + x + y + (f & 0x0F)
				else:
					a += a + (f & 0x0F)
			#z += x + y
			
			x += 1
			b -= 1

		x = 0
		y += 1
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

cells_used = 0
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
a = input_file.read().find('<map version="1.8"')
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
	out_head = open(PROJFOLER+"/"+"head.bin","wb")
	out_head.write( bytes([ int((LAY_WIDTH>>8)&0xFF),int(LAY_WIDTH&0xFF),
				int((LAY_HEIGHT>>8)&0xFF),int(LAY_HEIGHT&0xFF),
				int((TILE_WIDTH>>8)&0xFF),int(TILE_WIDTH&0xFF),
				int((TILE_HEIGHT>>8)&0xFF),int(TILE_HEIGHT&0xFF)
				]) )
	
	# Layout Flags
	a = 0
	if WIDE_LAYOUT == True:
		a = 0x40 #bitWide bit 6
	out_head.write( bytes([a>>8,a]) )
	out_head.close()
	
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

d = max_layers
c = 0
while d:
	lyr_file = open(PROJFOLER+"/"+layer_tags[c]+".bin","wb")
	a = layer_data[c].split(",")
	b = len(a)
	e = 0
	while b:
		f = int(a[e])
		if f != 0:
			h = len(layer_tiletops)
			g = h-1
			while h:
				if f > layer_tiletops[g]-1:
					f -= layer_tiletops[g]-1
					break
				g -= 1
				h -= 1
				
		if WIDE_LAYOUT == True:
			lyr_file.write(bytes([ f>>8&0xFF , f&0xFF ]))
		else:
			if f > 255:
				print("WARNING: ran out of bytes, value:",hex(f))
				f = f&0xFF
			lyr_file.write(bytes([ f&0xFF ]))
			#print("LEL")
		e += 1
		b -= 1
		
	lyr_file.close()
	c += 1
	d -= 1
	
#print( layer_tags )
#print( layer_data[0] )

#e = 0
#c = input_file.tell()
#d = True
#while d:
	#b = input_file.read()
	#a = b.find("<layer")
	#if a == -1:
		#d = False

	#if e != a+c:
		#layer_tags.append(a+c)
		#e = a+c
		#max_layers += 1

	#c += 1
	#input_file.seek( c )

#lastwarn = False
#entry = 0
#while max_layers:
	#input_file.seek( layer_tags[entry] )
	#layer = input_file.read()
	#input_file.seek( layer_tags[entry] )
	#flen = layer.find("</data>")
	#this = input_file.read(flen)

	#pstuff = this.replace("\n","")
	#stuff = this.replace("\n","").replace("</data","").split(">")

	#lyrhead = stuff[0].split('"') # entries: name[1], width[3], height[5]
	#lyrcsv = stuff[1].split('"') # entry 1
	#lyrdata = stuff[2]

	#if lyrcsv[1] != "csv":
		#print("Error: level format is not CSV")
		#break

	#else:
		#lyr_file = open(PROJFOLER+"/"+lyrhead[1]+".bin","wb")
		#a = lyrdata.split(",")
		#b = len(a)
		#c = 0
		#while b:
			#b -= 1
			#e = int(a[c])
			#if WIDE_LAYOUT == True:
				#d = e&0xFFFF
				#lyr_file.write( bytes([ (d>>8)&0xFF,d&0xFF ]))
			#else:
				#d = e&0xFF
				#if lastwarn == False:
					#if e > 256:
						#print("WARNING: ran out of layout bytes (max 255)")
						#lastwarn = True
				#lyr_file.write( bytes([ d ]))

			#c += 1
		#lyr_file.close()

	#entry += 1
	#max_layers -= 1

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

#d0 = "map16.tga"
#d0 = sys.argv[2]
input_file = open(sys.argv[3],"rb")
out_art    = open(PROJFOLER+"/"+"art.bin","wb")
out_pal    = open(PROJFOLER+"/"+"pal.bin","wb")
out_map    = open(PROJFOLER+"/"+"blocks.bin","wb")

input_file.seek(0x5)					#$05, palsize
size_pal = ord(input_file.read(1))

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
  r = r >> 5
  r = r << 1
  g = g >> 5
  g = g << 1
  b = b >> 5
  b = b << 1
  g = g << 4
  gr = g+r
  out_pal.write( bytes([b]) )
  out_pal.write( bytes([gr]))
  d0 -= 1

# ----------------------
# Make NULL block
# ----------------------

if DOUBLE_MODE == True:
  if TILE_HEIGHT & 8:
    print("INVALID HEIGHT FOR DOUBLE MODE")
    input_file.close()
    out_art.close()
    out_pal.close()
    out_map.close()
    exit()
  else:
   if BLANK_CELL == True:
     out_art.write(  bytes(0x40) )
     #VRAM_STARTD += 2
   map_vram = VRAM_STARTD
   a = int( (TILE_WIDTH>>3)*(TILE_HEIGHT>>3) )
   b = VRAM_ZERO&0x7FE >> 8 & 0xFF
   c = VRAM_ZERO&0x7FE & 0xFF
   d = VRAM_ZERO&0x7FE+1 >> 8 & 0xFF
   e = VRAM_ZERO&0x7FE+1 & 0xFF
   
   a = a >> 1
   out_map.write(  bytes([b,c,d,e]*(a)) )

else:
  if BLANK_CELL == True:
    out_art.write(  bytes(0x20) )
    #VRAM_START += 1
  map_vram = VRAM_START
  a = int( (TILE_WIDTH>>3)*(TILE_HEIGHT>>3) )
  b = VRAM_ZERO >> 8 & 0xFF
  c = VRAM_ZERO & 0xFF
  out_map.write(  bytes([b,c]*(a)) )
  
#======================================================================
# -------------------------------------------------
# Convert tga
# -------------------------------------------------

cells_used = 0
x_pos = 0
y_pos = 0
image_addr=input_file.tell()
last_warn = False

# --------------------------------
# DOUBLE MODE
# --------------------------------

if DOUBLE_MODE == True:
  if TILE_HEIGHT & 8 == True:
    print("INVALID HEIGHT FOR DOUBLE MODE")
    input_file.close()
    out_art.close()
    out_pal.close()
    out_map.close()
    exit()
  
  y_pos=0
  cell_y_size=IMG_HEIGHT/TILE_HEIGHT
  while cell_y_size:
    x_pos=0
    cell_x_size=IMG_WIDTH/TILE_WIDTH
    while cell_x_size:
      x_at = 0
      x_size = TILE_WIDTH>>3
      while x_size:
        y_at = 0
        y_size = TILE_HEIGHT>>4 #TILE_HEIGHT>>3
        while y_size:
          d3 = 0
          d4 = 0
          
          d1 = VRAM_ZERO & 0x7FE
          d2 = VRAM_ZERO & 0x7FE
          d6 = 4
          while d6:
            d5 = chk_cell(x_pos+x_at,y_pos+y_at,d4) | chk_cell(x_pos+x_at,y_pos+(y_at+1),d4)
            if d5 != 0:
              d3 = d4
              d6 = False
              break
            d4 += 1	  
            d6 -= 1
          if d5 != 0:
            #if clist_srch(d5,3)[0] == True:
              #d7=clist_srch(d5,3)[1]
              #d1=clist[d7+1]
              #d2=clist[d7+2]
              ##print("FOUND DOUBLE",hex(d1),hex(d2))
            #else:  
            if last_warn == False:
              make_cell(x_pos+x_at,y_pos+y_at,d3)
              make_cell(x_pos+x_at,y_pos+(y_at+1),d3)
              cells_used += 2
              if cells_used > VRAM_MAX:
                print("WARNING: ran out of vram, ignoring new cells")
                map_vram = 0
                last_warn = True
                  
              d3 = d3 << 13
              d1=map_vram|d3
              d2=(map_vram+1)|d3
              clist.append(d5)
              clist.append(d1)
              clist.append(d2)
              map_vram+=2
          out_map.write( bytes([(d1>>8)&0xFF,d1&0xFF]) )
          out_map.write( bytes([(d2>>8)&0xFF,d2&0xFF]) )
          y_at += 2
          y_size -= 1
        x_at += 1
        x_size -= 1
        
      x_pos += TILE_WIDTH>>3
      cell_x_size -= 1
      
    y_pos += TILE_HEIGHT>>3
    cell_y_size -= 1
  
# --------------------------------
# NORMAL MODE
# --------------------------------
else:
  y_pos=0
  cell_y_size=IMG_HEIGHT/TILE_HEIGHT	
  while cell_y_size:
    x_pos=0
    cell_x_size=IMG_WIDTH/TILE_WIDTH
    while cell_x_size:
      x_at = 0
      x_size = TILE_WIDTH>>3
      while x_size:
        y_at = 0
        y_size = TILE_HEIGHT>>3
        while y_size:
          d1 = VRAM_ZERO & 0x7FF
          d2 = 0
          d4 = 0
          d5 = 4
          while d5:
            d2 = chk_cell(x_pos+x_at,y_pos+y_at,d4)
            if d2 != 0:
              d3 = d4
              d5 = False
              break
            d4 += 1	  
            d5 -= 1
          if d2 != 0:
            if clist_srch(d2,2)[0] == True:
              d7=clist_srch(d2,2)[1]
              d1=clist[d7+1]
            else:
              make_cell(x_pos+x_at,y_pos+y_at,d3) #write_cell(image_addr+seek_cell(x_pos+x_at,y_pos+y_at))
              cells_used += 1
              if last_warn == False:
                if cells_used > VRAM_MAX:
                  print("WARNING: ran out of vram, ignoring new cells")
                  map_vram = 0
                  last_warn = True
              d3 = d3 << 13
              d1=map_vram|d3
              clist.append(d2)
              clist.append(d1)
              map_vram+=1
          out_map.write( bytes([(d1>>8)&0xFF,d1&0xFF]) )
          y_at += 1
          y_size -= 1
        x_at += 1
        x_size -= 1
        
      x_pos += TILE_WIDTH>>3
      cell_x_size -= 1
      
    y_pos += TILE_HEIGHT>>3
    cell_y_size -= 1
  
print("Used VRAM:",hex(cells_used))
print("Done.")
input_file.close()
out_art.close()
out_pal.close()
out_map.close()
