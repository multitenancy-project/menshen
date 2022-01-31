#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <net/if.h>

#include <err.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "nf_sume.h"


#define DEFAULT_BASE_ADDR	0x44020000


uint32_t get_ctrl_token();
uint32_t get_vlan_1_cnt();
uint32_t get_vlan_2_cnt();
uint32_t get_vlan_3_cnt();
void set_vlan_drop_flags(uint32_t set_vlan_drop_flags);
