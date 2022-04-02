MarsObj_test:
		dc.w 1,4
		dc.l .vert,.face,.vrtx,.mtrl
.vert:		binclude "data/mars/objects/mdl/test/vert.bin"
.face:		binclude "data/mars/objects/mdl/test/face.bin"
.vrtx:		binclude "data/mars/objects/mdl/test/vrtx.bin"
.mtrl:		include "data/mars/objects/mdl/test/mtrl.asm"
		align 4
