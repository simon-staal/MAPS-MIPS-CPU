module mips_cpu_bus_LUI_1;
  timeunit 1ns/10ps;

  //defining parameters
  parameter TIMEOUT_CYCLES = 10000;
  parameter TESTCASE_ID = " LUI_1";
  parameter INSTRUCTION = "lui";

  //create std instances
  logic clk,reset,active;
  logic[31:0] register_v0;

  //avalon mem instances
  logic[31:0] address, writedata, readdata;
  logic[3:0] byteenable;
  logic write, read, waitrequest;

  //instance of CPU
  mips_cpu_bus cpuInst(clk, reset, active, register_v0, address, write, read, waitrequest, writedata, byteenable, readdata);

  //clock loop
  initial begin
    clk = 0;
    repeat(TIMEOUT_CYCLES)begin
      #10;
      clk=!clk;
      #10
      clk=!clk
    end

    //if clock timesout
    $fatal(100, "%s %s Fail - Simulation did not finish within %d cycles", TESTCASE_ID, INSTRUCTION, TIMEOUT_CYCLES);
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

      @(posedge clk);
      readdata <= 32'h3C021234;
      waitrequest <= 0;

      @(negedge clk);
      assert(register_v0==32'h12340000) else $fatal(106, "%s %s Fail Incorrect value %d stored in v0." TESTCASE_ID, INSTRUCTION, register_v0);

      @(posedge clk);
      readdata <= 32'h3C0206C2;
      waitrequest <= 0;

      @(negedge clk);
      assert(register_v0==32'h06C20000) else $fatal(106, "%s %s Fail Incorrect value %d stored in v0." TESTCASE_ID, INSTRUCTION, register_v0);
    
      @(posedge clk); //fetch

      @(negedge clk);
        assert(address==32'hBFC00004) else $fatal(102, "%s %s Fail CPU accessing incorrect address %h", TESTCASE_ID, INSTRUCTION, address);

      @(posedge clk); //exec
        readdata <= 32'h00000008 // jr zero

      @(posedge clk); //fetch

      @(negedge clk);
      assert(address==32'hBFC00008) else $fatal(102, "%s %s Fail CPU accessing incorrect address %h", TESTCASE_ID, INSTRUCTION, address);

      @(posedge clk); //exec
      readdata <= 32'h24430000; //addiu v1 v0 0x0

      @(negedge clk);
      assert(register_v0==32'd192) else $fatal(106, "%s %s Fail Incorrect value %d stored in v0." TESTCASE_ID, INSTRUCTION, register_v0);

      @(posedge clk); //pc == 0 => cpu should halt

      @(negedge clk);
      assert(active==0) else $fatal(101, "%s %s Fail CPU incorrectly set active." TESTCASE_ID, INSTRUCTION);

      $display("%s %s Passed test!", TESTCASE_ID, INSTRUCTION);
      $finish;
  end
endmodule //
