// cpu-harness.cpp
#include <verilated.h>        // 核心头文件
#include <verilated_vcd_c.h>  // 波形生成头文件
#include <fstream>
#include <iostream>
#include "Vcpu.h"  // 译码器模块类
using namespace std;

Vcpu* top;           // 顶层dut对象指针
VerilatedVcdC* tfp;  // 波形生成对象指针

vluint64_t main_time = 0;            // 仿真时间戳
const vluint64_t sim_time = 500000;  // 最大仿真时间戳

int main(int argc, char** argv) {
    // 一些初始化工作
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    // 为对象分配内存空间
    top = new Vcpu;
    tfp = new VerilatedVcdC;

    // tfp初始化工作
    top->trace(tfp, 99);
    tfp->open("cpu.vcd");

    top->chk_addr = 0x1000 + 2;
    top->clk = 0;
    top->rstn = 0;

    top->eval();
    tfp->dump(main_time++);
    top->clk = 1;
    top->eval();
    tfp->dump(main_time++);
    top->rstn = 1;

    int a = 1, b = 1, cnt = 0;
    unsigned min_stack = 0xffffffff;

    while (!Verilated::gotFinish() && main_time < sim_time) {
        // 循环读取内存值

        top->clk = !top->clk;
        top->eval();           // 仿真时间步进
        tfp->dump(main_time);  // 波形文件写入步进

        if (top->io_we) {
            int data = top->io_dout;
            if (data != b) {
                b = a + b;
                a = b - a;
                if (data != b) {
                    cout << "失败：计算 fib 预期" << b << endl;
                }
                cnt++;
                cout << "预期" << b << " 实际" << data << endl;
                if (cnt > 147) {
                    cout << "通过 fib 测试" << endl;
                    cout << std::hex << "最小栈地址：" << min_stack << endl;
                    tfp->close();
                    exit(0);
                }
            }
        }

        if (top->chk_data < min_stack && main_time > 200) {
            min_stack = top->chk_data;
        }

        main_time++;
    }

    cout
        << "失败：未能在给定周期内结束测试，可以考虑手动调整 cpp 文件中周期设置"
        << endl;
    tfp->close();
    exit(0);
}