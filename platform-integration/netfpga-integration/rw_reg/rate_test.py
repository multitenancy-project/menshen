from ctypes import *
from datetime import datetime
import time


so_file = "/home/wtao/Downloads/test-netfpga/onNetFPGA/rw_reg/rw_reg.so"

so_dll = CDLL(so_file)

prev_vlan_1_cnt = c_uint32(so_dll.get_vlan_1_cnt())
prev_vlan_2_cnt = c_uint32(so_dll.get_vlan_2_cnt())
prev_vlan_3_cnt = c_uint32(so_dll.get_vlan_3_cnt())

while True:
    curr_vlan_1_cnt = c_uint32(so_dll.get_vlan_1_cnt())
    curr_vlan_2_cnt = c_uint32(so_dll.get_vlan_2_cnt())
    curr_vlan_3_cnt = c_uint32(so_dll.get_vlan_3_cnt())

    print (curr_vlan_1_cnt.value - prev_vlan_1_cnt.value,
        curr_vlan_2_cnt.value - prev_vlan_2_cnt.value,
        curr_vlan_3_cnt.value - prev_vlan_3_cnt.value)

    prev_vlan_1_cnt = curr_vlan_1_cnt
    prev_vlan_2_cnt = curr_vlan_2_cnt
    prev_vlan_3_cnt = curr_vlan_3_cnt

    time.sleep(0.1)
