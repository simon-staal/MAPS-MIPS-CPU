always_comb begin
        if(state == FETCH) begin
            byteenable = 4'b1111;
            read = 1;
            write = 0;
            address = pc;
        end
        if(state == EXEC) begin
            //ADD LOGIC FOR LOAD / STORE INSTRUCTIONS
            if(instr_opcode == OPCODE_SB)begin
            byteenable=4'b0001;
            write=1;
            address = reg_readdata1 + instr_imm;
            end

            else if(instr_opcode ==OPCODE_SH )begin
            byteenable=4'b0011;
            write=1;
            address = reg_readdata1 + instr_imm;
            end

        end
    end

always_ff @ (posedge clk) begin
    if(reset) begin
        state <= FETCH;
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
              FUNCTION_OR: begin
                assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                regs[rd] <= regs[rs] || regs[rt];
              end
              FUNCTION_SLT: begin
                assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                regs[rd] <= (regs[rs] -regs[rt])>>32;
          end
          OPCODE_ORI: begin
            regs[rt] <= regs[rs] || instr_imm;
          end
          OPCODE_SLTI: begin
            if (instr_imm[15]==1)begin
            regs[rt] <= (regs[rs] - {16'h0001,instr_imm})>>32;
           end
            else if (instr_imm[15]==O)begin
            regs[rt] <= (regs[rs] - { 16'h0000,instr_imm})>>32;
           end
            
           
          end
          FUNCTION_SLLV: begin
            regs[rd] <= regs[rs] << regs[rt];
          end
          OPCODE_SLTIU: begin
            regs[rt] <= (regs[rs] - { 16'h0000,instr_imm})>>32;
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
