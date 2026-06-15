module hazard(input  [4:0] Rs1E, Rs2E, RdM, RdW,
              input        RegWriteM, RegWriteW,
              input  [4:0] Rs1D, Rs2D, RdE,        // 2C
              input        ResultSrcE0,            // 2C: ResultSrcE[0] (load/lui)
              input        PCSrcE,                 // 2D
              output reg [1:0] ForwardAE, ForwardBE,
              output       StallF, StallD,
              output       FlushD, FlushE);        // 2D: FlushD nuevo

  // ---- Forwarding (2B) ----
  always @* begin
    if      ((Rs1E == RdM) & RegWriteM & (Rs1E != 0)) ForwardAE = 2'b10;
    else if ((Rs1E == RdW) & RegWriteW & (Rs1E != 0)) ForwardAE = 2'b01;
    else                                              ForwardAE = 2'b00;
    if      ((Rs2E == RdM) & RegWriteM & (Rs2E != 0)) ForwardBE = 2'b10;
    else if ((Rs2E == RdW) & RegWriteW & (Rs2E != 0)) ForwardBE = 2'b01;
    else                                              ForwardBE = 2'b00;
  end

  // ---- Stalling (2C): load-use ----
  wire lwStall;
  assign lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE));
  assign StallF  = lwStall;
  assign StallD  = lwStall;

  // ---- Flushing (2D): control hazard ----
  assign FlushD  = PCSrcE;             // descarta la instr en IF->ID
  assign FlushE  = lwStall | PCSrcE;   // burbuja load-use O descarte de branch
endmodule
