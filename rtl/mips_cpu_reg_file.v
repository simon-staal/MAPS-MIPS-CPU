`include "mips_cpu_definitions.v"

module mips_cpu_reg_file(
    input logic clk,
    input logic reset,
    input logic[4:0] a1,
    input logic[4:0] a2,
    input logic[4:0] a3,
    input logic [31:0] writedata,
    input logic write_en,
    input opcode_t opcode,
    output logic[31:0] readdata1,
    output logic[31:0] readdata2,
    );

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
    logic [32][31:0] regs;

    always_comb begin
      readdata1 = regs[a1];
      readdata2 = regs[a2];
    end

    always_ff @(posedge clk) begin
      if(write_en) begin
        if(opcode == OPCODE_R) begin
          regs[a3] <= writedata;
        end
        else if(opcode == OPCODE_REGIMM) begin
          regs[31] <= writedata;
        end
        else begin
          regs[a2] <= writedata;
        end
      end
    end

endmodule
