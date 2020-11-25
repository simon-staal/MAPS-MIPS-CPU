// SW and XOR

always @(posedge clk) begin
	if (reset) begin
		pc <= memory['hBFC00000]
		active <= 1;
		state <= FETCH;
	end
	else if (state == FETCH) begin
		instr <= readdata; //read control signal needs to be high
		state <= EXEC;
	end
	else if (state == EXEC) begin
		case(instr)
			OPCODE_SW: begin
				reg_readdata1 <= register_file[rt]; // store contents of rt in readdata1
				reg_writedata <= (base + instr_imm); //base + offset for memory addressing. instr_imm needs to be sign extended
				PC <= PC + PC_increment; //increment PC here so it is ready to be fetched on next cycle.
				state <= MEM_ACCESS; //set waitrequest to high
			end
			FUNCTION_XOR: begin
				reg_readdata1 <= register_file[rt];
				reg_readdata2 <= register_file[rs];
				state <= MEM_ACCESS;
			end
	else if (state == MEM_ACCESS) begin
		case(instr)
			OPCODE_SW: begin
				memory[reg_writedata] <= reg_readdata1; //write logic should be high
				state <= FETCH;
			end
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

if (state == EXEC && instr == OPCODE_SW) begin
	assign waitrequest = 1;
end

if (state == MEM_ACCESS %% instr == OPCODE_SW) begin
	assign write = 1;
end



/* Notes 

SW doesn't need last cycle? 

*/