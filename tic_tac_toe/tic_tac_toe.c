#include <stdio.h>

// 0x8000 至 0x8020，是每个格子的状态编码
// 2'b00: 该格子没有棋子
// 2'b01: 该格子对应圈
// 2'b10: 该格子对应叉
#define g1 0x8000
#define g2 0x8004
#define g3 0x8008
#define g4 0x800c
#define g5 0x8010
#define g6 0x8014
#define g7 0x8018
#define g8 0x801c
#define g9 0x8020

// 0x8048，是游戏结果
// 2'b00: 无
// 2'b01: 圈胜出
// 2'b10: 叉胜出
// 2'b11: 未结束
#define Win 0x8048

// 0xff10: 为 1 说明开关输入有效
// 0xff14: 从这里读用户输入的数据
#define input_flag 0xff10
#define input_data 0xff14

// load from g,g is an address
int lw(int g)
{
    unsigned int *p = (unsigned int *)g; //注意ARM中常用无符号整型指针，(unsigned int *)是强制类型转换，让等号两边类型匹配
    return p;                            //解引用，间接改变地址中存的数
}

// store data to g , g is an address
void sw(int g, int data)
{
    unsigned int *p = (unsigned int *)g;
    p = data;
}

int main()
{
    int win = 3;                            //一开始默认未结束
    int d1, d2, d3, d4, d5, d6, d7, d8, d9; // 9个格子的值
    int turn = 1;                           //本次轮到圈还是叉
                                            //从圈开始
    //默认值存入内存中
    sw(Win, win);
    sw(g1, 0);
    sw(g2, 0);
    sw(g3, 0);
    sw(g4, 0);
    sw(g5, 0);
    sw(g6, 0);
    sw(g7, 0);
    sw(g8, 0);
    sw(g9, 0);

    while (lw(Win) == 3) //游戏未结束
    {
        while (!lw(input_flag)) //输入标志
            ;
        switch (lw(input_data)) //用户输入的值：1-9，表示下在哪个格子
        {
        case 1:
            sw(g1, turn);
            break;
        case 2:
            sw(g2, turn);
            break;
        case 3:
            sw(g3, turn);
            break;
        case 4:
            sw(g4, turn);
            break;
        case 5:
            sw(g5, turn);
            break;
        case 6:
            sw(g6, turn);
            break;
        case 7:
            sw(g7, turn);
            break;
        case 8:
            sw(g8, turn);
            break;
        case 9:
            sw(g9, turn);
            break;
        default:
            continue;
        }
        //取值
        d1 = data(g1);
        d2 = data(g2);
        d3 = data(g3);
        d4 = data(g4);
        d5 = data(g5);
        d6 = data(g6);
        d7 = data(g7);
        d8 = data(g8);
        d9 = data(g9);

        //判断：行，列，对角线
        int i = turn;
        if (d1 == i && d2 == i && d3 == i)
            win = i;
        else if (d4 == i && d5 == i && d6 == i)
            win = i;
        else if (d7 == i && d8 == i && d9 == i)
            win = i;
        else if (d1 == i && d4 == i && d7 == i)
            win = i;
        else if (d2 == i && d5 == i && d8 == i)
            win = i;
        else if (d3 == i && d6 == i && d9 == i)
            win = i;
        else if (d1 == i && d5 == i && d9 == i)
            win = i;
        else if (d3 == i && d5 == i && d7 == i)
            win = i;

        //都不满足但是格子下满了，游戏结束
        else if (d1 != 0 && d2 != 0 && d3 != 0 && d4 != 0 && d5 != 0 && d6 != 0 && d7 != 0 && d8 != 0 && d9 != 0)
            win = 0;
        sw(Win, win);

        //圈和叉转换
        if (turn == 1)
            turn = 2;
        else
            turn = 1;
    }
}