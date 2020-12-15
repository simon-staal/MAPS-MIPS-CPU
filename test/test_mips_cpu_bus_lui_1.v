module mips_cpu_bus_tb;
    timeunit 1ns / 10ps;

    parameter TIMEOUT_CYCLES = 10000;
    parameter TESTCASE_ID = "lui_1";
    parameter INSTRUCTION = "lui";
    parameter RAM_INIT_FILE = "../test/1-hex/test_mips_cpu_bus_lui_1.hex.txt";


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

    RAM_32x4096 #(RAM_INIT_FILE) ramInst(clk, address, write, read, waitrequest, writedata, byteenable, readdata);

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
      //  $display("Address being read is %h",address);

        @(posedge clk); //fetch
        reset <= 0;
      //  $display("Address being read is %h",address);

        @(posedge clk)
        assert(active==1)else $fatal(1, "CPU is not active" );

        while (active) begin
          @(posedge clk);
          $display("Value of v0: %h",register_v0);
        end

        assert(register_v0==32'hDEAD0000) else $fatal(106, "%s %s Fail Incorrect value %d stored in v0.", TESTCASE_ID, INSTRUCTION, register_v0);

        $display("%s %s Pass #Add 0", TESTCASE_ID, INSTRUCTION);
        $finish;
    end

endmodule
