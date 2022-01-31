#include <features.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
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

//
#include "rw_reg.h"

uint32_t get_ctrl_token() {
	// 8
	char *ifnam;
	struct sume_ifreq sifr;
	struct ifreq ifr;
	size_t ifnamlen;
	uint32_t addr, value;
	int fd, flags, rc;

	addr = DEFAULT_BASE_ADDR + 8;
	ifnam = "ens1";
	value = 0;

	ifnamlen = strlen(ifnam);

	fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (fd == -1) {
		err(1, "socket failed for AF_INET");
	}

	memset(&sifr, 0, sizeof(sifr));
	sifr.addr = addr;

	memset(&ifr, 0, sizeof(ifr));
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';
	ifr.ifr_data = (char *)&sifr;

	rc = ioctl(fd, SUME_IOCTL_CMD_READ_REG, &ifr);
	if (rc == -1)
		err(1, "ioctl");

	close(fd);

	return sifr.val;
}

uint32_t get_vlan_1_cnt() {
	// c
	char *ifnam;
	struct sume_ifreq sifr;
	struct ifreq ifr;
	size_t ifnamlen;
	uint32_t addr, value;
	int fd, flags, rc;

	addr = DEFAULT_BASE_ADDR + 0xc;
	ifnam = "ens1";
	value = 0;

	ifnamlen = strlen(ifnam);

	fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (fd == -1) {
		err(1, "socket failed for AF_INET");
	}

	memset(&sifr, 0, sizeof(sifr));
	sifr.addr = addr;

	memset(&ifr, 0, sizeof(ifr));
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';
	ifr.ifr_data = (char *)&sifr;

	rc = ioctl(fd, SUME_IOCTL_CMD_READ_REG, &ifr);
	if (rc == -1)
		err(1, "ioctl");

	close(fd);

	return sifr.val;
}

uint32_t get_vlan_2_cnt() {
	// 0x10
	char *ifnam;
	struct sume_ifreq sifr;
	struct ifreq ifr;
	size_t ifnamlen;
	uint32_t addr, value;
	int fd, flags, rc;

	addr = DEFAULT_BASE_ADDR + 0x10;
	ifnam = "ens1";
	value = 0;

	ifnamlen = strlen(ifnam);

	fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (fd == -1) {
		err(1, "socket failed for AF_INET");
	}

	memset(&sifr, 0, sizeof(sifr));
	sifr.addr = addr;

	memset(&ifr, 0, sizeof(ifr));
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';
	ifr.ifr_data = (char *)&sifr;

	rc = ioctl(fd, SUME_IOCTL_CMD_READ_REG, &ifr);
	if (rc == -1)
		err(1, "ioctl");

	close(fd);

	return sifr.val;
}

uint32_t get_vlan_3_cnt() {
	// 0x14
	char *ifnam;
	struct sume_ifreq sifr;
	struct ifreq ifr;
	size_t ifnamlen;
	uint32_t addr, value;
	int fd, flags, rc;

	addr = DEFAULT_BASE_ADDR + 0x14;
	ifnam = "ens1";
	value = 0;

	ifnamlen = strlen(ifnam);

	fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (fd == -1) {
		err(1, "socket failed for AF_INET");
	}

	memset(&sifr, 0, sizeof(sifr));
	sifr.addr = addr;

	memset(&ifr, 0, sizeof(ifr));
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';
	ifr.ifr_data = (char *)&sifr;

	rc = ioctl(fd, SUME_IOCTL_CMD_READ_REG, &ifr);
	if (rc == -1)
		err(1, "ioctl");

	close(fd);

	return sifr.val;
}

void set_vlan_drop_flags(uint32_t vlan_drop_flags) {
	// 4
	char *ifnam;
	struct sume_ifreq sifr;
	struct ifreq ifr;
	size_t ifnamlen;
	uint32_t addr, value;
	int fd, flags, rc;

	addr = DEFAULT_BASE_ADDR + 4;
	ifnam = "ens1";

	ifnamlen = strlen(ifnam);

	fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (fd == -1) {
		err(1, "socket failed for AF_INET");
	}

	memset(&sifr, 0, sizeof(sifr));
	sifr.addr = addr;
	sifr.val = vlan_drop_flags;

	memset(&ifr, 0, sizeof(ifr));
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';
	ifr.ifr_data = (char *)&sifr;

	rc = ioctl(fd, SUME_IOCTL_CMD_WRITE_REG, &ifr);
	if (rc == -1)
		err(1, "ioctl");

	close(fd);

	return ;
}
