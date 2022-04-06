

	;********************************
	;*            FLIP              *
	;*            LCAT              *
	;*            LEX               *
	;*            PROT              *
	;*           UNPROT             *
	;*   Original ACORN versions    *
	;********************************

	;* Assembled using beebasm 1.09 *

	LOADADDR =?&0E23
	LOADADDR3 =?&0E40
	LOADADDR4 =?&0F10

	OSASCI=?&FFE3
	OSNEWL=?&FFE7
	OSWRCH=?&FFEE
	OSWORD=?&FFF1
	OSBYTE=?&FFF4
	OSFILE=?&FFDD
	OSFIND=?&FFCE
	OSCLI=?&FFF7

	TXTPTR=?&F2

	CLEAR LOADADDR, LOADADDR+&200
	ORG LOADADDR

.FLIP_START
{
	LDA #6
	STA OW_BLK
	JSR S_0E3E

	LDA OW_BLK+2
	PHA
	LDA OW_BLK+3
	STA OW_BLK+2
	PLA
	STA OW_BLK+3

	LDA #7
	STA OW_BLK

.S_0E3E
	LDX #LO(OW_BLK)
	LDY #HI(OW_BLK)
	LDA #&13
	JMP OSWORD

.OW_BLK
}
.FLIP_END

IF HI(FLIP_START)=&DD;MASTER
	SAVE "M\$.FLIP", FLIP_START, FLIP_END
ELIF HI(FLIP_START)=&0E
	SAVE "E\$.FLIP", FLIP_START, FLIP_END
ELSE
	SAVE "O\$.FLIP", FLIP_START, FLIP_END
ENDIF


	CLEAR LOADADDR3, LOADADDR3+&200
	ORG LOADADDR3

.LCAT_START
{
	JSR S_0E46
	JSR S_0E6A

.S_0E46
	LDA #6
	STA OW_BLK
	JSR S_0E61

	LDA OW_BLK+2
	PHA
	LDA OW_BLK+3
	STA OW_BLK+2
	PLA
	STA OW_BLK+3

	LDA #7
	STA OW_BLK

.S_0E61
	LDX #LO(OW_BLK)
	LDY #HI(OW_BLK)
	LDA #&13
	JMP OSWORD

.S_0E6A
	LDX #LO(D_0E71)
	LDY #HI(D_0E71)
	JMP OSCLI

.D_0E71
	EQUB ".", 13

.OW_BLK
}
.LCAT_END

IF HI(LCAT_START)=&DD;MASTER
	SAVE "M\$.LCAT", LCAT_START, LCAT_END
ELIF HI(LCAT_START)=&0E
	SAVE "E\$.LCAT", LCAT_START, LCAT_END
ELSE
	SAVE "O\$.LCAT", LCAT_START, LCAT_END
ENDIF


	CLEAR LOADADDR3, LOADADDR3+&200
	ORG LOADADDR3

.LEX_START
{
	JSR S_0E46
	JSR S_0E6A

.S_0E46
	LDA #6
	STA OW_BLK
	JSR S_0E61

	LDA OW_BLK+2
	PHA
	LDA OW_BLK+3
	STA OW_BLK+2
	PLA
	STA OW_BLK+3

	LDA #7
	STA OW_BLK

.S_0E61
	LDX #LO(OW_BLK)
	LDY #HI(OW_BLK)
	LDA #&13
	JMP OSWORD

.S_0E6A
	LDX #LO(D_0E71)
	LDY #HI(D_0E71)
	JMP OSCLI

.D_0E71
	EQUB "ex", 13

.OW_BLK
}
.LEX_END

IF HI(LEX_START)=&DD;MASTER
	SAVE "M\$.LEX", LEX_START, LEX_END
ELIF HI(LEX_START)=&0E
	SAVE "E\$.LEX", LEX_START, LEX_END
ELSE
	SAVE "O\$.LEX", LEX_START, LEX_END
ENDIF


	CLEAR LOADADDR, LOADADDR+&200
	ORG LOADADDR

.PROT_START
{
	LDX #LO(OW_BLK)
	LDY #HI(OW_BLK)
	LDA #&13
	JMP OSWORD

.OW_BLK
	EQUB 5, &FF
}
.PROT_END

IF HI(PROT_START)=&DD;MASTER
	SAVE "M\$.PROT", PROT_START, PROT_END
ELIF HI(PROT_START)=&0E
	SAVE "E\$.PROT", PROT_START, PROT_END
ELSE
	SAVE "O\$.PROT", PROT_START, PROT_END
ENDIF


	CLEAR LOADADDR4, LOADADDR4+&200
	ORG LOADADDR4

.UNPROT_START
{
	LDX #LO(OW_BLK)
	LDY #HI(OW_BLK)
	LDA #&13
	JMP OSWORD

.OW_BLK
	EQUB 5, &00
}
.UNPROT_END

IF HI(UNPROT_START)=&DD;MASTER
	SAVE "M\$.UNPROT", UNPROT_START, UNPROT_END
ELIF HI(UNPROT_START)=&0F
	SAVE "E\$.UNPROT", UNPROT_START, UNPROT_END
ELSE
	SAVE "O\$.UNPROT", UNPROT_START, UNPROT_END
ENDIF
