
	
.segment "CODE_FIXED"
	.include "pulsar.h"
	.include "common.h"
	.include "macros.asm"
	.include "reset.asm"
.segment "DPCM"
	.include "dpcm.asm"

.segment "RESET_FIXED"
	.include "reset_stub.asm"
