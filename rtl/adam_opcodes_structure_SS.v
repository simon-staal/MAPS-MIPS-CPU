// SW and XOR

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
				reg_readdata1 <= register_file[rt];
				reg_readdata2 <= register_file[rs];
				state <= MEM_ACCESS;
			end
	else if (state == MEM_ACCESS) begin
		case(instr)
			FUNCTION_XOR: begin
				register_file[rd] <= reg_readdata1 ^ reg_readdata2;
				state <= FETCH;
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
    address = reg_readdata1 + instr_imm; //reg_readdata1 contains the value stored in rs
    writedata = reg_readdata2; //reg_readdata2 contains value stored in rt
  end
end



/* Notes

SW doesn't need last cycle?

*/
