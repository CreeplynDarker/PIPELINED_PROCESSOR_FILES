module controller(input  [6:0] op,
                  input  [2:0] funct3,
                  input        funct7b5,
                  input        Zero,
                  input        LT, // CHANGE B
                  output [1:0] ResultSrc, 
                  output       MemWrite,
                  output       PCSrc, ALUSrc,
                  output       RegWrite, Jump,
                  output [2:0] ImmSrc, 
                  output [3:0] ALUControl,
                  output       JalrSrc); // CHANGE C
  
  wire [1:0] ALUOp; 
  wire       Branch; 
  reg        BranchTaken; // CHANGE B

  maindec md(
    .op(op), .ResultSrc(ResultSrc), .MemWrite(MemWrite), .Branch(Branch),
    .ALUSrc(ALUSrc), .RegWrite(RegWrite), .Jump(Jump),
    .ImmSrc(ImmSrc), .ALUOp(ALUOp), .JalrSrc(JalrSrc) // CHANGE C
  ); 

  aludec ad(
    .opb5(op[5]), .funct3(funct3), .funct7b5(funct7b5),
    .ALUOp(ALUOp), .ALUControl(ALUControl)
  ); 
  
  // CHANGE B: la condicion del salto depende de funct3.
  //   beq (000): toma si Zero      (a == b)
  //   bne (001): toma si !Zero     (a != b)
  //   blt (100): toma si LT        (a <  b con signo)
  //   bge (101): toma si !LT       (a >= b con signo)
  always @* case (funct3)
      3'b000:  BranchTaken = Zero;
      3'b001:  BranchTaken = ~Zero;
      3'b100:  BranchTaken = LT;
      3'b101:  BranchTaken = ~LT;
      default: BranchTaken = 1'b0;
    endcase

  assign PCSrc = (Branch & BranchTaken) | Jump; 
endmodule