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
              FUNCTION_ADDU: begin
                assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                regs[rd] <= regs[rs] + regs[rt];
              end
              FUNCTION_AND: begin
                assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                regs[rd] <= regs[rs] & regs[rt];
          end
          OPCODE_ADDIU: begin
            regs[rt] <= regs[rs] + instr_imm;
          end
          OPCODE_ANDI: begin
            regs[rt] <= regs[rs] & instr_imm;
          end
          OPCODE_BEQ: begin
            assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
            if(regs[rs] == regs[rt]) begin
              pc_jmp <= pc_increment + instr_imm << 2;
              delay <= 1;
            end
          end
          OPCODE_REGIMM: begin
            assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
            case(rt)
              BGEZ: begin
                if(regs[rs] >= 0) begin
                  pc_jmp <= pc_increment + instr_imm << 2;
                  delay <= 1;
                end
              end
              BGEZAL: begin
                if(regs[rs] >= 0) begin
                  pc_jmp <= pc_increment + instr_imm << 2;
                  delay <= 1;
                  regs[31] <= pc_increment + 4;
                end
              end
              BLTZ: begin
                if(regs[rs] < 0) begin
                  pc_jmp <= pc_increment + instr_imm << 2;
                  delay <= 1;
                end
              end
              BLTZAL: begin
                if(regs[rs] < 0) begin
                  pc_jmp <= pc_increment + instr_imm << 2;
                  delay <= 1;
                  regs[31] <= pc_increment + 4;
                end
              end
          end
          OPCODE_BGTZ: begin
            if(regs[rs] > 0) begin
              pc_jmp <= pc_increment + instr_imm << 2;
              delay <= 1;
            end
          end
          OPCODE_BLEZ: begin
            if(regs[rs] <= 0) begin
              pc_jmp <= pc_increment + instr_imm << 2;
              delay <= 1;
            end
          end
          OPCODE_BNE: begin
            if(regs[rs] != regs[rt]) begin
              pc_jmp <= pc_increment + instr_imm << 2;
              delay <= 1;
            end
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
