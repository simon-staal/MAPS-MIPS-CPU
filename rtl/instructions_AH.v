	    always_comb begin
        if(state == FETCH) begin
            byteenable = 4'b1111;
            read = 1;
            write = 0;
            address = pc;
        end
        if(state == EXEC) begin
			case(instr_opcode)
				OPCODE_SW: begin 
				write = 1;
				byteenable = 4'b1111;
				address = regs[rs] + instr_imm;
				writedata = regs[rt];
				end
            endcase
        end
    end
	
    always_ff @ (posedge clk) begin
        if(reset) begin
            state <= FETCH;
            active <= 1;
            pc <= 32'hBFC00000;
        end
        else if(pc == 32'h00000000) begin
            state <= HALTED;
            active <= 0;
        end
        else if(state == FETCH) begin
            state <= (waitrequest) ? FETCH : EXEC;
        end
        else if(state == EXEC) begin
            state <= (waitrequest && mem_access) ? EXEC : () ? MEM_ACCESS : FETCH; //Add condition if instruction requires mem access / if instruction requires writing back to a register
            pc <= (waitrequest) ? pc : (delay) ? pc_jmp : pc_increment;
            delay <= 0; //Resets the value of delay
            case(instr_opcode)
              OPCODE_R: begin
                case(instr_function)
	 // Adam instructions: XOR, SRL, SRA, SRLV, SRAV, SLTU, SUBU
					  FUNCTION_XOR: begin
						regs[rd] <= regs[rs] ^ regs[rt];
					  end
					  FUNCTION_SRL: begin
						regs[rd] <= regs[rt] >> shift; 
					  end
					  FUNCTION_SRA: begin
						regs[rd] <= regs[rt] >>> shift;
					  end
					  FUNCTION_SRLV: begin
					  regs[rd] <= regs[rt] >> regs[rs];
					  end
					  FUNCTION_SRAV: begin
					  regs[rd] <= regs[rt] >>> regs[rs];
					  end
					  FUNCTION_SLTU: begin
						if (regs[rs] < regs[rt]) begin
							regs[rd] <= 1;
						end
						else begin
							regs[rd] <= 0;
						end
					  end
					  FUNCTION_SUBU: begin
					  regs[rd] <= regs[rs] - regs[rt];
					  end
				end
					//Adam instructions: XORI, SW (SW done combinatorially). 
					OPCODE_XORI: begin
					regs[rs] <= regs[rt] ^ instr_imm;
					end
					OPCODE_SW: begin	
					end
				end
				else if(state == MEM_ACCESS) begin
					state <= (waitrequest) ? MEM_ACCESS : FETCH
				end
				else if(state == HALTED) begin
					//Do nothing
				end
				else begin
					$fatal(1, "CPU : ERROR : Processor in unexpected state %b", state);
				end
			end
			end
			end
			
					