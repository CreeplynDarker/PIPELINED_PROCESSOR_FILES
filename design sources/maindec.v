module maindec(input  [6:0] op,
               output [1:0] ResultSrc,
               output MemWrite,
               output Branch, ALUSrc,
               output RegWrite, Jump,
               output [2:0] ImmSrc,
               output [1:0] ALUOp,
               output JalrSrc); // CHANGE C: nueva señal de control
  
  // CHANGE C: controls ahora 13 bits (antes 12). Se añade JalrSrc al final.
  // Formato: RegWrite_ImmSrc[2:0]_ALUSrc_MemWrite_ResultSrc[1:0]_Branch_ALUOp[1:0]_Jump_JalrSrc
  reg [12:0] controls; 

  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump, JalrSrc} = controls; 

  always @* case(op)
      7'b0000011: controls = 13'b1_000_1_0_01_0_00_0_0; // lw
      7'b0100011: controls = 13'b0_001_1_1_00_0_00_0_0; // sw
      7'b0110011: controls = 13'b1_xxx_0_0_00_0_10_0_0; // R-type
      7'b1100011: controls = 13'b0_010_0_0_00_1_01_0_0; // branches (beq/bne/blt/bge)
      7'b0010011: controls = 13'b1_000_1_0_00_0_10_0_0; // I-type ALU
      7'b1101111: controls = 13'b1_011_0_0_10_0_00_1_0; // jal
      7'b0110111: controls = 13'b1_100_x_0_11_0_00_0_0; // lui
      7'b1100111: controls = 13'b1_000_x_0_10_0_00_1_1; // CHANGE C: jalr
      // jalr: ImmSrc=000 (I-type), ResultSrc=10 (rd=PC+4), Jump=1, JalrSrc=1
      default:    controls = 13'bx_xxx_x_x_xx_x_xx_x_x;
    endcase
endmodule