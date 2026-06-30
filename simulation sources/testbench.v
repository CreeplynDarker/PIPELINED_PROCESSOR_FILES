// =====================================================================
//  testbench_universal.v -- Testbench unico para TODOS los programas:
//    * Programas de fase (autocontenidos): centinela mem[100] = 25.
//    * Programa de prueba final (suma de arreglo): lee A de memoria.
//
//  La memoria de INSTRUCCIONES se elige con el plusarg propio del imem:
//      +mem=<programa.mem>
//
//  Plusargs OPCIONALES del testbench (todos con valor por defecto):
//      +data=<archivo.mem>  precarga de la dmem ($readmemh, palabra N -> RAM[N]).
//                           Si se omite, la dmem queda en 0 (fases).
//      +addr=N              direccion de byte del centinela   (def. 100).
//      +expect=N            valor esperado en el centinela     (def. 25).
//      +maxtime=N           ventana de simulacion en ns        (def. 2000).
//
//  Ejemplos:
//      vvp sim +mem=test_cj_cjal.mem
//      vvp sim +mem=programa_final_32bits.mem     +data=datos_suma.mem
//      vvp sim +mem=programa_final_comprimido.mem +data=datos_suma.mem
// =====================================================================
module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;

  reg [8*64:1] datafile;
  integer      addr_byte;   // direccion de byte del centinela
  integer      expected;    // valor esperado
  integer      maxtime;     // ventana de simulacion (ns)
  integer      widx;        // indice de palabra = addr_byte/4
  integer      i;

  // dispositivo bajo prueba
  top dut(.clk(clk), .reset(reset), .WriteData(WriteData),
          .DataAdr(DataAdr), .MemWrite(MemWrite));

  // volcado de waveform (abrir con GTKWave; mismo grupo de senales para
  // RV32I y RVC: PCF, InstrF, isCompressedF, InstrD, rf[*], MemWrite,
  // DataAdr, WriteData, PCSrcE, ...)
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, testbench);
  end

  // --- precarga opcional de datos + reset ---
  initial begin
    for (i = 0; i < 64; i = i + 1) dut.dmem.RAM[i] = 32'd0;  // limpia dmem (evita X)
    if (!$value$plusargs("data=%s", datafile))
      datafile = "data.mem";
    $readmemh(datafile, dut.dmem.RAM);
    reset = 1; # 22; reset = 0;
  end

  // reloj
  always begin clk = 1; # 5; clk = 0; # 5; end

  // log de cada escritura (util para seguir los stores en el waveform)
  always @(negedge clk)
    if (MemWrite)
      $display("[%0t] STORE  mem[%0d] <= %0d (0x%h)", $time, DataAdr, WriteData, WriteData);

  // --- veredicto unificado ---
  initial begin
    if (!$value$plusargs("addr=%d",    addr_byte)) addr_byte = 100;
    if (!$value$plusargs("expect=%d",  expected))  expected  = 25;
    if (!$value$plusargs("maxtime=%d", maxtime))   maxtime   = 2000;

    #(maxtime);
    widx = addr_byte / 4;
    $display("---------------------------------------------");
    $display("mem[%0d] = RAM[%0d] = %0d   (esperado %0d)",
             addr_byte, widx, dut.dmem.RAM[widx], expected);
    if (dut.dmem.RAM[widx] === expected)
      $display("Simulation succeeded");
    else
      $display("Simulation failed (mem[%0d] = %0d, esperado %0d)",
               addr_byte, dut.dmem.RAM[widx], expected);
    $finish;
  end
endmodule
