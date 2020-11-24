typedef enum logic[5:0] {
	FUNCTION_SLTU = 6'b101011, // $rd := $rs < $rt. Unsigned less-than comparison.
	FUNCTION_SRA = 6'b000011, // $rd := rt >> c. Arithmetic shift right by c bits.
	FUNCTION_SRAV = 6'b000111, // $rd := $rt >> $rs. Variable Arithmetic shift right, i.e. by a register variable.
	FUNCTION_SRL = 6'b000010, // $rd := $rt >> c. Logical shift right by constant c bits.
	FUNCTION_SRLV = 6'b000110, // $rd := $rt >> $rs. Variable logical shift right, i.e. by a register variable
	FUNCTION_SUBU = 6'b100011, // $rd := $rs - $rt. Subtract 2 registers.
	FUNCTION_XOR = 6'b100110 // $rd := $rs XOR $rt. Logical XOR between $rs and $rt.
	} function_t;
	
typedef enum logic[5:0] {
	OPCODE_SW = 6'b101011, // memory[base+offset] := $rt. Stores register rt in memory with an offset.
	OPCODE_XORI = 6'b001110 // $rt := $rs XORI c. Logical XOR between $rs and constant c.
	} opcode_t;