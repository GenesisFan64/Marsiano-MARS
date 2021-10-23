#======================================================================
# Convert Impulse tracker module to GEMA
#======================================================================

import sys
import os.path

#======================================================================
# -------------------------------------------------
# Settings
# -------------------------------------------------

MAX_PATTSIZE	= 0x200
MAX_TIME	= 0x7F
MAX_CHAN	= 18

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

if len(sys.argv) == 1:
	print("ARGS: inputfile [pattnumloop]")
	exit()
	
#if os.path.exists(sys.argv[1]) == False:
	#print("File not found")
	#exit()
	
MASTERNAME = sys.argv[1]
input_file = open("./trkr/"+MASTERNAME+".it","rb")
out_patterns = open(MASTERNAME+"_patt.bin","wb")
out_blocks   = open(MASTERNAME+"_blk.bin","wb")

#======================================================================
# -------------------------------------------------
# Init
# -------------------------------------------------

working=True

input_file.seek(0x20)
OrdNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)
InsNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)
SmpNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)
PatNum = ord(input_file.read(1)) | (ord(input_file.read(1)) << 8)

addr_BlockList = 0xC0
addr_PattList  = 0xC0+( (OrdNum) + (InsNum*4) + (SmpNum*4) )

can_loop = False
if len(sys.argv) > 2:
	can_loop = True
	loop_at = int(sys.argv[2])

#======================================================================
# -------------------------------------------------
# Start
# -------------------------------------------------

#$00 - $77  | notas
#$78 - $7F  | free
#$FE        | note CUT (rest ===)
#$FF        | note OFF (FM: key off)


# 0x00      = next row and reset channel counter to 0-8
# 0x01-0x7B = timer
# 0x7C      = next 8 channels (can't go back)
# 0x7D      = loop checkpoint
# 0x7E      = end and loop track (set loop with 0x7D)
# 0x7F      = end of track (NO loop)

# -------------------------------------------------

buff_Notes = [0]*(MAX_CHAN)				# mode, note, instr, volume, effects

# build BLOCKS
# TODO: manual user LOOP
input_file.seek(addr_BlockList)
for b in range(0,OrdNum):
	a = ord(input_file.read(1))
	out_blocks.write(bytes([a]))

# build patterns
curr_PattInc = 0					# OUT header counter
numof_Patt   = PatNum
out_patterns.write(bytes(numof_Patt*4))			# make room for pointers
while numof_Patt:
	input_file.seek(addr_PattList)
	addr_PattList += 4
	addr_CurrPat = ord(input_file.read(1)) | ord(input_file.read(1)) << 8 | ord(input_file.read(1)) << 16 | ord(input_file.read(1)) << 24
	input_file.seek(addr_CurrPat)
	sizeof_Patt = ord(input_file.read(1)) | ord(input_file.read(1)) << 8
	sizeof_Rows = ord(input_file.read(1)) | ord(input_file.read(1)) << 8
	input_file.seek(4,True)

	b = out_patterns.tell()
	out_patterns.seek(curr_PattInc)
	pattrn_start = b
	# set point to pattern, size is set below
	out_patterns.write(bytes([sizeof_Rows&0xFF,(sizeof_Rows>>8)&0xFF]))
	out_patterns.write(bytes([pattrn_start&0xFF,(pattrn_start>>8)&0xFF]))


	# ****************************************
	out_patterns.seek(b)
	# ---------------------------
	# read pattern head
	# ---------------------------
	set_End = False
	timerOut = 0
	while sizeof_Rows:
		a = ord(input_file.read(1))
		
		# TIMER set.
		if a == 0:
			# Set note data end flag
			if set_End == True:
				set_End = False
				out_patterns.write(bytes(1))
				
			# Make wait timer
			else:
				if timerOut != 0:
					out_patterns.seek(-1,True)
				out_patterns.write(bytes([timerOut&0x7F]))
				timerOut += 1
				if timerOut > MAX_TIME:
					timerOut = 0
			sizeof_Rows -= 1

		# 0x01-0xFF
		else:
			timerOut = 0
			b = (a-1) & 0x3F
			if (a & 128) != 0:
				# NEW data and format
				a = 0xC0 | b
				out_patterns.write(bytes([a&0xFF]))	# save format
				a = ord(input_file.read(1))
				buff_Notes[b] = a
				out_patterns.write(bytes([a&0xFF]))	# store
			else:
				# NEW data, reuse format
				a = 0x80 | b
				out_patterns.write(bytes([a&0xFF]))

			if b >= MAX_CHAN:
				print("Error: this pattern is empty")
				exit()

			# grab note/ins/etc.
			a = buff_Notes[b]
			if (a & 1) != 0:
				out_patterns.write(bytes([ord(input_file.read(1))&0xFF]))
			if (a & 2) != 0:
				out_patterns.write(bytes([ord(input_file.read(1))&0xFF]))
			if (a & 4) != 0:
				out_patterns.write(bytes([ord(input_file.read(1))&0xFF]))
			if (a & 8) != 0:
				out_patterns.write(bytes([ord(input_file.read(1))&0xFF]))
				out_patterns.write(bytes([ord(input_file.read(1))&0xFF]))
			set_End = True
			
	# Save size
	pattrn_size = (out_patterns.tell()-pattrn_start)
	#if pattrn_size >= MAX_PATTSIZE:
		#print("THIS PATTERN IS TOO LARGE FOR Z80")
		#break
	lastpatt = out_patterns.tell()
	#out_patterns.seek(curr_PattInc)
	#out_patterns.write(bytes([pattrn_size&0xFF,(pattrn_size>>8)&0xFF]))
	#print(hex(pattrn_start),hex(pattrn_size))
	out_patterns.seek(lastpatt)
	
	# Next block
	curr_PattInc += 4
	numof_Patt -= 1
		
# ----------------------------
# End
# ----------------------------

input_file.close()
out_patterns.close()    
