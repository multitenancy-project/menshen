from scapy.all import *
import sys, os
from socket import *
import argparse
import time as time
from ctypes import *

so_file = "/home/earl-07/corundum-forked/utils/mqnic.so"

sys.path.append("common_func")
import common_func.func as func

# parser = argparse.ArgumentParser(description='convert from pcap to axi file or vince visa')
# parser.add_argument('--direction', type=int, default=0, choices=[0,1],
#                         help='0 for pcap to axi, 1 for axi to pcap')
# args = parser.parse_args()


def main():
    s = socket(AF_PACKET, SOCK_RAW, ETH_P_ALL)
    s.bind(("enp1s0", 0))
    get_token = CDLL(so_file)
    stateful_pkts = func.parse_configuration("stateconf.txt")
    conf1_pkts = func.parse_configuration("conf1.txt")
    conf2_pkts = func.parse_configuration("conf2.txt")

    conf_pkts = []
    conf_pkts.extend(stateful_pkts)
    conf_pkts.extend(conf1_pkts)
    conf_pkts.extend(conf2_pkts)

    # cnt = 0
    for conf_pkt in conf_pkts:
        #if cnt%2==0:
        #    pkt = gen_data_pkt("abcdabcdabcdabcdabcdabcdabcd"+4*"00", 2)
        #    s.send(bytes(pkt))
        token_bf = get_token.get_token()
        time_bf = time.time_ns()
        s.send(bytes(conf_pkt))
        token_af = get_token.get_token()
        while(token_af==token_bf):
            continue
        time_af = time.time_ns()
        print("spent time: ", time_af-time_bf)
        time.sleep(0.1)

    pkt = func.gen_data_pkt("0009000000020000000400000000"+4*"00", 1)
    s.send(bytes(pkt))
    pkt = func.gen_data_pkt("002d000000040000000200000000"+4*"00", 1)
    s.send(bytes(pkt))
    pkt = func.gen_data_pkt("00130000000200000000"+8*"00", 2)
    s.send(bytes(pkt))
    pkt = func.gen_data_pkt("002600000002ffffffff"+8*"00", 2)
    s.send(bytes(pkt))
    pkt = func.gen_data_pkt("002d000000040000000200000000"+4*"00", 1)
    s.send(bytes(pkt))
    pkt = func.gen_data_pkt("002d000000040000000200000000"+4*"00", 1)
    s.send(bytes(pkt))
    pkt = func.gen_data_pkt("00130000000200000000"+8*"00", 2)
    s.send(bytes(pkt))

    s.close()

if __name__ == "__main__":
    main()
