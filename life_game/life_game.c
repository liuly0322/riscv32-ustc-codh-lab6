int state[16] = {124, 0, 1};
int life[16] = {123, 1, 1};

int main() {
    while (1) {
        for (int i = 0; i < 2000000; i++) {
            asm("addi x0,x0,0");
        }
        int *p_ready = 0x0000ff10;
        int *p_data  = 0x0000ff14;
        if (*p_ready == 1) {
            int data = *p_data;
            if (data == 0) {
                continue;
            }
            for (int x = 0; x < 16; x++) {
                life[x] = 0;
                for (int y = 0; y < 16; y++) {
                    data *= 3;
                    life[x] += data >= 0 ? (1 << y) : 0; 
                }
            }
        }
        // 否则进入计算流程，首先计算这一轮结果
        for (int x = 0; x < 16; x++) {
            state[x] = 0;
            for (int y = 0; y < 16; y++) {
                // 需要统计周围
                int cnt = 0, now_x, now_y;
                now_x = x - 1;
                now_y = y - 1;
                if (now_x >= 0 && now_x < 16 && now_y >= 0 && now_y < 16) {
                    if (life[now_x] & (1 << now_y))
                        cnt++;
                }
                now_x = x - 1;
                now_y = y;
                if (now_x >= 0 && now_x < 16 && now_y >= 0 && now_y < 16) {
                    if (life[now_x] & (1 << now_y))
                        cnt++;
                }
                now_x = x - 1;
                now_y = y + 1;
                if (now_x >= 0 && now_x < 16 && now_y >= 0 && now_y < 16) {
                    if (life[now_x] & (1 << now_y))
                        cnt++;
                }
                now_x = x;
                now_y = y - 1;
                if (now_x >= 0 && now_x < 16 && now_y >= 0 && now_y < 16) {
                    if (life[now_x] & (1 << now_y))
                        cnt++;
                }
                now_x = x;
                now_y = y + 1;
                if (now_x >= 0 && now_x < 16 && now_y >= 0 && now_y < 16) {
                    if (life[now_x] & (1 << now_y))
                        cnt++;
                }
                now_x = x + 1;
                now_y = y - 1;
                if (now_x >= 0 && now_x < 16 && now_y >= 0 && now_y < 16) {
                    if (life[now_x] & (1 << now_y))
                        cnt++;
                }
                now_x = x + 1;
                now_y = y;
                if (now_x >= 0 && now_x < 16 && now_y >= 0 && now_y < 16) {
                    if (life[now_x] & (1 << now_y))
                        cnt++;
                }
                now_x = x + 1;
                now_y = y + 1;
                if (now_x >= 0 && now_x < 16 && now_y >= 0 && now_y < 16) {
                    if (life[now_x] & (1 << now_y))
                        cnt++;
                }
                if (life[x] & (1 << y)) {
                    state[x] += (cnt == 2 || cnt == 3)? (1 << y) : 0;
                } else {
                    state[x] += (cnt == 3)? (1 << y) : 0;
                }
                
            }
        }
        // 随后替换
        for (int x = 0; x < 16; x++) {
            life[x] = state[x];
        }
    }
}