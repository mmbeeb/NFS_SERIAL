

	;********************************
	;*            DATE              *
	;* Updated for the 21st Century *
	;*    By Martin Mather 2022     *
	;********************************

	;* Assembled using beebasm 1.09 *
	
	CENTURY=21
	FIRSTDAY=5;Saturday
	FIRSTLEAP=0

	OSNEWL=&FFE7
	OSWRCH=&FFEE
	OSWORD=&FFF1

	CLEAR &0E00, &0FFF
	ORG &0E23
	GUARD &F00

.DATE_START
{
{
	LDA #&14
	LDX #LO(OWBLK)
	LDY #HI(OWBLK)
	JSR OSWORD
	
	;DECODE FS DATE
	LDX DATE1;DAY+YEAR
	TXA
	AND #&1F
	STA DAY
	TXA
	LSR A
	AND #&F0
	STA YEAR
	LDX DATE2;MONTH+YEAR
	TXA
	AND #&0F
	STA MONTH
	TXA
	LSR A
	LSR A
	LSR A
	LSR A
	ORA YEAR
	CLC
	ADC #81
	CMP #100
	BCC L1
	
	SBC #100
	
.L1	STA YEAR
	
	; PRINT DATE

	; DAY OF WEEK
	JSR PMSG;"Today is "
	JSR PDOW;"Monday the " etc.
	
	; DAY OF MONTH
	JSR PORD;day
	JSR PMSG;" of "
	
	;MONTH
	LDA MONTH
	CLC
	ADC #6
	JSR PSTR;"January" etc.
	LDA #' '
	JSR OSWRCH
	
	;YEAR
	CLV
	LDA #CENTURY-1
	JSR PNUM
	LDA YEAR
	JSR PNUM
	
	JMP OSNEWL
}
	
	;PRINT DAY OF WEEK
.PDOW
{
	DEC DAY
	LDY #0
	LDA #FIRSTDAY
	LDX #FIRSTLEAP+1
	
.L2	JSR MOD7
	CPY YEAR
	BCS L3
	
	INY
	ADC #1
	DEX
	BNE L2
	
	ADC #1
	LDX #4
	BNE L2
	
.L3	LDY MONTH
	CLC
	ADC MDAT-1,Y
	DEX
	BNE L4
	
	CPY #3
	
.L4	ADC DAY
	JSR MOD7
	INC DAY

	JSR PSTR
	JMP PMSG;"day the "
}

.PNUM
{
	LDY #&FF
	SEC 
	
.L1	INY;HI DIGIT
	SBC #10
	BCS L1
	
	ADC #10
	TAX;LO DIGIT

	TYA
	BVC L2
	BEQ L3
	
.L2	JSR L4

.L3	TXA

.L4	ORA #'0'
	JMP OSWRCH
}
	
	;DAY OF MONTH
.PORD
{
	LDA DAY
	BIT PNUM+1;SET V
	JSR PNUM
	
	DEY
	BEQ L1;TEENS
	
	CPX #4
	BCC L2

	LDY #0
	
.L1	LDA ORD1,Y
	JSR OSWRCH
	LDA ORD2,Y
	JMP OSWRCH
	
.L2	TXA
	AND #3
	TAY
	BPL L1
}
	
	ORG &0F17
	GUARD &1000

.PMSG
{
.L1	LDY #&FF
	INY
	
.L2	LDA MSG,Y
	BEQ L3
	JSR OSWRCH
	INY
	BNE L2
	
.L3	STY L1+1
	RTS
}

.PSTR
{
	TAX
	LDY DPTR,X
	
	LDA DSTR,Y
	JSR OSWRCH

.L1	LDA DSTR+1,Y
	CMP #'a'
	BCC L2;UPPERCASE?

	JSR OSWRCH
	INY
	BNE L1
	
.L2	RTS
}	

	;MOD 7
.MOD7
{
.L1	CMP #7
	BCS L2
	
	RTS
	
.L2	SBC #7
	BCS L1
}

.DPTR
	EQUB &00, &03, &07, &0D, &12, &15, &1A
	EQUB &1D, &24, &2C, &31, &36, &39, &3D, &41, &47, &50, &57, &5F
	
.DSTR
	EQUS "Mon", "Tues", "Wednes", "Thurs", "Fri", "Satur", "Sun"
	
	EQUS "January", "February", "March"
	EQUS "April", "May", "June"
	EQUS "July", "August", "September"
	EQUS "October", "November", "December"

.MSG
	EQUS "Today is ", 0, "day the ", 0, " of ", 0

.MDAT
	EQUB 0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5
	
.ORD1
	EQUS "tsnr"
.ORD2
	EQUS "htdd"

	;OSWORD &14 BLOCK
.OWBLK
	EQUB 0
	EQUB 5;BLOCK SIZE
	EQUB 0;
	EQUB 16;FUNCTION CODE 16 = READ TIME & DATE
.DATE1
	EQUB 0;/DATE1, DAY & YR
.DATE2
	EQUB 0;/DATE2, MONTH & YR
.DAY
	EQUB 0;/HOURS
.MONTH
	EQUB 0;/MINUTES
.YEAR
	EQUB 0;/SECONDS
}
.DATE_END

	SAVE "$.DATE", DATE_START, DATE_END

