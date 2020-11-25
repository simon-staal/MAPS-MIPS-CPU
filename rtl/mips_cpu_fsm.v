`include "mips_cpu_definitions.v"

module mips_cpu_fsm(
    input logic clk,
    input logic reset,
    input logic waitrequest,
    input opcode_t opcode,
    output state_t state
    );

    always_ff @ (posedge clk) begin
        if(reset) begin
            state <= FETCH;
        end
        else if(state == FETCH) begin
            state <= (waitrequest) ? FETCH : EXEC;
        end
        else if(state == EXEC) begin
            state <= () ? MEM_ACCESS : () : FETCH : WRITE_BACK; //Add condition if instruction requires mem access / if instruction requires writing back to a register
        end
        else if(state == MEM_ACCESS) begin
            state <= (waitrequest) ? MEM_ACCESS : () FETCH : WRITE_BACK; //Instructions that write to memory can go back to fetch instead of write_back
        end
        else if(state == WRITE_BACK) begin
            state <= FETCH;
        end
        else if(state == HALTED) begin
            //Do nothing
        end
        else begin
            $fatal(1, "CPU : ERROR : Processor in unexpected state %b", state);
        end
    end
