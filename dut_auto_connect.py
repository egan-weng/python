#!/usr/bin/python
# encoding: utf-8
"""
@Author: EganWeng
@Contact: eganweng@163.com
@File: dut_auto_connect.py
@Time: 3/31/2021 3:15 PM
"""

import re
import copy  # Used for deepcopy
import time
import os  # Used for os path
import shutil  # Used for remove non-empty directory

"""
Usage:
If you add a new module, you need to do the following thins:
1. define dut_name and a [] in dut_signal list

After completion of executing...
1. you need to search REVISIT
2. you need to find ()
"""

# Python log directory
run_log_dir = 'python_log'

# Project name
prj_name = 'yamin'

# Top file name
top_file_name = run_log_dir + '\\' + prj_name + '_mss_tb_dut.v'

# Signal lists of DUT blocks, all port signals, include clk and reset. Format: [signal_name, attribute]
dut_signal = {  # suffix has _i or _o
    'biu': [],
    'stb': [],
    'dcu': [],
    'icu': [],
    'lsu': [],
    'tcu': [],
    'miu': []
}

# Connection signals between the modules
conn_signal_list = []  # no _i or _o suffix

# The signals of top wrapper port, exclude clk_rst_signal_list
port_signal_list = []  # suffix has _i or _o

# Clock and Reset
clk_rst_signal_list = []
clk_rst_name = ('clk', 'aclk', 'bclk', 'clkin', 'dclk', 'iclk', 'rclk', 'fclk', 'clock', 'csysreset_n', 'reset_n',
                'po_reset_n', 'reset', 'rst_n', 'rst', 'cporeset_n', 'mbist_reset_n', 'mbistreset_n')


def print_file_header(mode='w'):
    """
    Print the Header of a file
    """
    with open(top_file_name, mode) as f_out:
        f_out.write('//------------------------------------------------------------------------------\n')
        f_out.write('// The confidential and proprietary information contained in this file may\n')
        f_out.write('// only be used by a person authorised under and to the extent permitted\n')
        f_out.write('// by a subsisting licensing agreement from Arm Limited or its affiliates.\n')
        f_out.write('//\n')
        f_out.write('//            (C) COPYRIGHT 2012-2019 Arm Limited or its affiliates.\n')
        f_out.write('//                ALL RIGHTS RESERVED\n')
        f_out.write('//\n')
        f_out.write('// This entire notice must be reproduced on all copies of this file\n')
        f_out.write('// and copies of this file may only be made by a person if such person is\n')
        f_out.write('// permitted to do so under the terms of a subsisting license agreement\n')
        f_out.write('// from Arm Limited or its affiliates.\n')
        f_out.write('//\n')
        f_out.write('// Release Information :\n')
        f_out.write('//------------------------------------------------------------------------------\n')
        f_out.write('// SystemVerilog (IEEE Std 1800-2012)\n')
        f_out.write('//------------------------------------------------------------------------------\n')
        f_out.write('\n')


def print_module_header(module_name, mode='a'):
    """
    Print the Header of a module
    """
    with open(top_file_name, mode) as f_out:
        f_out.write('module {0} import yamin_pkg::*;\n'.format(module_name))
        f_out.write(' #(\n')
        f_out.write('    `include "yamin_decl.sv"\n')
        f_out.write('  ) (\n')


def print_module_tailer(mode='a'):
    """
    Print the Tailer of a module
    """
    with open(top_file_name, mode) as f_out:
        f_out.write('\nendmodule\n')


def calc_signal_attr(signal):
    """
    The input should a list include: port_direction + port_type + port_name
    Calculate each signal attribute. The structure is: signal_name + attribute
    For Exacmple:
        input  wire logic        [31:0] core_lsu_dbg_bp_wdata_i,  ->  core_lsu_dbg_bp_wdata_i + [31:0]
        input  wire ippb_resp_t         core_lsu_ippb_resp_i,     ->  core_lsu_ippb_resp_i  +  ippb_resp_t
        input  wire logic               core_lsu_dbg_dbe_i,       ->  core_lsu_dbg_dbe_i  +  1
    """
    curr_list = [signal[-1]]
    if signal[-2] == 'logic' or signal[-2] == 'wire':
        curr_list.append('1')
    else:
        curr_list.append(signal[-2])
    return curr_list


def unique(list1):
    """
    Remove same value in list([ [,], ,[], [,] ])
    """
    unique_list = []
    remove_list = []
    # Get remove_list
    for line in list1:
        if line[0] not in unique_list:
            unique_list.append(line[0])
        else:
            remove_list.append(line)
    # Remove same signal_name from list1
    for line in remove_list:
        list1.remove(line)


def extract_dut_signal_list(dut_name):
    """
    The input should be a module name string, such as biu/stb/dcu/icu/lsu/tcu/miu
    """
    with open('mss_'+dut_name+'.sv', 'r') as f_in, open(run_log_dir+'\\'+dut_name+'_signals_check.sv', 'w') as f_out:
        for line in f_in.readlines():
            match = re.match(r'\s*//', line)  # Remove comment lines
            if match:
                continue
            list0 = line.split()
            if len(list0) == 0:  # Remove blank lines
                continue
            if list0[0] == 'input' or list0[0] == 'output':  # select input|output lines
                code_with_comment = re.search(r'(.+)(//.*)', line)  # Some code maybe with a comment at the end
                if code_with_comment:
                    line = code_with_comment.group(1)  # Extract code from lines that include code and comment
                line = line.strip()  # Remove \n and space
                line = line.strip(',')  # Remove ,
                list1 = line.split()  # Split into list1
                dut_signal[dut_name].append(calc_signal_attr(list1))
                f_out.write(list1[-1] + '\n')   # For check signal completeness
            else:
                line = line.strip()  # Remove \n and space
                if line[-2:] == ');':  # module port end
                    break
        print('[Generation] Signal generation of {0} is completed'.format(dut_name))


def compare_signal(sig_a, sig_b):
    """
    Only compare _i and  _o signals
    Compare sig_a and sig_b to see if the signal name and attribute are the same
    1. if not same, do nothing
    2. if same, but attribute not same, report a error
    3. if same and not in connect_signal_list, then append into conn_signal_list
    """
    find = 0   # Indicate whether a signal is in list_sel
    if sig_a[0][-2:] == '_i' or sig_a[0][-2:] == '_o':  # only compare _i and  _o signals
        if sig_a[0][:-2] == sig_b[0][:-2]:  # Compare signal_name
            if sig_a[1] == sig_b[1]:  # Compare signal attribute
                for list0 in conn_signal_list:
                    if sig_a[0][:-2] == list0[0]:
                        print('[INFO] {0} already exists in conn_signal_list'.format(sig_a[0][:-2]))
                        find = 1
                        break
                if find == 0:
                    conn_signal_list.append([sig_a[0][:-2], sig_a[1]])
            else:
                print('[ERROR] the signal({2}) attribute of sig_a({0}) and sig_b({1}) do not match'.format
                      (sig_a[1], sig_b[1], sig_a[0]))


def generate_conn_signal_list():
    """
    Generates signals that connect the instantiated modules
    """
    dut_num = len(dut_signal)
    keys = list(dut_signal.keys())
    for i in range(0, dut_num, 1):
        key_i = keys[i]
        for outer_signal in dut_signal[key_i]:
            for j in range(i, dut_num, 1):
                if j == i:
                    continue
                key_j = keys[j]
                for inner_signal in dut_signal[key_j]:
                    compare_signal(outer_signal, inner_signal)


def print_conn_signal_list(mode='a'):
    """
    Print the conn_signal_list base on the attribute of signals
    """
    with open(top_file_name, mode) as f_out:
        f_out.write('\n' * 2)
        f_out.write(' '*2 + '//' + '-' * 66 + '\n')
        f_out.write(' '*2 + '//' + ' Define connection signals\n')
        f_out.write(' '*2 + '//' + '-' * 66 + '\n')
        for line in conn_signal_list:
            f_out.write(' ' * 4)  # add four space
            if line[1] == '1':
                f_out.write('logic {0};\n'.format(line[0]))
            elif line[1][0] == '[' and line[1][-1] == ']':
                f_out.write('logic {0} {1};\n'.format(line[1], line[0]))
            else:
                f_out.write('{0} {1};\n'.format(line[1], line[0]))


def generate_port_signal_list():
    """
    Generate all unconnected signals list, which maybe port signals
    """
    # Generate port_signal_list
    for key in dut_signal.keys():  # loop for all modules
        list_tmp = copy.deepcopy(dut_signal[key])  # Only deepcopy can copy all of the sub-lists
        for sig in conn_signal_list:  # First loop, connected signals
            find = 0
            tmp = []
            for sig_tmp in list_tmp:  # Second loop, all signals of each module
                if sig[0] == sig_tmp[0][:-2]:  # signal match
                    tmp = sig_tmp
                    find = 1
                    break
            if find == 1:
                list_tmp.remove(tmp)  # if match, remove it from list_tmp
        port_signal_list.append([key, key])  # For printing convenience
        for i in list_tmp:   # append unconnected signals of each module
            port_signal_list.append(i)
    # put clk and reset in clk_rst_signal_list
    for line in port_signal_list:
        if line[0] in clk_rst_name:
            clk_rst_signal_list.append(line)
    # remove clk and reset from port_signal_list
    for line in clk_rst_signal_list:
        port_signal_list.remove(line)
    # Remove same signal_name from clk_rst_signal_list
    unique(clk_rst_signal_list)


def print_port_signal(mode='a'):
    """
    Print the unconnected signals base on signal port type(_i/_o)
    """
    module_names = list(dut_signal.keys())
    with open(top_file_name, mode) as f_out:
        f_out.write('\n')
        # Clock and Reset Ports
        f_out.write(' ' * 4 + '// ---------- Clk and Reset----------\n')
        for line in clk_rst_signal_list:
            f_out.write(' ' * 4)  # add four spaces
            f_out.write('input wire logic {0};\n'.format(line[0]))
        # Other Ports
        for line in port_signal_list:
            if line[0] in module_names and line[0] == line[1]:  # module dividing line
                f_out.write(' ' * 4 + '// ---------- {0} Port Signals----------\n'.format(line[0]))
                continue
            f_out.write(' ' * 4)  # add four spaces
            if line[0][-2:] == '_i':
                port_type = 'input'
            elif line[0][-2:] == '_o':
                port_type = 'output'
            else:
                port_type = 'REVISIT'  # Need to confirm port type manually
            if line[1] == '1':
                f_out.write('{0} wire logic {1}'.format(port_type, line[0]))
            elif line[1][0] == '[' and line[1][-1] == ']':
                f_out.write('{0} wire logic {1} {2}'.format(port_type, line[1], line[0]))
            else:
                f_out.write('{0} wire {1} {2}'.format(port_type, line[1], line[0]))
            if line == port_signal_list[-1]:  # Last line
                f_out.write('\n);\n')
            else:
                f_out.write(',\n')


def print_signal_connect_port(mode='a'):
    """
    Print the signals declaration and connect to ports
    """
    module_names = list(dut_signal.keys())
    with open(top_file_name, mode) as f_out:
        f_out.write('\n')
        # Declare signals
        f_out.write(' '*2 + '// ---------- Declares the signal to connect to the port signals ----------\n'.title())
        for line in port_signal_list:
            if line[0] in module_names and line[0] == line[1]:
                continue
            f_out.write(' ' * 4)  # add four spaces
            if line[1] == '1':
                if line[0][-2:] == '_i' or line[0][-2:] == '_o':
                    f_out.write('logic {0};\n'.format(line[0][:-2]))
                else:
                    f_out.write('logic {0};\n'.format(line[0]))
            elif line[1][0] == '[' and line[1][-1] == ']':
                if line[0][-2:] == '_i' or line[0][-2:] == '_o':
                    f_out.write('logic {0} {1};\n'.format(line[1], line[0][:-2]))
                else:
                    f_out.write('logic {0} {1};\n'.format(line[1], line[0]))
            else:
                if line[0][-2:] == '_i' or line[0][-2:] == '_o':
                    f_out.write('{0} {1};\n'.format(line[1], line[0][:-2]))
                else:
                    f_out.write('{0} {1};\n'.format(line[1], line[0]))
        # Connect signal
        f_out.write('\n' + ' ' * 2 + '// ---------- Signal connected to port signals ----------\n'.title())
        for line in port_signal_list:
            if line[0] in module_names and line[0] == line[1]:
                continue
            f_out.write(' ' * 4)  # add four spaces
            if line[0][-2:] == '_i':
                f_out.write('assign {0} = {1};\n'.format(line[0][:-2], line[0]))
            elif line[0][-2:] == '_o':
                f_out.write('assign {0} = {1};\n'.format(line[0], line[0][:-2]))
            else:
                f_out.write('assign REVISIT = {0};\n'.format(line[0]))


def remove_io(signa_name):
    """
    Input arg is signal name. if the last two letters of the signal are _i or _o, the last two letters will be removed.
    Otherwise, the null character is returned.
    """
    if signa_name[-2:] == '_i' or signa_name[-2:] == '_o':
        return signa_name[: -2]
    else:
        return ''  # clock and reset will return null character


def check_signal_in_port_signal_list(signal_list):
    """
    Check a signal whether in port_signal_list: 
    """
    match = False
    for line in port_signal_list:
        if signal_list[0][:-2] == line[0][:-2]:
            match = True
            break
    return match


def dut_instantiation(dut_name, mode='a'):
    """
    Input arg: dut_name is the instantiated dut, mode is the mss_top file open mode
    """
    with open(top_file_name, mode) as f_out:
        f_out.write('\n' * 2)
        f_out.write(' '*2 + prj_name + '_' + dut_name + ' #(\n')
        f_out.write(' '*2 + '`  include "yamin_inst.sv"\n')
        f_out.write(' '*2 + ') u_{0} (\n'.format(dut_name))
        list_tmp = dut_signal[dut_name]
        for line in list_tmp:
            f_out.write(' ' * 4)  # print 4 space
            if line == list_tmp[-1]:  # Used for calculate the last signal in signals list
                if check_signal_in_port_signal_list(line):
                    f_out.write('.{0}({1})\n'.format(line[0], line[0]))
                else:
                    f_out.write('.{0}({1})\n'.format(line[0], remove_io(line[0])))
                f_out.write('  );\n')  # print last lines
            else:
                if check_signal_in_port_signal_list(line):
                    f_out.write('.{0}({1}),\n'.format(line[0], line[0]))
                else:
                    f_out.write('.{0}({1}),\n'.format(line[0], remove_io(line[0])))
        print('[Instantiation] The instantiation of {0} is completed'.format(dut_name))


def create_run_log_dir(dir_name):
    """
    Create a directory in current path
    1. If exist, delete it, then re-create new dir with the same name(dir_name)
    2. If not exist, create new dir
    """
    path = os.getcwd() + '\\' + dir_name
    folder = os.path.exists(path)
    if not folder:
        print('[INFO] Directory:{0} is not exist, py will create it'.format(run_log_dir))
        os.makedirs(path)
    else:
        print('[INFO] Remove old Directory:{0}'.format(run_log_dir))
        shutil.rmtree(path)
        print('[INFO] Create new Directory:{0}'.format(run_log_dir))
        os.makedirs(path)


def main():
    start_time = time.time()
    print("The main function is executing...")
    create_run_log_dir(run_log_dir)
    print("Extracting signal port lists...")
    # for key in dut_signal.keys():
    #     extract_dut_signal_list(key)
    extract_dut_signal_list('biu')
    extract_dut_signal_list('stb')
    extract_dut_signal_list('dcu')
    generate_conn_signal_list()
    generate_port_signal_list()
    print_file_header('w')
    print_module_header(prj_name + '_mss_tb_dut', 'a')
    print_port_signal('a')
    print_conn_signal_list('a')
    # print_signal_connect_port('a')
    for key in dut_signal.keys():
        dut_instantiation(key, 'a')
    print_module_tailer('a')
    print("The main function is finished...")
    end_time = time.time()
    total_time = end_time - start_time
    print('Execution time: {0}'.format(total_time))


if __name__ == '__main__':
    main()
