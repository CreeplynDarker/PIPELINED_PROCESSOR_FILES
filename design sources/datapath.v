module datapath(input         clk, reset,
                // control desde controller
                input         PCSrcE,
                input         ALUSrcE, JalrSrcE,
                input  [3:0]  ALUControlE,
                input  [2:0]  ImmSrcD,
                input         RegWriteW,
                input  [1:0]  ResultSrcW,
                // interfaz de memoria (con top)
                input  [31:0] InstrF,        // desde imem
                input  [31:0] ReadDataM,     // desde dmem
                output [31:0] PCF,           // hacia imem
                output [31:0] ALUResultM,    // hacia dmem (direccion)
                output [31:0] WriteDataM,    // hacia dmem (dato)
                // hazard unit (2B)
                input  [1:0]  ForwardAE, ForwardBE,
                input         StallF, StallD, FlushE,
                output reg [4:0] Rs1E, Rs2E, RdM, RdW, RdE,
                output [4:0]  Rs1D, Rs2D,
                // hacia controller
                output [6:0]  opD,
                output [2:0]  funct3D,
                output        funct7b5D,
                output        ZeroE, LTE);

  // ---- Fetch ----
  reg  [31:0] PCF_r;
  wire [31:0] PCNextF, PCPlus4F, PCTargetE;
  assign PCF = PCF_r;
  mux2 #(32) pcmux(.d0(PCPlus4F), .d1(PCTargetE), .s(PCSrcE), .y(PCNextF));
  always @(posedge clk, posedge reset)
    if (reset) PCF_r <= 32'b0;
    else if (~StallF) PCF_r <= PCNextF;
  adder pcadd4(.a(PCF), .b(32'd4), .y(PCPlus4F));

  // ---- IF/ID ----
  reg [31:0] InstrD, PCD, PCPlus4D;
  always @(posedge clk, posedge reset)
    if (reset) {InstrD,PCD,PCPlus4D} <= 0;
    else if (~StallD) begin InstrD<=InstrF; PCD<=PCF; PCPlus4D<=PCPlus4F; end

  assign opD=InstrD[6:0]; assign funct3D=InstrD[14:12]; assign funct7b5D=InstrD[30];
  assign Rs1D=InstrD[19:15]; assign Rs2D=InstrD[24:20];

  // ---- Decode ----
  wire [31:0] RD1D, RD2D, ImmExtD, ResultW;
  regfile rf(.clk(clk), .we3(RegWriteW), .a1(InstrD[19:15]), .a2(InstrD[24:20]),
             .a3(RdW), .wd3(ResultW), .rd1(RD1D), .rd2(RD2D));
  extend ext(.instr(InstrD[31:7]), .immsrc(ImmSrcD), .immext(ImmExtD));

  // ---- ID/EX ----
  reg [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  always @(posedge clk, posedge reset)
    if (reset | FlushE) {RD1E,RD2E,PCE,ImmExtE,PCPlus4E,Rs1E,Rs2E,RdE} <= 0;
    else begin
      RD1E<=RD1D; RD2E<=RD2D; PCE<=PCD; ImmExtE<=ImmExtD; PCPlus4E<=PCPlus4D;
      Rs1E<=InstrD[19:15]; Rs2E<=InstrD[24:20]; RdE<=InstrD[11:7];
    end

  // ---- Execute ----
  wire [31:0] SrcAE, SrcBE, ALUResultE, WriteDataE, PCTargetBaseE;
  // forwarding: 00=regfile, 01=WB(ResultW), 10=MEM(ALUResultM)
  mux3 #(32) faemux(.d0(RD1E), .d1(ResultW), .d2(ALUResultM), .s(ForwardAE), .y(SrcAE));
  mux3 #(32) fbemux(.d0(RD2E), .d1(ResultW), .d2(ALUResultM), .s(ForwardBE), .y(WriteDataE));
  mux2 #(32) srcbmux(.d0(WriteDataE), .d1(ImmExtE), .s(ALUSrcE), .y(SrcBE));
  alu alu(.a(SrcAE), .b(SrcBE), .alucontrol(ALUControlE),
          .result(ALUResultE), .zero(ZeroE), .lt(LTE));
  mux2 #(32) jalrmux(.d0(PCE), .d1(SrcAE), .s(JalrSrcE), .y(PCTargetBaseE));
  adder pcaddbranch(.a(PCTargetBaseE), .b(ImmExtE), .y(PCTargetE));

  // ---- EX/MEM ----
  reg [31:0] ALUResultM_r, WriteDataM_r, PCPlus4M, ImmExtM;
  always @(posedge clk, posedge reset)
    if (reset) {ALUResultM_r,WriteDataM_r,RdM,PCPlus4M,ImmExtM} <= 0;
    else begin
      ALUResultM_r<=ALUResultE; WriteDataM_r<=WriteDataE; RdM<=RdE;
      PCPlus4M<=PCPlus4E; ImmExtM<=ImmExtE;
    end
  assign ALUResultM = ALUResultM_r;
  assign WriteDataM = WriteDataM_r;

  // ---- MEM/WB ----
  reg [31:0] ALUResultW, ReadDataW, PCPlus4W, ImmExtW;
  always @(posedge clk, posedge reset)
    if (reset) {ALUResultW,ReadDataW,RdW,PCPlus4W,ImmExtW} <= 0;
    else begin
      ALUResultW<=ALUResultM; ReadDataW<=ReadDataM; RdW<=RdM;
      PCPlus4W<=PCPlus4M; ImmExtW<=ImmExtM;
    end

  // ---- Writeback ----
  mux4 #(32) resultmux(.d0(ALUResultW), .d1(ReadDataW), .d2(PCPlus4W), .d3(ImmExtW),
                       .s(ResultSrcW), .y(ResultW));
endmodule
