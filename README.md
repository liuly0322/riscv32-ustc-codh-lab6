# USTC-CODH-LAB6 实验

USTC CODH 课程的综合实验 lab6

使用实体板：xc7a100tcsg324-1

本实验为小组合作实验，组员主页：

- <https://github.com/liuly0322>
- <https://github.com/start-shine>

模板来源：<https://github.com/liuly0322/ustc-cod-verilator>

上面的模板链接中有本项目测试工具的具体使用方法。针对本项目，还额外增添了几个案例（见 `judge.py` ）

具体测试样例对应的汇编代码见本目录下的 bypass.dump 和 ri.dump

## rv32i 指令集

实现除部分访存指令之外的所有 rv32i 指令

- add, sub, and, or, sll, sra, srl, xor, slt, sltu
- addi, andi, ori, slli, srai, srli, xori, slti, sltiu
- auipc, lui
- lw, sw
- beq, bne, blt, bge, bltu, bgeu
- jal, jalr

共计 31 条

## 分支预测

采用 2-level adaptive training 策略，具体性能评估见 report.md

## VGA 应用程序

作为示例，本项目运行了两个应用程序，分别是井字棋和生命游戏。具体说明见 `life_game` 和 `tic_tac_toe` 文件夹

本项目得到了中国科学技术大学 Vlab 实验平台的帮助与支持。

This project is accomplished with the help of Vlab Platform of University of Science and Technology of China.
