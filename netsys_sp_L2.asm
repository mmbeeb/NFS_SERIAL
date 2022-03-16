	\\ netsys_sp_L2.asm
	\\ Compiler: BeebAsm V1.09
	\\ By Martin Mather
	
.Sub_9630_Transmit_Start		;Start Transmit
	JMP Sub_9B6E_Transmit_Start
	
	;Called during ROM Service Call 2 (private workspace claim)
.Sub_9633_Listen_Start			;Start Listening
	LDA #&EA
	LDX #&00
	STX I_Own_NMI_D66
	STX SP_BAUDRATE
	LDY #&FF
	JSR OSBYTE
	STX TubePresent_D67			;If Tube present then X=&FF
	JMP NFS_NMI_RELEASED
	
	;Receiver timed out
.sp_receive_error
{
IF _SPDBG_
	lda #'~'
	jsr DBGWRCH
	lda #'R'
	jsr DBGWRCH
	lda SP_RX_STATE2
	jsr PRINT_HEX_SPC
ENDIF
	
	LDA SP_RX_STATE2			;The flag we were expecting.
	CMP #SP_FLAG_SCOUT
	BEQ L2
	
	CMP #SP_FLAG_ACK			;Reply to transmission error, we were expecing an ACK.
	BEQ L1
	
	;Else, assume A == SP_FLAG_DATA, i.e. we were expecting some data!

IF _SPDBG_
	lda #'d'
	jsr DBGWRCH
ENDIF
	
	JMP Sub_9835_Frame_Error

.L1

IF _SPDBG_
	lda #'a'
	jsr DBGWRCH
ENDIF


	JMP Sub_9EAC_tx_error41

.L2	JMP sp_listen4scout
}

	;Entry: A=FLAG FOR NEW FRAME
.sp_rx_newframe
{
	PHA
	LSR SP_TUBEEN				;TUBE related flag

	;First deal with previous frame

	;;Debug info
IF _SPDBG_
	jsr test_rxcrc
ENDIF

	;Check if old frame valid
	LDA SP_CRC
	ORA SP_CRC+1	
	BNE L1						;BAD CRC = IGNORE
	
	JSR sp_rx_oldframe

	;Set up for next frame	
.L1

IF _SPDBG_
	lda #'*'
	jsr DBGWRCH
	pla
	pha
	jsr PRINT_HEX_SPC
ENDIF
	
	LDY #0
	PLA							;A=FLAGS
	BPL L2						;If VOID
	
	CMP SP_RX_STATE2
	BNE L4						;Not what we were listening for!

.L3	TAY
	
.L2	STY SP_RX_STATE

	;Setup to read to control buffer (max 12 bytes)
	LDA #0
	STA SP_RX_COUNT				;Rest buffer counter
	STA SP_RX_OVERFLOW			;Reset overflow flag (bit 7)
	STA SP_CRC					;Reset CRC
	STA SP_CRC+1
	
	TYA
	JSR CRC_CALC				;INCLUDE FLAG IN CRC
	
	LDA #1
	STA SP_FIFO_STATE			;FIFO counter
	RTS
	
.L4A
	LDY SP_RX_STATE2	
	CPY #SP_FLAG_SCOUT
	BEQ	L3						;Listening for scout, but broadcast/reset OK
	BNE L4B						;Not expecting broadcast/reset
	
	;WRONG KIND OF FRAME RECEIVED!
	;If listening for scout, just ignore.
	;If waiting for reply to transmission, report tx error.
	;NOTE Y=0
	
.L4	CMP #SP_FLAG_BROADCAST
	BEQ L4A						;If broadcast
	CMP #SP_FLAG_RESET
	BEQ L4A						;If reset

.L4B
	LDA SP_RX_STATE2			;The flag we were expecting.
	CMP #SP_FLAG_SCOUT
	BEQ L2						;Listening for a scout, just ignore frame.  Y=0
	
	CMP #SP_FLAG_ACK			;Reply to transmission error, we were expecing an ACK.
	BEQ L5
	
	;Else, assume A == SP_FLAG_DATA, i.e. we were expecting some data!
	
	JMP Sub_9835_Frame_Error

.L5	JMP Sub_9EAC_tx_error41
}	
	
	
.sp_rx_oldframe
{
	CLV
	LDA	SP_RX_COUNT				;Number of bytes in SP_RX_BUF (control buffer)

IF _SPDBG_
	pha
	lda #'!'
	jsr DBGWRCH
	lda SP_RX_STATE
	jsr PRINT_HEX_SPC
	pla
ENDIF

	LDY SP_RX_STATE
	BEQ L1						;Not doing anything!
	BPL L2						;If received DATA, V=0

	;Received scout, ACK or NAK	frame
	BIT SP_RX_STATE
	BVS L2						;If ACK/NAK (assume it's an ACK), V=1
	
	;RECEIVED A SCOUT!

	;Enough bytes received?
	;If SCOUT, length must == 4 : Source stn + net, control byte, port
	;If BROADCAST, length must == 12 (as scout + 8 bytes of data)
	;If IMMEDIATE, length >= 4 and <= 12 (as scout + 0, 4 or 8 bytes of data)
	
	;A = bytes in control buffer
	CMP #4
	BCC L1						;Too small

	;Broadcast?
	LDA SP_RX_STATE
	ROL A
	ROL A
	BMI J1 						;Broadcast or reset

.J2	ROR A
	AND #&40
	STA RXTX_Flags_D4A			;Bit 6 = Broadcast
	
	JMP Sub_9756_RX_Scout

.J1	ROL A
	BMI J2						;If broadcast
	
	;Reset!
	LDA SP_RX_STN
	LDY #&14
	STA (ptr9CL_PWS0),Y			;My station number

.L1	RTS

	;Received ACK or DATA frame
	;V=0=ACK or V=1=DATA
	;A = bytes in control buffer
.L2	CMP #2						;Source Stn+Net
	BNE L4	 					;Wrong size

	LDA SP_RX_STN
	CMP SP_TX_STN
	BNE L4						;Wrong station
	
	LDA SP_RX_NET
	CMP SP_TX_NET
	BNE L4						;Wrong net
	
	BVC L3						;If DATA

	;RECEIVED AN ACK!
	JMP Sub_9EA8_tx_success

	;RECEIVED DATA!	
.L3	BIT SP_RX_OVERFLOW
	BMI L4						;Buffer overflowed

	JMP Sub_98EE_Received_Data
	
	;Wrong size, wrong station, or buffer overflowed.
.L4	BVS L5						;If ACK
	
	JMP Sub_9835_Frame_Error	;Data error

.L5	JMP Sub_9EAC_tx_error41
}


IF _SPDBG_
.test_rxcrc
{
	ldy #'v'
	lda SP_CRC
	ora SP_CRC+1
	beq LW1
	ldy #'e'
.LW1
	tya
	jmp DBGWRCH
}
ENDIF


	\\ RECEIVED A SCOUT FRAME
.Sub_9756_RX_Scout
{
IF _SPDBG_
	lda #'$'
	jsr DBGWRCH
ENDIF

	SEC
	ROR SP_TUBEEN				;Prevent release of TUBE when setting up counters
	
	LDA SP_RX_PORT				;A=PORT
	BNE J1						;If not immediate request

	;Note the original doesn't check if the frame is a broadcast.
	JMP Sub_9A46_RX_ImmediateRequest

	\ Look for receive control block.
.J1
	BIT RXTX_Flags_D64
	BPL L6						;If b7 = 0, don't include block at &00C0

	\ Expecting reply.
	\ Include control block at &00C0.

	LDA #&C0					;Y:A = &00C0 (&C0-&CF for current fs) :
	LDY #&00					;RX Buffer control block.

	\ Y:A -> 1st Control block
.L1	STA ptrA6L					;ptrA6 = Y:A
	STY ptrA6H

.L2	LDY #0
	LDA (ptrA6L),Y				;Flag byte
	BEQ L5						;If 0, no more blocks.

	CMP #&7F
	BNE L4						;If Not expecting data, try next block

	INY
	LDA (ptrA6L),Y
	BEQ L3						;If Port = 0 (any port)

	CMP SP_RX_PORT				;If Port = Rx_Port
	BNE L4						;Not this port, try next block

.L3	INY
	LDA (ptrA6L),Y
	BEQ L7						;If Station = 0 (any station)

	CMP SP_RX_STN				;If Station = Rx_SourceStation
	BNE L4						;Not source station, try next

	INY
	LDA (ptrA6L),Y
	CMP SP_RX_NET				;If Net = Rx_SourceNet
	BEQ L7						;We have a match!

	; Try next block
.L4	LDA ptrA6H
	BEQ L6						;If last block was at &00C0

	LDA ptrA6L					;ptrA6 += &0C
	CLC
	ADC #&0C
	STA ptrA6L
	BCC L2

	; No match
.L5	JMP sp_send_NAK

.L6	BIT RXTX_Flags_D64
	BVC L5						;If b6 = 0 : Only look at &00C0 block

	; Look at blocks in private workspace
	LDA #0						;Y:A -> PWSP1
	LDY ptr9EH_PWS1
	BNE L1
	
	; Match found
.L7	;JMP Sub_97B9_RX_FoundControlBlock
}
	

	\**** Control block found matching header!
	\ ptrA6 -> buffer control block
.Sub_97B9_RX_FoundControlBlock
{
	LDA #TUBEOP1	;TUBEOP3
	STA TubeOp_D5C				;Tube Operation 3=Multi pairs of bytes Host->Parasite

	JSR Sub_9ECA_SetupCounters	;Set up counters/Tube
	BCC L1						;If failed (i.e. Tube failed)

	BIT RXTX_Flags_D4A
	BVC sp_send_SCOUTACK		;If b6 clear = not broadcast

	JMP Sub_99F2_CopyDataToBuffer	;Received broadcast : Copy data received to buffer.
	
.L1
	;JMP Sub_9835_Frame_Error
}

.Sub_9835_Frame_Error
{
	LDA RXTX_Flags_D4A
	BPL Label_983D				;If b7 = 0 : No reply expected.
	
	;PEEK OR MACHINE TYPE...
	JMP Sub_9EAC_tx_error41

.Label_983D
	JMP Sub_99DB_ListenForScout
}

	;Send Scout ACK, then listen for data
.sp_send_SCOUTACK
{
	ASL Line_Not_Busy_D62		;Clear bit 7 = Line now busy

	LDA #&11
	BNE L2						;always

	;Send NAK, then listen for scout
.*sp_send_NAK
	BIT RXTX_Flags_D4A
	BVS L1						;If broadcast don't send NAK
	
	LDA #&91
	LDY #SP_FLAG_NAK
	BNE L3						;always
	
.L1	RTS

	;Send Immediate Reply, then listen for scout
.*sp_send_IMMDATA
	LDA #&90
	LDY #SP_FLAG_DATA
	BNE L3						;always
	
	;Send Immediate ACK, then listen for scout
.*sp_send_IMMACK
	LDA #&91
	BNE L2						;always

	;Send data ACK.
	;Once sent, call Sub_9995_RX_DataReceived.
.*sp_send_DATAACK
	LDA #&19

.L2	LDY #SP_FLAG_ACK

	;NOTE: We may have already set things up to receive data.
	;:. We need to preserve the TUBE flag and stop the TUBE being released (if claimed) at the end of the transmission.
	
.L3	ORA RXTX_Flags_D4A
	STA RXTX_Flags_D4A
	
	LDA SP_RX_STN
	STA SP_TX_STN
	LDA SP_RX_NET
	STA SP_TX_NET

.L3A
	STY SP_TX_FLAG
	STY SP_TUBEEN				;Set bit 7 = Stops the TUBE being released
	
.L4	LDA #2						;2 bytes in control buffer
	JMP sp_transmit

	;Send reset
.*sp_send_RESET
	LDA #&91
	STA RXTX_Flags_D4A
	LDA #0
	STA SP_TX_STN
	STA SP_TX_NET
	LDY #SP_FLAG_RESET
	BNE L3A
}


	;FINISHED RECEIVING DATA, NOW WHAT?
.Sub_98EE_Received_Data
{
	LDA RXTX_Flags_D4A
	BPL sp_send_DATAACK			;Send data ack
	
	;Immediate reply to PEEK or MACHINE TYPE
	JMP Sub_9EA8_tx_success
}


	\ IF TUBE : UPDATE END ADDRESS
	\ ptrA6 -> rcv control block
	\ Exit: Z=0 IF TUBE
.Sub_994E_TubeUpdateRxCB
{
	LDA #&02
	BIT RXTX_Flags_D4A
	BEQ Label_9994			; Not tube

	;Calc end address
	;ptrA6!8 += !&A2

	;CLC
	SEC
	PHP
	LDY #8

.Label_9959
	LDA (ptrA6L),Y
	PLP
	ADC &009A,Y
	STA (ptrA6L),Y
	INY
	PHP
	CPY #12
	BCC Label_9959

	PLP

.Label_9992
	LDA #&FF

.Label_9994
	;A = FF (TUBE) OR A = 0 (NOT TUBE)
	RTS
}


	\ Received data, sent ACK, now what?
.Sub_9995_RX_DataReceived
	LDA SP_RX_PORT
	BNE Sub_99A4_UpdateRxCB		;If Port <> 0 : Not immediate operation

	LDY SP_RX_CTRL				;Y = Ctrl byte
	CPY #&82
	BEQ Sub_99A4_UpdateRxCB		;If Ctrl byte = &82 (POKE)

	;Should be JSR/USER/OS only
	JSR Sub_9AE7_ExecuteImmediateRequest
	JMP Sub_99E8_ListenForScout

	\ Data or Poke (or broadcast)
.Sub_99A4_UpdateRxCB
{
	JSR Sub_994E_TubeUpdateRxCB	;If TUBE update end address in RxCB
	BNE Label_99BB				;If TUBE
	
	;Data buffer is in HOST

	LDA &A2						;ptrA4 += ?&A2
	;;CLC
	SEC							;MOD TO ORIGINAL
	ADC ptrA4L
	BCC Label_99B2

	INC ptrA4H

.Label_99B2
	LDY #8
	STA (ptrA6L),Y				;Update Buffer End
	INY
	LDA ptrA4H
	STA (ptrA6L),Y
	
.Label_99BB
	LDA SP_RX_PORT
	BEQ L1						;If Port = 0 : Immediate operation I.E. POKE

	\ Update receive control block

	LDA SP_RX_NET				;Source station net
	LDY #3
	STA (ptrA6L),Y
	DEY	;Y=2
	LDA SP_RX_STN				;Source station id
	STA (ptrA6L),Y
	DEY	;Y=1
	LDA SP_RX_PORT				;Port
	STA (ptrA6L),Y
	DEY	;Y=0
	LDA SP_RX_CTRL				;Control byte
	ORA #&80					;Message ready!
	STA (ptrA6L),Y
	
.L1
	;JMP Sub_99DB_ListenForScout
}

	\ Tidy up and listen for scout
.Sub_99DB_ListenForScout
	LDA #&02
	AND TubePresent_D67
	BIT RXTX_Flags_D4A
	BEQ Sub_99E8_ListenForScout	;If not tube
	
IF _SPDBG_
	;lda #'/'
	;jsr DBGWRCH
	;lda #'T'
	;jsr DBGWRCH
ENDIF
	
	JSR Release_Tube_Sub_9A2B	;Release tube

.Sub_99E8_ListenForScout
	JMP sp_listen4scout


	\ Copy data (8 bytes) from received frame to buffer
	\ ONLY USED WHEN BROADCAST RECEIVED
	
	;Preserves X - why?
.Sub_99F2_CopyDataToBuffer
{								;(Setup by call to Sub_9ECA_SetupCounters)
	TXA
	PHA							;Save X
	
	LDX #4						;Number of bytes = 12 - 4 = 8

	LDA #&02
	BIT RXTX_Flags_D4A
	BNE Label_9A19				;If TUBE

	;BUFFER IN HOST

	LDY &A2						;Copy to ptrA4 + ?A2

.Loop_99FF
	INY
	BEQ H1
		
.H2	LDA SP_RX_BUF,X
	STA (ptrA4L),Y

.Label_9A0D
	INX
	CPX #12
	BNE Loop_99FF
	
	STY &A2						;For update of RxCB

.Label_9A14
	PLA
	TAX							;Restore X
	JMP Sub_99A4_UpdateRxCB		;Update RxCB

.H1	INC ptrA4H
	DEC &A3
	BNE H2
	
	;Buffer overflowed
	
.HX	PLA
	TAX
	JMP Sub_99DB_ListenForScout

	;BUFFER OVER TUBE

.Label_9A19
	JSR Sub_9A37_IncCounter		;Increment counter
	BEQ HX						;Buffer overflow

	LDA SP_RX_BUF,X
	STA TUBE_R3_DATA

	INX
	CPX #12
	BNE Label_9A19
	BEQ Label_9A14				;always
}


.Release_Tube_Sub_9A2B
{
	BIT SP_TUBEEN				;If bit 7 set don't release it YET?
	BMI Label_9A34

	LDA #&82
	JSR TubeCode				;Release Tube (Low level primitives)

IF _SPDBG_
	;lda #'/'
	;jsr DBGWRCH
	;lda #'T'
	;jsr DBGWRCH
ENDIF

.Label_9A34
	LSR SP_TUBEEN				;Clear bit 7, release it NEXT TIME!
	RTS
}

	\ !&A2 += 1 (TUBE byte counter)
.Sub_9A37_IncCounter
{
	INC &A2
	BNE Label_9A45

	INC &A3
	BNE Label_9A45

	INC ptrA4L
	BNE Label_9A45

	INC ptrA4H

.Label_9A45
	RTS				;Z=1 if !&A2 == 0
}

	\ Received Immediate Request
.Sub_9A46_RX_ImmediateRequest
{
	LDY SP_RX_CTRL				;Control byte received
	CPY #&81
	BCC L1						;Y < &81

	CPY #&89
	BCS L1						;Y >= &89

	CPY #&87
	BCS Label_9A63				;Y == &87 CONT or &88 MACHINETYPE (no protecion)

	\ Is the machine protected?

	TYA
	SEC
	SBC #&81					;0 <= A <= 5
	TAY

	LDA ProtectionMask_D63

.Loop_9A5D
	ROR A
	DEY
	BPL Loop_9A5D
	BCC Label_9A63
	
	\ Not allowed, send a NAK

.L1	JMP sp_send_NAK				;Send a NAK
	
	\ Request allowed

.Label_9A63
	LDA SP_RX_CTRL
	CMP #&82
	BCC	Sub_9ABC_RX_PEEK		;81
	BEQ Sub_9A9F_RX_POKE		;82
	CMP #&86
	BCC Sub_9A81_RX_JSR			;83,84,85
	CMP #&88
	BCC Sub_9AD6_RX_HALTCONT	;86,87


	\ RCVD 88 MACHINETYPE
	\ Reply with four bytes of data.
.Sub_9AAA_RX_MACHINETYPE
	LDA #&01
	STA &A3						;?&A2 = &FC	   (&100 - &FC = 4 bytes)
	;LDA #&FC					;?&A3 = 1
	LDA #&FB					;Less 1 for new scheme
	STA &A2

	LDA #LO(Data_8021-&FC)		;ptrA4 -> Data to transmit.
	STA ptrA4L
	LDA #HI(Data_8021-&FC)
	STA ptrA4H
	BNE Label_9ACE				;always


	\ Received 83 JSR/84 User procedure/85 OS procedure
.Sub_9A81_RX_JSR
	LDA #&00					;Get ready to receive arguments
	STA ptrA4L					;ptrA4 = ptr9CH * &100
	;LDA #&82					;?&A2 = &82 (:. maximum of 126 bytes)
	LDA #&81					;Less 1 for new scheme
	STA &A2						;?&A3 = 1 (page)
	LDA #&01
	STA &A3
	LDA ptr9CH_PWS0
	STA ptrA4H

	LDY #3						;!&0D58 = Execution address etc.

.Loop_9A93
	LDA SP_RX_BUF + 4,Y
	STA &0D58,Y
	DEY
	BPL Loop_9A93
	
	JMP sp_send_SCOUTACK		;Send ACK, and wait for data.


	\ RCVD 82 POKE
.Sub_9A9F_RX_POKE
	LDA #LO(SP_RX_BUF)			;ptrA6 = SP_RX_BUF (contains RxCB)
	STA ptrA6L
	LDA #HI(SP_RX_BUF)
	STA ptrA6H
	JMP Sub_97B9_RX_FoundControlBlock
	

	\ RCVD 81 PEEK
.Sub_9ABC_RX_PEEK
	LDA #LO(SP_RX_BUF)			;ptrA6 = SP_RX_BUF (contains RxCB)
	STA ptrA6L
	LDA #HI(SP_RX_BUF)
	STA ptrA6H
	
	LDA #TUBEOP0
	STA TubeOp_D5C				;If Tube op : Transfer Parasite->Host
	JSR Sub_9ECA_SetupCounters	;Setup counters/Tube
	BCC Label_9B1D				;If failed (i.e. tube failed)
	

.Label_9ACE
	JMP sp_send_IMMDATA			;Transmit reply


	\ RCVD 86 HALT / 87 CONTINUE
.Sub_9AD6_RX_HALTCONT
	JSR sp_send_IMMACK			;Send ACK, and perform request.
	
	LDA SP_RX_CTRL
	CMP #&87
	BEQ Sub_9B5F_CONT

.Sub_9B48_HALT					;&86 HALT
	LDA #&04
	BIT RXTX_Flags_D64
	BNE Label_9B67				;If b3 set then already halted

	ORA RXTX_Flags_D64
	STA RXTX_Flags_D64			;Set b3

	LDA #&04
	CLI							;Enable interrupts

.Loop_9B58
	BIT RXTX_Flags_D64
	BNE Loop_9B58				;Idle until CONT received.
	BEQ Label_9B67				;always

.Sub_9B5F_CONT					;&87 CONTINUE
	LDA RXTX_Flags_D64
	AND #&FB					;Clear b3
	STA RXTX_Flags_D64

.Label_9B67
	RTS
			
.Label_9B1D
	JMP Sub_99E8_ListenForScout
}

	
	;Called after data received, i.e. arguments for JSR/USER/OS
	;Note: Interrupts disabled
.Sub_9AE7_ExecuteImmediateRequest
{
	;From routine at 9646
	LDA ProtectionMask_D63
	STA ProtectionMaskCopy_D65	;Save current mask
	ORA #&1C					;0001 1100 = disable further &83 JSR, &84 USER, &85 OS
	STA ProtectionMask_D63

	;From 9AE7
	LDA &A2						;Calc argument block size
	CLC
	ADC #&80

	LDY #&7F
	STA (ptr9CL_PWS0),Y			;PWSP1?&7F = Size of argument block.

	;LDY #&80
	INY	;Y=&80
	LDA SP_RX_STN				;PWSP1?&80 = Source station
	STA (ptr9CL_PWS0),Y
	INY
	LDA SP_RX_NET				;PWSP1?&81 = Source net
	STA (ptr9CL_PWS0),Y
	
	LDA SP_RX_CTRL				;ASSUME A=&83, &84 OR &85
	CMP #&84
	BEQ Sub_9B2E_USER
	BCS Sub_9B3C_OS
	
.Sub_9B25_JSR					;&83 JSR
	JMP (&0D58)					;!&D58 = copy of address from original scout

.Sub_9B2E_USER					;&84 USER
	LDY #8
	LDX &0D58
	LDA &0D59
	JMP OSEVEN					;Generate event Y=&08 Network Event => JSR EVNTV

.Sub_9B3C_OS					;&85 OS
	LDX &0D58
	LDY &0D59
	JMP langentry
}


	\ TX SUCCESSFUL
.Sub_9EA8_tx_success
	LDA #&00
	BEQ Sub_9EAE_tx_resultA		;always

	\ TX ERROR &41
.Sub_9EAC_tx_error41
	LDA #&41					;ERROR &41 = some part of 4-way handshake lost or damaged.

.Sub_9EAE_tx_resultA
	LDY #&00
	STA (ptrA0L),Y				;Return status : Let Transmit control block?0 = A

	;LDA #&80					;Return to listening.
	;STA Line_Not_Busy_D62
	JMP Sub_99DB_ListenForScout


	\**** Setup counters, start tube op if applicable
	\ ptrA6 -> buffer control block
	\ ?TubeOp_D5C = tube operation (if applicable)
	\ Exit: C = 1 if ok (else Tube failed)
.Sub_9ECA_SetupCounters
{
	LDY #6
	LDA (ptrA6L),Y
	INY
	AND (ptrA6L),Y
	CMP #&FF
	BEQ Label_9F19				;If buffer in host
	

	LDA TubePresent_D67
	BEQ Label_9F19				;If Tube not present

IF _SPDBG_
	;lda #'T'
	;jsr DBGWRCH
	;lda #'U'
	;jsr DBGWRCH
	;lda #'B'
	;jsr DBGWRCH
	;lda #'E'
	;jsr DBGWRCH
ENDIF

	\ **** USE TUBE ****
	LDA RXTX_Flags_D4A			;To TUBE
	ORA #&02
	STA RXTX_Flags_D4A

	;SEC
	CLC
	PHP
	LDY #4						;!&A2 = Buffer Start - Buffer End = Byte counter

.Loop_9EE6
	LDA (ptrA6L),Y
	INY
	INY
	INY
	INY
	PLP
	SBC (ptrA6L),Y
	STA &009A,Y
	DEY
	DEY
	DEY
	PHP
	CPY #8
	BCC Loop_9EE6

	PLP
	TXA
	PHA

	LDA #4
	CLC
	ADC ptrA6L
	TAX							;Assumes same page.
	LDY ptrA6H					;YX -> ptrA6!4 = Buffer Start

	LDA #&C2
	JSR TubeCode				;Claim Tube (Low level primitives)
	BCC Label_9F16				;If failed

	LDA TubeOp_D5C				;Operation
	JSR TubeCode

IF _SPDBG_
	;lda #'&'
	;jsr DBGWRCH
ENDIF

	JSR Release_Tube_Sub_9A2B	;Release Tube if TUBEBUSY reset
	SEC

.Label_9F16
	PLA
	TAX
	RTS							;C=0 if failed

	\ **** USE HOST ****
	\ ptrA4 = Base address
	\ ?&A2  = start offset (such that ptrA4 + ?&A2 = Buffer Start)
	\ ?&A3  = number of blocks
.Label_9F19						;To HOST
	LDY #4
	LDA (ptrA6L),Y

	LDY #8
	;SEC
	CLC
	SBC (ptrA6L),Y
	STA &A2

	LDY #5
	LDA (ptrA6L),Y
	SBC #0
	STA ptrA4H

	LDY #8
	LDA (ptrA6L),Y
	STA ptrA4L

	;LDY #9
	INY	;Y=9
	LDA (ptrA6L),Y

	SEC
	SBC ptrA4H
	STA &A3
	SEC

	RTS							;C=1=Success
}


	\ **************** Start Transmit *****************
	\ ************** SENDS SCOUT FRAME ****************
	\ Entry: ptrA0 -> control block (as OSWORD &10)
	\ Exit : X preserved
.Sub_9B6E_Transmit_Start
{
	;;0D50 is used to temp hold length of control buffer
	Scout_Len_D50 = &0D50

	TXA							;Save X
	PHA

	LDY #2
	LDA (ptrA0L),Y				;Destination Station
	STA SP_TX_STN
	INY
	LDA (ptrA0L),Y
	STA SP_TX_NET

IF _SPDBG_
IF FALSE
	lda #'@'
	jsr DBGWRCH
	lda SP_TX_NET
	JSR PRINT_HEX
	lda #'.'
	jsr DBGWRCH
	lda SP_TX_STN
	jsr PRINT_HEX_SPC
	ldy #0
	lda (ptrA0L),Y
	jsr PRINT_HEX_SPC	;CTRL
	iny
	lda (ptrA0L),Y
	jsr PRINT_HEX_SPC	;PORT
ENDIF
ENDIF

	LDY #0
	LDA (ptrA0L),Y				;A = Control byte
	BMI L2
	
.L1	LDA #&44					;Error &44 = Badly formed control block
	LDY #0
	STA (ptrA0L),Y				;Control Byte = A
	
	LDA #&80
	STA Line_Not_Busy_D62
	
	PLA
	TAX
	RTS

.L2	STA SP_TX_CTRL
	TAX							;X = Control byte (X is >=&80)

	INY
	LDA (ptrA0L),Y				;Destination Port
	STA SP_TX_PORT
	BNE Label_9BC5				;If Port > 0

	\ Port = 0 : Immediate Operation
	
	CPX #&83
	BCS Label_9BB1				;If X >= &83

	\ &81 PEEK and &82 POKE
	\ Note &80 trapped below and causes error.
	
	SEC							;SP_TX_BUF!8 = TxCB!8 - TxCB!4 = Buffer End - Buffer Start = Buffer Size
	PHP
	LDY #8

.Loop_9B9A
	LDA (ptrA0L),Y				;Buffer End
	DEY							;Y-=4
	DEY
	DEY
	DEY
	PLP
	SBC (ptrA0L),Y				;Buffer Start
	STA SP_TX_BUF+4,Y
	INY							;Y+=5
	INY
	INY
	INY
	INY
	PHP
	CPY #12
	BCC Loop_9B9A

	PLP

.Label_9BB1
	CPX #&81
	BCC L1						;If X < &81 Or

	CPX #&89
	BCS L1						;If X >= &89 : Error &44 Badly formed control block

	LDY #12						;SP_TX_BUF!4 = TxCB!12 = Remote Start Address

.Loop_9BBB
	LDA (ptrA0L),Y
	STA SP_TX_BUF-8,Y
	INY
	CPY #16
	BCC Loop_9BBB

.Label_9BC5
	LDA #4						;Setup scout packet:
	STA Scout_Len_D50			;Number of bytes in control buffer.

	SEC
	ROR SP_TUBEEN

	LDA SP_TX_PORT
	BNE Label_9C8E				;If Destination Port != 0

	\ Destination Port == 0 :. Immediate Operation

	LDY SP_TX_CTRL				;Y = control byte (&81 to &88)

	LDA Data_9EC2-&81,Y
	STA RXTX_Flags_D4A

	LDA Data_9EBA-&81,Y
	STA Scout_Len_D50			;Number of bytes in scout (for immediate operations).
	
	CPY #&82
	BCC Sub_9C6F				;81 PEEK
	BEQ Sub_9C73				;82 POKE
	
	CPY #&86
	BCC Sub_9CB5				;83 JSR, 84 User, 85 OS
	
	CPY #&88
	BCC Sub_9CC5				;86 Halt, 87 Continue
	
	;88 Machine Type

.Sub_9C6B						;Control &88 MACHINE TYPE
	LDA #TUBEOP1
	BNE Label_9CB7				;always

.Sub_9C6F						;Control &81 PEEK
	LDA #TUBEOP1
	BNE Label_9C75				;always

.Sub_9C73						;Control &82 POKE
	LDA #TUBEOP0

.Label_9C75
	STA TubeOp_D5C

	CLC
	PHP
	
	LDY #12

.Loop_9C7C
	LDA SP_TX_BUF-4,Y			;SP_TX_BUF!8 += TxCB!12 (i.e. Remote Start Address + Buffer Size = Remote End Address)
	PLP
	ADC (ptrA0L),Y
	STA SP_TX_BUF-4,Y
	INY
	PHP
	CPY #16
	BCC Loop_9C7C

	PLP
	BCC Label_9CBA				;Always

.Label_9C8E						;Destination Port != 0
	LDA SP_TX_STN
	AND SP_TX_NET
	CMP #&FF
	BNE Label_9CB0				;If Destination Station != &FFFF

	\ BROADCAST

	LDA #4+8					;Broadcast scout length
	STA Scout_Len_D50

	LDA #&40
	STA RXTX_Flags_D4A

	LDY #4						;Copy control block broadcast data (8 bytes)

.Loop_9CA4
	LDA (ptrA0L),Y
	STA SP_TX_BUF,Y
	INY
	CPY #12
	BCC Loop_9CA4
	BCS Sub_9CC5				;always

.Label_9CB0
	LDA #0
	STA RXTX_Flags_D4A

.Sub_9CB5						;Control byte &83 JSR, &84 User, &85 OS
	LDA #TUBEOP0

.Label_9CB7
	STA TubeOp_D5C

.Label_9CBA
	LDA ptrA0L					;ptrA6 = ptrA0
	STA ptrA6L
	LDA ptrA0H
	STA ptrA6H
	JSR Sub_9ECA_SetupCounters	;Set up to receive immediate reply (data frame)

.Sub_9CC5						;Control byte &86 Halt, &87 Continue
	\ SEND SCOUT

	LDA #SP_FLAG_SCOUT
	STA SP_TX_FLAG

	LDA Scout_Len_D50			;bytes in control buffer
	JSR sp_transmit

	PLA							;Restore X
	TAX
	RTS

.Data_9EBA						;Bytes in scout for immediate requests &81 to &88
	EQUB 4+8, 4+8, 4+4, 4+4, 4+4, 4, 4, 4+4

.Data_9EC2						;RXTX_Flags_D4A value
	EQUB &81, &00, &00, &00, &00, &01, &01, &81
	
	;FLAGS
	;BIT 0 : SET = NO DATA, CLEAR = SEND DATA
	;BIT 7 : SET = WAIT FOR DATA, CLEAR = WAIT FOR ACK
	
	;81	8	; 81 PEEK			NO DATA TO SEND, 		WAIT FOR DATA
	;00	8	; 82 POKE			SEND DATA,				WAIT FOR ACK
	;00	4	; 83 JSR
	;00	4	; 84 User
	;00	4	; 85 OS
	;01	0	; 86 Halt			NO DATA TO SEND,		WAIT FOR ACK
	;01	0	; 87 Continue
	;81	4	; 88 Machine Type	NO DATA TO SEND,		WAIT FOR DATA
}

	;Transmitter timed out
.sp_transmit_error
{
	LDA #&10
	BIT RXTX_Flags_D4A
	BNE	L1
	
	;Tried to transmit Broadcast/Scout/Data
	
	JMP Sub_9EAC_tx_error41
	
	;Tried to transmit an ACK/NAK/Immediate Reply.

.L1	JMP Sub_99DB_ListenForScout
}

	;Called after last byte of frame transmitted.
.Sub_9D14_Frame_Sent
{
IF _SPDBG_
	;lda #'%'
	;jsr DBGWRCH
;	lda RXTX_Flags_D4A
;	jsr PRINT_HEX_SPC
ENDIF
	
	LDA #&10
	BIT RXTX_Flags_D4A
	BNE	J30					;ACK/NAK transmitted.
	BVC J26					;If flag bit 6 clear, NOT BROADCAST
	
	;BROADCAST
	;Successful TX, update flag in TxCB
	JMP Sub_9EA8_tx_success
	
.J26
	;bit 0 clear and bit 7 clear = WAIT FOR ACK
	;bit 0 clear and bit 7 set = TX COMPLETE, NOTHING TO DO
	;bit 1 set and bit 7 clear = WAIT FOR ACK
	;bit 1 set and bit 7 set = WAIT FOR DATA

	LDA #&01
	BIT RXTX_Flags_D4A
	BNE J27					;If bit 0 set
	BMI J25					;If bit 0 clear and bit 7 set

.J27
	BMI J28A				;If bit 7 set
	
	LDA #SP_FLAG_ACK
	BNE J29					;Always
	
.J28
	BNE J31					;Just sent a Data ACK

.J28A	
	;Just sent a Scout ACK, or an Immediate Request - wait for data.
	LDA #SP_FLAG_DATA
	
.J29
	JMP sp_listen4flag		;Listen for ACK/DATA
	
	;Just sent a Data ACK, finish up.
.J31
	JMP Sub_9995_RX_DataReceived
	
	;Just tranmitted and ACK/NAK or a reply to an immediate request.
	;If bit 7 set:
	;	NAK or Immediate Reply
	;If bit 7 clear:
	;	If bit 3 clear = ACK to scout, wait for data
	;	If bit 3 set = ACK to data
.J30
	LDA #&08
	BIT RXTX_Flags_D4A
	BPL J28					;ACK
	
	;Unknown state or TX complete	
.J25
	JMP Sub_99DB_ListenForScout
}

\\\ END OF FILE
