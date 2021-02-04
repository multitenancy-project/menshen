/*

Copyright 2019, The Regents of the University of California.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE REGENTS OF THE UNIVERSITY OF CALIFORNIA ''AS
IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE REGENTS OF THE UNIVERSITY OF CALIFORNIA OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of The Regents of the University of California.

*/

#include "mqnic.h"

#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>

struct mqnic *mqnic_open(const char *dev_name)
{
    struct mqnic *dev = calloc(1, sizeof(struct mqnic));
    struct stat st;

    if (!dev)
    {
        perror("memory allocation failed");
        goto fail_alloc;
    }

    dev->fd = open(dev_name, O_RDWR);

    if (dev->fd < 0)
    {
        perror("open device failed");
        goto fail_open;
    }

    if (fstat(dev->fd, &st) == -1)
    {
        perror("fstat failed");
        goto fail_fstat;
    }

    dev->regs_size = st.st_size;

    if (dev->regs_size == 0)
    {
        struct mqnic_ioctl_info info;
        if (ioctl(dev->fd, MQNIC_IOCTL_INFO, &info) != 0)
        {
            perror("MQNIC_IOCTL_INFO ioctl failed");
            goto fail_ioctl;
        }

        dev->regs_size = info.regs_size;
    }

    dev->regs = (volatile uint8_t *)mmap(NULL, dev->regs_size, PROT_READ | PROT_WRITE, MAP_SHARED, dev->fd, 0);
    if (dev->regs == MAP_FAILED)
    {
        perror("mmap regs failed");
        goto fail_mmap_regs;
    }

    if (mqnic_reg_read32(dev->regs, MQNIC_REG_FW_ID) == 0xffffffff)
    {
        // if we were given a PCIe resource, then we may need to enable the device
        char path[PATH_MAX+32];
        char *ptr;

        strcpy(path, dev_name);
        ptr = strrchr(path, '/');
        if (ptr)
        {
            strcpy(++ptr, "enable");
        }

        if (access(path, F_OK) != -1)
        {
            FILE *fp = fopen(path, "w");

            if (fp)
            {
                fputc('1', fp);
                fclose(fp);
            }
        }
    }

    if (mqnic_reg_read32(dev->regs, MQNIC_REG_FW_ID) == 0xffffffff)
    {
        fprintf(stderr, "Error: device needs to be reset\n");
        goto fail_reset;
    }

    dev->fw_id = mqnic_reg_read32(dev->regs, MQNIC_REG_FW_ID);
    dev->fw_ver = mqnic_reg_read32(dev->regs, MQNIC_REG_FW_VER);
    dev->board_id = mqnic_reg_read32(dev->regs, MQNIC_REG_BOARD_ID);
    dev->board_ver = mqnic_reg_read32(dev->regs, MQNIC_REG_BOARD_VER);

    dev->phc_count = mqnic_reg_read32(dev->regs, MQNIC_REG_PHC_COUNT);
    dev->phc_offset = mqnic_reg_read32(dev->regs, MQNIC_REG_PHC_OFFSET);
    dev->phc_stride = mqnic_reg_read32(dev->regs, MQNIC_REG_PHC_STRIDE);

    if (dev->phc_count)
    {
        dev->phc_regs = dev->regs + dev->phc_offset;
    }

    dev->if_count = mqnic_reg_read32(dev->regs, MQNIC_REG_IF_COUNT);
    dev->if_stride = mqnic_reg_read32(dev->regs, MQNIC_REG_IF_STRIDE);
    dev->if_csr_offset = mqnic_reg_read32(dev->regs, MQNIC_REG_IF_CSR_OFFSET);


    if (dev->if_count > MQNIC_MAX_IF)
        dev->if_count = MQNIC_MAX_IF;

    for (int k = 0; k < dev->if_count; k++)
    {
        struct mqnic_if *interface = &dev->interfaces[k];
        interface->regs = dev->regs + k*dev->if_stride;
        interface->csr_regs = interface->regs + dev->if_csr_offset;

        if (interface->regs >= dev->regs+dev->regs_size)
            goto fail_range;
        if (interface->csr_regs >= dev->regs+dev->regs_size)
            goto fail_range;

        interface->if_id = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_IF_ID);
        interface->if_features = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_IF_FEATURES);

        interface->event_queue_count = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_EVENT_QUEUE_COUNT);
        interface->event_queue_offset = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_EVENT_QUEUE_OFFSET);
        interface->tx_queue_count = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_TX_QUEUE_COUNT);
        interface->tx_queue_offset = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_TX_QUEUE_OFFSET);
        interface->tx_cpl_queue_count = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_TX_CPL_QUEUE_COUNT);
        interface->tx_cpl_queue_offset = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_TX_CPL_QUEUE_OFFSET);
        interface->rx_queue_count = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_RX_QUEUE_COUNT);
        interface->rx_queue_offset = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_RX_QUEUE_OFFSET);
        interface->rx_cpl_queue_count = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_RX_CPL_QUEUE_COUNT);
        interface->rx_cpl_queue_offset = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_RX_CPL_QUEUE_OFFSET);

        interface->port_count = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_PORT_COUNT);
        interface->port_offset = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_PORT_OFFSET);
        interface->port_stride = mqnic_reg_read32(interface->csr_regs, MQNIC_IF_REG_PORT_STRIDE);

        if (interface->event_queue_count > MQNIC_MAX_EVENT_RINGS)
            interface->event_queue_count = MQNIC_MAX_EVENT_RINGS;
        if (interface->tx_queue_count > MQNIC_MAX_TX_RINGS)
            interface->tx_queue_count = MQNIC_MAX_TX_RINGS;
        if (interface->tx_cpl_queue_count > MQNIC_MAX_TX_CPL_RINGS)
            interface->tx_cpl_queue_count = MQNIC_MAX_TX_CPL_RINGS;
        if (interface->rx_queue_count > MQNIC_MAX_RX_RINGS)
            interface->rx_queue_count = MQNIC_MAX_RX_RINGS;
        if (interface->rx_cpl_queue_count > MQNIC_MAX_RX_CPL_RINGS)
            interface->rx_cpl_queue_count = MQNIC_MAX_RX_CPL_RINGS;

        if (interface->port_count > MQNIC_MAX_PORTS)
            interface->port_count = MQNIC_MAX_PORTS;

        for (int l = 0; l < interface->port_count; l++)
        {
            struct mqnic_port *port = &interface->ports[l];
            port->regs = interface->regs + interface->port_offset + interface->port_stride*l;

            if (port->regs >= dev->regs+dev->regs_size)
                goto fail_range;

            port->port_id = mqnic_reg_read32(port->regs, MQNIC_PORT_REG_PORT_ID);
            port->port_features = mqnic_reg_read32(port->regs, MQNIC_PORT_REG_PORT_FEATURES);
            port->port_mtu = mqnic_reg_read32(port->regs, MQNIC_PORT_REG_PORT_MTU);

            port->sched_count = mqnic_reg_read32(port->regs, MQNIC_PORT_REG_SCHED_COUNT);
            port->sched_offset = mqnic_reg_read32(port->regs, MQNIC_PORT_REG_SCHED_OFFSET);
            port->sched_stride = mqnic_reg_read32(port->regs, MQNIC_PORT_REG_SCHED_STRIDE);
            port->sched_type = mqnic_reg_read32(port->regs, MQNIC_PORT_REG_SCHED_TYPE);

            port->tdma_timeslot_count = mqnic_reg_read32(port->regs, MQNIC_PORT_REG_TDMA_TIMESLOT_COUNT);

            /*
            * checkme: inserted testcase for axil channel in RMT
            */
            if(k == 0) {
                port->if_token = mqnic_reg_read32(dev->regs, MQNIC_PORT_REG_RMT_TOKEN);
                port->if_cookie = mqnic_reg_read32(dev->regs, MQNIC_PORT_REG_RMT_COOKIE);
                //printf("token value is: %08x\n", port->if_token);
                //printf("cookie value is: %08x\n", port->if_cookie);
            }

            for (int m = 0; m < port->sched_count; m++)
            {
                struct mqnic_sched *sched = &port->sched[m];
                sched->regs = port->regs + port->sched_offset + port->sched_stride*m;

                if (sched->regs >= dev->regs+dev->regs_size)
                    goto fail_range;
            }
        }
    }

    return dev;

fail_range:
    fprintf(stderr, "Error: computed pointer out of range\n");
fail_reset:
    munmap((void *)dev->regs, dev->regs_size);
fail_mmap_regs:
fail_ioctl:
fail_fstat:
    close(dev->fd);
fail_open:
    free(dev);
fail_alloc:
    return NULL;
}

void mqnic_close(struct mqnic *dev)
{
    if (!dev)
        return;

    munmap((void *)dev->regs, dev->regs_size);
    close(dev->fd);
    free(dev);
}

uint32_t get_cookie()
{
    char *name;
    char *device = NULL;
    struct mqnic *dev;
    int interface = 0;
    int port = 0;
    uint32_t cookie  = 0;
    uint32_t token = 0;

    char dev_name[6] = "ens0f1";
    name = malloc(sizeof(dev_name));
    
    dev = mqnic_open(name);

    if (!dev)
    {
        fprintf(stderr, "Failed to open device\n");
        return -1;
    }
    struct mqnic_if *dev_interface = &dev->interfaces[interface];
    struct mqnic_port *dev_port = &dev_interface->ports[port];

    cookie = mqnic_reg_read32(dev_port->regs, MQNIC_PORT_REG_RMT_COOKIE);

    return cookie;
    
    //printf("the cookie value is %03x\n", cookie);
    //printf("the token value is %03x\n", token);

}   

uint32_t get_token()
{
    char *name;
    char *device = NULL;
    struct mqnic *dev;
    int interface = 0;
    int port = 0;
    uint32_t cookie  = 0;
    uint32_t token = 0;

    char dev_name[6] = "ens0f1";
    name = malloc(sizeof(dev_name));
    
    dev = mqnic_open(device);

    if (!dev)
    {
        fprintf(stderr, "Failed to open device\n");
        return -1;
    }
    struct mqnic_if *dev_interface = &dev->interfaces[interface];
    struct mqnic_port *dev_port = &dev_interface->ports[port];

    token = mqnic_reg_read32(dev_port->regs, MQNIC_PORT_REG_RMT_TOKEN);

    return token;
    
    //printf("the cookie value is %03x\n", cookie);
    //printf("the token value is %03x\n", token);

}   
