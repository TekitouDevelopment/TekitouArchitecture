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
    output logic [63:0] debug_reg3    // レジスタ3番の値
);
    // 1. プログラムカウンタ
    logic [63:0] pc;

    // 2. ROM（命令メモリ）
    logic [63:0] rom [0:3];

    initial begin
        rom[0] = {16'd0,  5'd0,  5'd0,  5'd0,  32'd0,  1'b0};
        rom[1] = {16'd2,  5'd1,  5'd0,  5'd0,  32'd30,  1'b0};
        rom[2] = {16'd2,  5'd2,  5'd0,  5'd0,  32'd20,  1'b0};
        rom[3] = {16'd1,  5'd3,  5'd1,  5'd2,  32'd00,  1'b0};
    end

    // PCの更新（8バイト刻み）
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 64'h0;
        end else begin
            pc <= pc + 64'h8;
        end
    end

    always_comb begin
        // pc >> 3 が 4 未満のとき
        if ((pc >> 3) < 4) begin
            inst = rom[pc[4:3]];
        end else begin
            inst = 64'b0;
        end
    end

    // 3. レジスタファイル（王道の32個に拡張！）
    logic [63:0] regs [0:31];

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

    // 4. 実行＆レジスタ書き込み部分
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // 32個すべてを初期化
            for (int i = 0; i < 32; i++) begin
                regs[i] <= 64'h0;
            end
        end else begin
            if (opcode == 16'h0001) begin
                // 1番：ADD命令（足し算）
                // （※ r0が常に0のハードウェアにするなら if (rd != 0) をつけるとさらに本格的になります！）
                if (rd != 5'd0) begin
                    regs[rd] <= regs[rs1] + regs[rs2];
                end
            end 
            else if (opcode == 16'h0002) begin
                // 2番：即値ロード命令（好きな値をレジスタに突っ込む！）
                // 32ビットの即値（imm）を64ビットに拡張してレジスタに書き込みます
                if (rd != 5'd0) begin
                    regs[rd] <= {32'h0, imm}; // ゼロ拡張する場合
                end
            end
        end
    end

    // デバッグ出力の割り当て
    assign debug_rd     = rd;
    assign debug_rs1    = rs1;
    assign debug_rs2    = rs2;
    
    // 今まさに指定されている rd 番号のレジスタの中身をそのまま出力
    assign debug_rd_val = regs[rd];

    // 個別のレジスタ確認用
    assign debug_reg1   = regs[1];
    assign debug_reg2   = regs[2];
    assign debug_reg3   = regs[3];

endmodule