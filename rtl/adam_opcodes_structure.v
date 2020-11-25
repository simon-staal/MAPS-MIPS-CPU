always @(posedge clk) begin
	if (state == FETCH) begin
		instr <= readdata; //read control signal needs to be high
		state <= EXEC;
	end
	else if (state == EXEC) begin
		case(instr)
			OPCODE_SW: begin
				acc <= rs + instr_imm; //instr_imm needs to be sign extended
				writedata <= register_file[rt]; //store contents of $rt in writedata. 
				state <= MEM_ACCESS;
			end
	else if (state == MEM_ACCESS) begin
		case(instr)
			OPCODE_SW: begin
				memory[acc] <= writedata; //MemWrite control signal needs to be high.
				pc <= pc_increment;
				state <= FETCH;
			end
	end
end

/* Notes 

I've done main memory write in this module, but should we have a separate module for it instead? Like DT did for MU0_delay1? How would this affect SW instruction cycles?
FETCH cycle is same for every instruction? 
Do we need an acc? Or can rs + instr_imm happen combinatorially, in which case we dont need MEM_ACCESS cycle for SW?

*/