module main (
    input  logic        clk,
    input  logic        rst,
    output logic [63:0] inst,
    // デバッグ用ポート
    output logic [4:0]  debug_rd,
    output logic [4:0]  debug_rs1,
    output logic [4:0]  debug_rs2,
    output logic [63:0] debug_rd_val, // 計算結果が書き込まれるレジスタの値
    output logic [63:0] debug_reg1,   // レジスタ1番の値
    output logic [63:0] debug_reg2,   // レジスタ2番の値
    output logic [63:0] debug_reg3,   // レジスタ3番の値
    output logic [63:0] debug_pc      // PCの値
);

    // 1. プログラムカウンタ
    logic [63:0] pc;

    // 2. ROM（命令メモリ：0〜7）
    logic [63:0] rom [0:7];

    initial begin
        // NOPスタートのプログラム構成
        rom[0] = {16'd0,  5'd0,  5'd0,  5'd0,  32'd0,   1'b0}; // NOP (何もしない)
        rom[1] = {16'd1,  5'd1,  5'd0,  5'd0,  32'd30,  1'b0}; // Load r1, 30
        rom[2] = {16'd1,  5'd2,  5'd0,  5'd0,  32'd20,  1'b0}; // Load r2, 20
        rom[3] = {16'd4,  5'd0,  5'd0,  5'd0,  32'd40,  1'b0}; // JMP  40 (アドレス40 = rom[5]の位置へジャンプ)
        rom[4] = {16'd2,  5'd3,  5'd1,  5'd2,  32'd00,  1'b0}; // （ここはスキップされるはず！）
        rom[5] = {16'd2,  5'd3,  5'd1,  5'd2,  32'd00,  1'b0}; // ADD  r3 = r1 + r2 (ジャンプ先)
        rom[6] = {16'd0,  5'd0,  5'd0,  5'd0,  32'd0,   1'b0};
        rom[7] = {16'd0,  5'd0,  5'd0,  5'd0,  32'd0,   1'b0};
    end

    // 命令フェッチ（PCから即座に命令を取り出す）
    always_comb begin
        if ((pc >> 3) < 8) begin
            inst = rom[pc[5:3]];
        end else begin
            inst = 64'b0;
        end
    end

    // デコード用のワイヤー
    logic [15:0] opcode;
    logic [4:0]  rd;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [31:0] imm;
    logic        reserved;

    assign opcode   = inst[63:48]; // 16bit
    assign rd       = inst[47:43]; // 5bit
    assign rs1      = inst[42:38]; // 5bit
    assign rs2      = inst[37:33]; // 5bit
    assign imm      = inst[32:1];  // 32bit
    assign reserved = inst[0];     // 1bit

    // ★ ここがポイント：今読んでいる命令がジャンプ（16'h0004）なら、次のPCを即座に即値にする！
    logic [63:0] next_pc;
    always_comb begin
        if (opcode == 16'h0004) begin
            next_pc = {32'h0, imm}; // ジャンプ先へワープ
        end else begin
            next_pc = pc + 64'h8;   // 通常は次へ進む
        end
    end

    // PCの更新（組み合わせ回路で決まった next_pc をそのまま受け取る）
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 64'h0;
        end else begin
            pc <= next_pc;
        end
    end

    // 3. レジスタファイル（32個）
    logic [63:0] regs [0:31];

    // 4. 実行＆レジスタ書き込み部分
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                regs[i] <= 64'h0;
            end
        end else begin
            // オペコードごとに処理を分岐（ジャンプはPC制御側で終わっているのでここでは不要）
            case (opcode)
                16'h0000: begin // NOP
                end

                16'h0001: begin // 32bit即値ロード
                    if (rd != 5'd0) begin
                        regs[rd] <= {32'h0, imm};
                    end
                end

                16'h0002: begin // ADD
                    if (rd != 5'd0) begin
                        regs[rd] <= regs[rs1] + regs[rs2];
                    end
                end

                16'h0003: begin // SUB
                    if (rd != 5'd0) begin
                        regs[rd] <= regs[rs1] - regs[rs2];
                    end
                end

                16'h0004: begin // 無条件ジャンプ（PCの書き換えは上で完了済みなのでここでは何もしない）
                end

                default: begin
                end
            endcase
        end
    end

    // デバッグ出力の割り当て
    assign debug_rd     = rd;
    assign debug_rs1    = rs1;
    assign debug_rs2    = rs2;
    assign debug_rd_val = regs[rd];
    assign debug_reg1   = regs[1];
    assign debug_reg2   = regs[2];
    assign debug_reg3   = regs[3];
    assign debug_pc     = pc;

endmodule