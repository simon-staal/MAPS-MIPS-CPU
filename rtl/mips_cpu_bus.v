`include "mips_cpu_definitions.v"

module mips_cpu_bus(
    /* Standard signals */
    input logic clk,
    input logic reset,
    output logic active,
    output logic[31:0] register_v0,

    /* Avalon memory mapped bus controller (master) */
    output logic[31:0] address,
    output logic write,
    output logic read,
    input logic waitrequest,
    output logic[31:0] writedata,
    output logic[3:0] byteenable,
    input logic[31:0] readdata
    );

    //Creates basic registers
    logic[31:0] pc, pc_increment;
    assign pc_increment = pc + 4;
    logic[31:0] ir;
    logic ir_write;

    //Create non GPR HI and LO registers
    logic[31:0] HI;
    logic[31:0] LO;

    //Divide intruction into seperate signals
    logic[31:0] instr;
    opcode_t instr_opcode;
    function_t instr_function;
    state_t state;
    logic[4:0] rs, rt, rd, shift;
    logic[15:0] instr_imm;
    logic[25:0] instr_index;

    assign instr = (state==FETCH) ? readdata : ir;
    assign intr_opcode = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign shift = instr[10:6];
    assign instr_function = instr[5:0];
    assign instr_imm = instr[15:0];
    assign instr_index = intr[25:0];

    /* Defines an array of 32 registers used by MIPS whit the following purposes:
    $zero (0): constant 0
    $at (1): assembler temporary
    $v0-$v1 (2-3): values for function returns and expression evaluation
    $a0-$a3 (4-7): function arguments
    $t0-$t7 (8-15): temporaries
    $s0-$s7 (16-23): saved temporaries
    $t8-$t9 (24-25): temporaries
    $k0-$k1 (26-27): reserved for OS kernel
    $gp (28): global pointer
    $sp (29): stack pointer
    $fp (30): frame pointer
    $ra (31): return address
    */
    logic[31:0] regs[31:0];
    assign regs[0] = 32'h00000000;
    assign register_v0 = regs[2];

    //Stores values for branch / jmp instructions
    logic[31:0] pc_jmp;
    logic delay;

    //Used for 2 cycle memory access instructions (stores) for waitrequest logic in controlling pc
    logic mem_access;

    initial begin
        state = HALTED;
        active = 0;
    end


    always_comb begin
        if(state == FETCH) begin
            byteenable = 4'b1111;
            read = 1;
            write = 0;
            address = pc;
        end
        if(state == EXEC) begin
            //ADD LOGIC FOR LOAD / STORE INSTRUCTIONS
            if(instr_opcode == )

            else if(instr_opcode == )

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
                  FUNCTION_ADDU: begin
                    assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= regs[rs] + regs[rt];
                  end
                  FUNCTION_AND: begin
                    assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= regs[rs] & regs[rt];
                  end
                  FUNCTION_MTHI:begin
                    assert(({rd,rt,shift}==15'h0000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    HI <= regs[rs];
                  end
                  FUNCTION_MTLO:begin
                    assert(({rd,rt,shift}==15'h0000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    LO <= regs[rs];
                  end
                  FUNCTION_MULT:begin
                    assert(({rd,shift}==10'h0000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    LO <= regs[rs][15:0]*regs[rt][15:0];
                    HI <= regs[rs][31:16]*regs[rt][31:16];
                  end
                  FUNCTION_MULTU:begin
                    assert(({rd,shift}==10'h0000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    LO <= regs[rs][15:0]*regs[rt][15:0];
                    HI <= regs[rs][31:16]*regs[rt][31:16];
                  end
                  //T0-DO: add MFHI and MFLO
                  FUNCTION_MFHI:
                  FUNCTION_MFLO:
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
              //SD instructions
              OPCODE_LH: address = regs[rs]+instr_imm;
              OPCODE_LHU: address = regs[rs]+instr_imm;
              OPCODE_LUI: begin
                assert(rs==5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc );
                regs[rt] <= {instr_imm, 16'h0000};
              end
              OPCODE_LW: address = regs[rs] + instr_imm;
              OPCODE_LWL: address = regs[rt] + instr_imm;
              OPCODE_LWR: address = regs[rt] + instr_imm;

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
            case (instr_opcode)
              OPCODE_LH: regs[rt] <= {16[readdata[15]],readdata[15:0]};
              OPCODE_LHU: regs[rt] <= {16'h0000, readdata[15:0]};
              OPCODE_LW: regs[rt] <= readdata;
              OPCODE_LWL:regs[rt] <= {readdata[31:16],regs[rt][15:0]};
              OPCODE_LWR: regs[rt] <= {regs[rt][31:16], readdata[15:0]};
            endcase
        end
        else if(state == HALTED) begin
            //Do nothing
        end
        else begin
            $fatal(1, "CPU : ERROR : Processor in unexpected state %b", state);
        end
    end

endmodule
