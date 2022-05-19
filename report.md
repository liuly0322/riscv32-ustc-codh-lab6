&nbsp;

<div style="text-align:center;font-size:2.5em;font-weight:bold">中国科学技术大学计算机学院</div>

&nbsp;

<div style="text-align:center;font-size:2.5em;font-weight:bold">《计算机组成原理实验报告》</div>

&nbsp;

&nbsp;

&nbsp;

&nbsp;

&nbsp;

<img src="https://raw.githubusercontent.com/liuly0322/USTC-CS-COURSE-HW/main/%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%BB%84%E6%88%90%E5%8E%9F%E7%90%86%E5%AE%9E%E9%AA%8C/logo.png" style="zoom: 50%;margin:auto;display:block" />

&nbsp;

&nbsp;

&nbsp;

&nbsp;

<div style="display:flex;justify-content:center;font-size:1.8em;line-height:2em">
<div>
<p style="padding-bottom:5px">实验题目：</p>
<p style="padding-bottom:5px">组员列表：</p>
<p style="padding-bottom:5px">&#x3000;</p>
<p style="padding-bottom:5px">完成时间：</p>
</div>
<div style="text-align: center;">
<p style="border-bottom: 1px solid; padding:0px 1em 4px">综合设计</p>
<p style="border-bottom: 1px solid; padding:0px 1em 4px">刘良宇 <span style="font-size:0.9em">PB20000180</span></p>
<p style="border-bottom: 1px solid; padding:0px 1em 4px">王铖潇 <span style="font-size:0.9em">PB20000072</span></p>
<p style="border-bottom: 1px solid; padding:0px 1em 4px">2022. 5. 19</p>
</div>
</div>


<div style="page-break-after:always"></div>

## 实验成果简介

本小组此次实验中在流水线 CPU 的基础上，增加拓展了以下内容：

- RV32i 指令集补充至 31 条
- 采用两级动态 Branch History Table 分支预测
- 提供可以实际运行的生命游戏，井字棋和贪吃蛇程序
  - 使用 C 语言编写程序，探索了交叉编译，增进了对计算机抽象层级的理解
  - 增添了对 VGA 屏幕外设的使用，使得程序更具有表现力
  - 增加一般性的外设拓展方法
    - 一般地，对数据寄存器封装，使用 MMIO
    - 特别地，由于 VGA 模块数据需求量较大，采取了共享内存的方式

## 实验环境

- Vivado 2019.1
- Verilator 4.220

## 指令集扩充

### 新增指令介绍

已经实现：

- add, sub, and, or, sll, sra, srl, xor, slt, sltu
- addi, andi, ori, slli, srai, srli, xori, slti, sltiu
- auipc, lui
- lw, sw
- beq, bne, blt, bge, bltu, bgeu
- jal, jalr

#### 原理介绍

（这里应该可以配个修改后的数据通路图）

- alu 修改（置位指令，lui 指令）

  to be done

- control 模块控制算数逻辑指令

  to be done

- 分支跳转部分利用 branch 指令对应三位标志位作为控制信号

  to be done

### 新增指令测试

对新增的指令进行了较为充分的测试：

![image-20220517105718522](report/image-20220517105718522.png)

对于每条新增指令都使用了多个测试样例

测试原理示例：

![image-20220517105844596](report/image-20220517105844596.png)

可以在仿真过程中，检测 pass 和 fail 寄存器的值，判断测试结果，通过读 x10 寄存器可以知道当前进行到了第几个测试样例

![image-20220517105914127](report/image-20220517105914127.png)

对应仿真程序：

![image-20220517110029052](report/image-20220517110029052.png)

### Verilator 高级语言仿真

#### 简介

Verilator 是一款高性能的 Verilog/System Verilog 开源仿真工具。运用 Verilator package，我们可以将 Verilog 和 System Verilog HDL 语言设计编译转换成 C++ 或者 SystemC 模型，所以从这个意义上来说，Verilator 更应该被成为是一个编译器而不是一个传统意义上的仿真器。

通常情况下，Verilator 的工作流程如下所示：

1. 首先 Verilator 将读取特定的 HDL 文件并检查其代码，同时还可以选择支持检查覆盖率和 debug 波形的生成。然后将源文件编译成源代码级的 `C++`或`SystemC`模型。其输出的模型会以`.cpp`和`.h`文件存在。
2. 为了能够完成仿真，额外需要一个用户自行编写的 C++ wrapper，这个 wrapper 与传统的 Verilog Testbench 功能类似，主要是为了连接顶层模块，并给予相应的激励。
3. 在 C++ 编译器的工作下，所有的之前生成的文件（C++ wrapper 以及 Verilated Model）以及库文件（Verilator 提供的 runtime library 或者 SystemC 库文件）会被一同合并成一个可执行文件。
4. 执行生成的可执行文件，就可以开始实际的仿真，"simulation runtime"

#### 优势

- 最快的开源仿真器
- coverage test（覆盖测试）
  - 覆盖率，便于功能验证
  - 断言式的测试样例（灵活度高），对应 Verilog testbench 文件中的 function 或者 task，但编写起来更为容易，可以自动判断 CPU 功能正确与否

| ![](report/verilator1.png) | ![](report/verilator2.png) |
| -------------------------- | -------------------------- |

图：覆盖测试能解决的问题

## 分支预测

### 原理

#### 静态分支预测

- 统一不跳转 / 统一跳转
- 下一条指令统一发射地址较小的
- ......

#### 动态分支预测

- 记录上次分支的结果（BTB）

- 基于两位饱和计数器的分支预测 （BHT）

  ![](report/counter.jpg)

- 两级适应性训练 Two-Level Adaptive Training

  - Tse-Yu Yeh and Yale N. Patt

  ![image-20220517112404458](report/image-20220517112404458.png)
  
  对于每个跳转的 pattern 都对应饱和计数器，进一步提高了分支预测准确性
  
  实现上，可以使用两级 RAM 查询
  

### Verilog 实现

  to be done

（以下这些测试结果可以考虑优化排版，绘制折线图等）

下面分别挑选排序测试以及两个分支测试样例，对比采用不同的分支预测策略对 CPI 的降低情况

### 排序测试

#### 单周期（CPI = 1）

![image-20220506131500227](report/image-20220506131500227.png)

#### 流水线（无分支预测）

![image-20220506131546222](report/image-20220506131546222.png)

$\mathrm{CPI} = 3187/2290 = 1.392$

#### 流水线（默认分支失败）

![image-20220506131630753](report/image-20220506131630753.png)

$\mathrm{CPI} = 2819/2290 = 1.231$

#### 流水线（ load 仅在产生相关时气泡）

![image-20220506133345894](report/image-20220506133345894.png)

$\mathrm{CPI} = 2643/2290 = 1.154$

#### 流水线（分支预测）

![image-20220506205005538](report/image-20220506205005538.png)

$\mathrm{CPI} = 2563/2290 = 1.119$

### 分支测试

```cpp
for (int i = 0; i <= 1000; i++) {
    if (i <= 500) {
        i++;
    }
}
```

对应汇编代码：

```assembly
addi a0, zero, 1000
addi a1, zero, 500
addi t1, zero, 0  # i

LOOP:
blt  a0, t1, FINISH
blt  a1, t1, CONT
addi t1  t1, 1
CONT:
addi t1, t1, 1
beq  zero, zero, LOOP

FINISH:
addi t6, zero, 1
```

#### 单周期（CPI = 1）

![image-20220506162917623](report/image-20220506162917623.png)

#### 流水线（默认跳转失败分支预测）

![image-20220506162747975](report/image-20220506162747975.png)

$\mathrm{CPI} = 9019/6517=1.384$

#### 流水线（优化分支预测）

![image-20220506163814604](report/image-20220506163814604.png)

$\mathrm{CPI}=6529/6517=1.002$

### 分支测试（续）

```c
for (int i = 0; i <= 1000; i++) {
    if (i % 4 == 0) {
        i+= 4;
    }
}
```

汇编：

```assembly
addi a0, zero, 1000
addi t0, zero, 0  # a
addi t1, zero, 0  # i

LOOP:
blt  a0, t1, FINISH
andi t2, t1, 3
bnez t2, CONT
addi t1  t1, 4
CONT:
addi t1, t1, 1
j    LOOP

FINISH:
addi t6, zero, 1
```

#### 单周期

![image-20220514004522267](report/image-20220514004522267.png)

#### 流水线（饱和计数器）

![image-20220514000829679](report/image-20220514000829679.png)

$\mathrm{CPI} = 1.049$

#### 流水线（二级适应性训练）

![image-20220514000839423](report/image-20220514000839423.png)

$\mathrm{CPI} = 1.004$

## 生命游戏

作为示例，本 cpu 搭载了两个和 vga 结合的展示程序

### 编译

采用 `riscv` 交叉编译工具链，使得仅需要编写 C 程序就可以很方便的烧写上板

环境如下：

![image-20220517112914875](report/image-20220517112914875.png)

- Vlab Ubuntu 20.04
- riscv32-unknown-elf-gcc 10.2.0

配置 makefile 使得自动生成 objdump 等文件

![image-20220517113023820](report/image-20220517113023820.png)

这里需要注意的是，如果编译开启了 `-O2` 优化选项，那么一些对于 MMIO 区域的数据读写操作可能会被编译器优化，可以考虑对 MMIO 地址添加 `volatile` 关键词来禁止编译器的这一优化

### 简介

生命游戏中，对于任意细胞，规则如下：

- 每个细胞有两种状态 - 存活或死亡，每个细胞与以自身为中心的周围 **八格** 细胞产生互动（如图，黑色为存活，白色为死亡）
- 当前细胞为存活状态时，当周围的存活细胞低于 2 个时，该细胞变成死亡状态。（模拟生命数量稀少）
- 当前细胞为存活状态时，当周围有 2 个或 3 个存活细胞时，该细胞保持原样。
- 当前细胞为存活状态时，当周围有超过 3 个存活细胞时，该细胞变成死亡状态。（模拟生命数量过多）
- 当前细胞为死亡状态时，当周围有 3 个存活细胞时，该细胞变成存活状态。（模拟繁殖）

可以把最初的细胞结构定义为种子，当所有在种子中的细胞 **同时** 被以上规则处理后，可以得到第一代细胞图。按规则继续处理当前的细胞图，可以得到下一代的细胞图，周而复始。

![](report/glider_gun.gif)

### C 语言实现

- 插入 nop 模拟定时

  ```cpp
  for (int i = 0; i < 2000000; i++) {
      asm("addi x0,x0,0");
  }
  ```

- 状态压缩 + 位运算

  ```cpp
  if (life[x] & (1 << y)) {
      state[x] += (cnt == 2 || cnt == 3)? (1 << y) : 0;
  } else {
      state[x] += (cnt == 3)? (1 << y) : 0;
  }
  ```

### VGA 驱动

这里采用的是共享内存的方式，VGA 可以访问主存中的数据从而进行显示器 RGB 信号的映射

```mermaid
graph LR
cpu--read/write-->memory
vga_output---vga_driver--read-->memory
```

### 展示

to be done

<http://home.ustc.edu.cn/~liuly0322/videos/life_game.mp4>

## 井字棋

### C 语言实现

```cpp
#define input_flag 0xff10
#define input_data 0xff14
......
if (!(*((unsigned int*)input_flag))) {
    continue;
}

// 用户输入的值：1-9，表示下在哪个格子
unsigned int user_input = (*((unsigned int*)input_data));

// 判断下的位置是否合法
if (!user_input || user_input > 9 || state[user_input - 1])
    continue;
state[user_input - 1] = turn;
cnt++;

// 首先判断是否胜利，再判断是否占满
if (state[0] == turn && state[1] == turn && state[2] == turn ||
    state[3] == turn && state[4] == turn && state[5] == turn ||
    state[6] == turn && state[7] == turn && state[8] == turn ||
    state[0] == turn && state[3] == turn && state[6] == turn ||
    state[1] == turn && state[4] == turn && state[7] == turn ||
    state[2] == turn && state[5] == turn && state[8] == turn ||
    state[0] == turn && state[4] == turn && state[8] == turn ||
    state[2] == turn && state[4] == turn && state[6] == turn) {
    // 胜利
    state[9] = turn;
} else if (cnt == 9) {
    state[9] = 0;
}

// 圈和叉转换
turn = 3 - turn;
}

// 死循环等待结果输出
while (1)
;
```

从中可以看到交叉编译的方便之处

### 展示

<http://home.ustc.edu.cn/~liuly0322/videos/tic_tac_toe.mp4>

不同的胜负画面：

| ![](tic_tac_toe/o_win.png) | ![](tic_tac_toe/x_win.png) | ![](tic_tac_toe/draw.png) |
| -------------------------- | -------------------------- | ------------------------- |

## 贪吃蛇

### 外设使用

贪吃蛇可以比较好的体现出 CPU 处理外部设备的能力

此程序通过 MMIO ，需要访问：

- 性能计数器，起到一个计时器的功能
- 上下左右按钮的输入
- 硬件随机数发生器（可选）

本程序采用初始种子生成苹果坐标，故没有采用硬件随机数生成器；通过轮询的方式，与性能计数器和按钮输入达成了良好的交互

从中也可以看出，中断对于外设交互并不是必须的

> 最初引入硬件中断，只是出于性能上的考量。如果电脑系统没有中断，则处理器与外部设备通信时，它必须在向该设备发出指令后进行忙等待（Busy waiting），反复轮询该设备是否完成了动作并返回结果。这就造成了大量处理器周期被浪费。引入中断以后，当处理器发出设备请求后就可以立即返回以处理其他任务，而当设备完成动作后，发送中断信号给处理器，后者就可以再回过头获取处理结果。这样，在设备进行处理的周期内，处理器可以执行其他一些有意义的工作，而只付出一些很小的切换所引发的时间代价

### C 语言实现

```c
while (1) {
    // 等待计时器
    if ((int)get(CNT_DATA) - past_time < interval) {
        continue;
    }
    past_time += interval;

    // 确认当前方向
    if (get(BTN_VLD))
        direction = get(BTN_DATA);

    // 之前的蛇头变为蛇身
    set(head_x, head_y, BODY_BASE + direction);

    // 计算更新后蛇头坐标
    if (direction == UP) {
        head_x -= 1;
    } else if ......

    // 如果吃到苹果，更新苹果坐标，否则移动蛇尾
    if (head_x == apple_x && head_y == apple_y) {
        set(head_x, head_y, NONE);
        // 随机生成新的坐标
        ......
        set(apple_x, apple_y, APPLE);
    } else {
        int tail_direction =
            ((snake[tail_x][tail_y >> 3] >> (tail_y << 2)) & 15) -
            BODY_BASE;
        set(tail_x, tail_y, NONE);
        // 更新 tail 的位置
        ......
    }

    // 苹果处理完之后，如果当前蛇头所在格子不为空，则说明碰到障碍，退出
    int head_state = (snake[head_x][head_y >> 3] >> (head_y << 2)) & 15;
    if (head_state != NONE)
        break;

    // 设置蛇头，等待下个循环的计算
    set(head_x, head_y, HEAD);
}
```

状态编码采用宏定义配合状态压缩

```c
// 状态压缩，30 行，40 列，8 列压缩为一个 int(32 位)
// 对应每个格子 4bit，参考 00(R分量)0(G分量)0(B分量)
#define NONE 0    // 空格
#define BORDER 1  // 蓝色边框
#define HEAD 2    // 绿色蛇头
#define APPLE 4   // 红色苹果
#define BODY_BASE 7
#define BODY_L 9   // 蛇身，左
#define BODY_R 8   // 蛇身，右
#define BODY_U 15  // 蛇身，上
#define BODY_D 11  // 蛇身，下

// 对应 rv32i 的 lw 指令
inline unsigned get(int p) {
    return *((unsigned*)p);
}

// 输入需要设置的坐标和状态
inline void set(unsigned x, unsigned y, unsigned state) {
    // 先抹平这些位，再将数据移位
    snake[x][y >> 3] &= (~(15 << (y << 2)));
    snake[x][y >> 3] |= (state << (y << 2));
}
```

### 展示

to be done

见文件夹内演示视频

## 总结与思考

to be done

## 致谢

- 本项目得到了中国科学技术大学 Vlab 实验平台的帮助与支持。

- 自动化测试参考 <https://github.com/cs3001h/cs3001h.tests> 以及官方测试 <https://github.com/riscv-software-src/riscv-tests>
