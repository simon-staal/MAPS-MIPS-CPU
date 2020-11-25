always @(posedge clk) begin
	if (state == FETCH) begin
		state <= (waitrequest) ? FETCH : EXEC;
	end
	else if (state == EXEC) begin
		ir <= readdata;
		case(instr)
			OPCODE_SW: begin
				address <= reg_readdata1 + instr_imm; //instr_imm needs to be sign extended
				writedata <= reg_readdata2; //store contents of $rt in writedata.
				state <= (waitrequest) ? EXEC : FETCH;
			end
	else if (state == MEM_ACCESS) begin
		case(instr)
			
	end
end

/* Notes

I've done main memory write in this module, but should we have a separate module for it instead? Like DT did for MU0_delay1? How would this affect SW instruction cycles?
FETCH cycle is same for every instruction?
Do we need an acc? Or can rs + instr_imm happen combinatorially, in which case we dont need MEM_ACCESS cycle for SW?

*/
