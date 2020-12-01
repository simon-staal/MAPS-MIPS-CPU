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
		reg_write_en = 1;
		reg_writedata = reg_readdata1 ^ reg_readdata2;
  end
	if (state == EXEC && instr == FUNCTION_SRA) begin
		reg_write_en = 1;
		reg_writedata = reg_readdata1 >>> instr[10:6];
	end
	if (state == EXEC && instr == FUNCTION_SRL) begin
		reg_write_en = 1;
		reg_writedata = reg_readdata1 >> instr[10:6];
	end
	if (state == EXEC && instr == OPCODE_XORI) begin
		reg_write_en = 1;
		reg_writedata = reg_readdata1 ^ instr_imm; // Need to sign extend instr_imm
	end
	if (state == EXEC && instr == FUNCTION_SUBU) begin
		reg_write_en = 1;
		reg_writedata = reg_readdata1 - reg_readdata2;
	end
	if (state == EXEC && instr == FUNCTION_SRLV) begin
		reg_write_en = 1;
		reg_writedata = reg_readdata1 >> reg_readdata2;
	end
	if (state == EXEC && instr == FUNCTION_SRAV) begin
		reg_write_en = 1;
		reg_writedata = reg_readdata1 >>> reg_readdata2;
	end
	if (state == EXEC && instr == FUNCTION_SLTU) begin
		reg_write_en = 1;
		if (reg_readdata1 < reg_readdata2) begin
			reg_writedata = 1;
		end
		else begin
			reg_writedata = 0;
		end
	end
end



/* Notes

SW doesn't need last cycle?
What about sign extending instr_imm? Where is that done?
Little endian encoding. 

Control Logic:
- Do we need a PC_write signal? So PC is changed only on certain cycles and depending on some instructions, e.g. Jr?	
SW: 
- RAM write_en high during write to main memory


*/
