#include "Vmain.h"
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <cstdio>
#include <string>

// 64bitの命令を [Opcode:16]_[Rd:5]_[Rs1:5]_[Rs2:5]_[Imm:32]_[Res:1] の形に整形する関数
std::string format_binary_inst(uint64_t inst) {
    uint16_t opcode   = (inst >> 48) & 0xFFFF;
    uint8_t  rd       = (inst >> 43) & 0x1F;
    uint8_t  rs1      = (inst >> 38) & 0x1F;
    uint8_t  rs2      = (inst >> 33) & 0x1F;
    uint32_t imm      = (inst >> 1)  & 0xFFFFFFFF;
    uint8_t  reserved = inst & 0x1;

    auto to_bin = [](uint64_t val, int width) {
        std::string s = "";
        for (int i = width - 1; i >= 0; --i) {
            s += ((val >> i) & 1) ? '1' : '0';
        }
        return s;
    };

    return to_bin(opcode, 16) + "_" +
           to_bin(rd, 5) + "_" +
           to_bin(rs1, 5) + "_" +
           to_bin(rs2, 5) + "_" +
           to_bin(imm, 32) + "_" +
           to_bin(reserved, 1);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true); // トレース（波形記録）を有効化
    
    // 1. 回路モジュールの準備
    Vmain* top = new Vmain;

    // 波形ファイル（VCD）の出力準備
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    vluint64_t clock = 0;
    vluint64_t sim_time = 0; // シミュレーション時間

    while (clock < 10) {
        if (clock == 0) top->rst = 1; // リセットON
        if (clock == 1) top->rst = 0; // リセットOFF

        // クロック 0 (立ち下がり)
        top->clk = 0;
        top->eval();
        tfp->dump(sim_time++);

        // クロック 1 (立ち上がり)
        top->clk = 1;
        top->eval();
        tfp->dump(sim_time++);

        // 実行結果の表示
        printf("Clock: %llu | Inst: %s | rd: r%d (val: %llu) | rs1: r%d | rs2: r%d | Reg1: %llu | Reg2: %llu | Reg3: %llu\n", 
                (unsigned long long)clock, 
                format_binary_inst(top->inst).c_str(), 
                (int)top->debug_rd,
                (unsigned long long)top->debug_rd_val,
                (int)top->debug_rs1,
                (int)top->debug_rs2,
                (unsigned long long)top->debug_reg1,
                (unsigned long long)top->debug_reg2,
                (unsigned long long)top->debug_reg3);
        
        clock++;
    }

    // 終了処理
    tfp->close();
    delete tfp;
    delete top;
    return 0;
}