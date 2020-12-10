module RAM_32x4096(
    input logic clk,
    input logic[31:0] address,
    input logic write,
    input logic read,
    output logic waitrequest,
    input logic[31:0] writedata,
    input logic[3:0] byteenable,
    output logic[31:0] readdata
);
    parameter RAM_INIT_FILE = "";

    reg [31:0] memory [65535:0];

    initial begin
        integer i;
        /* Initialise to zero by default */
        for (i=0; i<65535; i++) begin
            memory[i]=0;
        end
        /* Load contents from file if specified */
        if (RAM_INIT_FILE != "") begin
            $display("RAM : INIT : Loading RAM contents from %s", RAM_INIT_FILE);
            $readmemh(RAM_INIT_FILE, memory);
        end
    end

    //Maps input address from cpu to word address of RAM
    logic[31:0] address_relative;
    assign address_relative = address - 32'hBFC00000;


    //Uses byteenable to select words from input
    logic[31:0] r_data;
    assign r_data = (address == 0) ? 32'd0 : memory[address_relative];
    logic[7:0] r_data3, r_data2, r_data1, r_data0;
    assign r_data3 = r_data[31:24] & {8{byteenable[3]}};
    assign r_data2 = r_data[23:16] & {8{byteenable[2]}};
    assign r_data1 = r_data[15:8] & {8{byteenable[1]}};
    assign r_data0 = r_data[7:0] & {8{byteenable[0]}};

    logic[7:0] w_data3, w_data2, w_data1, w_data0;
    assign w_data3 = (byteenable[3]) ? writedata[31:24] : r_data[31:24];
    assign w_data2 = (byteenable[2]) ? writedata[23:16] : r_data[23:16];
    assign w_data1 = (byteenable[1]) ? writedata[15:8] : r_data[15:8];
    assign w_data0 = (byteenable[0]) ? writedata[7:0] : r_data[7:0];

    /* Synchronous write path */
    always_ff @(posedge clk) begin
        //$display("RAM : INFO : read=%h, addr = %h, mem=%h", read, address, memory[address]);
        if(address == 0) begin
          //do nothing, halt position
        end
        else if (write) begin
            memory[address_relative] <= {w_data3, w_data2, w_data1, w_data0};
        end
        else if (read) begin
            readdata <= {r_data3, r_data2, r_data1, r_data0};
        end
    end
endmodule
