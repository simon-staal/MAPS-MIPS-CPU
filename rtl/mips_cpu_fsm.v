module mips_cpu_fsm(
    input logic clk,
    input logic reset,
    input logic waitrequest,
    input logic[5:0] opcode,
    output logic[3:0] state
    );

    typedef enum logic[3:0] {
        FETCH = 3'b000,
        EXEC = 3'b001,
        MEM_ACCESS = 3'b010,
        WRITE_BACK = 3'b011,
        HALTED = 3'b111
    } state_t;

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
            s <= () ? MEM_ACCESS : WRITE_BACK; //Add condition if instruction requires mem access
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
