module regfile(input  clk,
               input  we3,
               input  [ 4:0] a1, a2, a3,
               input  [31:0] wd3,
               output [31:0] rd1, rd2);
  reg [31:0] rf[31:0];
  // CHANGE 2A: escribir en flanco de BAJADA (escribe 1a mitad, lee 2a mitad)
  always @(negedge clk)
    if (we3) rf[a3] <= wd3;
  assign rd1 = (a1 != 0) ? rf[a1] : 0;
  assign rd2 = (a2 != 0) ? rf[a2] : 0;
endmodule
