module imem(input  [31:0] a,
            output [31:0] rd);

  reg [31:0]   RAM[63:0];
  reg [8*64:1] memfile;          // buffer para el nombre de archivo

  initial begin
    // permite elegir el programa con +mem=...; si no, usa riscvtest.mem
    if (!$value$plusargs("mem=%s", memfile))
      memfile = "riscvtest.mem";
    $readmemh(memfile, RAM);
  end

  assign rd = RAM[a[31:2]];      // direccionamiento por palabra
endmodule