# 生命游戏

具体规则这里不再赘述

采用 `riscv32-unknown-elf-gcc` 编译，编译优化选项 `-O2`

注意 MMIO 区域最好用 `volatile int* p` 形式来表示以避免被优化

vga 的映射见 ../src/vga_driver.v

效果为显示屏中央显示 480x480 的 16x16 个黑白格

![default](default.png)

v0.2 版本默认是以上的图案，初始 data.coe 如下

```plaintext
00000000
00000410
00000410
00000630
00000000
00007367
00001554
00000630
00000000
00000630
00001554
00007367
00000000
00000630
00000410
00000410
```

演示视频：<http://home.ustc.edu.cn/~liuly0322/videos/life_game.mp4>
