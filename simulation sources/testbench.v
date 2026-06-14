module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;

  // instancia del dispositivo bajo prueba
  top dut(.clk(clk), .reset(reset), .WriteData(WriteData),
          .DataAdr(DataAdr), .MemWrite(MemWrite));

  // volcado de waveform para el informe (abrir con GTKWave)
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, testbench);
  end

  // reset inicial
  initial begin
    reset = 1; # 22; reset = 0;
  end

  // reloj
  always begin
    clk = 1; # 5; clk = 0; # 5;
  end

  // log de cada escritura: hace inspeccionable cualquier programa de prueba
  always @(negedge clk)
    if (MemWrite)
      $display("[%0t] STORE  mem[%0d] <= %0d", $time, DataAdr, WriteData);

  // self-check (sentinel: escribir 25 en la direccion 100)
  always @(negedge clk)
    if (MemWrite) begin
      if (DataAdr === 100 & WriteData === 25) begin
        $display("Simulation succeeded");
        $finish;                          // $finish, no $stop: sale limpio en batch
      end else if (DataAdr !== 96) begin
        $display("Simulation failed");
        $finish;
      end
    end

  // guarda de timeout: evita que un programa con bug corra para siempre
  initial begin
    # 2000;
    $display("Timeout: no convergio (no hubo store al sentinel)");
    $finish;
  end
endmodule