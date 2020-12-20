`include "mips_cpu_bus_definitions.vh"

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

    /* Defines an array of 32 registers used by MIPS with the following purposes:
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
    reg signed [31:0] regs [31:0];
    assign register_v0 = regs[2];

    //Creates basic registers (pc and ir)
    logic[31:0] pc, pc_increment;
    assign pc_increment = pc + 4;
    logic[31:0] ir;

    //Indicates whether the CPU is experiencing a stall cycle due to memory
    logic stall;

    //Create non GPR HI and LO registers
    logic[31:0] HI;
    logic[31:0] LO;
    //Intermediary logic for mult operations
    logic[63:0] mult_temp, multu_temp;
    assign mult_temp = ((state==EXEC)&&((instr_opcode==OPCODE_R)&&(instr_function==FUNCTION_MULT))) ? (regs[rs]*regs[rt]) : 0;
    assign multu_temp = ((state==EXEC)&&((instr_opcode==OPCODE_R)&&(instr_function==FUNCTION_MULTU))) ? ($unsigned(regs[rs])*$unsigned(regs[rt])) : 0;

    //Intermediary signals to process instructions
    logic[31:0] instr;
    opcode_t instr_opcode;
    function_t instr_function;
    state_t state;
    logic[4:0] rs, rt, rd, shift;
    logic[15:0] instr_imm;
    logic[25:0] instr_index;

    assign instr = (state==EXEC && stall==0) ? readdata : ir;
    assign instr_opcode = instr[31:26];
    assign rs = instr[25:21];
    assign rt = instr[20:16];
    assign rd = instr[15:11];
    assign shift = instr[10:6];
    assign instr_function = instr[5:0];
    assign instr_imm = instr[15:0];
    assign instr_index = instr[25:0];

    //Stores values for branch / jmp instructions
    logic[31:0] pc_jmp;
    logic delay; //Indicates delay slot instruction

    //Used to indicate memory access in EXEC to control waitrequest
    logic mem_access;
    assign mem_access = ((instr_opcode==OPCODE_SW)||(instr_opcode==OPCODE_SB)||(instr_opcode==OPCODE_SH)||(instr_opcode==OPCODE_LB)||(instr_opcode==OPCODE_LBU)||(instr_opcode==OPCODE_LHU)||(instr_opcode==OPCODE_LH)||(instr_opcode==OPCODE_LW)||(instr_opcode==OPCODE_LWL)||(instr_opcode==OPCODE_LWR));

    //Intermediary logic for aligning addresses
    logic [31:0] address_calc;
    assign address_calc = $unsigned(regs[rs]) + {{16{instr_imm[15]}}, (instr_imm)};
    logic [1:0] alignment;
    assign alignment = address_calc[1:0];

    //Intermediary logic for SB and SH
    logic [31:0] regs_byte, regs_hw;
    assign regs_byte = (state==EXEC)&&(instr_opcode==OPCODE_SB)? {4{regs[rt][7:0]}} : 0;
    assign regs_hw = (state==EXEC)&&(instr_opcode==OPCODE_SH)?  {2{regs[rt][15:0]}} : 0;

    integer i;
    initial begin
        state = HALTED;
        active = 0;
        delay = 0;
        stall = 0;
        for(i = 0; i < 32; i++) begin
          regs[i] = 0;
        end
    end

    //Combinatorial loop to manage the outputs of the CPU
    always_comb begin
        if(state == FETCH) begin
            byteenable = 4'b1111;
            read = 1;
            write = 0;
            address = pc;
        end
        if(state == EXEC || state == MEM_ACCESS) begin
      			if(instr_opcode==OPCODE_SW) begin
              if(alignment==2'b00) begin
        				byteenable = 4'b1111;
              end
              else begin //Unaligned memory
                byteenable = 4'b0000;
              end
              write = 1;
      				read = 0;
              address = address_calc & 32'hFFFFFFFC;
              writedata = regs[rt];
      			end
            else if(instr_opcode==OPCODE_SB) begin
              case(alignment)
                2'b00: begin
                  writedata = 32'h000000FF&regs_byte;
                  byteenable = 4'b0001;
                end
                2'b01: begin
                  writedata = 32'h0000FF00&regs_byte;
                  byteenable = 4'b0010;
                end
                2'b10: begin
                  writedata = 32'h00FF0000&regs_byte;
                  byteenable = 4'b0100;
                end
                2'b11: begin
                  writedata = 32'hFF000000&regs_byte;
                  byteenable = 4'b1000;
                end
              endcase
              write = 1;
              read = 0;
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_SH) begin
              if(alignment==2'b00) begin
                byteenable = 4'b0011;
                writedata = 32'h0000FFFF&regs_hw;
              end
              else if(alignment==2'b10) begin
                byteenable = 4'b1100;
                writedata = 32'hFFFF0000&regs_hw;
              end
              else begin //Writing to unaligned memory, do nothing
                byteenable = 4'b0000;
              end
              write = 1;
              read = 0;
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LB) begin
              read = 1;
              write = 0;
              case(alignment)
                2'b00: byteenable = 4'b0001;
                2'b01: byteenable = 4'b0010;
                2'b10: byteenable = 4'b0100;
                2'b11: byteenable = 4'b1000;
              endcase
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LBU) begin
              read = 1;
              write = 0;
              case(alignment)
                2'b00: byteenable = 4'b0001;
                2'b01: byteenable = 4'b0010;
                2'b10: byteenable = 4'b0100;
                2'b11: byteenable = 4'b1000;
              endcase
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LH) begin
              read = 1;
              write = 0;
              //alignment==00 or 01 --> LSHalfword, 10 or 11 --> MSHalfword
              if(alignment==2'b00) begin
                byteenable = 4'b0011;
              end
              else if(alignment==2'b10) begin
                byteenable = 4'b1100;
              end
              //Accessing unaligned memory, do nothing
              else begin
                byteenable = 4'b0000;
              end
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LHU) begin
              read = 1;
              write = 0;
              //alignment==00 or 01 --> LSHalfword, 10 or 11 MSHalfword
              if(alignment==2'b00) begin
                byteenable = 4'b0011;
              end
              else if(alignment==2'b10) begin
                byteenable = 4'b1100;
              end
              //Accessing unaligned memory, do nothing
              else begin
                byteenable = 4'b0000;
              end
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LW) begin
              read = 1;
              write = 0;
              if(alignment==2'b00) begin
                byteenable = 4'b1111;
              end
              else begin
                byteenable = 4'b0000;
              end
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LWL) begin
              read = 1;
              write = 0;
              case(alignment)
                2'b00: byteenable = 4'b0001;
                2'b01: byteenable = 4'b0011;
                2'b10: byteenable = 4'b1111;
                2'b11: byteenable = 4'b1111;
              endcase
              address = address_calc & 32'hFFFFFFFC;
            end
            else if(instr_opcode==OPCODE_LWR) begin
              read = 1;
              write = 0;
              case(alignment)
                2'b00: byteenable = 4'b1111;
                2'b01: byteenable = 4'b1111;
                2'b10: byteenable = 4'b1100;
                2'b11: byteenable = 4'b1000;
              endcase
              address = address_calc & 32'hFFFFFFFC;
            end
            else begin //Default behaviour
              read = 0;
              write = 0;
              byteenable = 4'b000;
              address = 32'hXXXXXXXX;
            end
        end
    end

    //Sequential loop to manage computer state and registers
    always @ (posedge clk) begin
        if(reset) begin
            state <= FETCH;
            active <= 1;
            pc <= 32'hBFC00000;
            for(i = 0; i < 32; i++) begin
              regs[i] <= 0;
            end
        end
        else if(address == 32'h00000000) begin
            state <= HALTED;
            active <= 0;
        end
        else if(state == FETCH) begin
            state <= (waitrequest) ? FETCH : EXEC;
        end
        else if(state == EXEC) begin
            ir <= (stall) ? ir : readdata;
            assert(regs[0]==32'h00000000) else $fatal(2, "$zero is no longer 0");
            state <= (waitrequest && mem_access) ? EXEC : ((instr_opcode==OPCODE_LB)||(instr_opcode==OPCODE_LBU)||(instr_opcode==OPCODE_LHU)||(instr_opcode==OPCODE_LH)||(instr_opcode==OPCODE_LW)||(instr_opcode==OPCODE_LWL)||(instr_opcode==OPCODE_LWR)) ? MEM_ACCESS : FETCH;
            pc <= (waitrequest && mem_access) ? pc : (delay) ? pc_jmp : pc_increment;
            delay <= (waitrequest && mem_access) ? delay : (delay) ? 0 : delay; //Resets the value of delay
            stall <= (waitrequest && mem_access);
            case(instr_opcode)
              OPCODE_R: begin
                case(instr_function)
                  FUNCTION_ADDU: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : $unsigned(regs[rs]) + $unsigned(regs[rt]);
                  end
                  FUNCTION_AND: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : regs[rs] & regs[rt];
                  end
                  FUNCTION_DIV: begin
            		    assert({rd,shift} == 10'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    LO <= (regs[rs]/regs[rt]);
            		    HI <= (regs[rs]%regs[rt]);
            		  end
            		  FUNCTION_DIVU: begin
                    assert({rd,shift} == 10'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    LO <= ($unsigned(regs[rs])/$unsigned(regs[rt]));
            		    HI <= ($unsigned(regs[rs])%$unsigned(regs[rt]));
            		  end
                  FUNCTION_JALR: begin
                    assert({rt,shift} == 10'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
            		    assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
                    assert(rs != rd) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h, rs cannot equal rd for JALR", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : pc + 8;
            		    pc_jmp <= regs[rs];
            		    delay <= 1;
            		  end
            		  FUNCTION_JR: begin
                    assert({rt,rd,shift} == 15'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
            		    assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
            		    pc_jmp <= regs[rs];
            		    delay <= 1;
            		  end
                  FUNCTION_MTHI:begin
                    assert(({rd,rt,shift}==15'h0000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    HI <= regs[rs];
                  end
                  FUNCTION_MTLO:begin
                    assert(({rd,rt,shift}==15'h0000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    LO <= regs[rs];
                  end
                  FUNCTION_MULT:begin
                    assert(({rd,shift}==10'h000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    LO <= mult_temp[31:0];
                    HI <= mult_temp[63:32];
                  end
                  FUNCTION_MULTU:begin
                    assert(({rd,shift}==10'h000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    LO <= multu_temp[31:0];
                    HI <= multu_temp[63:32];
                  end
                  FUNCTION_MFHI:begin
                    assert(({rs,rt,shift}==15'h0000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : HI;
                  end
                  FUNCTION_MFLO:begin
                    assert(({rs,rt,shift}==15'h0000)) else $fatal(2, "CPU : ERROR: Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : LO;
                  end
                  FUNCTION_OR: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : regs[rs] | regs[rt];
                  end
                  FUNCTION_SLT: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : (regs[rs] < regs[rt]);
                  end
                  FUNCTION_SLL: begin
                    assert(rs == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : regs[rt] << shift;
                  end
                  FUNCTION_SLLV: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : regs[rt] << (regs[rs] & 32'h0000001f);
                  end
                  FUNCTION_SLTU: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : ($unsigned(regs[rs]) < $unsigned(regs[rt]));
                  end
                  FUNCTION_SRA: begin
                    assert(rs == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
        						regs[rd] <= (rd == 0) ? 0 : regs[rt] >>> shift;
        				  end
                  FUNCTION_SRAV: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : regs[rt] >>> (regs[rs] & 32'h0000001f);
        				  end
        					FUNCTION_SRL: begin
                    assert(rs == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
        						regs[rd] <= (rd == 0) ? 0 : regs[rt] >> shift;
        				  end
        					FUNCTION_SRLV: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
        					  regs[rd] <= (rd == 0) ? 0 : regs[rt] >> (regs[rs] & 32'h0000001f);
        				  end
        					FUNCTION_SUBU: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
        					  regs[rd] <= (rd == 0) ? 0 : $unsigned(regs[rs]) - $unsigned(regs[rt]);
        				  end
                  FUNCTION_XOR: begin
                    assert(shift == 5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc);
                    regs[rd] <= (rd == 0) ? 0 : (regs[rs] ^ regs[rt]);
        				  end
                endcase
              end
              OPCODE_ADDIU: begin
                regs[rt] <= (rt == 0) ? 0 : $unsigned(regs[rs]) + ({{16{instr_imm[15]}}, instr_imm});
              end
              OPCODE_ANDI: begin
                regs[rt] <= (rt == 0) ? 0 : regs[rs] & instr_imm;
              end
              OPCODE_BEQ: begin
                assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
                if(regs[rs] == regs[rt]) begin
                  pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                  delay <= 1;
                end
              end
              //SD instructions
              OPCODE_LUI: begin
                assert(rs==5'b00000) else $fatal(2, "CPU : ERROR : Invalid instruction %b at pc %h", instr, pc );
                regs[rt] <= (rt == 0) ? 0 : {instr_imm, 16'h0000};
              end
              OPCODE_REGIMM: begin
                assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
                case(rt)
                  BGEZ: begin
                    if(regs[rs] >= 0) begin
                      pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                      delay <= 1;
                    end
                  end
                  BGEZAL: begin
                    assert(rs!=31) else $fatal(2, "CPU : ERROR : Cannot use $ra as rs, instr %b at pc %h", instr, pc );
                    regs[31] <= (pc_increment + 32'd4);
                    if(regs[rs] >= 0) begin
                      pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                      delay <= 1;
                    end
                  end
                  BLTZ: begin
                    if(regs[rs] < 0) begin
                      pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                      delay <= 1;
                    end
                  end
                  BLTZAL: begin
                    assert(rs!=31) else $fatal(2, "CPU : ERROR : Cannot use $ra as rs, instr %b at pc %h", instr, pc );
                    regs[31] <= (pc_increment + 4);
                    if(regs[rs] < 0) begin
                      pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                      delay <= 1;
                    end
                  end
                endcase
              end
              OPCODE_BGTZ: begin
                if(regs[rs] > 0) begin
                  pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                  delay <= 1;
                end
              end
              OPCODE_BLEZ: begin
                if(regs[rs] <= 0) begin
                  pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                  delay <= 1;
                end
              end
              OPCODE_BNE: begin
                if(regs[rs] != regs[rt]) begin
                  pc_jmp <= pc_increment + ({{16{instr_imm[15]}}, (instr_imm << 2)});
                  delay <= 1;
                end
              end
              OPCODE_J: begin
            		assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
                pc_jmp <= {{pc_increment[31:28]}, instr_index, {2'b00}};
            		delay <= 1;
      	      end
      	      OPCODE_JAL: begin
            		assert(delay == 0) else $fatal(2, "CPU : ERROR : Branch / Jump instruction %b in delay slot at pc %h", instr, pc);
            		regs[31] <= pc + 8;
            		pc_jmp <= {{pc_increment[31:28]}, instr_index, {2'b00}};
            		delay <= 1;
            	end
              OPCODE_ORI: begin
                regs[rt] <= (rt == 0) ? 0 : regs[rs] | instr_imm;
              end
              OPCODE_SLTI: begin
                regs[rt] <= (rt == 0) ? 0 : (regs[rs] < $signed(instr_imm));
              end
              OPCODE_SLTIU: begin
                regs[rt] <= (rt == 0) ? 0 : (regs[rs] < $unsigned(instr_imm));
              end
      			  OPCODE_XORI: begin
      					regs[rt] <= (rt == 0) ? 0 : regs[rs] ^ instr_imm;
      			  end
          endcase
        end
        else if(state == MEM_ACCESS) begin
            state <= FETCH;
            case(instr_opcode)
              OPCODE_LB: begin
                if (alignment==2'b00) begin
                  regs[rt] <= (rt == 0) ? 0 : {{24{readdata[7]}},readdata[7:0]};
                end
                else if (alignment==2'b01) begin
                  regs[rt] <= (rt == 0) ? 0 : {{24{readdata[15]}},readdata[15:8]};
                end
                else if (alignment==2'b10) begin
                  regs[rt] <= (rt == 0) ? 0 : {{24{readdata[23]}},readdata[23:16]};
                end
                else if (alignment==2'b11) begin
                  regs[rt] <= (rt == 0) ? 0 : {{24{readdata[31]}},readdata[31:24]};
                end
              end
              OPCODE_LBU: begin
                if (alignment==2'b00) begin
                  regs[rt] <= (rt == 0) ? 0 : {24'h000000,readdata[7:0]};
                end
                else if (alignment==2'b01) begin
                  regs[rt] <= (rt == 0) ? 0 : {24'h000000,readdata[15:8]};
                end
                else if (alignment==2'b10) begin
                  regs[rt] <= (rt == 0) ? 0 : {24'h000000,readdata[23:16]};
                end
                  else if (alignment==2'b11) begin //error was here, compiles now, still ensure of the implementation of byte enable
                  regs[rt] <= (rt == 0) ? 0 : {24'h000000,readdata[31:24]};
                end
              end
              OPCODE_LH: begin
                if(alignment[1]==1'b0) begin
                  regs[rt] <= (rt == 0) ? 0 : {{16{readdata[15]}},readdata[15:0]};
                end
                else if(alignment[1]==1'b1) begin
                  regs[rt] <= (rt == 0) ? 0 : {{16{readdata[31]}},readdata[31:16]};
                end
              end
              OPCODE_LHU:begin
                if(alignment[1]==2'b0) begin
                  regs[rt] <= (rt == 0) ? 0 : {16'h0000,readdata[15:0]};
                end
                else if(alignment[1]==2'b1) begin
                  regs[rt] <= (rt == 0) ? 0 : {16'h0000,readdata[31:16]};
                end
              end
              OPCODE_LW: regs[rt] <= (rt == 0) ? 0 : readdata;
              OPCODE_LWL: begin
                case(alignment)
                  2'b00: regs[rt] <= (rt == 0) ? 0 : {readdata[7:0],regs[rt][23:0]};
                  2'b01: regs[rt] <= (rt == 0) ? 0 : {readdata[15:0],regs[rt][15:0]};
                  2'b10: regs[rt] <= (rt == 0) ? 0 : {readdata[23:0], regs[rt][7:0]};
                  2'b11: regs[rt] <= (rt == 0) ? 0 : readdata;
                endcase
              end
              OPCODE_LWR:begin
                case(alignment)
                  2'b00: regs[rt] <= (rt == 0) ? 0 : readdata;
                  2'b01: regs[rt] <= (rt == 0) ? 0 : {regs[rt][31:24],readdata[31:8]};
                  2'b10: regs[rt] <= (rt == 0) ? 0 : {regs[rt][31:16], readdata[31:16]};
                  2'b11: regs[rt] <= (rt == 0) ? 0 : {regs[rt][31:8], readdata[31:24]};
                endcase
              end
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
