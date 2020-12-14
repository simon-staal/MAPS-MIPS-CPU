/*
Assembly code:
lui v1 0xbfc0
lw t1 0x14(v1)
lw t2 0x18(v1)
jr zero (jumps to address==0)
subu  v0 t1 t2 // 0x012A1023
*/

//This is a generic test_case format that uses the RAM memory block, and only checks the final output of register v0
module mips_cpu_bus_tb;
    timeunit 1ns / 10ps;

    parameter TIMEOUT_CYCLES = 10000;
    parameter TESTCASE_ID = "SUBU_1";
    parameter INSTRUCTION = "subu"
    parameter RAM_INIT_FILE = "SUBU.hex.txt"


    logic clk;
    logic reset;
    logic active;
    logic[31:0] register_v0;

    logic[31:0] address;
    logic write;
    logic read;
    logic waitrequest;
    logic[31:0] writedata;
    logic[3:0] byteenable;
    logic[31:0] readdata;

    mips_cpu_bus cpuInst(clk, reset, active, register_v0, address, write, read, waitrequest, writedata, byteenable, readdata);

    mips_cpu_ram #(RAM_INIT_FILE) ramInst(clk, address, write, read, waitrequest, writedata, byteenable, readdata);

    initial begin
        clk=0;

        repeat (TIMEOUT_CYCLES) begin
            #10;
            clk = !clk;
            #10;
            clk = !clk;
        end

        $fatal(100, "%s %s Fail Simulation did not finish within %d cycles.", TESTCASE_ID, INSTRUCTION, TIMEOUT_CYCLES);
    end


    initial begin
        reset <= 0;

        @(posedge clk);
        reset <= 1;

        @(posedge clk); //fetch
        reset <= 0;

        @(negedge clk);
        assert(active==1) else $fatal(101, "%s %s Fail CPU incorrectly set active." TESTCASE_ID, INSTRUCTION);
        assert(address==32'hBFC00000) else $fatal(102, "%s %s Fail CPU accessing incorrect address %h", TESTCASE_ID, INSTRUCTION, address);
        assert(read==1) else $fatal(103, "%s %s Fail CPU has read set incorrectly." TESTCASE_ID, INSTRUCTION);
        assert(write==0) else $fatal(104, "%s %s Fail CPU has write set incorrectly." TESTCASE_ID, INSTRUCTION);
        assert(byteenable==4'b1111) else $fatal(105, "%s %s Fail CPU incorrectly set byteenable %b." TESTCASE_ID, INSTRUCTION, byteenable);

        while (active) begin
          @(posedge clk);
        end
        assert(register_v0==/*insert value*/) else $fatal(106, "%s %s Fail Incorrect value %d stored in v0." TESTCASE_ID, INSTRUCTION, register_v0);

        $display("%s %s Pass #", TESTCASE_ID, INSTRUCTION);
        $finish;
    end

endmodule
