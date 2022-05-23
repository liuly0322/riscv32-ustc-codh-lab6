#!/bin/python3
# encoding=utf8
import subprocess

auto_tests = "sort_vcd bypass1 bypass2 bypass3 bypass4 bypass5 no_hazard branch ri load_store".split()

for s in auto_tests:
    cpu_test_file_name = s[:-1] if s[-1].isdigit() else s
    subprocess.run(['cp', 'headers/{}_data.coe'.format(s), 'headers/data.coe'])
    subprocess.run(['cp', 'headers/{}_text.coe'.format(s), 'headers/text.coe'])
    subprocess.run(['verilator', '-Iheaders', '-Isrc', '--cc',
                    'src/cpu.v', '--trace', '--exe', 'headers/cpu_{}.cpp'.format(cpu_test_file_name)])
    subprocess.run(['make', '-j', '-C', './obj_dir', '-f', 'Vcpu.mk', 'Vcpu'])
    out_text = subprocess.check_output(['./obj_dir/Vcpu']).decode('utf-8')
    print(out_text)
    if "失败" in out_text:
        exit(1)

print("通过全部测试")
