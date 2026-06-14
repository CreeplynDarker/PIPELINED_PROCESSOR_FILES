module hazard(input  [4:0] Rs1E, Rs2E, RdM, RdW,
              input        RegWriteM, RegWriteW,
              output reg [1:0] ForwardAE, ForwardBE);
  always @* begin
    // Operando A
    if      ((Rs1E == RdM) & RegWriteM & (Rs1E != 0)) ForwardAE = 2'b10; // desde MEM
    else if ((Rs1E == RdW) & RegWriteW & (Rs1E != 0)) ForwardAE = 2'b01; // desde WB
    else                                              ForwardAE = 2'b00; // register file
    // Operando B
    if      ((Rs2E == RdM) & RegWriteM & (Rs2E != 0)) ForwardBE = 2'b10;
    else if ((Rs2E == RdW) & RegWriteW & (Rs2E != 0)) ForwardBE = 2'b01;
    else                                              ForwardBE = 2'b00;
  end
endmodule
