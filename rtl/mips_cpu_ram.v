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

    reg [31:0] memory [4095:0];

    initial begin
        integer i;
        /* Initialise to zero by default */
        for (i=0; i<4096; i++) begin
            memory[i]=0;
        end
        /* Load contents from file if specified */
        if (RAM_INIT_FILE != "") begin
            $display("RAM : INIT : Loading RAM contents from %s", RAM_INIT_FILE);
            $readmemh(RAM_INIT_FILE, memory);
        end
    end

    //Maps input address from cpu to word address of RAM
    logic[31:0] address_relative, address_mapped;
    assign address_relative = (address == 0) ? 0 : (address - 32'hBFC00000)/4;
    logic[3:0] b_enable;
    assign b_enable = byteenable >> address % 4;
    /*
    load byte => give byte address, byteenable = 1000
    dividing address by 4 => word address
    shift byteenable by remainder to pick correct byte
    */

    //Uses byteenable to select words from input
    logic[31:0] r_data;
    assign r_data = (address == 0) ? 32'd0 : memory[address_relative];
    logic[7:0] r_data3, r_data2, r_data1, r_data0;
    assign r_data3 = r_data[31:24] & {8{b_enable[3]}};
    assign r_data2 = r_data[23:16] & {8{b_enable[2]}};
    assign r_data1 = r_data[15:8] & {8{b_enable[1]}};
    assign r_data0 = r_data[7:0] & {8{b_enable[0]}};

    logic[7:0] w_data3, w_data2, w_data1, w_data0;
    assign w_data3 = (b_enable[3]) ? writedata[31:24] : r_data[31:24];
    assign w_data2 = (b_enable[2]) ? writedata[23:16] : r_data[23:16];
    assign w_data1 = (b_enable[1]) ? writedata[15:8] : r_data[15:8];
    assign w_data0 = (b_enable[0]) ? writedata[7:0] : r_data[7:0]

    /* Synchronous write path */
    always @(posedge clk) begin
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
