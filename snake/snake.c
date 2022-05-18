// MMIO:
//
// 8'h10:
//     io_din_t = {{31{1'b0}}, swx_vld_r};
// 8'h14:
//     io_din_t = swx_data_r;
// 8'h18:
//     io_din_t = cnt_data_r;
// 8'h1c:
//     io_din_t = {31'b0, btn_vld_r};
// 8'h20:
//     io_din_t = {28'b0, btn_data_r};
#define SWX_VLD 0xff10
#define SWX_DATA 0xff14
#define CNT_DATA 0xff18
#define BTN_VLD 0xff1c
#define BTN_DATA 0xff20

// 方向，上下左右
#define UP 8
#define DOWN 4
#define LEFT 2
#define RIGHT 1

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
int snake[30][5] = {1};

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

int main() {
    // 游戏初始化
    unsigned interval;
    int random;
    while (1) {
        if (!get(SWX_VLD)) {
            continue;
        }
        interval = get(SWX_DATA);
        random = interval;
        break;
    }

    // 参量初始化
    unsigned direction = DOWN;
    unsigned apple_x = 16, apple_y = 20;
    unsigned head_x = 15, head_y = 20;
    unsigned tail_x = 15, tail_y = 20;

    // 数组初始化
    for (int x = 0; x < 30; x++) {
        for (int y = 0; y < 40; y++) {
            if (x == 0 || x == 29 || y == 0 || y == 39) {
                set(x, y, BORDER);
            } else {
                set(x, y, NONE);
            }
        }
    }
    set(16, 20, APPLE);
    set(15, 20, HEAD);

    // 计时器初始化
    int past_time = get(CNT_DATA);

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
        } else if (direction == DOWN) {
            head_x += 1;
        } else if (direction == LEFT) {
            head_y -= 1;
        } else {
            head_y += 1;
        }

        // 如果吃到苹果，更新苹果坐标，否则移动蛇尾
        if (head_x == apple_x && head_y == apple_y) {
            set(head_x, head_y, NONE);
            // 随机数，适配第一个空格且非当前头坐标的位置作为新的苹果坐标
            random = (random << 3) - random;
            int index = random & 1023;
            while (index) {
                for (int x = 0; x < 30 && index; x++) {
                    for (int y = 0; y < 40 && index; y++) {
                        if ((x != apple_x || y != apple_y) &&
                            (((snake[x][y >> 3] >> (y << 2)) & 15) == NONE)) {
                            if (!(--index)) {
                                apple_x = x;
                                apple_y = y;
                                break;
                            }
                        }
                    }
                }
            }
            set(apple_x, apple_y, APPLE);
        } else {
            int tail_direction =
                ((snake[tail_x][tail_y >> 3] >> (tail_y << 2)) & 15) -
                BODY_BASE;
            set(tail_x, tail_y, NONE);
            if (tail_direction == UP) {
                tail_x -= 1;
            } else if (tail_direction == DOWN) {
                tail_x += 1;
            } else if (tail_direction == LEFT) {
                tail_y -= 1;
            } else {
                tail_y += 1;
            }
        }

        // 苹果处理完之后，如果当前蛇头所在格子不为空，则说明碰到障碍，退出
        int head_state = (snake[head_x][head_y >> 3] >> (head_y << 2)) & 15;
        if (head_state != NONE)
            break;

        // 设置蛇头，等待下个循环的计算
        set(head_x, head_y, HEAD);
    }

    // 游戏结束
    while (1)
        ;
}