	\\ Acorn DNFS (NFS 3.60 & DFS 1.20)
	\\ nfs_swram.asm
	\\ Compiler: BeebAsm V1.08
	\\ Disassembly by Martin Mather


	_DNFS_ = FALSE
	_ADLC_ = FALSE			; Else it's SP

	_SPDBG_ = FALSE			; Debug SP

	_SWRAM_ = TRUE			; Sideways RAM Version

	INCLUDE "dfs.asm"

	SAVE "NFS360RAM.ROM", &8000, &C000
