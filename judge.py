import subprocess

while True:
    print("输入想要测试的 case 名，输入 quit 退出")
    print("当前支持： sort_vcd bypass1 bypass2 bypass3 bypass4 bypass5 no_hazard branch ri load_store")
    try:
        s = input().strip()
    except:
        exit(0)
    if s == "quit":
        break
    cpu_test_file_name = s[:-1] if s[-1].isdigit() else s
    subprocess.run(['cp', 'headers/{}_data.coe'.format(s), 'headers/data.coe'])
    subprocess.run(['cp', 'headers/{}_text.coe'.format(s), 'headers/text.coe'])
    subprocess.run(['verilator', '-Iheaders', '-Isrc', '--cc',
                    'src/cpu.v', '--trace', '--exe', 'headers/cpu_{}.cpp'.format(cpu_test_file_name)])
    subprocess.run(['make', '-j', '-C', './obj_dir', '-f', 'Vcpu.mk', 'Vcpu'])
    subprocess.run(['./obj_dir/Vcpu'])
    print('')
