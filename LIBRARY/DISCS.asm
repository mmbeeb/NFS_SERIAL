

	;********************************
	;*            DISCS             *
	;*   Original ACORN version     *
	;********************************

	;* Assembled using beebasm 1.09 *

	;THIS IS THE MASTER VERSION.

	LOADADDR =?&0E23

	OSASCI=?&FFE3
	OSNEWL=?&FFE7
	OSWRCH=?&FFEE
	OSWORD=?&FFF1
	OSBYTE=?&FFF4

	TXTPTR=?&F2

	CLEAR LOADADDR, LOADADDR+&200
	ORG LOADADDR

.DISCS_START
{
	LDX #&11
	LDA #&A1
	JSR OSBYTE;READ MASTER CONFIG
	
	TYA
	BPL L_DD17
	
	LDX #&00
	
.L_DD0C
	LDA D_DD64,X
	BEQ L_DD17
	
	JSR OSASCI
	INX
	BNE L_DD0C
	
.L_DD17
	LDA #&00
	STA &AA
	
	JSR S_DDAC_PRINT
	EQUS 13, "    drive  disc name", 13, 13
	
.L_DD35
	LDA &AA
	INC &AA
	CLC
	STA OW_BLK+7
	ADC #&02
	STA &AA
	STA OW_BLK+8
	LDA #&0E
	STA OW_BLK+3
	LDX #&30
	STX OW_BLK+1
	LDX #&00
	STX OW_BLK
	
	LDX #LO(OW_BLK)
	LDY #HI(OW_BLK)
	LDA #&14
	JSR OSWORD
	
	LDX #&00
	LDA OW_BLK+4
	BNE L_DD79
	
	RTS
	
.D_DD64
	EQUS "Display Discs. 1.04", 13, 0
	
.L_DD79
	DEC OW_BLK+4
	BMI L_DD35
	
	JSR S_DDAC_PRINT
	EQUS "      "
	
	LDA OW_BLK+5,X
	STA &AA
	INC &AA
	JSR S_DDC6
	
	JSR S_DDAC_PRINT
	EQUS "    "
	
	LDY #&10
	
.L_DD9A
	LDA OW_BLK+6,X
	JSR OSASCI
	INX
	DEY
	BNE L_DD9A
	
	INX
	LDA #13
	JSR OSASCI
	BNE L_DD79
	
.S_DDAC_PRINT
	PLA
	STA &A8
	PLA
	STA &A9
	
	LDY #0
	BEQ L_DDB9
	
.L_DDB6
	JSR OSASCI

.L_DDB9
	INC &A8
	BNE L_DDBF
	
	INC &A9
	
.L_DDBF
	LDA (&A8),Y
	BPL L_DDB6
	
	JMP (&00A8)
	
IF LOADADDR=&0E23
	ORG &0F09
	
	EQUD &FFFF0E23
ENDIF	

.S_DDC6
	TAY
	LDA #&01
	STA &A9
	TXA
	PHA
	TYA
	LDX #&2F
	SEC

.L_DDD1
	INX
	SBC &A9
	BCS L_DDD1
	
	ADC &A9
	TAY
	TXA
	JSR OSASCI
	PLA
	TAX
	RTS

.OW_BLK
}
.DISCS_END

	SAVE "$.DISCS", DISCS_START, DISCS_END



