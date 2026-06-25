// FASE 3: descompresor RVC -> RV32I.
// Soporta F1-F8 y c.xor (F9). El resto->NOP/illegal.
module decompressor(input  [15:0]     cinstr,
                    output reg [31:0] instr,    // 32 bits expandida
                    output reg        illegal); // 1 = no soportada (aun)

  wire [4:0] rdp  = {2'b01, cinstr[9:7]};  // rd'/rs1'  (x8..x15)
  wire [4:0] rs2p = {2'b01, cinstr[4:2]};  // rs2'      (x8..x15)
  wire [4:0] rd   = cinstr[11:7];          // rd/rs1 completo (formatos CI/CR)
  wire [1:0] op     = cinstr[1:0];
  wire [2:0] funct3 = cinstr[15:13];

  // sintetizador R-type (sub/xor/or/and/add)
  function [31:0] rtype(input [6:0] f7, input [4:0] rs2,
                        input [2:0] f3, input [4:0] rs1, input [4:0] rd);
    rtype = {f7, rs2, rs1, f3, rd, 7'b0110011};
  endfunction

  // sintetizador I-ALU (srli/srai/slli/addi/andi)
  function [31:0] itype(input [11:0] imm, input [4:0] rs1,
                        input [2:0] f3, input [4:0] rd);
    itype = {imm, rs1, f3, rd, 7'b0010011};
  endfunction

  // FASE 3: sintetizador U-type (lui)
  function [31:0] utype(input [19:0] imm, input [4:0] rd);
    utype = {imm, rd, 7'b0110111};
  endfunction

  always @(*) begin
    illegal = 1'b0;
    instr   = 32'h00000013;              // NOP por defecto
    case (op)
      2'b01: case (funct3)               // Quadrant 1
        3'b000:                          // FASE 6: c.addi (rd != x0)
          if (rd != 5'd0)
            instr = itype({{7{cinstr[12]}}, cinstr[6:2]}, rd, 3'b000, rd);
          else
            illegal = 1'b1;              // rd=x0 -> c.nop/HINT (no implementada)
        3'b011:                          // FASE 3: c.lui (rd != x0,x2; nzimm != 0)
          if (rd != 5'd0 && rd != 5'd2 && {cinstr[12], cinstr[6:2]} != 6'd0)
            instr = utype({{15{cinstr[12]}}, cinstr[6:2]}, rd);
          else
            illegal = 1'b1;              // rd=x2 -> c.addi16sp (no implementada)
        3'b100: case (cinstr[11:10])     // MISC-ALU
          2'b00: if (cinstr[12]==1'b0)   // c.srli  (RV32: shamt[5] debe ser 0)
                   instr = itype({7'b0000000, cinstr[6:2]}, rdp, 3'b101, rdp);
                 else illegal = 1'b1;
          2'b01: if (cinstr[12]==1'b0)   // FASE 8: c.srai (RV32: shamt[5]=0); funct7=0100000 -> SRA
                   instr = itype({7'b0100000, cinstr[6:2]}, rdp, 3'b101, rdp);
                 else illegal = 1'b1;
          2'b10: instr = itype({{7{cinstr[12]}}, cinstr[6:2]}, rdp, 3'b111, rdp); // FASE 4: c.andi (imm 6b con signo)
          2'b11: if (cinstr[12]==1'b0)   // grupo CA
                   case (cinstr[6:5])
                     2'b00:   instr = rtype(7'b0100000, rs2p, 3'b000, rdp, rdp); // c.sub
                     2'b01:   instr = rtype(7'b0000000, rs2p, 3'b100, rdp, rdp); // FASE 9: c.xor
                     default: illegal = 1'b1;                                    // Fases 10-11
                   endcase
                 else illegal = 1'b1;
          default: illegal = 1'b1;
        endcase
        default: illegal = 1'b1;
      endcase
      2'b10: case (funct3)               // Quadrant 2
        3'b000:                          // FASE 7: c.slli (rd != x0; RV32: shamt[5]=0)
          if (rd != 5'd0 && cinstr[12]==1'b0)
            instr = itype({7'b0000000, cinstr[6:2]}, rd, 3'b001, rd);
          else
            illegal = 1'b1;
        3'b100:                          // FASE 5: c.add (cinstr[12]=1, rs2 != 0)
          if (cinstr[12]==1'b1 && cinstr[6:2]!=5'd0)
            instr = rtype(7'b0000000, cinstr[6:2], 3'b000, rd, rd); // add rd,rd,rs2
          else
            illegal = 1'b1;              // c.jr/c.mv/c.jalr/c.ebreak -> lote 2
        default: illegal = 1'b1;
      endcase
      default: illegal = 1'b1;
    endcase
  end
endmodule
