#include <errno.h>
#include <fcntl.h>
//#include <math.h>
//#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
//#include <sys/stat.h>
//#include <sys/time.h>
//#include <sys/timex.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include "timespec.h"

#include "mqnic.h"

#define NSEC_PER_SEC 1000000000


static void usage(char *name)
{
    fprintf(stderr,
        "usage: %s [options]\n"
        " -d name    device to open (/dev/mqnic0)\n"
        " -i number  interface\n"
        " -P number  port\n"
        " -s number  TDMA schedule start time (ns)\n"
        " -p number  TDMA schedule period (ns)\n"
        " -t number  TDMA timeslot period (ns)\n"
        " -a number  TDMA active period (ns)\n",
        name);
}


int main(int argc, char *argv[])
{
    char *name;
    char *device;
    char *device = NULL;
    struct mqnic *dev;
    int interface = 0;
    int port = 0;
    int cookie  = 0;
    int token = 0;

    name = strrchr(argv[0], '/');
    name = name ? 1+name : argv[0];

    while ((opt = getopt(argc, argv, "d:i:P:s:p:t:a:h?")) != EOF)
    {
        switch (opt)
        {
        case 'd':
            device = optarg;
            break;
        case 'i':
            interface = atoi(optarg);
            break;
        case 'P':
            port = atoi(optarg);
            break;
        case 's':
            start_nsec = atoll(optarg);
            break;
        case 'p':
            period_nsec = atoll(optarg);
            break;
        case 't':
            timeslot_period_nsec = atoll(optarg);
            break;
        case 'a':
            active_period_nsec = atoll(optarg);
            break;
        case 'h':
        case '?':
            usage(name);
            return 0;
        default:
            usage(name);
            return -1;
        }
    }

    if (!device)
    {
        fprintf(stderr, "Device not specified\n");
        usage(name);
        return -1;
    }

    dev = mqnic_open(device);

    if (!dev)
    {
        fprintf(stderr, "Failed to open device\n");
        return -1;
    }
    struct mqnic_if *dev_interface = &dev->interfaces[interface];
    struct mqnic_port *dev_port = &dev_interface->ports[port];

    cookie = mqnic_reg_read32(dev_port->regs, MQNIC_PORT_REG_RMT_COOKIE);
    token = mqnic_reg_read32(dev_port->regs, MQNIC_PORT_REG_RMT_TOKEN);
    
    printf("the cookie value is %03x\n", cookie);
    printf("the token value is %03x\n", token);

    return 0;
}