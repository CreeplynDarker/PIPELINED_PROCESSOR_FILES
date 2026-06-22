// FASE 1: esqueleto del descompresor RVC -> RV32I.
// Solo implementa c.sub; el resto del batch se agrega en Fases 2..11.
module decompressor(input  [15:0]     cinstr,
                    output reg [31:0] instr,    // instruccion de 32 bits expandida
                    output reg        illegal); // 1 = comprimida no soportada (aun)

  // --- helpers reutilizables (los usaran las fases siguientes) ---
  wire [4:0] rdp  = {2'b01, cinstr[9:7]};  // rd'/rs1'  (x8..x15)
  wire [4:0] rs2p = {2'b01, cinstr[4:2]};  // rs2'      (x8..x15)
  wire [1:0] op     = cinstr[1:0];
  wire [2:0] funct3 = cinstr[15:13];

  // sintetizador R-type (reutilizable: sub/xor/or/and/add)
  function [31:0] rtype(input [6:0] f7, input [4:0] rs2,
                        input [2:0] f3, input [4:0] rs1, input [4:0] rd);
    rtype = {f7, rs2, rs1, f3, rd, 7'b0110011};
  endfunction

  always @(*) begin
    illegal = 1'b0;
    instr   = 32'h00000013;             // NOP (addi x0,x0,0) por defecto
    case (op)
      2'b01: begin                      // Quadrant 1
        case (funct3)
          3'b100: begin                 // MISC-ALU
            if (cinstr[12]==1'b0 && cinstr[11:10]==2'b11)
              case (cinstr[6:5])
                2'b00:   instr = rtype(7'b0100000, rs2p, 3'b000, rdp, rdp); // c.sub
                default: illegal = 1'b1;                                    // Fases 9-11
              endcase
            else
              illegal = 1'b1;           // c.srli/c.srai/c.andi -> Fases 2,8,4
          end
          default: illegal = 1'b1;
        endcase
      end
      default: illegal = 1'b1;          // otros cuadrantes -> fases posteriores
    endcase
  end
endmodule
