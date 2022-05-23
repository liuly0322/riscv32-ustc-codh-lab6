#!/usr/bin/bash
cp headers/top_text.coe headers/text.coe
verilator -Iheaders -Isrc --cc src/top_test.v --trace --exe headers/top_cpu.cpp
make -j -C ./obj_dir -f Vtop_test.mk Vtop_test 
./obj_dir/Vtop_test
open new.gtkw