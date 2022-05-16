// cpu-harness.cpp
#include <verilated.h>        // 核心头文件
#include <verilated_vcd_c.h>  // 波形生成头文件
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

    // 为对象分配内存空间
    top = new Vtop_test;
    tfp = new VerilatedVcdC;

    // tfp初始化工作
    top->trace(tfp, 99);
    tfp->open("cpu.vcd");

    int count = 0;

    top->clk = 0;
    top->rstn = 1;
    int sorted_cnt = 0;
    while (!Verilated::gotFinish() && main_time < sim_time) {
        // 循环读取内存值
        int i = main_time % 16;
        top->vga_addr = i * 4 + 64;
        top->clk = !top->clk;
        top->eval();           // 仿真时间步进
        tfp->dump(main_time);  // 波形文件写入步进
        count++;
        main_time++;
    }

    tfp->close();
    exit(0);
}