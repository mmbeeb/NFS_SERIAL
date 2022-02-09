	\\ Acorn DNFS
	\\ dfs.asm
	\\ Compiler: BeebAsm V1.09
	\\ Disassembly by Martin Mather


	_DNFS_ = FALSE
	_ADLC_ = FALSE
	
	_ADLC_ =? TRUE
	_DNFS_ =? TRUE
	
	_SPDBG_ = TRUE

	INCLUDE "acorn_os_eq.asm"
	INCLUDE "netsys_eq.asm"

IF NOT(_ADLC_)
	INCLUDE "netsys_sp_eq.asm"
ENDIF

	ORG &8000
	\GUARD &C000

.langentry
	JMP NFS_LANGUAGE_ENTRY

.serventry
	JMP NFS_SERVICE_ENTRY

.romtype
	EQUB &82

.copywoffset
	EQUB copyright-&8001

.binversion
	EQUB &83

.title
	EQUB "NET", 0

.copyright
	EQUS "(C)"
	;;"Acorn", 0

	
	INCLUDE "netsys.asm"
	
IF _ADLC_
	INCLUDE "netsys_adlc.asm"
ELSE
	INCLUDE "netsys_sp_L2.asm"
	INCLUDE "netsys_sp_L1.asm"
ENDIF
	
	\\ COPIED FROM OTHER FILES:::::
	
.Utils_PrintHexByte
{
	PHA 
	JSR Alsr4
	JSR Utils_PrintHexLoNibble	;hi nibble
	PLA 				;lo nibble
.Utils_PrintHexLoNibble
	JSR prthexnibcalc
	JSR OSASCI
	SEC 
	RTS
}

.prthexnibcalc
{
	AND #&0F
	CMP #&0A
	BCC prthex

	ADC #&06

.prthex
	ADC #&30
	RTS
}


.Alsr4
	LSR A
	LSR A
	LSR A
	LSR A
	RTS

	\\ END OF ROM

