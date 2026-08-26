#include "Vmain.h"
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <cstdio>
#include <string>
#include <thread>
#include <chrono>

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
    Verilated::traceEverOn(true);
    
    Vmain* top = new Vmain;

    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    vluint64_t clock = 0;
    vluint64_t sim_time = 0;

    while (clock < 10) {
        if (clock == 0) top->rst = 1;
        if (clock == 1) top->rst = 0;

        // クロックが立ち上がる直前の「まさに今から実行される命令とPC」を控えておく
        uint64_t current_pc = top->debug_pc;
        uint64_t current_inst = top->inst;

        // クロック 0 (立ち下がり)
        top->clk = 0;
        top->eval();
        tfp->dump(sim_time++);

        // クロック 1 (立ち上がり：ここでハードウェア内部が実行される)
        top->clk = 1;
        top->eval();
        tfp->dump(sim_time++);

        // リセット解除後（clock >= 1以降）に、そのクロックの実行結果を表示する
        if (clock >= 1) {
            printf("Clock: %llu | 実行PC: 0x%02llX | 命令: %s\n", 
                    (unsigned long long)clock, 
                    (unsigned long long)current_pc,
                    format_binary_inst(current_inst).c_str());
            printf("  -> 結果: Reg1=%llu | Reg2=%llu | Reg3=%llu | 次のPC=0x%02llX\n", 
                    (unsigned long long)top->debug_reg1,
                    (unsigned long long)top->debug_reg2,
                    (unsigned long long)top->debug_reg3,
                    (unsigned long long)top->debug_pc);
            printf("------------------------------------------------------------------\n");
        }

        clock++;
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }

    tfp->close();
    delete tfp;
    delete top;
    return 0;
}