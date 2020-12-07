//Implementation of: LUI; tbd: LHU, LW, LWL, LWR, MTHI, MTLO, MULTU, MULT

//sign extension for LUI, multiplex with data into rt
logic imm_load[31:0] = {instr_imm, 16'h0000};
logic alu_out[31:0];

assign reg_writedata = (instr==OPCODE_LUI)? imm_load: alu_out;

always_ff @(posedge clk) begin
  if(state==EXEC)begin
    case(instr)
      OPCODE_LUI: begin
      reg_writedata = imm_load;

  end
end
