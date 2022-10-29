MarsMapPz_02_refsep_n:
		dc.w 760,1642
		dc.l TH|.vert,TH|.face,TH|.vrtx,TH|.mtrl
.vert:		binclude "data/maps/3D/mcity/pz/02_refsep_n_vert.bin"
.face:		binclude "data/maps/3D/mcity/pz/02_refsep_n_face.bin"
.vrtx:		binclude "data/maps/3D/mcity/pz/02_refsep_n_vrtx.bin"
.mtrl:		include "data/maps/3D/mcity/pz/02_refsep_n_mtrl.asm"
