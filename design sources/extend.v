module extend(input  [31:7] instr,

              // CHANGE:
              // immsrc was originally 2 bits.
              // Now it is 3 bits because we need one more encoding
              // for U-type immediates used by lui.
              input  [2:0]  immsrc,

              output [31:0] immext);
  
  reg [31:0] immext_reg; 
  assign immext = immext_reg;

  always @* case(immsrc) 

      // I-type immediate
      // Used by lw and I-type ALU instructions such as addi.
      //
      // Old encoding: 2'b00
      // New encoding: 3'b000
      3'b000: immext_reg = {{20{instr[31]}}, instr[31:20]}; 

      // S-type immediate
      // Used by stores such as sw.
      //
      // Old encoding: 2'b01
      // New encoding: 3'b001
      3'b001: immext_reg = {{20{instr[31]}}, instr[31:25], instr[11:7]}; 

      // B-type immediate
      // Used by branches such as beq.
      //
      // Old encoding: 2'b10
      // New encoding: 3'b010
      3'b010: immext_reg = {{20{instr[31]}}, instr[7],
                             instr[30:25], instr[11:8], 1'b0}; 

      // J-type immediate
      // Used by jal.
      //
      // Old encoding: 2'b11
      // New encoding: 3'b011
      3'b011: immext_reg = {{12{instr[31]}}, instr[19:12],
                             instr[20], instr[30:21], 1'b0}; 

      // CHANGE:
      // U-type immediate
      // Used by lui.
      //
      // lui rd, imm20:
      //   rd = {imm20, 12'b0}
      //
      // In the instruction:
      //   imm20 = Instr[31:12]
      //
      // Therefore:
      //   ImmExt = {Instr[31:12], 12'b0}
      3'b100: immext_reg = {instr[31:12], 12'b0}; 

      // Undefined / non-implemented immediate type
      default: immext_reg = 32'bx; 

    endcase             

endmodule