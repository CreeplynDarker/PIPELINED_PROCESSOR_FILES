module controller(input        clk, reset,
                  // Decode-stage instruction fields (desde datapath)
                  input  [6:0] opD,
                  input  [2:0] funct3D,
                  input        funct7b5D,
                  // Execute-stage flags (desde datapath)
                  input        ZeroE, LTE,
                  // salidas hacia datapath
                  output [2:0] ImmSrcD,
                  output       PCSrcE,
                  output       ALUSrcE, JalrSrcE,
                  output [3:0] ALUControlE,
                  output       MemWriteM,
                  output       RegWriteM,
                  output       RegWriteW,
                  output [1:0] ResultSrcW);

  // ---- Decode: decodificadores (combinacional) ----
  wire       RegWriteD, MemWriteD, JumpD, BranchD, ALUSrcD, JalrSrcD;
  wire [1:0] ResultSrcD, ALUOpD;
  wire [3:0] ALUControlD;

  maindec md(.op(opD), .ResultSrc(ResultSrcD), .MemWrite(MemWriteD),
             .Branch(BranchD), .ALUSrc(ALUSrcD), .RegWrite(RegWriteD),
             .Jump(JumpD), .ImmSrc(ImmSrcD), .ALUOp(ALUOpD), .JalrSrc(JalrSrcD));
  aludec ad(.opb5(opD[5]), .funct3(funct3D), .funct7b5(funct7b5D),
            .ALUOp(ALUOpD), .ALUControl(ALUControlD));

  // ---- ID/EX: registro de control ----
  reg        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE_r, JalrSrcE_r;
  reg [1:0]  ResultSrcE;
  reg [3:0]  ALUControlE_r;
  reg [2:0]  funct3E;
  always @(posedge clk, posedge reset)
    if (reset) {RegWriteE,MemWriteE,JumpE,BranchE,ResultSrcE,
                ALUControlE_r,ALUSrcE_r,JalrSrcE_r,funct3E} <= 0;
    else begin
      RegWriteE<=RegWriteD; MemWriteE<=MemWriteD; JumpE<=JumpD; BranchE<=BranchD;
      ResultSrcE<=ResultSrcD; ALUControlE_r<=ALUControlD;
      ALUSrcE_r<=ALUSrcD; JalrSrcE_r<=JalrSrcD; funct3E<=funct3D;
    end
  assign ALUSrcE=ALUSrcE_r; assign JalrSrcE=JalrSrcE_r; assign ALUControlE=ALUControlE_r;

  // ---- EX: decision de branch (con funct3E, ZeroE, LTE) ----
  reg BranchTakenE;
  always @* case (funct3E)
      3'b000:  BranchTakenE = ZeroE;   // beq
      3'b001:  BranchTakenE = ~ZeroE;  // bne
      3'b100:  BranchTakenE = LTE;     // blt
      3'b101:  BranchTakenE = ~LTE;    // bge
      default: BranchTakenE = 1'b0;
    endcase
  assign PCSrcE = (BranchE & BranchTakenE) | JumpE;

  // ---- EX/MEM: registro de control ----
  reg RegWriteM_r, MemWriteM_r;
  reg [1:0] ResultSrcM;
  always @(posedge clk, posedge reset)
    if (reset) {RegWriteM_r,ResultSrcM,MemWriteM_r} <= 0;
    else begin RegWriteM_r<=RegWriteE; ResultSrcM<=ResultSrcE; MemWriteM_r<=MemWriteE; end
  assign MemWriteM = MemWriteM_r;
  assign RegWriteM = RegWriteM_r;

  // ---- MEM/WB: registro de control ----
  reg RegWriteW_r;
  reg [1:0] ResultSrcW_r;
  always @(posedge clk, posedge reset)
    if (reset) {RegWriteW_r,ResultSrcW_r} <= 0;
    else begin RegWriteW_r<=RegWriteM_r; ResultSrcW_r<=ResultSrcM; end
  assign RegWriteW=RegWriteW_r; assign ResultSrcW=ResultSrcW_r;
endmodule
