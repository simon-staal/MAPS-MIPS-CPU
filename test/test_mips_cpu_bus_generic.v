//This is a generic test_case format that uses the RAM memory block, and only checks the final output of register v0
module mips_cpu_bus_tb;
    timeunit 1ns / 10ps;

    parameter TIMEOUT_CYCLES = 10000;
    parameter TESTCASE_ID = "XXX_X";
    parameter INSTRUCTION = "XXX";
    parameter RAM_INIT_FILE = "../test/1-hex/test_mips_cpu_bus_addiu_1.hex.txt";
    //Use https://www.eg.bucknell.edu/~csci320/mips_web/ to convert assembly to hex
    /*
    Assembly:
    lui v1 0xbfc0
    lw t1 0x28(v1)
    jr zero
    addiu v0 t1 0x145
    */

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

    RAM_32x65536 #(RAM_INIT_FILE) ramInst(clk, address, write, read, waitrequest, writedata, byteenable, readdata);

    initial begin
        $dumpfile("mips_tb.vcd");
        $dumpvars(0, mips_cpu_bus_tb);
        clk=0;

        repeat (TIMEOUT_CYCLES) begin
            #10;
            clk = !clk;
            #10;
            clk = !clk;
        end

        $fatal(2, "%s %s Fail Simulation did not finish within %d cycles.", TESTCASE_ID, INSTRUCTION, TIMEOUT_CYCLES);
    end


    initial begin
        reset = 0;

        @(negedge clk);
        reset = 1;

        @(negedge clk); //fetch
        reset = 0;

        @(negedge clk);
        assert(active==1) else $fatal(1, "%s %s Fail CPU did not go active after reset.", TESTCASE_ID, INSTRUCTION);

        while (active) begin
          @(negedge clk);
        end

        $display("FINAL OUT: %h", register_v0);
        $finish;
    end

endmodule
