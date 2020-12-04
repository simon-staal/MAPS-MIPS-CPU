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
			OPCODE_SB: begin //writedata should be set to high in this cycle, address and writedata assignments should be combinatorial
				state <= (waitrequest) ? EXEC : FETCH;
				pc <= (waitrequest) ? pc : PC_increment;
			end
			OPCODE_SH: begin //writedata should be set to high in this cycle, address and writedata assignments should be combinatorial
				state <= (waitrequest) ? EXEC : FETCH;
				pc <= (waitrequest) ? pc : PC_increment;
			end
			FUNCTION_OR: begin
				state <= FETCH;
				pc <= (waitrequest) ? pc : PC_increment;
			end
	else if (state == MEM_ACCESS) begin
	end
	else if (state == WRITE_BACK) begin
		case(instr)
			OPCODE_SB: begin
			end
			OPCODE_SH: begin
			end
end
always_comb begin
	if (state == EXEC && instr == OPCODE_SB) begin
		write = 1; 
		address = reg_readdata1 + instr_imm; //reg_readdata1 contains the value stored in rs. Need to sign extend instr_imm
		writedata = reg_readdata2[7:0]; //reg_readdata2 contains value stored in rt 
  end
  if (state == EXEC && instr == OPCODE_SH) begin
		write = 1; 
		address = reg_readdata1 + instr_imm; //reg_readdata1 contains the value stored in rs. Need to sign extend instr_imm
		writedata = reg_readdata2[15:0]; //reg_readdata2 contains value stored in rt 
  end
	if (state == EXEC && instr == FUNCTION_OR) begin
		reg_write_en = 1;
		reg_writedata = reg_readdata1 || reg_readdata2;
  end
	if (state == EXEC && instr == FUNCTION_SLT) begin
		reg_write_en = 1;
		 assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
		reg_writedata = (reg_readdata1 - reg_readdata2)>>31;//msb?
	end
	if (state == EXEC && instr == FUNCTION_SLL) begin
		reg_write_en = 1;
		assert(shift != 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
		reg_writedata = reg_readdata1<< shift; //shift by sa 
	end
	if (state == EXEC && instr == OPCODE_ORI) begin
		reg_write_en = 1;
		reg_writedata = reg_readdata1 || instr_imm; // Need to sign extend instr_imm
	end
	
	if (state == EXEC && instr == FUNCTION_SLLV) begin
		reg_write_en = 1;
		assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
		reg_writedata = reg_readdata1 << reg_readdata2;
	end
	if (state == EXEC && instr == FUNCTION_SLTI) begin
		reg_write_en = 1;
		if (reg_readdata1 <instr_imm ) begin// need to sign extend intr_imm
			reg_writedata = 1;
		end
		else begin
			reg_writedata = 0;
		end
		
	end
	if (state == EXEC && instr == FUNCTION_SLTIU) begin
		reg_write_en = 1;
		if (reg_readdata1 <instr_imm ) begin// Need to extend instr_imm
			reg_writedata = 1;
		end
		else begin
			reg_writedata = 0;
		end
	end
end

