module imem(input  [31:0] a,
            output [31:0] rd);

  reg [31:0]   RAM[255:0];   // antes: RAM[63:0]
  reg [8*64:1] memfile;          // buffer para el nombre de archivo

  initial begin
    if (!$value$plusargs("mem=%s", memfile))
      memfile = "riscvtest.mem";
    $readmemh(memfile, RAM);
  end

  // --- FASE 1: fetch alineado a 2 bytes (modelo de parcels little-endian) ---
  wire [31:0] lo = RAM[a[31:2]];        // palabra que contiene el parcel bajo
  wire [31:0] hi = RAM[a[31:2] + 1];    // palabra siguiente (parcel alto si cruza)
  // a[1]==0 -> instruccion alineada a 4: la palabra completa
  // a[1]==1 -> empieza en frontera de 2: {parcel bajo de hi, parcel alto de lo}
  assign rd = a[1] ? {hi[15:0], lo[31:16]} : lo;
endmodule
