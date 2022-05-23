// cpu-harness.cpp
#include <verilated.h>        // 核心头文件
#include <verilated_vcd_c.h>  // 波形生成头文件
#include <cstdlib>
#include <fstream>
#include <iostream>
#include "Vtop_test.h"  // 译码器模块类
using namespace std;

Vtop_test* top;      // 顶层dut对象指针
VerilatedVcdC* tfp;  // 波形生成对象指针

vluint64_t main_time = 0;            // 仿真时间戳
const vluint64_t sim_time = 102400;  // 最大仿真时间戳

int main(int argc, char** argv) {
    // 一些初始化工作
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    srand((unsigned)time(NULL));

    // 为对象分配内存空间
    top = new Vtop_test;
    tfp = new VerilatedVcdC;

    // tfp初始化工作
    top->trace(tfp, 99);
    tfp->open("cpu.vcd");

    top->clk = 0;
    top->rstn = 0;
    top->io_din = 0;

    top->eval();
    tfp->dump(main_time++);
    top->clk = 1;
    top->eval();
    tfp->dump(main_time++);
    top->rstn = 1;

    int swx_data = rand();
    cout << swx_data;
    int end_cnt = 0;
    int prev_pc = 0;

    while (!Verilated::gotFinish()) {
        // 循环读取内存值
        if (top->io_rd) {
            int addr = top->io_addr;
            if (addr == 0x18) {
                top->io_din = main_time;
            } else if (addr == 0x10) {
                top->io_din = 1;
            } else if (addr == 0x14) {
                top->io_din = swx_data;
            } else {
                top->io_din = 0;
            }
        } else {
            top->io_din = 0;
        }
        if (top->pc == prev_pc) {
            end_cnt++;
        } else {
            end_cnt = 0;
        }
        if (end_cnt == 100) {
            break;
        }
        prev_pc = top->pc;

        top->clk = !top->clk;
        top->eval();           // 仿真时间步进
        tfp->dump(main_time);  // 波形文件写入步进
        main_time++;
    }

    tfp->close();
    exit(0);
}