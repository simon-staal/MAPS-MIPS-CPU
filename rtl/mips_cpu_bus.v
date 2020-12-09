`include "mips_cpu_definitions.vh"

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
    assign instr_opcode = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign shift = instr[10:6];
    assign instr_function = instr[5:0];
    assign instr_imm = instr[15:0];
    assign instr_index = instr[25:0];

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

    //Intermediary logic for aligning addresses
    logic [31:0] address_calc = regs[rs] + instr_imm;
    logic [1:0] alignment = address_calc[1:0];
    //address = {adress_calc[31:2], 2'b00};
    //byteenable[alignment] = 1

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
      			if(instr_opcode == OPCODE_SW) begin
      				write = 1;
      				read = 0;
      				byteenable = 4'b1111;
              assert(regs[rs] + instr_imm ==)
      				address = regs[rs] + instr_imm;
      				writedata = regs[rt];
      			end
            //TODO: FIX
            /*
            if(instr_opcode==OPCODE_SB) begin
              byteenable = 4'b0001;
              write = 1;
              read = 0;
              address = regs[rs] + instr_imm;
              writedata = (regs[rt])[7:0];
            end
            else if(instr_opcode==OPCODE_SH) begin
              byteenable = 4'b0011;
              write = 1;
              read = 0;
              address = regs[rs] + instr_imm;
              writedata = (regs[rt])[15:0];
            end
            */
            else if(instr_opcode==OPCODE_LB) begin
              read = 1;
              write = 0;
              byteenable = 4'b0001;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LBU) begin
              read = 1;
              write = 0;
              byteenable = 4'b0001;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LH) begin
              read = 1;
              write = 0;
              byteenable = 4'b1100;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LHU) begin
              read = 1;
              write = 0;
              byteenable = 4'b1100;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LW) begin
              read = 1;
              write = 0;
              byteenable = 4'b1111;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LWL) begin
              read = 1;
              write = 0;
              byteenable = 4'b1100;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else if(instr_opcode==OPCODE_LWR) begin
              read = 1;
              write = 0;
              byteenable = 4'b0011;
              //TO-DO: add signal exception for address error (address[0]==0)
              address = regs[rs]+instr_imm;
            end
            else begin
              read = 0;
              write = 0;
              byteenable = 0;
              address = pc;
            end
        end
    end


    always @ (posedge clk) begin
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
            state <= (waitrequest && mem_access) ? EXEC : (instr_opcode==OPCODE_LW) ? MEM_ACCESS : FETCH; //Add condition if instruction requires mem access / if instruction requires writing back to a register
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
                  FUNCTION_DIV: begin
            		    //not sure whether an assert is required here
            		    regs[LO] <= regs[rs]/regs[rt];
            		    regs[HI] <= regs[rs]%regs[rt];
            		    //does verilog automatically sign extend?
            		  end
            		  FUNCTION_DIVU: begin
            		    //not sure whether an assert is required here
            		    regs[LO] <= regs[rs]/regs[rt];
            		    regs[HI] <= regs[rs]%regs[rt];
            		  end
                  FUNCTION_JALR: begin
            		    assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
            		    regs[rd] <= pc + 8;
            		    pc_jmp <= regs[rs];
            		    delay <= 1;
            		  end
            		  FUNCTION_JR: begin
            		    assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
            		    pc_jmp <= regs[rs];
            		    delay <= 1;
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
                    assert(({rd,shift}==10'h000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    LO <= regs[rs][15:0]*regs[rt][15:0];
                    HI <= regs[rs][31:16]*regs[rt][31:16];
                  end
                  FUNCTION_MULTU:begin
                    assert(({rd,shift}==10'h000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    LO <= regs[rs][15:0]*regs[rt][15:0];
                    HI <= regs[rs][31:16]*regs[rt][31:16];
                  end
                  FUNCTION_MFHI:begin
                    assert(({rs,rt,shift}==15'h0000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= HI;
                  end
                  FUNCTION_MFLO:begin
                    assert(({rs,rt,shift}==15'h0000)) else $fatal(3, "CPU : ERROR: Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= LO;
                  end
                  FUNCTION_OR: begin
                    assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= regs[rs] || regs[rt];
                  end
                  FUNCTION_SLT: begin
                    assert(shift == 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= (regs[rs] - regs[rt])>>32;
                  end
                  FUNCTION_SLL: begin
                    assert(shift != 5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc);
                    regs[rd] <= regs[rs] << shift;
                  end
                  FUNCTION_SLLV: begin
                    regs[rd] <= regs[rs] << regs[rt];
                  end
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
                endcase
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
              OPCODE_LUI: begin
                assert(rs==5'b00000) else $fatal(3, "CPU : ERROR : Invalid instruction %b at pc %b", instr, pc );
                regs[rt] <= {instr_imm, 16'h0000};
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
                endcase
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
              OPCODE_J: begin
            		assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
            		pc_jmp <= instr_imm;
            		delay <= 1;
      	      end
      	      OPCODE_JAL: begin
            		assert(delay == 0) else $fatal(4, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %b", instr, pc);
            		regs[31] <= pc + 8;
            		pc_jmp <= instr_imm;
            		delay <= 1;
            	end
              OPCODE_ORI: begin
                regs[rt] <= regs[rs] || instr_imm;
              end
              OPCODE_SB: begin
                mem_access <= 1;
              end
              OPCODE_SH: begin
                mem_access <= 1;
              end
              OPCODE_SLTI: begin
                if (instr_imm[15]==1)begin
                  regs[rt] <= (regs[rs] - {16'h0001,instr_imm})>>32;
                end
                else if (instr_imm[15]==0)begin
                  regs[rt] <= (regs[rs] - { 16'h0000,instr_imm})>>32;
                end
              end
              OPCODE_SLTIU: begin
                regs[rt] <= (regs[rs] - { 16'h0000,instr_imm})>>32;
              end
      			  OPCODE_XORI: begin
      					regs[rs] <= regs[rt] ^ instr_imm;
      			  end
      			  OPCODE_SW: begin
      			    mem_access <= 1;
      			  end
          endcase
        end
        else if(state == MEM_ACCESS) begin
            state <= (waitrequest) ? MEM_ACCESS : FETCH;
            case(instr_opcode)
            //TODO: FIX THIS
            /*
              OPCODE_LB: begin
                if ((regs[rs]+instr_imm)[1:0]==0'b00) begin
                  regs[rt] <= {{24{readdata[7]}},readdata[7:0]};
                end
                else if ((regs[rs]+instr_imm)[1:0]==0'b01) begin
                  regs[rt] <= {{16{readdata[15]}},readdata[15:8],8'h00};
                end
                else if ((regs[rs]+instr_imm)[1:0]==0'b10) begin
                  regs[rt] <= {{8{readdata[23]}},readdata[23:16],16'h0000};
                end
                else if ((regs[rs]+instr_imm)[1:0]==0'b11) begin
                  regs[rt] <= {readdata[31:24],24'h000000};
                end
              end
              OPCODE_LBU: begin
                if ((regs[rs]+instr_imm)[1:0]==0'b00) begin
                  regs[rt] <= {24'h000000,readdata[7:0]};
                end
                else if ((regs[rs]+instr_imm)[1:0]==0'b01) begin
                  regs[rt] <= {16'h0000,readdata[15:8],8'h00};
                end
                else if ((regs[rs]+instr_imm)[1:0]==0'b10) begin
                  regs[rt] <= {8'h00,readdata[23:16],16'h0000};
                end
                else if ((regs[rs]+instr_imm)[1:0]==0'b10) begin
                  regs[rt] <= {readdata[31:24],24'h000000};
                end
              end

              OPCODE_LH: begin
                if((regs[rs]+instr_imm)[1:0]==0'b00) begin
                  regs[rt] <= {16[readdata[15]],readdata[15:0]};
                end
                else if((regs[rs]+instr_imm)[1:0]==0'b10) begin
                  regs[rt] <= {16[readdata[31]],readdata[31:16]};
                end
                else begin
                  //TO-DO: accessing invalid memory? assert nonetheless?
                end
              end
              OPCODE_LHU:begin
                if((regs[rs]+instr_imm)[1:0]==0'b00) begin
                  regs[rt] <= {16'h0000,readdata[15:0]};
                end
                else if((regs[rs]+instr_imm)[1:0]==0'b10) begin
                  regs[rt] <= {16'h0000,readdata[31:16]};
                end
              end
              */
              OPCODE_LW: regs[rt] <= readdata;
              OPCODE_LWL:regs[rt] <= {readdata[31:16],regs[rt][15:0]};
              OPCODE_LWR:regs[rt] <= {regs[rt][31:16], readdata[15:0]};
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
