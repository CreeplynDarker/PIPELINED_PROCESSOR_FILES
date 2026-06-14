// Used in the modified single-cycle processor to support lui.
//
// ResultSrc encoding in datapath:
//   2'b00 -> ALUResult
//   2'b01 -> ReadData
//   2'b10 -> PCPlus4
//   2'b11 -> ImmExt     // CHANGE: new path for lui

module mux4 #(parameter WIDTH = 8)
             (input  [WIDTH-1:0] d0, d1, d2, d3,
              input  [1:0]       s, 
              output [WIDTH-1:0] y);

  // CHANGE:
  // This mux supports four possible outputs instead of three.
  //
  // s = 00 -> d0
  // s = 01 -> d1
  // s = 10 -> d2
  // s = 11 -> d3
  //
  // For lui:
  //   s  = 2'b11
  //   d3 = ImmExt
  //   y  = ImmExt
  assign y = s[1] ? (s[0] ? d3 : d2)
                  : (s[0] ? d1 : d0);

endmodule