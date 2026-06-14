module riscvpipelined(input         clk, reset,
                      output [31:0] PC,
                      input  [31:0] Instr,
                      output        MemWrite,
                      output [31:0] DataAdr, WriteData,
                      input  [31:0] ReadData);
  wire [6:0] opD; wire [2:0] funct3D; wire funct7b5D;
  wire ZeroE, LTE;
  wire [2:0] ImmSrcD;
  wire PCSrcE, ALUSrcE, JalrSrcE, RegWriteW;
  wire [3:0] ALUControlE;
  wire [1:0] ResultSrcW;

  controller c(.clk(clk), .reset(reset),
    .opD(opD), .funct3D(funct3D), .funct7b5D(funct7b5D), .ZeroE(ZeroE), .LTE(LTE),
    .ImmSrcD(ImmSrcD), .PCSrcE(PCSrcE), .ALUSrcE(ALUSrcE), .JalrSrcE(JalrSrcE),
    .ALUControlE(ALUControlE), .MemWriteM(MemWrite), .RegWriteW(RegWriteW),
    .ResultSrcW(ResultSrcW));

  datapath dp(.clk(clk), .reset(reset),
    .PCSrcE(PCSrcE), .ALUSrcE(ALUSrcE), .JalrSrcE(JalrSrcE), .ALUControlE(ALUControlE),
    .ImmSrcD(ImmSrcD), .RegWriteW(RegWriteW), .ResultSrcW(ResultSrcW),
    .InstrF(Instr), .ReadDataM(ReadData), .PCF(PC),
    .ALUResultM(DataAdr), .WriteDataM(WriteData),
    .opD(opD), .funct3D(funct3D), .funct7b5D(funct7b5D), .ZeroE(ZeroE), .LTE(LTE));
endmodule
