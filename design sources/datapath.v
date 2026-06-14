module datapath(input  clk, reset,
                input  [1:0]  ResultSrc, 
                input  PCSrc, ALUSrc,
                input  RegWrite,
                // CHANGE:
                // ImmSrc was 2 bits before.
                // Now it is 3 bits because we need a new encoding for U-type immediates.
                // New ImmSrc encoding:
                // 000 = I-type
                // 001 = S-type
                // 010 = B-type
                // 011 = J-type
                // 100 = U-type, used by lui
                input  [2:0]  ImmSrc, 
                input  [3:0]  ALUControl,
                input  JalrSrc, // CHANGE C
                output Zero, LT, // CHANGE B:
                output [31:0] PC,
                input  [31:0] Instr,
                output [31:0] ALUResult, WriteData, 
                input  [31:0] ReadData);
  
  localparam WIDTH = 32; // Define a local parameter for bus width

  wire [31:0] PCNext, PCPlus4, PCTarget;
  wire [31:0] PCTargetBase;   // CHANGE C 
  wire [31:0] ImmExt; 
  wire [31:0] SrcA, SrcB; 
  wire [31:0] Result; 

  // ============================================================
  // Next PC logic
  // No change needed for lui.
  // lui is not a branch or jump, so normally PCNext = PCPlus4.
  // ============================================================

  flopr #(WIDTH) pcreg(
    .clk(clk), 
    .reset(reset), 
    .d(PCNext), 
    .q(PC)
  ); 

  adder pcadd4(
    .a(PC), 
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4)
  ); 

  // CHANGE C: el destino del salto parte de PC (jal/branch) o de rs1 (jalr)
  mux2 #(WIDTH) jalrmux(
    .d0(PC), 
    .d1(SrcA), 
    .s(JalrSrc), 
    .y(PCTargetBase)
  ); 

  adder pcaddbranch(
    .a(PCTargetBase),   // antes era .a(PC)
    .b(ImmExt), 
    .y(PCTarget)
  ); 

  mux2 #(WIDTH) pcmux(
    .d0(PCPlus4), 
    .d1(PCTarget), 
    .s(PCSrc), 
    .y(PCNext)
  ); 
 
  // ============================================================
  // Register file logic
  // No structural change needed for lui.
  //
  // For lui:
  //   rd = Instr[11:7]
  //   wd3 = Result
  //   RegWrite = 1
  //
  // The value written to rd will come from ImmExt through the
  // modified Result mux below.
  // ============================================================

  regfile rf(
    .clk(clk), 
    .we3(RegWrite), 
    .a1(Instr[19:15]), 
    .a2(Instr[24:20]), 
    .a3(Instr[11:7]), 
    .wd3(Result), 
    .rd1(SrcA), 
    .rd2(WriteData)
  ); 

  // ============================================================
  // Immediate extension logic
  //
  // CHANGE:
  // extend.v now receives a 3-bit ImmSrc.
  // This allows it to generate U-type immediates for lui:
  //
  //   ImmExt = {Instr[31:12], 12'b0}
  //
  // ============================================================

  extend ext(
    .instr(Instr[31:7]), 
    .immsrc(ImmSrc), 
    .immext(ImmExt)
  ); 

  // ============================================================
  // ALU logic
  // No new ALU operation is needed for lui in this implementation.
  //
  // lui bypasses the ALU and writes ImmExt directly to rd.
  //
  // xor still uses the normal R-type ALU path:
  //   SrcA = rs1
  //   SrcB = rs2
  //   ALUControl = 100
  //   ALUResult = SrcA ^ SrcB
  // ============================================================

  mux2 #(WIDTH) srcbmux(
    .d0(WriteData), 
    .d1(ImmExt), 
    .s(ALUSrc), 
    .y(SrcB)
  ); 

  alu alu(
    .a(SrcA), 
    .b(SrcB), 
    .alucontrol(ALUControl), 
    .result(ALUResult), 
    .zero(Zero),
    .lt(LT) // CHANGE B
  ); 

  // ============================================================
  // Writeback result mux
  //
  // CHANGE:
  // The original mux3 had only:
  //   ResultSrc = 00 -> ALUResult
  //   ResultSrc = 01 -> ReadData
  //   ResultSrc = 10 -> PCPlus4
  //
  // For lui, we need one more input:
  //   ResultSrc = 11 -> ImmExt
  //
  // Therefore, replace mux3 with mux4.
  // ============================================================

  mux4 #(WIDTH) resultmux(
    .d0(ALUResult), // ResultSrc = 00, R-type/I-type ALU result
    .d1(ReadData),  // ResultSrc = 01, lw
    .d2(PCPlus4),   // ResultSrc = 10, jal
    .d3(ImmExt),    // CHANGE: ResultSrc = 11, lui
    .s(ResultSrc), 
    .y(Result)
  ); 

endmodule