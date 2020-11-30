// My opcodes: SLTU, SRA, SRAV, SRL, SRLV, SUBU, SW, XOR, XORI

always @(posedge clk) begin
	if (reset) begin
		pc <= 32'hBFC00000;
		active <= 1;
		state <= FETCH;
	end
	else if (state == FETCH) begin
		state <= (waitrequest) ? FETCH : EXEC;
	end
	else if (state == EXEC) begin
		ir <= readdata;
		case(instr)
			OPCODE_SW: begin //writedata should be set to high in this cycle, address and writedata assignments should be combinatorial
				state <= (waitrequest) ? EXEC : FETCH;
				pc <= (waitrequest) ? pc : PC_increment;
			end
			FUNCTION_XOR: begin
				state <= FETCH;
				pc <= (waitrequest) ? pc : PC_increment;
			end
	else if (state == MEM_ACCESS) begin
		case(instr)
			FUNCTION_XOR: begin
			end
	end
	else if (state == WRITE_BACK) begin
		case(instr)
			OPCODE_SW: begin
			end
end

// Control logic for SW
always_comb begin
	if (state == EXEC && instr == OPCODE_SW) begin
		write = 1;
		address = reg_readdata1 + instr_imm; //reg_readdata1 contains the value stored in rs. Need to sign extend instr_imm
		writedata = reg_readdata2; //reg_readdata2 contains value stored in rt
  end
	if (state == EXEC && instr == FUNCTION_XOR) begin
		write = 1;
		writedata = reg_readdata1 ^ reg_readdata2;
  end
	if (state == EXEC && instr == FUNCTION_SRA) begin
		write = 1;
		writedata = reg_readdata1 >>> instr[10:6];
	end
	if (state == EXEC && instr == FUNCTION_SRL) begin
		write = 1;
		writedata = reg_readdata1 >> instr[10:6];
	end
	if (state == EXEC && instr == OPCODE_XORI) begin
		write = 1;
		writedata = reg_readdata1 ^ instr_imm; // Need to sign extend instr_imm
	end
	if (state == EXEC && instr == FUNCTION_SUBU) begin
		write = 1;
		writedata = reg_readdata1 - reg_readdata2;
	end
	if (state == EXEC && instr == FUNCTION_SRLV) begin
		write = 1;
		writedata = reg_readdata1 >> reg_readdata2;
	end
	if (state == EXEC && instr == FUNCTION_SRAV) begin
		write = 1;
		writedata = reg_readdata1 >>> reg_readdata2;
	end
	if (state == EXEC && instr == FUNCTION_SLTU) begin
		write = 1;
		if (reg_readdat1 < reg_readdata2) begin
			writedata = 1;
		end
		else begin
			writedata = 0;
		end
	end
end



/* Notes

SW doesn't need last cycle?
What about sign extending instr_imm? Where is that done?

Control Logic:
SW: 
- RAM write_en high during write to main memory


*/
