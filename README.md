# USTC-CODH-LAB6 实验

![test](https://github.com/liuly0322/ustc-codh-lab6/actions/workflows/test.yml/badge.svg)

USTC CODH 课程的综合实验 lab6

使用实体板：xc7a100tcsg324-1

本实验为小组合作实验，组员主页：

- <https://github.com/liuly0322>
- <https://github.com/start-shine>

## rv32i 指令集

实现了所有的 rv32i 指令

- add, sub, and, or, sll, sra, srl, xor, slt, sltu
- addi, andi, ori, slli, srai, srli, xori, slti, sltiu
- auipc, lui
- lw, sw, lb, lbu, lh, lhu, sb, sh
- beq, bne, blt, bge, bltu, bgeu
- jal, jalr

共计 37 条

## rv32ic 压缩指令集

- c.nop
- c.add, c.addi, c.addi16sp, c.addi4spn, c.and, c.andi, c.slli, c.srai, c.srli, c.sub, c.mv, c.or, c.xor
- c.j, c.jal, c.jr, c.jalr, c.beqz, c.bnez
- c.li, c.lui, c.lw, c.lwsp, c.sw, c.swsp

共计 26 条

## 冲突处理及分支预测

此部分主要是 CPU 的性能相关

较为完善地降低了 CPU 的 CPI，当且仅当 load 指令与后面指令存在数据相关时会产生气泡

分支（跳转）失败实际上是很影响流水线效率的：需要 flush IF/ID 和 ID/EX，损失两个周期

因此这里采用了 2-level adaptive training 的动态分支预测策略，具体性能评估见 report.md

整体性能上，当前 cpu 可以运行在约 85MHz 下

## 更改存储结构

- 对于 0x0000 至 0x3ffff，作为常用内存区域，与 VGA 共享内存
  这一部分相当于始终不会被换出的 cache
- 0xff00 至 0xffff 是 MMIO 区域
- 其余部分使用 L1d cache 连接主存，总共使用 BRAM 16KB（16 千字节）

具体 cache 设计：

tag 6 位，index 3 位，偏移 5 位（3 位字偏移）

采用写回加写分配的策略

## VGA 应用程序

作为示例，本项目运行了三个应用程序，生命游戏，井字棋和贪吃蛇。具体说明和演示视频见 `life_game`, `tic_tac_toe`, `snake` 文件夹

我们希望 VGA 驱动模块作为主要的输出模块能够在逻辑上独立于其他 Verilog 模块（这样便于修改），仅与汇编程序相配套，因此这里采用了与主存共享内存的方式来给 VGA 提供数据，事实证明这极大提高了移植的效率

## CI/CD 及自动化测试

### 持续集成

本项目支持持续集成 (Continuous Integration)，通过 `test.py` 实现，每次对主分支的 push 会自动运行功能测试，如果有错误会显示

以下是示例：

| ![image-20220523150827507](report/ci.png) | ![image-20220523150934880](report/ci-fail.png) |
| :---------------------------------------: | :--------------------------------------------: |
|            Push 后自动运行测试            |                具体错误信息提示                |

### 本地测试

本项目来源于模板：<https://github.com/liuly0322/ustc-cod-verilator>

上面的模板链接中有本项目本地测试工具 `judge.py` 的具体说明及使用方法。本项目在模板的基础上另行增添了几个测试用例

部分测试样例对应的汇编代码见本目录下的 bypass.dump， ri.dump 和 compress.dump

本项目当前总测试样例数为 181 个

## 致谢

- 本项目得到了中国科学技术大学 Vlab 实验平台的帮助与支持。
- 自动化测试参考 <https://github.com/cs3001h/cs3001h.tests> 以及官方测试 <https://github.com/riscv-software-src/riscv-tests>
