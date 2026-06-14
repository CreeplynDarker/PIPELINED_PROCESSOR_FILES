module riscvsingle(input  clk, reset,
                   output [31:0] PC,
                   input  [31:0] Instr,
                   output MemWrite,
                   output [31:0] DataAdr, 
                   output [31:0] WriteData,
                   input  [31:0] ReadData);
  
  wire [31:0] ALUResult; 
  wire ALUSrc, RegWrite, Jump, Zero; 
  wire [1:0] ResultSrc;

  // CHANGE:
  // ImmSrc was originally 2 bits:
  //   00 = I-type
  //   01 = S-type
  //   10 = B-type
  //   11 = J-type
  //
  // Now ImmSrc is 3 bits because lui needs a new U-type encoding:
  //   000 = I-type
  //   001 = S-type
  //   010 = B-type
  //   011 = J-type
  //   100 = U-type, used by lui
  wire [2:0] ImmSrc;
  wire [3:0] ALUControl; 
  wire PCSrc;
  wire LT; // CHANGE B
  wire JalrSrc; // CHANGE C 

  // DataAdr is connected to ALUResult.
  // No change needed for lui.
  // lui does not access data memory.
  assign DataAdr = ALUResult;

  controller c(
    .op(Instr[6:0]), 
    .funct3(Instr[14:12]), 
    .funct7b5(Instr[30]), 
    .Zero(Zero),
    .LT(LT),
    .ResultSrc(ResultSrc), 
    .MemWrite(MemWrite), 
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite), 
    .Jump(Jump),
    .JalrSrc(JalrSrc),
    // ImmSrc is now 3 bits.
    // controller receives it from maindec and sends it to datapath.
    .ImmSrc(ImmSrc), 
    .ALUControl(ALUControl)
  );
  
  datapath dp(
    .clk(clk), 
    .reset(reset), 
    .ResultSrc(ResultSrc), 
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite),
    .JalrSrc(JalrSrc),
    // datapath now receives a 3-bit ImmSrc.
    // This allows extend.v to generate I, S, B, J, and U immediates.
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl),
    .Zero(Zero),
    .LT(LT), 
    .PC(PC), 
    .Instr(Instr),
    .ALUResult(ALUResult), 
    .WriteData(WriteData), 
    .ReadData(ReadData)
  ); 

endmodule