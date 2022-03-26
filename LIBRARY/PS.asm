

	;********************************
	;*             PS               *
	;*   Original ACORN version     *
	;********************************

	;* Assembled using beebasm 1.09 *

	LOADADDR =? &0E23

	OSASCI=?&FFE3
	OSNEWL=?&FFE7
	OSWRCH=?&FFEE
	OSWORD=?&FFF1
	OSBYTE=?&FFF4
	
	TXTPTR=?&F2

	CLEAR LOADADDR, LOADADDR+&200
	ORG LOADADDR

.PS_START
{
.L_0E23
	LDA #&02
	JSR S_0EF5
	LDY #&00
	STY &A9
	STY &A8
	
.L_0E2E
	INY 
	LDA (TXTPTR),Y
	CMP #&0D
.D_0E33;THIS BIT IS OVERWRITTEN
	BEQ L_0E44
	
	CMP #&20
	BNE L_0E2E
	
.L_0E39
	INY 
	LDA (TXTPTR),Y
	CMP #&20
	BEQ L_0E39
	
	CMP #&0D
	BNE L_0E47
	
.L_0E44
	JMP S_0F0D
	
.L_0E47
	CMP #&2E
	BEQ L_0E53
	
	CMP #&30
	BCC L_0E66
	
	CMP #&3A
	BCS L_0E66
	
.L_0E53
	JSR S_0F8F
	BCC L_0E5E
	
	STA &AE
	INY 
	JSR S_0F8F
	
.L_0E5E
	BEQ L_0E62
	STA &AD
	
.L_0E62
	JSR S_0EF3
	RTS 
	
.L_0E66
	LDX #&00
	
.L_0E68
	LDA (TXTPTR),Y
	CMP #&0D
	BEQ L_0E83
	
	CMP #&61
	BCC L_0E78
	
	CMP #&7B
	BCS L_0E78
	
	AND #&5F
	
.L_0E78
	STA D_0F87,X
	INX 
	CPX #&06
	BCS L_0E83

	INY 
	BCC L_0E68
	
.L_0E83
	CLC 
	LDA D_0F7F
	STA D_0F7B
	ADC #&03
	STA D_0F7F
	LDA #&00
	STA D_0F76
	LDA #&11
	LDX #LO(D_0F76)
	LDY #HI(D_0F76)
	JSR OSWORD
	LDX &A9
	LDA D_0F76
	STA L_0E23,X
	BEQ L_0EAB
	
	INC &A9
	BNE L_0E83
	
.L_0EAB
	LDA #&80
	STA D_0F83
	LDX #LO(D_0F83)
	LDY #HI(D_0F83)
	LDA #&10
	JSR OSWORD
	LDA D_0F83
	BEQ L_0EAB
	
	LDX #&00
	LDY #&00
	LDA #&04
	STA &A8
	
.L_0EC6
	INX 
	BNE L_0EC6
	
	INY 
	BNE L_0EC6
	
	DEC &A8
	BNE L_0EC6
	
.L_0ED0
	DEC &A9
	BMI S_0F0D
	
	LDX &A9
	LDA L_0E23,X
	STA D_0F76
	TAX 
	LDA #&33
	JSR OSBYTE
	TXA 
	BPL L_0EE8
	
	JSR S_0FB6
	
.L_0EE8
	LDX D_0F76
	LDA #&34
	JSR OSBYTE
	JMP L_0ED0
	
.S_0EF3
	LDA #&03
	
.S_0EF5
	STA &AC
	LDX #&AC
	LDY #&00
	LDA #&13
	JMP OSWORD
	
IF LOADADDR = &0E23
	ORG &0F09
	EQUD &FFFF0E23;Execution address
ENDIF

.S_0F0D
	JSR S_0FE0_PRINT
	EQUS "Printer server "
	LDA &A8
	BEQ L_0F40
	
	JSR S_0FE0_PRINT
	EQUS "now "
	
.L_0F2A
	LDY &AE
	BEQ L_0F35
	
	JSR S_0F4C
	JSR S_0FE0_PRINT
	EQUS "."
	
.L_0F35
	LDY &AD
	JSR S_0F4C
	JSR S_0EF3
	JMP OSNEWL
	
.L_0F40
	JSR S_0FE0_PRINT
	EQUS "still "
	CLV 
	BVC L_0F2A
	
.S_0F4C
	BIT D_0F85
	LDA #&64
	JSR S_0F5C
	LDA #&0A
	JSR S_0F5C
	LDA #&01
	CLV 
	
.S_0F5C
	STA &AA
	TYA 
	LDX #&2F
	SEC 
	PHP 
	
.L_0F63
	INX 
	SBC &AA
	BCS L_0F63
	
	ADC &AA
	TAY 
	TXA 
	PLP 
	BVC L_0F73
	
	CMP #&30
	BEQ L_0FDF
	
.L_0F73
	JMP OSASCI

.D_0F76
	EQUB &00, &7F, &9E, &00, &00
.D_0F7B
	EQUB LO(D_0E33)
.D_0F7C
	EQUB HI(D_0E33)
	EQUW &FFFF
.D_0F7F
	EQUW D_0E33
	EQUW &FFFF
	
.D_0F83
	EQUB &80, &9F
.D_0F85
	EQUW &FFFF

.D_0F87
	EQUB &20, &20, &20, &20
	EQUB &20, &20, &01, &00

.S_0F8F
	LDA #&00
	STA &AA
	
.L_0F93
	LDA (TXTPTR),Y
	CMP #&40
	BCS L_0FB2
	
	CMP #&2E
	BEQ L_0FB3
	BMI L_0FB2
	
	AND #&0F
	STA &AB
	ASL &AA
	LDA &AA
	ASL A
	ASL A
	ADC &AA
	ADC &AB
	STA &AA
	INY 
	BNE L_0F93
	
.L_0FB2
	CLC 
	
.L_0FB3
	LDA &AA
	RTS 
	
.S_0FB6
	LDX #LO(D_0F76)
	LDY #HI(D_0F76)
	LDA #&11
	JSR OSWORD
	LDA D_0F7B
	STA &AA
	LDA D_0F7C
	STA &AB
	LDY #&00
	LDA (&AA),Y
	BEQ L_0FD3
	
	CMP #&03
	BNE L_0FDF
	
.L_0FD3
	LDA &0F79
	STA &AD
	LDA &0F7A
	STA &AE
	DEC &A8
	
.L_0FDF
	RTS 
	
.S_0FE0_PRINT
	PLA 
	STA &AA
	PLA 
	STA &AB
	LDY #&00
	BEQ L_0FED
	
.L_0FEA
	JSR OSASCI
	
.L_0FED
	INC &AA
	BNE L_0FF3
	
	INC &AB
	
.L_0FF3
	LDA (&AA),Y
	BPL L_0FEA
	
	JMP (&00AA)
}
.PS_END
	
	SAVE "$.PS", PS_START, PS_END
		
	