#======================================================================
# MD AUTOSPRITE
#
# v6
#======================================================================

import sys
import os.path

#======================================================================

# Set this to True to use DPLC (format: Sonic 2)
PLC_MODE  = True

# 0 for Sonic series, 1 for custom
PLC_TYPE  = 0

# False for Sonic 1
# True  for Sonic 2
MAPS_ALT = False

# False for normal mode
# True  for interlace mode optimization (x8 and x24 replaced with x16 and x32 plus a blank cell)
ART_DUAL = False

# For doing separate sprites (last moment changes)
DONT_LIST = False
START_CNT = 0

#======================================================================
# -------------------------------------------------
# Subs
# -------------------------------------------------

#def get_val(string_in):
  #got_this_str=""
  #for do_loop_for in string_in:
    #got_this_str = got_this_str + ("0"+((hex(ord(do_loop_for)))[2:]))[-2:]
  #return(got_this_str)

def write_line(in_offset):
  input_file.seek(in_offset)

  a = int(ord(input_file.read(1))) & 0x0F
  b = int(ord(input_file.read(1))) & 0x0F
  c = int(ord(input_file.read(1))) & 0x0F
  d = int(ord(input_file.read(1))) & 0x0F
  e = int(ord(input_file.read(1))) & 0x0F
  f = int(ord(input_file.read(1))) & 0x0F
  g = int(ord(input_file.read(1))) & 0x0F
  h = int(ord(input_file.read(1))) & 0x0F

  a = a << 4
  a = a+b
  c = c << 4
  c = c+d
  e = e << 4
  e = e+f
  g = g << 4
  g = g+h

  output_art.write(bytes([a]))
  output_art.write(bytes([c]))
  output_art.write(bytes([e]))
  output_art.write(bytes([g]))

def write_cell(cell_off):
  rept = 8
  while rept:
    write_line(cell_off)
    cell_off += max_width
    rept -= 1

def seek_cell(x,y):
  x = x << 3
  y = y * (max_width*8)

  out_offset=x+y
  return(out_offset)

def check_cell(lay):
  d7 = 0

  d1 = 8
  while d1:
    input_file.seek(lay)
    d2 = 8
    while d2:
      a = ord(input_file.read(1))
      byte = a & 0x0F
      d7 += byte
      d2 -= 1
    lay += max_width
    d1 -= 1

  return(d7)

def cell_list_filter(in_x,in_y):
        out_x = 0
        out_y = 0
        indx_entry = 0
        found_it = False
        indx_list = 0
        len_list = len(cell_list)
        while len_list:
                srch_x = cell_list[indx_list]
                srch_y = cell_list[indx_list+1]
                if srch_x == in_x:
                        if srch_y == in_y:
                                found_it=True
                                indx_entry = indx_list
                indx_list +=2
                len_list -= 2

        return(found_it,indx_entry)

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

max_width      = 32
max_height     = 48
cell_used      = 0
vram_entry     = 0
frame_size     = 0
cell_list      = list()
sprpos_x_list  = [0xC0,0xC8,0xD0,0xD8,0xE0,0xE8,0xF0,0xF8,0x00,0x08,0x10,0x18,0x20,0x28,0x30,0x38]
sprpos_y_list  = [0xC0,0xC8,0xD0,0xD8,0xE0,0xE8,0xF0,0xF8,0x00,0x08,0x10,0x18,0x20,0x28,0x30,0x38]#[0x94,0x9C,0xA4,0xAC,0xB4,0xBC,0xC4,0xCC,0xD4,0xDC,0xE4,0xEC,0xF4,0xFC,0x04,0x0C]
frame_curr     = 0+START_CNT
frames         = 1
dual_size3_fix = 0

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

if len(sys.argv) == 1:
	print("Usage: inputfile outputfile")
	exit()

if os.path.exists(sys.argv[1]) == False:
	print("Input file not found")
	exit()

MASTERNAME = sys.argv[1][:-4]
input_file = open(sys.argv[1],"rb")

#input_file  = open("test.tga","rb")
output_art  = open(MASTERNAME+"_art.bin","wb")
output_map  = open(MASTERNAME+"_map.asm","w")
out_pal     = open(MASTERNAME+"_pal.bin","wb")
output_mapd = open("1.tmp","w+")
if DONT_LIST == False:
  output_map.write(".mappings:\n")

if PLC_MODE == True:
  dplc_cell = 0
  dplc_req_list = [0x00,0x10,0x20,0x30,0x10,0x30,0x50,0x70,0x20,0x50,0x80,0xB0,0x30,0x70,0xB0,0xF0]
  output_dplc  = open(MASTERNAME+"_plc.asm","w")
  output_dplcd = open("2.tmp","w+")
  if DONT_LIST == False:
    output_dplc.write(".dplc:\n")

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

input_file.seek(1)
color_type = ord(input_file.read(1))
image_type = ord(input_file.read(1))

# start checking
#print("CURRENT IMAGE TYPE: "+hex(image_type))

if color_type == 1:
	#print("FOUND PALETTE")
	pal_start = ord(input_file.read(1))
	pal_start += ord(input_file.read(1)) << 8
	pal_len = ord(input_file.read(1))
	pal_len += ord(input_file.read(1)) << 8
	ignore_this = ord(input_file.read(1))
	has_pal = True

if image_type == 1:
	#print("IMAGE TYPE 1: Indexed")
	img_xstart = ord(input_file.read(1))
	img_xstart += ord(input_file.read(1)) << 8
	img_ystart = ord(input_file.read(1))
	img_ystart += ord(input_file.read(1)) << 8
	img_width = ord(input_file.read(1))
	img_width += ord(input_file.read(1)) << 8
	img_height = ord(input_file.read(1))
	img_height += ord(input_file.read(1)) << 8

	img_pixbits = ord(input_file.read(1))
	img_type = ord(input_file.read(1))
	#print( hex(img_type) )

	#0 = Origin in lower left-hand corner
	#1 = Origin in upper left-hand corner
	if (img_type >> 5 & 1) == False:
		print("ERROR: TOP LEFT images only")
		quit()
	has_img = True
else:
	print("IMAGE TYPE NOT SUPPORTED:",hex(image_type))
	quit()

#======================================================================
# ----------------------
# Write palette
# ----------------------

#print ( img_height )
if img_height > max_height:
	frames = img_height/max_height

input_file.seek(0x5)                                        #$05, palsize
size_pal = int(ord(input_file.read(1)))
if size_pal == 0:
  print("SPRITE SHEET MUST BE INDEXED")
  exit()

input_file.seek(0x12)
d0 = size_pal
while d0:
  b = int(ord(input_file.read(1)))
  g = int(ord(input_file.read(1)))
  r = int(ord(input_file.read(1)))
  r = r >> 5
  r = r << 1
  g = g >> 5
  g = g << 1
  b = b >> 5
  b = b << 1
  g = g << 4
  gr = g+r
  out_pal.write(bytes([b]))
  out_pal.write(bytes([gr]))
  d0 -= 1

#======================================================================
# -------------------------------------------------
# Loop
# -------------------------------------------------

frame_dstart = 0
frame_dsize  = 0
offset = input_file.tell()
while frames:

# ----------------------------
# Part 1
# Check cells
# ----------------------------

  print("Frame:",frame_curr)
  #print( hex(input_file.tell()))
  #Loop
  cell_x_find = 0
  x_loop = max_width>>3
  while x_loop:
    cell_y_find = 0
    y_loop = max_height>>3
    while y_loop:
      frame_pos = offset + (seek_cell(cell_x_find,cell_y_find))

      # TEMPORAL
      #is_blank = check_cell(frame_pos)
     # if is_blank > 0:
      cell_list.append(cell_x_find)
      cell_list.append(cell_y_find)

      cell_used += 1
      cell_y_find += 1
      y_loop -= 1
    cell_x_find +=1
    x_loop -=1

# ----------------------------
# Part 2
# Do the mappings
# ----------------------------

  if PLC_MODE == True:
    vram_entry = 0

  #init vals
  cell_list_entry = 0
  output_map.write("\t\tdc.w .frame_")                #.frame_xx-.mappings
  output_map.write(str(frame_curr))
  output_map.write("-.mappings\n")
  off_mapl_last = output_map.tell()

  output_mapd.write(".frame_")                        #.frame_xx:
  output_mapd.write(str(frame_curr))
  output_mapd.write(":\n")

  off_d_size = output_mapd.tell()
  output_mapd.write("\t\tdc.b $")
  output_mapd.write("00")                        #dc.w size (if blank)
  output_mapd.write("\n")
  off_d_entries = output_mapd.tell()

  if PLC_MODE == True:
    output_dplc.write("\t\tdc.w .frame_")        #.frame_xx-.dplc
    output_dplc.write(str(frame_curr))
    output_dplc.write("-.dplc\n")
    off_dplcl_last = output_dplc.tell()

    output_dplcd.write(".frame_")                #.frame_xx:
    output_dplcd.write(str(frame_curr))
    output_dplcd.write(":\n")

    off_d_plc_size = output_dplcd.tell()
    if PLC_TYPE == 0:
      output_dplcd.write("\t\tdc.w $")
      output_dplcd.write("00")                        #dc.w size (if blank)
      output_dplcd.write("\n")
    off_d_plc_entries = output_dplcd.tell()

  mapping=len(cell_list)
  while mapping:
    spr_size_x = 0
    spr_size_y = 0
    cell_temp_list = list()
    start_x = cell_list[cell_list_entry]
    start_y = cell_list[cell_list_entry+1]
    if start_x != -1:
      cell_temp_list.append(start_x)
      cell_temp_list.append(start_y)

      # *********************************************
      # NEW CHECK
      # *********************************************

      next_y=start_y+1
      max_y = 0
      d0 = 3
      while d0:
        if cell_list_filter(start_x,next_y)[0] == True:
          indx = cell_list_filter(start_x,next_y)[1]
          cell_list[indx] = -1
          cell_list[indx+1] = -1
          cell_temp_list.append(start_x)
          cell_temp_list.append(next_y)
          next_y +=1
          spr_size_y += 1
          max_y += 1
          d0 -= 1
        else:
          d0 = False

      next_x=start_x+1
      new_x=start_x+1
      d0 = 3
      while d0:
        if cell_list_filter(next_x,start_y)[0] == True:
          d1=max_y+1
          used_sprcells=0
          new_y = start_y
          while d1:
            if cell_list_filter(next_x,new_y)[0] == True:
              used_sprcells += 1
              new_y += 1
              d1 -= 1
            else:
              d1 = False
            if used_sprcells == max_y+1:
              new_y = start_y
              d2 = max_y+1
              spr_size_x += 1
              spr_size_y = -1
              while d2:
                if cell_list_filter(next_x,new_y)[0] == True:
                  indx = cell_list_filter(next_x,new_y)[1]
                  cell_list[indx] = -1
                  cell_list[indx+1] = -1
                  cell_temp_list.append(next_x)
                  cell_temp_list.append(new_y)
                  new_y +=1
                  spr_size_y += 1
                  d2 -= 1

          next_x +=1
          d0 -= 1
        else:
          d0 = False

      # *********************************************
      # Part 2
      #
      # Writing mappings
      # *********************************************

      d = spr_size_y
      if ART_DUAL == True:
        if spr_size_y == 0:
          d = 1
        if spr_size_y == 2:
          d = 3
      b = spr_size_x << 2
      a = b + d

      frame_size    += 1
      spr_size      = '%x' % a
      sprpos_map_x  = '%x' % sprpos_x_list[cell_list[cell_list_entry]]
      sprpos_map_y  = '%x' % sprpos_y_list[cell_list[cell_list_entry+1]]
      spr_frame_cnt = '%x' % frame_size

      vram_l         = (vram_entry<<8)&0xFF
      vram_r         = (vram_entry)&0xFF
      spr_vram_l     = '%x' % vram_l
      spr_vram_r     = '%x' % vram_r

      output_mapd.seek(off_d_size)
      if MAPS_ALT == True:
        output_mapd.write("\t\tdc.w $")
        output_mapd.write(str(spr_frame_cnt).upper())        #dc.b size
        output_mapd.write("\n")
      else:
        output_mapd.write("\t\tdc.b $")
        output_mapd.write(str(spr_frame_cnt).upper())        #dc.b size
        output_mapd.write("\n")

      output_mapd.seek(off_d_entries)
      output_mapd.write("\t\tdc.b $")                        #Y
      output_mapd.write(str(sprpos_map_y).upper())
      output_mapd.write(",$")                                #Size
      output_mapd.write(str(spr_size).upper())

      output_mapd.write(",$")                                #VRAM
      output_mapd.write(str(spr_vram_l).upper())
      output_mapd.write(",$")                                #VRAM
      output_mapd.write(str(spr_vram_r).upper())

      if MAPS_ALT == True:
        output_mapd.write(",$")                                #VRAM
        output_mapd.write(str(spr_vram_l).upper())
        output_mapd.write(",$")                                #VRAM
        output_mapd.write(str(spr_vram_r).upper())

        a = sprpos_x_list[cell_list[cell_list_entry]]
        output_mapd.write(",$")                                #X
        if a > 127:
            a = a*-1
        a = a >> 8 & 0xFF
        b  = '%x' % a
        output_mapd.write(str(b).upper())
        output_mapd.write(",$")                                #X
        output_mapd.write(str(sprpos_map_x).upper())
      else:
        output_mapd.write(",$")                                #X
        output_mapd.write(str(sprpos_map_x).upper())

      output_mapd.write("\n")
      off_d_entries = output_mapd.tell()

      if PLC_MODE == True:
        d = spr_size_y
        if ART_DUAL == True:
          if spr_size_y == 0:
            d = 1
          if spr_size_y == 2:
            d = 3
        b = spr_size_x << 2
        a = b + d
        c = dplc_req_list[a]

        if PLC_TYPE == 1:
          #output_dplcd.write("\n")
          frame_dsize += (c)+0x10

        else:
          plc_size = '%x' % c
          plc_cell = '%x' % dplc_cell
          output_dplcd.seek(off_d_plc_size)
          output_dplcd.write("\t\tdc.w $")
          output_dplcd.write(str(spr_frame_cnt).upper())
          output_dplcd.write("\n")

          output_dplcd.seek(off_d_plc_entries)
          output_dplcd.write("\t\tdc.w $")
          d = c << 8
          e = d + dplc_cell
          f = '%x' % e
          output_dplcd.write(str(f).upper())
          output_dplcd.write("\n")
          off_d_plc_entries = output_dplcd.tell()

      # *********************************************
      # Part 3
      #
      # Writing the cells
      # *********************************************

      cell_guess_wait = len(cell_temp_list)
      cell_guess_indx = 0
      while cell_guess_wait:
        offset_art = offset + (seek_cell(cell_temp_list[cell_guess_indx],cell_temp_list[cell_guess_indx+1]))
        write_cell(offset_art)
        if ART_DUAL == True:
          if spr_size_y == 0:
            output_art.write(chr(0)*(0x20))
            vram_entry += 1
            if PLC_MODE == True:
              dplc_cell += 1
          if spr_size_y == 2:
            dual_size3_fix += 1
            if dual_size3_fix == 3:
              output_art.write(chr(0)*(0x20))
              vram_entry += 1
              dual_size3_fix = 0
              if PLC_MODE == True:
                dplc_cell += 1

        vram_entry += 1
        if PLC_MODE == True:
          dplc_cell += 1
        cell_guess_indx += 2
        cell_guess_wait -= 2

      # *********************************************
      # End of the painful check
      # *********************************************

      cell_list[cell_list_entry] = -1
      cell_list[cell_list_entry+1] = -1

    del cell_temp_list[:]
    cell_list_entry += 2
    mapping -= 2

  # --- even ---
  #output_mapd.write("\n")
  output_mapd.write("\t\teven")
  output_mapd.write("\n")

# ----------------------------
# Next frame
# ----------------------------

  if PLC_MODE == True:
    if PLC_TYPE == 1:
      #plc_size = '%x' % c
      #plc_cell = '%x' % dplc_cell
      #output_dplcd.seek(off_d_plc_size)
      #output_dplcd.write("\t\tdc.w $")
      #output_dplcd.write(str(spr_frame_cnt).upper())
      #output_dplcd.write("\n")

      output_dplcd.seek(off_d_plc_entries)
      output_dplcd.write("\t\tdc.w $")
      f = '%x' % frame_dsize
      output_dplcd.write(str(f).upper())
      output_dplcd.write("\n")
      output_dplcd.write("\t\tdc.w $")
      f = '%x' % frame_dstart
      output_dplcd.write(str(f).upper())
      output_dplcd.write("\n")

      off_d_plc_entries = output_dplcd.tell()

      frame_dstart += (cell_used*0x20)
      frame_dsize = 0

  del cell_list[:]
  cell_used = 0
  frame_size = 0
  frame_curr += 1
  offset += (max_width*max_height)

  # last frame?
  frames -= 1

  #input_file.seek(offset)
  #input_file.seek(+8,True)
  #a = input_file.read(0x10)
  #if a == "TRUEVISION-XFILE":
    #frames = False
    #break
  #input_file.seek(offset)

# ----------------------------
# End
# ----------------------------

if PLC_MODE == True:
  output_dplc.seek(off_dplcl_last)
  output_dplcd.seek(0)
  output_dplc.write(output_dplcd.read())
  output_dplc.close()
  output_dplcd.close()

output_map.seek(off_mapl_last)
output_mapd.seek(0)
output_map.write(output_mapd.read())
input_file.close()
output_art.close()
output_map.close()
output_mapd.close()

os.remove("1.tmp")
if PLC_MODE == True:
	os.remove("2.tmp")
print("Done.")
input_file.close()
