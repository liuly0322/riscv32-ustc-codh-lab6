// 前九个数为每个格子的状态编码
// 2'b00: 该格子没有棋子
// 2'b01: 该格子对应圈
// 2'b10: 该格子对应叉
// 最后一个数为游戏结果
// 2'b00: 无
// 2'b01: 圈胜出
// 2'b10: 叉胜出
// 2'b11: 未结束
int state[10] = {1};

// 0xff10: 为 1 说明开关输入有效
// 0xff14: 从这里读用户输入的数据
#define input_flag 0xff10
#define input_data 0xff14

int main() {
    // 内存重置为默认值
    for (int i = 0; i < 9; i++) {
        state[i] = 0;
    }
    state[9] = 3;

    // 从圈开始
    int turn = 1;

    // 当前总共有多少棋子
    int cnt = 0;

    while (state[9] == 3) {
        // 等待开关输入
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
}