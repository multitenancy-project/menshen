from ctypes import *
from datetime import datetime
import time


so_file = "/home/wtao/Downloads/test-netfpga/onNetFPGA/rw_reg/rw_reg.so"

so_dll = CDLL(so_file)

print (type(so_dll.get_ctrl_token()))
print (so_dll.get_ctrl_token())
print (so_dll.get_vlan_1_cnt())
print (so_dll.get_vlan_2_cnt())
print (so_dll.get_vlan_3_cnt())
'''
print (so_dll.set_vlan_drop_flags(2))
time.sleep(2.0)
print (so_dll.set_vlan_drop_flags(0))
time.sleep(2.0)
'''
