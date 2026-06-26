// =====================================================================
//  testbench_final.v -- Testbench para el "Programa de prueba final"
//  (multiplicacion de matrices 2x2 + checksum).
//
//  Diferencias respecto al testbench de fases:
//   1) Precarga A y B en la memoria de datos antes del reset.
//   2) No usa el sentinel mem[100]=25; comprueba C y h AL FINAL.
//   3) Timeout mas largo (el programa son 272 ciclos ~ 2720 ns).
//
//  Compilar (con la imem ampliada a >=66 palabras para la version RV32I):
//    iverilog -g2012 -o sim <design>/*.v testbench_final.v
//    vvp sim +mem=matmul_rv32i.mem      (o matmul_hybrid.mem)
// =====================================================================
module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;
  integer      errores;

  // instancia del dispositivo bajo prueba
  top dut(.clk(clk), .reset(reset), .WriteData(WriteData),
          .DataAdr(DataAdr), .MemWrite(MemWrite));

  // volcado de waveform para el informe (abrir con GTKWave)
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, testbench);
  end

  // --- PRECARGA de datos + reset ---
  // A y B se colocan a mano en la memoria de datos (la dmem no se carga
  // desde archivo). Palabra N de la dmem = direccion de byte 4*N.
  //   A en palabras 0..3 (dir 0..12):  [[2,3],[4,1]]
  //   B en palabras 4..7 (dir 16..28): [[1,5],[2,3]]
  initial begin
    dut.dmem.RAM[0] = 32'd2;  dut.dmem.RAM[1] = 32'd3;   // A[0][0], A[0][1]
    dut.dmem.RAM[2] = 32'd4;  dut.dmem.RAM[3] = 32'd1;   // A[1][0], A[1][1]
    dut.dmem.RAM[4] = 32'd1;  dut.dmem.RAM[5] = 32'd5;   // B[0][0], B[0][1]
    dut.dmem.RAM[6] = 32'd2;  dut.dmem.RAM[7] = 32'd3;   // B[1][0], B[1][1]
    reset = 1; # 22; reset = 0;
  end

  // reloj
  always begin
    clk = 1; # 5; clk = 0; # 5;
  end

  // log de cada escritura (util para seguir los stores en el waveform)
  always @(negedge clk)
    if (MemWrite)
      $display("[%0t] STORE  mem[%0d] <= %0d", $time, DataAdr, WriteData);

  // --- COMPROBACION FINAL ---
  // Se espera a que el programa termine y se revisa la memoria de datos:
  //   C en palabras 8..11 (dir 32..44) debe ser [8, 19, 6, 23]
  //   h en palabra 12 (dir 48) debe ser 15
  initial begin
    # 4000;                      // holgura suficiente (272 ciclos ~ 2720 ns)
    errores = 0;
    if (dut.dmem.RAM[8]  !== 32'd8)  errores = errores + 1;
    if (dut.dmem.RAM[9]  !== 32'd19) errores = errores + 1;
    if (dut.dmem.RAM[10] !== 32'd6)  errores = errores + 1;
    if (dut.dmem.RAM[11] !== 32'd23) errores = errores + 1;
    if (dut.dmem.RAM[12] !== 32'd15) errores = errores + 1;

    $display("---------------------------------------------");
    $display("C = [%0d %0d ; %0d %0d]   checksum h = %0d",
             dut.dmem.RAM[8],  dut.dmem.RAM[9],
             dut.dmem.RAM[10], dut.dmem.RAM[11], dut.dmem.RAM[12]);
    if (errores === 0) $display("Simulation succeeded");
    else               $display("Simulation failed (%0d valores incorrectos)", errores);
    $finish;
  end
endmodule