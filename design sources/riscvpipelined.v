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
  wire [1:0] ForwardAE, ForwardBE;
  wire [4:0] Rs1E, Rs2E, RdM, RdW;
  wire       RegWriteM;
  wire       StallF, StallD, FlushE, ResultSrcE0;
  wire [4:0] Rs1D, Rs2D, RdE;

  controller c(.clk(clk), .reset(reset),
    .opD(opD), .funct3D(funct3D), .funct7b5D(funct7b5D), .ZeroE(ZeroE), .LTE(LTE),
    .ImmSrcD(ImmSrcD), .PCSrcE(PCSrcE), .ALUSrcE(ALUSrcE), .JalrSrcE(JalrSrcE),
    .ALUControlE(ALUControlE), .MemWriteM(MemWrite),
    .RegWriteM(RegWriteM), .RegWriteW(RegWriteW), .ResultSrcW(ResultSrcW),
    .FlushE(FlushE), .ResultSrcE0(ResultSrcE0));

  datapath dp(.clk(clk), .reset(reset),
    .PCSrcE(PCSrcE), .ALUSrcE(ALUSrcE), .JalrSrcE(JalrSrcE), .ALUControlE(ALUControlE),
    .ImmSrcD(ImmSrcD), .RegWriteW(RegWriteW), .ResultSrcW(ResultSrcW),
    .InstrF(Instr), .ReadDataM(ReadData), .PCF(PC),
    .ALUResultM(DataAdr), .WriteDataM(WriteData),
    .opD(opD), .funct3D(funct3D), .funct7b5D(funct7b5D), .ZeroE(ZeroE), .LTE(LTE),
    .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
    .StallF(StallF), .StallD(StallD), .FlushE(FlushE),
    .Rs1E(Rs1E), .Rs2E(Rs2E), .RdM(RdM), .RdW(RdW), .RdE(RdE),
    .Rs1D(Rs1D), .Rs2D(Rs2D));

  hazard hu(.Rs1E(Rs1E), .Rs2E(Rs2E), .RdM(RdM), .RdW(RdW),
            .RegWriteM(RegWriteM), .RegWriteW(RegWriteW),
            .Rs1D(Rs1D), .Rs2D(Rs2D), .RdE(RdE), .ResultSrcE0(ResultSrcE0),
            .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
            .StallF(StallF), .StallD(StallD), .FlushE(FlushE));
endmodule
