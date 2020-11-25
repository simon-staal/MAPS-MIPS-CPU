`include "mips_cpu_definitons.v"

module mips_cpu_fsm(
    input logic clk,
    input logic reset,
    input logic waitrequest,
    input logic[5:0] opcode,
    output logic[3:0] state
    );

    state_t s;
    assign state = s

    always_ff @ (posedge clk) begin
        if(reset) begin
            s <= FETCH;
        end
        else if(s == FETCH) begin
            s <= (waitrequest) ? FETCH : EXEC;
        end
        else if(s == EXEC) begin
            s <= () ? MEM_ACCESS : () : FETCH : WRITE_BACK; //Add condition if instruction requires mem access / if instruction requires writing back to a register
        end
        else if(s == MEM_ACCESS) begin
            s <= (waitrequest) ? MEM_ACCESS : () FETCH : WRITE_BACK; //Instructions that write to memory can go back to fetch instead of write_back
        end
        else if(s == WRITE_BACK) begin
            s <= FETCH;
        end
        else if(s == HALTED) begin
            //Do nothing
        end
        else begin
            $fatal(1, "CPU : ERROR : Processor in unexpected state %b", s);
        end
    end
