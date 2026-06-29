// FASE 16: descompresor RVC -> RV32I.
// Soporta Lote 1 completo + F12 c.j/c.jal + F13 c.beqz/c.bnez +
// F14 c.lw/c.sw + F15 c.lwsp/c.swsp + F16 c.jr.
module decompressor(input  [15:0]     cinstr,
                    output reg [31:0] instr,    // 32 bits expandida
                    output reg        illegal); // 1 = no soportada aun

  wire [4:0] rdp  = {2'b01, cinstr[9:7]};  // rd'/rs1'  (x8..x15)
  wire [4:0] rs2p = {2'b01, cinstr[4:2]};  // rs2'/rd'  (x8..x15)
  wire [4:0] rd   = cinstr[11:7];          // rd/rs1 completo (formatos CI/CR)
  wire [1:0] op     = cinstr[1:0];
  wire [2:0] funct3 = cinstr[15:13];

  // FASE 12: inmediato CJ (c.j/c.jal) -> offset con signo, imm[0]=0
  wire [20:0] cj_imm = {
    {9{cinstr[12]}}, // [20:12] extension de signo
    cinstr[12],      // [11]
    cinstr[8],       // [10]
    cinstr[10],      // [9]
    cinstr[9],       // [8]
    cinstr[6],       // [7]
    cinstr[7],       // [6]
    cinstr[2],       // [5]
    cinstr[11],      // [4]
    cinstr[5],       // [3]
    cinstr[4],       // [2]
    cinstr[3],       // [1]
    1'b0             // [0]
  };

  // FASE 13: inmediato CB (c.beqz/c.bnez) -> offset con signo, imm[0]=0
  wire [12:0] cb_imm = {
    {5{cinstr[12]}}, // [12:8] signo + imm[8]
    cinstr[6],       // [7]
    cinstr[5],       // [6]
    cinstr[2],       // [5]
    cinstr[11],      // [4]
    cinstr[10],      // [3]
    cinstr[4],       // [2]
    cinstr[3],       // [1]
    1'b0             // [0]
  };

  // FASE 14: inmediato CL/CS (c.lw/c.sw), offset sin signo escalado por palabra
  wire [11:0] clw_imm = {5'b0, cinstr[5], cinstr[12:10], cinstr[6], 2'b00};

  // FASE 15: inmediato CI para c.lwsp, offset sin signo escalado por palabra
  wire [11:0] clwsp_imm = {4'b0, cinstr[3:2], cinstr[12], cinstr[6:4], 2'b00};

  // FASE 15: inmediato CSS para c.swsp, offset sin signo escalado por palabra
  wire [11:0] cswsp_imm = {4'b0, cinstr[8:7], cinstr[12:9], 2'b00};

  // sintetizador R-type (sub/xor/or/and/add)
  function [31:0] rtype(input [6:0] f7, input [4:0] rs2,
                        input [2:0] f3, input [4:0] rs1, input [4:0] rd);
    rtype = {f7, rs2, rs1, f3, rd, 7'b0110011};
  endfunction

  // sintetizador I-ALU (srli/srai/slli/addi/andi)
  // OJO: no usar para lw ni jalr, porque fija opcode 0010011.
  function [31:0] itype(input [11:0] imm, input [4:0] rs1,
                        input [2:0] f3, input [4:0] rd);
    itype = {imm, rs1, f3, rd, 7'b0010011};
  endfunction

  // sintetizador U-type (lui)
  function [31:0] utype(input [19:0] imm, input [4:0] rd);
    utype = {imm, rd, 7'b0110111};
  endfunction

  // FASE 12: sintetizador J-type (jal) -- opcode 1101111
  function [31:0] jtype(input [20:0] imm, input [4:0] rd);
    jtype = {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
  endfunction

  // FASE 13: sintetizador B-type (beq/bne) -- opcode 1100011
  function [31:0] btype(input [12:0] imm, input [4:0] rs2,
                        input [4:0] rs1, input [2:0] f3);
    btype = {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], 7'b1100011};
  endfunction

  // FASE 14/15: sintetizador LOAD (lw) -- opcode 0000011, funct3 010
  function [31:0] itype_load(input [11:0] imm, input [4:0] rs1, input [4:0] rd);
    itype_load = {imm, rs1, 3'b010, rd, 7'b0000011};
  endfunction

  // FASE 14/15: sintetizador STORE (sw) -- opcode 0100011, funct3 010
  function [31:0] stype(input [11:0] imm, input [4:0] rs2, input [4:0] rs1);
    stype = {imm[11:5], rs2, rs1, 3'b010, imm[4:0], 7'b0100011};
  endfunction

  // FASE 16: sintetizador JALR -- opcode 1100111, funct3 000
  function [31:0] itype_jalr(input [11:0] imm, input [4:0] rs1, input [4:0] rd);
    itype_jalr = {imm, rs1, 3'b000, rd, 7'b1100111};
  endfunction

  always @(*) begin
    illegal = 1'b0;
    instr   = 32'h00000013;              // NOP por defecto

    case (op)
      2'b00: case (funct3)               // Quadrant 0
        3'b010: instr = itype_load(clw_imm, rdp, rs2p); // FASE 14: c.lw -> lw rd',off(rs1')
        3'b110: instr = stype(clw_imm, rs2p, rdp);      // FASE 14: c.sw -> sw rs2',off(rs1')
        default: illegal = 1'b1;
      endcase

      2'b01: case (funct3)               // Quadrant 1
        3'b001: instr = jtype(cj_imm, 5'd1); // FASE 12: c.jal -> jal x1, off
        3'b101: instr = jtype(cj_imm, 5'd0); // FASE 12: c.j   -> jal x0, off
        3'b110: instr = btype(cb_imm, 5'd0, rdp, 3'b000); // FASE 13: c.beqz -> beq rs1',x0,off
        3'b111: instr = btype(cb_imm, 5'd0, rdp, 3'b001); // FASE 13: c.bnez -> bne rs1',x0,off

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

          2'b01: if (cinstr[12]==1'b0)   // c.srai (RV32: shamt[5]=0); funct7=0100000 -> SRA
                   instr = itype({7'b0100000, cinstr[6:2]}, rdp, 3'b101, rdp);
                 else illegal = 1'b1;

          2'b10: instr = itype({{7{cinstr[12]}}, cinstr[6:2]}, rdp, 3'b111, rdp); // c.andi

          2'b11: if (cinstr[12]==1'b0)   // grupo CA
                   case (cinstr[6:5])
                     2'b00: instr = rtype(7'b0100000, rs2p, 3'b000, rdp, rdp); // c.sub
                     2'b01: instr = rtype(7'b0000000, rs2p, 3'b100, rdp, rdp); // c.xor
                     2'b10: instr = rtype(7'b0000000, rs2p, 3'b110, rdp, rdp); // c.or
                     2'b11: instr = rtype(7'b0000000, rs2p, 3'b111, rdp, rdp); // c.and
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

        3'b010:                          // FASE 15: c.lwsp -> lw rd,off(x2)
          if (rd != 5'd0)
            instr = itype_load(clwsp_imm, 5'd2, rd);
          else
            illegal = 1'b1;              // rd=x0 reservado

        3'b100: begin                    // CR: c.jr / c.add / otros
          if (cinstr[12] == 1'b0) begin
            if (cinstr[6:2] == 5'd0 && rd != 5'd0)
              instr = itype_jalr(12'd0, rd, 5'd0); // FASE 16: c.jr -> jalr x0,0(rs1)
            else
              illegal = 1'b1;            // c.mv no implementada / rs1=x0 reservado
          end else begin
            if (cinstr[6:2] != 5'd0)
              instr = rtype(7'b0000000, cinstr[6:2], 3'b000, rd, rd); // c.add ya implementada
            else
              illegal = 1'b1;            // c.jalr/c.ebreak -> Fase 17
          end
        end

        3'b110: instr = stype(cswsp_imm, cinstr[6:2], 5'd2); // FASE 15: c.swsp -> sw rs2,off(x2)

        default: illegal = 1'b1;
      endcase

      default: illegal = 1'b1;
    endcase
  end
endmodule
